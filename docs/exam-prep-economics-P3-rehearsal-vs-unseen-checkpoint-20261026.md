# iClub APP · Economics 9708 P3 · source exposure, 12 additional accepted QA candidates, and rehearsal-only blueprint
**Date:** 2026-10-26 · **Production state:** program `draft`, `launch_enabled=false`, learner access remains **OFF**.

## What was checked, not rechecked

Previous checkpoint `docs/exam-prep-economics-working-plan.md` section 11 already confirmed **24** direct A-Level Paper3 skill MCQ sources with completed internal academic + EN/RU/UZ checks and `status=candidate` in existing private Exam Core. They were NOT academically reaudited again.

This turn explicitly checked actual paper contract in `private.iclub_exam_core_papers_v1` and official Cambridge syllabus 9708 for 2026–2028, version 2:
- **P3: 30 multiple-choice questions, 75 minutes, 30 marks.**
- **Tests A Level directly**; AS is assumed prerequisite and should not be the direct target.
- P3 original existing `papers` record remains `draft`. The official syllabus does not prescribe an obligatory distribution 8/7/4/3/8 across Units7–11, so internal rehearsal spread is not an official Cambridge weighting.

## Learner exposure risk found in real records

A scoped **read-only** query covered **84 source question IDs**: 24 existing QA-pass + 30 A1 + 30 A2 legacy sources. It checked five existing answer history sources:
`public.practice_answers`,
`public.practice_session_answers_v4`,
`public.practice_drill_answers_v4`,
`public.tour_answers`,
`public.tour_session_answers_v4`.

Summary (no personal user IDs retrieved/stored):
- Across 84 IDs, **zero stored answer events** found in these five tables.
- However, **each of the 84** has **one historical, now-inactive `practice_pool_questions` assignment**.
- No currently active Practice/Tours assignment for any of the 84; no historical Tour assignment among them.
- **Interpretation: a historic Practice assignment can correspond to prior on-screen exposure even without a submitted answer.** Neither zero recorded answers nor current inactive pool membership proves a question was genuinely unseen to a learner. Also it does not prove each student viewed the item.
- **Policy: ALL 84 must be `historically_possible_exposure`; cannot label them `protected_unseen` or guarantee unbiased diagnostic evidence without actual presentation-level evidence.** Candidates may serve teaching/rehearsal if later explicitly approved for that purpose, not automatically first-time diagnostics.

This finding is a *new* distinction from earlier screening, which excluded only active Practice/Tour assignment.

## Substantive new academic review: 12 additional items

The previous 24 were not reread. Newly inspected **12** source IDs from earlier A1/A2 shortlists that lacked substantive 3-language distractor QA:
- **Unit 8 (8):** `9179` poverty trap / taper; `9183` absolute and relative poverty; `9162` targeted aid; `9173` tradable pollution permit cap; `9168` privatisation and regulation; `9155` behavioural nudge; `9150` monopsony marginal labour expenditure; `9176` MRP 4 × $9 = $36.
- **Unit 10 (4):** `8989` internal and external value of money; `9019` subsidy forecast and government failure; `9009` inflation expectations shift short-run Phillips curve; `9231` demand movement along short-run Phillips curve.

All 12 were read with **full English/Russian/Uzbek question stems, 4 answer alternatives per language, answer key and full explanations**; each underwent first meaningful economic correctness, language equivalence and technical format analysis. **12/12 passed this internal content screen**, including MRP arithmetic and the difference between a short-run Phillips-curve shift and a movement along it. No external experts, no duplicate rereviews. This does not prove all future user presentation/exposure or official examination fitness.

Per-ID evidence with learning objective and outcome, no new exam answer keys:
`exam-prep/academic/economics-9708-mcq/A-P3-Units8-10-12-trilingual-QA-and-exposure-v0.1.json`.

## Actual safe staging performed (same existing private Exam Core)

One atomic guarded write added exactly these **12** to **existing** `private.iclub_exam_core_question_candidates_v1`:
- `paper_code='P3'`, canonical `level_code='A'` direct skill mapping.
- `status='candidate'` only; `qa_scope_status/qa_academic_status/qa_language_status/qa_format_status='pass'`.
- Each source had to remain active/published, complete and internally consistent across EN/RU/UZ, four distinct answers, pinned `source_snapshot_md5` matching live text and frozen initial review record; not linked to active Practice or Tours; no existing P3 candidate per ID; source has no image and Tour marker.
- Transaction fails/rolls back if fewer than 12 pass. No `ON CONFLICT DO UPDATE`, no user data changes, no new schema/migrations or branches.
- The previously held `9044` (EN stem urbanisation ambiguity) remains absent from Exam Core. Wrong-key legacy `9732` remains blocked and unchanged.
- **Post-write production read:** total **36/36 QA-pass `status=candidate`**, by unit: **Unit7=10, Unit8=8, Unit9=4, Unit10=4, Unit11=10**. **P3 approved=0, P1 approved=0.** Program still `draft/off`. Closed allowlist state `closed_catalog_preview`, **0 exposed MCQ**, `can_issue_learner_task=false`. `anon/authenticated` have no private candidate `SELECT`. The active Math version remains present `count=1`.

Nothing changed in `public.questions`, Practice, Tours, user scores, Mathematics evidence, localStorage, learner paths or UI.

## Rehearsal plan — not a released or unseen mock

A fully deterministic *planning only* 30+6 source-ID blueprint is in
`exam-prep/academic/economics-9708-mcq/P3-30-item-closed-rehearsal-blueprint-NOT-UNSEEN-v0.1.json`.

Its 30-item internal topic spread: Unit7=8, Unit8=7, Unit9=4, Unit10=3, Unit11=8, plus **6 reserves** (2/1/0/1/2).
- Coverage of all five A-Level units is now possible for **rehearsal planning**.
- The 30 do NOT constitute an actually issued/formally approved Cambridge mock. There is **no runtime/scores/mapping to learner**.
- This blueprint is **not unseen**: all IDs have historical Practice assignment. Reserve pool six is insufficient for an independent second 30-item set.

## Release decision and next substantive task

**NO-GO for learner-facing Exam Prep Economics P3.** Despite 36 fully internally QA-screened source candidates, there are **zero approved** and no guaranteed-unseen 30-item set.

For genuine first diagnostics, preserve source exposure truth:
1. A Level original private drafts from A1 (6) and A2 (6) provide **12 *drafts***, not yet source-approved or in the database, and no actual historic-visibility proof is necessary for their newly authored content. They remain under the private ChatGPT Library, not public GitHub. They require the same full academic review and a protected source import plan.
2. **At least 18 more genuinely independent A-Level MCQs** would be needed to reach a 30-item draft set *if the 12 originals are all validated*. That is **arithmetic minimum for one Paper3 form, not a sufficiency claim**. Reserve/retest pools need substantially more independent items. Prefer finding never-used sources with credible display-level evidence before writing all 18, otherwise create new originals in private Library in meaningful academic batches.
3. Don't mark 36 historic legacy candidates `approved` or use them for diagnostic/retest evidence until exposure policy and licence/source rights are explicitly safe. They may be promoted for educational rehearsal only under a separate well-defined product step.
4. Remediate/question 9044 only with versioned replacement or choose another clean source; never silently rewrite or rescore legacy data.
5. Written P2/P4 and learner-specific signed issuance/scoring remain separate no-go components.

**Last durable handoff:** `docs/exam-prep-economics-working-plan.md` section 12. No repeat QA treadmill, unnecessary tables/branches or production learner release.
