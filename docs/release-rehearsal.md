# Non-production release rehearsal

This runbook rehearses a dependency-locked release without changing a live
instance, deleting auth data, or adding host-specific configuration to the
application. It is for a fresh PostgreSQL database or branch created solely
for the rehearsal.

## Preconditions and stopping conditions

1. Create a new, empty non-production database named
   `release_rehearsal_YYYYMMDD_HHMMSS`. Do not reuse the local development,
   shared staging, or production database.
2. Confirm that its direct and pooled connection URLs point to that exact
   database. Do not paste URLs, credentials, tokens, or secret values into the
   terminal transcript, ticket, chat, or evidence file.
3. Stop immediately if the database name does not have that exact rehearsal
   prefix, if a URL points to a live/shared environment, or if the database is
   not empty. Escalate to the release owner and database owner; do not use
   `db:push`, `migrate reset`, a force-reset, or a delete command as a remedy.
4. Review `package-lock.json` and all committed SQL in `prisma/migrations/`.
   Stop if either has unreviewed changes or if `npm ci`/`prisma validate`
   fails.

## Rehearsal command

The following is the only executable workflow. It applies reviewed migrations
explicitly with `prisma migrate deploy`; it intentionally does **not** run the
development fixture command. A clean migrated schema must have zero users.

```bash
export REHEARSAL_DATABASE_URL='pooled URL for the new rehearsal database'
export REHEARSAL_DIRECT_URL='direct URL for the same rehearsal database'
export REHEARSAL_BASE_URL='http://127.0.0.1:3100'
export REHEARSAL_CONFIRM=I_CONFIRM_NON_PRODUCTION
bash scripts/rehearse-release.sh
```

The script installs all lockfile dependencies, including build-time
`devDependencies`, validates Prisma, applies the baseline
and follow-up migration, checks the migration history, verifies all four auth
tables and their indexes, confirms `user` has zero rows, builds the Next.js
artifact, starts it locally, and verifies `/` plus the logged-out `/dashboard`
redirect. The server log is retained under `/tmp` for failed smoke checks.

Stop and escalate if migration status is not up to date, the schema/index/user
count check fails, the artifact does not start, `/` is not successful, or the
dashboard does not redirect to `/sign-in`. Record command exit status, commit
SHA, migration IDs, the redacted database name, and smoke output only.

## Manual authenticated smoke

In a private browser session against the rehearsal URL, create a unique
`@example.test` account through `/sign-up`, verify `/dashboard`, sign out, and
confirm the protected-route redirect. This is a verification account, not a
fixture. Do not run `npm run db:seed:local`; it is reserved for local
development fixtures and would violate the clean-schema assertion.

## Deploy and rollback boundary

For a production release, run the reviewed migration as a separate controlled
job against the target environment's `DIRECT_URL`, then deploy the already
verified code artifact. The application build itself does not mutate the
database.

A **code-only rollback** returns the deployment to the previously verified
artifact/revision and repeats the smoke suite. It never resets, drops, or
rolls back the database. Stop and escalate if the prior artifact is
incompatible with the now-current schema.

**Database recovery is a separate incident procedure.** It requires the
database owner, an approved backup/restore or forward-fix plan, impact review,
and explicit confirmation before any data-changing recovery work. Do not
combine it with a code rollback and never delete existing authentication data
to make a rollback succeed.

## Evidence and escalation

Before publishing release evidence, redact userinfo/query strings in database
URLs, authentication secrets, API tokens, cookies, and authorization headers.
Have the release owner confirm the target environment and the rollback
revision before migration or deployment. Escalate migration drift, a failed
backup/restore check, authentication failures, unexpected user rows, failed
smoke checks, or any uncertainty about environment ownership to the release
owner, database owner, and security/on-call contact.

This document and script use portable npm, Prisma, PostgreSQL, curl, and
Next.js commands only; no AllSpark runtime configuration is committed upstream.

## Recorded rehearsal evidence — 2026-09-02

Target: isolated local database `release_rehearsal_20260902_141245` (no
connection URL or credential retained). The database was newly provisioned and
was not reset, dropped, seeded, or otherwise cleaned during this rehearsal.

| Check | Result |
| --- | --- |
| Locked dependency installation | Passed with `npm ci --include=dev` |
| Migration baseline | Passed: `20260902000000_better_auth_baseline` and `20260902000100_add_better_auth_account_issuer` applied with `npm run db:migrate` |
| Clean schema | Passed: 4 auth tables, 9 indexes, and 0 `user` rows |
| Deploy artifact | Passed: `npm run build` completed |
| Smoke suite | Passed: `/` returned 200; logged-out `/dashboard` returned 307 to `/sign-in` |
| Static release gate | Passed: lint, TypeScript, Prisma validation, build, and `npm audit --omit=dev` (0 production vulnerabilities) |
| Code-only rollback rehearsal | Procedure verified: redeploy the prior verified artifact, rerun the smoke suite, and leave the rehearsal database unchanged |

Initial stopping condition observed: the host npm configuration had `dev=false`,
which made a plain `npm ci` omit the already locked Tailwind build packages and
caused the build to stop. The runbook now uses `npm ci --include=dev`; after
that explicit dependency install, the build and smoke checks passed. The npm
install reported five dependency advisories (two low, three high); that output
is retained as release evidence for owner review and does not change the
successful migration/smoke result.
