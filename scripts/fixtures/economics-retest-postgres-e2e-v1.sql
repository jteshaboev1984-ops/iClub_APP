-- Isolated PG17 runtime contract: fully fictional users, sessions, skills, MCQs.
-- Run AFTER scripts/fixtures/economics-retest-postgres-fixture-v1.sql and
-- docs/release-candidates/economics-private-retest-gated-v1.sql.
\set ON_ERROR_STOP on

create function public.synthetic_expect_code_v1(p_result jsonb,p_code text)
returns void language plpgsql as $$
begin
  if p_result->>'ok' is distinct from 'false' or p_result->>'code' is distinct from p_code then
    raise exception 'expected failure %; obtained %',p_code,p_result;
  end if;
end; $$;

do $$
begin
 if (select issuance_enabled from private.iclub_econ_retest_control_v1 where id=1) is distinct from false
 then raise exception 'New issuance unexpectedly enabled'; end if;
 if has_table_privilege('authenticated','private.iclub_econ_retest_sources_v1','select')
    or has_table_privilege('authenticated','private.iclub_econ_retest_sessions_v1','select')
    or has_table_privilege('anon','private.iclub_econ_retest_sources_v1','select')
 then raise exception 'Private source or session table leaked'; end if;
 if has_function_privilege('anon','public.iclub_econ_retest_start_v1(uuid,integer,text)','execute')
    or has_function_privilege('anon','public.iclub_econ_retest_get_v1(uuid,text)','execute')
    or has_function_privilege('anon','public.iclub_econ_retest_submit_v1(uuid,integer,text)','execute')
 then raise exception 'Anonymous user has RPC execute privilege'; end if;
 if (select count(*) from private.iclub_exam_native_mcq_attempts_v1)<>2 then
    raise exception 'Synthetic original exam fixture missing'; end if;
end $$;

-- Source text is deliberately generic and fictional; no proprietary question.
insert into private.iclub_econ_retest_sources_v1
(item_key,content_version,paper_code,skill_key,source_sha256,locales,answer_key)
values
('FICT-RETEST-A','fiction-v1','P1','SYNTH-P1-A',repeat('a',64),
 jsonb_build_object(
   'en',jsonb_build_object('question','Which fictional choice is labelled C?',
     'options',jsonb_build_array('Fictional A','Fictional B','Fictional C','Fictional D'),
     'explanation','Fictional outcome C is correct by synthetic test definition.'),
   'ru',jsonb_build_object('question','Какой условный вариант обозначен C?',
     'options',jsonb_build_array('Условно A','Условно B','Условно C','Условно D'),
     'explanation','Это синтетический тест корректного варианта C.'),
   'uz',jsonb_build_object('question','Qaysi shartli javob C deb belgilangan?',
     'options',jsonb_build_array('Shartli A','Shartli B','Shartli C','Shartli D'),
     'explanation','Bu sinov uchun C javobi to‘g‘ri deb belgilangan.')
 ),'C'),
('FICT-RETEST-B','fiction-v1','P1','SYNTH-P1-B',repeat('b',64),
 jsonb_build_object(
   'en',jsonb_build_object('question','Which fictional choice is labelled D?',
     'options',jsonb_build_array('Fictional A','Fictional B','Fictional C','Fictional D'),
     'explanation','Fictional outcome D is correct for the synthetic scenario.'),
   'ru',jsonb_build_object('question','Какой условный вариант обозначен D?',
     'options',jsonb_build_array('Условно A','Условно B','Условно C','Условно D'),
     'explanation','Это синтетический тест корректного варианта D.'),
   'uz',jsonb_build_object('question','Qaysi shartli javob D deb belgilangan?',
     'options',jsonb_build_array('Shartli A','Shartli B','Shartli C','Shartli D'),
     'explanation','Bu sinov uchun D javobi to‘g‘ri deb belgilangan.')
 ),'D');

-- As the synthetic authenticated learner, verify default OFF before release.
set role authenticated;
select set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',false);
select set_config('request.jwt.claims',jsonb_build_object(
 'sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
 'session_id','aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa',
 'exp',extract(epoch from clock_timestamp()+interval '1 hour')::bigint,
 'is_anonymous',false)::text,false);

do $$
begin
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_start_v1(
 '11111111-1111-4111-8111-111111111111',1,'off-case-123456789'),'not_available');
end $$;

