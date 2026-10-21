DO $test$
DECLARE r jsonb;u1 uuid:='11111111-1111-4111-8111-111111111111';
 u2 uuid:='22222222-2222-4222-8222-222222222222';
 e uuid:='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
 f uuid:='ffffffff-ffff-4fff-8fff-ffffffffffff';
 g uuid:='99999999-9999-4999-8999-999999999999';
 h text:=repeat('a',64);n integer;
BEGIN
 -- QUOTA cannot be marked completed without a settled, charged provider receipt.
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(e,u1,h);
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Reserve E'; END IF;
 r:=public.finish_iclub_ai_v21_freeform_quota_v1(e,u1,h,'completed');
 IF r->>'ok'<>'false' OR r->>'released'<>'true'
 THEN RAISE EXCEPTION 'Completion without money was not blocked'; END IF;
 SELECT committed_count INTO n FROM private.iclub_ai_v21_beta_usage WHERE user_id=u1;
 IF n<>0 THEN RAISE EXCEPTION 'Unpaid generation quota not refunded'; END IF;
 -- Synthetic settled provider cost for F; no provider call is ever made.
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(f,u1,h);
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Reserve F'; END IF;
 INSERT INTO private.iclub_ai_v21_freeform_budget_ledger
 (request_id,user_id,session_fingerprint,request_fingerprint,
 source_fingerprint,source_version,locale,state,held_microusd,
 actual_microusd,finished_at)
 VALUES(f,u1,h,h,h,'approved_help_v1','en','charged',50000,1750,clock_timestamp());
 r:=public.finish_iclub_ai_v21_freeform_quota_v1(f,u1,h,'completed');
 IF r->>'ok'<>'true' THEN RAISE EXCEPTION 'Fully paid and eligible reply rejected'; END IF;
 SELECT committed_count INTO n FROM private.iclub_ai_v21_beta_usage WHERE user_id=u1;
 IF n<>3 THEN RAISE EXCEPTION 'Valid generated reply not billed 3 units'; END IF;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(g,u2,h);
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Reserve G'; END IF;
 INSERT INTO private.iclub_ai_v21_freeform_budget_ledger
 (request_id,user_id,session_fingerprint,request_fingerprint,
 source_fingerprint,source_version,locale,state,held_microusd,
 actual_microusd,finished_at)
 VALUES(g,u2,h,h,h,'approved_help_v1','en','charged',50000,1750,clock_timestamp());
 INSERT INTO public.practice_sessions_v4 VALUES(u2,'in_progress');
 r:=public.finish_iclub_ai_v21_freeform_quota_v1(g,u2,h,'completed');
 IF r->>'ok'<>'false' OR r->>'released'<>'true'
 THEN RAISE EXCEPTION 'Active Practice accepted model answer'; END IF;
 SELECT committed_count INTO n FROM private.iclub_ai_v21_beta_usage WHERE user_id=u2;
 IF n<>0 THEN RAISE EXCEPTION 'Protected Practice did not refund student'; END IF;
END $test$;
SELECT 'PASS_FREEFORM_ATOMIC_COMPLETION_PROTECTED_PAYMENT_RECHECK' result;
