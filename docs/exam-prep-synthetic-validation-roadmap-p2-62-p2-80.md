# Exam Prep Synthetic Validation Roadmap — P2-62 through P2-80

Status: ACTIVE / source of truth for the current Exam Prep development cycle.

Owner decision: 2026-09-14.

This document exists so the plan survives chat/context limits. It remains the canonical working roadmap until P2-80 is complete. Changes must be explicit in this file and recorded in Change Log; stage numbers must not be silently reused or skipped.

## Non-negotiable safety rules

- iClub is live. Existing learner data, legacy Practice/Tours, ratings, certificates, history, localStorage and pending operations are protected.
- Real beta learners are never reused as synthetic test identities.
- Synthetic learner/operational evidence must never satisfy a real learner weekly review, real learner readiness gate or real-world release evidence. Explicit engineering validation artifacts may satisfy only the engineering prerequisite they were designed for.
- Synthetic identities/seeders must never read, copy or clone real learner PII/evidence to make fixtures realistic.
- P1 and P5 mastery/evidence remain fully independent.
- AI Assist and Mentor Care remain separately gated. Core must remain fully functional with AI OFF and Mentor OFF.
- Answer keys, correctness and private explanations remain protected during active protected assessments.
- Production changes remain additive, rollback-first and fail-closed.
- Before merge, before production migration, before destructive/cleanup operations, and after production change: perform a fresh safety re-check.

## Engineering status model

1. Core Engineering GREEN — deterministic Exam Prep passes the fixed synthetic engineering gates.
2. AI Engineering GREEN — requires Core GREEN plus AI safety, academic-state parity and explanation-quality gates.
3. Mentor Technical GREEN — assignment/RLS/queue/override/second-check technical gates pass.
4. Real-world Evidence UNPROVEN — remains unproven until real learner/mentor evidence exists.

Synthetic validation must never be presented as proof of real learner UX/usability, real population calibration, real retention/support workload, real human mentor capacity/calibration, or real production peak-load behaviour.

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

AI Engineering GREEN additionally requires:

- Core Engineering GREEN;
- AI safety gates GREEN;
- academic-state parity Core-only vs Core+AI diff = 0;
- explanation-quality evaluation GREEN with no critical factual/math error in the release-blocking evaluation set.

Mentor Technical GREEN additionally requires:

- assignment/entitlement isolation GREEN;
- unassigned human-work leakage = 0;
- queue/review/override/second-check/handover/safeguarding technical flows GREEN;
- 600 learners with exactly 10 active mentor scopes produces exactly 10 routine human scopes.

Human mentor capacity is never inferred from synthetic load tests.

## Current production baseline — P2-62 starting point

Repository: `jteshaboev1984-ops/iClub_APP`

- baseline main SHA: `e2dc173d0c325f1550b382f26fbeefaa69d38d31`
- latest completed stage before this roadmap: P2-61
- production Supabase project: `mmmduffgpvwjdpruzikw`

Feature config at rebaseline:

- rollout_state: `controlled_beta`
- core_enabled: true
- ai_enabled: false
- mentor_enabled: false
- kill_switch: false

Real beta at rebaseline:

- cohort key: `math_as_p1_p5_beta_2026_09_01`
- cohort status: `canary`
- planned size: 12
- current wave: 1
- active members: 3
- consents: 3 granted
- active Core-only entitlements: 3
- weekly reviews: 0
- active Exam Prep sessions: 0
- sessions since real-review epoch: 0
- development_data_state: `real_monitoring`
- learner-scoped synthetic residue: 0

Legacy baseline at rebaseline:

- Practice attempts: 906
- Practice answers: 8820
- Tour attempts: 365
- Tour answers: 6267
- certificates: 157
- public users: 1326

The real beta track is never deleted or converted into synthetic evidence. Synthetic development does not fabricate real weekly reviews or real learner outcomes.

## Roadmap

### P2-62 — Synthetic Development Rebaseline

Goal: lock the development contract before generating new synthetic learner state.

Deliverables: confirm repository/Supabase baseline and gates; persist roadmap/GREEN criteria; confirm zero synthetic residue; preserve real beta controls; no production learner-data write.

