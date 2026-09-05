# Exam Prep P0-15 / P0-16 Release Readiness Record

**Program:** `math_as_p1_p5`  
**Canonical release branch:** `main`  
**Assessment / amendment date:** 2026-09-05  
**Overall status:** **APPROVED FOR CORE-FIRST CONTROLLED BETA — NOT YET ACTIVATED**  
**Controlled-beta capacity:** **up to 12 learners**  
**Current staged roster:** **3 Core candidates, wave 1**  
**Learner consent:** **0 / 3 granted**  
**Governed content runway:** **AW1–24 GREEN for both P1 and P5**  
**Syllabus Closure / first coverage:** **81 / 81 canonical skills = 100%**  
**P1-03 pre-live depth:** **Stage-2 timed sections + cumulative mini-mocks + Stage-3 full P1/P5 papers + evidence-driven Stage 1→2→3 + fail-closed Stage-3 exit evaluator deployed**  
**Stage 4:** **LOCKED — key-skill registry is pending and contains 0 governed rows**  
**Exam Ready status:** **NOT CLAIMED — requires real learner correction/retest, timed and comparable full-paper evidence**  
**AI Assist live authorization:** **NO**  
**Mentor Care live authorization:** **NO**

> **2026-09-04 operational amendment.** Earlier wording that required an exactly filled, pre-stratified 12-person Core / AI Assist / Mentor Care cohort is superseded for the initial canary. Capacity remains at most 12, but the first controlled-beta wave may start with at least 3 explicitly consented Core learners. AI Assist and Mentor Care representation is deferred until later waves that actually test those capabilities. Their independent activation gates remain unchanged.

## 1. Current release decision

The governed interpretation is:

- `planned_size=12` is cohort **capacity**, not a requirement to fill all seats;
- the initial controlled beta may start **Core-only with at least 3 real, allowlisted, explicitly consented learners**;
- production contains **3 Core candidates in wave 1**;
- no artificial AI Assist or Mentor Care placeholders are required for the initial Core canary;
- later learners may be added as future-wave candidates up to remaining capacity, with separate consent and approval;
- AI Assist and Mentor Care retain independent activation gates;
- Project Owner approval is not learner consent;
- integrity/security failure or active-learner consent revocation retains the fail-closed pause/rollback path;
- P1-04 / AI remains blocked until deterministic beta stability evidence exists.

The academic content runway has reached **100% first coverage / Syllabus Closure content availability**. That is not the same as a learner having exited Stage 3, and it is not an Exam Ready claim. Learner Stage-3 exit requires real user evidence: 100% confirmed canonical coverage, every canonical skill at least L2, explicitly governed key skills at least L3, a comparable full-paper baseline for that component, and no unknown syllabus section.

## 2. Technical evidence

### P0 / Core-first release line

- `P0-15 Isolated Alpha` run `33856650388` — **SUCCESS**.
- `P0-16 Controlled Beta Gate` run `33900000335` — **SUCCESS**.
- `P1-01 Weekly Governance Gate` run `33899931900` — **SUCCESS**.
- `P0-14 Host Regression` run `33900747278` — **SUCCESS**.
- Core-first convergence was squash-merged through PR **#13** into `main` as commit `7953563de0c4b57b4e49055492c448124c7aaf85`.

The controlled-beta regression proves capacity-12/Core-first incremental enrollment, explicit learner consent, isolated Wave 1 activation, later-wave additions, AI activation blocking until readiness, and rollback without synthetic residue. Viewing the authenticated invitation never grants consent automatically.

### P1-02 governed content runway — Syllabus Closure content

Production verification on **2026-09-05** confirms every governed runway window through **AW24** is complete:

| Release window | P1 | P5 | State |
|---|---:|---:|---|
| AW1–4 | 5 / 5 skills ready | 4 / 4 skills ready | GREEN |
| AW5–8 | 8 / 8 skills ready | 6 / 6 skills ready | GREEN |
| AW9–12 | 8 / 8 skills ready | 6 / 6 skills ready | GREEN |
| AW13–16 | 8 / 8 skills ready | 7 / 7 skills ready | GREEN |
| AW17–20 | 6 / 6 skills ready | 5 / 5 skills ready | GREEN |
| AW21–24 | 10 / 10 skills ready | 8 / 8 skills ready | GREEN |

Cumulative governed first coverage is:

