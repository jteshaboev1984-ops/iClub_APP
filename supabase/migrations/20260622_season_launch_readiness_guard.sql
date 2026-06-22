begin;

-- =========================================================
-- iClub Season Launch Readiness Guard
--
-- Read-only checker.
-- It does NOT launch a season and does NOT update user data.
--
-- Run later from Supabase SQL Editor:
--
-- select *
-- from public.get_season_launch_readiness(2);
-- =========================================================

create or replace function public.get_season_launch_readiness(
  p_season_no integer
)
returns table (
  season_id bigint,
  season_no integer,
  season_status text,

  main_subjects_found integer,
  subjects_with_7_tours integer,
  tour_containers_found integer,

  dated_tours integer,
  valid_date_tours integer,
  inactive_tours integer,
  consistent_tour_windows integer,
  subject_schedule_overlaps integer,

  tours_with_20_published_questions integer,
  tours_with_6_9_5 integer,

  duplicate_question_groups integer,
  practice_overlap_questions integer,
  subject_mismatch_links integer,

  ready boolean,
  blocking_reasons text[]
)
language sql
stable
security invoker
set search_path to 'public'
as $function$

with
input_row as (
  select p_season_no::integer as season_no
),

target_season as (
  select
    s.id,
    s.season_no,
    s.status
  from public.seasons s
  where s.season_no = p_season_no
  limit 1
),

main_subjects as (
  select
    s.id,
    s.subject_key
  from public.subjects s
  where s.subject_key in (
    'biology',
    'chemistry',
    'mathematics',
    'informatics',
    'economics'
  )
    and s.is_active is true
),

season_tours as (
  select
    t.id,
    t.season_id,
    t.subject_id,
    t.tour_no,
    t.start_date,
    t.end_date,
    t.is_active
  from public.tours t
  join target_season ts
    on ts.id = t.season_id
  where t.subject_id in (
    select ms.id
    from main_subjects ms
  )
),

subject_tour_counts as (
  select
    st.subject_id,
    count(*)::integer as tour_count,
    count(distinct st.tour_no)::integer
      as distinct_tour_count,
    min(st.tour_no)::integer as min_tour_no,
    max(st.tour_no)::integer as max_tour_no
  from season_tours st
  group by st.subject_id
),

schedule_by_tour_no as (
  select
    st.tour_no,
    count(*)::integer as subject_rows,

    count(
      distinct (
        st.start_date,
        st.end_date
      )
    )::integer as window_variants,

    bool_and(
      st.start_date is not null
      and st.end_date is not null
    ) as all_dates_present
  from season_tours st
  group by st.tour_no
),

ordered_tours as (
  select
    st.*,

    lag(st.end_date) over (
      partition by st.subject_id
      order by st.tour_no
    ) as previous_end_date
  from season_tours st
),

tour_question_stats as (
  select
    st.id as tour_id,

    count(*) filter (
      where tq.is_active is true
        and q.is_active is true
    )::integer as published_questions,

    count(distinct tq.order_no) filter (
      where tq.is_active is true
        and q.is_active is true
    )::integer as distinct_order_numbers,

    min(tq.order_no) filter (
      where tq.is_active is true
        and q.is_active is true
    )::integer as first_order_number,

    max(tq.order_no) filter (
      where tq.is_active is true
        and q.is_active is true
    )::integer as last_order_number,

    count(*) filter (
      where tq.is_active is true
        and q.is_active is true
        and lower(q.difficulty) = 'easy'
    )::integer as easy_questions,

    count(*) filter (
      where tq.is_active is true
        and q.is_active is true
        and lower(q.difficulty) = 'medium'
    )::integer as medium_questions,

    count(*) filter (
      where tq.is_active is true
        and q.is_active is true
        and lower(q.difficulty) = 'hard'
    )::integer as hard_questions

  from season_tours st

  left join public.tour_questions tq
    on tq.tour_id = st.id

  left join public.questions q
    on q.id = tq.question_id

  group by st.id
),

duplicate_questions as (
  select
    count(*)::integer
      as duplicate_question_groups
  from (
    select
      tq.question_id
    from season_tours st
    join public.tour_questions tq
      on tq.tour_id = st.id
    join public.questions q
      on q.id = tq.question_id
    where tq.is_active is true
      and q.is_active is true
    group by tq.question_id
    having count(*) > 1
  ) duplicated
),

practice_overlaps as (
  select
    count(
      distinct tq.question_id
    )::integer
      as practice_overlap_questions
  from season_tours st
  join public.tour_questions tq
    on tq.tour_id = st.id
  join public.questions q
    on q.id = tq.question_id
  join public.practice_pool_questions ppq
    on ppq.question_id = tq.question_id
  where tq.is_active is true
    and q.is_active is true
    and ppq.is_active is true
),

subject_mismatches as (
  select
    count(*)::integer
      as subject_mismatch_links
  from season_tours st
  join public.tour_questions tq
    on tq.tour_id = st.id
  join public.questions q
    on q.id = tq.question_id
  where tq.is_active is true
    and q.is_active is true
    and q.subject_id <> st.subject_id
),

