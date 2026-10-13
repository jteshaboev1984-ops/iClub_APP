# iClub AI v2.1 — §40 Protected Preview admission and real app screen mapping

**Decision: NO-GO for an actual Preview deployment before separate architect approval.** This assessment is completed in the existing QA branch and does not create environments.

## Evidence from original app

- app.js renderLessons fetches lessons(id,title,topic,order_no); selecting a row sets state.courses.lessonId and opens the video screen. This internal state value is not yet supplied as a validated V2 screen selector.
- app.js syncPracticeAiDomContext exposes the old practice attempt identifier from practiceLastAttempt.db.attemptId. New V2 server authority instead requires an owned finalized practice_sessions_v4.id and an exact answered question_id. These different identifiers MUST NEVER be assumed interchangeable.
- global-ai-ui.js continues using the legacy global-ai V1 function; V2 requires the isolated /context and /answer routes. No silent production cutover.
- Active ordinary Practice Quiz is now completely blacked out in the dormant QA shell; its stale asynchronous AI reply is discarded even after navigating to results.

## Completed automated gates

- A read-only preflight audits index.html, app.js, current shell, Deno context and unapplied SQL. It emits NO_GO and concrete blockers. A green test means a truthful NO-GO report, not permission to launch.
- Chromium synthetic UI tests cover Practice Quiz blackout, return to finalized-result UI, stale answer, protected Exam Prep, account switch, layouts 320/390/desktop.

## Required before real Preview

Separate architect approval, isolated non-production database and auth realm, read/write fencing, real verified server selector for Lesson and finalized Practice, protected branch-specific Vercel target, reviewed production-safe migration of any required v2 RPC, and safe QA-only UI routing. Actual app browser acceptance and owner-approved AI icon are still outstanding.

Do not test with real students, their stored browser data or the production Supabase service role. No new branch, PR, production migration, Preview or paid model was created.