- **P1: 45 / 45 = 100%**;
- **P5: 36 / 36 = 100%**;
- **total: 81 / 81 canonical skills = 100%**.

All Exam Prep rows inserted into legacy `public.questions` remain `draft + inactive`; production acceptance found **0 Exam Prep legacy-active rows**. Content publication changed no learner entitlement or feature state.

### P1-03 timed / paper depth — pre-live hardening

P1-03 uses server-authoritative timing, session authorization, feedback firewall, timed finalization/result semantics and official component profiles:

- **P1: 75 marks / 6600 seconds**;
- **P5: 50 marks / 4500 seconds**.

Production hardening includes:

- operational-stage filtering in `get_exam_prep_timed_catalog_safe_v1`;
- independent direct-authorization stage checks in `authorize_exam_prep_timed_safe_v1`;
- fail-closed behavior when authoritative stage state is absent;
- minimum stage mapping: `timed_section=2`, `modified_paper=2`, `diagnostic_full=2`, `full_paper=3`;
- governed written-only publication for timed/paper content without activating legacy `public.questions`;
- machine-readable Stage 1→2→3 transitions;
- post-self-review full-paper score-comparability semantics;
- a fail-closed machine-readable Stage-3 exit evaluator.

#### Operational-stage policy

| Transition | Machine rule |
|---|---|
| Stage 0 → 1 | existing placement/prerequisite Stage-0 gate complete |
| Stage 1 → 2 | no explicit prerequisite blocker **and** confirmed coverage ≥ **15%**, or governed fast-track |
| Stage 2 → 3 | confirmed coverage ≥ **80%**; no calendar auto-advance |
| Stage 3 → 4 | **not auto-enabled**; current automatic maximum remains Stage 3 |

Stage 3 is **Syllabus Closure**. The first comparable full-paper baseline is Stage-3 work / Stage-3 exit evidence, not a Stage-3 entry requirement. Therefore `full_paper min_stage=3` is non-circular.

The operational-transition line passed the full P1-03 migration/regression path before production deployment. Stage 4 remains structurally separate from coverage-only progression.

#### Stage-2 timed sections published

| Component | Assessment | Marks | Strict time | Items | Minimum stage |
|---|---|---:|---:|---:|---:|
| P1 | `p1_stage2_timed_block_01` | 15 | 1320 s | 3 written | 2 |
| P1 | `p1_stage2_timed_block_02` | 15 | 1320 s | 3 written | 2 |
| P5 | `p5_stage2_timed_block_01` | 15 | 1350 s | 3 written | 2 |
| P5 | `p5_stage2_timed_block_02` | 15 | 1350 s | 3 written | 2 |

This is **30 pre-positioned timed-section marks per component**. Each component uses six distinct primary skills across the two short blocks.

#### Stage-2 cumulative mini-mocks published

| Component | Assessment | Marks | Timing rule / limit | Items | Minimum stage |
|---|---|---:|---|---:|---:|
| P1 | `p1_stage2_mini_mock_01` | 20 | proportional / **1760 s** | 4 written | 2 |
| P5 | `p5_stage2_mini_mock_01` | 20 | proportional / **1800 s** | 4 written | 2 |

The mini-mocks use `attempt_kind='modified_paper'`, remain Stage-2 gated, and become score-comparable only under the existing timed-result/self-review rules.

All Stage-2 timed/mini-mock versions are original iClub-authored written-only content and inserted **0** rows into `public.questions`.

### Stage-3 full papers — published in production

The first governed full papers are now pre-positioned behind the existing `full_paper min_stage=3` gate:

| Component | Assessment | Items | Marks | Official time | Syllabus breadth | Contract |
|---|---|---:|---:|---:|---:|---|
| P1 | `p1_stage3_full_paper_01` | 10 written | **75** | **6600 s** | **8 / 8 sections** | `full_paper / official_full / full / strict` |
| P5 | `p5_stage3_full_paper_01` | 7 written | **50** | **4500 s** | **5 / 5 sections** | `full_paper / official_full / full / strict` |

P1 full-paper migration commit `5b9688f911054b8620f2fca6c7b7d7581153f1f0` passed P1-03 run **#61 (`33959305685`)** before production publication.

P5 full-paper migration commit `680b23560ff0ce1a915486bc8afbe56e1ae49fbb` passed P1-03 run **#62 (`33979687999`)** before production publication.

Production acceptance confirms for both papers:

