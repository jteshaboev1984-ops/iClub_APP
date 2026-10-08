-- Mathematics Practice v2 — close obsolete direct Practice answer/oracle RPCs
-- Branch-only migration. Do not apply to production until the Practice v2 release gate is approved.
--
-- Current learner flow uses the session-bound v4 RPCs:
--   start_practice_session_auto_safe_v4
--   get_practice_session_resume_safe_v4
--   submit_practice_session_answer_safe_v4
--   finalize_practice_session_safe_v4
--   get_practice_review_full_safe_v4
--
-- The legacy functions below are not used by the current frontend and are too broad
-- for direct learner execution:
-- - submit_practice_attempt can construct an attempt from arbitrary active question IDs.
-- - submit_practice_answer_safe can evaluate arbitrary active questions in an owned legacy attempt.
-- - get_practice_review_safe_v4 lacks the newer protected-question guard.
--
-- Keep postgres/service_role access so trusted server-side compatibility paths can remain intact.

revoke execute on function public.submit_practice_attempt(bigint, integer, numeric, integer, jsonb)
from authenticated;

revoke execute on function public.submit_practice_answer_safe(bigint, bigint, text, integer, integer)
from authenticated;

revoke execute on function public.get_practice_review_safe_v4(bigint)
from authenticated;
