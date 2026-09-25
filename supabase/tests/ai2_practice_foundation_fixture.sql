\set ON_ERROR_STOP on

-- AI-2 isolated fixture. Never run in production.
create schema if not exists private;

create table if not exists public.subjects (
  id bigint primary key,
  subject_key text not null unique,
  title text not null,
  type text,
  is_active boolean not null default true
);

insert into public.subjects(id,subject_key,title,type,is_active)
values(7,'economics','Economics','main',true)
on conflict(id) do nothing;

alter table public.practice_attempts add column if not exists user_id uuid;
alter table public.practice_attempts add column if not exists subject_id bigint;
alter table public.practice_attempts add column if not exists score integer;
alter table public.practice_attempts add column if not exists percent numeric;
alter table public.practice_attempts add column if not exists time_seconds integer;
alter table public.practice_attempts add column if not exists created_at timestamptz not null default now();
alter table public.practice_attempts add column if not exists is_lab boolean not null default false;

alter table public.practice_answers add column if not exists attempt_id bigint;
alter table public.practice_answers add column if not exists question_id bigint;
alter table public.practice_answers add column if not exists user_answer text;
alter table public.practice_answers add column if not exists is_correct boolean;
alter table public.practice_answers add column if not exists time_spent integer;
alter table public.practice_answers add column if not exists created_at timestamptz not null default now();

alter table public.tour_attempts add column if not exists user_id uuid;
alter table public.tour_attempts add column if not exists tour_id bigint;
alter table public.tour_attempts add column if not exists status text;
alter table public.tour_attempts add column if not exists created_at timestamptz not null default now();

create table if not exists public.practice_sessions_v4 (
  id bigint generated always as identity primary key,
  user_id uuid not null,
  subject_id bigint not null,
  pool_id bigint,
  client_session_id text,
  question_ids bigint[] not null,
  legacy_attempt_id bigint,
  status text not null default 'in_progress',
  created_at timestamptz not null default now(),
  finalized_at timestamptz
);

create table if not exists public.practice_session_answers_v4 (
  session_id bigint not null,
  question_id bigint not null,
  user_answer text,
  picked_index integer,
  is_correct boolean not null,
  time_spent integer not null default 0,
  answered_at timestamptz not null default now(),
  primary key(session_id,question_id)
);

create table if not exists public.user_answer_diagnosis (
  id bigint generated always as identity primary key,
  user_id uuid not null,
  subject_id bigint not null,
  attempt_type text not null,
  attempt_id bigint not null,
  practice_answer_id bigint,
  tour_answer_id bigint,
  question_id bigint not null,
  selected_answer text,
  is_correct boolean not null,
  diagnostic_id bigint,
  mistake_type text,
  weak_skill text,
  feedback_ru text,
  feedback_uz text,
  feedback_en text,
  next_action_ru text,
  next_action_uz text,
  next_action_en text,
  created_at timestamptz not null default now()
);

create or replace function private.exam_prep_has_active_protected_assessment_v1(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path=''
as $$ select false; $$;

revoke all on function private.exam_prep_has_active_protected_assessment_v1(uuid)
  from public,anon,authenticated;
grant execute on function private.exam_prep_has_active_protected_assessment_v1(uuid)
  to service_role;
