# Mathematics P1/P5 — Stage C: real HTTP stale-material, expired-authorization and protected-results journey

**Date:** 2026-11-02 · **Tracker:** [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450) · **PR:** [#466](https://github.com/jteshaboev1984-ops/iClub_APP/pull/466)

**Exact tested code commit:** `e279ee3a90bc9b226ad24d9bbe6805bcb54295da`.

**All three independent exact-candidate checks GREEN:** [genuine Chromium + signed HTTP + PostgREST/PG17 with added learner journey #41426409560](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41426409560) (job `125213978812`), [P2-78 load 600 learners/10 mentors #41426409610](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41426409610) (job `125213981074`), [P2-79 recovery/rollback #41426409547](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41426409547) (job `125213978974`).

## Exact learner-level evidence

Executed `scripts/p1p5-isolated-http-retired-content-recovery.cjs` **after** the existing true Chromium UI and prior academic suites, on actual signed HTTP requests to locally started PostgREST and production-equivalent public RPC functions in disposable PostgreSQL 17.

An isolated **existing CI-only learner B** (not a production account) receives three already-published learning task authorizations from a **test-only SQL setup**, `supabase/tests/p1p5_stage_c_real_http_stale_content_fixture.sql`. No manufactured question, result, mastery or stage. The test then:

1. Safely marks the selected P1 content version `retired` **only on disposable PostgreSQL**. The learner sends an actual HTTP request to start P1. The server rejects with `exam_prep_content_version_not_published`, and no ghost session is created.
2. While that P1 content is unavailable, the learner successfully starts and reads the unaffected published **P5** learning session via HTTP, confirming component independence.
3. The test restores the precise P1 content version to `published`. The learner retries the **same** previously failed client start key, starts one legitimate P1 session; a subsequent retry with the identical key yields the **same session ID** and `resumed=true`, not a duplicate.
4. A separate **expired P1 authorization** is rejected via the actual public HTTP RPC, and another authenticated user cannot start learner B's authorized task.
5. In **both active P1/P5 sessions**, requests for final review before completion are rejected. Neither answer keys nor explanations appear in active-session item data; foreign reading is refused. An attempt to submit a client-provided `is_correct=true` field is rejected.
6. The learner submits **actual published answers** for **4 P1 and 4 P5 assessment items** through real signed HTTP and the original public server evaluator; finalizes both sessions and obtains legitimate owner-only final review, including the answer key. A foreign user cannot access the completed review.
7. A `finally` restore protects the temporarily retired content status even if the HTTP test encounters an error. The postflight confirms it is published, exactly the original **two disposable CI users** remain, and there are no new Practice/Tour/certificate/human-beta records. Unlike earlier rollback-only SQL suites, the two learner sessions persist **inside the throwaway CI database** until the entire GitHub runner destroys it; they are **not** production records and this test does not claim transaction rollback.

The precise CI success payload:

```text
STAGE C REAL HTTP CONTENT RETIREMENT EXPIRY AND PROTECTED REVIEW PASS {"p1RetiredDenied":true,"p5Continues":true,"p1RestoredAfterRetry":true,"p1ExactlyOnceResume":true,"expiredAuthorizationDenied":true,"prefinalReviewDeniedBoth":true,"clientForgedGradesDeniedBoth":true,"foreignOwnerIsolation":true,"finalizedP1Items":4,"finalizedP5Items":4,"syntheticRealDeviceRuns":0,"hostedGoTrueRuns":0}
STAGE C REAL HTTP P1 CONTENT RESTORED TWO DISPOSABLE USER BOUNDARY PASS
```

The test intentionally does **not** write or reveal raw correct-answer keys in CI evidence. No client code, UI, production migrations, hosted Supabase data, paid AI, learner progress, certificate or launch switches changed.

## Truthful remaining boundary

**Stage C IN PROGRESS:** this is one **actual signed HTTP learner lifecycle path across both papers**, not all 15+18 full longitudinal narratives. The existing P2-79 simulated retired-content/authorization cases are independent and also green on the same candidate; the new evidence verifies an actual public HTTP and grading route. Further high-risk content and timer/feedback paths need only be added if they remain gaps on the approved roadmap.

**Stage B IN PROGRESS:** local ephemeral signed JWT is **not** hosted Supabase GoTrue token refresh, and Chromium is **not** a real learner's Telegram WebApp device. There are no four genuine human weekly reviews or real 72-hour observation. Stage D remains not started. **Mass release NO_GO.**
