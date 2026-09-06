# macOS v1 recovery matrix and release decision

## Decision: NO-GO

The macOS v1 onboarding release must not be published or promoted. The
recovery implementation passes its focused fixture matrix, but the critical
clean-Mac/Claude Desktop gate has no successful evidence. The documented
`bootstrap-v1.0.0` tag is absent from the canonical remote, its raw bootstrap
URL returns HTTP 404, and the candidate implementation is not an immutable Git
revision. Publishing either bootstrap or template alone would also break their
shared version/provenance contract.

This decision is based only on implementation plan
`2ea258d4-23f9-4481-94ae-b8beaa4d73d2` revision
`94465352-0851-446a-96f7-650363fd1631`, requirements
`11e0f129-f487-485b-bf78-f02e0fc2d29a` revision
`e63a5a77-72e7-4893-b5e6-bc2aa55d587a`, and execution
`0c97f4c9-a6c5-410f-989d-6fd84360afb1`.

## Verification record — 2026-09-06 UTC

| Check | Result |
| --- | --- |
| `npm run test:bootstrap` | Passed: 6 recovery suites |
| `npm run test:contract` | Passed: 4/4 tests |
| `npm run test:first-session` | Passed: 4/4 tests |
| `npm run verify` | Passed: credential/env and no-seed scan, ESLint, TypeScript, 21/21 quality tests, Prisma validation, Next.js production build, and production audit with 0 vulnerabilities |
| Bootstrap/README digest agreement | Passed: `4b9e8d741072d5a1465777620cc2923e4249efbfbc727950f00a1d6c9eeffdd7` |
| Remote `bootstrap-v1.0.0` tag | **Failed: absent** |
| Tag-qualified bootstrap URL | **Failed: HTTP 404** |
| Commit-qualified old template archive | Reachable (HTTP 200), but incompatible with the uncommitted candidate behavior |
| Clean supported Mac and Desktop Code | **Blocked: no macOS GUI host in this execution environment** |

## Recovery matrix

Automated results below use temporary local fixtures. They verify surrounding
shell and contract behavior but do not impersonate macOS GUI consent,
Keychain, Postgres.app, or Claude Desktop. The participant controls every
authentication and permission action.

| Scenario | Result | Evidence | Owner / closing action |
| --- | --- | --- | --- |
| Successful rerun | Pass (fixture) | Contract output is semantically stable, run sequence increments, managed Homebrew block remains single, and prior diagnostics remain bounded | Bootstrap owner maintains idempotency |
| Interrupted receipt write and rerun | Pass (fixture) | Existing receipt remains valid after a stale partial temporary write; rerun writes a valid receipt without consuming the stale file | Bootstrap owner |
| Interruption after prerequisite, Postgres, GitHub, or Desktop phase | Manual validation blocked | Receipt records partial capability state and recovery actions, but this Linux host cannot interrupt real macOS/GUI phases | macOS rehearsal operator; bootstrap owner fixes any failure |
| Homebrew installed outside `PATH` | Pass (fixture) | Standard-location stub is classified `off-PATH`, `brew shellenv` is activated, and Homebrew is not reinstalled | Bootstrap owner |
| Missing shell profile | Pass (fixture) | Profile is created only in an owned, writable directory and receives one managed block | Participant owns profile; bootstrap owner owns guard |
| Unwritable shell profile | Pass (fixture) | Bootstrap stops before discovery/mutation and fixture checksum is unchanged | Participant repairs file permission narrowly |
| Incorrectly owned shell profile | Pass (fixture) | Bootstrap stops before discovery/mutation and fixture checksum is unchanged; no recursive ownership command exists | Participant/system administrator performs narrow ownership repair |
| Postgres.app Gatekeeper / Open / Initialize / permission UI | Manual validation blocked | Recovery text names all interactions plus Spotlight/Finder; bounded wait is fixture-tested | Participant approves UI; database owner confirms safe local target |
| Postgres readiness and cancellation | Pass (fixture) | Only explicit Postgres.app `psql -X -w` query result `1` verifies readiness; timeout exposes retry, Finder, continue-unverified, and stop choices | Participant chooses; bootstrap owner maintains check |
| Empty destination | Pass (fixture) | Exact resolved root receives pinned checkout and required root markers are verified | Participant confirms destination; bootstrap owner |
| Unrelated nonempty destination | Pass (fixture) | Directory is classified unrelated and retained file checksum is unchanged; workflow offers alternate path or abort | Participant chooses destination |
| Failed/interrupted checkout | Pass (fixture) | Provenance-marked incomplete checkout resumes to the exact commit; wrong origin and moving commit are rejected | Bootstrap owner |
| GitHub GUI Keychain succeeds while SSH fails | Pass (fixture contract); manual GUI validation blocked | SSH/background context remains non-authoritative, receipt records `gui_context_required`, and bootstrap never invokes `gh auth login` | Participant authenticates in GUI Terminal; account/org owner handles policy |
| Claude Desktop absent, signed out, or unavailable by policy | Manual validation blocked | Install is consent-gated; recovery preserves checkout and directs sign-in/account-policy resolution without credential automation | Participant and Claude account/org owner |
| Deep link unavailable or canceled | Pass (fixture recovery); manual GUI validation blocked | URL contains one encoded exact-root value; manual Open Folder and normal CLI fallback are present; checkout precedes launch | Participant confirms exact folder |
| Folder confirmation canceled | Pass (fixture recovery); manual GUI validation blocked | Project is preserved and exact-root manual recovery is shown; no permission bypass flags exist | Participant |
| Parent directory / wrong application root | Pass (fixture) | First-session verifier fails closed before changing generated artifacts; receipt producer rejects mismatched physical root/provenance | Participant reopens exact printed root; template owner maintains markers |
| Desktop-local tools, database, app start, and preview | Automated verifier Pass (fixture); real Desktop run blocked | Four verifier tests cover success, wrong root, compatible v1 minor, and unsupported-major fail-closed behavior | macOS rehearsal operator and participant |
| Windows and Linux | Excluded | Bootstrap rejects non-Darwin before profile or tool mutation; no parity or workaround is published | Release owner keeps scope macOS-only |

