#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
setup="$repo_root/setup.sh"
readme="$repo_root/README.md"

search_extended() {
  if command -v rg >/dev/null 2>&1; then
    rg -n "$@"
  else
    grep -nE "$@"
  fi
}

/bin/bash -n "$setup"

# GitHub browser authentication is launched only in an interactive GUI login
# context. SSH and background shells remain non-authoritative.
grep -F 'github_auth_context_is_authoritative' "$setup" >/dev/null
grep -F 'SSH_CONNECTION' "$setup" >/dev/null
grep -F 'gui_context_required' "$setup" >/dev/null
grep -F 'gh auth login --web --git-protocol https' "$setup" >/dev/null
gui_gate_line=$(grep -n 'if ! github_auth_context_is_authoritative; then' "$setup" | tail -1 | cut -d: -f1)
github_login_line=$(awk -v gate="$gui_gate_line" 'NR > gate && /gh auth login --web --git-protocol https/ { print NR; exit }' "$setup")
test "$gui_gate_line" -lt "$github_login_line"

# Interactive Homebrew work must remain visible and preserve the tool's exit
# status instead of hiding prompts inside a spinner.
grep -F 'brew_install_visible() {' "$setup" >/dev/null
grep -F 'brew install "$@"' "$setup" >/dev/null
grep -F 'Retry this phase from a macOS Terminal with:' "$setup" >/dev/null
if grep -nE 'spin .*brew install' "$setup"; then
  echo "Homebrew installation is hidden behind a spinner." >&2
  exit 1
fi

grep -F 'verify_gui_login_shell() {' "$setup" >/dev/null
grep -F 'GUI_LOGIN_SHELL_BIN="/bin/zsh"' "$setup" >/dev/null
grep -F 'collect_gui_login_shell_missing() {' "$setup" >/dev/null
grep -F 'mise node npm ruby claude' "$setup" >/dev/null
grep -F 'Setup will recheck its managed shell configuration and check once more.' "$setup" >/dev/null
grep -F 'if [[ "$OPTIONAL_CLI_STATE" == "off-PATH" ]]; then' "$setup" >/dev/null
last_profile_change_line=$(grep -n '^append_profile ' "$setup" | tail -1 | cut -d: -f1)
gui_verification_line=$(grep -n '^verify_gui_login_shell$' "$setup" | tail -1 | cut -d: -f1)
test "$last_profile_change_line" -lt "$gui_verification_line"

grep -F 'curl -fsSL https://raw.githubusercontent.com/TanookiLabs/creator-ai-tools/main/setup.sh -o /tmp/creator-ai-setup.sh && /bin/bash /tmp/creator-ai-setup.sh' "$readme" >/dev/null
grep -F 'resolve_main_commit() {' "$setup" >/dev/null
grep -F 'refs/heads/${SOURCE_BRANCH}' "$setup" >/dev/null
grep -F 'Pinned starter template to ${TEMPLATE_COMMIT} from ${SOURCE_BRANCH}' "$setup" >/dev/null
if search_extended 'VIBE_SETUP_(INSTALLER|TEMPLATE)_COMMIT|bootstrap-v1\.1\.0-rc\.1|resolve_release_commit|source_mode|release_tag' "$setup" "$readme" "$repo_root/docs/first-app-handoff-contract.md"; then
  echo "Strict release-candidate mechanics remain in active bootstrap sources." >&2
  exit 1
else
  search_status=$?
  if (( search_status > 1 )); then
    echo "Unable to inspect bootstrap sources for stale release mechanics." >&2
    exit "$search_status"
  fi
fi

platform_line=$(grep -n 'uname -s' "$setup" | head -1 | cut -d: -f1)
profile_validation_line=$(grep -n '^validate_shell_profile$' "$setup" | head -1 | cut -d: -f1)
discovery_line=$(grep -n '^BREW_STATE=' "$setup" | head -1 | cut -d: -f1)
test "$platform_line" -lt "$profile_validation_line"
test "$profile_validation_line" -lt "$discovery_line"

output=$(printf '' | /bin/bash "$setup" 2>&1 || true)
grep -F "Vibe Coding Setup" <<<"$output" >/dev/null
grep -F "Active phase: startup validation" <<<"$output" >/dev/null
grep -F "needs an interactive terminal" <<<"$output" >/dev/null
grep -F "No credentials or environment values are included" <<<"$output" >/dev/null

test_root=$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-safety.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/home" "$test_root/bin" "$test_root/off-path"

cat > "$test_root/bin/uname" <<'EOF'
#!/bin/sh
echo Darwin
EOF
cat > "$test_root/bin/git" <<'EOF'
#!/bin/sh
exit 7
EOF
cat > "$test_root/off-path/brew" <<EOF
#!/bin/sh
if [ "\$1" = shellenv ]; then
  echo 'export PATH="$test_root/off-path:\$PATH"'
else
  echo 'Homebrew 4.6.0'
fi
EOF
chmod +x "$test_root/bin/uname" "$test_root/bin/git" "$test_root/off-path/brew"

