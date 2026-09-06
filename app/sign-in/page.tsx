"use client"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { authClient } from "@/lib/auth-client"
import { safeAuthDestination } from "@/lib/auth-redirect"
import Link from "next/link"
import { useRouter, useSearchParams } from "next/navigation"
import { Suspense } from "react"
import { useState } from "react"

export default function SignInPage() {
  return (
    <Suspense fallback={<AuthPageLoading label="Loading sign in…" />}>
      <SignInForm />
    </Suspense>
  )
}

function SignInForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [error, setError] = useState("")
  const [pending, setPending] = useState(false)
  const callbackUrl = safeAuthDestination(searchParams.get("callbackUrl"))

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setError("")
    setPending(true)

    const formData = new FormData(e.currentTarget)
    const email = formData.get("email") as string
    const password = formData.get("password") as string

    try {
      const { error: signInError } = await authClient.signIn.email({
        email,
        password,
      })

      if (signInError) {
        // Deliberately do not distinguish an unknown email from a bad password.
        setError("We couldn't sign you in with those details. Check them and try again.")
        return
      }

      router.replace(callbackUrl)
      router.refresh()
    } catch {
      setError("We couldn't sign you in. Check your connection and try again.")
    } finally {
      setPending(false)
    }
  }

  return (
    <main className="min-h-screen flex items-center justify-center p-4">
      <Card className="w-full max-w-sm">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl">Sign in</CardTitle>
          <CardDescription>Sign in to your account to continue</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" name="email" type="email" required />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="password">Password</Label>
              <Input id="password" name="password" type="password" required />
            </div>
            {error && <p className="text-sm text-destructive" role="alert">{error}</p>}
            <Button type="submit" className="w-full" size="lg" disabled={pending}>
              {pending ? "Signing in..." : "Sign in"}
            </Button>
          </form>
          <p className="text-center text-sm text-muted-foreground mt-4">
            Don&apos;t have an account?{" "}
            <Link href={`/sign-up?callbackUrl=${encodeURIComponent(callbackUrl)}`} className="underline hover:text-foreground">
              Sign up
            </Link>
          </p>
        </CardContent>
      </Card>
    </main>
  )
}

function AuthPageLoading({ label }: { label: string }) {
  return <main className="flex min-h-screen items-center justify-center p-4 text-sm text-muted-foreground" aria-busy="true">{label}</main>
}
