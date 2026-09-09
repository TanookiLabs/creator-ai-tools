# [Project Name] - Implementation Tasks

<!--
════════════════════════════════════════════════════════════════════════
HOW TO USE THIS TEMPLATE (instructions for the LLM generating the plan)
────────────────────────────────────────────────────────────────────────
Produce an implementation plan that follows this exact format and level of
detail. Requirements:

1. Break the work into sequential PHASES, and each phase into discrete TASKS.
2. Give every task a stable ID (TASK-001, TASK-002, …) that never changes,
   so tasks can reference each other as dependencies.
3. Every task MUST be self-contained: someone should be able to execute it
   using only that task block plus the tasks it depends on.
4. Fill in EVERY field in the task template below. Do not skip sections.
   If a section genuinely does not apply, write "N/A" and say why.
5. The "Detailed Execution Plan" must contain real, runnable, copy-pasteable
   code/commands specific to this project's stack — not pseudocode and not
   vague prose. Match the conventions of the existing codebase.
6. Do NOT include time estimates of any kind (no hours, days, story points,
   or effort scores). Priority and dependencies convey sequencing instead.
7. Order tasks so that dependencies always appear earlier than the tasks
   that depend on them.
8. Keep acceptance criteria concrete and testable — each item should be
   verifiable as done/not-done.

Replace every [bracketed placeholder] and delete these comment blocks in the
final output.
════════════════════════════════════════════════════════════════════════
-->

## Project Overview
[2–4 sentences describing what is being built, the primary capabilities it
delivers, and any overarching architectural approach. State the end goal so a
reader understands the "why" behind the tasks.]

## Total Tasks: [N]

<!-- List the phases up front so the reader has a map before diving in. -->
### Phases
- **Phase 1: [Name]** ([N] tasks) — [one-line purpose]
- **Phase 2: [Name]** ([N] tasks) — [one-line purpose]
- **Phase 3: [Name]** ([N] tasks) — [one-line purpose]
- [...continue for all phases...]

---

# PHASE 1: [PHASE NAME] ([N] Tasks)

<!--
════════════════════════════════════════════════════════════════════════
TASK TEMPLATE — copy this block for every task. Keep the field order.
════════════════════════════════════════════════════════════════════════
-->

## TASK-001: [Concise, action-oriented task title]
**Feature Reference**: [The feature/component/epic this task belongs to]
**Phase**: [Phase number]
**Priority**: [Critical | High | Medium | Low]

**Description**:
[1–3 sentences stating exactly what this task accomplishes and its scope.
Be specific about what is in scope and, where useful, what is out of scope.]

**Acceptance Criteria**:
<!-- Concrete, testable outcomes. Each must be objectively verifiable. -->
- [ ] [Observable outcome 1]
- [ ] [Observable outcome 2]
- [ ] [Observable outcome 3]
- [ ] [Edge case / error handling that must be satisfied]
- [ ] [Verification that it works in the target environment(s)]

**Dependencies**: [None | TASK-00X, TASK-00Y — the specific task IDs that
must be complete before this one can start]

**Technical Implementation**:
<!-- High-level "where and how": files to create/modify, services or modules
     touched, patterns to follow. A quick orientation before the step-by-step. -->
- [File/module to create or edit, e.g. `path/to/file`]
- [Integration point / pattern to follow]
- [Any library, config, or interface involved]

**Detailed Execution Plan**:
<!-- Numbered, ordered steps. Include real, runnable code/commands in fenced
     blocks. This is the heart of the task — be exhaustive and concrete. -->
1. [First concrete step — command or action]
   ```[language]
   [actual code or command]
   ```
2. [Next step — what to write/change and where]
   ```[language]
   [actual code, showing the full relevant snippet]
   ```
3. [Continue with each step needed to fully complete the task...]
4. [Final step, e.g. wiring it up / registering / running it]

**Testing Requirements**:
<!-- How this task's correctness is verified. Name the specific tests to write. -->
- [Unit test(s) for the new logic]
- [Integration test(s) for interactions with other components]
- [Edge case / error-path tests]
- [Any manual verification step, if applicable]

---

## TASK-002: [Next task title]
**Feature Reference**: [...]
**Phase**: 1
**Priority**: [...]

**Description**:
[...]

**Acceptance Criteria**:
- [ ] [...]
- [ ] [...]

**Dependencies**: [TASK-001 | None]

**Technical Implementation**:
- [...]

**Detailed Execution Plan**:
1. [...]
   ```[language]
   [...]
   ```

**Testing Requirements**:
- [...]

---

<!-- Repeat the task block for every task in this phase. -->

---

# PHASE 2: [PHASE NAME] ([N] Tasks)

<!-- Continue with the same TASK template for all subsequent phases. -->

## TASK-00X: [...]
[... full task block ...]

---

<!--
════════════════════════════════════════════════════════════════════════
OPTIONAL: ABBREVIATED TASKS
If the plan is very large and later phases are well-understood, later tasks
MAY be summarized in one paragraph each instead of the full block — but only
after a critical mass of fully-detailed tasks establishes the pattern. Each
summary must still state: what it builds, its key deliverables, and notable
dependencies. Prefer full detail wherever the work is non-obvious.
════════════════════════════════════════════════════════════════════════
-->

# PHASE [N]: [FINAL PHASE NAME] (Tasks XX-YY) — Summarized

**TASK-0XX: [Title]** — [1–2 sentence summary of what it builds and its key
deliverables.]

**TASK-0YY: [Title]** — [1–2 sentence summary.]

---

# IMPLEMENTATION SUMMARY

[Closing overview that ties the plan together. Recap the major capabilities
delivered across the phases as a bulleted list:]

- **[Capability 1]** — [one line]
- **[Capability 2]** — [one line]
- **[Capability 3]** — [one line]

[Optionally note the recommended implementation approach — e.g. incremental
delivery by phase, parallelizable tracks, or a suggested team structure.
Do NOT include time or hour estimates.]
