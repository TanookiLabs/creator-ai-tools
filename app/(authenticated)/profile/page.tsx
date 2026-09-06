"use client"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { authClient } from "@/lib/auth-client"
import { MAX_PROFILE_NAME_LENGTH, validateProfile, type ProfileFieldErrors } from "@/lib/profile-validation"
import { useState } from "react"

type ProfileUser = { email: string; image?: string | null; name: string }

export default function ProfilePage() {
  const { data: session, isPending, error } = authClient.useSession()

  return (
    <main>
      <div className="mx-auto max-w-2xl px-4 py-10 sm:px-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-2xl">Your profile</CardTitle>
            <CardDescription>
              Update the name and avatar shown for your signed-in account. Your email is managed by your sign-in account.
            </CardDescription>
          </CardHeader>
          <CardContent>
            {isPending ? <p className="text-sm text-muted-foreground" role="status" aria-live="polite">Loading your profile…</p> : null}
            {!isPending && error ? (
              <div className="space-y-3" role="alert">
                <p className="text-sm text-destructive">We couldn&apos;t load your profile. Check your connection and try again.</p>
                <Button type="button" variant="outline" onClick={() => window.location.reload()}>Try again</Button>
              </div>
            ) : null}
            {!isPending && !error && !session?.user ? <p className="text-sm text-destructive" role="alert">Your session has ended. Sign in again to update your profile.</p> : null}
            {!isPending && !error && session?.user ? <ProfileForm key={session.user.id} user={session.user} /> : null}
          </CardContent>
        </Card>
      </div>
    </main>
  )
}

function ProfileForm({ user }: { user: ProfileUser }) {
  const [name, setName] = useState(user.name)
  const [image, setImage] = useState(user.image ?? "")
  const [savedName, setSavedName] = useState(user.name)
  const [savedImage, setSavedImage] = useState(user.image ?? "")
  const [fieldErrors, setFieldErrors] = useState<ProfileFieldErrors>({})
  const [saveError, setSaveError] = useState("")
  const [message, setMessage] = useState("")
  const [saving, setSaving] = useState(false)

  const hasChanges = name !== savedName || image !== savedImage

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (saving) return
    const validation = validateProfile({ image, name })
    const { errors } = validation
    const { image: trimmedImage, name: trimmedName } = validation.values

    setFieldErrors(errors)
    setSaveError("")
    setMessage("")
    if (Object.keys(errors).length > 0) return

    setSaving(true)

    try {
      // Better Auth derives the target from the active session; no user ID is accepted.
      const { error: updateError } = await authClient.updateUser({
        name: trimmedName,
        image: trimmedImage || null,
      })

      if (updateError) {
        setSaveError("We couldn't save your changes. Your entries are still here—please try again.")
        return
      }

      setName(trimmedName)
      setImage(trimmedImage)
      setSavedName(trimmedName)
      setSavedImage(trimmedImage)
      setMessage("Your profile was saved.")
    } catch {
      setSaveError("We couldn't save your changes. Your entries are still here—check your connection and try again.")
    } finally {
      setSaving(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6" noValidate aria-busy={saving}>
      <div className="space-y-2">
        <Label htmlFor="profile-email">Email</Label>
        <Input id="profile-email" type="email" value={user.email} disabled />
        <p className="text-xs text-muted-foreground">Your email can&apos;t be changed here.</p>
      </div>
      <div className="space-y-2">
        <Label htmlFor="profile-name">Name</Label>
        <Input id="profile-name" value={name} onChange={(event) => { setName(event.target.value); setFieldErrors((current) => ({ ...current, name: undefined })); setSaveError(""); setMessage("") }} disabled={saving} required maxLength={MAX_PROFILE_NAME_LENGTH + 1} autoComplete="name" aria-invalid={Boolean(fieldErrors.name)} aria-describedby={fieldErrors.name ? "profile-name-error" : "profile-name-help"} />
        {fieldErrors.name ? <p id="profile-name-error" className="text-sm text-destructive" role="alert">{fieldErrors.name}</p> : <p id="profile-name-help" className="text-xs text-muted-foreground">Use the name you want displayed in this app.</p>}
      </div>
      <div className="space-y-2">
        <Label htmlFor="profile-image">Avatar URL <span className="font-normal text-muted-foreground">(optional)</span></Label>
        <Input id="profile-image" type="url" value={image} onChange={(event) => { setImage(event.target.value); setFieldErrors((current) => ({ ...current, image: undefined })); setSaveError(""); setMessage("") }} disabled={saving} placeholder="https://example.com/avatar.png" autoComplete="url" inputMode="url" aria-invalid={Boolean(fieldErrors.image)} aria-describedby={fieldErrors.image ? "profile-image-error" : "profile-image-help"} />
        {fieldErrors.image ? <p id="profile-image-error" className="text-sm text-destructive" role="alert">{fieldErrors.image}</p> : <p id="profile-image-help" className="text-xs text-muted-foreground">Paste a direct http or https link, or leave this blank to remove your avatar.</p>}
      </div>
      <div className="space-y-3">
        {saveError ? <p className="text-sm text-destructive" role="alert">{saveError}</p> : null}
        {message ? <p className="text-sm font-medium text-foreground" role="status" aria-live="polite">{message}</p> : null}
        <Button type="submit" className="w-full sm:w-auto" disabled={saving || !hasChanges}>
          {saving ? "Saving profile…" : "Save profile"}
        </Button>
      </div>
    </form>
  )
}
