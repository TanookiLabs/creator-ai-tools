#!/bin/bash
set -euo pipefail

# Captures and restores only the known Vercel Marketplace agent-installation
# side effects. State lives outside the participant project and is disposable.
action="$1"
root="$2"
state="$3"
artifacts=(".agents" ".claude/skills/neon" ".claude/skills/neon-postgres" "skills-lock.json")

tracked() {
  git -C "$root" ls-files --error-unmatch -- "$1" >/dev/null 2>&1
}

capture() {
  mkdir -p "$state"
  git -C "$root" status --short > "$state/status"
  for path in "${artifacts[@]}"; do
    [[ -e "$root/$path" ]] && printf 'present\n' > "$state/$(echo "$path" | tr '/' '_').exists" || : > "$state/$(echo "$path" | tr '/' '_').exists"
    tracked "$path" && printf 'tracked\n' > "$state/$(echo "$path" | tr '/' '_').tracked" || : > "$state/$(echo "$path" | tr '/' '_').tracked"
  done
  if [[ -e "$root/.gitignore" ]]; then
    cp "$root/.gitignore" "$state/gitignore"
    printf 'present\n' > "$state/gitignore.exists"
  else
    : > "$state/gitignore"
    : > "$state/gitignore.exists"
  fi
  git -C "$root" diff --quiet -- .gitignore && printf 'clean\n' > "$state/gitignore.clean" || : > "$state/gitignore.clean"
}

restore_gitignore() {
  [[ -s "$state/gitignore.clean" ]] || return
  local expected="$state/gitignore.expected"
  cp "$state/gitignore" "$expected"
  printf '%s\n' '.env*' >> "$expected"
  if cmp -s "$root/.gitignore" "$expected"; then
    if [[ -s "$state/gitignore.exists" ]]; then cp "$state/gitignore" "$root/.gitignore"; else rm -f "$root/.gitignore"; fi
  fi
}

cleanup() {
  for path in "${artifacts[@]}"; do
    local_key=$(echo "$path" | tr '/' '_')
    if [[ ! -s "$state/$local_key.exists" && -e "$root/$path" && ! -s "$state/$local_key.tracked" ]] && ! tracked "$path"; then
      rm -rf "$root/$path"
    fi
  done
  restore_gitignore
  if ! cmp -s "$state/status" <(git -C "$root" status --short); then
    echo "Repository state differs from the pre-provider state; stop for participant direction." >&2
    exit 1
  fi
}

case "$action" in
  capture) capture ;;
  cleanup) cleanup ;;
  *) echo "Usage: $0 capture|cleanup PROJECT_ROOT STATE_DIR" >&2; exit 64 ;;
esac
