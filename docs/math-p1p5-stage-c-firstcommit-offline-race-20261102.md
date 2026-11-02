# Mathematics P1/P5 — Stage C offline-before-commit and first-write concurrency

**Date:** 2026-11-02  
**Tracker:** [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450)  
**Pull request:** [#461](https://github.com/jteshaboev1984-ops/iClub_APP/pull/461)  
**Exact tested code candidate:** `5c31de8e8fbdbafc1f6b76fea2619d94d34a4016`  
**GREEN CI:** [41404087751](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41404087751), job `125142077459`, conclusion `success`.  
**Changed test:** `scripts/p1p5-isolated-http-written-criteria-next-browser.cjs`. No production app runtime or SQL migration edits.

## Genuine isolated browser → HTTP → PostgreSQL results

The existing 12 P1/P5×RU/UZ/EN×385/1280 Chromium UI cases and all previous real HTTP learner routes ran in one ephemeral PostgreSQL 17 + PostgREST + signed JWT CI. On the last Uzbek desktop written step of **each** P1 and P5 component, this extension:

1. Asserted a genuinely **uncommitted** written step: no `private.exam_prep_written_step_advances_v1` for the item and no written response.
2. Intercepted the **first** UI Next HTTP request and aborted it **before it could reach the server**, with Playwright `internetdisconnected`. The production UI subsequently called the real read-only written status RPC. It returned `open` + `can_advance=true`, and the UI displayed a governed retry; no DB advancement or answer was manufactured.
3. Started **eight independently signed real HTTP** first-write attempts with distinct idempotency keys plus a UI retry from the same still-open step. This targets a **first commit** with uncommitted data, unlike the previously tested replays of already committed evidence.
4. Confirmed all eight first-write HTTP callers accepted/returned `advanced`, at most one HTTP request returned `replayed=false`, and the UI retry request also proceeded through the actual PostgREST backend.
5. Simulated lost client ACK **only after the UI's real server response**; confirmed the UI made a read-only status reconciliation. The persisted record count was exactly **one** for the step per component, and the written response count was zero. The guard distinguishes a winning UI write from a winning HTTP request by the durable idempotency key; it never awards automatic written marks.

Exact log marker:
`STAGE C FIRST-COMMIT OFFLINE + CONCURRENT UI HTTP PASS`

| Check | P1 | P5 |
| --- | --- | --- |
| Browser request aborted before server commit | PASS | PASS |
| Read-only server status remained `open`, no write | PASS | PASS |
| Eight concurrent HTTP first-write calls | PASS | PASS |
| Separate genuine UI retry | PASS | PASS |
| One durable `Next` advancement | PASS | PASS |
| Simulated postcommit ACK lost then read-only reconciliation | PASS | PASS |
| Written automated credit created | **0** | **0** |

A total of 16 independent HTTP first-write calls and 2 UI retries were exercised across P1/P5. The preceding full Stage B positive diagnostic→learning/correction→governed post-due retest→mixed/timed/full-paper E2E passed on the same exact candidate. The subsequent Stage C JWT/foreign-access/14 already-saved replay/emergency kill-switch suite also passed.

## Evidence boundaries and safety

- This is actual signed local HTTP/PostgREST→DB evidence with the real Math component browser UI. The auth transport remains a **test-local JWT-compatible adapter**, not hosted Supabase GoTrue; no Telegram learner device was used.
- The initial request abort is a deterministic **pre-server network failure**. It is not a timed hardware radio disconnect, real 3G network simulation or a failure amid an uncommitted database transaction.
- The eight requests are started concurrently and race a browser retry. It does not prove a particular schedule or that every request entered PostgreSQL simultaneously; it **does** prove the fresh uncommitted step converges to one persisted advance under the test concurrency.
- Student accounts, production database, real learner progress, Practice/Tours, certificates, source answer keys, entitlement flags, academic gate approvals, and mass-launch release state were **not modified**.
- All written solutions remain external/on paper. Opening criteria or pressing Next never supplies a Cambridge examiner mark, L4/L5 human verification or guaranteed readiness.
- Stage C still needs the 15+18 **executed** profile/state-machine battery, mid-write fault types, time-zone/timer and load scenarios. Stage B remains open for hosted GoTrue refreshed-session + consenting Telegram mobile learner evidence. Stage D and mass release still blocked.
