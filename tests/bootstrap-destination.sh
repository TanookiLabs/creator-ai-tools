#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
setup="$repo_root/setup.sh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-destination.XXXXXX")
trap 'rm -rf "$test_root"' EXIT

# Load only the provenance and destination functions. The complete bootstrap
# is interactive and macOS-only; these focused tests use a local Git source.
sed -n '/^valid_full_commit() {/,/^}$/p' "$setup" > "$test_root/functions.sh"
sed -n '/^resolve_main_commit() {/,/^}$/p' "$setup" >> "$test_root/functions.sh"
sed -n '/^resolve_destination() {/,/^SRC_DIR=/p' "$setup" | sed '$d' >> "$test_root/functions.sh"
# shellcheck source=/dev/null
source "$test_root/functions.sh"
info() { :; }
warn() { :; }
ok() { :; }
fail() { printf '%s\n' "$*" >&2; }

mkdir "$test_root/source"
git -C "$test_root/source" init --quiet
git -C "$test_root/source" config user.name Test
git -C "$test_root/source" config user.email test@example.invalid
mkdir -p "$test_root/source/app" "$test_root/source/prisma"
touch "$test_root/source/package.json" "$test_root/source/package-lock.json"
touch "$test_root/source/next.config.ts" "$test_root/source/prisma/schema.prisma"
touch "$test_root/source/app/page.tsx"
touch "$test_root/source/CLAUDE.md"
printf '# Candidate starter\n\nUse this current README.\n' > "$test_root/source/README.md"
git -C "$test_root/source" add .
git -C "$test_root/source" commit --quiet -m template
git -C "$test_root/source" branch -M main
TEMPLATE_REPOSITORY="$test_root/source"
SOURCE_BRANCH=main
TEMPLATE_COMMIT=""
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid

# Resolve main once, then retain that exact checkout commit for this run.
resolve_main_commit
initial_template_commit="$TEMPLATE_COMMIT"
test "$TEMPLATE_COMMIT" = "$(git -C "$test_root/source" rev-parse main)"

# A later change to main cannot change the already-pinned checkout.
printf 'change\n' > "$test_root/source/moving"
git -C "$test_root/source" add moving
git -C "$test_root/source" commit --quiet -m moving
test "$TEMPLATE_COMMIT" = "$initial_template_commit"

mkdir -p "$test_root/paths/existing"
expected_paths_root=$(cd "$test_root/paths" && pwd -P)
test "$(resolve_destination "$test_root/paths/new/../project")" = "$expected_paths_root/project"

root="$test_root/Documents/src/my-app"
test "$(destination_state "$root")" = absent
copy_template_worktree "$root" absent
initialize_participant_repository "$root"
test "$(destination_state "$root")" = complete
template_markers_are_valid "$root"
grep -F 'Use this current README.' "$root/README.md" >/dev/null
test "$(git -C "$root" symbolic-ref --short HEAD)" = participant-work
test "$(git -C "$root" rev-list --count HEAD)" -eq 1
test "$(git -C "$root" remote get-url origin 2>/dev/null || true)" = ""
test "$(git -C "$root" remote get-url template)" = "$TEMPLATE_REPOSITORY"
test "$(git -C "$root" remote get-url --push template)" = DISABLED
if git -C "$root" push template participant-work >/dev/null 2>&1; then
  echo "The template remote accepted a participant push." >&2
  exit 1
fi
test "$(sed -n '1p' "$root/.git/vibe-template-provenance")" = "$TEMPLATE_REPOSITORY"
test "$(sed -n '2p' "$root/.git/vibe-template-provenance")" = "$initial_template_commit"

# Skipped GitHub authentication keeps the independent local repository and no
# writable origin. A later authenticated run may create the private origin.
GITHUB_VERIFIED=false
GH_USER=""
create_participant_repository "$root" my-app
test "$(git -C "$root" remote get-url origin 2>/dev/null || true)" = ""

