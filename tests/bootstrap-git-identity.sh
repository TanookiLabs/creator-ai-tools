#!/bin/bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
setup="$repo_root/setup.sh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-git-identity.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
sed -n '/^valid_git_email() {/,/^}$/p' "$setup" > "$test_root/functions.sh"
sed -n '/^configure_github_git_identity() {/,/^}$/p' "$setup" >> "$test_root/functions.sh"
source "$test_root/functions.sh"
fail() { return 1; }
HOME="$test_root/home"; export HOME; mkdir "$HOME"
mkdir "$test_root/bin"
cat > "$test_root/bin/gh" <<'EOF'
#!/bin/sh
case "${GH_EMAIL_CASE:-}" in
 valid) printf 'verified@example.test\n' ;;
 json) printf '{"message":"Not Found","status":"404"}\n' ;;
 multiline) printf 'one@example.test\ntwo@example.test\n' ;;
 *) : ;;
esac
EOF
chmod +x "$test_root/bin/gh"; PATH="$test_root/bin:$PATH"
GITHUB_VERIFIED=true GH_USER_ID=42 GH_USER=octo
GH_EMAIL_CASE=json configure_github_git_identity
test "$(git config --global user.email)" = 42+octo@users.noreply.github.com
GH_EMAIL_CASE=multiline configure_github_git_identity
test "$(git config --global user.email)" = 42+octo@users.noreply.github.com
git config --global user.email participant@example.test
git config --global --unset vibe-coding-setup.managed-email || true
GH_EMAIL_CASE=json configure_github_git_identity
test "$(git config --global user.email)" = participant@example.test
git config --global user.email '{"message":"Not Found"}'
git config --global vibe-coding-setup.managed-email true
GH_EMAIL_CASE= configure_github_git_identity
test "$(git config --global user.email)" = 42+octo@users.noreply.github.com
git var GIT_AUTHOR_IDENT >/dev/null
GH_USER_ID=''; GH_USER=''
if configure_github_git_identity; then
  echo "Unverified GitHub identity was accepted." >&2
  exit 1
fi
echo "Git identity checks passed."
