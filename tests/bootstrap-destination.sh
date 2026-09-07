#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
setup="$repo_root/setup.sh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-destination.XXXXXX")
trap 'rm -rf "$test_root"' EXIT

# Load only the destination functions. The complete bootstrap is interactive
# and macOS-only; these focused tests use a local immutable Git source.
sed -n '/^resolve_destination() {/,/^SRC_DIR=/p' "$setup" | sed '$d' > "$test_root/functions.sh"
# shellcheck source=/dev/null
source "$test_root/functions.sh"
info() { :; }
fail() { printf '%s\n' "$*" >&2; }

mkdir "$test_root/source"
git -C "$test_root/source" init --quiet
git -C "$test_root/source" config user.name Test
git -C "$test_root/source" config user.email test@example.invalid
mkdir -p "$test_root/source/app" "$test_root/source/prisma"
touch "$test_root/source/package.json" "$test_root/source/package-lock.json"
touch "$test_root/source/next.config.ts" "$test_root/source/prisma/schema.prisma"
touch "$test_root/source/app/page.tsx"
touch "$test_root/source/CLAUDE.md" "$test_root/source/README.md"
git -C "$test_root/source" add .
git -C "$test_root/source" commit --quiet -m template
TEMPLATE_REPOSITORY="$test_root/source"
TEMPLATE_COMMIT=$(git -C "$test_root/source" rev-parse HEAD)

mkdir -p "$test_root/paths/existing"
expected_paths_root=$(cd "$test_root/paths" && pwd -P)
test "$(resolve_destination "$test_root/paths/new/../project")" = "$expected_paths_root/project"

root="$test_root/Documents/src/my-app"
test "$(destination_state "$root")" = absent
checkout_template "$root" absent
test "$(destination_state "$root")" = complete
test "$(git -C "$root" rev-parse HEAD)" = "$TEMPLATE_COMMIT"
template_markers_are_valid "$root"
test "$(ensure_participant_branch "$root")" = participant-work
test "$(git -C "$root" symbolic-ref --short HEAD)" = participant-work

# An unrelated nonempty destination is classified without changing its data.
unrelated="$test_root/Documents/src/existing"
mkdir "$unrelated"
printf 'participant data\n' > "$unrelated/keep.txt"
before=$(shasum -a 256 "$unrelated/keep.txt")
test "$(destination_state "$unrelated")" = unrelated
test "$(shasum -a 256 "$unrelated/keep.txt")" = "$before"

# A fetch interruption leaves a provenance marker and is safely resumable.
partial="$test_root/Documents/src/partial"
mkdir "$partial"
git -C "$partial" init --quiet
git -C "$partial" remote add origin "$TEMPLATE_REPOSITORY"
printf '%s\n%s\n' "$TEMPLATE_REPOSITORY" "$TEMPLATE_COMMIT" > "$partial/.git/vibe-template-checkout"
test "$(destination_state "$partial")" = incomplete
checkout_template "$partial" incomplete
test "$(destination_state "$partial")" = complete

# A moving ref is never accepted in place of the frozen full commit.
printf 'change\n' > "$test_root/source/moving"
git -C "$test_root/source" add moving
git -C "$test_root/source" commit --quiet -m moving
git -C "$root" fetch --quiet origin HEAD
git -C "$root" checkout --quiet --detach FETCH_HEAD
test "$(destination_state "$root")" = unrelated

# A forged/incomplete marker with the wrong origin remains unrelated.
forged="$test_root/Documents/src/forged"
mkdir "$forged"
git -C "$forged" init --quiet
git -C "$forged" remote add origin "$test_root/other"
printf '%s\n%s\n' "$TEMPLATE_REPOSITORY" "$TEMPLATE_COMMIT" > "$forged/.git/vibe-template-checkout"
test "$(destination_state "$forged")" = unrelated

echo "Bootstrap destination checks passed."
