# Manual macOS setup

Use this guide when you want to set up the same local development environment
as [`setup.sh`](../../setup.sh), but prefer to inspect and run each step
yourself. The automated installer remains the quickest path. This guide is for
a new Mac and a new project folder; it does not replace the installer’s safe
rerun checks.

This project is a Next.js 16, TypeScript, Better Auth, Prisma, and PostgreSQL
application. The manual outcome is a local development environment, an
independent project repository on `main`, a read-only template remote, and an
optional private GitHub repository. Production deployment remains a separate
assistant-led workflow.

## Before you start

- Use a macOS desktop session with an internet connection.
- Have your own GitHub and Claude accounts. You approve browser sign-in,
  Keychain, Marketplace, and account prompts yourself.
- Choose a project name containing lowercase letters, numbers, dots, hyphens,
  or underscores. The examples use `my-first-app`.
- Do not run these commands inside an existing project or a folder containing
  work you want to keep.

Open Terminal and set the project location. Change these two values before
continuing:

```bash
PROJECT_PARENT="$HOME/Developer"
PROJECT_NAME="my-first-app"
PROJECT_ROOT="$PROJECT_PARENT/$PROJECT_NAME"
```

Confirm the destination is absent or empty. Stop and choose another location
if it is not:

```bash
test ! -e "$PROJECT_ROOT" || test -z "$(find "$PROJECT_ROOT" -mindepth 1 -maxdepth 1 -print -quit)"
```

## 1. Install the Mac development tools

Install Apple Command Line Tools if `xcode-select -p` fails. Accept Apple’s
dialog and wait for it to finish:

```bash
xcode-select --install
```

