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
**P1-03 pre-live depth:** **Stage-gated timed infrastructure + first P1/P5 Stage-2 timed blocks published, learner-inaccessible until authoritative Stage 2**  
**Exam Ready status:** **NOT CLAIMED — requires learner evidence, correction/retest performance and timed/full-paper readiness**  
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

The academic runway has reached **Syllabus Closure / first coverage**. This does **not** mean that learners are Exam Ready. Exam Ready still requires real learner diagnostic evidence, placement, weekly-plan execution, correction loops, delayed retests, timed sections, cumulative mini-mocks and full-paper evidence.

## 2. Technical evidence

### P0 / Core-first release line

- `P0-15 Isolated Alpha` run `33856650388` — **SUCCESS**.
- `P0-16 Controlled Beta Gate` run `33900000335` — **SUCCESS**.
- `P1-01 Weekly Governance Gate` run `33899931900` — **SUCCESS**.
- `P0-14 Host Regression` run `33900747278` — **SUCCESS**.
- Core-first convergence was squash-merged through PR **#13** into `main` as commit `7953563de0c4b57b4e49055492c448124c7aaf85`.

The controlled-beta regression proves capacity-12/Core-first incremental enrollment, explicit learner consent, isolated Wave 1 activation, later-wave additions, AI activation blocking until readiness, and rollback without synthetic residue. The authenticated invitation flow also proves that viewing an invitation never grants consent automatically.

### P1-02 governed content runway — Syllabus Closure

Production verification on **2026-09-05** confirms every active governed runway window through **AW24** is complete:

| Release window | P1 | P5 | State |
|---|---:|---:|---|
| AW1–4 | 5 / 5 skills ready | 4 / 4 skills ready | GREEN |
| AW5–8 | 8 / 8 skills ready | 6 / 6 skills ready | GREEN |
| AW9–12 | 8 / 8 skills ready | 6 / 6 skills ready | GREEN |
| AW13–16 | 8 / 8 skills ready | 7 / 7 skills ready | GREEN |
| AW17–20 | 6 / 6 skills ready | 5 / 5 skills ready | GREEN |
| AW21–24 | 10 / 10 skills ready | 8 / 8 skills ready | GREEN |

Cumulative governed first coverage is now:

- **P1: 45 / 45 = 100%**;
- **P5: 36 / 36 = 100%**;
- **total: 81 / 81 canonical skills = 100%**.

The AW21–24 closure is prerequisite-closed and completes the remaining production prerequisite graph:

- P1: `COO-05/06`, `DIF-05/06/07`, `INT-01/02/03/04/05`;
- P5: `DAT-08/09/10`, `NOR-02/03/04/05/06`.

Published governed AW21–24 versions are:

- `p1_aw21_24_coordinate_v1`;
- `p1_aw21_24_diff_apps_v1`;
- `p1_aw21_24_integration_core_v1`;
- `p1_aw21_24_integration_apps_v1`;
- `p5_aw21_24_dat08_v1`;
- `p5_aw21_24_dat09_v1`;
- `p5_aw21_24_dat10_v1`;
- `p5_aw21_24_nor02_03_v1`;
- `p5_aw21_24_nor04_05_v1`;
- `p5_aw21_24_nor06_v1`.

Production acceptance confirms all ten versions are `published` and their required skills pass `exam_prep_skill_content_ready_v1`.

All Exam Prep rows inserted into legacy `public.questions` remain `draft + inactive`; production acceptance found **0 Exam Prep legacy-active rows**. Content publication changed no learner entitlement or feature state.

### P1-03 timed / paper depth — pre-live hardening

P1-03 already contained server-authoritative timing, session authorization, feedback firewall, timed finalization/result semantics and official component profiles (**P1: 75 marks / 6600 seconds; P5: 50 marks / 4500 seconds**). Before paper content was added, production had zero timed contracts/items/attempts.

Pre-live hardening now adds:

- operational-stage filtering to `get_exam_prep_timed_catalog_safe_v1`;
- an independent direct-authorization stage check in `authorize_exam_prep_timed_safe_v1`;
- fail-closed behavior when authoritative stage state is absent;
- minimum stage mapping: `timed_section=2`, `modified_paper=2`, `diagnostic_full=2`, `full_paper=3`;
- a narrowly scoped written-only content publication path for fully governed timed/paper versions while preserving the original P1-02 question floor for versions that contain question metadata.

P1-03 CI run **#50 (`33957175238`)** passed the stage-gate behavioral matrix and zero-activation residue. After written-only timed content support, P1-03 CI run **#52 (`33957557924`)** passed the full migration line, AW1–24 runway regression, Stage-1/Stage-2 access behavior, timed flow and zero-activation checks.