-- With global OFF removed but content still unapproved, no question is issued.
reset role;
update private.iclub_econ_retest_control_v1 set issuance_enabled=true where id=1;
set role authenticated;
do $$
begin
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_start_v1(
 '11111111-1111-4111-8111-111111111111',1,'draft-case-1234567'),'no_unseen_approved_item');
end $$;

-- Academic and linguistic signoff is explicit and fictional.
reset role;
update private.iclub_econ_retest_sources_v1
 set academic_status='approved',language_status='pass',
 semantic_distinct_status='pass',release_enabled=true;
set role authenticated;
do $$
declare v jsonb; v_id uuid; v_get jsonb;
begin
  perform public.synthetic_expect_code_v1(public.iclub_econ_retest_start_v1(
    '22222222-2222-4222-8222-222222222222',1,'foreign-123456789'),'source_not_found');
  perform public.synthetic_expect_code_v1(public.iclub_econ_retest_start_v1(
    '11111111-1111-4111-8111-111111111111',2,'correct-123456789'),'not_an_error');
  perform public.synthetic_expect_code_v1(public.iclub_econ_retest_start_v1(
    '11111111-1111-4111-8111-111111111111',3,'unanswered-1234567'),'no_recorded_wrong_answer');
  v:=public.iclub_econ_retest_start_v1(
    '11111111-1111-4111-8111-111111111111',1,'right-1234567890');
  if v->>'ok' is distinct from 'true' or v->>'status' is distinct from 'active'
    or v->>'resumed' is distinct from 'false'
  then raise exception 'Valid owned wrong answer not issued: %',v; end if;
  v_id:=(v->>'session_id')::uuid;
  insert into public.synthetic_retest_run_v1 values ('first',v_id);
  v_get:=public.iclub_econ_retest_get_v1(v_id,'ru');
  if v_get->>'ok' is distinct from 'true'
      or v_get->>'question' is null
      or v_get->>'correct_index' is not null
      or v_get->>'explanation' is not null
      or v_get->>'is_correct' is not null
      or v_get::text like '%answer_key%'
  then raise exception 'Key leaked before completion: %',v_get; end if;
  v:=public.iclub_econ_retest_start_v1(
    '11111111-1111-4111-8111-111111111111',1,'right-1234567890');
  if v->>'session_id' is distinct from v_id::text
    or v->>'resumed' is distinct from 'true'
  then raise exception 'Retry not idempotent: %',v; end if;
  v:=public.iclub_econ_retest_start_v1(
    '11111111-1111-4111-8111-111111111111',1,'another-12345678');
  if v->>'session_id' is distinct from v_id::text
  then raise exception 'Concurrent source had second issuance: %',v; end if;
  v:=public.iclub_econ_retest_resume_v1(null);
  if v->>'session_id' is distinct from v_id::text
  then raise exception 'Active attempt not resumable: %',v; end if;
end $$;

-- Another authenticated user cannot read or submit somebody else's retest.
select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',false);
select set_config('request.jwt.claims',jsonb_build_object(
 'sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
 'session_id','bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb',
 'exp',extract(epoch from clock_timestamp()+interval '1 hour')::bigint,
 'is_anonymous',false)::text,false);
do $$
declare v_id uuid:=(select session_id from public.synthetic_retest_run_v1 where label='first');
begin
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_get_v1(v_id,'en'),'not_found');
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_submit_v1(v_id,2,'foreign-submit-98765'),'not_found');
end $$;

-- Anonymous Supabase Auth account is blocked even with a valid session.
select set_config('request.jwt.claim.sub','cccccccc-cccc-4ccc-8ccc-cccccccccccc',false);
select set_config('request.jwt.claims',jsonb_build_object(
 'sub','cccccccc-cccc-4ccc-8ccc-cccccccccccc',
 'session_id','cccccccc-3333-4333-8333-cccccccccccc',
 'exp',extract(epoch from clock_timestamp()+interval '1 hour')::bigint,
 'is_anonymous',true)::text,false);
do $$
begin
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_start_v1(
 '11111111-1111-4111-8111-111111111111',1,'anon-1234567890123'),'not_authorized');
end $$;

-- Return to A: server score only, then finished results become readable.
select set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',false);
select set_config('request.jwt.claims',jsonb_build_object(
 'sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
 'session_id','aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa',
 'exp',extract(epoch from clock_timestamp()+interval '1 hour')::bigint,
 'is_anonymous',false)::text,false);
do $$
declare v_id uuid:=(select session_id from public.synthetic_retest_run_v1 where label='first');
 v jsonb;