mkdir "$test_root/bin" "$test_root/remotes" "$test_root/gh-state"
cat > "$test_root/bin/gh" <<'EOF'
#!/bin/sh
if [ "$1" = repo ] && [ "$2" = view ]; then
  name=${3#test-user/}
  test -f "$FAKE_GH_STATE/$name" || exit 1
  printf 'test-user/%s|https://github.com/test-user/%s\n' "$name" "$name"
  exit 0
fi
if [ "$1" = repo ] && [ "$2" = create ]; then
  name=$3
  case " $* " in
    *" --private "*) ;;
    *) exit 1 ;;
  esac
  case " $* " in
    *" --remote=origin "*) ;;
    *) exit 1 ;;
  esac
  case " $* " in
    *" --push "*) ;;
    *) exit 1 ;;
  esac
  for arg in "$@"; do
    case "$arg" in --source=*) root=${arg#--source=} ;; esac
  done
  git init --bare --quiet "$FAKE_GH_REPOSITORIES/$name.git"
  touch "$FAKE_GH_STATE/$name"
  git -C "$root" remote add origin "https://github.com/test-user/$name.git"
  if [ "$FAKE_GH_CREATE_PUSH_FAIL" = 1 ]; then
    exit 1
  fi
  git -C "$root" push --quiet origin participant-work:participant-work
  exit 0
fi
exit 1
EOF
chmod +x "$test_root/bin/gh"
PATH="$test_root/bin:$PATH"
export FAKE_GH_REPOSITORIES="$test_root/remotes" FAKE_GH_STATE="$test_root/gh-state"
configure_fake_github() {
  git -C "$1" config url."file://$test_root/remotes/".insteadOf https://github.com/test-user/
}
GITHUB_VERIFIED=true
GH_USER=test-user
VIBE_SETUP_ASSUME_YES=1
configure_fake_github "$root"
create_participant_repository "$root" my-app
test "$(git -C "$root" config --get remote.origin.url)" = https://github.com/test-user/my-app.git
test "$(git -C "$root" ls-remote --heads origin refs/heads/participant-work | awk 'NR == 1 { print $1 }')" = "$(git -C "$root" rev-parse participant-work)"
test "$(git -C "$root" remote get-url template)" = "$TEMPLATE_REPOSITORY"
test "$(git -C "$root" remote get-url --push template)" = DISABLED

# If GitHub creates the repository but its initial --push fails, origin and the
# marker survive; the installer completes the safe branch push without a
# duplicate repository. A rerun reconnects an absent local origin from that
# recorded participant-owned repository.
partial="$test_root/Documents/src/partial-app"
copy_template_worktree "$partial" absent
initialize_participant_repository "$partial"
configure_fake_github "$partial"
FAKE_GH_CREATE_PUSH_FAIL=1 create_participant_repository "$partial" partial-app
test "$(git -C "$partial" config --get remote.origin.url)" = https://github.com/test-user/partial-app.git
test -f "$partial/.git/vibe-participant-repository"
test "$(git -C "$partial" ls-remote --heads origin refs/heads/participant-work | awk 'NR == 1 { print $1 }')" = "$(git -C "$partial" rev-parse participant-work)"
git -C "$partial" remote remove origin
create_participant_repository "$partial" partial-app
test "$(git -C "$partial" config --get remote.origin.url)" = https://github.com/test-user/partial-app.git

# A participant-owned remote branch with a different commit is never forced or
# overwritten during a rerun.
conflict="$test_root/Documents/src/conflict-app"
copy_template_worktree "$conflict" absent
initialize_participant_repository "$conflict"
configure_fake_github "$conflict"
git init --bare --quiet "$test_root/remotes/conflict-app.git"
touch "$test_root/gh-state/conflict-app"
git -C "$conflict" remote add origin https://github.com/test-user/conflict-app.git
record_participant_repository "$conflict" conflict-app
seed="$test_root/seed"
git clone --quiet "$test_root/remotes/conflict-app.git" "$seed"
git -C "$seed" config user.name Test
git -C "$seed" config user.email test@example.invalid
printf 'conflicting history\n' > "$seed/README.md"
git -C "$seed" add README.md
git -C "$seed" commit --quiet -m conflict
git -C "$seed" push --quiet origin HEAD:participant-work
remote_before=$(git -C "$conflict" ls-remote --heads origin refs/heads/participant-work | awk 'NR == 1 { print $1 }')
if create_participant_repository "$conflict" conflict-app; then
  echo "A conflicting participant-work branch was accepted." >&2
  exit 1
fi
test "$(git -C "$conflict" ls-remote --heads origin refs/heads/participant-work | awk 'NR == 1 { print $1 }')" = "$remote_before"

# An unrelated nonempty destination is classified without changing its data.
unrelated="$test_root/Documents/src/existing"
mkdir "$unrelated"
printf 'participant data\n' > "$unrelated/keep.txt"
before=$(shasum -a 256 "$unrelated/keep.txt")
test "$(destination_state "$unrelated")" = unrelated
test "$(shasum -a 256 "$unrelated/keep.txt")" = "$before"

# A clean legacy template checkout can be explicitly converted, but any
# participant commit or worktree change prevents history/remotes from changing.
legacy="$test_root/Documents/src/legacy"
git clone --quiet "$TEMPLATE_REPOSITORY" "$legacy"
git -C "$legacy" checkout --quiet --detach "$initial_template_commit"
test "$(destination_state "$legacy")" = legacy
convert_legacy_template_checkout "$legacy"
test "$(git -C "$legacy" symbolic-ref --short HEAD)" = participant-work
test "$(git -C "$legacy" rev-list --count HEAD)" -eq 1
test "$(git -C "$legacy" remote get-url origin 2>/dev/null || true)" = ""
test "$(git -C "$legacy" remote get-url template)" = "$TEMPLATE_REPOSITORY"
test "$(git -C "$legacy" remote get-url --push template)" = DISABLED

git -C "$legacy" config user.name Test
git -C "$legacy" config user.email test@example.invalid
printf 'participant change\n' > "$legacy/participant.txt"
git -C "$legacy" add participant.txt
git -C "$legacy" commit --quiet -m participant-change
legacy_head=$(git -C "$legacy" rev-parse HEAD)
if convert_legacy_template_checkout "$legacy"; then
  echo "Existing participant history was rewritten." >&2
  exit 1
fi
test "$(git -C "$legacy" rev-parse HEAD)" = "$legacy_head"

echo "Bootstrap destination checks passed."
