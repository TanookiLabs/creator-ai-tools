# Frozen release inputs

This inventory freezes the inputs for the macOS v1 Claude Desktop-first
onboarding work. It is an audit only: it does not approve a deployment or
change bootstrap or template behavior.

## Provenance for this audit

- Requirements: `11e0f129-f487-485b-bf78-f02e0fc2d29a` revision
  `e63a5a77-72e7-4893-b5e6-bc2aa55d587a` (revision 2, checksum
  `baf9f8b447f10559dc974e3d6a5e46ff8f0e3e00b252ff82c1c001a8c0bb19b7`).
- Implementation plan: `2ea258d4-23f9-4481-94ae-b8beaa4d73d2` revision
  `94465352-0851-446a-96f7-650363fd1631` (revision 6).
- Execution: `0c97f4c9-a6c5-410f-989d-6fd84360afb1`.
- Audit date: 2026-09-06 UTC.

The plan required the T3 source to be established before behavior work. The
local checkout, its configured `origin`, GitHub repository metadata, remote
refs, and immutable HTTP artifacts all agree on the source recorded below.

## Frozen sources

| Role | Canonical repository | Owner | Default/target branch | Frozen starting commit | Immutable publication |
| --- | --- | --- | --- | --- | --- |
| Bootstrap | `https://github.com/TanookiLabs/creator-ai-tools` | GitHub organization `TanookiLabs` | `main` / `main` | `0393501676cf5f3751089699eafb5090411ff8c7` | [setup.sh at the frozen commit](https://raw.githubusercontent.com/TanookiLabs/creator-ai-tools/0393501676cf5f3751089699eafb5090411ff8c7/setup.sh) |
| T3 application template | `https://github.com/TanookiLabs/creator-ai-tools` | GitHub organization `TanookiLabs` | `main` / `main` | `0393501676cf5f3751089699eafb5090411ff8c7` | [repository tarball at the frozen commit](https://codeload.github.com/TanookiLabs/creator-ai-tools/tar.gz/0393501676cf5f3751089699eafb5090411ff8c7), or Git checkout of the full SHA |

These are two release inputs with different entrypoints, but they are
currently co-located in one repository and one commit. Later work must not
invent a second template repository. It must use the full SHA above until an
owner deliberately reviews and freezes a replacement.

Both immutable URLs returned HTTP 200 during this audit. The downloaded
bootstrap's SHA-256 was
`dfd14dce60c91f22452df0e9e2677ee0f054e2b2ca8d9bf5f471da4db0178580`,
matching the bytes of `setup.sh` in the frozen Git commit. The commit exists on
the remote `main` ref and GitHub identifies it as an unsigned commit authored
and committed by David Renz. That author metadata is evidence, not a
substitute for organization release approval.

Moving URLs are not release inputs. In particular, do not publish a bootstrap
from `.../main/setup.sh` and do not acquire the template from a branch archive.

## Verified bootstrap surface

- Entrypoint: repository-root `setup.sh` (Bash, macOS-only).
- Documentation entrypoint: `README.md`, especially **Set up your Mac** and
  **Continue with Claude**.
- Current phases in `setup.sh`: preflight/Xcode Command Line Tools and
  Homebrew; Git; build libraries; mise/Node/Ruby; Postgres.app; GitHub CLI and
  login; Stripe Projects CLI; Claude Code and Claude Desktop; source folder;
  summary/handoff.
- Generated artifact: `~/Documents/src/FIRST_APP_HANDOFF.md`, also copied to
  the clipboard when `pbcopy` is available.
- Bootstrap tests: none. There is no bootstrap test directory, shell test
  runner, or CI job at the frozen commit.
- Bootstrap release mechanism: no tag and no GitHub Release exists. The only
  reproducible publication available now is the raw GitHub URL containing the
  full commit SHA above. GitHub `main` is the sole remote branch.

### Current bootstrap safety findings

These findings are inventory for later behavior tasks; they are not changed by
this audit.

- `README.md:55` and the header example in `setup.sh` use interactive
  `curl | bash` from the obsolete `ericskiff/vibe-setup` source.
- `README.md:68` and `setup.sh:638` invoke
  `claude --dangerously-skip-permissions`, bypassing normal participant
  permission prompts.
- `setup.sh:20-25` tries to recover piped stdin with `/dev/tty`; the pinned
  requirements instead require download-then-run as the supported path.
- `setup.sh:212` executes the moving Homebrew `HEAD/install.sh` directly from
  a command substitution, and `setup.sh:525` pipes the moving Claude installer
  into Bash. These dependency installers are not content-pinned.
- `setup.sh:54-67` appends to a shell profile without first verifying current
  user ownership and writability.
- `setup.sh:449-460` performs and, on failure, initiates GitHub authentication
  in the script's current context; it does not distinguish GUI Keychain state
  from an SSH/background false negative.
- Postgres readiness is a bounded retry, but failure is downgraded to “Claude
  will examine this later”; it does not require a successful explicit
  Postgres.app `psql` connection before overall handoff.
- The bootstrap does not acquire or verify a pinned application template. It
  creates only `~/Documents/src`, then asks Claude to choose/scaffold a project.
- The handoff instructs Claude to create a database, run Prisma schema push,
  create application files, and create/push a GitHub repository. It is the
  obsolete agent-first flow and is not the required template-first handoff.
- Claude Desktop installation is checked, but the script finishes with a
  terminal Claude Code launch instruction. It has no exact-root
  `claude://code/new` handoff or participant folder confirmation.
- The script has no bootstrap version, receipt schema, immutable template
  provenance, or secret-redacted completion receipt.

## Verified T3 template surface

- Application root markers: `package.json`, `package-lock.json`, `next.config.ts`,
  `app/`, `prisma/schema.prisma`, `CLAUDE.md`, and `README.md`.
- Stack: Next.js 16 App Router, React 19, TypeScript, Tailwind CSS, shadcn/ui,
  Better Auth, Prisma 6, and PostgreSQL. Authentication and authorization stay
  participant-controlled; `proxy.ts`, `lib/auth.ts`, `lib/auth-client.ts`, and
  the authenticated route group are the verified auth boundaries.
- Package manager: npm 10, locked by `package-lock.json` and
  `packageManager: npm@10.9.7`; Node is constrained to 22.x.
- Durable agent instructions: root `CLAUDE.md`. It describes custom commands,
  but the referenced `.claude/commands/` directory is absent at the frozen
  commit.
- Participant docs: root `README.md`, `guides/prerequisites/`, `guides/build/`,
  `docs/auth-access.md`, `docs/prisma-migrations.md`,
  `docs/quality-verification.md`, `docs/release-verification.md`,
  `docs/release-handoff.md`, and `docs/release-rehearsal.md`.
- Application entrypoints: `app/layout.tsx`, `app/page.tsx`,
  `app/api/auth/[...all]/route.ts`, `app/(authenticated)/layout.tsx`, and
  `proxy.ts`.
- Runtime/build scripts: `npm run dev`, `npm run build`, and `npm run start`.
- Focused static/test scripts: `npm run lint`, `npm run typecheck`,
  `npm run test:auth`, `npm run test:quality`, `npm run verify:template`, and
  `npm run verify`.
- Database scripts: `npm run db:migrate`, `npm run db:migrate:dev`, guarded
  local-only `npm run db:seed:local`, `npm run db:studio`, and the explicitly
  prototype-only `npm run db:push` escape hatch.
- Node test files: `lib/access-policy.test.ts`, `lib/auth-redirect.test.ts`,
  `lib/build-guides.test.ts`, `lib/profile-validation.test.ts`, and
  `lib/ui-quality.test.ts`.
- Release checks: `scripts/verify-template-release.sh`; the opt-in isolated
  database rehearsal is `scripts/rehearse-release.sh`.

### Template publishing and ownership boundaries

No `.github/workflows/`, `CODEOWNERS`, release configuration, provider
deployment manifest, tags, or GitHub Releases exist at the frozen commit.
`docs/release-handoff.md` therefore requires an owner-reviewed manual gate.
The organization owner must designate the human release owner and database
owner; the repository does not name those people, so later work must not guess.

The repository describes Vercel as the exercised application deployment path,
with a reviewed migration applied separately and an application build that
does not mutate the database. It also describes a `production` deployment
branch, but the upstream repository currently exposes only `main`.
Consequently `production` is documentation for participant-created
repositories, not a verified branch or publication mechanism for this
template.

For the coordinated onboarding release, the verified sequence is:

1. Change bootstrap and template-owned files together in this repository and
   review one PR against `main`, with explicit TanookiLabs release-owner review.
2. Run the repository's documented template gate and any focused bootstrap
   tests added by later tasks against the exact candidate commit. Preserve
   normal authentication and permission prompts.
3. Merge, resolve the resulting full commit SHA, and verify the raw bootstrap
   and template archive at that same SHA.
4. Publish only those SHA-qualified URLs. Record the SHA and bootstrap digest
   in release evidence before any clean-Mac rehearsal.

## Stale and conflicting references

- `README.md:55` and `setup.sh:11` reference
  `https://raw.githubusercontent.com/ericskiff/vibe-setup/main/setup.sh`.
  GitHub returned 404 for that repository during this audit.
- `README.md:108` clones `https://github.com/slow-ventures/creator-ai-tools.git`.
  That older repository still exists, but its remote `main` is
  `6dd2c78d78c4e578d80fa4c7c3f7fa69744fe1c8`, it has no tags or releases,
  and it is not the pinned canonical source.
- `README.md:110` directs participants to `rm -rf .git`. Even though scoped to
  the cloned directory in the prose, it is a destructive manual step and is
  incompatible with a bootstrap that must identify and safely resume a pinned
  checkout.
- `README.md:64-76` and the generated handoff in `setup.sh` describe a
  terminal-first, agent-scaffolded flow rather than the required Desktop-first,
  template-first flow.
- `README.md` and `CLAUDE.md` describe a `production` branch that is absent
  from the canonical remote.
- `CLAUDE.md` advertises custom command files under `.claude/commands/`, but
  that directory and those command files are absent from the frozen commit.

Embedded ZIPs under `docs/uploads/` are reference evidence, not canonical
publication sources: they carry no Git metadata or immutable upstream commit.
They must not be substituted for either frozen source.

## Paths frozen for later work

Later tasks may change behavior only in these verified ownership areas:

| Concern | Verified path(s) |
| --- | --- |
| Bootstrap behavior and generated handoff | `setup.sh` |
| Bootstrap invocation and participant flow | `README.md` |
| Template agent guidance and handoff consumption | `CLAUDE.md`, `.gitignore` |
| Desktop-specific troubleshooting | `guides/prerequisites/claude-code.md` (existing focused guide; rename/additions require owner review) |
| Template commands and dependency contract | `package.json`, `package-lock.json` |
| Template static/release validation | `scripts/verify-template-release.sh`, `scripts/rehearse-release.sh`, `lib/*.test.ts`, `docs/release-handoff.md` |
| Auth and permission boundaries | `proxy.ts`, `lib/auth.ts`, `lib/auth-client.ts`, `app/api/auth/[...all]/route.ts`, `app/(authenticated)/` |

No path in this inventory is proposed or inferred: every path above exists at
the frozen commit. A future file that does not yet exist must be introduced and
reviewed explicitly rather than cited as an existing release input.
