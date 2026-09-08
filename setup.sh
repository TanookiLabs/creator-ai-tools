#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════
# Vibe Coding Setup
# One command that takes a fresh Mac from nothing to a fully
# working development machine, then hands off to Claude Code
# to build the user's first app.
#
# The installer is downloaded from main. Resolve main once after Git is
# available so the starter checkout cannot mix revisions during one run.
SOURCE_BRANCH="main"
ACTIVE_PHASE="startup validation"
TEMPLATE_REPOSITORY="https://github.com/TanookiLabs/creator-ai-tools"
CURRENT_TEMPLATE_COMMIT=""
INSTALLED_TEMPLATE_COMMIT=""
CONTRACT_VERSION="1.0"
RUN_STARTED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
SHELL_CONFIGURATION_CHANGED=false

report_context() {
  local status="$1"
  echo ""
  echo "Vibe Coding Setup did not complete."
  echo "Active phase: ${ACTIVE_PHASE}"
  echo "Exit status: ${status}"
  echo "No credentials or environment values are included in this report."
  echo "Correct the message above, then run the same downloaded release again."
}

fail_before_mutation() {
  echo "$1" >&2
  report_context 1 >&2
  exit 1
}
#
# All user-facing text follows ASD-STE100 Simplified Technical
# English: short sentences, active voice, one instruction per
# sentence, no idioms, no contractions.
# ═══════════════════════════════════════════════════════════════

echo "Vibe Coding Setup"
echo "Active phase: ${ACTIVE_PHASE}"

# Validate the execution context before creating files or installing tools.
# A downloaded file leaves stdin connected to the participant's terminal, so
# prompts work without redirecting input from /dev/tty.
if [[ ! -t 0 ]]; then
  fail_before_mutation "This script needs an interactive terminal. Run it directly with: /bin/bash setup.sh"
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  fail_before_mutation "Unsupported platform: this bootstrap supports macOS only."
fi

# Later failures report only stable, nonsecret retry context. Individual tools
# can still print their own actionable error immediately before this summary.
trap 'status=$?; trap - ERR; report_context "$status"' ERR

# ── Pre-TUI helpers (used before gum is available) ────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

pre_ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
pre_warn() { echo -e "  ${YELLOW}!${NC} $1"; }
pre_fail() { echo -e "  ${RED}✗${NC} $1"; }

# ── Preflight and shell profile helpers ───────────────────────

SHELL_PROFILE="${VIBE_SETUP_SHELL_PROFILE:-$HOME/.zshrc}"
PROFILE_MARKER_PREFIX="vibe-coding-setup"
GUI_LOGIN_SHELL_BIN="/bin/zsh"

file_owner_uid() {
  local owner
  owner=$(stat -f '%u' "$1" 2>/dev/null || true)
  if [[ "$owner" =~ ^[0-9]+$ ]]; then
    printf '%s' "$owner"
  else
    stat -c '%u' "$1" 2>/dev/null
  fi
}

validate_shell_profile() {
  local parent owner
  parent=$(dirname "$SHELL_PROFILE")

  if [[ -L "$SHELL_PROFILE" ]]; then
    fail_before_mutation "The shell profile is a symbolic link. The setup will not change it: $SHELL_PROFILE"
  fi
  if [[ -e "$SHELL_PROFILE" ]]; then
    if [[ ! -f "$SHELL_PROFILE" ]]; then
      fail_before_mutation "The shell profile is not a regular file. The setup will not change it: $SHELL_PROFILE"
    fi
    owner=$(file_owner_uid "$SHELL_PROFILE")
    if [[ "$owner" != "$(id -u)" || ! -w "$SHELL_PROFILE" ]]; then
      fail_before_mutation "The shell profile is not owned and writable by the current user. The setup will not change it: $SHELL_PROFILE"
    fi
  else
    owner=$(file_owner_uid "$parent")
    if [[ ! -d "$parent" || "$owner" != "$(id -u)" || ! -w "$parent" ]]; then
      fail_before_mutation "The shell profile directory is not owned and writable by the current user. The setup will not create: $SHELL_PROFILE"
    fi
  fi
}

valid_full_commit() {
  [[ "$1" =~ ^[0-9a-f]{40}$ ]]
}

resolve_main_commit() {
  local main_ref="refs/heads/${SOURCE_BRANCH}" refs commit
  refs=$(git ls-remote "$TEMPLATE_REPOSITORY" "$main_ref") || return 1
  commit=$(printf '%s\n' "$refs" | awk -v ref="$main_ref" '$2 == ref { print $1; exit }')
  valid_full_commit "$commit" || return 1
  CURRENT_TEMPLATE_COMMIT="$commit"
}

append_profile() {
  local line="$1"
  local name="$2"
  local begin="# >>> ${PROFILE_MARKER_PREFIX}:${name} >>>"
  local end="# <<< ${PROFILE_MARKER_PREFIX}:${name} <<<"

  if [[ -f "$SHELL_PROFILE" ]] && grep -qF "$begin" "$SHELL_PROFILE"; then
    return
  fi
  # Preserve an equivalent participant-controlled setting instead of adding a
  # second copy merely to put it inside our markers.
  if [[ -f "$SHELL_PROFILE" ]] && grep -qF "$line" "$SHELL_PROFILE"; then
    return
  fi
  if [[ ! -e "$SHELL_PROFILE" ]]; then
    : > "$SHELL_PROFILE"
  fi
  {
    echo ''
    echo "$begin"
    echo "$line"
    echo "$end"
  } >> "$SHELL_PROFILE"
  SHELL_CONFIGURATION_CHANGED=true
}

managed_shell_profile_is_ready() {
  [[ -f "$SHELL_PROFILE" && ! -L "$SHELL_PROFILE" && -r "$SHELL_PROFILE" ]] || return 1
  grep -qF 'eval "$(mise activate zsh)"' "$SHELL_PROFILE" || return 1
  if [[ -n "${PSQL_BIN:-}" ]]; then
    grep -qF 'export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"' "$SHELL_PROFILE" || return 1
  fi
  # A Claude binary found outside PATH works for this process only after
  # preflight adds its directory. Its managed PATH entry is still required so
  # a fresh GUI login shell can find it. A genuinely healthy Claude setup may
  # be participant-configured and needs no additional managed entry.
  if [[ "${OPTIONAL_CLI_STATE:-}" != "healthy" ]]; then
    grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_PROFILE" || return 1
  fi
  if [[ -n "${BREW_PROFILE_LINE:-}" ]]; then
    grep -qF "$BREW_PROFILE_LINE" "$SHELL_PROFILE" || return 1
  fi
}

tool_state() {
  local command_name="$1"
  shift
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'missing'
  elif "$@" >/dev/null 2>&1; then
    printf 'healthy'
  else
    printf 'unhealthy'
  fi
}

print_preflight() {
  printf '  %-20s %s\n' "$1" "$2"
}

