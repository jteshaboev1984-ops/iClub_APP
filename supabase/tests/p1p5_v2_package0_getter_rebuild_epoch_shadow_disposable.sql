-- Issue #450 P0-20: three apparent read-only GET RPCs that rebuild learner state.
-- ABSOLUTELY DISPOSABLE PostgreSQL 17 ONLY; NOT A PRODUCTION MIGRATION.
-- Requires full real-migration disposable stack and prior P0-16/P0-17 epoch fixture.
-- Shadow-patch three REAL existing GETTER-WITH-SIDE-EFFECTS RPCs only.
-- Never rewrite beta consent, Chemistry, mentor, or protected legacy paths.
\set ON_ERROR_STOP on
DO $p020$
DECLARE
 v_name text;
 v_oid oid;
 v_source text;
 v_anchor text;
 v_new text;
 v_changed integer:=0;
 v_signature text;
BEGIN
 IF current_database()<>'postgres'
 OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR current_setting('server_version_num')::int<170000
 OR (SELECT count(*) FROM public.users)<>2
 OR (SELECT count(*) FROM auth.users)<>2
 OR to_regclass('private.p0_16_academic_epoch_gate') IS NULL
 OR (SELECT epoch FROM private.p0_16_academic_epoch_gate
     WHERE program_key='math_as_p1_p5')<>2
 OR (SELECT paused FROM private.p0_16_academic_epoch_gate
     WHERE program_key='math_as_p1_p5') IS DISTINCT FROM false
 OR (SELECT epoch FROM private.p0_16_academic_epoch_gate
     WHERE program_key='economics_as')<>1
 OR (SELECT count(*) FROM private.exam_prep_sessions WHERE p0_16_issued_epoch=1)<2
 THEN RAISE EXCEPTION 'P0-20 refuses non-disposable/unfrozen schema or missing old sessions'; END IF;

 FOR v_name IN
 SELECT unnest(ARRAY[
   'get_exam_prep_diagnostic_progress_safe_v1',
   'get_exam_prep_placement_safe_v1',
   'get_exam_prep_state_safe_v1'
 ])
 LOOP
   v_signature:='public.'||v_name||'(text)';
   v_oid:=to_regprocedure(v_signature);
   IF v_oid IS NULL
    OR NOT has_function_privilege('authenticated',v_oid,'EXECUTE')
    OR NOT EXISTS(SELECT 1 FROM pg_proc
       WHERE oid=v_oid AND prosecdef AND provolatile='v')
   THEN RAISE EXCEPTION 'P0-20 refuses altered getter privilege/volatility: %',v_signature; END IF;
   v_source:=pg_get_functiondef(v_oid);
   IF v_source LIKE '%p0_16_require_current_epoch_v1%'
    OR v_source NOT ILIKE '%SECURITY DEFINER%'
   THEN RAISE EXCEPTION 'P0-20 refuses prepatched/missing-security getter %',v_name; END IF;
   v_anchor:=CASE WHEN v_name='get_exam_prep_state_safe_v1'
     THEN 'v_uid := auth.uid();'
     ELSE 'v_uid:=private.exam_prep_require_core_access_v1();' END;
   IF (length(v_source)-length(replace(v_source,v_anchor,'')))<>length(v_anchor)
   THEN RAISE EXCEPTION 'P0-20 refuses getter source-anchor drift %',v_name; END IF;
   IF v_name='get_exam_prep_state_safe_v1' AND
     v_source NOT LIKE '%private.rebuild_exam_prep_state_v1%'
   THEN RAISE EXCEPTION 'P0-20 lost state rebuild helper %',v_name; END IF;
   IF v_name<>'get_exam_prep_state_safe_v1' AND
     v_source NOT LIKE '%private.rebuild_exam_prep_placement_v1%'
   THEN RAISE EXCEPTION 'P0-20 lost placement rebuild helper %',v_name; END IF;

   -- The genuine signed role is verified inside P0-16's server-owned fence.
   -- Epoch FOR SHARE and cutoff validate BEFORE any rebuild helper can write.
   v_new:=replace(v_source,v_anchor,
      v_anchor||E'\n  PERFORM private.p0_16_require_current_epoch_v1(v_uid,NULL::uuid);');
   EXECUTE v_new;
   v_changed:=v_changed+1;
 END LOOP;

 IF v_changed<>3 OR (
  SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
   AND p.proname=ANY(ARRAY[
      'get_exam_prep_diagnostic_progress_safe_v1',
      'get_exam_prep_placement_safe_v1',
      'get_exam_prep_state_safe_v1'
   ])
   AND pg_get_functiondef(p.oid) LIKE '%private.p0_16_require_current_epoch_v1%'
 )<>3
 THEN RAISE EXCEPTION 'P0-20 three getters not exactly shadow-fenced'; END IF;
 IF EXISTS(
  SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
   AND p.proname IN(
     'grant_my_exam_prep_beta_consent_v1',
     'grant_my_exam_prep_chemistry_consent_v1',
     'revoke_my_exam_prep_chemistry_consent_v1'
   )
   AND pg_get_functiondef(p.oid) LIKE '%private.p0_16_require_current_epoch_v1%'
 )
 THEN RAISE EXCEPTION 'P0-20 touched out-of-scope beta or Chemistry consent RPC'; END IF;
 RAISE NOTICE 'PASS P0-20 three original side-effecting getters shadow-fenced ONLY in disposable PG17';
END $p020$;
