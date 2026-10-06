\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('global_ai.gateway_isolated', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'GLOBAL AI GATEWAY REFUSED: global_ai.gateway_isolated=true is required.';
  END IF;
END
$$;

BEGIN;

-- Extend the minimal CI Tour fixture so the global protected-assessment guard
-- can exercise the same production contract used by Practice AI.
ALTER TABLE public.tour_attempts
  ADD COLUMN IF NOT EXISTS user_id uuid,
  ADD COLUMN IF NOT EXISTS status text;

CREATE OR REPLACE FUNCTION private.exam_prep_has_active_protected_assessment_v1(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT false;
$$;

CREATE TEMP TABLE gai_gateway_people(
  person_key text primary key,
  user_id uuid not null
) ON COMMIT DROP;

DO $$
DECLARE
  k text;
  uid uuid;
BEGIN
  FOREACH k IN ARRAY ARRAY['free','plus','pro','unassigned','exam'] LOOP
    uid:=gen_random_uuid();
    INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
    VALUES(uid,'authenticated','authenticated','global-ai-gateway-'||k||'-'||replace(uid::text,'-','')||'@invalid.example',now(),now(),false,false);
    INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
    VALUES(uid,'GlobalAI','Gateway '||k,'en',now(),false);
    INSERT INTO gai_gateway_people VALUES(k,uid);
  END LOOP;

  INSERT INTO private.iclub_subscription_entitlements(
    user_id,plan_code,entitlement_status,entitlement_source,valid_from
  )
  SELECT user_id,'free','active','gateway-ci',now()-interval '1 minute'
  FROM gai_gateway_people WHERE person_key='free';

  INSERT INTO private.iclub_subscription_entitlements(
    user_id,plan_code,entitlement_status,entitlement_source,valid_from
  )
  SELECT user_id,'plus','active','gateway-ci',now()-interval '1 minute'
  FROM gai_gateway_people WHERE person_key in ('plus','exam');

  INSERT INTO private.iclub_subscription_entitlements(
    user_id,plan_code,entitlement_status,entitlement_source,valid_from
  )
  SELECT user_id,'pro','active','gateway-ci',now()-interval '1 minute'
  FROM gai_gateway_people WHERE person_key='pro';
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_gateway_people WHERE person_key='free');
BEGIN
  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'mathematics','exam_prep','topic_explanation','prepared','en',0
  );

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'gateway_disabled' THEN
    RAISE EXCEPTION 'Dormant gateway did not fail closed: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_gateway_people WHERE person_key='unassigned');
BEGIN
  UPDATE private.iclub_global_ai_runtime_config
  SET gateway_enabled=true,
      generation_enabled=false,
      kill_switch=false,
      updated_at=now()
  WHERE id=1;

  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'mathematics','exam_prep','topic_explanation','prepared','en',0
  );

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'subscription_unassigned' THEN
    RAISE EXCEPTION 'Unassigned subscription did not fail closed: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_gateway_people WHERE person_key='free');
BEGIN
  v:=public.get_iclub_subscription_capabilities_service_v1(uid);

  IF coalesce((v->>'resolved')::boolean,false) IS NOT TRUE
     OR v->>'plan_code'<>'free'
     OR v->>'ai_usage_policy_code'<>'free_v1'
     OR coalesce((v->>'ai_generation_entitled')::boolean,true) IS NOT FALSE THEN
    RAISE EXCEPTION 'Free capabilities mismatch: %',v;
  END IF;

  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'mathematics','exam_prep','topic_explanation','prepared','en',0
  );

  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'ai_usage_policy_code'<>'free_v1'
     OR v->>'adapter_code'<>'math_exam_prep_v1' THEN
    RAISE EXCEPTION 'Free prepared Mathematics route should be allowed: %',v;
  END IF;

  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'mathematics','exam_prep','freeform_question','generated','en',20
  );

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'generation_disabled' THEN
    RAISE EXCEPTION 'Free learner was upsold while generation runtime was unavailable: %',v;
  END IF;
END
$;

DO $
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_gateway_people WHERE person_key='plus');
BEGIN
  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'mathematics','exam_prep','freeform_question','generated','en',20
  );

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'generation_disabled' THEN
    RAISE EXCEPTION 'Plus generated route ignored runtime generation OFF: %',v;
  END IF;

  UPDATE private.iclub_global_ai_runtime_config
  SET generation_enabled=true,
      updated_at=now()
  WHERE id=1;

  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'mathematics','exam_prep','freeform_question','generated','en',20
  );

  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'ai_usage_policy_code'<>'plus_v1'
     OR v->>'adapter_code'<>'math_exam_prep_v1' THEN
    RAISE EXCEPTION 'Plus generated route should pass gateway policy: %',v;
  END IF;
