# Mathematics P1/P5 S4 — actual current full-Paper audit, hybrid checkpoint candidates and Stage3–6 reconciliation

**Issue:** [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450) · **Date:** 2026-11-09 · **Branch:** `docs/math-p1p5-s4-hybrid-paper-owner-decision-20261109` · **Owner contract:** [S4 hybrid / no learner marks](math-p1p5-v22-s4-hybrid-paper-product-decision-20261109.md).

**Scope and safety:** LIVE Supabase/PostgreSQL metadata, task/rubric and `pg_get_functiondef` read with SELECT only; GitHub source read. **No database, user or runtime source writes**. This is a completed **structural and targeted mathematical feasibility audit**, not a claim of end-to-end acceptance, a finished auto-checker, fully worked solutions, printable PDFs, cleared content copyrights or production readiness. All prior attempts remain untouched. **Stage-gate decision below is RECOMMENDED, NOT YET ARCHITECT-APPROVED** and MUST NOT be applied as SQL until approved.

## 1. Exact current source inventory (not archive-version inflation)

Selection: published `private.exam_prep_assessments` with published `private.exam_prep_timed_assessment_contracts` of `attempt_kind='full_paper'`, take the latest approved `assessment_id` per `component_code,assessment_key`. Each of the six selected assessment IDs is **all-written, zero objective auto-graded questions**. Paper contract totals match full question marking criteria (and each written `rubric_json.criteria[].marks` sum), with no mismatched totals.

| Paper key | Current assessment | Latest version | Written tasks | Total available marks | Task IDs in order (NOT keys or answers) |
|---|---:|---|---:|---:|---|
| `p1_stage3_full_paper_01` | 391 | av2 | 10 | 75 | 105, 220, 195, 108, 109, 227, 221, 112, 113, 114 |
| `p1_stage4_full_paper_02` | 451 | av3 | 10 | 75 | 122, 273, 124, 125, 126, 127, 196, 129, 130, 131 |
| `p1_stage4_full_paper_03` | 452 | av3 | 10 | 75 | 139, 140, 274, 142, 143, 144, 145, 146, 147, 197 |
| `p5_stage3_full_paper_01` | 453 | av3 | 7 | 50 | 115, 116, 222, 118, 223, 228, 275 |
| `p5_stage4_full_paper_02` | 455 | av3 | 7 | 50 | 132, 133, 134, 230, 231, 179, 277 |
| `p5_stage4_full_paper_03` | 363 | av2 | 7 | 50 | 149, 150, 151, 233, 167, 234, 235 |

**Do not call the 8 P1 + 8 P5 published rows “eight distinct Papers each”.** They are historical *versions* of exactly **three logical full-Paper keys each**. For latest versions, **30 P1 distinct task IDs and 21 P5 distinct task IDs; no shared written-task ID between the three current Papers within a component**. Reattempting an already revealed Paper remains non-blind regardless.

### Structural content QA (51/51 current question placements)

- **51/51** prompts populated in EN/RU/UZ; **51/51** nonempty `rubric_json` containing `criteria` and `max_marks`; **51/51** sum of criterion marks equals both rubric max and full-Paper per-question max. Existing published task QA statuses are `math=pass`, `language=pass`, `technical=pass`, `copyright=pass`.
- **51/51** mapped to a primary syllabus skill; **51/51** have a nonempty EN/RU/UZ *self-review tip*; each is a brief hint (EN typically 80–193 characters), **NOT a complete worked solution**. The approved RU/UZ criteria locale records exist for all 51/51 current placements.
- The stored criteria are **method-sensitive**, with incremental mark allocation; neither the existence of rubrics nor full-possible marks creates a machine-checkable student-written score.
- No separately confirmed complete worked-solution asset was found in inspected **source schema**; verify all available app/static/external assets separately before promising per-question fully worked solutions or printing complete papers. Requirements/marking points and short review hints are what source checks establish so far.
- The paper metadata table has only **one metadata-only approved external official-past-paper portal link per component**. It does **not** establish rights to mirror Cambridge PDFs, a source-managed printable iClub full-Paper PDF, or a local MF19 download.

**Official clock:** current published source paper profiles state **P1 6600 s (110 min), 75 available marks; P5 4500 s (75 min), 50 available marks**, source-tagged 9709 2026–2027; `timed_assessment_contracts.fixed_time_limit_sec` for these full Papers is NULL, so the implementation MUST use the linked governed paper profile/timing contract, **not hardcode a default or silently interpret NULL as untimed**. The Cambridge 9709 syllabus (2026–2027) requires normal scientific calculator and makes the MF19 list of formulae and statistical tables available; unsupported calculator answers may lose method marks. Reference: https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf (assessment details page 41; MF19 starts page 43); help centre: https://help.cambridgeinternational.org/hc/en-gb/articles/20756798012562-Which-list-of-formulae-do-candidates-use-for-the-AS-A-Level-examinations .

