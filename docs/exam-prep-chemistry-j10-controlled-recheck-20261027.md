# iClub Chemistry 9701 — J-10: controlled after-study recheck (27.10.2026)

**State: built and QA-tested in existing isolated branch; strictly NO learner release.** No new branch, no PR or merge, no production deployment, no data reset.

## What changed

- Reused the **22 separate original J-09 recheck MCQs** (EN/RU/UZ). Their options, detailed explanations and private answer keys remain **only in private Supabase**; public Git has **schema/migrations, student UI logic without original question content, fake test fixtures and reports**. All earlier 10 corrected manuscript versions remain privately archived. Previously authored J07 Entry and 45 P1 originals + preserved 26 older originals are unchanged.
- Added `private.iclub_exam_chemistry_recheck_control_v1` (initially OFF), `..._recheck_release_items_v1` (empty, exact source hash per approved question), `..._recheck_attempts_v1` (empty, owner-scoped). All three **FORCE RLS** with no authenticated table access. Key data never leave the private server, even though finalized explanations become available through an owner-authenticated RPC.
- Seven J10 RPCs:
  - `get_my_exam_prep_chemistry_recheck_shell_v1(locale)`: gate requires existing Maths controlled Beta eligibility, Chemistry separately approved and consented, **published Chemistry program and matching visible Theory version**, independent J10 owner release, exactly 22 approved source hashes and a **finalized Entry** by that learner.
  - `iclub_exam_chemistry_recheck_start_v1(client_key,entry_id,study_confirmed)`: uses the learner's own finalized Entry, requires explicit **self-reported** preparedness and an owner-approved manifest; one active recheck per user, one attempt per exact source manifest. **The check box is not independent proof that the student studied.**
  - `..._get_v1(session_id,locale)`, `..._answer_v1(session_id,item_order,choice)`, `..._finish_v1(session_id)`, `..._history_v1()`, `..._review_v1(session_id,locale)`: 22 new choice-shuffled questions, 30-minute timed flow, save/revise/resume, no pre-finish correct keys, post-finish explanations, single final score and comparison by **syllabus unit** of the independent prior Entry question vs fresh recheck question. **No mastery/grades are credited.**
- New independent `exam-prep/exam-prep-chemistry-recheck-native.js` with accessible self-report checkbox, RU/UZ/EN, progress, 22 question navigator, timer, finish confirmation, own recent sessions, detailed review per topic, visible limitations and back to Entry without resetting selected locale. Entry UI offers the feature **only when the additional server-side recheck shell returns approved and points to the same owner Entry session.** Host unmounts and relocalizes both Entry and Recheck; Mathematics, Economics and P1 mounts unchanged. `index.html` and CSS have uniquely versioned assets; uses existing host, no third-party UI.
- Recheck **only after Entry and after Chemistry Theory publication**. That publication has **NOT** happened. Existing source table `can_issue_learner=false` etc remains permanently enforced, while any later approved release is a separate explicit registry. **This feature is not enabled and cannot start for current real users.**

## Verified in the current session

- Fully ephemeral positive server test using **two currently eligible Mathematics beta user identifiers** but no real account login: transient Entry release, distinct recheck release, library publication, explicit Chemistry consent, start denied before Entry finish, start denied without self-report, start approved after finished Entry, RU/UZ/EN, correct keys hidden until finish, 21 saved choices including one wrong, one skipped and one edited, result **20/22**, personal topic comparison including entry results, other account read/save/finish/review denied, session resume, source-hash anti-retake, revocation refuses access without removing owned attempt. Entire `BEGIN...ROLLBACK`.
- Separate `BEGIN...ROLLBACK` expiry regression: after deadline responses denied, zero-answer score remains zero, repeated finalize immutable, withdrawal of Theory visibility denies further session reads but preserves underlying attempt. All ephemeral permissions/data fully rolled back.
- Repeatable synthetic JS UI tests:
  - `scripts/qa-chemistry-9701-j08-entry-ui.cjs`: 11/11.
  - `scripts/qa-chemistry-9701-j09-lesson-ui.cjs`: 16/16.
  - `scripts/qa-chemistry-9701-j10-recheck-ui.cjs`: 16/16 (conditional Entry offer, explicit checkbox, new questions, RU→UZ, comparison, return preserves language).
  - 20 additional JS/HTML/CSS source checks passed, including Math/Econ/P1 preservation, no localStorage use and no private key material in browser modules.
- Four live **read-only regression scripts**: J04 **32/32**, J08 **39/39**, J09 **36/36**, J10 **41/41**. Snapshots after tests: Chemistry Entry attempts 0, Recheck attempts 0, no approved release items, consent count 0, program Draft/OFF, library hidden, no P1 sessions. Mathematics 544 sessions/1979 responses, Practice 502 attempts/4816 answers, Economics one native attempt, user_subjects >=2098.
- Supabase security advisor has expected INFO `rls_enabled_no_policy` because private forced-RLS tables are deliberately unreadable, and WARN on authenticated SECURITY DEFINER RPCs. Each recheck RPC validates `auth.uid()`, current consent/cohort/owner releases plus owner session ID. Not an external penetration test; need real browser/token acceptance test before any student rollout.
- Git branch remains **behind current main**, which has unrelated production improvements. Do not fast-forward production, force reset, merge or delete branches without safely reconciling these changes. There are more current main commits now than at J09.

## Next stage J-11: controlled acceptance, still no production deployment

1. Verify exact Chemistry Theory package validation/owner release and reconcile the separate ENTRY, P1, RECHECK manifests with intended controlled-beta rollout. No automatic publication. Keep all unopened content in private Supabase.
2. Test real browser/account session and mobile with authorized beta account only after explicit separate consent; verify keyboard, screen readers, account switching, interrupted network, language changes, timeout, cross-device resume, review restrictions and no side effects on Mathematics/Practice/Tours history.
3. Review potential need for **more than one new item per topic** and longer-spaced reassessment before making any credible mastery claim. Currently 1 Entry + 1 Recheck per syllabus unit = only an approximate comparison; no skill mastery, grades or official Cambridge readiness.
4. Rebase/merge carefully only after cross-branch conflict audit, read-only production regression, and explicit owner GO. Do not silently roll out Chemistry to the existing Mathematics beta cohort; they require a separate Chemistry-specific opt-in.

**Explicitly not delivered:** browser/device-tested production Chemistry rollout, an approved Theory publication, real student enrolment, external academic expert certification, and automated mastery credit.
