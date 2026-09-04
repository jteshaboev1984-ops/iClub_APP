-- P0-16 current-schema capacity boundary regression.
-- Test-only. Requires full P0 -> P1-03 schema and ends in ROLLBACK.
--
-- Proves:
-- 1) cohort capacity above 12 is rejected;
-- 2) a 12-seat draft cohort accepts exactly 12 candidates;
-- 3) the 13th distinct candidate is rejected by the governed RPC;
-- 4) the 13th distinct candidate is also rejected by the database-level guard;
-- 5) rejected membership creates no row, entitlement or feature-flag leakage;
-- 6) all synthetic data rolls back.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p016.current_schema',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P0-16 CAPACITY BOUNDARY REFUSED: p016.current_schema=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE p016b_people(
  ord integer PRIMARY KEY,
  user_id uuid NOT NULL UNIQUE
) ON COMMIT DROP;

INSERT INTO p016b_people(ord,user_id)
SELECT g,gen_random_uuid() FROM generate_series(1,13) g;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',
       format('p016b-%s-%s@invalid.example',ord,replace(user_id::text,'-','')),
       now(),now(),false,false
FROM p016b_people;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P016 Boundary',ord::text,'en',now(),false
FROM p016b_people;

GRANT SELECT ON TABLE p016b_people TO service_role;

SET LOCAL ROLE service_role;

-- Capacity itself is an upper bound: 13 must not even stage.
DO $$
BEGIN
  BEGIN
    PERFORM public.stage_exam_prep_controlled_beta_v1(
      'math_as_p1_p5_beta_capacity_bad13',13::smallint,
      'This cohort must never be created.'
    );
    RAISE EXCEPTION 'P0-16 boundary expected capacity=13 staging to fail';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE 'exam_prep_beta_capacity_must_be_3_to_12%' THEN
      RAISE;
    END IF;
  END;
END
$$;

SELECT public.stage_exam_prep_controlled_beta_v1(
  'math_as_p1_p5_beta_capacity_12',12::smallint,
  'P0-16 exact max-capacity regression; no activation.'
);

-- Fill all 12 seats while preserving the governed mixed-mode representation.
SELECT public.set_exam_prep_beta_member_v1(
  'math_as_p1_p5_beta_capacity_12',p.user_id,
  CASE WHEN p.ord<=4 THEN 'core' WHEN p.ord<=8 THEN 'ai_assist' ELSE 'mentor_care' END,
  1::smallint
)
FROM p016b_people p
WHERE p.ord<=12
ORDER BY p.ord;

-- The 13th candidate must be refused by the public governed mutation path.
DO $$
DECLARE v_user uuid;
BEGIN
  SELECT user_id INTO v_user FROM p016b_people WHERE ord=13;
  BEGIN
    PERFORM public.set_exam_prep_beta_member_v1(
      'math_as_p1_p5_beta_capacity_12',v_user,'core',1::smallint
    );
    RAISE EXCEPTION 'P0-16 boundary expected 13th RPC candidate to fail';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE 'exam_prep_beta_capacity_reached:%' THEN
      RAISE;
    END IF;
  END;
END
$$;

-- Defense in depth: service_role direct table INSERT must not bypass the same cap.
DO $$
DECLARE v_user uuid; v_cohort bigint;
BEGIN
  SELECT user_id INTO v_user FROM p016b_people WHERE ord=13;
  SELECT id INTO v_cohort
  FROM private.exam_prep_beta_cohorts
  WHERE cohort_key='math_as_p1_p5_beta_capacity_12';

  BEGIN
    INSERT INTO private.exam_prep_beta_members(
      cohort_id,user_id,service_mode,activation_wave,member_status
    ) VALUES (v_cohort,v_user,'core',1,'candidate');
    RAISE EXCEPTION 'P0-16 boundary expected 13th direct candidate to fail';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE 'exam_prep_beta_capacity_reached_db:%' THEN
      RAISE;
    END IF;
  END;
END
$$;

RESET ROLE;

DO $$
DECLARE
  v_cfg record;
  v_capacity int;
  v_members int;
  v_13th_rows int;
  v_13th_entitlements int;
  v_bad_cohort int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 capacity boundary changed feature config: %',row_to_json(v_cfg);
  END IF;

  SELECT c.planned_size,count(m.*)
  INTO v_capacity,v_members
  FROM private.exam_prep_beta_cohorts c
  LEFT JOIN private.exam_prep_beta_members m ON m.cohort_id=c.id AND m.member_status<>'removed'
  WHERE c.cohort_key='math_as_p1_p5_beta_capacity_12'
  GROUP BY c.planned_size;
  IF v_capacity<>12 OR v_members<>12 THEN
    RAISE EXCEPTION 'P0-16 capacity boundary expected capacity=12 members=12, got capacity=% members=%',v_capacity,v_members;
  END IF;

  SELECT count(*) INTO v_bad_cohort
  FROM private.exam_prep_beta_cohorts
  WHERE cohort_key='math_as_p1_p5_beta_capacity_bad13';
  IF v_bad_cohort<>0 THEN
    RAISE EXCEPTION 'P0-16 capacity=13 staging left % cohort rows',v_bad_cohort;
  END IF;

  SELECT count(*) INTO v_13th_rows
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  JOIN p016b_people p ON p.user_id=m.user_id
  WHERE c.cohort_key='math_as_p1_p5_beta_capacity_12' AND p.ord=13;
  IF v_13th_rows<>0 THEN
    RAISE EXCEPTION 'P0-16 rejected 13th learner left % member rows',v_13th_rows;
  END IF;

  SELECT count(*) INTO v_13th_entitlements
  FROM private.exam_prep_feature_entitlements e
  JOIN p016b_people p ON p.user_id=e.user_id
  WHERE p.ord=13
    AND e.entitlement_status='active'
    AND (e.core_access OR e.ai_assist OR e.mentor_care_entitled);
  IF v_13th_entitlements<>0 THEN
    RAISE EXCEPTION 'P0-16 rejected 13th learner leaked % active entitlements',v_13th_entitlements;
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_cfg record; v_users int; v_cohorts int; v_members int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 capacity boundary post-rollback config not fail-closed: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_users FROM auth.users WHERE email like 'p016b-%@invalid.example';
  SELECT count(*) INTO v_cohorts FROM private.exam_prep_beta_cohorts WHERE cohort_key like 'math_as_p1_p5_beta_capacity_%';
  SELECT count(*) INTO v_members
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key like 'math_as_p1_p5_beta_capacity_%';
  IF v_users<>0 OR v_cohorts<>0 OR v_members<>0 THEN
    RAISE EXCEPTION 'P0-16 capacity boundary synthetic residue users=% cohorts=% members=%',v_users,v_cohorts,v_members;
  END IF;
END
$$;

\echo 'P0-16 capacity boundary matrix: GREEN (up to 12; 13th rejected twice)'
