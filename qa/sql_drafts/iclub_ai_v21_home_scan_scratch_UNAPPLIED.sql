-- iClub unified AI §82: actual-schema Home scan, scratch DB only.
-- Only existing owner records and server clock. No user data writes, no source publishing.
-- NEVER run against production; the runtime also enforces a scratch-only database name.
DO $scratch$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
 OR (inet_server_addr() IS NOT NULL
  AND inet_server_addr() NOT IN ('127.0.0.1'::inet,'::1'::inet)
  AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr AND
   current_setting('application_name')='iclub_ai_v21_local_scratch'))
 THEN RAISE EXCEPTION 'STOP: Home scanner may only exist in local disposable scratch';
 END IF;
END $scratch$;

-- The allowlist is per owner, subject and current mode in disposable scratch.
-- Its rows are synthetic and are NEVER accepted as real commercial proof.
-- This allowlist exists in SCRATCH tests, not in production. A future real
-- integration MUST replace it with approved owner-bound commercial entitlements.
CREATE TABLE IF NOT EXISTS private.iclub_ai_v21_home_synthetic_access(
 user_id uuid NOT NULL, subject_key text NOT NULL,
 intent text NOT NULL CHECK(intent IN ('study','competitive')),
 allowed boolean NOT NULL DEFAULT false,
 PRIMARY KEY(user_id,subject_key,intent)
);
REVOKE ALL ON private.iclub_ai_v21_home_synthetic_access FROM public,anon,authenticated;

CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_home_scan_scratch_service(
 p_user_id uuid,p_context_handle uuid
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $home$
DECLARE
 v_now timestamptz := now();
 v_tashkent_date date := (now() AT TIME ZONE 'Asia/Tashkent')::date;
 v_revision bigint;
 v_entries jsonb;
 v_count int;
BEGIN
 -- Runtime safety defense even if the SQL were accidentally copied elsewhere.
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
 OR p_user_id IS NULL OR p_context_handle IS NULL
 THEN RETURN jsonb_build_object('allowed',false); END IF;
 IF NOT EXISTS (
  SELECT 1 FROM private.iclub_ai_v21_home_synthetic_access a
  WHERE a.user_id=p_user_id AND a.allowed=true
 ) OR NOT EXISTS (
  SELECT 1 FROM private.iclub_global_ai_runtime_config g
  WHERE g.id=1 AND g.kill_switch=false AND g.gateway_enabled=true
 ) OR private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 THEN RETURN jsonb_build_object('allowed',false); END IF;
 -- Server-owned EXACT home handle: no browser-selected subject, action, date,
 -- progress tile or borrowed context accepted as proof.
 SELECT nav.revision INTO v_revision
 FROM private.iclub_ai_v21_current_screen nav
 JOIN private.iclub_ai_v21_scoped_contexts c
   ON c.context_handle=nav.current_handle
    AND c.user_id=nav.user_id AND c.context_revision=nav.revision
 WHERE nav.user_id=p_user_id AND nav.current_handle=p_context_handle
  AND c.context_handle=p_context_handle
  AND c.surface_code='home' AND c.app_view_code='home'
  AND c.feature_code='next_step' AND c.topic_key='next_actions'
  AND c.subject_key='general'
  AND c.revoked_at IS NULL AND c.expires_at>v_now
  AND public.get_iclub_ai_v21_scoped_context_service(
      p_user_id,p_context_handle::text)->>'allowed'='true';
 IF v_revision IS NULL THEN RETURN jsonb_build_object('allowed',false); END IF;

 -- Every enrolled active subject is enumerated. A returned candidate is
 -- evidence of an eligible action, NOT mastery and NOT an AI release.
 WITH eligible AS (
  SELECT DISTINCT subj.id,subj.subject_key,us.mode
  FROM public.user_subjects us
  JOIN public.subjects subj ON subj.id=us.subject_id AND subj.is_active=true
  JOIN private.iclub_ai_v21_home_synthetic_access a
   ON a.user_id=us.user_id AND a.subject_key=subj.subject_key
    AND a.intent=us.mode AND a.allowed=true
  WHERE us.user_id=p_user_id AND us.mode IN ('study','competitive')
 ),
 practice_candidates AS (
  SELECT DISTINCT ON (e.id) 1 AS priority,'review_finalized_practice'::text AS action_code,
   e.subject_key,s.id::bigint AS evidence_id,extract(epoch FROM s.finalized_at)::bigint AS evidence_revision
  FROM eligible e
  JOIN public.practice_sessions_v4 s ON s.subject_id=e.id
    AND s.user_id=p_user_id AND s.status='finalized' AND s.finalized_at IS NOT NULL
  JOIN public.practice_session_answers_v4 a ON a.session_id=s.id
    AND a.question_id=ANY(s.question_ids) AND a.is_correct=false AND a.answered_at IS NOT NULL
  WHERE e.mode='study'
  ORDER BY e.id,s.finalized_at DESC,s.id DESC
 ),
 archive_candidates AS (
  SELECT DISTINCT ON (e.id) 2 AS priority,'review_open_tour_archive'::text AS action_code,
   e.subject_key,ta.id::bigint AS evidence_id,
   extract(epoch FROM rt.finalized_at)::bigint AS evidence_revision
  FROM eligible e
  JOIN public.tours t ON t.subject_id=e.id
   AND t.end_date IS NOT NULL AND v_tashkent_date>t.end_date
  JOIN public.tour_attempts ta ON ta.tour_id=t.id
   AND ta.user_id=p_user_id AND ta.status IN ('submitted','time_expired')
  JOIN public.tour_session_runtime_v4 rt ON rt.attempt_id=ta.id
   AND rt.user_id=ta.user_id AND rt.tour_id=ta.tour_id AND rt.finalized_at IS NOT NULL
  WHERE e.mode='competitive'
  ORDER BY e.id,rt.finalized_at DESC,ta.id DESC
 ),
 continue_candidates AS (
  SELECT 3 AS priority,'continue_enrolled_subject'::text AS action_code,
   e.subject_key,e.id::bigint AS evidence_id,v_revision::bigint AS evidence_revision
  FROM eligible e WHERE e.mode='study'
 ),
 all_found AS (
  SELECT * FROM practice_candidates
  UNION ALL SELECT * FROM archive_candidates
  UNION ALL SELECT * FROM continue_candidates
 ),
 top_type AS (
  SELECT * FROM all_found
  WHERE priority=(SELECT min(priority) FROM all_found)
 ),
 total AS (SELECT count(*)::int AS n FROM top_type)
 SELECT jsonb_agg(jsonb_build_object(
    'actionCode',q.action_code,'subjectKey',q.subject_key,
    'evidenceId',q.evidence_id,'evidenceRevision',greatest(1,q.evidence_revision)
 ) ORDER BY q.subject_key,q.evidence_id),max(q.n)
 INTO v_entries,v_count
 FROM (
  SELECT t.*,n.n FROM top_type t CROSS JOIN total n
 ) q;
 -- No implicit selection of a random subject if candidate set is too large.
 IF v_count IS NULL OR v_count=0 OR v_count>3
 THEN RETURN jsonb_build_object('allowed',false,'reason','no_complete_safe_choice');END IF;
 RETURN jsonb_build_object('allowed',true,'review_only',true,
  'owner_id',p_user_id,'context_handle',p_context_handle,
  'screen_revision',v_revision,
  'policy_version','home_next_actions_20261014_v1',
  'complete_scan',true,
  'source_publication',false,'rights_approved',false,
  'candidates',v_entries);
END $home$;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_home_scan_scratch_service(
 uuid,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_home_scan_scratch_service(
 uuid,uuid) TO service_role;
