\set ON_ERROR_STOP on

DO $gate$
BEGIN
  IF current_setting('global_ai.generation_isolated',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'GLOBAL AI GENERATION REFUSED: global_ai.generation_isolated=true is required';
  END IF;
END
$gate$;

BEGIN;

ALTER TABLE public.tour_attempts
  ADD COLUMN IF NOT EXISTS user_id uuid,
  ADD COLUMN IF NOT EXISTS status text;

CREATE OR REPLACE FUNCTION private.exam_prep_has_active_protected_assessment_v1(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $assessment$
  SELECT false;
$assessment$;

CREATE TEMP TABLE gai_generation_people(
  person_key text primary key,
  user_id uuid not null
) ON COMMIT DROP;

DO $people$
DECLARE
  k text;
  uid uuid;
BEGIN
  FOREACH k IN ARRAY ARRAY['free','plus','pro','normal'] LOOP
    uid:=gen_random_uuid();
    INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
    VALUES(
      uid,'authenticated','authenticated',
      'global-ai-generation-'||k||'-'||replace(uid::text,'-','')||'@invalid.example',
      now(),now(),false,false
    );

    INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
    VALUES(uid,'GlobalAI','Generation '||k,'en',now(),false);

    INSERT INTO gai_generation_people VALUES(k,uid);
  END LOOP;
END
$people$;

DO $canaries$
DECLARE
  v jsonb;
  uid uuid;
BEGIN
  SELECT user_id INTO uid FROM gai_generation_people WHERE person_key='free';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'free','generation-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free canary setup failed: %',v;
  END IF;

  SELECT user_id INTO uid FROM gai_generation_people WHERE person_key='plus';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'plus','generation-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus canary setup failed: %',v;
  END IF;

  SELECT user_id INTO uid FROM gai_generation_people WHERE person_key='pro';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'pro','generation-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pro canary setup failed: %',v;
  END IF;
END
$canaries$;

-- Runtime remains closed by default even for a paid canary.
DO $dormant$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_generation_people WHERE person_key='plus');
BEGIN
  v:=public.reserve_iclub_global_ai_provider_call_service_v1(
    gen_random_uuid(),uid,'mathematics','exam_prep','math_exam_prep_v1',0.001
  );

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'generation_disabled' THEN
    RAISE EXCEPTION 'Dormant generation provider unexpectedly opened: %',v;
  END IF;

  IF EXISTS(select 1 from private.iclub_global_ai_provider_leases) THEN
    RAISE EXCEPTION 'Dormant provider guard wrote a lease';
  END IF;
END
$dormant$;

UPDATE private.iclub_global_ai_runtime_config
SET ui_enabled=true,
    gateway_enabled=true,
    generation_enabled=true,
    kill_switch=false,
    global_ai_rollout_mode='canary',
    updated_at=now()
WHERE id=1;

-- Free remains prepared-only; normal non-canary users cannot bypass rollout.
DO $commercial_gates$
DECLARE
  v jsonb;
  uid uuid;
BEGIN
  SELECT user_id INTO uid FROM gai_generation_people WHERE person_key='free';
  v:=public.reserve_iclub_global_ai_provider_call_service_v1(
    gen_random_uuid(),uid,'mathematics','exam_prep','math_exam_prep_v1',0.001
  );
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'generation_upgrade_required' THEN
    RAISE EXCEPTION 'Free canary reached generated provider: %',v;
  END IF;

  SELECT user_id INTO uid FROM gai_generation_people WHERE person_key='normal';
  v:=public.reserve_iclub_global_ai_provider_call_service_v1(
    gen_random_uuid(),uid,'mathematics','exam_prep','math_exam_prep_v1',0.001
  );
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'rollout_unavailable' THEN
    RAISE EXCEPTION 'Non-canary user bypassed provider rollout: %',v;
  END IF;
END
$commercial_gates$;

-- Plus canary may reserve only the reviewed Math Exam Prep adapter.
DO $plus_path$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_generation_people WHERE person_key='plus');
  rid uuid:=gen_random_uuid();
