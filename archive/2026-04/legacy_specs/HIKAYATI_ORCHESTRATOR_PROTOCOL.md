# HIKAYATI_ORCHESTRATOR_PROTOCOL.md

## Purpose
This file is the execution protocol for the manager agent and all worker agents.
It is mandatory. The manager agent must distribute work by phase, preserve state, and resume from the exact stopping point on the next session without requiring the user to restate context.

---

## Authority Order
The agents must obey documents in this order:
1. `HIKAYATI_AGENT_MASTER_SPEC.md`
2. `stabilization_report.md`
3. `architecture_report.md`
4. `implementation_plan.md`
5. `task.md`
6. This file `HIKAYATI_ORCHESTRATOR_PROTOCOL.md`

If two documents conflict, the higher document wins.

---

## Current Project Truth (must be assumed unless updated by a newer report)
- LAW 1 has been refactored toward a use-case flow.
- `StoryCreationScreen` must remain input-only.
- `IntroCinematicScreen` must remain loading/transition-only.
- `CinemaScreen` must remain display-only.
- Avatar features must remain isolated from story generation flow.
- No worker may place avatar generation logic inside Story Wizard or Cinema.

---

## Runtime Issues Already Observed
These are active defects and must be prioritized before any new feature work:
1. `HakeemService` chat model error:
   - runtime log shows: `models/gemini-pro is not found for API version v1beta`
   - implication: Hakeem chat is using an invalid or deprecated model identifier/configuration.
2. Story persistence schema mismatch:
   - runtime log shows: `Could not find the 'cover_image' column of 'stories' in the schema cache`
   - implication: code and Supabase schema are out of sync.
3. Performance issue:
   - runtime log shows skipped frames and main-thread overload warnings.
   - implication: cinematic/audio/image flow needs profiling before expansion.
4. Android manifest warning:
   - `android:enableOnBackInvokedCallback="true"` not enabled.

No worker may ignore these issues and jump to feature expansion.

---

## Manager Agent Responsibilities
The manager agent must:
- Break work into phases and sub-phases.
- Assign each sub-phase to worker agents with explicit file scope.
- Prevent overlap between workers.
- Maintain a persistent progress ledger.
- Produce a closure report at the end of each working session.
- On the next session, resume from the last unfinished checkpoint automatically.

The manager agent must never ask the user to restate the project plan if the project files already contain it.

---

## Required Persistent Files In Project Root
The manager agent must create and maintain these files in the project root:

### 1) `PROJECT_STATUS.md`
Single source of truth for current phase, active blockers, latest decisions, and next step.

### 2) `TASK_BACKLOG.md`
Ordered backlog of all tasks by priority.
Each task must include:
- Task ID
- Title
- Phase
- Priority
- Status (`todo`, `in_progress`, `blocked`, `done`)
- Owner (`manager`, `worker-A`, etc.)
- File scope
- Acceptance criteria

### 3) `SESSION_HANDOFF.md`
End-of-session handoff file.
Must include:
- What was completed today
- What is currently in progress
- Exact next action to execute first next session
- Known blockers
- Commands to run for verification

### 4) `DECISIONS_LOG.md`
All architecture decisions.
Each entry must include:
- Date/time
- Decision
- Why
- Files affected
- Whether reversible

### 5) `TEST_CHECKLIST.md`
Per-phase verification checklist.
No phase is marked done without passing its checklist.

---

## Execution Rules
1. Only one phase may be actively expanded at a time.
2. No new feature work before current blockers are resolved.
3. Any worker touching routing must list all affected routes before editing.
4. Any worker touching backend persistence must verify schema compatibility first.
5. Any worker touching cinematic playback must test:
   - load
   - scene transition
   - audio start/stop
   - back navigation
6. Any worker touching Hakeem must not reintroduce avatar analysis into chat service.
7. Dead code must be identified explicitly before deletion.
8. No worker may silently rename files, routes, or models without logging it in `DECISIONS_LOG.md`.

---

## Phase Plan (authoritative)

### Phase A — Stabilize Runtime
Goal: eliminate runtime defects in current flow.

Tasks:
- Fix Hakeem model configuration/runtime call.
- Fix `stories.cover_image` schema/code mismatch.
- Enable Android back callback in manifest.
- Investigate skipped frames in cinematic flow.
- Verify full create-story-to-cinema-to-exit loop.

Exit criteria:
- No runtime exceptions in the primary story flow.
- Story save either works fully or is intentionally disabled with explicit fallback.
- Hakeem chat either works or is gated/disabled cleanly.

### Phase B — Align Persistence
Goal: align Supabase schema and repositories with the master spec.

Tasks:
- Audit stories table fields.
- Add migration or patch code for missing columns.
- Verify insert/update/select models.
- Document schema truth.

Exit criteria:
- Story save path passes real test.
- Schema documented in repo.

### Phase C — Phase 2 Product Work
Goal: auth + save + private library.

Tasks:
- Auth flow audit
- Save story finalization
- Private Library data flow
- Re-open saved story in Cinema

Exit criteria:
- Signed-in user can generate, save, reopen story.

No phase after C may start until C is complete and signed off.

---

## Worker Assignment Template
For every task assignment, the manager agent must use this structure:

- Task ID:
- Goal:
- Files allowed to change:
- Files forbidden to change:
- Inputs:
- Expected output:
- Verification command:
- Risk notes:

---

## Session Resume Rule
At the start of any future session, the manager agent must read in this exact order:
1. `HIKAYATI_AGENT_MASTER_SPEC.md`
2. `PROJECT_STATUS.md`
3. `SESSION_HANDOFF.md`
4. `TASK_BACKLOG.md`
5. `DECISIONS_LOG.md`

Then it must output:
- Current phase
- Last completed task
- First next task
- Blockers

Then continue immediately.

---

## Forbidden Behaviors
- Do not ask the user to explain the architecture again.
- Do not add avatar logic into story generation screens.
- Do not add store/settings/public library work during runtime stabilization.
- Do not start Phase 3+ while runtime issues remain unresolved.
- Do not mark tasks done without verification evidence.

---

## Definition of “Done” for any task
A task is only `done` if all of the following are true:
- Code changed
- App still analyzes/builds
- Runtime flow relevant to the task was tested
- Result logged in `SESSION_HANDOFF.md`
- Decision logged if architecture changed

---

## First Mandatory Next Actions
The manager agent must do these now, before any other work:
1. Create/update the five persistent root files.
2. Register the current runtime defects from logs.
3. Open a new task batch for Phase A.
4. Assign workers only to Phase A stabilization.
5. Return a short execution plan before modifying code.
