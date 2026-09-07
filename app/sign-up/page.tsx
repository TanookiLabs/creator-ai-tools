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

export default function SignUpPage() {
  return (
    <Suspense fallback={<AuthPageLoading label="Loading sign up…" />}>
      <SignUpForm />
    </Suspense>
  )
}

function SignUpForm() {
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
    const name = formData.get("name") as string
    const email = formData.get("email") as string
    const password = formData.get("password") as string

    try {
      const { error: signUpError } = await authClient.signUp.email({
        name: name.trim() || email,
        email,
        password,
      })

      if (signUpError) {
        // Keep account existence and backend details out of the response.
        setError("We couldn't create your account with those details. Review them and try again.")
        return
      }

      router.replace(callbackUrl)
      router.refresh()
    } catch {
      setError("We couldn't create your account. Check your connection and try again.")
    } finally {
      setPending(false)
    }
  }

  return (
    <main className="min-h-screen flex items-center justify-center p-4">
      <Card className="w-full max-w-sm">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl">Create an account</CardTitle>
          <CardDescription>Enter your details to get started</CardDescription>
        </CardHeader>
        <CardContent>
          <form method="post" onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-2">
              <Label htmlFor="name">Name</Label>
              <Input id="name" name="name" type="text" />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" name="email" type="email" required />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="password">Password</Label>
              <Input id="password" name="password" type="password" required minLength={6} />
            </div>
            {error && <p className="text-sm text-destructive" role="alert">{error}</p>}
            <Button type="submit" className="w-full" size="lg" disabled={pending}>
              {pending ? "Creating account..." : "Sign up"}
            </Button>
          </form>
          <p className="text-center text-sm text-muted-foreground mt-4">
            Already have an account?{" "}
            <Link href={`/sign-in?callbackUrl=${encodeURIComponent(callbackUrl)}`} className="underline hover:text-foreground">
              Sign in
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
