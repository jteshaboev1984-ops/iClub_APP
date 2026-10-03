\set ON_ERROR_STOP on

DO $$ BEGIN
  IF current_setting('p302.ai_real_canary_isolated',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P3-02 AI REAL CANARY TEST REFUSED: isolated database required';
  END IF;
END $$;

BEGIN;

CREATE TEMP TABLE p302_ai_canary_people(
  ord integer primary key,
  user_id uuid not null unique
) ON COMMIT DROP;

INSERT INTO p302_ai_canary_people(ord,user_id) VALUES
  (1,gen_random_uuid()),
  (2,gen_random_uuid()),
  (3,gen_random_uuid());

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',
       'p302-ai-real-canary-'||ord||'@invalid.example',now(),now(),false,false
FROM p302_ai_canary_people;

INSERT INTO public.users(id,first_name,created_at,must_change_password)
SELECT user_id,'P302 AI Canary',now(),false
FROM p302_ai_canary_people;

INSERT INTO private.exam_prep_beta_cohorts(
  cohort_key,program_key,cohort_status,planned_size,current_wave,monitoring_hours,notes,
  approved_at,started_at
) VALUES(
  'math_as_p1_p5_beta_2026_09_01','math_as_p1_p5','canary',12,1,72,
  'isolated three-learner AI Assist activation fixture',now(),now()
);

INSERT INTO private.exam_prep_beta_members(
  cohort_id,user_id,service_mode,activation_wave,member_status
)
SELECT c.id,p.user_id,'core',1,'candidate'
FROM private.exam_prep_beta_cohorts c
CROSS JOIN p302_ai_canary_people p
WHERE c.cohort_key='math_as_p1_p5_beta_2026_09_01';

INSERT INTO private.exam_prep_beta_consents(
  cohort_id,user_id,consent_scope,consent_status,consented_at,grant_evidence_ref
)
SELECT c.id,p.user_id,'exam_prep_controlled_beta_v1','granted',now(),
       'isolated:p302-ai-real-canary:'||p.ord
FROM private.exam_prep_beta_cohorts c
CROSS JOIN p302_ai_canary_people p
WHERE c.cohort_key='math_as_p1_p5_beta_2026_09_01';

UPDATE private.exam_prep_beta_members bm
SET member_status='active',activated_at=now(),updated_at=now()
FROM private.exam_prep_beta_cohorts c,p302_ai_canary_people p
WHERE bm.cohort_id=c.id
  AND bm.user_id=p.user_id
  AND c.cohort_key='math_as_p1_p5_beta_2026_09_01';

INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,
  cohort_key,valid_from
)
SELECT user_id,'active',true,false,false,'math_as_p1_p5_beta_2026_09_01',now()
FROM p302_ai_canary_people;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,
    mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;

UPDATE private.exam_prep_ai_policy
SET generation_enabled=false,updated_at=now()
WHERE id=1;

UPDATE private.exam_prep_optional_capability_status
SET runtime_status='shadow',gate_version=null,
    evidence=jsonb_build_object('isolated_baseline',true),updated_at=now()
WHERE capability_code='ai_assist';

\ir ../../docs/release-packages/20261003_exam_prep_ai_three_beta_canary_activation_v1.sql

DO $verify$
DECLARE
  r record;
  c record;
  v_guard jsonb;
