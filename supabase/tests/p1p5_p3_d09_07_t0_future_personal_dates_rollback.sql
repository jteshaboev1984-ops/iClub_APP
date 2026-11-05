-- D09-07: architect-approved four-year personal date ceiling; keep
-- real separate P1/P5 Stage0 start frozen and independent.
-- DISPOSABLE PG17 only. Entire fake-user write test rolls back atomically.
\set ON_ERROR_STOP on
-- Snapshot exactly the current two synthetic owner date rows OUTSIDE the
-- rolled-back transaction; never assume an unrelated fixture year or status.
DO $preflight$
BEGIN
 IF current_database()<>'postgres'
    OR current_setting('server_version_num')::int<170000
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM public.users)<>2
 THEN RAISE EXCEPTION 'D09-07 preflight refused non-disposable PostgreSQL'; END IF;
END;
$preflight$;
CREATE TEMP TABLE d0907_original_dates ON COMMIT PRESERVE ROWS AS
  SELECT to_jsonb(d) AS original_row
  FROM private.exam_prep_learner_exam_dates_v1 d
  WHERE d.user_id='11111111-1111-4111-8111-111111111191'::uuid;
BEGIN;
DO $proof$
DECLARE
 v_user uuid:='11111111-1111-4111-8111-111111111191'::uuid;
 v_profile private.exam_prep_exam_profiles%ROWTYPE;
 v_today date;
 v_future_p1 date;
 v_future_p5 date;
 v_too_late date;
 v_before_other jsonb;
 v_after_other jsonb;
 v_before_session_count integer;
 v_before_plan_count integer;
 v_before_profile_revision integer;
 v_after_profile_revision integer;
 v_result jsonb;
 v_t0 jsonb;
 v_rejected boolean:=false;
 v_rejected_too_late boolean:=false;
