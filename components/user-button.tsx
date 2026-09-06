"use client"

import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { authClient } from "@/lib/auth-client"
import Image from "next/image"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { useState } from "react"

export function UserButton() {
  const { data: session } = authClient.useSession()
  const router = useRouter()
  const [signOutError, setSignOutError] = useState("")
  const [signingOut, setSigningOut] = useState(false)

  if (!session?.user) return null

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="sm" className="gap-2">
          {session.user.image ? (
            <Image
              src={session.user.image}
              alt=""
              width={24}
              height={24}
              unoptimized
              className="h-6 w-6 rounded-full"
            />
          ) : null}
          {session.user.name ?? session.user.email}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem asChild>
          <Link href="/profile">Profile</Link>
        </DropdownMenuItem>
        <DropdownMenuItem
          disabled={signingOut}
          onSelect={async (event) => {
            event.preventDefault()
            if (signingOut) return
            setSignOutError("")
            setSigningOut(true)
            try {
              const { error } = await authClient.signOut()
              if (error) {
                setSignOutError("We couldn't sign you out. Please try again.")
                return
              }
              router.replace("/sign-in")
              router.refresh()
            } catch {
              setSignOutError("We couldn't sign you out. Check your connection and try again.")
            } finally {
              setSigningOut(false)
            }
          }}
        >
          {signingOut ? "Signing out…" : "Sign out"}
        </DropdownMenuItem>
        {signOutError ? <p className="max-w-52 px-2 py-1.5 text-xs text-destructive" role="alert">{signOutError}</p> : null}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
