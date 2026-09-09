# Manual Windows setup

Use this guide when you want to create the same kind of local environment as
the automated installer, but want to inspect and perform each action yourself
on Windows. It uses **native Windows with Git Bash**: no WSL or Linux
installation is required. The automated installer remains the quickest path,
and this guide does not replace its safe rerun checks.

This project is a Next.js 16, TypeScript, React 19, Better Auth, Prisma 6, and
PostgreSQL application. The outcome is a local development environment, an
independent project repository on `main`, a read-only template remote, and an
optional private GitHub repository.

## Before you start

- Use a current, supported 64-bit Windows 10 or Windows 11 desktop.
- Have your own GitHub and Claude accounts. You approve installer, browser
  sign-in, account, and permission prompts yourself.
- Choose a project name containing lowercase letters, numbers, dots, hyphens,
  or underscores. The examples use `my-first-app`.
- Do not run these commands inside an existing project or a folder containing
  work you want to keep.

Use **PowerShell** only for the Windows installers in steps 1 and 2. Open a new
**Git Bash** window for every remaining command. Keep the project, Node, Git,
Claude Code, and PostgreSQL on the Windows side; do not mix this guide with
WSL tooling.

## 1. Install Git, Node 22, and GitHub CLI

Open PowerShell and first confirm Windows Package Manager is available:

```powershell
winget --version
```

Install Git for Windows, the Node 22 major version required by this project,
and GitHub CLI:

```powershell
winget install --id Git.Git --exact
winget install --id OpenJS.NodeJS.22 --exact
winget install --id GitHub.cli --exact
```

Accept the installer prompts, then close PowerShell and open **Git Bash** from
the Start menu. Confirm the new tools are on its path:

```bash
git --version
node --version
npm --version
gh --version
```