## 2. Limited independent mathematical re-derivation — PILOT CANDIDATES, NOT APPROVED KEYS

For **12 concrete existing question parts** (two per current full Paper) re-derived the numeric/exact result from the English question and checked consistency with the stored marking rule. **All 12 matched the existing source rule in this spot audit**. They are candidates to build an OPTIONAL, source-guarded final-answer checkpoint, never ready-made verified paper marks. The correct values stay in the protected source `rubric_json`, **NOT in this Markdown or browser client**; before enabling, the actual `checkpoint` answer key must be independently typed/version-pinned, tested for parsing/equivalence and subjected to math QA.

| Current Paper | Item / task ID | Proposed narrow checkpoint (only that part) | Answer semantics / outstanding parser test |
|---|---|---|---|
| P1 01 | Q02 / 220 | Part (c): composite inverse equation, value of x | exact rational, accept equivalent fraction and decimal; domain check not machine-verified |
| P1 01 | Q04 / 108 | Part (c): minor segment numeric area | 3 significant figures, cm²; ignore written method |
| P1 02 | Q04 / 125 | Part (c): sector area | exact number with optional cm²; earlier parts not verified |
| P1 02 | Q10 / 131 | Part (c): positive endpoint a | exact positive integer; improper-integral limiting method unverified |
| P1 03 | Q06 / 144 | Part (c): least positive integer n | exact integer; lower-bound reasoning unverified |
| P1 03 | Q08 / 146 | Part (b): maximum rectangular area | exact number plus area unit; optimisation proof unverified |
| P5 01 | Q02 / 116 | Part (c): distinct arrangement count | exact nonnegative integer; block combinatorics method unverified |
| P5 01 | Q06 / 228 | Part (e): conditional waiting-time probability | exact 4-digit decimal or rational equivalent |
| P5 02 | Q02 / 133 | Part (c): distinct arrangements with non-adjacent L | exact nonnegative integer; counting argument unverified |
| P5 02 | Q06 / 179 | Part (d): conditional probability | exact fraction or 4 d.p. decimal as question specifies |
| P5 03 | Q02 / 150 | Part (c): codes divisible by five | exact nonnegative integer; interpretation of leading zero unverified by final answer |
| P5 03 | Q06 / 234 | Part (c): normal 90th percentile | **3 significant figures**, acceptable rounding only; MF19/normal-table context |

Spot-check derivations (not numeric keys): inverse composition substitution; sector/chord formula; perimeter/area geometry; √-endpoint integral; AP sum at consecutive integer boundaries; differentiation and maximum; combinations followed by 3!×2! row arrangements; geometric memorylessness; repeated-letter permutations and exclusion; conditional geometric tail ratio; disjoint endings 0/5; normal quantile with mean/SD. **No claim** that all 51 full questions are mathematically re-solved; source QA-pass still remains the existing broader academic status.

### Candidate blockers until executable checkpoint QA

1. **No published `final_answer_checkpoint` authoritative keys or equivalence contracts for these written tasks** exist in the examined P1/P5 full Paper schema. A marking-rule sentence like “Gets ...” is NOT a safe automatically parsed answer key. Do not regex-extract into production or send raw `rubric_json`/correct answers to the browser before reveal.
2. Exact result vs approximate 3 s.f./4 d.p.; comma vs decimal point under RU/UZ; fractions/exact symbols; optional units, sign, boundary ties, accepted alternative forms. Whitelist tested deterministic numeric/rational grammar; **never `eval` a browser expression**; do not silently broaden tolerance beyond question requirements. Symbolic-only answers must be explicitly reviewed or skipped.
3. Each checkpoint is **one named subpart of a written multi-part question**, not a full question-score or written method. Do not sum guessed `marks` from that item/part or expose a 75/50 paper percentage. Label response *final answer matched/not matched*.
4. Authenticated user/version/attempt binding, immutable key identity, single idempotent pre-reveal submission, server-owned timing and ownership, anti-replay and readback; no leaked keys through API responses, HTML or logs.
5. Reveal/order guard: **student can skip optional checks**; once criteria, worked result or protected answer were exposed for that task/assessment, any later answer cannot be represented as an independent blind result. Historical same-Paper answer exposure must be reflected; do not erase prior review history.
6. A submitted answer may be a legitimate mismatch or student transcription error; recommendations can use **only genuinely recorded mismatches and source-mapped skills**, with caveat that the *method* is not assessed. No unsupported “weak topic” inference.
7. Print/PDF availability, diagrams/notation rendering, accessibility and **MF19/normal table** access need actual device acceptance. Prefer a printer-friendly HTML/PDF-printed browser route from **iClub-owned content**, not rehosting copyrighted official PDFs.

