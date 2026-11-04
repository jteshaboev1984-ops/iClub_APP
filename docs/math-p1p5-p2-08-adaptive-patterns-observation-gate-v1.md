# P2-08 — Mathematics P1/P5: adaptive learning patterns and defensible study-time measurement

**Version:** 1.0, 2026-11-03. **Status:** draft academic/engineering method, not learner-hour approval. **Issue:** #450. **PR:** #470. **Production change:** NONE.

## 1. Reuse decisions from established educational products

| Existing product (official published description) | Supported pattern | iClub implementation decision | Not copied / not permitted |
| --- | --- | --- | --- |
| [ALEKS Knowledge Checks](https://www.mheducation.com/prek-12/support/knowledge/what-is-a-knowledge-check.html) | Initial assessment, knowledge/ready-to-learn distinctions, periodic retention verification, session continuation | Existing P1 and P5 separate diagnostics → evidenced known / observed-but-unverified / unknown → corrections and delayed retest. Prerequisites may prioritize next work **but never transfer credit** across components. | No proprietary knowledge-space algorithm; no inference that untested=weak; no copying ALEKS assessment frequency, algorithms or questions. |
| [Seneca Revision Planner (Aug 2026)](https://help.senecalearning.com/en/articles/13972891-seneca-revision-planner-your-personalised-ai-study-plan) | Learner-controlled weekly timetable, prioritizing areas of uncertainty and optional schedule adjustments | User-elected Mathematics days and time; one shared budget, with separate P1/P5 deadlines and evidence; non-blocking missed-goal guidance. **Weekly/monthly summaries only.** | No Seneca daily nag/prompt schedule, no automatic extra catch-up time, no inferred daily minutes, no AI authority over academic state. |
| [Magoosh study-schedule guidance](https://magoosh.zendesk.com/hc/en-us/articles/218364023-Which-GRE-study-schedule-should-I-follow) | Different paths for prior experience and time remaining; explicit warning when short study cannot cover everything | Baseline + deadline + evidence-driven achievable-priority path; disclose partial coverage rather than fictitious readiness. | No copy of GRE hours, difficulty, course content, grades or misleading Cambridge predictions. |
| [Dr Frost mastery explanation (Jul 2026)](https://support.drfrost.org/hc/en-gb/articles/6079181131935-What-are-mastery-and-points-and-where-can-I-view-them) | Progressive difficulty, repeated performance evidence; harder practice tests stronger transfer | Retain original iClub canonical skill evidence standards, difficulty and delayed retest; no shortcuts based on easy item completion or arbitrary question counts. | Do not transplant its 0–100 scale or mastery thresholds into 9709 P1/P5; written method remains unscored by learner and AI. |

**Sources are references for public workflow patterns, not libraries with reusable open-source code, validated individual study-hour norms or license to reproduce content.** iClub adapts only original implementation concepts.

## 2. What sources can and cannot establish

Cambridge International **Mathematics 9709 2026–2027 syllabus** is authoritative for assessed topic scope, prerequisites and paper timing: <https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf>. Cambridge confirms that its approximately **180 guided learning hours for AS** include teaching/supervised-directed learning, **not private study**: <https://help.cambridgeinternational.org/hc/en-gb/articles/20712874440850-What-are-the-recommended-number-of-teaching-hours-for-Cambridge-International-A-Level>.

Existing privately stored 2020 Cambridge scheme-of-work **topic** contact-time suggestions (P1=90h in eight areas; P5=50h in five areas) remain *historical teaching references*, not 2026–27 individual study norms. **Do not divide 180, 90 or 50 hours by 81; do not use question limits or beta elapsed_ms as study time.**

The canonical 81 skill review pack, independently from question content, has already verified **81/81 source mappings**. Existing Exam Prep published content is plentiful, but content quantity does not measure how long a learner takes to understand a method.

## 3. New measurement path — offline first, data-safe

**Executable guard:** [scripts/math-p1p5-workload-measurement-quality-gate-v1.cjs](../scripts/math-p1p5-workload-measurement-quality-gate-v1.cjs)

The guard reads a **known 81-skill catalogue** and optional *separately protected* measurement JSON from an authorized academic calibration environment. By default no measurements are supplied: all 81 stay **measurement_evidence_incomplete**, no minutes are approved and personal recommendations remain disabled.

For each potential observation, require:

- Canonical exact **P1/P5 skill identity**, independently observed **active seconds**, observed original work, **core** vs **revision** phase and documented prior-knowledge cohort.
- Separate **paused seconds**; no background time, guided tutorial/tutoring time, estimation from exercise timers or inferencing missing study outside the platform.
- Original source/evidence references and a consent receipt, plus a **nonidentifying** actor reference and an observer reference; all raw evidence remains in a protected workflow, not this public repository.
- An actual completed unassisted observation; zero/negative/implausibly large segments, cross-component mismatch, duplicate actor/phase and obviously identifying references are rejected.
- A **pilot quality floor** of three distinct actors **per phase**, two prior-knowledge bands and two observer references, **not a statistical proof** of representativeness or a permission to publish a normative interval. A few expert walk-throughs or fabricated CI actors cannot establish a population study-time requirement.

Even if a pilot floor is fulfilled, the guard returns only **observed sample spans for academic review** (not fitted predictive intervals); it never sets \`approved_skill_norms\`, \`recommended_hours_per_week\` or any learner readiness/grade. Reproducible test fixtures exist **only in memory during \`--self-test\`**; they are not evidence that real learners were timed. External measurements must not be checked into GitHub or exposed via the browser.

**Run in CI (source-only, no access to production):**

\`\`\`bash
node scripts/math-p1p5-validate-workload-review-pack-v1.cjs
node scripts/math-p1p5-workload-measurement-quality-gate-v1.cjs --self-test
node scripts/math-p1p5-workload-measurement-quality-gate-v1.cjs
\`\`\`

## 4. Independent academic review required before any numerical advice

For each of 81 skills, a separate academic review must document a valid learner baseline, time spent on explanation/method, practice/correction, delayed retest, unseen transfer and written working where required, distinct revision effort, an actual plausible **range** with uncertainty, source-evidence traceability and a different reviewer/approver. The program cannot self-certify a skill from a script's numeric output.

Where no independent observation is available, the skill stays **unknown workload**, even if its syllabus mapping and assessment content pass. The implementation of any final estimate must produce ranges plus potential insufficiency, never a falsely exact minute amount or Cambridge grade prediction.

A future server engine must:
1. Attribute remaining work to **each separate P1/P5 skill ledger** and shared prerequisite work once, not double credit or double-count already confirmed skills.
2. Use **one shared Mathematics weekly time budget** to allocate tasks before the different official/center-confirmed P1 and P5 exam dates; avoid summing calendar capacity for both components.
3. Reserve real uninterrupted paper sittings (P1 110 min, P5 75 min) and retest/transfer without double-counting tasks already represented by calibration observations.
4. Show honest **capacity shortfall/unknown** and keep **all learning access unblocked** when planned hours are exceeded or the horizon is short.
5. Support **exactly three learner-initiated decisions** (keep chosen hours, accept recommended, enter custom hours) **only when evidence-backed recommendations exist**; never change a student's schedule without confirmation.
6. Preserve legacy users, Tours, Practice, certificate history and all beta academic events during drafting. Release-time cleanup remains separately authorized.

## 5. Review decision

**P2-08 engineering observation-method gate: testable. Academic intervals: NOT YET SUBSTANTIATED.** No external product publishes defensible individual P1/P5 skill minute intervals that can simply be imported into iClub. The current production beta timestamps are contaminated/sparse, and the textbooks describe subjects rather than actual learner-independent durations. The accurate next academic job is **skill-by-skill review of independent time evidence and uncertainty**, then a versioned server-only estimate model and explicit choice UI. Until that is achieved **NO_GO for numerical recommendations** and **NO_GO for public rollout**.

**State isolation:** PR #470 DRAFT; no production Supabase DML/DDL, no migration application, no Vercel deploy, no AI grants/access change, no test-user data deletion.
