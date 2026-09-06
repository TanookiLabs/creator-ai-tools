#!/usr/bin/env bash

# Rehearse a release on a NEW, explicitly named non-production PostgreSQL
# database. This script never runs db:push, migrate reset, or seed commands.
set -euo pipefail

if [[ "${REHEARSAL_CONFIRM:-}" != "I_CONFIRM_NON_PRODUCTION" ]]; then
  echo "Stopping: set REHEARSAL_CONFIRM=I_CONFIRM_NON_PRODUCTION after confirming both URLs target the isolated rehearsal database." >&2
  exit 1
fi

for required in REHEARSAL_DATABASE_URL REHEARSAL_DIRECT_URL REHEARSAL_BASE_URL; do
  if [[ -z "${!required:-}" ]]; then
    echo "Stopping: $required is required." >&2
    exit 1
  fi
done

database_name="${REHEARSAL_DIRECT_URL%%\?*}"
database_name="${database_name##*/}"
if [[ ! "$database_name" =~ ^release_rehearsal_[0-9]{8}_[0-9]{6}$ ]]; then
  echo "Stopping: rehearsal database name must be release_rehearsal_YYYYMMDD_HHMMSS." >&2
  exit 1
fi

export DATABASE_URL="$REHEARSAL_DATABASE_URL"
export DIRECT_URL="$REHEARSAL_DIRECT_URL"
export BETTER_AUTH_URL="$REHEARSAL_BASE_URL"

echo "1/6 Validating reviewed dependency lock and Prisma schema"
# Build tooling such as Tailwind lives in devDependencies. Include it explicitly
# so a machine-level npm `dev=false` setting cannot produce a partial artifact.
npm ci --include=dev
npx prisma validate

echo "2/6 Applying committed migrations to $database_name"
npm run db:migrate

echo "3/6 Verifying migration state, auth schema, indexes, and zero users"
npx prisma migrate status
schema_and_indexes=$(psql "$DIRECT_URL" --tuples-only --no-align --command "
  SELECT (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('user', 'session', 'account', 'verification'))
       || ':' ||
         (SELECT count(*) FROM pg_indexes WHERE schemaname = 'public' AND tablename IN ('user', 'session', 'account', 'verification'))
       || ':' ||
         (SELECT count(*) FROM \"user\");")

if [[ "$schema_and_indexes" != 4:*:0 ]]; then
  echo "Stopping: expected 4 auth tables, one or more indexes, and zero users; got $schema_and_indexes." >&2
  exit 1
fi
echo "Schema evidence (tables:indexes:users): $schema_and_indexes"

echo "4/6 Building the deploy artifact (build never mutates the database)"
npm run build

echo "5/6 Starting the artifact and running unauthenticated smoke checks"
port="${REHEARSAL_PORT:-3100}"
PORT="$port" npm run start >"/tmp/release-rehearsal-$database_name.log" 2>&1 &
server_pid=$!
cleanup() { kill "$server_pid" 2>/dev/null || true; }
trap cleanup EXIT

for attempt in {1..30}; do
  if curl --fail --silent --show-error "http://127.0.0.1:$port/" >/dev/null; then break; fi
  sleep 1
  if [[ "$attempt" == 30 ]]; then
    echo "Stopping: deploy artifact did not become ready; see /tmp/release-rehearsal-$database_name.log." >&2
    exit 1
  fi
done

curl --fail --silent --show-error "http://127.0.0.1:$port/" >/dev/null
dashboard_headers=$(curl --silent --show-error --output /dev/null --write-out '%{http_code} %{redirect_url}' "http://127.0.0.1:$port/dashboard")
if [[ "$dashboard_headers" != 307\ *"/sign-in"* && "$dashboard_headers" != 302\ *"/sign-in"* ]]; then
  echo "Stopping: unauthenticated dashboard did not redirect to sign-in; got: $dashboard_headers" >&2
  exit 1
fi

echo "6/6 Passed: clean schema, zero demo users, deploy artifact, and smoke checks"
echo "Evidence: database=$database_name; dashboard_redirect=$dashboard_headers"
