# iClub Economics 9708 · Paper 3 academic-source approval, 26 October 2026

## Architect decision overriding the earlier 'unseen' policy

**A learner may already have seen a question; this is not an Exam Prep blocker.** Treat historic Practice display or an inactive Practice assignment as a permitted content reuse signal, not an automatic disqualification for Paper1/Paper3 diagnostic, learning, or retesting. The app must never claim a specific question is guaranteed new/unseen if that is unknown. Keep no-duplicate-within-the-same-test and vary subsequent tests when possible. **Do not author at least 18 extra A-Level items merely to achieve unseen status.**

This architect policy replaces the opposite blocking recommendation in `docs/exam-prep-economics-P3-rehearsal-vs-unseen-checkpoint-20261026.md` section "Release decision" and previous `working-plan.md` section 12. Historical reports remain factual historical records of prior reasoning, not operative instructions.

## Production writes carried out, no new infrastructure

**On 2026-10-26, source-content promotion was completed in ONE guarded atomic transaction** on existing Supabase project `mmmduffgpvwjdpruzikw`:
- `private.iclub_exam_core_skills_v1`: the exact 36 previously QA-approved A-Level `skill_key` rows advanced from `candidate` to **`reviewed`**.
- `private.iclub_exam_core_paper_skills_v1`: the exact 36 related **P3 `direct`** mappings advanced from `candidate` to **`approved`**.
- `private.iclub_exam_core_question_candidates_v1`: the exact 36 corresponding `legacy_question_id` rows, each `qa_scope_status`, `qa_academic_status`, `qa_language_status`, `qa_format_status='pass'`, advanced from `candidate` to **`approved`**.

**Prewrite guarded checks** for each of the 36 reused the recorded per-ID full QA evidence in:
- `exam-prep/academic/economics-9708-mcq/A-reinforcement-25-trilingual-QA-results-v0.1.json` (24/25 pass, 9044 held).
- `exam-prep/academic/economics-9708-mcq/A-P3-Units8-10-12-trilingual-QA-and-exposure-v0.1.json` (12/12 pass).

No question QA was reaudited. The transaction additionally checked P3 contract exactly **30 MCQ/75 min/A Level**, Program `draft/off`, validated Library, source key+snapshot equality against the frozen `private.iclub_exam_core_question_review_v1` and live `public.questions`, level A and direct P3 relation, unchanged canonical theory SHA256, completed EN/RU/UZ theory cards, answer format, source active/published, no *current* active Practice or Tour assignment (past exposure explicitly allowed), and zero candidate mappings for held IDs **9044/9732**. It asserted row counts =36 at each approval step; any mismatched count would abort the entire transaction. No new tables, migrations, branches or public original answer keys were created.

**No mutations to `public.questions`, Practice, Tours, student attempts, grades, enrollment, Math, Auth or localStorage.** Original non-released draft question texts and keys remain private in ChatGPT Library.

## Post-write checks (actual production verified)

- **P3 approved** question links = **36**; original QA-pass records=36; source snapshots still match.
- **P3 A Level unit distribution** = 7:10; 8:8; 9:4; 10:4; 11:10. The 30/6 distribution within the blueprint is internal, not mandatory official Cambridge unit weighting.
- Closed catalog `private.iclub_exam_core_native_content_allowlist_v1('economics_9708','economics_2026_2028_v1','P3',100)`: `state='closed_catalog_preview'`, **36** safe MCQ metadata records visible to `service_role` only, `can_issue_learner_task=false`. This is not student question delivery and contains no answer keys.
- Planner `private.iclub_exam_core_native_plan_preflight_v1`: `state='blocked'`, `can_issue_learner_plan=false`; blockers for P3 = **`paper_not_published`**, **`assessment_runtime_not_verified`**, **`learner_diagnostic_and_plan_evidence_missing`**. Program remains `status='draft', launch_enabled=false`.
- Private source table `SELECT` denied for `anon` and `authenticated`; closed catalog function `EXECUTE` denied for those roles.
- P1 approved =0; legacy active Math Exam Prep program versions count =1.
- Known source blockers **9044** (EN/RU/UZ urbanization ambiguity), **9732** (wrong published answer choice) =0 candidate mappings and have NOT been rewritten.

## Current product interpretation

**An academically approved 36-question P3 CONTENT BANK exists.** A proposed 30-question blueprint plus six reserves can support a future controlled assessment, though no learner test has been issued and repeat pools/long-term question variety remain to be developed. This is not an official Cambridge past paper or licensed released assessment.

Blueprint that reflects the actual 36 approved rows and updated reuse policy:
`exam-prep/academic/economics-9708-mcq/P3-36-approved-academic-bank-and-30-item-blueprint-v0.1.json`.

No Economics screen or session is switched on yet. Content approval ≠ live launch.

## Next clear execution target

**Paper1, 30 MCQ, 60 minutes, AS Units1–6.** Currently **16** existing closed P1 candidates, all four QA status fields **pending**, links and skills still `candidate`, frozen source snapshot matched the review record at inspection. Reuse the **96 source review positions** from AS1+AS2+AS3 (78 legacy plus 18 original private drafts), *do not blanket rerun finished topic inventories*.

Carry out **one substantive full EN/RU/UZ academic/distractor review** on 24–36 *not yet thoroughly reviewed* AS existing questions (prefer the 16 already mapped + additional strong candidates). Use exact current source and canonical syllabus skill mapping; after confirmed pass, write candidate and four QA status only through **existing** private Exam Core with atomic guarded snapshots. When a sufficient complete P1 pool exists, promote reviewed skills, direct paper mappings and QA-passed question candidates to approved with an explicit fail-closed transaction. No new tables, no invisible-question barrier, no manual source rewrites.

Following content approval, the genuine blockers are runtime, learner evidence, Paper2/Paper4 written assessment, permission/QA and explicit architect GO for student release. **Do not release or claim user completion.**
