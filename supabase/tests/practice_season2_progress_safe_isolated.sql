-- #574 · disposable PostgreSQL 17 only; NO production data.
\set ON_ERROR_STOP on

create role authenticated;
create role anon;
create schema auth;
create function auth.uid() returns uuid language sql stable
as $$ select coalesce(nullif(current_setting('request.jwt.claim.sub',true),''),
  nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'sub')::uuid $$;

create table public.subjects(id bigint primary key,subject_key text unique,is_active boolean);
create table public.seasons(id bigint primary key,season_no integer,status text,start_date date);
create table public.tours(
 id bigint primary key,season_id bigint,subject_id bigint,tour_no smallint,
 start_date date,end_date date,is_active boolean
);
create table public.practice_attempts(
 id bigint primary key,user_id uuid,subject_id bigint,
 created_at timestamptz,is_lab boolean,score integer,percent integer,time_seconds integer
);
create table public.practice_drill_sessions_v4(
 id bigint primary key,user_id uuid,subject_id bigint,created_at timestamptz,
 status text,drill_type text,client_session_id text,topic text
);
create table public.practice_drill_answers_v4(
 id bigint primary key,session_id bigint,is_correct boolean
);
grant usage on schema public,auth to authenticated,anon;
grant execute on function auth.uid() to authenticated,anon;

insert into public.subjects values
 (5,'mathematics',true),(4,'chemistry',true);
insert into public.seasons values
 (1,1,'closed',null),
 (2,2,'draft','2026-11-03');
-- Intentional mismatch: seasons.start_date is NOT the approved Practice cutoff.
insert into public.tours values
 (499,1,5,1,'2026-10-31','2026-11-01',false),
 (498,1,4,1,'2026-10-31','2026-11-01',false),
 (500,2,5,1,'2026-11-01','2026-11-07',true),
 (501,2,4,1,null,null,false);
insert into public.practice_attempts values
 (101,'11111111-1111-4111-8111-111111111111',5,'2026-10-31T18:59:59+00',false,6,60,100),
 (102,'11111111-1111-4111-8111-111111111111',5,'2026-10-31T19:00:00+00',false,8,80,90),
 (103,'11111111-1111-4111-8111-111111111111',5,'2026-11-02T10:00:00+00',false,9,90,75),
 (104,'11111111-1111-4111-8111-111111111111',5,'2026-11-03T10:00:00+00',true,10,100,30),
 (105,'22222222-2222-4222-8222-222222222222',5,'2026-11-04T10:00:00+00',false,10,100,30),
 (106,'11111111-1111-4111-8111-111111111111',4,'2026-11-04T10:00:00+00',false,7,70,50);
