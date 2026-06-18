begin;

-- =========================================================
-- iClub Season 1 Foundation Safe
-- Purpose:
-- - mark existing tours/certificates/tour recommendations as Season 1
-- - prepare future repeated tour_no 1..7 by season
-- - keep practice global
-- - no Grand Final here
-- =========================================================

-- 1) Seasons
create table if not exists public.seasons (
  id bigserial primary key,
  season_no integer not null unique,
  title text not null,
  status text not null default 'draft',
  start_date date,
  end_date date,
  created_at timestamptz not null default now(),
  constraint seasons_status_check check (status in ('draft', 'current', 'closed'))
);

insert into public.seasons (season_no, title, status)
values (1, 'Season 1', 'closed')
on conflict (season_no) do update
set title = excluded.title,
    status = excluded.status;

insert into public.seasons (season_no, title, status)
values (2, 'Current', 'draft')
on conflict (season_no) do update
set title = excluded.title,
    status = excluded.status;

-- 2) Add season_id columns
alter table public.tours
  add column if not exists season_id bigint;

alter table public.certificates
  add column if not exists season_id bigint;

alter table public.recommendations
  add column if not exists season_id bigint;

-- 3) Foreign keys, safe DO blocks
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'tours_season_id_fkey'
  ) then
    alter table public.tours
      add constraint tours_season_id_fkey
      foreign key (season_id)
      references public.seasons(id)
      on delete restrict;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'certificates_season_id_fkey'
  ) then
    alter table public.certificates
      add constraint certificates_season_id_fkey
      foreign key (season_id)
      references public.seasons(id)
      on delete set null;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'recommendations_season_id_fkey'
  ) then
    alter table public.recommendations
      add constraint recommendations_season_id_fkey
      foreign key (season_id)
      references public.seasons(id)
      on delete set null;
  end if;
end $$;

-- 4) Backfill existing data to Season 1
update public.tours t
set season_id = s.id
from public.seasons s
where s.season_no = 1
  and t.season_id is null;

update public.certificates c
set season_id = s.id
from public.seasons s
where s.season_no = 1
  and c.season_id is null;

update public.recommendations r
set season_id = s.id
from public.seasons s
where s.season_no = 1
  and r.source_type = 'tour'
  and r.season_id is null;

-- practice recommendations stay global
update public.recommendations
set season_id = null
where source_type = 'practice';

-- 5) Prepare tours for repeated Tour 1..7 in future seasons
alter table public.tours
  alter column season_id set not null;

alter table public.tours
  drop constraint if exists tours_subject_id_tour_no_key;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'tours_season_subject_tour_no_key'
  ) then
    alter table public.tours
      add constraint tours_season_subject_tour_no_key
      unique (season_id, subject_id, tour_no);
  end if;
end $$;

-- 6) Indexes
create index if not exists tours_season_subject_idx
  on public.tours(season_id, subject_id, tour_no);

create index if not exists certificates_season_user_subject_idx
  on public.certificates(season_id, user_id, subject_id, certificate_type);

create index if not exists recommendations_tour_season_user_subject_idx
  on public.recommendations(season_id, user_id, subject_id, source_type, tour_no);

-- 7) Existing tour certificates must store season_id from their tour
create or replace function public.issue_tour_certificate(p_attempt_id bigint)
returns public.certificates
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_attempt public.tour_attempts%rowtype;
  v_tour public.tours%rowtype;
  v_user public.users%rowtype;
  v_existing public.certificates%rowtype;
  v_inserted public.certificates%rowtype;

  v_participants_total integer;
  v_rank_country integer;
  v_rank_region integer;
  v_rank_district integer;
