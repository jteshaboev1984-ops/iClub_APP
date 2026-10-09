# Economics 9708 — Stage 1 bulk source-scope pass + non-production pre-approval dossier v10

**2026-10-09 | Stage 1 still IN_PROGRESS | NO learner-facing release | Draft-only GitHub PR #337.**

## Reference authority and decision boundaries
1. Official [Cambridge International AS & A Level Economics 9708, examination 2026–2028, Version 2](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf); AS covers syllabus topics 1.1–6.5, A Level requires topics 1.1–11.6. This is the examinable boundary; optional coursebook examples are not mandatory independent Cambridge skills.
2. User-provided *Economics* fourth-edition coursebook used as pedagogical support and chapter reference. No protected book text/questions/figures copied. The chapter/Tour mapping follows the user-provided approved `Tour Map v1.0 — Economics (по книге) для 7 туров.docx`.
3. Approved workplan `docs/subject-ai-content-expansion-master-plan-v1.md` mandates syllabus map first, then original theory, Tutor card sources, question/diagnostic mapping, QA, and only then separately authorised additive release.
4. Preservation contract `docs/economics-9708-curriculum-practice-runtime-separation-contract-v1.md`: a syllabus point, proposed learnable action, book chapter, historical Practice question and versioned Tutor source are different identities. Draft updates never migrate existing questions, student attempts, certificates, progress or local storage.

## One large source-scope pass instead of 20-row increments
**All 107 unreviewed parent placeholders** from `docs/economics-9708-remaining-atomic-review-queue-v6.csv` received source-scoped, explicit editorial decisions, grounded in the official numbered syllabus and mapped book chapter.

| Measure | Previous v9 | Current working v10 |
|---|---:|---:|
| Official syllabus numbered parent IDs represented | 253 | **253** |
| Original parent points still without a scope decision | 107 | **0** |
| Distinct candidate atomic learning actions | 488 | **503** |
| Newly source-scoped parent points this pass | — | **107** |
| Parent points retained as one integrated action | — | **96** |
| Parent points split into multiple teaching/diagnosis actions | — | **11** |
| Resulting child proposals from those 11 points | — | **26** |
| Teacher/examiner-approved canonical denominator | unknown | **STILL UNKNOWN** |

**Files**:
- `docs/economics-9708-atomic-candidate-register-v10.csv` — complete **503**-candidate working source map; no unreviewed placeholders, every provisional `runtime_allowed=false`, every exact question link `NONE_VERIFIED`.
- `docs/economics-9708-v10-all-107-source-scope-decisions-v1.csv` — one explicit Cambridge-numbered outcome, coursebook Ch, Tour, old action, retained/split action(s), and rationale per each of the **107** official parent points.

Corrections specifically **remove unintended scope inflation**, including:
- AS `1.5.1` means nature/meaning of PPC; mandatory standalone chart production cannot be inferred from that wording.
- AS `2.5.1` and `2.5.2` mean **meaning and significance** of consumer/producer surplus, not a separate compulsory numerical surplus-area calculation per point.
- AS `3.3.2`: no Gini calculation, whereas A Level `11.4.2` includes Gini calculation and Lorenz analysis.
- AS `4.2.2`: multiplier **not required**, and `4.2.3` does not require marginal/average propensities.
- AS `4.3.3`: detailed AD-component knowledge not required for this determinants point; `4.3.2` separately covers AD = C + I + G + (X − M).
- AS `4.5.1`: unemployment **meaning**; AS `4.5.3` expressly names **five** unemployment types/causes, provisionally split into separate source actions.
- AS `6.3.1` lists current-account components *and* balanced/imbalanced positions; `6.3.2` contains detailed four calculations.
- AS `2.2.8` explicitly includes implications for decision-making for PED, YED, XED (three distinct applications).
- A Level `7.3.5`: **definition of market failure only**. A Level `7.4.5`: deadweight welfare loss in positive/negative externalities, not a separate universal numerical calculation obligation.
- A Level `10.2.1`: relationship between internal/external value of money, not an unrelated financial-market module.

These are syllabus-scope **editorial proposals**, not individual question answer-key verification or full-textbook expert academic signoff.

## Full seven-Tour syllabus coverage and tier control

