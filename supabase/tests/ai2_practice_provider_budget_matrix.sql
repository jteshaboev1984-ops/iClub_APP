\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE ai2_budget_users(user_id uuid primary key) ON COMMIT DROP;

DO $$
DECLARE v_uid uuid:=gen_random_uuid();
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(v_uid,'authenticated','authenticated','ai2-budget-'||replace(v_uid::text,'-','')||'@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_uid,'AI2','Budget Synthetic','en',now(),false);
  INSERT INTO ai2_budget_users VALUES(v_uid);
END
$$;

DO $$
BEGIN
  IF has_table_privilege('authenticated','private.practice_ai_provider_leases','SELECT')
     OR has_table_privilege('anon','private.practice_ai_provider_leases','SELECT') THEN
    RAISE EXCEPTION 'AI-2 provider leases became browser-readable';
  END IF;

  IF has_function_privilege('authenticated','public.reserve_practice_ai_provider_call_service_v1(uuid,uuid,numeric)','EXECUTE')
     OR has_function_privilege('anon','public.reserve_practice_ai_provider_call_service_v1(uuid,uuid,numeric)','EXECUTE')
     OR has_function_privilege('authenticated','public.finalize_practice_ai_provider_call_service_v1(uuid,text,numeric)','EXECUTE')
     OR has_function_privilege('anon','public.finalize_practice_ai_provider_call_service_v1(uuid,text,numeric)','EXECUTE') THEN
    RAISE EXCEPTION 'AI-2 provider accounting RPC became browser-executable';
  END IF;
END
$$;

UPDATE private.practice_ai_policy
SET max_daily_requests=3,
    max_daily_provider_cost_usd=0.0200,
    max_user_daily_provider_cost_usd=0.0150,
    max_provider_request_cost_usd=0.0080,
    max_concurrent_provider_calls=1,
    provider_lease_ttl_seconds=45,
    updated_at=now()
WHERE id=1;

SET LOCAL ROLE service_role;

DO $$
DECLARE
  v_uid uuid:=(SELECT user_id FROM ai2_budget_users LIMIT 1);
  v_req1 uuid:=gen_random_uuid();
  v_req2 uuid:=gen_random_uuid();
  v jsonb;
BEGIN
  v:=public.reserve_practice_ai_provider_call_service_v1(v_req1,v_uid,0.0060);
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'AI-2 first reservation failed: %',v;
  END IF;

  v:=public.reserve_practice_ai_provider_call_service_v1(v_req1,v_uid,0.0060);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'duplicate_request' THEN
    RAISE EXCEPTION 'AI-2 duplicate request escaped: %',v;
  END IF;

  v:=public.reserve_practice_ai_provider_call_service_v1(v_req2,v_uid,0.0040);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'provider_concurrency_limit' THEN
    RAISE EXCEPTION 'AI-2 concurrency guard failed: %',v;
  END IF;

  v:=public.finalize_practice_ai_provider_call_service_v1(v_req1,'completed',0.0050);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'AI-2 finalize failed: %',v;
  END IF;

  v:=public.reserve_practice_ai_provider_call_service_v1(v_req2,v_uid,0.0040);
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'AI-2 reservation after finalize failed: %',v;
  END IF;

  perform public.finalize_practice_ai_provider_call_service_v1(v_req2,'completed',0.0030);

  v:=public.reserve_practice_ai_provider_call_service_v1(gen_random_uuid(),v_uid,0.0090);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'request_cost_limit' THEN
    RAISE EXCEPTION 'AI-2 request-cost guard failed: %',v;
  END IF;

  v:=public.reserve_practice_ai_provider_call_service_v1(gen_random_uuid(),v_uid,0.0080);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'user_daily_cost_limit' THEN
    RAISE EXCEPTION 'AI-2 user daily cost guard failed: %',v;
  END IF;
END
$$;

RESET ROLE;

DO $$
DECLARE v_snapshot jsonb;
BEGIN
  SET LOCAL ROLE service_role;
  v_snapshot:=public.get_practice_ai_operational_snapshot_v1();
  RESET ROLE;

  IF v_snapshot#>>'{policy,max_daily_provider_cost_usd}' IS NULL
     OR v_snapshot#>>'{policy,max_user_daily_provider_cost_usd}' IS NULL
     OR v_snapshot#>>'{policy,max_provider_request_cost_usd}' IS NULL
     OR v_snapshot#>>'{policy,max_concurrent_provider_calls}' IS NULL
     OR v_snapshot->>'provider_active_leases' IS NULL
     OR v_snapshot->>'provider_cost_today_usd' IS NULL THEN
    RAISE EXCEPTION 'AI-2 provider budget fields missing from snapshot: %',v_snapshot;
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email like 'ai2-budget-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'AI-2 budget rollback left users=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.practice_ai_provider_leases;
  IF v_count<>0 THEN RAISE EXCEPTION 'AI-2 budget rollback left leases=%',v_count; END IF;
END
$$;

\echo 'AI-2 Practice provider budget/concurrency matrix: GREEN'
