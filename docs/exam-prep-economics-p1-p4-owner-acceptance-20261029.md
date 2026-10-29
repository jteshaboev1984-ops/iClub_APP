# Economics 9708 Exam Prep — owner acceptance of the current working stage

**Date:** 29 October 2026  
**Product owner:** iClub architect  
**Decision:** **CURRENT WORKING STAGE ACCEPTED; FREEZE ITS EXISTING PRODUCTION BEHAVIOUR.**  
**Scope:** Economics P1–P4 entry, navigation, study-plan presentation and governed P2/P4 independent written practice. This is a **scoped internal owner acceptance**, **not** a general-audience launch, complete Cambridge syllabus coverage, publication authorization for held content, or independent learner-beta validation.

## Explicit owner feedback
In chat the architect opened the production app, reviewed the recent UI and said essentially **“вроде все работает”**. The architect also clarified that **all current beta accounts are theirs** and requiring every beta account to complete written exercises is **not a condition of closing the current working stage**.

Record this accurately: an owner-level manual UI smoke review, not independent real-student feedback, all-language physical device certification, or objective proof that all workflows are flawless. Do not require two extra beta learners merely to close this agreed internal scope.

## Freeze: what is accepted in the current working stage
1. One Economics entry route with all four cards **P1, P2, P3, P4**. P1/P3 use server-owned MCQ/diagnostic logic; P2/P4 use source-guarded written learning with existing academic sequencing and beta access.
2. P2/P4 work **is not graded by the app**. Its approved path is task → independent offline work → optional assessment criteria → idempotent Next. Next only advances an owned plan item; it is never an essay score, mastery evidence, correctness or Mentor Care submission.
3. Criteria are shown as **what an examiner assesses** (maximum marks, AO, levels where appropriate), not a worked solution or answer key. Bespoke iClub practice marks must not claim to be official Cambridge past-paper marking schemes.
4. The redundant extra beta-consent prompt was removed from the learner-facing Economics flow. Subject/plan admission is still controlled on the server; opening the screen itself must not enroll or grade anyone. Historic membership/consent records must remain preserved.
5. Compact, accessible Back button beside the heading in Economics and written tasks; the four summary values in a **two-by-two mobile grid**, four balanced columns on wide screens. RU/UZ/EN strings are present.
6. The existing non-grading policy applies cross-subject: Chemistry P3/P5 practical-skills cards **do not grade laboratory work or certify practical ability**; independent gated release remains OFF unless separately approved.
7. The data boundary remains unchanged: Mathematics, Practice, Tours, attempts, scores, source books, plans, user-subject selection, auth data and localStorage cannot be reset, repurposed or deleted to close this stage.

## Evidence and limitations at the checkpoint
- `main` and Vercel production were checked **29 October 2026**. Latest reported production deployment `e287a293cf9bc01f9476745827ef5aba0f407dc2` READY before this documentation-only acceptance.
- Previous governed SQL/CI checks verified **22 current Economics v3 written items, 22 private marking schemes, 20 maximum marks per Section A, 12 currently allocated written items in one plan and 3 plan advances**. Historical rows were preserved; **only 12 of 22** were made eligible to be served in the limited written beta. The remaining **10 stay held**.
- `scripts/qa-exam-prep-written-lab-no-grading-v1.cjs` and matching read-only SQL/CI from PR #414 confirm the no-automatic-written/laboratory-grade boundary. The PR #414 isolated CI PASSED.
- No additional student sessions were created or simulated to manufacture an independent beta result. No new screenshot-based visual certification is claimed beyond the owner's own observation.
- Source and task review, rights, syllabus mapping and exam-style mark allocation must remain version-controlled for **future publication**; passing current QA does not authorize releasing all draft or reserved content.
- A separate Economics P1/P3 submission/access parity P0 working-plan checkpoint has its own change/release gates; **do not infer its unmerged branch was shipped** from this internal UI acceptance. Keep remaining work tracked separately and do not silently discard it.
- Mathematics has a historical **student-entered timed self-mark** route. That is not an iClub-examiner result; untouched here. Do not rewrite its history under the Economics closure.

## Decision and next actions
**Closed now:** current owner-facing Economics P1–P4 UI and limited written Core functionality, subject to ordinary bug fixes.

**Not closed / not auto-authorized:** public release, independent beta validation, extra 10 written items, full Cambridge 9708 academic/syllabus closure, Chemistry gated features, or separate P0 hardening work.

The recommended next workstream is to continue the **existing Chemistry Exam Prep scope**, with independent LAB and Tutor protection unchanged. For Economics, make only evidence-backed fixes, security regressions and separately approved expansion; avoid cosmetic churn. Any future new Paper content or general release needs its own release decision and checks.

**No production database changes, user-state changes, access changes, application code changes or new feature enablement belong to this owner acceptance document.**