The first two learner-inaccessible Stage-2 timed sections are published in production:

| Component | Assessment | Marks | Strict time | Items | Minimum stage |
|---|---|---:|---:|---:|---:|
| P1 | `p1_stage2_timed_block_01` | 15 | 1320 s (22 min) | 3 written | 2 |
| P5 | `p5_stage2_timed_block_01` | 15 | 1350 s (22 min 30 s) | 3 written | 2 |

These versions are written-only and inserted **0** rows into `public.questions`. They are content-prepositioning only: current production has **0 stage-state rows, 0 timed attempts/results and 0 learner runtime evidence**, so they cannot be surfaced to a real learner yet.

A full-paper publication is deliberately **deferred**. Current stage law requires a first comparable full-paper baseline for Stage 3 while the timed access map currently requires Stage 3 for `full_paper`; `diagnostic_full` is intentionally non-comparable. That Stage-2→Stage-3 transition must be made machine-readable and non-circular before any real full-paper path is authorized.

## 3. Current production snapshot

| Control | Observed state |
|---|---:|
| cohort | `math_as_p1_p5_beta_2026_09_01` |
| cohort status | `draft` |
| cohort capacity | `12` |
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
| timed written self-marks | `0` |
| published Stage-2 timed sections | `2` (P1 + P5) |
| Stage-2 timed-section marks | `15 P1 + 15 P5` |
| Exam Prep legacy-active questions | `0` |
| governed runway | `AW1–24 GREEN P1 + P5` |
| governed P1 first coverage | `45 / 45 = 100%` |
| governed P5 first coverage | `36 / 36 = 100%` |
| combined first coverage | `81 / 81 = 100%` |

No learner access has been granted. P1-01 therefore still has no live operational evidence. P1-03 now has pre-positioned Stage-2 content but remains learner-inaccessible because no learner has reached authoritative Stage 2.

## 4. What Syllabus Closure means — and does not mean

**Complete now:** canonical P1/P5 first coverage, governed learning items, diagnostic/retest/mixed reserves, written tasks, QA states, prerequisite closure and fail-closed publication through AW24; first cross-topic Stage-2 timed sections are also pre-positioned.

**Not complete yet:** real learner validation, actual placement accuracy, mastery/correction-loop evidence, delayed-retest retention, Stage-2 transition evidence, cumulative mini-mock performance, comparable full-paper baseline, full-paper reliability and operational 72-hour beta evidence.

Therefore:

**SYLLABUS CLOSURE = GREEN / 100% FIRST COVERAGE**  
**FIRST STAGE-2 TIMED BLOCKS = PUBLISHED BUT ACCESS-GATED**  
**EXAM READY = NOT YET PROVEN**  
**LIVE CONTROLLED BETA = NOT YET ACTIVATED**

## 5. Source of truth and deployment boundary

**`main` is the repository source of truth.** It contains the Core-first capacity/consent/incremental-enrollment changes, governed P1-02 content through AW24 Syllabus Closure and the current P1-03 pre-live timed hardening/content.

The previous `exam-prep-p0-host` branch was a working branch for the earlier release line and is not a canonical target for new work.

The existing Vercel project/configuration is intentionally left **unchanged**. Deployment continues through the established repository/deployment model; this readiness record does not require or authorize Vercel infrastructure restructuring.

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
3. verify approval did not create entitlements and feature state remains fail-closed before activation;
4. activate **wave 1 only**, containing the 3 Core learners;
5. immediately verify only the 3 Core entitlements are active, AI/Mentor remain zero/off, legacy integrity is unchanged and the kill-switch path remains valid;
6. begin the first real diagnostic → placement → weekly plan → practice → correction → delayed-retest flow;
7. begin the first-72h P1-01 monitoring window;
8. do not activate AI Assist or Mentor Care until their independent prerequisites and later release decisions pass.

### Work that may continue safely while consent is pending

- continue P1-03 exam-readiness depth with additional **Stage-2 timed sections** using skills not overrepresented in block 01;
- after sufficient timed-section breadth, prepare a Stage-2 cumulative mini-mock / modified-paper contract behind the same operational-stage gate;
- do **not** publish or authorize a real `full_paper` until the Stage-2→Stage-3 comparable-baseline circularity is resolved by an explicit machine-readable stage transition;
- preserve the 81-skill denominator, P1/P5 firewall and fail-closed release controls;
- keep P1-04 AI blocked until deterministic live-beta stability exists;
- do not infer Exam Ready from Syllabus Closure or pre-positioned timed content;
- do not alter legacy Tours/Practice/history or the existing Vercel configuration as part of this milestone.
