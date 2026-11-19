-- Mathematics P1/P5 P0-16B · SOURCE-ONLY / DORMANT CANDIDATE
-- Do not copy into supabase/migrations, run on hosted Supabase or enable controls
-- without an independent exact-main source/ACL review, signed E2E and owner GO.
-- Designed against main f30adcd4b6b4cbc230fa375418e5aa56f95e49d2.
-- JWT issuance-time fence is signed by PostgREST; the browser build header is
-- an honest stale-tab compatibility signal, NOT cryptographic code attestation.
BEGIN;

ALTER TABLE private.exam_prep_feature_config
  ADD COLUMN IF NOT EXISTS writer_min_jwt_iat bigint,
  ADD COLUMN IF NOT EXISTS writer_client_contract text;

COMMENT ON COLUMN private.exam_prep_feature_config.writer_min_jwt_iat IS
  'P0-16B opt-in signed JWT iat cutoff; NULL=OFF. Requires separate release GO.';
COMMENT ON COLUMN private.exam_prep_feature_config.writer_client_contract IS
  'P0-16B opt-in Math browser compatibility marker; NULL=OFF. Spoofable, not auth.';

-- No UPDATE of the feature row: both controls remain NULL, OFF on installation.
CREATE OR REPLACE FUNCTION private.exam_prep_writer_contract_current_v1()
RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $guard$
DECLARE
  v_min bigint; v_contract text; v_claims text; v_iat text; v_headers text; v_sent text;
BEGIN
  SELECT c.writer_min_jwt_iat,c.writer_client_contract
    INTO v_min,v_contract
    FROM private.exam_prep_feature_config c
    WHERE c.program_key='math_as_p1_p5';
  IF v_min IS NULL AND v_contract IS NULL THEN RETURN true; END IF;
  IF v_min IS NOT NULL THEN
    v_claims:=nullif(current_setting('request.jwt.claims',true),'');
    v_iat:=coalesce(
      CASE WHEN v_claims IS NOT NULL THEN v_claims::jsonb->>'iat' ELSE NULL END,
      nullif(current_setting('request.jwt.claim.iat',true),''));
    IF v_iat IS NULL OR v_iat !~ '^[0-9]{9,12}$' OR v_iat::bigint<v_min THEN
      RETURN false;
    END IF;
  END IF;
  IF v_contract IS NOT NULL THEN
    v_headers:=nullif(current_setting('request.headers',true),'');
    v_sent:=CASE WHEN v_headers IS NOT NULL
      THEN v_headers::jsonb->>'x-iclub-math-writer-build' ELSE NULL END;
    IF v_sent IS DISTINCT FROM v_contract THEN RETURN false; END IF;
  END IF;
  RETURN true;
END
$guard$;

CREATE OR REPLACE FUNCTION private.exam_prep_require_writer_contract_v1()
RETURNS void LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $guard$
BEGIN
  IF NOT private.exam_prep_writer_contract_current_v1() THEN
    RAISE EXCEPTION 'exam_prep_writer_contract_stale' USING errcode='42501';
  END IF;
END
$guard$;

REVOKE ALL ON FUNCTION private.exam_prep_writer_contract_current_v1()
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.exam_prep_require_writer_contract_v1()
  FROM PUBLIC,anon,authenticated;

-- Fail atomically on drift or newly overloaded/rewritten entrypoints.
-- The existing Core owner/access authorization runs BEFORE this future-only
-- additional cutoff. Do not version individual answer payloads or reset IDs.
DO $patch$
DECLARE
  v_name text; v_oid oid; v_count integer; v_src text; v_anchor text;
  v_guard_count integer;
  v_pattern constant text :=
    'v_uid[[:space:]]*:=[[:space:]]*private[.]exam_prep_require_core_access_v1[(][)];';