# GitHub CLI credentials can be stored in the macOS login Keychain. A remote
# shell can see gh while being unable to use the participant's GUI Keychain.
github_auth_context_is_authoritative() {
  local console_uid
  [[ -t 0 && -t 1 ]] || return 1
  [[ -z "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ]] || return 1
  console_uid=$(stat -f '%u' /dev/console 2>/dev/null || true)
  [[ "$console_uid" =~ ^[0-9]+$ && "$console_uid" == "$(id -u)" ]]
}

show_github_auth_recovery() {
  info "Open Terminal from your macOS desktop."
  info "The setup can start the browser sign-in only from that Terminal."
  info "Complete the GitHub browser and Keychain prompts yourself."
  info "Then select the retry option if GitHub is still not verified."
}

# Postgres.app owns its client binaries inside the application bundle. Use that
# exact client for both version reporting and readiness checks so another psql
# on PATH cannot produce a false success.
POSTGRES_APP_PATH="${VIBE_SETUP_POSTGRES_APP_PATH:-/Applications/Postgres.app}"
POSTGRES_WAIT_SECONDS="${VIBE_SETUP_POSTGRES_WAIT_SECONDS:-120}"
POSTGRES_WAIT_INTERVAL="${VIBE_SETUP_POSTGRES_WAIT_INTERVAL:-5}"
POSTGRES_REMINDER_SECONDS="${VIBE_SETUP_POSTGRES_REMINDER_SECONDS:-20}"
PSQL_BIN=""
if [[ ! "$POSTGRES_WAIT_SECONDS" =~ ^[1-9][0-9]*$ ]]; then POSTGRES_WAIT_SECONDS=120; fi
if [[ ! "$POSTGRES_WAIT_INTERVAL" =~ ^[1-9][0-9]*$ ]]; then POSTGRES_WAIT_INTERVAL=5; fi
if [[ ! "$POSTGRES_REMINDER_SECONDS" =~ ^[1-9][0-9]*$ ]]; then POSTGRES_REMINDER_SECONDS=20; fi

find_postgres_psql() {
  local candidate version_dir
  candidate="$POSTGRES_APP_PATH/Contents/Versions/latest/bin/psql"
  if [[ -x "$candidate" ]]; then
    printf '%s' "$candidate"
    return 0
  fi
  while IFS= read -r version_dir; do
    candidate="$version_dir/bin/psql"
    if [[ -x "$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done < <(find "$POSTGRES_APP_PATH/Contents/Versions" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | LC_ALL=C sort -r)
  return 1
}

postgres_connection_ready() {
  local result
  [[ -n "$PSQL_BIN" && -x "$PSQL_BIN" ]] || return 1
  # -w forbids a hidden password prompt. -X ignores participant psql startup
  # files. Output is captured and reduced to the expected nonsecret value.
  result=$("$PSQL_BIN" -X -w -d postgres -Atqc 'select 1' 2>/dev/null) || return 1
  [[ "$result" == "1" ]]
}

show_postgres_initialize_guidance() {
  info "Postgres.app is opening."
  echo ""
  info "If you see an Initialize button:"
  info "1. Click Initialize."
  info "2. Approve any macOS permission prompt."
  info "3. Leave Postgres.app running."
  echo ""
  info "Setup will continue automatically when the database is ready."
}

activate_postgres_app() {
  local app_name
  app_name=$(basename "$POSTGRES_APP_PATH" .app)
  if open -a "$app_name" >/dev/null 2>&1; then
    ok "Postgres.app opened in the foreground"
    return 0
  fi
  warn "Postgres.app could not be brought to the foreground."
  if open "$POSTGRES_APP_PATH" >/dev/null 2>&1; then
    info "Open Postgres.app from Applications if its window is not visible."
    return 0
  fi
  warn "Open Postgres.app from Applications or Spotlight, then return to this setup."
  return 1
}

show_postgres_recovery() {
  warn "Postgres.app is not ready yet. Setup is still waiting."
  info "If macOS shows a security message, select Open."
  info "In Postgres.app, select Initialize if that button appears."
  info "Review and approve any macOS permission dialog yourself."
  info "Spotlight recovery: Press Command-Space. Type Postgres. Open Postgres.app."
  info "Finder recovery: Open Finder. Select Applications. Double-click Postgres.app."
  info "If Gatekeeper blocks it, Control-click Postgres.app in Finder. Select Open."
}

wait_for_postgres_connection() {
  local elapsed=0 next_reminder=0
  while (( elapsed < POSTGRES_WAIT_SECONDS )); do
    if postgres_connection_ready; then
      return 0
    fi
    printf '  Waiting for a database connection: %s/%s seconds\n' "$elapsed" "$POSTGRES_WAIT_SECONDS"
    if (( elapsed >= next_reminder )); then
      info "If Postgres.app shows Initialize, click it and approve any macOS permission prompt. Setup is still waiting."
      next_reminder=$((elapsed + POSTGRES_REMINDER_SECONDS))
    fi
    sleep "$POSTGRES_WAIT_INTERVAL"
    elapsed=$((elapsed + POSTGRES_WAIT_INTERVAL))
  done
  postgres_connection_ready
}

# Keep the receipt implementation in this downloaded entrypoint. The supported
# bootstrap invocation downloads one file, so contract production must not
# depend on an unverified helper from the participant's machine or checkout.
produce_first_app_contract() {
  local application_repository="local-only" marker_repository origin_repository local_commit remote_commit
  if [[ -f "$PROJECT_ROOT/.git/vibe-participant-repository" ]]; then
    marker_repository=$(canonical_https_repository_url "$(sed -n '2p' "$PROJECT_ROOT/.git/vibe-participant-repository")" 2>/dev/null || true)
    origin_repository=$(canonical_https_repository_url "$(git -C "$PROJECT_ROOT" config --get remote.origin.url 2>/dev/null || true)" 2>/dev/null || true)
    local_commit=$(git -C "$PROJECT_ROOT" rev-parse main 2>/dev/null || true)
    remote_commit=$(git -C "$PROJECT_ROOT" ls-remote --heads origin refs/heads/main 2>/dev/null | awk 'NR == 1 { print $1 }')
    if [[ -n "$marker_repository" && "$marker_repository" == "$origin_repository" && "$remote_commit" == "$local_commit" ]]; then
      application_repository="$marker_repository"
    fi
  fi
  RECEIPT_ROOT="$PROJECT_ROOT" \
  RECEIPT_CONTRACT_VERSION="$CONTRACT_VERSION" \
  RECEIPT_RUN_STARTED_AT="$RUN_STARTED_AT" \
  RECEIPT_REPOSITORY="$TEMPLATE_REPOSITORY" \
  RECEIPT_APPLICATION_REPOSITORY="$application_repository" \
  RECEIPT_APPLICATION_COMMIT="$(git -C "$PROJECT_ROOT" rev-parse HEAD)" \
  RECEIPT_SOURCE_BRANCH="$SOURCE_BRANCH" \
  RECEIPT_INSTALLER_SHA256="$(shasum -a 256 "$0" | awk '{print $1}')" \
  RECEIPT_TEMPLATE_REPOSITORY="$TEMPLATE_REPOSITORY" \
  RECEIPT_TEMPLATE_COMMIT="$INSTALLED_TEMPLATE_COMMIT" \
  RECEIPT_GIT_VERSION="$(git --version 2>/dev/null | sed 's/^git version //' || true)" \
  RECEIPT_NODE_VERSION="$(node --version 2>/dev/null | sed 's/^v//' || true)" \
  RECEIPT_NPM_VERSION="$(npm --version 2>/dev/null || true)" \
  RECEIPT_GH_VERSION="$(gh --version 2>/dev/null | sed -n '1s/.*version \([^ ]*\).*/\1/p' || true)" \
  RECEIPT_PSQL_VERSION="$(if [[ -n "${PSQL_BIN:-}" && -x "$PSQL_BIN" ]]; then "$PSQL_BIN" --version 2>/dev/null | sed -n 's/.* \([0-9][0-9.]*\).*$/\1/p'; fi || true)" \
  RECEIPT_GITHUB_STATUS="${GITHUB_VERIFIED:-false}" \
  RECEIPT_GITHUB_EVIDENCE="${GITHUB_AUTH_EVIDENCE:-interactive_check_required}" \
  RECEIPT_POSTGRES_STATUS="${POSTGRES_VERIFIED:-false}" \
  RECEIPT_DESKTOP_STATUS="${DESKTOP_VERIFIED:-false}" \
  RECEIPT_GUI_LOGIN_SHELL_STATUS="${GUI_LOGIN_SHELL_VERIFIED:-false}" \
  RECEIPT_GUI_LOGIN_SHELL_MISSING="${GUI_LOGIN_SHELL_MISSING:-}" \
  node <<'FIRST_APP_CONTRACT_JS'
const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");

const env = process.env;
const root = path.resolve(env.RECEIPT_ROOT || "");
const now = () => new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
const secret = /-----BEGIN .*PRIVATE KEY-----|github_pat_|gh[pousr]_|sk_(?:live|test)_|whsec_|(?:postgres(?:ql)?|mysql):\/\/[^\s@]+:[^\s@]+@|authorization\s*:|(?:token|password|secret|cookie)\s*[=:]\s*\S+/i;
const redactedFields = [];
function safe(value, field) {
  const text = String(value || "").trim().slice(0, 240);
  if (!text) return undefined;
  if (secret.test(text)) {
    redactedFields.push(field);
    return "[REDACTED]";
  }
  return text;
}
function capability(id, verified, summary, version, recovery) {
  const item = { id, status: verified ? "verified" : "unverified", checked_at: now(), summary };
  const cleanVersion = safe(version, `capabilities.${id}.version`);
  if (cleanVersion) item.version = cleanVersion;
  if (!verified && recovery) {
    item.evidence_code = recovery.evidence;
    item.recovery_action_id = recovery.id;
  }
  return item;
}
function requireMatch(value, expression, name) {
  if (!expression.test(value)) throw new Error(`Receipt ${name} is invalid.`);
}
function canonicalHttpsRepository(value, name) {
  const normalized = String(value || "").trim().replace(/\/+$/, "").replace(/\.git$/, "").replace(/\/+$/, "");
  requireMatch(normalized, /^https:\/\/[^/?#@]+\/[^/?#]+\/[^/?#]+$/, name);
  return normalized;
}
if (!path.isAbsolute(root) || root === path.parse(root).root) throw new Error("Receipt application root is unsafe.");
const repository = env.RECEIPT_APPLICATION_REPOSITORY === "local-only" ? "local-only" : canonicalHttpsRepository(env.RECEIPT_APPLICATION_REPOSITORY, "application repository");
const commit = env.RECEIPT_APPLICATION_COMMIT;
const templateRepository = env.RECEIPT_TEMPLATE_REPOSITORY;
const templateCommit = env.RECEIPT_TEMPLATE_COMMIT;
requireMatch(commit, /^[0-9a-f]{40}$/, "application commit");
canonicalHttpsRepository(templateRepository, "template repository");
requireMatch(templateCommit, /^[0-9a-f]{40}$/, "template commit");
requireMatch(env.RECEIPT_SOURCE_BRANCH, /^main$/, "source branch");
requireMatch(env.RECEIPT_INSTALLER_SHA256, /^[0-9a-f]{64}$/, "installer digest");
if (fs.realpathSync(root) !== root) throw new Error("Receipt root does not match the physical checkout root.");
if (require("node:child_process").execFileSync("git", ["-C", root, "rev-parse", "HEAD"], { encoding: "utf8" }).trim() !== commit) throw new Error("Receipt commit does not match the checkout.");
if (repository !== "local-only") {
  const origin = canonicalHttpsRepository(require("node:child_process").execFileSync("git", ["-C", root, "config", "--get", "remote.origin.url"], { encoding: "utf8" }), "origin repository");
  if (origin !== repository) throw new Error("Receipt repository does not match the checkout.");
}
const templateMarker = fs.readFileSync(path.join(root, ".git", "vibe-template-provenance"), "utf8").trim().split(/\r?\n/);
if (templateMarker.length !== 2 || templateMarker[0] !== templateRepository || templateMarker[1] !== templateCommit) throw new Error("Receipt template provenance does not match the local marker.");

const stateDir = path.join(root, ".first-app");
const diagnosticsDir = path.join(stateDir, "diagnostics");
const receiptPath = path.join(stateDir, "receipt.json");
const handoffPath = path.join(root, "FIRST_APP_HANDOFF.md");
for (const directory of [stateDir, diagnosticsDir]) {
  if (fs.existsSync(directory)) {
    const stat = fs.lstatSync(directory);
    if (!stat.isDirectory() || stat.isSymbolicLink() || stat.uid !== process.getuid()) throw new Error(`Generated-state directory is unsafe: ${directory}`);
  }
}
fs.mkdirSync(diagnosticsDir, { recursive: true, mode: 0o700 });
let previous = null;
if (fs.existsSync(receiptPath)) {
  const stat = fs.lstatSync(receiptPath);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.uid !== process.getuid()) throw new Error("Existing receipt is unsafe to replace.");
  try { previous = JSON.parse(fs.readFileSync(receiptPath, "utf8")); } catch { previous = null; }
}
const runId = crypto.randomUUID();
const sequence = Number.isInteger(previous?.run?.sequence) ? previous.run.sequence + 1 : 1;
const run = { id: runId, sequence };
if (previous?.run?.id) run.rerun_of = previous.run.id;
const actions = [];
const githubEvidence = ["interactive_status_verified", "interactive_status_failed", "gui_context_required"].includes(env.RECEIPT_GITHUB_EVIDENCE) ? env.RECEIPT_GITHUB_EVIDENCE : "interactive_check_required";
const guiMissingCommands = [...new Set(String(env.RECEIPT_GUI_LOGIN_SHELL_MISSING || "").split(",").filter(command => ["mise", "node", "npm", "ruby", "claude"].includes(command)))];
if (env.RECEIPT_GITHUB_STATUS !== "true") actions.push({ id: "authenticate.github", kind: "authenticate", blocking: true, instruction: githubEvidence === "gui_context_required" ? "Open Terminal from your macOS desktop and rerun setup so GitHub CLI can use your GUI login Keychain. Do not reauthenticate because of an SSH or background check alone." : "In your interactive Mac terminal, run gh auth login --web --git-protocol https yourself, complete the browser and Keychain prompts, then rerun setup." });
if (env.RECEIPT_POSTGRES_STATUS !== "true") actions.push({ id: "repair.postgres", kind: "repair", blocking: true, instruction: "Open and initialize Postgres.app, confirm its server is running, then rerun the setup." });
if (env.RECEIPT_GUI_LOGIN_SHELL_STATUS !== "true") actions.push({ id: "verify.gui_login_shell", kind: "retry", blocking: true, instruction: `Open a new Terminal window from the macOS desktop, confirm these commands are available: ${guiMissingCommands.join(", ") || "mise, node, npm, ruby, and claude"}, then rerun setup.` });
if (env.RECEIPT_DESKTOP_STATUS !== "true") actions.push({ id: "confirm.desktop_folder", kind: "confirm", blocking: false, instruction: "In Claude Desktop Code, open the exact application root manually. Folder selection is not verified by this installer." });
const guiLoginShellCapability = capability("tool.gui_login_shell", env.RECEIPT_GUI_LOGIN_SHELL_STATUS === "true", env.RECEIPT_GUI_LOGIN_SHELL_STATUS === "true" ? "A fresh macOS GUI login shell resolved mise, node, npm, ruby, and claude." : guiMissingCommands.length ? `A fresh macOS GUI login shell could not find: ${guiMissingCommands.join(", ")}.` : "A fresh macOS GUI login shell did not verify all required development tools.", undefined, { id: "verify.gui_login_shell", evidence: "gui_login_shell_unverified" });
if (guiMissingCommands.length) guiLoginShellCapability.missing_commands = guiMissingCommands;
const capabilities = [
  capability("auth.github", env.RECEIPT_GITHUB_STATUS === "true", env.RECEIPT_GITHUB_STATUS === "true" ? "GitHub CLI authentication was verified in the participant's interactive GUI login context." : githubEvidence === "gui_context_required" ? "This SSH or background result is not authoritative for the participant's GUI Keychain." : "GitHub CLI authentication was not verified in the participant's interactive GUI login context.", env.RECEIPT_GH_VERSION, { id: "authenticate.github", evidence: githubEvidence }),
  capability("handoff.claude_desktop", env.RECEIPT_DESKTOP_STATUS === "true", env.RECEIPT_DESKTOP_STATUS === "true" ? "The exact application root was verified by a reliable Desktop mechanism." : "Claude Desktop folder selection is not observable by this installer and remains unverified.", undefined, { id: "confirm.desktop_folder", evidence: "folder_selection_unverified" }),
  capability("service.postgres", env.RECEIPT_POSTGRES_STATUS === "true", env.RECEIPT_POSTGRES_STATUS === "true" ? "The Postgres client completed a local connection check." : "A local PostgreSQL connection was not verified.", env.RECEIPT_PSQL_VERSION, { id: "repair.postgres", evidence: "connection_check_failed" }),
  capability("tool.git", true, "Git is available.", env.RECEIPT_GIT_VERSION),
  capability("tool.node", true, "Node.js is available.", env.RECEIPT_NODE_VERSION),
  capability("tool.npm", true, "npm is available.", env.RECEIPT_NPM_VERSION),
  guiLoginShellCapability,
].sort((a, b) => a.id.localeCompare(b.id));
actions.sort((a, b) => a.id.localeCompare(b.id));
const requiredCapabilityIds = new Set(["auth.github", "service.postgres", "tool.git", "tool.gui_login_shell", "tool.node", "tool.npm"]);
const failed = capabilities.filter(item => requiredCapabilityIds.has(item.id) && item.status !== "verified").map(item => item.id).sort();
const finished = now();
const receipt = {
  contract_version: env.RECEIPT_CONTRACT_VERSION,
  kind: "first_app_bootstrap_receipt",
  run,
  application: { root, repository, commit, instructions: ["CLAUDE.md", "README.md", "docs/quality-verification.md"] },
  provenance: {
    bootstrap: { repository: env.RECEIPT_REPOSITORY, source_branch: env.RECEIPT_SOURCE_BRANCH, sha256: env.RECEIPT_INSTALLER_SHA256 },
    template: { repository: templateRepository, source_branch: env.RECEIPT_SOURCE_BRANCH, commit: templateCommit },
  },
  capabilities,
  participant_actions: actions,
  result: { status: failed.length || actions.some(action => action.blocking) ? "partial_failure" : "success", failed_capability_ids: failed },
  redaction: { applied: redactedFields.length > 0, fields: [...new Set(redactedFields)].sort() },
  timestamps: { started_at: env.RECEIPT_RUN_STARTED_AT, finished_at: finished },
};
requireMatch(receipt.contract_version, /^1\.[0-9]+$/, "contract version");
requireMatch(receipt.run.id, /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/, "run ID");
requireMatch(receipt.timestamps.started_at, /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/, "start timestamp");
const serialized = JSON.stringify(receipt, null, 2) + "\n";
if (secret.test(serialized)) throw new Error("Receipt redaction failed closed.");

// Retain only distinct semantic partial failures. Volatile run metadata is
// removed for duplicate comparison so identical reruns do not grow history.
const semantic = value => JSON.stringify({ application: value.application, provenance: value.provenance, capabilities: value.capabilities.map(({ checked_at, ...item }) => item), participant_actions: value.participant_actions, result: value.result, redaction: value.redaction });
if (previous?.result?.status && previous.result.status !== "success") {
  const duplicate = fs.readdirSync(diagnosticsDir).filter(name => name.endsWith(".json")).some(name => {
    try { return semantic(JSON.parse(fs.readFileSync(path.join(diagnosticsDir, name), "utf8"))) === semantic(previous); } catch { return false; }
  });
  if (!duplicate) {
    const diagnosticName = `${previous.timestamps.started_at.replace(/:/g, "-")}-${previous.run.id}.json`;
    fs.writeFileSync(path.join(diagnosticsDir, diagnosticName), JSON.stringify(previous, null, 2) + "\n", { mode: 0o600, flag: "wx" });
  }
}
const diagnostics = fs.readdirSync(diagnosticsDir).filter(name => name.endsWith(".json")).sort();
for (const name of diagnostics.slice(0, Math.max(0, diagnostics.length - 5))) fs.unlinkSync(path.join(diagnosticsDir, name));

const lines = ["# First App Handoff", `<!-- generated; local-only; contract ${receipt.contract_version} -->`, "", "## Next action", ""];
for (const action of actions) lines.push(`- ${action.instruction}`);
lines.push("", "## Application", "", `- Root: \`${root}\``, `- Repository: \`${repository}\``, `- Commit: \`${commit}\``, "", "## Provenance", "", `- Source branch: \`${receipt.provenance.template.source_branch}\``, `- Template repository: \`${templateRepository}\``, `- Template commit: \`${templateCommit}\``, `- Downloaded installer SHA-256: \`${receipt.provenance.bootstrap.sha256}\``, "", "## Capability results", "", "| ID | Status | Version | Checked at | Summary |", "| --- | --- | --- | --- | --- |");
for (const item of capabilities) lines.push(`| ${item.id} | ${item.status} | ${item.version || "—"} | ${item.checked_at} | ${item.summary} |`);
lines.push("", "## Durable instructions", "");
for (const instruction of receipt.application.instructions) lines.push(`- [${instruction}](${instruction})`);
lines.push("", "## Run result", "", `- Status: \`${receipt.result.status}\``, `- Run ID: \`${runId}\``, `- Started: \`${receipt.timestamps.started_at}\``, `- Finished: \`${finished}\``, "- Receipt: `.first-app/receipt.json`", "");
const markdown = lines.join("\n");
if (secret.test(markdown)) throw new Error("Handoff redaction failed closed.");
function atomicWrite(target, content) {
  const temporary = `${target}.tmp-${runId}`;
  fs.writeFileSync(temporary, content, { mode: 0o600, flag: "wx" });
  fs.renameSync(temporary, target);
}
atomicWrite(receiptPath, serialized);
atomicWrite(handoffPath, markdown);
FIRST_APP_CONTRACT_JS
}

ACTIVE_PHASE="preflight"
echo "Active phase: ${ACTIVE_PHASE}"
validate_shell_profile

BREW_STATE=$(tool_state brew brew --version)
BREW_BIN=""
if [[ "$BREW_STATE" != "healthy" ]]; then
  for candidate in ${VIBE_SETUP_BREW_CANDIDATES:-/opt/homebrew/bin/brew /usr/local/bin/brew}; do
    if [[ -x "$candidate" ]] && "$candidate" --version >/dev/null 2>&1; then
      BREW_BIN="$candidate"
      BREW_STATE="off-PATH"
      eval "$("$candidate" shellenv)"
      break
    fi
  done
fi
GIT_STATE=$(tool_state git git --version)
GH_STATE=$(tool_state gh gh --version)
NODE_STATE=$(tool_state node node --version)
NPM_STATE=$(tool_state npm npm --version)
MISE_SHIMS_DIR="$HOME/.local/share/mise/shims"
if [[ "$NODE_STATE" != "healthy" && -x "$MISE_SHIMS_DIR/node" ]] && "$MISE_SHIMS_DIR/node" --version >/dev/null 2>&1; then
  NODE_STATE="off-PATH"
  export PATH="$MISE_SHIMS_DIR:$PATH"
fi
if [[ "$NPM_STATE" != "healthy" && -x "$MISE_SHIMS_DIR/npm" ]] && "$MISE_SHIMS_DIR/npm" --version >/dev/null 2>&1; then
  NPM_STATE="off-PATH"
  export PATH="$MISE_SHIMS_DIR:$PATH"
fi
PSQL_STATE=$(tool_state psql psql --version)
POSTGRES_APP_STATE="missing"
if [[ -d /Applications/Postgres.app ]]; then
  if [[ -x /Applications/Postgres.app/Contents/MacOS/Postgres ]]; then
    POSTGRES_APP_STATE="healthy"
  else
    POSTGRES_APP_STATE="unhealthy"
  fi
fi
DESKTOP_STATE="missing"
DESKTOP_WAS_RUNNING=false
if pgrep -x Claude >/dev/null 2>&1; then
  DESKTOP_WAS_RUNNING=true
fi
if [[ -d /Applications/Claude.app ]]; then
  if [[ -x /Applications/Claude.app/Contents/MacOS/Claude ]]; then
    DESKTOP_STATE="healthy"
  else
    DESKTOP_STATE="unhealthy"
  fi
fi
OPTIONAL_CLI_STATE=$(tool_state claude claude --version)

POSTGRES_BIN_DIR="/Applications/Postgres.app/Contents/Versions/latest/bin"
if [[ "$PSQL_STATE" != "healthy" && -x "$POSTGRES_BIN_DIR/psql" ]] && "$POSTGRES_BIN_DIR/psql" --version >/dev/null 2>&1; then
  PSQL_STATE="off-PATH"
  export PATH="$POSTGRES_BIN_DIR:$PATH"
fi
if [[ "$OPTIONAL_CLI_STATE" != "healthy" && -x "$HOME/.local/bin/claude" ]] && "$HOME/.local/bin/claude" --version >/dev/null 2>&1; then
  OPTIONAL_CLI_STATE="off-PATH"
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "  Component preflight:"
print_preflight "Homebrew" "$BREW_STATE"
print_preflight "Git" "$GIT_STATE"
print_preflight "GitHub CLI" "$GH_STATE"
print_preflight "Node.js" "$NODE_STATE"
print_preflight "npm" "$NPM_STATE"
print_preflight "Postgres.app" "$POSTGRES_APP_STATE"
print_preflight "psql" "$PSQL_STATE"
print_preflight "Claude Desktop" "$DESKTOP_STATE"
print_preflight "Claude CLI (optional)" "$OPTIONAL_CLI_STATE"

if [[ "$BREW_STATE" == "off-PATH" ]]; then
  printf -v BREW_PROFILE_LINE 'eval "$(%q shellenv)"' "$BREW_BIN"
  append_profile "$BREW_PROFILE_LINE" "homebrew"
fi

if [[ "${VIBE_SETUP_PREFLIGHT_ONLY:-0}" == "1" ]]; then
  echo "Preflight complete. No installation phases were run."
  exit 0
fi

# ── TUI helpers (used after gum is installed) ─────────────────

TOTAL_STEPS=8
CURRENT_STEP=0

header() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  ACTIVE_PHASE="$1"
  echo ""
  echo "Active phase: ${ACTIVE_PHASE}"
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

prompt_value() {
  local prompt="$1"
  local value="$2"
  gum input --prompt "$prompt" --value "$value"
}

spin() {
  local title="$1"
  shift
  gum spin --spinner dot --spinner.foreground 99 --title "  $title" -- "$@"
}

# Homebrew can ask the participant to confirm an installation. Do not conceal
# that prompt behind a spinner or discard the tool's own error output.
brew_install_visible() {
  local description="$1" status
  shift
  info "Homebrew installs ${description}. Review and answer any Homebrew prompt in this terminal."
  if brew install "$@"; then
    return 0
  fi
  status=$?
  fail "Homebrew could not install ${description}."
  info "Retry this phase from a macOS Terminal with:"
  printf '  brew install'
  printf ' %q' "$@"
  printf '\n'
  report_context "$status"
  exit "$status"
}

collect_gui_login_shell_missing() {
  local raw status=0 command missing=""
  raw=$("$GUI_LOGIN_SHELL_BIN" -lic 'for tool in mise node npm ruby claude; do command -v "$tool" >/dev/null 2>&1 || print -r -- "$tool"; done' 2>/dev/null) || status=$?
  if (( status != 0 )); then
    printf '%s' 'mise,node,npm,ruby,claude'
    return
  fi
  while IFS= read -r command; do
    case "$command" in
      mise|node|npm|ruby|claude)
        [[ ",$missing," == *",$command,"* ]] || missing="${missing:+$missing,}$command"
        ;;
    esac
  done <<< "$raw"
  printf '%s' "$missing"
}

verify_gui_login_shell() {
  local first_missing second_missing
  GUI_LOGIN_SHELL_VERIFIED=false
  GUI_LOGIN_SHELL_MISSING=""
  if ! github_auth_context_is_authoritative; then
    warn "A fresh GUI login-shell check requires Terminal from the macOS desktop."
    return
  fi
  first_missing=$(collect_gui_login_shell_missing)
  if [[ -z "$first_missing" ]]; then
    GUI_LOGIN_SHELL_VERIFIED=true
    ok "A fresh GUI login shell resolves mise, Node.js, npm, Ruby, and Claude"
    return
  fi

  warn "A fresh macOS GUI login shell could not find: $first_missing"
  info "Setup will recheck its managed shell configuration and check once more."
  if managed_shell_profile_is_ready; then
    info "Managed shell configuration is present and readable."
  else
    warn "Managed shell configuration could not be fully confirmed before the retry."
  fi
  second_missing=$(collect_gui_login_shell_missing)
  if [[ -z "$second_missing" ]]; then
    GUI_LOGIN_SHELL_VERIFIED=true
    ok "A fresh GUI login shell resolves all required tools after one internal retry"
  else
    GUI_LOGIN_SHELL_MISSING="$second_missing"
    warn "A fresh macOS GUI login shell could not find: $second_missing"
    info "Open a new Terminal window from the macOS desktop, then rerun setup."
  fi
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
echo "  Active phase: ${ACTIVE_PHASE}"
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
  if ! brew install gum; then
    pre_fail "Homebrew could not install the interface toolkit."
    echo "  Retry this phase from a macOS Terminal with: brew install gum"
    report_context 1
    exit 1
  fi
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

if [[ "$GIT_STATE" == "healthy" ]]; then
  ok "Git installed ($(git --version | sed 's/git version //'))"
else
  brew_install_visible "Git" git
  if git --version &>/dev/null; then
    ok "Git installed"
  else
    fail "The Git installation was not successful."
    exit 1
  fi
fi

ACTIVE_PHASE="main source resolution"
if ! resolve_main_commit; then
  fail "Could not resolve ${TEMPLATE_REPOSITORY} ${SOURCE_BRANCH}. Check your network connection and run setup again."
  exit 1
fi
ok "Current template commit available: ${CURRENT_TEMPLATE_COMMIT} from ${SOURCE_BRANCH}"

info "The script installs the libraries that Ruby and other tools need."
brew_install_visible "the build libraries" libyaml gmp openssl@3 readline
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
  brew_install_visible "mise" mise
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

if [[ ( "$NODE_STATE" == "healthy" || "$NODE_STATE" == "off-PATH" ) && ( "$NPM_STATE" == "healthy" || "$NPM_STATE" == "off-PATH" ) ]]; then
  ok "Node.js $(node --version) and npm $(npm --version) found"
elif mise which node &>/dev/null && mise exec -- node --version &>/dev/null && mise exec -- npm --version &>/dev/null; then
  ok "Node.js $(mise exec -- node --version) and npm $(mise exec -- npm --version) (via mise)"
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

if [[ "$POSTGRES_APP_STATE" == "healthy" ]]; then
  ok "Postgres.app found"
else
  if confirm "Install Postgres.app?"; then
    brew_install_visible "Postgres.app" --cask postgres-app
  else
    warn "Postgres.app installation was skipped."
  fi
  if [[ -d "$POSTGRES_APP_PATH" ]]; then
    ok "Postgres.app installed"
  else
    warn "Postgres.app is not installed. Download it from https://postgresapp.com"
  fi
fi

if PSQL_BIN=$(find_postgres_psql); then
  POSTGRES_BIN_DIR=$(dirname "$PSQL_BIN")
  append_profile 'export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"' "postgres-app"
  export PATH="$POSTGRES_BIN_DIR:$PATH"
  ok "Postgres.app client found: $PSQL_BIN"
else
  PSQL_BIN=""
  warn "The Postgres.app psql client is not available yet."
fi

divider

POSTGRES_VERIFIED=false
if postgres_connection_ready; then
  POSTGRES_VERIFIED=true
  ok "Postgres.app accepted a real database connection"
elif [[ -d "$POSTGRES_APP_PATH" ]]; then
  show_postgres_initialize_guidance
  activate_postgres_app || true

  while [[ "$POSTGRES_VERIFIED" != true ]]; do
    if [[ -z "$PSQL_BIN" ]]; then
      PSQL_BIN=$(find_postgres_psql || true)
    fi
    info "The connection check will stop after ${POSTGRES_WAIT_SECONDS} seconds."
    if wait_for_postgres_connection; then
      POSTGRES_VERIFIED=true
      ok "Postgres.app accepted a real database connection"
      break
    fi

    show_postgres_recovery
    POSTGRES_ACTION=$(gum choose "Open Postgres.app again and retry" "Retry the database connection check" "Stop setup")
    case "$POSTGRES_ACTION" in
      "Open Postgres.app again and retry") show_postgres_initialize_guidance; activate_postgres_app || true ;;
      "Retry the database connection check") info "Retrying the database connection check without reopening Postgres.app." ;;
      *) fail "Postgres.app is not ready. Run this setup again after you initialize it."; exit 1 ;;
    esac
  done
else
  show_postgres_recovery
  warn "Continue after you install Postgres.app, or rerun this setup later."
fi

# ═════════════════════════════════════════════════════════════════
# Step 4: GitHub CLI and authentication
# ═════════════════════════════════════════════════════════════════

header "GitHub CLI & login"

info "GitHub keeps your code online. The GitHub CLI lets Claude use GitHub."
echo ""

if [[ "$GH_STATE" == "healthy" ]]; then
  ok "GitHub CLI installed"
else
  brew_install_visible "the GitHub CLI" gh
  if gh --version &>/dev/null; then
    ok "GitHub CLI installed"
  else
    fail "The GitHub CLI installation was not successful."
    exit 1
  fi
fi

divider

GITHUB_VERIFIED=false
GITHUB_AUTH_EVIDENCE="gui_context_required"
if ! github_auth_context_is_authoritative; then
  warn "This shell is SSH, background, or outside the active macOS GUI login."
  warn "Its GitHub Keychain result is not authoritative."
  info "Open Terminal from the macOS desktop and rerun setup to verify GitHub."
else
  if gh auth status &>/dev/null 2>&1; then
    GITHUB_VERIFIED=true
    GITHUB_AUTH_EVIDENCE="interactive_status_verified"
    ok "You are logged in to GitHub"
  else
    GITHUB_AUTH_EVIDENCE="interactive_status_failed"
    warn "GitHub CLI authentication is not available in this GUI login session."
    info "The setup opens the standard GitHub browser sign-in now."
    if gh auth login --web --git-protocol https; then
      if gh auth status &>/dev/null 2>&1; then
        GITHUB_VERIFIED=true
        GITHUB_AUTH_EVIDENCE="interactive_status_verified"
        ok "You are logged in to GitHub"
      else
        warn "GitHub sign-in finished, but GitHub CLI authentication is still not verified."
      fi
    else
      warn "GitHub browser sign-in was canceled or did not complete."
    fi
    if [[ "$GITHUB_VERIFIED" != "true" ]]; then
      show_github_auth_recovery
    fi
    while true; do
      [[ "$GITHUB_VERIFIED" == "true" ]] && break
      GITHUB_AUTH_ACTION=$(gum choose "Retry GitHub browser sign-in" "Continue with GitHub unverified" "Stop setup")
      case "$GITHUB_AUTH_ACTION" in
        "Retry GitHub browser sign-in")
          if ! github_auth_context_is_authoritative; then
            warn "GitHub browser sign-in can only start from Terminal on the macOS desktop."
            break
          fi
          if ! gh auth login --web --git-protocol https; then
            warn "GitHub browser sign-in was canceled or did not complete."
          fi
          if gh auth status &>/dev/null 2>&1; then
            GITHUB_VERIFIED=true
            GITHUB_AUTH_EVIDENCE="interactive_status_verified"
            ok "You are logged in to GitHub"
            break
          fi
          warn "GitHub authentication is still not verified."
          show_github_auth_recovery
          ;;
        "Continue with GitHub unverified") break ;;
        *) fail "GitHub authentication remains participant-controlled. Rerun setup when you are ready."; exit 1 ;;
      esac
    done
  fi
