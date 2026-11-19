# Mathematics Practice v2 — owner clarification on content corrections and Season 2 history

Status: **scoped owner instruction recorded 19 November 2026**, from the iClub project conversation. This documents **how to handle content correction candidates**; it does **not** authorize a live Supabase SQL change, merge, academic publication or deletion of attempts.

## Confirmed instruction — correct Practice content, do not retain defects merely because attempts exist

Owner: past Practice answers are **not a release blocker** for fixing errors. The bank should be corrected rather than retaining wrong or ambiguous questions. The owner currently reports that the application is being tested only by the owner; treat this as beta operating context, **not** as proof that other learner records do not exist.

Implement this alongside existing `AGENTS.md`/history integrity constraints:

1. **Fix active Practice questions for future learners.** When the meaning, solution, options or key of a history-bearing item changes, publish a corrected *future-only version/replacement* using the project's existing governed content mechanism. Stop serving the incorrect variant once the correction is approved. Retaining an incorrect active question just to preserve attempts is not acceptable.
2. **Keep historical facts intact:** old attempts, submitted answers, original versions/keys for audit, final scores and previously issued certificates remain unchanged. Do not use previous attempts to mark new answers, silently recalculate scores, delete learner rows or wipe old access.
3. **Editorial clarifications that do not change mathematical meaning or keyed outcomes** can be prepared now for all affected IDs, including history-bearing questions. Approval and safe deployment path are separate from authoring; make pre/post version/content hashes and final source/DB mapping inspectable at release.
4. **No artificial external expert review gate.** Reuse legitimate prior approvals and verify the actual corrected candidate with proportionate math, three-language and input-evaluator checks.

## Current Mathematics Practice v2 work item

- Canonical [Issue #574](https://github.com/jteshaboev1984-ops/iClub_APP/issues/574) and [Draft PR #577](https://github.com/jteshaboev1984-ops/iClub_APP/pull/577).
- The 495-item per-question metadata-only review ledger: `docs/qa/math-practice-v2-495-question-coverage-20261119.csv`.
- The previously held three decimal-format questions, IDs **7710, 7714 and 7754**, now have explicit EN/RU/UZ decimal-input instructions in the source draft; **canonical answers, MCQ/options, diagnostics, explanation mathematics and historical attempts remain unchanged**. All three are no longer **content-edit HOLD** solely because previous attempts exist.
- The live input evaluator's format restrictions are a distinct runtime correctness issue tracked in Draft PR #575. Clarifying the input format fixes learner wording, not the actual deployed scorer.
- This Draft PR contains only source/document/QA changes. The published bank has not been updated.

## Owner suggestion — fresh progress view for Season 2, not a data-deletion decision

The owner indicated that when Season 2 starts, a **new history for everyone may be opened**. This is a **possible release design**, not yet a defined migration contract or permission to reset existing history.

Separate at least these concepts before implementing:

- **Season 2 Tours:** use the distinct Season 2 attempt/ranking/certificate records; leave Season 1 records available for historical review.
- **Practice:** currently has cross-season/global historical attempts. If a fresh Season 2 progress experience is desired, use a new period/generation view or new attempts while retaining historical raw events and already earned results. Do not assume a Tour season boundary automatically resets Practice.
- **Exam Prep:** remains separate; do not reset verified marks, mastery or Paper evidence.

To make this operational requires owner approval on **what gets a new visible start** (Practice dashboard progress, recommendation period, attempts, ratings, or more), exact effective date and rollback. Until then **no reset, truncate, bulk regrade or season activation**.

## Acceptance before actual production cutover

- Pin approved corrected question IDs and content digests against the active DB snapshot; verify all 495 active memberships and translations.
- For each change, distinguish `editorial_equal_key` from `semantic_version_required`; never rebind an existing attempt to a different semantic answer.
- Apply only the individually authorized, non-destructive future-serving update method; run protected signed authenticated E2E with history-before/after checks.
- Production/merge/publication requires separate explicit owner GO. No release step is implied by creating this draft or writing this decision note.
