# Exam Prep Synthetic Validation Roadmap — P2-62 through P2-80

Status: ACTIVE / source of truth for the next Exam Prep development cycle.

Owner decision: 2026-09-14.

This document exists so the plan survives chat/context limits. It must remain the canonical working roadmap until P2-80 is complete. The roadmap may be corrected when new evidence requires it, but changes must be explicit: update this file, record the reason in Change Log, and do not silently reuse or skip stage numbers.

## Non-negotiable safety rules

- iClub is live. Existing learner data, legacy Practice/Tours, ratings, certificates, history, localStorage and pending operations are protected.
- Real beta learners are never reused as synthetic test identities.
- Synthetic learner/operational evidence must never satisfy a real learner weekly review, real learner readiness gate or real-world release evidence. Explicit engineering validation artifacts may satisfy only the engineering prerequisite they are designed for (for example the existing 600/10 and service-transition validations); they never substitute for the required real weekly reviews or real learner evidence.
- Synthetic identities/seeders must never read, copy or clone real learner PII/evidence to make fixtures "realistic".
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

Synthetic validation must never be presented as proof of:

- real learner UX/usability;
- real population calibration of placement/readiness;
- real retention/support workload;
- real human mentor capacity/calibration;
- real production traffic/peak-load behaviour.

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

Repository:

- repo: `jteshaboev1984-ops/iClub_APP`
- baseline main SHA: `e2dc173d0c325f1550b382f26fbeefaa69d38d31`
- latest completed stage before this roadmap: P2-61

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

Deliverables:

- confirm repository/Supabase baseline and current gates;
- persist this roadmap and GREEN criteria before implementation begins;
- confirm no current synthetic learner residue;
- confirm real beta members/consents/entitlements remain preserved;
- define how real beta is treated while synthetic development proceeds without fabricating real reviews;
- no production learner-data write in this stage.

Exit: baseline and roadmap are version-controlled; safety assumptions are explicit.

### P2-63 — Bidirectional Synthetic Evidence Firewall

Goal: make real/synthetic separation structural, not procedural.

Required:

- explicit synthetic identity/evidence classification before any production-schema synthetic learner data is generated;
- synthetic learner/operational evidence cannot enter real beta membership, consent, weekly-review or learner-readiness paths;
- explicitly designated engineering validation artifacts remain allowed only for their existing engineering validation slots and never replace real weekly reviews;
- synthetic identities/seeders cannot read/clone real learner PII/evidence;
- negative tests in both directions;
- browser roles cannot bypass the boundary.

Exit: contamination tests = 0 in both directions.

### P2-64 — Synthetic Run Registry

Goal: every synthetic row is attributable to a specific validation run.

Each run records at minimum:

- `run_id` using `SV-*` naming, never Wave 1/2 wording;
- scenario-set version;
- Git SHA;
- schema/migration generation;
- deterministic seed;
- capability mode: Core / AI shadow / Mentor technical;
- started/completed/failed timestamps;
- audit result;
- cleanup status.

Exit: ambiguous synthetic provenance = 0.

### P2-65 — Dedicated Synthetic Identities

Goal: stop using any real account as test infrastructure.

Required:

- dedicated synthetic learner identities;
- dedicated synthetic mentor identities where needed;
- fixtures generated from canonical scenario definitions, never cloned real users;
- RLS/authorization tests prove isolation from real users.

Exit: synthetic identities cannot access real private learner data.

### P2-66 — Reusable Seed -> Run -> Audit -> Cleanup Engine

Goal: replace one-off cleanup with repeatable per-run lifecycle.

Required:

- seed only data owned by a known `run_id`;
- run tests;
- audit owned rows and invariants;
- cleanup only rows owned by that run;
- fail closed on ambiguous ownership;
- cleanup idempotency;
- zero residue assertion;
- summary audit event;
- preserve real beta controls and legacy data.

Exit: the same synthetic run can be created, audited, cleaned and recreated with zero residue/manual SQL repair.

### P2-67 — Canonical Scenario Matrix v2

Goal: version the complete synthetic learner scenario set before broad execution.

Include canonical 15 profiles plus adversarial variants covering at least:

- P1 strong / P5 weak;
- P1 weak / P5 strong;
- both weak / foundation placement;
- advanced placement;
- partial coverage;
- failed learning/correction;
- failed/delayed/fresh retest;
- interrupted learner and recovery;
- exam profile/session/target/time revision;
- stale weekly plan/action;
- offline/retry/idempotency;
- integrity events;
- Core/AI/Mentor service transitions.

