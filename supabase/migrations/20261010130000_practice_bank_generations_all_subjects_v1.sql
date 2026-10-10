-- STAGED: all-subject Practice bank generations. Do not apply to production before QA.
-- Additive: no deletion, no progress reset, no publication or notification.
begin;
create table if not exists public.practice_bank_generations (
  subject_id bigint not null references public.subjects(id) on delete restrict,
  generation integer not null check (generation >= 1),
  activated_at timestamptz not null,
  release_key text,
  primary key(subject_id,generation),
  unique(subject_id,activated_at)
);
comment on table public.practice_bank_generations is
  'Per-subject Practice bank epochs. Only explicit audited full-bank replacement adds a generation.';
insert into public.practice_bank_generations(subject_id,generation,activated_at,release_key)
select id,1,'-infinity'::timestamptz,'legacy'
from public.subjects on conflict (subject_id,generation) do nothing;
-- The Mathematics v2 activation is verified by the existing publication audit.
-- All other subjects remain generation 1 until their own audited publication.
insert into public.practice_bank_generations(subject_id,generation,activated_at,release_key)
select subject_id,2,completed_at,release_version
from private.practice_v2_release_switch_audit
where release_version='math_p1_practice_v2_2026_10_07'
  and status='published' and completed_at is not null
on conflict (subject_id,generation) do nothing;
alter table public.practice_sessions_v4 add column if not exists bank_generation integer;
alter table public.practice_drill_sessions_v4 add column if not exists bank_generation integer;
alter table public.practice_attempts add column if not exists bank_generation integer;
alter table public.recommendations add column if not exists bank_generation integer;
alter table public.recommendations add column if not exists practice_session_id bigint
  references public.practice_sessions_v4(id);
alter table public.recommendations add column if not exists practice_drill_session_id bigint
  references public.practice_drill_sessions_v4(id);
create index if not exists recommendations_practice_bank_lookup_idx
  on public.recommendations(user_id,subject_id,bank_generation,created_at desc)
  where source_type='practice';
create or replace function public.practice_stamp_bank_generation_v1()
returns trigger language plpgsql security definer
set search_path = pg_catalog,public,pg_temp as $$
declare v_generation integer;
begin
  if tg_op='UPDATE' then
    if new.subject_id is distinct from old.subject_id
      or new.bank_generation is distinct from old.bank_generation then
      raise exception 'practice_bank_generation_immutable';
    end if;
    return new;
  end if;
  select generation into v_generation from public.practice_bank_generations
  where subject_id=new.subject_id and activated_at <= statement_timestamp()
  order by activated_at desc,generation desc limit 1;
  if v_generation is null then\n    -- Newly added subjects begin at generation 1 without breaking session creation.\n    v_generation := 1;\n  end if;
  new.bank_generation := v_generation;
  return new;
end $$;
-- Historical sessions retain the generation active when questions were issued.
update public.practice_sessions_v4 s set bank_generation=(
 select g.generation from public.practice_bank_generations g
 where g.subject_id=s.subject_id and g.activated_at<=s.created_at
 order by g.activated_at desc,g.generation desc limit 1
) where s.bank_generation is null;
update public.practice_drill_sessions_v4 s set bank_generation=(
 select g.generation from public.practice_bank_generations g
 where g.subject_id=s.subject_id and g.activated_at<=s.created_at
 order by g.activated_at desc,g.generation desc limit 1
) where s.bank_generation is null;
-- Old attempts lack a reliable start timestamp. Only attempts definitively
-- predating the first replacement are safely assigned generation 1.
update public.practice_attempts a set bank_generation=1
where bank_generation is null and not exists (
 select 1 from public.practice_bank_generations g
 where g.subject_id=a.subject_id and g.generation>1 and g.activated_at<=a.created_at
);
-- Legacy recommendations are time-classified once using the exact audited
-- publication boundary. New recommendations require a linked server session.
update public.recommendations r set bank_generation=(
 select g.generation from public.practice_bank_generations g
 where g.subject_id=r.subject_id and g.activated_at<=r.created_at
 order by g.activated_at desc,g.generation desc limit 1
) where r.source_type='practice' and r.bank_generation is null;
drop trigger if exists practice_stamp_bank_generation_v1 on public.practice_sessions_v4;
create trigger practice_stamp_bank_generation_v1 before insert or update
on public.practice_sessions_v4 for each row execute function public.practice_stamp_bank_generation_v1();
drop trigger if exists practice_drill_stamp_bank_generation_v1 on public.practice_drill_sessions_v4;
create trigger practice_drill_stamp_bank_generation_v1 before insert or update
on public.practice_drill_sessions_v4 for each row execute function public.practice_stamp_bank_generation_v1();
-- Existing legacy attempts and unlinked recommendations remain NULL until audited backfill.
-- Origin-linked recommendations get their generation from the server-owned session.
create or replace function public.practice_stamp_recommendation_generation_v1()
returns trigger language plpgsql security definer
set search_path = pg_catalog,public,pg_temp as $$
declare v_subject bigint; v_user uuid; v_generation integer;
begin
  if new.source_type <> 'practice' then
    new.bank_generation := null;
    new.practice_session_id := null;
    new.practice_drill_session_id := null;
    return new;
  end if;
  if new.practice_session_id is not null and new.practice_drill_session_id is not null then
    raise exception 'multiple_practice_origins';
  end if;
  if new.practice_session_id is not null then
    select subject_id,user_id,bank_generation into v_subject,v_user,v_generation
    from public.practice_sessions_v4 where id=new.practice_session_id;
  elsif new.practice_drill_session_id is not null then
    select subject_id,user_id,bank_generation into v_subject,v_user,v_generation
    from public.practice_drill_sessions_v4 where id=new.practice_drill_session_id;
  else
    -- Preserve only the audited historical classification on updates.
    -- New unlinked recommendations never acquire an invented generation.
    if tg_op='UPDATE' and old.practice_session_id is null
      and old.practice_drill_session_id is null then
      new.bank_generation := old.bank_generation;
    else
      new.bank_generation := null;
    end if;
    return new;
  end if;
  if v_subject is null or v_subject <> new.subject_id or v_user <> new.user_id
    or v_generation is null then
    raise exception 'practice_recommendation_origin_mismatch';
  end if;
  new.bank_generation := v_generation;
  return new;
end $$;
drop trigger if exists practice_stamp_recommendation_generation_v1 on public.recommendations;
create trigger practice_stamp_recommendation_generation_v1 before insert or update
on public.recommendations for each row execute function public.practice_stamp_recommendation_generation_v1();
alter table public.practice_bank_generations enable row level security;
revoke all on public.practice_bank_generations from anon,authenticated;
revoke execute on function public.practice_stamp_bank_generation_v1() from public,anon,authenticated;
revoke execute on function public.practice_stamp_recommendation_generation_v1() from public,anon,authenticated;
commit;
