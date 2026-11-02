# Mathematics P1/P5 — Stage C real HTTP security, parallel replay and emergency recovery

**Date:** 2026-11-02  
**Issue:** [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450)  
**PR:** [#460](https://github.com/jteshaboev1984-ops/iClub_APP/pull/460)  
**Exact tested candidate:** `b0b4ef3980b8a25c0b240cb7edc534facc4ed562`  
**GREEN Actions run:** [41402263595](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41402263595)  
**GREEN job:** `125136444520` — `actual Math UI JWT PostgREST PG17`  
**Test script:** `scripts/p1p5-isolated-http-stage-c-security-race.cjs`  
**Workflow:** `.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml`

## What was executed against real isolated PostgreSQL

The new Stage C security and fault step ran **after** all existing Stage B checks in the same disposable GitHub Actions job: authentic Math UI/Chromium, signed JWT→PostgREST→real public Exam Prep RPCs→PostgreSQL 17, diagnostic/learning/correction, registered synthetic post-due retest, stage-3 mixed/timed/full-paper, owner recovery, and written RU/UZ/EN mobile/desktop Next+lost-ACK.

The new script verifies two real server-committed P1/P5 written-step records. This batch exercises already-persisted Next acknowledgment **replays** with 6 parallel signed HTTP connections per component (plus one different-key retry per component); it does **not** claim a fresh simultaneous first-write insert race.

| Runtime check | Verified result |
| --- | --- |
| Owned papers | P1 and P5 |
| Signed-JWT negative probes | **12 / 12** (anonymous, invalid signature, expired token, unregistered user, foreign user, signed anonymous-role token; each for P1 and P5) |
| Explicit foreign access/write rejection | **4** denials across components |
| Concurrent/repeated signed HTTP writes | **14 / 14** replayed (existing committed written step, same/different keys) |
| Key reused for different item | Rejected, both components |
| Locale re-open after saved Next | 6 / 6 language-component combinations, RU/UZ/EN |
| Existing written-step durable rows | Exactly one per tested session; 0 written answer/marks fabricated for that item |
| Core emergency kill-switch | Flag ON denied protected owner reads/writes P1 and P5; capability false |
| Core restoration | Flag restored OFF; same owner/Core capability true |
| Academic and legacy state before/after | Identical counts for sessions/responses/advances, skill states, retests, beta reviews and legacy attempts/certificates |
| Canonical scenario manifest | 15 canonical profiles + 18 adversarial variants **registered**, not newly executed full-year journeys |

GitHub Actions log proof marker:

`STAGE C REAL HTTP AUTH RACE KILL SWITCH PASS`

It recorded `threeLocalesRead:6`, `signedJwtNegativeCases:12`, `foreignAccessDenied:4`, `parallelRealHttpReplays:14`, `keyCollisionDenied:true`, `killSwitchFailClosed:true`, `killSwitchRestored:true`, and `academicEvidenceUnchanged:true`.

## Isolation and product integrity

- Only fake users with fixed invalid-local identity names, with an ephemeral JWT signing key and local `127.0.0.1:5432` database. The script refuses to start outside exact `CI=true`, `P1P5_E2E_ISOLATED=true`, `PGDATABASE=postgres` and explicit `PGOPTIONS=-c iclub.e2e_isolated=true`.
- The emergency drill changes only the **disposable CI** config and uses database guard checks requiring precisely two fixed fake identities, no legacy attempts/certificates, no real beta reviews, and exact Core-only configuration. It restores the kill switch in `finally`.
- None of these new tests access hosted GoTrue, real Supabase learner accounts, production DML, production entitlements, user/localStorage data, or official Telegram learner devices.
- Production and deployment app logic were unchanged; only the isolated Node test and workflow were modified.

## Acceptance boundaries still OPEN

1. **Stage B:** hosted GoTrue token refresh and a genuine consented Telegram WebApp learner-device resume; cannot be certified from signed local JWT alone.
2. **Stage C:** live first-write concurrency and mid-submit offline/reconnect, multi-tab double-tap, full 15+18 scenario **execution** (not just source registry), invalid/retired content, timer/time-zone/auth-expiry and long-formula screen tests, repeatable seeded model outcomes with no false progression.
3. **Stage D:** consolidated reproducible candidate-SHA release pipeline with separate flags for real-user beta and mass-launch governance.
4. **Mass release:** remains `NO_GO` until actual four authorized weekly reviews, independent learner evidence, monitoring and owner approval.

**Verdict:** Stage C security/negative-auth/replay/emergency batch **GREEN**, Stage C as a whole **IN PROGRESS**. Never convert this synthetic test into a real-user or academic examiner sign-off.
