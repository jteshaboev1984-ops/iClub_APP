-- P0-16 Core-first + incremental enrollment regression.
-- Test-only. Requires full current schema with learner-consent overlays and ends in ROLLBACK.
--
-- Proves:
-- 1) three consented Core learners can approve a 12-seat cohort without AI/Mentor placeholders;
-- 2) wave 1 activates Core only and leaves AI/Mentor disabled;
-- 3) a fourth learner can be added after the canary starts, consented, approved and activated in wave 2;
-- 4) a later AI candidate can be staged/approved but activation remains blocked while AI runtime is not ready;
-- 5) all synthetic state rolls back.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p016.current_schema',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P0-16 CORE-FIRST REFUSED: p016.current_schema=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE p016i_people(
  ord integer PRIMARY KEY,
  user_id uuid NOT NULL UNIQUE
) ON COMMIT DROP;

INSERT INTO p016i_people(ord,user_id)
SELECT g,gen_random_uuid() FROM generate_series(1,5) g;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',
       format('p016i-%s-%s@invalid.example',ord,replace(user_id::text,'-','')),
       now(),now(),false,false
FROM p016i_people;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P016 Incremental',ord::text,'en',now(),false
FROM p016i_people;

GRANT SELECT ON TABLE p016i_people TO service_role;

SET LOCAL ROLE service_role;

SELECT public.stage_exam_prep_controlled_beta_v1(
  'math_as_p1_p5_beta_core_first_12',12::smallint,
  'Core-first incremental regression.'
);

-- Initial three learners: Core-only, wave 1.
SELECT public.set_exam_prep_beta_member_v1(
  'math_as_p1_p5_beta_core_first_12',p.user_id,'core',1::smallint
)
FROM p016i_people p
WHERE p.ord<=3
ORDER BY p.ord;

SELECT public.record_exam_prep_beta_consent_v1(
  'math_as_p1_p5_beta_core_first_12',p.user_id,
  'test:core-first-consent-'||p.ord::text,now()
)
FROM p016i_people p
WHERE p.ord<=3
ORDER BY p.ord;

DO $$
DECLARE v jsonb;
BEGIN
  v:=public.approve_exam_prep_controlled_beta_v1('math_as_p1_p5_beta_core_first_12');
  IF v->>'approval_mode'<>'initial_core_first' OR (v->>'approved_now')::int<>3 THEN
    RAISE EXCEPTION 'P0-16 Core-first approval returned unexpected payload: %',v;
  END IF;
END
$$;

DO $$
DECLARE v jsonb;
BEGIN
  v:=public.activate_exam_prep_controlled_beta_wave_v1('math_as_p1_p5_beta_core_first_12',1::smallint);
  IF v->>'status'<>'canary' OR (v->>'active_members')::int<>3 THEN
    RAISE EXCEPTION 'P0-16 Core-first wave 1 unexpected payload: %',v;
  END IF;
END
$$;

RESET ROLE;

DO $$
DECLARE v_cfg record; v_active int; v_ai int; v_mentor int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta' OR NOT v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 Core-first wave 1 config wrong: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_active
  FROM private.exam_prep_feature_entitlements
  WHERE cohort_key='math_as_p1_p5_beta_core_first_12' AND entitlement_status='active' AND core_access;
  SELECT count(*) INTO v_ai
  FROM private.exam_prep_feature_entitlements
  WHERE cohort_key='math_as_p1_p5_beta_core_first_12' AND entitlement_status='active' AND ai_assist;
  SELECT count(*) INTO v_mentor
  FROM private.exam_prep_feature_entitlements
  WHERE cohort_key='math_as_p1_p5_beta_core_first_12' AND entitlement_status='active' AND mentor_care_entitled;
  IF v_active<>3 OR v_ai<>0 OR v_mentor<>0 THEN
    RAISE EXCEPTION 'P0-16 Core-first entitlement isolation wrong active=% ai=% mentor=%',v_active,v_ai,v_mentor;
  END IF;
END
$$;

SET LOCAL ROLE service_role;

-- Add a fourth Core learner after wave 1. Must be future wave.
SELECT public.set_exam_prep_beta_member_v1(
  'math_as_p1_p5_beta_core_first_12',(SELECT user_id FROM p016i_people WHERE ord=4),'core',2::smallint
);
SELECT public.record_exam_prep_beta_consent_v1(
  'math_as_p1_p5_beta_core_first_12',(SELECT user_id FROM p016i_people WHERE ord=4),
  'test:incremental-core-consent-4',now()
);

