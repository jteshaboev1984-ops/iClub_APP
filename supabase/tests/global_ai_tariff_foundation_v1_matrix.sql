\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('global_ai.foundation_isolated', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'GLOBAL AI FOUNDATION REFUSED: global_ai.foundation_isolated=true is required.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE gai_people(
  person_key text primary key,
  user_id uuid not null
) ON COMMIT DROP;

DO $$
DECLARE
  k text;
  uid uuid;
BEGIN
  FOREACH k IN ARRAY ARRAY['free','plus','plus_exhaust','pro','fail','duplicate','reset'] LOOP
    uid:=gen_random_uuid();
    INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
    VALUES(uid,'authenticated','authenticated','global-ai-'||k||'-'||replace(uid::text,'-','')||'@invalid.example',now(),now(),false,false);
    INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
    VALUES(uid,'GlobalAI',k,'en',now(),false);
    INSERT INTO gai_people VALUES(k,uid);
  END LOOP;
END
$$;

DO $$
DECLARE
  v jsonb;
BEGIN
  v:=public.get_iclub_global_ai_foundation_snapshot_v1();

  IF v#>>'{runtime,ui_enabled}'<>'false'
     OR v#>>'{runtime,gateway_enabled}'<>'false'
     OR v#>>'{runtime,generation_enabled}'<>'false'
     OR v#>>'{runtime,kill_switch}'<>'true' THEN
    RAISE EXCEPTION 'Global AI foundation is not dormant: %',v;
  END IF;

  IF (v->>'assigned_subscriptions')::integer<>0 THEN
    RAISE EXCEPTION 'Foundation unexpectedly assigned production-style subscriptions: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
BEGIN
  v:=public.get_iclub_public_plan_catalog_v1();

  IF jsonb_array_length(v)<>3 THEN
    RAISE EXCEPTION 'Plan catalog must contain exactly Free/Plus/Pro: %',v;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(v) x
    WHERE x->>'plan_code'='free'
      AND (x->>'monthly_price_uzs')::integer=0
      AND (x->>'study_subject_limit')::integer=1
      AND (x->>'competitive_subject_limit')::integer=1
      AND (x->>'ai_generation_entitled')::boolean=false
  ) THEN
    RAISE EXCEPTION 'Free plan policy mismatch: %',v;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(v) x
    WHERE x->>'plan_code'='plus'
      AND (x->>'monthly_price_uzs')::integer=35000
      AND (x->>'study_subject_limit')::integer=3
      AND (x->>'competitive_subject_limit')::integer=2
      AND (x->>'ai_generation_entitled')::boolean=true
  ) THEN
    RAISE EXCEPTION 'Plus plan policy mismatch: %',v;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(v) x
    WHERE x->>'plan_code'='pro'
      AND (x->>'monthly_price_uzs')::integer=50000
      AND x->'study_subject_limit'='null'::jsonb
      AND (x->>'all_available_subjects')::boolean=true
      AND (x->>'competitive_subject_limit')::integer=2
      AND (x->>'ai_generation_entitled')::boolean=true
      AND (x->>'priority_support')::boolean=true
      AND (x->>'early_access_entitled')::boolean=true
  ) THEN
    RAISE EXCEPTION 'Pro plan policy mismatch: %',v;
  END IF;

  IF v::text ~ '(allowance_units|prepared_weight|generation_weight|internal_units)' THEN
    RAISE EXCEPTION 'Public plan catalog leaked hidden AI accounting: %',v;
  END IF;
END
$$;

DO $$
BEGIN
  IF has_table_privilege('authenticated','private.iclub_ai_usage_periods','SELECT')
     OR has_table_privilege('authenticated','private.iclub_ai_usage_reservations','SELECT')
     OR has_table_privilege('authenticated','private.iclub_ai_usage_policies','SELECT')
     OR has_table_privilege('authenticated','private.iclub_subscription_entitlements','SELECT')
     OR has_table_privilege('anon','private.iclub_ai_usage_periods','SELECT') THEN
    RAISE EXCEPTION 'Private Global AI accounting became browser-readable';
  END IF;

  IF has_function_privilege('authenticated','public.reserve_iclub_ai_usage_service_v1(uuid,uuid,text,text)','EXECUTE')
     OR has_function_privilege('authenticated','public.finalize_iclub_ai_usage_service_v1(uuid,text,text)','EXECUTE')
     OR has_function_privilege('anon','public.reserve_iclub_ai_usage_service_v1(uuid,uuid,text,text)','EXECUTE')
     OR has_function_privilege('anon','public.finalize_iclub_ai_usage_service_v1(uuid,text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'Global AI usage accounting became browser-executable';
  END IF;
END
$$;

DO $$
DECLARE
  uid uuid:=(SELECT user_id FROM gai_people WHERE person_key='free');
  v jsonb;
BEGIN
  v:=public.reserve_iclub_ai_usage_service_v1(gen_random_uuid(),uid,'free_v1','generated');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'generation_not_entitled' THEN
    RAISE EXCEPTION 'Free generation was not blocked: %',v;
  END IF;

  IF EXISTS (
    SELECT 1 FROM private.iclub_ai_usage_periods
    WHERE user_id=uid AND status in ('provisional','active')
  ) THEN
    RAISE EXCEPTION 'Blocked Free generation incorrectly started a usage period';
  END IF;
END
$$;

DO $$
DECLARE
  uid uuid:=(SELECT user_id FROM gai_people WHERE person_key='fail');
  rid uuid:=gen_random_uuid();
  v jsonb;
  cnt integer;
BEGIN
  v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'plus_v1','generated');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Failure-path reservation should succeed: %',v;
  END IF;

  v:=public.finalize_iclub_ai_usage_service_v1(rid,'released','provider_timeout');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Failure-path release failed: %',v;
  END IF;

  SELECT count(*) INTO cnt
  FROM private.iclub_ai_usage_periods
  WHERE user_id=uid AND status in ('provisional','active');

  IF cnt<>0 THEN
    RAISE EXCEPTION 'Failed first response left an open five-hour period: %',cnt;
  END IF;
