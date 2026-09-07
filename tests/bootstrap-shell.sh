#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
setup="$repo_root/setup.sh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-shell.XXXXXX")
trap 'rm -rf "$test_root"' EXIT

# Load only shell-profile and GUI login-shell verification helpers.
sed -n '/^SHELL_PROFILE=/,/^tool_state() {/p' "$setup" | sed '$d' > "$test_root/functions.sh"
sed -n '/^collect_gui_login_shell_missing() {/,/^# ── Confetti/p' "$setup" | sed '$d' >> "$test_root/functions.sh"
# shellcheck source=/dev/null
source "$test_root/functions.sh"

warn() { printf '%s\n' "$*"; }
info() { printf '%s\n' "$*"; }
ok() { printf '%s\n' "$*"; }
github_auth_context_is_authoritative() { return 0; }

mkdir -p "$test_root/home" "$test_root/bin"
SHELL_PROFILE="$test_root/home/.zshrc"
printf '%s\n' 'eval "$(mise activate zsh)"' > "$SHELL_PROFILE"
PSQL_BIN=""
OPTIONAL_CLI_STATE=healthy
BREW_PROFILE_LINE=""
managed_shell_profile_is_ready

# An already healthy Claude command can be configured by the participant and
# does not need our managed PATH block. An off-PATH or newly installed Claude
# command does need that durable block before a fresh login shell is ready.
OPTIONAL_CLI_STATE=off-PATH
if managed_shell_profile_is_ready; then
  echo "An off-PATH Claude command was accepted without a managed PATH block." >&2
  exit 1
fi
append_profile 'export PATH="$HOME/.local/bin:$PATH"' "claude-cli"
managed_shell_profile_is_ready

printf '%s\n' 'eval "$(mise activate zsh)"' > "$SHELL_PROFILE"
OPTIONAL_CLI_STATE=missing
if managed_shell_profile_is_ready; then
  echo "A fresh Claude installation was accepted without a managed PATH block." >&2
  exit 1
fi
append_profile 'export PATH="$HOME/.local/bin:$PATH"' "claude-cli"
managed_shell_profile_is_ready
OPTIONAL_CLI_STATE=healthy

cat > "$test_root/bin/zsh" <<'EOF'
#!/bin/sh
count=$(cat "$GUI_SHELL_COUNT" 2>/dev/null || printf 0)
count=$((count + 1))
printf '%s' "$count" > "$GUI_SHELL_COUNT"
case "${GUI_SHELL_MODE:-success}" in
  transient) [ "$count" -eq 1 ] && printf '%s\n' claude ;;
  persistent) printf '%s\n' node claude ghp_fixture_secret_value ;;
esac
exit 0
EOF
chmod +x "$test_root/bin/zsh"
GUI_LOGIN_SHELL_BIN="$test_root/bin/zsh"
export GUI_SHELL_COUNT="$test_root/count"

export GUI_SHELL_MODE=success
rm -f "$GUI_SHELL_COUNT"
verify_gui_login_shell > "$test_root/first.out"
first_output=$(<"$test_root/first.out")
test "$GUI_LOGIN_SHELL_VERIFIED" = true
test -z "$GUI_LOGIN_SHELL_MISSING"
test "$(cat "$GUI_SHELL_COUNT")" = 1
grep -F 'resolves mise, Node.js, npm, Ruby, and Claude' <<<"$first_output" >/dev/null

export GUI_SHELL_MODE=transient
rm -f "$GUI_SHELL_COUNT"
verify_gui_login_shell > "$test_root/retry.out"
retry_output=$(<"$test_root/retry.out")
test "$GUI_LOGIN_SHELL_VERIFIED" = true
test -z "$GUI_LOGIN_SHELL_MISSING"
test "$(cat "$GUI_SHELL_COUNT")" = 2
grep -F 'could not find: claude' <<<"$retry_output" >/dev/null
grep -F 'managed shell configuration' <<<"$retry_output" >/dev/null
grep -F 'after one internal retry' <<<"$retry_output" >/dev/null

export GUI_SHELL_MODE=persistent
rm -f "$GUI_SHELL_COUNT"
verify_gui_login_shell > "$test_root/persistent.out"
persistent_output=$(<"$test_root/persistent.out")
test "$GUI_LOGIN_SHELL_VERIFIED" = false
test "$GUI_LOGIN_SHELL_MISSING" = node,claude
test "$(cat "$GUI_SHELL_COUNT")" = 2
grep -F 'could not find: node,claude' <<<"$persistent_output" >/dev/null
! grep -F 'ghp_fixture_secret_value' <<<"$persistent_output" >/dev/null

echo "Bootstrap GUI login-shell checks passed."
