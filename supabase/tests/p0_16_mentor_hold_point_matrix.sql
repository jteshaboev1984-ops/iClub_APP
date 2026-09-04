-- P0-16 / P1-01 current-schema GO WITH HOLD POINT acceptance.
-- Test-only. Requires full P0 -> P1-03 schema and ends in ROLLBACK.
--
-- Proves:
-- 1) capacity=12 does not require filling all seats: a stratified 6-person cohort may be approved;
-- 2) cohort approval creates zero entitlements and keeps global feature state OFF;
-- 3) wave 1 may activate Core only;
-- 4) AI/Mentor candidates remain dark with zero entitlement;
-- 5) global feature flags remain Core-only;
-- 6) emergency pause returns the feature to fail-closed state;
-- 7) all synthetic rows roll back.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p016.current_schema',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P0-16 HOLD-POINT REFUSED: p016.current_schema=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE p016h_people(
  ord integer PRIMARY KEY,
  user_id uuid NOT NULL UNIQUE
) ON COMMIT DROP;

INSERT INTO p016h_people(ord,user_id)
SELECT g,gen_random_uuid() FROM generate_series(1,6) g;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',
       format('p016h-%s-%s@invalid.example',ord,replace(user_id::text,'-','')),
       now(),now(),false,false
FROM p016h_people;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P016 Hold',ord::text,'en',now(),false
FROM p016h_people;

GRANT SELECT ON TABLE p016h_people TO service_role;

-- Production-like hold-point precondition: no Mentor Care staff/assignments.
DO $$
DECLARE v_staff int; v_assign int;
BEGIN
  SELECT count(*) INTO v_staff
  FROM private.exam_prep_staff_roles
  WHERE role_code in ('mentor','lead_mentor','academic_moderator')
    AND role_status='active'
    AND valid_from<=now()
    AND (valid_until is null OR valid_until>now());
  SELECT count(*) INTO v_assign
  FROM private.exam_prep_mentor_assignments
  WHERE assignment_status='active'
    AND valid_from<=now()
    AND (valid_until is null OR valid_until>now());
  IF v_staff<>0 OR v_assign<>0 THEN
    RAISE EXCEPTION 'P0-16 hold-point fixture expects zero mentor capacity staff=% assignments=%',v_staff,v_assign;
  END IF;
END
$$;

SET LOCAL ROLE service_role;
SELECT public.stage_exam_prep_controlled_beta_v1(
  'math_as_p1_p5_beta_hold_01',12::smallint,
  'P0-16 current-schema GO WITH HOLD POINT: capacity 12, actual roster 6, Core canary first.'
);

-- Actual roster is only 6 of 12 seats: 4 Core + 1 future AI + 1 future Mentor Care.
-- Wave 1 = four Core only. Optional modes stay dark in this test.
SELECT public.set_exam_prep_beta_member_v1(
  'math_as_p1_p5_beta_hold_01',p.user_id,
  CASE WHEN p.ord<=4 THEN 'core' WHEN p.ord=5 THEN 'ai_assist' ELSE 'mentor_care' END,
  CASE WHEN p.ord<=4 THEN 1::smallint ELSE 3::smallint END
)
FROM p016h_people p
ORDER BY p.ord;

SELECT public.approve_exam_prep_controlled_beta_v1('math_as_p1_p5_beta_hold_01');
RESET ROLE;

-- Approval is allowlist only; underfilled capacity must not manufacture entitlements.
DO $$
DECLARE v_cfg record; v_total int; v_core int; v_ai int; v_mentor int; v_ent int; v_capacity int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 hold-point approval changed feature config: %',row_to_json(v_cfg);
  END IF;

  SELECT c.planned_size,
         count(*),
         count(*) filter(where m.service_mode='core'),
         count(*) filter(where m.service_mode='ai_assist'),
         count(*) filter(where m.service_mode='mentor_care')
  INTO v_capacity,v_total,v_core,v_ai,v_mentor
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_hold_01' AND m.member_status='approved'
  GROUP BY c.planned_size;
  IF v_capacity<>12 OR v_total<>6 OR v_core<>4 OR v_ai<>1 OR v_mentor<>1 THEN
    RAISE EXCEPTION 'P0-16 hold-point underfilled approval mismatch capacity=% total=% core=% ai=% mentor=%',v_capacity,v_total,v_core,v_ai,v_mentor;
  END IF;

  SELECT count(*) INTO v_ent
  FROM private.exam_prep_feature_entitlements e
  JOIN p016h_people p ON p.user_id=e.user_id
  WHERE e.entitlement_status='active';
  IF v_ent<>0 THEN RAISE EXCEPTION 'P0-16 hold-point approval leaked % active entitlements',v_ent; END IF;