END
$$;

DO $$
DECLARE
  uid uuid:=(SELECT user_id FROM gai_people WHERE person_key='free');
  rid uuid;
  v jsonb;
  i integer;
  started timestamptz;
  reset timestamptz;
BEGIN
  FOR i IN 1..3 LOOP
    rid:=gen_random_uuid();
    v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'free_v1','prepared');
    IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
      RAISE EXCEPTION 'Free prepared reservation % should succeed: %',i,v;
    END IF;
    v:=public.finalize_iclub_ai_usage_service_v1(rid,'completed');
    IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
      RAISE EXCEPTION 'Free prepared completion % failed: %',i,v;
    END IF;
  END LOOP;

  SELECT started_at,reset_at INTO started,reset
  FROM private.iclub_ai_usage_periods
  WHERE user_id=uid AND status='active';

  IF started IS NULL OR reset IS NULL
     OR abs(extract(epoch from ((reset-started)-interval '5 hours'))) > 1 THEN
    RAISE EXCEPTION 'Free period is not exactly five hours: start %, reset %',started,reset;
  END IF;

  v:=public.reserve_iclub_ai_usage_service_v1(gen_random_uuid(),uid,'free_v1','prepared');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'usage_exhausted'
     OR v->>'reset_at' IS NULL THEN
    RAISE EXCEPTION 'Free fourth response did not exhaust with reset time: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  uid uuid:=(SELECT user_id FROM gai_people WHERE person_key='plus');
  rid uuid;
  v jsonb;
  i integer;
  committed integer;
BEGIN
  rid:=gen_random_uuid();
  v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'plus_v1','generated');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus generated reservation should succeed: %',v;
  END IF;
  PERFORM public.finalize_iclub_ai_usage_service_v1(rid,'completed');

  FOR i IN 1..4 LOOP
    rid:=gen_random_uuid();
    v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'plus_v1','prepared');
    IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
      RAISE EXCEPTION 'Plus prepared reservation % should succeed: %',i,v;
    END IF;
    PERFORM public.finalize_iclub_ai_usage_service_v1(rid,'completed');
  END LOOP;

  SELECT committed_units INTO committed
  FROM private.iclub_ai_usage_periods
  WHERE user_id=uid AND status='active';

  IF committed<>9 THEN
    RAISE EXCEPTION 'Plus committed units mismatch: %',committed;
  END IF;

  v:=public.reserve_iclub_ai_usage_service_v1(gen_random_uuid(),uid,'plus_v1','prepared');
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'usage_exhausted' THEN
    RAISE EXCEPTION 'Plus allowance did not stop after 9 units: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  uid uuid:=(SELECT user_id FROM gai_people WHERE person_key='plus_exhaust');
  rid uuid;
  v jsonb;
  i integer;
  committed integer;
  exhausted_state boolean;
BEGIN
  rid:=gen_random_uuid();
  PERFORM public.reserve_iclub_ai_usage_service_v1(rid,uid,'plus_v1','generated');
  PERFORM public.finalize_iclub_ai_usage_service_v1(rid,'completed');

  FOR i IN 1..3 LOOP
    rid:=gen_random_uuid();
    PERFORM public.reserve_iclub_ai_usage_service_v1(rid,uid,'plus_v1','prepared');
    PERFORM public.finalize_iclub_ai_usage_service_v1(rid,'completed');
  END LOOP;

  SELECT committed_units INTO committed
  FROM private.iclub_ai_usage_periods
  WHERE user_id=uid AND status='active';
  IF committed<>8 THEN
    RAISE EXCEPTION 'Plus exhaust fixture expected 8 committed units, got %',committed;
  END IF;

  v:=public.reserve_iclub_ai_usage_service_v1(gen_random_uuid(),uid,'plus_v1','generated');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'usage_exhausted' THEN
    RAISE EXCEPTION 'Insufficient generated allowance did not exhaust period: %',v;
  END IF;

  SELECT exhausted INTO exhausted_state
  FROM private.iclub_ai_usage_periods
  WHERE user_id=uid AND status='active';
  IF exhausted_state IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus period not marked exhausted after unaffordable route';
  END IF;

  v:=public.reserve_iclub_ai_usage_service_v1(gen_random_uuid(),uid,'plus_v1','prepared');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'usage_exhausted' THEN
    RAISE EXCEPTION 'Prepared route leaked through after full exhausted state: %',v;
  END IF;
