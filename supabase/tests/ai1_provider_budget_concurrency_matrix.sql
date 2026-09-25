\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p274.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'AI-1 REFUSED: p274.isolated_db=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE ai1_people(person_key text primary key,user_id uuid not null) ON COMMIT DROP;

DO $$
DECLARE
  v_user1 uuid:=gen_random_uuid();
  v_user2 uuid:=gen_random_uuid();
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES
    (v_user1,'authenticated','authenticated','ai1-budget-1-'||replace(v_user1::text,'-','')||'@invalid.example',now(),now(),false,false),
    (v_user2,'authenticated','authenticated','ai1-budget-2-'||replace(v_user2::text,'-','')||'@invalid.example',now(),now(),false,false);

  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES
    (v_user1,'AI1','Budget One','en',now(),false),
    (v_user2,'AI1','Budget Two','en',now(),false);

  INSERT INTO ai1_people VALUES('u1',v_user1),('u2',v_user2);
END
$$;

DO $$
BEGIN
  IF has_table_privilege('authenticated','private.exam_prep_ai_provider_leases','SELECT')
     OR has_table_privilege('anon','private.exam_prep_ai_provider_leases','SELECT') THEN
    RAISE EXCEPTION 'AI-1 provider leases became browser-readable';
  END IF;

  IF has_function_privilege('authenticated','public.reserve_exam_prep_ai_provider_call_service_v1(uuid,uuid,numeric)','EXECUTE')
     OR has_function_privilege('anon','public.reserve_exam_prep_ai_provider_call_service_v1(uuid,uuid,numeric)','EXECUTE')
     OR has_function_privilege('authenticated','public.finalize_exam_prep_ai_provider_call_service_v1(uuid,text,numeric)','EXECUTE')
     OR has_function_privilege('anon','public.finalize_exam_prep_ai_provider_call_service_v1(uuid,text,numeric)','EXECUTE') THEN
    RAISE EXCEPTION 'AI-1 provider accounting RPC became browser-executable';
  END IF;
END
$$;

UPDATE private.exam_prep_ai_policy
SET max_daily_requests=10,
    max_daily_provider_cost_usd=0.1000,
    max_user_daily_provider_cost_usd=0.0500,
    max_provider_request_cost_usd=0.0080,
    max_concurrent_provider_calls=1,
    provider_lease_ttl_seconds=45,
    updated_at=now()
WHERE id=1;


DO $$
DECLARE
  v_u1 uuid:=(SELECT user_id FROM ai1_people WHERE person_key='u1');
  v_req1 uuid:=gen_random_uuid();
  v_req2 uuid:=gen_random_uuid();
  v jsonb;
BEGIN
  v:=public.reserve_exam_prep_ai_provider_call_service_v1(v_req1,v_u1,0.0060);
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'AI-1 first reservation should succeed: %',v;
  END IF;

  v:=public.reserve_exam_prep_ai_provider_call_service_v1(v_req1,v_u1,0.0060);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'duplicate_request' THEN
    RAISE EXCEPTION 'AI-1 duplicate request was not blocked: %',v;
  END IF;

  v:=public.reserve_exam_prep_ai_provider_call_service_v1(v_req2,v_u1,0.0040);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'provider_concurrency_limit' THEN
    RAISE EXCEPTION 'AI-1 concurrency limit was not atomic: %',v;
  END IF;

  v:=public.finalize_exam_prep_ai_provider_call_service_v1(v_req1,'completed',0.0050);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE OR v->>'status'<>'completed' THEN
    RAISE EXCEPTION 'AI-1 completion failed: %',v;
  END IF;

  v:=public.reserve_exam_prep_ai_provider_call_service_v1(v_req2,v_u1,0.0040);
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'AI-1 reservation after completion should succeed: %',v;
  END IF;

  v:=public.finalize_exam_prep_ai_provider_call_service_v1(v_req2,'completed',0.0030);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'AI-1 second completion failed: %',v;
  END IF;
END
$$;


