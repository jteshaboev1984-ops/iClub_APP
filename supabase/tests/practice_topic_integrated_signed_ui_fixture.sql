-- #574: attach actual installed catalog + History RPC to synthetic Topic PG17.
-- Run AFTER practice_topic_crosscutover_isolated.sql on its disposable database.
-- All sample names/answers are synthetic. Never point at hosted Supabase.
\set ON_ERROR_STOP on
alter table public.subjects add column is_active boolean not null default true;
create table public.practice_pools(
 id bigint primary key,subject_id bigint not null,is_active boolean not null);
create table public.practice_pool_questions(
 pool_id bigint not null,question_id bigint not null,is_active boolean not null,
 primary key(pool_id,question_id));
create table public.tour_questions(question_id bigint not null);
create table private.practice_v2_question_meta(
 question_id bigint primary key, release_version text,
 lifecycle_state text,is_runtime_allowed boolean
);
insert into public.practice_pools values (501,5,true),(401,4,true);
insert into public.practice_pool_questions values
 (501,10,true),(501,11,true),(501,12,true),(501,14,true),(501,15,true),
 (401,13,true);
insert into private.practice_v2_question_meta
 (question_id,release_version,lifecycle_state,is_runtime_allowed) values
 (10,'math_p1_practice_v2_2026_10_07','published',true),
 (11,'math_p1_practice_v2_2026_10_07','published',true),
 (12,'math_p1_practice_v2_2026_10_07','published',true),
 (14,'math_p1_practice_v2_2026_10_07','published',true),
 (15,'math_p1_practice_v2_2026_10_07','published',true);
-- Synthetic other-owner completed attempt is used solely for strict History isolation.
update public.practice_drill_sessions_v4
   set status='finalized',finalized_at=now()
 where id=103;
insert into public.practice_drill_answers_v4(
 session_id,question_id,user_answer,is_correct,time_spent)
values(103,14,'RIGHT',true,9);

\i supabase/tests/fixtures/practice_topic_integrated_signed_catalog_history_20261120.sql
revoke all on function public.get_practice_available_topics_safe_v1(text)
 from public,anon;
revoke all on function public.get_practice_topic_history_safe_v1(text)
 from public,anon;
grant execute on function public.get_practice_available_topics_safe_v1(text)
 to authenticated;
grant execute on function public.get_practice_topic_history_safe_v1(text)
 to authenticated;

do $auth_gate$
begin
 if has_function_privilege('anon',
   'public.get_practice_available_topics_safe_v1(text)','EXECUTE')
 or has_function_privilege('anon',
   'public.get_practice_topic_history_safe_v1(text)','EXECUTE')
 then raise exception 'Anonymous Topic RPC permission regression';end if;
 if not has_function_privilege('authenticated',
   'public.get_practice_available_topics_safe_v1(text)','EXECUTE')
 or not has_function_privilege('authenticated',
   'public.get_practice_topic_history_safe_v1(text)','EXECUTE')
 then raise exception 'Signed Topic RPC permission missing';end if;
 if has_table_privilege('authenticated',
   'public.practice_drill_sessions_v4','SELECT')
 or has_table_privilege('authenticated',
   'public.practice_drill_answers_v4','SELECT')
 or has_table_privilege('authenticated',
   'private.practice_v2_question_meta','SELECT')
 then raise exception 'Raw question/session access leaked';end if;
end $auth_gate$;

select set_config('request.jwt.claim.sub',
 '11111111-1111-4111-8111-111111111111',false);
set role authenticated;
do $scoped$
declare m jsonb;c jsonb;h jsonb;
begin
 m:=public.get_practice_available_topics_safe_v1('mathematics');
 c:=public.get_practice_available_topics_safe_v1('chemistry');
 h:=public.get_practice_topic_history_safe_v1('mathematics');
 if m->>'subject_key'<>'mathematics'
 or jsonb_array_length(m->'topics')<>1
 or (m->'topics'->0->>'question_count')::int<>5
 or c->>'subject_key'<>'chemistry'
 or (c->'topics'->0->>'question_count')::int<>1
 or (h->>'completed_sessions')::int<>2
 or (h->>'total_correct_answers')::int<>2
 or (h->>'total_answered')::int<>3
 then raise exception 'Owner authenticated Topic catalog/history contract invalid';end if;
end $scoped$;
reset role;
select set_config('request.jwt.claim.sub',
 '22222222-2222-4222-8222-222222222222',false);
set role authenticated;
do $owner_b$
declare h jsonb;
begin
 h:=public.get_practice_topic_history_safe_v1('mathematics');
 if (h->>'completed_sessions')::int<>1
 or (h->>'total_correct_answers')::int<>1
 or (h->'recent'->0->>'session_id')::int<>103
 then raise exception 'Cross-owner Topic History leak or missing own attempt';end if;
end $owner_b$;
reset role;
select set_config('request.jwt.claim.sub','',false);
do $done$ begin raise notice 'PRACTICE_TOPIC_FULL_UI_INSTALLED_CATALOG_HISTORY_PG17_PASS'; end $done$;
