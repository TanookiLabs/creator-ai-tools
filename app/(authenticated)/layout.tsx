import { auth } from "@/lib/auth"
import { AuthenticatedShell } from "@/components/authenticated-shell"
import { headers } from "next/headers"
import { redirect } from "next/navigation"
import { Suspense } from "react"

async function AuthGate({ children }: { children: React.ReactNode }) {
  const session = await auth.api.getSession({
    headers: await headers(),
  })
  if (!session) redirect("/sign-in")
  return <AuthenticatedShell>{children}</AuthenticatedShell>
}

export default function AuthenticatedLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <Suspense fallback={<div className="flex min-h-screen items-center justify-center p-4 text-sm text-muted-foreground" aria-busy="true" aria-live="polite">Loading your workspace…</div>}>
      <AuthGate>{children}</AuthGate>
    </Suspense>
  )
}
