# Mathematics P1/P5 — Stage B genuine Chromium written Core + signed HTTP/PostgREST integration

**Date:** 2026-11-02  
**Pull request:** [#457](https://github.com/jteshaboev1984-ops/iClub_APP/pull/457)  
**Exact green verification:** [GitHub Actions 41397847064](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41397847064), candidate source `bf3594fbccc7767e29cf664bef13ff8f052bd2dd` (**GREEN**).  
**Scope:** original production Math renderer (not a mock UI), browser→signed-local-JWT HTTP→PostgREST→actual published Math P1/P5 RPC/isolated PostgreSQL 17. The HTTP RPC results are real; the test data and temporary locale translations are synthetic.

## Academic and rollout rules retained

Grounded in `docs/exam-prep-written-learning-contract-v1.md` and `docs/exam-prep-written-equivalence-beta-acceptance-20261101.md`:

- Writing is performed **on paper**, not via compulsory answer field.
- **Criteria are optional.** “Next” does not depend on opening or understanding the criteria, and means only **plan advancement**, not `is_correct`, a grader score, L2/L3 mastery or examiner certification.
- Every paper and learner action is owner-authenticated and idempotent. Lost ACK must be resolved using read-only server status without automatic extra commit.
- RU/UZ/EN labels and content access may not reveal future tasks or unapproved criteria; protected personal, academic and legacy records are not modified.

## The 12 true browser scenarios that passed

| Screen width | English | Russian | Uzbek |
| --- | --- | --- | --- |
| Mobile, 385 px | P1 PASS; P5 PASS | P1 PASS; P5 PASS | P1 PASS; P5 PASS |
| Desktop, 1280 px | P1 PASS; P5 PASS | P1 PASS; P5 PASS | P1 PASS; P5 PASS |

Each scenario **closes the entire Chromium browser context** and opens a completely fresh context with the same temporary signed user JWT. In both components, the Math card offers server-owned **Resume**, retains the same `session_id` and original objective answers, reaches the same paper-based written step, and renders localized `Criteria/Критерии/Baholash mezonlari` and `Next/Далее/Keyingi`.

- Written step does **not** demand a textarea submission, uploaded file or self-awarded marks.
- Clicking criteria calls the real `get_exam_prep_written_criteria_safe_v1` RPC and displays nonempty owner-scoped requirements. Criteria retrieval changes **zero** academic progress rows.
- DOM horizontal width does not overflow in the 12 tested viewport-language-paper combinations.
- On the final Uzbek desktop visit for **both** papers, clicking actual UI **Next** calls `advance_exam_prep_written_step_safe_v1`. The HTTP request fully commits on real local PostgreSQL, then the adapter intentionally **drops only its client acknowledgment**. Client reconciliation calls the actual `get_exam_prep_written_step_status_safe_v1`; each session has **exactly one** durable `private.exam_prep_written_step_advances_v1` for that item and **zero** written responses to the same item. No synthetic exam grading or written correctness event was manufactured.
- A second fake user cannot read the first user's paper-step status.

Exact CI log marker: `STAGE B TRUE MATH UI HTTP WRITTEN CRITERIA NEXT RELOAD PASS`, two rows with six language/width scenarios each and `oneRealNext:true`, `duplicateWrittenResponses:false`, `foreignDenied:true`.

## Critical **localization fixture distinction**

The current migration-only disposable database lacks the **operational RU/UZ approved locale data** populated outside migrations in the existing controlled beta. The production owner-operated academic/localization ledger is deliberately **not copied into the GitHub repository or dumped into CI**.

The first isolated attempts **properly failed closed** on `exam_prep_written_locale_approvals_incomplete`. The final CI permanently asserts that activating the written mode with missing approved languages returns a database check violation and leaves the mode **disabled**.

Only *after this negative gate assertion*, a `PGOPTIONS='-c iclub.e2e_isolated=true'`, 2-fake-user-only fixture inserts explicit **synthetic placeholder locales** (academic and language refs named `DISPOSABLE_SYNTHETIC_CI_NOT_*_QA`). These placeholders are **not approved academic translations**, must never be offered to students, and are used **solely to exercise locale gating, render UX, HTTP auth, persistence and recoverability** in a disposable DB that is immediately destroyed. The CI test does **not** certify the mathematical meaning of those placeholder criteria.

A separate **production read-only** query on 2026-11-02 confirmed that for eligible published tasks, P1 had 866 criteria / 170 tasks and P5 had 865 criteria / 164 tasks, and the current production review ledger yielded **zero missing RU locale and zero missing UZ locale criterion matches** by the actual source-MD5/approved-state rule. These are metadata coverage checks, **not a new human review of 1,731 translations or a retroactive independent certification**. No production update was performed.

## Scope of the CI workflow and remaining Stage B

PR #457 introduces only:

- `supabase/tests/p1p5_isolated_http_written_browser_allowlist.sql` (hard-guarded **test-only** config/locale scaffold, negative fail-closed assertion)
- `scripts/p1p5-isolated-http-written-criteria-next-browser.cjs` (actual Chromium UI with signed HTTP and data invariants)
- Extension to `.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml` after all prior generated-learner cleanup
- This evidence and persistent roadmap/Issue #450 updates.

The *same* successful CI execution also reran existing genuine P1/P5 diagnostic + learning, correction, real after-due retest and isolated clock, original lost-ACK browser resume, signed HTTP mixed transfer, timed section, full papers, and governed synthetic user cleanup. No product runtime, DB migration, academic-state table, feature flag or production account changed.

**Stage B still IN PROGRESS**: hosted Supabase GoTrue real auth token refresh, actual consenting beta-learner Telegram WebApp/mobile session lifecycle (and any non-test real-world integration fault found there), plus separate verified human beta weekly reviews. This isolated JWT/PostgREST+Chromium test cannot establish live Telegram behavior or real human consent. **Mass rollout NO_GO** persists.
