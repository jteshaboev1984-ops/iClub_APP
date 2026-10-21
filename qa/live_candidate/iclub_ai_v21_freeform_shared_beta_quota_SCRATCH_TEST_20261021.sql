DO $check$
DECLARE r jsonb; consumed integer;
 u1 uuid:='11111111-1111-4111-8111-111111111111';
 u2 uuid:='22222222-2222-4222-8222-222222222222';
 u3 uuid:='33333333-3333-4333-8333-333333333333';
 a uuid:='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 b uuid:='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
 c uuid:='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
 d uuid:='dddddddd-dddd-4ddd-8ddd-dddddddddddd';
 h text:=repeat('a',64);
BEGIN
 IF has_function_privilege('authenticated',
 'public.reserve_iclub_ai_v21_freeform_quota_v1(uuid,uuid,text)','EXECUTE')
 THEN RAISE EXCEPTION 'Client can edit quota'; END IF;
 UPDATE private.iclub_ai_v21_freeform_budget_control SET enabled=false;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(a,u1,h);
 IF r->>'reason'<>'beta_generation_disabled'
 THEN RAISE EXCEPTION 'Offline quota reservation accepted';END IF;
 -- TEST ONLY; production remains OFF until reviewed Edge runtime ships.
 UPDATE private.iclub_ai_v21_freeform_budget_control SET enabled=true;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(a,u3,h);
 IF r->>'reason'<>'beta_generation_disabled'
 THEN RAISE EXCEPTION 'Unconsented learner can reserve Free quota';END IF;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(a,u1,h);
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Free generation quota not reserved';END IF;
 SELECT committed_count INTO consumed FROM private.iclub_ai_v21_beta_usage WHERE user_id=u1;
 IF consumed<>3 THEN RAISE EXCEPTION 'Generation is not charged 3 units';END IF;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(a,u1,h);
 IF r->>'reason'<>'request_already_seen'
 THEN RAISE EXCEPTION 'Quota replay failed';END IF;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(b,u1,h);
 IF r->>'reason'<>'usage_exhausted'
 THEN RAISE EXCEPTION 'Generated quota 3+3 incorrectly allowed';END IF;
 r:=public.finish_iclub_ai_v21_freeform_quota_v1(a,u2,h,'released');
 IF r->>'ok'<>'false' THEN RAISE EXCEPTION 'Cross-user quota refund';END IF;
 r:=public.finish_iclub_ai_v21_freeform_quota_v1(a,u1,h,'released');
 IF r->>'ok'<>'true' THEN RAISE EXCEPTION 'Failed answer did not refund';END IF;
 SELECT committed_count INTO consumed FROM private.iclub_ai_v21_beta_usage WHERE user_id=u1;
 IF consumed<>0 THEN RAISE EXCEPTION 'Refund did not restore shared quota';END IF;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(b,u1,h);
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Refunded quota cannot be reused';END IF;
 r:=public.finish_iclub_ai_v21_freeform_quota_v1(b,u1,h,'completed');
 IF r->>'ok'<>'true' THEN RAISE EXCEPTION 'Completed generated answer not charged';END IF;
 SELECT committed_count INTO consumed FROM private.iclub_ai_v21_beta_usage WHERE user_id=u1;
 IF consumed<>3 THEN RAISE EXCEPTION 'Completed answer did not charge 3';END IF;
 r:=public.finish_iclub_ai_v21_freeform_quota_v1(b,u1,h,'released');
 IF r->>'ok'<>'false' THEN RAISE EXCEPTION 'Completed quota double refund';END IF;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(c,u2,h);
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Second learner Free exception denied';END IF;
 r:=public.finish_iclub_ai_v21_freeform_quota_v1(c,u2,h,'released');
 IF r->>'ok'<>'true' THEN RAISE EXCEPTION 'Second learner refund failed';END IF;

 -- Mimic a prepared 1-unit reply on a new window. Generated 3 must refuse.
 UPDATE private.iclub_ai_v21_beta_usage SET
  started_at=clock_timestamp(),committed_count=1 WHERE user_id=u1;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(d,u1,h);
 IF r->>'reason'<>'usage_exhausted'
 THEN RAISE EXCEPTION 'Prepared 1+generated 3 bypassed shared 3-unit policy';END IF;
 UPDATE private.iclub_ai_v21_beta_usage SET committed_count=0 WHERE user_id=u1;
 INSERT INTO public.practice_sessions_v4 VALUES(u1,'in_progress');
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(d,u1,h);
 IF r->>'reason'<>'active_assessment'
 THEN RAISE EXCEPTION 'Live in-progress Practice was ignored';END IF;
 DELETE FROM public.practice_sessions_v4;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(d,u1,h);
 IF r->>'allowed'<>'true' THEN RAISE EXCEPTION 'Finished Practice still refused';END IF;
 r:=public.finish_iclub_ai_v21_freeform_quota_v1(d,u1,h,'released');
 IF r->>'ok'<>'true' THEN RAISE EXCEPTION 'Final refund failed';END IF;
 IF (SELECT generation_enabled FROM private.iclub_ai_v21_beta_control WHERE singleton=1)
 THEN RAISE EXCEPTION 'Legacy prepared-beta switch was altered';END IF;
END $check$;
SELECT 'PASS_FREEFORM_BETA_QUOTA_SHARED_WEIGHT3_5H_SCRATCH' result;
