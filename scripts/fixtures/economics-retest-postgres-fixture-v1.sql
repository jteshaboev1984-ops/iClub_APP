-- Synthetic-only isolated PostgreSQL 17 setup for Economics retest contract.
-- No Supabase credentials, production IDs, learner data, or protected questions.
\set ON_ERROR_STOP on
begin;
create role anon nologin;
create role authenticated nologin;
create schema auth;
create schema private;
create table auth.users(id uuid primary key,is_anonymous boolean not null default false);
create table auth.sessions(id uuid primary key,user_id uuid not null references auth.users(id),
  not_after timestamptz);
create function auth.uid() returns uuid language sql stable set search_path='' as $$
  select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid;
$$;
create function auth.jwt() returns jsonb language sql stable set search_path='' as $$
  select nullif(current_setting('request.jwt.claims',true),'')::jsonb;
$$;
grant usage on schema public,auth to authenticated;
grant execute on function auth.uid(),auth.jwt() to authenticated;
create table private.iclub_exam_core_skills_v1(
  program_key text not null, version_key text not null, skill_key text not null,
  status text not null, level_code text not null,
  primary key(program_key,version_key,skill_key));
create table private.iclub_exam_core_paper_skills_v1(
  program_key text not null, version_key text not null,paper_code text not null,
  skill_key text not null, status text not null,link_role text not null,
  primary key(program_key,version_key,paper_code,skill_key,link_role));
create table private.iclub_exam_native_mcq_attempts_v1(
  id uuid primary key, user_id uuid not null references auth.users(id),
  program_key text not null,version_key text not null,paper_code text not null,
  status text not null, finalized_at timestamptz,
  items jsonb not null, responses jsonb not null default '{}'::jsonb);
create table private.synthetic_access_v1(user_id uuid primary key references auth.users(id),
  authorized boolean not null default false);
create function private.iclub_exam_native_mcq_enrolled_v1(p_user uuid)
 returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from private.synthetic_access_v1 where user_id=p_user and authorized);
 $$;
create function private.iclub_exam_native_economics_beta_allowed_v1(p_user uuid)
 returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from private.synthetic_access_v1 where user_id=p_user and authorized);
 $$;
commit;

-- Synthetic identities cannot correspond to any real Supabase user.
insert into auth.users(id,is_anonymous) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',false),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',false),
 ('cccccccc-cccc-4ccc-8ccc-cccccccccccc',true);
insert into auth.sessions(id,user_id,not_after) values
 ('aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',clock_timestamp()+interval '2 hours'),
 ('bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',clock_timestamp()+interval '2 hours'),
 ('cccccccc-3333-4333-8333-cccccccccccc','cccccccc-cccc-4ccc-8ccc-cccccccccccc',clock_timestamp()+interval '2 hours');
insert into private.synthetic_access_v1(user_id,authorized) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',true),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',true),
 ('cccccccc-cccc-4ccc-8ccc-cccccccccccc',true);
insert into private.iclub_exam_core_skills_v1(program_key,version_key,skill_key,status,level_code) values
 ('economics_9708','economics_2026_2028_v1','SYNTH-P1-A','reviewed','AS'),
 ('economics_9708','economics_2026_2028_v1','SYNTH-P1-B','reviewed','AS');
insert into private.iclub_exam_core_paper_skills_v1(program_key,version_key,paper_code,skill_key,status,link_role) values
 ('economics_9708','economics_2026_2028_v1','P1','SYNTH-P1-A','approved','direct'),
 ('economics_9708','economics_2026_2028_v1','P1','SYNTH-P1-B','approved','direct');
insert into private.iclub_exam_native_mcq_attempts_v1
(id,user_id,program_key,version_key,paper_code,status,finalized_at,items,responses)
select '11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
'economics_9708','economics_2026_2028_v1','P1','finalized',clock_timestamp()-interval '30 minutes',
'[
{"skill_key":"SYNTH-P1-A","key":"B","display_order":[0,1,2,3],"source_id":101,"snapshot_md5":"11111111111111111111111111111111"},
{"skill_key":"SYNTH-P1-A","key":"A","display_order":[0,1,2,3],"source_id":102,"snapshot_md5":"22222222222222222222222222222222"},
{"skill_key":"SYNTH-P1-B","key":"D","display_order":[0,1,2,3],"source_id":103,"snapshot_md5":"33333333333333333333333333333333"},
{"skill_key":"SYNTH-P1-B","key":"C","display_order":[0,1,2,3],"source_id":104,"snapshot_md5":"44444444444444444444444444444444"}
]'::jsonb,
'{"1":{"choice":0},"2":{"choice":0},"4":{"choice":1}}'::jsonb;
-- Second user's session: cannot be used by first user.
insert into private.iclub_exam_native_mcq_attempts_v1
select '22222222-2222-4222-8222-222222222222','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
'economics_9708','economics_2026_2028_v1','P1','finalized',clock_timestamp()-interval '30 minutes',
'[
{"skill_key":"SYNTH-P1-A","key":"B","display_order":[0,1,2,3],"source_id":999,"snapshot_md5":"ffffffffffffffffffffffffffffffff"},
{"skill_key":"SYNTH-P1-B","key":"D","display_order":[0,1,2,3],"source_id":998,"snapshot_md5":"eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"}
]'::jsonb,
'{"1":{"choice":0},"2":{"choice":0}}'::jsonb;

create table public.synthetic_retest_run_v1(label text primary key,session_id uuid);
grant select,insert on public.synthetic_retest_run_v1 to authenticated;
