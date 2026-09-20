-- ISOLATED PG17 ONLY. All synthetic rows ROLLBACK. NEVER run live.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true'
    OR to_regclass('weekly_goal_ci.fixture') IS NULL
    OR to_regprocedure('public.save_my_exam_prep_profile_with_weekday_availability_safe_v1(text,text,numeric,numeric,jsonb,integer,integer)') IS NULL
 THEN RAISE EXCEPTION 'WEEKDAY TEST REFUSED: disposable database required'; END IF;
END $$;
BEGIN;
DO $test$
DECLARE
 u uuid:=gen_random_uuid(); foreign_id uuid:=gen_random_uuid();
 days jsonb:='{"mon":1,"tue":1,"wed":1,"thu":1,"fri":1,"sat":0,"sun":0}'::jsonb;
 changed jsonb:='{"mon":0,"tue":1,"wed":1,"thu":1,"fri":1,"sat":1,"sun":0}'::jsonb;
 r jsonb; p private.exam_prep_exam_profiles%rowtype; rev int; epoch int; aud int;
BEGIN
 UPDATE private.exam_prep_feature_config SET rollout_state='controlled_beta',core_enabled=true,
  ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now() WHERE id=1;
 INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous) VALUES
  (u,'authenticated','authenticated','weekday-synthetic@invalid.example',now(),now(),false,false),
  (foreign_id,'authenticated','authenticated','weekday-foreign@invalid.example',now(),now(),false,false);
 INSERT INTO public.users(id,first_name,created_at,must_change_password) VALUES
  (u,'WeekdaySyntheticFixture',now(),false),(foreign_id,'WeekdayForeignFixture',now(),false);
 INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
 VALUES(u,'active',true),(foreign_id,'active',true);
 PERFORM set_config('request.jwt.claim.sub',u::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 r:=public.save_exam_prep_exam_profile_v2('May/June 2027','A',12,6);
 IF r->>'profile_revision'<>'1' THEN RAISE EXCEPTION 'Initial profile missing'; END IF;
 BEGIN
  PERFORM public.get_my_exam_prep_weekday_availability_safe_v1();
  RAISE EXCEPTION 'Unenrolled read succeeded';
 EXCEPTION WHEN sqlstate '42501' THEN NULL; END;
 BEGIN
  PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,6,days,1,0);
  RAISE EXCEPTION 'Unenrolled write succeeded';
 EXCEPTION WHEN sqlstate '42501' THEN NULL; END;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekday_availability_v1 WHERE user_id=u)
 THEN RAISE EXCEPTION 'Denied save wrote data'; END IF;
 INSERT INTO private.exam_prep_weekly_flow_enrollment_v1(user_id,enabled,approved_by,approved_at)
 VALUES(u,true,'00000000-0000-4000-8000-000000000001',now());
 r:=public.get_my_exam_prep_weekday_availability_safe_v1();
 IF r->>'profile_revision'<>'1' OR r->>'availability_revision'<>'0' OR
    r->>'confirmed'<>'false' OR r->'weekday_hours'<>'null'::jsonb
 THEN RAISE EXCEPTION 'Initial empty optional availability wrong: %',r; END IF;
 r:=public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,6,days,1,0);
 IF r->>'day_availability_saved'<>'true' OR r->>'availability_revision'<>'1' OR
    r->>'progress_retained'<>'true' OR r->>'does_not_replace_current_week'<>'true'
 THEN RAISE EXCEPTION 'Atomic save invalid: %',r; END IF;
 r:=public.get_my_exam_prep_weekday_availability_safe_v1();
 IF r->>'confirmed'<>'true' OR r->>'availability_revision'<>'1' OR
    r->'weekday_hours'<>days OR r->>'scope'<>'shared_mathematics_week'
 THEN RAISE EXCEPTION 'Owner readback invalid: %',r; END IF;
 -- Same profile revision on two devices: only the first weekday edit wins.
 r:=public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,6,changed,1,1);
 IF r->>'availability_revision'<>'2' OR r->>'profile_revision'<>'1' THEN
   RAISE EXCEPTION 'Day-only edit did not advance independent revision: %',r; END IF;
 BEGIN
  PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,6,days,1,1);
  RAISE EXCEPTION 'Stale day-only edit overwrote another device';
 EXCEPTION WHEN sqlstate '40001' THEN NULL; END;
 IF (SELECT weekday_hours FROM private.exam_prep_weekday_availability_v1 WHERE user_id=u)<>changed
 THEN RAISE EXCEPTION 'Stale overwrite changed stored day availability'; END IF;
 -- Older legacy tab can change budget; its unchanged four-arg RPC survives.
 PERFORM public.save_exam_prep_exam_profile_v2('May/June 2027','A',12,5);
 r:=public.get_my_exam_prep_weekday_availability_safe_v1();
 IF r->>'confirmed'<>'false' OR r->>'needs_reconfirmation'<>'true' OR
    r->>'profile_revision'<>'2' OR r->>'availability_revision'<>'2' OR r->'weekday_hours'<>changed
 THEN RAISE EXCEPTION 'Legacy edit lost/still confirmed old hours: %',r; END IF;
 BEGIN
  PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,5,changed,1,2);
  RAISE EXCEPTION 'Stale profile edit overwrote other device';
 EXCEPTION WHEN sqlstate '40001' THEN NULL; END;
 r:=public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,5,days,2,2);
 IF r->>'availability_revision'<>'3' THEN RAISE EXCEPTION 'Reconfirmation failed: %',r; END IF;
 SELECT * INTO p FROM private.exam_prep_exam_profiles WHERE user_id=u;
 rev:=p.profile_revision;epoch:=p.paper_comparability_epoch;
 -- Fail both profile and schedule together on each invalid payload.
 BEGIN
  PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A*',12,4,days,2,3);
  RAISE EXCEPTION 'Over-budget schedule was accepted';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM='Over-budget schedule was accepted' THEN RAISE; END IF;
 END;
 BEGIN
  PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A*',12,5,'{"mon":1}'::jsonb,2,3);
  RAISE EXCEPTION 'Partial schedule was accepted';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM='Partial schedule was accepted' THEN RAISE; END IF;
 END;
 BEGIN
  PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A*',12,5,
    '{"mon":0.25,"tue":1,"wed":1,"thu":1,"fri":1,"sat":0,"sun":0}'::jsonb,2,3);
  RAISE EXCEPTION 'Quarter-hour schedule was accepted';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM='Quarter-hour schedule was accepted' THEN RAISE; END IF;
 END;
 BEGIN
  PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('Oct/Nov 2027','A*',12,5,
    '{"mon":"1","tue":1,"wed":1,"thu":1,"fri":1,"sat":0,"sun":0}'::jsonb,2,3);
  RAISE EXCEPTION 'String hours were accepted';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM='String hours were accepted' THEN RAISE; END IF;
 END;
 SELECT * INTO p FROM private.exam_prep_exam_profiles WHERE user_id=u;
 IF p.profile_revision<>rev OR p.paper_comparability_epoch<>epoch OR
    p.target_grade<>'A' OR p.exam_series<>'May/June 2027' OR
    (SELECT weekday_hours FROM private.exam_prep_weekday_availability_v1 WHERE user_id=u)<>days
 THEN RAISE EXCEPTION 'Failed save partially modified learner state'; END IF;
 -- Explicit all-blank clear: keep audit record and no academic mutations.
 r:=public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,5,NULL,2,3);
 r:=public.get_my_exam_prep_weekday_availability_safe_v1();
 IF r->>'confirmed'<>'false' OR r->>'availability_revision'<>'4' OR
    r->'weekday_hours'<>'null'::jsonb OR r->>'needs_reconfirmation'<>'false'
 THEN RAISE EXCEPTION 'Clear contract invalid: %',r; END IF;
 SELECT count(*) INTO aud FROM private.exam_prep_audit_events WHERE target_user_id=u
   AND object_type='private.exam_prep_weekday_availability_v1';
 IF aud<4 THEN RAISE EXCEPTION 'Day revisions/clear audit missing: %',aud; END IF;
 IF (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=u)<>0 OR
    (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=u)<>0 OR
    (SELECT count(*) FROM private.exam_prep_evidence_events WHERE user_id=u)<>0
 THEN RAISE EXCEPTION 'Days unexpectedly mutated academic history'; END IF;
 PERFORM set_config('request.jwt.claim.sub',foreign_id::text,true);
 BEGIN
  PERFORM public.get_my_exam_prep_weekday_availability_safe_v1();
  RAISE EXCEPTION 'Unenrolled foreign read succeeded';
 EXCEPTION WHEN sqlstate '42501' THEN NULL; END;
 BEGIN
  PERFORM public.save_my_exam_prep_profile_with_weekday_availability_safe_v1('May/June 2027','A',12,6,days,1,0);
  RAISE EXCEPTION 'Unenrolled foreign write succeeded';
 EXCEPTION WHEN sqlstate '42501' THEN NULL; END;
 IF has_table_privilege('authenticated','private.exam_prep_weekday_availability_v1','SELECT') OR
    has_table_privilege('authenticated','private.exam_prep_weekday_availability_v1','UPDATE') OR
    has_function_privilege('anon','public.get_my_exam_prep_weekday_availability_safe_v1()','EXECUTE') OR
    has_function_privilege('anon','public.save_my_exam_prep_profile_with_weekday_availability_safe_v1(text,text,numeric,numeric,jsonb,integer,integer)','EXECUTE')
 THEN RAISE EXCEPTION 'Private schedule privileges leaked'; END IF;
 RAISE NOTICE 'GREEN: independent two-device CAS, stale profile, atomic validation, ownership, audit, no academic writes';
END;
$test$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM auth.users WHERE email IN('weekday-synthetic@invalid.example','weekday-foreign@invalid.example'))
 THEN RAISE EXCEPTION 'Synthetic users survived weekday ROLLBACK'; END IF;
 RAISE NOTICE 'GREEN: weekday test rolled back with zero synthetic residue';
END $$;