insert into public.practice_drill_sessions_v4 values
 (201,'11111111-1111-4111-8111-111111111111',5,'2026-10-31T18:59:59+00','finalized','rec_topic','practice_topic_choice_old','Synthetic topic'),
 (202,'11111111-1111-4111-8111-111111111111',5,'2026-10-31T19:00:00+00','finalized','rec_topic','practice_topic_choice_new','Synthetic topic'),
 (203,'11111111-1111-4111-8111-111111111111',5,'2026-11-02T10:00:00+00','in_progress','rec_topic','practice_topic_choice_open','Synthetic topic'),
 (204,'22222222-2222-4222-8222-222222222222',5,'2026-11-02T10:00:00+00','finalized','rec_topic','practice_topic_choice_other','Synthetic topic'),
 (205,'11111111-1111-4111-8111-111111111111',5,'2026-11-03T10:00:00+00','finalized','another_drill','not_topic_choice_foo','Synthetic topic');
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
  if (v->'practice_access'->>'open_season_no')::int<>1
     or (v->'practice_access'->>'season1_new_attempts_open')::boolean is not true
     or (v->'practice_access'->>'season2_new_attempts_open')::boolean is not false
     or (v->'history_snapshot'->>'practice_open')::boolean is not true
  then raise exception 'Season1 Practice must remain open while S2 draft';end if;
  if (v->'history_snapshot'->>'period_active')<>'true'
     or (v->'history_snapshot'->>'season_no')::int<>1
     or v->'history_snapshot'->>'period_status'<>'closed'
     or (v->'history_snapshot'->'main'->>'attempts_count')::int<>3
     or (v->'history_snapshot'->'topic'->>'sessions_count')::int<>2
     or (v->'history_snapshot'->'main'->>'archived_attempts_count')::int<>0
     or jsonb_array_length(v->'history_snapshot'->'archive_seasons')<>0
  then
    raise exception 'closed Season1 fallback missing or mislabeled while S2 draft';
  end if;
  if (public.get_practice_season2_progress_safe_v1('chemistry')->'practice_access'->>'open_season_no')::int<>1
     or (public.get_practice_season2_progress_safe_v1('chemistry')->'history_snapshot'->>'practice_open')::boolean is not true
  then raise exception 'other subject Season1 Practice closed without own S2 Tour1';end if;
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
     or (v->'practice_access'->>'open_season_no')::int<>2
     or (v->'practice_access'->>'season1_new_attempts_open')::boolean is not false
     or (v->'practice_access'->>'season2_new_attempts_open')::boolean is not true
     or (v->'main'->>'attempts_count')::integer <> 2
     or (v->'main'->>'archived_attempts_count')::integer <> 1
     or (v->'main'->'best'->>'id')::integer <> 103
     or jsonb_array_length(v->'main'->'recent') <> 2
     or (v->'topic'->>'sessions_count')::integer <> 1
     or (v->'topic'->>'archived_sessions_count')::integer <> 1
     or (v->'topic'->>'correct')::integer <> 1
     or (v->'topic'->>'answered')::integer <> 2
     or jsonb_array_length(v->'main'->'recent') <> 2
     or jsonb_array_length(v->'main'->'archived_recent') <> 1
     or (v->'main'->'archived_recent'->0->>'id')::integer <> 101
     or jsonb_array_length(v->'topic'->'recent') <> 1
     or jsonb_array_length(v->'topic'->'archived_recent') <> 1
     or (v->'topic'->'recent'->0->>'correct')::integer <> 1
     or (v->'topic'->'recent'->0->>'total')::integer <> 2
     or left(v->>'period_starts_at',19) <> '2026-10-31T19:00:00' then
    raise exception 'Practice S2 owner/period filter regression (metadata only)';
  end if;
  if (public.get_practice_season2_progress_safe_v1('chemistry')->>'period_active') <> 'false'
     or (public.get_practice_season2_progress_safe_v1('chemistry')->'practice_access'->>'open_season_no')::int<>1
  then raise exception 'Chemistry S1 Practice closed by unrelated Math S2';end if;
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

-- Each subject begins ONLY with its own Tour1 official calendar start.
update public.tours set start_date='2026-11-05',end_date='2026-11-11',
  is_active=true where id=501;
set role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
do $per_subject$
begin
  if (public.get_practice_season2_progress_safe_v1('chemistry')->>'period_active') <> 'true'
     or (public.get_practice_season2_progress_safe_v1('chemistry')->'practice_access'->>'open_season_no')::int<>2
     or (public.get_practice_season2_progress_safe_v1('chemistry')->'practice_access'->>'season1_new_attempts_open')::boolean is not false
     or (public.get_practice_season2_progress_safe_v1('chemistry')->'main'->>'attempts_count')::int <> 0
     or (public.get_practice_season2_progress_safe_v1('chemistry')->'main'->>'archived_attempts_count')::int <> 1
  then
    raise exception 'chemistry own Tour1 start boundary not respected';
  end if;
end
$per_subject$;
reset role;
-- Restore undated Chemistry for the subsequent signed HTTP test fixture.
update public.tours set start_date=null,end_date=null,is_active=false where id=501;
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

-- Historical period swipe contract: S1 is identified only by the released
-- Tour1 cutoff; older legacy work never inherits the Season1 label.
-- These rows are synthetic and remain in the outer ROLLBACK.
insert into public.practice_attempts values
 (107,'11111111-1111-4111-8111-111111111111',5,'2026-10-30T12:00:00Z',false,3,30,170);
