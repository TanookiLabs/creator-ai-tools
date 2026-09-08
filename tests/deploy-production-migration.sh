#!/bin/bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/deploy-migration.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
printf 'DATABASE_URL=postgresql://localhost/unsafe\n' > "$test_root/.env"
printf 'DIRECT_URL=postgresql://localhost/unsafe\n' > "$test_root/.env.local"
output=$(POOLED_URL='postgresql://pooled/secret' DIRECT_URL='postgresql://direct/secret' \
  "$repo_root/.claude/skills/deploy-production/run-production-migration.sh" "$test_root" POOLED_URL DIRECT_URL /bin/sh -c 'test ! -e .env && test ! -e .env.local && test "$DATABASE_URL" = "postgresql://pooled/secret" && test "$DIRECT_URL" = "postgresql://direct/secret"')
test -z "$output"
test -f "$test_root/.env"
test -f "$test_root/.env.local"
grep -Fx 'DATABASE_URL=postgresql://localhost/unsafe' "$test_root/.env" >/dev/null
if POOLED_URL=pooled DIRECT_URL=direct "$repo_root/.claude/skills/deploy-production/run-production-migration.sh" "$test_root" POOLED_URL DIRECT_URL /bin/sh -c 'test ! -e .env && exit 23'; then
  echo "Migration wrapper masked a failed command." >&2
  exit 1
else
  test "$?" -eq 23
fi
test -f "$test_root/.env"
test -f "$test_root/.env.local"
grep -Fx 'DATABASE_URL=postgresql://localhost/unsafe' "$test_root/.env" >/dev/null
rm "$test_root/.env.local"
POOLED_URL=pooled DIRECT_URL=direct "$repo_root/.claude/skills/deploy-production/run-production-migration.sh" "$test_root" POOLED_URL DIRECT_URL /bin/sh -c 'exit 0'
test ! -e "$test_root/.env.local"
grep -Fx 'DATABASE_URL=postgresql://localhost/unsafe' "$test_root/.env" >/dev/null
POOLED_URL=pooled DIRECT_URL=direct "$repo_root/.claude/skills/deploy-production/run-production-migration.sh" "$test_root" POOLED_URL DIRECT_URL /bin/sh -c 'kill -TERM "$PPID"' || true
test ! -e "$test_root/.env.local"
if POOLED_URL=pooled "$repo_root/.claude/skills/deploy-production/run-production-migration.sh" "$test_root" POOLED_URL DIRECT_URL /bin/true; then
  echo "Migration wrapper accepted a missing direct variable." >&2
  exit 1
fi
echo "Production migration isolation checks passed."
