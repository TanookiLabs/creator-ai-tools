const DEFAULT_AUTH_DESTINATION = "/dashboard"
const AUTH_ENTRY_PATHS = ["/sign-in", "/sign-up", "/api/auth"]

/**
 * Accept only an in-app path as an authentication return destination.
 * Protocol-relative URLs, backslashes, control characters, and auth entry
 * routes are rejected to prevent open redirects and redirect loops.
 */
export function safeAuthDestination(value: string | null | undefined) {
  if (
    !value ||
    !value.startsWith("/") ||
    value.startsWith("//") ||
    value.includes("\\") ||
    /[\u0000-\u001f\u007f]/.test(value)
  ) {
    return DEFAULT_AUTH_DESTINATION
  }

  let pathname: string
  try {
    pathname = new URL(value, "https://local.invalid").pathname
  } catch {
    return DEFAULT_AUTH_DESTINATION
  }

  if (
    AUTH_ENTRY_PATHS.some(
      (route) => pathname === route || pathname.startsWith(`${route}/`)
    )
  ) {
    return DEFAULT_AUTH_DESTINATION
  }

  return value
}
