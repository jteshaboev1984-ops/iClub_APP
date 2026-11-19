-- #574 · disposable PostgreSQL 17 only; NO production data.
\set ON_ERROR_STOP on

create role authenticated;
create role anon;
create schema auth;
create function auth.uid() returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;

create table public.subjects(id bigint primary key,subject_key text unique,is_active boolean);
create table public.seasons(id bigint primary key,season_no integer,status text,start_date date);
create table public.practice_attempts(
 id bigint primary key,user_id uuid,subject_id bigint,
 created_at timestamptz,is_lab boolean,score integer,percent integer,time_seconds integer
);
create table public.practice_drill_sessions_v4(
 id bigint primary key,user_id uuid,subject_id bigint,created_at timestamptz,
 status text,drill_type text,client_session_id text
);
create table public.practice_drill_answers_v4(
 id bigint primary key,session_id bigint,is_correct boolean
);
grant usage on schema public,auth to authenticated,anon;
grant execute on function auth.uid() to authenticated,anon;

insert into public.subjects values
 (5,'mathematics',true),(4,'chemistry',true);
insert into public.seasons values
 (2,2,'draft',null);
insert into public.practice_attempts values
 (101,'11111111-1111-4111-8111-111111111111',5,'2026-10-31T18:59:59+00',false,6,60,100),
 (102,'11111111-1111-4111-8111-111111111111',5,'2026-10-31T19:00:00+00',false,8,80,90),
 (103,'11111111-1111-4111-8111-111111111111',5,'2026-11-02T10:00:00+00',false,9,90,75),
 (104,'11111111-1111-4111-8111-111111111111',5,'2026-11-03T10:00:00+00',true,10,100,30),
 (105,'22222222-2222-4222-8222-222222222222',5,'2026-11-04T10:00:00+00',false,10,100,30),
 (106,'11111111-1111-4111-8111-111111111111',4,'2026-11-04T10:00:00+00',false,7,70,50);
insert into public.practice_drill_sessions_v4 values
 (201,'11111111-1111-4111-8111-111111111111',5,'2026-10-31T18:59:59+00','finalized','rec_topic','practice_topic_choice_old'),
 (202,'11111111-1111-4111-8111-111111111111',5,'2026-10-31T19:00:00+00','finalized','rec_topic','practice_topic_choice_new'),
 (203,'11111111-1111-4111-8111-111111111111',5,'2026-11-02T10:00:00+00','in_progress','rec_topic','practice_topic_choice_open'),
 (204,'22222222-2222-4222-8222-222222222222',5,'2026-11-02T10:00:00+00','finalized','rec_topic','practice_topic_choice_other'),
 (205,'11111111-1111-4111-8111-111111111111',5,'2026-11-03T10:00:00+00','finalized','another_drill','not_topic_choice_foo');
insert into public.practice_drill_answers_v4 values
 (301,201,true),(302,202,true),(303,202,false),(304,203,true),(305,204,true);

\i supabase/candidates/practice_season2_progress_safe_v1.sql

-- All evaluation steps rolled back; source fixture lives only in disposable PG17.
begin;
-- No raw read access to answer, attempt or session tables for authenticated.
set role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
do $audit$
declare v jsonb;
begin
  v:=public.get_practice_season2_progress_safe_v1('mathematics');
  if v->>'period_active' <> 'false' or v->>'reason' <> 'season_not_started' then
    raise exception 'draft season improperly triggered Practice reset';
  end if;
  begin
    perform count(*) from public.practice_attempts;
    raise exception 'authenticated raw attempts access unexpectedly allowed';
  exception when insufficient_privilege then null; end;
end
$audit$;
reset role;

update public.seasons set status='current',start_date='2026-11-01' where id=2;

set role authenticated;
do $audit$
declare v jsonb;
begin
  v:=public.get_practice_season2_progress_safe_v1('Mathematics');
  if v->>'period_active' <> 'true'
     or (v->'main'->>'attempts_count')::integer <> 2
     or (v->'main'->>'archived_attempts_count')::integer <> 1
     or (v->'main'->'best'->>'id')::integer <> 103
     or jsonb_array_length(v->'main'->'recent') <> 2
     or (v->'topic'->>'sessions_count')::integer <> 1
     or (v->'topic'->>'archived_sessions_count')::integer <> 1
     or (v->'topic'->>'correct')::integer <> 1
     or (v->'topic'->>'answered')::integer <> 2
     or left(v->>'period_starts_at',19) <> '2026-10-31T19:00:00' then
    raise exception 'Practice S2 owner/period filter regression (metadata only)';
  end if;
  if (public.get_practice_season2_progress_safe_v1('chemistry')->'main'->>'attempts_count')::int <> 1 then
    raise exception 'subject separation failed';
  end if;
  begin
    perform public.get_practice_season2_progress_safe_v1('unknown');
    raise exception 'unknown subject was accepted';
  exception when sqlstate 'P0002' then null; end;
end
$audit$;
select set_config('request.jwt.claim.sub','',false);
do $audit$
begin
  begin
    perform public.get_practice_season2_progress_safe_v1('mathematics');
    raise exception 'anonymous user incorrectly authenticated';
  exception when sqlstate '28000' then null; end;
end
$audit$;
reset role;
update public.seasons set status='closed' where id=2;
set role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
do $audit$
begin
  if (public.get_practice_season2_progress_safe_v1('mathematics')->>'period_active') <> 'true' then
    raise exception 'closed S2 archive period disappeared';
  end if;
end
$audit$;
reset role;

-- All rows remain exactly as before tests; only synthetic season fixture was toggled.
do $integrity$
begin
 if (select count(*) from public.practice_attempts) <> 6
    or (select count(*) from public.practice_drill_sessions_v4) <> 5
    or (select count(*) from public.practice_drill_answers_v4) <> 5 then
   raise exception 'history mutated by read-only progress RPC';
 end if;
 raise notice 'PRACTICE_SEASON2_PROGRESS_PG17_SYNTHETIC_PASS';
end
$integrity$;
rollback;
