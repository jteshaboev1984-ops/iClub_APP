-- Fix history JSONB answer count before opening any beta.
CREATE OR REPLACE FUNCTION public.iclub_exam_chemistry_p1_history_v1()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid();v_rows jsonb;
BEGIN
 IF v_user IS NULL THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_p1_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT jsonb_agg(jsonb_build_object(
 'session_id',z.id,'paper_code','P1','status',z.status,
 'started_at',z.started_at,'deadline_at',z.deadline_at,
 'score',CASE WHEN z.status='finalized' THEN z.score ELSE NULL END,
 'answered',(SELECT count(*) FROM jsonb_object_keys(z.responses))) ORDER BY z.started_at DESC)
 INTO v_rows
 FROM (SELECT id,status,started_at,deadline_at,score,responses
 FROM private.iclub_exam_chemistry_p1_live_attempts_v1
 WHERE user_id=v_user ORDER BY started_at DESC LIMIT 30) z;
 RETURN jsonb_build_object('ok',true,'sessions',coalesce(v_rows,'[]'::jsonb));
END $function$;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_p1_history_v1() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_p1_history_v1() TO authenticated;
DO $verify$ BEGIN
 IF has_function_privilege('anon','public.iclub_exam_chemistry_p1_history_v1()','EXECUTE')
 THEN RAISE EXCEPTION 'Chemistry history anon privilege leak'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_p1_live_attempts_v1)<>0
 THEN RAISE EXCEPTION 'Chemistry beta unexpectedly started'; END IF;
END $verify$;