- assessment and content version are `published`;
- timed marks equal rubric marks and official component total;
- timing resolves to the official full-paper duration;
- `min_stage=3`;
- full syllabus-section breadth is present;
- no full-paper rows were inserted into `public.questions`;
- publication created no learner session, evidence, timed result or entitlement.

A finalized written full paper is not treated as finally score-comparable while written review remains pending. Post-self-review comparability is calculated from the persisted timed result plus completed written self-marks.

### Stage-3 exit evaluator — deployed fail closed

Master-plan law for exiting Stage 3 is represented in production by rule `stage3_exit_v1_2026_09_05`:

- canonical coverage = **100%** for the component;
- every canonical skill ≥ **L2**;
- governed key skills ≥ **L3**;
- at least one **comparable official full-paper baseline** for the component;
- all official syllabus sections represented / no unknown section.

The evaluator implementation is intentionally **not** a Stage-4 unlock. It returns evidence counts and a reason code, while `stage4_unlocked=false` remains explicit.

The source plans specify the key-skill threshold but do **not** enumerate a canonical list of key skill codes. No safe production surrogate was found in the existing schema or skill-contract profiles. Therefore:

- `key_registry_status='pending'`;
- `exam_prep_stage3_key_skills` contains **0 governed rows**;
- both P1 and P5 evaluator results are currently `ready=false`, reason `key_registry_pending`;
- automatic progression remains capped at **Stage 3**.

The evaluator and rollback-only matrix were committed atomically in `8bdbe35194c9cefef71bfd02e0967b08bb1141d4`. P1-03 run **#63 (`33980264553`)** passed the existing timed/modified-paper matrix, operational Stage matrix, the new Stage-3 exit matrix and zero-activation residue before production deployment.

The rollback-only evaluator matrix proves:

1. pending/empty key registry fails closed;
2. cross-component key-skill spoofing is rejected;
3. 100% P1 coverage + all L2 + CI-only key L3 still fails until a comparable full baseline exists;
4. a full paper with pending written review does **not** count as comparable;
5. completing governed written self-review makes that synthetic paper comparable;
6. with all closure evidence present the evaluator may report `ready=true` while **still not unlocking Stage 4**;
7. reopening the CI-only key skill to L2 immediately returns `key_l3_incomplete`.

Post-DDL performance lint identified one missing covering index for the new canonical key-skill FK. Migration commit `5385cfa0261f357af87547b374226ee0d50e0e3c` added `exam_prep_stage3_key_skills_program_skill_idx`; P1-03 run **#64 (`33980437025`)** passed the full migration/regression line before production apply. A repeated advisor scan no longer reports that FK as unindexed. The index is currently naturally reported as unused because the governed registry is intentionally empty.

## 3. Current production snapshot

| Control | Observed state |
|---|---:|
| cohort | `math_as_p1_p5_beta_2026_09_01` |
| cohort status | `draft` |
| cohort capacity | `12` |
| current wave | `0` |
| current staged members | `3` |
| Core candidates | `3` |
| consent grants | `0 / 3` |
| consent missing | `3 / 3` |
| `rollout_state` | `off` |
| `core_enabled` | `false` |
| `ai_enabled` | `false` |
| `mentor_enabled` | `false` |
| `kill_switch` | `true` |
| active Exam Prep entitlements | `0` |
| Exam Prep sessions | `0` |
| component placements | `0` |
| weekly plans | `0` |
| evidence events | `0` |
| authoritative stage-state rows | `0` |
| timed attempt results | `0` |
| Stage-2 timed sections | `4` (2 P1 + 2 P5) |
| Stage-2 short-section marks | `30 P1 + 30 P5` |
| Stage-2 cumulative mini-mocks | `2` (P1 + P5) |
| Stage-3 full papers | `2` (P1 + P5) |
| P1 full paper | `10 items / 75 marks / 6600 s / 8 sections` |
| P5 full paper | `7 items / 50 marks / 4500 s / 5 sections` |
| Stage-3 key registry | `pending / 0 rows` |
| automatic stage ceiling | `3` |
| current Stage-3 exit evaluator | `P1=false / P5=false / key_registry_pending` |
| Exam Prep legacy-active questions | `0` |
| governed runway | `AW1–24 GREEN P1 + P5` |
| governed P1 first coverage | `45 / 45 = 100%` |
| governed P5 first coverage | `36 / 36 = 100%` |
| combined first coverage | `81 / 81 = 100%` |

