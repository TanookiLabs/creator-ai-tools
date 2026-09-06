# Deploy the application

This is a provider-neutral release workflow. Vercel is the repository's exercised example; other hosts are acceptable when they preserve the same build, migration, secret, and verification boundaries.

## Prerequisites

- Tests and review are complete for the exact commit being released.
- The owner has selected and controls the hosting account, domain, production database, and deployment branch.
- Production variables are present in the host's encrypted configuration; values are not stored in Git.

## Ownership

The user or organization owner approves production access, billing, domains, data retention, and rollback. An integration or host is opt-in: repository documentation does not connect it or grant it access.

## Workflow

1. Run `npm ci`, `npm run lint`, `npm run typecheck`, and `npm run build` for the release commit.
2. Review committed Prisma migration SQL and back up material production data according to the owner's policy.
3. Apply migrations once from a controlled release job with `npm run db:migrate`. Never run `db:push` against shared or production data.
4. Configure the host to build with `npm run build` and start with `npm run start`. The build must not mutate the database.
5. Deploy the reviewed commit using the owner-approved branch or immutable commit reference.
6. Record the commit, migration result, deployment URL, verifier, and time without recording secrets.

The existing step-by-step Vercel path remains in the [README](../../README.md) and [Vercel prerequisite guide](../prerequisites/vercel.md).

## Verify

- The host reports a successful build and healthy runtime.
- HTTPS loads at the production `BETTER_AUTH_URL`.
- Sign-up or sign-in, `/dashboard`, `/profile`, and sign-out work with a production-owned test account.
- Runtime logs contain no new errors and the expected migration is recorded.

## If it fails

- Stop promotion and preserve logs with sensitive values redacted.
- For migration failures, do not rerun destructive SQL or `db:push`; diagnose from the committed migration and database state.
- For application failures, roll back to the last verified commit using the host's documented rollback control, then follow [release verification](../../docs/release-verification.md).
