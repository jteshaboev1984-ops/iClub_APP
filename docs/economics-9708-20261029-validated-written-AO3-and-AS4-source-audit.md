# Economics 9708 — Official source verification, written crosswalk v0.2, AS Unit 4 item review
**Date:** 2026-10-29 • **Branch:** `audit/economics-9708-master-coverage-20261029` • **Status:** evidence-backed research, read-only; **NO BANK APPROVAL / NO LEARNER RELEASE**. Baseline GitHub/Vercel production SHA `ad048f9b008243169a4d4cb7ec8a4a576dc40674`. Live Supabase project `mmmduffgpvwjdpruzikw`. No schema/data/function/entitlement/user-history modifications.
  
## 1. Official Cambridge source explicitly rechecked

Source: [Cambridge Economics 9708 syllabus 2026–2028 v2 (Dec 2025)](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf). Verified by direct official PDF assessment and selected syllabus pages:
- AS topics 1.1–6.5; A candidates study 1.1–11.6. Syllabus source printed pp 15–34 (PDF 0-based pages 14–33).
- Four components and paper conditions: P1 30 MCQs/60min; P2 60 marks/120min A data20+B choice20+C choice20; P3 30 MCQs/75min; P4 60 marks/120min A data20+B unstructured choice20+C unstructured choice20.
- Approximate component AO weights **P1 and P3: AO1 47%, AO2 40%, AO3 13%; P2 and P4: AO1 33%, AO2 37%, AO3 30%**, official printed page 14 (PDF 0-based p13). MCQ therefore must assess contextual analysis and some evaluation, not just factual recall.
- Direct paper boundary: P3/P4 assess A-specific subject content with AS knowledge assumed; an AS numerical prerequisite does NOT by itself prove direct A-level skill coverage.
- Coursebook `Economics 4th edition A Level (2).pdf` independently inspected (637 pages): 53 teaching chapters 1–53 begin on uploaded PDF 1-based pages **11,18,26,...,459** with chapter 54 `Preparing for assessment` beginning **467**. The existing 53-chapter crosswalk is appropriate for navigation; uploaded PDF indexes are not independently verified printed-page citations of each legacy item. Book reference `EC9708:G2:...` is a content package ID, not a source page.

**Sampled strict exclusions and level differences:**
- AS 3.3.2 Gini coefficient **calculation not required**, while A 11.4.2 requires Gini calculations and Lorenz curves. Current internal titles/text appear to respect this.
- AS 4.2.2 **multiplier not required**; 4.2.3 **marginal/average propensities not required**. Source bank candidate sample stays within injections/leakages and equilibrium.
- AS 5.1.1 does **not** require macro policy conflicts/trade-offs as a tested source point; A Level 10.2/10.3 explicitly develops policy conflicts/effectiveness.
- A Level 7.4.7 cost-benefit analysis: **net present value knowledge not required**; current iClub Theory flags formal NPV as outside requirement.
- These are **selected source exclusions only**. Full independent semantic line-by-line validation of all 253 official identifiers and 498 internal splits remains pending; do not certify it complete on the strength of spot checks.

## 2. Corrected P2/P4 crosswalk: 22 tasks mapped to syllabus and candidate skills

New file: `exam-prep/academic/economics-9708-coverage/20261029_22_written_corrected_source_checked_crosswalk_v0.2.csv`. **22 task rows; 42 distinct existing canonical skill IDs referenced; all 42 IDs independently validated to exist in live program.** All these associations are **audit proposals**, not newly approved DB `paper_skills` relationships. Secondary links are particularly non-crediting until task-specific source/AO QA. The existing live v3 task versions and current 22-step learner plan are untouched.

