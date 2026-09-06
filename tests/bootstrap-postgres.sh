#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
setup="$repo_root/setup.sh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-postgres.XXXXXX")
trap 'rm -rf "$test_root"' EXIT

sed -n '/^# Postgres.app owns its client binaries/,/^# Keep the receipt implementation/p' "$setup" | sed '$d' > "$test_root/functions.sh"
# shellcheck source=/dev/null
source "$test_root/functions.sh"
warn() { printf '%s\n' "$*"; }
info() { printf '%s\n' "$*"; }

POSTGRES_APP_PATH="$test_root/Postgres.app"
mkdir -p "$POSTGRES_APP_PATH/Contents/Versions/17/bin"
cat > "$POSTGRES_APP_PATH/Contents/Versions/17/bin/psql" <<'EOF'
#!/bin/sh
if [ "$1" = --version ]; then
  echo 'psql (PostgreSQL) 17.0'
  exit 0
fi
printf '%s\n' "$*" > "$PSQL_ARGS_FILE"
printf '%s' "${PSQL_RESULT:-1}"
exit "${PSQL_EXIT:-0}"
EOF
chmod +x "$POSTGRES_APP_PATH/Contents/Versions/17/bin/psql"

PSQL_BIN=$(find_postgres_psql)
test "$PSQL_BIN" = "$POSTGRES_APP_PATH/Contents/Versions/17/bin/psql"
export PSQL_ARGS_FILE="$test_root/args"
postgres_connection_ready
grep -F -- '-X -w -d postgres -Atqc select 1' "$PSQL_ARGS_FILE" >/dev/null

export PSQL_RESULT=not-a-query-result
if postgres_connection_ready; then
  echo "A non-connection result incorrectly passed readiness." >&2
  exit 1
fi

export PSQL_EXIT=1 PSQL_RESULT=1
POSTGRES_WAIT_SECONDS=2
POSTGRES_WAIT_INTERVAL=1
wait_output=$(wait_for_postgres_connection 2>&1 || true)
grep -F 'Waiting for a database connection: 0/2 seconds' <<<"$wait_output" >/dev/null
grep -F 'Waiting for a database connection: 1/2 seconds' <<<"$wait_output" >/dev/null

recovery=$(show_postgres_recovery)
grep -F 'Command-Space' <<<"$recovery" >/dev/null
grep -F 'Finder' <<<"$recovery" >/dev/null
grep -F 'Gatekeeper' <<<"$recovery" >/dev/null
grep -F 'Initialize' <<<"$recovery" >/dev/null

grep -F '"Retry the bounded check"' "$setup" >/dev/null
grep -F '"Continue without database readiness"' "$setup" >/dev/null
grep -F '"Stop setup"' "$setup" >/dev/null
if grep -nE 'psql .*password|PGPASSWORD|DATABASE_URL' "$setup"; then
  echo "Credential-bearing database invocation is present." >&2
  exit 1
fi

echo "Bootstrap Postgres.app checks passed."
