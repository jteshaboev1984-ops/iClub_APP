-- D10-05: real signed-owner-calculation, EXACT independent P1/P5 deadlines,
-- upward one-decimal iClub HEURISTIC rounding; no new learner access gate.
-- DISPOSABLE PostgreSQL 17 only; temporary personal dates fully rolled back.
\set ON_ERROR_STOP on
DO $preflight$
BEGIN
 IF current_database()<>'postgres'
 OR current_setting('server_version_num')::integer<170000
 OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR (SELECT count(*) FROM auth.users)<>2
 OR (SELECT count(*) FROM public.users)<>2
 THEN RAISE EXCEPTION 'D10-05 refused non-disposable owner database'; END IF;
END
$preflight$;
CREATE TEMP TABLE d1005_pre_profile ON COMMIT PRESERVE ROWS AS
 SELECT to_jsonb(p) original_record FROM private.exam_prep_exam_profiles p
 WHERE p.user_id='11111111-1111-4111-8111-111111111191'::uuid;
CREATE TEMP TABLE d1005_pre_dates ON COMMIT PRESERVE ROWS AS
 SELECT to_jsonb(d) original_record FROM private.exam_prep_learner_exam_dates_v1 d
 WHERE d.user_id='11111111-1111-4111-8111-111111111191'::uuid;
BEGIN;
DO $proof$
DECLARE
 v_user uuid:='11111111-1111-4111-8111-111111111191'::uuid;
 v_today date;
 v_p1_date date;
 v_p5_date date;
 v_rate1 numeric;
 v_rate5 numeric;
 v_h1 numeric;
 v_h5 numeric;
 v_expected numeric;
 v_first_rate numeric;
 v_later_rate numeric;
 v_pace numeric;
 v_previous_other jsonb;
 v_after_other jsonb;
 v_result jsonb;
 v_one jsonb;
 v_p1_expected numeric;
 v_p5_expected numeric;
