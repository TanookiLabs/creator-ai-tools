import assert from "node:assert/strict"
import { existsSync } from "node:fs"
import { resolve } from "node:path"
import test from "node:test"
import { buildGuides, getBuildGuide, getBuildGuideSourceUrl } from "./build-guides"

test("every Build Guide has a unique routable slug and repository source", () => {
  assert.equal(new Set(buildGuides.map(({ slug }) => slug)).size, buildGuides.length)

  for (const guide of buildGuides) {
    assert.equal(getBuildGuide(guide.slug), guide)
    assert.equal(existsSync(resolve(process.cwd(), guide.repositoryPath)), true, guide.repositoryPath)
    assert.match(getBuildGuideSourceUrl(guide), new RegExp(`${guide.repositoryPath.replaceAll("/", "\\/")}$`))
  }
})

test("unknown guide slugs are recoverable through not-found handling", () => {
  assert.equal(getBuildGuide("not-a-real-guide"), undefined)
})
