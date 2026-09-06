# Prisma migration lifecycle

`prisma/schema.prisma` remains the source of truth. This project uses two deliberately separate ways to apply it:

| Purpose | Command | Where it is allowed |
| --- | --- | --- |
| Fast prototype synchronization | `npm run db:push` | Disposable/local development databases only |
| Apply reviewed, committed migrations | `npm run db:migrate` | Staging and production deployment step |
| Create and review the next migration | `npm run db:migrate:dev -- --name describe_change` | A development database after editing the schema |

`npm run build` runs only `prisma generate` and `next build`; it never changes a database. Run `npm run db:migrate` as a distinct, explicit deployment command after the migration SQL has been reviewed and committed.

There are intentionally no reset or force-reset commands in `package.json`. Do not add destructive database operations to build, deploy, or routine development scripts.

## Connection URLs

- `DATABASE_URL` is the runtime URL. For Neon, use the pooled connection URL; the application and Prisma Client use it for normal queries.
- `DIRECT_URL` is the direct, non-pooled URL. Prisma Migrate uses it for migration and baseline operations that need a stable direct PostgreSQL connection.

Both values are required in the environment for this schema. Keep them pointed at the same database/branch; use separate values for development, staging, and production.

## Better Auth baseline

`prisma/migrations/20260902000000_better_auth_baseline/migration.sql` is the reviewed initial state for the existing Better Auth tables: `user`, `session`, `account`, and `verification`. It preserves the model/table mappings and cascade relations used by `lib/auth.ts`.

For a brand-new empty database, deploy it normally:

```bash
npm run db:migrate
```

For an existing database previously initialized through `db:push`, rehearse the adoption on a populated development or staging clone first. These steps do not delete accounts, sessions, or auth records.

1. Take a normal database backup/snapshot and confirm `DATABASE_URL` and `DIRECT_URL` target the rehearsal clone.
2. Check that the live schema matches the Prisma schema. This command is read-only and exits with code `2` when it finds a difference:

   ```bash
   npx prisma migrate diff --from-url "$DIRECT_URL" --to-schema-datamodel prisma/schema.prisma --exit-code
   ```

3. If—and only if—the check reports no difference, record the committed baseline as already applied. This writes only Prisma's migration-history row; it does not execute the baseline SQL or modify auth data:

   ```bash
   npx prisma migrate resolve --applied 20260902000000_better_auth_baseline
   ```

4. Rehearse the normal production command. It should report that there are no pending migrations:

   ```bash
   npm run db:migrate
   ```

5. Verify existing sign-in/session behavior and confirm the `_prisma_migrations` row for the baseline exists before repeating the same procedure on production.

If the schema comparison finds drift, stop. Reconcile the drift in a reviewed migration or update the baseline through review; do not use `db push`, `migrate reset`, or a force-reset command against the populated database.
