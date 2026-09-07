import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { resolve } from "node:path"
import test from "node:test"

function source(path: string) {
  return readFileSync(resolve(process.cwd(), path), "utf8")
}

const shell = source("components/authenticated-shell.tsx")
const dashboard = source("app/(authenticated)/dashboard/page.tsx")
const profile = source("app/(authenticated)/profile/page.tsx")
const guides = source("app/(authenticated)/resources/page.tsx")
const guideDetail = source("app/(authenticated)/resources/setup/[guide]/page.tsx")
const signIn = source("app/sign-in/page.tsx")
const signUp = source("app/sign-up/page.tsx")

test("authenticated navigation exposes the complete participant journey", () => {
  for (const destination of ["/dashboard", "/profile", "/resources"]) {
    assert.match(shell, new RegExp(`href: "${destination}"`))
  }
  assert.match(shell, /aria-current=/)
  assert.match(shell, /authClient\.signOut\(\)/)
  assert.match(shell, /router\.replace\("\/sign-in"\)/)
  assert.match(shell, /Sign out failed\. Please try again\./)
})

test("dashboard remains neutral and explicitly rejects fabricated activity", () => {
  assert.match(dashboard, /does not assume a project or fill in activity for you/)
  assert.match(dashboard, /starting directions, not saved selections/)
  assert.doesNotMatch(dashboard, /recent activity|percent complete|completion rate|due date|your projects|welcome back/i)
})

test("profile communicates loading, session, validation, save, and retry states", () => {
  for (const evidence of [
    /Loading your profile/,
    /Your session has ended/,
    /aria-invalid/,
    /Your entries are still here/,
    /Your profile was saved/,
    /Try again/,
  ]) assert.match(profile, evidence)
})

test("Build Guides are clearly documentation-only and all cards target the detail route", () => {
  assert.match(guides, /documentation only and does not mean a tool or service is connected/)
  assert.match(guides, /href={`\/resources\/setup\/\${guide\.slug}`}/)
  assert.match(guideDetail, /getBuildGuide\(slug\)/)
  assert.match(guideDetail, /does not check connection status, enable an integration, or collect credentials/)
})

test("shell, dashboard, profile, and guides retain keyboard and responsive affordances", () => {
  assert.match(shell, /aria-label="Primary navigation"/)
  assert.match(shell, /focus-visible:ring-2/)
  assert.match(shell, /flex-col[^"]*sm:flex-row/)
  assert.match(dashboard, /sm:grid-cols-2/)
  assert.match(dashboard, /w-full[^"]*sm:w-auto/)
  assert.match(profile, /<form onSubmit=/)
  assert.match(profile, /htmlFor="profile-name"/)
  assert.match(profile, /w-full sm:w-auto/)
  assert.match(guides, /focus-visible:ring-2/)
  assert.match(guides, /sm:grid-cols-2 lg:grid-cols-3/)
  assert.match(guideDetail, /focus-visible:ring-2/)
})

test("authenticated errors and unknown pages provide keyboard-operable recovery", () => {
  const error = source("app/(authenticated)/error.tsx")
  const notFound = source("app/(authenticated)/not-found.tsx")
  assert.match(error, /role="alert"/)
  assert.match(error, /onClick={reset}/)
  assert.match(notFound, /href="\/dashboard"/)
})

test("auth credentials never use a query-string form submission", () => {
  for (const form of [signIn, signUp]) {
    assert.match(form, /<form method="post" onSubmit={handleSubmit}/)
    assert.match(form, /e\.preventDefault\(\)/)
    assert.doesNotMatch(form, /method="get"/)
  }
})
