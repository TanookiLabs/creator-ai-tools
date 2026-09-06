import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { ArrowLeft, ExternalLink } from "lucide-react"
import Link from "next/link"
import { notFound } from "next/navigation"

const resources = {
  "show-notes": {
    title: "Build notes",
    description: "Tools, APIs, and practical strategies for building software.",
    sourceUrl: "https://github.com/slow-ventures/creator-ai-tools/blob/main/show-notes.md",
    items: ["Agentic coding workflows", "APIs, data enrichment, and mapping", "Ideas for applying these tools to software projects"],
  },
  slides: {
    title: "Eric’s 201 slides",
    description: "Advanced AI coding material for taking projects beyond the first prototype.",
    sourceUrl: "https://github.com/slow-ventures/creator-ai-tools/blob/main/slides/slides.md",
    items: ["Building complex apps with AI", "Chrome integration, custom skills, and background jobs", "Deployment patterns and next steps"],
  },
} as const

export function generateStaticParams() {
  return Object.keys(resources).map((resource) => ({ resource }))
}

export default async function ResourcePage({ params }: { params: Promise<{ resource: string }> }) {
  const { resource } = await params
  const content = resources[resource as keyof typeof resources]
  if (!content) notFound()

  return (
    <main>
      <div className="mx-auto max-w-3xl px-4 py-10 sm:px-6">
        <Link href="/dashboard" className="inline-flex items-center gap-2 text-sm font-medium text-primary hover:underline">
          <ArrowLeft className="h-4 w-4" aria-hidden="true" /> Back to dashboard
        </Link>
        <Card className="mt-6">
          <CardHeader>
            <CardTitle>{content.title}</CardTitle>
            <CardDescription>{content.description}</CardDescription>
          </CardHeader>
          <CardContent>
            <h2 className="font-semibold">What you’ll find</h2>
            <ul className="mt-3 list-disc space-y-2 pl-5 text-muted-foreground">
              {content.items.map((item) => <li key={item}>{item}</li>)}
            </ul>
            <p className="mt-6 text-sm text-muted-foreground">The full source material is included with this project.</p>
            <a
              href={content.sourceUrl}
              target="_blank"
              rel="noreferrer"
              className="mt-3 inline-flex items-center gap-1 text-sm font-medium text-primary hover:underline"
            >
              Open the complete material <ExternalLink className="h-3.5 w-3.5" aria-hidden="true" />
            </a>
          </CardContent>
        </Card>
      </div>
    </main>
  )
}