EN/RU/UZ is a cross-cutting requirement for applicable learner-facing scenarios.

Exit: scenario set is explicit, versioned and reproducible.

### P2-68 — Incremental Evidence and Virtual-Time Harness

Goal: test the 36-week/stage lifecycle quickly without faking causal evidence.

Rules:

- virtual time exists only inside synthetic validation;
- do not change normal production/server time for real users;
- generate the intermediate evidence chain in order;
- a stage cannot advance merely because time moved forward;
- delayed retest/freshness/staleness windows must be exercised with actual intermediate events.

Exit: full synthetic year can run in accelerated time while preserving evidence causality.

### P2-69 — Full Stage 0 -> 6 Core Simulation

Goal: exercise deterministic Core end to end.

Cover:

- profile/exam setup;
- diagnostic and placement;
- weekly plans;
- learning/correction;
- delayed fresh retest;
- mixed transfer/mastery;
- syllabus completion;
- timed consolidation;
- full papers/readiness;
- final calibration;
- independent P1/P5 state throughout.

Exit: governed Stage 0 -> 6 flows are reproducible with correct evidence.

### P2-70 — Content Lifecycle / Runway Validation

Goal: prove content is connected to runtime rather than merely present.

For all 45 P1 + 36 P5 skills verify governed availability and linkage for applicable:

- diagnostic;
- learning;
- correction;
- fresh retest;
- written evidence;
- mixed ownership/transfer;
- timed/full-paper linkage;
- protected reserve/holdout;
- RU/UZ/EN QA;
- runway hard floor.

Exit: no orphan/dead-end canonical skill and no reserve/runway policy violation.

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

Approach:

- isolated CI: complete fixture before/after row fingerprints/hashes;
- live production smoke: scope-aware fingerprints and proof that synthetic mechanisms have no write path into legacy tables/state;
- do not require whole-production-table checksum equality because legitimate live users may change legacy rows concurrently.

Protect Practice/Tours, ratings, certificates, histories, localStorage and pending operations.

Exit: synthetic-induced legacy mutation = 0.

### P2-73 — Core Engineering Dress Rehearsal

Goal: earn Core Engineering GREEN.

Run three consecutive complete clean rehearsals on the same candidate SHA using different deterministic seeds:

- clean start;
- canonical scenarios;
- Stage 0 -> 6;
- failures/adversarial paths;
- service transitions relevant to Core;
- audit;
- cleanup;
- rollback/replay.

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

Feed identical raw learner evidence through Core-only and Core+AI paths and compare:

- placement;
- P1/P5 state;
- mastery;
- stages;
- correction/retest eligibility;
- readiness state.

Exit: deterministic academic-state diff = 0.

### P2-76 — AI Explanation Quality Evaluation

Goal: evaluate the only area AI is allowed to improve: explanation/personalization quality.

Use a fixed versioned golden evaluation pack across P1/P5 and EN/RU/UZ covering:

- mathematical/factual correctness;
- source fidelity;
- no invented rules/facts;
- relevance to the actual learner evidence/question;
- safe pedagogical usefulness;
- answer-key boundary.

Use internal Academic QA/verified reference answers; this is not Mentor Care.

Exit: AI quality threshold is met and no release-blocking critical factual/math error remains.

### P2-77 — Mentor Technical Simulation

Goal: validate Mentor Care mechanics without claiming human capacity evidence.

Test synthetic mentor flows:

- entitlement != assignment;
- assigned/unassigned/waitlist/paused;
- queue creation/isolation;
- written judgement;
- override with audit;
- second check;
- handover/absence;
- safeguarding route;
- SLA timestamps;
- P1/P5 scope.

Exit: Mentor Technical GREEN prerequisites pass; no claim about real human capacity.

### P2-78 — 600/10 Concurrency and Service Transitions

Goal: prove technical isolation under scale-shaped synthetic load.

Required:

- 600 synthetic learners;
- exactly 10 active mentor assignments/scopes;
- remaining 590 create no routine human queue;
- concurrent sessions/retries/queues/RLS checks;
- Core <-> AI capability transition;
- mentor assignment/remove/pause;
- AI outage/fallback;
- evidence/history preserved through service changes.

Exit: exactly 10 human scopes and no cross-user/service-state corruption.

This does not prove real production traffic profile or real mentor capacity.

### P2-79 — Recovery / Rollback / Disaster Rehearsal

Goal: prove failure recovery without manual learner-history repair.

Exercise:

