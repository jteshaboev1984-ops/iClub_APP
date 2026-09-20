-- ISOLATED PG17 ONLY: artificial students and all their rows rolled back.
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true'
     OR to_regclass('weekly_goal_ci.fixture') IS NULL
     OR to_regprocedure('public.save_my_exam_prep_profile_with_weekday_availability_safe_v1(text,text,numeric,numeric,jsonb,integer)') IS NULL THEN
    RAISE EXCEPTION 'WEEKDAY TEST REFUSED: isolated database and proposal required';
  END IF;
END $$;
BEGIN;
DO $test$
DECLARE
  v_uid uuid:=gen_random_uuid();v_foreign uuid:=gen_random_uuid();
  v_result jsonb;v_profile private.exam_prep_exam_profiles%rowtype;
  v_days jsonb:='{"mon":1,"tue":1,"wed":1,"thu":1,"fri":1,"sat":0,"sun":0}'::jsonb;
  v_revision integer;v_epoch integer;v_audit integer;
BEGIN
  UPDATE private.exam_prep_feature_config SET rollout_state='controlled_beta',
    core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now() WHERE id=1;
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
  v_result:=public.save_exam_prep_exam_profile_v2('May/June 2027','A',12,6);
  IF v_result->>'profile_revision'<>'1' THEN RAISE EXCEPTION 'Initial profile missing';END IF;
  IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE user_id IN(v_uid,v_foreign)) THEN
    RAISE EXCEPTION 'New users were enrolled without approval';END IF;
  BEGIN
    PERFORM public.get_my_exam_prep_weekday_availability_safe_v1();
    RAISE EXCEPTION 'Unenrolled read incorrectly succeeded';
  EXCEPTION WHEN sqlstate '42501' THEN NULL;END;
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,6,v_days,1);
    RAISE EXCEPTION 'Unenrolled write incorrectly succeeded';
  EXCEPTION WHEN sqlstate '42501' THEN NULL;END;
  IF EXISTS(SELECT 1 FROM private.exam_prep_weekday_availability_v1 WHERE user_id=v_uid) THEN
    RAISE EXCEPTION 'Denied write stored schedule';END IF;

  INSERT INTO private.exam_prep_weekly_flow_enrollment_v1(user_id,enabled,approved_by,approved_at)
    VALUES(v_uid,true,'00000000-0000-4000-8000-000000000001',now());
  v_result:=public.get_my_exam_prep_weekday_availability_safe_v1();
  IF v_result->>'profile_revision'<>'1' OR v_result->>'confirmed'<>'false' OR
     v_result->'weekday_hours'<>'null'::jsonb THEN
    RAISE EXCEPTION 'Initial optional schedule must be empty: %',v_result;END IF;
  v_result:=public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,6,v_days,1);
  IF v_result->>'day_availability_saved'<>'true' OR v_result->>'day_availability_confirmed'<>'true'
     OR v_result->>'progress_retained'<>'true' OR v_result->>'does_not_replace_current_week'<>'true' THEN
    RAISE EXCEPTION 'Atomic save response invalid: %',v_result;END IF;
  v_result:=public.get_my_exam_prep_weekday_availability_safe_v1();
  IF v_result->>'contract_version'<>'weekly_day_availability_v1' OR
     v_result->>'scope'<>'shared_mathematics_week' OR v_result->>'confirmed'<>'true' OR
     v_result->'weekday_hours'<>v_days OR v_result->>'exam_series'<>'May/June 2027' THEN
    RAISE EXCEPTION 'Owner seven-day roundtrip failed: %',v_result;END IF;
  IF (SELECT count(*) FROM private.exam_prep_weekday_availability_v1 WHERE user_id=v_uid)<>1 THEN
    RAISE EXCEPTION 'One schedule per owner expected';END IF;

  -- A legacy tab changes the shared budget. Old hours remain auditable but stale.
  PERFORM public.save_exam_prep_exam_profile_v2('May/June 2027','A',12,5);
  v_result:=public.get_my_exam_prep_weekday_availability_safe_v1();
  IF v_result->>'confirmed'<>'false' OR v_result->>'needs_reconfirmation'<>'true'
     OR v_result->'weekday_hours'<>v_days OR v_result->>'profile_revision'<>'2' THEN
    RAISE EXCEPTION 'Legacy tab silently revalidated/deleted hours: %',v_result;END IF;
  PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,5,v_days,2);
  v_result:=public.get_my_exam_prep_weekday_availability_safe_v1();
  IF v_result->>'confirmed'<>'true' OR v_result->>'needs_reconfirmation'<>'false' THEN
    RAISE EXCEPTION 'Explicit reconfirmation failed: %',v_result;END IF;
  SELECT * INTO v_profile FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  v_revision:=v_profile.profile_revision;v_epoch:=v_profile.paper_comparability_epoch;

  -- Invalid payload must fail before changing series, revision, paper epoch or availability.
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A*',12,4,v_days,2);
    RAISE EXCEPTION 'Accepted over-budget days';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM='Accepted over-budget days' THEN RAISE;END IF;END;
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A*',12,5,'{"mon":2}'::jsonb,2);
    RAISE EXCEPTION 'Accepted incomplete weekdays';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM='Accepted incomplete weekdays' THEN RAISE;END IF;END;
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A*',12,5,
      '{"mon":0.25,"tue":1,"wed":1,"thu":1,"fri":1,"sat":0,"sun":0}'::jsonb,2);
    RAISE EXCEPTION 'Accepted invalid quarter-hour step';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM='Accepted invalid quarter-hour step' THEN RAISE;END IF;END;
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A*',12,5,
      '{"mon":"1","tue":1,"wed":1,"thu":1,"fri":1,"sat":0,"sun":0}'::jsonb,2);
    RAISE EXCEPTION 'Accepted string-number input';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM='Accepted string-number input' THEN RAISE;END IF;END;
  SELECT * INTO v_profile FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  IF v_profile.profile_revision<>v_revision OR v_profile.paper_comparability_epoch<>v_epoch
     OR v_profile.exam_series<>'May/June 2027' OR v_profile.mathematics_hours_budget<>5
     OR (SELECT weekday_hours FROM private.exam_prep_weekday_availability_v1 WHERE user_id=v_uid)<>v_days THEN
    RAISE EXCEPTION 'Invalid input partially modified learner profile/schedule';END IF;

  -- Two-device optimistic conflict: the old editor must not overwrite a newer grade.
  PERFORM public.save_exam_prep_exam_profile_v2('May/June 2027','A*',12,5);
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,5,v_days,2);
    RAISE EXCEPTION 'Stale browser overwrote new profile';
  EXCEPTION WHEN sqlstate '40001' THEN NULL;END;
  SELECT * INTO v_profile FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  IF v_profile.target_grade<>'A*' OR v_profile.profile_revision<>3 THEN
    RAISE EXCEPTION 'Stale submission changed newer grade/revision';END IF;
  v_result:=public.get_my_exam_prep_weekday_availability_safe_v1();
  IF v_result->>'needs_reconfirmation'<>'true' OR v_result->>'confirmed'<>'false' THEN
    RAISE EXCEPTION 'Newer profile failed to invalidate old schedule';END IF;
  PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A*',12,5,v_days,3);
  v_result:=public.get_my_exam_prep_weekday_availability_safe_v1();
  IF v_result->>'confirmed'<>'true' THEN RAISE EXCEPTION 'Current revision revalidation failed';END IF;

  -- Seven explicitly empty inputs clear ONLY distribution, never exam evidence.
  PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A*',12,5,NULL,3);
  v_result:=public.get_my_exam_prep_weekday_availability_safe_v1();
  IF v_result->>'confirmed'<>'false' OR v_result->'weekday_hours'<>'null'::jsonb OR
     v_result->>'needs_reconfirmation'<>'false' THEN
    RAISE EXCEPTION 'Optional clear failed: %',v_result;END IF;
  IF NOT EXISTS(SELECT 1 FROM private.exam_prep_weekday_availability_v1 WHERE user_id=v_uid AND NOT confirmed) THEN
    RAISE EXCEPTION 'Clear deleted schedule row';END IF;
  SELECT count(*) INTO v_audit FROM private.exam_prep_audit_events
    WHERE target_user_id=v_uid AND object_type='private.exam_prep_weekday_availability_v1';
  IF v_audit<3 THEN RAISE EXCEPTION 'Schedule creation/reconfirmation/clear audit missing';END IF;
  IF (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=v_uid)<>0
     OR (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=v_uid)<>0
     OR (SELECT count(*) FROM private.exam_prep_evidence_events WHERE user_id=v_uid)<>0 THEN
    RAISE EXCEPTION 'Availability changed plans/sessions/academic evidence';END IF;

  PERFORM set_config('request.jwt.claim.sub',v_foreign::text,true);
  BEGIN
    PERFORM public.get_my_exam_prep_weekday_availability_safe_v1();
    RAISE EXCEPTION 'Unenrolled foreign read succeeded';
  EXCEPTION WHEN sqlstate '42501' THEN NULL;END;
  BEGIN
    PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,6,v_days,1);
    RAISE EXCEPTION 'Unenrolled foreign write succeeded';
  EXCEPTION WHEN sqlstate '42501' THEN NULL;END;
  IF has_table_privilege('authenticated','private.exam_prep_weekday_availability_v1','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_weekday_availability_v1','UPDATE')
     OR has_table_privilege('anon','private.exam_prep_weekday_availability_v1','SELECT')
     OR has_function_privilege('anon','public.get_my_exam_prep_weekday_availability_safe_v1()','EXECUTE')
     OR has_function_privilege('anon','public.save_my_exam_prep_profile_with_weekday_availability_safe_v1(text,text,numeric,numeric,jsonb,integer)','EXECUTE') THEN
    RAISE EXCEPTION 'Private weekday data/grants exposed';END IF;
  RAISE NOTICE 'GREEN: gated, atomic, owner-only, old-tab stale, device conflict, auditable clearing, no academic writes';
END;
$test$;
ROLLBACK;
DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM auth.users WHERE email IN('weekday-synthetic@invalid.example','weekday-foreign@invalid.example'))
     OR EXISTS(SELECT 1 FROM public.users WHERE first_name IN('WeekdaySyntheticFixture','WeekdayForeignFixture')) THEN
    RAISE EXCEPTION 'Synthetic weekday student survived rollback';END IF;
  RAISE NOTICE 'GREEN: zero synthetic weekday residue';
END $$;
