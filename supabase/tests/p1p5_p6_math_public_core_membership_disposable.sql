-- P6 actual Mathematics selection and real Core RPC boundary.
-- ONLY already isolated PostgreSQL 17; entire mutation rolled back.
\set ON_ERROR_STOP on
BEGIN;
DO $proof$
DECLARE
 v_math uuid;
 v_foreign uuid;
 v_math_subject bigint;
 v_count_before int;
 v_cap record;
 v_denied boolean:=false;
BEGIN
 IF current_database()<>'postgres'
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR current_setting('server_version_num')::int < 170000
    OR (SELECT count(*) FROM public.users)<>3
    OR (SELECT count(*) FROM auth.users)<>3 THEN
  RAISE EXCEPTION 'P6 REFUSED: not disposable completed 3-user PG17';
 END IF;
 SELECT user_id INTO v_math
 FROM private.exam_prep_synthetic_identities
 WHERE identity_kind='learner' AND identity_status='active'
 ORDER BY created_at DESC LIMIT 1;
 SELECT id INTO v_foreign FROM public.users
 WHERE id<>v_math ORDER BY id LIMIT 1;
 SELECT id INTO v_math_subject FROM public.subjects
 WHERE subject_key='mathematics' AND is_active IS TRUE ORDER BY id LIMIT 1;
 IF v_math IS NULL OR v_foreign IS NULL OR v_math_subject IS NULL
  THEN RAISE EXCEPTION 'P6 missing real Math study subject or synthetic learners'; END IF;
 SELECT count(*) INTO v_count_before FROM private.exam_prep_sessions WHERE user_id=v_math;

 -- The selected-Math case uses the real public learner subject table.
 DELETE FROM public.user_subjects WHERE user_id=v_foreign AND subject_id=v_math_subject;
 INSERT INTO public.user_subjects(user_id,subject_id)
 SELECT v_math,v_math_subject
 WHERE NOT EXISTS(SELECT 1 FROM public.user_subjects
  WHERE user_id=v_math AND subject_id=v_math_subject);
 UPDATE private.exam_prep_feature_entitlements
 SET core_access=false,ai_assist=false WHERE user_id IN (v_math,v_foreign);
 UPDATE private.exam_prep_feature_config
 SET rollout_state='mass',core_enabled=true,public_math_core_enabled=true,
     qa_open_all_core=false,qa_open_all_weekly=false,
     ai_enabled=false,mentor_enabled=false,kill_switch=false
 WHERE program_key='math_as_p1_p5';

 PERFORM set_config('request.jwt.claim.sub',v_math::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 SELECT * INTO v_cap FROM public.get_exam_prep_capabilities_v1();
 IF v_cap.core_access IS DISTINCT FROM true OR v_cap.ai_assist IS DISTINCT FROM false
  OR v_cap.mentor_authority IS DISTINCT FROM false
  OR v_cap.rollout_state<>'mass'
  OR private.exam_prep_require_core_access_v1() IS DISTINCT FROM v_math
  OR private.exam_prep_weekly_flow_enrolled_v1(v_math) IS DISTINCT FROM true
 THEN RAISE EXCEPTION 'P6 real Math learner cannot access Core without beta entitlement'; END IF;

 PERFORM set_config('request.jwt.claim.sub',v_foreign::text,true);
 SELECT * INTO v_cap FROM public.get_exam_prep_capabilities_v1();
 IF v_cap.core_access IS DISTINCT FROM false
    OR private.exam_prep_weekly_flow_enrolled_v1(v_foreign) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'P6 nonMath learner leaked Core/weekly'; END IF;
 BEGIN
  PERFORM private.exam_prep_require_core_access_v1();
 EXCEPTION WHEN insufficient_privilege THEN v_denied:=true;
 END;
 IF NOT v_denied THEN RAISE EXCEPTION 'P6 nonMath direct RPC guard leaked'; END IF;

 -- Temporary QA grant must never become an accidental public mass bypass.
 UPDATE private.exam_prep_feature_config SET qa_open_all_core=true WHERE id=1;
 SELECT * INTO v_cap FROM public.get_exam_prep_capabilities_v1();
 IF v_cap.core_access IS DISTINCT FROM false THEN
  RAISE EXCEPTION 'P6 temporary QA open exposed nonMath learner during mass'; END IF;
 UPDATE private.exam_prep_feature_config
 SET qa_open_all_core=false,public_math_core_enabled=false WHERE id=1;
 PERFORM set_config('request.jwt.claim.sub',v_math::text,true);
 SELECT * INTO v_cap FROM public.get_exam_prep_capabilities_v1();
 IF v_cap.core_access IS DISTINCT FROM false THEN
  RAISE EXCEPTION 'P6 default-off release switch ignored'; END IF;

 UPDATE private.exam_prep_feature_config
 SET public_math_core_enabled=true,kill_switch=true WHERE id=1;
 SELECT * INTO v_cap FROM public.get_exam_prep_capabilities_v1();
 IF v_cap.core_access IS DISTINCT FROM false THEN
  RAISE EXCEPTION 'P6 kill switch ignored'; END IF;

 -- Preserve already completed Papers, answer ledger and stage rows.
 IF (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=v_math)<>v_count_before THEN
  RAISE EXCEPTION 'P6 access changed learner history'; END IF;
 RAISE NOTICE 'P6 MASS ACCESS PASS: real selected Math Core, no beta seat, nonMath refused, weekly route, QA isolation, AI off and kill switch';
END $proof$;
ROLLBACK;
DO $post$
BEGIN
 IF NOT EXISTS(
  SELECT 1 FROM private.exam_prep_feature_config
  WHERE id=1 AND public_math_core_enabled=false AND rollout_state='controlled_beta'
 ) THEN RAISE EXCEPTION 'P6 rollback did not restore controlled beta'; END IF;
 RAISE NOTICE 'P6 MASS ACCESS ROLLBACK PASS';
END $post$;
