# iClub AI Layer v2.1 — §82–§86 server Home, source packet, isolated Preview and CI

**Date:** 2026-10-14. **Scope:** QA-only. **Current release verdict:** NO-GO; preserve production and learner evidence.

## §82 Owner-bound actual-table Home scan — implemented only as scratch SQL

`qa/sql_drafts/iclub_ai_v21_home_scan_scratch_UNAPPLIED.sql` is a read-only candidate query over the source-confirmed `subjects`, `user_subjects`, `practice_sessions_v4`, `practice_session_answers_v4`, `tours`, `tour_attempts`, `tour_session_runtime_v4` shapes. It checks the exact current 90-second Home handle, user, screen revision, protected-exam blackout, local scratch global kill switch, scratch-only synthetic authorization, and server-local Tashkent date. It considers only finalized Practice with a checked incorrect answer; Tour archive only for finalized permitted attempts with a strictly ended Tour; then continue an active enrolled subject. It does not include answers, grades, raw chat, browser percentages or device time. If no choice or more than three equal-top choices remain, fail closed.

**IMPORTANT:** This is not a deployed or publication-ready planner. It is guarded both at SQL installation and RPC invocation against any non-`iclub_ai_v21_scratch_*` database, and its allowlist is explicitly **synthetic**. Current SQL is not authorized for real deployment because real commercial entitlement and coherent signed full enumeration, release, and atomic source/version proofs are still needed.

## §83 Scratch PostgreSQL owner/stale/lock tests

`qa/sql_drafts/iclub_ai_v21_home_scan_local_pg.psql` builds only virgin scratch synthetic schemas, checks wrong owner/handle, ended versus not-yet-ended Tour, anti-cheat, finalized Practice, withdrawn entitlement, active assessment, and revoked Home handle, and finishes in `ROLLBACK`. The offline scratch runner now supports the fourteenth `home` suite. **Actual PostgreSQL execution not confirmed** here: the execution environment does not have a usable local PostgreSQL binary/server. GitHub Actions must run and report GREEN before this contract can be treated as proven.

## §84 Source governance: approved product copy is not a published source

`qa/ai-layer-v21-p6-approved-copy-bundle.cjs` pins the exact 18 product-approved RU/UZ/EN texts to the previously approved Git blob `ab94d7ca03bbdf521acc95dedafd0dba43c45f7e`. The returned preview-only pack explicitly has `editorialRightsApproved:false`, `globalAiSourcePublished:false`, `providerAllowed:false`. A changed character fails closed. Actual publication is **not** performed: distinct review of rights, editorial provenance, source version/hash, rollout, and owner-authorized isolated DB is missing.

## §85 Protected synthetic Vercel Preview

A **separate one-file demonstration** was created at Vercel deployment `dpl_BswWrQATQYEL86vEAxaECgQhs27r` (status `READY`), URL: `https://i-club-8ikby7smn-jasurbeks-projects-c5451f97.vercel.app`. Deployment target is **null** (Preview), aliases **empty**; Vercel's existing SSO protection applies to noncustom-domain deployments. The only deployed source is `qa/preview_v21/index.html`, not the main app. Its CSP sets `default-src 'none'; connect-src 'none'`; it has no Supabase, real auth, student records, live AI requests, writes, localStorage or cookies. The UI exposes the product-approved 18 directions and order-of-operations explanation as a **demo**, with explicit “personal recommendations unavailable” messaging. This does not prove real backend/Edge integration.

Vercel deployment metadata and one-file inventory were verified. Outside browser opening could not verify content because the URL was not accessible to an unauthenticated client (likely SSO). No claims about a successful signed-in browser walk-through are made.

## §86 CI status / explicit stop line

QA workflow `.github/workflows/iclub-ai-v21-offline-qa.yml` now tracks this SQL, its local scratch suite, immutable copy pack, Preview source and associated tests. It has Node, Chromium, Deno, 14 scratch PostgreSQL suites, multiworker races and the original frozen Exam Prep isolation checks. **A real full workflow GREEN has not been retrieved.** Connector workflow lookup is scoped to pull-request runs and reported no matching PR run; combined statuses are absent. This cannot be reinterpreted as pass.

### Still missing for real release

- Replace synthetic authorization with real active per-subject and commercial enrollment entitlement in an isolated owner-scoped server service, independently compare all three categories and implement atomic signed plan version and per-locale source checks. Preserve all closed Tour and finished Practice constraints.
- Authorized isolated Supabase environment and source governance, with human rights/independent editorial verification; no permission to write real Supabase.
- Separate, **actual** full Preview running the integrated UI/Edge backend and a signed-in protected end-to-end browser QA before any beta candidate.
- Obtain real GitHub Actions run URL/logs showing complete Node/Deno/14 scratch PostgreSQL/Chromium success, then verify frozen Math Tutor parity and full protected-file diff.
- Real-user beta, production promotion, third-party provider money and payments require fresh explicit architect GO.

**This report does not authorize any main, production, live Supabase, student-progress, localStorage, Mathematics Tutor, billing or production-domain changes.** Global AI remains OFF / NO-GO.
