#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
setup="$repo_root/setup.sh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-desktop.XXXXXX")
trap 'rm -rf "$test_root"' EXIT

# Load the pure link and recovery helpers without running the macOS bootstrap.
sed -n '/^desktop_deep_link() {/,/^header "Your project folder"/p' "$setup" | sed '$d' > "$test_root/functions.sh"
# shellcheck source=/dev/null
source "$test_root/functions.sh"

project_root="$test_root/Documents/Creator App & Notes"
link=$(desktop_deep_link "$project_root")
node - "$link" "$project_root" <<'NODE'
const assert = require("node:assert/strict")
const link = process.argv[2]
const root = process.argv[3]
assert.ok(link.startsWith("claude://code/new?"))
const query = new URL(link).searchParams
assert.equal(query.get("folder"), root)
assert.equal(query.get("q"), "Read CLAUDE.md and FIRST_APP_HANDOFF.md, then help me start this app.")
assert.equal(query.getAll("folder").length, 1)
NODE

# The verified checkout must precede every Desktop deep-link attempt.
checkout_line=$(grep -n '^ok "Template commit verified:' "$setup" | cut -d: -f1)
link_line=$(grep -n 'open "\$CLAUDE_DEEP_LINK"' "$setup" | cut -d: -f1)
test "$checkout_line" -lt "$link_line"

grep -F 'confirm "Install the Claude desktop app?"' "$setup" >/dev/null
grep -F 'confirm "Is the Code interface available in Claude Desktop?"' "$setup" >/dev/null
grep -F 'confirm "Open the exact project root in Claude Desktop now?"' "$setup" >/dev/null
grep -F 'confirm "Did you approve the exact folder and send the prompt?"' "$setup" >/dev/null
grep -F 'cd $(printf '\''%q'\'' "$root")' "$setup" >/dev/null
grep -F '  claude' "$setup" >/dev/null

if grep -nE -- '--dangerously-skip-permissions|--permission-mode[ =](bypassPermissions|dontAsk)' "$setup"; then
  echo "Unsafe Claude permission flags are present." >&2
  exit 1
fi

echo "Bootstrap Desktop handoff checks passed."
