-- DISPOSABLE PG17 ONLY; no real students. ROLLBACK all synthetic records.
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true'
     OR to_regclass('weekly_goal_ci.fixture') IS NULL
     OR to_regprocedure('public.save_my_exam_prep_profile_with_weekday_availability_safe_v1(text,text,numeric,numeric,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'WEEKDAY TEST REFUSED: disposable DB and reviewed proposal required';
  END IF;
END $$;
BEGIN;
DO $test$
DECLARE
  v_uid uuid:=gen_random_uuid(); v_foreign uuid:=gen_random_uuid();
  v_result jsonb; v_profile private.exam_prep_exam_profiles%rowtype;
  v_days jsonb:='{"mon":1,"tue":1,"wed":1,"thu":1,"fri":1,"sat":0,"sun":0}'::jsonb;
  v_revision integer; v_epoch integer; v_audit integer;
BEGIN
  UPDATE private.exam_prep_feature_config SET rollout_state='controlled_beta',core_enabled=true,
    ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now() WHERE id=1;
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
    VALUES(v_uid,'authenticated','authenticated','weekday-synthetic@invalid.example',now(),now(),false,false),
          (v_foreign,'authenticated','authenticated','weekday-foreign@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,created_at,must_change_password)
    VALUES(v_uid,'WeekdaySyntheticFixture',now(),false),
          (v_foreign,'WeekdayForeignFixture',now(),false);
  INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
    VALUES(v_uid,'active',true),(v_foreign,'active',true);
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  -- Existing unrelated synthetic enrollment from prior fixtures is allowed.
  -- Neither THIS owner nor the second owner is enrolled yet.
  IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1
            WHERE user_id IN (v_uid,v_foreign)) THEN
    RAISE EXCEPTION 'New synthetic user unexpectedly enrolled'; END IF;
  BEGIN
    PERFORM public.get_my_exam_prep_weekday_availability_safe_v1();
    RAISE EXCEPTION 'Unenrolled read incorrectly succeeded';
  EXCEPTION WHEN sqlstate '42501' THEN NULL; END;
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,6,v_days);
    RAISE EXCEPTION 'Unenrolled write incorrectly succeeded';
  EXCEPTION WHEN sqlstate '42501' THEN NULL; END;
  IF EXISTS(SELECT 1 FROM private.exam_prep_exam_profiles WHERE user_id=v_uid) THEN
    RAISE EXCEPTION 'Denied write created a profile'; END IF;

  INSERT INTO private.exam_prep_weekly_flow_enrollment_v1(user_id,enabled,approved_by,approved_at)
    VALUES(v_uid,true,'00000000-0000-4000-8000-000000000001',now());
  v_result:=public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,6,v_days);
  IF v_result->>'day_availability_saved'<>'true' OR v_result->>'day_availability_confirmed'<>'true'
     OR v_result->>'progress_retained'<>'true' THEN
    RAISE EXCEPTION 'Atomic save contract invalid: %',v_result; END IF;
  v_result:=public.get_my_exam_prep_weekday_availability_safe_v1();
  IF v_result->>'contract_version'<>'weekly_day_availability_v1'
     OR v_result->>'scope'<>'shared_mathematics_week'
     OR v_result->>'confirmed'<>'true' OR v_result->'weekday_hours'<>v_days THEN
    RAISE EXCEPTION 'Seven-day confirmation did not roundtrip: %',v_result; END IF;
  IF (SELECT count(*) FROM private.exam_prep_weekday_availability_v1 WHERE user_id=v_uid)<>1 THEN
    RAISE EXCEPTION 'One owner schedule expected'; END IF;
  SELECT count(*) INTO v_audit FROM private.exam_prep_audit_events
    WHERE target_user_id=v_uid AND object_type='private.exam_prep_weekday_availability_v1';
  IF v_audit<1 THEN RAISE EXCEPTION 'Availability audit missing'; END IF;

  -- An old tab can edit its usual four fields, but its save must invalidate,
  -- never silently revalidate or delete, the previous weekday confirmation.
  v_result:=public.save_exam_prep_exam_profile_v2('May/June 2027','A',12,5);
  v_result:=public.get_my_exam_prep_weekday_availability_safe_v1();
  IF v_result->>'confirmed'<>'false' OR v_result->>'needs_reconfirmation'<>'true'
     OR v_result->'weekday_hours'<>v_days THEN
    RAISE EXCEPTION 'Old tab incorrectly revalidated/destroyed availability: %',v_result; END IF;
  v_result:=public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,5,v_days);
  v_result:=public.get_my_exam_prep_weekday_availability_safe_v1();
  IF v_result->>'confirmed'<>'true' OR v_result->>'needs_reconfirmation'<>'false' THEN
    RAISE EXCEPTION 'Explicit reconfirmation failed: %',v_result; END IF;
  SELECT * INTO v_profile FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  v_revision:=v_profile.profile_revision; v_epoch:=v_profile.paper_comparability_epoch;

  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A*',12,4,v_days);
    RAISE EXCEPTION 'Over-budget weekdays incorrectly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='Over-budget weekdays incorrectly accepted' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A',12,5,'{"mon":2}'::jsonb);
    RAISE EXCEPTION 'Partial weekday object incorrectly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='Partial weekday object incorrectly accepted' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A',12,5,
      '{"mon":-1,"tue":1,"wed":1,"thu":1,"fri":1,"sat":0,"sun":0}'::jsonb);
    RAISE EXCEPTION 'Negative weekday hours incorrectly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='Negative weekday hours incorrectly accepted' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A',12,5,
      '{"mon":0.25,"tue":1,"wed":1,"thu":1,"fri":1,"sat":0,"sun":0}'::jsonb);
    RAISE EXCEPTION 'Unapproved quarter-hour precision incorrectly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='Unapproved quarter-hour precision incorrectly accepted' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A',12,5,
      '{"mon":"1","tue":1,"wed":1,"thu":1,"fri":1,"sat":0,"sun":0}'::jsonb);
    RAISE EXCEPTION 'Untrusted string number incorrectly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='Untrusted string number incorrectly accepted' THEN RAISE; END IF;
  END;
  SELECT * INTO v_profile FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  IF v_profile.mathematics_hours_budget<>5 OR v_profile.profile_revision<>v_revision
     OR v_profile.paper_comparability_epoch<>v_epoch OR v_profile.exam_series<>'May/June 2027'
     OR v_profile.target_grade<>'A'
     OR (SELECT weekday_hours FROM private.exam_prep_weekday_availability_v1 WHERE user_id=v_uid)<>v_days THEN
    RAISE EXCEPTION 'Invalid schedules partially changed exam profile/confirmation'; END IF;

  -- All seven blanks explicitly clear current availability but retain its audit.
  v_result:=public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,5,NULL);
  v_result:=public.get_my_exam_prep_weekday_availability_safe_v1();
  IF v_result->>'confirmed'<>'false' OR v_result->'weekday_hours'<>'null'::jsonb
     OR v_result->>'needs_reconfirmation'<>'false' THEN
    RAISE EXCEPTION 'Optional blank/clear failed: %',v_result; END IF;
  IF NOT EXISTS(SELECT 1 FROM private.exam_prep_weekday_availability_v1 WHERE user_id=v_uid AND NOT confirmed) THEN
    RAISE EXCEPTION 'Blank schedule deleted user row'; END IF;
  SELECT count(*) INTO v_audit FROM private.exam_prep_audit_events
    WHERE target_user_id=v_uid AND object_type='private.exam_prep_weekday_availability_v1';
  IF v_audit<3 THEN RAISE EXCEPTION 'Confirmation/reconfirmation/clear audit history missing'; END IF;

  IF (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=v_uid)<>0
     OR (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=v_uid)<>0
     OR (SELECT count(*) FROM private.exam_prep_evidence_events WHERE user_id=v_uid)<>0 THEN
    RAISE EXCEPTION 'Weekday preferences modified plans/sessions/evidence'; END IF;

  PERFORM set_config('request.jwt.claim.sub',v_foreign::text,true);
  BEGIN
    PERFORM public.get_my_exam_prep_weekday_availability_safe_v1();
    RAISE EXCEPTION 'Foreign/unenrolled read succeeded';
  EXCEPTION WHEN sqlstate '42501' THEN NULL; END;
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,6,v_days);
    RAISE EXCEPTION 'Foreign/unenrolled write succeeded';
  EXCEPTION WHEN sqlstate '42501' THEN NULL; END;
  IF has_table_privilege('authenticated','private.exam_prep_weekday_availability_v1','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_weekday_availability_v1','UPDATE')
     OR has_table_privilege('anon','private.exam_prep_weekday_availability_v1','SELECT')
     OR has_function_privilege('anon','public.get_my_exam_prep_weekday_availability_safe_v1()','EXECUTE')
     OR has_function_privilege('anon','public.save_my_exam_prep_profile_with_weekday_availability_safe_v1(text,text,numeric,numeric,jsonb)','EXECUTE') THEN
    RAISE EXCEPTION 'Private availability exposed to client/anon'; END IF;
  RAISE NOTICE 'GREEN: server gate, seven days, old-tab invalidation, atomic save, ownership, audit, no academic writes';
END;
$test$;
ROLLBACK;
DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM auth.users WHERE email IN ('weekday-synthetic@invalid.example','weekday-foreign@invalid.example'))
     OR EXISTS(SELECT 1 FROM public.users WHERE first_name IN ('WeekdaySyntheticFixture','WeekdayForeignFixture')) THEN
    RAISE EXCEPTION 'Synthetic weekday learners survived rollback'; END IF;
  RAISE NOTICE 'GREEN: weekday test zero synthetic residue';
END $$;
