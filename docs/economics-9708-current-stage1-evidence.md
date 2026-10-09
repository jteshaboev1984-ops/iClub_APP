# Economics 9708 — Current Stage 1 academic approval dossier

**2026-10-09 | Candidate for independent academic review | Stage 1 = IN_PROGRESS | Learner release = BLOCKED**

This is the ONE maintained current Stage 1 dossier. Do not spawn interim report variants. See [workspace index](economics-9708-workspace-index.md), which preserves earlier revisions by pinned Git commit without cluttering the working tree.

## Source hierarchy and method

- **Assessment authority:** [official Cambridge International AS & A Level Economics 9708 syllabus v2 for 2026–2028](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf), subject content printed pp. 15–34; updated Version 2 confirms no significant changes affecting teaching. The numbered syllabus parent ID and the AS/A Level boundary prevail over any draft actions.
- **Coursebook support:** user-uploaded *Economics for Cambridge International AS & A Level, 4th ed.*; 53 topical chapters (Ch54 exam guidance).
- **Approved iClub learning order:** user-uploaded `Tour Map v1.0 — Economics (по книге) для 7 туров.docx`; seven Tours by book chapter. Coursebook/Tour classification must not be substituted for exam syllabus tier or for live Practice question membership.
- **Existing app/data contract:** [subject source ↔ skill ↔ live assessment separation](economics-9708-curriculum-practice-runtime-separation-contract-v1.md).

## Proposed denominator, after first-pass semantic consolidation

| Metric | Current proposal | Approval meaning |
|---|---:|---|
| Official numbered Cambridge parent points | **253** | 131 AS + 122 A Level addition |
| Provisional individual teachable/diagnosable learning actions | **498** | **NOT approved** as an independently correct final denominator |
| Untreated official syllabus parent points | **0** | All underwent source-scope first-pass editorial treatment |
| Early source-scope decisions with missing rationale | **0** | All **29** previously flagged decisions now carry explicit syllabus-grounded editorial rationales, **not independent teacher signoff** |
| Automatically matched/merged historic production question IDs | **0** | Every skill still has `verified_precise_question_ids=NONE_VERIFIED` |
| Approved individual atomic Theory/Tutor cards | **0** | Stage 2/3 not approved/promoted |
| Learner runtime permissions | **0** | Every draft candidate has `runtime_allowed=false` |

**Per Tour candidate action distribution:** 1=75, 2=65, 3=60, 4=112, 5=36, 6=87, 7=63. This is source-map planning, not Practice question counts and not a learner-facing product value. AS candidate actions 200; A Level addition 298.

## Maintained evidence; no duplicate v11/v12 files

1. [Provisional action register](economics-9708-atomic-candidate-register-current.csv): **498** rows, immutable current draft identity and source status. Parent-to-action structure is **proposed**, not learner-approved.
2. [Consolidated 253-point editorial source decision register](economics-9708-current-253-point-decision-register.csv): 253 rows, includes restored detailed justification for all former 29 early sparse decisions, source point, chapter, Tour, all current keys and separate approval flags.
3. [Semantic overlap review](economics-9708-semantic-overlap-review-current.csv): **99** cross-parent potentially related pairs, each now has a specific editorial distinction and provisional **KEEP DISTINCT** decision. Zero flagged pairs remain without an editorial rationale. **Not an examiner/teacher approval; possible unflagged semantic duplicates cannot be ruled out by a lexical search.**
4. [Parent/topic and locale approval matrix](economics-9708-academic-approval-matrix-current.csv): all 253 points reconciled to the same 498 keys, EN/RU/UZ parent overviews and skill-level release blockers; no phantom approval.
5. [Official point registry](economics-9708-official-subpoint-registry-v1.md) and [book chapter/Tour crosswalk](economics-9708-syllabus-chapter-crosswalk-v1.md); original audit and question gap triage separately retained.

### Three meaningful corrections from semantic/source review

The earlier **503** proposals are superseded by **498** after removal of **five unpublished draft-only provisional keys**, with every change preserved in Git history and no live IDs changed:

- **11.2.1:** official syllabus requires the nominal-vs-real exchange-rate distinction and trade-weighted rates. Duplicate `ECON-9708-11.2.1-01` retired, while `-02` now states the combined nominal-vs-real task and `-03` retains trade-weighted rates. Draft numbers may have gaps; preserving surviving draft keys is safer than unnecessary renumbering.
- **8.2.5:** official policy requirement presents redistribution mechanisms as *examples*. The four speculative compulsory policy child-mastery outcomes were consolidated into one integrated policy-evaluation action `-01`; old draft `-02`, `-03`, `-04` retired. Negative income tax, universal and means-tested benefits and basic income remain valid **examples**, not four separate compulsory Cambridge-numbered requirements.
- **10.3.1:** official five policy categories retained as five provisional children. Standalone `-06` multi-policy synthesis was retired as a separate mandatory denominator item; it remains valid **AO3 applied evaluative teaching** in exam-style questions, not a sixth named policy category.

