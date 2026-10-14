# iClub AI v2.1 — §50: Home / Profile / General Help trusted scope

**Date:** 2026-10-14  
**Implementation:** `qa/iclub-ai-layer-v21-20261012`; **QA ONLY, no production migrations or beta enablement**.

## Basis: real application, real schema, no student rows

Read-only inspection of the production baseline `app.js` and live Supabase table **definitions**, not learner content, confirmed:

- **Home**: `renderHome()` uses `loadProfile()` / browser-selected competitive and pinned-study subjects, plus computed per-subject Tour and Practice overlays. It has **no independently approved server next-actions planner or source**. A current Home selector cannot be treated as a signed next-step recommendation.
- **Profile**: `renderProfileMain()` shows Competitive and pinned Study subject counts, a Tour count, plus Best / Trend / Stability derived partly from **local Practice history**. The legacy client `getProfileCompletedToursCount()` counts distinct Tour IDs with statuses `submitted`, `time_expired` **and** `anti_cheat`, without requiring a finalized runtime row. These legacy UI semantics are **not identical** to the stronger new QA AI evidence and are not silently replaced.
- **Production tables** (metadata confirmed): `public.users(id,...)`, `public.subjects(id,subject_key,is_active)`, `public.user_subjects(user_id,subject_id,mode,is_pinned,...)`, `public.tour_attempts(id,user_id,tour_id,status,...)`, and `public.tour_session_runtime_v4(attempt_id,user_id,tour_id,finalized_at,...)`. No deployed app-wide Home next-actions, full-profile signed aggregate, or curated General Help navigation source has been established.

## Implemented with the existing single server lifecycle

1. `qa/sql_drafts/iclub_ai_scoped_context_v21_UNAPPLIED.sql` extends the **same** 90-second `private.iclub_ai_v21_scoped_contexts` table and current-screen revision row for three additional `surface_code` values: `home`, `profile` and `global`. No extra table, academic mutation, raw chat, or localStorage write.
2. `mint_iclub_ai_v21_app_view_context_service(p_user_id,p_view)` accepts only `home,profile,courses,ratings,about,support`. It requires an authenticated (Edge-bound) registered `public.users` ID, checks kill switch and protected assessment, locks the user current-screen row, applies the same rate limit and TTL, and returns only the opaque handle. The browser view is **a selector**, not proof of the actual pixels being displayed or a license to offer AI content.
3. Deno's **existing** `/context` endpoint now offers `{action:"mintAppView",view:"profile"}` (or another allowed view) and rejects forged `userId,subject,topic,plan,progress,score,sessionId,questionId,tourAttemptId`. `qa/edge_v21/supabase_services.ts` calls the single proposed RPC via the existing JWT-verified/service-role bridge. No new public route or AI Tutor.
4. `get_iclub_ai_v21_screen_evidence_service` now derives a **Profile activity snapshot** only while the current, owner-scoped Profile handle is live, unrevoked, and not protected. The only metrics are:
   - enrolled and active `competitive` subjects,
   - enrolled and active pinned `study` subjects,
   - distinct Tours with status `submitted/time_expired` **and** verified finalized `tour_session_runtime_v4`.
   Each is a **count**, not readiness, academic mastery, improvement, ranking, or recommendation. `aggregate_revision` derives from the current server screen revision; the existing internal proof hash includes the metric values so changed counts invalidate the delivered screen proof. No name, school, exam marks or raw answers are returned.
5. **Home next-actions and General Help navigation remain denied** at the source-proof level. Their server-minted screen handles are not source approval. Real next-actions require an independently governed cross-subject planner; General Help requires accurate, editorially approved and versioned UI instructions for the particular app view, plus locale-specific release. No permissive model fallback.

## Privacy / protection tests

The disposable `context` PostgreSQL suite validates own Profile counts, exact subject modes, finalized Tour provenance, no private name leakage, foreign learner denial, idempotent mint, old Profile proof invalidated by Home navigation, lack of Home/General sources, protected-assessment blackout, and handle revocation. Deno asserts allowlisted view selectors, JWT-bound user, service-role-only RPC and denial of account/plan/topic injection. Node regression checks app view scope restrictions. The existing 13 local disposable PostgreSQL suites, headless Chrome and Mathematics Exam Prep parity remain required.

## Limitations and next gate

**QA GREEN does not mean feature enabled.** The real current-screen may change in the browser without server notification; actual UI binding and auth state invalidation are still unapproved. Profile’s subset does **not** replace the real UI or its local activity metrics, especially the `anti_cheat` semantics and trend/best. There are still **no approved P6 public AI sources** for Home or General Help and no live RPC deployment. All model/billing/production integration stays **NO-GO**. Implement/approve a real Home action-plan source and versioned General Help instructions in separately isolated QA before a protected beta candidate can be considered.
