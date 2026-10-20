# iClub AI v2.1 — Chemistry + Economics academic editorial pre-screen

**Date:** 20 October 2026 · **Scope:** first 37 exact finalized-Practice question sources (111 language variants) · **Human approval:** PENDING · **Academic runtime:** OFF.

## Source of truth and evidence

The actual Supabase has 33 chemistry and four economics exact-question `answer_explanation` sets, all three `ru/uz/en` locale variants for each question, active and `quality_status=published` real questions, full localized question statements and database explanations. Verified each existing source card text against its SHA-256 hash and each published original-question fingerprint against its current live contents: **111/111 passed**.

Original source-pack lineage exists in the repository:
- `supabase/migrations/20260926014500_practice_ai4_chemistry_p1_atomic_structure_precise_v1.sql`
- `supabase/migrations/20260926020500_practice_ai4_chemistry_p1_electrons_precise_v1.sql`
- The 2026-09-25 `practice_ai4_economics_p1_precise_*` source migrations, plus the existing question-specific legacy cards

These migrations describe **original iClub explanatory summaries**, but a legacy `rights_status=original_iclub` is **not** a new Global AI release signature. The independent rights reviewer must verify authorship and no unauthorized reproduction from the commercial Cambridge books. Source lineage here is an audit lead, **not conclusive rights permission**.

## Substantive pre-screen

Compared all 37 EN explanations to their live question, answer key, options and original explanation; examined all 74 translated RU/UZ explanations for meaning and any obviously reversed scientific/economic logic. No outright contradiction of the keyed answer was found in this initial review. It is an **AI-assisted pre-screen**, not an independently signed academic or professional-language review.

Two editorial precision issues flagged in the [37-row review register](../docs/iclub-ai-v21-chemistry-economics-37-question-editorial-review.csv):
- Chemistry question **1908**: says a *p subshell* has a dumbbell shape. Technically a **p orbital** has a dumbbell-like shape and a p subshell comprises three such orbitals; the prepared explanation already makes the distinction. Reviewer should approve/clarify the question wording on a future governed content revision, without changing existing learner marks or attempts.
- Economics question **1081**: `P = MC` is the usual allocative-efficiency benchmark, but is not sufficient by itself under externalities/market failure. Reviewer should confirm the curricular simplification and whether the question or explanation needs a caveat.

All other questions are classified only as `AI_PRECHECK_NO_OBVIOUS_CONTRADICTION`, **never** as formally reviewed. No grades or answers were corrected.

## Genuine Study scope discrepancy, corrected

`app.js` `renderVideo()` opens subject-wide Telegram resources and **overwrites** its `lessonId` with a first/primary lesson ID. That ID is an event-tracking surrogate, not the selected lesson. It previously reached the academic selector. The current controlled update removes the misleading lesson-specific UI binding on this view while retaining the universal backend `lesson_topic` route for a future actual lesson screen. Practice exact-question and Tour attempt binding continue unaffected. No change to accepted Option A mark, UI visual styling, user progress or Mathematics Exam Prep.

## Readiness and release conditions

The reusable metadata-only preflight `qa/live_candidate/iclub_ai_v21_release_readiness_readonly.sql` covers any subject/surface and reports locale completeness, equal source versions, current question/lesson/Tour fingerprints, SHA-256 consistency, human approval flags, publication state. It cannot authorize publication; only a signed editorial process and explicit release decision can.

The 111 rows remain in the private academic registry with `published=false`, `revoked=true`, all four new approval booleans false, and `approved_at=NULL`. `academic_policy.enabled=false`; the Edge academic route is not enabled for real learners. Neither an AI pre-screen nor an inherited `approved` flag is permission to promote them. No paid model calls, no modified Math Tutor, no resets.

## Next governed milestone

Obtain independent evidence of rights, academic correctness for IDs 1908/1081 and the other exact sources, and verified RU/UZ/EN equivalence. Only then approve a coherent first batch, test a real wrong-answer owner with a finalized Practice record, verify correct/unanswered/foreign/active attempts deny, check source revocation and version drift, and release academic beta separately. The same single publisher and preflight process can then be reused across Biology, Mathematics (not Exam Prep), Informatics and future source batches without new subject-specific app code.
