import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { buildGuides } from "@/lib/build-guides"
import { ArrowRight, BookOpen } from "lucide-react"
import Link from "next/link"

export default function ResourcesPage() {
  return (
    <main>
      <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
        <div className="max-w-2xl">
          <Badge variant="secondary">Repository documentation</Badge>
          <h1 className="mt-3 text-3xl font-bold tracking-tight sm:text-4xl">Build Guides</h1>
          <p className="mt-2 text-muted-foreground">
            Browse practical setup notes maintained with this project. A guide is documentation only and does not mean a tool or service is connected.
          </p>
        </div>

        <section className="mt-8" aria-labelledby="guide-list-heading">
          <h2 id="guide-list-heading" className="sr-only">Available build guides</h2>
          <div className="grid min-w-0 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {buildGuides.map((guide) => (
              <Card key={guide.slug} className="flex min-w-0 flex-col">
                <CardHeader>
                  <div className="flex items-start justify-between gap-3">
                    <span className="rounded-md bg-muted p-2 text-foreground">
                      <BookOpen className="h-5 w-5" aria-hidden="true" />
                    </span>
                    <Badge variant="outline">Guide only</Badge>
                  </div>
                  <CardTitle className="pt-2 text-lg">{guide.title}</CardTitle>
                  <CardDescription>{guide.description}</CardDescription>
                </CardHeader>
                <CardContent className="mt-auto">
                  <p className="mb-4 text-xs text-muted-foreground">No connection is enabled from this page.</p>
                  <Link href={`/resources/setup/${guide.slug}`} className="inline-flex min-h-10 items-center gap-2 rounded-md text-sm font-medium text-primary underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2">
                    View guide details <ArrowRight className="h-4 w-4" aria-hidden="true" />
                  </Link>
                </CardContent>
              </Card>
            ))}
          </div>
        </section>
      </div>
    </main>
  )
}