BEGIN
 IF current_database()<>'postgres'
    OR current_setting('server_version_num')::int<170000
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM auth.users)<>2
    OR (SELECT count(*) FROM public.users)<>2
    OR to_regprocedure('public.save_my_exam_prep_timeline_dates_safe_v1(date,date)') IS NULL
    OR to_regprocedure('public.get_exam_prep_diagnostic_periods_safe_v1()') IS NULL
 THEN RAISE EXCEPTION 'D09-07 refused: not genuine disposable CI PostgreSQL 17'; END IF;
 PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 PERFORM set_config('request.jwt.claims',
   jsonb_build_object('sub',v_user::text,'role','authenticated')::text,true);
 IF private.exam_prep_require_core_access_v1() IS DISTINCT FROM v_user
 THEN RAISE EXCEPTION 'D09-07 source owner auth failed'; END IF;
 SELECT * INTO STRICT v_profile FROM private.exam_prep_exam_profiles
 WHERE user_id=v_user;
 v_before_profile_revision:=v_profile.profile_revision;
 v_today:=(now() at time zone 'Asia/Tashkent')::date;
 v_future_p1:=(v_today+interval '18 months')::date;
 v_future_p5:=(v_today+interval '4 years')::date;
 v_too_late:=(v_today+interval '4 years 1 day')::date;
 SELECT count(*) INTO v_before_session_count FROM private.exam_prep_sessions
 WHERE user_id=v_user;
 SELECT count(*) INTO v_before_plan_count FROM private.exam_prep_weekly_plans
 WHERE user_id=v_user;
 SELECT coalesce(jsonb_agg(to_jsonb(d) ORDER BY d.user_id,d.component_code),'[]'::jsonb)
 INTO v_before_other FROM private.exam_prep_learner_exam_dates_v1 d
 WHERE d.user_id<>v_user;

 -- This is the REAL existing user-consent RPC, not an internal fake insert.
 v_result:=public.save_my_exam_prep_timeline_dates_safe_v1(v_future_p1,v_future_p5);
 IF v_result->>'contract_version'<>'exam_prep_one_line_progress_timeline_v2_estimated'
   OR v_result->'P1'->>'exam_date_status'<>'valid_exam_date'
   OR v_result->'P5'->>'exam_date_status'<>'valid_exam_date'
   OR v_result->'P1'->>'exam_date_source'<>'learner_selected'
   OR v_result->'P5'->>'exam_date_source'<>'learner_selected'
   OR (v_result->>'no_automatic_schedule_change')::boolean IS DISTINCT FROM true
   OR v_result->>'recommended_schedule_applied_automatically'<>'false'
   OR v_result->>'study_access_capped'<>'false'
 THEN RAISE EXCEPTION 'D09-07 future personal dates invalid or changed plan: %',v_result; END IF;
 IF (SELECT exam_date FROM private.exam_prep_learner_exam_dates_v1
     WHERE user_id=v_user AND component_code='P1') IS DISTINCT FROM v_future_p1
   OR (SELECT exam_date FROM private.exam_prep_learner_exam_dates_v1
     WHERE user_id=v_user AND component_code='P5') IS DISTINCT FROM v_future_p5
 THEN RAISE EXCEPTION 'D09-07 18-month and exact four-year personal dates not saved'; END IF;
 v_t0:=public.get_exam_prep_diagnostic_periods_safe_v1();
 SELECT profile_revision INTO STRICT v_after_profile_revision
 FROM private.exam_prep_exam_profiles WHERE user_id=v_user;
 IF v_after_profile_revision IS DISTINCT FROM v_before_profile_revision
 THEN RAISE EXCEPTION 'D09-07 date save changed profile revision or budget'; END IF;
 IF (v_t0->'P1'->>'diagnostic_completed_at')::timestamptz IS DISTINCT FROM
       (v_result->'P1'->>'start_at')::timestamptz
   OR (v_t0->'P5'->>'diagnostic_completed_at')::timestamptz IS DISTINCT FROM
       (v_result->'P5'->>'start_at')::timestamptz
 THEN RAISE EXCEPTION 'D09-07 exam date changed the independent genuine diagnostic start'; END IF;

 -- A date one day beyond the agreed four-year limit must be rejected
 -- by the real owner RPC without changing the previously saved dates.
 BEGIN
   PERFORM public.save_my_exam_prep_timeline_dates_safe_v1(v_future_p1,v_too_late);
 EXCEPTION WHEN SQLSTATE '22007' THEN
   v_rejected_too_late:=true;
 END;
 IF NOT v_rejected_too_late
 THEN RAISE EXCEPTION 'D09-07 accepted date beyond four years'; END IF;
 IF (SELECT exam_date FROM private.exam_prep_learner_exam_dates_v1
     WHERE user_id=v_user AND component_code='P5') IS DISTINCT FROM v_future_p5
 THEN RAISE EXCEPTION 'D09-07 rejected overflow changed saved date'; END IF;

 -- Past/today remains invalid and a deliberate clear remains possible.
 BEGIN
   PERFORM public.save_my_exam_prep_timeline_dates_safe_v1(v_today,v_future_p5);
 EXCEPTION WHEN SQLSTATE '22007' THEN
   v_rejected:=true;
 END;
 IF NOT v_rejected THEN RAISE EXCEPTION 'D09-07 accepted past/today exam date'; END IF;
 v_result:=public.save_my_exam_prep_timeline_dates_safe_v1(NULL,NULL);
 IF v_result->'P1'->>'exam_date_status'<>'exam_date_not_yet_selected'
    OR v_result->'P5'->>'exam_date_status'<>'exam_date_not_yet_selected'
 THEN RAISE EXCEPTION 'D09-07 explicit owner clear lost previous supported behaviour'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=v_user)
       <>v_before_session_count
    OR (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=v_user)
       <>v_before_plan_count
 THEN RAISE EXCEPTION 'D09-07 dates mutated learning or existing plans'; END IF;
 SELECT coalesce(jsonb_agg(to_jsonb(d) ORDER BY d.user_id,d.component_code),'[]'::jsonb)
 INTO v_after_other FROM private.exam_prep_learner_exam_dates_v1 d
 WHERE d.user_id<>v_user;
 IF v_after_other IS DISTINCT FROM v_before_other
 THEN RAISE EXCEPTION 'D09-07 foreign learner date records changed'; END IF;
 RAISE NOTICE 'D09-07 PASS: real owner saved 18-month and four-year personal dates, rejected overflow and past, preserved Stage0, plans and foreign users';
END;
$proof$;
ROLLBACK;
DO $postflight$
BEGIN
 IF current_database()<>'postgres'
 OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR (SELECT count(*) FROM public.users)<>2
 THEN RAISE EXCEPTION 'D09-07 rollback verification refused non-disposable database'; END IF;
 -- No coupling to a hard-coded calendar day: compare the exact previously
 -- saved owner rows including timestamps. Both directions catch extras/deletes.
 IF EXISTS(
   SELECT original_row FROM pg_temp.d0907_original_dates
   EXCEPT ALL
   SELECT to_jsonb(d) FROM private.exam_prep_learner_exam_dates_v1 d
   WHERE d.user_id='11111111-1111-4111-8111-111111111191'::uuid
 ) OR EXISTS(
   SELECT to_jsonb(d) FROM private.exam_prep_learner_exam_dates_v1 d
   WHERE d.user_id='11111111-1111-4111-8111-111111111191'::uuid
   EXCEPT ALL
   SELECT original_row FROM pg_temp.d0907_original_dates
 )
 THEN RAISE EXCEPTION 'D09-07 rollback altered original personal dates'; END IF;
 RAISE NOTICE 'D09-07 ROLLBACK PASS: owner profile, future dates, old learning and test users retained exactly';
END;
$postflight$;
