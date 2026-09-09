# Vercel deployment

This is the assistant-led path for deploying this Next.js, Prisma, and Better
Auth application. The live participant-owned `vercel-test-3` Vercel/Neon
rehearsal reached READY, applied migrations, served canonical HTTPS, and passed
browser sign-up, sign-out, sign-in, session persistence, and dashboard access.

To run the equivalent Vercel setup and deployment yourself, follow
[Manual Vercel deployment](../manual-vercel-deployment.md).

Ask: **“Deploy this application to Vercel.”** The assistant rediscovers the
repository, Vercel project, Postgres integration, production variable names,
canonical domain, and migration state on every run. It never relies on a prior
attempt as evidence that an action completed.

If the starter template is still `origin`, the assistant treats it as a
repairable setup issue: the explicit request to deploy authorizes it to make
the template fetch-only and create/verify a private participant repository
before Vercel discovery. It never pushes to the template or overwrites a
conflicting remote branch. An unchanged starter is shown as a warning but may
proceed for an explicitly approved production run. Discovery never
restarts a local dev server, and Vercel commands use ephemeral
`npx --yes vercel@latest` rather than a global installation.

The participant controls Vercel login/OAuth, Marketplace provider terms and
plan selection, and one final confirmation after seeing the repository, commit,
project, database integration, variable names, HTTPS origin, and migration
status. Database URLs and secret values never appear in chat. Vercel
Marketplace is the normal database boundary; use a separate Neon login only if
Vercel cannot provide a necessary capability.

Builds do not change the database. The assistant reuses existing configuration
where safe, maps discovered Neon pooled and unpooled variables to `DATABASE_URL`
and `DIRECT_URL` only for the isolated migration without displaying values, and uses the verified canonical HTTPS
origin for `BETTER_AUTH_URL`. After final approval, it applies reviewed Prisma
migrations once and deploys the reviewed commit. It never uses `db:push`, reset,
destructive SQL, or an improvised retry. Provider-created agent artifacts and
temporary environment files are removed without changing participant files.

Then it verifies deployment readiness, HTTPS, database access, Better Auth
tables, anonymous protected-route redirects, and sign-up behavior. A failure
stops further mutations and receives a concise redacted summary; ask the
participant how to proceed. A code-only rollback may redeploy a compatible
artifact, while database recovery is a separate owner-approved incident.
