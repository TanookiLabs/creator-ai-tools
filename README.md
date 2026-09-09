# Creator AI Tools

Build and launch a full-stack app with Claude. This starter includes a polished
Next.js interface, authentication, a PostgreSQL database, and a supported path
to Vercel production.

## Start your project

You need a [Claude account](https://claude.ai) and a
[GitHub account](https://github.com/signup).

Open Terminal, paste this command, and press Return:

```bash
curl -fsSL https://raw.githubusercontent.com/TanookiLabs/creator-ai-tools/main/setup.sh -o /tmp/creator-ai-setup.sh && /bin/bash /tmp/creator-ai-setup.sh
```

Follow the prompts. Setup installs or reuses the tools you need, prepares your
copy of this starter, connects GitHub, starts the local database, and opens
Claude Desktop.

## Build your app

When Claude opens, describe what you want to build. It can customize the
existing Next.js, TypeScript, Better Auth, and Prisma application; run it
locally; and save your work to your GitHub repository.

> Build a dashboard for managing my brand partnerships.

> Create a membership site for my video courses.

> Make a tool that generates social media campaign ideas.

## Guides

Use these guides when you want to understand or complete a part of the setup
yourself.

### Get started

- [Start a project](guides/build/starting-a-project.md)
- [Manual macOS setup](guides/prerequisites/manual-macos-setup.md)
- [Manual Windows setup](guides/prerequisites/manual-windows-setup.md)
- [Setup troubleshooting](guides/prerequisites/claude-desktop.md)

### Add capabilities

- [OpenRouter setup](guides/openrouter-setup.md) — make a secure first AI request
- [Vercel AI chat](guides/vercel-ai-chat.md) — build an AI chat experience
- [Resend email setup](guides/resend-email-setup.md) — send transactional email
- [Background agents with Inngest](guides/background-agents-with-inngest.md)
- [APIs and webhooks](guides/build/apis-and-webhooks.md)
- [Shopify integration](guides/build/shopify-opt-in.md)

### Deploy

- [Manual Vercel deployment](guides/manual-vercel-deployment.md)

## Vercel deployment

When the reviewed app is ready, ask your assistant:

> Deploy this application to Vercel.

The assistant-led workflow is reviewed and production-only: it keeps secrets
out of chat, presents one final non-secret production summary, and stops on a
failed migration, deployment, or smoke check. It passed the live
participant-owned `vercel-test-3` rehearsal with Vercel, Neon, Better Auth,
and browser sign-up, sign-out, sign-in, session persistence, and authenticated
dashboard checks.

Prefer to perform the setup yourself? Follow the
[manual Vercel deployment guide](guides/manual-vercel-deployment.md).

## Need help?

Run the setup command again. It will reuse completed steps and preserve your
project.

- [Setup troubleshooting](guides/prerequisites/claude-desktop.md)
- [Starting a project](guides/build/starting-a-project.md)

## Resources

### Included technologies

- Next.js and React
- TypeScript
- Better Auth
- Prisma and PostgreSQL
- Tailwind CSS and shadcn/ui
- GitHub integration
- Vercel deployment support
- Project instructions for Claude

- [Hackathon show notes](show-notes.md)
- [Eric’s 201 talk slides](slides/slides.md)
