# Hackathon Starter: Next.js + Better Auth + Prisma

> **[Show Notes: Tools, APIs & Strategies from the Hackathon](show-notes.md)** — Everything we covered: Ralph loops, Apify, Shopify JSON trick, Twilio, Stripe, data enrichment, mapping, and more.
>
> **[Eric's 201 Talk Slides](slides/slides.md)** — Advanced AI coding: complex apps, Ralph loops, Chrome integration, custom skills, deployment, background jobs, and more.

Pre-configured for the AI Bootcamp with Better Auth for email/password authentication and Prisma ORM for type-safe database queries. No third-party auth services — everything runs through your own database.

## What's Included

- **Next.js 16** (App Router) with TypeScript and React 19
- **Better Auth** for email/password authentication (database sessions, built-in API endpoints)
- **Prisma ORM** for type-safe PostgreSQL queries and reviewed migrations
- **Tailwind CSS** + **shadcn/ui** components
- **Claude Code config** (CLAUDE.md + custom slash commands)
- **Reviewed Prisma migrations** with a committed Better Auth baseline
- Ready to deploy on **Vercel**

## Build Guides

These repository-native workflow guides complement the setup instructions below. They document safe, agent-usable steps only: external services and integrations remain opt-in and controlled by their user or organization owner.

- [Start a project](guides/build/starting-a-project.md)
- [Deploy the application](guides/build/deployment.md)
- [Shopify integration (opt-in example)](guides/build/shopify-opt-in.md)
- [Environment variables and secrets](guides/build/environment-variables-and-secrets.md)
- [APIs and webhooks](guides/build/apis-and-webhooks.md)

Signed-in users can also browse these alongside the existing prerequisite documentation in **Build Guides** at `/resources`.

## Quality checks

Run `npm run test:quality` for deterministic auth-policy, profile, navigation, neutral-copy, Build Guides, error-recovery, keyboard-contract, and responsive-contract coverage. The test uses no shared accounts or integrations. See [participant journey quality verification](docs/quality-verification.md) for the exact scope and the documented browser-automation gap.

Before handing off a clean template release, follow the
[provider-neutral release handoff](docs/release-handoff.md). Its
`npm run verify:template` gate checks the empty environment contract, scans
release-candidate files for credential signatures, and confirms release paths
cannot seed or reset data.

## What you see after signing in

`/dashboard` is a protected welcome workspace that demonstrates authenticated navigation, an optional browser-local onboarding checklist, and links to external project resources. The checklist is stored only in the visitor's browser; it does not create database records. The linked `/profile` page is a working, minimal example of an authenticated form: it updates the signed-in user's existing Better Auth name and optional image URL without requiring an additional database table.

## Set up your Mac

This is the recommended local setup for a new **macOS** computer. You only need:

1. A [GitHub account](https://github.com/signup)
2. An active [Claude subscription](https://claude.ai)

Open the Terminal app and run:

```bash
curl -fsSL https://raw.githubusercontent.com/ericskiff/vibe-setup/main/setup.sh | bash
```

The interactive script installs the development tools, a local Postgres database, GitHub CLI, Claude Code, and the Claude desktop app. It asks for your Mac password only when macOS requires it and opens a browser for GitHub sign-in. It is safe to run again: installed tools are detected and skipped.

The script is macOS-only. It makes user-level development-tool and shell-profile changes; if you prefer to inspect it before running, download [setup.sh](setup.sh) from this repository and run `bash setup.sh` from its directory.

### Continue with Claude

At completion, the script saves `~/Documents/src/FIRST_APP_HANDOFF.md` and copies it to your clipboard. Open a new Terminal window and run:

```bash
cd ~/Documents/src
claude --dangerously-skip-permissions
```

Paste the handoff when Claude is ready. Claude checks the local environment, helps choose a project, creates a local app with Postgres, and guides the first edit, commit, and push.

### Use this starter from a ZIP

If you received this starter as a ZIP, extract it inside `~/Documents/src` after the bootstrap completes. Open the extracted folder in Claude Code and ask Claude to set up the existing project. Do not use the first-app handoff to scaffold over an extracted starter.

For this Next.js + Better Auth + Prisma project, Claude should use the checked-in `.env.example`, run the reviewed migration command `npm run db:migrate`, and start the app with `npm run dev`. Do not use `db:push` to adopt an existing database; see [Prisma migration lifecycle](docs/prisma-migrations.md) if the database already contains Better Auth tables.

## Manual setup (advanced)

Make sure you have all of these installed before starting. Click the **Setup guide** link for detailed step-by-step instructions.

| Prerequisite | Quick Download | Setup Guide |
| ------------ | -------------- | ----------- |
| **Node.js & npm** | [nodejs.org](https://nodejs.org/) (LTS) | [Step-by-step guide](guides/prerequisites/nodejs.md) |
| **Git** | Mac: `xcode-select --install` · Win: [git-scm.com](https://git-scm.com/) | [Step-by-step guide](guides/prerequisites/git.md) |
| **GitHub & GitHub CLI** | [github.com](https://github.com/) · [cli.github.com](https://cli.github.com/) | [Step-by-step guide](guides/prerequisites/github.md) |
| **VS Code** | [code.visualstudio.com](https://code.visualstudio.com/) | [Step-by-step guide](guides/prerequisites/vscode.md) |
| **Claude Code** | `npm install -g @anthropic-ai/claude-code` | [Step-by-step guide](guides/prerequisites/claude-code.md) |
| **Vercel** | [vercel.com](https://vercel.com/) (sign in with GitHub) | [Step-by-step guide](guides/prerequisites/vercel.md) |
| **Neon** | [neon.tech](https://neon.tech/) | [Step-by-step guide](guides/prerequisites/neon.md) |

Verify your tools are installed:

```bash
node --version    # v22.x.x
npm --version     # 10.x.x
git --version     # 2.x.x
gh --version      # 2.x.x
claude --version
```

## Quick Start

### 1. Clone the template and install

```bash
git clone https://github.com/slow-ventures/creator-ai-tools.git slow-hackathon
cd slow-hackathon
rm -rf .git
npm install
```

The `rm -rf .git` removes the template's git history so you start fresh with your own repo.

### 2. Initialize Git and create a GitHub repository

Your project needs its own Git repository so you can save your work and deploy to Vercel.

Initialize Git and make your first commit:

```bash
git init
git add .
git commit -m "initial commit from hackathon starter"
```

Now you need a GitHub repository to push your code to. Pick **one** of the two options below:

#### Option A: Using the GitHub CLI (if you have it installed)

```bash
gh repo create slow-hackathon --public --source=. --push
```

This creates a new repo on GitHub and pushes your code in one step. Done!

#### Option B: Create the repo on GitHub.com (works for everyone)

1. Go to [github.com/new](https://github.com/new)
2. Enter a **Repository name** (e.g., `slow-hackathon`)
3. Leave it set to **Public**
4. **Do NOT** check "Add a README file" — your project already has files
5. Click **Create repository**
6. GitHub will show you a page with setup instructions. Find the section that says **"…or push an existing repository from the command line"** and copy the URL. It will look like `https://github.com/YOUR-USERNAME/slow-hackathon.git`
7. Back in your terminal, run these two commands (replace the URL with yours):

```bash
git remote add origin https://github.com/YOUR-USERNAME/slow-hackathon.git
git push -u origin main
```

8. Refresh the GitHub page — you should see all your project files

### 3. Configure local environment

```bash
cp .env.example .env
```

Now generate a secret key for authentication. Run this in your terminal:

```bash
openssl rand -base64 32
```

This prints a random secret string. Copy it into `BETTER_AUTH_SECRET` in `.env`, then set `BETTER_AUTH_URL` to the local application origin. Leave the file open — you'll fill in the database credentials in the next step.

### 4. Set up Neon

You'll create a **Neon project** with two branches — one for development and one for production. This keeps your dev data completely separate from your live app.

1. Go to [console.neon.tech](https://console.neon.tech/)
2. Create a project named `slow-hackathon`
3. On the project dashboard, go to **Connection Details**
4. Select **Prisma** from the framework dropdown
5. Copy the `DATABASE_URL` and `DIRECT_URL`

> ⚠️ **Important:** You need both URLs. `DATABASE_URL` uses the connection pooler (has `-pooler` in the hostname). `DIRECT_URL` is for migrations and uses the direct connection.

Paste your connection strings into `.env`:
- `DATABASE_URL` — your Neon pooled connection string
- `DIRECT_URL` — your Neon direct connection string

### 5. Apply the database baseline

```bash
npm run db:migrate
```

This creates the auth tables in a new dev database from the committed baseline. If this database already has Better Auth tables from an earlier `db:push`, follow the non-destructive adoption rehearsal in [Prisma migration lifecycle](docs/prisma-migrations.md) instead.

### 6. Create local development fixtures (optional)

```bash
npm run db:seed:local
```

This is an opt-in convenience for a local development database only. The fixture command refuses to run outside `NODE_ENV=development`, creates distinct generated passwords, and is idempotent. Save the generated credentials from your terminal if you need to sign in as a fixture user.

Do not run fixture commands against a shared, staging, or production database. A fresh database after `npm run db:migrate` contains only the schema and indexes; you can instead create your own account through the sign-up screen.

### 7. Run it

```bash
npm run dev
```

Open [localhost:3000](http://localhost:3000) in your browser. You can sign up with any email/password.

### 8. Deploy to Vercel (verified route)

Your project has two branches: `main` (where you work) and `production` (what Vercel deploys). This means you can push code to `main` as much as you want without affecting your live site. When you're ready to go live, you push to `production`.

#### Link your project

```bash
npx vercel link
```

This will ask you to log in (opens a browser), then connects your local project to Vercel. Accept the default settings when prompted.

#### Set the production branch

Go to your project on [vercel.com](https://vercel.com/), then **Settings → Git → Production Branch** and change it from `main` to `production`.

This is the only step that requires the Vercel dashboard — everything else is done from the terminal.

#### Add production environment variables

```bash
npx vercel env add BETTER_AUTH_SECRET production
```

When prompted, paste a production-only secret and press Enter. Do not reuse development secrets across environments.

```bash
npx vercel env add BETTER_AUTH_URL production
```

Enter your production URL (e.g., `https://slow-hackathon.vercel.app`).

```bash
npx vercel env add DATABASE_URL production
```

Paste your **prod** Neon pooled connection string (has `-pooler` in hostname).

```bash
npx vercel env add DIRECT_URL production
```

Paste your **prod** Neon direct connection string.

#### Deploy

Push your code to the `production` branch to trigger a deploy:

```bash
git push origin main:production
```

This pushes your `main` branch to `production` on GitHub. Vercel will build your app and give you a live URL (e.g., `slow-hackathon.vercel.app`).

The Vercel build runs `prisma generate && next build` and never changes the database. Before deploying code that depends on a reviewed migration, run the explicit production command against the production `DIRECT_URL` from a controlled deployment shell or migration job:

```bash
npm run db:migrate
```

Commit and review migration SQL before this step. Do not run `db:push` against production.

#### Verify the release

After the migration command reports success and Vercel marks the deployment **Ready**:

1. Open the production `BETTER_AUTH_URL` over HTTPS and confirm the home page loads.
2. Create a new account or sign in with a production account; do not use local fixtures as production credentials.
3. Confirm the redirect reaches `/dashboard`, the account menu can open and save `/profile`, and the dashboard's external resource links load.
4. Check the Vercel deployment logs for runtime errors. If the release includes schema work, confirm the expected migration is recorded in that environment before treating the release as complete.

#### Deploying updates

Every time you want to update your live site, push to `production`:

```bash
git push origin main:production
```

Or use the `/deploy` slash command in Claude Code, which does this for you.

## How It Works: Dev vs Production

```
LOCAL DEVELOPMENT (main branch)
  .env → DATABASE_URL + DIRECT_URL point to your Neon dev branch
  npm run db:push → optional fast sync for disposable prototypes
  npm run db:migrate → applies reviewed, committed migrations
  npm run dev → runs app against dev database
  git push → pushes to main (does NOT deploy)

PRODUCTION (production branch → Vercel)
  git push origin main:production → triggers Vercel deploy
  Vercel env vars → DATABASE_URL + DIRECT_URL point to your Neon prod branch
  migration job/shell → npm run db:migrate applies reviewed migrations
  Vercel builds → prisma generate → next build (no database mutation)
  Your app and production database are both updated
```

| Environment | Database | How Schema Gets Updated |
|-------------|----------|------------------------|
| **Prototype dev** | Disposable Neon dev branch (from `.env`) | `npm run db:push` |
| **Staging / production** | Neon branch for that environment | Explicit `npm run db:migrate` after migration review |

## Other hosting platforms

Vercel is the deployment path exercised by this project. Render and DigitalOcean can host the same Next.js application without changing application dependencies, provided their build and release configuration follows the same sequence:

1. Supply `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL`, `DATABASE_URL`, and `DIRECT_URL` through the platform's encrypted environment-variable store.
2. Run `npm ci` and `npm run build` as the build step; builds must not mutate the database.
3. Run `npm run db:migrate` once as a controlled release/pre-deploy job using the target environment's direct database URL.
4. Start the app with `npm run start`, expose it through HTTPS, and set `BETTER_AUTH_URL` to that public canonical origin.
5. Perform the same sign-in, dashboard, sign-out, and deployment-log verification listed above.

For Render, configure the migration as a one-off release step rather than as part of every web-process start. For DigitalOcean App Platform, use a dedicated job/component or a controlled deploy command for the migration. Keep runtime and migration credentials scoped to the target environment, and do not add a platform SDK solely for deployment.

## Using Claude Code

This project comes with a `CLAUDE.md` and custom slash commands pre-configured. Open Claude Code in this directory and try:

| Command      | What It Does                                                       |
| ------------ | ------------------------------------------------------------------ |
| `/plan`      | Turn your idea into a requirements + build plan                    |
| `/build`     | Execute the plan step by step                                      |
| `/add-table` | Add a new model to the Prisma schema                               |
| `/add-ai`    | Add an AI feature (image gen, text gen, chat)                      |
| `/design`    | Build or redesign a UI from a description                          |
| `/fix`       | Debug and fix the current error                                    |
| `/snapshot`  | Save a local git checkpoint                                        |
| `/deploy`    | Commit, push to GitHub, and deploy (run reviewed migrations separately first) |
| `/help`      | Show all available commands and tips                                |

## Adding Features

Tell Claude Code what you want to add. Some examples:

- "Add a dashboard page that shows a list of my brand deals"
- "Add image generation using Replicate — let users describe an image and generate it"
- "Add a contact form that saves submissions to the database"
- "Add Stripe checkout so users can buy my digital products"

## Authentication

Authentication uses **Better Auth** with email/password. Sessions are stored in the database (not JWTs), so they can be revoked at any time.

### Get the current user in a Server Component or Server Action

```typescript
import { auth } from "@/lib/auth"
import { headers } from "next/headers"

const session = await auth.api.getSession({
  headers: await headers(),
})
const user = session?.user // { id, name, email, emailVerified, image, createdAt, updatedAt }
```

### Get the current user in a Client Component

```typescript
"use client"
import { authClient } from "@/lib/auth-client"

const { data: session, isPending } = authClient.useSession()
const user = session?.user
```

No `<SessionProvider>` wrapper is needed — Better Auth uses reactive stores internally.

### Route protection

All routes are protected by default — any page you create requires login automatically. Public routes (like the homepage and sign-in pages) are explicitly whitelisted in `proxy.ts`.

To make a new route public, add it to the `publicRoutes` array:

```typescript
// proxy.ts
const publicRoutes = ["/", "/sign-in", "/sign-up", "/api/auth", "/pricing"]
```

For an additional layer of protection, pages inside `app/(authenticated)/` are wrapped by a layout that checks the session server-side. To add a new protected page, just create it inside that folder:

```
app/(authenticated)/dashboard/page.tsx   → /dashboard (protected)
app/(authenticated)/settings/page.tsx    → /settings (protected)
```

The `(authenticated)` folder name is a Next.js route group — it doesn't appear in the URL.

### Add OAuth providers (optional)

To add Google, GitHub, Discord, or other OAuth providers alongside email/password, edit `lib/auth.ts`:

```typescript
import { betterAuth } from "better-auth"

export const auth = betterAuth({
  // ...existing config
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    },
  },
})
```

Then add `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` to your `.env`.

## Database with Prisma ORM

Your database schema is defined in `prisma/schema.prisma`. This is the single source of truth for your tables.

### Define a model

```prisma
// prisma/schema.prisma
model Product {
  id        String   @id @default(cuid())
  name      String
  price     Int
  userId    String
  createdAt DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("products")
}
```

Don't forget to add the relation to the User model too:

```prisma
model User {
  // ... existing fields
  products Product[]
}
```

### Synchronize the database

```bash
npm run db:migrate:dev -- --name add_product
npm run db:migrate
```

The first command creates a migration for review; the second applies committed migrations. Use `npm run db:push` only for disposable prototype databases. Vercel builds do not run migrations. See [Prisma migration lifecycle](docs/prisma-migrations.md) for the Better Auth baseline, populated-database rehearsal, and URL roles.

### Query data

```typescript
import { prisma } from "@/lib/db/prisma"

// Read all
const allProducts = await prisma.product.findMany()

// Insert
await prisma.product.create({
  data: { name: "T-Shirt", price: 2500, userId: session.user.id },
})

// Filter
const cheap = await prisma.product.findMany({
  where: { price: { lt: 1000 } },
})
```

### Browse data

```bash
npm run db:studio
```

Opens Prisma Studio — a visual data browser at localhost:5555.

## Project Structure

```
proxy.ts                        ← Route protection (all routes require login by default)
prisma/
  schema.prisma                 ← Database schema (auth tables + your tables)
  fixtures/development.ts       ← Guarded, opt-in local development fixtures
app/
  page.tsx                      ← Homepage (public)
  layout.tsx                    ← Root layout (fonts, theme)
  globals.css                   ← Tailwind + CSS variables
  sign-in/page.tsx              ← Email/password sign-in form (public)
  sign-up/page.tsx              ← Registration form (public)
  api/auth/[...all]/
    route.ts                    ← Better Auth API route handler
  (authenticated)/
    layout.tsx                  ← Auth check layout (redirects if not signed in)
    dashboard/
      page.tsx                  ← Protected welcome workspace and local onboarding checklist
    profile/
      page.tsx                  ← Authenticated profile form (name and image URL)
    resources/                  ← Optional protected workshop reference pages
components/
  ui/                           ← shadcn/ui components (button, card, input, etc.)
  auth-button.tsx               ← Login/user button (switches based on session)
  sign-in-button.tsx            ← Sign in / Sign up links
  user-button.tsx               ← User dropdown with profile and sign-out links
lib/
  auth.ts                       ← Better Auth server config (Prisma adapter, session settings)
  auth-client.ts                ← Better Auth client helpers (React hooks)
  db/
    prisma.ts                   ← Database client (Prisma)
  utils.ts                      ← cn() helper for classnames
.claude/
  commands/                     ← Custom Claude Code slash commands
CLAUDE.md                       ← Claude Code project config
.env.example                    ← Environment variable template
```

## Environment Variables and secret boundaries

Copy `.env.example` to `.env` and fill in the values you need:

| Variable | Required | Purpose and boundary |
| --- | --- | --- |
| `BETTER_AUTH_SECRET` | Yes | Server-only secret used to sign Better Auth data. Generate a different value per environment. |
| `BETTER_AUTH_URL` | Yes | Public canonical origin for the current environment; not a credential. |
| `DATABASE_URL` | Yes | Pooled runtime PostgreSQL URL. Keep it server-only. |
| `DIRECT_URL` | Yes | Direct PostgreSQL URL used by Prisma Migrate. Keep it server-only and use it only in controlled migration jobs. |
| `REPLICATE_API_TOKEN`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` | Only when the corresponding integration is added | Server-only provider credentials. |
| `STRIPE_SECRET_KEY`, `RESEND_API_KEY` | Only when the corresponding integration is added | Server-only provider credentials. |
| `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` | Only when Stripe client code is added | A browser-visible identifier, not a secret. Never put a secret in a `NEXT_PUBLIC_` variable. |

`.env` is local-only and ignored by Git. `.env.example` documents names and contains no credentials. Put production values in the host's encrypted environment settings; use separate development, staging, and production database branches or projects. Do not paste values into the README, commits, issue comments, or client-side code.