END
$;

DO $
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_gateway_people WHERE person_key='free');
BEGIN
  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'mathematics','exam_prep','freeform_question','generated','en',20
  );

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'generation_upgrade_required' THEN
    RAISE EXCEPTION 'Free generated route was not upgrade-gated when paid generation was actually available: %',v;
  END IF;
END
$;

DO $
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_gateway_people WHERE person_key='pro');
BEGIN
  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'mathematics','exam_prep','freeform_question','generated','ru',100
  );

  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'ai_usage_policy_code'<>'pro_v1' THEN
    RAISE EXCEPTION 'Pro generated route should pass gateway policy: %',v;
  END IF;
END
$$;

-- Safety ordering: active protected assessment must win before subject readiness.
DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_gateway_people WHERE person_key='exam');
BEGIN
  INSERT INTO public.tour_attempts(user_id,status)
  VALUES(uid,'in_progress');

  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'chemistry','global','freeform_question','generated','en',10
  );

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'active_assessment'
     OR v->>'mode'<>'blocked' THEN
    RAISE EXCEPTION 'Protected assessment was not evaluated before subject readiness: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_gateway_people WHERE person_key='plus');
BEGIN
  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'chemistry','global','freeform_question','generated','en',10
  );

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'subject_not_ready' THEN
    RAISE EXCEPTION 'Unsupported academic subject did not fail safely: %',v;
  END IF;

  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'chemistry','global','app_help','prepared','en',0
  );

  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'BASIC subject should still allow prepared app-help policy: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  uid uuid:=(SELECT user_id FROM gai_gateway_people WHERE person_key='plus');
  inserted boolean;
  c integer;
BEGIN
  inserted:=public.record_iclub_global_ai_gateway_audit_service_v1(
    gen_random_uuid(),uid,'mathematics','exam_prep','topic_explanation','prepared',
    'prepared',null,'math_exam_prep_v1','global_ai_gateway_policy_v1',12,'abc123'
  );

  IF inserted IS NOT TRUE THEN
    RAISE EXCEPTION 'Gateway audit insert failed';
  END IF;

  SELECT count(*) INTO c
  FROM private.iclub_global_ai_gateway_audit
  WHERE user_id=uid
    AND mode='prepared';

  IF c<>1 THEN
    RAISE EXCEPTION 'Gateway audit row mismatch=%',c;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='private'
      AND table_name='iclub_global_ai_gateway_audit'
      AND column_name in ('user_text','message','prompt','response_text','raw_chat')
  ) THEN
    RAISE EXCEPTION 'Gateway audit unexpectedly stores raw conversation text';
  END IF;
END
$$;

DO $$
BEGIN
  IF has_table_privilege('authenticated','private.iclub_global_ai_gateway_policy','SELECT')
     OR has_table_privilege('authenticated','private.iclub_global_ai_gateway_audit','SELECT')
     OR has_table_privilege('anon','private.iclub_global_ai_gateway_audit','SELECT') THEN
    RAISE EXCEPTION 'Global AI gateway private storage became browser-readable';
  END IF;

  IF has_function_privilege(
       'authenticated',
       'public.get_iclub_global_ai_guard_service_v1(uuid,text,text,text,text,text,integer)',
       'EXECUTE'
     )
     OR has_function_privilege(
       'authenticated',
       'public.get_iclub_subscription_capabilities_service_v1(uuid)',
       'EXECUTE'
     )
     OR has_function_privilege(
       'anon',
       'public.get_iclub_global_ai_guard_service_v1(uuid,text,text,text,text,text,integer)',
       'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'Global AI gateway service RPC became browser-executable';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE
  c integer;
BEGIN
  SELECT count(*) INTO c
  FROM auth.users
  WHERE email like 'global-ai-gateway-%@invalid.example';

  IF c<>0 THEN
    RAISE EXCEPTION 'Gateway matrix rollback left synthetic users=%',c;
  END IF;

  SELECT count(*) INTO c
  FROM private.iclub_global_ai_gateway_audit;

  IF c<>0 THEN
    RAISE EXCEPTION 'Gateway matrix rollback left audit rows=%',c;
  END IF;
END
$$;

\echo 'Global AI gateway foundation v1 matrix: GREEN'