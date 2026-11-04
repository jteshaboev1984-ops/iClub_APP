-- Issue #450 / Package 3 P3-03: genuine NEXT weekly budget after 7 days.
-- DISPOSABLE PostgreSQL 17 CI ONLY. NOT A PRODUCTION MIGRATION.
-- Complements the signed-JWT/PostgREST/Chromium current-week proof.
-- This specific 7-day rollover uses postgres-internal authenticated claim
-- context in a single transaction; does NOT claim a cryptographically signed
-- HTTP request or genuine human week. All changes ROLLBACK, even on SQL failure
-- when psql ON_ERROR_STOP closes the transaction.
\set ON_ERROR_STOP on
BEGIN;
DO $p303$
DECLARE
 v_uid uuid := '11111111-1111-4111-8111-111111111191'::uuid;
 v_other uuid := '22222222-2222-4222-8222-222222222292'::uuid;
 v_profile private.exam_prep_exam_profiles%ROWTYPE;
 v_old private.exam_prep_weekly_budget_snapshots_v1%ROWTYPE;
 v_old_p1 uuid;
 v_old_p5 uuid;
 v_old_p1_items jsonb;
 v_old_p5_items jsonb;
 v_same jsonb;
 v_next_p1 jsonb;
 v_next_p5 jsonb;
 v_new_p1 jsonb;
 v_new_p5 jsonb;
 v_repeat jsonb;
 v_horizon_before jsonb;
 v_horizon_after jsonb;
 v_sessions_before text;
 v_sessions_after text;
 v_auth_before text;
 v_auth_after text;
 v_corrections_before text;
 v_corrections_after text;
 v_b_before jsonb;
 v_b_after jsonb;
 v_legacy_before jsonb;
 v_legacy_after jsonb;
 v_minutes integer;
 v_week integer;
 v_refused boolean := false;