- kill switch mid-flow;
- deploy rollback;
- failed migration in isolated validation;
- interrupted synthetic run;
- interrupted cleanup;
- bad/stale content version;
- expired/stale client;
- AI outage;
- recovery and replay.

Exit: rollback/recovery is clean, synthetic residue = 0, Core remains recoverable.

### P2-80 — Independent A-to-Z Release Audit

Goal: independently re-audit implementation against the approved project documents and actual production/repository state.

Recheck:

- Master Implementation Plan;
- Beta Release Plan;
- Content Governance;
- AI Safety Architecture;
- Mentor Care Operating Model;
- Annual Roadmap compliance;
- GitHub <-> production schema parity;
- deployed browser behaviour;
- rollback/recovery;
- final legacy protection.

Final verdict must be split, never collapsed into one GREEN:

- Core Engineering: GREEN / NO-GO
- AI Engineering: GREEN / NO-GO / NOT RUN
- Mentor Technical: GREEN / NO-GO / NOT RUN
- Real-world Evidence: PROVEN / UNPROVEN

## Execution order

Do not jump directly to mass synthetic data creation.

Mandatory foundation first:

P2-62 -> P2-63 -> P2-64 -> P2-65 -> P2-66

Then Core:

P2-67 -> P2-68 -> P2-69 -> P2-70 -> P2-71 -> P2-72 -> P2-73

Then optional layers:

P2-74 -> P2-75 -> P2-76 -> P2-77 -> P2-78

Then hardening/final audit:

P2-79 -> P2-80

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
- P2-74: COMPLETE
- P2-75: COMPLETE
- P2-76: COMPLETE — AI Engineering GREEN
- P2-77: COMPLETE — Mentor Technical GREEN
- P2-78: IN PROGRESS
- P2-79..P2-80: NOT STARTED

## Change Log

### 2026-09-15 — v1.6

- Closed P2-74 after AI Shadow Safety merged through PR #69 to `main` at `d2e61dba29aaabe5c96f687f22669c21c37ff4d9`. The shadow gate proved assessment blackout, server-built context, source allowlisting/no-source fallback, answer-key protection, prompt-injection/secret boundaries, rate/budget/timeout/fallback controls and EN/RU/UZ without enabling a real provider or changing learner academic state.
- Closed P2-75 after PR #70 merged to `main` at `f25bbc8c78d0ebe2243b81dc630691ee215cd089`. Identical raw evidence produced deterministic academic-state diff = 0 across Core-only and Core+AI for placement, P1/P5 state, mastery, stages, correction/retest eligibility and readiness; production AI remained OFF.
- Closed P2-76 after PR #71 merged to `main` at `86a54036fabf96c7adf655e4c42f518dcb439d9d`. The fixed P1/P5 EN/RU/UZ golden evaluation passed 18/18 with zero critical factual/math failures. The successful funded run used approximately $0.002683 and the earlier fail-fast calibration approximately $0.000288; ordinary CI remains configured not to make paid provider calls. AI Engineering is GREEN, but real learner UX/learning impact remains UNPROVEN and production learner AI remains OFF.
- Closed P2-77 after PR #72 merged to `main` at `50bf194c6257c2f92a7b7424fb5ef5549c4f323c`. Exact-main Mentor Technical workflow `34930794936` passed, and the exact-main P2-73 dress rehearsal `34930794972` passed all three seeds 27301/27302/27303. Governed production migrations were applied additively; post-migration verification kept Core ON, AI OFF, Mentor OFF, AI generation OFF/shadow, zero active synthetic identities, zero Mentor Care entitlements and zero active mentor assignments. Mentor Technical is GREEN, but real human mentor capacity/calibration remains UNPROVEN.
- Began P2-78 600/10 Concurrency and Service Transitions. The non-negotiable service law remains: 600 Exam Prep learners with 10 active Mentor Care assignments means exactly those 10 human scopes; the other 590 must generate no routine mentor queue/SLA. P2-78 remains synthetic/isolated and does not authorize Mentor Care or AI for real learners.

### 2026-09-14 — v1.5

