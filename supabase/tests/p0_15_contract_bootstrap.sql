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

-- History-bearing legacy tables are deliberately empty. P0-15 only requires
-- their existence to prove that the Exam Prep drill does not mutate them.
create table if not exists public.questions (
  id bigint generated always as identity primary key
);
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
