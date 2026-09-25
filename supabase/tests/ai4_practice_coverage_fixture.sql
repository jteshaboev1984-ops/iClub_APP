\set ON_ERROR_STOP on

create table if not exists public.practice_pools (
  id bigint primary key,
  subject_id bigint not null,
  tour_no integer not null,
  title text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.practice_pool_questions (
  id bigint generated always as identity primary key,
  pool_id bigint not null,
  question_id bigint not null,
  order_no integer,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.question_answer_diagnostics (
  id bigint generated always as identity primary key,
  question_id bigint not null,
  is_correct boolean,
  mistake_type text,
  quality_status text
);
