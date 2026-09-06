import assert from "node:assert/strict"
import test from "node:test"
import { MAX_PROFILE_NAME_LENGTH, validateProfile } from "./profile-validation"

test("normalizes valid profile values without external calls", () => {
  assert.deepEqual(validateProfile({ name: "  Neutral Participant  ", image: "  https://example.test/avatar.png  " }), {
    errors: {},
    values: { name: "Neutral Participant", image: "https://example.test/avatar.png" },
  })
})

test("allows an empty optional avatar", () => {
  assert.deepEqual(validateProfile({ name: "Participant", image: "  " }).errors, {})
})

test("rejects empty and overlong names", () => {
  assert.equal(validateProfile({ name: " ", image: "" }).errors.name, "Enter a name to continue.")
  assert.match(validateProfile({ name: "x".repeat(MAX_PROFILE_NAME_LENGTH + 1), image: "" }).errors.name ?? "", /100 characters/)
})

test("accepts only http and https avatar URLs", () => {
  for (const image of ["javascript:alert(1)", "data:image/png;base64,abc", "not a URL"]) {
    assert.ok(validateProfile({ name: "Participant", image }).errors.image)
  }
  assert.equal(validateProfile({ name: "Participant", image: "http://example.test/avatar.png" }).errors.image, undefined)
})
