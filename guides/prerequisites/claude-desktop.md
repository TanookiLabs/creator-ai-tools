# Claude Desktop: first handoff and recovery

Claude Desktop Code is the primary interface for this macOS onboarding release.
The bootstrap finishes the pinned template checkout before Desktop opens. Your
project remains on disk if Desktop is unavailable or folder selection is not
completed.

Gatekeeper approval, Desktop sign-in and Code eligibility, exact-folder
confirmation, GitHub Keychain access, and visual preview confirmation remain
manual participant scenarios. Automated tests use fixtures for the surrounding
recovery behavior; they do not click GUI consent dialogs or inspect Keychain.

## Confirm the exact application root

Find the absolute path printed after `Project root verified` and recorded as
`Exact application root` in `FIRST_APP_HANDOFF.md`. In Claude Desktop:

1. Sign in with your own account and select **Code**.
2. Choose **Open folder** and select the exact verified path.
3. Confirm only when its complete path exactly matches the verified path.
4. Send: `Open /absolute/path/printed/as/Project root verified, read CLAUDE.md, and help me start the app.`

The directory must contain `package.json`, `package-lock.json`,
`next.config.ts`, `app/`, `prisma/schema.prisma`, `CLAUDE.md`, and
`FIRST_APP_HANDOFF.md`. A folder ending at `src` is the parent and is wrong.

## Verify the first Desktop Code session

From the Code session opened at that exact root, run:

```bash
npm run verify:first-session
```

The verifier does not install packages, authenticate accounts, migrate or seed
the database, or keep a server running. It checks `git`, `gh`, `node`, `npm`,
and `psql`; performs a read-only query against the configured application
database; checks the npm dependency tree; starts the existing `npm run dev`
command on a temporary loopback port; observes its HTTP preview; and stops only
that temporary process. Raw command output and connection values are never
printed or written to the generated handoff.

An action result names the failed capability and records a participant-owned
recovery step in `.first-app/receipt.json` and `FIRST_APP_HANDOFF.md`. Complete
that step yourself and rerun the same command. A Terminal-only run is useful for
diagnosis but is not evidence that the Desktop Code environment is ready.

## Folder selection is pending or pointed at the wrong folder

No checkout recovery is necessary. The installer does not claim that a Desktop
deep link or a yes/no response selected the folder. In Claude Desktop, select
**Code**, choose **Open folder**, and select the exact verified application
root. If another folder is open, close that Code session and open a new one at
the verified root. Recheck the markers above before sending the first prompt.

If setup changed shell or PATH configuration while Desktop was open, quit
Claude normally and reopen it before verifying tools. Do not grant access to a
broader parent folder as a workaround.

## Desktop or Code is unavailable

- If `/Applications/Claude.app` is absent or will not launch, rerun the
  bootstrap and approve installation, or download Claude Desktop from
  <https://claude.ai/download>. macOS may require approval to open it.
- If sign-in fails, complete recovery in Desktop or with your account owner.
  The bootstrap never enters credentials.
- If **Code** is missing, check the account plan and organization policy. App
  installation does not grant eligibility and setup must not claim success.

When the normal Claude CLI is available, it is a secondary recovery path:

```bash
cd "/absolute/path/printed/as/Project root verified"
pwd -P
claude
```

Compare `pwd -P` with the handoff. Use normal permission behavior; never add a
flag that bypasses prompts. This release supports macOS only and does not
provide another platform path.

## Postgres.app is installed but not ready

Installation alone is not readiness. Bring Postgres.app to the foreground. On
first launch, macOS may require **Open**, Gatekeeper approval, permissions, and
**Initialize**. If no window appears, open **Applications** in Finder or use
Spotlight to launch `Postgres.app`.

Wait only for the bounded check shown by the bootstrap. If it times out, choose
its retry or Finder option after the server reports it is running. Rerun the
same bootstrap release; readiness is recorded only after the explicit
Postgres.app `psql` client completes a real local connection.

Do not replace the documented migration with `db:push` to hide a connectivity
failure. Once ready, Desktop can apply the baseline with `npm run db:migrate`.

## GitHub looks signed out in one context

GitHub CLI credentials may be available through the macOS Keychain in your GUI
login session but unavailable to SSH or a background process. A failed remote
check is not authoritative. From the participant's interactive Terminal, run:

```bash
gh auth status
```

If that local check fails, run `gh auth login` and complete the browser and
Keychain prompts yourself, then rerun the bootstrap. Do not paste tokens into
Claude, the handoff, logs, URLs, or repository files. Do not log out or replace
a working login solely because a remote session could not read the Keychain.

## Safe rerun

Run the exact immutable bootstrap block from the root README again. Healthy
steps are reused. For an interrupted approved checkout, choose **Resume**. For
an unrelated nonempty destination, choose another location or abort. Never
delete or merge its contents to force setup to continue.
