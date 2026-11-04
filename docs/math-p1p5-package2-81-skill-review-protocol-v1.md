# Mathematics P1/P5 — P2-07 workload evidence review protocol

**2026-11-03 · Academic review pack · DRAFT · no personal-hour norms approved**

## What was actually established

This package snapshots **81 actual canonical Mathematics skills** (45 P1, 36 P5) from the current production `private.exam_prep_syllabus_nodes`, using **SELECT only**. Each row carries its own component, official syllabus area, skill code and description, prerequisites, textbook chapter/pages and existing mastery-evidence rule. Its accompanying JSON file is `docs/math-p1p5-package2-81-skill-review-pack-v1.json`. It contains **no question texts, protected answer keys, learner responses, reserve IDs or personal records**.

All per-skill learning/revision minutes are **null**. This is not the absence of academic preparation: it records the exact remaining **measurement** obligation rather than converting a syllabus mapping into invented study minutes. Review status is `awaiting_observations`; no skill is approved for a personal-hours recommendation. The separate 2020 Cambridge schemes describe **topic-level guided teaching time**, not 2026–27 learner-specific independent study. The current 2026–27 syllabus's approximately 180 AS guided hours do not validate any of these 81 time ranges.

## Reproducible evidence needed for each one of 81 rows

1. **Baseline and prerequisites.** Identify a defined learner starting point and which prerequisites have already been demonstrated. Mark unknown as **unknown**, not weak. Do not allocate a prerequisite's initial teaching time again to each dependent skill.
2. **Observed instructional route.** Document original explanation and worked method, representative *released* objective and written-method activities, independent practice, wrong-answer correction, delayed retest and unseen mixed transfer. Record the specific task selection in a secure governed review log; **never copy protected question/answer content into this repository**. The `required_mastery_evidence` field in each JSON row defines the evidence *type*, not its time duration.
3. **Actual durations and validity.** Gather separately identifiable timings/credible bounded instructional walkthroughs for every phase; note learner prior knowledge, method, pauses, help received, and whether the task was completed. Do not use short beta `elapsed_ms`, question deadline maxima, published-item counts, guided classroom hours or video counts as unassisted study duration. Unobserved phases remain null.
4. **Interval and uncertainty.** Independently review the lower/upper plausible minutes for **initial/core learning** and **revision**, with rationale for variation (known/unknown prerequisites, correction and delayed retests, written-method understanding). A single point figure without a derivation is insufficient. Do not call an estimate an official Cambridge norm.
5. **Independent check.** Record named primary reviewer and a different authorized independent approver, dated review, method version, source/evidence identifiers and disputed assumptions. Do not treat an assistant self-check, a CI pass or a syllabus citation as a substitute for independent verification. If evidence is missing, retain `awaiting_observations` and null minutes.

## Component-safe eventual calculation (NOT ENABLED)

P1 and P5 each have independent mastery/evidence and different verified exam dates; they share one Mathematics weekly study budget. A future engine may allocate a reviewed workload once, never sum P1 and P5 *calendar capacity* as independent hours. Only genuinely observed progress can reduce work; diagnostic-unsampled skills are not automatically failures. Corrective, mixed, written-unscored and whole-paper (P1 110 min, P5 75 min) logistics must be accounted for separately without counting the same minutes twice. Paper sitting time cannot be derived by summing per-skill question timers. No method marks are assigned by learners or AI.

No valid recommendation exists until the **81 row-level ranges**, reviewer independence, methodology, missing-data handling and server-side planning policy are signed off and tested. Until then keep the existing numeric recommendation `NULL`, learner choice of hours unchanged, and Core freely usable beyond a chosen study schedule. Future approved recommendations must present exactly: **Оставить моё время / Принять рекомендуемое / Указать другое время**, without changing anything until the student confirms. Reports are weekly/monthly only.

## Coverage and safety checks

| Syllabus section | Canonical skills |
|---|---:|
| 1.1 Quadratics | 6 |
| 1.2 Functions | 8 |
| 1.3 Coordinate geometry | 6 |
| 1.4 Circular measure | 3 |
| 1.5 Trigonometry | 5 |
| 1.6 Series | 5 |
| 1.7 Differentiation | 7 |
| 1.8 Integration | 5 |
| 5.1 Representation of data | 10 |
| 5.2 Permutations and combinations | 5 |
| 5.3 Probability | 6 |
| 5.4 Discrete random variables | 9 |
| 5.5 The normal distribution | 6 |

Run `node scripts/math-p1p5-validate-workload-review-pack-v1.cjs`. The guard checks 81/45/36, all 13 syllabus groups, canonical source/evidence presence and strict unapproved/unmeasured status; it also deliberately corrupts a test copy to prove unauthorized approval or a lone numeric value fails. The guard does **not** certify educational duration accuracy. No production data writes, user-facing flags, deployment or cleanup are part of P2-07.

**Source precedence:** current 2026–27 Cambridge syllabus → iClub signed 81-skill map → textbook explanation → internal iClub measurement and independent review. See `docs/math-p1p5-package2-workload-source-register-v1.md` for original source provenance and the historical scheme-of-work caveats. Issue [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450); draft [PR #470](https://github.com/jteshaboev1984-ops/iClub_APP/pull/470).