UPDATE private.exam_prep_ai_policy
SET max_daily_requests=2,
    updated_at=now()
WHERE id=1;

DO $$
DECLARE
  v_u1 uuid:=(SELECT user_id FROM ai1_people WHERE person_key='u1');
  v jsonb;
BEGIN
  v:=public.reserve_exam_prep_ai_provider_call_service_v1(gen_random_uuid(),v_u1,0.0010);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'daily_request_limit' THEN
    RAISE EXCEPTION 'AI-1 atomic daily provider-call limit failed: %',v;
  END IF;
END
$$;

UPDATE private.exam_prep_ai_policy
SET max_daily_requests=10,
    max_daily_provider_cost_usd=0.1000,
    max_user_daily_provider_cost_usd=0.0060,
    max_provider_request_cost_usd=0.0060,
    updated_at=now()
WHERE id=1;

DO $$
DECLARE
  v_u2 uuid:=(SELECT user_id FROM ai1_people WHERE person_key='u2');
  v_req uuid:=gen_random_uuid();
  v jsonb;
BEGIN
  v:=public.reserve_exam_prep_ai_provider_call_service_v1(v_req,v_u2,0.0050);
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'AI-1 user-cost seed reservation failed: %',v;
  END IF;
  PERFORM public.finalize_exam_prep_ai_provider_call_service_v1(v_req,'completed',0.0050);

  v:=public.reserve_exam_prep_ai_provider_call_service_v1(gen_random_uuid(),v_u2,0.0020);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'user_daily_cost_limit' THEN
    RAISE EXCEPTION 'AI-1 per-user daily cost limit failed: %',v;
  END IF;

  v:=public.reserve_exam_prep_ai_provider_call_service_v1(gen_random_uuid(),v_u2,0.0070);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'request_cost_limit' THEN
    RAISE EXCEPTION 'AI-1 per-request cost limit failed: %',v;
  END IF;
END
$$;

UPDATE private.exam_prep_ai_policy
SET max_daily_requests=10,
    max_daily_provider_cost_usd=0.0100,
    max_user_daily_provider_cost_usd=0.0100,
    max_provider_request_cost_usd=0.0080,
    updated_at=now()
WHERE id=1;

DO $$
DECLARE
  v_u1 uuid:=(SELECT user_id FROM ai1_people WHERE person_key='u1');
  v jsonb;
BEGIN
  -- u1 already consumed actual cost 0.008 in the two completed calls above.
  v:=public.reserve_exam_prep_ai_provider_call_service_v1(gen_random_uuid(),v_u1,0.0030);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'global_daily_cost_limit' THEN
    RAISE EXCEPTION 'AI-1 global daily cost limit failed: %',v;
  END IF;
END
$$;

DO $snap$
DECLARE
  v_snapshot jsonb;
BEGIN
  v_snapshot:=public.get_exam_prep_ai_operational_snapshot_v1();

  IF v_snapshot#>>'{policy,max_daily_provider_cost_usd}' IS NULL
     OR v_snapshot#>>'{policy,max_user_daily_provider_cost_usd}' IS NULL
     OR v_snapshot#>>'{policy,max_provider_request_cost_usd}' IS NULL
     OR v_snapshot#>>'{policy,max_concurrent_provider_calls}' IS NULL
     OR v_snapshot->>'provider_active_leases' IS NULL
     OR v_snapshot->>'provider_cost_today_usd' IS NULL THEN
    RAISE EXCEPTION 'AI-1 operational snapshot missing provider budget fields: %',v_snapshot;
  END IF;
END
$snap$;

ROLLBACK;

DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM auth.users
  WHERE email like 'ai1-budget-%@invalid.example';
  IF v_count<>0 THEN
    RAISE EXCEPTION 'AI-1 rollback left synthetic users=%',v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_ai_provider_leases;
  IF v_count<>0 THEN
    RAISE EXCEPTION 'AI-1 rollback left provider lease residue=%',v_count;
  END IF;
END
$$;

\echo 'AI-1 provider budget/concurrency matrix: GREEN'
