#!/bin/bash
set -euo pipefail

# Source only from the deployment skill after its final confirmation. This keeps
# local dotenv files unavailable while Vercel injects the production variables.
if [[ $# -lt 4 ]]; then
  echo "Usage: $0 PROJECT_ROOT POOLED_VARIABLE DIRECT_VARIABLE COMMAND..." >&2
  exit 64
fi

root="$1"
pooled_variable="$2"
direct_variable="$3"
shift 3
if [[ ! "$pooled_variable" =~ ^[A-Za-z_][A-Za-z0-9_]*$ || ! "$direct_variable" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  echo "The selected Neon variable names are invalid." >&2
  exit 64
fi
if [[ -z "${!pooled_variable:-}" || -z "${!direct_variable:-}" ]]; then
  echo "The selected Neon pooled or direct variable is unavailable in the production environment." >&2
  exit 1
fi
staged=()
restore() {
  local item
  for item in "${staged[@]}"; do
    [[ -e "${item}.deploy-production-hidden" ]] && mv "${item}.deploy-production-hidden" "$item"
  done
}
trap restore EXIT HUP INT TERM
for item in "$root/.env" "$root/.env.local"; do
  if [[ -f "$item" ]]; then
    mv "$item" "${item}.deploy-production-hidden"
    staged+=("$item")
  fi
done
cd "$root"
env -u DATABASE_URL -u DIRECT_URL -u BETTER_AUTH_URL -u BETTER_AUTH_SECRET \
  DATABASE_URL="${!pooled_variable}" DIRECT_URL="${!direct_variable}" "$@"
