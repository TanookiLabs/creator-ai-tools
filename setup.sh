#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════
# Vibe Coding Setup
# One command that takes a fresh Mac from nothing to a fully
# working development machine, then hands off to Claude Code
# to build the user's first app.
#
# Run with:
#   curl -fsSL https://raw.githubusercontent.com/ericskiff/vibe-setup/main/setup.sh | bash
#
# Or download it and run: bash setup.sh
#
# All user-facing text follows ASD-STE100 Simplified Technical
# English: short sentences, active voice, one instruction per
# sentence, no idioms, no contractions.
# ═══════════════════════════════════════════════════════════════

# When piped from curl, stdin is the script itself. Reattach the
# terminal so interactive prompts work.
if [[ ! -t 0 ]]; then
  if [[ -e /dev/tty ]]; then
    exec < /dev/tty
  else
    echo "This script needs an interactive terminal."
    echo "Download the script. Then run: bash setup.sh"
    exit 1
  fi
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only."
  exit 1
fi

# ── Pre-TUI helpers (used before gum is available) ────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

pre_ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
pre_warn() { echo -e "  ${YELLOW}!${NC} $1"; }
pre_fail() { echo -e "  ${RED}✗${NC} $1"; }

# ── Shell profile helper ──────────────────────────────────────

SHELL_PROFILE="$HOME/.zshrc"
touch "$SHELL_PROFILE"

append_profile() {
  local line="$1"
  local comment="$2"
  if ! grep -qF "$line" "$SHELL_PROFILE" 2>/dev/null; then
    {
      echo ''
      [[ -n "$comment" ]] && echo "# $comment"
      echo "$line"
    } >> "$SHELL_PROFILE"
  fi
}

# ── TUI helpers (used after gum is installed) ─────────────────

TOTAL_STEPS=8
CURRENT_STEP=0

header() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo ""
  gum style \
    --border rounded \
    --border-foreground 99 \
    --padding "0 2" \
    --margin "0 0" \
    --bold \
    "Step $CURRENT_STEP of $TOTAL_STEPS  ·  $1"
  echo ""
}

ok()   { gum style --foreground 76 "  ✓ $1"; }
warn() { gum style --foreground 214 "  ! $1"; }
fail() { gum style --foreground 196 --bold "  ✗ $1"; }
info() { gum style --foreground 111 "  → $1"; }

divider() {
  gum style --foreground 240 "  ─────────────────────────────────────────────────"
}

confirm() {
  gum confirm --prompt.foreground 255 --selected.background 99 --unselected.background 240 "$1"
}

spin() {
  local title="$1"
  shift
  gum spin --spinner dot --spinner.foreground 99 --title "  $title" -- "$@"
}

# ── Confetti animation ─────────────────────────────────────────

confetti() {
  local cols
  cols=$(tput cols 2>/dev/null || echo 80)
  local rows=8
  local frames=12
  local pieces=("🎉" "🎊" "✨" "⭐" "🌟" "💫" "🎯" "🚀" "💜" "🟣")

  tput civis 2>/dev/null || true

  for (( f=0; f<frames; f++ )); do
    if [[ $f -gt 0 ]]; then
      for (( r=0; r<rows; r++ )); do
        tput cuu1 2>/dev/null || echo -ne "\033[1A"
      done
    fi

    for (( r=0; r<rows; r++ )); do
      local line=""
      for (( c=0; c<cols-1; c++ )); do
        if (( RANDOM % 12 == 0 )); then
          local piece="${pieces[$((RANDOM % ${#pieces[@]}))]}"
          line+="$piece"
          c=$((c + 1))
        else
          line+=" "
        fi
      done
      echo -e "$line"
    done

    sleep 0.12
  done

  for (( r=0; r<rows; r++ )); do
    tput cuu1 2>/dev/null || echo -ne "\033[1A"
    tput el 2>/dev/null || echo -ne "\033[2K"
    echo ""
  done
  for (( r=0; r<rows; r++ )); do
    tput cuu1 2>/dev/null || echo -ne "\033[1A"
  done

  tput cnorm 2>/dev/null || true
}

