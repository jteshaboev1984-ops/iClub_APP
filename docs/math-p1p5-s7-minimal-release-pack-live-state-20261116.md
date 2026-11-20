# iClub Mathematics P1/P5 — S7 minimal release pack

> **ACTUAL UX CONTROLLED-BETA RELEASE COMPLETED — 2026-11-16.** Owner answered «разрешаю» to the specifically scoped request for **UX-only production publication of #540 into the existing controlled beta**, with **NO SQL migrations, rollout/QA/stage flag updates or live learner writes**. [PR #540](https://github.com/jteshaboev1984-ops/iClub_APP/pull/540) was readied and squash-merged **after exact HEAD `b390ce46be2154ccba831bfd9a92521e991b338b` passed 56/56 CI**, into GitHub `main` SHA `464551650ae925ca3404feff4a5c4c506c49cd70`. Vercel **production READY** deployment `dpl_GhNT6FiyVkgkbPva18fbgNW9qpKK` and verified project alias `i-club-app.vercel.app` report that identical SHA. Prior READY prod `dpl_7Tc4WV4tQHHCcDdBavQbVfodBHnW` / SHA `dc8c9b08e9c56565aeb575bc22c93ca9f289838a` is documented rollback reference. This supersedes the PRE-RELEASE approval/production snapshot below.
>
> **Post-deploy live PG17 SELECT-only verification:** `controlled_beta`, Core ON, QA Core+Weekly ON, S4 Paper ON, Stage3–6 gates OFF, kill switch OFF; 7 previously installed source migration receipts; **120/120 Exam Prep profiles chose Mathematics**, no additional Stage6 bridge `20261116164000`; counts unchanged vs immediately before publication (1,477 registered, 883 Math-selected). No deployment SQL or config DML performed. **Do not construe Vercel READY as authenticated user/device smoke**: that step has NOT been exercised; generic public HTTP fetching was unavailable from this environment. One voluntary consented existing-beta account must still verify sign-in, P1/P5, S3 plan save/reload, Paper no marks, history and resume. Mass rollout and Stage6 PR #550 remain explicitly unapproved; P0-16B still tracked separately.


**Prepared 2026-11-16, READ-ONLY production verification.** This is a release handoff, **not approval or execution** of main merge, Vercel promotion, Supabase migration, mass rollout, feature flag changes, beta cleanup, live user writes, new AI cost or academic content publication.

## 1. Freeze the first releasable scope