begin
  select ta.*
    into v_attempt
  from public.tour_attempts ta
  where ta.id = p_attempt_id;

  if not found then
    raise exception 'issue_tour_certificate: attempt not found (%).', p_attempt_id;
  end if;

  if v_attempt.status not in ('submitted', 'time_expired') then
    raise exception 'issue_tour_certificate: invalid attempt status (%).', v_attempt.status;
  end if;

  select t.*
    into v_tour
  from public.tours t
  where t.id = v_attempt.tour_id;

  if not found then
    raise exception 'issue_tour_certificate: tour not found for attempt (%).', p_attempt_id;
  end if;

  if v_tour.start_date is not null and (v_attempt.created_at at time zone 'UTC')::date < v_tour.start_date then
    raise exception 'issue_tour_certificate: attempt before tour start.';
  end if;

  if v_tour.end_date is not null and (v_attempt.created_at at time zone 'UTC')::date > v_tour.end_date then
    raise exception 'issue_tour_certificate: attempt after tour end.';
  end if;

  select u.*
    into v_user
  from public.users u
  where u.id = v_attempt.user_id;

  if not found then
    raise exception 'issue_tour_certificate: user not found.';
  end if;

  select c.*
    into v_existing
  from public.certificates c
  where c.user_id = v_attempt.user_id
    and c.tour_id = v_attempt.tour_id
    and c.certificate_type = 'tour'
  limit 1;

  if found then
    if v_existing.season_id is null then
      update public.certificates
      set season_id = v_tour.season_id
      where id = v_existing.id
      returning * into v_existing;
    end if;

    return v_existing;
  end if;

  with valid_attempts as (
    select
      ta.user_id,
      ta.tour_id,
      ta.score,
      ta.percent,
      ta.total_time,
      u.region_id,
      u.district_id
    from public.tour_attempts ta
    join public.users u on u.id = ta.user_id
    where ta.tour_id = v_attempt.tour_id
      and ta.status in ('submitted', 'time_expired')
  ),
  ranked_country as (
    select
      va.*,
      row_number() over (
        order by va.score desc, va.total_time asc, va.user_id asc
      ) as rn_country
    from valid_attempts va
  ),
  ranked_region as (
    select
      va.*,
      row_number() over (
        partition by va.region_id
        order by va.score desc, va.total_time asc, va.user_id asc
      ) as rn_region
    from valid_attempts va
    where va.region_id is not null
  ),
  ranked_district as (
    select
      va.*,
      row_number() over (
        partition by va.district_id
        order by va.score desc, va.total_time asc, va.user_id asc
      ) as rn_district
    from valid_attempts va
    where va.district_id is not null
  )
  select
    (select count(*) from valid_attempts),
    (select rc.rn_country from ranked_country rc where rc.user_id = v_attempt.user_id limit 1),
    (select rr.rn_region from ranked_region rr where rr.user_id = v_attempt.user_id and rr.region_id = v_user.region_id limit 1),
    (select rd.rn_district from ranked_district rd where rd.user_id = v_attempt.user_id and rd.district_id = v_user.district_id limit 1)
  into
    v_participants_total,
    v_rank_country,
    v_rank_region,
    v_rank_district;

  insert into public.certificates (
    user_id,
    subject_id,
    tour_id,
    season_id,
    certificate_type,
    score,
    percent,
    rank_no,
    participants_total,
    rank_district,
    rank_region,
    rank_country,
    language_code,
    total_tours
  )
  values (
    v_attempt.user_id,
    v_tour.subject_id,
    v_attempt.tour_id,
    v_tour.season_id,
    'tour',
    v_attempt.score,
    v_attempt.percent,
    v_rank_country,
    coalesce(v_participants_total, 0),
    v_rank_district,
    v_rank_region,
    v_rank_country,
    coalesce(v_user.language_code, 'ru'),
    7
  )
  returning *
    into v_inserted;

  update public.certificates c
     set certificate_number = public.make_certificate_number(
       'tour',
       c.subject_id,
       c.tour_id,
       c.id
     )
   where c.id = v_inserted.id
  returning *
    into v_inserted;

  return v_inserted;
end;
$function$;

-- 8) Season-aware final certificate helper.
create or replace function public.issue_final_certificate_for_season(
  p_user_id uuid,
  p_subject_id bigint,
  p_season_id bigint
)
returns public.certificates
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user public.users%rowtype;
  v_existing public.certificates%rowtype;
  v_inserted public.certificates%rowtype;

  v_series_ready boolean;
  v_completed_tours integer;
  v_total_score integer;
  v_avg_percent numeric(5,2);
  v_total_time integer;

  v_participants_total integer;
  v_rank_country integer;
  v_rank_region integer;
  v_rank_district integer;
