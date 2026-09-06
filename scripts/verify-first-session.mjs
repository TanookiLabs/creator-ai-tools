#!/usr/bin/env node

import { spawn, spawnSync } from "node:child_process"
import { createServer } from "node:net"
import { existsSync, lstatSync, readFileSync, realpathSync, renameSync, writeFileSync } from "node:fs"
import { join, parse, resolve } from "node:path"
import { fileURLToPath } from "node:url"

const CAPABILITY_PREFIXES = ["desktop."]
const ACTION_PREFIXES = ["desktop."]
const SECRET_PATTERN = /-----BEGIN .*PRIVATE KEY-----|github_pat_|gh[pousr]_|sk_(?:live|test)_|whsec_|(?:postgres(?:ql)?|mysql):\/\/[^\s@]+:[^\s@]+@|authorization\s*:|(?:token|password|secret|cookie)\s*[=:]\s*\S+/i
const REQUIRED_MARKERS = ["CLAUDE.md", "package.json", "package-lock.json", "next.config.ts", "app", "prisma/schema.prisma"]

const timestamp = () => new Date().toISOString().replace(/\.\d{3}Z$/, "Z")

function command(file, args, options = {}) {
  const result = spawnSync(file, args, {
    cwd: options.cwd,
    env: options.env,
    encoding: "utf8",
    timeout: options.timeout ?? 15_000,
    stdio: ["ignore", "pipe", "pipe"],
  })
  return { ok: result.status === 0, stdout: result.stdout ?? "", error: result.error }
}

function cleanVersion(value) {
  const text = String(value ?? "").trim().split(/\r?\n/, 1)[0].slice(0, 80)
  return text && !SECRET_PATTERN.test(text) ? text : undefined
}

function loadLocalEnvironment(root, base = process.env) {
  const environment = { ...base }
  for (const name of [".env", ".env.local"]) {
    const path = join(root, name)
    if (!existsSync(path)) continue
    for (const line of readFileSync(path, "utf8").split(/\r?\n/)) {
      const match = line.match(/^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/)
      if (!match || environment[match[1]]) continue
      let value = match[2]
      if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) value = value.slice(1, -1)
      environment[match[1]] = value
    }
  }
  return environment
}

function postgresEnvironment(environment) {
  const raw = environment.DIRECT_URL || environment.DATABASE_URL
  if (!raw) return null
  try {
    const url = new URL(raw)
    if (!["postgres:", "postgresql:"].includes(url.protocol) || !url.hostname || !url.pathname.slice(1)) return null
    const result = { ...environment }
    delete result.DATABASE_URL
    delete result.DIRECT_URL
    result.PGHOST = url.hostname
    result.PGPORT = url.port || "5432"
    result.PGDATABASE = decodeURIComponent(url.pathname.slice(1))
    if (url.username) result.PGUSER = decodeURIComponent(url.username)
    if (url.password) result.PGPASSWORD = decodeURIComponent(url.password)
    const sslmode = url.searchParams.get("sslmode")
    if (sslmode) result.PGSSLMODE = sslmode
    return result
  } catch {
    return null
  }
}

function capability(id, ok, success, failure, recovery, version) {
  const item = {
    id,
    status: ok ? "verified" : "unverified",
    checked_at: timestamp(),
    summary: ok ? success : failure,
  }
  const safeVersion = cleanVersion(version)
  if (safeVersion) item.version = safeVersion
  if (!ok) {
    item.evidence_code = recovery.evidence
    item.recovery_action_id = recovery.id
  }
  return item
}

const action = (id, kind, instruction) => ({ id, kind, blocking: true, instruction })

async function freePort() {
  return await new Promise((resolvePort, reject) => {
    const server = createServer()
    server.unref()
    server.on("error", reject)
    server.listen(0, "127.0.0.1", () => {
      const address = server.address()
      server.close(() => resolvePort(address.port))
    })
  })
}

