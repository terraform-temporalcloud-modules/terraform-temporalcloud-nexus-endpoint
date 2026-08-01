# Tests

Not usage examples — see [examples/](../examples) for those.

| Path | Runs on | Credentials |
| --- | --- | --- |
| `local/` | every pull request | no |
| `*.tftest.hcl` | on demand, weekly | **yes** |
| `setup/` | helper for `*.tftest.hcl` | no |

`local/` passes every module input and references every output, so `terraform
validate` fails there as soon as the variable surface changes.

`*.tftest.hcl` applies against a real Temporal Cloud account, which is the only
way to catch the API rejecting a configuration that type-checks.

| File | Covers |
| --- | --- |
| `nexus_endpoint.tftest.hcl` | Create with a description, one caller and a worker target; update in place to a second caller, a different task queue and a new description; then the `wrappers` submodule with two endpoints from one call |
| `disabled.tftest.hcl` | `create_nexus_endpoint = false` creates nothing and every output falls back |

Fixtures: `setup/` generates unique names, selects a region the account is
entitled to, and creates the two namespaces the endpoint routes between.
`orphan-check/` reports leftovers and creates nothing.

## This suite is slower than most in the family

A Nexus endpoint is routing configuration between two namespaces and cannot be
applied without them, so `setup/` creates a real target namespace and a real
caller namespace on every run. Namespace creation dominates the runtime — the
endpoint itself is quick.

Two decisions follow from that, and both are deliberate:

- **`setup/` creates two namespaces, not more.** Two is the minimum that proves a
  caller can be a namespace other than the target.
- **The wrapper is exercised inside `nexus_endpoint.tftest.hcl` rather than in its
  own file.** A separate file would re-run `setup/` and create a second pair of
  namespaces. It is the last `run` block in the file, so a failure there cannot
  make the lifecycle coverage above skip.

`disabled.tftest.hcl` needs no namespaces and stays in its own file, so a fault in
the expensive file cannot hide it.

## Notes on the assertions

`description` is marked sensitive by the provider, so the module's
`nexus_endpoint_description` output is sensitive too. Assertions on it are wrapped
in `nonsensitive()`; without that the value cannot be compared in a test
condition.

Outputs wrapped in `try(x, [])` evaluate to a *tuple*, so
`output.nexus_endpoint_allowed_caller_namespaces == tolist([])` is false even
against an empty result. Compare with `length()` and `contains()` instead.

## What is not covered on apply

Every module input is exercised on apply. Two behaviours around the endpoint are
outside what Terraform can assert:

- **Whether a caller can actually reach the service.** Creating the endpoint only
  registers the route. Serving it needs a worker in the target namespace polling
  the task queue and registering a Nexus service, and calling it needs a workflow
  in a caller namespace. Neither is Terraform's to create, so the tests assert the
  routing configuration round-trips, not that a Nexus call succeeds.
- **That an unlisted caller is rejected.** Same reason: proving it requires making
  a real Nexus call.

## Running the apply tests

```bash
export TEMPORAL_CLOUD_API_KEY="<key for a scratch account>"
terraform init
terraform test -verbose
```

Point them at a scratch account: they create and destroy **real, billable**
namespaces and endpoints.

Without a key, every run block is skipped — a cheap way to confirm the test files
parse:

```text
Failure! 0 passed, 0 failed, 5 skipped.
```

## Cleaning up leftovers

`terraform test` destroys what it created, including after a failed assertion, but
a cancelled or crashed run can orphan resources. The CI workflow therefore runs
`scripts/check-orphans.sh` afterwards — always, including when the tests fail,
since that is when something is most likely to be left behind. It fails the job and
names anything still present, endpoints and namespaces alike:

```bash
scripts/check-orphans.sh
```

Test resources are prefixed so they are identifiable:

| Prefix | Created by |
| --- | --- |
| `yulei-tftest-nxs-<random>` | `*.tftest.hcl`, both the endpoints and their namespaces |
| `yulei-tflocal-*` | `local/`, only if applied by hand — CI never applies it |

Anything matching those prefixes that no live configuration owns can be deleted.
Delete endpoints before the namespaces they route between.

The `examples/` directories are not covered by this prefix; they create
`ex-complete` and `ex-single-caller`. Example code is published to the Terraform
Registry, so it carries no test-specific naming. Check for those separately if you
have applied an example by hand.

[CONTRIBUTING.md](../CONTRIBUTING.md) explains why the layers are split this way
and which API behaviours they guard against.
