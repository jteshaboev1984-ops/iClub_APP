DO $test$
DECLARE r jsonb; expense bigint;
 a uuid:='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 b uuid:='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
 c uuid:='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
 d uuid:='dddddddd-dddd-4ddd-8ddd-dddddddddddd';
 user1 uuid:='11111111-1111-4111-8111-111111111111';
 user2 uuid:='22222222-2222-4222-8222-222222222222';
 user3 uuid:='33333333-3333-4333-8333-333333333333';
 h text:=repeat('a',64);s text:=repeat('b',64);v text:=repeat('c',64);
BEGIN
 IF (SELECT enabled FROM private.iclub_ai_v21_freeform_budget_control WHERE singleton=1)
 OR has_function_privilege('authenticated',
 'public.reserve_iclub_ai_v21_freeform_budget_v1(uuid,uuid,text,text,text,text,text)','EXECUTE')
 OR has_table_privilege('service_role','private.iclub_ai_v21_freeform_budget_ledger','INSERT')
 THEN RAISE EXCEPTION 'Default OFF or RLS privilege failure'; END IF;
 r:=public.reserve_iclub_ai_v21_freeform_budget_v1(a,user1,h,s,v,'v1','en');
 IF r->>'reason'<>'beta_generation_disabled' THEN RAISE EXCEPTION 'Default OFF broken';END IF;
 -- TEST FIXTURE ONLY; live migration never enables these flags.
 UPDATE private.iclub_ai_v21_freeform_budget_control SET enabled=true;
 -- Legacy beta generation_enabled=false MUST remain unchanged:
 IF (SELECT generation_enabled FROM private.iclub_ai_v21_beta_control WHERE singleton=1)
 THEN RAISE EXCEPTION 'Legacy prepared beta must remain unaffected'; END IF;
 r:=public.reserve_iclub_ai_v21_freeform_budget_v1(a,user3,h,s,v,'v1','ru');
 IF r->>'reason'<>'beta_generation_disabled' THEN RAISE EXCEPTION 'Unconsented member funded';END IF;
 r:=public.reserve_iclub_ai_v21_freeform_budget_v1(a,user1,h,s,v,'v1','en');
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Consented Free member denied';END IF;
 r:=public.reserve_iclub_ai_v21_freeform_budget_v1(a,user1,h,s,v,'v1','en');
 IF r->>'reason'<>'request_already_seen' THEN RAISE EXCEPTION 'Replay billed';END IF;
 r:=public.dispatch_iclub_ai_v21_freeform_budget_v1(a,user2,h,s);
 IF r->>'allowed'<>'false' THEN RAISE EXCEPTION 'Cross-user spend';END IF;
 r:=public.dispatch_iclub_ai_v21_freeform_budget_v1(a,user1,h,s);
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Dispatch first failed';END IF;
 r:=public.dispatch_iclub_ai_v21_freeform_budget_v1(a,user1,h,s);
 IF r->>'allowed'<>'false' THEN RAISE EXCEPTION 'Double dispatch';END IF;
 r:=public.settle_iclub_ai_v21_freeform_budget_v1(a,user1,h,s,'no_charge',NULL);
 IF r->>'ok'<>'false' THEN RAISE EXCEPTION 'Dispatched bill cleared';END IF;
 r:=public.settle_iclub_ai_v21_freeform_budget_v1(a,user1,h,s,'charged',1200);
 IF r->>'ok'<>'true' THEN RAISE EXCEPTION 'Valid charge failed';END IF;
 r:=public.settle_iclub_ai_v21_freeform_budget_v1(a,user1,h,s,'charged',1200);
 IF r->>'ok'<>'false' THEN RAISE EXCEPTION 'Duplicate settlement';END IF;
 r:=public.reserve_iclub_ai_v21_freeform_budget_v1(b,user1,h,s,v,'v1','ru');
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Reserve B';END IF;
 r:=public.dispatch_iclub_ai_v21_freeform_budget_v1(b,user1,h,s);
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Dispatch B';END IF;
 r:=public.settle_iclub_ai_v21_freeform_budget_v1(b,user1,h,s,'unknown',NULL);
 IF r->>'ok'<>'true' THEN RAISE EXCEPTION 'Unknown bill should retain hold';END IF;
 r:=public.reserve_iclub_ai_v21_freeform_budget_v1(c,user1,h,s,v,'v1','uz');
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Reserve C';END IF;
 r:=public.settle_iclub_ai_v21_freeform_budget_v1(c,user1,h,s,'no_charge',NULL);
 IF r->>'ok'<>'true' THEN RAISE EXCEPTION 'Safe pre-dispatch release';END IF;
 r:=public.reserve_iclub_ai_v21_freeform_budget_v1(d,user1,h,s,v,'v1','ru');
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Reserve D';END IF;
 UPDATE private.iclub_ai_v21_freeform_budget_control SET enabled=false;
 r:=public.dispatch_iclub_ai_v21_freeform_budget_v1(d,user1,h,s);
 IF r->>'allowed'<>'false' THEN RAISE EXCEPTION 'Kill switch failed';END IF;
 r:=public.settle_iclub_ai_v21_freeform_budget_v1(d,user1,h,s,'no_charge',NULL);
 IF r->>'ok'<>'true' THEN RAISE EXCEPTION 'Kill switch blocked legitimate no-charge';END IF;
 UPDATE private.iclub_ai_v21_freeform_budget_control SET enabled=true;
 -- Inject SYNTHETIC historical expenditure at $4.9512; a new $0.05 reservation
 -- MUST fail because 4.9512 + 0.05 exceeds the owner's lifetime $5.
 INSERT INTO private.iclub_ai_v21_freeform_budget_ledger
 (request_id,user_id,session_fingerprint,request_fingerprint,
 source_fingerprint,source_version,locale,state,held_microusd,
 actual_microusd,finished_at)
 SELECT gen_random_uuid(),gen_random_uuid(),h,s,v,'fixture_v1','en',
 'charged',50000,50000,clock_timestamp() FROM generate_series(1,98);
 SELECT SUM(CASE WHEN state='charged' THEN actual_microusd
  WHEN state='no_charge' THEN 0 ELSE held_microusd END)
 INTO expense FROM private.iclub_ai_v21_freeform_budget_ledger;
 IF expense<>4951200 THEN RAISE EXCEPTION 'Synthetic cost mismatch %',expense;END IF;
 r:=public.reserve_iclub_ai_v21_freeform_budget_v1(
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',user2,h,s,v,'v1','en');
 IF r->>'reason'<>'pilot_budget_exhausted'
 THEN RAISE EXCEPTION 'Lifetime $5 cap bypassed';END IF;
END $test$;
SELECT 'PASS_5USD_BETA_FREE_AND_LIFETIME_LIABILITY_SCRATCH' result;
