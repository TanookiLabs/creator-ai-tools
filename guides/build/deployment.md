# Experimental Vercel deployment

This is the experimental assistant-led path for deploying this Next.js,
Prisma, and Better Auth application. It becomes supported only after a live
disposable participant-owned Vercel and Postgres rehearsal succeeds.

Ask: **“Deploy this application to Vercel.”** The assistant rediscovers the
repository, Vercel project, Postgres integration, production variable names,
canonical domain, and migration state on every run. It never relies on a prior
attempt as evidence that an action completed.

If the starter template is still `origin`, the assistant treats it as a
repairable setup issue: it makes the template fetch-only, creates a private
participant repository after the final authorization, and never pushes to the
template. An unchanged starter is shown as a warning but may proceed for an
explicitly approved disposable rehearsal. Discovery never restarts a local dev
server, and Vercel commands use ephemeral `npx --yes vercel@latest` rather
than a global installation.

The participant controls Vercel login/OAuth, Marketplace provider terms and
plan selection, and one final confirmation after seeing the repository, commit,
project, database integration, variable names, HTTPS origin, and migration
status. Database URLs and secret values never appear in chat. Vercel
Marketplace is the normal database boundary; use a separate Neon login only if
Vercel cannot provide a necessary capability.

Builds do not change the database. The assistant reuses existing configuration
where safe, maps pooled and direct connections to `DATABASE_URL` and
`DIRECT_URL` without displaying values, and uses the verified canonical HTTPS
origin for `BETTER_AUTH_URL`. After final approval, it applies reviewed Prisma
migrations once and deploys the reviewed commit. It never uses `db:push`, reset,
destructive SQL, or an improvised retry.

Then it verifies deployment readiness, HTTPS, database access, Better Auth
tables, anonymous protected-route redirects, and sign-up behavior. A failure
stops further mutations and receives a concise redacted summary; ask the
participant how to proceed. A code-only rollback may redeploy a compatible
artifact, while database recovery is a separate owner-approved incident.