BEGIN
 IF current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR (SELECT count(*) FROM public.users)<>2
 THEN RAISE EXCEPTION 'D10-05 refused live/non-disposable database'; END IF;
 PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 PERFORM set_config('request.jwt.claims',
   jsonb_build_object('sub',v_user::text,'role','authenticated')::text,true);
 IF private.exam_prep_require_core_access_v1() IS DISTINCT FROM v_user
 THEN RAISE EXCEPTION 'D10-05 owner JWT claims not bound'; END IF;
 SELECT coalesce(jsonb_agg(to_jsonb(d) ORDER BY d.user_id,d.component_code),
   '[]'::jsonb) INTO v_previous_other
 FROM private.exam_prep_learner_exam_dates_v1 d WHERE d.user_id<>v_user;
 v_today:=(now() at time zone 'Asia/Tashkent')::date;
 -- Typical personal horizons; not assertions of official examination dates.
 v_p1_date:=(v_today+interval '4 months')::date;
 v_p5_date:=(v_today+interval '5 months')::date;
 v_result:=public.save_my_exam_prep_timeline_dates_safe_v1(v_p1_date,v_p5_date);
 IF v_result->>'contract_version'<>'exam_prep_one_line_progress_timeline_v2_estimated'
   OR v_result->>'weekly_pace_precision'<>'exact_calendar_interval_ceiling_to_0.1_hours'
   OR (v_result->>'weekly_pace_is_verified_personal_requirement')::boolean
       IS DISTINCT FROM false
   OR (v_result->>'recommended_schedule_applied_automatically')::boolean
       IS DISTINCT FROM false
   OR (v_result->>'study_access_capped')::boolean IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'D10-05 false precision, changed student consent or added access gate'; END IF;

 v_rate1:=extract(epoch from (
   (v_result->'P1'->>'exam_at')::timestamptz
   -(v_result->>'as_of')::timestamptz))::numeric/604800;
 v_rate5:=extract(epoch from (
   (v_result->'P5'->>'exam_at')::timestamptz
   -(v_result->>'as_of')::timestamptz))::numeric/604800;
 v_h1:=(v_result->'P1'->>'estimated_remaining_study_hours')::numeric;
 v_h5:=(v_result->'P5'->>'estimated_remaining_study_hours')::numeric;
 IF v_rate1<=0 OR v_rate5<=v_rate1 OR v_h1 IS NULL OR v_h5 IS NULL
 THEN RAISE EXCEPTION 'D10-05 invalid real owner P1/P5 dates or source-weighted status'; END IF;
 v_first_rate:=v_h1/v_rate1;
 v_later_rate:=(v_h1+v_h5)/v_rate5;
 v_expected:=ceil(greatest(v_first_rate,v_later_rate)*10)/10;
 v_p1_expected:=ceil((v_h1/v_rate1)*10)/10;
 v_p5_expected:=ceil((v_h5/v_rate5)*10)/10;
 v_pace:=(v_result->>'estimated_joint_math_hours_per_week')::numeric;
 IF v_pace IS DISTINCT FROM v_expected
   OR (v_result->'P1'->>'estimated_component_weekly_hours')::numeric
        IS DISTINCT FROM v_p1_expected
   OR (v_result->'P5'->>'estimated_component_weekly_hours')::numeric
        IS DISTINCT FROM v_p5_expected
   OR v_pace<greatest(v_first_rate,v_later_rate)
   OR v_pace>=greatest(v_first_rate,v_later_rate)+0.1
 THEN RAISE EXCEPTION 'D10-05 under-estimated or over-rounded weekly Math pace'; END IF;
 IF (v_result->>'p1_p5_hour_budgets_are_not_additive')::boolean
       IS DISTINCT FROM true
 THEN RAISE EXCEPTION 'D10-05 counted one Mathematics budget twice'; END IF;

 -- A learner-selected date for ONLY P1 must still give a P1 estimate,
 -- without inventing a joint P1+P5 rate or forcing P5 selection.
 v_one:=public.save_my_exam_prep_timeline_dates_safe_v1(v_p1_date,NULL);
 IF v_one->>'joint_paper_dates_status'<>'missing_at_least_one_paper_exam_date'
    OR v_one->>'estimated_joint_math_hours_per_week' IS NOT NULL
    OR (v_one->'P1'->>'estimated_component_weekly_hours')::numeric
         IS DISTINCT FROM v_p1_expected
 THEN RAISE EXCEPTION 'D10-05 one-paper personal plan changed or lost accuracy'; END IF;
 SELECT coalesce(jsonb_agg(to_jsonb(d) ORDER BY d.user_id,d.component_code),
   '[]'::jsonb) INTO v_after_other
 FROM private.exam_prep_learner_exam_dates_v1 d WHERE d.user_id<>v_user;
 IF v_after_other IS DISTINCT FROM v_previous_other
 THEN RAISE EXCEPTION 'D10-05 changed foreign learner dates'; END IF;
 IF (SELECT to_jsonb(p) FROM private.exam_prep_exam_profiles p WHERE user_id=v_user)
    IS DISTINCT FROM (SELECT original_record FROM pg_temp.d1005_pre_profile)
 THEN RAISE EXCEPTION 'D10-05 date and rate calculation silently changed profile or chosen hours'; END IF;
 -- Demonstrate a realistic arithmetic rounding bug without fake pupils:
 -- 50 proxy topic-hours over 11 weeks is 4.545..., not 4.5h weekly.
 IF round(50::numeric/11,1)<>4.5
    OR ceil((50::numeric/11)*10)/10<>4.6
 THEN RAISE EXCEPTION 'D10-05 expected known nearest-tenth under-round example changed'; END IF;
 RAISE NOTICE 'D10-05 PASS: exact P1/P5 clock, ceiling-safe weekly and one-paper rate, learner control unchanged';
END
$proof$;
ROLLBACK;
DO $postflight$
BEGIN
 IF current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR (SELECT count(*) FROM public.users)<>2
 THEN RAISE EXCEPTION 'D10-05 rollback verification refused live database'; END IF;
 IF EXISTS(
   SELECT original_record FROM pg_temp.d1005_pre_dates
   EXCEPT ALL
   SELECT to_jsonb(d) FROM private.exam_prep_learner_exam_dates_v1 d
   WHERE d.user_id='11111111-1111-4111-8111-111111111191'::uuid
 ) OR EXISTS(
   SELECT to_jsonb(d) FROM private.exam_prep_learner_exam_dates_v1 d
   WHERE d.user_id='11111111-1111-4111-8111-111111111191'::uuid
   EXCEPT ALL
   SELECT original_record FROM pg_temp.d1005_pre_dates
 ) OR
 (SELECT to_jsonb(p) FROM private.exam_prep_exam_profiles p
   WHERE user_id='11111111-1111-4111-8111-111111111191'::uuid)
   IS DISTINCT FROM (SELECT original_record FROM pg_temp.d1005_pre_profile)
 THEN RAISE EXCEPTION 'D10-05 rollback failed to restore exact original owner data'; END IF;
 RAISE NOTICE 'D10-05 ROLLBACK PASS: exact original owner dates/profile preserved';
END
$postflight$;
