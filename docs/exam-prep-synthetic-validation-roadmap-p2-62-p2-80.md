# Exam Prep Synthetic Validation Roadmap — P2-62 through P2-80

Status: ACTIVE / source of truth for the next Exam Prep development cycle.

Owner decision: 2026-09-14.

This document exists so the plan survives chat/context limits. It must remain the canonical working roadmap until P2-80 is complete. The roadmap may be corrected when new evidence requires it, but changes must be explicit: update this file, record the reason in Change Log, and do not silently reuse or skip stage numbers.

## Non-negotiable safety rules

- iClub is live. Existing learner data, legacy Practice/Tours, ratings, certificates, history, localStorage and pending operations are protected.
- Real beta learners are never reused as synthetic test identities.
- Synthetic evidence must never satisfy a real learner weekly review, Wave expansion gate, readiness gate or real-world release evidence.
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

- explicit synthetic run/evidence classification;
- real expansion/weekly/readiness gates reject synthetic evidence;
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

- P2-62: IN PROGRESS
- P2-63..P2-80: NOT STARTED

## Change Log

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