Crucial source corrections:
- **P4.A.a:** previously assigned primary `11.1.1` (complete BoP account classification) although the prompt mainly computes an **AS-level** goods-and-services trade balance and evaluates the **A-level** rationale for exchange-rate intervention. Revised primary candidate: `11.1.2 / ECON-9708-11.1.2-05`; AS arithmetic `6.3.2 / ECON-9708-6.3.2-03` classified as assumed prerequisite, **not direct P4 coverage**. A Level `11.1.1` cannot be credited by this task as it lacks classification of capital and financial accounts.
- **P2.C2.b:** old `6.5.2` assignment was overbroad. Official AS `6.5.2` expressly enumerates fiscal, monetary, supply-side and protectionist measures, **not standalone evaluation of floating-rate depreciation**. Source-relevant proposed core is `6.4.3` floating depreciation, plus current-account causal reasoning; a qualified reviewer must decide how far AS-level international analysis may extend. **Marshall–Lerner condition and J-curve MUST NOT be obligatory for P2**: they explicitly occur at A Level `11.2.5` and are correctly mapped to **P4.A.c**. The approved P2.C2.b internal response requirements discuss basic responsiveness and lags without naming these A-specific constructs.
- **P4.B1** cannot credit all nine `7.6.4` firm-performance skills just by comparing efficiencies of oligopoly and perfect competition; candidate primary `7.6.4-06`, supplementary `7.3.1`, `7.3.2`.
- **P4.C2** concerns GDP per head as a development indicator and alternatives; `11.3.3` also contains Kuznets and other distinct official subrequirements not demonstrated by this one essay.
- **P2.B2.a** explicitly tests XED, not every PED/YED operation under broad 2.2.2.
- Written diagrams in P2.A.c are optional (`if helpful`), so do not mark mandatory independent diagram construction covered.

**22 P2/P4 tasks remain current internally approved original, source-bound EN/RU/UZ editorial content in a guarded three-seat beta, NOT a full-syllabus certified practice course.** Their first versioned 22 English-only drafts remain unreleased. No automatic written scoring/mastery is permitted.

## 3. Paper 2 / Paper 4 AO3 distribution — quantified design gap, not a grading bug

Live private `iclub_exam_written_mark_scheme_v1` metadata was inspected without exposing private answer requirements to the repository. Current iClub custom per-task marks are consistent internally, but their optional-choice 60-mark practice route allocates approximately:
- **P2:** compulsory Section A **2 AO3**, chosen Section B **4 AO3**, chosen Section C **4 AO3** → **10 of 60 = 16.7% AO3**, versus official paper-level **approx 30%**.
- **P4:** compulsory A **4 AO3**, chosen B **6 AO3**, chosen C **6 AO3** → **16 of 60 = 26.7% AO3**, versus official paper-level **approx 30%**.
- This is **a curriculum/blueprint mismatch for a hypothetical true exam simulation**, not evidence that existing original self-review practice must be re-marked. P2/P4 currently do not auto-grade essays or issue 60-mark paper results. The current internal scheme combines AO1+AO2 into one `ao12_marks` field; therefore separate AO1 vs AO2 composition (33/37) has NOT been objectively demonstrated.
- Any future exam-faithful blueprint adjustment requires a **new task/scheme version and explicit product owner release decision**, not silent changes to published P2/P4 written content or historic steps. The aim is better AO3 emphasis in future novel prompts and qualitative criteria, not algorithmic essay marking.

## 4. AS Unit 4: first content-reuse feasibility batch (unapproved)

New inventory file: `exam-prep/academic/economics-9708-coverage/20261029_AS4_24_legacy_MCQ_reuse_feasibility_unapproved.csv`: **24 distinct legacy question IDs**, from six AS Macroeconomy subtopics (4 per subtopic), mapped as provisional 21 primary canonical skills. This is NOT 24 added approved Exam Prep items.

- Source base: 89 active published legacy MCQ explicitly labelled `The macroeconomy (AS Level)`; all 89 structurally contain EN/RU/UZ fields.
- All 89 are already associated with Practice or Tours; **0/89** are untouched by both. In the selected 24, **24/24** already belong to Practice pools (0 Tour); therefore they can be reviewed as extra learning/retest material but **not claimed as virgin independent exam/diagnostic reserve**.
- 24/24 selected question stems and answer reasoning received a preliminary EN academic plausibility pass (not a separate qualified expert or final distractor-by-distractor review). 8 numeric questions independently recalculated using exact arithmetic with consistent expected result: IDs **8699, 8714, 8721, 9454, 9455, 9456, 9460, 9473**. A targeted RU/UZ comparison of eight numerically sensitive items confirmed arithmetic content/options and correct-key alignment in those samples; **all 24 need full EN/RU/UZ semantic and distractor review** before any approval.
- Stable source `md5(jsonb_build_object(...))` snapshots recorded in the CSV for all 24. No answer key, private criteria or worked answer appears in published GitHub file.
- The 21 distinct proposed primary skills include **two** already approved existing P1 skills (GDP↔GNI conversion and inflation/disinflation), so the theoretical highest additional *skill presence* from this exact sample is **19 new primary skills** if all pass future independent QA, taking AS Unit 4 at most from **3/46 to 22/46**. Even this would leave **24/46** primary skill slots uncovered and 0 independent unseen practice reserve. **Do not report this speculative 22 as live coverage.**
- Economically, the batch mixes AD/SRAS mechanisms, real growth calculations, circular flow, national income, inflation, unemployment and consequences. Some two-item pairs rehearse the **same** calculation skill, so volume is not equivalent to coverage diversity.
- All these items retain `SHORTLIST_UNAPPROVED_DO_NOT_SERVE_OR_RELEASE` status. No Supabase insert/update, existing question rewrite, paper allocation change or beta enable has occurred.

