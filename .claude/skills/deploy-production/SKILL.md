---
name: deploy-production
description: Experimentally deploy this Next.js application to a participant-controlled Vercel production project when they ask to deploy, release, ship, or go live.
---

# Experimental Vercel deployment

This is an experimental, assistant-led production workflow. It is not a
promise that a provider integration or CLI flow has been rehearsed successfully.
The participant can start with “Deploy this application to Vercel” or
`/deploy-production`; they do not run a repository deployment command or copy
database URLs or secret values into chat.

## Discover and resume

At the beginning of every invocation, rediscover Git root, branch, commit,
working-tree status, remotes, Vercel authentication, linked project/team,
Postgres integration, production variable names, current production deployment,
canonical domain, and migration status where that can be checked safely. Do not
assume a prior command completed. Resume from the first incomplete step.

Before a provider mutation, confirm the writable `origin` is not
`TanookiLabs/creator-ai-tools`, identify the participant repository, report the
branch and full commit, and stop for unexplained working-tree changes. A
read-only `template` remote is allowed; never push participant work to it.

## Participant-controlled actions

The participant personally completes Vercel browser login/OAuth and any
Marketplace provider agreement or plan choice. Use Vercel Marketplace first to
reuse or connect one Postgres integration; do not require a separate Neon login
unless Vercel cannot expose a necessary capability, and explain that gap first.
Avoid duplicate projects or databases.

Never print, request, commit, or paste database URLs, auth secrets, tokens,
cookies, or provider output containing them. Inspect and report variable names
only. Map the integration's pooled and direct values to `DATABASE_URL` and
`DIRECT_URL` without exposing either value; stop rather than guessing. Reuse an
existing healthy `BETTER_AUTH_SECRET`; for a new project the assistant may
generate it locally and stream it directly to Vercel without displaying it.
Never rotate an existing secret automatically. Set `BETTER_AUTH_URL` only to a
verified canonical HTTPS production origin belonging to the selected project.

## Validate, confirm, mutate

Run focused tests, lint, type checking, Prisma validation with safe injected
configuration, and build checks appropriate to the change. Confirm migration
files are committed and determine pending migrations without changing schema.

Before mutations, show one concise non-secret summary: repository and commit,
Vercel project, Postgres integration, configured variable names, canonical
production URL, and migration status. Ask once: “Continue with the production
migration and deployment?” A general affirmative answer is sufficient.

After confirmation, run the reviewed migration once through the selected
Vercel project's production environment, then deploy the reviewed commit. The
rehearsal assumption is `vercel env run -e production -- npm run db:migrate`;
verify that exact CLI behavior during the disposable rehearsal before treating
it as supported. Do not print, export, or copy production values while running
it. Never use `prisma db push`, reset, destructive SQL, migration generation,
forced deployment flags, or a retry/improvised repair after migration failure.

## Verify and stop

Verify the deployment is ready, canonical HTTPS responds, logs have no missing
variable or database errors, the database accepts a read-only query, expected
Better Auth tables exist, anonymous protected routes redirect to sign-in, and
sign-up reaches the application without origin or missing-table errors. Do not
create an account without participant approval.

On migration, deployment, or smoke failure, make no further provider or
database mutation. Give a concise redacted failure summary and ask the
participant how to proceed. Record the resolved Vercel CLI version in the
disposable rehearsal report; do not add a deployment dependency or public
deployment script to this repository.
