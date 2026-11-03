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


## Checkpoint P0-02 — Practice version and non-Math access reality (2026-11-02, SELECT only)

A source-to-database ambiguity from the older plans has been resolved **without writes**:

- Current *published server Mathematics Practice bank* is **v2**, release key \`math_p1_practice_v2_2026_10_07\`, numeric \`public.practice_bank_generations.generation=2\`. Published release audit records 490 old memberships replaced by 495 new memberships on 2026-10-08, \`status='published'\`, no rollback; \`public.is_math_practice_v2_published_safe_v1\` exists. **Do not invent a published bank generation=3.**
- The separately named browser local storage namespace \`practice_history_v3\` in Practice v2's historical runbook is **not** proof of a newer server bank. D06's "preserve new Practice v3" must be implemented as **preserve current published Practice bank plus postrelease local state**, regardless of version naming. Check actual app source for exact keys before cleanup.
- Current user activity **must be protected**: in public.practice_sessions_v4 there are 15 Mathematics rows with bank_generation=2, and in public.practice_drill_sessions_v4 there are 14 Mathematics rows with generation=2. public.practice_attempts contains 13 Mathematics rows with NULL bank_generation, for 7 distinct users: these cannot automatically be classified and deleted as old test garbage. Zero \`private.practice_reset_archives_v1\` rows does NOT disprove a completed reset because the published audit is a stronger source for the v2 controlled release.
- Economics native Exam Prep registration is \`status=published, launch_enabled=true\` (chemistry is \`status=draft,launch_enabled=false\`). The shared Math host still checks a server-supplied Economics shell. This conflicts with newly approved D02 for **future public Math release**: the exact change must be coordinated at Package 6 and must not delete Economics beta content or change its production flag without controlled access transition.
- The independent math program entry in \`private.iclub_exam_core_programs_v1\` remains \`status=legacy_external, launch_enabled=false\`: do not infer Math Core is disabled from this separate native-shell registry; Math currently uses its own server entitlement/QA logic.

**Result:** Package 0 investigation is progressing but exact scoped cleanup allowlist, browser-key inventory, full FK graph / restore rehearsal remain OPEN. No production DML performed.

**Protection decision for next chat:** treat current Mathematics Practice published v2 and its current v4 sessions as preserved production data regardless of any earlier shorthand "Practice v3." Do not reset it during Exam Prep launch. Also do not hide the Economics launch-enabled discrepancy: preserve history, plan selective D02 access restrictions for a later approved technical package.

## Checkpoint P0-03 — verified dry-run and isolated PG17 guard (2026-11-02)

**Package 0 IN PROGRESS; production release NO_GO.**

- [Consolidated read-only candidate scope report](../supabase/tests/p1p5_v2_package0_cleanup_scope_report_readonly.sql) was run against actual production Supabase under SELECT-only guard. Returned DRY_RUN_ONLY__NO_MUTATIONS. **32 provisional learner-state tables; 19,794 exact current rows total**. This is NOT a production cleanup approval or a scoped user-by-user DELETE count.
- FK scope: 38 inbound foreign keys, of which one originates from a retained table — Mentor queue -> human review recommendation (ON DELETE RESTRICT). Currently zero populated Mentor queue references; fail closed if nonzero at release.
- Non-deferrable authorization/session FK cycle: 548 authorization consumed-session links and 548 mandatory session authorization links. An eventually authorized transaction must unlink nullable consumed_session_id, handle every dependent child, and only then delete root rows. NO such transaction ran in production.
- Protected production baseline: 1,476 user accounts; 881 Mathematics subject selections; 149 Mathematics tour attempts, 2,477 tour answers, 66 Math certificates; current Mathematics Practice server generation 2 with 15 sessions, 14 drills, 13 practice_attempts; 496 non-Math Practice attempts; three active AI grants; three beta consents; 14,748 Exam Prep audit events; 70 Math content versions and 334 written tasks. Economics native launch_enabled=true is a separate access task, not an excuse for wiping beta history.
- Exclude from any automatic reset: users, app registration, all Tours, certificates, Mathematics Practice current published bank and post-cutover local keys, other subject records, published academic content, AI grants, beta consents/policy until explicitly governed, audit records, source/QA metadata.
- Exam Prep live JS is server-driven for learner state; exam-prep-store.js is a preview store, not authoritative live progression. The exact existing practice cleanup script security/practice-v2-local-reset.js only removes old practice_history_v2:mathematics:tour_* after server publication proof and preserves current practice_history_v3. Do NOT call localStorage.clear().

### Genuine disposable PostgreSQL test, not production

- [Synthetic isolated PG17 rehearsal](../supabase/tests/p1p5_v2_package0_cleanup_isolated_fk_rehearsal.sql) explicitly tests actual NOT DEFERRABLE ON DELETE RESTRICT parent cycle, retained Mentor link rejection, scoped learner-state deletion, non-target learner retention, protected Practice/Tour/certificate retention, repeated cleanup and SAVEPOINT rollback. The entire rehearsal transaction is rolled back.
- [Node source guard](../scripts/p1p5-v2-package0-scope-guard.cjs) rejects mutation keywords in actual production dry-run files and checks the 32-table provisional manifest and excluded data contracts.
- [GitHub Actions run 41498044157](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41498044157) COMPLETED SUCCESS: real isolated PostgreSQL 17 workflow job 125458041110, every required step success, including synthetic FK rollback and zero remaining rehearsal schema. These are genuine automated technical tests but the schema is a deliberately simplified model, not full 122-table production-equivalent rehearsal.

### Remaining Package 0

1. Full current-migrations disposable PG17 rehearsal with all actual relevant FK parents, real structural checks, release backup/restore drill. Do not substitute the small synthetic model for this.
2. Exact approved allowlist by program/learner plus deferred beta/audit/AI retention decision and all indirect children; produce fail-closed cleanup authorization dry-run. No direct DELETE yet.
3. Review with master implementation / beta / content / safety governance docs and formally approve versioned accelerated release gate. Current old mass gate still NO_GO.
4. Once all Package 0 release-safety artifacts are verified, advance to Package 1 dates and diagnostic anchoring.

**No production DML, DDL, feature flag, AI permission, clearance or mass release was performed in this checkpoint.**

## Checkpoint P0-04 — two nullable FK cuts and actual migration-schema test (2026-11-02)

**Package 0 still IN PROGRESS; no production writes; beta/mass release NO_GO.**

### New independently verified facts

- [Authoritative read-only structural FK check](../supabase/tests/p1p5_v2_package0_fk_graph_readonly.sql) was executed on actual production Supabase; verdict GRAPH_PRECHECK_PASS_NO_DELETE_AUTHORIZED. Exactly 32 candidate learner tables, 37 internal FK edges; after excluding **TWO** nullable authorizations FK links, the 32-table dependency graph has zero cycles. The links are exam_prep_session_authorizations.consumed_session_id -> sessions and exam_prep_session_authorizations.correction_case_id -> correction_cases. Do not bypass constraints: releasing only consumed_session_id leaves the correction/evidence/response/session/authorization cycle unresolved.
- One currently empty retained inbound exception: exam_prep_mentor_queue_items.recommendation_id -> human_review_recommendations.id, RESTRICT. Fail-closed if its row count becomes nonzero at cutover. This is not a grant to delete historical Mentor Care records.
- Live read-only owner-scope check: **28 of 32 candidate tables have direct user_id / learner_user_id** and **zero rows in those tables belong to accounts lacking current Mathematics subject enrollment**. The remaining four tables are indirect references and require relational ownership joins. These counts are evidence only, not authorization for table-wide deletes.
- [Expanded synthetic PG17 two-cycle and Mentor blocker test](../supabase/tests/p1p5_v2_package0_cleanup_isolated_fk_rehearsal.sql) GREEN: [run 41499740447](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41499740447); genuine FK violations on premature deletion, two-link unlink, idempotent scoped simulated deletion, protected other learner/Practice/Tours and rollback.
- [Real current-migrations PG17 fake learner FK proof](../supabase/tests/p1p5_v2_package0_full_schema_fk_rollback.sql) integrated into the existing [full P1/P5 signed HTTP/Chromium suite](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41499740468), run 41499740468 **COMPLETED SUCCESS**, including the new actual-schema P1 fake session/auth link block/unlink/delete and SAVEPOINT rollback. All previously required browser/RPC suite steps also succeeded. It does not yet execute a full 32-table deletion, and the second correction chain is currently checked in real schema through read-only FK metadata plus PG17 representative synthetic model.
- The historical Stage D exact-SHA gate for this newer candidate was still running at this checkpoint. It requires separate load and disaster workflows on the **same** SHA; do not describe current partial P0 tests as old Stage D PASS or release GO. Historical Stage D PR #467 technical PASS remains separate.

### Required next technical work

1. Extend existing disposable current-migrations PostgreSQL 17 rehearsal to generate real target records across **all 32** learner-state tables, then test two-link scoped cleanup and re-entrant rollback without retaining Mentor-child references or touching second synthetic account/Practice/Tours/content. No production SQL writes.
2. Build exact per-table ownership/indirect joins and compile an explicit fail-closed allowlist that is **only executable in isolated CI** until final architect GO. Re-run current FK graph after code changes; a schema drift must block.
3. Prepare secure scoped backup and verified restore strategy for real cutover, including preserved AI entitlements, beta consent/audit retention decision, login/session epoch and cross-subject invariants. Old 4 real weekly reviews/72h gate requires versioned replacement; never fake evidence.
4. Only after Package 0 acceptance proceed to Package 1: confirmed P1/P5 dates, diagnostic completion anchors and personal study horizon. The full workplan is in docs/math-p1p5-release-workplan-v2-20261102.md, PR #468 and Issue #450.

**No user accounts or progress, feature configuration, AI grants, existing Practice v2, other subject data, production DDL/DML, or Vercel production deployment was changed by these tests.**

## Checkpoint P0-05 — full 32-table isolated cleanup/rollback CI GREEN (2026-11-02)

**First successful exact executable SHA:** `9bbdf9ac5b75451f9242f2d466d2d4337a9ce06a`; **[GitHub Actions real-HTTP/Chromium/PG17 run #41502015565](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41502015565) completed SUCCESS**, job `125471610990` (36 steps), including the new `Package 0 full 32-table scoped fake-learner cleanup and complete rollback` step SUCCESS. This commit differs from later documentation-only commits; don't misrepresent a different SHA as tested.

### What the actual production-shaped isolated schema test proves

- Exact new fixture: [`supabase/tests/p1p5_v2_package0_32table_disposable_rollback_only.sql`](../supabase/tests/p1p5_v2_package0_32table_disposable_rollback_only.sql). Runs **only in disposable PG17** with `current_database()='postgres'`, guarded `iclub.e2e_isolated=true` and exactly two specific fake P1/P5 users; never sent to production.
- All **32 scoped table DELETE statements** executed in the two-FK-cut DAG order for only synthetic fake user A. Four dependent child tables use joins to user-owned session/plan/revalidation/correction IDs. No public user, Practice, Tour or certificate rows were deleted. The second fake learner and protected counters remained unchanged.
- The test first required a real immutable learner response and attempted an unguarded DELETE: actual immutable trigger correctly rejected it (CI log `PASS: authentic immutable evidence trigger denies unguarded delete`). Only afterward **in disposable CI** did the test set transaction-local existing `iclub.exam_prep_synthetic_cleanup=on` to use the pre-existing narrowly synthetic cleanup exemption, never disabling triggers.
- CI log independently reports `PASS P0 actual 32-table synthetic learner-state reset; protected public and other user unchanged`; `PASS P0 second same-scope cleanup is idempotent`; `PASS P0 full 32-table learner-state counts restored by SAVEPOINT`. All checks executed under one transaction and a final ROLLBACK. Existing diagnostic, due retest, mixed transfer, timed/paper, multilingual written/HTTP, fault and security test steps also GREEN on this SHA.
- The synthetic bootstrap is intentionally narrower than real iClub app: only missing protected public tables were provisioned with fake rows inside the always-rolled-back CI transaction. Most of the 32 table routes use genuine post-E2E learner records; some zero-row paths remain and therefore are schema/order tests rather than nonempty deletion tests. **This is NOT proof of actual encrypted production backup/restore or a relaunch-ready cleanup.**

### Genuine blocker discovered and documented

- Production `private.exam_prep_block_immutable_mutation_v1()` protects responses, evidence events, correction actions, integrity events, timed result facts and other immutable records. Only `iclub.exam_prep_synthetic_cleanup=on` currently permits some deletes. The existing `public.cleanup_exam_prep_beta_synthetic_progress_v1/v2` requires synthetic-present review state, no real monitoring epoch, AI disabled, kill switch on; **does not apply** to the current real-monitoring beta or future real prelaunch test-state purge.
- The future release-time cleanup needs a **new versioned, strictly authorized one-shot real-prelaunch procedure** with owner-approved exact target, secure backup/recovery, locked new Exam Prep writes, explicit allowlist, preservation of historical audit/consent/AI policy as decided, and no ordinary-app permission bypass. Do not use the synthetic cleanup flag in production on real beta learners.

### Status and next precise work (Package 0 remains IN PROGRESS)

1. Prepare verified secure backup/restore implementation and governance plan for the ONE-TIME controlled release-time purge, using only synthetic records in CI. Do not export real account records into GitHub.
2. Formalize exactly what to retain or archive among 14,748 audit events, beta consent/membership, AI entitlements, optional Mentor/security records. Current published Practice bank and Tour history are protected.
3. Draft/review versioned release-cleanup authorization and accelerated mass Core gate without falsifying prior 4-week/72-hour evidence. Do not actually apply production migration/flags until final architect release GO.
4. Once Package 0 is formally accepted, proceed to Package 1 (confirmed P1/P5 exam dates + completion-anchored study horizon).

**Production Supabase DML/DDL: ZERO. Vercel production deploy: NONE. AI users/flags, practice data, Tours, other subject data: UNCHANGED. Old public release gate: NO_GO. PR #468 remains draft.**

## Checkpoint P0-06 — independent synthetic PostgreSQL 17 backup/restore GREEN (2026-11-02)

**Actual successful test:** [GitHub Actions run 41503416002](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41503416002), exact code SHA `b87afff6d49e51bfc31812b9221aa1edbb182b1c`, job `125476453184`, status SUCCESS. Both the earlier 32-table scoped fake-user rollback and the new independent backup+restore step were GREEN.

- The first backup attempt on SHA `7590b9ea19c0b8aa51f742ce73e5c28c91093f24` failed **only** because the GitHub Ubuntu runner supplied `pg_dump 16.15` to a `PostgreSQL 17.11` server. This was fixed by running the existing repository backup script inside the ephemeral `postgres:17` container with localhost-only PG and exact two-fake-user guards. No application runtime or production migration changed.
- The [synthetic-only backup/restore script](../scripts/p1p5-v2-package0-synthetic-backup-restore.sh) creates a private custom-format archive of the disposable two-user integration database, restores it to an **independent new PG17 database**, compares deterministic account/session/authorization/response/evidence fingerprints and counts of academic content, entitlements and protected Practice/Tours/certificates, and then deletes the temporary archive and disposable restore database. No archive is uploaded to GitHub; no production user data is downloaded.
- Actual job log confirms `PASS: synthetic-only PG17 backup restored to independent DB; exact account, academic, content and protected fingerprints match` after the immutable-fact negative test, 32-table isolated fake-user reset, repeat and SAVEPOINT restore all passed.
- **Package 0 remaining:** approving preservation/retention of audit and beta-control facts, specifying strictly controlled versioned *real-prelaunch* cleanup authorization (must not use synthetic cleanup GUC against real learners), securing/validating real production scoped backup at final GO, and formal governance/release-gate approval. A synthetic independent restore is not evidence that a real production encrypted backup exists. Other subjects and existing user progress remain protected.

**No Supabase production DML/DDL, no Vercel release, no access/AI flag changes and no live cleanup. Package 0 engineering backup rehearsal PASS, release NO_GO.**

## Checkpoint P0-07 — explicit retention and one-shot authorization boundaries (2026-11-02)

- Authored [Package 0 proposed release-authorization contract](math-p1p5-v2-package0-release-authorization-contract.md) under the existing architect-approved v2 cleanup goal. It is DRAFT policy and **not** approval for production purge or access opening. It defaults to retaining historical audit, beta consent/membership, immutable security/mentor records, AI entitlement and usage/policy; no invented retention period. The intended future reset is **only** the exact Maths P1/P5 prelaunch learner-academic-state allowlist after a separate final release GO.
- Required future one-shot release service: freeze Mathematics Exam Prep writes only, scoped encrypted verified production backup, per-user/child FK manifest, two nullable FK cut points, immutable-fact protected authorization, old-tab epoch replay prevention, transaction rollback, untouched Practice/Tours/Economics/Chemistry and exactly 3 AI grants. Do **not** use the preexisting `iclub.exam_prep_synthetic_cleanup` privilege against real beta learners; do not disable triggers.
- Expanded [Package 0 static safety guard](../scripts/p1p5-v2-package0-scope-guard.cjs) to protect 32 scoped replay DELETE sequences, isolate the intentional negative immutable-row DELETE test, enforce readonly production graph, backup fake two-account guards, exact isolated PG17 container invocation and the presence of release authorization protection. [CI run 41504358562](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41504358562) completed GREEN for source guard after correcting the initial guard's inclusion of the *intentional negative security-test delete*. No production write or weakening of immutable triggers.
- Backup/restore independent full-schema synthetic E2E remains confirmed **GREEN** on [run 41503416002](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41503416002), SHA `b87afff6d49e51bfc31812b9221aa1edbb182b1c`; do not falsely attribute earlier CI to later documentation changes.

### Exact next item

**Package 0 technical backup/rollback rehearsal DONE; Package 0 release-authorization/governance acceptance still OPEN.** Secure production backup itself, versioned real-one-shot release service with negative access/epoch tests, and human release GO must remain separate; current old mass gate is NO_GO. Once the final protected-data/authorization design has been accepted, start Package 1 verified P1/P5 exam-date/profile/calendar work in a separate implementation PR. No rollout or user reset should be inferred from CI green.

**Latest combined technical suite:** [CI #41504358560](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41504358560) on exact source SHA `5eadcc19d346dfabe996e964fdde169fe28c42d8` finished **GREEN**, including current-migration FK rollback, all 32-table cleanup/rollback and independent PG17 backup/restore on the same SHA; separate [Package 0 static guard #41504358562](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41504358562) also GREEN. Stage D's old mass evidence aggregator is separate and does **not** imply public GO.

## Checkpoint P1-01A — planned hours never cap actual study (architect update 2026-11-03)

- **Architect binding rule:** a learner who studies more than declared daily/weekly hours must not have lessons, already permitted sessions, or study progress blocked. Planned hours are a recommendation/capacity input only. Existing *assessment time limits, anti-cheat and one-attempt rights are independent* and remain enforced.
- Less-than-plan progress generates a **nonblocking** review only after a verifiable period. Existing `get_exam_prep_previous_week_adherence_safe_v1` counts frozen due goals with finalized academic evidence; it does **not** measure study minutes, and cannot infer off-platform work. Missing or contradictory data must suppress a quantitative alert.
- Current [draft PR #469](https://github.com/jteshaboev1984-ops/iClub_APP/pull/469) adds RU/UZ/EN dashboard advice and **three safe actions** on verified missed goals: keep plan (no backend write), open current authorized tasks (existing navigation), edit days/minutes (focus; only changes on confirmed Save). It also explicitly explains that extra learning is allowed. A valid learner schedule remains bounded for **planning consistency** by total weekly availability; this does **not** block real extra learning.
- Verified by production **read-only** PostgreSQL function-definition search: no session/authorization/plan/goal function reads `mathematics_hours_budget` to impose a quota. Existing nightly/weekly adherence RPC is reused, with no new time-logging table or invented Cambridge per-skill norm.
- Current app branch `feature/math-p1p5-exam-dates-horizon-v1-20261103`, implementation code SHA `b874c551fb1086c9d780c42026a30e0b2d7f2d26`, [full combined signed JWT/PostgREST/Chromium/PG17 run #41573625039](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41573625039) QUEUED at check. JS parse on new live/API/E2E source **PASS**. **Do not claim full green for this newest commit until CI finishes.** The previous schedule/dates candidate had [full E2E #41569187763 SUCCESS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41569187763).
- **Package 3 still requires** a *validated Cambridge-scope workload recommendation engine* before the fixed three **time-change** actions (`Оставить / Принять рекомендованное / Указать другое`) can present an accept-recommended-time option. Do not conflate these with the interim missed-task guidance buttons or invent precise Cambridge personal hours.
- No production SQL, Vercel deploy, QA/AI access changes, Tour/Practice modifications or old progress deletion were performed. Public Math Core remains NO_GO until governed release.

**Next exact action:** inspect newest PR #469 E2E result, fix genuine failures only; update Issue #450. Then proceed with Package 2 source-backed workload estimates (81 skills) and Package 3 consent-only schedule adjustments; avoid unnecessary fake student scenarios.
