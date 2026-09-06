import { Button } from "@/components/ui/button"
import Link from "next/link"

export default function AuthenticatedNotFound() {
  return (
    <main className="flex min-h-screen items-center justify-center p-4">
      <section className="max-w-md text-center" aria-labelledby="not-found-heading">
        <p className="text-sm font-medium text-muted-foreground">404</p>
        <h1 id="not-found-heading" className="mt-2 text-2xl font-semibold">Page not found</h1>
        <p className="mt-2 text-sm text-muted-foreground">The page you requested isn&apos;t available.</p>
        <Button asChild className="mt-5"><Link href="/dashboard">Back to dashboard</Link></Button>
      </section>
    </main>
  )
}
