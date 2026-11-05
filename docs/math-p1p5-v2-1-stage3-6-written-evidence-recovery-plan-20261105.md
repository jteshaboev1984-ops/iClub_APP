# Mathematics P1/P5 — roadmap v2.1 / Stage 3–6 written-evidence recovery
**2026-11-05 · Issue #450 · architect decision carried forward · IMPLEMENTATION IN PROGRESS · DRAFT / PUBLIC NO_GO**

## Purpose and source precedence

This **versioned addendum** amends the approved [full roadmap v2.0](https://github.com/jteshaboev1984-ops/iClub_APP/blob/docs/math-p1p5-v2-workplan-issue450-20261102/docs/math-p1p5-release-workplan-v2-20261102.md) at **D03 (no student/app/AI written scores), Package 4, Package 7 and Stage 3–6 acceptance**. It does not replace D01–D13 or the master 81-skill P1/P5 map. It records the architect's **2026-11-05** decision to **accept the identified progression defect, reject mandatory Mentor Care, and reject an objective-only percentage for all-written papers**.

The practical integration base is [DRAFT PR #492](https://github.com/jteshaboev1984-ops/iClub_APP/pull/492), exact before-fix SHA `925fdffe44f5c63c20009a4798ed2f2fb35b0c78`, previously **71/71 SUCCESS**, **not** evidence that the full Stage 3–6 product semantics work. This corrective work is **stacked on PR #492**, not merged into main. The independent earlier Package 0 safety [PR #493](https://github.com/jteshaboev1984-ops/iClub_APP/pull/493) belongs to the separate workplan docs branch: **do not pretend it is included in this integration PR**.

## Verified facts: source code + LIVE READ-ONLY metadata

1. The draft `20261104110000_exam_prep_p1p5_disable_written_self_marks_v1.sql` correctly forbids learner-entered written scores and retains written artifacts, but its `private.exam_prep_timed_score_comparable_v1` requires both pending written totals to be **zero**. A normal completed written task remains ungraded/pending, so qualifying scored attempts become unavailable.
2. `private.exam_prep_stage3_exit_status_v1`, `private.exam_prep_stage4_raw_evidence_v1`, `private.exam_prep_stage4_timed_section_gate_v1` and `private.exam_prep_stage5_raw_readiness_v1` depend directly on that old **score** comparability notion. Stage 4 and Stage 5 have additional evidence/threshold rules.
3. An independent live Supabase **SELECT-only** metadata/catalogue query found **8 P1 + 8 P5 published full-paper assessments**; every one is **100% written-only**, with P1 **10 tasks/75 total written marks/zero objective marks** and P5 **7 tasks/50 total written marks/zero objective marks**. All item sums match published paper contracts. No private prompt/answer contents or learner records were exported.
4. Live `private.exam_prep_stage5_thresholds` has **zero rows** at this snapshot. No legitimate grade thresholds exist to infer from these papers.
5. The draft Stage 5 calculates `100*objective_marks_in_time/marks_available`: with all-written papers this becomes **0/75** or **0/50**, not a valid score of the paper. Changing the denominator to objective marks becomes **0/0**. Both are academically inappropriate as evidence of readiness. `in_time_percent=null` on ungraded writing is currently correct.
6. The signed E2E `scripts/p1p5-isolated-http-positive-mixed-timed.cjs` explicitly expects `score_comparable=false` with written content, but does NOT prove legitimate Stage 3→4→5→6 progression. The previous **71 green CI runs must not be relabeled** as a completed 4-stage release journey.
7. Any claim that a Stage 5/6 change is already deployed, that 3 completed full Papers can be genuinely machine-marked, or that mentor certification can be inferred is **false**.

## Approved mathematical and product semantics — two orthogonal notions

- **Execution/conditions comparability**: was a genuine server-issued paper/timed session finalized under equivalent component, paper form/family, server time, series/epoch, attempt constraints and integrity conditions? Writing may be completed but ungraded. This is **a fact of sitting the practice paper**, not a Cambridge exam mark. It may support practice-stage flow and trends in completion/timing, but NOT grade prediction.
- **Scored comparability**: a genuinely verified mark / percentage with a defensible, positive and comparable assessed denominator. **An all-written, unmarked paper is NEVER scored-comparable**. A paper's `marks_available` still denotes Cambridge-style total opportunity, **not** automatically earned/failed marks. `pending_review_*` is **unknown**, not zero or wrong.
- **Objective skill evidence**: independently verified diagnostic, practice, correction and delayed retest facts (component-safe P1/P5), including unknown/unsampled skills. Use only within already approved deterministic mastery policy.
- **Written-method evidence**: final artifact + timestamp and, when relevant, voluntary rubric review; correctness/awarded marks stay **unknown** absent an independently authorized external human review. Core cannot demand Mentor Care access; no self/AI scoring.
- **Core operational stage** and **App Readiness Estimate** are distinct. The learner may continue Core learning and exam training without human marking, but the UI must **not** label ungraded full-paper results as verified exam marks/grade/readiness. Do not fabricate Stage 5 thresholds; keep human-verified readiness separately scoped.

## Ordered execution: first unfinished corrective work (P4-01 → P4-06)

**P4-01 — complete factual dependency mapping and failing-baseline guard (STARTED).**
Inventory all readers, finalizers, triggers, stage projections, UI and statuses that interpret `score_comparable`, `base_score_comparable`, pending written marks, paper percentages, thresholds or availability. Cross-check live catalog metadata and exact PR #492 files without any production changes. Commit a **read-only** paper-composition source query and source-bound regression showing existing impossible combination without publishing protected question content. Preserve existing 71/71 evidence.

**P4-02 — implement a new strict *execution* comparability helper without modifying scored semantics.**
Versioned additive, service-only, `search_path=''`, no public key/grant exposure; preserve all existing time, integrity, paper epoch, exam series, authorization and component checks. No blanket `pending=0` on execution qualification; no blanket `score_comparable=true`. Implement signed owner/foreign/anon, expired paper clock, compromised integrity, wrong-series, original paper family, missing written, and repeated finalization tests. Preserve original session snapshots.

**P4-03 — safely rewire Stage 3/4 *practice-completion* progress.**
Source-review every stage evaluator and only substitute execution comparability where it asks whether the practice was legitimately completed. Separate time-usage trend from correctness. Protect the genuine objective mastery, key skill, correction, attempt integrity and distinct P1/P5 requirements. No automatic stage promotion just for a date/week or submitting blank writing; no new learning access block.

**P4-04 — resolve Stage 5/6 operational continuation vs readiness.**
Stage 5 must distinguish `three_execution_comparable_papers` from `three_scored_comparable_papers`. All-written papers cannot have a machine percentage or assert `ready`; show specific `written_ungraded` / `score_unavailable` status. For operational Stage 6 access use approved objective academic evidence + governed practice milestones without depending on mentor marks, while keeping App Readiness Estimate expressly provisional/insufficient when written-method correctness is unknown. Review stage projection triggers, versioning, no false notification/certificate. Any threshold-based numerical exam readiness remains **unconfigured**, never autofilled.

**P4-05 — full source-accurate isolated PG17/JWT/PostgREST/Chromium E2E and negative tests.**
Exercise P1/P5 independently: both full-paper types, completed written, skipped written, one and three genuine full attempts, in-time/late, integrity strike, session replay, stale authorization, failed objective correction, retest, interrupted client/offline retry, non-Mentor Core, anon/foreign access, three locales and desktop/mobile. No tests may INSERT arbitrary `pending_review=0` for an all-written source paper, fake learner scores, force stage states or grant Mentor. When positive stage criteria are not configured, assert **honest not-ready/unknown**, not a fictitious Stage 6 success. Test clean isolated rollback and prior saved history fingerprints, plus exact-SHA full existing 71 workflows.

**P4-06 — clean integration/release candidate checks.**
Do **not** merge the 162-file parent PR or cherry-pick random migrations. Review migration ordering/privileges, all staged SHA/CI, UI contracts, security and protected preservation. Keep P0-16B complete writer/epoch inventory, final GO/retention and deferred cleanup on their original track. Mass public mode stays **NO_GO** until separately approved; do not invent additional product access gates.

## Carry-forward academic backlog (NOT LOST, not first task)

- D10-08: five known mathematical prompt repeats; soft retest preference tested, 5 private versioned candidate replacements **not** published; original IDs/71-session historical diagnostic remain immutable. Validate multilingual mathematical equivalence before versioned import, never modify shared published question rows.
- P2 per-skill independent-study minute estimates for all 81 canonical skills remain unapproved/unobserved; no invented personal Cambridge norms or forced learner schedule.
- The original 12 architect-designed Extra Hard remain unrecovered exact source; do not create claimed substitutions.
- D09: two distinct diagnostic T0 anchors, one shared Math week budget, weekly/monthly-only reports and exactly three voluntary time choices remain unchanged.
- P0-16B: trigger-mediated nested writer findings in DRAFT PR #493 remain **partially** open; final old-token/epoch coverage and release-time backup/cleanup are separately governed.

## New-chat restart instruction — canonical active pointer

> **Продолжай Mathematics P1/P5 Issue #450 по roadmap v2.1 (Stage 3–6 written-evidence recovery). Сначала прочитай этот документ, исходный v2.0 roadmap, последние комментарии Issue #450, DRAFT PR #492 и текущий дочерний PR исправления; проверь SHA и CI. Продолжай ровно с первого незавершённого P4-01/P4-02/... пункта, не повторяя пройденные этапы. Письменные работы P1/P5 полностью не оцениваются автоматически. Не путай контроль условий выполнения с экзаменационным баллом; Core работает без Mentor, но не даёт ложных grade/readiness. Проверки на изолированном PG17 с настоящими подписанными запросами, без production, merge/deploy, переписывания ответов, сброса Practice/Tours или beta cleanup. Исправляй настоящие баги и фиксируй фактический SHA/CI/следующий пункт в Issue.**

## Checkpoint and acceptance log

- **2026-11-05 P4-01 initial audit:** 16/16 published full-paper assessments are written-only with 0 objective marks; no approved Stage 5 threshold rows. In-progress corrective child branch; **no code or production acceptance asserted yet**.
- Completed P4-02...P4-06 must be documented with exact implementation SHA and independently executed tests, not old inherited green runs.


## P4-02 isolated implementation candidate (2026-11-05; CHECK EXACT CI BEFORE GREEN)

- Added future-only migration `20261105153000_exam_prep_p1p5_timed_execution_comparable_v1.sql`, which introduces a **new** private service-role-only `exam_prep_timed_execution_comparable_v1` helper. Unlike score comparability, it does **not** deny completed but ungraded writing; it preserves time, non-diagnostic status, integrity, paper epoch and exam-series comparisons and requires finalized genuine timed/paper sessions. Existing score comparator, stage evaluator, marks, content and user evidence remain unchanged.
- Added disposable-only `p1p5_p4_02_execution_without_written_score_disposable.sql`, placed **after** existing genuine signed P1/P5 full-paper HTTP completion and **before** synthetic cleanup in full PG17 E2E. The synthetic acceptance expects two genuine paper attempts, each `execution=true`, `score=false`, `objective_marks=0`, privacy rights intact, non-timed mixed and NULL requests false.
- The first exploratory CI workflow edit had a YAML colon in an unquoted step title (source syntax error); corrected the title. The P4-01 negative baseline check has **SUCCESS** independent of any Stage3–6 fix.
- **Do not mark P4-02 accepted until the exact new SHA full PG17 signed E2E completes SUCCESS.** P4-03 through P4-06 remain open. No release GO and no live migration.


## Current checkpoint — 2026-11-05 P4-03/P4-04 isolated acceptance; P4-05 NEXT

The following **exact code SHA**, `8b0ded7a650c2ee453f76009984f9086784e057b`, completed **72/72 GitHub Actions SUCCESS** when PR #494 temporarily targeted `main` for CI only (no merge): [signed full PG17/JWT/PostgREST/Chromium #42003697360](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42003697360), [P2-36 current-schema expansion #42003697388](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42003697388), [P2-80 independent release audit #42003697391](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42003697391), [Stage D consolidated #42003697467](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42003697467) and [P3-17 canary #42003697389](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42003697389). The P2-36 run log explicitly reports **P2-69 full Stage 0–6 Core synthetic simulation: GREEN** and synthetic rollback. Green CI does NOT authorize public release.

**P4-03 isolated ACCEPTED:** guarded migration `20261105154000_exam_prep_p1p5_stage3_stage4_execution_evidence_v1.sql` changes **exactly three** source-validated service-only stage evaluators (Stage3 baseline, Stage4 raw full-paper progress, Stage4 timed-section count) from *scored* comparability to the independent *execution* comparator. The P4-02 execution helper was hardened to require a nonblank session AND persisted valid `exam_prep_responses` matching the claimed answered-item count; historical self marks or fabricated attempt-result counters alone cannot qualify. Genuine signed P1/P5 full written Papers and timed sections passed owner, ACL and score-negative tests. Historical P2-02 and P2-04 matrices were reconciled without weakening the academic score firewall.

**P4-04 isolated ACCEPTED as operational architecture (NOT assessed readiness):** `20261105155000_exam_prep_p1p5_stage5_operational_calibration_v1.sql` adds private service-only `exam_prep_stage5_operational_completion_v1`. Core Stage5→Stage6 operational calibration requires Stage4 completion, **at least 3 compatible executed** full Papers, objective skill L3 and no unresolved correction cycles; it is independent of Mentor and must not issue an exam grade. The grade/score-based `exam_prep_stage5_readiness_status_v1`, its readiness projection, numeric thresholds and written-mark scoring remain unchanged, fail-closed and explicitly **ungraded/not-ready** for all-written unmarked Papers. The original P2-69 simulation no longer invents scored full-paper results or Cambridge thresholds; written practice artifacts are now submitted through the genuine public RPC in isolated PG17, and Stage6 remains operational only. Separate signed P1/P5 single-Paper negative P4-04 test passed: one paper cannot open Stage6, no readiness claim.

**FIRST UNFINISHED: P4-05.** Extend source-backed E2E to genuine server-authenticated **three full Papers** per P1 and P5, missing/skipped submissions, in-time/late, integrity strikes, stale authorization, retries, cross-user and cross-component protections, and full three-language mobile/desktop projection; independently prove no false scored readiness, no reset and disposable cleanup. The existing P4-04 P2-69 lifecycle simulation contains a controlled isolated test-harness timed-results row after real written response submission; it is **not** equivalent to three complete signed HTTP timed-finalization paths. P4-06 integration/release checks remain OPEN; public NO_GO, production migrations/merge/deploy/cleanup not authorized. P0-16B PR #493 remains separate and OPEN. This checkpoint supersedes the earlier exploratory P4-02 text above.
