# First-app handoff and receipt contract

This document defines contract version `1.0` between the
`TanookiLabs/creator-ai-tools` bootstrap producer and the T3 template consumer.
Both release inputs are currently co-located in that repository. The frozen
source and commit are recorded in [release-inputs.md](release-inputs.md).

The contract carries only local, nonsecret setup facts. It does not authorize
Claude, GitHub, database, filesystem, or deployment actions. Authentication,
folder access, permission prompts, and any repair remain participant-controlled.

## Files and ownership

The producer writes these files inside the verified application root:

| File | Purpose | Lifecycle |
| --- | --- | --- |
| `FIRST_APP_HANDOFF.md` | Concise human/agent projection of the latest receipt | Atomically replaced on every completed bootstrap attempt after the root is verified, including partial failure |
| `.first-app/receipt.json` | Canonical machine-readable latest receipt | Atomically replaced with the same `run.id` and outcomes as the handoff |
| `.first-app/diagnostics/*.json` | Optional bounded, redacted prior diagnostics | Local only; at most five most-recent distinct failed/partial attempts |

The template must ignore `/FIRST_APP_HANDOFF.md` and `/.first-app/`. These
root-anchored rules are the v1 retention policy and are present in `.gitignore`.
The producer must not amend global Git excludes or commit either artifact. A
future template may adopt a handoff as durable documentation only through an
explicit reviewed contract-version change; `.first-app/` remains local.

The participant may delete the handoff, receipt, or diagnostics at any time.
They contain no credentials and are not required to run the application. A
rerun recreates current files. The bootstrap does not copy them outside the
application root, except that it may display the handoff summary in the current
terminal. Clipboard copying is opt-in and must receive the same redacted text.

## Versioning and compatibility

`contract_version` uses `MAJOR.MINOR` decimal strings. The producer writes
exactly one version; v1 writes `1.0`.

- A consumer supporting major `1` must accept any `1.x`, ignore unknown fields,
  and use known required fields. Additive fields and enum values require a minor
  increment. Unknown enum values are treated as `unverified`, never as success.
- Removing/renaming a field, changing meaning, location, or requiredness, or
  weakening redaction requires a new major version.
- A missing/malformed version or unsupported major makes the handoff
  informational only. The consumer must stop automated interpretation, preserve
  participant files, and direct the participant to a compatible bootstrap. It
  must not guess from prose.
- Producers must validate against
  `docs/contracts/first-app-receipt-v1.schema.json` before writing or displaying
  a receipt. Consumers read the JSON receipt as authoritative; Markdown is a
  projection for people and agents.

## Receipt schema

The JSON Schema is normative. Required top-level fields are
`contract_version`, `kind`, `run`, `application`, `provenance`, `capabilities`,
`participant_actions`, `result`, `redaction`, and `timestamps`. All other v1
fields are optional. Paths are absolute, normalized paths with no `~`; repository
URLs contain no userinfo or query string; commits are full lowercase Git SHA-1
values.

Capability IDs are stable producer-defined lowercase dotted names, such as
`tool.node`, `service.postgres`, `auth.github`, and `handoff.claude_desktop`.
Each capability requires:

- `id`, `status`, `checked_at`, and a nonsecret `summary`.
- `status`: `verified`, `unverified`, `unavailable`, `failed`, or `skipped`.
- Optional `version`, `evidence_code`, and `recovery_action_id`. Evidence is a
  bounded symbolic code, not command output. A version is omitted when it was
  not reliably established.

Participant actions require `id`, `kind`, `blocking`, and `instruction`.
`kind` is `authenticate`, `grant_permission`, `confirm`, `repair`, `retry`, or
`continue`. Instructions must not embed secret values or tell an agent to bypass
permissions. `blocking: true` means overall success cannot yet be claimed. The
Desktop folder-selection action is non-blocking when the installer cannot
observe that selection reliably: a deep link or participant response is not
proof that the exact folder was selected.

`result.status` is derived, not caller-selected:

- `success`: every release-required capability is `verified` and there are no
  blocking participant actions. An optional, explicitly unverified Desktop
  folder-selection handoff does not change installation success.
- `partial_failure`: an application root and valid provenance exist, but at
  least one required capability is not verified or a blocking action remains.