END
$$;

SET LOCAL ROLE service_role;
SELECT public.activate_exam_prep_controlled_beta_wave_v1('math_as_p1_p5_beta_hold_01',1::smallint);
RESET ROLE;

DO $$
DECLARE v_cfg record; v_active int; v_core_active int; v_ai_active int; v_mentor_active int; v_waiting int; v_dark int; v_monitor jsonb;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta' OR v_cfg.kill_switch OR NOT v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled THEN
    RAISE EXCEPTION 'P0-16 hold-point Core canary config mismatch: %',row_to_json(v_cfg);
  END IF;

  SELECT count(*) filter(where m.member_status='active'),
         count(*) filter(where m.member_status='active' and m.service_mode='core'),
         count(*) filter(where m.member_status='active' and m.service_mode='ai_assist'),
         count(*) filter(where m.member_status='active' and m.service_mode='mentor_care'),
         count(*) filter(where m.member_status='approved')
  INTO v_active,v_core_active,v_ai_active,v_mentor_active,v_waiting
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_hold_01';

  IF v_active<>4 OR v_core_active<>4 OR v_ai_active<>0 OR v_mentor_active<>0 OR v_waiting<>2 THEN
    RAISE EXCEPTION 'P0-16 hold-point canary member state mismatch active=% core=% ai=% mentor=% waiting=%',v_active,v_core_active,v_ai_active,v_mentor_active,v_waiting;
  END IF;

  SELECT count(*) INTO v_dark
  FROM private.exam_prep_feature_entitlements e
  JOIN p016h_people p ON p.user_id=e.user_id
  WHERE p.ord between 5 and 6
    AND e.entitlement_status='active'
    AND (e.core_access OR e.ai_assist OR e.mentor_care_entitled);
  IF v_dark<>0 THEN RAISE EXCEPTION 'P0-16 hold-point future optional members leaked % live entitlements',v_dark; END IF;

  SELECT public.get_exam_prep_controlled_beta_monitor_v1('math_as_p1_p5_beta_hold_01') INTO v_monitor;
  IF coalesce((v_monitor->>'runway_green')::boolean,false) IS NOT TRUE
     OR (v_monitor#>>'{member_counts,active}')::int<>4
     OR (v_monitor#>>'{active_service_mix,core}')::int<>4
     OR (v_monitor#>>'{active_service_mix,ai_assist}')::int<>0
     OR (v_monitor#>>'{active_service_mix,mentor_care}')::int<>0
     OR (v_monitor#>>'{integrity,entitlement_mismatches}')::int<>0
     OR (v_monitor#>>'{integrity,mentor_readiness_violations}')::int<>0
     OR (v_monitor#>>'{integrity,queue_leakage}')::int<>0 THEN
    RAISE EXCEPTION 'P0-16 hold-point monitor not green: %',v_monitor;
  END IF;
END
$$;

SET LOCAL ROLE service_role;
SELECT public.pause_exam_prep_controlled_beta_v1(
  'math_as_p1_p5_beta_hold_01',
  'P0-16 hold-point isolated rollback verification'
);
RESET ROLE;

DO $$
DECLARE v_cfg record; v_ent int; v_active int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 hold-point pause did not restore fail-closed config: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_ent
  FROM private.exam_prep_feature_entitlements e
  JOIN p016h_people p ON p.user_id=e.user_id
  WHERE e.entitlement_status='active';
  IF v_ent<>0 THEN RAISE EXCEPTION 'P0-16 hold-point pause left % active entitlements',v_ent; END IF;
  SELECT count(*) INTO v_active
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_hold_01' AND m.member_status='active';
  IF v_active<>0 THEN RAISE EXCEPTION 'P0-16 hold-point pause left % active members',v_active; END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_cfg record; v_users int; v_cohorts int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 hold-point post-rollback config not fail-closed: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_users FROM auth.users WHERE email like 'p016h-%@invalid.example';
  SELECT count(*) INTO v_cohorts FROM private.exam_prep_beta_cohorts WHERE cohort_key='math_as_p1_p5_beta_hold_01';
  IF v_users<>0 OR v_cohorts<>0 THEN
    RAISE EXCEPTION 'P0-16 hold-point synthetic residue users=% cohorts=%',v_users,v_cohorts;
  END IF;
END
$$;

\echo 'P0-16 Mentor Care hold-point matrix: GREEN (capacity 12, actual cohort 6)'
