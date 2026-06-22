begin;

-- =========================================================
-- iClub Season 2 draft tour containers
--
-- Safe preparation only:
-- - creates 7 inactive, undated tour rows for each main subject
-- - keeps Season 2 hidden as draft
-- - does not attach questions
-- - does not change Season 1 data or user progress
-- =========================================================

do $$
declare
  v_season2_id bigint;
  v_season2_status text;
  v_main_subjects integer;
  v_existing_rows integer;
begin
  select s.id, s.status
    into v_season2_id, v_season2_status
  from public.seasons s
  where s.season_no = 2;

  if v_season2_id is null then
    raise exception 'Season 2 does not exist. Apply the Season 1 foundation migration first.';
  end if;

  if v_season2_status <> 'draft' then
    raise exception 'Season 2 must remain draft during preparation. Current status: %.', v_season2_status;
  end if;

  select count(*)
    into v_main_subjects
  from public.subjects s
  where s.subject_key in (
    'biology',
    'chemistry',
    'mathematics',
    'informatics',
    'economics'
  );

  if v_main_subjects <> 5 then
    raise exception 'Expected 5 main subjects, found %.', v_main_subjects;
  end if;

  select count(*)
    into v_existing_rows
  from public.tours t
  where t.season_id = v_season2_id;

  if v_existing_rows <> 0 then
    raise exception 'Season 2 already has % tour rows. Stop and audit before continuing.', v_existing_rows;
  end if;
end $$;

insert into public.tours (
  subject_id,
  tour_no,
  start_date,
  end_date,
  is_active,
  season_id
)
select
  s.id,
  gs.tour_no::smallint,
  null::date,
  null::date,
  false,
  season2.id
from public.subjects s
cross join generate_series(1, 7) as gs(tour_no)
cross join lateral (
  select id
  from public.seasons
  where season_no = 2
) as season2
where s.subject_key in (
  'biology',
  'chemistry',
  'mathematics',
  'informatics',
  'economics'
)
order by s.id, gs.tour_no;

do $$
declare
  v_season2_id bigint;
  v_total integer;
  v_active integer;
  v_with_dates integer;
begin
  select id
    into v_season2_id
  from public.seasons
  where season_no = 2;

  select
    count(*),
    count(*) filter (where is_active),
    count(*) filter (where start_date is not null or end_date is not null)
  into
    v_total,
    v_active,
    v_with_dates
  from public.tours
  where season_id = v_season2_id;

  if v_total <> 35 then
    raise exception 'Season 2 preparation failed: expected 35 tours, found %.', v_total;
  end if;

  if v_active <> 0 then
    raise exception 'Season 2 preparation failed: % tours are active.', v_active;
  end if;

  if v_with_dates <> 0 then
    raise exception 'Season 2 preparation failed: % tours already have dates.', v_with_dates;
  end if;
end $$;

commit;
