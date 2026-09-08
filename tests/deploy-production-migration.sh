#!/bin/bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/deploy-migration.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
printf 'DATABASE_URL=postgresql://localhost/unsafe\n' > "$test_root/.env"
printf 'DIRECT_URL=postgresql://localhost/unsafe\n' > "$test_root/.env.local"
"$repo_root/.claude/skills/deploy-production/run-production-migration.sh" "$test_root" /bin/sh -c 'test ! -e .env && test ! -e .env.local && test -z "${DATABASE_URL:-}" && test -z "${DIRECT_URL:-}"'
test -f "$test_root/.env"
test -f "$test_root/.env.local"
if "$repo_root/.claude/skills/deploy-production/run-production-migration.sh" "$test_root" /bin/sh -c 'test ! -e .env && exit 23'; then
  echo "Migration wrapper masked a failed command." >&2
  exit 1
else
  test "$?" -eq 23
fi
test -f "$test_root/.env"
test -f "$test_root/.env.local"
echo "Production migration isolation checks passed."