async function observePreview(root, environment) {
  const port = await freePort()
  const child = spawn("npm", ["run", "dev", "--", "--hostname", "127.0.0.1", "--port", String(port)], {
    cwd: root,
    env: { ...environment, PORT: String(port), NEXT_TELEMETRY_DISABLED: "1" },
    detached: true,
    stdio: ["ignore", "ignore", "ignore"],
  })
  let started = false
  let preview = false
  try {
    for (let attempt = 0; attempt < 30; attempt += 1) {
      if (child.exitCode !== null) break
      try {
        const response = await fetch(`http://127.0.0.1:${port}/`, { redirect: "manual", signal: AbortSignal.timeout(1_000) })
        started = true
        preview = response.status >= 200 && response.status < 500
        if (preview) break
      } catch {}
      await new Promise(resolveWait => setTimeout(resolveWait, 500))
    }
  } finally {
    if (child.pid && child.exitCode === null) {
      try { process.kill(-child.pid, "SIGTERM") } catch {}
    }
  }
  return { started, preview }
}

function renderHandoff(receipt) {
  const lines = ["# First App Handoff", `<!-- generated; local-only; contract ${receipt.contract_version} -->`, "", "## Next action", ""]
  if (receipt.participant_actions.length) for (const item of receipt.participant_actions) lines.push(`- ${item.instruction}`)
  else lines.push("- Desktop-local verification passed. Continue working from this exact application root.")
  lines.push("", "## Application", "", `- Root: \`${receipt.application.root}\``, `- Repository: \`${receipt.application.repository}\``, `- Commit: \`${receipt.application.commit}\``, "", "## Provenance", "", `- Bootstrap repository: \`${receipt.provenance.bootstrap.repository}\``, `- Bootstrap version: \`${receipt.provenance.bootstrap.version}\``)
  if (receipt.provenance.bootstrap.release_label) lines.push(`- Bootstrap release label: \`${receipt.provenance.bootstrap.release_label}\``)
  lines.push(`- Bootstrap commit: \`${receipt.provenance.bootstrap.commit}\``, `- Bootstrap SHA-256: \`${receipt.provenance.bootstrap.sha256}\``, `- Template repository: \`${receipt.provenance.template.repository}\``, `- Template version: \`${receipt.provenance.template.version}\``, `- Template commit: \`${receipt.provenance.template.commit}\``, "", "## Capability results", "", "| ID | Status | Version | Checked at | Summary |", "| --- | --- | --- | --- | --- |")
  for (const item of receipt.capabilities) lines.push(`| ${item.id} | ${item.status} | ${item.version || "—"} | ${item.checked_at} | ${item.summary} |`)
  lines.push("", "## Durable instructions", "")
  for (const instruction of receipt.application.instructions) lines.push(`- [${instruction}](${instruction})`)
  lines.push("", "## Run result", "", `- Status: \`${receipt.result.status}\``, `- Run ID: \`${receipt.run.id}\``, `- Started: \`${receipt.timestamps.started_at}\``, `- Finished: \`${receipt.timestamps.finished_at}\``, "- Receipt: `.first-app/receipt.json`", "")
  return lines.join("\n")
}

function atomicWrite(target, content) {
  const current = lstatSync(target)
  if (!current.isFile() || current.isSymbolicLink() || current.uid !== process.getuid()) throw new Error(`Refusing to replace unsafe generated file: ${target}`)
  const temporary = `${target}.tmp-${process.pid}`
  writeFileSync(temporary, content, { mode: 0o600, flag: "wx" })
  renameSync(temporary, target)
}

