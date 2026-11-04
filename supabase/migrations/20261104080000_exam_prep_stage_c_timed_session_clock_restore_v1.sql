-- Stage C: Restore learner's minimal Timed/Paper countdown projection.
-- Later full getter rewrites dropped the 20260904 timing_contract key.
-- Append only to the existing owner-gated getter response; preserve every
-- other item, security, grade, answer and feedback rule byte-for-byte.
-- No table DML or changes to any real or synthetic academic evidence.
BEGIN;
DO $restore$
DECLARE
  v_sig regprocedure := to_regprocedure('public.get_exam_prep_session_safe_v1(uuid,text)');
  v_src text;
  v_anchor text := '''finalized_at'',v_s.finalized_at,';
  v_add text;
BEGIN
  IF v_sig IS NULL THEN
    RAISE EXCEPTION 'timed_clock_restore: getter is not installed';
  END IF;
  v_src := pg_get_functiondef(v_sig);
  IF position('''timing_contract'',' in v_src)>0 THEN
    IF position('''server_now''' in v_src)=0
      OR position('v_s.timing_contract->>''deadline_at''' in v_src)=0
      OR position('''items'',v_items' in v_src)=0
    THEN RAISE EXCEPTION 'timed_clock_restore: preexisting projection has drifted'; END IF;
    RAISE NOTICE 'timed_clock_restore: already installed';
    RETURN;
  END IF;
  IF (length(v_src)-length(replace(v_src,v_anchor,'')))<>length(v_anchor)
     OR position('''items'',v_items' in v_src)=0
     OR position('private.exam_prep_require_core_access_v1()' in v_src)=0
     OR position('where id=p_session_id and user_id=v_uid' in lower(v_src))=0
  THEN RAISE EXCEPTION 'timed_clock_restore: current source mismatch, abort without DDL'; END IF;
  v_add:=E'\n    ''timing_contract'',case when v_s.session_type in (''timed'',''paper'') then '
    || 'jsonb_build_object('
    || '''deadline_at'',v_s.timing_contract->>''deadline_at'','
    || '''time_limit_sec'',v_s.timing_contract->''time_limit_sec'','
    || '''strict_timing'',v_s.timing_contract->''strict_timing'','
    || '''attempt_kind'',v_s.timing_contract->>''attempt_kind'','
    || '''server_now'',now()) else null end,';
  EXECUTE replace(v_src,v_anchor,v_anchor||v_add);
END;
$restore$;

DO $post$
DECLARE v_src text;
BEGIN
  v_src:=pg_get_functiondef('public.get_exam_prep_session_safe_v1(uuid,text)'::regprocedure);
  IF position('''timing_contract'',' in v_src)=0
     OR position('''server_now''' in v_src)=0
     OR position('''deadline_at''' in v_src)=0
     OR position('''time_limit_sec''' in v_src)=0
     OR position('''strict_timing''' in v_src)=0
     OR position('''attempt_kind''' in v_src)=0
     OR has_function_privilege('anon','public.get_exam_prep_session_safe_v1(uuid,text)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.get_exam_prep_session_safe_v1(uuid,text)','EXECUTE')
  THEN RAISE EXCEPTION 'timed_clock_restore: postcheck failed'; END IF;
END;
$post$;
COMMIT;
