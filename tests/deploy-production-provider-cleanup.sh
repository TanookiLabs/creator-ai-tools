#!/bin/bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
helper="$repo_root/.claude/skills/deploy-production/cleanup-provider-side-effects.sh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/deploy-provider-cleanup.XXXXXX")
state=$(mktemp -d "${TMPDIR:-/tmp}/deploy-provider-state.XXXXXX")
state_preserve=$(mktemp -d "${TMPDIR:-/tmp}/deploy-provider-state.XXXXXX")
trap 'rm -rf "$test_root" "$state" "$state_preserve"' EXIT

git -C "$test_root" init -q
git -C "$test_root" config user.name fixture
git -C "$test_root" config user.email fixture@example.test
printf 'node_modules\n' > "$test_root/.gitignore"
printf 'starter\n' > "$test_root/app.txt"
git -C "$test_root" add . && git -C "$test_root" commit -qm initial
"$helper" capture "$test_root" "$state"
mkdir -p "$test_root/.agents" "$test_root/.claude/skills/neon" "$test_root/.claude/skills/neon-postgres"
touch "$test_root/.agents/provider" "$test_root/.claude/skills/neon/skill" "$test_root/.claude/skills/neon-postgres/skill" "$test_root/skills-lock.json"
printf 'node_modules\n.env*\n' > "$test_root/.gitignore"
"$helper" cleanup "$test_root" "$state"
test ! -e "$test_root/.agents"
test ! -e "$test_root/.claude/skills/neon"
test ! -e "$test_root/.claude/skills/neon-postgres"
test ! -e "$test_root/skills-lock.json"
test "$(git -C "$test_root" status --short)" = ""

mkdir -p "$test_root/.agents" "$test_root/.claude/skills/neon"
touch "$test_root/.agents/participant" "$test_root/.claude/skills/neon/participant"
"$helper" capture "$test_root" "$state_preserve"
printf 'node_modules\n.env*\nparticipant\n' > "$test_root/.gitignore"
if "$helper" cleanup "$test_root" "$state_preserve"; then
  echo "Cleanup accepted participant changes." >&2
  exit 1
fi
test -e "$test_root/.agents/participant"
test -e "$test_root/.claude/skills/neon/participant"
test -f "$test_root/.gitignore"
echo "Provider side-effect cleanup checks passed."