**Historic removed provisional keys were never live learner progress, Practice, mastery or user identities.** Git history retains exact provenance. No other keys or historical question mappings silently merged.

### Cross-parent overlap disposition and remaining true academic gates

The full working register was re-scanned **after** the 503 → 498 correction. A keyword similarity filter now detects **99** cross-parent pairs: the 98 previously reviewed pairs remain valid, plus one new `8.2.1` equity/equality **definition** versus `8.2.5` equity/equality **policy evaluation** relation. Every one of the 99 has a distinct preliminary rationale. Treat this as **completed editorial semantic triage**, not exhaustive proof of no duplication.

**Recommended editorial disposition: keep the 99 separately identifiable pending expert confirmation**, primarily for reasons of (a) definitions versus applied causal analysis, (b) different economic markets or models, (c) AS foundation versus A Level extension, (d) calculation versus interpretation/evaluation and (e) same analytical method in different exam contexts. A future qualified reviewer can still overrule any proposed distinction. **No shared learner mastery, implicit co-credit or automatic skill equivalence** is authorised.

## Real source and teaching readiness

Across **11 retained original EN/RU/UZ editorial JSON packages**, structurally verified **40 distinct official parent-topic overviews × 3 locales × 4 text variants = 480 original explanation drafts**. These are **unpublished parent overviews**, not 498 independently reviewed skill-specific Tutor cards. The other **213 numbered parent topics** have no dedicated trilingual overview draft. Original chart SVGs and caption JSON remain isolated in `docs/economics-diagrams-v0/`, still lacking full mobile 390px and in-image EN/RU/UZ QA.

The official syllabus permits a range of legitimate examples and commands; **one listed example is not always one compulsory independent skill**. Conversely, independently assessable computations or markedly different market mechanisms may justify more than one action per numbered parent. The 498 is therefore a candidate curricular decomposition, **not a Cambridge-published number**.

## Real production and methodology compatibility — no side effects

- Historic approved Tour Map: 60 Practice questions per Tour. Read-only production snapshot (2026-10-09): 70 **active distinct** Practice questions in each of seven Economics pools, 490 total; Tour 2 additionally has 7 inactive links. **Do not silently fix or reshard** these pools; this policy discrepancy remains for the architect's explicit decision.
- Never remap historical `question_id`, answer key, attempts, scores, student progress, mastery, certificates, access permissions, payments, localStorage or Tour course placement based on draft changes. Parent overview content cannot be counted as verified child answer evidence.
- No Vercel API/build/preview/deploy, merge, production AI activation or live learner changes in Stage 1 preparation.

## Decision package for independent academic signoff

| Review gate | Current state | Required evidence to close |
|---|---|---|
| Official syllabus parent coverage (253/253) | **EDITORIAL PASS** | Teacher agrees no compulsory Cambridge area absent/out of scope |
| Atomic decomposition (498 proposed actions) | **PROPOSED** | Reviewer confirms teachable, independently diagnosable boundaries; can retain/split/merge with traceable evidence |
| 29 formerly sparse rationales | **RECONSTRUCTED** | Independent academic reviewer validates each, including five former draft-only keys retired |
| 99 semantic overlap distinctions | **EDITORIAL PASS** | Independent subject reviewer accepts or changes each relation; zero auto-merge by the system |
| AS vs A Level, syllabus exemptions, book/Tour order | **STRUCTURAL PASS** | Teacher checks difficulty and validity per skill; do not transfer A Level add-ons to AS |
| Precise verified question+answer key per child | **NOT STARTED** | Independent rights/assessment check in later stage, no fabrication or broad parent-level inference |
| EN/RU/UZ Theory and Tutor teaching readiness | **NOT APPROVED** | Original correct child-specific content, 3-language technical and pedagogical QA |
| Graphs, copyright/source rights, mobile and accessibility QA | **NOT APPROVED** | 390px visual rendering and independent diagram/text check |
| Runtime release / rollback / production compatibility | **NOT AUTHORISED** | Separate express approval, guarded release procedure and data preservation tests |

### Signoff record — must not be filled by an automated editorial pass

**Independent academic reviewer:** PENDING  
**Review date and syllabus version acknowledgment:** PENDING  
**Approved canonical independent skill count:** PENDING (proposal = 498)  
**Exceptions / correction requests:** PENDING  
**Architect authorisation to proceed from Stage 1 to Stage 2:** PENDING  
**Separate release / production deployment consent:** NOT GIVEN

**Stage 1 = IN_PROGRESS until these gates are met.** No mass Tutor content authoring or skill-to-question runtime integration yet. Chemistry and Biology remain queued, Informatics deferred.
