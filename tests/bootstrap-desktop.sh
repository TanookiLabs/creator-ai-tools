#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
setup="$repo_root/setup.sh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-desktop.XXXXXX")
trap 'rm -rf "$test_root"' EXIT

# Load the recovery helper without running the macOS bootstrap.
sed -n '/^show_claude_desktop_handoff() {/,/^header "Your project folder"/p' "$setup" | sed '$d' > "$test_root/functions.sh"
# shellcheck source=/dev/null
source "$test_root/functions.sh"
info() { printf '%s\n' "$*"; }

project_root="$test_root/Documents/Creator App & Notes"
output=$(show_claude_desktop_handoff "$project_root")
grep -F "$project_root" <<<"$output" >/dev/null
grep -F 'cannot verify' <<<"$output" >/dev/null

# The verified checkout must precede the Desktop handoff.
checkout_line=$(grep -n '^ok "Installed project template commit verified:' "$setup" | cut -d: -f1)
handoff_line=$(grep -n 'show_claude_desktop_handoff "\$PROJECT_ROOT"' "$setup" | tail -1 | cut -d: -f1)
test "$checkout_line" -lt "$handoff_line"

grep -F 'confirm "Install the Claude desktop app?"' "$setup" >/dev/null
grep -F 'STARTER_PROMPT="Open $PROJECT_ROOT, read CLAUDE.md, and help me start the app."' "$setup" >/dev/null
grep -F 'Copy this starter prompt to the clipboard?' "$setup" >/dev/null
grep -F 'folder selection is not observable by this installer' "$setup" >/dev/null
! grep -F 'claude://code/new' "$setup"
! grep -F 'Copy the redacted handoff to the clipboard?' "$setup"

if grep -nE -- '--dangerously-skip-permissions|--permission-mode[ =](bypassPermissions|dontAsk)' "$setup"; then
  echo "Unsafe Claude permission flags are present." >&2
  exit 1
fi

echo "Bootstrap Desktop handoff checks passed."
