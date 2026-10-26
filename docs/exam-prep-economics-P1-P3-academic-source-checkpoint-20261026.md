# Economics 9708 — P1 and P3 academic source checkpoint (2026-10-26)

**Production remains CLOSED: program draft/off; papers draft; learner issuance disabled.**

## Completed academic source approval

Paper1 / AS Units1–6: 37 sources read in full EN/RU/UZ across stems, four options, answers and explanations. **36 pass; 8751 HOLD** for awkward Russian wording of the binding price-floor explanation. The correction is not applied to legacy sources. The 36 approved P1 questions target **35 distinct AS skills**, spanning six units (5,16,4,3,3,5). Paper1 specification: **30 MCQ / 60 minutes**.

Paper3 / A Units7–11: **36 approved** from previous 24+12 substantive reviews. Level coverage (10,8,4,4,10). Paper3 specification: **30 MCQ / 75 minutes**. Two known earlier source defects (9044 and 9732) remain excluded.

**Total academically approved MCQ sources 72 (P1 36 + P3 36)**. Neither paper is learner-accessible.

## Changes made to existing private Exam Core

A single guarded P1 transaction:
- 16 existing P1 candidates: four QA columns pending → pass.
- 20 additional P1 candidate links inserted with four QA statuses pass.
- 36 P1 question candidate links became status approved.
- 35 distinct AS skills became reviewed.
- 35 direct P1 paper-skill links became approved.

Source MD5 was verified against frozen question-review snapshots and current legacy source; canonical AS skill, direct Paper1 relation, published active source, three complete translations, four distinct options per language, A-D answer key and validated theory hashes were checked. Atomic rollback guards verified exact counts, exclusions and dormant program state. Source Practice sharing (IDs 8616,8619,8621,8625) is allowed by the architect; no existing Practice or learner records were edited.

**No new schemas, functions, migrations, branches, frontend changes or modifications to existing learner progress, Math, Tour, Practice or public.questions.**

## Confirmed safety AFTER database changes

Service-only P1 allowlist: 36 approved metadata entries; P3 allowlist: 36. Both `closed_catalog_preview`, `can_issue_learner_task=false`. Native plan preflight is `blocked` because each paper is still draft, assessment runtime has not been verified, and authenticated learner diagnostics/plans lack proof. Program `draft/off`. Private candidates and preview function inaccessible to anon/authenticated roles. Existing active Math version count remains one.

## Per-item evidence and paper structure

- `exam-prep/academic/economics-9708-mcq/P1-AS-37-item-full-QA-36-pass-1-hold-v0.1.json`
- `exam-prep/academic/economics-9708-mcq/P1-36-approved-academic-bank-30-item-blueprint-v0.1.json`
- `docs/exam-prep-economics-P3-academic-approval-20261026.md`
- `exam-prep/academic/economics-9708-mcq/P3-36-approved-academic-bank-and-30-item-blueprint-v0.1.json`

Each approved bank has an internal **30 main + 6 reserve** question-ID plan. Unit distributions are internal planning examples, not official Cambridge quotas; no answer keys or unpublished originals stored in this public repository.

## Controlling architect decision and next phase

Potential previous viewing through Practice is **not a blocker** for Economics Exam Prep, including diagnostics and repeated assessments. Never describe previously used sources as guaranteed unseen. Avoid exact duplicates inside one session.

**Next work is the technical learner path**, reusing existing Math host design and native Economics Core safely: authenticated question issuance, timing, server-side answers/marks, diagnostic results, study recommendations, error correction, retesting, anti-cheat and E2E. Written Paper2/4 assessment/marking remains separate. Do not publish Economics before architect GO and verified no-regression tests; do not redo QA on 72 approved MCQs without a specific defect.
