# Mathematics P1/P5 D10-08 — safeguard genuinely fresh delayed retests

Date: 2026-11-05. Issue #450. Based on fully verified PR #491 (71/71). DRAFT ONLY.

## Direct read-only content finding

All 486 **published** and 729 **reserve** P1/P5 objective items were checked for missing RU/UZ/EN prompts/explanations, malformed MCQ key, missing answer, 4-option array shape, and duplicate choices. These structural invariants passed. A separate maths-safe fingerprint (only whitespace, case, superscript glyphs and Unicode minus/relation glyph variants; NEVER suppress the plus or minus signs or change comparators) revealed **five actual same-prompt pairs** among published/reserve content:

- P1-DIF-05 published learning vs withheld mixed reserve;
- P1-INT-03 published learning vs withheld retest reserve;
- P1-QUA-03 published learning vs withheld diagnostic reserve;
- P1-INT-03 two withheld diagnostic variants;
- P1-INT-04 withheld diagnostic vs withheld retest.

Several initial loose-normalization candidates were false positives (distinct sign/equation); excluded from the confirmed count.

**Live usage safety:** read-only metadata indicated one old P1-QUA-03 diagnostic duplicate already appeared in **71 stored sessions**. The other four protected duplicate candidates currently show no session-item references, but are already linked to published assessments. Editing them in place or deleting assessment rows would jeopardize referential integrity, historical result snapshots and current release rules. This draft **never edits any existing question, key, assessment or learner history**.

## Implemented narrowly

The only production-code mutation in D10-08 is an additive owner-scoped migration `20261105112000_exam_prep_p1p5_fresh_retest_math_prompt_priority_v1.sql` that preserves the exact input/output signature and all existing eligibility filters of the private service-role function `exam_prep_select_fresh_retest_assessment_v1`.

It changes **sort priority only**, when deciding among already eligible retest variants:
1. Prefer a mathematical prompt not already delivered to this learner in another P1/P5 session.
2. Prefer a prompt not identical to a released learning item of the skill.
3. Otherwise retain existing assessment-id order.

All old candidates remain eligible. **No hard duplicate exclusion**: if there is no genuinely fresh alternative, the old fallback still returns an eligible retest. No new learner access denial, plan rule, hour limit, release gate, hourly target, date bound, score recalculation, or daily reminder. This avoids repeating the learner's exact problem when an alternative exists without creating a no-content blocker.

The new normalization helper is in the **private** schema, not exposed to the web API. It is explicitly revoked from PUBLIC/anon/authenticated and granted only to service_role; the existing selector's privileges remain unchanged. It treats signed `+6x` and `-6x` as different, as well as `<=` and `>=`.

## Actual verification

`supabase/tests/p1p5_d10_08_fresh_retest_math_prompt_priority_rollback.sql` requires PostgreSQL 17, explicit `iclub.e2e_isolated=true`, exactly two synthetic fixture users, and runs its synthetic mutation within `BEGIN ... ROLLBACK`. It validates all five real duplicates, preservation of maths signs, constructs a temporary retest assessment with an **artificially earlier ID** containing a duplicated learning question, proves the retest selector nevertheless chooses a mathematically distinct real reserve, and then retires *only in the disposable transaction* the novel alternatives to prove a retest is still available via the old fallback. It verifies all original assessment/question/session counts after rollback and that the synthetic assessment is gone. The existing real signed owner JWT/PostgREST/PG17 E2E and Stage D release gates are also required.

**Scope boundary:** This runtime improvement addresses delayed retest prioritization, NOT diagnostic or mixed-content replacement. A separate version-safe private replacement content pack is needed for the other duplicates before any production content changes; the 71 historically presented P1-QUA-03 diagnostic instances must remain immutable. No answer key or protected question text is added to GitHub.

No live Supabase DML/DDL, no Vercel deployment, no `main` merge, no user-data reset, no progress or certificate modifications, no extension of Mathematics to other subjects, and no re-creation of the 12 architect-original Extra Hard.