BEGIN
 IF current_database() <> 'postgres'
   OR current_setting('server_version_num')::int < 170000
   OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
   OR (SELECT count(*) FROM auth.users) <> 2
   OR (SELECT count(*) FROM public.users) <> 2
   OR NOT EXISTS(SELECT 1 FROM public.users WHERE id=v_uid)
   OR NOT EXISTS(SELECT 1 FROM public.users WHERE id=v_other)
   OR to_regclass('private.exam_prep_weekly_flow_enrollment_v1') IS NULL
   OR to_regclass('private.exam_prep_weekly_budget_snapshots_v1') IS NULL
   OR to_regprocedure('public.ensure_my_exam_prep_weekly_budget_safe_v1(text,uuid)') IS NULL
   OR to_regprocedure('public.ensure_exam_prep_balanced_weekly_plan_safe_v1(text)') IS NULL
   OR to_regprocedure('private.exam_prep_effective_active_week_v1(uuid)') IS NULL
 THEN RAISE EXCEPTION 'P3-03 REFUSED: isolated two-learner PG17 candidate required'; END IF;

 -- Match auth.uid() context for public SECDEF RPCs. This alone is NOT signed JWT.
 PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 PERFORM set_config('request.jwt.claims',
   jsonb_build_object('sub',v_uid::text,'role','authenticated',
    'aud','authenticated','iat',floor(extract(epoch from now()))::bigint)::text,true);
 IF auth.uid() IS DISTINCT FROM v_uid
    OR private.exam_prep_require_core_access_v1() IS DISTINCT FROM v_uid
 THEN RAISE EXCEPTION 'P3-03 synthetic authenticated Core scope invalid'; END IF;

 SELECT * INTO STRICT v_profile
 FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
 IF v_profile.active_week_no<>1
    OR private.exam_prep_effective_active_week_v1(v_uid)<>1
    OR v_profile.mathematics_hours_budget<>3.5
 THEN RAISE EXCEPTION 'P3-03 unexpected current-week real HTTP fixture profile %',
   to_jsonb(v_profile); END IF;
 SELECT * INTO STRICT v_old
 FROM private.exam_prep_weekly_budget_snapshots_v1
 WHERE user_id=v_uid AND program_version_id=v_profile.program_version_id
   AND active_week_no=1;
 IF v_old.available_math_minutes<>360
    OR v_old.selected_math_hours<>6
    OR v_old.p1_available_minutes+v_old.p5_available_minutes<>360
 THEN RAISE EXCEPTION 'P3-03 existing six-hour budget was not frozen before real schedule change'; END IF;
 SELECT id INTO STRICT v_old_p1 FROM private.exam_prep_weekly_plans
 WHERE user_id=v_uid AND program_version_id=v_profile.program_version_id
   AND component_code='P1' AND active_week_no=1 AND status='active';
 SELECT id INTO STRICT v_old_p5 FROM private.exam_prep_weekly_plans
 WHERE user_id=v_uid AND program_version_id=v_profile.program_version_id
   AND component_code='P5' AND active_week_no=1 AND status='active';

 SELECT coalesce(jsonb_agg(to_jsonb(i) ORDER BY i.priority_order),'[]'::jsonb)
  INTO v_old_p1_items FROM private.exam_prep_weekly_plan_items i WHERE plan_id=v_old_p1;
 SELECT coalesce(jsonb_agg(to_jsonb(i) ORDER BY i.priority_order),'[]'::jsonb)
  INTO v_old_p5_items FROM private.exam_prep_weekly_plan_items i WHERE plan_id=v_old_p5;
 SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),''))
  INTO v_sessions_before FROM private.exam_prep_sessions x WHERE user_id=v_uid;
 SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),''))
  INTO v_auth_before FROM private.exam_prep_session_authorizations x WHERE user_id=v_uid;
 SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),''))
  INTO v_corrections_before FROM private.exam_prep_correction_cases x WHERE user_id=v_uid;
 SELECT jsonb_build_object(
  'profile',(SELECT coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb)
    FROM private.exam_prep_exam_profiles t WHERE t.user_id=v_other),
  'sessions',(SELECT coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb)
    FROM private.exam_prep_sessions t WHERE t.user_id=v_other),
  'budgets',(SELECT coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb)
    FROM private.exam_prep_weekly_budget_snapshots_v1 t WHERE t.user_id=v_other)
 ) INTO v_b_before;
 SELECT jsonb_build_object(
  'practice',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),''))
    FROM public.practice_attempts t),
  'tours',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),''))
    FROM public.tour_attempts t),
  'certificates',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),''))
    FROM public.certificates t)
 ) INTO v_legacy_before;
 v_horizon_before:=public.get_exam_prep_personal_horizon_safe_v1();
 IF v_horizon_before->'P1'->>'exam_start_at' IS NULL
    OR v_horizon_before->'P5'->>'exam_start_at' IS NULL
    OR v_horizon_before->'P1'->>'exam_start_at'
      IS NOT DISTINCT FROM v_horizon_before->'P5'->>'exam_start_at'
 THEN RAISE EXCEPTION 'P3-03 P1/P5 independent centre-confirmed dates not present'; END IF;

 -- Already selected a new 30min*7d=3.5h Math budget in real signed HTTP,
 -- after week 1 snapshot captured six hours. Reopening week 1 must not rewrite.
 v_same:=public.ensure_my_exam_prep_weekly_budget_safe_v1('P1',v_old_p1);
 IF (v_same->>'available_math_minutes')::int<>360
    OR (v_same->>'profile_changed_after_capture')::boolean IS DISTINCT FROM true
 THEN RAISE EXCEPTION 'P3-03 same-week recomputation changed frozen budget %',v_same; END IF;

 -- Simulate passage of eight days for ONLY this disposable learner, and only
 -- inside this transaction. Does not touch the real clock or exam deadlines.
 UPDATE private.exam_prep_exam_profiles
 SET created_at=now()-interval '8 days'
 WHERE user_id=v_uid;
 v_week:=private.exam_prep_effective_active_week_v1(v_uid);
 IF v_week<>2
 THEN RAISE EXCEPTION 'P3-03 7-day real active-week rollover failed %',v_week; END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_budget_snapshots_v1
   WHERE user_id=v_uid AND program_version_id=v_profile.program_version_id
     AND active_week_no=2)
 THEN RAISE EXCEPTION 'P3-03 week two existed before genuine plan creation'; END IF;

 -- The real weekly planner is an independently opt-in beta route.
 -- Enrol ONLY fake A, ONLY in this immediately rolled-back transaction.
 -- Never flip global qa_open_all_*, Core, AI or the production rollout state.
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) IS DISTINCT FROM true THEN
   INSERT INTO private.exam_prep_weekly_flow_enrollment_v1(
     user_id,enabled,approved_by,approved_at
   ) VALUES (v_uid,true,v_uid,clock_timestamp())
   ON CONFLICT(user_id) DO UPDATE SET
     enabled=excluded.enabled,
     approved_by=excluded.approved_by,
     approved_at=excluded.approved_at;
 END IF;
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) IS DISTINCT FROM true
 THEN RAISE EXCEPTION 'P3-03 weekly Core route cannot be enabled for isolated fake A'; END IF;
 -- One existing normal academic plan authority, never a new planner.
 v_next_p1:=public.ensure_exam_prep_balanced_weekly_plan_safe_v1('P1');
 v_next_p5:=public.ensure_exam_prep_balanced_weekly_plan_safe_v1('P5');
 IF v_next_p1->>'status'<>'created' OR v_next_p5->>'status'<>'created'
    OR (v_next_p1->>'plan_id')::uuid=v_old_p1
    OR (v_next_p5->>'plan_id')::uuid=v_old_p5
 THEN RAISE EXCEPTION 'P3-03 next genuine plan not created or previous session still pending, P1=% P5=%',
  v_next_p1,v_next_p5; END IF;

 v_new_p1:=public.ensure_my_exam_prep_weekly_budget_safe_v1('P1',(v_next_p1->>'plan_id')::uuid);
 v_new_p5:=public.ensure_my_exam_prep_weekly_budget_safe_v1('P5',(v_next_p5->>'plan_id')::uuid);
 v_minutes:=floor(v_profile.mathematics_hours_budget*60)::integer;
 IF v_minutes<>210
    OR (v_new_p1->>'available_math_minutes')::int<>v_minutes
    OR (v_new_p5->>'available_math_minutes')::int<>v_minutes
    OR (v_new_p1->>'p1_reserved_minutes')::int + (v_new_p1->>'p5_reserved_minutes')::int<>v_minutes
    OR (v_new_p1->>'p1_reserved_minutes')::int IS DISTINCT FROM
       (v_new_p5->>'p1_reserved_minutes')::int
    OR (v_new_p1->>'p5_reserved_minutes')::int IS DISTINCT FROM
       (v_new_p5->>'p5_reserved_minutes')::int
    OR (v_new_p1->>'active_week_no')::int<>2
    OR (v_new_p5->>'active_week_no')::int<>2
    OR (v_new_p1->>'profile_revision_at_capture')::int IS DISTINCT FROM
       v_profile.profile_revision
 THEN RAISE EXCEPTION 'P3-03 new 210-minute P1/P5 single budget wrong: P1=% P5=%',
  v_new_p1,v_new_p5; END IF;

 v_repeat:=public.ensure_my_exam_prep_weekly_budget_safe_v1('P5',(v_next_p5->>'plan_id')::uuid);
 IF v_repeat->>'p1_reserved_minutes' IS DISTINCT FROM v_new_p5->>'p1_reserved_minutes'
    OR v_repeat->'priority_slots' IS DISTINCT FROM v_new_p5->'priority_slots'
 THEN RAISE EXCEPTION 'P3-03 repeated next-week open rewrote allocation'; END IF;

 -- Old plan cannot be used to create a second-week budget or reopen a session.
 BEGIN
  PERFORM public.ensure_my_exam_prep_weekly_budget_safe_v1('P1',v_old_p1);
 EXCEPTION WHEN SQLSTATE '42501' THEN v_refused:=true;
 END;
 IF NOT v_refused THEN
  RAISE EXCEPTION 'P3-03 week one plan accepted as an active week two plan'; END IF;

 IF (SELECT to_jsonb(b) FROM private.exam_prep_weekly_budget_snapshots_v1 b
     WHERE b.user_id=v_uid AND b.program_version_id=v_profile.program_version_id
       AND b.active_week_no=1) IS DISTINCT FROM to_jsonb(v_old)
 THEN RAISE EXCEPTION 'P3-03 old week snapshot changed'; END IF;
 IF (SELECT coalesce(jsonb_agg(to_jsonb(i) ORDER BY i.priority_order),'[]'::jsonb)
      FROM private.exam_prep_weekly_plan_items i WHERE plan_id=v_old_p1)
    IS DISTINCT FROM v_old_p1_items
 OR (SELECT coalesce(jsonb_agg(to_jsonb(i) ORDER BY i.priority_order),'[]'::jsonb)
      FROM private.exam_prep_weekly_plan_items i WHERE plan_id=v_old_p5)
    IS DISTINCT FROM v_old_p5_items
 THEN RAISE EXCEPTION 'P3-03 prior week priorities/corrections were rewritten'; END IF;
 SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),''))
  INTO v_sessions_after FROM private.exam_prep_sessions x WHERE user_id=v_uid;
 SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),''))
  INTO v_auth_after FROM private.exam_prep_session_authorizations x WHERE user_id=v_uid;
 SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),''))
  INTO v_corrections_after FROM private.exam_prep_correction_cases x WHERE user_id=v_uid;
 IF v_sessions_before IS DISTINCT FROM v_sessions_after
    OR v_auth_before IS DISTINCT FROM v_auth_after
    OR v_corrections_before IS DISTINCT FROM v_corrections_after
 THEN RAISE EXCEPTION 'P3-03 saved sessions/auth/corrections changed from time rollover'; END IF;

 v_horizon_after:=public.get_exam_prep_personal_horizon_safe_v1();
 IF v_horizon_after->'P1'->>'exam_start_at' IS DISTINCT FROM
    v_horizon_before->'P1'->>'exam_start_at'
    OR v_horizon_after->'P5'->>'exam_start_at' IS DISTINCT FROM
       v_horizon_before->'P5'->>'exam_start_at'
 THEN RAISE EXCEPTION 'P3-03 independent P1/P5 exam dates changed'; END IF;
 SELECT jsonb_build_object(
  'profile',(SELECT coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb)
    FROM private.exam_prep_exam_profiles t WHERE t.user_id=v_other),
  'sessions',(SELECT coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb)
    FROM private.exam_prep_sessions t WHERE t.user_id=v_other),
  'budgets',(SELECT coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb)
    FROM private.exam_prep_weekly_budget_snapshots_v1 t WHERE t.user_id=v_other)
 ) INTO v_b_after;
 SELECT jsonb_build_object(
  'practice',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),''))
    FROM public.practice_attempts t),
  'tours',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),''))
    FROM public.tour_attempts t),
  'certificates',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),''))
    FROM public.certificates t)
 ) INTO v_legacy_after;
 IF v_b_before IS DISTINCT FROM v_b_after
    OR v_legacy_before IS DISTINCT FROM v_legacy_after
 THEN RAISE EXCEPTION 'P3-03 other learner or legacy Practice/Tours/certificates changed'; END IF;

 RAISE NOTICE 'P3-03 PASS inside disposable transaction: 360min frozen week1, 210min week2, 7+day transition, one P1/P5 budget, no old session/correction/date/other-user drift';
END;
$p303$;
ROLLBACK;

-- Independent post-ROLLBACK: neither the calendar manipulation nor newly
-- generated week-two plans/budget may survive this SQL test connection.
DO $postflight$
DECLARE
 v_uid uuid := '11111111-1111-4111-8111-111111111191'::uuid;
BEGIN
 IF current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
  OR private.exam_prep_effective_active_week_v1(v_uid) <> 1
  OR EXISTS (SELECT 1 FROM private.exam_prep_weekly_budget_snapshots_v1
     WHERE user_id=v_uid AND active_week_no=2)
  OR EXISTS (SELECT 1 FROM private.exam_prep_weekly_plans
     WHERE user_id=v_uid AND active_week_no=2)
  OR EXISTS (SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1
     WHERE user_id=v_uid AND enabled)
 THEN RAISE EXCEPTION 'P3-03 refused: transaction did not restore original fake learner'; END IF;
 RAISE NOTICE 'P3-03 POST-ROLLBACK PASS: original two synthetic users restored, no next-week test rows';
END;
$postflight$;