- `failed`: no safe, verified application root/provenance handoff can be made.
  When the root cannot be verified, no in-root receipt is written; the producer
  prints only a redacted failure summary and recovery action.

`result.failed_capability_ids` contains every required non-verified capability,
sorted lexicographically with no duplicates. `participant_actions` and
`capabilities` are also sorted by `id`. These rules make semantic output stable.

## Provenance

`provenance.bootstrap` and `provenance.template` each require canonical
`repository`, immutable `commit`, and `version`. Until tagged releases exist,
`version` is the full commit prefixed by `git:`. The bootstrap additionally
requires the SHA-256 digest of the executed bootstrap bytes. Optional
`source_url` must be immutable and credential-free.

The application object records the exact verified `root`, repository identity,
checked-out commit, and links to durable repository instructions as relative
paths. It must never contain a home-directory listing or environment dump.

## Timestamps and deterministic reruns

All timestamps are UTC RFC 3339 strings with whole-second precision. `run.id`
is a UUID generated once per invocation. `started_at` never changes during an
invocation; `finished_at` and capability `checked_at` describe that invocation.

On rerun, the producer rechecks capabilities rather than trusting the old
receipt, constructs the complete new receipt, validates/redacts it, then writes
receipt and handoff via same-directory temporary files plus atomic rename. The
latest files are replacements, not merges. Given identical observed state, the
same contract/bootstrap/template versions, and the same participant choices,
all fields except `run.id` and timestamps are identical.

Before replacement, a `partial_failure` or `failed` latest receipt may be copied
to diagnostics under `<started_at>-<run.id>.json`; a byte-identical semantic
failure is not copied twice. Successful receipts are not archived. After a
successful write, or after adding a diagnostic, keep the five newest diagnostic
files by `(started_at, run.id)` and remove only older files inside that exact
directory. Never retain raw command output, environment dumps, or credentials.
An interrupted write leaves the previous valid latest file intact; orphaned
temporary files may be removed only after their path and ownership are checked.

## Redaction before output

Redaction happens before validation, disk writes, terminal display, clipboard,
or diagnostics. The producer uses an allowlist serializer for the schema; it
must not serialize process environments or arbitrary stdout/stderr. It must:

1. Omit tokens, passwords, cookies, authorization headers, private keys,
   database URLs, environment values, Keychain contents, and Git credential
   helper output.
2. Strip URL userinfo, query strings, and fragments. Record canonical HTTPS Git
   repository URLs only.
3. Record GitHub authentication only as capability status and, optionally, a
   nonsecret account handle explicitly returned by an approved status check.
4. Reduce failures to stable `evidence_code` plus a curated summary. Never place
   raw commands, stack traces, or participant-entered text in the contract.
5. Replace any detected secret-like value with `[REDACTED]`, then fail closed if
   a credential signature remains. `redaction.applied` is `true` when a value
   was replaced and `redaction.fields` lists schema paths; otherwise it is
   `false` with an empty list.

## Markdown projection

`FIRST_APP_HANDOFF.md` is generated from the validated receipt in this fixed
section order:

1. `# First App Handoff` and `<!-- generated; local-only; contract 1.0 -->`
2. `## Next action` (all participant actions, or the safe continue action)
3. `## Application` (exact root, repository, commit)
4. `## Provenance` (bootstrap/template repository, version, commit, digest)
5. `## Capability results` (table of ID, status, version, checked time, summary)
6. `## Durable instructions` (repository-relative links)
7. `## Run result` (status, run ID, start/finish timestamps, receipt location)

The projection never includes optional fields that are absent and never adds
facts not in the receipt. Success and partial-failure examples live under
`docs/contracts/examples/`; both are intentionally nonsecret.

## Consumer behavior

Claude Desktop or another template consumer must verify that the selected
working directory resolves to `application.root`, read durable `CLAUDE.md`
before acting, and treat each capability status as evidence only for its
`checked_at` time. It re-verifies environment-dependent facts before mutation.
It may guide the listed participant action, but it must not authenticate,
approve permissions, change repository visibility, overwrite occupied paths,
or use unsafe permission bypasses on the participant's behalf.
