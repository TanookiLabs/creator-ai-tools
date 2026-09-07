# Postgres through Vercel Marketplace (experimental)

For the normal experimental deployment path, connect or reuse Postgres through
Vercel Marketplace. The participant approves any provider agreement and plan;
the assistant does not require a separate Neon login unless Vercel lacks a
specific capability, which it explains first.

The assistant reuses an existing valid integration where possible and avoids
duplicate databases. It maps the pooled runtime connection to `DATABASE_URL`
and the direct migration connection to `DIRECT_URL` without showing either
value. It records and checks names only, retains the direct migration boundary,
and stops rather than guessing the mapping.

After the participant's single final production confirmation, reviewed Prisma
migrations run once before deployment. Never use schema synchronization, reset,
seed, destructive SQL, or retries after a production migration failure.

This path remains experimental until a participant-owned disposable rehearsal
passes.
