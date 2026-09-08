import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import test from "node:test"

const skill = readFileSync(".claude/skills/deploy-production/SKILL.md", "utf8")
const documentPaths = [
  "README.md",
  "CLAUDE.md",
  "guides/build/deployment.md",
  "guides/prerequisites/vercel.md",
  "guides/prerequisites/neon.md",
  "docs/auth-access.md",
  "docs/prisma-migrations.md",
  "docs/release-handoff.md",
  "docs/participant-owned-provider-rehearsal.md",
] as const
const documents = Object.fromEntries(documentPaths.map((path) => [path, readFileSync(path, "utf8")]))

test("the deployment skill is concise, Vercel-first, and resumable", () => {
  assert.ok(skill.split("\n").length <= 90)
  assert.match(skill, /Deploy this application to Vercel/i)
  assert.match(skill, /Record `git status --short`/i)
  assert.match(skill, /Use Vercel Marketplace first/i)
  assert.doesNotMatch(skill, /neonctl|npm install -g|exact confirmation payload|ledger/i)
})

test("the deployment skill protects secrets and keeps one final mutation boundary", () => {
  assert.match(skill, /Never print, request, commit, or paste database URLs, secrets/i)
  assert.match(skill, /Ask once: “Continue with the production\s+migration and\s+deployment\?”/i)
  assert.match(skill, /Never use `prisma db\s+push`, reset, seed, destructive\/ad-hoc SQL/i)
  assert.match(skill, /make no further provider\/database mutation/i)
  assert.match(skill, /run-production-migration\.sh/)
  assert.doesNotMatch(skill, /clear local .* from `npx --yes vercel@latest env run/i)
  assert.match(skill, /live participant-owned `vercel-test-3` Vercel\/Neon rehearsal/i)
})

test("the Git-backed Vercel monitor stops on every terminal provider state", () => {
  assert.match(skill, /bounded interval/i)
  assert.match(skill, /`READY`, `ERROR`, `CANCELED`, and `BLOCKED` are terminal/i)
  assert.match(skill, /provider reason/i)
  assert.match(skill, /stop without retry/i)
  assert.match(skill, /without filtering errors/i)
})

test("production migration always uses the dotenv-isolating skill wrapper", () => {
  assert.match(skill, /SKILL_DIR[\s\S]*run-production-migration\.sh/)
  assert.match(documents["docs/prisma-migrations.md"], /SKILL_DIR[\s\S]*run-production-migration\.sh/)
  for (const contents of [skill, documents["docs/prisma-migrations.md"]]) {
    assert.doesNotMatch(contents, /disposable rehearsal|unverified.*rehearsal/i)
    assert.doesNotMatch(contents, /env -u DATABASE_URL[\s\S]*vercel@latest env run/i)
  }
  assert.match(skill, /exactly one Marketplace pooled and one unpooled Neon variable/i)
  assert.match(skill, /do not create a redundant write-only\s+`DIRECT_URL`/i)
  assert.match(skill, /only in its child process/i)
})

test("documentation records the successful live rehearsal and one confirmation", () => {
  for (const [path, contents] of Object.entries(documents)) {
    assert.doesNotMatch(contents, /(^|\n)#+\s+Supported production sequence|only supported assistant-led production/im, path)
    assert.doesNotMatch(contents, /deployment receipt|\.deployment-receipts|separate production-variable confirmation|fresh migration approval/i, path)
  }
  assert.match(documents["docs/release-handoff.md"], /vercel-test-3/i)
  assert.match(documents["docs/participant-owned-provider-rehearsal.md"], /vercel-test-3/i)
  assert.match(documents["README.md"], /sign-up, sign-out, sign-in, session persistence/i)
  assert.match(documents["CLAUDE.md"], /configuration, reviewed\s+production migration, and deployment are covered by the single final\s+participant confirmation/i)
  assert.match(documents["docs/auth-access.md"], /For a new project with no secret, generate one locally\s+and stream it directly to Vercel without displaying or persisting it/i)
  assert.match(documents["docs/auth-access.md"], /asks once before configuration, migration,\s+and deployment/i)
  assert.match(documents["docs/prisma-migrations.md"], /single final production summary and confirmation/i)
  assert.doesNotMatch(documents["docs/prisma-migrations.md"], /production configuration record|\breceipt\b/i)
})

test("provider cleanup and dotenv rules preserve participant state", () => {
  assert.match(skill, /cleanup-provider-side-effects\.sh capture/i)
  assert.match(skill, /\.agents`, `\.claude\/skills\/neon`, `\.claude\/skills\/neon-postgres`, and `skills-lock\.json`/)
  assert.match(skill, /final `git status --short` to match the snapshot/i)
  assert.match(skill, /Never run `vercel env pull` into `\.env\.local`/i)
  assert.match(skill, /mktemp.*EXIT\/HUP\/INT\/TERM removal trap/i)
  assert.match(skill, /Preserve any existing `\.env\.local`/i)
  const cleanup = readFileSync(".claude/skills/deploy-production/cleanup-provider-side-effects.sh", "utf8")
  assert.match(cleanup, /status --short/)
  assert.match(cleanup, /\.claude\/skills\/neon-postgres/)
  assert.doesNotMatch(cleanup, /deploy-production.*rm -rf/i)
})

test("the normal path has no participant deployment command or Neon state framework", () => {
  const all = Object.values(documents).join("\n")
  assert.doesNotMatch(all, /npm run deploy:setup|neonctl|separate Neon authentication/i)
  assert.doesNotMatch(skill, /receipt|ledger|runner|state machine/i)
  assert.doesNotMatch(readFileSync("package.json", "utf8"), /"deploy:setup"/i)
})

test("repository repair and rehearsal discovery are safe and recoverable", () => {
  assert.match(skill, /Never push to `TanookiLabs\/creator-ai-tools`/)
  assert.match(skill, /rename it to `template`, set push URL `DISABLED`/i)
  assert.match(skill, /gh repo create <name> --private --source=\. --remote=origin --push/)
  assert.match(skill, /explicit deployment request authorizes this safe private-repository setup/i)
  assert.match(skill, /before Vercel discovery/i)
  assert.match(skill, /remote `main` resolves to the local commit/i)
  assert.match(skill, /On an occupied name\/owner, conflicting remote branch, or possible history rewrite, stop/i)
  assert.match(skill, /authorizes Vercel configuration, reviewed migration, and deployment only/i)
  assert.match(skill, /unchanged starter.*explicitly approved production run/i)
  assert.match(skill, /record its resolved version/i)
  assert.match(skill, /Do not restart local development servers/i)
})

test("the Prisma verification fixture is local to schema validation", () => {
  const helper = readFileSync("scripts/verify-prisma.mjs", "utf8")
  assert.match(helper, /\["prisma", "validate"\]/)
  assert.doesNotMatch(helper, /\["prisma", "migrate"\]|db push|writeFile|\.env(?:\s|["'])/i)
})

test("bootstrap checks fall back to grep and fail on inspection errors", () => {
  for (const path of ["tests/bootstrap-safety.sh", "tests/bootstrap-docs.sh"]) {
    const script = readFileSync(path, "utf8")
    assert.match(script, /command -v rg/)
    assert.match(script, /grep -nE/)
    assert.match(script, /search_status > 1/)
  }
})
