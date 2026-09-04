-- P0-15 isolated PostgreSQL/Supabase contract bootstrap.
-- Test-only. Creates the minimum pre-Exam-Prep contract required to apply the
-- real P0-04..P0-13 migrations in an ephemeral CI database.

\set ON_ERROR_STOP on

create extension if not exists pgcrypto;

-- Supabase client roles used by grants/RLS in production migrations.
do $$
begin
  if not exists (select 1 from pg_roles where rolname='anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname='authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname='service_role') then
    create role service_role nologin bypassrls;
  end if;
end
$$;

create schema if not exists auth;

-- Minimal auth.uid() compatible with request.jwt.claim.sub used by the app RPCs.
create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true),'')::uuid;
$$;

grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;

-- Minimal auth identity table. The P0-15 harness writes synthetic identities
-- here only to preserve the production-style FK contract; everything rolls back.
create table if not exists auth.users (
  id uuid primary key,
  aud text,
  role text,
  email text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_sso_user boolean not null default false,
  is_anonymous boolean not null default false
);

-- Minimal legacy public user contract used by Exam Prep foreign keys.
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text,
  last_name text,
  language_code text,
  created_at timestamptz not null default now(),
  must_change_password boolean not null default false
);

-- P0-07 reads the existing P1 question inventory but never mutates it. Recreate
-- only the columns used by the real mapping/QA migrations and seed the exact
-- legacy IDs they reference with safe published tri-language placeholders.
create table if not exists public.questions (
  id bigint primary key,
  subject_id integer not null,
  topic text,
  subtopic text,
  difficulty text,
  qtype text,
  question_text text,
  options_text text,
  correct_answer text,
  explanation text,
  image_url text,
  is_active boolean not null default true,
  question_text_ru text,
  question_text_uz text,
  question_text_en text,
  options_text_ru text,
  options_text_uz text,
  options_text_en text,
  explanation_ru text,
  explanation_uz text,
  explanation_en text,
  book_ref text,
  time_limit_sec integer,
  quality_flag text,
  quality_status text
);

insert into public.questions(
  id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
  explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,
  options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,
  explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select qid,5,'P1 test contract','safe launch candidate','medium','mcq',
       'Contract question '||qid,'A|B|C|D','A','Contract explanation',null,true,
       'RU contract question '||qid,'UZ contract question '||qid,'EN contract question '||qid,
       'A|B|C|D','A|B|C|D','A|B|C|D',
       'RU explanation','UZ explanation','EN explanation','P0-15 contract',60,null,'published'
from unnest(array[
  6014,6013,1516,6035,6036,6040,2691,2721,6052,6089,6099,6100,6093,6090,2833,
  2984,3274,2759,6077,6078,6110,6120,6115,6116,6129,6135,6132,6140,6139,6054,2958
]::bigint[]) as q(qid)
on conflict(id) do nothing;

-- Remaining history-bearing legacy tables are deliberately empty. P0-15 only
-- requires their existence to prove the Exam Prep drill does not mutate them.
create table if not exists public.practice_attempts (
  id bigint generated always as identity primary key
);
create table if not exists public.practice_answers (
  id bigint generated always as identity primary key
);
create table if not exists public.tour_attempts (
  id bigint generated always as identity primary key
);
create table if not exists public.tour_answers (
  id bigint generated always as identity primary key
);
create table if not exists public.ratings_cache (
  id bigint generated always as identity primary key
);
create table if not exists public.certificates (
  id bigint generated always as identity primary key
);

grant usage on schema public to anon, authenticated, service_role;
