export const buildGuides = [
  {
    slug: "starting-a-project",
    title: "Start a project",
    description: "Create an independently owned project from this starter and verify the local baseline.",
    repositoryPath: "guides/build/starting-a-project.md",
  },
  {
    slug: "deployment",
    title: "Deploy the application",
    description: "Release a reviewed commit with explicit migration, ownership, and rollback boundaries.",
    repositoryPath: "guides/build/deployment.md",
  },
  {
    slug: "manual-vercel-deployment",
    title: "Deploy to Vercel yourself",
    description: "Set up Vercel, Neon, Better Auth, migrations, and a Git-backed production deployment manually.",
    repositoryPath: "guides/manual-vercel-deployment.md",
  },
  {
    slug: "resend-email-setup",
    title: "Send transactional email with Resend",
    description: "Plan a secure Resend sender, configuration, Better Auth email flows, and production verification.",
    repositoryPath: "guides/resend-email-setup.md",
  },
  {
    slug: "vercel-ai-chat",
    title: "Build a Vercel AI chat",
    description: "Add a streaming, authenticated AI chat with narrow server-side tools through Vercel AI Gateway.",
    repositoryPath: "guides/vercel-ai-chat.md",
  },
  {
    slug: "background-agents-with-inngest",
    title: "Run agents in the background",
    description: "Start durable, user-owned AI agents with safe progress updates, approvals, and recovery.",
    repositoryPath: "guides/background-agents-with-inngest.md",
  },
  {
    slug: "shopify-opt-in",
    title: "Shopify integration (opt-in)",
    description: "Evaluate and implement a user-owned Shopify connection only when explicitly chosen.",
    repositoryPath: "guides/build/shopify-opt-in.md",
  },
  {
    slug: "environment-variables-and-secrets",
    title: "Environment variables & secrets",
    description: "Classify, store, verify, rotate, and recover configuration without committing values.",
    repositoryPath: "guides/build/environment-variables-and-secrets.md",
  },
  {
    slug: "apis-and-webhooks",
    title: "APIs & webhooks",
    description: "Add opt-in APIs and signed, idempotent webhooks with safe failure behavior.",
    repositoryPath: "guides/build/apis-and-webhooks.md",
  },
  {
    slug: "nodejs",
    title: "Node.js & npm",
    description: "Install the JavaScript runtime and package manager used by this project.",
    repositoryPath: "guides/prerequisites/nodejs.md",
  },
  {
    slug: "git",
    title: "Git",
    description: "Install Git and confirm that source control is ready to use.",
    repositoryPath: "guides/prerequisites/git.md",
  },
  {
    slug: "github",
    title: "GitHub & GitHub CLI",
    description: "Set up the optional tools used to work with a GitHub repository.",
    repositoryPath: "guides/prerequisites/github.md",
  },
  {
    slug: "vscode",
    title: "VS Code",
    description: "Install and prepare the editor used in the starter guidance.",
    repositoryPath: "guides/prerequisites/vscode.md",
  },
  {
    slug: "claude-desktop",
    title: "Claude Desktop",
    description: "Confirm the exact project root and recover the macOS Desktop-first handoff.",
    repositoryPath: "guides/prerequisites/claude-desktop.md",
  },
  {
    slug: "claude-code",
    title: "Claude CLI recovery",
    description: "Use the normal CLI only when the primary Desktop handoff is unavailable.",
    repositoryPath: "guides/prerequisites/claude-code.md",
  },
  {
    slug: "vercel",
    title: "Vercel",
    description: "Review the repository's optional deployment setup guidance.",
    repositoryPath: "guides/prerequisites/vercel.md",
  },
  {
    slug: "neon",
    title: "Neon",
    description: "Review the repository's optional PostgreSQL setup guidance.",
    repositoryPath: "guides/prerequisites/neon.md",
  },
] as const

export type BuildGuide = (typeof buildGuides)[number]

export function getBuildGuide(slug: string) {
  return buildGuides.find((guide) => guide.slug === slug)
}

export function getBuildGuideSourceUrl(guide: BuildGuide) {
  return `https://github.com/TanookiLabs/creator-ai-tools/blob/main/${guide.repositoryPath}`
}
