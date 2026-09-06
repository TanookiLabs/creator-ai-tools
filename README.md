# Hackathon Starter: Next.js + Better Auth + Prisma

This is the approved T3 starter for the AI Bootcamp: Next.js 16, React 19,
TypeScript, Better Auth, Prisma 6, PostgreSQL, Tailwind CSS, and shadcn/ui.
Claude Desktop is the primary way to start. The bootstrap prepares a Mac,
checks out this template at an approved commit, and opens the exact application
root in Desktop.

## Start on a Mac

You need macOS, a GitHub account, and a Claude account whose plan or
organization provides the Code interface in Claude Desktop. Sign-in, folder
access, GitHub authorization, and command permissions remain under your control.

Open Terminal and run this complete block. It downloads the published
bootstrap to a private temporary directory, verifies the release digest and
shell syntax, and then runs the file with interactive input intact.

```bash
bootstrap_tmp=$(mktemp -d "${TMPDIR:-/tmp}/creator-ai-tools.XXXXXX") || exit 1
cleanup_bootstrap() { rm -f "$bootstrap_tmp/setup.sh"; rmdir "$bootstrap_tmp" 2>/dev/null || true; }
trap cleanup_bootstrap EXIT
trap 'exit 130' HUP INT TERM
bootstrap_url="https://raw.githubusercontent.com/TanookiLabs/creator-ai-tools/refs/tags/bootstrap-v1.0.0/setup.sh"
if ! curl --fail --location --silent --show-error --output "$bootstrap_tmp/setup.sh" "$bootstrap_url"; then
  echo "Bootstrap download failed. No setup changes were made. Check your connection, then run these commands again."
  exit 1
fi
if ! printf '%s  %s\n' '3d018c8128da5c0e5286ad31d7ae6aaa300befb7e616922611beaa07123242cb' "$bootstrap_tmp/setup.sh" | shasum -a 256 --check --status; then
  echo "Bootstrap integrity check failed. No setup changes were made. Exit this shell, then retry from this page."
  exit 1
fi
if ! /bin/bash -n "$bootstrap_tmp/setup.sh"; then
  echo "Bootstrap validation failed. No setup changes were made. Report bootstrap 1.0.0 to the workshop organizer."
  exit 1
fi
/bin/bash "$bootstrap_tmp/setup.sh"
```

The URL is release-tagged rather than branch-based, and the digest pins the
exact published bytes. The first output must identify `Vibe Coding Setup
1.0.0` and its active phase. A download, integrity, syntax, or unsupported
platform failure stops before bootstrap changes. The temporary copy is removed
when the shell exits.

The bootstrap shows each longer phase, detects healthy tools on rerun, and asks
before installing or reusing anything. It offers
`~/Documents/src/<project-name>`, displays the resolved absolute application
root, and asks you to confirm it before checkout. It never merges into or
deletes an unrelated nonempty directory. Its template source is the canonical
[`TanookiLabs/creator-ai-tools`](https://github.com/TanookiLabs/creator-ai-tools)
repository at an approved immutable commit.

## Claude Desktop handoff

After checkout, the bootstrap creates two ignored, nonsecret support artifacts
inside the application root:

- `FIRST_APP_HANDOFF.md`, the readable next-step summary
- `.first-app/receipt.json`, the versioned receipt with the exact root,
  bootstrap/template provenance, verification results, and recovery actions

The bootstrap opens Claude Desktop and explains any required sign-in. Confirm
that the **Code** interface is available. When macOS asks for folder access,
compare the displayed path character-for-character with the bootstrap's
`Project root verified` path. Approve only that application root—not its parent
`src` directory—and keep normal permission prompts enabled.

Send this first prompt:

> Read CLAUDE.md and FIRST_APP_HANDOFF.md, confirm this is the receipt's exact application root, then verify and start the app.

Claude must do the verification from the Desktop Code session. A Terminal-only
check is not enough. The durable instructions are in `CLAUDE.md`; the generated
handoff reports this particular Mac's state and grants no extra permission.

## If the fast path stops

Your checked-out project is preserved. Rerun the same release block to resume a
partial setup. Keep the displayed bootstrap version, active phase, and exit
status when asking for help; do not share tokens or environment values.

For Desktop sign-in, missing Code access, a canceled deep link, the wrong
folder, Postgres.app first launch, or GitHub Keychain context, follow the
[Claude Desktop recovery guide](guides/prerequisites/claude-desktop.md).

If Desktop is unavailable but your account permits the normal Claude CLI, the
secondary recovery is:

```bash
cd "/absolute/path/printed/as/Project root verified"
pwd -P
claude
```

Compare `pwd -P` with the exact path in `FIRST_APP_HANDOFF.md`, then send the
first prompt above. Do not use permission bypass flags. If Code is unavailable
because of account or organization policy, contact that owner; installing the
app cannot change eligibility.

This onboarding release supports macOS only. It intentionally provides no
Windows or Linux installer, deep link, parity claim, or workaround.

## Work on the application

After Desktop verifies the handoff, use the checked-in commands:

```bash
npm ci
cp .env.example .env
npm run db:migrate
npm run dev
```

Supply the local values named in `.env.example` without printing or committing
them. `npm run db:migrate` applies reviewed Prisma migrations; `npm run db:push`
is only for an explicitly approved disposable prototype. Open
<http://localhost:3000>, create your own account, and verify the dashboard.

Useful checks:

```bash
npm run test:quality
npm run lint
npm run typecheck
```

Before a template release, run `npm run verify:template`. The full local gate
is `npm run verify`. Neither command seeds, resets, or deploys a database.

## Repository guides

- [Start a project](guides/build/starting-a-project.md)
- [Environment variables and secrets](guides/build/environment-variables-and-secrets.md)
- [Prisma migration lifecycle](docs/prisma-migrations.md)
- [Deploy the application](guides/build/deployment.md)
- [Provider-neutral release handoff](docs/release-handoff.md)
- [Claude Desktop recovery](guides/prerequisites/claude-desktop.md)

External accounts, integrations, repository visibility, deployment, and
production database changes are opt-in and participant-controlled.
