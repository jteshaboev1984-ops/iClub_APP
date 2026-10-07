\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('global_ai.math_adapter_isolated', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'GLOBAL AI MATH ADAPTER REFUSED: global_ai.math_adapter_isolated=true is required.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE math_adapter_people(
  person_key text primary key,
  user_id uuid not null
) ON COMMIT DROP;

DO $people$
DECLARE
  k text;
  uid uuid;
BEGIN
  FOREACH k IN ARRAY ARRAY['free_canary','plus_canary','pro_canary','plus_normal'] LOOP
    uid:=gen_random_uuid();

    INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
    VALUES(
      uid,'authenticated','authenticated',
      'global-math-adapter-'||k||'-'||replace(uid::text,'-','')||'@invalid.example',
      now(),now(),false,false
    );

    INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
    VALUES(uid,'GlobalAI','Math Adapter '||k,'en',now(),false);

    INSERT INTO math_adapter_people VALUES(k,uid);
  END LOOP;
END
$people$;

DO $canaries$
DECLARE
  v jsonb;
  uid uuid;
BEGIN
  SELECT user_id INTO uid FROM math_adapter_people WHERE person_key='free_canary';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'free','math-adapter-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free canary setup failed: %',v;
  END IF;

  SELECT user_id INTO uid FROM math_adapter_people WHERE person_key='plus_canary';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'plus','math-adapter-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus canary setup failed: %',v;
  END IF;

  SELECT user_id INTO uid FROM math_adapter_people WHERE person_key='pro_canary';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'pro','math-adapter-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pro canary setup failed: %',v;
  END IF;
END
$canaries$;

-- Explicit Plus subscription outside the canary proves rollout remains independent
-- from commercial entitlement.
DO $paid_normal$
DECLARE
  uid uuid:=(SELECT user_id FROM math_adapter_people WHERE person_key='plus_normal');
BEGIN
  INSERT INTO private.iclub_subscription_entitlements(
    user_id,plan_code,entitlement_status,entitlement_source,valid_from
  ) VALUES(uid,'plus','active','math-adapter-ci',now()-interval '1 minute');
END
$paid_normal$;

UPDATE private.iclub_global_ai_runtime_config
SET ui_enabled=true,
    gateway_enabled=true,
    generation_enabled=true,
    kill_switch=false,
    global_ai_rollout_mode='canary',
    updated_at=now()
WHERE id=1;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',
    core_enabled=true,
    ai_enabled=true,
    mentor_enabled=false,
    kill_switch=false,
    updated_at=now()
WHERE id=1;

UPDATE private.exam_prep_ai_policy
SET generation_enabled=true,
    updated_at=now()
WHERE id=1;

INSERT INTO private.exam_prep_optional_capability_status(
  capability_code,runtime_status,gate_version,updated_at
) VALUES('ai_assist','ready','global-math-adapter-ci',now())
ON CONFLICT(capability_code) DO UPDATE
SET runtime_status='ready',
    gate_version='global-math-adapter-ci',
    updated_at=now();

-- The new interaction exists, but browser roles cannot call the user-id service context.
DO $policy$
DECLARE
  p private.exam_prep_ai_policy%rowtype;
BEGIN
  SELECT * INTO p FROM private.exam_prep_ai_policy WHERE id=1;

  IF NOT ('skill_question'=any(p.allowed_interactions)) THEN
    RAISE EXCEPTION 'skill_question missing from provider policy';
  END IF;

  IF has_function_privilege(
    'authenticated',
    'public.get_exam_prep_ai_skill_theory_context_service_v1(uuid,text,text,text)',
    'EXECUTE'
  ) OR has_function_privilege(
    'anon',
    'public.get_exam_prep_ai_skill_theory_context_service_v1(uuid,text,text,text)',
    'EXECUTE'
  ) THEN
    RAISE EXCEPTION 'Skill-question service context became browser executable';
  END IF;
END
$policy$;

-- Free canary cannot use generated Math questions.
DO $free$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM math_adapter_people WHERE person_key='free_canary');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_exam_prep_ai_guard_v1('P1','skill_question','en',40);

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'generation_upgrade_required' THEN
    RAISE EXCEPTION 'Free canary escaped Math generated guard: %',v;
  END IF;