BEGIN
  FOREACH v_name IN ARRAY ARRAY[
    'advance_exam_prep_written_step_safe_v1',
    'authorize_exam_prep_correction_safe_v1',
    'authorize_exam_prep_goal_once_safe_v1',
    'authorize_exam_prep_mixed_safe_v1',
    'authorize_exam_prep_plan_item_safe_v1',
    'authorize_exam_prep_retest_safe_v1',
    'authorize_exam_prep_revalidation_item_safe_v1',
    'authorize_exam_prep_timed_safe_v1',
    'check_exam_prep_hybrid_s4_final_safe_v1',
    'claim_exam_prep_periodic_study_report_safe_v1',
    'ensure_exam_prep_balanced_weekly_plan_safe_v1',
    'ensure_exam_prep_stable_weekly_plan_safe_v1',
    'ensure_exam_prep_weekly_goals_safe_v1',
    'finalize_exam_prep_session_safe_v1',
    'finalize_exam_prep_session_written_v1',
    'finalize_exam_prep_timed_safe_v1',
    'finish_exam_prep_hybrid_s4_paper_safe_v1',
    'generate_exam_prep_weekly_plan_safe_v1',
    'generate_exam_prep_weekly_plan_safe_v2',
    'generate_exam_prep_weekly_plan_safe_v3',
    'record_my_exam_prep_interruption_v1',
    'record_my_exam_prep_interruption_v2',
    'reveal_exam_prep_hybrid_s4_review_safe_v1',
    'save_exam_prep_exam_profile_v1',
    'save_exam_prep_exam_profile_v2',
    'save_exam_prep_study_schedule_safe_v1',
    'save_my_exam_prep_exam_appointment_v1',
    'save_my_exam_prep_exam_appointment_v2',
    'save_my_exam_prep_timeline_dates_safe_v1',
    'save_my_exam_prep_weekly_choice_s3_safe_v1',
    'set_my_exam_prep_exam_ops_confirmation_v1',
    'start_exam_prep_hybrid_s4_paper_safe_v1',
    'start_exam_prep_learning_review_safe_v1',
    'start_exam_prep_next_diagnostic_safe_v1',
    'start_exam_prep_plan_session_once_safe_v1',
    'start_exam_prep_session_safe_v1',
    'start_my_exam_prep_extra_hard_safe_v1',
    'submit_exam_prep_response_safe_v1',
    'submit_my_exam_prep_extra_hard_safe_v1'
  ] LOOP
    SELECT count(*), min(p.oid) INTO v_count,v_oid
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname=v_name;
    IF v_count<>1 THEN
      RAISE EXCEPTION 'P0-16B missing/overloaded writer % count=%',v_name,v_count;
    END IF;
    v_src:=pg_get_functiondef(v_oid);
    SELECT count(*) INTO v_guard_count
      FROM regexp_matches(v_src,v_pattern,'gi');
    IF v_guard_count<>1
       OR position('SECURITY DEFINER' in upper(v_src))=0
       OR position('search_path TO ''''' in v_src)=0
       OR position('exam_prep_require_writer_contract_v1' in v_src)>0
       OR NOT has_function_privilege('authenticated',v_oid,'EXECUTE')
       OR has_function_privilege('anon',v_oid,'EXECUTE')
    THEN
      RAISE EXCEPTION 'P0-16B source/ACL drift on % anchors=%',v_name,v_guard_count;
    END IF;
    v_anchor:=substring(v_src FROM v_pattern);
    EXECUTE replace(v_src,v_anchor,v_anchor||E'\n  PERFORM private.exam_prep_require_writer_contract_v1();');
  END LOOP;
END
$patch$;

-- Three read RPCs rebuild skill/stage/placement projections. During a
-- cutover they may still READ preserved projections but must not DELETE/
-- INSERT them from stale tabs (including JWT-refreshed cached JavaScript).
DO $reads$
DECLARE
  v_name text; v_oid oid; v_count integer; v_src text; v_anchor text;
  v_pattern text;
BEGIN
  FOREACH v_name IN ARRAY ARRAY[
    'get_exam_prep_state_safe_v1',
    'get_exam_prep_placement_safe_v1',
    'get_exam_prep_diagnostic_progress_safe_v1'
  ] LOOP
    SELECT count(*),min(p.oid) INTO v_count,v_oid
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname=v_name;
    IF v_count<>1 THEN RAISE EXCEPTION 'P0-16B read drift %',v_name; END IF;
    v_src:=pg_get_functiondef(v_oid);
    v_pattern:=CASE WHEN v_name='get_exam_prep_state_safe_v1'
      THEN 'perform[[:space:]]+private[.]rebuild_exam_prep_state_v1[(]v_uid,p_component_code[)];'
      ELSE 'perform[[:space:]]+private[.]rebuild_exam_prep_placement_v1[(]v_uid,p_component_code[)];' END;
    SELECT count(*) INTO v_count FROM regexp_matches(v_src,v_pattern,'gi');
    IF v_count<>1 OR position('SECURITY DEFINER' in upper(v_src))=0
      OR position('search_path TO ''''' in v_src)=0
      OR position('exam_prep_writer_contract_current_v1' in v_src)>0 THEN
      RAISE EXCEPTION 'P0-16B getter source drift % matches=%',v_name,v_count;
    END IF;
    v_anchor:=substring(v_src FROM v_pattern);
    EXECUTE replace(v_src,v_anchor,
      'IF private.exam_prep_writer_contract_current_v1() THEN '||v_anchor||' END IF;');
  END LOOP;
END
$reads$;

-- Intentional exception: record_exam_prep_integrity_event_safe_v1 is an
-- authenticated append-only audit path. Blocking it would lose anti-cheat
-- evidence from stale tabs; it retains its existing owner/Core checks.
-- No config activation, no learner DML and no migration ledger entry here.
COMMIT;
