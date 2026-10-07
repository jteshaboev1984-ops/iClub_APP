\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('global_ai.shell_isolated', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'GLOBAL AI SHELL REFUSED: global_ai.shell_isolated=true is required.';
  END IF;
END
$$;

BEGIN;

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

CREATE TEMP TABLE gai_shell_people(
  person_key text primary key,
  user_id uuid not null
) ON COMMIT DROP;

DO $$
DECLARE
  k text;
  uid uuid;
BEGIN
  FOREACH k IN ARRAY ARRAY['free','plus','tour','unassigned'] LOOP
    uid:=gen_random_uuid();
    INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
    VALUES(uid,'authenticated','authenticated','global-ai-shell-'||k||'-'||replace(uid::text,'-','')||'@invalid.example',now(),now(),false,false);
    INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
    VALUES(uid,'GlobalAI','Shell '||k,case when k='plus' then 'uz' else 'ru' end,now(),false);
    INSERT INTO gai_shell_people VALUES(k,uid);
  END LOOP;

  INSERT INTO private.iclub_subscription_entitlements(
    user_id,plan_code,entitlement_status,entitlement_source,valid_from
  )
  SELECT user_id,'free','active','shell-ci',now()-interval '1 minute'
  FROM gai_shell_people WHERE person_key in ('free','tour');

  INSERT INTO private.iclub_subscription_entitlements(
    user_id,plan_code,entitlement_status,entitlement_source,valid_from
  )
  SELECT user_id,'plus','active','shell-ci',now()-interval '1 minute'
  FROM gai_shell_people WHERE person_key='plus';
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_shell_people WHERE person_key='free');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_ai_ui_bootstrap_v1();

  IF coalesce((v->>'visible')::boolean,true)
     OR v->>'reason'<>'ui_disabled' THEN
    RAISE EXCEPTION 'Dormant UI bootstrap did not stay hidden: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_shell_people WHERE person_key='unassigned');
BEGIN
  UPDATE private.iclub_global_ai_runtime_config
  SET ui_enabled=true,
      gateway_enabled=true,
      generation_enabled=false,
      kill_switch=false,
      updated_at=now()
  WHERE id=1;

  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_ai_ui_bootstrap_v1();

  IF coalesce((v->>'visible')::boolean,true)
     OR v->>'reason'<>'access_unresolved' THEN
    RAISE EXCEPTION 'Unassigned learner unexpectedly received shell visibility: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_shell_people WHERE person_key='free');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_ai_ui_bootstrap_v1();

  IF coalesce((v->>'visible')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'assessment_blocked')::boolean,true) IS NOT FALSE
     OR v->>'locale'<>'ru'
     OR v->>'ui_version'<>'global_ai_shell_v1' THEN
    RAISE EXCEPTION 'Free shell bootstrap mismatch: %',v;
  END IF;

  IF v::text ~ '(plan_code|allowance|unit|usage_policy|provider|cache|source_card|price)' THEN
    RAISE EXCEPTION 'UI bootstrap leaked commercial/internal accounting: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_shell_people WHERE person_key='plus');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_ai_ui_bootstrap_v1();

  IF coalesce((v->>'visible')::boolean,false) IS NOT TRUE
     OR v->>'locale'<>'uz' THEN
    RAISE EXCEPTION 'Plus shell bootstrap mismatch: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_shell_people WHERE person_key='tour');
BEGIN
  INSERT INTO public.tour_attempts(user_id,status)
  VALUES(uid,'in_progress');

  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_ai_ui_bootstrap_v1();

  IF coalesce((v->>'visible')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'assessment_blocked')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'active_assessment' THEN
    RAISE EXCEPTION 'Active Tour did not return collapsed shell state: %',v;
  END IF;
END
$$;

DO $$
BEGIN
  IF has_function_privilege('anon','public.get_iclub_ai_ui_bootstrap_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous role can execute Global AI UI bootstrap';
  END IF;

  IF NOT has_function_privilege('authenticated','public.get_iclub_ai_ui_bootstrap_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'Authenticated learner cannot execute safe Global AI UI bootstrap';
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
  WHERE email like 'global-ai-shell-%@invalid.example';

  IF c<>0 THEN
    RAISE EXCEPTION 'Shell matrix rollback left synthetic users=%',c;
  END IF;
END
$$;

\echo 'Global AI learner-shell bootstrap v1 matrix: GREEN'
