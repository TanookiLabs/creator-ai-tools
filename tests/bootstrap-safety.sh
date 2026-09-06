#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
setup="$repo_root/setup.sh"
readme="$repo_root/README.md"

/bin/bash -n "$setup"

# Authentication is observed only in an interactive GUI login context. The
# bootstrap never launches authentication or treats SSH as authoritative.
grep -F 'github_auth_context_is_authoritative' "$setup" >/dev/null
grep -F 'SSH_CONNECTION' "$setup" >/dev/null
grep -F 'gui_context_required' "$setup" >/dev/null
if grep -nE '^[[:space:]]*gh auth login([[:space:]]|$)' "$setup"; then
  echo "The bootstrap must not automate GitHub authentication." >&2
  exit 1
fi

documented_digest=$(sed -n "s/.*'\([0-9a-f]\{64\}\)' \"\$bootstrap_tmp\/setup.sh\".*/\1/p" "$readme")
actual_digest=$(shasum -a 256 "$setup" | awk '{print $1}')
test "$documented_digest" = "$actual_digest"

platform_line=$(grep -n 'uname -s' "$setup" | head -1 | cut -d: -f1)
profile_validation_line=$(grep -n '^validate_shell_profile$' "$setup" | head -1 | cut -d: -f1)
discovery_line=$(grep -n '^BREW_STATE=' "$setup" | head -1 | cut -d: -f1)
test "$platform_line" -lt "$profile_validation_line"
test "$profile_validation_line" -lt "$discovery_line"

output=$(printf '' | /bin/bash "$setup" 2>&1 || true)
grep -F "Vibe Coding Setup 1.0.0" <<<"$output" >/dev/null
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
sudo -n chown root:root "$test_root/wrong-owner-profile"
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
