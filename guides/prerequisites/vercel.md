# Vercel

Vercel hosts this Next.js application and gives it a live URL. Git pushes trigger a build and deployment, but database migrations remain a separate, explicit release step.

**Quick link:** [vercel.com](https://vercel.com/) — sign up with your GitHub account

---

## Step 1: Create a Vercel account

1. Go to [vercel.com](https://vercel.com/)
2. Click **Sign Up**
3. Choose **Continue with GitHub** (recommended — this connects your repos automatically)
4. Authorize Vercel to access your GitHub account

The free **Hobby** plan is all you need for the hackathon.

---

## Step 2: Verify your account

After signing up, you should be able to see your Vercel dashboard at [vercel.com/dashboard](https://vercel.com/dashboard).

No local installation is required — Vercel connects to your GitHub repo and deploys when you push to its configured production branch.

---

## How deployment works

Once your project is connected to Vercel:

```
You write code locally
  → git push to GitHub
  → Vercel detects the push
  → Vercel builds and deploys your app
  → You get a live URL like slow-hackathon.vercel.app
```

Every push creates a new deployment. You can see all deployments in your Vercel dashboard.

---

## Deploying for the first time

You have two options:

### Option A: Use the Vercel dashboard

1. Go to [vercel.com/new](https://vercel.com/new)
2. Click **Import** next to your GitHub repo
3. Vercel auto-detects your framework (Next.js)
4. Add `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL`, `DATABASE_URL`, and `DIRECT_URL` as Production environment variables
5. Click **Deploy**

### Option B: Tell Claude Code

Open Claude Code in your project and say:

```
Deploy this to Vercel
```

Claude Code will handle the setup for you.

---

## Adding environment variables

Your app needs environment variables (like database credentials) to work in production:

1. Go to your project on [vercel.com](https://vercel.com/)
2. Click **Settings** → **Environment Variables**
3. Add each variable name and value
4. Redeploy for the changes to take effect

`BETTER_AUTH_SECRET`, `DATABASE_URL`, and `DIRECT_URL` are secrets and must stay server-only. Set `BETTER_AUTH_URL` to the final HTTPS production origin. Do not copy secrets into `NEXT_PUBLIC_` variables or commit them to `.env.example`.

---

## Migration and release verification

The Vercel build command is `prisma generate && next build`; it does not apply schema changes. After reviewing and committing a migration, run this once from a controlled release shell or migration job with production's `DIRECT_URL` available:

```bash
npm run db:migrate
```

Then deploy the application and verify the production URL: load the home page, sign up or sign in, confirm the redirect to `/dashboard`, test sign-out, and check deployment logs. Do not run `npm run db:push` against a shared or production database.

---

## Troubleshooting

| Problem                              | Fix                                                                                                                         |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------- |
| Can't see your GitHub repo in Vercel | Make sure you authorized Vercel to access your GitHub account during signup. Go to Settings → Git Integration to reconnect. |
| Deployment fails                     | Check the build logs in your Vercel dashboard — they usually tell you exactly what went wrong.                              |
| App works locally but not on Vercel  | You're probably missing environment variables. Add them in Settings → Environment Variables.                                |
| "Error: No framework detected"       | Make sure your project has a `package.json` with Next.js as a dependency.                                                   |

---

## More details

- [Vercel documentation](https://vercel.com/docs)
- [Deploying Next.js on Vercel](https://vercel.com/docs/frameworks/nextjs)