END
$free$;

-- Plus/Pro canaries use commercial generation capability without needing a
-- legacy exam_prep_feature_entitlements row.
DO $paid_canary$
DECLARE
  v jsonb;
  uid uuid;
  k text;
BEGIN
  FOREACH k IN ARRAY ARRAY['plus_canary','pro_canary'] LOOP
    SELECT user_id INTO uid FROM math_adapter_people WHERE person_key=k;

    IF EXISTS(
      SELECT 1 FROM private.exam_prep_feature_entitlements e WHERE e.user_id=uid
    ) THEN
      RAISE EXCEPTION '% unexpectedly has a legacy Exam Prep entitlement fixture',k;
    END IF;

    PERFORM set_config('request.jwt.claim.sub',uid::text,true);
    PERFORM set_config('request.jwt.claim.role','authenticated',true);

    v:=public.get_exam_prep_ai_guard_v1('P1','skill_question','en',120);

    IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
       OR v->>'authorization_source'<>'global_commercial_ai' THEN
      RAISE EXCEPTION '% skill-question guard mismatch: %',k,v;
    END IF;
  END LOOP;
END
$paid_canary$;

-- A paid non-canary cannot bypass the controlled rollout by calling Exam Prep AI directly.
DO $noncanary$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM math_adapter_people WHERE person_key='plus_normal');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_exam_prep_ai_guard_v1('P1','skill_question','en',40);

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'rollout_unavailable' THEN
    RAISE EXCEPTION 'Paid non-canary escaped direct skill-question rollout guard: %',v;
  END IF;
END
$noncanary$;

-- Global generation kill switch applies even to Pro.
DO $runtime_off$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM math_adapter_people WHERE person_key='pro_canary');
BEGIN
  UPDATE private.iclub_global_ai_runtime_config
  SET generation_enabled=false
  WHERE id=1;

  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_exam_prep_ai_guard_v1('P5','skill_question','en',40);

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'global_generation_disabled' THEN
    RAISE EXCEPTION 'Global generation OFF did not close direct domain route: %',v;
  END IF;

  UPDATE private.iclub_global_ai_runtime_config
  SET generation_enabled=true
  WHERE id=1;
END
$runtime_off$;

-- Protected assessment remains authoritative before provider generation.
-- The isolated matrix temporarily replaces only the protected-assessment reader;
-- ROLLBACK restores the production implementation.
CREATE OR REPLACE FUNCTION private.exam_prep_has_active_protected_assessment_v1(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path=''
AS $assessment_stub$
  SELECT coalesce(
    nullif(current_setting('global_ai.math_adapter_blocked_user',true),'')::uuid = p_user_id,
    false
  );
$assessment_stub$;

DO $assessment$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM math_adapter_people WHERE person_key='pro_canary');
BEGIN
  PERFORM set_config('global_ai.math_adapter_blocked_user',uid::text,true);
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_exam_prep_ai_guard_v1('P1','skill_question','en',40);

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'active_assessment' THEN
    RAISE EXCEPTION 'Cross-component assessment blackout failed for skill question: %',v;
  END IF;

  PERFORM set_config('global_ai.math_adapter_blocked_user','',true);
END
$assessment$;

-- Existing Exam Prep AI interactions preserve their old entitlement rule.
DO $legacy_independent$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM math_adapter_people WHERE person_key='plus_canary');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_exam_prep_ai_guard_v1('P1','progress_summary','en',0);

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'core_not_available' THEN
    RAISE EXCEPTION 'New commercial path changed legacy Exam Prep AI entitlement: %',v;
  END IF;
END
$legacy_independent$;

ROLLBACK;

DO $clean$
DECLARE
  c integer;
BEGIN
  SELECT count(*) INTO c
  FROM auth.users
  WHERE email like 'global-math-adapter-%@invalid.example';

  IF c<>0 THEN
    RAISE EXCEPTION 'Math adapter matrix rollback left synthetic users=%',c;
  END IF;
END
$clean$;

\echo 'Global AI governed Math skill-question DB matrix: GREEN'