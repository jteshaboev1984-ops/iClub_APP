# iClub Exam Prep — Chemistry 9701 protected authoring checkpoint

Date: 2026-10-26. Working branch: `work/chemistry-9701-stage-h-20261026`.

## Non-negotiable security rule

The main `iClub_APP` GitHub repository is **public**. Therefore **no unpublished exam question bodies, complete multiple-choice options, answer keys, answer explanations, scoring logic tied to answers, or unpublished assessment rubrics may be committed to this repository**, including non-main branches. Branch names and draft states provide no confidentiality.

The previous working branch contained 26 original item drafts with keys and explanations. That branch reference was moved back to the latest known `main` commit via a conditional lease. **This does not guarantee erasure of copies or historical Git objects.** Those 26 drafts are permanently excluded from graded Exam Prep selection and assessment authority.

## Where confidential drafts actually live

Supabase project `mmmduffgpvwjdpruzikw` has two distinct **private** FORCED-RLS tables:

1. `private.iclub_exam_core_chemistry_p1_quarantine_v1` — 26 formerly public-Git-exposed drafts, **permanently non-releasable** by table CHECK constraints. Supabase migration `20261026101900`. Archive count 26, no source hash mismatch, no ordinary-user read privileges.
2. `private.iclub_exam_core_chemistry_p1_secure_drafts_v1` — freshly authored, never committed to public Git; as of this checkpoint, **9 new trilingual P1 draft-only items for AS syllabus topics 5–13**. Supabase migration `20261026102221`. All have `academic_review=language_review=format_review=pending`, and `release_enabled=exam_candidate_eligible=credit_mastery=false`.

These tables are not callable by the student UI and have no integration with native Exam Prep question issuing. `anon` and `authenticated` cannot SELECT. Service role has SELECT-only for review, not write. A standalone authorized academic review/promotion mechanism would be separate and versioned; do not reuse this public repository for item keys.

## Other previous groundwork still present in Supabase

- `private.iclub_exam_core_chemistry_paper_catalog_preview_v1` — isolated draft-only combined skill catalog, 154 regular + 12 practical skills; 348 Paper links.
- `private.iclub_exam_core_chemistry_p1_duplicates_preview_v1` — 37 exact normalized English-stem duplicate pairs (74 IDs), 13 with differing answer letters/options; review only.
- `private.iclub_exam_core_question_review_v1` — 1,180 snapshotted legacy Chemistry source questions, no edits to `public.questions`.
- `private.iclub_exam_core_question_candidates_v1` — 30 P1 legacy references, all still candidate, zero approved; four have recorded format/locale QA failures.
- `private.iclub_exam_core_written_tasks_v1` — three trilingual P2/P4/P5 authored drafts, all pending/release off.

## Completed private QA for new 9 drafts

- Exactly 9 distinct syllabus units, numbered 5 through 13; no duplicates.
- 9 mapped to existing direct P1 skills.
- All three locales, four answer options, explanations in each.
- Zero exact English-stem matches against existing published Chemistry source bank.
- All stored-content digests valid; no permission leaks or unexpected release/academic approvals.
- All key and translation reviews remain **pending**, not claimed as independent professional verification.

## Next actions (advance from here, do not repeat prior inventories)

1. Independently inspect the new private drafts' complete chemistry reasoning and translations, without changing historical questions. Record findings separately.
2. Author **new** protected content for the remaining AS topics 14–22 in the same private source (not the previously exposed versions), still draft-only.
3. Define a private assessor/reviewer signoff flow with provenance, immutable version hashes, test matrix and no premature mastery claims. Never use leaked drafts for grading.
4. Progress Chemistry P2/P4/P5 separately, respecting written/practical evidence and the already registered three pilot tasks. Locate original 24-item authoring package if it exists; do not manufacture its provenance.
5. Build the native question issuer only after source-quality and access gates are demonstrated; verify Maths legacy adapter, Practice, Tours, and stored histories. Final launch flags require owner GO.

## Production freeze

At this checkpoint: Chemistry program `draft`, `launch_enabled=false`, Library `visible_to_learners=false`, native plan preflight `blocked`. The previously live Maths, Tours and Practice paths have not been modified by this protected authoring work.

**This checkpoint contains NO unpublished question content or answer keys.**
