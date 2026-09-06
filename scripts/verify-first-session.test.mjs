import assert from "node:assert/strict"
import { execFileSync } from "node:child_process"
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import test from "node:test"
import { verifyFirstSession } from "./verify-first-session.mjs"

const commit = "a".repeat(40)
const repository = "https://github.com/example/starter"

function fixture() {
  const root = realpathSync(mkdtempSync(join(tmpdir(), "first-session-")))
  for (const directory of ["app", "prisma", ".first-app", "bin"]) mkdirSync(join(root, directory), { recursive: true })
  for (const file of ["CLAUDE.md", "next.config.ts", "app/page.tsx", "prisma/schema.prisma"]) writeFileSync(join(root, file), "")
  writeFileSync(join(root, "package.json"), JSON.stringify({ name: "first-session-fixture", version: "1.0.0", private: true }))
  writeFileSync(join(root, "package-lock.json"), JSON.stringify({
    name: "first-session-fixture",
    version: "1.0.0",
    lockfileVersion: 3,
    requires: true,
    packages: { "": { name: "first-session-fixture", version: "1.0.0" } },
  }))
  execFileSync("git", ["init", "--quiet"], { cwd: root })
  for (const name of ["gh", "psql"]) {
    writeFileSync(join(root, "bin", name), `#!/bin/sh\nif [ "$1" = "--version" ]; then echo '${name} version 1.0'; else ${name === "psql" ? "echo 1" : "exit 0"}; fi\n`)
    chmodSync(join(root, "bin", name), 0o700)
  }
  const capabilities = [
    { id: "auth.github", status: "unverified", checked_at: "2026-09-06T12:00:00Z", summary: "Pending.", evidence_code: "pending", recovery_action_id: "authenticate.github" },
    { id: "handoff.claude_desktop", status: "unverified", checked_at: "2026-09-06T12:00:00Z", summary: "Pending.", evidence_code: "pending", recovery_action_id: "confirm.desktop_folder" },
    { id: "service.postgres", status: "unverified", checked_at: "2026-09-06T12:00:00Z", summary: "Pending.", evidence_code: "pending", recovery_action_id: "repair.postgres" },
    { id: "tool.git", status: "verified", checked_at: "2026-09-06T12:00:00Z", summary: "Available." },
    { id: "tool.node", status: "verified", checked_at: "2026-09-06T12:00:00Z", summary: "Available." },
    { id: "tool.npm", status: "verified", checked_at: "2026-09-06T12:00:00Z", summary: "Available." },
  ]
  const receipt = {
    contract_version: "1.0", kind: "first_app_bootstrap_receipt", run: { id: "00000000-0000-4000-8000-000000000001", sequence: 1 },
    application: { root, repository, commit, instructions: ["CLAUDE.md"] },
    provenance: { bootstrap: { repository, commit, version: `git:${commit}`, sha256: "b".repeat(64) }, template: { repository, commit, version: `git:${commit}` } },
    capabilities,
    participant_actions: [
      { id: "authenticate.github", kind: "authenticate", blocking: true, instruction: "Authenticate." },
      { id: "confirm.desktop_folder", kind: "grant_permission", blocking: true, instruction: "Confirm." },
      { id: "repair.postgres", kind: "repair", blocking: true, instruction: "Repair." },
    ],
    result: { status: "partial_failure", failed_capability_ids: ["auth.github", "handoff.claude_desktop", "service.postgres"] },
    redaction: { applied: false, fields: [] }, timestamps: { started_at: "2026-09-06T12:00:00Z", finished_at: "2026-09-06T12:00:01Z" },
  }
  writeFileSync(join(root, ".first-app", "receipt.json"), JSON.stringify(receipt))
  writeFileSync(join(root, "FIRST_APP_HANDOFF.md"), "generated")
  return root
}

test("records real checks through supported receipt fields without leaking connection values", async t => {
  const root = fixture()
  t.after(() => rmSync(root, { recursive: true, force: true }))
  // Assemble the fixture so the release-candidate scanner does not mistake a
  // deliberately fake test value for a committed credential.
  const secretUrl = ["postgresql", "://participant:", "super-secret-value", "@localhost/application"].join("")
  const environment = { ...process.env, PATH: `${join(root, "bin")}:${process.env.PATH}`, DATABASE_URL: secretUrl }
  const { receipt } = await verifyFirstSession(root, { environment, observePreview: async () => ({ started: true, preview: true }) })
  assert.equal(receipt.result.status, "success", JSON.stringify(receipt.result.failed_capability_ids))
  assert.ok(receipt.capabilities.filter(item => item.id.startsWith("desktop.")).every(item => item.status === "verified"))
  assert.ok(receipt.capabilities.find(item => item.id === "service.postgres")?.status === "verified")
  assert.deepEqual(receipt.participant_actions, [])
  const output = readFileSync(join(root, ".first-app", "receipt.json"), "utf8") + readFileSync(join(root, "FIRST_APP_HANDOFF.md"), "utf8")
  assert.doesNotMatch(output, /super-secret-value|postgresql:\/\//)
})

test("wrong root stops before changing either generated artifact", async t => {
  const root = fixture()
  t.after(() => rmSync(root, { recursive: true, force: true }))
  const receiptPath = join(root, ".first-app", "receipt.json")
  const before = readFileSync(receiptPath, "utf8")
  const other = join(root, "other")
  mkdirSync(other)
  await assert.rejects(() => verifyFirstSession(other), /handoff files are missing/)
  assert.equal(readFileSync(receiptPath, "utf8"), before)
})

test("future v1 minors are accepted and unknown capability states never become success", async t => {
  const root = fixture()
  t.after(() => rmSync(root, { recursive: true, force: true }))
  const receiptPath = join(root, ".first-app", "receipt.json")
  const receipt = JSON.parse(readFileSync(receiptPath, "utf8"))
  receipt.contract_version = "1.9"
  receipt.capabilities.push({ id: "future.capability", status: "future_state", checked_at: "2026-09-06T12:00:00Z", summary: "Unknown additive state." })
  receipt.future_field = { ignored: true }
  writeFileSync(receiptPath, JSON.stringify(receipt))
  const environment = { ...process.env, PATH: `${join(root, "bin")}:${process.env.PATH}`, DATABASE_URL: "postgresql://localhost/application" }
  const result = await verifyFirstSession(root, { environment, observePreview: async () => ({ started: true, preview: true }) })
  assert.equal(result.receipt.result.status, "partial_failure")
  assert.ok(result.receipt.result.failed_capability_ids.includes("future.capability"))
})

test("unsupported contract major fails closed without changing generated files", async t => {
  const root = fixture()
  t.after(() => rmSync(root, { recursive: true, force: true }))
  const receiptPath = join(root, ".first-app", "receipt.json")
  const receipt = JSON.parse(readFileSync(receiptPath, "utf8"))
  receipt.contract_version = "2.0"
  writeFileSync(receiptPath, JSON.stringify(receipt))
  const beforeReceipt = readFileSync(receiptPath, "utf8")
  const beforeHandoff = readFileSync(join(root, "FIRST_APP_HANDOFF.md"), "utf8")
  await assert.rejects(() => verifyFirstSession(root), /unsupported/)
  assert.equal(readFileSync(receiptPath, "utf8"), beforeReceipt)
  assert.equal(readFileSync(join(root, "FIRST_APP_HANDOFF.md"), "utf8"), beforeHandoff)
})
