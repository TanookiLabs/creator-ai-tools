import assert from "node:assert/strict"
import test from "node:test"
import { safeAuthDestination } from "./auth-redirect"

test("keeps local protected paths, queries, and fragments", () => {
  assert.equal(safeAuthDestination("/profile?tab=account#name"), "/profile?tab=account#name")
})

test("defaults absent and off-site return targets to the dashboard", () => {
  for (const target of [null, "", "https://evil.example", "//evil.example", "/\\evil.example"]) {
    assert.equal(safeAuthDestination(target), "/dashboard")
  }
})

test("prevents authentication endpoint redirect loops", () => {
  assert.equal(safeAuthDestination("/sign-in?callbackUrl=/profile"), "/dashboard")
  assert.equal(safeAuthDestination("/api/auth/sign-in"), "/dashboard")
})
