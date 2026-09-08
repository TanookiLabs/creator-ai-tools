---
name: deploy-production
description: Deploy this Next.js application to a participant-controlled Vercel production project when they ask to deploy, release, ship, or go live.
---

# Vercel production deployment

This assistant-led path was proven by the live participant-owned `vercel-test-3` Vercel/Neon rehearsal: production reached `READY`, committed migrations applied, canonical HTTPS worked, and browser sign-up, sign-out, sign-in, session persistence, and authenticated dashboard access passed. The canonical path is local `main` → GitHub `main` → Vercel production. The participant starts with “Deploy this application to Vercel” or `/deploy-production`; they never run a repository deployment command or share values in chat.

## Discover and resume

Record `git status --short`, Git root, branch, commit, remotes, Vercel authentication, linked project/team, Postgres integration, production variable names, current deployment, canonical domain, and migration status. Do not restart local development servers. Resume from the first incomplete step.

Classify template `origin`, absent participant repository, or absent Vercel CLI as repairable; unchanged starter as a warning for an explicitly approved production run; Vercel login and Marketplace terms/plan as participant actions. Stop for unexplained dirty work, conflicting repository/name, ambiguous ownership or variable mapping, or failed migration.

Never push to `TanookiLabs/creator-ai-tools`. If it is `origin`, rename it to `template`, set push URL `DISABLED`, then create the participant-owned private repository with `gh repo create <name> --private --source=. --remote=origin --push` before Vercel discovery. The explicit deployment request authorizes this safe private-repository setup. Verify the known owner/URL, remote `main` resolves to the local commit, and make `main` default. Keep old installer branches unless deliberately migrated. On an occupied name/owner, conflicting remote branch, or possible history rewrite, stop.

## Provider and configuration boundaries

The participant completes Vercel login/OAuth and Marketplace agreement or plan choices. Use Vercel Marketplace first, reuse the selected Postgres integration, and avoid duplicate projects/databases. Prefer browser provisioning; do not use `vercel integration add neon` or commands that install agent skills when a non-mutating path exists.

Before provider commands, capture a temporary snapshot with `cleanup-provider-side-effects.sh capture "$PROJECT_ROOT" "$STATE_DIR"`; run its `cleanup` action on completion and EXIT/HUP/INT/TERM. It removes only newly created, untracked `.agents`, `.claude/skills/neon`, `.claude/skills/neon-postgres`, and `skills-lock.json`, restores only an exact provider-added `.env*` gitignore line, and requires final `git status --short` to match the snapshot. Never remove the tracked `.claude/skills/deploy-production` skill. Stop for unrelated or ambiguous changes.

Never print, request, commit, or paste database URLs, secrets, tokens, cookies, or provider output containing them. Inspect and report names only. Never run `vercel env pull` into `.env.local`; if a file is required, use an explicit `mktemp` path outside the project and an EXIT/HUP/INT/TERM removal trap. Preserve any existing `.env.local` and verify the local `.env` database configuration is unchanged.

Identify exactly one Marketplace pooled and one unpooled Neon variable. The migration wrapper maps them to `DATABASE_URL` and `DIRECT_URL` only in its child process; do not create a redundant write-only `DIRECT_URL`. Stop rather than guessing. Reuse a healthy `BETTER_AUTH_SECRET` (or generate and stream a new one without displaying it); never rotate automatically. Keep it write-only/sensitive and scope `BETTER_AUTH_URL` only to the verified canonical HTTPS production origin.

## Validate, confirm, mutate

Run focused tests, lint, type checking, Prisma validation with safe injected configuration, and build checks. Use `npx --yes vercel@latest ...`, never a global install or dependency; record its resolved version in the redacted deployment summary. Confirm migrations are committed and inspect pending state without schema mutation. Warn “This appears to be an unchanged starter application” but continue an explicitly approved production run.

Before Vercel mutations, display one non-secret summary: repository/commit, project, integration, variable names, HTTPS origin, starter warning, and migration status. Ask once: “Continue with the production migration and deployment?” A general affirmative answer authorizes Vercel configuration, reviewed migration, and deployment only.

After confirmation, verify production tracks `main` and the GitHub commit author is associated with the Vercel user. Reconcile schema state, then run once: `npx --yes vercel@latest env run -e production -- bash "$SKILL_DIR/run-production-migration.sh" "$PROJECT_ROOT" "$POOLED_VARIABLE" "$UNPOOLED_VARIABLE" npm run db:migrate`. Resolve `SKILL_DIR` relative to this skill. The wrapper takes project root, discovered names, then command; hides/restores local dotenv files and injects pooled/unpooled values only into Prisma. Do not print, export, or copy values. Never use `prisma db push`, reset, seed, destructive/ad-hoc SQL, migration generation, forced flags, or retry after migration failure.

Trigger one Git-backed production deployment and wait only for a bounded interval. `READY`, `ERROR`, `CANCELED`, and `BLOCKED` are terminal; on non-READY stop without retry and report deployment ID, dashboard URL, and provider reason without filtering errors.

## Verify and stop

Verify READY, canonical HTTPS, no missing-variable/database logs, read-only database access, Better Auth tables, protected-route redirect, and—only with participant approval—sign-up, sign-out, sign-in, session persistence, and authenticated pages. On any failure, make no further provider/database mutation; give a concise redacted summary and ask how to proceed. Do not add a deployment dependency or public deployment script.
