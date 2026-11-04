-- Read-only Stage C guard on the disposable PG17 migration stack.
-- Actual private payload, foreign-owner and anonymous rules are checked
-- over signed local PostgREST by the existing P1/P5 Stage 3 E2E.
\set ON_ERROR_STOP on
DO $guard$
DECLARE v_src text;
BEGIN
  v_src:=pg_get_functiondef('public.get_exam_prep_session_safe_v1(uuid,text)'::regprocedure);
  IF position('''timing_contract'',' in v_src)=0
    OR position('''server_now''' in v_src)=0
    OR position('''deadline_at''' in v_src)=0
    OR position('''time_limit_sec''' in v_src)=0
    OR position('''strict_timing''' in v_src)=0
    OR position('''attempt_kind''' in v_src)=0
    OR position('v_s.session_type in (''timed'',''paper'')' in v_src)=0
    OR position('private.exam_prep_require_core_access_v1()' in v_src)=0
    OR position('where id=p_session_id and user_id=v_uid' in lower(v_src))=0
    OR position('then v_s.timing_contract else' in v_src)>0
    OR position('''comparability_key''' in v_src)>0
    OR position('''marks_available''' in v_src)>0
    OR has_function_privilege('anon','public.get_exam_prep_session_safe_v1(uuid,text)','EXECUTE')
    OR NOT has_function_privilege('authenticated','public.get_exam_prep_session_safe_v1(uuid,text)','EXECUTE')
  THEN RAISE EXCEPTION 'Stage C getter clock projection or security broken'; END IF;
  RAISE NOTICE 'PASS Stage C: Timed/Paper five-field owner-only countdown; no sensitive fields';
END;
$guard$;