BEGIN
  v:=public.reserve_iclub_global_ai_provider_call_service_v1(
    rid,uid,'mathematics','exam_prep','math_exam_prep_v1',0.001
  );

  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus Math provider reservation failed: %',v;
  END IF;

  v:=public.reserve_iclub_global_ai_provider_call_service_v1(
    rid,uid,'mathematics','exam_prep','math_exam_prep_v1',0.001
  );
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'duplicate_request' THEN
    RAISE EXCEPTION 'Provider request idempotency guard failed: %',v;
  END IF;

  v:=public.finalize_iclub_global_ai_provider_call_service_v1(rid,'released',0);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE
     OR v->>'status'<>'released' THEN
    RAISE EXCEPTION 'Provider release failed: %',v;
  END IF;
END
$plus_path$;

-- Unsupported academic scope cannot borrow the Math provider adapter.
DO $adapter_boundary$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_generation_people WHERE person_key='plus');
BEGIN
  v:=public.reserve_iclub_global_ai_provider_call_service_v1(
    gen_random_uuid(),uid,'mathematics','global','math_exam_prep_v1',0.001
  );
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'subject_generation_not_ready' THEN
    RAISE EXCEPTION 'Unsupported scope reached provider budget: %',v;
  END IF;

  v:=public.reserve_iclub_global_ai_provider_call_service_v1(
    gen_random_uuid(),uid,'chemistry','global','math_exam_prep_v1',0.001
  );
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'subject_generation_not_ready' THEN
    RAISE EXCEPTION 'Unsupported subject reached provider budget: %',v;
  END IF;
END
$adapter_boundary$;

-- Per-request provider cost ceiling is independent from tariff usage accounting.
DO $cost_ceiling$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_generation_people WHERE person_key='plus');
BEGIN
  v:=public.reserve_iclub_global_ai_provider_call_service_v1(
    gen_random_uuid(),uid,'mathematics','exam_prep','math_exam_prep_v1',0.011
  );
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'request_cost_limit' THEN
    RAISE EXCEPTION 'Provider request-cost ceiling failed: %',v;
  END IF;
END
$cost_ceiling$;

-- Global concurrency is atomically capped.
DO $concurrency$
DECLARE
  v jsonb;
  plus_uid uuid:=(SELECT user_id FROM gai_generation_people WHERE person_key='plus');
  pro_uid uuid:=(SELECT user_id FROM gai_generation_people WHERE person_key='pro');
  r1 uuid:=gen_random_uuid();
  r2 uuid:=gen_random_uuid();
  r3 uuid:=gen_random_uuid();
BEGIN
  v:=public.reserve_iclub_global_ai_provider_call_service_v1(
    r1,plus_uid,'mathematics','exam_prep','math_exam_prep_v1',0.001
  );
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'First concurrent lease failed: %',v;
  END IF;

  v:=public.reserve_iclub_global_ai_provider_call_service_v1(
    r2,pro_uid,'mathematics','exam_prep','math_exam_prep_v1',0.001
  );
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Second concurrent lease failed: %',v;
  END IF;

  v:=public.reserve_iclub_global_ai_provider_call_service_v1(
    r3,plus_uid,'mathematics','exam_prep','math_exam_prep_v1',0.001
  );
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'provider_concurrency_limit' THEN
    RAISE EXCEPTION 'Third concurrent provider call was not blocked: %',v;
  END IF;

  PERFORM public.finalize_iclub_global_ai_provider_call_service_v1(r1,'released',0);
  PERFORM public.finalize_iclub_global_ai_provider_call_service_v1(r2,'released',0);
END
$concurrency$;

-- A protected assessment wins even after generation is globally enabled.
CREATE OR REPLACE FUNCTION private.exam_prep_has_active_protected_assessment_v1(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $assessment_on$
  SELECT p_user_id=(SELECT user_id FROM gai_generation_people WHERE person_key='plus');
$assessment_on$;

DO $assessment_guard$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_generation_people WHERE person_key='plus');
BEGIN
  v:=public.reserve_iclub_global_ai_provider_call_service_v1(
    gen_random_uuid(),uid,'mathematics','exam_prep','math_exam_prep_v1',0.001
  );

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'active_assessment' THEN
    RAISE EXCEPTION 'Protected assessment did not block provider reservation: %',v;
  END IF;