begin
 v:=public.iclub_econ_retest_submit_v1(v_id,2,'valid-submit-12345');
 if v->>'ok' is distinct from 'true' or v->>'status' is distinct from 'finalized'
   or v->>'is_correct' is distinct from 'true' then
   raise exception 'Server score mismatch: %',v; end if;
 v:=public.iclub_econ_retest_submit_v1(v_id,2,'valid-submit-12345');
 if v->>'duplicate' is distinct from 'true' then raise exception 'Duplicate submit altered state: %',v; end if;
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_submit_v1(
   v_id,1,'different-submit-12345'),'already_finalized');
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_start_v1(
   '11111111-1111-4111-8111-111111111111',1,'second-attempt-1234'),'already_retested');
 v:=public.iclub_econ_retest_get_v1(v_id,'uz');
 if v->>'status' is distinct from 'finalized'
   or v->>'correct_index' is distinct from '2'
   or v->>'is_correct' is distinct from 'true'
   or coalesce(length(v->>'explanation'),0)<5
 then raise exception 'Completed result unavailable: %',v; end if;
end $$;

-- Global kill switch blocks new issuance, not existing finished history.
reset role;
update private.iclub_econ_retest_control_v1 set issuance_enabled=false where id=1;
set role authenticated;
do $$
declare v_id uuid:=(select session_id from public.synthetic_retest_run_v1 where label='first');
begin
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_start_v1(
 '11111111-1111-4111-8111-111111111111',4,'kill-switch-1234567'),'not_available');
 if public.iclub_econ_retest_get_v1(v_id,'en')->>'status' is distinct from 'finalized'
 then raise exception 'Disabled issuance erased historical result'; end if;
end $$;

-- Second synthetic skill: expired active sessions cannot leak answers or take scores.
reset role;
update private.iclub_econ_retest_control_v1 set issuance_enabled=true where id=1;
set role authenticated;
do $$
declare v jsonb;
begin
 v:=public.iclub_econ_retest_start_v1(
    '11111111-1111-4111-8111-111111111111',4,'expires-123456789');
 if v->>'ok' is distinct from 'true' then raise exception 'Expected second issued item: %',v; end if;
 insert into public.synthetic_retest_run_v1 values ('expire',(v->>'session_id')::uuid);
end $$;
reset role;
update private.iclub_econ_retest_sessions_v1
 set deadline_at=clock_timestamp()-interval '2 seconds'
 where id=(select session_id from public.synthetic_retest_run_v1 where label='expire');
set role authenticated;
do $$
declare v_id uuid:=(select session_id from public.synthetic_retest_run_v1 where label='expire');
begin
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_get_v1(v_id,'en'),'expired');
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_submit_v1(
 v_id,3,'expired-submit-1234'),'expired');
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_start_v1(
 '11111111-1111-4111-8111-111111111111',4,'expires-123456789'),'prior_retest_expired');
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_start_v1(
 '11111111-1111-4111-8111-111111111111',4,'another-expired-12345'),'prior_retest_expired');
end $$;

-- Revoked server-side session fails even if JWT contents still appear valid.
reset role;
update auth.sessions set not_after=clock_timestamp()-interval '1 second'
  where id='aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa';
set role authenticated;
do $$
declare v_id uuid:=(select session_id from public.synthetic_retest_run_v1 where label='first');
begin
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_get_v1(v_id,'en'),'not_authorized');
 perform public.synthetic_expect_code_v1(public.iclub_econ_retest_start_v1(
 '11111111-1111-4111-8111-111111111111',4,'revoked-123456789'),'not_authorized');
end $$;
reset role;

-- If a newly created private session was changed by another user or if
-- a historical exam attempt was overwritten, fail the entire CI job.
do $$
begin
 if (select count(*) from private.iclub_exam_native_mcq_attempts_v1)<>2
 then raise exception 'Legacy attempts were altered/deleted'; end if;
 if (select count(*) from private.iclub_exam_native_mcq_attempts_v1
      where status='finalized' and responses='{"1":{"choice":0},"2":{"choice":0},"4":{"choice":1}}'::jsonb)=0
 then raise exception 'Legacy answers were overwritten'; end if;
 if (select count(*) from private.iclub_econ_retest_sessions_v1)<>2 then
  raise exception 'Unexpected retest session count'; end if;
end $$;
select 'SYNTHETIC ISOLATED RETEST E2E PASS' as status;