Exit: baseline and roadmap are version-controlled and safety assumptions explicit.

### P2-63 — Bidirectional Synthetic Evidence Firewall

Goal: make real/synthetic separation structural.

Required: explicit synthetic classification; synthetic evidence cannot enter real membership/consent/weekly-review/readiness; engineering validation artifacts remain engineering-only; synthetic seeders cannot clone real PII/evidence; negative tests both directions; browser roles cannot bypass.

Exit: contamination tests = 0 in both directions.

### P2-64 — Synthetic Run Registry

Goal: every synthetic row is attributable to a validation run.

Each run records run_id (`SV-*`), scenario-set version, Git SHA, schema generation, deterministic seed, capability mode, lifecycle timestamps, audit result and cleanup status.

Exit: ambiguous synthetic provenance = 0.

### P2-65 — Dedicated Synthetic Identities

Goal: stop using any real account as test infrastructure.

Required: dedicated synthetic learner/mentor identities; fixtures from canonical scenarios, never real-user clones; RLS/authorization isolation.

Exit: synthetic identities cannot access real private learner data.

### P2-66 — Reusable Seed -> Run -> Audit -> Cleanup Engine

Goal: repeatable per-run lifecycle.

Required: seed only rows owned by run_id; audit owned rows/invariants; cleanup only owned rows; fail closed on ambiguous ownership; cleanup idempotency; zero residue; summary audit; preserve real beta and legacy data.

Exit: run can be created, audited, cleaned and recreated with zero residue/manual repair.

### P2-67 — Canonical Scenario Matrix v2

Goal: version the complete synthetic scenario set before broad execution.

Include 15 canonical profiles plus adversarial variants for P1/P5 asymmetry, both weak, advanced placement, partial coverage, failed learning/correction, delayed/fresh retest, interruption/recovery, profile/session/target/time revision, stale plan/action, offline/retry/idempotency, integrity events and Core/AI/Mentor service transitions. EN/RU/UZ is cross-cutting for learner-facing scenarios.

Exit: scenario set explicit, versioned and reproducible.

### P2-68 — Incremental Evidence and Virtual-Time Harness

Goal: test the 36-week/stage lifecycle quickly without faking causal evidence.

Rules: virtual time is synthetic-only; real server time is unchanged; intermediate evidence is generated in order; calendar alone cannot advance stage; delayed/freshness/staleness windows require actual intermediate events.

Exit: full synthetic year can run accelerated while preserving causality.

### P2-69 — Full Stage 0 -> 6 Core Simulation

Goal: exercise deterministic Core end to end: profile/exam setup; diagnostics/placement; weekly plans; learning/correction; delayed fresh retest; mixed transfer/mastery; syllabus completion; timed consolidation; full papers/readiness; final calibration; independent P1/P5 state.

Exit: governed Stage 0 -> 6 flows reproducible with correct evidence.

### P2-70 — Content Lifecycle / Runway Validation

Goal: prove content is connected to runtime.

For all 45 P1 + 36 P5 skills verify governed diagnostic, learning, correction, fresh retest, written evidence, mixed ownership/transfer, timed/full-paper linkage, protected reserve/holdout, RU/UZ/EN QA and runway hard floor as applicable.

Exit: no orphan/dead-end canonical skill and no reserve/runway violation.

### P2-71 — Failure and Adversarial Campaign

Goal: attack state/security boundaries.

Test offline/reconnect; refresh/back/close/abandon/resume; duplicate submit/finalize; stale action/idempotency key; timer expiry; focus/visibility integrity events; malformed/unauthorized RPC; cross-user access; P1<->P5 leakage attempts; protected answer-key/correctness access before finalization; rollback/recovery during interrupted flows.

Exit: no data leak, cross-component credit or unrecoverable corruption.

### P2-72 — Legacy Preservation Firewall v2

Goal: prove Exam Prep synthetic work cannot mutate live legacy state.

Approach: isolated CI complete before/after row fingerprints/hashes; live production scope-aware fingerprints and proof synthetic mechanisms have no write path into legacy tables/state; do not require whole-production-table equality while real users may legitimately write.

Protect Practice/Tours, ratings, certificates, histories, localStorage and pending operations.

