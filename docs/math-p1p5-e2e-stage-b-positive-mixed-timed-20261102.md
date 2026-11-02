# Mathematics P1/P5 Stage B — Positive Mixed Transfer, Timed Sections and Full Papers over Authenticated HTTP

**Date:** 2026-11-02  
**PR:** [#456](https://github.com/jteshaboev1984-ops/iClub_APP/pull/456)  
**Final exact green candidate:** `e38e6341f7078cab5ca6b575a1b2fe1794a85927`, [GitHub Actions run 41394460084](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41394460084), **GREEN**.  
**Verdict:** real HTTP-positive mixed, separate timed-section, full-paper execution and **provisional learner self-review** **VERIFIED**. **Not an independent written examiner grade.** Stage B overall remains IN PROGRESS.

## What was actually tested

The same disposable PostgreSQL 17 + current migrations + local PostgREST v12.2.3 + HMAC JWT + verified P1/P5 Playwright learner baseline from PRs #452–#455. A new, separately registered **P2-67 canonical synthetic learner** `SV-P1P5-MIXED-TIMED-HTTP-01` is created *only after* the previous post-due learner has been governed-cleaned. The temporary P2-69 helper definitions are reused, but **not** their rollback main body or simulated direct `exam_prep_timed_attempt_results` inserts.

### Credible stage precondition

For this new learner, isolated PostgreSQL first executes the actual Stage 0 public RPCs on published diagnostic content and completes the normal public answer/finalize RPC chain. Next the existing P2-69 *test-only published learning authorization helper* issues enough real learning packs to attain Stage 3 (37 P1 skills L2 / 30 P5 skills L2). Answers are graded through the real public RPC, not direct assignments to skill states, stages, mastery, readiness or grades. **This precondition is a database synthetic-learner preparation**, *not a complete human-clicked Stage-3 year*; it is called out separately.

After the server itself derives Stage 3, **every positive mixed/timed authorization, session start, answer submission, finalization, written self-review and result lookup below runs through actual signed HTTP/PostgREST to published public Exam Prep RPCs**, never a mocked RPC result.

| Verified case | P1 observed | P5 observed |
| --- | --- | --- |
| Published weekly plan `mixed_transfer` selected, same-component authorized by `authorize_exam_prep_plan_item_safe_v1`, started/answered/finalized over HTTP | 5 items | 3 items |
| Published independent fixed-time `timed_section` selected from actual gated catalog, server authorized, started/answered/finalized through special timed finalizer | 3 written items | 3 written items |
| Published authentic `stage3_full_paper_01`, selected from server-gated catalog, authorized, attempted before server deadline, finalized by special timed finalizer | 10 written items, 75 marks available | 7 written items, 50 marks available |
| Timed/finalizer replay with same idempotency identity | `replayed=true` | `replayed=true` |
| User B tries reading A’s mixed session or timed results | Denied | Denied |
| Before written learner self-review | `pending_self_review` | `pending_self_review` |
| Learner self-review after finish | 0 synthetic self-marks per item; `provisional_comparable`, `timingComparable=true` | 0 synthetic self-marks per item; `provisional_comparable`, `timingComparable=true` |
| Awarded readiness or human-examiner verified grade from those self-marks | **NO**; `readiness_claim=false` | **NO**; `readiness_claim=false` |
| Academic stages after one set of mixed/paper/section attempts | P1 remains Stage 3 | P5 remains Stage 3 |
| Canonical learner cleanup | P2-66 completion + cleanup accepted; only original two disposable accounts remain, no Practice/Tour/certificate/beta-review spillover | Same |

### Limitations

1. **Full-paper success means authentic authorized submission, strict real-clock measurement, provisional comparison metadata and safe written self-review; it does NOT mean verified Cambridge grades or successful academic mastery.** The actual full-paper content in this test comprises written tasks; the test explicitly self-marks each 0 to avoid fabricating examiner judgment.
2. The positive mixed/timed/full-paper step is **authenticated HTTP client -> PostgREST -> PostgreSQL**. The earlier Math UI Chromium sequence runs in the *same CI job* and remains green; this new positive segment does not click its cards in Chromium. Do not re-label it as a full human-interaction timed-paper browser test.
3. The preparatory 37/45 and 30/36 L2 academic evidence is synthetic, though all graded by actual public RPCs on approved published content. No real pupil, genuine weekly beta reviews, GoTrue token refresh, Telegram in-app lifecycle or production data was used.
4. The whole suite executes in disposable localhost containers; no database migration, product runtime JS, permissions or real user flags are changed. The mass-release decision remains **NO_GO**.

## Reproduce

- `.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml`
- `supabase/tests/p1p5_isolated_http_mixed_timed_stage3_prep.sql`
- `scripts/p1p5-isolated-http-positive-mixed-timed.cjs`
- `supabase/tests/p1p5_isolated_http_mixed_timed_cleanup.sql`
- Existing `supabase/tests/p2_69_full_stage0_6_core_simulation.sql` provides only **temporary helper definitions** via CI `awk` extraction; its rollback-only main routine is not executed here.

## Stage B next

Primary open items: full Mathematics-specific **written criteria → noncredit Next → pause/restore** journey in true HTTP/browser on RU/UZ/EN phone and desktop, plus GoTrue managed Auth/token-refresh and real Telegram WebApp smoke for the consented cohort. The six new positive mixed/timed/full-paper paths do not substitute for those acceptance gates, and no real owner signoff is inferred.
