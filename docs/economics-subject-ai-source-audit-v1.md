# Economics — Subject AI Academic Source & Production Bank Audit v1 (working)

**2026-10-08 | Stage 1 IN PROGRESS | READ-ONLY findings.** This is NOT a signed Cambridge syllabus map, finished skill count, or approved Tutor pack.

## Normative hierarchy and academic scope
- Coursebook: *Economics for Cambridge International AS & A Level*, Colin Bamford and Susan Grant, 4th edition (book states syllabus 9708, from 2023).
- Supplied `Tour Map v1.0 — Economics (по книге) для 7 туров.docx`: chapter aggregation below. **Not an official Cambridge syllabus or evidence of examinability in a candidate year.**
- Still required before stage 1 GREEN: official current Cambridge 9708 syllabus/updates for the selected exam year, complete point-by-point mapping, skill-split review and original-content copyright check.
- Chapter 54 *Preparing for assessment* is methodology (command words/exam skills) and must **not** be misrepresented as a separate examinable theory chapter.

## Seven-tour chapter reconciliation (document-backed)
| Tour | Book chapter boundaries | Scope |
| --- | --- | --- |
| 1 | 1–11 | AS basics of microeconomics, resource allocation and price system |
| 2 | 12–20 | AS government microeconomic intervention + introductory macroeconomy |
| 3 | 21–29 | AS macro policies and international economics |
| 4 | 30–37 | A Level consumer choice, market failure, costs/revenues and firms |
| 5 | 38–40 | A Level efficiency policies, redistribution and labour market |
| 6 | 41–47 | A Level macroeconomy and macro policy effectiveness |
| 7 | 48–53, with Ch54 separate | A Level balance of payments, exchange rates, development, globalization; exam-methodology after content |

This is the **existing curriculum sequence**, not yet an approved atomic skills map. AS/A Level tier boundary occurs between tours 3 and 4.

## Direct live Supabase read-only evidence (2026-10-08)
- `public.subjects`: economics = subject id 7.
- `public.questions`: 809 total; 790 active. All 809 have non-empty `book_ref`, `explanation_ru`, `explanation_uz`, `explanation_en`.
- Seven existing Practice pools, each linked to exactly 70 questions = **490**; DO NOT re-create or resize to an older Tour Map target of 60.
- `public.tours`: 7 tours in Season 1 and 7 tours in Season 2, each with 20 linked questions in Season 2 (140). Do not assume all are currently available to learners or change their state.
- `private.practice_ai_source_cards`, EN/RU/UZ each: **80 approved runtime** `answer_explanation` cards and **1** `result_context` card. Of the 80 answer cards, 4 have direct `question_id`; 76 have NULL `question_id` and are topical sources. **80 cards does not mean 80 individually covered questions.**
- `public.question_answer_diagnostics`: 277 rules representing 73 distinct Economics questions; do not claim general coverage before verifying that the published/incorrect-answer guard accepts these rules.
- `private.iclub_ai_subject_readiness`: economics/global = basic; generation_allowed=false. `private.practice_ai_policy`: disabled. `private.iclub_global_ai_runtime_config`: ui=false, gateway=false, generation=false, kill_switch=true, rollout_mode='off'. Keep unchanged.

## Bank metadata source alignment
Season 2 `book_ref` entries include exact chapter numbers, for example chapter 53 (global value-chain vulnerability), 52 (FDI and development), 49 (exchange rates), 50 (GDP per capita). This supports robust **read-only** question-to-chapter mapping.

Practice topic distribution by tour (total 70 each):
- Tour 1: Elasticity 16; Equilibrium 8; Demand 8; Basics 7; Intro 6; Market 6; Systems 5; Supply 5; Goods 5; PPC 3; Costs 1.
- Tour 2: Macroeconomy 45; Government Intervention 20; Circular Flow 4; Government intervention 1.
- Tour 3: International economic issues 38; Government macroeconomic intervention 32.
- Tour 4: Market structures 10; Costs/revenue/profit 10; Efficiency/market failure 8; Externalities 8; Growth/survival 8; Indifference curves/budget lines 8; Advanced microeconomics 7; Utility 6; Firms' objectives/policies 5.
- Tour 5: Policies to correct market failure 25; Labour market 25; Equity/redistribution 20.
- Tour 6: Advanced macroeconomics 70.
- Tour 7: International economics and development 70.

Legacy `topic` is NOT unique or academically atomic. Tours 6/7 each have one broad topic label for 70 questions, so use `book_ref` and `subtopic` to make atomic source mappings. Tour 2 has capitalisation variations `Government Intervention` vs `Government intervention`: avoid naïve exact-text matching or destructive metadata edits. Tour 1 has one Practice question labelled `Costs` despite AS micro focus: check actual `book_ref` and chapter before any mapping; this may be valid introductory cost material or mislabeled.

## Original QA challenges to resolve
1. Verify full 9708 syllabus for relevant year, particularly AS/A Level scope, relevant paper components and content changes.
2. Derive one skill only per independently teachable/diagnosable action; avoid hardcoded 53=53 skills.
3. Check per-chapter and per-skill unique question coverage (real overlaps and gaps), not just 7×70 totals.
4. Preserve existing approved Practice answer cards; use precision over broad coverage.
5. Distinguish complete Core static explanation from optional generative AI Tutor availability.
6. Check cross-language pedagogical accuracy; book excerpts/diagrams are **not** copied.

## Next intended read-only work
- Extract precise per-chapter inventory from `book_ref` across Practice and Season 2 Tours.
- Cross-check against official 9708 syllabus for candidate-year scope.
- Draft `ECON-...` canonical codes only after syllabus verification; submit proposed skill denominator and mapping for approval.
- Then independently draft and QA original theory/Tutor content, keeping runtime OFF.

**Preservation declaration:** No live subject data, learner progress, Practice/Tours, localStorage, AI entitlements, AI runtime configuration, payment config or source cards are changed by this audit.
