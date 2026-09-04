# Exam Prep P0-15 / P0-16 Release Readiness Record

**Program:** `math_as_p1_p5`  
**Canonical release branch:** `main`  
**Assessment / amendment date:** 2026-09-04  
**Overall status:** **APPROVED FOR CORE-FIRST CONTROLLED BETA — NOT YET ACTIVATED**  
**Controlled-beta capacity:** **up to 12 learners**  
**Current staged roster:** **3 Core candidates, wave 1**  
**Learner consent:** **0 / 3 granted**  
**AI Assist live authorization:** **NO**  
**Mentor Care live authorization:** **NO**

> **2026-09-04 operational amendment.** Earlier wording in this record that required an exactly filled, pre-stratified 12-person Core / AI Assist / Mentor Care cohort is superseded for the initial canary. Capacity remains at most 12, but the first controlled-beta wave may start with at least 3 explicitly consented Core learners. AI Assist and Mentor Care representation is deferred until the later waves that actually test those capabilities. Their independent activation gates remain unchanged.

## 1. Current release decision

The current governed interpretation is:

- `planned_size=12` is cohort **capacity**, not a requirement to fill all seats;
- the initial controlled beta may start **Core-only with at least 3 real, allowlisted, explicitly consented learners**;
- the current production roster already contains **3 Core candidates in wave 1**;
- no artificial AI Assist or Mentor Care placeholders are required to approve the initial Core canary;
- additional learners may be added later as **future-wave candidates**, up to remaining capacity;
- every additional learner must separately consent and be approved before activation;
- AI Assist activation remains blocked until the AI runtime/readiness gate passes;
- Mentor Care activation remains blocked until assignment/capacity/readiness gates pass;
- Project Owner approval is not learner consent;
- any live integrity/security failure or active-learner consent revocation retains the fail-closed pause/rollback path;
- P1-04 / AI remains blocked until deterministic beta stability evidence exists.

This amendment changes beta enrollment/release sequencing only. It does **not** lower academic evidence standards, content-runway requirements, P1/P5 isolation, rollback requirements, or readiness definitions.

## 2. Technical evidence

### Historical P0-15 / P0-16 recertification

- `P0-15 Isolated Alpha` run `33856650388` — **SUCCESS**.
- Earlier `P0-16 Controlled Beta Gate` recertification — **SUCCESS** and preserved rollback / mixed-service isolation.

### Core-first convergence evidence

The Core-first change was implemented and regression-tested on `exam-prep-p0-host`, then squash-merged through PR **#13** into `main` as commit `7953563de0c4b57b4e49055492c448124c7aaf85`.

Verified gates include:

- `P0-16 Controlled Beta Gate` run `33900000335` — **SUCCESS**;
- `P1-01 Weekly Governance Gate` run `33899931900` — **SUCCESS**;
- `P0-14 Host Regression` run `33900747278` — **SUCCESS**;
- existing P0-15, P1-02 content runway and P1-03 timed-paper gates remained GREEN during the release line.

The new P0-16 regression proves all of the following in one rolled-back synthetic path:

1. capacity 12 with only 3 initial Core learners;
2. 3 / 3 explicit consent required before approval;
3. initial Core-only cohort approval without AI/Mentor placeholders;
4. wave 1 activates only those Core learners;
5. an additional Core learner can be added later as a future-wave candidate, consented, approved and activated;
6. an AI candidate may be staged/approved later while AI activation remains blocked when runtime readiness is not green;
7. zero synthetic residue after rollback.

The host regression additionally proves that an allowlisted learner can see the beta invitation **before Core entitlement**, while merely viewing/opening the invitation never grants consent automatically. Grant/revoke require explicit learner actions.

## 3. Current production snapshot before deployment of the final overlays

Production was re-read after the GitHub merge and before applying the final self-consent/Core-first overlays:

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

No learner access has been granted. P1-03 remains dormant infrastructure.

## 4. Source-of-truth reconciliation

The governed release line has been squash-merged into **`main`**. `main` is now the repository source of truth for the Core-first capacity, consent, incremental-enrollment and invitation UI changes.

The previous working branch `exam-prep-p0-host` was used only to prove the release line and is no longer the canonical target for new work after the merge.

## 5. Human / learner gates

**Project Owner release decision:** APPROVED FOR CONTROLLED BETA.  
**Learner consent gate:** NOT COMPLETE — currently **0 / 3**.

Mandatory interpretation:

**CONTROLLED-BETA CAPACITY = UP TO 12**  
**INITIAL LIVE CANARY = CURRENT 3 CORE LEARNERS, AFTER 3 / 3 CONSENT**  
**AI ASSIST LIVE ACCESS = NOT AUTHORIZED / INDEPENDENT GATE**  
**MENTOR CARE LIVE ACCESS = NOT AUTHORIZED / INDEPENDENT GATE**  
**P1-04 = STILL BLOCKED BY DETERMINISTIC-BETA STABILITY PREREQUISITE**

## 6. Authorized next action

The next operational sequence is:

1. apply the tested learner self-consent, Core-first/incremental and incremental-consent overlays to production while the feature remains fail-closed;
2. verify production still has the same 3 candidates, zero active entitlements, `rollout_state=off` and `kill_switch=true`;
3. verify the authenticated invitation/consent RPCs are available;
4. obtain **explicit 3 / 3 learner consent** through the authenticated learner flow;
5. approve the current cohort;
6. activate **wave 1 only**, containing the 3 Core learners;
7. immediately verify capability isolation, legacy integrity and zero AI/Mentor leakage;
8. begin the first-72h P1-01 monitoring window;
9. do not activate AI Assist or Mentor Care until their independent prerequisites and later release decisions pass.
