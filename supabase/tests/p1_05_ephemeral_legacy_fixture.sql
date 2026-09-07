-- P1-05 ephemeral compatibility fixture for the minimal P0-15 CI database only.
-- Never run in production. It only enriches the deliberately skeletal legacy tables in CI.

\set ON_ERROR_STOP on

alter table public.practice_attempts add column if not exists user_id uuid;
alter table public.practice_attempts add column if not exists subject_id bigint;
alter table public.practice_attempts add column if not exists is_lab boolean not null default false;

alter table public.practice_answers add column if not exists attempt_id bigint;
alter table public.practice_answers add column if not exists question_id bigint;
alter table public.practice_answers add column if not exists user_answer text;
alter table public.practice_answers add column if not exists is_correct boolean not null default false;
alter table public.practice_answers add column if not exists time_spent integer not null default 0;
alter table public.practice_answers add column if not exists created_at timestamptz not null default now();

create table if not exists public.tours (
  id bigint generated always as identity primary key
);
alter table public.tours add column if not exists subject_id bigint;

alter table public.tour_attempts add column if not exists user_id uuid;
alter table public.tour_attempts add column if not exists tour_id bigint;

alter table public.tour_answers add column if not exists attempt_id bigint;
alter table public.tour_answers add column if not exists question_id bigint;
alter table public.tour_answers add column if not exists user_answer text;
alter table public.tour_answers add column if not exists answered boolean not null default true;
alter table public.tour_answers add column if not exists is_correct boolean not null default false;
alter table public.tour_answers add column if not exists time_spent integer not null default 0;
alter table public.tour_answers add column if not exists finish_reason text;
alter table public.tour_answers add column if not exists created_at timestamptz not null default now();

create table if not exists public.certificates (
  id bigint generated always as identity primary key
);
create table if not exists public.ratings_cache (
  id bigint generated always as identity primary key
);
