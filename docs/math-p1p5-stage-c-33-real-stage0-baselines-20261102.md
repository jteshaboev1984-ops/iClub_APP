# Mathematics P1/P5 — Stage C: 33 independent source-mapped Stage-0 baselines

**Date:** 2026-11-02  
**Tracker:** [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450)  
**PR:** [#462](https://github.com/jteshaboev1984-ops/iClub_APP/pull/462)  
**Exact tested SHA:** `4162e01909d5c95bef23879ef29554a7c7cc2b85`  
**Real CI:** [run #41406954373](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41406954373), job `125151049108`, conclusion **success**.  
**Reproducible SQL:** `supabase/tests/p1p5_stage_c_33_independent_stage0_rollbacks.sql`  
**Runner:** `.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml`

## Proof obtained

The exact candidate first ran the full previously GREEN browser→authenticated real PostgREST/JWT→disposable PG17 Math P1/P5 E2E (diagnostic, learning, correction, post-due retest, mixed, timed/full paper, written RU/UZ/EN and stage C concurrent first-write/replay/kill-switch). It then executed a **single explicit PostgreSQL transaction** with the immutable canonical P2-67 33-row manifest as the scenario source. For each source row it created a distinct rollback-only synthetic actor with Core entitlement and saved an exam profile through the real public RPC. It then asked the real server for **one independently generated P1 and one P5 Stage-0 diagnostic**. Every session was graded and finalized using the actual public learner RPCs and already published objective question keys; no direct stage assignment, fabricated grade, or manually written evidence event.

| Exact runtime result | Value |
| --- | ---: |
| Distinct immutable source manifest scenarios | 33 |
| Canonical scenario baselines | 15 |
| Adversarial scenario baselines | 18 |
| Separate synthetic learner identities | 33 |
| Real authorized/finalized diagnostic sessions | 66 (P1 33, P5 33) |
| Persisted actual submitted response rows inside test transaction | 462 |
| Deliberate wrong-answer **choices** sent to server | 200 (not asserted as 200 server-scored incorrect outcomes) |
| Deterministic answer pattern variants | 9 |
| Full source event contracts completed | **0**; specifically not claimed |
| Rollback / restored original isolated users | **PASS**: 2 original users only |
| Legacy Practice/Tour/certificate and beta-review contamination | **zero** |

Exact log markers:

- `STAGE C 33 INDEPENDENT SERVER-GRADED STAGE0 BASELINES PASS`
- `STAGE C 33 ROLLBACK RESTORED TWO ORIGINAL FAKE USERS: PASS`

The test also proves each synthetic owner had only two genuine finalized diagnostic sessions, neither paper silently created a session for the other, and no objective-skill level was granted simply for taking one diagnostic. The `ADV-16-CROSS-USER-ACCESS-ATTEMPT` scenario additionally exercised the actual owner-scoped read RPC and rejected the foreign user. The `ADV-11-OFFLINE-DUPLICATE-RETRY` scenario resubmitted the same question with the same idempotency key without duplication. All 33 manifest entries were represented exactly once, with answer patterns deliberately varied by source profile. The 33 source definitions are not changed and contain no real-person identifiers.

## Important non-equivalence — Stage C still OPEN

These are **33 distinct server-executed Stage-0 baselines**, **NOT** 33 full simulations of the source's complete event sequences. The canonical manifest's `initial_state.stage` fields (including nominal Stage 3/4/5) are **descriptive target profiles**; the test does not set that stage or copy hypothetical skill coverage into records. Adv. tags such as 30-day interruption, mentor assignment, failed delayed retest, stale weekly plans, focus/visibility events, protected-feedback leakage and retired content need independently earned state and real event-specific tests. Stage 0 evidence cannot close those gates.

The test's signed HTTP/Chromium checks occur in preceding steps. The **33-profile loop itself invokes real public server functions from SQL** inside the disposable local database, not a separate 33× HTTP/UI workflow; label its transport accurately. Output is an aggregate only: no bank text, solution key, student ID, access token or personally identifiable data logged. The entire transaction ends with `ROLLBACK`; it never runs against hosted Supabase. CI refuses nonlocal database, absent isolation flag, an unexpected preexisting learner, enabled AI/Mentor or global QA override, beta reviews or nonempty legacy attempts/certificates.

## Next substantial battery

1. Drive the 18 distinct adversarial **event sequences** on genuine progressively earned Core P1/P5 stages, including failed learning, retest failure/renewal, stale auth/plan/content, long interruption, protected feedback, time-zone/deadline, service transitions and false mastery/credit.
2. Exercise 15 canonical learner **progression models** (strong P1/weak P5 etc.) beyond the first diagnostics with server-grade evidence and explicit stage assertions, preserving component separation.
3. Re-run P2-78/79 stress/rollback on the same exact candidate, then assemble the Stage D combined release verdict. Hosted GoTrue refresh, two consenting actual Telegram/browser users, four real weekly reviews, 72-hour real wave and owner decision remain separate NO_GO gates.

**No production DB writes, runtime application changes, learner data migration, certificate changes or mass-beta enrollment occurred.**
