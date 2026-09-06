import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { ArrowRight, BookOpen, Code2, Compass, Rocket, Wrench } from "lucide-react"
import Link from "next/link"

const directions = [
  {
    title: "Shape an idea",
    description: "Clarify who you want to help and the smallest useful outcome you can build first.",
    nextStep: "Write the outcome in one sentence, then list the first screen someone needs.",
    icon: Compass,
  },
  {
    title: "Build a feature",
    description: "Turn one clear user need into a focused page, workflow, or interaction.",
    nextStep: "Choose one action a person should be able to finish from start to end.",
    icon: Code2,
  },
  {
    title: "Improve the foundation",
    description: "Work on setup, navigation, accessibility, authentication, or another app essential.",
    nextStep: "Pick the foundation issue that most directly unblocks useful building.",
    icon: Wrench,
  },
  {
    title: "Prepare to share",
    description: "Review the experience, fix rough edges, and get the project ready for other people.",
    nextStep: "Walk through the main path as a new user and note the first point of confusion.",
    icon: Rocket,
  },
] as const

export default function DashboardPage() {
  return (
    <main>
      <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
          <div className="space-y-2">
            <Badge variant="secondary">Your workspace</Badge>
            <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">Choose a useful next step</h1>
            <p className="max-w-2xl text-muted-foreground">
              Start with the outcome you want to create. This workspace does not assume a project or fill in activity for you.
            </p>
          </div>
          <Button asChild className="w-full shrink-0 sm:w-auto">
            <Link href="/resources">
              Open Build Guides <BookOpen aria-hidden="true" />
            </Link>
          </Button>
        </div>

        <section className="mt-10" aria-labelledby="directions-heading">
          <div className="max-w-2xl">
            <h2 id="directions-heading" className="text-2xl font-semibold tracking-tight">
              Where would you like to begin?
            </h2>
            <p className="mt-2 text-sm text-muted-foreground">
              These are starting directions, not saved selections. Pick whichever best matches the work in front of you.
            </p>
          </div>

          <div className="mt-5 grid min-w-0 gap-4 sm:grid-cols-2">
            {directions.map(({ title, description, nextStep, icon: Icon }) => (
              <Card key={title} className="min-w-0">
                <CardHeader>
                  <div className="flex items-start gap-3">
                    <span className="rounded-md bg-muted p-2 text-foreground">
                      <Icon className="h-5 w-5" aria-hidden="true" />
                    </span>
                    <div className="min-w-0">
                      <CardTitle className="text-lg">{title}</CardTitle>
                      <CardDescription className="mt-1">{description}</CardDescription>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <p className="text-sm">
                    <span className="font-medium">Try this:</span> {nextStep}
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>
        </section>

        <section className="mt-8" aria-labelledby="guides-heading">
          <Card>
            <CardHeader>
              <CardTitle id="guides-heading">Need help with the setup?</CardTitle>
              <CardDescription>
                Build Guides provide practical, step-by-step help for the tools included with this starter.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button asChild variant="outline" className="w-full sm:w-auto">
                <Link href="/resources">
                  Browse Build Guides <ArrowRight aria-hidden="true" />
                </Link>
              </Button>
            </CardContent>
          </Card>
        </section>
      </div>
    </main>
  )
}
