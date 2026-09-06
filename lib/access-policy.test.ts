import assert from "node:assert/strict"
import test from "node:test"
import { isPublicPath } from "../proxy"

test("only authentication entry points and the landing page are public", () => {
  for (const path of ["/", "/sign-in", "/sign-up", "/api/auth/session"]) {
    assert.equal(isPublicPath(path), true, path)
  }

  for (const path of ["/dashboard", "/profile", "/resources", "/resources/deployment", "/unknown"]) {
    assert.equal(isPublicPath(path), false, path)
  }
})

test("prefix lookalikes do not bypass protection", () => {
  for (const path of ["/sign-injected", "/sign-updates", "/api/authentication"]) {
    assert.equal(isPublicPath(path), false, path)
  }
})
