export default function AuthenticatedLoading() {
  return (
    <main className="flex min-h-screen items-center justify-center p-4" aria-busy="true" aria-live="polite">
      <p className="text-sm text-muted-foreground">Loading your workspace…</p>
    </main>
  )
}
