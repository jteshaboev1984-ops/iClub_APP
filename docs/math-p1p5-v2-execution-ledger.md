# Mathematics Exam Prep P1/P5 — v2.0 execution ledger / restart checkpoint

**Issue:** [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450)  
**Last checked:** 2026-11-02 UTC · **Current workflow:** Package 0 IN PROGRESS; Packages 1–8 NOT STARTED under new v2 plan.  
**Authoritative approved product workplan:** [full v2.0 plan](math-p1p5-release-workplan-v2-20261102.md).  
**Change-control:** [v2.0 addendum](math-p1p5-v2-governance-addendum-20261102.md).  
**Existing E2E ledger:** [old integration plan v1.16](math-p1p5-integrated-e2e-release-roadmap-v1.md); preserve all authentic proof from PR #451–#467.  
**Reproducible production SELECT-only baseline:** [p1p5_v2_package0_baseline_readonly.sql](../supabase/tests/p1p5_v2_package0_baseline_readonly.sql).

## The precise new-chat handoff

User can send exactly:

> Продолжай цифровой E2E-полигон Mathematics P1/P5 по GitHub Issue #450. Прочитай сохранённый roadmap, проверь текущий прогресс и работай с первого незавершённого этапа.

**Required executor behavior:** fetch issue #450 and links in the pinned v2 header, read entire full v2.0 workplan (not only a summary), this checkpoint, change-control addendum and prior E2E v1 status; read latest main SHA, relevant PR/CI and live Supabase read-only state. Then continue the first **uncompleted v2 package** and the corresponding unclosed engineering acceptance, not Stage A already done or unnecessary academic rechecks. Record exact file/PR/CI evidence and next action in this ledger + issue #450 after each large verified stage. User has no coding fluency; do technical work safely on isolated branch and give short clear results.

## Checkpoint P0-01 — read-only state verified (2026-11-02)