# ═════════════════════════════════════════════════════════════════
# Phase 0: Bootstrap. Xcode CLT, Homebrew, and gum, in that order,
# since nothing else installs without them.
# ═════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}Vibe Coding Setup${NC}"
echo ""
echo "  This script prepares your Mac to build apps with Claude."
echo "  The installers can ask for your Mac password. This is normal."
echo ""
echo "  The script examines the basic tools..."
echo ""

# ── Xcode Command Line Tools ──────────────────────────────────

if xcode-select -p &>/dev/null; then
  pre_ok "Xcode Command Line Tools found"
else
  echo ""
  echo "  The script installs the Apple Command Line Tools."
  echo "  These tools contain the compilers and Git."
  echo "  This step takes 5 to 15 minutes."
  echo "  Type your Mac password if the system asks for it."
  echo ""

  # Headless install: the placeholder file makes softwareupdate list
  # the Command Line Tools as an installable update.
  CLT_PLACEHOLDER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  touch "$CLT_PLACEHOLDER"
  CLT_LABEL=$(softwareupdate -l 2>/dev/null | grep -E '\* Label: Command Line Tools' | sed 's/^[^:]*: //' | tail -1)
  if [[ -n "$CLT_LABEL" ]]; then
    echo "  The script installs: $CLT_LABEL"
    sudo softwareupdate -i "$CLT_LABEL" || true
  fi
  rm -f "$CLT_PLACEHOLDER"

  if xcode-select -p &>/dev/null; then
    pre_ok "Xcode Command Line Tools installed"
  else
    # Fallback: Apple's GUI installer dialog.
    xcode-select --install 2>/dev/null || true
    echo "  A dialog is open on your screen."
    echo "  Click Install. Accept the license."
    echo "  The setup continues automatically when the installation is complete."
    until xcode-select -p &>/dev/null; do
      sleep 10
    done
    pre_ok "Xcode Command Line Tools installed"
  fi
fi

# ── Homebrew ───────────────────────────────────────────────────

if command -v brew &>/dev/null; then
  pre_ok "Homebrew found"
else
  echo ""
  echo "  The script installs Homebrew."
  echo "  Homebrew is the package manager for the Mac."
  echo "  Type your Mac password if the system asks for it."
  echo ""
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    append_profile 'eval "$(/opt/homebrew/bin/brew shellenv)"' "Homebrew"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    append_profile 'eval "$(/usr/local/bin/brew shellenv)"' "Homebrew"
  fi

  if command -v brew &>/dev/null; then
    pre_ok "Homebrew installed"
  else
    pre_fail "The Homebrew installation was not successful."
    echo "  Close this terminal window. Open a new one. Run the script again."
    exit 1
  fi
fi

# ── gum (our TUI toolkit) ─────────────────────────────────────

if ! command -v gum &>/dev/null; then
  echo "  The script installs the interface toolkit..."
  brew install gum &>/dev/null
fi

if ! command -v gum &>/dev/null; then
  pre_fail "The gum installation was not successful. The script stops."
  exit 1
fi

pre_ok "Ready"
echo ""

# ═════════════════════════════════════════════════════════════════
# Welcome screen
# ═════════════════════════════════════════════════════════════════

clear

echo ""
gum style \
  --border double \
  --border-foreground 99 \
  --padding "1 4" \
  --margin "1 2" \
  --bold \
  "V I B E   C O D I N G   S E T U P" \
  "" \
  "From zero to your first app."

gum style --foreground 252 --margin "0 4" \
  "This script installs all the tools you need. Then Claude" \
  "builds your first app with you. The setup is almost fully" \
  "automatic. You give your Mac password when the system asks" \
  "for it. You log in to GitHub in the browser. You possibly" \
  "click one button in Postgres.app. That is all." \
  "" \
  "You can run this script again at any time. The script does" \
  "not install a tool that is already installed."

echo ""
gum style --foreground 240 --margin "0 4" \
  "Steps:" \
  "  1. Git & build libraries    5. Git identity" \
  "  2. mise, Node.js & Ruby     6. Claude Code & Claude app" \
  "  3. Postgres.app             7. Your source folder" \
  "  4. GitHub CLI & login       8. Claude handoff"

echo ""
divider
info "You need a GitHub account and an active Claude subscription."
echo ""

if ! confirm "  Do you have both accounts?"; then
  open "https://claude.ai" 2>/dev/null || true
  open "https://github.com/signup" 2>/dev/null || true
  warn "Two browser tabs are now open."
  info "Make the two accounts. Then press Enter here."
  read -rp ""
