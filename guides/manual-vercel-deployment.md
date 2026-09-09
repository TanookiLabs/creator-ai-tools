# Manual Vercel deployment

Use this guide when you want to deploy this Next.js, Prisma, and Better Auth
application yourself instead of using the assistant-led deployment workflow.
It uses a private GitHub repository connected to Vercel, Vercel Marketplace
Postgres, and the production `main` branch. You approve all account, billing,
Marketplace, and domain actions yourself.

The normal ongoing path is:

```text
local main → GitHub main → Vercel production
```

Do not treat `npm run build` or an arbitrary Git push as a successful
production release. The steps below deliberately separate validation,
production configuration, migration, deployment, and smoke checks.

## Before you start

- Complete the [manual macOS setup](../prerequisites/manual-macos-setup.md),
  or the automated installer.
- Use a clean, independent project repository on `main`. Its `origin` must be
  your private GitHub repository—not `TanookiLabs/creator-ai-tools`.
- Have accounts for GitHub and Vercel. The Vercel account must be able to
  install Marketplace integrations and create projects.
- Review all pending application and migration changes. A production migration
  must already be committed; never create one as part of deployment.

From the project root, confirm the repository and application are ready:

```bash
git branch --show-current
git status --short
npm run verify
```

Continue only when the branch is `main`, the worktree contains only intended
changes, and `npm run verify` succeeds. Commit reviewed changes:

```bash
git add <reviewed-files>
git commit -m "Describe the reviewed change"
```

Never commit `.env`, `.env.local`, `.vercel`, database URLs, secrets, or
installer handoff files. Keep the committed `main` revision local until step
6 if it depends on the production configuration you set below. The initial
repository revision must already be on GitHub so Vercel can import it.

## 1. Create or import the Vercel project

