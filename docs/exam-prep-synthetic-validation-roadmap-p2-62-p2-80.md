# Exam Prep Synthetic Validation Roadmap — P2-62 through P2-80

Status: ACTIVE / source of truth for the next Exam Prep development cycle.

Owner decision: 2026-09-14.

This document exists so the plan survives chat/context limits. It must remain the canonical working roadmap until P2-80 is complete. The roadmap may be corrected when new evidence requires it, but changes must be explicit: update this file, record the reason in Change Log, and do not silently reuse or skip stage numbers.

## Non-negotiable safety rules

- iClub is live. Existing learner data, legacy Practice/Tours, ratings, certificates, history, localStorage and pending operations are protected.
- Real beta learners are never reused as synthetic test identities.
- Synthetic learner/operational evidence must never satisfy a real learner weekly review, real learner readiness gate or real-world release evidence. Explicit engineering validation artifacts may satisfy only the engineering prerequisite they are designed for; they never substitute for the required real weekly reviews or real learner evidence.
- Synthetic identities/seeders must never read, copy or clone real learner PII/evidence to make fixtures realistic.
- P1 and P5 mastery/evidence remain fully independent.
- AI and Mentor Care remain separately gated. Core must stay fully functional with AI OFF and Mentor OFF.
- Answer keys, correctness and private explanations must remain protected during active protected assessments.
- Production changes remain additive, rollback-first and fail-closed.
- Before merge, before production migration, before destructive/cleanup operations, and after production change: perform a fresh safety re-check.

## Engineering status model

The project now has separate readiness statuses:

1. Core Engineering GREEN — deterministic Exam Prep passes the synthetic engineering gates.
2. AI Engineering GREEN — requires Core GREEN plus AI safety, parity and explanation-quality gates.
3. Mentor Technical GREEN — assignment/RLS/queue/override/second-check technical gates pass.
4. Real-world Evidence UNPROVEN — remains unproven until real learner/mentor evidence exists.

Synthetic validation must never be presented as proof of real learner UX/usability, real population calibration, real retention/support workload, real human mentor capacity/calibration, or real production traffic/peak-load behaviour.

## Synthetic GREEN exit criteria fixed in advance

Core Engineering GREEN requires all of the following on one release-candidate SHA:

- 3 consecutive clean full dress rehearsals using different deterministic seeds;
- all canonical 15 beta/scenario profiles pass;
- valid Stage 0 -> 6 progression from incremental evidence, not calendar jumps;
- all 45 P1 + 36 P5 canonical skills are reachable through governed lifecycle checks;
- P1 <-> P5 mastery/evidence leakage = 0;
- cross-user/RLS leakage = 0;
- protected pre-answer answer-key/correctness/explanation leakage = 0;
- synthetic -> real evidence contamination = 0;
- synthetic -> legacy mutation = 0;
- synthetic cleanup residue after every run = 0;
- rollback succeeds without manual learner-data repair;
- applicable learner-facing scenarios pass EN/RU/UZ;
- 600 learners / 10 mentor-scope isolation matrix passes;
- service-transition matrix passes;
- no unresolved Sev0 or release-blocking Sev1.

AI Engineering GREEN additionally requires Core Engineering GREEN, AI safety gates GREEN, academic-state parity Core-only vs Core+AI diff = 0, and explanation-quality evaluation GREEN with no critical factual/math error in the release-blocking evaluation set.

Mentor Technical GREEN additionally requires assignment/entitlement isolation GREEN, unassigned human-work leakage = 0, queue/review/override/second-check/handover/safeguarding technical flows GREEN, and 600 learners with exactly 10 active mentor scopes producing exactly 10 routine human scopes.

Human mentor capacity is never inferred from synthetic load tests.

## Current production baseline — P2-62 starting point

Repository: `jteshaboev1984-ops/iClub_APP`

Production Supabase project: `mmmduffgpvwjdpruzikw`

Exam Prep feature config at rebaseline:

- rollout_state: `controlled_beta`
- core_enabled: true
- ai_enabled: false
- mentor_enabled: false
- kill_switch: false

Current real beta cohort:

- cohort key: `math_as_p1_p5_beta_2026_09_01`
- cohort status: `canary`
- planned size: 12
- current wave: 1
- active members: 3
- consent rows: 3 `granted`
- active Core-only entitlements: 3
- weekly reviews: 0
- active Exam Prep sessions: 0
- sessions since real-review epoch: 0
- real_review_epoch_started_at: `2026-09-14T04:41:45.818233+00:00`
- monitoring_until: `2026-09-17T04:41:45.818233+00:00`
- development_data_state: `real_monitoring`
- current learner-scoped synthetic residue: 0

Legacy baseline snapshot at rebaseline:

- Practice attempts: 906
- Practice answers: 8820
- Tour attempts: 365
- Tour answers: 6267
- certificates: 157
- public users: 1326

The real beta track is not deleted and is not converted into synthetic evidence. Development no longer waits for real Wave 1 activity. If real learners later appear, their evidence remains on the separate real track.

## Roadmap