## 5. Live server check: exact MCQ paper-start selection and reserve risk

Repeated **all material filters** from `public.iclub_exam_native_mcq_start_v1` via a SELECT-only CTE: approved candidate, exact paper/version, reviewed canonical skill, approved paper link, QA pass, public question published, no banned IDs, four locale options, immutable snapshot match.

| Component | Unit | Live minimum | Live eligible primary skills | Slack |
|---|---|---:|---:|---:|
| P1 | 1 | 4 | 5 | 1 |
| P1 | 2 | 12 | 15 | 3 |
| P1 | 3 | 3 | 4 | 1 |
| P1 | 4 | 3 | 3 | **0** |
| P1 | 5 | 3 | 3 | **0** |
| P1 | 6 | 5 | 5 | **0** |
| P3 | 7 | 8 | 10 | 2 |
| P3 | 8 | 7 | 8 | 1 |
| P3 | 9 | 4 | 4 | **0** |
| P3 | 10 | 3 | 4 | 1 |
| P3 | 11 | 8 | 10 | 2 |

**All 11 pass now**. However these **four zero-buffer sections** are a genuine resilience risk: revoking an erroneous source/skill would block creation of NEW full papers until equivalent newly approved unique-skill evidence is available. Existing historical attempts remain valid and untouched. This also explains why only counting available 72 MCQs conceals production fragility.

Source inspect also confirmed `public.iclub_exam_native_mcq_get_v1` reveals `correct_index` and explanation **only after** `status='finalized'`; `answer_v1` enforces authenticated ownership and beta access plus active session/time constraints; this is a source-code inspection, **not an independent forged-authenticated-browser/BOLA penetration pass**. No new security vulnerability is alleged.

## 6. Priorities and strict next operations

1. **Content-first reliability:** review additional candidate MCQ for P1 Units 4, 5, 6 and P3 Unit 9 so every quota has nonzero independently reviewed alternatives. This is a floor, not proof of full syllabus depth. New unseen original papers will be needed for real independent variants even if a Practice-reused MCQ is academically excellent.
2. **Full academic direct mapping:** for P2/P4 complete exact source/AO skill mappings with sign-off, independent numeric/diagram/evaluation checks and 3-locale equivalence; correct candidate mappings through versioned *additive* metadata only if approved (no writing now).
3. **Remaining 253-point/498-skill audit:** continue source point-by-point against official PDF, then evaluate each missing primary skill with existing legacy options; separate reuse, new-original, and unsupported because excluded from syllabus. Never assume 1 item = full syllabus point.
4. **Approval gate:** only approve candidate after four technical QA passes + blind economic/translation check + dedup + snapshot + reserve collision policy; real production content modification must be its own tested gated step.
5. **Learner data safe:** do not change Vercel production, programs/entitlements, current Maths/Chem/Bio/CS, Practice/Tours, localStorage, plans, responses or archived 22 written drafts. No independent student E2E claim is made.

## 7. Source citations / continuation

- Cambridge primary: https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf (printed pp 14–36)
- Repo baseline: `docs/economics-9708-master-syllabus-gap-audit-20261029.md` and related 498-row/53-topic CSVs
- Written mapping source: `docs/economics-9708-written-22-bank-release-audit-20261029.md`
- Runtime: `public.iclub_exam_native_mcq_start_v1`, `..._start_diagnostic_v1`, `..._get_v1`, `..._answer_v1` and private candidate/skill tables
- **This addendum supersedes the original rough 22-task topic-only crosswalk wherever its primary official point differs**, notably P4.A.a and P2.C2.b. The rough CSV is retained as historical audit evidence rather than silently rewritten.
