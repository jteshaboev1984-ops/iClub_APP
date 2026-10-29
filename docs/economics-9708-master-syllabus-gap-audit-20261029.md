# iClub APP — Cambridge International Economics 9708 (2026–2028) Master Syllabus Gap Audit

**Date:** 2026-10-29 (Asia/Tashkent). **Status:** READ-ONLY academic inventory and implementation planning. **Source SHA:** `ad048f9b008243169a4d4cb7ec8a4a576dc40674` (GitHub main = Vercel production READY when inspected). **Database:** Supabase `mmmduffgpvwjdpruzikw`, read-only SQL. **Product:** `economics_9708` / `economics_2026_2028_v1`. **No production/DB/user-data modifications** in this audit. This report is NOT a Cambridge endorsement, academic certification, or release authorization.

## 1. Source hierarchy and evidence boundaries

1. Primary norm: Cambridge International AS & A Level Economics 9708 syllabus **2026–2028, version 2**: https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf . Check its 2026–2028 candidate applicability, 11 content units, assessment objectives, command words and component rules. Independent point-by-point semantic revalidation of the 498-node decomposition against every original syllabus bullet remains a sign-off task.
2. Actual state (highest authority for production): live Supabase read-only table/column/aggregate queries, current `main` and Vercel READY deployment at matching SHA. The 2026-10-23 status in `docs/exam-prep-economics-working-plan.md` is historical, not the live status.
3. Local project contracts: `docs/exam-prep-economics-p1-p4-owner-acceptance-20261029.md` (current functionality accepted; NOT full coverage or open public launch), `docs/economics-9708-written-22-bank-release-audit-20261029.md` (22-task beta), `docs/economics-9708-P2-P4-academic-language-source-closure-v3-20261028.md`, written-learning, academic governance, AI Safety, Mentor Care and Exam Prep integration rules. Attached year roadmap and Economics 7-Tour Map are study-planning sources, not official paper blueprints.
4. Secondary teaching source: Bamford & Grant, *Economics for Cambridge International AS & A Level*, 4th edition, user-supplied PDF. It has 53 syllabus-aligned teaching chapters and chapter 54 for exam technique. `book_pdf_pages` in this export are **1-based uploaded PDF page indexes, not verified printed textbook page numbers**. Chapters are matched to the 53 numbered official content sections in order; do not claim an independently checked printed-page citation.
5. No copyrighted Cambridge questions/official marking schemes or answer keys are stored in these exported reports.

## 2. Delivered audit artifacts and transparent classification

- `exam-prep/academic/economics-9708-coverage/20261029_canonical_498_skill_coverage_audit.csv` — **498 rows**, each internal canonical skill, exact official point code and teaching title in EN/RU/UZ from the existing iClub library; AS/A, paper ownership, applicable AS prerequisite, source chapter/PDF page range, approved P1/P3 ID links, preliminary P2/P4 task references, library status and evidence gaps. It is intentionally explicit: NO row is falsely labelled FULL coverage.
- `exam-prep/academic/economics-9708-coverage/20261029_53_official_topic_coverage_rollup.csv` — 53 official subsection headings at 1.1–11.6 grouping, numerators/denominators and absent/partial approved MCQ primary coverage.
- `exam-prep/academic/economics-9708-coverage/20261029_22_written_thematic_preliminary_mapping.csv` — 22 approved written parts and **proposed thematic connections only**, NOT reviewed/approved direct skill mappings; recheck exact primary/secondary point and AO before adopting.

**Status semantics:**
- `PARTIAL`: at least one individually approved MCQ with a direct primary canonical skill association; **does not demonstrate exam depth or independent repeatable assessment**.
- `MISSING_APPROVED_DIRECT_MCQ`: no approved direct question→skill association, even if legacy published questions or Theory/Tutor exist; NOT proof that no suitable source question can be reused after review.
- `NEEDS_ACADEMIC_VERIFICATION`: syllabus decomposition, AO, semantic translation, difficulty, data/diagram, originality or source mapping requires independent examination.
- `FULL` requires all applicable core internal skills, AO and exam action families with sufficient varied QA evidence and secure assessment configuration. **No FULL claim is established today.**

**Formulae:** MCQ canonical skill *presence* = number of distinct canonical skills with at least one approved direct MCQ / number of direct canonical skills. Official-point *presence* = distinct `syllabus_point` having such a skill / unique distinct official code in the database. Full-depth coverage must NOT be substituted by presence.