insert into public.practice_drill_sessions_v4 values
 (206,'11111111-1111-4111-8111-111111111111',5,
 '2026-10-30T12:00:00Z','finalized','rec_topic','practice_topic_choice_legacy','Synthetic historical topic');
insert into public.practice_drill_answers_v4 values (306,206,true);

set role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
do $season_rail$
declare v jsonb; a jsonb;
begin
  v:=public.get_practice_season2_progress_safe_v1('mathematics');
  a:=v->'archive_seasons';
  if jsonb_array_length(a) <> 2
    or a->0->>'key'<>'season-1'
    or (a->0->>'season_no')::int<>1
    or (a->0->'main'->>'attempts_count')::int<>1
    or (a->0->'topic'->>'sessions_count')::int<>1
    or a->1->>'key'<>'legacy'
    or (a->1->'main'->>'attempts_count')::int<>1
    or (a->1->'topic'->>'sessions_count')::int<>1
    or (v->'main'->>'archived_attempts_count')::int<>2
    or (v->'topic'->>'archived_sessions_count')::int<>2
    or (select sum((x->'main'->>'attempts_count')::int) from jsonb_array_elements(a) x)<>2
  then
    raise exception 'Season swipe periods mislabel or omit owner history';
  end if;
  if (public.get_practice_season2_progress_safe_v1('chemistry')->>'period_active')<>'false'
  then raise exception 'Chemistry season inherited Mathematics Tour1';end if;
end
$season_rail$;
reset role;
do $season_rail_notice$ begin
  raise notice 'SEASON_ARCHIVE_SWIPE_PERIODS_PASS';
end $season_rail_notice$;

-- The previous S1 History must remain discoverable while S2 is draft,
-- including owner records preceding the verified Season1 Tour1 boundary.
-- S2 reset stays dormant and no completed Season1 is called "current".
update public.seasons set status='draft' where id=2;
set role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
do $s1_fallback$
declare v jsonb; h jsonb; a jsonb;
begin
  v:=public.get_practice_season2_progress_safe_v1('mathematics');
  h:=v->'history_snapshot';
  a:=h->'archive_seasons';
  if v->>'period_active'<>'false'
     or (h->>'season_no')::int<>1
     or h->>'period_status'<>'closed'
     or (h->'main'->>'attempts_count')::int<>3
     or (h->'topic'->>'sessions_count')::int<>2
     or (h->'main'->>'archived_attempts_count')::int<>1
     or (h->'topic'->>'archived_sessions_count')::int<>1
     or jsonb_array_length(a)<>1
     or a->0->>'key'<>'legacy'
     or (a->0->'main'->>'attempts_count')::int<>1
     or (a->0->'topic'->>'sessions_count')::int<>1
     or (h->'main'->'recent'->0->>'id')::int<>103
  then raise exception 'owner-scoped S1 fallback / legacy split regression';
  end if;
  if (public.get_practice_season2_progress_safe_v1('chemistry')->'practice_access'->>'open_season_no')::int<>1
     or (public.get_practice_season2_progress_safe_v1('chemistry')->'history_snapshot'->>'practice_open')::boolean is not true
  then raise exception 'undated Chemistry should remain S1 Practice despite Math S2 draft';end if;
end $s1_fallback$;
select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',false);
do $owner_isolation$
declare h jsonb;
begin
  h:=public.get_practice_season2_progress_safe_v1('mathematics')->'history_snapshot';
  if (h->'main'->>'attempts_count')::int<>1
    or (h->'topic'->>'sessions_count')::int<>1
    or (h->'main'->>'archived_attempts_count')::int<>0
    or (h->'main'->'recent'->0->>'id')::int<>105
  then raise exception 'cross-user S1 fallback data exposed or omitted';end if;
end $owner_isolation$;
reset role;
do $s1_fallback_notice$ begin
  raise notice 'PRACTICE_S1_DORMANT_S2_HISTORY_PG17_PASS';
end $s1_fallback_notice$;

rollback;
