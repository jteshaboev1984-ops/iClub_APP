# iClub APP — Economics 9708 · A-1 Paper 3 / Units 7–8 checkpoint
**Date:** 2026-10-26. **Status:** First A-Level-only academic bank pass completed; **NOT academic Exam Prep approval / NOT launch-ready**.

## Authority and scope

Official [Cambridge Economics 9708 syllabus 2026–2028, Version 2](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf), **printed pages 24–28**, confirms:

- Unit 7: advanced consumer behaviour and utility, indifference curves, efficient allocation, market failure/externalities, costs and profit, market structure, firm growth and pricing.
- Unit 8: corrective government intervention and government failure, income/wealth redistribution and poverty, labour market, monopsony, marginal revenue product, wage determination and economic rent.
- **Paper 3 tests A Level material.** AS subject knowledge is assumed but is not directly assessed as a Paper 3 target. Never award an A-level direct skill from AS prerequisite exposure.

The existing program is `economics_9708 / economics_2026_2028_v1`. Preserve `draft / launch_enabled=false`.

## Source inventory and selective reuse

Using **two bounded read-only Supabase queries for inventory and one SQL cross-check of selected IDs**, inspected source with explicit A-Level topic labels:
- `The price system and the microeconomy (A Level)`
- `Government microeconomic intervention (A Level)`

From **253** existing active published A-Level MCQs in the two explicit source topic buckets, **57** were not assigned to active Practice/Tours and had no Tour `-T-` provenance:
- Unit 7 explicit-labelled source: **28** usable candidate IDs;
- Unit 8 explicit-labelled source: **29** usable candidate IDs.

Selected **30** individual existing MCQs (15 Unit 7 + 15 Unit 8), with a direct A skill mapping per item. Avoided semantic repetition, shallow labelling-only items and AS-level substitutes. Important examples of excluded near-duplicates: 9135 vs 8890 (concentration ratio); 9202 vs 9155 (automatic-enrolment nudge); 9167 vs 9152/8938 (information/capture in government failure); 9205 vs 9162 (targeted vs universal transfers); 9133 (vaccination externalities already in earlier AS/A1 review). Exclusion is from **this batch only**, not deletion or invalidation of legacy questions.

Validation of all 30 selected, using one SQL selection/skill join:
- 30/30 source `published + active + mcq`;
- 30/30 four answer options in **EN, RU and UZ**, with filled stems/options/explanations; answer-key *shape* A–D;
- 30/30 source IDs are absent from active Practice/Tours assignments;
- 30/30 **canonical A** skill matches the proposed exact syllabus point, and Paper 3 mapping role is **direct** (`candidate` state, not `approved`).
- **No new source content, user evidence, scoring records or Exam Prep approval has been written.** We have not claimed an independent full semantic audit of every RU/UZ distractor/explanation.

Review-only file (no confidential question text or answers):
`exam-prep/academic/economics-9708-mcq/A1-P3-Units7-8-30-item-review-shortlist-v0.1.json`.

## Six original private draft questions — actual completed content

To add distinctive A Level reasoning absent from this selective legacy set, authored six original MCQs, each with EN/RU/UZ question, **four unique translated options**, explanation per language, **one unambiguous intended A–D key**, rationale for the three wrong options and a per-item SHA256 source check:

| Key | Syllabus | A-Level targeted skill |
|---|---|---|
| `EC9708-A1-ORIG-001` | 7.2.3 | Giffen good: income effect outweighs substitution effect |
| `EC9708-A1-ORIG-002` | 7.6.4 | Two-player strategic discounting and Prisoner's Dilemma Nash equilibrium |
| `EC9708-A1-ORIG-003` | 7.8.3 | Third-degree price discrimination, market segmentation and resale |
| `EC9708-A1-ORIG-004` | 8.1.1 | Specific tax versus ad valorem tax as price changes |
| `EC9708-A1-ORIG-005` | 8.3.8 | Possible wage and employment effects of a minimum wage in monopsony |
| `EC9708-A1-ORIG-006` | 8.3.10 | Calculate economic rent relative to transfer earnings |

Local deterministic checks **6/6 PASS**: three languages, 4 nonduplicate options each, correct-answer letter present, three other-option explanations present, expected internal hashes recalculated successfully, distinct stems and keys. Economic logic was first-pass checked during authoring (e.g., individually dominant discount in the payoff matrix, difference between marginal income/substitution effects, and monopsony effect described as possible rather than guaranteed).

**Confidential source file**:
`/iClub APP/Exam Prep/iClub_Economics_A1_6_original_drafts_PRIVATE_2026-10-26.json`
- Uploaded to personal ChatGPT Library successfully; also available as this conversation's mounted file.
- Full file SHA256: `c05fdb0aebda35cccb38f55eef3869cdba02aca3f1ffb0e8e1b3ff6080807ffb`.
- **Never copy full question content or keys into the public GitHub repository**. Stored in Library only, not in Supabase or the app.

## A1 totals / limitations

**36 A-1 working candidates**: 30 existing legacy + 6 original private drafts; each unit gets 18. This is a source review and draft inventory, not a fully approved Paper 3 test bank.

The canonical A skill inventory includes **148 skills across Units 7–8**. A batch of 36 questions does **not** establish complete coverage, adequate unseen timed mock pools, calibrated Paper 3 difficulty, or exam readiness. More batches will be needed after first coverage pass through A2 and after checking the source-specific paper blueprint.

## Preserve user guidance and production guarantees

- No external expert dependency, repeated AS1–AS3 full-audit loop or invented academic sign-off.
- No new Supabase tables, branches, release flag updates or user attempts. All database access this turn was read-only.
- No changes to legacy questions, live Mathematics Exam Prep, Practice/Tours, scores, localStorage or authored progress.
- Future academic verification is **targeted and issue-driven**. A legacy `published` status alone is not `Exam Prep approved`.
- Continue in one substantive content package, not question-by-question micro-phases.

**Next meaningful work:** **A-2 / Paper 3 / A Level Units 9–11**. Use one bounded direct-A-level source inventory, select 24–36 meaningful candidates with true direct skills, author original private questions only for holes. Then revisit first-coverage shortcomings across P1/P3 and document a safe path from source shortlist to actual academically approved Exam Prep bank *without breaking production*. No new tables/branches unless a demonstrated real need and explicit architectural decision.
