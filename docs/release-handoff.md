# Clean-template release handoff

This is the reviewer and operator handoff for a provider-neutral release of
this Next.js 16, Better Auth, Prisma, and PostgreSQL template. It describes the
repository's actual commands. It does **not** authorize a deployment, select a
host or database provider, reset data, or seed records.

## Release invariant

The release is a clean application template: applying the committed Prisma
migrations creates schema and indexes only. It creates no users, shared login,
demo account, sample content, provider connection, webhook, or external
resource. The optional `npm run db:seed:local` command is a guarded local
developer convenience and is never a build, migration, rehearsal, start, or
deployment step.

The repository has no CI workflow and no provider deployment manifest. Until
an owner adds one, a reviewer must run and record the commands below against
the exact commit. A hosting provider must not infer or add a seed command.

## What the owner must supply

The user or organization owner selects and controls the host, public HTTPS
origin, PostgreSQL service, DNS, environment access, backups, logs, retention,
release approval, and rollback mechanism. Store values in the selected host's
encrypted environment configuration, never in Git.

| Variable | Owner-provided requirement | Exposure |
| --- | --- | --- |
| `BETTER_AUTH_SECRET` | Unique high-entropy value for each environment | Server-only secret |
| `BETTER_AUTH_URL` | Exact canonical HTTPS origin (local HTTP is allowed only for local work) | Public configuration |
| `DATABASE_URL` | Runtime PostgreSQL connection for the target environment | Server-only secret |
| `DIRECT_URL` | Direct PostgreSQL connection to the same database, restricted to controlled migrations | Server-only secret |

Variables for AI, payment, email, OAuth, or webhook providers are optional and
must remain absent until the owner explicitly chooses and configures that
integration. `.env.example` is the complete name-only template contract; all
assignments in it must remain empty.

## Reviewer gate (read-only and local build)

From a fresh checkout of the exact candidate commit, with required environment
variables set to an isolated non-production environment where needed:

```bash
npm ci --include=dev
npm run verify:template
npm run lint
npm run typecheck
npm run test:quality
npx prisma validate
npm run build
npm audit --omit=dev
git status --short
```

`verify:template` scans tracked and unignored release-candidate files for
common credential signatures, requires empty `.env.example` assignments, and
proves that `build`, `start`, `verify`, and `db:migrate` contain no seed/reset
operation. The lint, typecheck, `test:quality`, Prisma validation, build, and
production audit are the same checks composed by `npm run verify`.

The final `git status --short` must print nothing in the fresh checkout after
verification. If generated output changes tracked files, or any command fails,
the candidate is not ready. Also review the candidate diff and commit history;
pattern scanning supplements review and does not prove a secret was never
committed. If a real credential is found, stop, have its owner revoke/rotate
it, remove it through the approved history-remediation process, and rerun the
entire gate.

## Clean-schema evidence (isolated rehearsal only)

The static gate does not touch a database. Before first release, the database
owner may provision a new, empty, disposable non-production PostgreSQL database
and follow [the release rehearsal](release-rehearsal.md):

```bash
REHEARSAL_DATABASE_URL='owner-supplied pooled URL' \
REHEARSAL_DIRECT_URL='owner-supplied direct URL' \
REHEARSAL_BASE_URL='http://127.0.0.1:3100' \
REHEARSAL_CONFIRM=I_CONFIRM_NON_PRODUCTION \
bash scripts/rehearse-release.sh
```

The rehearsal refuses a database name outside its explicit pattern, applies
only committed migrations, asserts zero users, builds, and performs logged-out
smoke checks. It never seeds, pushes schema, resets, drops, or deploys. Do not
run it against shared, staging, or production data.

## Deployment sequence (operator-owned; do not run for this handoff)

1. Pin the reviewed commit/artifact and record the prior verified revision.
2. Confirm backups/recovery ownership and review every committed migration.
3. Apply `npm run db:migrate` once in a controlled migration job using the
   target `DIRECT_URL`. Do not use `db:push`, `migrate reset`, or fixtures.
4. Build with `npm run build`, start with `npm run start`, and expose the
   application at the owner-supplied `BETTER_AUTH_URL`. A build must not mutate
   the database.
5. Promote only after the health checks below pass. Record commit, artifact,
   migration IDs, time, verifier, and redacted results—not secret values.

## Health checks

- The process starts and the host reports it ready; `GET /` succeeds over
  HTTPS at the canonical origin.
- Logged-out `GET /dashboard` redirects to `/sign-in` with the requested route
  preserved in `callbackUrl`.
- With a unique, environment-owned verification account (never a shared demo
  login), sign-up/sign-in reaches `/dashboard`; `/profile` saves; sign-out
  restores the protected-route redirect.
- Run the focused participant scenario in
  [release verification](release-verification.md), including duplicate and
  invalid credentials, storage-failure resilience, keyboard operation, and
  1440x900, 768x1024, and 375x812 layouts.
- Confirm expected migration IDs are applied and runtime logs show no new
  application errors, failed requests, leaked credentials, or redirect loops.

## Rollback triggers and boundary

Stop promotion or initiate the owner-approved code rollback when any required
gate fails, the process is unhealthy, `/` fails, auth or protected routing
regresses, migration state is unexpected, participant checks fail, new runtime
errors appear, or secrets appear in artifacts/logs. Treat unexpected rows in a
fresh rehearsal database as a release blocker.

A code rollback redeploys the previously verified artifact and does not change
the database. Never reset, drop, reverse migration SQL, delete users, or seed
records to make rollback pass. If the prior artifact is incompatible with the
current schema, stop and involve the release and database owners for an
approved forward fix or backup/restore incident procedure.

## Required revalidation

After any code, lockfile, configuration, environment, migration, domain/TLS,
or rollback change, rerun the complete reviewer gate and all health checks
against the resulting exact revision/environment. Revalidate after credential
rotation or incident recovery as well. A prior run, a build from another
commit, or a provider's green deployment badge is not transferable evidence.