### P2-62 — Synthetic Development Rebaseline
Goal: lock the new development contract before generating any new synthetic learner state.

### P2-63 — Bidirectional Synthetic Evidence Firewall
Goal: make real/synthetic separation structural, not procedural.

### P2-64 — Synthetic Run Registry
Goal: every synthetic row is attributable to a specific validation run.

### P2-65 — Dedicated Synthetic Identities
Goal: stop using any real account as test infrastructure.

### P2-66 — Reusable Seed -> Run -> Audit -> Cleanup Engine
Goal: replace one-off cleanup with repeatable per-run lifecycle.

### P2-67 — Canonical Scenario Matrix v2
Goal: version the complete synthetic learner scenario set before broad execution.

### P2-68 — Incremental Evidence and Virtual-Time Harness
Goal: test the 36-week/stage lifecycle quickly without faking causal evidence.

### P2-69 — Full Stage 0 -> 6 Core Simulation
Goal: exercise deterministic Core end to end.

### P2-70 — Content Lifecycle / Runway Validation
Goal: prove content is connected to runtime rather than merely present.

### P2-71 — Failure and Adversarial Campaign

Goal: actively attack state/security boundaries.

Test at minimum:

- offline/reconnect;
- refresh/back/close/abandon/resume;
- duplicate submit/finalize;
- stale action/idempotency key;
- timer expiry;
- focus/visibility integrity events;
- malformed/unauthorized RPC;
- cross-user access;
- P1 -> P5 and P5 -> P1 leakage attempts;
- protected answer-key/correctness access before finalization;
- rollback/recovery during interrupted flows.

Exit: no data leak, cross-component credit or unrecoverable corruption.

### P2-72 — Legacy Preservation Firewall v2
Goal: prove Exam Prep synthetic work cannot mutate live legacy state.

### P2-73 — Core Engineering Dress Rehearsal
Goal: earn Core Engineering GREEN.

### P2-74 — AI Shadow Safety
Prerequisite: Core Engineering GREEN.

### P2-75 — AI Academic-State Parity
Goal: prove AI is optional explanation/personalization only.

### P2-76 — AI Explanation Quality Evaluation
Goal: evaluate the only area AI is allowed to improve: explanation/personalization quality.

### P2-77 — Mentor Technical Simulation
Goal: validate Mentor Care mechanics without claiming human capacity evidence.

### P2-78 — 600/10 Concurrency and Service Transitions
Goal: prove technical isolation under scale-shaped synthetic load.

### P2-79 — Recovery / Rollback / Disaster Rehearsal
Goal: prove failure recovery without manual learner-history repair.

### P2-80 — Independent A-to-Z Release Audit
Goal: independently re-audit implementation against the approved project documents and actual production/repository state.

## Execution order

P2-62 -> P2-63 -> P2-64 -> P2-65 -> P2-66 -> P2-67 -> P2-68 -> P2-69 -> P2-70 -> P2-71 -> P2-72 -> P2-73 -> P2-74 -> P2-75 -> P2-76 -> P2-77 -> P2-78 -> P2-79 -> P2-80

## Current progress

- P2-62: COMPLETE
- P2-63: COMPLETE
- P2-64: COMPLETE
- P2-65: COMPLETE
- P2-66: COMPLETE
- P2-67: COMPLETE
- P2-68: COMPLETE
- P2-69: COMPLETE
- P2-70: COMPLETE
- P2-71: IN PROGRESS
- P2-72..P2-80: NOT STARTED

## Change Log

### 2026-09-14 — v1.4

- Closed P2-70 after PR #64 passed current-schema CI and merged to `main` at `7be28732675c1e620ee0ae1b2acfd002e50d4856`.
- Applied the narrow, fail-closed production alignment migration `exam_prep_p2_70_protected_retest_holdout_alignment_v1`. It changed only the three identified early P5 assessment-item source flags. The migration first confirmed exactly three false targets and zero affected historical non-holdout session snapshots.
- Post-migration verification confirmed 45 P1 and 36 P5 canonical skills, zero published holdout-policy mismatches, zero affected session snapshots, and unchanged controlled-beta/AI/Mentor configuration.
- Began P2-71 failure and adversarial campaign. Its timed security cases will remain separate from P2-69, which tested normal timed progression only.

### 2026-09-14 — v1.3

- Closed P2-68 after the accelerated academic-time harness and its weekly-plan ownership hotfix both passed full current-schema CI and production verification.
- Closed P2-69 after the full rollback-only Stage 0 -> 6 Core synthetic learner journey passed, including independent P1/P5 progression, correction/remediation/delayed retest, mixed evidence, timed/full-paper readiness, zero synthetic residue and unchanged legacy state.
- Began P2-70 content lifecycle/runway validation.

### 2026-09-14 — v1.2

- Closed P2-63 through P2-67 after full current-schema CI and production verification.

### 2026-09-14 — v1.1

- Marked P2-62 complete after the roadmap/rebaseline PR merged to `main`.

### 2026-09-14 — v1.0

- Switched development strategy from waiting for real Wave 1/2 activity to a separate repeatable synthetic-validation track.
