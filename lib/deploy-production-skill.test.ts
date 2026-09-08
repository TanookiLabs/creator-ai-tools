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
  assert.match(skill, /rediscover/i)
  assert.match(skill, /Vercel Marketplace first/i)
  assert.doesNotMatch(skill, /neonctl|npm install -g|exact confirmation payload|ledger/i)
})

test("the deployment skill protects secrets and keeps one final mutation boundary", () => {
  assert.match(skill, /Never print, request, commit, or paste database URLs, auth secrets/i)
  assert.match(skill, /Ask once: “Continue with the production\s+migration and\s+deployment\?”/i)
  assert.match(skill, /Never use `prisma db\s+push`, reset, destructive SQL/i)
  assert.match(skill, /make no further provider or\s+database mutation/i)
  assert.match(skill, /npx --yes vercel@latest env run -e production -- npm\s+run db:migrate/i)
  assert.match(skill, /rehearsal assumption/i)
})

test("every relevant document keeps the workflow experimental and one-confirmation only", () => {
  for (const [path, contents] of Object.entries(documents)) {
    assert.doesNotMatch(contents, /(^|\n)#+\s+Supported production sequence|only supported assistant-led production/im, path)
    assert.doesNotMatch(contents, /deployment receipt|\.deployment-receipts|separate production-variable confirmation|fresh migration approval/i, path)
  }
  assert.match(documents["docs/release-handoff.md"], /Experimental production rehearsal sequence/)
  assert.match(documents["docs/participant-owned-provider-rehearsal.md"], /not the current\s+operating procedure/i)
  assert.match(documents["README.md"], /experimental/i)
  assert.match(documents["CLAUDE.md"], /configuration, reviewed\s+production migration, and deployment are covered by the single final\s+participant confirmation/i)
  assert.match(documents["docs/auth-access.md"], /For a new project with no secret, generate one locally\s+and stream it directly to Vercel without displaying or persisting it/i)
  assert.match(documents["docs/auth-access.md"], /asks once before configuration, migration,\s+and deployment/i)
  assert.match(documents["docs/prisma-migrations.md"], /single final production summary and confirmation/i)
  assert.doesNotMatch(documents["docs/prisma-migrations.md"], /production configuration record|\breceipt\b/i)
})

test("the normal path has no participant deployment command or Neon state framework", () => {
  const all = Object.values(documents).join("\n")
  assert.doesNotMatch(all, /npm run deploy:setup|neonctl|separate Neon authentication/i)
  assert.doesNotMatch(skill, /receipt|ledger|runner|state machine/i)
  assert.doesNotMatch(readFileSync("package.json", "utf8"), /"deploy:setup"/i)
})

test("repository repair and rehearsal discovery are safe and recoverable", () => {
  assert.match(skill, /Never push to `TanookiLabs\/creator-ai-tools`/)
  assert.match(skill, /rename it to\s+`template`, set its push URL to `DISABLED`/i)
  assert.match(skill, /gh repo create <name> --private --source=\. --remote=origin --push/)
  assert.match(skill, /explicit request to deploy authorizes this safe\s+private-repository setup/i)
  assert.match(skill, /before Vercel discovery/i)
  assert.match(skill, /remote `participant-work` resolves to the local\s+commit/i)
  assert.match(skill, /creation succeeds but its first push fails, retain the origin/i)
  assert.match(skill, /stop for a name\/owner choice or conflicting remote\s+branch/i)
  assert.match(skill, /authorizes Vercel configuration, the\s+reviewed migration, and deployment only/i)
  assert.match(skill, /unchanged starter.*explicitly approved disposable rehearsal/i)
  assert.match(skill, /npx --yes vercel@latest --version/)
  assert.match(skill, /Do not restart or stop local development servers during discovery/i)
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
