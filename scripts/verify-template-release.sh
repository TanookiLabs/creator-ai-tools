#!/usr/bin/env bash

# Read-only checks for files that would be included in a template release.
# This script does not connect to a database, start a deployment, or create data.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

mapfile -d '' indexed_files < <(git ls-files --cached --others --exclude-standard -z)
candidate_files=()
for file in "${indexed_files[@]}"; do
  [[ -f "$file" ]] && candidate_files+=("$file")
done
if (( ${#candidate_files[@]} == 0 )); then
  echo "Stopping: no release-candidate files found." >&2
  exit 1
fi

echo "1/4 Checking the committed environment contract contains placeholders only"
if [[ ! -f .env.example ]]; then
  echo "Stopping: .env.example is missing." >&2
  exit 1
fi

nonempty_env_values=$(awk '
  /^[[:space:]]*($|#)/ { next }
  /^[A-Za-z_][A-Za-z0-9_]*=/ {
    value = $0
    sub(/^[^=]*=/, "", value)
    if (value != "") print NR ":" $0
    next
  }
  { print NR ":unrecognized environment-template line: " $0 }
' .env.example)
if [[ -n "$nonempty_env_values" ]]; then
  echo "Stopping: .env.example must contain empty assignments only:" >&2
  printf '%s\n' "$nonempty_env_values" >&2
  exit 1
fi

echo "2/4 Scanning release-candidate text for credential signatures"
secret_pattern='-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|sk_(live|test)_[0-9A-Za-z]{16,}|whsec_[0-9A-Za-z]{16,}|postgres(ql)?://[^[:space:]@]+:[^[:space:]@]+@'
set +e
secret_hits=$(grep -InE --binary-files=without-match -e "$secret_pattern" -- "${candidate_files[@]}")
grep_status=$?
set -e
if (( grep_status > 1 )); then
  echo "Stopping: credential scan could not inspect the release candidate." >&2
  exit "$grep_status"
fi
if [[ -n "$secret_hits" ]]; then
  echo "Stopping: possible credential material found in release-candidate files:" >&2
  printf '%s\n' "$secret_hits" >&2
  exit 1
fi

echo "3/4 Confirming release scripts cannot seed or reset data"
node <<'NODE'
const { readFileSync } = require("node:fs")

const scripts = JSON.parse(readFileSync("package.json", "utf8")).scripts ?? {}
const releaseScripts = ["build", "start", "verify", "db:migrate"]
const forbidden = /(^|\s|&&|;)([^\n]*\b(seed|db:push|migrate\s+reset|force-reset)\b)/i

for (const name of releaseScripts) {
  if (!scripts[name]) throw new Error(`required release script is missing: ${name}`)
  if (forbidden.test(scripts[name])) {
    throw new Error(`release script ${name} contains a data seed/reset command`)
  }
}

const localSeed = scripts["db:seed:local"] ?? ""
if (!localSeed.includes("NODE_ENV=development") || !localSeed.includes("ALLOW_LOCAL_FIXTURES=true")) {
  throw new Error("db:seed:local must remain explicitly development-only and opt-in")
}
NODE

if grep -InE '^[[:space:]]*[^#].*\b(prisma db seed|db:seed|prisma db push|migrate reset|force-reset)\b' scripts/rehearse-release.sh; then
  echo "Stopping: the release rehearsal contains a seed, push, or reset command." >&2
  exit 1
fi

echo "4/4 Passed: placeholder env contract, credential scan, and no-seed release paths"
echo "Scanned ${#candidate_files[@]} tracked/unignored release-candidate files; no files or data were changed."