totals as (
  select
    (
      select count(*)::integer
      from main_subjects
    ) as main_subjects_found,

    (
      select count(*)::integer
      from subject_tour_counts stc
      where stc.tour_count = 7
        and stc.distinct_tour_count = 7
        and stc.min_tour_no = 1
        and stc.max_tour_no = 7
    ) as subjects_with_7_tours,

    count(*)::integer
      as tour_containers_found,

    count(*) filter (
      where st.start_date is not null
        and st.end_date is not null
    )::integer as dated_tours,

    count(*) filter (
      where st.start_date is not null
        and st.end_date is not null
        and st.start_date <= st.end_date
    )::integer as valid_date_tours,

    count(*) filter (
      where st.is_active is false
    )::integer as inactive_tours,

    (
      select count(*)::integer
      from schedule_by_tour_no sbt
      where sbt.subject_rows = 5
        and sbt.window_variants = 1
        and sbt.all_dates_present is true
    ) as consistent_tour_windows,

    (
      select count(*)::integer
      from ordered_tours ot
      where ot.previous_end_date is not null
        and ot.start_date is not null
        and ot.start_date <= ot.previous_end_date
    ) as subject_schedule_overlaps,

    (
      select count(*)::integer
      from tour_question_stats tqs
      where tqs.published_questions = 20
        and tqs.distinct_order_numbers = 20
        and tqs.first_order_number = 1
        and tqs.last_order_number = 20
    ) as tours_with_20_published_questions,

    (
      select count(*)::integer
      from tour_question_stats tqs
      where tqs.published_questions = 20
        and tqs.easy_questions = 6
        and tqs.medium_questions = 9
        and tqs.hard_questions = 5
    ) as tours_with_6_9_5

  from season_tours st
),

evaluation as (
  select
    ir.season_no as requested_season_no,
    ts.id as target_season_id,
    ts.status as target_season_status,

    totals.main_subjects_found,
    totals.subjects_with_7_tours,
    totals.tour_containers_found,

    totals.dated_tours,
    totals.valid_date_tours,
    totals.inactive_tours,
    totals.consistent_tour_windows,
    totals.subject_schedule_overlaps,

    totals.tours_with_20_published_questions,
    totals.tours_with_6_9_5,

    duplicate_questions.duplicate_question_groups,
    practice_overlaps.practice_overlap_questions,
    subject_mismatches.subject_mismatch_links

  from input_row ir

  left join target_season ts
    on true

  cross join totals
  cross join duplicate_questions
  cross join practice_overlaps
  cross join subject_mismatches
)

select
  e.target_season_id as season_id,
  e.requested_season_no as season_no,
  e.target_season_status as season_status,

  e.main_subjects_found,
  e.subjects_with_7_tours,
  e.tour_containers_found,

  e.dated_tours,
  e.valid_date_tours,
  e.inactive_tours,
  e.consistent_tour_windows,
  e.subject_schedule_overlaps,

  e.tours_with_20_published_questions,
  e.tours_with_6_9_5,

  e.duplicate_question_groups,
  e.practice_overlap_questions,
  e.subject_mismatch_links,

  (
    e.target_season_id is not null
    and e.target_season_status = 'draft'

    and e.main_subjects_found = 5
    and e.subjects_with_7_tours = 5
    and e.tour_containers_found = 35

    and e.dated_tours = 35
    and e.valid_date_tours = 35
    and e.inactive_tours = 35

    and e.consistent_tour_windows = 7
    and e.subject_schedule_overlaps = 0

    and e.tours_with_20_published_questions = 35
    and e.tours_with_6_9_5 = 35

    and e.duplicate_question_groups = 0
    and e.practice_overlap_questions = 0
    and e.subject_mismatch_links = 0
  ) as ready,

  array_remove(
    array[
      case
        when e.target_season_id is null
        then 'Season does not exist'
      end,

      case
        when e.target_season_id is not null
         and e.target_season_status <> 'draft'
        then 'Season status must be draft before launch'
      end,

      case
        when e.main_subjects_found <> 5
        then 'Exactly 5 active main subjects are required'
      end,

      case
        when e.subjects_with_7_tours <> 5
        then 'Every main subject must contain Tours 1-7'
      end,

      case
        when e.tour_containers_found <> 35
        then 'Exactly 35 tour containers are required'
      end,

      case
        when e.dated_tours <> 35
        then 'All 35 tours must have start and end dates'
      end,

      case
        when e.valid_date_tours <> 35
        then 'Every tour start date must be on or before its end date'
      end,

      case
        when e.inactive_tours <> 35
        then 'All draft-season tours must remain inactive before launch'
      end,

      case
        when e.consistent_tour_windows <> 7
        then 'Each tour number must use one shared date window across all subjects'
      end,

      case
        when e.subject_schedule_overlaps <> 0
        then 'Tour date windows overlap within at least one subject'
      end,

      case
        when e.tours_with_20_published_questions <> 35
        then 'Every tour must contain 20 active published questions ordered 1-20'
      end,

      case
        when e.tours_with_6_9_5 <> 35
        then 'Every tour must contain 6 easy, 9 medium and 5 hard questions'
      end,

      case
        when e.duplicate_question_groups <> 0
        then 'A question is linked to more than one Season tour'
      end,

      case
        when e.practice_overlap_questions <> 0
        then 'Season tour questions overlap with the global practice pool'
      end,

      case
        when e.subject_mismatch_links <> 0
        then 'A tour contains a question from another subject'
      end
    ]::text[],
    null
  ) as blocking_reasons

from evaluation e;

$function$;

comment on function
public.get_season_launch_readiness(integer)
is
'Read-only launch readiness report. Does not update seasons, tours, questions, attempts, certificates, recommendations or practice progress.';

revoke all
on function public.get_season_launch_readiness(integer)
from public;

revoke all
on function public.get_season_launch_readiness(integer)
from anon, authenticated;

commit;
