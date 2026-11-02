# Mathematics P1/P5 — Stage C first structural integrity / exact snapshot parity checkpoint

**Date:** 2026-11-02  
**PR:** [#458](https://github.com/jteshaboev1984-ops/iClub_APP/pull/458)  
**CI candidate:** `530210e603a3e86c4dbde7cf0cff243503cf2734`, [GitHub Actions 41399053076 — GREEN](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41399053076).  
**Status:** Stage C **IN PROGRESS**. Structural current-live snapshot **read-only PASS**; migration-only snapshot **CI PASS**; 101 written-task and 397 assessment-route snapshot differences remain an **explicit fidelity gap**, not a production mutation or automatically repaired user content.

## Two distinct, verifiable source snapshots (DO NOT conflate)

| Count | Current live Supabase (read-only) | Migration-only disposable PG17 (CI) |
| --- | ---: | ---: |
| Released learning questions | 486 | 486 |
| Protected withheld diagnostic / mixed / retest questions | 729 | 729 |
| **Active question versions** | **1,215** | **1,215** |
| Published written task versions | **334** | **233** |
| **Active academic materials** | **1,549** | **1,448** |
| Preserved retired question versions | 3 | 0 |
| Total question-meta rows including retired | 1,218 | 1,215 |
| Assessment item routing rows | **1,930** | **1,533** |
| Mathematics syllabus skill count | **81** | **81** |
| Canonical profiles / adversarial scenario definitions | 15 / 18 | 15 / 18 |

The older academic snapshot of **1,448** was accurate for **migration-only** sources. Live content has since changed through reviewed *operational content* releases. The difference is **+101 published written versions, +397 assessment item route rows, and +3 retired metadata versions** in current production. These numbers alone do not prove missing or defective learner experiences, nor identify which operational content should be copied into migrations. Crucially, **do not downgrade or delete** released production content to force a CI match.

## Actual read-only production integrity inspection

The checked-in, SELECT-only SQL file `scripts/fixtures/math-p1p5-stage-c-structural-integrity-readonly.sql` ran successfully against Supabase project `mmmduffgpvwjdpruzikw` on 2026-11-02. Its report returned **zero** errors in all 13 structural integrity classes:

1. Incomplete question text, answer existence, or RU/UZ/EN fields.
2. Question mathematics/scope/language/technical QA flags.
3. Written task published QA flags / required locales.
4. Learning versus withheld reserve exposure contradiction.
5. Question with no matching component syllabus skill.
6. Written task with no matching component syllabus skill.
7. Assessment routing to unindexed question.
8. P1/P5 cross-component question contamination.
9. P1/P5 cross-component written task contamination.
10. Withheld diagnostic/mixed/retest question exposed as learning.
11. Retired question used by an active published assessment.
12. Invalid or ambiguous question/written assessment item target.
13. Learning holdout incorrectly exposed.

It counted all 81 skills, checked 1,930 assessment-item routing rows, and verified the 15 canonical +18 adversarial **scenario definitions** still exist. **No answer keys or full protected written texts were exported from the database.**

This is **structural/metadata QA**, **not a mathematical re-solve** and **not a test execution of every scenario in 33 independent browser sessions**.

## Actual GitHub CI evidence

The same SQL ran against the PG17 disposable copy of all versioned `*exam_prep*.sql` migrations and, after passing, the unchanged full real HTTP P1/P5 Exam Prep battery executed. The CI log contains:

`STAGE C P1/P5 VERSIONED STRUCTURAL ROUTING & 15+18 SCENARIO CATALOG PASS {"actualActiveContent":1448,"publishedLearning":486,"protectedReserve":729,"publishedWritten":233,"retiredPreserved":0,"assessmentItemRoutes":1533,"skills":81,"canonical":15,"adversarial":18,"integrityAsserts":13,"allBadZero":true,"migrationOnly":true}`

And separately a GREEN run of the genuine RU/UZ/EN written criteria/Next/browser reload, signed JWT/PostgREST diagnostics, correction, post-due retest, mixed and full-paper journeys.

## Remaining Stage C / release decision

- **Source snapshot parity:** build a safe, versioned, **reviewed operational content fixture** for the 101 additional published written task versions, associated 397 route rows and 3 retired historical metadata versions. It must be *additive*, stable and exact; never wholesale re-import production student data or overwrite prior question/answer keys. Compare the version-aware active source manifest rather than hardcoding an outdated count.
- **Scenario execution:** 15 canonical / 18 adversarial scenario *catalog count* verified, but still require executable seeded behavioral paths for each model, including duplicate/retry, concurrent clients and cross-paper faults.
- **Actual locales/viewport:** 12 written UI combinations already passed in Stage B with explicitly synthetic placeholder translations; real approved content semantically remains a separate academic QA.
- **External boundaries:** hosted GoTrue token refresh, genuine consenting beta learners on real Telegram WebApp, four real weekly reviews and release governance not completed by this test.

**No production DB write, release toggle, migration, existing learner progress change or mass expansion occurred in PR #458. Mass release remains NO_GO.**
