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
    slug: "claude-code",
    title: "Claude Code",
    description: "Install the optional coding assistant covered by the repository guide.",
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
  return `https://github.com/slow-ventures/creator-ai-tools/blob/main/${guide.repositoryPath}`
}
