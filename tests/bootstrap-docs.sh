#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

readme=README.md
desktop_guide=guides/prerequisites/claude-desktop.md
contract=docs/first-app-handoff-contract.md
release_inputs=docs/release-inputs.md
setup=setup.sh
canonical=https://github.com/TanookiLabs/creator-ai-tools

# Check only current participant-facing sources. release-inputs.md intentionally
# retains obsolete strings as historical audit evidence.
active_sources=("$readme" "$desktop_guide" CLAUDE.md "$contract" "$setup")
grep -F "$canonical" "$readme" >/dev/null
grep -F 'TanookiLabs/creator-ai-tools' "$contract" >/dev/null
grep -F 'BOOTSTRAP_REPOSITORY="https://github.com/TanookiLabs/creator-ai-tools"' "$setup" >/dev/null
grep -F 'TEMPLATE_REPOSITORY="https://github.com/TanookiLabs/creator-ai-tools"' "$setup" >/dev/null

if rg -n 'raw\.githubusercontent\.com/[^ /]+/[^ /]+/(main|master)/|codeload\.github\.com/[^ /]+/[^ /]+/(zip|tar\.gz)/(main|master)([^[:alnum:]]|$)' "${active_sources[@]}"; then
  echo "A moving production source is present in active bootstrap documentation or code." >&2
  exit 1
fi
if rg -n 'ericskiff/vibe-setup|slow-ventures/creator-ai-tools' "${active_sources[@]}"; then
  echo "An obsolete bootstrap source is present in active documentation or code." >&2
  exit 1
fi

bootstrap_url=$(sed -n 's/^bootstrap_url="\([^"]*\)"/\1/p' "$readme")
[[ "$bootstrap_url" =~ /refs/tags/[^/]+/setup\.sh$ ]] || {
  echo "The primary bootstrap URL is not release-tagged." >&2
  exit 1
}
documented_digest=$(sed -n "s/.*'\([0-9a-f]\{64\}\)' \"\$bootstrap_tmp\/setup.sh\".*/\1/p" "$readme")
actual_digest=$(shasum -a 256 "$setup" | awk '{print $1}')
test "$documented_digest" = "$actual_digest"

if rg -n 'curl[^|\n]*\|[[:space:]]*(ba)?sh' "$readme" || \
   rg -n -- '--dangerously-skip-permissions|--permission-mode[ =](bypassPermissions|dontAsk)' "${active_sources[@]}"; then
  echo "Unsafe invocation or permission flags are present." >&2
  exit 1
fi

# Every documented local Markdown target and npm command must exist.
node <<'NODE'
const fs = require("node:fs")
const path = require("node:path")
const files = ["README.md", "CLAUDE.md", "guides/prerequisites/claude-desktop.md", "docs/first-app-handoff-contract.md"]
const scripts = JSON.parse(fs.readFileSync("package.json", "utf8")).scripts || {}
for (const file of files) {
  const body = fs.readFileSync(file, "utf8")
  for (const match of body.matchAll(/\[[^\]]+\]\(([^)#]+)(?:#[^)]+)?\)/g)) {
    const target = match[1]
    if (/^[a-z]+:/i.test(target)) continue
    const resolved = path.resolve(path.dirname(file), target)
    if (!fs.existsSync(resolved)) throw new Error(`${file}: missing documentation target ${target}`)
  }
  for (const match of body.matchAll(/npm run ([a-zA-Z0-9:_-]+)/g)) {
    if (!scripts[match[1]]) throw new Error(`${file}: missing package script ${match[1]}`)
  }
}
NODE

grep -F 'supports macOS only' "$readme" >/dev/null
grep -F 'Terminal-only' "$desktop_guide" >/dev/null
grep -F 'Gatekeeper' "$desktop_guide" >/dev/null
grep -F 'Sign in with your own account' "$desktop_guide" >/dev/null
grep -F 'folder confirmation' "$desktop_guide" >/dev/null
grep -F 'Keychain' "$desktop_guide" >/dev/null
grep -F 'participant' "$desktop_guide" >/dev/null
grep -F 'manual' "$desktop_guide" >/dev/null

# The contract, producer, consumer, and examples must stay on the same major.
grep -F 'CONTRACT_VERSION="1.0"' "$setup" >/dev/null
grep -F 'contract version `1.0`' "$contract" >/dev/null
grep -F 'major version `1`' CLAUDE.md >/dev/null
for example in docs/contracts/examples/*.json; do
  test "$(node -p "require('./$example').contract_version")" = 1.0
done
grep -F '0393501676cf5f3751089699eafb5090411ff8c7' "$release_inputs" >/dev/null

echo "Bootstrap documentation and release-contract checks passed."
