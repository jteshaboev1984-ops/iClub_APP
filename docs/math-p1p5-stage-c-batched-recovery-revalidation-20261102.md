# Mathematics P1/P5 — Stage C consolidated recovery, clock, stale plan, noncredit revalidation, profile revision

**Date:** 2026-11-02  
**Issue:** [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450)  
**PR:** [#465](https://github.com/jteshaboev1984-ops/iClub_APP/pull/465)  
**Exact executed candidate:** `64c89c840334bd133f5dcbc26bb01e9af95aadf8`  
**Genuine Math Chromium/JWT/PostgREST/PG17 + new batch:** [CI GREEN #41419880221](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41419880221), job `125192593893`  
**P2-78 600 learners/10 mentor scopes:** [CI GREEN #41419880236](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41419880236), job `125192593723`  
**P2-79 disaster/rollback previous-SHA rehearsal:** [CI GREEN #41419880312](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41419880312), job `125192595136`

## What was actually executed

One substantial, reproducible PostgreSQL transaction, `supabase/tests/p1p5_stage_c_recovery_plan_revalidation_batched.sql`, runs inside the existing isolated PG17 E2E after the complete production Math UI→signed HTTP/JWT→PostgREST real-browser suites (the same job). The new suite itself uses **real server-side public RPCs from SQL** rather than pretending it made sixteen extra UI browser journeys.

The one dedicated owned synthetic learner first completes actual published P1 and P5 Stage-0 diagnostics and earns **at least seven P1 and six P5** objective L2 skills through genuine graded published learning sessions using pre-existing temporary P2-69 engineering helpers. It directly exercises current `public.record_my_exam_prep_interruption_v2`, `public.get_exam_prep_recovery_safe_v2`, `public.authorize_exam_prep_revalidation_item_safe_v1`, `public.generate_exam_prep_weekly_plan_safe_v3`, `public.authorize_exam_prep_plan_item_safe_v1`, and `public.save_exam_prep_exam_profile_v2`.

| Test family | Actual verified result |
| --- | --- |
| **Recovery decisions, 4 durations × 2 time zones × 2 components** | **16 real P1/P5 server decisions**: 5/15/25/35 day interruptions under `Pacific/Kiritimati` and `America/Los_Angeles`; exactly 16/16 untouched objective levels, server stage and recorded evidence |
| Two components after each interruption | Separate P1/P5 recovery readbacks, explicitly retained progress and unchanged academic evidence standards; absence alone never demotes stage |
| Long-break revalidation (35 days) | Both components received independently available recommended revalidation; P1 authorized a real published retest session with `academic_credit=false`, finalized it and retained an **`app_checked_noncredit` history entry** without generating new `app_verified` academic evidence |
| Regenerated weekly plan | Fresh P1 plan superseded old plan; old plan's authorization denied; no new academic session authorization created |
| Exam series/target/hours revision | Genuine protected profile update reported `progress_retained=true`; earlier academic evidence count unchanged, and P1 ≥7 / P5 ≥6 L2 skills remained earned |
| Foreign-user revalidation authorization | Denied by real server owner/entitlement protection |
| Legacy/canary/beta protection | No Practice/Tour/certificate or human weekly-review write |
| Synthetic cleanup | One explicit transaction `ROLLBACK`; **exactly the original two CI-only users restored**, no synthetic run or identities persisted |

The 25-day case currently preserves `source_gap_review` as the historical engine mode while the v2 amendment describes conservative/extended recovery policy; this test checks the **actual current database contract**, not an invented new duration rule. Time-zone input is supplied as a **transaction-local SQL session setting** and dates are computed from that session's current date, not by falsifying user timestamps.

Exact production-like CI logs:

```
NOTICE: STAGE C BATCH ACTIVE SERVER RECOVERY 16 TZ-BAND-PAPER PASS, noncredit_revalidation=1, stale_plan_denied=t, foreign_denied=t, profile_revision_progress_retained=true
STAGE C BATCH 16 RECOVERY TZ DAYBAND P1P5 PRESERVATION PASS | 16 | 2 | 4 | 16
STAGE C BATCH ZERO SYNTHETIC RESIDUE RESTORED TWO ORIGINAL CI USERS PASS
```

## Repairs made in test code, not app runtime

The first candidate failed on a **test expectation error**: noncredit revalidation is correctly preserved in `private.exam_prep_evidence_events` with `verification_status='app_checked_noncredit'`; it was incorrect to assert zero new *history* rows. The precise fix requires an expected noncredit audit entry while confirming **zero new `app_verified` evidence**. A second candidate exposed the incorrect assumption that weekly plan rows contain `created_at`; canonical ordering is `plan_version`. Both repaired **inside the isolated test only**, and the exact final candidate ran the full three GREEN workflows.

This validates **16 component/clock decisions plus several actual preservation, noncredit and safety transitions**, **not** 16 independent learners, 33 full-year event-contract simulations, hosted Supabase GoTrue, genuine Telegram device resumes or four human weekly beta reviews. Earlier independent PR #464 covered genuine P1 passed and P5 failed/reopened retests; P2-79 covers retired content/stale authorization simulated recovery in its own isolated matrix. Further Stage C model execution and eventual consolidated Stage D still need explicit truthful gating.

**No application runtime file was edited. No production data, feature flags, student progress, localStorage, Practice/Tour/certificate or human beta evidence were changed. Mass release remains NO_GO.**
