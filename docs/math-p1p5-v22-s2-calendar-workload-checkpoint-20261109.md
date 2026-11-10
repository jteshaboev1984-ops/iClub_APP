# P1/P5 v2.2 — S2 calendar and 81-skill workload: main-based integration candidate
**9 Nov 2026 · Issue #450 · on main D03 source `23ea8e31814f4e8c659f9bc50a3078e9d2392e14` · DRAFT and rollout OFF.**

## Actual progress

1. Reused and relocated the **15 original source-proven** calendar/workload migrations from #516 (P1/P2). Reversioned into ordered `20261109130000...` through `20261109131400...` on the AFTER-D03, AFTER-LIVE-Extra-Hard main branch. Original SQL bodies were kept exactly as reviewed; versioned names are the new deployment units. These files are NOT applied to live Supabase.
2. Surgically ported the four legacy owner-only RPC adapters: `personalHorizon`, `studySchedule`, `saveStudySchedule`, `confirmExamDate`. No old client self-grade was restored; all four protected Extra Hard adapters remain intact.
3. Ported the existing RU/UZ/EN daily study schedule and **distinct P1 and P5** exam-date/time panels (school/centre confirmation, UTC+5, relative horizon only after diagnostic), plus corresponding phone-responsive CSS and cache busting, without replacing current Math home or any other subject.
4. Live PostgreSQL 17.6 already has **45 P1 + 36 P5 canonical skill contracts**. This maps all 81 skill codes; **it does NOT prove 81 academically approved minute estimates**. Source norm registries intentionally seed `unreviewed` with NULL numeric estimates and separate approval evidence requirements. Public UI must NOT show fictional approved Cambridge per-skill hours.
5. On the **existing** paid Supabase database, the first two source calendar and study schedule migrations were syntax/contract probed in one bounded `BEGIN ... ROLLBACK` transaction: functions validated; post-rollback proved both functions absent, user state unchanged. NO new paid copy database, NO schema change, NO learner write.
6. S1 D03 already **MERGED** [PR #518](https://github.com/jteshaboev1984-ops/iClub_APP/pull/518), live Supabase migration applied, signed PG17/JWT/PostgREST/Chromium acceptance PASS in D03 workflow dedicated ubuntu24.04 job. Do not re-run or re-publish this accepted S1.

## Honest next S2 acceptance

- Academic source approval for **each** per-skill action/core minute range is a separate evidence requirement. Until complete, numeric per-skill weekly recommendation must remain `null/unknown`; do not use Cambridge guided teacher hours as official personal study minutes. This is a genuine S2 academic dependency, not a reason to fabricate a number or make time compulsory.
- Test the entire exact 15-migration dependency chain against the existing schema in bounded rollback blocks first; adapt only demonstrated incompatible anchors and guard against overwriting already-live Nov9 Extra Hard.
- Finish an owner-bound signed date/schedule real API acceptance and mobile EN/RU/UZ view on a supported temporary, **no extra paid Supabase instance** runner. Existing live DB is for read-only preflight and rollback-probed function/source checks until safe targeted migration approval.
- When a self-contained verified set is ready, merge one main-based S2 PR; install only source-approved non-destructive mutations in a controlled existing-DB release. Public Math Core MASS flag stays OFF, all old Paper/Practice/Tours/other-subject results unchanged.

## S3 onward

After S2 source acceptance, port **S3 7-day completion period + three saved user choices**; **S4 P4-02→P4-08 Paper Stage3–6 separation of execution and externally verified marks**; **S5 P6 study/competitive public membership feature OFF**; one full current-source signed acceptance S6, then separately owner-authorized S7 mass enable. P0-16B remains separately unfinished; no beta data cleanup.