**Repository:** jteshaboev1984-ops/iClub_APP. At this audit, production Vercel most recent READY SHA \`bdb98e0c85f7ffdf0b15736068d79259fbb810d3\`, built automatically from previous docs/CI PR #467. **Do not assume it remains latest at next-chat time.**  
**Supabase:** mmmduffgpvwjdpruzikw (ACTIVE historically; all this checkpoint's queries were SELECT-only).  
**Observed live read-only state:**

| Measure | Observed count / state | Interpretation |
|---|---:|---|
| Registered users | 1,476 | Never delete \`public.users\` |
| Mathematics enrolments | 881 | 811 competitive + 70 study as previously verified |
| Mathematics Exam Prep sessions | 548 | Includes old beta/test activity |
| Active Exam Prep sessions | 61 | Now test data by architect's explicit release reset decision, but do not erase before GO |
| Exam Prep profiles | 120 | Test data subject to future precise scoped reset |
| Active individualized Core grants | 3 | Preserve AI/Core beta entitlement until authorized cutover |
| AI eligible individualized grants | 3 | AI is a separate future paid launch, do not broadly expose |
| Stage5 approved thresholds | 0 | Never invent Cambridge grade thresholds |
| Timed attempt results | 0 | Prior isolated timed successful tests do not equal live attempts |
| Timed written self-marks | 0 | API and client support still exists; must retire safely |
| Feature config | controlled_beta; core=on; ai=on; mentor=off; kill=off; QA-open Core=on; QA-open weekly=on | Broad QA access not real release readiness |
| Existing mass gate | NO_GO: four_real_weekly_reviews_incomplete | Must version/change formally, do NOT falsify |

**Dependency inventory first pass:** in \`private\`, 122 tables matching \`exam_prep_%\` (total); 44 with a direct user-id-like column; 4 additional tables with indirect link IDs but no direct learner-id column; 196 foreign-key constraints attached to Exam Prep tables. This is a **schema inventory, NOT a safe deletion allowlist**. It includes program/content catalogs, beta governance, mentor/AI data and support tables not to be blindly cleared.

**Existing cleanup functions observed (names only, not run):**
- \`private.cleanup_exam_prep_synthetic_run_v1\`
- \`private.exam_prep_beta_cleanup_provenance_v1\`
- \`private.transition_exam_prep_synthetic_cleanup_v1\`
- \`public.cleanup_exam_prep_beta_synthetic_progress_v1/v2\`
- \`public.get_exam_prep_beta_cleanup_readiness_v1\`

The historical cleanup routines may target **synthetic** rather than the architect's new once-only broad prelaunch Math Exam Prep test state; do not call before understanding dependencies and ownership. Some direct-user tables (e.g., AI grants, consent, staff roles) **must be carved out**; do not assume prefix inclusion means deletion authorization.

**Source-level release blockers confirmed:**
- \`exam-prep-live.js\` \`deadlineMs()\` expects \`session.timing_contract.deadline_at\` but public \`get_exam_prep_session_safe_v1\` does not include \`timing_contract\`; actual browser countdown has no valid deadline. Server deadline logic must remain authoritative.
- \`public.submit_exam_prep_timed_written_self_mark_safe_v1\` still accepts learner marks, and stage5 score aggregation can add them. Violates D03: must remove all UI/direct-API paths and paper/readiness self-mark dependencies, not fabricate 75/50 full marks.
- Profile \`renderProfile()\` and \`save_exam_prep_exam_profile_v2\` take free-text exam series/target, weekly hours, no P1/P5 confirmed exam date and no diagnosis-to-exam workload engine.
- \`private.rebuild_exam_prep_placement_v1\` sends completed diagnostics conservatively to Foundation; cannot claim calibrated fast-track.
- \`public.questions.difficulty\` DB CHECK allows only easy/medium/hard; separate versioned metadata needed for Extra Hard; preserve old global CHECK.
- Some client API/boot paths require rolloutState=controlled_beta; simply flipping production to "mass" is unsafe.
- Every 45/45 P1 and 36/36 P5 syllabus skill currently has at least one published assessment and published written task; this **does not** prove enough independent Extra Hard or retest items.
- Older 36-week learner windows are planning-only; \`calendar_auto_promotion=false\`. Current personal exam-date recommendation not implemented.

**Read-only fixture check:** exact checked-in draft-branch SQL executed against live Supabase with a syntax/safety guard checking for prohibited DML/DDL; returned old governance gate NO_GO as expected. No production write of any kind or Vercel deployment was made from this work.

## Package 0 completion conditions (still open)

- [x] Locate existing GitHub issue #450, original roadmap, PR #451–#467 evidence and successful Stage D technical evidence.
- [x] Persist **full exact v2.0 approved workplan** in GitHub branch.
- [x] Draft additive versioned governance/change-control addendum; explicitly distinguish old release gates.
- [x] Observe real Supabase baseline, present flag state, 122-table/196-FK first-pass inventory using SELECT only.
- [x] Create and run committed SELECT-only baseline fixture; verify old gate remains NO_GO.
- [ ] Expand cleanup dependency map to **exact** allowed learner-state tables and indirect children, protected tables, ownership scoping, old Practice v2 vs current Practice v3, and hidden JSON/client-local state. Produce proof-oriented dry-run, not cleanup.
- [ ] Prepare isolated restore/rehearsal and verified backup plan before any destructive user-state cleanup; confirm legacy Tours, certificates, Practice v3, Economics/Chemistry unaffected.
- [ ] Review full exact superseding decisions against project Master Implementation, Content Governance, Safety, Beta Release and current source; obtain formal merged versioned release-policy acceptance.
- [ ] Finish Package 0 acceptance artifacts and record the final evidence; **only then** proceed to Package 1 exam dates/diagnostic anchors.

## Preserved old-E2E progress and remaining engineering proofs

The old E2E tracker is valuable but **not a substitute for v2 new functionality**:

| E2E stage (old #450) | As of PR #467 | Do not redo | Remaining |
|---|---|---|---|
| A source trace | COMPLETE | 61/61 RPC map | None unless a new contract changes it |
| B isolated HTTP/Chromium | MOST TECHNICAL PATHS PASS; not formally closed | Real P1/P5 diagnostics, learning, correction, due retest, mixed, timed/paper server path, written Next, multilingual reopens | Hosted GoTrue refresh and short consenting Telegram/browser device check; v2 no-self-mark and timer end-to-end |
| C model-based faults | PARTIAL, many GREEN | 33 stage0 profiles, 1,448 metadata objects, auth/first-commit races, 600/10 load, retest/recovery/clock paths | Unproven **full** 15 canonical+18 adversarial longitudinal UI journeys, v2 workload/choice/extra-hard/cutover |
| D engineering gate | TECHNICAL PASS in isolated CI; release NO_GO | Exact same candidate SHA 3-source green evidence, 18 steps and negative stale-gate tests | v2 release addendum, automated coverage expansion, short device smoke, formally governed new gate and architect signoff |

## Exact next task

**Continue Package 0 without production writes:**
1. Read \`docs/math-p1p5-release-workplan-v2-20261102.md\` sections 0–3, 6–10 fully; verify current repo main and live function definitions. Reuse current branch/PR if unmerged.
2. Build a full **targeted cleanup graph** for test-only Mathematics Exam Prep, identifying every indirect FK child and non-cleanup exception. Confirm old Practice v2 cleanup and current Practice v3 by read-only query, not prior memory.
3. Write a no-write dry-run report with exact per-table counts and unaffected invariants; test the algorithm in disposable PG17 with seeded users, verifying rollback and cross-module isolation. **Do not execute production cleanup.**
4. Then start Package 1 (verified Cambridge P1/P5 date registry + diagnostic completion anchors) as an additive PR, with three-language UX and local E2E.

**Hard stop:** no production cleanup, schema mutation, feature flag, public AI, Vercel deploy or beta entitlement change without an explicit separate architect GO. A draft documentation PR is not GO.

## Update protocol for every new chat / major package

Append one dated checkpoint containing: baseline SHA; exact changed files; verified tests and actual results; unresolved defects; old vs new release gate status; production DML/deploy disclosure; next task. Update issue #450 to point here. Never mark work complete from mere source presence, synthetic-only record posed as consented beta, or an unstated policy override.