| Tour | Source book chapters | Official parent points | Candidate atomic actions | Tier |
|---|---|---:|---:|---|
| 1 | 1–11 | 51 | 75 | AS |
| 2 | 12–20 | 46 | 65 | AS |
| 3 | 21–29 | 34 | 60 | AS |
| 4 | 30–37 | 47 | 112 | A Level addition |
| 5 | 38–40 | 17 | 39 | A Level addition |
| 6 | 41–47 | 33 | 88 | A Level addition |
| 7 | 48–54 | 25 | 64 | A Level addition |
| **Total** | | **253** | **503** | **131 AS parent points + 122 A Level parent points** |

Book Ch54 provides exam preparation context, not a new independently numbered Cambridge syllabus topic. Every provisional source-mapped action keeps an explicit tier and Tour.

## Semantic overlap and avoidance of double mastery
- Scanned **all 503 candidate actions** across different official numbered parent points, comparing normalised learning-action titles.
- Found **0 exact repeated normalised action titles** across the complete register.
- Similarity heuristics flagged **98 related cross-parent candidate pairs**. **39** have been given provisional, specific scope distinctions in `docs/economics-9708-v10-semantic-overlap-review-queue-v1.csv`; **59** require individual semantic/educator review, not deletion.
- Typical distinctions: demand-elasticity **definition vs calculation vs determinants**; generic AD/AS model vs exchange-rate application; open market exchange-rate equilibrium vs determinants of changes; definition of monetary policy vs effects on the BOP; introductory AS policy vs deeper A Level assessment.
- **Do not** equate shared vocabulary or a common textbook example with two independently proven competencies. No automatic merge, no copying legacy question evidence to new child key and no mastery reset.

## Actual Tutor coverage, intentionally not inflated
A readback scan of **11 stored original editorial theory packages** verified **120 unique point+locale drafts**, exactly **40 official parent topics × EN/RU/UZ**, each with four nonblank explanation variants (**480 variants**), all `runtime_allowed=false`.

The latest 253-row matrix `docs/economics-9708-v10-master-academic-approval-matrix-v1.csv` separately records:
- **40** parent points having full **unapproved EN/RU/UZ overview drafts**; **213** parent points do **not** yet have these dedicated overview drafts.
- **503** proposed learning actions in the latest working register.
- **ZERO** independently reviewed/approved **atomic** theory cards and Tutor cards, **ZERO** independently verified exact question-answer links; not because no information exists in legacy questions, but because exact-source QA has not been conducted for these new skills.
- Source approval, bilingual language accuracy, rights and accessibility remain pending across all unfinished content.

**No claim** that the original overview drafts already cover the proposed 503 child skills. This blocks premature progression to content “100% done” metrics.

## Existing learner-state and Tour pool compatibility
The original approved Economics Tour Map planned **60** Practice questions in each Tour, while the live database as earlier verified contains **70 distinct active questions in each of seven Economics Practice pools (490)**, with another seven *inactive* associations in Tour 2. This remains a separate architect-held discrepancy, **not** a reason to change the working production arrangement. No questions were moved, deleted, reassigned, regraded or reactivated.

Original nonruntime SVG figures in `docs/economics-diagrams-v0/` remain publication-blocked until 390px rendering, academic diagram review, accessible labels and embedded EN/RU/UZ translation are complete.

## Stage-gate and next action
**Achieved:** one complete first-pass syllabus source-scope decision for every **253 of 253** Cambridge numbered parent points, with traceable candidate actions and source links. **NOT achieved:** a validated final independent skill denominator.

**Before Stage 1 can be approved**:
1. Independently review **59** still unresolved cross-parent semantic similarity flags and re-evaluate excessively split or redundant child actions in prior drafts.
2. Obtain content-owner/educator approval for canonical scope (including embedded AS vs A Level exclusions) and lock the final skill ID mapping without migrating historical user records.
3. Then only Stage 2: write teacher-reviewed original theory and Tutor cards for each approved independent skill × locale, with source version/hash and independent RU/UZ QA. Practice-specific post-answer reasoning and deterministic diagnosis are separate Stage 4 evidence, not current coverage.

**Economics Stage 1 status: IN_PROGRESS.** Chemistry and Biology remain queued. Informatics deferred. Work exists only in draft GitHub documents + private service-only tracker; **no Vercel, build, deploy, merge, runtime AI flags, question-bank changes, user access, localStorage, scoring, attempts, progress, certificates or payments were touched.**
