export const MAX_PROFILE_NAME_LENGTH = 100

export type ProfileValues = { image: string; name: string }
export type ProfileFieldErrors = { image?: string; name?: string }

export function validateProfile(values: ProfileValues) {
  const name = values.name.trim()
  const image = values.image.trim()
  const errors: ProfileFieldErrors = {}

  if (!name) {
    errors.name = "Enter a name to continue."
  } else if (name.length > MAX_PROFILE_NAME_LENGTH) {
    errors.name = `Keep your name to ${MAX_PROFILE_NAME_LENGTH} characters or fewer.`
  }

  if (image) {
    try {
      const imageUrl = new URL(image)
      if (imageUrl.protocol !== "http:" && imageUrl.protocol !== "https:") {
        errors.image = "Enter a web address beginning with http:// or https://."
      }
    } catch {
      errors.image = "Enter a complete image URL, or leave this blank."
    }
  }

  return { errors, values: { image, name } }
}
