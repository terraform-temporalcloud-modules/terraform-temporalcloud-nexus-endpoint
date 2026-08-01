#!/usr/bin/env bash
#
# Fails if the test suite left Nexus endpoints or namespaces behind.
#
# `terraform test` destroys what it created, including after a failed assertion,
# but a cancelled or crashed run can orphan resources and nothing else would
# notice. Run this after the apply tests.
#
# Both kinds are checked: the endpoints this module manages, and the namespaces
# tests/setup creates for them to route between. The namespaces are the more
# expensive thing to leak.
#
# Requires TEMPORAL_CLOUD_API_KEY. Creates nothing — tests/orphan-check contains
# data sources and outputs only.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)/tests/orphan-check"

terraform init -backend=false -no-color >/dev/null
terraform apply -auto-approve -no-color >/dev/null

count="$(terraform output -raw orphan_count)"

if [ "$count" -eq 0 ]; then
  echo "No leftover test resources."
  exit 0
fi

echo "ERROR: $count test resource(s) still present after the suite finished:" >&2
terraform output -json orphans | sed 's/[][",]/ /g' | tr -s ' ' '\n' | sed '/^$/d;s/^/  - /' >&2
echo >&2
echo "These were not destroyed. Delete them in the Temporal Cloud UI, or import and" >&2
echo "destroy them. Delete the endpoints before the namespaces they route between." >&2
exit 1
