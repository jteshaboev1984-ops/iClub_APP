# Economics 9708 — Stage 1: atomic decomposition v4 and original graph source (9 October 2026)

**Release: BLOCKED. This is a draft academic/content development result only.**

## Primary reference
[Official Cambridge International AS & A Level Economics 9708 syllabus, examinations 2026–2028, Version 2](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf), especially pp. 25–34; also user-supplied *Economics 4th edition* chapters 31, 34–37, 40, 42–44, 46, 51–53.

## Stage 1 work completed in this slice
Previous draft `docs/economics-9708-atomic-candidate-register-v3.csv` had 356 distinct candidate learning actions, including **224 one-to-one placeholders** needing atomicity review. We decomposed **23 specific prior placeholder parent points** into **76 syllabus-scoped child candidates**:

- Microeconomics market structure and firm behaviour: `7.5.8`, `7.6.1`, `7.6.2`, `7.6.3`, `7.7.3`, `7.8.2`, `7.8.3`, `7.8.4`, `7.8.5`.
- Microeconomic intervention: `8.1.2`, `8.3.4`.
- Growth, unemployment, money: `9.2.5`, `9.2.6`, `9.3.4`, `9.3.6`, `9.4.7`, `9.4.8`.
- Inflation/unemployment: `10.2.5`.
- Development and globalisation: `11.4.2`, `11.5.3`, `11.5.4`, `11.5.5`, `11.6.1`.

**New master candidate file:** `docs/economics-9708-atomic-candidate-register-v4.csv`.

| Editorial metric | Before v4 | v4 |
|---|---:|---:|
| Distinct official Cambridge numbered parent points | 253 | **253** |
| Draft skill candidate records | 356 | **409** |
| Still-unsplit one-to-one placeholders | 224 | **201** |
| This slice's parent points decomposed | — | **23** |
| Child draft skill records created from these 23 parents | — | **76** |
| This slice's retired `-BASE` *draft identifiers | — | **23** |

The additional 53 records are the result of splitting 23 former one-to-one placeholders into 76 children, **not** new syllabus subject headings. All new child actions remain proposed; **409 is NOT a final approved skill denominator.**

### Critical compatibility rule
Earlier non-runtime EN/RU/UZ theory packages may reference `ECON-9708-<parent>-BASE` for some of these 23 points. Those parent-level texts are still useful **overview drafts**. They **must not** automatically count as 76 approved skill-specific cards. Map each child to its own approved source or an explicitly verified reusable source segment after teacher review; never delete old draft provenance or manufacture a source-to-skill pass.

**Specific syllabus scope corrections in v4:**
- `7.5.8` separates TR, AR and MR calculations; do not make profit-maximising output an automatic requirement of 7.5.8 (covered by other syllabus points).
- `7.6.3` separates four listed barriers: legal, market, cost and physical.
- `7.7.3` separates horizontal, forward/backward vertical, conglomerate integration, motives and consequences.
- `8.3.4` separates MRP computation from deriving firm labour demand.
- `9.2.6` separates definition, resource conservation, environmental impacts and mitigation policies.
- `9.4.8` preserves the difference between liquidity-preference money market and loanable-funds market.
- `10.2.5` separates traditional, expectations-adjusted short-run and long-run Phillips reasoning.
- `11.4.2` separates interpreting Lorenz and calculating Gini (the Gini computation is **A Level**, not AS 3.3.2).
The remaining **201** placeholders have not been approved as indivisible.

## Original non-runtime SVG diagrams added
Four **original source diagrams**, not textbook copies and not deployed:
1. `docs/economics-diagrams-v0/straight-line-ped.svg` — Q=10−P; checked three points with absolute PED 4, 1, 0.25.
2. `docs/economics-diagrams-v0/lorenz-gini-038.svg` — five equal population groups, trapezoid area below Lorenz B=0.31, Gini 0.38; shaded areas A=0.19 and B=0.31.
3. `docs/economics-diagrams-v0/ad-as-short-run-equilibrium.svg` — AD and SRAS crossing determines Y* and PL*; does **not** imply full employment without capacity benchmark.
4. `docs/economics-diagrams-v0/expectations-augmented-phillips.svg` — original SRPC and shifted SRPC alongside a vertical long-run curve at natural unemployment.

`docs/economics-diagrams-v0/locale-captions-v0.json` provides 12 EN/RU/UZ title, axis-label, explanatory caption sets. The SVG source artworks themselves currently contain English wording only. **They are NOT ready to be displayed to RU/UZ learners.**

## Targeted structural QA
- v4 CSV verified **409 distinct keys**, **253 official parent IDs**, 201 one-to-one placeholders, 76 newly proposed children, no missing parent IDs.
- Every record still asserts `NONE_VERIFIED` for exact matched question evidence and `runtime_allowed=false`.
- All four SVG files read back from GitHub; confirmed proper SVG structural wrapper, accessible title/description and source paths.
- All four diagrams have separate EN/RU/UZ caption records and a runtime prohibition.
- **Not completed:** independent teacher checking of exam syllabus interpretations, visually rendered mobile 390px QA, full RU/UZ diagram rendering, diagram pedagogical accessibility, protected-answer mapping, independent source rights approval.

## Non-negotiable guardrails
No deploys, Vercel API calls or builds. No changed production learner data, attempts, progress, content flags, question pools, answers, history, localStorage or entitlements. Stage 1 stays `in_progress`. Draft PR stays open and unmerged. Informatics deferred.
