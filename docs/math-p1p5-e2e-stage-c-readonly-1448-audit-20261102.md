# Mathematics P1/P5 — Stage C current-content structural/routing checkpoint

**Date:** 2026-11-02 | **Issue:** #450 | **Stage C:** partial, not complete.
**Executable guard:** `supabase/tests/p1p5_stage_c_1448_current_metadata_readonly.sql`
**Execution:** exact GitHub branch file executed using connected Supabase project `mmmduffgpvwjdpruzikw` in **SELECT-only** mode. No user/session rows or content text returned; no DML or DDL.

## Verified current production snapshot (read-only)

| Metric | Result |
| --- | ---: |
| Published objective learning questions | 486 (P1 270, P5 216) |
| Withheld governed diagnostic/mixed/retest questions | 729 (P1 405, P5 324) |
| Current distinct objective question metadata rows | 1,215 |
| Current approved written-task **keys** | 233 (P1 130, P5 103) |
| Prior written task versions retained separately | 101 |
| Current unique objects checked exactly once | **1,448 / 1,448** |
| Component-owned canonical skills represented | **81 / 81** |
| Structural/routing failure categories detected | **0** |
| Result | **PASS** |

The guard checks existing P1/P5 component contracts, subject ID, question types, three-language presence, MCQ option presence, question duration, stored source hash format, quality review statuses, published assessment routing, component isolation, withheld-vs-learning exposure boundary, current written task locale/QA/rubric metadata and published routing. It only reports counts and failure-category labels, not protected answer keys, question IDs, student data or written content.

## Important version-order correction

A first **incorrect audit query** ranked latest written versions by database ID and produced one *false positive* `w_latest_not_routed`. Read-only investigation established a concrete counterexample: written `P1CIR03-AW14` had a high numeric ID created in September and a lower numeric ID approved in October. These are **not chronologically ordered IDs**.

The corrected guard ranks published task versions by `approved_at DESC NULLS LAST, created_at DESC, id DESC`, chooses one current version per (component,task_key), and keeps the other 101 versions as historical. The exact stored SQL was re-executed against live metadata and yielded zero failures. No production repair was needed or attempted.

## Evidence boundary

- This checkpoint is **live metadata analysis**, not a new independent examiner/linguist review. It does not solve questions or verify answer correctness.
- The guard reads confidential metadata inside Supabase but commits **only SQL source**, no bank export, private learner records, academic answers or tokens.
- No production writes, flag changes, beta enrollments, review approvals, public access migrations or user-profile changes.
- Stage B remains open for hosted GoTrue/refresh + real consenting Telegram client/device acceptance. Human weekly reviews and mass launch governance remain **NO_GO**.
- Stage C remains **IN PROGRESS**: complete 15+18 behavioral model/fault/concurrency matrix, real auth/expiry, mobile/desktop UX and repeatable candidate-SHA CI before closure. Structural 1,448 routing gate alone is insufficient for full engineering E2E approval.