DO $$
DECLARE v jsonb;
BEGIN
  v:=public.approve_exam_prep_controlled_beta_v1('math_as_p1_p5_beta_core_first_12');
  IF v->>'approval_mode'<>'incremental' OR (v->>'approved_now')::int<>1 THEN
    RAISE EXCEPTION 'P0-16 incremental approval returned unexpected payload: %',v;
  END IF;
END
$$;

DO $$
DECLARE v jsonb;
BEGIN
  v:=public.activate_exam_prep_controlled_beta_wave_v1('math_as_p1_p5_beta_core_first_12',2::smallint);
  IF (v->>'active_members')::int<>4 THEN
    RAISE EXCEPTION 'P0-16 incremental Core wave 2 unexpected payload: %',v;
  END IF;
END
$$;

-- Add an AI candidate for wave 3. Approval is allowed; activation must remain blocked.
SELECT public.set_exam_prep_beta_member_v1(
  'math_as_p1_p5_beta_core_first_12',(SELECT user_id FROM p016i_people WHERE ord=5),'ai_assist',3::smallint
);
SELECT public.record_exam_prep_beta_consent_v1(
  'math_as_p1_p5_beta_core_first_12',(SELECT user_id FROM p016i_people WHERE ord=5),
  'test:incremental-ai-consent-5',now()
);
SELECT public.approve_exam_prep_controlled_beta_v1('math_as_p1_p5_beta_core_first_12');

DO $$
BEGIN
  BEGIN
    PERFORM public.activate_exam_prep_controlled_beta_wave_v1('math_as_p1_p5_beta_core_first_12',3::smallint);
    RAISE EXCEPTION 'P0-16 expected AI wave 3 to remain blocked while runtime is not ready';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE 'exam_prep_beta_ai_runtime_not_ready%' THEN
      RAISE;
    END IF;
  END;
END
$$;

RESET ROLE;

DO $$
DECLARE v_active int; v_ai_active int; v_ai_member text; v_cohort_status text; v_wave int;
BEGIN
  SELECT count(*) INTO v_active
  FROM private.exam_prep_feature_entitlements
  WHERE cohort_key='math_as_p1_p5_beta_core_first_12' AND entitlement_status='active';
  SELECT count(*) INTO v_ai_active
  FROM private.exam_prep_feature_entitlements
  WHERE cohort_key='math_as_p1_p5_beta_core_first_12' AND entitlement_status='active' AND ai_assist;
  SELECT m.member_status INTO v_ai_member
  FROM private.exam_prep_beta_members m
  JOIN p016i_people p ON p.user_id=m.user_id
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_core_first_12' AND p.ord=5;
  SELECT cohort_status,current_wave INTO v_cohort_status,v_wave
  FROM private.exam_prep_beta_cohorts
  WHERE cohort_key='math_as_p1_p5_beta_core_first_12';
  IF v_active<>4 OR v_ai_active<>0 OR v_ai_member<>'approved' OR v_cohort_status<>'canary' OR v_wave<>2 THEN
    RAISE EXCEPTION 'P0-16 AI hold point leaked state active=% ai_active=% ai_member=% status=% wave=%',v_active,v_ai_active,v_ai_member,v_cohort_status,v_wave;
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_cfg record; v_users int; v_cohorts int; v_members int; v_consents int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 Core-first post-rollback config not fail-closed: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_users FROM auth.users WHERE email like 'p016i-%@invalid.example';
  SELECT count(*) INTO v_cohorts FROM private.exam_prep_beta_cohorts WHERE cohort_key='math_as_p1_p5_beta_core_first_12';
  SELECT count(*) INTO v_members
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_core_first_12';
  SELECT count(*) INTO v_consents
  FROM private.exam_prep_beta_consents c
  JOIN private.exam_prep_beta_cohorts b ON b.id=c.cohort_id
  WHERE b.cohort_key='math_as_p1_p5_beta_core_first_12';
  IF v_users<>0 OR v_cohorts<>0 OR v_members<>0 OR v_consents<>0 THEN
    RAISE EXCEPTION 'P0-16 Core-first synthetic residue users=% cohorts=% members=% consents=%',v_users,v_cohorts,v_members,v_consents;
  END IF;
END
$$;

\echo 'P0-16 Core-first incremental matrix: GREEN (3 Core start; add later; AI still held)'
