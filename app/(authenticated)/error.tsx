"use client"

import { Button } from "@/components/ui/button"
import { AlertCircle } from "lucide-react"

export default function AuthenticatedError({ reset }: { error: Error; reset: () => void }) {
  return (
    <main className="flex min-h-screen items-center justify-center p-4">
      <section className="max-w-md text-center" role="alert" aria-labelledby="error-heading">
        <AlertCircle className="mx-auto mb-4 h-8 w-8 text-destructive" aria-hidden="true" />
        <h1 id="error-heading" className="text-xl font-semibold">We couldn&apos;t load your workspace</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Please try again. If this keeps happening, return later.
        </p>
        <Button className="mt-5" onClick={reset}>Try again</Button>
      </section>
    </main>
  )
}
