-- D09-02: new Stage0 first-completion T0 is server-frozen and read-only.
-- DISPOSABLE 2-USER PG17 ONLY, AFTER full signed owner JWT test.
\set ON_ERROR_STOP on
BEGIN;
DO $t0_test$
DECLARE
 v_uid uuid:='11111111-1111-4111-8111-111111111191'::uuid;
 v_other uuid:='22222222-2222-4222-8222-222222222292'::uuid;
 v_program bigint;
 v_original_p1 private.exam_prep_diagnostic_t0_snapshots_v1%ROWTYPE;
 v_original_p5 private.exam_prep_diagnostic_t0_snapshots_v1%ROWTYPE;
 v_after_p1 private.exam_prep_diagnostic_t0_snapshots_v1%ROWTYPE;
 v_after_p5 private.exam_prep_diagnostic_t0_snapshots_v1%ROWTYPE;
 v_before_other jsonb;
 v_after_other jsonb;
 v_old_sessions text;
 v_new_sessions text;
 v_old_corrections text;
 v_new_corrections text;
 v_denied boolean:=false;
 v_view jsonb;
BEGIN
 IF current_database()<>'postgres'
    OR current_setting('server_version_num')::integer<170000
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM auth.users)<>2
    OR (SELECT count(*) FROM public.users)<>2
    OR to_regclass('private.exam_prep_diagnostic_t0_snapshots_v1') IS NULL
    OR to_regprocedure('private.capture_exam_prep_diagnostic_t0_stage0_v1()') IS NULL
 THEN RAISE EXCEPTION 'D09-02 refuses non-disposable or missing migrated PG17'; END IF;
 SELECT program_version_id INTO STRICT v_program
 FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;

 -- These records were formed by REAL diagnostic workflow, before this SQL test.
 SELECT * INTO STRICT v_original_p1
 FROM private.exam_prep_diagnostic_t0_snapshots_v1
 WHERE user_id=v_uid AND program_version_id=v_program AND component_code='P1';
 SELECT * INTO STRICT v_original_p5
 FROM private.exam_prep_diagnostic_t0_snapshots_v1
 WHERE user_id=v_uid AND program_version_id=v_program AND component_code='P5';
 IF v_original_p1.diagnostic_completed_at IS NULL
    OR v_original_p5.diagnostic_completed_at IS NULL
    OR v_original_p1.capture_source<>'first_verified_stage0_transition'
    OR v_original_p5.capture_source<>'first_verified_stage0_transition'
 THEN RAISE EXCEPTION 'D09-02 real owner diagnostic T0 missing'; END IF;

 SELECT coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb) INTO v_before_other
 FROM private.exam_prep_diagnostic_t0_snapshots_v1 t WHERE t.user_id=v_other;
 SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY t.id::text),''))
 INTO v_old_sessions FROM private.exam_prep_sessions t WHERE t.user_id=v_uid;
 SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY t.id::text),''))
 INTO v_old_corrections FROM private.exam_prep_correction_cases t WHERE t.user_id=v_uid;

 -- A second placement recalculation or later rescreening cannot move first T0.
 UPDATE private.exam_prep_component_placements SET stage0_complete=false
 WHERE user_id=v_uid AND program_version_id=v_program
   AND component_code IN ('P1','P5') AND stage0_complete=true;
 UPDATE private.exam_prep_component_placements SET stage0_complete=true
 WHERE user_id=v_uid AND program_version_id=v_program
   AND component_code IN ('P1','P5') AND stage0_complete=false;

 SELECT * INTO STRICT v_after_p1
 FROM private.exam_prep_diagnostic_t0_snapshots_v1
 WHERE user_id=v_uid AND program_version_id=v_program AND component_code='P1';
 SELECT * INTO STRICT v_after_p5
 FROM private.exam_prep_diagnostic_t0_snapshots_v1
 WHERE user_id=v_uid AND program_version_id=v_program AND component_code='P5';
 IF to_jsonb(v_after_p1) IS DISTINCT FROM to_jsonb(v_original_p1)
    OR to_jsonb(v_after_p5) IS DISTINCT FROM to_jsonb(v_original_p5)
 THEN RAISE EXCEPTION 'D09-02 repeated placement changed immutable original T0'; END IF;

 -- Even a privileged SQL UPDATE fails. Public learners have zero direct table
 -- privilege; arbitrary updates cannot rewrite the academic chronology.
 BEGIN
  UPDATE private.exam_prep_diagnostic_t0_snapshots_v1
  SET diagnostic_completed_at=diagnostic_completed_at+interval '7 days'
  WHERE user_id=v_uid AND component_code='P1';
 EXCEPTION WHEN SQLSTATE '42501' THEN v_denied:=true;
 END;
 IF NOT v_denied THEN RAISE EXCEPTION 'D09-02 T0 row can be overwritten'; END IF;
 IF has_table_privilege('authenticated',
    'private.exam_prep_diagnostic_t0_snapshots_v1'::regclass,'INSERT')
    OR has_table_privilege('authenticated',
    'private.exam_prep_diagnostic_t0_snapshots_v1'::regclass,'UPDATE')
    OR has_table_privilege('authenticated',
    'private.exam_prep_diagnostic_t0_snapshots_v1'::regclass,'SELECT')
 THEN RAISE EXCEPTION 'D09-02 public user has direct origin table access'; END IF;

 PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 PERFORM set_config('request.jwt.claims',
  jsonb_build_object('sub',v_uid::text,'role','authenticated')::text,true);
 v_view:=public.get_exam_prep_diagnostic_periods_safe_v1();
 IF v_view->'P1'->>'anchor_immutable'<>'true'
    OR v_view->'P5'->>'anchor_immutable'<>'true'
    OR (v_view->'P1'->>'diagnostic_completed_at')::timestamptz IS DISTINCT FROM
       v_original_p1.diagnostic_completed_at
    OR (v_view->'P5'->>'diagnostic_completed_at')::timestamptz IS DISTINCT FROM
       v_original_p5.diagnostic_completed_at
 THEN RAISE EXCEPTION 'D09-02 frozen P1/P5 first periods mismatched: %',v_view; END IF;

 SELECT coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb) INTO v_after_other
 FROM private.exam_prep_diagnostic_t0_snapshots_v1 t WHERE t.user_id=v_other;
 SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY t.id::text),''))
 INTO v_new_sessions FROM private.exam_prep_sessions t WHERE t.user_id=v_uid;
 SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY t.id::text),''))
 INTO v_new_corrections FROM private.exam_prep_correction_cases t WHERE t.user_id=v_uid;
 IF v_before_other IS DISTINCT FROM v_after_other
    OR v_old_sessions IS DISTINCT FROM v_new_sessions
    OR v_old_corrections IS DISTINCT FROM v_new_corrections
 THEN RAISE EXCEPTION 'D09-02 proof changed another learner, sessions or corrections'; END IF;
 RAISE NOTICE 'D09-02 PASS: actual first Stage0 T0 frozen across second placement, direct update denied, owner P1/P5 periods immutable, sessions/corrections unchanged';
END;
$t0_test$;
ROLLBACK;

DO $postflight$
BEGIN
 IF current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'D09-02 non-isolated rollback postflight'; END IF;
 RAISE NOTICE 'D09-02 POST-ROLLBACK PASS: temporary placement toggles and denied overwrite discarded';
END;
$postflight$;