## Compatibility and immutable publication gate

Bootstrap `1.0.0`, receipt contract major `1`, and the T3 template must be
released from the same reviewed full commit because this repository currently
owns both producer and consumer. Contract consumers accept later `1.x` minors,
ignore unknown fields, and treat unknown capability states as unverified. An
unsupported or malformed major fails closed without rewriting local handoff
state.

No immutable release was created during this no-go. To change the decision,
the TanookiLabs release owner must:

1. Review and commit the combined bootstrap/template candidate.
2. Run the complete release gate from a clean checkout of that exact commit.
3. Publish `bootstrap-v1.0.0` at that commit, recalculate the exact `setup.sh`
   SHA-256, update the README if needed, and verify both tag-qualified raw
   bootstrap and commit-qualified template archive are reachable.
4. Run the README flow on a clean supported Mac and capture participant-
   confirmed Desktop Code, exact-root, Keychain, Postgres.app, app-start, and
   preview evidence without secrets.
5. Rerun this recovery matrix against the same immutable bytes. Any critical
   failure keeps the decision at no-go.

## Non-destructive rollback

Before promotion, rollback means stop and leave the participant checkout and
generated local diagnostics intact. Do not delete an occupied destination,
profile content, credentials, or database data.

After promotion, the release owner restores the previously verified
bootstrap/template pair together and republishes documentation that pins those
exact immutable bytes. Existing participant projects remain in place. A code
rollback redeploys the prior compatible application artifact and reruns health
checks; it never resets, drops, seeds, reverses migrations, deletes users, or
rewrites authentication. If the prior artifact is incompatible with the
current schema, stop and involve the database owner for an approved forward
fix or backup/restore incident procedure. Database recovery is separate from
release rollback and requires explicit owner approval.

## Codebase deviations and retained risks

- The dependency task record is complete, but its evidence explicitly says
  the clean-Mac rehearsal was blocked. Administrative completion is not a pass.
- The release source inventory freezes old commit
  `0393501676cf5f3751089699eafb5090411ff8c7`; the implemented behavior exists
  only as uncommitted work above it and cannot truthfully use that old commit
  as its provenance.
- The full static gate initially stopped because a fake credential-shaped URL
  was committed literally in a verifier test. The fixture now assembles that
  value at runtime so the credential scanner can remain strict.
- Real macOS GUI scenarios remain unverified. Fixture success must not be
  promoted to participant or Desktop success.
- Generated `AGENTS.md` contains pre-existing trailing whitespace, so broad
  `git diff --check` reports unrelated warnings until its generator/source is
  corrected.
