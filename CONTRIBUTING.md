# Contributing

## Prerequisites

```bash
brew install pre-commit terraform-docs
brew install terraform-linters/tap/tflint
pre-commit install
```

Local tool versions must match the pins in
[`.github/workflows/pre-commit.yml`](.github/workflows/pre-commit.yml). terraform-docs changed its
markdown table style after v0.20.0, so a mismatch makes CI reject README tables that were generated
correctly on your machine. When you bump one side, bump the other in the same pull request.

## The gate

```bash
pre-commit run -a
```

This is what CI runs: `terraform fmt`, `terraform-docs`, `tflint`, `terraform validate`, plus two local
checks described below. Expect the first run after a change to *modify* files — terraform-docs rewrites
the README tables. Re-run until clean; it should pass twice in a row.

## Test layers

| Path | Runs on | Credentials | Proves |
| --- | --- | --- | --- |
| `examples/*` | every PR | no | The documented usage still type-checks against this code |
| `tests/local/` | every PR | no | Every input and output is still valid |
| `tests/*.tftest.hcl` | on demand, weekly | **yes** | Temporal Cloud accepts the payloads this module sends |

`terraform validate` is not a test: it never executes anything and never contacts the API. Only the
apply layer can catch the API rejecting a configuration that looks valid.

`terraform plan` is not a usable middle ground, because the provider authenticates when it initialises
and so needs a real key even for a plan that would create nothing.

### Why `terraform validate` proves so little here

`terraform validate` does not run the provider's own validators when a value arrives through a module
input. `ConflictsWith`, `OneOf`, `ExactlyOneOf` and the custom set validators all defer until every
attribute they compare is *known*, and a module input is unknown during the validate walk. Verified
both directions: a bad literal written straight onto the resource errors at validate, the same value
behind a variable does not, and `count` is not the cause.

Module-level `variable ... validation` blocks are the exception — they run at validate regardless,
which is why the rules this module enforces itself do surface there.

The consequence for the layering above: `validate` is a lint over types and the variable surface, not
evidence that a configuration is complete or correct. Resource `precondition` blocks are likewise
plan-time only. Only applying proves behaviour, which is what `tests/*.tftest.hcl` is for.
### Why examples are validated indirectly

`examples/*` source the **published** module so consumers can copy them verbatim from the Terraform
Registry. Validating them as written would check the last release rather than the working tree, which
would mean a module change and its example update could never land in the same pull request.

[`scripts/validate-examples.sh`](scripts/validate-examples.sh) resolves this: it copies each example to
a temporary directory, rewrites the registry source to a path to the repository root, and validates the
copy. Tracked files are never modified. `terraform_validate` excludes `examples/`, and the
`examples-validate` hook covers them instead.

The rewrite is scoped to this module's own registry address, not to every
`terraform-temporalcloud-modules/` address. `examples/complete` also calls the published **namespace**
module, which has to keep resolving from the registry — an unscoped rewrite would point it at this
repository. If a new example calls another module in the family, it will resolve from the registry the
same way, so that example needs network access to validate.

One consequence: examples are validated only on the maximum supported Terraform version, because the
exclusion also removes them from the minimum-version matrix jobs. The root module and `tests/local/`
are still checked against the minimum, which is what `required_version` asserts.

### Why `wrappers/` is hand-maintained

The upstream `terraform_wrapper_module_for_each` pre-commit hook is not enabled. It hardcodes
`terraform-aws-modules` and `aws` in the source addresses it generates, and it overwrites
`wrappers/README.md` on every run with an Amazon S3 example whose inputs do not exist in this module.
It offers no way to skip that file, so restoring a correct one leaves the gate permanently dirty.

[`scripts/check-wrapper-sync.sh`](scripts/check-wrapper-sync.sh) replaces the one useful thing the hook
did: it fails if a root variable is not passed through `wrappers/main.tf`. When you add a variable to
the root module, add the matching line to the wrapper in the same change.

## API behaviours the tests guard against

1. **Both sides of the endpoint are namespace IDs, not names.** `worker_target.namespace_id` and every
   entry in `allowed_caller_namespaces` must be `<namespace>.<account_id>`. A bare namespace name
   type-checks but is not a namespace ID, and the provider applies no validator of its own — so this
   module checks the shape during plan, and
   `nexus_endpoint.tftest.hcl` asserts the value that comes back is the ID and *not* the bare name — so
   the assumption fails loudly if the provider ever changes it.
2. **A namespace is not implicitly allowed to call its own endpoint.** The target namespace has to
   appear in `allowed_caller_namespaces` like any other caller. The update run block covers this.
3. **`description` is marked sensitive by the provider**, unusually for a description field. The module
   output is therefore sensitive, and test assertions on it need `nonsensitive()`.
4. **Region entitlements are per-account.** A region on the published list can still be rejected with
   `Region "..." is not a valid Temporal Cloud region`. `tests/setup/` reads the `temporalcloud_regions`
   data source rather than hardcoding one, so the suite runs on any account.

When writing assertions, note that outputs wrapped in `try(x, [])` evaluate to a *tuple*, so
`output.nexus_endpoint_allowed_caller_namespaces == tolist([])` is false even against an empty result.
Compare with `length()` and `contains()` instead.

## Running the apply tests

They create and destroy **real, billable** namespaces and endpoints. Point them at a scratch account.

```bash
export TEMPORAL_CLOUD_API_KEY="<key for a scratch account>"
terraform init
terraform test -verbose
```

This suite is slower than most in the family, because an endpoint cannot be applied without namespaces
on both sides and `tests/setup/` has to create them. [`tests/README.md`](tests/README.md) explains how
the files are arranged to keep that cost down.

Without a key every run block is skipped, which is a cheap way to check that the test files parse:

```text
Failure! 0 passed, 0 failed, 5 skipped.
```

In CI they run from the **Apply Tests** workflow. Its first step is
[`scripts/check-api.sh`](scripts/check-api.sh), a liveness check that confirms the API answers and the
key is accepted, so a credentials problem fails immediately rather than surfacing minutes later as a
namespace that would not create.

Apply Tests is chained after Pre-Commit, and Release after Apply Tests, so a merge to main runs:

```text
push to main -> Pre-Commit -> Apply Tests -> Release
```

A release is therefore only cut from code that passed both the static gate and the tests that apply
against a real account. Any failure in the chain stops it.

Apply Tests never runs on pull requests: forks cannot read secrets and every run costs money. It also
runs weekly, and on demand. Runs are serialized with `cancel-in-progress: false`, because cancelling
mid-apply would abandon real resources with no destroy.

Resources created by the tests are prefixed so leftovers from an interrupted run are identifiable; see
[`tests/README.md`](tests/README.md).

## Pull requests

Titles must be [conventional commits](https://www.conventionalcommits.org/) — `feat:`, `fix:`, `docs:`,
`ci:`, `chore:` — with a capitalised subject. Squash-merge makes the title the commit message, and
semantic-release derives the next version from it, so an invalid title silently breaks versioning. A
workflow enforces this.

`CHANGELOG.md` and tags are generated on merge. Never bump versions by hand.

If CI reports fewer checks than usual, check whether the pull request has merge conflicts: GitHub skips
`pull_request` workflows when it cannot compute a merge ref, with no failed check to show for it.
