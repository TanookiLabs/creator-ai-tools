# Vercel deployment (experimental)

Vercel is the experimental assistant-led production path for this Next.js app.
Ask the assistant to “Deploy this application to Vercel”; do not use a custom
repository deployment command or paste configuration values into chat.

The assistant rediscovers Vercel authentication, the linked project, Postgres
integration, production variable names, canonical domain, and deployment state
before resuming. The participant completes browser login/OAuth, any Marketplace
provider agreement or plan selection, and one final production confirmation.

A template `origin`, absent participant repository, or absent Vercel CLI is
repairable. The assistant never pushes to the template: it makes it a
fetch-only `template` remote, then can create a private participant `origin`
before Vercel discovery when the participant explicitly requests deployment.
It verifies the owner and remote `participant-work` commit without overwriting
a conflicting branch. It uses `npx --yes vercel@latest`, so no global CLI
installation is needed. An unchanged starter is a warning, not a blocker, for
an explicitly approved disposable rehearsal.

Vercel Marketplace is the normal way to reuse or connect Postgres. Existing
projects, integrations, and healthy auth secrets are reused. The assistant
keeps `DATABASE_URL`, `DIRECT_URL`, and `BETTER_AUTH_SECRET` values secret,
sets `BETTER_AUTH_URL` only to the selected canonical HTTPS origin, applies a
reviewed migration once, deploys, and observes the live app. It stops on any
failure without a destructive database repair or automatic retry.

This path remains experimental until a disposable end-to-end rehearsal passes.