**Release acceptance for checkpoints:** correct/wrong/blank/skipped answers; fraction and decimal locale; 3 s.f./4 d.p. boundary; submit just before/after reveal; repeated session after reveal; two users; old client; expired JWT; browser sleep/resume/timeout; lost ACK/retry; RU/UZ/EN; no paper total or academic-stage promotion; disabled/empty-checkpoint option works from first day.

## 3. Real Stage 3→6 baseline dependencies — why old S4 cannot simply be ported

Verified using **actual currently deployed function definitions**, live active source rules and accepted draft sources [#494](https://github.com/jteshaboev1984-ops/iClub_APP/pull/494), [#507](https://github.com/jteshaboev1984-ops/iClub_APP/pull/507):

| Stage transition | Current source requirements (simplified, but based on live code/rules) | Hybrid conflict |
|---|---|---|
| Stage 3→4 | All canonical component skills coverage and **L2**, key skills **L3**, plus `require_comparable_full_baseline=true` and **one score-comparable genuine full Paper** | A no-upload paper rehearsal has NO written-artifact execution evidence or score-comparable result. |
| Stage 4→5 | Stage 3 passed; **2 comparable strict full Papers** in family, improving/nonworsening *unattempted* and *after-time marks* shares; majority of scoped timed sections (**2 published per component**, actual required majority determined by rule); below-L3 skills require explicit corrective-plan conditions | Blind paper rehearsal has timestamps but **no evidence of written marks attempted or left after time**. Timer alone cannot populate either share. Timed sections still follow old digital answered-paper evidence path. |
| Stage 5→6 | Stage 4 passed; **3 comparable full Papers**; all canonical skills **L3** and correction cycles closed; approved grade-/time-scoring rules | Current **approved Stage5 score threshold rows = 0**. New paper rehearsal cannot generate any verified full-paper grade. Legacy P4-04 operational stage separation was tested on digitally *submitted* writings, not no-upload. |

**Source facts:** live `private.exam_prep_stage3_exit_status_v1`, `private.exam_prep_stage4_raw_evidence_v1`, `private.exam_prep_stage4_exit_status_v1`, `private.exam_prep_stage4_timed_section_gate_v1`, `private.exam_prep_stage5_readiness_status_v1`, `private.exam_prep_apply_stage0_gate_v1()`. Current stage3 active min levels `2 / 3`; stage4 active comparable full attempts `2`; stage5 min comparable full attempts `3`. DRAFT P4-02 comparator requires **nonblank persisted written responses** and server integrity; simply making a blank practice record “execution comparable” is a breach.

**Existing observed timed UX** on current S3 parent source (`exam-prep/exam-prep-live.js`): `startTimer()` computes remaining from server `timing_contract.deadline_at` and `Date.now()` (not increment-only ticks), auto-requests `finishTimed("time_expired")` on zero **only while browser JavaScript runs**, and on a resumed expired active session `loadSession()` triggers expiration. A browser asleep/offline cannot promise exactly-on-deadline server finalisation without a server read/finalisation path. The existing full-Paper UI still requires `textarea` written artifacts on the timed route and exposes rubric in `renderWrittenReview` after finalize. It is **NOT the approved hybrid UX yet**.

## 4. PRECISE recommended operational-stage reconciliation (FOR OWNER APPROVAL)

**Goal:** retain **academic skill quality** and original distinct P1/P5 boundaries while ensuring independent handwriting in a notebook is NOT blocked by an artificial screenshot/typed-work gate; do not fabricate exam readiness, false attempts or score. Preserve all legacy digital/verified records and all historical stage achievements.

### Separate immutable evidence categories

- `paper_training_session`: user-owned server-authorized P1/P5 full-paper version+timing+review state, including early/expired/interrupted; **noncredit, not stage/grade evidence**. Even “completed” is a learner-initiated rehearsal closure and NOT independently verified mathematical execution.
- `final_answer_checkpoint`: per-part server-evaluated exact/rounding match, with provenance and pre-reveal/blindness; **not method marks**, not L3 or readiness unless a **future explicit academically validated bridge** is approved.
- `written_method_marking`: future only: optional authorized qualified Mentor, or optional independently approved tariff-entitled AI; no current capability or compulsory request; no student grading.
- `verified_objective_skill_evidence`: maintain all existing server-verified diagnostic/mixed/retest/plan/correction facts and existing L2/L3 requirements.

### Proposed specific gate changes

1. **Stage 3→4: retain all existing confirmed syllabus coverage, L2-for-all, L3-for-key-skill requirements.** Remove the full-Paper **submission/scored-comparability requirement as a blocking prerequisite** for *operational education flow only*; display “first Paper practice: not attempted / attempted / reviewed” separately as a recommended milestone. No rehearsal-click can award L2/L3.
2. **Stage 4→5: retain the existing corrective-plan governance** (L3 where earned, or the existing **explicit approved corrective plan** for below-L3 skills), and any non-Paper objective checks that are legitimately independent. **Do NOT require two digitized Paper solutions, fictional unattempted/after-time mark trends, or timed-section completion that still requires typed mathematical working.** Keep two Papers and timed-section practice as learner-visible guidance with honest observed duration/outcome fields, not prerequisites. Trend fields that lack submitted-written evidence are **NULL/unknown**, not 0 or “improving”. No new day/hour/grade gate.
3. **Stage 5→6 (Final Calibration access, NOT academic exam readiness): require existing objectively verified L3 stability for **all** canonical component skills and all existing correction cycles CLOSED**, Stage4 completion, existing component ownership and authorized stage rules. **Do not require three no-upload training sessions as proof** and never create a Cambridge grade from 0 objective marks or a missing Stage5 threshold. The three-Paper milestone becomes a visible study **recommendation** with no eligibility/credit effect. Keep `App Readiness Estimate=INSUFFICIENT_EVIDENCE` / written-method unreadiness explicit where independently marked method evidence is absent.
4. **Presentation:** Current Stage 5 UI uses “Exam Readiness”, and Stage 6 “Final Calibration”. These are **operational curriculum labels**, not verified claim of passing Cambridge. New RU/UZ/EN user text must explicitly distinguish *training plan position* from *validated exam performance*. Don't overwrite the current stage or former badges of real learners on migration.
5. **Migration discipline:** do **not** mutate existing `exam_prep_stage*_rules`, `exam_prep_timed_attempt_results`, old comparators, old source cohorts, stage history or `App Readiness` in place. Write NEW versioned operational gate reader(s) and a guarded source-specific projection only after architect approval; reuse old source clock/auth for legacy timed submissions. Regression verifies legitimate existing Stage3/4/5/6 states do not decrease on migration, no blank paper gets credit, no stage-skipping purely on a checkbox, no cross-component or other-subject writes. No arbitrary threshold or invented teacher verification.

### One approval required before coding stage-projection SQL

**Architect confirmation required:** Is it acceptable that the **three full-Paper rehearsals (and old two-paper timing trend) become learning recommendations, not compulsory Stage3–6 access prerequisites**, while strong **verified objective-skill L2/L3 and corrective-cycle conditions stay binding**, and written/full-Paper exam readiness remains **unknown** without genuine marking? This is the recommended least-coercive, honest hybrid-stage contract. **Do not treat today's “work per plan” as approval of this different stage-gate policy**; keep implementation paused at this decision boundary.

## 5. Next concrete engineering package (after gate approval)

1. Define authenticated, owner-bound, idempotent, private noncredit `paper_training_session` persistence and lawful review-reveal order using an existing versioned assessment; avoid broad new tables for future AI/photo/tariff.
2. Source QA for 12 proposed narrow subparts (or fewer after filter), private keyed deterministic equality/precision without sending key before reveal, client RU/UZ/EN copy and examiner-safe accessibility; secure unknown result for all other items. QA should include math notation, units and rounding and no numeric self-scoring.
3. Make the existing **full-Paper learner screen** paper-first only under an isolated feature-disabled S4 beta flag; keep legacy timed/written submission accessible to old sessions to preserve their stored artifacts and existing signed HTTP semantics.
4. After separate owner-approved stage-gate contract, add isolated versioned operational progression readers and targeted triggers, with no historical DML or manufactured marks.
5. Test exact integrated S3+S4 SHA in GitHub Actions **free** disposable PostgreSQL17, signed JWT/PostgREST and Chromium, then optional 8–12 learner pilot (no fixed waiting gate), before any separate mass production GO. Explicit old/new browser and session/paper versions, source fingerprint and fallback, RLS/private schema, session recovery, exact 75/50 maximum labels, MF19 + device-sleep behaviour, UI RU/UZ/EN, and zero change to Extra Hard/Practice/Tours/certificates/other subjects. P0-16B remains separately open; beta cleanup deferred.

**No tests executed for any new hybrid API here because no new API/code was written; prior P4 CI only proves historical digital-paper paths.**
