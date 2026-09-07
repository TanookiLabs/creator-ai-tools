# Creator AI Tools

A ready-to-use starter for building and launching an app with Claude.

It includes authentication, a database, a polished interface, and everything you need to deploy with Vercel.

- [Hackathon show notes](show-notes.md)
- [Eric’s 201 talk slides](slides/slides.md)

## Get started

You need a [Claude account](https://claude.ai) and a [GitHub account](https://github.com/signup).

Open Terminal, paste this command, and press Return:

```bash
curl -fsSL https://raw.githubusercontent.com/TanookiLabs/creator-ai-tools/refs/tags/bootstrap-v1.0.0/setup.sh -o /tmp/creator-ai-setup.sh && /bin/bash /tmp/creator-ai-setup.sh
```

Follow the prompts. Setup will install or reuse the tools you need, prepare your copy of the starter, connect GitHub, start the local database, and open the project in Claude.

When Claude opens, tell it what you want to build.

## What is included

- Next.js and React
- TypeScript
- Better Auth
- Prisma and PostgreSQL
- Tailwind CSS and shadcn/ui
- GitHub integration
- Vercel deployment support
- Project instructions for Claude

## Build your app

Start by describing your idea to Claude:

> Build a dashboard for managing my brand partnerships.

> Create a membership site for my video courses.

> Make a tool that generates social media campaign ideas.

Claude will help you customize the starter, run it locally, and save your work to GitHub.

## Deploy with Vercel

When your app is ready, ask Claude:

> Deploy this app to Vercel.

Claude will walk you through signing in, connecting your GitHub repository, configuring the required project settings, and publishing the app.

You remain in control of account access, permissions, and deployment.

## Need help?

Run the setup command again. It will reuse completed steps and preserve your project.

- [Setup troubleshooting](guides/prerequisites/claude-desktop.md)
- [Starting a project](guides/build/starting-a-project.md)
- [Deploying with Vercel](guides/build/deployment.md)
