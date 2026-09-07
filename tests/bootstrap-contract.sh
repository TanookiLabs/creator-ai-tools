#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
setup="$repo_root/setup.sh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-contract.XXXXXX")
trap 'rm -rf "$test_root"' EXIT

# Load the self-contained producer without running the interactive bootstrap.
sed -n '/^produce_first_app_contract() {/,/^FIRST_APP_CONTRACT_JS$/p' "$setup" > "$test_root/producer.sh"
printf '}\n' >> "$test_root/producer.sh"
# shellcheck source=/dev/null
source "$test_root/producer.sh"

project="$test_root/my-first-app"
mkdir -p "$project/app" "$project/prisma" "$project/docs" "$test_root/bin"
touch "$project/package.json" "$project/package-lock.json" "$project/next.config.ts"
touch "$project/prisma/schema.prisma" "$project/app/page.tsx"
touch "$project/CLAUDE.md" "$project/README.md" "$project/docs/quality-verification.md"
cp "$repo_root/.gitignore" "$project/.gitignore"
git -C "$project" init --quiet
git -C "$project" config user.name Test
git -C "$project" config user.email test@example.invalid
git -C "$project" add .
git -C "$project" commit --quiet -m template

TEMPLATE_REPOSITORY="https://github.com/TanookiLabs/creator-ai-tools"
TEMPLATE_COMMIT=$(git -C "$project" rev-parse HEAD)
git -C "$project" remote add origin "$TEMPLATE_REPOSITORY"
PROJECT_ROOT=$(cd "$project" && pwd -P)
CONTRACT_VERSION=1.0
RUN_STARTED_AT=2026-09-06T12:00:00Z
SOURCE_BRANCH=main
GITHUB_VERIFIED=true
GITHUB_AUTH_EVIDENCE=interactive_status_verified
POSTGRES_VERIFIED=true
DESKTOP_VERIFIED=false
GUI_LOGIN_SHELL_VERIFIED=true
GUI_LOGIN_SHELL_MISSING=""

# The GitHub version fixture resembles a token. It must be replaced before
# disk and terminal output, while participant authentication stays untouched.
cat > "$test_root/bin/gh" <<'EOF'
#!/bin/sh
echo 'gh version ghp_fixture_secret_value'
EOF
cat > "$test_root/bin/psql" <<'EOF'
#!/bin/sh
echo 'psql (PostgreSQL) 17.0'
EOF
chmod +x "$test_root/bin/gh" "$test_root/bin/psql"
export PATH="$test_root/bin:$PATH"

first_output=$(produce_first_app_contract)
receipt="$project/.first-app/receipt.json"
handoff="$project/FIRST_APP_HANDOFF.md"
test -f "$receipt"
test -f "$handoff"
grep -F '"contract_version": "1.0"' "$receipt" >/dev/null
grep -F "\"root\": \"$PROJECT_ROOT\"" "$receipt" >/dev/null
grep -F "\"commit\": \"$TEMPLATE_COMMIT\"" "$receipt" >/dev/null
grep -F '"source_branch": "main"' "$receipt" >/dev/null
node -e 'const r=require(process.argv[1]); if (r.provenance.bootstrap.commit || r.provenance.bootstrap.source_branch !== "main" || r.provenance.template.source_branch !== "main" || r.provenance.template.commit !== r.application.commit) throw new Error("main provenance is inaccurate")' "$receipt"
grep -F '"status": "success"' "$receipt" >/dev/null
grep -F '"blocking": false' "$receipt" >/dev/null
grep -F '"evidence_code": "folder_selection_unverified"' "$receipt" >/dev/null
grep -F '"applied": true' "$receipt" >/dev/null
grep -F '[REDACTED]' "$receipt" >/dev/null
grep -F '<!-- generated; local-only; contract 1.0 -->' "$handoff" >/dev/null
grep -F '## Next action' "$handoff" >/dev/null
grep -F '## Run result' "$handoff" >/dev/null
! grep -F 'ghp_fixture_secret_value' <<<"$first_output$(cat "$receipt")$(cat "$handoff")" >/dev/null
# A successful fresh install writes its initial receipt during this first
# invocation. It is not a rerun and must not need a second installer pass.
test "$(node -p "require('$receipt').run.sequence")" -eq 1
node -e 'const run=require(process.argv[1]).run; if (Object.hasOwn(run, "rerun_of")) throw new Error("First-run receipt unexpectedly references a rerun.")' "$receipt"

