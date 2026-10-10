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
-- Backfill before enabling immutability triggers. Existing sessions predate this registry.
-- A legacy session is generation 1 only when no later generation was active at creation.
update public.practice_sessions_v4 s set bank_generation=1
where bank_generation is null and not exists (
  select 1 from public.practice_bank_generations g
  where g.subject_id=s.subject_id and g.generation>1 and g.activated_at<=s.created_at
);
update public.practice_drill_sessions_v4 s set bank_generation=1
where bank_generation is null and not exists (
  select 1 from public.practice_bank_generations g
  where g.subject_id=s.subject_id and g.generation>1 and g.activated_at<=s.created_at
);
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
    -- Do not assign current generation based on write time.
    new.bank_generation := null;
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
