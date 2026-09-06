import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { buildGuides, getBuildGuide, getBuildGuideSourceUrl } from "@/lib/build-guides"
import { ArrowLeft, ExternalLink } from "lucide-react"
import Link from "next/link"
import { notFound } from "next/navigation"

export function generateStaticParams() {
  return buildGuides.map((guide) => ({ guide: guide.slug }))
}

export default async function SetupGuidePage({ params }: { params: Promise<{ guide: string }> }) {
  const { guide: slug } = await params
  const guide = getBuildGuide(slug)
  if (!guide) notFound()

  return (
    <main>
      <div className="mx-auto max-w-3xl px-4 py-10 sm:px-6">
        <Link href="/resources" className="inline-flex min-h-10 items-center gap-2 rounded-md text-sm font-medium text-primary underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2">
          <ArrowLeft className="h-4 w-4" aria-hidden="true" /> All Build Guides
        </Link>
        <Card className="mt-6">
          <CardHeader>
            <Badge variant="outline" className="w-fit">Repository guide</Badge>
            <CardTitle>{guide.title}</CardTitle>
            <CardDescription>{guide.description}</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3 text-muted-foreground">
            <p>This page points to documentation maintained in the project repository. It does not check connection status, enable an integration, or collect credentials.</p>
            <p className="break-words text-xs"><span className="font-medium text-foreground">Repository file:</span> {guide.repositoryPath}</p>
            <a
              href={getBuildGuideSourceUrl(guide)}
              target="_blank"
              rel="noreferrer"
              className="inline-flex min-h-10 items-center gap-2 rounded-md text-sm font-medium text-primary underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
            >
              Open repository guide <ExternalLink className="h-4 w-4" aria-hidden="true" />
            </a>
          </CardContent>
        </Card>
      </div>
    </main>
  )
}