BEGIN
  IF (SELECT count(*) FROM private.exam_prep_feature_entitlements WHERE ai_assist)<>3 THEN
    RAISE EXCEPTION 'P3-02 real canary test expected exactly three AI entitlements';
  END IF;
  IF (SELECT count(*) FROM private.exam_prep_beta_members
      WHERE member_status='active' AND service_mode='ai_assist')<>3 THEN
    RAISE EXCEPTION 'P3-02 real canary test service modes not promoted';
  END IF;
  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_feature_config
    WHERE id=1 AND rollout_state='controlled_beta'
      AND core_enabled AND ai_enabled AND NOT mentor_enabled AND NOT kill_switch
  ) THEN
    RAISE EXCEPTION 'P3-02 real canary test feature state wrong';
  END IF;
  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_optional_capability_status
    WHERE capability_code='ai_assist' AND runtime_status='ready'
      AND gate_version='p3_02_real_beta_ai_canary_v1'
  ) THEN
    RAISE EXCEPTION 'P3-02 real canary test runtime not ready';
  END IF;
  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_ai_policy WHERE id=1 AND generation_enabled
  ) THEN
    RAISE EXCEPTION 'P3-02 real canary test generation not enabled';
  END IF;

  FOR r IN SELECT user_id FROM p302_ai_canary_people ORDER BY ord
  LOOP
    PERFORM set_config('request.jwt.claim.sub',r.user_id::text,true);
    PERFORM set_config('request.jwt.claim.role','authenticated',true);

    SELECT * INTO STRICT c FROM public.get_exam_prep_capabilities_v1();
    IF NOT c.core_access OR NOT c.ai_assist OR c.mentor_care_entitled
       OR c.mentor_assignment_active OR c.mentor_authority OR c.kill_switch THEN
      RAISE EXCEPTION 'P3-02 real canary capability mismatch user=% cap=%',r.user_id,row_to_json(c);
    END IF;

    v_guard:=public.get_exam_prep_ai_guard_v1('P1','theory_explanation','en',0);
    IF coalesce((v_guard->>'allowed')::boolean,false) IS NOT TRUE
       OR v_guard->>'mode'<>'ready' THEN
      RAISE EXCEPTION 'P3-02 real canary guard not ready user=% guard=%',r.user_id,v_guard;
    END IF;
  END LOOP;

  IF (SELECT count(*) FROM private.exam_prep_audit_events
      WHERE event_type='ai_controlled_beta_canary_activated'
        AND object_id='p3_02_real_beta_ai_canary_v1')<>1 THEN
    RAISE EXCEPTION 'P3-02 real canary semantic activation audit missing';
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_audit_events
      WHERE event_type='ai_assist_entitlement_activated'
        AND target_user_id IN (SELECT user_id FROM p302_ai_canary_people))<>3 THEN
    RAISE EXCEPTION 'P3-02 real canary per-learner audit missing';
  END IF;

  IF (private.exam_prep_active_plan_transition_audit_v1()->>'hard_anomaly_count')::integer<>0 THEN
    RAISE EXCEPTION 'P3-02 real canary changed Core transition state';
  END IF;

  RAISE NOTICE 'P3-02 three-learner AI Assist canary activation: PASS';
END;
$verify$;

ROLLBACK;

DO $cleanup$
BEGIN
  IF EXISTS(SELECT 1 FROM auth.users WHERE email LIKE 'p302-ai-real-canary-%@invalid.example')
     OR EXISTS(SELECT 1 FROM public.users WHERE first_name='P302 AI Canary') THEN
    RAISE EXCEPTION 'P3-02 real canary test left fixture users';
  END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_beta_cohorts
    WHERE cohort_key='math_as_p1_p5_beta_2026_09_01'
  ) THEN
    RAISE EXCEPTION 'P3-02 real canary test left fixture cohort';
  END IF;

  IF EXISTS(SELECT 1 FROM private.exam_prep_feature_entitlements WHERE ai_assist) THEN
    RAISE EXCEPTION 'P3-02 real canary rollback left AI entitlement';
  END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_feature_config
    WHERE id=1 AND ai_enabled=false AND core_enabled=true
      AND mentor_enabled=false AND kill_switch=false
  ) THEN
    RAISE EXCEPTION 'P3-02 real canary rollback changed feature baseline';
  END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_ai_policy WHERE id=1 AND generation_enabled=false
  ) OR NOT EXISTS(
    SELECT 1 FROM private.exam_prep_optional_capability_status
    WHERE capability_code='ai_assist' AND runtime_status='shadow'
  ) THEN
    RAISE EXCEPTION 'P3-02 real canary rollback changed AI baseline';
  END IF;

  RAISE NOTICE 'P3-02 three-learner AI Assist canary rollback: PASS';
END;
$cleanup$;