run_preflight() {
  local command="env HOME='$test_root/home' PATH='$test_root/bin:/usr/bin:/bin' VIBE_SETUP_BREW_CANDIDATES='$test_root/off-path/brew' VIBE_SETUP_PREFLIGHT_ONLY=1 /bin/bash '$setup'"
  if script --version >/dev/null 2>&1; then
    script -qec "$command" /dev/null 2>&1
  else
    script -q /dev/null /bin/bash -c "$command" 2>&1
  fi
}

preflight_output=$(run_preflight)
grep -E 'Homebrew +off-PATH' <<<"$preflight_output" >/dev/null
grep -E 'Git +unhealthy' <<<"$preflight_output" >/dev/null
grep -E 'Node.js +(healthy|missing)' <<<"$preflight_output" >/dev/null
grep -F 'Preflight complete. No installation phases were run.' <<<"$preflight_output" >/dev/null
test "$(grep -cF '# >>> vibe-coding-setup:homebrew >>>' "$test_root/home/.zshrc")" -eq 1

run_preflight >/dev/null
test "$(grep -cF '# >>> vibe-coding-setup:homebrew >>>' "$test_root/home/.zshrc")" -eq 1

# A missing profile is created only inside a current-user-owned, writable
# directory. An existing unwritable or differently owned profile fails closed
# and remains byte-for-byte unchanged.
rm "$test_root/home/.zshrc"
run_preflight >/dev/null
test -f "$test_root/home/.zshrc"
test "$(grep -cF '# >>> vibe-coding-setup:homebrew >>>' "$test_root/home/.zshrc")" -eq 1

printf 'participant unwritable setting\n' > "$test_root/unwritable-profile"
chmod 400 "$test_root/unwritable-profile"
unwritable_before=$(shasum -a 256 "$test_root/unwritable-profile")
if script --version >/dev/null 2>&1; then
  unwritable_output=$(script -qec "env HOME='$test_root/home' PATH='$test_root/bin:/usr/bin:/bin' VIBE_SETUP_SHELL_PROFILE='$test_root/unwritable-profile' VIBE_SETUP_PREFLIGHT_ONLY=1 /bin/bash '$setup'" /dev/null 2>&1 || true)
else
  unwritable_output=$(script -q /dev/null /bin/bash -c "env HOME='$test_root/home' PATH='$test_root/bin:/usr/bin:/bin' VIBE_SETUP_SHELL_PROFILE='$test_root/unwritable-profile' VIBE_SETUP_PREFLIGHT_ONLY=1 /bin/bash '$setup'" 2>&1 || true)
fi
grep -F 'not owned and writable by the current user' <<<"$unwritable_output" >/dev/null
test "$(shasum -a 256 "$test_root/unwritable-profile")" = "$unwritable_before"

printf 'participant differently owned setting\n' > "$test_root/wrong-owner-profile"
sudo -n chown 0 "$test_root/wrong-owner-profile"
wrong_owner_before=$(shasum -a 256 "$test_root/wrong-owner-profile")
if script --version >/dev/null 2>&1; then
  wrong_owner_output=$(script -qec "env HOME='$test_root/home' PATH='$test_root/bin:/usr/bin:/bin' VIBE_SETUP_SHELL_PROFILE='$test_root/wrong-owner-profile' VIBE_SETUP_PREFLIGHT_ONLY=1 /bin/bash '$setup'" /dev/null 2>&1 || true)
else
  wrong_owner_output=$(script -q /dev/null /bin/bash -c "env HOME='$test_root/home' PATH='$test_root/bin:/usr/bin:/bin' VIBE_SETUP_SHELL_PROFILE='$test_root/wrong-owner-profile' VIBE_SETUP_PREFLIGHT_ONLY=1 /bin/bash '$setup'" 2>&1 || true)
fi
grep -F 'not owned and writable by the current user' <<<"$wrong_owner_output" >/dev/null
test "$(shasum -a 256 "$test_root/wrong-owner-profile")" = "$wrong_owner_before"

printf 'participant setting\n' > "$test_root/profile-target"
ln -s "$test_root/profile-target" "$test_root/unsafe-profile"
if script --version >/dev/null 2>&1; then
  unsafe_output=$(script -qec "env HOME='$test_root/home' PATH='$test_root/bin:/usr/bin:/bin' VIBE_SETUP_SHELL_PROFILE='$test_root/unsafe-profile' VIBE_SETUP_PREFLIGHT_ONLY=1 /bin/bash '$setup'" /dev/null 2>&1 || true)
else
  unsafe_output=$(script -q /dev/null /bin/bash -c "env HOME='$test_root/home' PATH='$test_root/bin:/usr/bin:/bin' VIBE_SETUP_SHELL_PROFILE='$test_root/unsafe-profile' VIBE_SETUP_PREFLIGHT_ONLY=1 /bin/bash '$setup'" 2>&1 || true)
fi
grep -F 'shell profile is a symbolic link' <<<"$unsafe_output" >/dev/null
test "$(cat "$test_root/profile-target")" = 'participant setting'
test ! -e "$test_root/home/.unsafe-profile-created"

if grep -nE 'curl[^|]*\|[[:space:]]*(ba)?sh' "$readme"; then
  echo "Interactive curl-to-shell guidance remains in a primary entrypoint." >&2
  exit 1
fi

echo "Bootstrap safety checks passed."