1. Sign in at [Vercel](https://vercel.com).
2. Select **Add New** → **Project**.
3. Import your private GitHub repository. Authorize the GitHub connection only
   for the account or organization that should own the project.
4. Confirm Vercel recognizes **Next.js** and the repository root is the app
   root. Do not add a custom build command; this project’s normal build is
   `npm run build`.
5. Set the production branch to `main` in the project’s Git settings.
6. Open **Settings** → **Domains** and choose one canonical HTTPS production
   origin. The Vercel-provided `.vercel.app` domain is fine initially; add a
   custom domain only after you can update its DNS records.

Importing a Git repository makes pushes to the production branch create
production deployments; other branches create previews. See Vercel’s
[project management guide](https://vercel.com/docs/projects/managing-projects)
and [environment overview](https://vercel.com/docs/environment-variables).

## 2. Create the production database

1. In the Vercel project, open **Storage** or **Integrations** and select the
   [Neon Marketplace integration](https://vercel.com/marketplace/neon).
2. Create or connect one database for this project. Review the provider’s plan
   and billing terms before approval.
3. Connect it to the **Production** environment. Do not create a second
   database only to retry a failed configuration.
4. In the Vercel project’s environment-variable screen, record the *names*
   that Neon supplied for its pooled runtime connection and unpooled/direct
   migration connection. Do not copy their values into chat, a commit, or a
   local file.

The Marketplace integration injects its connection credentials as Vercel
environment variables. If its names are not clearly identified as one pooled
and one direct connection, stop and inspect the integration’s dashboard/help
before continuing. Do not guess from a connection string.

## 3. Set production environment variables

In **Settings** → **Environment Variables**, add these variables for
**Production only**:

| Name | Value and purpose |
| --- | --- |
| `DATABASE_URL` | The Neon pooled runtime connection for this production database. |
| `DIRECT_URL` | The Neon unpooled/direct connection for migrations on the same database. |
| `BETTER_AUTH_SECRET` | A new, unique server secret for this production environment. Mark it sensitive/write-only when Vercel offers that option. |
| `BETTER_AUTH_URL` | The exact canonical HTTPS origin selected in step 1, with no path, query, fragment, or trailing slash. |

Use the marketplace/provider interface to copy the pooled and direct values
into the first two variables yourself. Do not use `NEXT_PUBLIC_` for any of
these values, and do not add production values to `.env` or `.env.local`.

Generate the Better Auth secret locally and paste its output directly into the
Vercel form. The value is shown only in your terminal; do not save it in a
document or send it to another person:

```bash
openssl rand -base64 32
```

Use `vercel env ls production` to confirm variable *names* are present. Do not
use `vercel env pull .env.local` for production: it would leave production
credentials in a local file that Next.js prioritizes over `.env`.

## 4. Install the Vercel CLI temporarily and link the project

The guide uses an ephemeral CLI, so it adds neither a project dependency nor a
global machine installation. From the project root:

```bash
npx --yes vercel@latest login
npx --yes vercel@latest link
npx --yes vercel@latest env ls production
```

Complete browser login yourself. During `link`, choose the Vercel project you
imported in step 1. It creates the ignored `.vercel/` directory; do not commit
it. When you need to run a local command with Vercel values without writing
them to a file, use `vercel env run`, for example:

```bash
npx --yes vercel@latest env run -e production -- npm run build
```

That command is for a configuration check only; it does not migrate or deploy.
Do not leave a local development server using production database values.

## 5. Review and apply the production migration once

Read the pending, committed SQL in `prisma/migrations/` and the
[Prisma migration lifecycle](../../docs/prisma-migrations.md). Confirm you
have the intended Vercel project, one database, a recovery owner, and exactly
the production variable names from step 3.

The project’s isolation wrapper keeps local `.env` and `.env.local` unavailable
while Vercel injects the production values. Run this command once from the
project root:

```bash
SKILL_DIR="$(pwd)/.claude/skills/deploy-production"
PROJECT_ROOT="$(pwd)"
npx --yes vercel@latest env run -e production -- bash \
  "$SKILL_DIR/run-production-migration.sh" "$PROJECT_ROOT" \
  DATABASE_URL DIRECT_URL npm run db:migrate
```

The wrapper restores your local files after success, failure, or interruption.
It does not print connection values. If you named the Vercel variables
differently, stop and either map them to the required names in Vercel or use
the exact known pooled and direct names as the two wrapper arguments. Never use
`npm run db:push`, `prisma migrate reset`, seed commands, ad-hoc SQL, or a retry
after a production migration failure.

## 6. Deploy production

For the Git-connected workflow, ensure the migration has succeeded, then push
the reviewed `main` commit:

```bash
git push origin main
```

Open the Vercel project dashboard and wait for the production deployment to
reach **READY**. `ERROR`, `CANCELED`, and `BLOCKED` are failures: inspect the
deployment details and logs, make no further database mutation, and fix the
reported cause before a later deliberate release.

If you intentionally use a CLI deploy instead of Git integration, deploy only
the linked project from its root:

```bash
npx --yes vercel@latest deploy --prod
```

The CLI deployment route is an alternative—not an extra deployment after the
Git push. Vercel documents both the [CLI deployment flow](https://vercel.com/docs/projects/deploy-from-cli)
and [`vercel deploy --prod`](https://vercel.com/docs/cli/deploy).

## 7. Verify the live application

1. Open the canonical HTTPS origin in a private browser window.
2. Confirm the home page loads and `/dashboard` redirects an anonymous visitor
   to `/sign-in`.
3. With a unique production verification account you control, test sign-up,
   sign-out, sign-in, session persistence after a page reload, and access to
   `/dashboard` and `/profile`.
4. In Vercel, inspect the production deployment logs for missing-variable or
   database errors. Do not copy log lines containing values into tickets or
   chat.
5. Confirm the local project is still clean apart from your original work:

   ```bash
   git status --short
   ```

## If something fails

- **Vercel cannot access GitHub:** repair the repository connection in Vercel;
  do not change a participant-owned GitHub repository into the template.
- **Variable mapping is unclear:** stop. Verify which Neon value is pooled and
  which is direct in the integration/provider interface before changing Vercel.
- **Migration fails:** stop all deployment retries and database changes. Preserve
  the failure details, involve the database owner, and use the approved recovery
  process. A code rollback does not roll back database schema/data.
- **Auth fails after a READY deployment:** confirm `BETTER_AUTH_URL` exactly
  matches the selected canonical HTTPS origin and that the secret is present in
  Production. Do not rotate a healthy secret automatically.
- **A local `.env.local` appears with Vercel values:** stop using it, remove only
  the generated file after confirming it was not participant-owned, and restore
  your local `.env` configuration. Future checks should use `vercel env run`.
