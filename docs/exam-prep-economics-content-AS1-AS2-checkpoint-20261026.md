# iClub Economics 9708 — content checkpoint AS-1 / AS-2 (26 Oct 2026)

**Status:** academic authoring in progress; production Economics Exam Prep OFF. This file contains no question texts or answer keys. Public GitHub is not a confidential vault.

## Product owner update / working rules

Owner explicitly rejected extra tables/branches, repeated auditing without a specific defect, and any dependency on unavailable external experts. Adopted:
- One substantive 24–36 item academic batch at a time; work on new items and explicitly flagged deficiencies only.
- Internal academic review by AI + deterministic tests; independent outside experts are **not** a requirement. Distinguish internal preliminary verification from actual approved Exam Prep release. Do not use pass/approve labels without real checks, and do not demand indefinite second-opinion loops.
- Existing public.questions and Practice/Tours are the source for legacy items; no copying or mutation. Original question texts/keys in *personal ChatGPT Library* rather than the public GitHub repo.
- No new Supabase schemas/tables, no branch, no repeat of completed Stage 5B migrations. Query Supabase only for new inventory or essential regression/authorization checks; derive data locally wherever possible.

## Unnecessary table removed

The speculative `private.iclub_exam_core_authoring_blobs_v1` was empty (0 rows) and had 0 incoming foreign keys, 0 dependent views/functions when checked. A compensating Supabase migration `20261026054023_iclub_exam_core_remove_unused_empty_authoring_vault_v1` **dropped only this unused table** with safety guards (refuses if nonempty/referenced). Recorded in GitHub under `supabase/migrations/`. Do not reintroduce it. Keep the historical creation and rollback migration files intact for replay/audit; net schema has no vault.

## AS-1 batch (Units 1–2, Paper 1)

- 30 legacy original source IDs inventoried and provisionally reviewed; no need to rerun whole 30 unless a concrete new discrepancy arises. 16 existing candidate mappings for Unit 2; 14 Unit 1 proposed mappings only.
- Six original EN/RU/UZ MCQs authored for syllabus `1.2.1, 1.2.2, 1.2.3, 1.2.4, 1.5.2, 1.6.3` (item keys `EC9708-AS1-ORIG-001…006`). Personal Library file: `/iClub APP/Exam Prep/iClub_Economics_AS1_6_original_drafts_PRIVATE_2026-10-23.json`, **confirmed uploaded** on Oct 26.
- SHA-256 of entire private JSON: `bd7d8ae40167691dcfa2458872c4b55891c960b17ae029f35bc5eae0e0bfc6e5`.
- All six per-item SHA-256 hashes validated locally; distinct keys; EN/RU/UZ stems, exactly 4 distinct options and explanatory text present.
- 4 older IDs `8616/8619/8621/8625` overlap active Practice and remain unsuitable for independent unseen timed mocks.
- Syllabus 2.4.3 concerns on `8618/8622` were resolved in previous Cambridge academic review; **do not reopen** without new evidence.
- Conceptual similarity: original ceteris-paribus `003` relates to previously used economic-methodology questions, original PPC `005` shares tested principle with Practice question 8612; keep separated from equivalent unseen mocks, not falsely label as zero-near-duplicates.
- Total 36 in AS-1 draft/review, **0 Exam Prep academic approvals issued**. No full Paper 1 readiness claim.

## AS-2 batch (Units 3–4, Paper 1) — new work completed this turn

Single SQL inventory of relevant AS Level topics yielded **28** active published legacy MCQ with no active Practice/Tour assignment and no `-T-` provenance tag. Four excluded as near-overlaps: `8709` (LRAS as 8704); `8723` (structural unemployment as 8711); `8725` (information failure/merit goods as AS-1 original 006); `8734` (disinflation as 8722).

**24 selected legacy IDs**, each source question has 4 EN/RU/UZ options, nonempty explanations, published+active status, zero active Practice/Tour links. Their first pass checked English economic inference and calculations and RU/UZ question/correct option meaning, but **do not assert that all distractors and explanations are independently reviewed**:
`8702,8703,8704,8705,8706,8710,8711,8713,8714,8715,8718,8719,8721,8722,8724,8728,8732,8737,8741,8742,8743,8749,8751,8786`.

- Unit 3: 6 legacy.
- Unit 4: 18 legacy.
- Proposed exact skill mappings, notes and exclusion rationale (no keys) in `exam-prep/academic/economics-9708-mcq/AS2-P1-Units3-4-24-item-review-shortlist-v0.1.json`. No Exam Prep candidate mapping inserted into the database.
- Opposite-direction SRAS questions `8713` and `8732` are not identical, but do not put both in the same short unseen mock without an equivalence review.
- Calculations spot-verified: GNI=560+18-38=540 (8702); AD=430+120+180+80-110=700 (8705); GDP market=800+55-15=840 (8714); GDP growth=(252-240)/240=5% (8721); unemployment=0.3/(2.4+0.3)≈11.1% (8728); real buying power 1.04/1.07−1≈−2.8%, thus about -3% (8786).
- Six original EN/RU/UZ MCQ authored for `3.1.1,3.2.1,3.2.4,3.2.6,3.3.2,3.3.4`, item keys `EC9708-AS2-ORIG-001…006`. Private personal Library file `/iClub APP/Exam Prep/iClub_Economics_AS2_6_original_drafts_PRIVATE_2026-10-26.json`; **confirmed uploaded**.
- SHA-256 of entire AS2 private JSON `99c7b7ae0794a69915ccf72af363b0b4e6ca53e7ed49446de8a452daece0910d`.
- Programmatic QA across **12** original AS1+AS2 drafts: all source hashes match recomputed canonical JSON, 4 distinct options in all EN/RU/UZ versions, exactly one A–D key, three wrong-answer notes, no duplicate item keys, no near-identical EN stems *within these 12* by text similarity >0.6. These checks do **not** certify the global bank has no conceptual duplicates.
- AS2 = **30 working items: 24 legacy + 6 originals, 0 new Exam Prep approved mappings**, no learner release.
- Unit3 government intervention still has other syllabus objectives for future targeted expansion (specific tax graphs, tax incidence variation, minimum wages, welfare distribution). Do not produce artificial evenly sized sets without topic evidence.

## Production safety

- No learner UI or Mathematics Exam Prep changes; no branch; no legacy question updates/inserts, no personal records touched.
- `private.iclub_exam_core_native_content_allowlist_v1` remains closed, `can_issue_learner_task=false`.
- Economics program `draft / launch_enabled=false`.
- Stored original question+answer content only in personal Library, **not public GitHub** and **not Supabase**. Library is the correct workspace for this draft phase; no extra DB table needed.

## Next (one substantive block, not micro work)

1. Close AS2 remaining **targeted** issues: evaluate all distractor translations and independent mock equivalents only on 30 new AS2 records; do not loop through completed AS1.
2. Start **AS-3 Units 5–6** with one 24–36-item syllabus spread, prefer existing unused legacy items, add only necessary original question content in personal Library.
3. Keep academic approvals and production release separate. No external reviewer dependency, no fake academic approval.
4. Update this checkpoint plus `docs/exam-prep-economics-working-plan.md` with actual counts and GitHub commits, preserving the latest checks.
