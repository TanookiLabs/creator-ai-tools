import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import test from "node:test"

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