**Release candidate:** [Academy OS UX531 DRAFT #540](https://github.com/jteshaboev1984-ops/iClub_APP/pull/540), HEAD `b390ce46be2154ccba831bfd9a92521e991b338b`. At this exact head **56/56 GitHub Actions SUCCESS** including actual-source Chromium, signed PG17/JWT/PostgREST S4 Paper, P2-36, P2-80 and intact UX-only release firewall. It is migration-free, no new infrastructure/cost, and has already had owner screenshot feedback incorporated. Do **not** bulk merge old workstreams #492/#523 or add unpublished academic bank material.

**Included:** Academy/Profile responsive UX, existing Mathematics P1/P5 Exam Prep screens, approved source/skills, profile and weekly choices/reports, existing diagnostics and Core, *optional* timed handwritten Paper review with **no Paper marks**, source-approved short guidance and **optional** mentor consultation, owner-only history. Ordinary objectively scored non-Paper Core evidence stays separate. Keep existing study budgets and guardrails; do not introduce forced Mentor, manuscript upload, invented grades, or extra Mathematics enrollment.

**Explicitly excluded from this minimal release:** [academic Stage6 bridge DRAFT #550](https://github.com/jteshaboev1984-ops/iClub_APP/pull/550), new `20261116164000` SQL, new Stage3–6 screen and opening `stage_gates_enabled`, unapproved AI/written grading, full worked solutions that have not been academically source-approved, paid features, Extra Hard rewrite, other subjects, live student records. Stage3–6 operational upgrade can be a separate later release; do not present readiness as an official Cambridge grade.

**Owner's binding policy:** [Paper never graded](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450#issuecomment-6915022101); optional final-answer match is not a mark. [Policy docs #548](https://github.com/jteshaboev1984-ops/iClub_APP/pull/548) remains separate DRAFT. Reject earlier future Mentor/AI grading assumptions in historical Nov 9 notes.

## 2. Fresh source/deployment/DB state actually inspected

| Item | Verified state at preparation |
| --- | --- |
| GitHub `main` | `dc8c9b08e9c56565aeb575bc22c93ca9f289838a` |
| Vercel current production | `i-club-app`, deployment `dpl_7Tc4WV4tQHHCcDdBavQbVfodBHnW`, **READY**, Git SHA `dc8c9b08e9c56565aeb575bc22c93ca9f289838a`; no new deploy done |
| Supabase | Project **iClub_APP** Postgres 17, live SELECT-only inspection |
| Registered users / Mathematics selected | 1,477 registered / 883 existing Mathematics subject rows (counts are a snapshot, NOT a permission grant) |
| Existing Math Exam Prep owners | **120 / 120** Exam Prep profiles also selected Mathematics; no account identifiers or progress exported |
| Beta source | `controlled_beta`, Core ON, kill switch OFF, **QA Core+Weekly ON**; preserve until a separate safe and approved transition |
| Hybrid Paper | `paper_enabled=true` in live DB; full handwritten Paper has **no score** |
| Hybrid stage projector | `stage_gates_enabled=false` live. Do not enable in this UX release |
| Installed migration receipts | D03 `20261109110109`, S2 `20261109111900`, S3 `20261109132000`+`20261109132100`, S4 `20261109154000`+`20261109155000`, Mathematics selection guard `20261115100103` all **already applied** |
| Subject-authorizer source | Both `private.exam_prep_require_core_access_v1` and `public.get_exam_prep_capabilities_v1` contain `iclub_math_subject_release_guard_v1`, as verified live |
| New Stage6 migration | `20261116164000` **NOT applied**; remains separate in #550 |

**CRITICAL:** Older Nov 10 source plans say S3/S4 uninstalled. This was accurate at that time but is **superseded by current live migration receipts**. Never replay D03/S2/S3/S4/subject guard because an older handoff says to do so.

Run `scripts/ops/20261116_math_s7_release_readonly_preflight.sql` immediately before an authorized GO to refresh this aggregate status. This is **one SELECT**, no PII or learner row updates.

## 3. A release sequence with only meaningful gates

1. **Source freeze:** Keep #540 unchanged; verify its exact HEAD, 56/56 CI, no unintended SQL/data paths, current `main`, correct Vercel project/production deployment, and current DB migration receipts. Do not integrate #550 into #540; its UX-only firewall deliberately prohibits SQL migrations. `main` is not allowed to receive code without **explicit owner GO for the exact scope**.
2. **Owner decision 1 — UX update for EXISTING controlled beta only:** after explicit approval, selectively merge reviewed #540, deploy matching code with existing Vercel integration, leave live `controlled_beta`, `qa_open_all_core`, `qa_open_all_weekly`, `paper_enabled`, `stage_gates_enabled` unchanged, and do **zero live migrations** for this scope. A passing CI is engineering proof, not a live deployment approval.
3. **Very short smoke after approved deploy:** with **consenting existing authorized beta account**, verify registered/Mathematics-selected landing, profile edit save/retry, My Plan S3 save+reload, P1/P5 navigation, ungraded Paper notice and history, ordinary diagnostic resume, no lost progress. Avoid new test-account writes into live data. If any critical failure, roll back Vercel frontend to previous confirmed production build; **never rollback existing DB migrations by deleting user rows**.
4. **Owner decision 2 — expand to ALL existing Mathematics selectors (`mass`) only separately:** the installed existing guard makes Mathematics selection sufficient for mass Core and denies nonselected users; signed [source-only access guard test #43702200664](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/43702200664) already covers study/competitive, nonselected direct RPC, QA OFF and independent AI/Mentor. However the currently **open QA overrides must be safely retired**, after confirming existing beta accounts' continuity and actual server-side activation path. **Do not change mass flags automatically**. The `private.exam_prep_weekly_flow_enrolled_v1` legacy function still references `controlled_beta` and does not mention `mass`; its relevance to a mass learner's intended weekly experience must be checked in the final mass-specific smoke, distinct from S3's newer owner-bound weekly RPCs. If it is used, resolve only that demonstrated mismatch (no new hours/mentor requirement).
5. **Owner decision 3 — Stage3–6 upgrade later:** [#550](https://github.com/jteshaboev1984-ops/iClub_APP/pull/550) has signed PG17/JWT/PostgREST positive objective-only progression + P2-06 exam-operations preservation **SUCCESS** on exact SHA `3e3e12a988d55f2abfeb4b8737cb8dc8bd333e66`, but overall PR checks **21/40 pass**, due to its older main baseline + Linux/Playwright and fixture failures. It is **NOT** approved for mixing into this UX rollout or for toggling live stage gates. A separately approved integrated academic candidate and fresh gates are required; if not ready, keep this feature OFF without delaying the UX-only beta improvement.

## 4. Security and other honest release boundaries

- [Issue #526](https://github.com/jteshaboev1984-ops/iClub_APP/issues/526): live Mathematics subject guard **already installed**, broad direct-RPC audit explicitly tracked separately as **NON-BLOCKING** for S2/S3/S4 source integration. During `controlled_beta` with QA open, a registered non-Math account may still have Core RPC access; do **not** advertise this beta as a selected-only mass rollout. That difference is known and must not be hidden.
- [P0-16B PR #493](https://github.com/jteshaboev1984-ops/iClub_APP/pull/493): trigger-mediated writer/security audit is still OPEN, not falsely marked complete. Preserve as an explicit owner risk/gate before any broader mass rollout or destructive clean-up, but **do not** start a project-wide security rewrite in this UI release.
- No automatic release, no migration replay, no `qa_open_all_core` deactivation, no mass toggle, no AI/mentor entitlement widening, no grade/self-mark restoration, no reimport of exposed answer keys, no Course/Tour/Practice/Certificate mutation.
- [Math canonical Issue #450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450) and [UX Issue #531](https://github.com/jteshaboev1984-ops/iClub_APP/issues/531) hold exact-SHA checkpoints, not just historical `LATEST` notes.

## 5. Precise remaining human approval

**Ready to request**: explicit owner GO for **UX-only controlled-beta deployment of #540** with no SQL/flag changes and 1-device smoke. This is **not** approval for `main`, production, changing mass rollout or data unless the owner clearly authorizes those specific actions.

Do not require a second general audit or another 56-test rerun when the SHA is unchanged. One targeted smoke after deployment is sufficient for this **scope**. For a mass launch, first obtain a separate owner decision and QA-override transition plan. For Stage6, retain #550 as an independent academic release.