Exit: synthetic-induced legacy mutation = 0.

### P2-73 — Core Engineering Dress Rehearsal

Goal: earn Core Engineering GREEN.

Run three consecutive complete clean rehearsals on the same candidate SHA with different deterministic seeds, covering clean start, canonical scenarios, Stage 0 -> 6, adversarial paths, Core service transitions, audit, cleanup and rollback/replay.

Exit: all fixed Core GREEN criteria pass 3/3.

### P2-74 — AI Shadow Safety

Prerequisite: Core Engineering GREEN.

Goal: develop AI without changing real learner academic state.

Sequence:

1. stub/fake provider;
2. governed synthetic AI only;
3. no real-user AI enablement.

Test:

- active protected-assessment blackout;
- server-built context only;
- source allowlist/no-source behaviour;
- answer-key and hidden explanation protection;
- prompt-injection resistance;
- secret isolation;
- timeout/fallback/rate/budget guards;
- RU/UZ/EN.

Exit: AI safety gates GREEN.

### P2-75 — AI Academic-State Parity

Goal: prove AI is optional explanation/personalization only.

Feed identical raw learner evidence through Core-only and Core+AI and compare placement, P1/P5 state, mastery, stages, correction/retest eligibility and readiness.

Exit: deterministic academic-state diff = 0.

### P2-76 — AI Explanation Quality Evaluation

Goal: evaluate explanation/personalization quality only.

Use a fixed versioned golden pack across P1/P5 and EN/RU/UZ for mathematical/factual correctness, source fidelity, no invented rules/facts, relevance, safe pedagogical usefulness and answer-key boundary. Use internal Academic QA/verified reference answers; this is not Mentor Care.

Exit: quality threshold met and no release-blocking critical factual/math error.

### P2-77 — Mentor Technical Simulation

Goal: validate Mentor Care mechanics without claiming human capacity evidence.

Test entitlement != assignment; assigned/unassigned/waitlist/paused; queue isolation; written judgement; override/audit; second check; handover/absence; safeguarding route; SLA timestamps; P1/P5 scope.

Exit: Mentor Technical GREEN prerequisites pass; no claim about real human capacity.

### P2-78 — 600/10 Concurrency and Service Transitions

Goal: prove technical isolation under scale-shaped synthetic load.

Required: 600 synthetic learners; exactly 10 active mentor scopes; remaining 590 create no routine human queue; concurrent sessions/retries/queues/RLS; Core<->AI transition; mentor assignment/remove/pause; AI outage/fallback; evidence/history preserved.

Exit: exactly 10 human scopes and no cross-user/service-state corruption. This does not prove real production traffic or real mentor capacity.

### P2-79 — Recovery / Rollback / Disaster Rehearsal

Goal: prove failure recovery without manual learner-history repair.

Exercise kill switch mid-flow, deploy rollback, failed isolated migration, interrupted synthetic run, interrupted cleanup, bad/stale content version, expired/stale client, AI outage, recovery and replay.

Exit: clean recovery, synthetic residue = 0, Core remains recoverable.

### P2-80 — Independent A-to-Z Release Audit

Goal: independently re-audit implementation against approved project documents and actual production/repository state.

Recheck Master Implementation Plan, Beta Release Plan, Content Governance, AI Safety Architecture, Mentor Care Operating Model, Annual Roadmap compliance, GitHub<->production schema parity, deployed browser behaviour, rollback/recovery and final legacy protection.

Final verdict remains split:

- Core Engineering: GREEN / NO-GO
- AI Engineering: GREEN / NO-GO / NOT RUN
- Mentor Technical: GREEN / NO-GO / NOT RUN
- Real-world Evidence: PROVEN / UNPROVEN

## Execution order

Foundation: P2-62 -> P2-63 -> P2-64 -> P2-65 -> P2-66

Core: P2-67 -> P2-68 -> P2-69 -> P2-70 -> P2-71 -> P2-72 -> P2-73

Optional layers: P2-74 -> P2-75 -> P2-76 -> P2-77 -> P2-78

Hardening/final audit: P2-79 -> P2-80

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
- P2-71: COMPLETE
- P2-72: COMPLETE
- P2-73: COMPLETE — Core Engineering GREEN
- P2-74: IN PROGRESS
- P2-75..P2-80: NOT STARTED