begin
  if p_season_id is null then
    raise exception 'issue_final_certificate_for_season: season_id is required.';
  end if;

  select u.*
    into v_user
  from public.users u
  where u.id = p_user_id;

  if not found then
    raise exception 'issue_final_certificate: user not found (%).', p_user_id;
  end if;

  select c.*
    into v_existing
  from public.certificates c
  where c.user_id = p_user_id
    and c.subject_id = p_subject_id
    and c.season_id = p_season_id
    and c.certificate_type = 'final'
  limit 1;

  if found then
    return v_existing;
  end if;

  with subject_tours as (
    select t.*
    from public.tours t
    where t.subject_id = p_subject_id
      and t.season_id = p_season_id
      and t.tour_no between 1 and 7
  )
  select
    count(distinct st.tour_no) = 7
    and bool_and(st.end_date is not null and st.end_date < current_date)
  into v_series_ready
  from subject_tours st;

  if coalesce(v_series_ready, false) = false then
    raise exception 'issue_final_certificate: subject season series is not finished yet.';
  end if;

  with my_valid_attempts as (
    select
      ta.tour_id,
      ta.score,
      ta.percent,
      ta.total_time
    from public.tour_attempts ta
    join public.tours t on t.id = ta.tour_id
    where ta.user_id = p_user_id
      and t.subject_id = p_subject_id
      and t.season_id = p_season_id
      and t.tour_no between 1 and 7
      and ta.status in ('submitted', 'time_expired')
  )
  select
    count(distinct mva.tour_id),
    coalesce(sum(mva.score), 0),
    coalesce(round(avg(mva.percent)::numeric, 2), 0),
    coalesce(sum(mva.total_time), 0)
  into
    v_completed_tours,
    v_total_score,
    v_avg_percent,
    v_total_time
  from my_valid_attempts mva;

  if coalesce(v_completed_tours, 0) = 0 then
    raise exception 'issue_final_certificate: user has no completed tours for this subject season.';
  end if;

  with all_valid_attempts as (
    select
      ta.user_id,
      t.subject_id,
      ta.tour_id,
      ta.score,
      ta.percent,
      ta.total_time,
      u.region_id,
      u.district_id
    from public.tour_attempts ta
    join public.tours t on t.id = ta.tour_id
    join public.users u on u.id = ta.user_id
    where t.subject_id = p_subject_id
      and t.season_id = p_season_id
      and t.tour_no between 1 and 7
      and ta.status in ('submitted', 'time_expired')
  ),
  aggregated as (
    select
      ava.user_id,
      max(ava.region_id) as region_id,
      max(ava.district_id) as district_id,
      count(distinct ava.tour_id) as completed_tours,
      sum(ava.score) as total_score,
      round(avg(ava.percent)::numeric, 2) as avg_percent,
      sum(ava.total_time) as total_time
    from all_valid_attempts ava
    group by ava.user_id
  ),
  ranked_country as (
    select
      a.*,
      row_number() over (
        order by a.total_score desc,
                 a.completed_tours desc,
                 a.total_time asc,
                 a.user_id asc
      ) as rn_country
    from aggregated a
  ),
  ranked_region as (
    select
      a.*,
      row_number() over (
        partition by a.region_id
        order by a.total_score desc,
                 a.completed_tours desc,
                 a.total_time asc,
                 a.user_id asc
      ) as rn_region
    from aggregated a
    where a.region_id is not null
  ),
  ranked_district as (
    select
      a.*,
      row_number() over (
        partition by a.district_id
        order by a.total_score desc,
                 a.completed_tours desc,
                 a.total_time asc,
                 a.user_id asc
      ) as rn_district
    from aggregated a
    where a.district_id is not null
  )
  select
    (select count(*) from aggregated),
    (select rc.rn_country from ranked_country rc where rc.user_id = p_user_id limit 1),
    (select rr.rn_region from ranked_region rr where rr.user_id = p_user_id and rr.region_id = v_user.region_id limit 1),
    (select rd.rn_district from ranked_district rd where rd.user_id = p_user_id and rd.district_id = v_user.district_id limit 1)
  into
    v_participants_total,
    v_rank_country,
    v_rank_region,
    v_rank_district;

  insert into public.certificates (
    user_id,
    subject_id,
    tour_id,
    season_id,
    certificate_type,
    score,
    percent,
    rank_no,
    participants_total,
    rank_district,
    rank_region,
    rank_country,
    language_code,
    completed_tours,
    total_tours
  )
  values (
    p_user_id,
    p_subject_id,
    null,
    p_season_id,
    'final',
    v_total_score,
    v_avg_percent,
    v_rank_country,
    coalesce(v_participants_total, 0),
    v_rank_district,
    v_rank_region,
    v_rank_country,
    coalesce(v_user.language_code, 'ru'),
    v_completed_tours,
    7
  )
  returning *
    into v_inserted;

  update public.certificates c
     set certificate_number = public.make_certificate_number(
       'final',
       c.subject_id,
       null,
       c.id
     )
   where c.id = v_inserted.id
  returning *
    into v_inserted;

  return v_inserted;
end;
$function$;

-- 9) Keep old RPC name safe for cached/current app clients.
create or replace function public.issue_final_certificate(
  p_user_id uuid,
  p_subject_id bigint
)
returns public.certificates
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_season_id bigint;
begin
  -- Pick the latest completed season for this subject.
  -- This keeps existing 2-arg app calls safe after introducing Season 2 draft/current.
  select s.id
    into v_season_id
  from public.seasons s
  where exists (
    select 1
    from public.tours t
    where t.season_id = s.id
      and t.subject_id = p_subject_id
      and t.tour_no between 1 and 7
    group by t.season_id
    having count(distinct t.tour_no) = 7
       and bool_and(t.end_date is not null and t.end_date < current_date)
  )
  order by s.season_no desc
  limit 1;

  if v_season_id is null then
    raise exception 'issue_final_certificate: no completed season found for this subject.';
  end if;

  return public.issue_final_certificate_for_season(p_user_id, p_subject_id, v_season_id);
end;
$function$;

commit;
