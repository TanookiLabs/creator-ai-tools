# Email/password access boundary

The application uses Better Auth's email/password provider and database-backed
sessions. `/api/auth/[...all]` is the only authentication route handler. The
Next.js proxy performs an optimistic cookie check and the authenticated route
group performs the authoritative server-side session check.

Authentication return destinations are relative application paths. Invalid,
off-site, or authentication-loop callback values fall back to `/dashboard`.
Profile changes use Better Auth's `updateUser` call, which selects the user from
the active session and does not accept a user ID from the browser.

## Environment impact

This flow adds no environment variables. It continues to require:

- `BETTER_AUTH_SECRET`: server-only secret, unique per environment
- `BETTER_AUTH_URL`: canonical public origin for that environment
- `DATABASE_URL`: pooled PostgreSQL runtime connection
- `DIRECT_URL`: direct PostgreSQL migration connection

Keep values in local `.env` and deployment environment settings. Never commit
credentials or expose these values through a `NEXT_PUBLIC_` variable.

## Production origin and secret boundary

For production, retain only variable names in redacted deployment summaries,
tests, or diagnostics—never their values. Reuse an existing healthy
`BETTER_AUTH_SECRET`. For a new project with no secret, generate one locally
and stream it directly to Vercel without displaying or persisting it. Never
rotate an existing secret automatically.

Set `BETTER_AUTH_URL` only after the participant selects and verifies one
canonical HTTPS origin for the selected production Vercel project. It must be
an exact origin (no path, query, fragment, or credentials), not HTTP,
localhost, a preview alias, a generated deployment URL, or an unverified or
mismatched project origin. Any failure to establish that mapping stops the
configuration and subsequent migration/deployment steps.

The experimental assistant-led workflow records these names only and does not
ask for values in chat. The participant handles Vercel identity and any
Marketplace approval; after discovery and validation, the assistant presents
one non-secret production summary and asks once before configuration, migration,
and deployment. After deployment, HTTPS and protected-route observations are
reported concisely with sensitive details redacted. If authentication smoke
verification fails, stop further mutations; a code-only rollback changes only
the application artifact, while database recovery is a separate approved
incident.

## Focused verification

Run `npm run test:auth` for callback safety cases, followed by `npm run lint`,
`npm run typecheck`, and `npm run build`.
