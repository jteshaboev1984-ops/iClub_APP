\set ON_ERROR_STOP on

-- Minimal legacy subject contract for isolated commercial-access tests.
-- Test-only. Mirrors only the columns used by the new lifecycle/access migration.

create table if not exists public.subjects (
  id integer primary key,
  subject_key text not null unique,
  title text not null,
  type text not null,
  is_active boolean not null default true
);

create table if not exists public.user_subjects (
  user_id uuid not null references public.users(id) on delete cascade,
  subject_id integer not null references public.subjects(id) on delete cascade,
  mode text not null check (mode in ('study','competitive')),
  is_pinned boolean not null default false,
  primary key(user_id,subject_id)
);

insert into public.subjects(id,subject_key,title,type,is_active) values
  (1,'mathematics','Mathematics','main',true),
  (2,'biology','Biology','main',true),
  (3,'chemistry','Chemistry','main',true),
  (4,'economics','Economics','main',true),
  (5,'informatics','Informatics','main',true),
  (6,'english_a1','English A1','additional',false)
on conflict(id) do nothing;

grant select,insert,update,delete on public.subjects to service_role;
grant select,insert,update,delete on public.user_subjects to service_role;