# Successful reruns replace current files, increment sequence, retain no
# diagnostic failure, and keep stable observed fields semantically identical.
first_semantic=$(node -e 'const r=require(process.argv[1]); delete r.run; delete r.timestamps; for(const c of r.capabilities) delete c.checked_at; console.log(JSON.stringify(r))' "$receipt")
produce_first_app_contract >/dev/null
second_semantic=$(node -e 'const r=require(process.argv[1]); delete r.run; delete r.timestamps; for(const c of r.capabilities) delete c.checked_at; console.log(JSON.stringify(r))' "$receipt")
test "$first_semantic" = "$second_semantic"
test "$(node -p "require('$receipt').run.sequence")" -eq 2
test "$(find "$project/.first-app/diagnostics" -type f -name '*.json' | wc -l)" -eq 0
produce_first_app_contract >/dev/null
test "$(find "$project/.first-app/diagnostics" -type f -name '*.json' | wc -l)" -eq 0

# An interrupted atomic replacement cannot corrupt the prior receipt. A stale
# temporary file is local to the fixture and is never interpreted as current.
receipt_before=$(shasum -a 256 "$receipt")
printf '{"interrupted":true' > "$receipt.tmp-interrupted"
test "$(shasum -a 256 "$receipt")" = "$receipt_before"
node -e 'JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"))' "$receipt"
produce_first_app_contract >/dev/null
node -e 'JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"))' "$receipt"
test -f "$receipt.tmp-interrupted"

# A remote observation stays unverified and records only a bounded evidence
# code plus a participant-controlled next action.
GITHUB_VERIFIED=false
GITHUB_AUTH_EVIDENCE=gui_context_required
produce_first_app_contract >/dev/null
grep -F '"evidence_code": "gui_context_required"' "$receipt" >/dev/null
grep -F 'not authoritative for the participant' "$receipt" >/dev/null
grep -F 'Do not reauthenticate because of an SSH or background check alone.' "$receipt" >/dev/null
! grep -Ei 'SSH_CONNECTION|SSH_CLIENT|SSH_TTY|keychain[^.]*:' "$receipt" "$handoff" >/dev/null

# A missing fresh GUI login-shell check is a real required recovery, while an
# unverified Desktop folder alone remains a truthful non-blocking handoff.
GITHUB_VERIFIED=true
GITHUB_AUTH_EVIDENCE=interactive_status_verified
GUI_LOGIN_SHELL_VERIFIED=false
GUI_LOGIN_SHELL_MISSING="node,claude"
produce_first_app_contract >/dev/null
grep -F '"status": "partial_failure"' "$receipt" >/dev/null
grep -F '"id": "verify.gui_login_shell"' "$receipt" >/dev/null
grep -F '"missing_commands": [' "$receipt" >/dev/null
grep -F '"node"' "$receipt" >/dev/null
grep -F '"claude"' "$receipt" >/dev/null
grep -F 'confirm these commands are available: node, claude' "$receipt" >/dev/null

# Reject unsafe roots and non-main provenance before writing state.
SOURCE_BRANCH=feature
if produce_first_app_contract >"$test_root/rejected-branch.out" 2>&1; then
  echo "Non-main provenance was accepted." >&2
  exit 1
fi
SOURCE_BRANCH=main
wrong_commit="$TEMPLATE_COMMIT"
TEMPLATE_COMMIT=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
if produce_first_app_contract >"$test_root/rejected.out" 2>&1; then
  echo "A mismatched checkout was accepted." >&2
  exit 1
fi
TEMPLATE_COMMIT="$wrong_commit"
! grep -F 'ghp_fixture_secret_value' "$test_root/rejected-branch.out" "$test_root/rejected.out" >/dev/null

git -C "$project" check-ignore -q FIRST_APP_HANDOFF.md
git -C "$project" check-ignore -q .first-app/receipt.json

echo "Bootstrap contract checks passed."
