import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import test from "node:test"

const readJson = (path: string) => JSON.parse(readFileSync(path, "utf8"))
const examples = [
  "docs/contracts/examples/success.json",
  "docs/contracts/examples/partial-failure.json",
]
const secretPattern = /-----BEGIN .*PRIVATE KEY-----|github_pat_|gh[pousr]_|sk_(?:live|test)_|whsec_|postgres(?:ql)?:\/\/[^\s@]+:[^\s@]+@|authorization\s*:/i
const timestampPattern = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/
const commitPattern = /^[0-9a-f]{40}$/

test("v1 examples contain the required producer/consumer fields and no secrets", () => {
  for (const path of examples) {
    const receipt = readJson(path)
    assert.match(receipt.contract_version, /^1\.\d+$/)
    assert.equal(receipt.kind, "first_app_bootstrap_receipt")
    for (const field of ["run", "application", "provenance", "capabilities", "participant_actions", "result", "redaction", "timestamps"]) {
      assert.ok(receipt[field] !== undefined, `${path}: missing ${field}`)
    }
    assert.ok(receipt.application.root.startsWith("/"))
    assert.match(receipt.application.commit, commitPattern)
    assert.equal(receipt.provenance.bootstrap.source_branch, "main")
    assert.equal(receipt.provenance.template.source_branch, "main")
    assert.match(receipt.provenance.template.commit, commitPattern)
    assert.match(receipt.provenance.bootstrap.sha256, /^[0-9a-f]{64}$/)
    assert.match(receipt.timestamps.started_at, timestampPattern)
    assert.match(receipt.timestamps.finished_at, timestampPattern)
    assert.deepEqual(receipt.capabilities.map((item: { id: string }) => item.id), [...receipt.capabilities.map((item: { id: string }) => item.id)].sort())
    assert.deepEqual(receipt.participant_actions.map((item: { id: string }) => item.id), [...receipt.participant_actions.map((item: { id: string }) => item.id)].sort())
    assert.deepEqual(receipt.result.failed_capability_ids, [...receipt.result.failed_capability_ids].sort())
    assert.doesNotMatch(JSON.stringify(receipt), secretPattern)
  }
})

test("success and partial failure examples obey derived result semantics", () => {
  const success = readJson(examples[0])
  assert.equal(success.result.status, "success")
  assert.ok(success.capabilities.every((item: { status: string }) => item.status === "verified"))
  assert.ok(success.participant_actions.every((item: { blocking: boolean }) => !item.blocking))

  const partial = readJson(examples[1])
  assert.equal(partial.result.status, "partial_failure")
  const nonVerified = partial.capabilities.filter((item: { status: string }) => item.status !== "verified").map((item: { id: string }) => item.id).sort()
  assert.deepEqual(partial.result.failed_capability_ids, nonVerified)
  assert.ok(partial.participant_actions.some((item: { blocking: boolean }) => item.blocking))
})

test("local contract artifacts are root-anchored and ignored", () => {
  const ignore = readFileSync(".gitignore", "utf8").split(/\r?\n/)
  assert.ok(ignore.includes("/FIRST_APP_HANDOFF.md"))
  assert.ok(ignore.includes("/.first-app/"))
})

test("durable instructions fail closed and retain generated files locally", () => {
  const instructions = readFileSync("CLAUDE.md", "utf8")

  assert.match(instructions, /receipt\.json` as authoritative/)
  assert.match(instructions, /major version `1`/)
  assert.match(instructions, /unknown capability states as `unverified`/)
  assert.match(instructions, /version is missing, malformed, or has an unsupported major/)
  assert.match(instructions, /stop\s+automated interpretation/)
  assert.match(instructions, /Preserve all participant files/)
  assert.match(instructions, /must remain root-anchored in `\.gitignore`/)
  assert.match(instructions, /never commit, relocate, or edit/)
  assert.doesNotMatch(instructions, /--dangerously-skip-permissions/)
  assert.doesNotMatch(instructions, /(?:\/Users\/|\/home\/)[^\s`]+/)
})
