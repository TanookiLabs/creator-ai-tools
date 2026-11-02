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
const signIn = source("app/sign-in/page.tsx")
const signUp = source("app/sign-up/page.tsx")

test("authenticated navigation exposes the complete participant journey", () => {
  for (const destination of ["/dashboard", "/profile"]) {
    assert.match(shell, new RegExp(`href: "${destination}"`))
  }
  assert.match(shell, /aria-current=/)
  assert.match(shell, /authClient\.signOut\(\)/)
  assert.match(shell, /router\.replace\("\/sign-in"\)/)
  assert.match(shell, /Sign out failed\. Please try again\./)
})

test("dashboard is a neutral starting point without fabricated activity", () => {
  assert.match(dashboard, /Your app starts here/)
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

test("shell, dashboard, and profile retain keyboard and responsive affordances", () => {
  assert.match(shell, /aria-label="Primary navigation"/)
  assert.match(shell, /focus-visible:ring-2/)
  assert.match(shell, /flex-col[^"]*sm:flex-row/)
  assert.match(dashboard, /w-full[^"]*sm:w-auto/)
  assert.match(profile, /<form onSubmit=/)
  assert.match(profile, /htmlFor="profile-name"/)
  assert.match(profile, /w-full sm:w-auto/)
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