END
$assessment_guard$;

CREATE OR REPLACE FUNCTION private.exam_prep_has_active_protected_assessment_v1(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $assessment_off$
  SELECT false;
$assessment_off$;

-- Provider telemetry audit is private and records no raw learner message.
DO $audit$
DECLARE
  ok boolean;
  uid uuid:=(SELECT user_id FROM gai_generation_people WHERE person_key='pro');
  rid uuid:=gen_random_uuid();
BEGIN
  ok:=public.record_iclub_global_ai_gateway_audit_service_v2(
    rid,uid,'mathematics','exam_prep','freeform_question','generated','generated',
    null,'math_exam_prep_v1','global_ai_gateway_policy_v1',123,'deadbeef',
    ARRAY['source:test:v1'],ARRAY[]::text[],'openai','gpt-5.6-luna',321,120,0.000321
  );

  IF ok IS NOT TRUE THEN
    RAISE EXCEPTION 'Generated audit insert failed';
  END IF;

  IF NOT EXISTS(
    select 1
    from private.iclub_global_ai_gateway_audit
    where request_id=rid
      and mode='generated'
      and model_provider='openai'
      and model_id='gpt-5.6-luna'
      and input_tokens=321
      and output_tokens=120
      and estimated_cost_usd=0.000321
      and source_card_keys=ARRAY['source:test:v1']::text[]
  ) THEN
    RAISE EXCEPTION 'Generated audit telemetry mismatch';
  END IF;
END
$audit$;

DO $permissions$
BEGIN
  IF has_table_privilege('authenticated','private.iclub_global_ai_provider_policy','SELECT')
     OR has_table_privilege('authenticated','private.iclub_global_ai_provider_leases','SELECT')
     OR has_table_privilege('anon','private.iclub_global_ai_provider_leases','SELECT') THEN
    RAISE EXCEPTION 'Global AI provider budget became browser-readable';
  END IF;

  IF has_function_privilege(
       'authenticated',
       'public.reserve_iclub_global_ai_provider_call_service_v1(uuid,uuid,text,text,text,numeric)',
       'EXECUTE'
     )
     OR has_function_privilege(
       'anon',
       'public.reserve_iclub_global_ai_provider_call_service_v1(uuid,uuid,text,text,text,numeric)',
       'EXECUTE'
     )
     OR has_function_privilege(
       'authenticated',
       'public.finalize_iclub_global_ai_provider_call_service_v1(uuid,text,numeric)',
       'EXECUTE'
     )
     OR has_function_privilege(
       'authenticated',
       'public.record_iclub_global_ai_gateway_audit_service_v2(uuid,uuid,text,text,text,text,text,text,text,text,integer,text,text[],text[],text,text,integer,integer,numeric)',
       'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'Global AI provider service functions became browser-executable';
  END IF;
END
$permissions$;

UPDATE private.iclub_global_ai_runtime_config
SET ui_enabled=false,
    gateway_enabled=false,
    generation_enabled=false,
    kill_switch=true,
    global_ai_rollout_mode='off',
    updated_at=now()
WHERE id=1;

ROLLBACK;

DO $cleanup$
DECLARE
  c integer;
BEGIN
  SELECT count(*) INTO c
  FROM auth.users
  WHERE email like 'global-ai-generation-%@invalid.example';

  IF c<>0 THEN
    RAISE EXCEPTION 'Generation matrix rollback left synthetic users=%',c;
  END IF;

  SELECT count(*) INTO c
  FROM private.iclub_global_ai_provider_leases;

  IF c<>0 THEN
    RAISE EXCEPTION 'Generation matrix rollback left provider leases=%',c;
  END IF;
END
$cleanup$;

\echo 'Global AI generated Mathematics adapter v1 SQL matrix: GREEN'