fi

spin "The script updates Homebrew..." brew update --quiet || true

# ═════════════════════════════════════════════════════════════════
# Step 1: Git and build libraries
# ═════════════════════════════════════════════════════════════════

header "Git & build libraries"

if command -v git &>/dev/null; then
  ok "Git installed ($(git --version | sed 's/git version //'))"
else
  spin "The script installs Git..." brew install git
  if command -v git &>/dev/null; then
    ok "Git installed"
  else
    fail "The Git installation was not successful."
    exit 1
  fi
fi

info "The script installs the libraries that Ruby and other tools need."
spin "The script installs the build libraries..." brew install libyaml gmp openssl@3 readline
ok "Build libraries installed"

# ═════════════════════════════════════════════════════════════════
# Step 2: mise, Node.js, and Ruby
# ═════════════════════════════════════════════════════════════════

header "mise, Node.js & Ruby"

info "mise controls the versions of Node.js, Ruby, and other languages."
echo ""

if command -v mise &>/dev/null; then
  ok "mise installed ($(mise --version 2>/dev/null | head -1))"
else
  spin "The script installs mise..." brew install mise
  if command -v mise &>/dev/null; then
    ok "mise installed"
  else
    fail "The mise installation was not successful. Run: brew install mise"
    exit 1
  fi
fi

append_profile 'eval "$(mise activate zsh)"' "mise version manager"
eval "$(mise activate bash --shims)"

divider

if mise which node &>/dev/null; then
  ok "Node.js $(mise exec -- node --version) (via mise)"
  spin "The script examines Node.js for updates..." mise upgrade node || true
else
  spin "The script installs Node.js (latest LTS)..." mise use -g node@lts
  if mise which node &>/dev/null; then
    ok "Node.js $(mise exec -- node --version) installed"
  else
    fail "The Node.js installation was not successful. Run: mise use -g node@lts"
    exit 1
  fi
fi

divider

if mise which ruby &>/dev/null; then
  ok "Ruby $(mise exec -- ruby --version | cut -d' ' -f2) (via mise)"
else
  info "The script installs Ruby. This step takes approximately 10 minutes."
  spin "The script installs Ruby..." mise use -g ruby@3 || true
  if mise which ruby &>/dev/null; then
    ok "Ruby $(mise exec -- ruby --version | cut -d' ' -f2) installed"
  else
    warn "The Ruby installation was not successful. Claude can repair this later."
  fi
fi

# ═════════════════════════════════════════════════════════════════
# Step 3: Postgres.app
# ═════════════════════════════════════════════════════════════════

header "Postgres.app"

info "Postgres.app operates a PostgreSQL database on your Mac."
info "Your apps keep their data in this database."
echo ""

if [[ -d "/Applications/Postgres.app" ]]; then
  ok "Postgres.app found"
else
  spin "The script installs Postgres.app..." brew install --cask postgres-app
  if [[ -d "/Applications/Postgres.app" ]]; then
    ok "Postgres.app installed"
  else
    fail "The installation was not successful. Download the app from https://postgresapp.com"
    exit 1
  fi
fi

append_profile 'export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"' "Postgres.app command line tools"
export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"

divider

pg_up() {
  psql -h localhost -U "$USER" -d postgres -c 'select 1' &>/dev/null
}

if pg_up; then
  ok "The Postgres server is on"
else
  info "The script opens Postgres.app."
  info "If you see an Initialize button, click it."
  info "The setup continues automatically when the server is on."
  open -a Postgres 2>/dev/null || true

  PG_WAITED=0
  until pg_up; do
    sleep 3
    PG_WAITED=$((PG_WAITED + 3))
    if [[ $PG_WAITED -ge 180 ]]; then
      break
    fi
  done

  if pg_up; then
    ok "The Postgres server is on"
  else
    warn "The server is not available. Claude will examine this later."
  fi
fi

# ═════════════════════════════════════════════════════════════════
# Step 4: GitHub CLI and authentication
# ═════════════════════════════════════════════════════════════════

header "GitHub CLI & login"

info "GitHub keeps your code online. The GitHub CLI lets Claude use GitHub."
echo ""