Node must report major version `22` and npm major version `10`. If `winget` is
not available, install Git from [Git for Windows](https://git-scm.com/download/win),
Node 22 from the [Node.js downloads page](https://nodejs.org/en/download), and
GitHub CLI from its [Windows MSI download](https://cli.github.com/).

## 2. Install and start PostgreSQL for Windows

Download the [official PostgreSQL Windows installer](https://www.postgresql.org/download/windows/),
which is provided by EDB and includes PostgreSQL and pgAdmin. During setup:

1. Keep the default local port, `5432`, unless another local PostgreSQL server
   already owns it.
2. Set and save a strong local password for the `postgres` administrator
   account. It stays only on this computer and is required to create the app’s
   local database.
3. Install pgAdmin if you want its visual database browser.
4. Finish the installer and leave the PostgreSQL service running.

In Git Bash, add the installed PostgreSQL client directory to the current
terminal’s path. Replace `18` with the version you installed:

```bash
export PATH="/c/Program Files/PostgreSQL/18/bin:$PATH"
psql --version
```

To use that path in future Git Bash windows, add the same line to `~/.bashrc`
after confirming the version directory exists.

Create a project-specific local role and database. First choose a database-safe
name—use underscores rather than hyphens—and replace the sample name below:

```bash
DATABASE_NAME="my_first_app"
DATABASE_ROLE="my_first_app"
```

The commands will prompt for the `postgres` password you set in the installer,
then prompt you to choose a separate password for the project role. Do not paste
either password into chat or commit it:

```bash
createuser -U postgres -h localhost --pwprompt "$DATABASE_ROLE"
createdb -U postgres -h localhost --owner="$DATABASE_ROLE" "$DATABASE_NAME"
psql -U "$DATABASE_ROLE" -h localhost -d "$DATABASE_NAME" -c 'select 1'
```

If a role or database already exists, stop and inspect it in pgAdmin or `psql`;
do not overwrite or reset it. PostgreSQL’s Windows installer is the desktop
alternative to Postgres.app on macOS.

## 3. Sign in to GitHub and configure Git

Authenticate from Git Bash and complete browser prompts yourself:

```bash
gh auth login --web --git-protocol https
gh auth status
GITHUB_LOGIN="$(gh api user --jq .login)"
```

Keep an existing healthy, participant-managed Git identity. If you need one,
set a name and deterministic GitHub noreply address without displaying a
private email address:

```bash
GITHUB_ID="$(gh api user --jq .id)"
git config --global user.name "${GITHUB_LOGIN}"
git config --global user.email "${GITHUB_ID}+${GITHUB_LOGIN}@users.noreply.github.com"
git var GIT_AUTHOR_IDENT
```

If `git var GIT_AUTHOR_IDENT` fails, stop and repair the Git identity before
making any commit. Do not paste tokens, private email addresses, or command
output into this project or chat.

## 4. Install Claude Code in Git Bash

Claude Code supports native Windows when Git for Windows supplies Git Bash.
From Git Bash, install and verify it:

```bash
npm install -g @anthropic-ai/claude-code
claude doctor
claude --version
```

Start `claude` from the project directory after setup and complete browser
authentication yourself. Anthropic documents both this Git Bash route and the
optional WSL alternative in its [Claude Code Windows setup guide](https://docs.anthropic.com/en/docs/claude-code/getting-started).

## 5. Create an independent project copy

Choose the project location and name in Git Bash:

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

The Creator AI Tools template must not become your writable `origin`. Download
it into a temporary directory, copy only its working files, and initialize a
fresh repository:

```bash
TEMPLATE_REPOSITORY="https://github.com/TanookiLabs/creator-ai-tools"
TEMPLATE_TEMPORARY="$(mktemp -d)"
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

Confirm the repository is independent and the template cannot be pushed to:

```bash
git -C "$PROJECT_ROOT" branch --show-current
git -C "$PROJECT_ROOT" log --oneline -1
git -C "$PROJECT_ROOT" remote -v
```

You should see `main`, no `origin` yet, and `template` with `DISABLED` as its
push URL. Do not rename `template` to `origin`.

## 6. Optionally create your private GitHub repository

Skip this step if you want a local-only project for now. Otherwise create a
new private repository under your authenticated GitHub account and push `main`:

```bash
cd "$PROJECT_ROOT"
gh repo create "$PROJECT_NAME" --private --source=. --remote=origin --push
gh api -X PATCH "repos/$GITHUB_LOGIN/$PROJECT_NAME" -f default_branch=main
git ls-remote --heads origin refs/heads/main
```

If the name already exists, do not connect to it just because the name matches.
Choose another name or keep the project local. If repository creation succeeds
but its initial push fails, retain the participant-owned `origin`, diagnose the
push, and push `main` only after confirming the remote branch is absent or
matches your local commit.

## 7. Install, configure, and run the application

Install the pinned dependencies and create the local `.env` file:

```bash
cd "$PROJECT_ROOT"
npm ci
cp .env.example .env
```

Generate a local Better Auth secret once:

```bash
openssl rand -base64 32
```

Copy that output into `BETTER_AUTH_SECRET` in `.env`; it is a local secret and
must never be committed. Also set the database values using the project role,
password, and database name you chose in step 2:

```dotenv
BETTER_AUTH_SECRET=<paste the generated local value here>
BETTER_AUTH_URL=http://localhost:3000
DATABASE_URL=postgresql://my_first_app:<project-role-password>@localhost:5432/my_first_app
DIRECT_URL=postgresql://my_first_app:<project-role-password>@localhost:5432/my_first_app
```

Keep `DATABASE_URL` and `DIRECT_URL` on the same local database. Do not create
`.env.local` from production values. Apply committed migrations once, then
start the app:

```bash
npm run db:migrate
npm run dev
```

Open <http://localhost:3000>, create an account, and confirm the dashboard
loads. For migration boundaries, read [Prisma migration lifecycle](../../docs/prisma-migrations.md).

## 8. Verify and hand off

From the project root, run:

```bash
npm run lint
npm run typecheck
npm run test:quality
```

Start Claude Code from the same Git Bash project directory and ask it to read
`CLAUDE.md` before making changes. Before committing, confirm only intended
project files are present:

```bash
git status --short
```

Do not commit `.env`, database credentials, generated handoff files, or local
PostgreSQL data. When ready to release, follow the [manual Vercel deployment
guide](../manual-vercel-deployment.md) or use the assistant-led flow.

## Resume or recover

- **A Windows installer fails:** complete or repair that installer, open a new
  Git Bash window, and repeat its version check.
- **PostgreSQL is not ready:** check the PostgreSQL service in Windows Services
  or pgAdmin, then repeat only the connection check and migration step.
- **GitHub is unavailable:** keep the independent local repository and create
  `origin` later.
- **Existing files or Git history are at the destination:** stop. Do not remove
  `.git`, repoint remotes, or overwrite the folder automatically.
- **A local migration fails:** stop instead of using `db:push`, reset, seed, or
  destructive SQL. Compare only variable names with `.env.example`, never
  values.
