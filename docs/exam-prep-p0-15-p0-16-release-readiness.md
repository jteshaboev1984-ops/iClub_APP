# Exam Prep P0-15 / P0-16 Release Readiness Record

**Program:** `math_as_p1_p5`  
**Branch:** `exam-prep-p0-host`  
**Evidence baseline commit:** `393526e96886570338e04ed828ced55a4433a077`  
**Assessment date:** 2026-09-04  
**Overall status:** **APPROVED FOR CONTROLLED BETA — FIRST LIVE WAVE CORE ONLY**  
**Controlled-beta cohort size:** **12 learners**  
**First live canary:** **Core only**  
**AI Assist live authorization:** **NO**  
**Mentor Care live authorization:** **NO**

> The Project Owner approval authorizes a real controlled beta under the Master Plan. “Core-only” refers to the first live learner wave, not to removing the Master Plan requirement that the 12-person controlled-beta cohort represent Core / AI Assist / Mentor Care service modes. Future-mode members remain dark until their independent gates are satisfied.

## 1. Current release decision

Technical P0-15 and P0-16 recertification is GREEN against the current P0 -> P1-03 schema. The Project Owner explicitly approved a real controlled beta with the following operational interpretation, reconciled to the Master Plan:

- total controlled-beta cohort: **12 learners**;
- cohort must retain representation of all three planned service modes as required by P0-16;
- planned 12-person service mix for the first cohort: **8 Core + 2 future AI Assist + 2 future Mentor Care**;
- first live canary wave: **4 Core learners only**;
- remaining Core learners stay approved/waiting until a later wave decision;
- AI Assist candidate members remain **approved/waiting with zero entitlement** until the AI runtime/readiness gate is satisfied and a later wave is explicitly allowed;
- Mentor Care candidate members remain **approved/waiting with zero entitlement** until mentor readiness/capacity and a later wave are explicitly allowed;
- AI Assist and Mentor Care are therefore **not live-authorized on day one**;
- expansion beyond the Core canary is governed by monitoring/gates in the Master Plan;
- any Sev1 integrity/security issue, queue leakage, state corruption, or release-gate violation requires immediate pause/rollback through the existing controlled-beta governance path.

This interpretation preserves both the Project Owner’s “Core-only” day-one decision and the Master Plan requirement that the controlled-beta cohort be stratified rather than permanently Core-only.

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
  7. mixed 12-person cohort staged and approved while global access remains OFF;
  8. deterministic Core-only canary activation;
  9. proof that an AI wave is blocked while AI runtime is not ready;
  10. emergency pause / rollback verification;
  11. zero synthetic residue after rollback.

The current-schema sequencing test intentionally proves that mixed cohort governance and Core-only first-wave activation coexist correctly; it also proves that the P1-01 AI runtime gate cannot be bypassed.

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

The Project Owner approval acknowledges this operational governance weakness for the limited 12-learner controlled beta. It does not authorize bypassing the successful P0-15/P0-16 gates or expanding rollout without the Master Plan monitoring requirements.

## 6. Human sign-off gate

**Status: APPROVED**

- Decision: `[x] APPROVE CONTROLLED BETA`  `[ ] HOLD`  `[ ] REJECT / REMEDIATE`
- Approved operational scope: `12-person stratified controlled-beta cohort; first live canary is Core-only; AI Assist and Mentor Care remain dark until their independent gates.`
- Planned cohort mix: `8 Core + 2 future AI Assist + 2 future Mentor Care.`
- First live wave: `4 Core learners.`
- Human approver name: `Azizbek Erkinov`
- Human approver role: `Project Owner`
- Decision date: `2026-09-04`
- Evidence / decision reference: `Explicit Project Owner approval in the ChatGPT implementation session: "1 Да / 2 Core-only / 3 12 / 4 Azizbek Erkinov — Project Owner"; subsequent instruction: execute the full Master Plan and launch the app.`
- Required checks before activation: `Production fail-closed precheck; exact 12-user selection; Mentor candidate readiness; governed RPC-only staging/approval; AI/Mentor entitlement must remain zero.`
- Notes: `Core-only is the first live wave. The mixed cohort exists to preserve the Master Plan service-mode test design; candidate status does not itself grant learner access.`

### Mandatory interpretation

**RELEASE GATE = OPEN FOR A 12-LEARNER STRATIFIED COHORT**  
**FIRST LIVE CANARY = CORE ONLY**  
**AI ASSIST LIVE ACCESS = NOT AUTHORIZED / RUNTIME NOT DEPLOYED**  
**MENTOR CARE LIVE ACCESS = NOT AUTHORIZED**  
**P1-04 = STILL BLOCKED BY DETERMINISTIC-BETA STABILITY PREREQUISITE**

## 7. Authorized next action

The next operational action is to:

1. re-run production pre-activation integrity/security checks;
2. select exactly 12 eligible real learners using an auditable, non-arbitrary selection rule;
3. stage one 12-person controlled-beta cohort using the planned 8 Core / 2 future AI / 2 future Mentor service mix;
4. verify the two Mentor Care candidates have valid assignment/capacity before cohort approval;
5. approve the cohort while global access remains OFF;
6. activate **wave 1 only**, containing four Core learners;
7. verify capability isolation and production integrity immediately after activation;
8. monitor the canary according to P1-01 weekly governance / first-72h rules;
9. do not activate AI or Mentor waves until their independent prerequisites and later release decisions are satisfied.
