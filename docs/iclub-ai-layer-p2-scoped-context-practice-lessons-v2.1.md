# iClub AI Layer v2.1 — P2 Server-owned Screen Context (Practice + Lessons)
**Checkpoint date:** 2026-10-13 · **Scope:** technical implementation in QA branch only; **UNAPPLIED** to production.

## Division of responsibilities

This workstream owns only **AI infrastructure and safe automatic content consumption**. Subject-specific cards, questions, answer keys, approved academic explanations and their editorial QA are developed in the **separate content workflow**. A verified screen context is **not** editorial content approval, not subscription entitlement, and not permission to generate/charge.

The same backend context contract works across active Biology, Chemistry, Economics, Informatics and other properly enrolled subjects. Mathematics Exam Prep remains independently protected and does not use this new context handler.

## Verified actual database foundation (read-only inspection)

- `public.subjects(id,subject_key,is_active)`
- `public.user_subjects(user_id,subject_id)`
- `public.lessons(id,subject_id,title,topic,order_no)`
- `public.practice_sessions_v4(id,user_id,subject_id,status,finalized_at,question_ids)`
- `public.practice_session_answers_v4(session_id,question_id,...)`
- Existing private `iclub_ai_has_active_protected_assessment_v1(user_id)` and `iclub_global_ai_runtime_config`.

No actual user rows, answers, scores or progress were read. The inspection queried **schema metadata only**.

## New purely technical artifacts

1. `qa/sql_drafts/iclub_ai_scoped_context_v21_UNAPPLIED.sql`: local-scratch-only private tables for a single current AI screen and short-lived opaque UUID handles, and **four service-role-only RPCs**:
   - `mint_iclub_ai_v21_practice_context_service(user,session,question)`: proves the caller's finalized owned Practice session, answered exact question, active subject and enrollment; it does not read the answer text. Source/topic identity comes from the database, not HTTP input.
   - `mint_iclub_ai_v21_lesson_context_service(user,lesson)`: checks a real `lessons` row with an active enrolled subject; the lesson text or readiness need not exist yet.
   - `get_iclub_ai_v21_scoped_context_service(user,handle)`: resolves only owner-bound, current, non-revoked, non-expired handles; rereads the current live Practice/Lesson facts plus protected-exam guard. The returned subject, screen, feature and topic are **server-derived**.
   - `revoke_iclub_ai_v21_scoped_context_service(user,handle)`: closes the **currently active** screen only, increments revision; an old tab cannot revoke a newer screen.
2. `qa/edge_v21/context_core.ts`: small validated Deno HTTP context endpoint. The client may supply **only a Practice session+question ID** or **one Lesson ID**, plus its Auth token. Neither subject, topic, rights, quota, progress, source, readiness nor arbitrary user ID are accepted. Logout/navigation can revoke the previous handle.
3. `qa/edge_v21/index.ts`: separately routes QA `/context` and `/answer`, behind existing explicit QA boot lock and origin allowlist. No active `supabase/functions` entrypoint imports it.
4. `qa/edge_v21/supabase_services.ts`: server-owned Supabase Auth verified identity mapped to narrowly scoped mint/resolve/revoke RPC parameters.
5. `qa/sql_drafts/iclub_ai_scoped_context_local_pg.psql` and `qa/ai-layer-v21-scoped-context-sql.test.cjs`: synthetic roll-back-only live PostgreSQL tests plus static security checks. Native Deno HTTP and API-contract tests cover selector spoofing and malformed/foreign handles.

## Important behavioral and safety guarantees

- **Existing topic metadata suffices to create a context.** A Lesson may have zero approved AI cards: the context is still grounded in an existing authorized lesson; a *separate* publication/source/rights gate returns **«В разработке» / «Ishlab chiqilmoqda» / “In development”** without invoking a model or charging a unit.
- Canonical keys: Lesson `surface='lesson',feature='topic_explanation',topic='lesson_<lesson_id>'`; Practice `surface='practice',feature='answer_explanation',topic='question_<question_id>'`. Editorial publishing must attach to the exact canonical source identifier and locale; there is no generic-topic substitution for a specific missed question.
- **Only one new AI current screen per learner:** minting a different authorized screen advances the server navigation revision and invalidates the prior handle, including in another browser tab.
- Minting the **same active screen** twice is idempotent; the same handle is returned. Server-side cap: at most **30 newly created contexts per learner per rolling minute**, counting both Practice and Lessons. Handles expire **90 seconds** after creation. A reopened screen creates a newly verified handle.
- Every resolver call rechecks the owner, current revision, live subject enrollment/activity, finalized answer or existing lesson, global AI gate and protected assessment. Removing enrollment, deactivating a subject, unfinalizing Practice or starting a protected exam makes the existing handle unusable.
- Context tables hold only technical owner UUID, screen/resource IDs, revisions, times and canonical subject/topic keys. **No student answer, grades, question text, model reply, transcript, generated prompt, tutoring progress or certificate state.**
- The context RPCs are exposed **only to the service role**, not `anon`/`authenticated`. Browser calls a token-verified Edge adapter; the raw service role key never reaches the client.

## Remaining deployment blockers

The context draft remains **UNAPPLIED** in `qa/sql_drafts`. The preview candidate is **disabled by default**. No production SQL, Edge, migration, academic progress, source-card authoring, subscription or UI navigation has been changed.

- The existing app screens do **not yet** request/revoke this new handle. For navigation away from an AI-capable screen, the future UI must explicitly revoke or mint the next screen. Abrupt tab closure may leave the old handle usable for **up to 90 seconds**; do not falsely claim instant server-awareness of an unreported browser navigation.
- Real content ingestion requires the independent editorial publisher + topic/source hash/rights/locale proof; these RPCs have NOT been installed. An editor's unapproved card cannot activate AI.
- Rollout flags, protected Preview and effective subject-specific audience remain OFF until explicit architect authorization.
- Separate production-safe migration/RLS/GRANT review, expiry-retention policy for minimal technical records, Supabase Edge bundler verification, actual browser RU/UZ/EN and cross-worker reauthorization are required.
- No paid provider or production integration is run by these tests. Original Math Exam Prep is not migrated.
