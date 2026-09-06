# Clean-Mac happy-path rehearsal evidence

## Run record: 2026-09-06

**Result: BLOCKED BEFORE PARTICIPANT OR MACHINE MUTATION**

This record covers the AC-01 release-gate attempt for the macOS v1 onboarding
flow. It is intentionally not marked as a successful clean-Mac rehearsal.
The immutable bootstrap candidate named by the participant documentation was
not reachable, and the available execution host was Linux rather than a clean
supported Mac. A terminal fixture or Linux preview is not a substitute for
Claude Desktop Code evidence.

### Immutable task provenance

| Source | Pinned revision |
| --- | --- |
| Implementation plan | `2ea258d4-23f9-4481-94ae-b8beaa4d73d2` @ `94465352-0851-446a-96f7-650363fd1631` |
| Requirements | `11e0f129-f487-485b-bf78-f02e0fc2d29a` @ `e63a5a77-72e7-4893-b5e6-bc2aa55d587a` |
| Plan execution | `0c97f4c9-a6c5-410f-989d-6fd84360afb1` |

### Candidate and environment metadata

| Field | Redacted evidence |
| --- | --- |
| Attempt start | `2026-09-06T19:07:19Z` |
| Operator | Automated build session; no personal identifier retained |
| Host | Linux 6.8, x86_64; **not a supported rehearsal host** |
| Required host | Clean supported Mac with participant-controlled GUI session |
| Documented bootstrap release | `bootstrap-v1.0.0` / bootstrap `1.0.0` |
| Documented bootstrap URL | SHA-256-pinned, tag-qualified URL in `README.md` |
| Expected bootstrap digest | `4b9e8d741072d5a1465777620cc2923e4249efbfbc727950f00a1d6c9eeffdd7` |
| Candidate URL result | HTTP 404; no bytes executed |
| Template source | `https://github.com/TanookiLabs/creator-ai-tools` |
| Template commit named by bootstrap | `0393501676cf5f3751089699eafb5090411ff8c7` |
| Remote `main` at attempt | `0393501676cf5f3751089699eafb5090411ff8c7` |
| Local checkout HEAD | `0393501676cf5f3751089699eafb5090411ff8c7` plus uncommitted task-chain changes |
| Receipt contract | `1.0` |

The working tree contains the bootstrap and template implementation changes
that are candidates for a later commit. Therefore the old immutable commit is
not a release candidate for the new behavior, even though it is still remote
`main`. Publishing a tag for the old commit would not satisfy this gate.

## Checklist and timings

Timings below are deliberately coarse and contain no command output, user
names, home paths, URLs with userinfo, tokens, cookies, or connection strings.

| Step | Result | Elapsed | Evidence / stopping reason |
| --- | --- | ---: | --- |
| Read exact plan and requirements revisions | Passed | ~12 s | Both requested revision IDs were returned as current, retained, safe, and ready |
| Inspect actual target repository and release inputs | Passed | <1 s | Next.js 16, React 19, Better Auth, Prisma 6, PostgreSQL, npm lockfile; canonical source and local HEAD recorded above |
| Resolve immutable bootstrap candidate | **Blocked** | <1 s | Tag ref absent; documented raw tag URL returned HTTP 404 |
| Run documented bootstrap on clean Mac | Not started | — | Fail-before-mutation rule applied because candidate download failed and host is not macOS |
| Participant consent and destination confirmation | Not started | — | Must occur in participant's interactive Mac session |
| Pinned checkout and exact physical root confirmation | Not started | — | No candidate bootstrap was executed |
| Postgres.app Open / Initialize / permission flow | Not started | — | Requires macOS GUI and an isolated participant-local database |
| Claude Desktop launch, sign-in, Code eligibility, exact-root folder approval | Not started | — | Requires participant-controlled GUI interaction |
| Desktop-local toolchain, GitHub Keychain, database, dependencies | Not started | — | Terminal-only evidence is explicitly insufficient |
| Desktop-local application start and reachable preview | **Not demonstrated** | — | AC-01 remains open |
| Bootstrap fixture suite | Passed | ~6 s | Safety, destination, contract, Desktop handoff, Postgres.app, and documentation checks passed |
| Contract tests | Passed | <1 s | 4/4 tests passed |
| First-session verification tests | Passed | ~3.3 s | 4/4 tests passed, including root fail-closed and redaction behavior |

## Consent, bypass, and redaction review

- No sign-in, GitHub authorization, Keychain access, macOS folder access,
  Postgres initialization, or command permission was automated or inferred.
- No permission-bypass flag was used. The rehearsal did not weaken
  authentication or alter repository visibility.
- No database URL, environment value, token, cookie, authorization header,
  private key, participant email, or machine-specific home path is retained.
- No generated receipt is attached because the pinned bootstrap never ran.
  Creating a synthetic successful receipt would misrepresent the release gate.
- Focused automated tests used temporary fixtures. Their passing results show
  contract and safety behavior, not a completed Desktop-local rehearsal.

## Manual friction observed

1. **The published entrypoint is unreachable.** The README presents
   `bootstrap-v1.0.0` and a digest as the supported immutable candidate, but
   the tag does not exist and the raw URL returns 404. A clean participant
   cannot begin the happy path.
2. **The implementation is not an immutable candidate.** Required bootstrap,
   receipt, Desktop, Postgres, and template-consumer changes are still local
   working-tree changes on top of the old pinned commit.
3. **A real Mac runner is mandatory.** This build session exposes no macOS GUI,
   Postgres.app, Claude Desktop, participant login context, or folder-consent
   dialog. These are the behavior under test, so emulation would hide the most
   important friction.
4. **Existing unrelated worktree noise affects `git diff --check`.** Trailing
   whitespace in the generated `AGENTS.md` block causes that broad check to
   report warnings; it did not affect the focused bootstrap and contract tests.

## Evidence required to close AC-01

After owner review, commit the candidate changes and publish a tag whose raw
`setup.sh` bytes match the README digest. Then run the README block on a clean
supported Mac and append a new run record containing:

- macOS version and hardware family, bootstrap release/digest, template commit,
  contract version, anonymized operator, start/finish times, and step timings;
- the redacted generated `.first-app/receipt.json` or its checksum plus every
  capability status, without credentials or participant identifiers;
- the physical application root in a restricted evidence attachment (use a
  stable placeholder such as `<participant-home>` in this repository), and the
  matching Git origin and full commit;
- participant confirmation of destination, Postgres.app initialization,
  Desktop Code availability, exact-root folder access, and normal command
  permission prompts;
- Desktop Code output summary from `npm run verify:first-session`, including
  toolchain, interactive GitHub state, PostgreSQL connection, dependency
  installation, application start, and reachable loopback preview;
- observed manual friction, recovery steps used, defects, and confirmation that
  no bypass flag or secret appeared in the retained transcript.

AC-01 may be marked passed only when the new record shows a successful receipt
and `desktop.preview` is verified from Desktop Code on that Mac.
