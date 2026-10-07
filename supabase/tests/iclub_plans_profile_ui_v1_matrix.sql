\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('iclub.plans_isolated', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'ICLUB PLANS REFUSED: iclub.plans_isolated=true is required.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE plan_people(
  person_key text primary key,
  user_id uuid not null
) ON COMMIT DROP;

DO $$
DECLARE
  k text;
  uid uuid;
BEGIN
  FOREACH k IN ARRAY ARRAY['free','plus','pro','unassigned'] LOOP
    uid:=gen_random_uuid();
    INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
    VALUES(uid,'authenticated','authenticated','plan-ui-'||k||'-'||replace(uid::text,'-','')||'@invalid.example',now(),now(),false,false);

    INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
    VALUES(uid,'Plan','UI '||k,'en',now(),false);

    INSERT INTO plan_people VALUES(k,uid);
  END LOOP;

  INSERT INTO private.iclub_subscription_entitlements(
    user_id,plan_code,entitlement_status,entitlement_source,valid_from
  )
  SELECT user_id,'free','active','plans-ci',now()-interval '1 minute'
  FROM plan_people WHERE person_key='free';

  INSERT INTO private.iclub_subscription_entitlements(
    user_id,plan_code,entitlement_status,entitlement_source,valid_from
  )
  SELECT user_id,'plus','active','plans-ci',now()-interval '1 minute'
  FROM plan_people WHERE person_key='plus';

  INSERT INTO private.iclub_subscription_entitlements(
    user_id,plan_code,entitlement_status,entitlement_source,valid_from
  )
  SELECT user_id,'pro','active','plans-ci',now()-interval '1 minute'
  FROM plan_people WHERE person_key='pro';
END
$$;

-- Default runtime must keep commercial UI completely dormant.
DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM plan_people WHERE person_key='free');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_plan_ui_bootstrap_v1();

  IF coalesce((v->>'visible')::boolean,true)
     OR v->>'reason'<>'plans_ui_disabled'
     OR coalesce((v->>'checkout_enabled')::boolean,true) THEN
    RAISE EXCEPTION 'Dormant plans UI did not fail closed: %',v;
  END IF;
END
$$;

-- Enable presentation only. Checkout remains OFF.
UPDATE private.iclub_global_ai_runtime_config
SET plans_ui_enabled=true,
    checkout_enabled=false,
    updated_at=now()
WHERE id=1;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM plan_people WHERE person_key='free');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_plan_ui_bootstrap_v1();

  IF coalesce((v->>'visible')::boolean,false) IS NOT TRUE
     OR v->>'current_plan_code'<>'free'
     OR coalesce((v->>'checkout_enabled')::boolean,true)
     OR v->>'ui_version'<>'iclub_plans_v1'
     OR jsonb_array_length(v->'plans')<>3 THEN
    RAISE EXCEPTION 'Free plan bootstrap mismatch: %',v;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM jsonb_array_elements(v->'plans') x
    WHERE x->>'plan_code'='free'
      AND (x->>'monthly_price_uzs')::integer=0
      AND (x->>'study_subject_limit')::integer=1
      AND (x->>'competitive_subject_limit')::integer=1
      AND coalesce((x->>'ai_generation_entitled')::boolean,true) IS NOT TRUE
  ) THEN
    RAISE EXCEPTION 'Free public plan mismatch: %',v;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM jsonb_array_elements(v->'plans') x
    WHERE x->>'plan_code'='plus'
      AND (x->>'monthly_price_uzs')::integer=35000
      AND (x->>'study_subject_limit')::integer=3
      AND (x->>'competitive_subject_limit')::integer=2
      AND coalesce((x->>'ai_generation_entitled')::boolean,false) IS TRUE
  ) THEN
    RAISE EXCEPTION 'Plus public plan mismatch: %',v;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM jsonb_array_elements(v->'plans') x
    WHERE x->>'plan_code'='pro'
      AND (x->>'monthly_price_uzs')::integer=50000
      AND x->'study_subject_limit'='null'::jsonb
      AND coalesce((x->>'all_available_subjects')::boolean,false) IS TRUE
      AND (x->>'competitive_subject_limit')::integer=2
      AND coalesce((x->>'ai_generation_entitled')::boolean,false) IS TRUE
  ) THEN
    RAISE EXCEPTION 'Pro public plan mismatch: %',v;
  END IF;

  IF v::text ~ '(allowance_units|prepared_weight|generation_weight|ai_usage_policy_code|provider|cost_usd|reservation_ttl|committed_units|reserved_units)' THEN
    RAISE EXCEPTION 'Plan UI bootstrap leaked hidden accounting: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid;
  expected text;
BEGIN
  FOREACH expected IN ARRAY ARRAY['plus','pro'] LOOP
    SELECT user_id INTO uid FROM plan_people WHERE person_key=expected;

    PERFORM set_config('request.jwt.claim.sub',uid::text,true);
    PERFORM set_config('request.jwt.claim.role','authenticated',true);

    v:=public.get_iclub_plan_ui_bootstrap_v1();

    IF coalesce((v->>'visible')::boolean,false) IS NOT TRUE
       OR v->>'current_plan_code'<>expected
       OR coalesce((v->>'checkout_enabled')::boolean,true) THEN
      RAISE EXCEPTION '% bootstrap mismatch: %',expected,v;
    END IF;
  END LOOP;
END
$$;

-- Unassigned production users must not silently become Free during this presentation phase.
DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM plan_people WHERE person_key='unassigned');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_plan_ui_bootstrap_v1();

  IF coalesce((v->>'visible')::boolean,true)
     OR v->>'reason'<>'access_unresolved' THEN
    RAISE EXCEPTION 'Unassigned learner was silently mapped to a tariff: %',v;
  END IF;
END
$$;

DO $$
BEGIN
  IF has_function_privilege('anon','public.get_iclub_plan_ui_bootstrap_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous role can read authenticated plan bootstrap';
  END IF;

  IF NOT has_function_privilege('authenticated','public.get_iclub_plan_ui_bootstrap_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'Authenticated learner cannot read plan bootstrap';
  END IF;
END
$$;

-- Presentation migration itself must not assign anyone or touch learner history.
DO $$
DECLARE
  c integer;
BEGIN
  SELECT count(*) INTO c
  FROM private.iclub_subscription_entitlements
  WHERE entitlement_source<>'plans-ci';

  IF c<>0 THEN
    RAISE EXCEPTION 'Plan UI phase created unexpected entitlement rows=%',c;
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
  WHERE email like 'plan-ui-%@invalid.example';

  IF c<>0 THEN
    RAISE EXCEPTION 'Plan UI matrix rollback left synthetic auth users=%',c;
  END IF;

  SELECT count(*) INTO c
  FROM private.iclub_subscription_entitlements;

  IF c<>0 THEN
    RAISE EXCEPTION 'Plan UI matrix rollback left subscription rows=%',c;
  END IF;
END
$$;

\echo 'iClub Free Plus Pro profile UI v1 SQL matrix: GREEN'