if command -v gh &>/dev/null; then
  ok "GitHub CLI installed"
else
  spin "The script installs the GitHub CLI..." brew install gh
  if command -v gh &>/dev/null; then
    ok "GitHub CLI installed"
  else
    fail "The GitHub CLI installation was not successful."
    exit 1
  fi
fi

divider

if gh auth status &>/dev/null 2>&1; then
  ok "You are logged in to GitHub"
else
  info "Log in to GitHub now. Obey the instructions on the screen."
  info "A browser window opens. The terminal shows a code. Type the"
  info "code in the browser."
  echo ""
  gh auth login --web --git-protocol https
  if gh auth status &>/dev/null 2>&1; then
    ok "You are logged in to GitHub"
  else
    fail "The GitHub login was not successful. Run: gh auth login"
    exit 1
  fi
fi

GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "")
GH_NAME=$(gh api user --jq '.name // empty' 2>/dev/null || echo "")
GH_PRIMARY_EMAIL=$(gh api user/emails --jq '.[] | select(.primary==true) | .email' 2>/dev/null || echo "")
GH_ALL_EMAILS=$(gh api user/emails --jq '.[].email' 2>/dev/null || echo "")

echo ""
ok "GitHub user: $GH_USER"
[[ -n "$GH_NAME" ]] && ok "Display name: $GH_NAME"
[[ -n "$GH_PRIMARY_EMAIL" ]] && ok "Primary email: $GH_PRIMARY_EMAIL"

# ═════════════════════════════════════════════════════════════════
# Step 5: Git identity
# ═════════════════════════════════════════════════════════════════

header "Git identity"

GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")

if [[ -n "$GIT_NAME" ]]; then
  ok "Git name: $GIT_NAME"
else
  GIT_NAME="${GH_NAME:-$GH_USER}"
  git config --global user.name "$GIT_NAME"
  ok "Git name set from GitHub: $GIT_NAME"
fi

GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [[ -n "$GIT_EMAIL" ]]; then
  ok "Git email: $GIT_EMAIL"
  if [[ -n "$GH_ALL_EMAILS" ]] && ! echo "$GH_ALL_EMAILS" | grep -qiF "$GIT_EMAIL"; then
    warn "This email is not in your GitHub account. Your commits will"
    warn "not connect to your GitHub profile. Claude can repair this later."
  fi
else
  if [[ -n "$GH_PRIMARY_EMAIL" ]]; then
    GIT_EMAIL="$GH_PRIMARY_EMAIL"
  elif [[ -n "$GH_ALL_EMAILS" ]]; then
    GIT_EMAIL=$(echo "$GH_ALL_EMAILS" | head -1)
  else
    GIT_EMAIL="$GH_USER@users.noreply.github.com"
  fi
  git config --global user.email "$GIT_EMAIL"
  ok "Git email set from GitHub: $GIT_EMAIL"
fi

git config --global init.defaultBranch main 2>/dev/null || true

# ═════════════════════════════════════════════════════════════════
# Step 6: Claude Code and the Claude desktop app
# ═════════════════════════════════════════════════════════════════

header "Claude Code & Claude app"

info "Claude Code is the AI agent that writes code with you."
echo ""

if command -v claude &>/dev/null; then
  ok "Claude Code installed ($(claude --version 2>/dev/null | head -1))"
else
  spin "The script installs Claude Code..." bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
  append_profile 'export PATH="$HOME/.local/bin:$PATH"' "Claude Code"
  export PATH="$HOME/.local/bin:$PATH"
  if command -v claude &>/dev/null; then
    ok "Claude Code installed"
  else
    fail "The Claude Code installation was not successful. See https://claude.com/claude-code"
    exit 1
  fi
fi

divider

if [[ -d "/Applications/Claude.app" ]]; then
  ok "Claude desktop app found"
else
  spin "The script installs the Claude desktop app..." brew install --cask claude || true
  if [[ -d "/Applications/Claude.app" ]]; then
    ok "Claude desktop app installed"
  else
    warn "The installation was not successful. Download the app from"
    warn "https://claude.ai/download. Claude Code in the terminal also works."
  fi
fi

# ═════════════════════════════════════════════════════════════════
# Step 7: Your source folder
# ═════════════════════════════════════════════════════════════════

header "Your source folder"

