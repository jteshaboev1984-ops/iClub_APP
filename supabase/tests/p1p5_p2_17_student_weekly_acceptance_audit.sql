-- D10 supersedes the earlier positive heuristic-acceptance audit.
-- Exact isolated two-user PG17 stack only. Real 81-skill personal study-time
-- ranges are NOT approved, so neither Accept nor Keep may alter state.
\set ON_ERROR_STOP on
DO $$
DECLARE
  uid uuid:='11111111-1111-4111-8111-111111111191';
  p private.exam_prep_exam_profiles%ROWTYPE;
  latest private.exam_prep_exam_map_revisions%ROWTYPE;
BEGIN
  IF current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM public.users)<>2 THEN
    RAISE EXCEPTION 'D10 REFUSED: not isolated two-user PG17 fixture';
  END IF;
  SELECT * INTO p FROM private.exam_prep_exam_profiles WHERE user_id=uid;
  IF p.user_id IS NULL OR p.mathematics_hours_budget<>6
    OR p.total_student_hours_available<>12 THEN
    RAISE EXCEPTION 'D10 profile hours changed by unapproved recommendation';
  END IF;
  SELECT * INTO latest FROM private.exam_prep_exam_map_revisions
   WHERE user_id=uid ORDER BY profile_revision DESC LIMIT 1;
  IF latest.user_id IS NULL OR latest.profile_revision<>p.profile_revision THEN
    RAISE EXCEPTION 'D10 profile revision changed by refused advice';
  END IF;
  IF EXISTS (SELECT 1 FROM private.exam_prep_weekly_time_decisions_v1
    WHERE user_id=uid) THEN
    RAISE EXCEPTION 'D10 an unapproved Keep decision was persisted';
  END IF;
  IF position('awaiting_independent_81_skill_time_review' IN
    pg_get_functiondef(
      'public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2()'::regprocedure))=0 THEN
    RAISE EXCEPTION 'D10 missing server-side academic time firewall';
  END IF;
  IF position('PT409' IN
    pg_get_functiondef(
      'public.accept_my_exam_prep_timeline_weekly_target_safe_v1(numeric,integer,numeric)'::regprocedure))=0
    OR position('errcode=''40001''' IN
    pg_get_functiondef(
      'public.accept_my_exam_prep_timeline_weekly_target_safe_v1(numeric,integer,numeric)'::regprocedure))>0 THEN
    RAISE EXCEPTION 'D10 stale profile must keep PT409 conflict semantics';
  END IF;
  IF has_function_privilege('anon',
    'public.accept_my_exam_prep_timeline_weekly_target_safe_v1(numeric,integer,numeric)','EXECUTE')
    OR has_function_privilege('anon',
    'public.keep_my_exam_prep_timeline_weekly_time_safe_v1(numeric,integer,numeric,text)','EXECUTE') THEN
    RAISE EXCEPTION 'D10 anonymous user obtained time-decision write access';
  END IF;
  RAISE NOTICE 'D10 PASS: authentic owner profile unchanged; no unapproved hour acceptance or Keep receipt';
END $$;