## 3. Production fact table (29 October 2026)

| Metric | P1 | P2 | P3 | P4 |
|---|---:|---:|---:|---:|
| AS or A direct internal canonical skills (denominator) | 200 | 200 | 298 | 298 |
| Approved direct skill–question mapping count | **35** | **0** | **36** | **0** |
| Approved MCQ question records | **36** | N/A | **36** | N/A |
| Approved released original written task parts | N/A | **14** | N/A | **8** |
| Approved direct canonical skills absent | **165** | **200 unapproved written mapping** | **262** | **298 unapproved written mapping** |
| Strict single-MCQ skill presence | **17.5%** | Not measurable | **12.1%** | Not measurable |
| Official-point MCQ presence | **32/131 = 24.4%** | Not measurable | **31/122 = 25.4%** | Not measurable |
| Verified full-depth coverage | NOT ESTABLISHED | NOT ESTABLISHED | NOT ESTABLISHED | NOT ESTABLISHED |

The **P2/P4 zero mapping** refers to approved direct `iclub_exam_core_paper_skills_v1` links, not zero written content! The written tasks themselves have internal editorial, language and source approval, and are released only in their protected beta. P3/P4 assume AS prerequisite content; these links DO NOT count as direct A-level question coverage.

**Other DB facts:**
- 253 unique official numbered source points in current iClub decomposition (131 AS, 122 A), elaborated as 498 internal canonical skills (200 AS, 298 A). The canonical skill count is an internal iClub product taxonomy, **not an official Cambridge count**.
- 498 Theory records with all three locale keys, 1,494 Tutor cards (three locales); their presence is not an assessment approval.
- 1,644 active legacy published MCQs available as **unreviewed reuse candidates**: 326 with explicit AS level hint, 503 with explicit A hint, 815 unclassified; plus 39 published input questions and 19 inactive MCQ drafts that are NOT approved direct MCQs.
- Approved MCQ mapping = P1 36 items/35 primary skills, P3 36 items/36 primary skills, with no cross-paper question ID collision; every one of the 72 carries source `difficulty=medium`, no nonempty `image_url`, and all 72 occur in ordinary legacy Practice pools (none in Tour associations). The original four-option arrays and EN/RU/UZ stem text structurally exist for all 72. **None of these observations proves academic parity of translations, deep AO, answer correctness under blind review or unexposed independent paper reserves.**
- All 72 existing `questions.book_ref` values are opaque `EC9708:G2:...` package IDs, not `ch=...;p_from=...;p_to=...` chapter/page references. They are provenance identifiers but **NOT validated edition/page citations**; do not conflate generated chapter lookup with original item source verification.
- Native learner history observed: two finalized P1 30-item paper attempts and one finalized 12-item P1 diagnostic, **no P3 attempt in the inspected table**. Prior attempts indicate runtime use, not fully independent exam correctness; preserve their historical evidence.
- Current `iclub_exam_core_programs_v1` has `status=published`, `launch_enabled=true` (historical October 23 plan's `draft/off` is obsolete); P1/P3 paper metadata `published`, P2/P4 full-paper metadata still `draft`. This does NOT imply a full public P2/P4 timed exam.
- Exactly one owned written plan of 22 tasks: 3 advanced, 19 pending. Approved 14 P2 and 8 P4 written parts; 22 old version drafts unreleased. `iclub_econ_written_beta_control_v1`: `enabled=true`, `max_members=3`. Do not change these rules.
- Current Vercel production READY deployment `dpl_BG9D8HXTpDrddkEg2pQPGYavbC3s` at `ad048f9b008243169a4d4cb7ec8a4a576dc40674` during audit. READY is not a full learner-browser/real-device acceptance test.

## 4. Full official UNIT coverage roll-up (direct approved MCQ primary skill, not full syllabus completeness)

| Official section | Level / MCQ | Canonical skills | Skill with approved MCQ | Presence | Uncovered |
|---|---|---:|---:|---:|---:|
| 1 Basic economic ideas and resource allocation | AS / P1 | 30 | 5 | 16.7% | 25 |
| 2 Price system and microeconomy | AS / P1 | 45 | 15 | 33.3% | 30 |
| 3 Government microeconomic intervention | AS / P1 | 19 | 4 | 21.1% | 15 |
| 4 The macroeconomy | AS / P1 | 46 | 3 | 6.5% | 43 |
| 5 Government macroeconomic intervention | AS / P1 | 27 | 3 | 11.1% | 24 |
| 6 International economic issues | AS / P1 | 33 | 5 | 15.2% | 28 |
| 7 Price system and microeconomy | A / P3 | 112 | 10 | 8.9% | 102 |
| 8 Government microeconomic intervention | A / P3 | 36 | 8 | 22.2% | 28 |
| 9 The macroeconomy | A / P3 | 66 | 4 | 6.1% | 62 |
| 10 Government macroeconomic intervention | A / P3 | 21 | 4 | 19.0% | 17 |
| 11 International economic issues | A / P3 | 63 | 10 | 15.9% | 53 |
| **Total** | P1 + P3 | **498** | **71** | **14.3%** | **427** |

The 71 is the number of primary skills; there are 72 approved MCQs because one primary skill has two. The combined 14.3% is a canonical-skill-weighted pooled metric **not an official composite exam score**.

**Entirely unrepresented official *topic groups* in the currently approved direct MCQ map:** 1.2; 1.4; 1.5; 3.1; 4.2; 4.4; 4.5; 5.1; 5.4; 6.4; 6.5; 7.3; 7.8; 9.1; 9.2; 10.1; 11.6. **17 of 53 groups have zero approved primary-MCQ evidence**. This is NOT proof the wider 1,644 legacy question pool contains none.

**Balance:**
- AS microeconomics, Units 1–3: **24/94 = 25.5%**; AS macroeconomics/international, Units 4–6: **11/106 = 10.4%**. The biggest immediate P1 imbalance is macroeconomics.
- A microeconomics, Units 7–8: **18/148 = 12.2%**; A macro/international, Units 9–11: **18/150 = 12.0%**. Percentages similar but depth extremely thin. Important weaknesses are Units 7 and 9.
- No verified chart/image questions in the current 72 approved MCQs. Historical text-only diagram references are not a verified visual assessment.
- No easy/hard difficulty classifications among approved records; review actual cognitive challenge rather than relabel scores.
- Computation, applications, AO1/AO2/AO3 and data analysis have not yet been item-wise adjudicated; mere lexical scan of prompts is not sufficient to claim balance.

## 5. P2 and P4: written practice vs examination simulation

**Actual protected bank:** P2 = Section A six parts plus two optional 2-part alternatives in Section B and two optional 2-part alternatives in Section C = **14 separate stored parts**. P4 = Section A four parts plus two alternative unstructured essays in Section B and two in Section C = **8 parts**. Two localized fictional original source case studies: Isara (P2), Nerava (P4). Their per-task and source QA is version-scoped internal editorial approval, **not Cambridge certification** and **not separate independent human subject-expert sign-off**.

The topic-links spreadsheet is an INITIAL proposed map of 22 task prompt themes against **20 distinct official point codes**; it is explicitly NOT an approved evidential link to all 200 AS/298 A canonical skills. Some original written tasks integrate multiple outcomes, which must be recorded as primary/secondary cross-topic mappings before a numerator is defensible.

Approved workflow remains:
- learner studies prompt/source and writes their own response outside the app;
- optional public assessment criteria describe expected skills/marks/AO but omit solved answers;
- Next advances owned study plan only, not mark, mastery, grading, completion evidence or successful essay outcome;
- mentor grading/review only through separately approved active Mentor Care;
- P2/P4 `paper_metadata` remains draft; sequential study of both optional essays is **NOT** a true Cambridge 60-mark timed paper. No new essay-upload/AI examiner or simulated grades.

Academic breadth: one data source scenario per P2/P4 is not enough to prove cross-context data-response transfer; current essay alternatives concentrate on elasticity/intervention/macroeconomic policy (P2) and trade/externalities/market structures/growth/development (P4). Expand contexts and commands to cover omitted official skills and AO3 evaluation, not by arbitrary task count.

## 6. Prioritised defects / risks

**HIGH — confirmed academic coverage gaps:**
1. **427 primary canonical MCQ skill-mapping gaps** (165 P1, 262 P3); 17 official topic groups have no approved direct MCQ. Existing 1,644 unreviewed published MCQs are a reuse reservoir, not an authorized direct exam bank.
2. Academic depth cannot be inferred from one mapped question. All approved candidate question metadata `medium`; no verified diagram assets. Need calculation/graph/data/application/evaluation/command-word and multiple unrelated scenarios testing.
3. No approved direct P2/P4 written-skill links despite 22 released editorial tasks; full syllabus written coverage % is currently **UNDETERMINABLE**, not zero-content or complete.
4. Repeated-source vulnerability: all 72 approved MCQs are present in ordinary Practice pools. Independent unseen timed/diagnostic reserve and question history are not yet demonstrated.
5. Actual `book_ref` stored as package code, not reliable edition/chapter/page mapping. Textbook PDF page index supplied separately is chapter navigation, not item-level provenance.
6. P3 true learner sessions have not been demonstrated by current inspected attempts; isolated code QA must not be called independent learner certification.
7. P2/P4 one source context each and paper metadata draft; no verified full authentic option-choice/timed exam workflow.

**MEDIUM — acceptance/quality checks missing:**
- independent academic blind review of 72 MCQ answer logic and distractors;
- 498-item official syllabus point-by-point decomposition semantic sign-off, especially any oversplitting/misclassification;
- EN/RU/UZ semantic equivalence of terms, numeric units, diagrams and answer distractors (locale presence alone insufficient);
- question text near-duplicates, key/distractor leakage, item overlap across independent mocks/diagnostics;
- item-level AO1/AO2/AO3, numerical/diagram tags, difficulty adjudication, paper distribution;
- server authorization and current answer key visibility tests using actual beta accounts; do not infer new vulnerability from older Maths reports.

**Source reconciliation:** `docs/exam-prep-economics-working-plan.md` October 23 `draft/off`, P1 16 candidates, P3 zero is historical. Current prod program is enabled and P1/P3 36 approved each. `docs/exam-prep-economics-p1-p4-owner-acceptance-20261029.md` owner-level UI acceptance is NOT a full-syllabus/independent-student claim. `docs/economics-9708-written-22-bank-release-audit-20261029.md` newer applied 22-task state supersedes owner-acceptance older 12-task snapshot.

## 7. Missing content estimate — evidence-based, not arbitrary quota

- **MCQ first-pass missing primary skill-evidence:** P1 165 and P3 262 = **427 uncovered primary skill slots**. These are academic evidence obligations, **NOT automatically 427 newly written questions**; each candidate existing legacy question must be inspected before original authorship. Primary one-to-one item mapping suggests at least one reviewed direct question for every uncovered primary skill if no reusable items remain. Multiple variant/scenario/AO reservations increase the final number; carefully approved multi-skill questions may reduce distinct authoring needs but do not erase separately needed evidence.
- **Independent 30-MCQ mock sets:** a provisional internal content governance gate of **three independent sets = 90 MCQ unique items per paper** implies each current 36-item mapped bank is **54 distinct approved items short of even this minimum reserve** (for P1 and P3 separately). This is *not* an official Cambridge numerical requirement; it is a reserve-planning floor, and it does not close the 427 skill gaps.
- **Written:** 14 P2 + 8 P4 released parts currently. Cannot responsibly calculate "exact N more essays" until 22 prompts have independently signed direct/mixed skill and AO mappings and all official point+skill deficiencies are sorted into data response, structured essay, unstructured essay and evaluation capabilities. A single 20-mark essay can validly integrate multiple skills. Produce a per-skill coverage heat map and review the topics before setting content batches.
- **Reuse first, author second:** review all 1,644 legacy items grouped by paper/syllabus point; quarantine rejects, source-code-only or duplicate pieces; approve only audited non-identical candidates with stable snapshot hashes; create originals only for demonstrated gaps. Never copy Cambridge official papers/mark schemes or textbook exercises.

## 8. Safe staged implementation and immutable ownership boundary

**Gate A — baseline freeze:** this GitHub docs-only branch, baseline SHA, 498-row matrix, 53-topic rollup and 22 written-topic mapping; no production writes. Before a future change, refresh live counts (real learner activity changes numbers).

**Gate B — paper-specific academic QA:**
1. Validate canonical 253 official codes/498 iClub skills against Cambridge exact content bullet hierarchy, correct exceptions/scope.
2. For each of five existing thematic MCQ packets (AS-1/2/3, A-1/2), inspect potential legacy stems in batches ~24–36, assign explicit primary/secondary skill, syllabus code, paper, AO, cognitive challenge, scenario, calculation/diagram metadata; verify keys, rationale, four distinct distractors and three equivalent locales. Treat prior approvals as existing evidence to audit, not blindly discard. Record accept/correct-by-new-version/reject/needs review; keep history immutable.
3. In parallel, map all P2/P4 written prompt parts to actual canonical primary/secondary skills and separately map source analysis/diagram/numeracy/argumentative AO3 evaluation. Written criteria only tell the student what is assessed, never the solution.

**Gate C — per-topic delta:** use new matrix filtered for missing/depth gaps; establish demonstrated reuse counts and explicit original-authoring needs, distinct mock/diagnostic/retest exposure reserves and accessible diagram coverage. No arbitrary equal quota by chapter. Protect slow/advanced skills and transfer beyond mere definitions.

**Gate D — content-only additive candidate batches:** immutable new content/version and source/provenance, four answer options (MCQ), separate approved rubrics (written), trilingual semantic QA; issue source ID/hash, review status, paper and AO. Never overwrite a published/history-bearing version. Old completed tasks never auto-reassign. No mutation of Mathematics, Chemistry, Biology, CS, original Practice/Tours or legacy user progress. Academic candidate approval != automatic beta publication.

**Gate E — controlled technical rollout:** new payloads must use existing fail-closed server access and approved channel, not client-held keys, with assigned beta cohort unchanged until architect decides. Verification: two owners and no-cross-owner BOLA; cold/refresh/replay/offline/double-submit/idempotence; no key leak; P1/P3 diagnostic/paper including timing and option order; P2/P4 optional criteria with no answers/no marks; mobile/desktop + RU/UZ/EN; plan progress baseline invariants. Any fail => rollback only the new release path, retain data.

**Gate F — 100% release readiness:** full canonical academic mapping (not solely candidate existence); reviewed evidence for all applicable official skills/AO; three-language academic QA; properly separated P1/P3 unseen reserves; P2/P4 written types and option-choice accurately represented *if* a true mock is later approved; no essay auto-grading; security, accessibility and regression green. Explicit architect decision required for larger release. Product Content Complete is not learner Exam Ready.

## 9. Non-negotiable preservation baseline

- No `INSERT/UPDATE/DELETE/DDL`, user advancement, progress reset, localStorage change, feature toggle, runtime code change, or deployment performed during this audit.
- `main`, Supabase live assessment, existing P1/P3 attempts, written plan 22 steps (3 historical advances), original questions and course assets remain exactly as observed except unrelated real user activity.
- Report-only GitHub branch `audit/economics-9708-master-coverage-20261029`; do not merge before review. A docs-only merge later is not itself content publication.
- The oldest 22 written drafts remain unreleased.
- iClub does NOT auto-mark essays or laboratory work. Mentor Care active assignment remains the only approved source of human judgement.

## 10. Next-session checkpoint

1. Open this report and three CSVs; read live `docs/exam-prep-economics-working-plan.md`, written-22 and owner-acceptance 29 Oct.
2. Recheck GitHub main SHA/production SHA and Supabase 498/253, P1 36 P3 36 and 22 released written tasks.
3. **First substantive academic action:** scrutinise and approve the official 253-point/498-skill source map and direct P2/P4 theme→canonical primary/secondary skill links, then run paper-by-paper QA for the most glaringly missing groups (P1 Units 4–6, P3 Units 7 and 9; entire 17 zero groups).
4. Form a quantified inventory of reusable vs new original MCQ and written needs from audited candidates. Write controlled candidates under the existing governance (never alter historical approved question snapshots); keep them closed until explicit release gate.
5. Record exact test evidence, approved source hashes and next checkpoint in repo; do not infer completion from `READY` or presence-only percent.

**Audit reproducibility note:** Rows are derived by a read-only join `private.iclub_exam_core_skills_v1` → `private.iclub_subject_library_theory` → `private.iclub_exam_core_question_candidates_v1` filtered `program_key='economics_9708'` and candidate `status='approved'`, with first-party source control SHA noted. Topic roll-up groups by the first two numeric identifiers of `syllabus_point`. All note-level task thematic mappings are clearly labelled unapproved research hypotheses.
