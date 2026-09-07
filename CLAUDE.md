# Project instructions

This is an npm-managed Next.js 16 App Router application using TypeScript,
React 19, Tailwind CSS, shadcn/ui, Better Auth, Prisma 6, and PostgreSQL. Read
the version-matched Next.js guidance in `node_modules/next/dist/docs/` before
changing framework behavior.

## Start and verify

1. Inspect `README.md`, `package.json`, `.env.example`, and the files relevant
   to the requested change. Install the pinned dependencies with `npm ci`.
2. Put local values in `.env`; never commit or display them. The required keys
   are `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL`, `DATABASE_URL`, and `DIRECT_URL`.
3. Run the app with `npm run dev`.
4. For the generated first-app handoff, run `npm run verify:first-session`
   from Claude Desktop Code. It rechecks this exact root, tools, GitHub CLI,
   the configured database, dependencies, the existing development command,
   and a loopback preview without printing command output or secret values.
5. During development, run the focused test plus `npm run lint` and
   `npm run typecheck`. Before release, run `npm run verify`.

`app/` contains routes and layouts. Authenticated routes live under
`app/(authenticated)/`; `proxy.ts` provides the initial cookie check and the
authenticated layout performs the server-side session check. Use the existing
Better Auth helpers in `lib/auth.ts` and `lib/auth-client.ts`, and the Prisma
singleton in `lib/db/prisma.ts`. Preserve participant-controlled sign-in,
folder access, repository visibility, and permission prompts.

## Database and deployment boundaries

`prisma/schema.prisma` is the schema source of truth. Do not rename Better Auth
models or fields. Scope participant-owned data by the authenticated user. For
reviewed schema changes, create a migration with
`npm run db:migrate:dev -- --name <change>`, review and commit it, then apply it
with `npm run db:migrate`. `npm run db:push` is only for an explicitly approved
disposable prototype. Never seed, reset, or migrate a shared/production database
as an incidental build step.

No Git push or build is a production deployment. The configuration, reviewed
production migration, and deployment are covered by the single final
participant confirmation described by the deployment skill. Never weaken
authentication, bypass tool permissions, change repository access, overwrite
occupied paths, or expose credentials to make a task pass.

## Experimental assistant-led production deployments

Use `.claude/skills/deploy-production/SKILL.md` when a participant asks to
release, ship, or deploy this application. It is an experimental Vercel-first
workflow until a disposable participant-owned rehearsal succeeds. Rediscover
Git and Vercel state on every invocation, use Vercel Marketplace before asking
for a separate Neon login, and keep database URLs and secret values out of
chat, Git, and reports. The participant approves Vercel identity, Marketplace
terms/plan choices, and one final displayed production summary. Builds remain
non-mutating; apply reviewed migrations once using the direct production
connection, then deploy and observe HTTPS, database, and Better Auth smoke
checks. Do not add public deployment scripts, daemons, launchers, credential
helpers, permission bypasses, or user-facing npm deployment commands.

## Generated first-app handoff

`FIRST_APP_HANDOFF.md` and `.first-app/` are generated, local support artifacts.
They must remain root-anchored in `.gitignore`; never commit, relocate, or edit
them as durable project documentation. Their absence is valid and does not
prevent the app from running.

When both files exist:

1. Read this file first. Treat `.first-app/receipt.json` as authoritative and
   `FIRST_APP_HANDOFF.md` only as its human-readable projection.
2. Accept `contract_version` values with major version `1`, ignore unknown
   fields, and treat unknown capability states as `unverified` rather than
   success. Verify the selected working directory resolves to
   `application.root` before using the receipt.
3. Treat capability results as time-bounded evidence and recheck relevant facts
   before mutation. Listed actions are guidance only; the receipt grants no
   permission to authenticate, approve access, deploy, or alter data.
4. If the version is missing, malformed, or has an unsupported major, stop
   automated interpretation. Preserve all participant files, do not infer state
   from the Markdown, and ask the participant to rerun a compatible bootstrap.

Make narrow changes that follow existing patterns. Do not add dependencies
without approval. Never print environment values, tokens, cookies, connection
URLs, credential-helper output, or private keys. Report what changed, the checks
run, and any repository deviation or remaining risk.
