# Changelog

All notable changes to this project will be documented in this file.

## [2.0.1](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/compare/v2.0.0...v2.0.1) (2026-08-03)

### Documentation

* Pin the examples to v2 ([163ac23](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/commit/163ac23e9231c2f52fe1a40f9eda27bdef30e5fa))

### Tests

* Coalesce null data source lists in the orphan check ([#1](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/issues/1)) ([f681fd6](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/commit/f681fd6530288ef6a3db4a37fc20d3dd0fb015e7))

## [2.0.0](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/compare/v1.0.4...v2.0.0) (2026-08-01)

### ⚠ BREAKING CHANGES

* name, worker_target and allowed_caller_namespaces no longer
have defaults. A module call that sets create_nexus_endpoint = false must now
pass them explicitly.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

### Features

* Require the inputs the provider requires ([5008d82](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/commit/5008d82cbcdbe48d0f90cf0d2fd00da9c5a0a475))

## [1.0.4](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/compare/v1.0.3...v1.0.4) (2026-08-01)

### Documentation

* Trim the validate explanation to what a consumer needs ([738f9dd](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/commit/738f9ddf61a9c99af5c147b1ada6b9a30788c63c))

## [1.0.3](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/compare/v1.0.2...v1.0.3) (2026-08-01)

### Documentation

* Drop the badge explanation from the README ([1e2aee3](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/commit/1e2aee398de4c92acd72235a3d277bc64001b325))

## [1.0.2](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/compare/v1.0.1...v1.0.2) (2026-08-01)

## [1.0.1](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/compare/v1.0.0...v1.0.1) (2026-08-01)

### Bug Fixes

* Mark the wrapper output sensitive and null-guard the description ([79549ba](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/commit/79549ba3eb2fe411ce1baec6a6941a33e8d7303f))

## 1.0.0 (2026-08-01)

### Features

* Initial nexus-endpoint module ([e82c7fe](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/commit/e82c7fea463c24509c40beebd6f11540fc977e0a))
