-- Economics native MCQ: durable own attempt history / resumable and finalized sessions.
-- No source or learner data rewrite; additive read-only authenticated RPC.
BEGIN;
CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_history_v1(
 p_paper_code text DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid(); v_rows jsonb;
BEGIN
 IF v_user IS NULL OR (p_paper_code IS NOT NULL AND p_paper_code NOT IN('P1','P3')) THEN
   RETURN jsonb_build_object('ok',false,'code','invalid_request');
 END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object(
   'session_id',s.id,
   'paper_code',s.paper_code,
   'status',s.status,
   'started_at',s.started_at,
   'deadline_at',s.deadline_at,
   'finalized_at',s.finalized_at,
   'score',CASE WHEN s.status='finalized' THEN s.score ELSE NULL END,
   'total_items',30,
   'answered',(SELECT count(*) FROM jsonb_object_keys(s.responses))
 ) ORDER BY s.started_at DESC),'[]'::jsonb)
 INTO v_rows
 FROM (SELECT * FROM private.iclub_exam_native_mcq_attempts_v1
   WHERE user_id=v_user AND program_key='economics_9708'
   AND version_key='economics_2026_2028_v1'
   AND (p_paper_code IS NULL OR paper_code=p_paper_code)
   ORDER BY started_at DESC LIMIT 20) s;
 RETURN jsonb_build_object('ok',true,'sessions',v_rows);
END;
$f$;
REVOKE ALL ON FUNCTION public.iclub_exam_native_mcq_history_v1(text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_mcq_history_v1(text) TO authenticated;
DO $assert$
BEGIN
 IF has_function_privilege('anon','public.iclub_exam_native_mcq_history_v1(text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.iclub_exam_native_mcq_history_v1(text)','EXECUTE')
 OR has_table_privilege('authenticated','private.iclub_exam_native_mcq_attempts_v1','SELECT')
 THEN RAISE EXCEPTION 'History permission invariant failed'; END IF;
END $assert$;
COMMIT;