No learner access has been granted. There is still no real learner operational evidence. All timed, mini-mock and full-paper assets remain pre-positioned behind authoritative stage/access gates.

## 4. What is complete — and what is not

**Complete now:** canonical P1/P5 first coverage; governed learning, diagnostic, retest and mixed content; prerequisite closure; Stage-2 timed sections; Stage-2 cumulative mini-mocks; first official-length Stage-3 P1/P5 full papers; evidence-driven Stage 1→2→3 progression; post-self-review score-comparability semantics; and a fail-closed machine-readable Stage-3 exit evaluator.

**Not complete yet:** real learner validation, actual placement accuracy, mastery/correction-loop evidence, delayed-retest retention, real Stage-2 timed performance, real comparable Stage-3 full-paper baselines, governance-approved key-skill registry, learner Stage-3 exit, Stage-4 progression, full-paper reliability across repeated attempts and operational 72-hour beta evidence.

Therefore:

**CONTENT FIRST COVERAGE = GREEN / 81 OF 81**  
**STAGE-2 TIMED DEPTH = PRE-POSITIONED / ACCESS-GATED**  
**STAGE-3 FULL PAPERS = PUBLISHED / ACCESS-GATED**  
**STAGE 1→2→3 POLICY = DEPLOYED / EVIDENCE-DRIVEN**  
**STAGE-3 EXIT EVALUATOR = DEPLOYED / FAIL-CLOSED ON KEY REGISTRY**  
**STAGE 4 = LOCKED**  
**EXAM READY = NOT YET PROVEN**  
**LIVE CONTROLLED BETA = NOT YET ACTIVATED**

## 5. Source of truth and deployment boundary

**`main` is the repository source of truth.** It contains the Core-first capacity/consent/incremental-enrollment changes, governed P1-02 content through AW24 Syllabus Closure, P1-03 timed/full-paper assets, operational Stage 1→2→3 policy and the fail-closed Stage-3 exit evaluator.

The previous `exam-prep-p0-host` branch was a working branch for the earlier release line and is not a canonical target for new work.

The existing Vercel project/configuration remains intentionally **unchanged**. This milestone does not require or authorize Vercel infrastructure restructuring.

## 6. Human / learner gates

**Project Owner release decision:** APPROVED FOR CONTROLLED BETA.  
**Learner consent gate:** NOT COMPLETE — currently **0 / 3**.

Mandatory interpretation:

**CONTROLLED-BETA CAPACITY = UP TO 12**  
**INITIAL LIVE CANARY = CURRENT 3 CORE LEARNERS, AFTER 3 / 3 CONSENT**  
**AI ASSIST LIVE ACCESS = NOT AUTHORIZED / INDEPENDENT GATE**  
**MENTOR CARE LIVE ACCESS = NOT AUTHORIZED / INDEPENDENT GATE**  
**P1-04 = STILL BLOCKED BY DETERMINISTIC-BETA STABILITY PREREQUISITE**

## 7. Next actions

### Human-gated live sequence

1. obtain **explicit 3 / 3 learner consent** through the authenticated learner flow;
2. approve the current cohort;
3. verify approval creates no learner entitlements and feature state remains fail closed before activation;
4. activate **wave 1 only**, containing the 3 Core learners;
5. immediately verify only the 3 Core entitlements are active, AI/Mentor remain zero/off, legacy integrity is unchanged and the kill-switch path remains valid;
6. begin the first real diagnostic → placement → weekly plan → practice → correction → delayed-retest flow;
7. begin the first-72h P1-01 monitoring window;
8. do not activate AI Assist or Mentor Care until their independent prerequisites and later release decisions pass.

### Work that may continue safely while consent is pending

- define and separately approve an **explicit canonical key-skill registry** for P1 and P5 from a documented governance basis; do not infer it from contract-profile labels alone;
- keep Stage 4 locked until that registry is governed, regression-tested and the Stage-3 exit evaluator can consume it without bypasses;
- do not invent numeric Stage-4 timing/improvement thresholds that are not stated in the source plans;
- preserve the 81-skill denominator, P1/P5 firewall and fail-closed release controls;
- keep P1-04 AI blocked until deterministic live-beta stability exists;
- do not infer Exam Ready from content closure or pre-positioned paper content;
- do not alter legacy Tours/Practice/history or the existing Vercel configuration as part of this milestone.