END
$$;

DO $$
DECLARE
  uid uuid:=(SELECT user_id FROM gai_people WHERE person_key='pro');
  rid uuid;
  v jsonb;
  i integer;
  committed integer;
BEGIN
  FOR i IN 1..2 LOOP
    rid:=gen_random_uuid();
    v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'pro_v1','generated');
    IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
      RAISE EXCEPTION 'Pro generated reservation % should succeed: %',i,v;
    END IF;
    PERFORM public.finalize_iclub_ai_usage_service_v1(rid,'completed');
  END LOOP;

  FOR i IN 1..4 LOOP
    rid:=gen_random_uuid();
    v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'pro_v1','prepared');
    IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
      RAISE EXCEPTION 'Pro prepared reservation % should succeed: %',i,v;
    END IF;
    PERFORM public.finalize_iclub_ai_usage_service_v1(rid,'completed');
  END LOOP;

  SELECT committed_units INTO committed
  FROM private.iclub_ai_usage_periods
  WHERE user_id=uid AND status='active';

  IF committed<>14 THEN
    RAISE EXCEPTION 'Pro committed units mismatch: %',committed;
  END IF;
END
$$;

DO $$
DECLARE
  uid uuid:=(SELECT user_id FROM gai_people WHERE person_key='duplicate');
  rid uuid:=gen_random_uuid();
  v jsonb;
  committed integer;
BEGIN
  v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'plus_v1','prepared');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Duplicate fixture initial reservation failed: %',v;
  END IF;

  v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'plus_v1','prepared');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'duplicate')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Duplicate reservation did not resolve idempotently: %',v;
  END IF;

  PERFORM public.finalize_iclub_ai_usage_service_v1(rid,'completed');
  v:=public.finalize_iclub_ai_usage_service_v1(rid,'completed');

  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'duplicate')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Duplicate finalize did not resolve idempotently: %',v;
  END IF;

  SELECT committed_units INTO committed
  FROM private.iclub_ai_usage_periods
  WHERE user_id=uid AND status='active';

  IF committed<>1 THEN
    RAISE EXCEPTION 'Duplicate request double-charged usage: %',committed;
  END IF;
END
$$;

DO $$
DECLARE
  uid uuid:=(SELECT user_id FROM gai_people WHERE person_key='reset');
  rid uuid:=gen_random_uuid();
  v jsonb;
  open_count integer;
BEGIN
  PERFORM public.reserve_iclub_ai_usage_service_v1(rid,uid,'free_v1','prepared');
  PERFORM public.finalize_iclub_ai_usage_service_v1(rid,'completed');

  UPDATE private.iclub_ai_usage_periods
  SET reset_at=now()-interval '1 second',
      started_at=now()-interval '5 hours 1 second'
  WHERE user_id=uid AND status='active';

  rid:=gen_random_uuid();
  v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'free_v1','prepared');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'New five-hour period did not open after reset: %',v;
  END IF;
  PERFORM public.finalize_iclub_ai_usage_service_v1(rid,'completed');

  SELECT count(*) INTO open_count
  FROM private.iclub_ai_usage_periods
  WHERE user_id=uid AND status in ('provisional','active');

  IF open_count<>1 THEN
    RAISE EXCEPTION 'Expected exactly one open period after reset, got %',open_count;
  END IF;
END
$$;

DO $$
DECLARE
  c integer;
BEGIN
  SELECT count(*) INTO c FROM private.iclub_subscription_entitlements;
  IF c<>0 THEN
    RAISE EXCEPTION 'Foundation test unexpectedly created subscription entitlements=%',c;
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
  WHERE email like 'global-ai-%@invalid.example';

  IF c<>0 THEN
    RAISE EXCEPTION 'Global AI foundation rollback left synthetic users=%',c;
  END IF;

  SELECT count(*) INTO c FROM private.iclub_ai_usage_periods;
  IF c<>0 THEN
    RAISE EXCEPTION 'Global AI foundation rollback left usage periods=%',c;
  END IF;

  SELECT count(*) INTO c FROM private.iclub_ai_usage_reservations;
  IF c<>0 THEN
    RAISE EXCEPTION 'Global AI foundation rollback left reservations=%',c;
  END IF;
END
$$;

\echo 'Global AI + tariffs foundation v1 matrix: GREEN'