- Closed P2-71 after the rollback-only failure/adversarial campaign passed and merged to `main` at `418a8aad9b22769743eea51715f119e6bfab3b8c`. It covered offline/retry/idempotency, stale actions, duplicate submit/finalize, timed expiry/integrity, cross-user denial, P1/P5 leakage attempts, protected-answer boundaries and clean rollback.
- Closed P2-72 after Legacy Preservation Firewall v2 merged to `main` at `668ed7f32874425201b318abfbf6fcc2bea38649`. Isolated database fingerprints and browser storage sentinels showed synthetic-induced mutation = 0; production read-only smoke found zero synthetic-linked legacy rows, zero forbidden Exam Prep legacy DML paths and zero Exam Prep triggers on protected legacy tables.
- Closed P2-73 after the three-seed Core Engineering Dress Rehearsal merged to `main` at `ea2a3a83e6ec1c04711eb09a1e405a98fca5a331`. The same candidate SHA passed seeds 27301, 27302 and 27303 across Stage 0 -> 6, all 81 skills, adversarial paths, 600/10 isolation, browser journey, EN/RU/UZ, legacy preservation and zero synthetic residue.
- Core Engineering is GREEN. This remains an engineering result only; real learner UX/calibration/support/capacity evidence is still UNPROVEN.
- Began P2-74 AI Shadow Safety. Production learner AI remains disabled and no real-user AI enablement is authorized by this status change.

### 2026-09-14 — v1.4

- Closed P2-70 after PR #64 passed current-schema CI and merged to `main` at `7be28732675c1e620ee0ae1b2acfd002e50d4856`.
- Applied the narrow, fail-closed production alignment migration `exam_prep_p2_70_protected_retest_holdout_alignment_v1`. It changed only the three identified early P5 assessment-item source flags after confirming exactly three false targets and zero affected historical non-holdout session snapshots.
- Post-migration verification confirmed 45 P1 and 36 P5 canonical skills, zero published holdout-policy mismatches, zero affected session snapshots, and unchanged controlled-beta/AI/Mentor configuration.
- Began P2-71 failure and adversarial campaign. Its timed-security cases remain separate from P2-69, which tested normal timed progression only.

### 2026-09-14 — v1.3

- Closed P2-68 after the accelerated academic-time harness and its weekly-plan ownership hotfix both passed full current-schema CI and production verification. The hotfix changed only how synthetic weekly-plan items resolve their owner; real learner time and legacy state remained unchanged.
- Closed P2-69 after the full rollback-only Stage 0 -> 6 Core synthetic learner journey passed, including independent P1/P5 progression, correction/remediation/delayed retest, mixed evidence, timed/full-paper readiness, zero synthetic residue and unchanged legacy state. P2-69 merged through PR #62; resulting `main` SHA is `3a44e9b71f783c042bbe5a73feb57d28dcbcdb05`.
- Began P2-70 content lifecycle/runway validation. The read-only audit found three early P5 retest source items whose governed metadata was already `reserve` + `withheld` but whose assessment-item `is_holdout` snapshot flag remained false. No historical session snapshot existed for those three questions. A narrow fail-closed alignment migration and a full 81-skill content lifecycle matrix were staged for validation before any production change.

### 2026-09-14 — v1.2

- Closed P2-63 through P2-67 after full current-schema CI and production verification.
- P2-67 merged through PR #60; resulting `main` SHA is `b9890cd9e0ee857313683cd3a5a4d3cb8003a53c`.
- Canonical synthetic scenario set `p2_67_canonical_v2_0` is active with 15 canonical profiles + 18 adversarial variants, zero locale/structure violations, and no persistent synthetic learner runtime.
- Began P2-68 on a separate branch. Virtual time is explicitly synthetic academic chronology only; real learners and strict timed-assessment security remain on real server time.

### 2026-09-14 — v1.1

- Marked P2-62 complete after the roadmap/rebaseline PR merged to `main`.
- Corrected an overbroad rule: synthetic learner/operational evidence can never replace real weekly/release evidence, while explicitly designated engineering validation artifacts (such as the existing 600/10 and service-transition matrices) may still satisfy only their own engineering prerequisite in the expansion gate.
- Began P2-63 with structural bidirectional real/synthetic identity boundaries before any new production-schema synthetic learner data is generated.

### 2026-09-14 — v1.0

- Switched development strategy from waiting for real Wave 1/2 activity to a separate repeatable synthetic-validation track.
- Kept real beta evidence separate and unproven.
- Added bidirectional evidence/privacy firewall requirement.
- Added fixed Synthetic GREEN criteria before testing.
- Added AI explanation-quality evaluation.
- Clarified that 600/10 tests technical isolation, not real mentor capacity or real traffic.
- Required incremental evidence simulation rather than timestamp-only time travel.
- Made RU/UZ/EN cross-cutting for learner-facing validation.
- Replaced naive whole-production checksum rule with isolated full fingerprints plus production scope-aware legacy protection.