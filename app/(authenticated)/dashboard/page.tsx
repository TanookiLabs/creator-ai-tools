import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { ArrowRight, LayoutDashboard } from "lucide-react"
import Link from "next/link"

export default function DashboardPage() {
  return (
    <main>
      <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">Dashboard</h1>

        <Card className="mt-8">
          <CardHeader>
            <span className="w-fit rounded-md bg-muted p-2 text-foreground">
              <LayoutDashboard className="h-5 w-5" aria-hidden="true" />
            </span>
            <CardTitle className="text-xl">Your app starts here</CardTitle>
            <CardDescription>
              This page only appears after sign-in. Replace this card with your app&apos;s main screen.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button asChild variant="outline" className="w-full sm:w-auto">
              <Link href="/profile">
                Edit your profile <ArrowRight aria-hidden="true" />
              </Link>
            </Button>
          </CardContent>
        </Card>
      </div>
    </main>
  )
}
