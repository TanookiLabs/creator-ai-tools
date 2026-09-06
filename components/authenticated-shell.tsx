"use client"

import { Button } from "@/components/ui/button"
import { authClient } from "@/lib/auth-client"
import { cn } from "@/lib/utils"
import Link from "next/link"
import { usePathname, useRouter } from "next/navigation"
import { useState } from "react"

const navigation = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/profile", label: "Profile" },
  { href: "/resources", label: "Build Guides" },
] as const

function isCurrentLocation(pathname: string, href: string) {
  return pathname === href || (href === "/resources" && pathname.startsWith("/resources/"))
}

export function AuthenticatedShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  const router = useRouter()
  const [isSigningOut, setIsSigningOut] = useState(false)
  const [signOutError, setSignOutError] = useState("")

  async function signOut() {
    if (isSigningOut) return
    setIsSigningOut(true)
    setSignOutError("")

    try {
      const { error } = await authClient.signOut()
      if (error) {
        setSignOutError("Sign out failed. Please try again.")
        setIsSigningOut(false)
        return
      }

      router.replace("/sign-in")
      router.refresh()
    } catch {
      setSignOutError("Sign out failed. Please try again.")
      setIsSigningOut(false)
    }
  }

  return (
    <div className="min-h-screen bg-muted/30">
      <header className="border-b bg-background">
        <div className="mx-auto flex max-w-6xl flex-col gap-3 px-4 py-3 sm:flex-row sm:items-center sm:justify-between sm:px-6">
          <nav aria-label="Primary navigation">
            <ul className="flex flex-wrap items-center gap-1">
              {navigation.map(({ href, label }) => {
                const isCurrent = isCurrentLocation(pathname, href)
                return (
                  <li key={href}>
                    <Link
                      href={href}
                      aria-current={isCurrent ? "page" : undefined}
                      className={cn(
                        "inline-flex min-h-10 items-center rounded-md px-3 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
                        isCurrent && "bg-accent text-accent-foreground"
                      )}
                    >
                      {label}
                    </Link>
                  </li>
                )
              })}
            </ul>
          </nav>
          <div className="flex flex-col items-start sm:items-end">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              disabled={isSigningOut}
              onClick={signOut}
            >
              {isSigningOut ? "Signing out…" : "Sign out"}
            </Button>
            {signOutError ? <p className="text-sm text-destructive" role="alert">{signOutError}</p> : null}
          </div>
        </div>
      </header>
      {children}
    </div>
  )
}