fi

GH_USER=""
GH_NAME=""
GH_PRIMARY_EMAIL=""
GH_ALL_EMAILS=""
GH_USER_ID=""
if [[ "$GITHUB_VERIFIED" == "true" ]]; then
  GH_IDENTITY=$(gh api user --jq '[.id, .login] | @tsv' 2>/dev/null || true)
  IFS=$'\t' read -r GH_USER_ID GH_USER <<< "$GH_IDENTITY"
  GH_NAME=$(gh api user --jq '.name // empty' 2>/dev/null || echo "")
  GH_PRIMARY_EMAIL=$(gh api user/emails --jq '.[] | select(.primary==true) | .email' 2>/dev/null || echo "")
  GH_ALL_EMAILS=$(gh api user/emails --jq '.[].email' 2>/dev/null || echo "")
fi

echo ""
[[ -n "$GH_USER" ]] && ok "GitHub user: $GH_USER"
[[ -n "$GH_NAME" ]] && ok "Display name: $GH_NAME"

# ═════════════════════════════════════════════════════════════════
# Step 5: Git identity
# ═════════════════════════════════════════════════════════════════

header "Git identity"

valid_git_email() {
  [[ "$1" =~ ^[A-Za-z0-9.!#$%\&\'*+/=?^_\`{|}~-]+@[A-Za-z0-9.-]+\.[A-Za-z0-9-]+$ ]] &&
    [[ "$1" != *$'\n'* && "$1" != *$'\r'* ]]
}

configure_github_git_identity() {
  local existing managed candidate identity
  existing=$(git config --global --get user.email 2>/dev/null || true)
  managed=$(git config --global --get vibe-coding-setup.managed-email 2>/dev/null || true)
  if [[ -n "$existing" ]] && valid_git_email "$existing" && [[ "$managed" != "true" ]]; then
    GIT_EMAIL="$existing"
    return 0
  fi
  if [[ "$GITHUB_VERIFIED" != "true" || ! "$GH_USER_ID" =~ ^[0-9]+$ || ! "$GH_USER" =~ ^[A-Za-z0-9-]+$ ]]; then
    fail "GitHub identity is unavailable. Sign in with gh auth login, then rerun setup before creating commits."
    return 1
  fi
  candidate=$(gh api user/emails --jq '.[] | select(.primary == true) | .email' 2>/dev/null | head -n 1 || true)
  if ! valid_git_email "$candidate"; then candidate="${GH_USER_ID}+${GH_USER}@users.noreply.github.com"; fi
  valid_git_email "$candidate" || { fail "Git identity email is invalid. Sign in to GitHub and rerun setup."; return 1; }
  git config --global user.email "$candidate"
  git config --global vibe-coding-setup.managed-email true
  GIT_EMAIL="$candidate"
}

GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")

if [[ -n "$GIT_NAME" ]]; then
  ok "Git name: $GIT_NAME"
else
  if [[ "$GITHUB_VERIFIED" == "true" && -n "${GH_NAME:-$GH_USER}" ]]; then
    GIT_NAME="${GH_NAME:-$GH_USER}"
    git config --global user.name "$GIT_NAME"
    ok "Git name set from GitHub: $GIT_NAME"
  else
    warn "Git name is not configured. Configure it after GitHub is verified."
  fi
fi

if ! configure_github_git_identity; then exit 1; fi
if ! git var GIT_AUTHOR_IDENT >/dev/null 2>&1; then
  fail "Git cannot form a valid author identity. Configure Git identity and rerun setup."
  exit 1
fi
ok "Git email configured"

git config --global init.defaultBranch main 2>/dev/null || true

# ═════════════════════════════════════════════════════════════════
# Step 6: Claude Code and the Claude desktop app
# ═════════════════════════════════════════════════════════════════

header "Claude Code & Claude app"

info "Claude Code is the AI agent that writes code with you."
echo ""

if [[ "$OPTIONAL_CLI_STATE" == "healthy" || "$OPTIONAL_CLI_STATE" == "off-PATH" ]]; then
  if [[ "$OPTIONAL_CLI_STATE" == "off-PATH" ]]; then
    append_profile 'export PATH="$HOME/.local/bin:$PATH"' "claude-cli"
  fi
  ok "Claude Code installed ($(claude --version 2>/dev/null | head -1))"
else
  spin "The script installs Claude Code..." bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
  append_profile 'export PATH="$HOME/.local/bin:$PATH"' "claude-cli"
  export PATH="$HOME/.local/bin:$PATH"
  if claude --version &>/dev/null; then
    ok "Claude Code installed"
  else
    fail "The Claude Code installation was not successful. See https://claude.com/claude-code"
    exit 1
  fi
fi

divider

DESKTOP_VERIFIED=false
DESKTOP_AVAILABLE=false
if [[ "$DESKTOP_STATE" == "healthy" ]]; then
  ok "Claude desktop app found"
  DESKTOP_AVAILABLE=true
else
  if confirm "Install the Claude desktop app?"; then
    brew_install_visible "the Claude desktop app" --cask claude
    if [[ -x "/Applications/Claude.app/Contents/MacOS/Claude" ]]; then
      ok "Claude desktop app installed and launchable"
      DESKTOP_AVAILABLE=true
    else
      warn "The installation was not successful. Download the app from"
      warn "https://claude.ai/download. The project will remain unchanged."
    fi
  else
    warn "Claude Desktop installation was skipped. The project will remain unchanged."
  fi
fi

show_claude_desktop_handoff() {
  local root="$1"
  info "In Claude Desktop, open Code and choose this exact project folder:"
  info "$root"
  info "The installer cannot verify that Claude Desktop selected this folder."
}

# ═════════════════════════════════════════════════════════════════
# Step 7: Your project folder and pinned template
# ═════════════════════════════════════════════════════════════════

header "Your project folder"

DEFAULT_SRC_DIR="$HOME/Documents/src"

resolve_destination() {
  local path="$1"
  if [[ "$path" != /* ]]; then
    path="$PWD/$path"
  fi
  local component normalized="" index
  local -a components=() stack=()
  IFS='/' read -r -a components <<< "$path"
  for component in "${components[@]}"; do
    case "$component" in
      ''|.) ;;
      ..)
        if [[ ${#stack[@]} -gt 0 ]]; then
          index=$((${#stack[@]} - 1))
          unset "stack[$index]"
        fi
        ;;
      *) stack[${#stack[@]}]="$component" ;;
    esac
  done
  for component in "${stack[@]}"; do
    normalized="$normalized/$component"
  done
  path="${normalized:-/}"
  # realpath is not present on every supported macOS version. Resolve the
  # existing parent and append the leaf without following a destination link.
  local parent leaf
  parent=$(dirname "$path")
  leaf=$(basename "$path")
  if [[ -L "$path" ]]; then
    fail "The project destination is a symbolic link: $path"
    return 1
  fi
  while [[ ! -d "$parent" ]]; do
    leaf="$(basename "$parent")/$leaf"
    parent=$(dirname "$parent")
  done
  parent=$(cd "$parent" && pwd -P)
  printf '%s/%s' "${parent%/}" "$leaf"
}

valid_project_name() {
  [[ "$1" =~ ^[a-z0-9][a-z0-9._-]{0,62}$ && "$1" != "." && "$1" != ".." ]]
}

template_remote_is_safe() {
  local root="$1" template_url template_push_url
  template_url=$(git -C "$root" remote get-url template 2>/dev/null || true)
  template_push_url=$(git -C "$root" remote get-url --push template 2>/dev/null || true)
  [[ "$template_url" == "$TEMPLATE_REPOSITORY" || "$template_url" == "${TEMPLATE_REPOSITORY}.git" ]] &&
    [[ "$template_push_url" == "DISABLED" ]]
}

template_origin_is_legacy() {
  local root="$1" origin
  origin=$(git -C "$root" remote get-url origin 2>/dev/null || true)
  [[ "$origin" == "$TEMPLATE_REPOSITORY" || "$origin" == "${TEMPLATE_REPOSITORY}.git" ]]
}

template_markers_are_valid() {
  local root="$1"
  [[ -f "$root/package.json" && -f "$root/package-lock.json" &&
     -f "$root/next.config.ts" && -d "$root/app" &&
     -f "$root/prisma/schema.prisma" && -f "$root/CLAUDE.md" &&
     -f "$root/README.md" ]]
}

installed_template_commit() {
  local root="$1" marker repository commit lines
  marker="$root/.git/vibe-template-provenance"
  [[ -f "$marker" ]] || return 1
  repository=$(sed -n '1p' "$marker")
  commit=$(sed -n '2p' "$marker")
  lines=$(wc -l < "$marker" | tr -d ' ')
  [[ "$repository" == "$TEMPLATE_REPOSITORY" && "$lines" == "2" ]] && valid_full_commit "$commit" || return 1
  printf '%s\n' "$commit"
}

destination_state() {
  local root="$1"
  if [[ ! -e "$root" ]]; then printf 'absent'; return; fi
  if [[ ! -d "$root" || -L "$root" ]]; then printf 'unsafe'; return; fi
  if [[ -z "$(find "$root" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    printf 'empty'; return
  fi
  if [[ -f "$root/.git/vibe-template-checkout" ]] &&
     template_origin_is_legacy "$root" &&
     [[ "$(sed -n '1p' "$root/.git/vibe-template-checkout")" == "$TEMPLATE_REPOSITORY" ]] &&
     [[ "$(sed -n '2p' "$root/.git/vibe-template-checkout")" == "$CURRENT_TEMPLATE_COMMIT" ]] &&
     [[ "$(wc -l < "$root/.git/vibe-template-checkout" | tr -d ' ')" == "2" ]]; then
    printf 'incomplete'; return
  fi
  if template_origin_is_legacy "$root" &&
     [[ "$(git -C "$root" rev-parse HEAD 2>/dev/null || true)" == "$CURRENT_TEMPLATE_COMMIT" ]] &&
     template_markers_are_valid "$root"; then
    if [[ -z "$(git -C "$root" status --porcelain)" ]]; then
      printf 'legacy'; return
    fi
    printf 'unrelated'; return
  fi
  if installed_template_commit "$root" >/dev/null &&
     template_remote_is_safe "$root" &&
     template_markers_are_valid "$root"; then
    printf 'complete'; return
  fi
  printf 'unrelated'
}

copy_template_worktree() {
  local root="$1" state="$2"
  local temporary
  if [[ "$state" == "absent" ]]; then
    mkdir -p "$(dirname "$root")"
    mkdir "$root"
  fi
  temporary=$(mktemp -d "${TMPDIR:-/tmp}/creator-ai-template.XXXXXX")
  git -C "$temporary" init --quiet
  git -C "$temporary" remote add template "$TEMPLATE_REPOSITORY"
  info "The setup retrieves the approved template commit without retaining its Git history."
  if ! git -C "$temporary" fetch --no-tags --depth=1 template "$CURRENT_TEMPLATE_COMMIT" ||
     ! git -C "$temporary" checkout --quiet --detach "$CURRENT_TEMPLATE_COMMIT"; then
    rm -rf "$temporary"
    fail "Could not retrieve the approved template commit."
    return 1
  fi
  if [[ "$(git -C "$temporary" rev-parse HEAD)" != "$CURRENT_TEMPLATE_COMMIT" ]]; then
    rm -rf "$temporary"
    fail "Template verification failed: the checked-out commit is not approved."
    return 1
  fi
  tar -C "$temporary" --exclude=.git -cf - . | tar -C "$root" -xf -
  rm -rf "$temporary"
  if ! template_markers_are_valid "$root"; then
    fail "Template verification failed: required application root markers are missing."
    return 1
  fi
}

initialize_participant_repository() {
  local root="$1"
  git -C "$root" init --quiet -b main
  git -C "$root" add .
  git -C "$root" commit --quiet -m "Initialize project from Creator AI Tools"
  git -C "$root" remote add template "$TEMPLATE_REPOSITORY"
  git -C "$root" remote set-url --push template DISABLED
  INSTALLED_TEMPLATE_COMMIT="$CURRENT_TEMPLATE_COMMIT"
  printf '%s\n%s\n' "$TEMPLATE_REPOSITORY" "$INSTALLED_TEMPLATE_COMMIT" > "$root/.git/vibe-template-provenance"
}

convert_legacy_template_checkout() {
  local root="$1"
  [[ -z "$(git -C "$root" status --porcelain)" ]] || return 1
  [[ "$(git -C "$root" rev-parse HEAD 2>/dev/null || true)" == "$CURRENT_TEMPLATE_COMMIT" ]] || return 1
  rm -rf "$root/.git"
  initialize_participant_repository "$root"
}

participant_repository_details() {
  local project_name="$1"
  gh repo view "$GH_USER/$project_name" --json nameWithOwner,url --jq '.nameWithOwner + "|" + .url' 2>/dev/null || true
}

canonical_https_repository_url() {
  local repository="$1"
  repository="${repository#"${repository%%[![:space:]]*}"}"
  repository="${repository%"${repository##*[![:space:]]}"}"
  repository="${repository%/}"
  repository="${repository%.git}"
  repository="${repository%/}"
  [[ "$repository" =~ ^https://[^/?#@]+/[^/?#]+/[^/?#]+$ ]] || return 1
  printf '%s\n' "$repository"
}

participant_origin_is_owned() {
  local root="$1" project_name="$2" origin details expected_name expected_url
  origin=$(canonical_https_repository_url "$(git -C "$root" config --get remote.origin.url 2>/dev/null || true)" 2>/dev/null || true)
  details=$(participant_repository_details "$project_name")
  expected_name="$GH_USER/$project_name"
  expected_url="https://github.com/$expected_name"
  [[ "$details" == "$expected_name|$expected_url" ]] &&
    [[ "${origin%.git}" == "$expected_url" ]]
}

record_participant_repository() {
  local root="$1" project_name="$2" repository
  repository=$(canonical_https_repository_url "https://github.com/$GH_USER/$project_name")
  printf '%s\n%s\n' "$GH_USER/$project_name" "$repository" > "$root/.git/vibe-participant-repository"
}

participant_repository_marker_matches() {
  local root="$1" project_name="$2" repository
  repository=$(canonical_https_repository_url "$(sed -n '2p' "$root/.git/vibe-participant-repository" 2>/dev/null || true)" 2>/dev/null || true)
  [[ -f "$root/.git/vibe-participant-repository" ]] &&
    [[ "$(sed -n '1p' "$root/.git/vibe-participant-repository")" == "$GH_USER/$project_name" ]] &&
    [[ "$repository" == "https://github.com/$GH_USER/$project_name" ]]
}

ensure_participant_branch_remote() {
  local root="$1" project_name="$2" local_commit remote_commit
  if ! participant_origin_is_owned "$root" "$project_name"; then
    fail "The existing origin is not the authenticated participant's expected repository. It was not changed."
    return 1
  fi
  local_commit=$(git -C "$root" rev-parse main)
  remote_commit=$(git -C "$root" ls-remote --heads origin refs/heads/main | awk 'NR == 1 { print $1 }')
  if [[ -z "$remote_commit" ]]; then
    if ! git -C "$root" push origin main:main; then
      warn "The private repository exists and origin is preserved, but main was not pushed. Rerun setup after resolving the GitHub push failure."
      return 0
    fi
    remote_commit=$(git -C "$root" ls-remote --heads origin refs/heads/main | awk 'NR == 1 { print $1 }')
  fi
  if [[ "$remote_commit" != "$local_commit" ]]; then
    fail "The remote main branch differs from this local commit. It was not overwritten."
    return 1
  fi
  gh api -X PATCH "repos/$GH_USER/$project_name" -f default_branch=main >/dev/null 2>&1 || {
    fail "The participant repository main branch was pushed, but GitHub could not set it as the default branch. Set main as the default branch in GitHub, then rerun setup."
    return 1
  }
  record_participant_repository "$root" "$project_name"
  ok "Private participant repository: $GH_USER/$project_name https://github.com/$GH_USER/$project_name"
}

create_participant_repository() {
  local root="$1" project_name="$2" details expected_url creation_status
  [[ "$GITHUB_VERIFIED" == "true" && -n "$GH_USER" ]] || {
    warn "GitHub is unavailable. This project remains a fresh local repository with no origin."
    return 0
  }

  if git -C "$root" remote get-url origin >/dev/null 2>&1; then
    ensure_participant_branch_remote "$root" "$project_name"
    return
  fi

  details=$(participant_repository_details "$project_name")
  expected_url="https://github.com/$GH_USER/$project_name"
  if [[ -n "$details" ]]; then
    if ! participant_repository_marker_matches "$root" "$project_name"; then
      warn "GitHub repository $GH_USER/$project_name already exists. This local project was not connected to it."
      return 0
    fi
    git -C "$root" remote add origin "$expected_url.git"
    ensure_participant_branch_remote "$root" "$project_name"
    return
  fi
  if [[ "${VIBE_SETUP_ASSUME_YES:-0}" != "1" ]] && ! confirm "Create private GitHub repository $GH_USER/$project_name and push main?"; then
    warn "Private GitHub repository creation was skipped. The deployment skill can create one later."
    return 0
  fi

  creation_status=0
  gh repo create "$project_name" --private --source="$root" --remote=origin --push || creation_status=$?
  details=$(participant_repository_details "$project_name")
  if [[ "$details" != "$GH_USER/$project_name|$expected_url" ]]; then
    warn "GitHub repository creation did not complete. This project remains local with no origin."
    return 0
  fi
  if ! git -C "$root" remote get-url origin >/dev/null 2>&1; then
    git -C "$root" remote add origin "$expected_url.git"
  fi
  if (( creation_status != 0 )); then
    warn "GitHub created the private repository, but its initial push did not complete. Origin is preserved and setup will resume it safely."
  fi
  ensure_participant_branch_remote "$root" "$project_name"
}

SRC_DIR="${VIBE_SETUP_SOURCE_DIR:-$DEFAULT_SRC_DIR}"

ACTIVE_PHASE="project destination verification"
info "Current template commit available: $CURRENT_TEMPLATE_COMMIT"

PROJECT_NAME="${VIBE_SETUP_PROJECT_NAME:-my-first-app}"
if [[ -z "${VIBE_SETUP_PROJECT_NAME:-}" ]]; then
  PROJECT_NAME=$(prompt_value "Project name: " "$PROJECT_NAME")
fi
while ! valid_project_name "$PROJECT_NAME"; do
  warn "Use 1 to 63 lowercase letters, numbers, dots, hyphens, or underscores."
  PROJECT_NAME=$(prompt_value "Project name: " "my-first-app")
done

if [[ -z "${VIBE_SETUP_SOURCE_DIR:-}" ]]; then
  if ! confirm "Use $DEFAULT_SRC_DIR as the source folder?"; then
    SRC_DIR=$(prompt_value "Source folder: " "$DEFAULT_SRC_DIR")
  fi
fi
SRC_DIR=$(resolve_destination "$SRC_DIR")
PROJECT_ROOT=$(resolve_destination "$SRC_DIR/$PROJECT_NAME")

info "Source folder: $SRC_DIR"
info "Project name: $PROJECT_NAME"
info "Resolved project root: $PROJECT_ROOT"
if [[ "${VIBE_SETUP_ASSUME_YES:-0}" != "1" ]] && ! confirm "Use this exact project root?"; then
  echo "The setup stopped before changing the destination."
  exit 0
fi

while true; do
  DESTINATION_STATE=$(destination_state "$PROJECT_ROOT")
  case "$DESTINATION_STATE" in
    absent|empty)
      copy_template_worktree "$PROJECT_ROOT" "$DESTINATION_STATE"
      initialize_participant_repository "$PROJECT_ROOT"
      break
      ;;
    complete)
      INSTALLED_TEMPLATE_COMMIT=$(installed_template_commit "$PROJECT_ROOT")
      ok "The independent participant repository is already complete at this root."
      ok "Existing project template commit verified: $INSTALLED_TEMPLATE_COMMIT"
      break
      ;;
    legacy)
      choice="${VIBE_SETUP_EXISTING_ACTION:-$(gum choose "Convert the unchanged template checkout" "Use an alternate destination" "Abort without changes")}" # participant choice
      ;;
    unrelated|unsafe)
      warn "The destination is nonempty and is not this approved template."
      choice="${VIBE_SETUP_EXISTING_ACTION:-$(gum choose "Use an alternate destination" "Abort without changes")}" # participant choice
      ;;
  esac

  case "$choice" in
    "Convert the unchanged template checkout")
      if ! convert_legacy_template_checkout "$PROJECT_ROOT"; then
        fail "The existing checkout is not safe to convert automatically. Its history and remotes were left unchanged."
        exit 1
      fi
      break
      ;;
    "Use an alternate destination")
      SRC_DIR=$(resolve_destination "$(prompt_value "Source folder: " "$SRC_DIR")")
      PROJECT_NAME=$(prompt_value "Project name: " "$PROJECT_NAME")
      if ! valid_project_name "$PROJECT_NAME"; then
        warn "The alternate project name is not valid."
        continue
      fi
      PROJECT_ROOT=$(resolve_destination "$SRC_DIR/$PROJECT_NAME")
      info "Resolved project root: $PROJECT_ROOT"
      if [[ "${VIBE_SETUP_ASSUME_YES:-0}" != "1" ]] && ! confirm "Use this exact project root?"; then
        continue
      fi
      ;;
    *) echo "The setup stopped. Existing destination data was not changed."; exit 0 ;;
  esac
done

ok "Source folder confirmed: $SRC_DIR"
ok "Project root verified: $PROJECT_ROOT"
if [[ -z "$INSTALLED_TEMPLATE_COMMIT" ]]; then
  INSTALLED_TEMPLATE_COMMIT=$(installed_template_commit "$PROJECT_ROOT") || {
    fail "The installed template provenance marker is invalid. Existing project files were not changed."
    exit 1
  }
fi
ok "Current template commit available: $CURRENT_TEMPLATE_COMMIT"
ok "Installed project template commit verified: $INSTALLED_TEMPLATE_COMMIT"
PARTICIPANT_BRANCH=$(git -C "$PROJECT_ROOT" symbolic-ref --short HEAD)
ok "Development branch ready: $PARTICIPANT_BRANCH"

if [[ "${VIBE_SETUP_DESTINATION_ONLY:-0}" == "1" ]]; then
  exit 0
fi

if [[ -z "$(git -C "$PROJECT_ROOT" remote get-url origin 2>/dev/null || true)" ]]; then
  create_participant_repository "$PROJECT_ROOT" "$PROJECT_NAME"
fi

# Create the local diagnostic artifacts before the concise participant handoff.
HANDOFF_FILE="$PROJECT_ROOT/FIRST_APP_HANDOFF.md"
produce_first_app_contract >/dev/null

# The project exists before any Desktop action. Declining or failing this
# optional handoff cannot remove or rewrite the checkout.
if [[ "$DESKTOP_AVAILABLE" == "true" ]]; then
  if [[ "$DESKTOP_WAS_RUNNING" == "true" && "$SHELL_CONFIGURATION_CHANGED" == "true" ]]; then
    info "The setup changed your shell configuration after Claude Desktop started."
    if confirm "Restart Claude Desktop so it can read the current environment?"; then
      osascript -e 'tell application "Claude" to quit' >/dev/null 2>&1 || true
      open -a Claude >/dev/null 2>&1 || true
    else
      warn "Claude Desktop was not restarted. Restart it before you verify Code tools."
    fi
  else
    open -a Claude >/dev/null 2>&1 || true
  fi

  info "Sign in to Claude Desktop with your own account."
  info "Claude Code access depends on your account, plan, and organization policy."
  info "You control sign-in, folder approval, and all normal permission prompts."
  show_claude_desktop_handoff "$PROJECT_ROOT"
else
  warn "Claude Desktop is unavailable. Your project is still ready for development."
  show_claude_desktop_handoff "$PROJECT_ROOT"
fi

# ═════════════════════════════════════════════════════════════════
# Step 8: Summary and Claude handoff
# ═════════════════════════════════════════════════════════════════

verify_gui_login_shell

if [[ "$POSTGRES_VERIFIED" == "true" && "$GITHUB_VERIFIED" == "true" && "$GUI_LOGIN_SHELL_VERIFIED" == "true" && -n "${GIT_NAME:-}" && -n "${GIT_EMAIL:-}" ]]; then
  SETUP_READY=true
  SUMMARY_TITLE="Your Mac is ready."
  header "Setup complete!"
  confetti
else
  SETUP_READY=false
  SUMMARY_TITLE="Setup needs your attention."
  header "Setup needs attention"
fi

gum style \
  --border rounded \
  --border-foreground 76 \
  --padding "1 3" \
  --margin "0 2" \
  "$(gum style --foreground 76 --bold "$SUMMARY_TITLE")" \
  "" \
  "$(gum style --foreground 76 "  ✓") Xcode tools, Homebrew, Git, build libraries" \
  "$(gum style --foreground 76 "  ✓") mise with Node.js and Ruby" \
  "$(gum style --foreground 76 "  $([[ "$POSTGRES_VERIFIED" == "true" ]] && printf '✓' || printf '!')") Postgres.app database: $([[ "$POSTGRES_VERIFIED" == "true" ]] && printf 'verified' || printf 'participant action required')" \
  "$(gum style --foreground 76 "  $([[ "$GITHUB_VERIFIED" == "true" ]] && printf '✓' || printf '!')") GitHub authentication: $([[ "$GITHUB_VERIFIED" == "true" ]] && printf 'verified in GUI context' || printf 'participant action required')" \
  "$(gum style --foreground 76 "  $([[ -n "${GIT_NAME:-}" && -n "${GIT_EMAIL:-}" ]] && printf '✓' || printf '!')") Git identity: $([[ -n "${GIT_NAME:-}" && -n "${GIT_EMAIL:-}" ]] && printf 'configured' || printf 'participant action required')" \
  "$(gum style --foreground 76 "  ✓") Claude Code installed" \
  "$(gum style --foreground 76 "  !") Claude Desktop folder: select it manually in Code" \
  "$(gum style --foreground 76 "  ✓") Project root: $PROJECT_ROOT" \
  "$(gum style --foreground 76 "  ✓") Development branch: $PARTICIPANT_BRANCH"

# ── Generate the versioned receipt and its Markdown projection ───────────────

produce_first_app_contract >/dev/null

# ── Show handoff instructions ──────────────────────────────────

STARTER_PROMPT="Open $PROJECT_ROOT, read CLAUDE.md, and help me start the app."

echo ""
gum style \
  --border rounded \
  --border-foreground 214 \
  --padding "1 3" \
  --margin "0 2" \
  --bold \
  "Next: open your project in Claude Desktop Code"

echo ""
info "Project folder:"
gum style --foreground 255 --background 237 --padding "1 2" --margin "0 4" \
  "$PROJECT_ROOT"
info "In Claude Desktop, open Code and select that exact folder."
info "Starter prompt:"
gum style --foreground 255 --background 237 --padding "1 2" --margin "0 4" "$STARTER_PROMPT"
if confirm "Copy this starter prompt to the clipboard?"; then
  printf '%s' "$STARTER_PROMPT" | pbcopy 2>/dev/null || true
  info "The starter prompt is on your clipboard."
fi
info "Diagnostics remain local at: $PROJECT_ROOT/.first-app/receipt.json"
info "If a tool needs repair, open a new Terminal window from the macOS desktop and rerun this setup."
echo ""

gum style \
  --foreground 99 \
  --bold \
  --margin "0 2" \
  "The setup is complete. Build your first app now. 🚀"
echo ""
