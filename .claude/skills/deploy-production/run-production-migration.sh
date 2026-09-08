#!/bin/bash
set -euo pipefail

# Source only from the deployment skill after its final confirmation. This keeps
# local dotenv files unavailable while Vercel injects the production variables.
root="$1"
shift
staged=()
restore() {
  local item
  for item in "${staged[@]}"; do mv "${item}.deploy-production-hidden" "$item"; done
}
trap restore EXIT HUP INT TERM
for item in "$root/.env" "$root/.env.local"; do
  if [[ -f "$item" ]]; then
    mv "$item" "${item}.deploy-production-hidden"
    staged+=("$item")
  fi
done
cd "$root"
env -u DATABASE_URL -u DIRECT_URL -u BETTER_AUTH_URL -u BETTER_AUTH_SECRET "$@"
