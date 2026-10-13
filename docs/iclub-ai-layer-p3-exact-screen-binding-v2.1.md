# §41 — V2 QA-only exact-screen admission bridge

Scope: same existing QA branch, original iClub app screens untouched, no migrations, provider, Preview, PR or real student context. The new binder is NOT loaded by index.html; its browser export is enabled only by the synthetic QA harness flag.

The input selectors are never authorization. Supabase Edge separately verifies owner, finalized practice_sessions_v4 record, answered question, enrollment, release, rights and current protected-assessment status.

Admission is restricted to one visible active Lessons video screen with the explicit integer data-iclub-ai-v21-lesson-id, or one active Practice review screen with data-iclub-ai-v21-session-id and exactly one explicitly selected data-iclub-ai-v21-question-id. An old data-practice-ai-attempt-id alone is always denied. No visible subject, score, user name, lesson title, progress, cookie or localStorage value is used.

Opening another screen revokes the old client context before minting the new one; a stale mint/answer after navigation or logout cannot return; active Quiz, Tours and Exam Prep host deny access. Prepared/status response may only be returned when the binder's current screen key still matches. There is no background retry of a potentially billed request.

Node regression covers exact selectors, legacy mismatch, protected tests, stale async requests, account change and backend disabled behavior. Chromium checks the same contract against synthetic DOM on four device sizes while loading the original global-ai-ui.js and CSS without modifying app.js/index.html.

Remaining NO_GO: actual app lacks these explicitly reviewed markers, true V4 Practice session/answered question binding is unverified, QA-only client routing is not imported, protected isolated Supabase Preview is not authorized. This bridge is a tested compatibility component, NOT a deployed AI feature.