Engineering readiness now:

- Core Engineering: GREEN
- AI Engineering: NOT YET GREEN — P2-74 started; P2-75/P2-76 pending
- Mentor Technical: NOT RUN for this cycle
- Real-world Evidence: UNPROVEN

## Change Log

### 2026-09-14 — v1.5

- Closed P2-71 at `418a8aad9b22769743eea51715f119e6bfab3b8c` after rollback-only failure/adversarial coverage passed for offline/retry/idempotency, stale actions, duplicate submit/finalize, timed expiry/integrity, cross-user denial, P1/P5 leakage attempts, protected-answer boundaries and clean rollback.
- Closed P2-72 at `668ed7f32874425201b318abfbf6fcc2bea38649`. Isolated database fingerprints and browser storage sentinels proved synthetic-induced mutation = 0 for Practice/Tours/ratings/certificates/history/localStorage/pending operations. Production read-only smoke found zero synthetic-linked legacy rows, zero forbidden Exam Prep legacy DML paths and zero Exam Prep triggers on protected legacy tables.
- Closed P2-73 at `ea2a3a83e6ec1c04711eb09a1e405a98fca5a331`. Three full release-candidate rehearsals on the same SHA passed with deterministic seeds 27301, 27302 and 27303, including Stage 0 -> 6, all 81 skills, adversarial paths, 600/10 isolation, browser journey, EN/RU/UZ, legacy preservation and zero synthetic residue.
- Core Engineering is GREEN. This is an engineering result only; real learner UX/calibration/support/capacity evidence remains UNPROVEN.
- Began P2-74 AI Shadow Safety. Production learner AI remains disabled; AI Assist and Mentor Care remain independently gated.

### 2026-09-14 — v1.4

- Closed P2-70 after current-schema CI and merge to `main` at `7be28732675c1e620ee0ae1b2acfd002e50d4856`.
- Applied narrow fail-closed P5 retest holdout alignment only after confirming exactly three target flags and zero affected historical non-holdout session snapshots.
- Post-migration verification confirmed 45 P1 + 36 P5 skills, no holdout mismatch, no affected session snapshots and unchanged controlled-beta/AI/Mentor configuration.
- Began P2-71.

### 2026-09-14 — v1.3

- Closed P2-68 after accelerated academic-time harness and weekly-plan ownership hotfix passed full current-schema CI and production verification.
- Closed P2-69 at `3a44e9b71f783c042bbe5a73feb57d28dcbcdb05` after full rollback-only Stage 0 -> 6 Core journey passed with independent P1/P5 progression, correction/remediation/delayed retest, mixed evidence, timed/full-paper readiness, zero synthetic residue and unchanged legacy state.
- Began P2-70 content lifecycle/runway validation.

### 2026-09-14 — v1.2

- Closed P2-63 through P2-67 after full current-schema CI and production verification.
- P2-67 merged at `b9890cd9e0ee857313683cd3a5a4d3cb8003a53c`.
- Canonical synthetic scenario set `p2_67_canonical_v2_0` contains 15 canonical profiles + 18 adversarial variants with zero locale/structure violations and no persistent synthetic learner runtime.
- Began P2-68. Virtual time is synthetic academic chronology only; real learners and strict timed-assessment security remain on real server time.

### 2026-09-14 — v1.1

- Marked P2-62 complete after roadmap/rebaseline merge.
- Clarified that synthetic learner/operational evidence never replaces real weekly/release evidence, while explicit engineering validation artifacts may satisfy only their own engineering prerequisites.
- Began P2-63 structural real/synthetic separation.

### 2026-09-14 — v1.0

- Switched development from waiting for real Wave 1/2 activity to a separate repeatable synthetic-validation track.
- Kept real beta evidence separate and unproven.
- Added bidirectional evidence/privacy firewall, fixed synthetic GREEN criteria, AI explanation-quality evaluation, incremental evidence simulation, RU/UZ/EN cross-cutting coverage and production scope-aware legacy protection.
- Clarified that 600/10 proves technical isolation only, not real mentor capacity or production traffic.