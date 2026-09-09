# Start a project

Use this workflow to turn this starter into a separately owned project without overwriting the existing setup guidance in the [README](../../README.md).

For an opt-in, step-by-step alternative to the automated macOS installer, see
[Manual macOS setup](../prerequisites/manual-macos-setup.md).

For the equivalent native Windows and Git Bash path, see [Manual Windows
setup](../prerequisites/manual-windows-setup.md).

## Prerequisites

- The repository is available locally.
- Node.js 22, npm 10, and Git are installed.
- You have chosen the project's owner, repository visibility, and working name.

## Ownership

The project owner controls the source repository, database, hosting account, access list, costs, and production data. An agent may run repository commands, but must not create accounts, accept terms, or choose access policy for the owner.

## Workflow

1. Read `README.md`, `CLAUDE.md`, `.env.example`, and the relevant files under `docs/` before changing code.
2. If this is a copied template, create a new Git history only after confirming the copy no longer needs the template history. Otherwise, keep the current history.
3. Install the locked dependencies with `npm ci`.
4. Copy `.env.example` to the ignored `.env` file and have the owner supply local values. Do not copy values from another project or environment.
5. Apply the committed database baseline with `npm run db:migrate`. Use `db:push` only for an explicitly disposable prototype.
6. Start the application with `npm run dev`, create an account through the UI, and make a small, reviewable first change.
7. Review `git diff` and commit only source, migrations, examples, and documentation intended for the new repository.

## Verify

- `npm run typecheck` succeeds.
- The app loads at `http://localhost:3000`, and sign-up reaches `/dashboard`.
- `git status --short` shows no `.env`, credentials, generated local data, or unrelated files staged for commit.

## If it fails

- If install or runtime versions differ, compare them with `package.json`; do not change the machine-wide toolchain without owner approval.
- If configuration is missing, compare variable names with `.env.example` without printing their values.
- If migration fails, stop and follow [Prisma migration lifecycle](../../docs/prisma-migrations.md); do not use `db:push` on shared data.