export async function verifyFirstSession(root = process.cwd(), options = {}) {
  root = realpathSync(resolve(root))
  if (root === parse(root).root) throw new Error("The selected folder is not a safe application root.")
  const receiptPath = join(root, ".first-app", "receipt.json")
  const handoffPath = join(root, "FIRST_APP_HANDOFF.md")
  if (!existsSync(receiptPath) || !existsSync(handoffPath)) throw new Error("Generated first-app handoff files are missing. Rerun the pinned bootstrap, then reopen its exact application root.")
  const receipt = JSON.parse(readFileSync(receiptPath, "utf8"))
  if (!/^1\.\d+$/.test(receipt.contract_version ?? "")) throw new Error("The handoff contract version is missing, malformed, or unsupported. Rerun a compatible bootstrap; no files were changed.")
  if (root !== realpathSync(receipt.application?.root ?? "/")) throw new Error(`Wrong application root. Open the exact root recorded in FIRST_APP_HANDOFF.md; no files were changed.`)

  const capabilities = []
  const actions = []
  const add = (item, recovery) => { capabilities.push(item); if (item.status !== "verified") actions.push(recovery) }
  const markersOk = REQUIRED_MARKERS.every(marker => existsSync(join(root, marker)))
  add(capability("desktop.root", markersOk, "The physical working directory matches the receipt and contains every application-root marker.", "The receipt root is open, but one or more required application markers are missing.", { id: "desktop.repair_root", evidence: "root_markers_missing" }), action("desktop.repair_root", "repair", "Restore the missing root markers from the approved template commit, then rerun npm run verify:first-session."))

  const tools = [
    ["git", ["--version"], "desktop.tool.git"], ["gh", ["--version"], "desktop.tool.gh"],
    ["node", ["--version"], "desktop.tool.node"], ["npm", ["--version"], "desktop.tool.npm"],
    ["psql", ["--version"], "desktop.tool.psql"],
  ]
  for (const [name, args, id] of tools) {
    const result = command(name, args, { cwd: root })
    add(capability(id, result.ok, `${name} is available in this session.`, `${name} is unavailable or unhealthy in this session.`, { id: `desktop.repair_${name}`, evidence: "tool_unavailable" }, result.ok ? result.stdout : undefined), action(`desktop.repair_${name}`, "repair", `Restore ${name} on the Claude Desktop PATH, restart Desktop if PATH changed, then rerun npm run verify:first-session.`))
  }

  const gitRoot = command("git", ["rev-parse", "--show-toplevel"], { cwd: root })
  let repositoryOk = false
  try { repositoryOk = gitRoot.ok && realpathSync(gitRoot.stdout.trim()) === root } catch {}
  add(capability("desktop.repository", repositoryOk, "Git identifies this exact directory as the repository root.", "Git does not identify this directory as the repository root.", { id: "desktop.reopen_root", evidence: "git_root_mismatch" }), action("desktop.reopen_root", "confirm", "Close this Code session and open the exact application root recorded in FIRST_APP_HANDOFF.md."))

  const gh = command("gh", ["auth", "status"], { cwd: root })
  add(capability("desktop.auth.github", gh.ok, "GitHub CLI authentication is valid in this Desktop-local session.", "GitHub CLI authentication was not verified in this Desktop-local session.", { id: "desktop.authenticate_github", evidence: "interactive_auth_check_failed" }), action("desktop.authenticate_github", "authenticate", "Run gh auth login yourself in the interactive macOS login session, complete its prompts, restart Desktop if needed, then rerun verification."))

  const environment = loadLocalEnvironment(root, options.environment)
  const pgEnvironment = postgresEnvironment(environment)
  const database = pgEnvironment ? command("psql", ["-X", "-w", "--tuples-only", "--no-align", "--command", "SELECT 1"], { cwd: root, env: pgEnvironment }) : { ok: false }
  add(capability("desktop.database", database.ok && database.stdout.trim() === "1", "psql completed a real read-only connection to the configured application database.", pgEnvironment ? "The configured application database did not accept a read-only psql connection." : "DATABASE_URL or DIRECT_URL is missing or is not a valid PostgreSQL URL.", { id: "desktop.repair_database", evidence: pgEnvironment ? "database_connection_failed" : "database_configuration_missing" }), action("desktop.repair_database", "repair", "Configure the local PostgreSQL URL without sharing it, confirm Postgres is running, then rerun npm run verify:first-session."))

  const dependencies = command("npm", ["ls", "--depth=0", "--silent"], { cwd: root, timeout: 30_000 })
  add(capability("desktop.dependencies", dependencies.ok, "Installed dependencies match the npm manifest and lockfile.", "Project dependencies are missing or do not match the npm manifest and lockfile.", { id: "desktop.install_dependencies", evidence: "dependencies_unready" }), action("desktop.install_dependencies", "repair", "Review the repository state, run npm ci from the exact application root, then rerun npm run verify:first-session."))

  let observed = { started: false, preview: false }
  if (dependencies.ok && markersOk) observed = await (options.observePreview ?? observePreview)(root, environment)
  add(capability("desktop.application", observed.started, "The existing npm run dev command started an HTTP application process.", "The existing npm run dev command did not start an observable HTTP application process within 15 seconds.", { id: "desktop.repair_application", evidence: "application_start_failed" }), action("desktop.repair_application", "repair", "Run npm run dev, inspect only redacted error details, correct the reported application error, then rerun verification."))
  add(capability("desktop.preview", observed.preview, "A loopback HTTP request observed a reachable application preview.", "No reachable application preview was observed within 15 seconds.", { id: "desktop.retry_preview", evidence: "preview_unreachable" }), action("desktop.retry_preview", "retry", "Confirm the application can bind a local port, then rerun npm run verify:first-session and open the preview URL shown by Desktop."))

  // These bootstrap observations have now been rechecked in the actual
  // consumer session. Update only their existing contract fields; do not
  // change provenance, authentication, permissions, or participant choices.
  const latest = new Map(capabilities.map(item => [item.id, item]))
  const superseded = {
    "auth.github": latest.get("desktop.auth.github"),
    "handoff.claude_desktop": latest.get("desktop.root"),
    "service.postgres": latest.get("desktop.database"),
    "tool.git": latest.get("desktop.tool.git"),
    "tool.node": latest.get("desktop.tool.node"),
    "tool.npm": latest.get("desktop.tool.npm"),
  }
  receipt.capabilities = receipt.capabilities.map(item => {
    const observation = superseded[item.id]
    if (!observation) return item
    const updated = { ...item, status: observation.status, checked_at: observation.checked_at, summary: observation.summary }
    if (observation.version) updated.version = observation.version
    else delete updated.version
    if (observation.status === "verified") {
      delete updated.evidence_code
      delete updated.recovery_action_id
    } else {
      updated.evidence_code = observation.evidence_code
      updated.recovery_action_id = observation.recovery_action_id
    }
    return updated
  })

  const resolvedBootstrapActions = new Set()
  if (latest.get("desktop.root")?.status === "verified") resolvedBootstrapActions.add("confirm.desktop_folder")
  if (latest.get("desktop.auth.github")?.status === "verified") resolvedBootstrapActions.add("authenticate.github")
  if (latest.get("desktop.database")?.status === "verified") resolvedBootstrapActions.add("repair.postgres")

  receipt.capabilities = [...receipt.capabilities.filter(item => !CAPABILITY_PREFIXES.some(prefix => item.id.startsWith(prefix))), ...capabilities].sort((a, b) => a.id.localeCompare(b.id))
  receipt.participant_actions = [...receipt.participant_actions.filter(item => !ACTION_PREFIXES.some(prefix => item.id.startsWith(prefix)) && !resolvedBootstrapActions.has(item.id)), ...actions].sort((a, b) => a.id.localeCompare(b.id))
  receipt.result.failed_capability_ids = receipt.capabilities.filter(item => item.status !== "verified").map(item => item.id).sort()
  receipt.result.status = receipt.result.failed_capability_ids.length || receipt.participant_actions.some(item => item.blocking) ? "partial_failure" : "success"
  receipt.timestamps.finished_at = timestamp()
  receipt.redaction = { applied: receipt.redaction?.applied === true, fields: Array.isArray(receipt.redaction?.fields) ? receipt.redaction.fields : [] }
  const serialized = JSON.stringify(receipt, null, 2) + "\n"
  const markdown = renderHandoff(receipt)
  if (SECRET_PATTERN.test(serialized) || SECRET_PATTERN.test(markdown)) throw new Error("Generated verification output failed the credential safety check; no files were changed.")
  atomicWrite(receiptPath, serialized)
  atomicWrite(handoffPath, markdown)
  return { receipt, capabilities }
}

async function main() {
  try {
    console.log("Desktop first-session verification: checking the exact root, tools, database, dependencies, application, and preview.")
    const { receipt, capabilities } = await verifyFirstSession()
    for (const item of capabilities) console.log(`${item.status === "verified" ? "PASS" : "ACTION"} ${item.id}: ${item.summary}`)
    console.log(`Result: ${receipt.result.status}. Redacted details were written to FIRST_APP_HANDOFF.md and .first-app/receipt.json.`)
    process.exitCode = receipt.result.status === "success" ? 0 : 1
  } catch (error) {
    console.error(`Verification stopped: ${error instanceof Error ? error.message : "unknown safe failure"}`)
    process.exitCode = 1
  }
}

if (resolve(process.argv[1] ?? "") === fileURLToPath(import.meta.url)) await main()
