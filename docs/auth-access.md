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

## Focused verification

Run `npm run test:auth` for callback safety cases, followed by `npm run lint`,
`npm run typecheck`, and `npm run build`.
