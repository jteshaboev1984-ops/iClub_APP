# Mathematics P1/P5 S6 — guarded public-Math integration bridge, source-only

**Date:** 2026-11-10 · **Source parent:** [S5 OFF DRAFT #524](https://github.com/jteshaboev1984-ops/iClub_APP/pull/524), inheriting S4 [DRAFT #523](https://github.com/jteshaboev1984-ops/iClub_APP/pull/523), S3 [DRAFT #520](https://github.com/jteshaboev1984-ops/iClub_APP/pull/520) **which already contains every S2 [DRAFT #519](https://github.com/jteshaboev1984-ops/iClub_APP/pull/519) source path**.

## 1. Exactly what the code changes

`supabase/migrations/20261110123000_exam_prep_math_s6_guarded_public_auth_bridge_v1.sql` is a single transaction with a guarded replacement of the **existing** `private.exam_prep_require_core_access_v1()` definition. It appends exactly one conditional term `OR private.exam_prep_s5_public_math_eligible_v1(v_uid)` to the ORIGINAL beta authorization's OR tree.

- The present beta `auth.uid()`, registration, `exam_prep_feature_config`, `qa_open_all_core`, existing entitlements, time bounds, `core_enabled`, `rollout_state` and global kill switch logic are all **preserved**. The owner/entitlement policy is **not replaced**.
- The additional term can be TRUE only under S5's separate flag **`public_math_core_enabled=true`**, independent public kill switch OFF, documented owner-GO evidence, global Core still enabled/not killed, real registered user, and a Mathematics subject id=5 enrollment with mode **study or competitive**. Existing S5 state is OFF.
- On migration startup, require exact OFF S5 config; refuse if public access is already ON or if the expected legacy beta function/entitlement snippet changed. Failure aborts entire transaction without partially patching source.
- No user/progress/certificate/migration-history DML; no global production feature flag update; no AI/Mentor tariff or marking changes.

**Verified source inspection only:** live `private.exam_prep_require_core_access_v1()` was read via SELECT; its hash was `0b6fc256fe5d2f191c70f0ec57c513e9` at inspection, and the proposed replacement anchor occurs EXACTLY once. A local pure string substitution verified that **removing the new OFF-only public predicate reproduces the previous function byte-for-byte**. This is NOT a signed PostgreSQL17 execution or proof of full source integration.

## 2. Critical distinction: existing QA beta vs future public access

Live controlled-beta configuration previously observed `qa_open_all_core=true`. This means the existing QA/beta pathway has historically broader eligibility than the *new strict S5 public path*; this migration intentionally **does not revoke it** because current real users might rely on it.

**Therefore DO NOT claim all non-Mathematics registered accounts cannot reach the existing beta just because S5's strict public entitlement denies them.** Public-path Mathematics enrollment is verified; existing controlled beta remains separately governed. Before S7 mass release, inspect which real beta accounts rely on `qa_open_all_core` (aggregate/read-only) and agree on a non-disruptive cutover; do NOT flip `qa_open_all_core` automatically. This is a launch-policy/data-preservation issue, not an excuse to rewrite user progress.

## 3. One actual E2E remaining — do not manufacture more tests

The whole source lineage is now **S2 as included in S3 #520 → S4 #523 → S5 #524 → S6 guarded authorization bridge**; D03 #518 already merged. Do NOT cherry-pick #519 or replay any known LIVE Extra Hard migrations.

When GitHub Actions jobs can actually start, run **ONE exact assembled source SHA** on disposable PostgreSQL17 and signed JWT/PostgREST with a targeted Chromium RU/UZ/EN check:
1. S5 OFF: old beta-entitled authenticated learner still gets the same Core access; no Math public shortcut; guest denies; old local/DB data untouched.
2. Disposable-only S5 ON with a mock owner-GO ref: Math study and competition enrollees are admitted, non-Math-only account denied by the **strict** public route, old beta entitlement route preserved; public kill switch and global Core kill switch deny new public access; expiry/anon/replay reject as appropriate.
3. S4 OFF by default; paper-first route only under explicit client+server beta permission; all Paper counters are learning journal, not checked marks; previous 12 leaked answer parts **disabled**; no self-scoring. Confirm stage L2/L3/correction constraints, P1/P5 separation.
4. Browser mobile RU/UZ and desktop EN: user enters from separate Paper action, Stage0 diagnosis remains intact, stops/returns/resumes, criteria+short hints review in an honest collapsible per-question display, print only actual questions, no invented solved-paper mark.
5. Source/persistence fingerprints: old Exam Prep, Practice, Tours, Extra Hard, certificates, language preferences and other subjects unchanged.

**CI blocker:** last associated workflow attempts failed before creating a job; no claim of current green E2E. Do not repeatedly trigger no-job CI by meaningless commits. Once a complete stable candidate is ready and Actions enabled, run the one grouped acceptance.

## 4. Remaining release gates beyond S6 code

**S4 academic content:** no verified full worked solutions for all 51 questions; current guided review uses approved criteria+short hints and labels the limitation. Previously leaked 12 final-answer parts must stay disabled for blind checks. New genuinely confidential keys can be approved only inside owner-controlled private storage after source review, never public Git; optional checker may legitimately offer none.

**S7 release:** reconcile **current** production SHA/migrations with this source lineage and preserve old live beta rights; rollback/kill-switch and device smoke; obtain a separate explicit architect GO to merge/apply migrations and change rollout flags. Do not enable public Math, S4 or AI marking in this draft. Mentor and tariff-entitled AI method marking remain future only. P0-16B OPEN separately; no beta cleanup authorization.

**Next after source package:** 1) resolve GitHub Actions ability to create actual jobs without blind retries, 2) complete one assembled E2E, 3) produce S7 GO/NO_GO with a concrete safe live cutover and old-beta-preservation policy.