SRC_DIR="$HOME/Documents/src"

info "Your projects will be in the folder Documents/src."
mkdir -p "$SRC_DIR"
ok "Source folder ready: $SRC_DIR"

# ═════════════════════════════════════════════════════════════════
# Step 8: Summary and Claude handoff
# ═════════════════════════════════════════════════════════════════

header "Setup complete!"

confetti

gum style \
  --border rounded \
  --border-foreground 76 \
  --padding "1 3" \
  --margin "0 2" \
  "$(gum style --foreground 76 --bold "Your Mac is ready.")" \
  "" \
  "$(gum style --foreground 76 "  ✓") Xcode tools, Homebrew, Git, build libraries" \
  "$(gum style --foreground 76 "  ✓") mise with Node.js and Ruby" \
  "$(gum style --foreground 76 "  ✓") Postgres.app database" \
  "$(gum style --foreground 76 "  ✓") GitHub CLI, logged in as $GH_USER" \
  "$(gum style --foreground 76 "  ✓") Git identity configured" \
  "$(gum style --foreground 76 "  ✓") Claude Code & the Claude desktop app" \
  "$(gum style --foreground 76 "  ✓") Source folder: ~/Documents/src"

# ── Generate handoff file ──────────────────────────────────────

HANDOFF_FILE="$SRC_DIR/FIRST_APP_HANDOFF.md"

cat > "$HANDOFF_FILE" << 'HANDOFF_EOF'
# First App Handoff

I completed a setup script on this Mac. I am new to coding. Give simple explanations as you go. Take me the rest of the way to a running first app.

## What is already installed
- Xcode Command Line Tools, Homebrew, and Git
- mise, with Node.js LTS and Ruby active globally (if Ruby is missing, install it with: mise use -g ruby@3)
- Postgres.app (the server should be on, and its CLI tools are on my PATH)
- The GitHub CLI, already logged in, and my git identity is configured
- Claude Code and the Claude desktop app
- My projects folder is ~/Documents/src, and you are running there now

## What I need you to do

1. Verify the environment quietly: node, git, gh auth status, and a Postgres connection (psql -h localhost -d postgres). Repair anything that is broken before you continue. Open and initialize Postgres.app if necessary.
2. Ask me what I want to build. Help me select a short project name.
3. Scaffold the app with create-t3-app (latest version) inside ~/Documents/src. Use TypeScript, Tailwind, tRPC, Prisma, and the App Router. Do not use a third-party auth provider.
4. Create a Postgres database for it (createdb <project-name>). Point DATABASE_URL in .env at it. Use my Mac username with no password on localhost:5432.
5. Push the Prisma schema to the database. Confirm that it worked.
6. Initialize git. Make the first commit. Create a private GitHub repo for it with gh.
7. Start the dev server. Have me open http://localhost:3000 to see it running.
8. Guide me through one small visible change, for example an edit to the home page text. Then commit and push it with me, so I experience the full loop: edit, see it live, commit, push.

Skip deployment for now. Local is enough today. When everything works, give me a short summary: what we built, where it lives, and three ideas for what to try next.
HANDOFF_EOF

# ── Show handoff instructions ──────────────────────────────────

pbcopy < "$HANDOFF_FILE" 2>/dev/null || true

echo ""
gum style \
  --border rounded \
  --border-foreground 214 \
  --padding "1 3" \
  --margin "0 2" \
  --bold \
  "Next: Claude builds your first app with you"

echo ""
info "The instructions for Claude are on your clipboard."
# shellcheck disable=SC2088  # literal tilde is intentional display text
info "They are also in the file: $(gum style --bold "~/Documents/src/FIRST_APP_HANDOFF.md")"
echo ""
info "Open a new terminal window. Run these two commands:"
echo ""
gum style --foreground 255 --background 237 --padding "1 2" --margin "0 4" \
  "cd ~/Documents/src" \
  "claude --dangerously-skip-permissions"
echo ""
info "At the first start, Claude asks you to log in with your Claude account."
info "When Claude is ready, paste the instructions (Cmd+V). Press Enter."
info "Claude then builds your first app with you."
echo ""

gum style \
  --foreground 99 \
  --bold \
  --margin "0 2" \
  "The setup is complete. Build your first app now. 🚀"
echo ""