Install Homebrew from [its official installation page](https://brew.sh), then
open a new Terminal window if its installer asks you to. Confirm it is ready:

```bash
brew --version
```

Install Git, the build libraries used by Ruby tooling, mise, the GitHub CLI,
and Postgres.app:

```bash
brew install git libyaml gmp openssl@3 readline mise gh
brew install --cask postgres-app
```

Add mise and the Postgres.app client to your zsh configuration, then reload it:

```bash
grep -qxF 'eval "$(mise activate zsh)"' ~/.zshrc || echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
grep -qxF 'export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"' ~/.zshrc || echo 'export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Install the runtime versions used by the installer. Node 22 and npm 10 are the
project requirements; Ruby is installed to match the complete Mac setup:

```bash
mise use -g node@22 ruby@3
node --version
npm --version
git --version
```

## 2. Start and verify local PostgreSQL

If you did not install Postgres.app with the Homebrew command in step 1,
download it from [Postgres.app](https://postgresapp.com/downloads.html), move
it to **Applications**, and open it. If it shows **Initialize**, select it and
complete the macOS prompt. Leave the app running, then verify the bundled client
can connect:

```bash
psql -d postgres -c 'select 1'
```

If this fails, return to Postgres.app rather than substituting another database
or using `db:push`. See [Postgres.app recovery](claude-desktop.md#postgresapp-is-installed-but-not-ready).

## 3. Sign in to GitHub and set a valid Git identity

Authenticate from this interactive Mac Terminal; complete browser and Keychain
prompts yourself:

```bash
gh auth login --web --git-protocol https
gh auth status
GITHUB_LOGIN="$(gh api user --jq .login)"
```

Keep an existing healthy, participant-managed Git identity. If you need one,
set a name and the deterministic GitHub noreply address without displaying a
private email address:

```bash
GITHUB_ID="$(gh api user --jq .id)"
git config --global user.name "${GITHUB_LOGIN}"
git config --global user.email "${GITHUB_ID}+${GITHUB_LOGIN}@users.noreply.github.com"
git var GIT_AUTHOR_IDENT
```

If `git var GIT_AUTHOR_IDENT` fails, stop and repair Git identity before making
any commit. Do not paste tokens, private email addresses, or Keychain output
into this project or chat.

## 4. Install Claude tools

Install Claude Code using the current instructions at
[Claude Code](https://claude.com/claude-code), then confirm it is available:

```bash
claude --version
```

Claude Desktop is optional but is the normal handoff interface. Install it from
[Claude Desktop](https://claude.ai/download), sign in yourself, and later use
**Code** → **Open folder** to select the exact project root.

## 5. Create an independent project copy

The Creator AI Tools template must not become your writable `origin`. Download
it into a temporary directory, copy only its working files, and initialize a
fresh repository. This preserves template provenance while starting your own
history on `main`:

```bash
TEMPLATE_REPOSITORY="https://github.com/TanookiLabs/creator-ai-tools"
TEMPLATE_TEMPORARY="$(mktemp -d "${TMPDIR:-/tmp}/creator-ai-template.XXXXXX")"
mkdir -p "$PROJECT_ROOT"
git clone --depth=1 "$TEMPLATE_REPOSITORY" "$TEMPLATE_TEMPORARY"
TEMPLATE_COMMIT="$(git -C "$TEMPLATE_TEMPORARY" rev-parse HEAD)"
tar -C "$TEMPLATE_TEMPORARY" --exclude=.git -cf - . | tar -C "$PROJECT_ROOT" -xf -
rm -rf "$TEMPLATE_TEMPORARY"

git -C "$PROJECT_ROOT" init -b main
git -C "$PROJECT_ROOT" add .
git -C "$PROJECT_ROOT" commit -m "Initialize project from Creator AI Tools"
git -C "$PROJECT_ROOT" remote add template "$TEMPLATE_REPOSITORY"
git -C "$PROJECT_ROOT" remote set-url --push template DISABLED
printf '%s\n%s\n' "$TEMPLATE_REPOSITORY" "$TEMPLATE_COMMIT" > "$PROJECT_ROOT/.git/vibe-template-provenance"
```

Confirm the repository has one independent initial commit and that the template
cannot be pushed to:

```bash
git -C "$PROJECT_ROOT" branch --show-current
git -C "$PROJECT_ROOT" log --oneline -1
git -C "$PROJECT_ROOT" remote -v
```

You should see `main`, no `origin` yet, and `template` with `DISABLED` as its
push URL. Do not run `git remote rename template origin`.

## 6. Optionally create your private GitHub repository

Skip this step if you want a local-only project for now. Otherwise create a
new private repository under the authenticated GitHub account and push `main`:

```bash
cd "$PROJECT_ROOT"
gh repo create "$PROJECT_NAME" --private --source=. --remote=origin --push
gh api -X PATCH "repos/$GITHUB_LOGIN/$PROJECT_NAME" -f default_branch=main
git ls-remote --heads origin refs/heads/main
```

If the chosen name already exists, do not connect to it merely because the
name matches. Choose a new name or keep the project local. If creation succeeds
but the push fails, retain the participant-owned `origin`, diagnose the push,
and push `main` only after confirming the remote branch is absent or matches
your local commit.

## 7. Install the app and configure a local database

Install the pinned dependencies and create a local database named after your
project:

```bash
cd "$PROJECT_ROOT"
npm ci
createdb "$PROJECT_NAME"
cp .env.example .env
```

Edit `.env` locally. It is ignored by Git. Use local values only—never copy
production or Vercel credentials into it. The required keys are:

Generate the local Better Auth secret once, then copy the command’s output into
the `BETTER_AUTH_SECRET` value in `.env`. Do not commit, print in chat, or reuse
this value for another project:

```bash
openssl rand -base64 32
```

```dotenv
BETTER_AUTH_SECRET=<paste the generated local value here>
BETTER_AUTH_URL=http://localhost:3000
DATABASE_URL=postgresql://localhost/my-first-app
DIRECT_URL=postgresql://localhost/my-first-app
```

Use your actual project name in both URLs. Keep `DATABASE_URL` and `DIRECT_URL`
on the same local database. Do not create `.env.local` from production values.

Apply the committed migrations once, then start the app:

```bash
npm run db:migrate
npm run dev
```

Open <http://localhost:3000>, create an account through the UI, and confirm the
dashboard loads. For the full migration policy, read
[Prisma migration lifecycle](../../docs/prisma-migrations.md).

## 8. Verify and hand off

From the project root, run the normal checks:

```bash
npm run lint
npm run typecheck
npm run test:quality
```

In Claude Desktop, choose **Code** → **Open folder**, select exactly
`$PROJECT_ROOT`, and ask Claude to read `CLAUDE.md` before making changes. If
you used the installer-generated handoff instead, use
[Claude Desktop recovery](claude-desktop.md) and run `npm run verify:first-session`.

Before committing, check that only intended project files are present:

```bash
git status --short
```

Do not commit `.env`, database credentials, generated handoff files, or local
Postgres data. When you are ready to deploy, ask an assistant to deploy the
application to Vercel; do not treat a Git push or `npm run build` as production.

## Resume or recover

- A failed tool installation: fix that tool, open a fresh Terminal window, and
  continue from the matching section.
- Postgres not ready: open and initialize Postgres.app, then repeat only the
  connection check and migration step.
- GitHub unavailable: keep the independent local repository; create `origin`
  later through GitHub or the deployment workflow.
- Existing files or Git history at the destination: stop. Do not remove `.git`,
  repoint remotes, or overwrite the folder automatically.
- Missing configuration: compare variable names with `.env.example`, never their
  values. For migration failure, stop rather than using `db:push`, reset, seed,
  or destructive SQL.
