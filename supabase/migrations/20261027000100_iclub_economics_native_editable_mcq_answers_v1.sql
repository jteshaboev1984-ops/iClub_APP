-- Economics live Paper UX: save on option selection, allow revisions only before finish.
-- Existing completed attempts, scores, snapshots, progress are untouched.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='60s';
CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_answer_v1(
  p_session_id uuid,p_item_order integer,p_choice integer
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE
  v_user uuid:=auth.uid();
  v private.iclub_exam_native_mcq_attempts_v1%ROWTYPE;
  v_key text;
  v_prior jsonb;
  v_same boolean;
BEGIN
  IF v_user IS NULL OR p_session_id IS NULL
     OR p_item_order NOT BETWEEN 1 AND 30 OR p_choice NOT BETWEEN 0 AND 3 THEN
    RETURN jsonb_build_object('ok',false,'code','invalid_request');
  END IF;
  SELECT * INTO v FROM private.iclub_exam_native_mcq_attempts_v1
    WHERE id=p_session_id AND user_id=v_user FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
  -- No modification of completed or timed-out attempts, including duplicate requests.
  IF v.status<>'active' OR clock_timestamp()>=v.deadline_at THEN
    RETURN jsonb_build_object('ok',false,'code','attempt_closed_or_expired');
  END IF;
  v_key:=p_item_order::text;
  v_prior:=v.responses->v_key;
  v_same:=v_prior IS NOT NULL AND (v_prior->>'choice')::integer=p_choice;
  IF v_same THEN
    RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',true,
      'selected_index',p_choice);
  END IF;
  -- Preserve the original submission timestamp while recording the last choice.
  UPDATE private.iclub_exam_native_mcq_attempts_v1
    SET responses=jsonb_set(responses,ARRAY[v_key],
      jsonb_build_object('choice',p_choice,'at',clock_timestamp(),
        'first_at',coalesce(v_prior->'first_at',v_prior->'at',
          to_jsonb(clock_timestamp()))),true)
    WHERE id=v.id AND user_id=v_user AND status='active';
  RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',false,
    'revised',v_prior IS NOT NULL,'selected_index',p_choice);
END;
$f$;
REVOKE ALL ON FUNCTION public.iclub_exam_native_mcq_answer_v1(uuid,integer,integer)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_mcq_answer_v1(uuid,integer,integer)
 TO authenticated;
DO $verify$
DECLARE v_count int;
BEGIN
 IF has_function_privilege('anon','public.iclub_exam_native_mcq_answer_v1(uuid,integer,integer)','EXECUTE')
 OR has_table_privilege('authenticated','private.iclub_exam_native_mcq_attempts_v1','UPDATE')
 THEN RAISE EXCEPTION 'Answer access boundary changed'; END IF;
 SELECT count(*) INTO v_count FROM private.iclub_exam_native_mcq_attempts_v1
   WHERE status='finalized';
 IF v_count<1 THEN RAISE EXCEPTION 'Existing finalized attempt missing before safe revision'; END IF;
 IF NOT EXISTS (SELECT 1 FROM private.iclub_exam_core_programs_v1
   WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
   AND launch_enabled=true AND status='published')
 THEN RAISE EXCEPTION 'Economics beta launch changed'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND status='active')<>1
 THEN RAISE EXCEPTION 'Mathematics active version changed'; END IF;
END;
$verify$;
COMMIT;
