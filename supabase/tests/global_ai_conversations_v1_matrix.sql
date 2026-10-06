\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('global_ai.conversations_isolated', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'GLOBAL AI CONVERSATIONS REFUSED: global_ai.conversations_isolated=true is required.';
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

CREATE TEMP TABLE gai_conversation_people(
  person_key text primary key,
  user_id uuid not null
) ON COMMIT DROP;

DO $$
DECLARE
  k text;
  uid uuid;
BEGIN
  FOREACH k IN ARRAY ARRAY['free','plus','unassigned'] LOOP
    uid:=gen_random_uuid();
    INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
    VALUES(uid,'authenticated','authenticated','global-ai-conversations-'||k||'-'||replace(uid::text,'-','')||'@invalid.example',now(),now(),false,false);
    INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
    VALUES(uid,'GlobalAI','Conversations '||k,case when k='plus' then 'en' else 'ru' end,now(),false);
    INSERT INTO gai_conversation_people VALUES(k,uid);
  END LOOP;

  INSERT INTO private.iclub_subscription_entitlements(
    user_id,plan_code,entitlement_status,entitlement_source,valid_from
  )
  SELECT user_id,'free','active','conversation-ci',now()-interval '1 minute'
  FROM gai_conversation_people WHERE person_key='free';

  INSERT INTO private.iclub_subscription_entitlements(
    user_id,plan_code,entitlement_status,entitlement_source,valid_from
  )
  SELECT user_id,'plus','active','conversation-ci',now()-interval '1 minute'
  FROM gai_conversation_people WHERE person_key='plus';
END
$$;

DO $$
DECLARE
  c integer;
  v private.iclub_ai_subject_readiness%rowtype;
BEGIN
  SELECT * INTO v
  FROM private.iclub_ai_subject_readiness
  WHERE subject_key='general'
    AND scope_code='global';

  IF NOT FOUND
     OR v.readiness<>'basic'
     OR v.generation_allowed
     OR v.adapter_code<>'app_help_v1' THEN
    RAISE EXCEPTION 'General iClub readiness mismatch: %',row_to_json(v);
  END IF;

  SELECT count(*) INTO c
  FROM information_schema.tables
  WHERE table_schema='private'
    AND table_name like 'iclub%ai%chat%';

  IF c<>0 THEN
    RAISE EXCEPTION 'Conversation phase unexpectedly introduced raw chat storage tables=%',c;
  END IF;

  SELECT count(*) INTO c
  FROM information_schema.columns
  WHERE table_schema='private'
    AND table_name like 'iclub%ai%'
    AND column_name in ('raw_chat','raw_message','user_text','assistant_text','conversation_text');

  IF c<>0 THEN
    RAISE EXCEPTION 'Conversation phase unexpectedly introduced raw chat text columns=%',c;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_conversation_people WHERE person_key='free');
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

  IF coalesce((v->>'visible')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'assessment_blocked')::boolean,true) IS NOT FALSE
     OR coalesce((v->>'usage_exhausted')::boolean,true) IS NOT FALSE
     OR v->>'reset_at' IS NOT NULL
     OR v->>'ui_version'<>'global_ai_conversations_v1' THEN
    RAISE EXCEPTION 'Fresh conversation bootstrap mismatch: %',v;
  END IF;

  IF v::text ~ '(plan_code|allowance|unit|usage_policy|provider|cache|source_card|price|monthly_price|prepared_weight|generation_weight)' THEN
    RAISE EXCEPTION 'Conversation bootstrap leaked commercial/internal accounting: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  uid uuid:=(SELECT user_id FROM gai_conversation_people WHERE person_key='free');
  rid uuid;
  v jsonb;
  i integer;
BEGIN
  FOR i IN 1..3 LOOP
    rid:=gen_random_uuid();
    v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'free_v1','prepared');
    IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
      RAISE EXCEPTION 'Free prepared reservation % failed: %',i,v;
    END IF;

    v:=public.finalize_iclub_ai_usage_service_v1(rid,'completed');
    IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
      RAISE EXCEPTION 'Free prepared completion % failed: %',i,v;
    END IF;
  END LOOP;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_conversation_people WHERE person_key='free');
  v_reset timestamptz;
BEGIN
  SELECT reset_at INTO v_reset
  FROM private.iclub_ai_usage_periods
  WHERE user_id=uid
    AND status='active'
  ORDER BY created_at DESC
  LIMIT 1;

  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_ai_ui_bootstrap_v1();

  IF coalesce((v->>'visible')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'usage_exhausted')::boolean,false) IS NOT TRUE
     OR (v->>'reset_at')::timestamptz IS DISTINCT FROM v_reset
     OR v->>'reason'<>'usage_exhausted' THEN
    RAISE EXCEPTION 'Exhausted conversation bootstrap mismatch: % expected reset %',v,v_reset;
  END IF;

  IF v::text ~ '(3/3|allowance|unit|usage_policy|prepared_weight|generation_weight|plan_code|price)' THEN
    RAISE EXCEPTION 'Exhausted bootstrap leaked hidden accounting: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_conversation_people WHERE person_key='plus');
BEGIN
  INSERT INTO public.tour_attempts(user_id,status)
  VALUES(uid,'in_progress');

  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_ai_ui_bootstrap_v1();

  IF coalesce((v->>'visible')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'assessment_blocked')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'active_assessment' THEN
    RAISE EXCEPTION 'Protected assessment did not take priority in conversation bootstrap: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM gai_conversation_people WHERE person_key='unassigned');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_ai_ui_bootstrap_v1();

  IF coalesce((v->>'visible')::boolean,true)
     OR v->>'reason'<>'access_unresolved' THEN
    RAISE EXCEPTION 'Unassigned learner unexpectedly received conversation shell: %',v;
  END IF;
END
$$;

DO $$
BEGIN
  IF has_function_privilege('anon','public.get_iclub_ai_ui_bootstrap_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous role can execute Global AI conversation bootstrap';
  END IF;

  IF NOT has_function_privilege('authenticated','public.get_iclub_ai_ui_bootstrap_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'Authenticated learner cannot execute browser-safe conversation bootstrap';
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
  WHERE email like 'global-ai-conversations-%@invalid.example';

  IF c<>0 THEN
    RAISE EXCEPTION 'Conversation matrix rollback left synthetic users=%',c;
  END IF;

  SELECT count(*) INTO c
  FROM private.iclub_ai_usage_periods;
  IF c<>0 THEN
    RAISE EXCEPTION 'Conversation matrix rollback left usage periods=%',c;
  END IF;

  SELECT count(*) INTO c
  FROM private.iclub_ai_usage_reservations;
  IF c<>0 THEN
    RAISE EXCEPTION 'Conversation matrix rollback left usage reservations=%',c;
  END IF;
END
$$;

\echo 'Global AI contextual conversations v1 SQL matrix: GREEN'
