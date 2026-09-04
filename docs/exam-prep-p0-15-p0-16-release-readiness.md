# Exam Prep P0-15 / P0-16 Release Readiness Record

**Program:** `math_as_p1_p5`  
**Branch:** `exam-prep-p0-host`  
**Evidence baseline commit:** `393526e96886570338e04ed828ced55a4433a077`  
**Assessment date:** 2026-09-04  
**Overall status:** **APPROVED FOR CONTROLLED BETA — CORE ONLY**  
**Learner beta authorization:** **YES — FIRST WAVE LIMITED TO 12 LEARNERS**  
**AI Assist authorization:** **NO**  
**Mentor Care authorization:** **NO**

> This record authorizes only the deterministic Core controlled-beta scope written below. It does not authorize AI Assist, Mentor Care, broader rollout, or bypass of any technical gate.

## 1. Current release decision

Technical P0-15 and P0-16 recertification is GREEN against the current P0 -> P1-03 schema. The Project Owner has explicitly approved a real controlled beta with the following scope:

- service mode: **Core only**;
- first real learner wave: **12 learners maximum**;
- AI Assist: **not authorized**;
- Mentor Care: **not authorized**;
- expansion beyond the first wave: only after the monitoring/gates required by the Master Plan;
- any Sev1 integrity/security issue, queue leakage, state corruption, or release-gate violation requires immediate pause/rollback through the existing controlled-beta governance path.

The approval does not change the independent prerequisite for P1-04 / AI work: deterministic beta must first produce the stability evidence required by the Master Plan.

## 2. Technical evidence

### P0-15 — current-schema isolated alpha

- Workflow: `P0-15 Isolated Alpha`
- GitHub Actions run: `33856650388`
- Head commit: `1b18f1a48b4d5f327f8f4bc7a19f8bd02404b205`
- Result: **SUCCESS**
- Run: https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/33856650388
- Scope: fresh PostgreSQL bootstrap, real P0 migrations, current P1-01 -> P1-03 migrations, fail-closed precheck, isolated P0-15 behavioral matrix, rollback, zero synthetic residue.

### P0-16 — layered controlled-beta recertification

- Workflow: `P0-16 Controlled Beta Gate`
- GitHub Actions run: `33857445108`
- Head commit: `393526e96886570338e04ed828ced55a4433a077`
- Result: **SUCCESS**
- Run: https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/33857445108
- Scope:
  1. fresh PostgreSQL bootstrap;
  2. real P0-04 -> P0-16 migrations;
  3. original mixed Core / AI Assist / Mentor Care P0-16 contract matrix;
  4. proof of rollback before the P1 overlay;
  5. current P1-01 -> P1-03 migrations;
  6. fail-closed current-schema verification;
  7. deterministic Core-only canary activation in an isolated transaction;
  8. proof that an AI wave is blocked while AI runtime is not ready;
  9. emergency pause / rollback verification;
  10. zero synthetic residue after rollback.

The current-schema sequencing test intentionally proves that the P1-01 AI runtime gate is effective; it does not weaken or bypass that gate.

## 3. Production snapshot before activation

Production Supabase was re-read after both recertification gates. No beta activation had occurred at that snapshot.

Observed fail-closed state before activation:

| Control | Observed state |
|---|---:|
| `rollout_state` | `off` |
| `core_enabled` | `false` |
| `ai_enabled` | `false` |
| `mentor_enabled` | `false` |
| `kill_switch` | `true` |
| beta cohorts | `0` |
| beta members | `0` |
| beta weekly reviews | `0` |
| timed attempt results | `0` |
| timed written self-marks | `0` |
| AI runtime status | `not_deployed` |
| AI gate version | `NULL` |

P1-03 remains dormant infrastructure until the controlled-beta activation path is used.

## 4. Source-of-truth reconciliation

The authoritative Exam Prep working branch for this release line is **`exam-prep-p0-host`**.

During recertification, an earlier branch-identification mistake (`exam-prep-p0-core`) was detected and corrected. The `exam-prep-p0-host` source tree was then reconciled against production migration history, including P0-15, P0-16, P1-01, P1-02 and all P1-03 migrations.

No production migration was added as part of P0-15/P0-16 recertification; only CI/tests and this readiness record were changed.

## 5. Known governance observation

At the time of approval, `exam-prep-p0-host` is not protected by GitHub branch protection and does not enforce required status checks at branch level.

The Project Owner approval acknowledges this operational governance weakness for the limited 12-learner Core-only beta. It does not authorize bypassing the successful P0-15/P0-16 gates or expanding rollout without the Master Plan monitoring requirements.

## 6. Human sign-off gate

**Status: APPROVED**

- Decision: `[x] APPROVE CONTROLLED BETA`  `[ ] HOLD`  `[ ] REJECT / REMEDIATE`
- Approved scope: `Deterministic Exam Prep Core only; AI Assist and Mentor Care remain off.`
- Authorized cohort / wave constraints: `First real learner wave limited to 12 learners.`
- Human approver name: `Azizbek Erkinov`
- Human approver role: `Project Owner`
- Decision date: `2026-09-04`
- Evidence / decision reference: `Explicit Project Owner approval in the ChatGPT implementation session: "1 Да / 2 Core-only / 3 12 / 4 Azizbek Erkinov — Project Owner".`
- Required remediation before activation: `Re-run production pre-activation checks; use only governed controlled-beta RPCs; keep AI/Mentor off.`
- Notes: `Expansion is governed by Master Plan monitoring and stability gates. P1-04 remains blocked until deterministic beta stability evidence exists.`

### Mandatory interpretation

**RELEASE GATE = OPEN FOR THE APPROVED 12-LEARNER CORE-ONLY WAVE**  
**AI ASSIST = NOT DEPLOYED / NOT AUTHORIZED**  
**MENTOR CARE = NOT AUTHORIZED**  
**P1-04 = STILL BLOCKED BY DETERMINISTIC-BETA STABILITY PREREQUISITE**

## 7. Authorized next action

The next operational action is to:

1. re-run production pre-activation integrity/security checks;
2. prepare exactly one governed Core-only beta cohort;
3. add no more than 12 explicitly selected real learners;
4. activate the smallest canary wave permitted by the existing P0-16 governance path;
5. verify capability isolation and production integrity immediately after activation;
6. monitor the beta according to P1-01 weekly governance and the Master Plan;
7. expand only after the required GREEN evidence exists.

AI Assist and Mentor Care must remain independently disabled until their own prerequisites and explicit authorization are satisfied.
