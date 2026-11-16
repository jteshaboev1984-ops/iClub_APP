# Mathematics P1/P5 — written comparability after D03

**2026-11-16; Draft PR #540.** Source-only analysis and rollback-only isolated SQL test. No changes to runtime grading, database migrations, learner data, entitlement, released stages, feature flags, production or main.

## Proven gap

The original Stage3 exit evaluator (`supabase/migrations/20260905152500_exam_prep_p1_03_stage3_exit_evaluator_v1.sql`) requires component-independent 100% canonical coverage (P1 45 / P5 36), all skills L2, key skills L3 (P1 8 / P5 7), and a **comparable official full-paper baseline**. A full Paper completed before its written work is academically verified does not satisfy that last condition.

D03 (`20261109110109_exam_prep_p1p5_d03_written_selfmark_firewall_v1_20261109.sql`) deliberately changed `private.exam_prep_timed_score_comparable_v1`: self-mark rows no longer clear pending written marks; comparability needs zero pending-review marks, positive server elapsed seconds, valid integrity, current paper epoch and consistent exam series. The public stale-client self-mark RPC is fail-closed and revoked for anon/authenticated.

The old P2-02 PG17 fixture used to insert *all-written Paper attempts* then synthesize marks via `private.exam_prep_timed_written_self_marks` and **expect Stage3 READY**. That is now an invalid, pre-D03 assumption. The correct result is an incomplete, ungraded Paper, **not** an automatic 0/75, 0/50, verified score, Stage3 exit or Stage4 unlock. S4 Paper completion/review/history remains valuable as **ungraded practice**, independent of academic comparability.

## What current isolated regression proves

`supabase/tests/p2_02_stage3_syllabus_closure_matrix.sql` retains original program/rule/key registry, independent P1/P5 syllabus L2/L3 and coverage checks, explicit absent-baseline reason, Stage4 false, calendar/product-no-override and all test rows inside BEGIN/ROLLBACK. It also checks revoked self-grade RPC privileges; inserts historic self-mark rows **only as an adversarial superuser fixture**; then requires `score_comparable=false`, baseline count 0 and both components blocked. Independently reducing P1 key skill L3 and P5 non-key L2 must produce their own specific failure without affecting the other Paper.

**Limits of a GREEN regression:** It proves negative safety, **not** successful Stage3 closure for genuinely verified handwritten work, student readiness or complete release acceptance. The existing P2-80 engineering workflow already distinguishes `ENGINEERING AUDIT GREEN` from `real_world_evidence=UNPROVEN`. That limitation must remain in release/checkpoint summaries even if P2-36 and P2-80 finish green.

## Separate academic requirement — #450

Design and approve how **independently verified** written-method marks are obtained and attributed to a particular student, assessment version, official marking criteria, exact paper identity and attempt. Include correction/dispute and tamper-resistance rules, signed/owner-bound receipts, retry idempotency, and separate P1/P5 histories. No mandatory mentor, self-scoring, fabricated written marks or arbitrary minimums. Then create a new *positive* signed PostgreSQL17/PostgREST/JWT/Chromium test against the approved mechanism, before claiming Stage3 academic closure. Release governance and human acceptance remain independently NO-GO without those proofs.
