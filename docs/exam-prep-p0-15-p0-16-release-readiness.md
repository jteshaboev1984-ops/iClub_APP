# Exam Prep P0-15 / P0-16 Release Readiness Record

**Program:** `math_as_p1_p5`  
**Canonical release branch:** `main`  
**Assessment / amendment date:** 2026-09-05  
**Overall status:** **APPROVED FOR CORE-FIRST CONTROLLED BETA — NOT YET ACTIVATED**  
**Controlled-beta capacity:** **up to 12 learners**  
**Current staged roster:** **3 Core candidates, wave 1**  
**Learner consent:** **0 / 3 granted**  
**Governed content runway:** **AW1–12 GREEN for both P1 and P5**  
**AI Assist live authorization:** **NO**  
**Mentor Care live authorization:** **NO**

> **2026-09-04 operational amendment.** Earlier wording that required an exactly filled, pre-stratified 12-person Core / AI Assist / Mentor Care cohort is superseded for the initial canary. Capacity remains at most 12, but the first controlled-beta wave may start with at least 3 explicitly consented Core learners. AI Assist and Mentor Care representation is deferred until later waves that actually test those capabilities. Their independent activation gates remain unchanged.

## 1. Current release decision

The governed interpretation is:

- `planned_size=12` is cohort **capacity**, not a requirement to fill all seats;
- the initial controlled beta may start **Core-only with at least 3 real, allowlisted, explicitly consented learners**;
- the production roster contains **3 Core candidates in wave 1**;
- no artificial AI Assist or Mentor Care placeholders are required for the initial Core canary;
- additional learners may be added later as **future-wave candidates**, up to remaining capacity;
- every additional learner must separately consent and be approved before activation;
- AI Assist activation remains blocked until its independent runtime/readiness gate passes;
- Mentor Care activation remains blocked until assignment/capacity/readiness gates pass;
- Project Owner approval is not learner consent;
- any live integrity/security failure or active-learner consent revocation retains the fail-closed pause/rollback path;
- P1-04 / AI remains blocked until deterministic beta stability evidence exists.

This amendment changes beta enrollment/release sequencing only. It does **not** lower academic evidence standards, content-runway requirements, P1/P5 isolation, rollback requirements, or readiness definitions.

## 2. Technical evidence

### P0 / Core-first release line

- `P0-15 Isolated Alpha` run `33856650388` — **SUCCESS**.
- `P0-16 Controlled Beta Gate` run `33900000335` — **SUCCESS**.
- `P1-01 Weekly Governance Gate` run `33899931900` — **SUCCESS**.
- `P0-14 Host Regression` run `33900747278` — **SUCCESS**.
- Core-first convergence was squash-merged through PR **#13** into `main` as commit `7953563de0c4b57b4e49055492c448124c7aaf85`.

The controlled-beta regression proves:

1. capacity 12 with only 3 initial Core learners;
2. 3 / 3 explicit learner consent required before approval;
3. initial Core-only cohort approval without AI/Mentor placeholders;
4. wave 1 activates only those Core learners;
5. later learners can be added as future-wave candidates and must independently consent/approve;
6. AI candidates can be staged while AI activation remains blocked until AI readiness is green;
7. zero synthetic residue after rollback.

The host regression additionally proves that an allowlisted learner can see the beta invitation **before Core entitlement**, while merely viewing/opening the invitation never grants consent automatically. Grant/revoke require explicit authenticated learner actions.

### P1-02 governed content runway

Production verification on **2026-09-05** confirms contiguous governed runway through **AW12**:

| Release window | P1 | P5 | State |
|---|---:|---:|---|
| AW1–4 | 5 / 5 skills ready | 4 / 4 skills ready | GREEN |
| AW5–8 | 8 / 8 skills ready | 6 / 6 skills ready | GREEN |
| AW9–12 | 8 / 8 skills ready | 6 / 6 skills ready | GREEN |

At `active_week_no=9`, both components report `ready_through_aw=12`, `ahead_weeks=4`, `hard_floor_2w_green=true` and `target_4w_green=true`; the global runway is therefore GREEN for both the 2-week hard floor and the 4-week target.

The final AW9–12 P5 content was published through the existing governed content-floor trigger in two isolated versions:

- `p5_aw09_12_data_v1`: DAT-05 / DAT-03 / DAT-07 — **21 governed questions, 3 written tasks, 8 assessments**;
- `p5_aw09_12_count_prob_v1`: CNT-05 / PRO-02 / PRO-04 — **21 governed questions, 3 written tasks, 8 assessments**.

All new `public.questions` rows remain `draft + inactive`; production verification found **0 legacy-active rows** from these packs. No beta entitlement or feature state was changed by content publication.

## 3. Current production snapshot

| Control | Observed state |
|---|---:|
| cohort | `math_as_p1_p5_beta_2026_09_01` |
| cohort status | `draft` |
| cohort capacity | `12` |
| current wave | `0` |
| staged members | `3` |
| Core candidates | `3` |
| consent grants | `0 / 3` |
| `rollout_state` | `off` |
| `core_enabled` | `false` |
| `ai_enabled` | `false` |
| `mentor_enabled` | `false` |
| `kill_switch` | `true` |
| active Exam Prep entitlements | `0` |
| governed runway | `AW1–12 GREEN P1 + P5` |

No learner access has been granted. P1-03 remains dormant infrastructure.

## 4. Source of truth

**`main` is the repository source of truth.** It contains the Core-first capacity/consent/incremental-enrollment changes and the governed P1-02 content runway through AW12.

The previous `exam-prep-p0-host` branch was a working branch for the earlier release line and is not a canonical target for new work.

## 5. Human / learner gates

**Project Owner release decision:** APPROVED FOR CONTROLLED BETA.  
**Learner consent gate:** NOT COMPLETE — currently **0 / 3**.

Mandatory interpretation:

**CONTROLLED-BETA CAPACITY = UP TO 12**  
**INITIAL LIVE CANARY = CURRENT 3 CORE LEARNERS, AFTER 3 / 3 CONSENT**  
**AI ASSIST LIVE ACCESS = NOT AUTHORIZED / INDEPENDENT GATE**  
**MENTOR CARE LIVE ACCESS = NOT AUTHORIZED / INDEPENDENT GATE**  
**P1-04 = STILL BLOCKED BY DETERMINISTIC-BETA STABILITY PREREQUISITE**

## 6. Next actions

### Human-gated live sequence

1. obtain **explicit 3 / 3 learner consent** through the authenticated learner flow;
2. approve the current cohort;
3. activate **wave 1 only**, containing the 3 Core learners;
4. immediately verify capability isolation, legacy integrity and zero AI/Mentor leakage;
5. begin the first-72h P1-01 monitoring window;
6. do not activate AI Assist or Mentor Care until their independent prerequisites and later release decisions pass.

### Work that may continue safely while consent is pending

- continue **P1-02** governed annual content production ahead of learner need, preserving the 2-week hard floor / 4-week target and prerequisite closure;
- keep P1-03 dormant until Stage 2 timing needs approach;
- keep P1-04 AI blocked until deterministic live-beta stability exists;
- do not infer live readiness from content publication alone and do not alter legacy Tours/Practice/history.
