# §42 QA evidence publisher: finalized Practice source → exact AI selector

This candidate remains unimported by app.js and index.html. It does NOT enable AI or change production student progress, answers, Supabase or localStorage.

Read-only inspection of app.js confirms that successful V4 finalize uses quiz.safeSessionId, returns finalResult.attempt_id (a DIFFERENT legacy attempt identifier), and later fetches safeApi.review(dbAttemptId) returning server-reviewed question_id rows. Original Practice review DOM carries data-practice-ai-question-id. Never send attemptId as context sessionId.

QA helper accepts a Practice context only when safe V4 finalization is completed, a valid server-returned attemptId exists, and unique valid question IDs are present. It waits for verified review rows, matches all rendered question IDs exactly and rejects missing, duplicate, extra or stale records. Only then can a single selected row expose data-iclub-ai-v21-session-id + question-id for the v2 screen binder; the Edge must separately verify ownership, finalized status, answer, release and protected state.

Any navigation, different result, logout or incomplete review MUST invoke clear(), advancing epoch and clearing DOM. Delayed review callbacks carry a token tied to the matching finalization. This stage remains opt-in QA-only with no mutations of app.js; linking lifecycle calls to the original app requires a distinct reviewed Preview-only source overlay and an owner-authorized isolated environment.

Lessons remain intentionally DENIED: renderVideo() changes state.courses.lessonId to the first lesson of the subject regardless of the selected lesson, and Telegram video is a SUBJECT-level resource. Do not attach a lesson-specific AI selector until the product screen genuinely identifies the lesson.

All fixtures are synthetic and contain no academic answers, messages, model calls, secrets or real student data.