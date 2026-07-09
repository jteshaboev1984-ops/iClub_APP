-- Fix get_practice_progress_summary for the real production schema.
-- There is no practice_pool_attempts table, so tour_no is inferred from answered question_ids
-- through practice_pool_questions -> practice_pools.

create or replace function public.get_practice_progress_summary(
  p_subject_key text,
  p_tour_no integer default null,
  p_limit integer default 30
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_auth_user uuid := auth.uid();
  v_subject_id bigint;
  v_tour_no integer := nullif(p_tour_no, 0);
  v_limit integer := least(greatest(coalesce(p_limit, 30), 1), 50);
  v_best jsonb := null;
  v_last jsonb := '[]'::jsonb;
  v_attempts_count integer := 0;
begin
  if v_auth_user is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select s.id
  into v_subject_id
  from public.subjects s
  where s.subject_key = trim(lower(coalesce(p_subject_key, '')))
  limit 1;

  if v_subject_id is null then
    raise exception 'subject_not_found' using errcode = 'P0002';
  end if;

  with attempt_tours as (
    select
      pa.id as attempt_id,
      min(pp.tour_no)::integer as tour_no,
      min(pp.id)::bigint as pool_id,
      count(ans.id)::integer as answers_total
    from public.practice_attempts pa
    left join public.practice_answers ans
      on ans.attempt_id = pa.id
    left join public.practice_pool_questions ppq
      on ppq.question_id = ans.question_id
     and ppq.is_active = true
    left join public.practice_pools pp
      on pp.id = ppq.pool_id
     and pp.subject_id = pa.subject_id
     and pp.is_active = true
    where pa.user_id = v_auth_user
      and pa.subject_id = v_subject_id
      and coalesce(pa.is_lab, false) is false
    group by pa.id
  ),
  rows as (
    select
      pa.id,
      pa.score,
      pa.percent,
      pa.time_seconds,
      pa.created_at,
      at.tour_no,
      at.pool_id,
      coalesce(at.answers_total, 0)::integer as answers_total
    from public.practice_attempts pa
    left join attempt_tours at on at.attempt_id = pa.id
    where pa.user_id = v_auth_user
      and pa.subject_id = v_subject_id
      and coalesce(pa.is_lab, false) is false
      and (
        v_tour_no is null
        or at.tour_no = v_tour_no
      )
  ),
  ranked as (
    select *
    from rows
    order by created_at desc, id desc
    limit v_limit
  ),
  best_row as (
    select *
    from rows
    order by percent desc, time_seconds asc nulls last, created_at desc, id desc
    limit 1
  )
  select
    (select count(*)::integer from rows),
    (select to_jsonb(b.*) from best_row b),
    coalesce((select jsonb_agg(to_jsonb(r.*) order by r.created_at desc, r.id desc) from ranked r), '[]'::jsonb)
  into v_attempts_count, v_best, v_last;

  return jsonb_build_object(
    'ok', true,
    'subject_id', v_subject_id,
    'subject_key', trim(lower(coalesce(p_subject_key, ''))),
    'tour_no', v_tour_no,
    'attempts_count', coalesce(v_attempts_count, 0),
    'best', v_best,
    'last', v_last
  );
end;
$$;

revoke all on function public.get_practice_progress_summary(text, integer, integer) from public, anon;
grant execute on function public.get_practice_progress_summary(text, integer, integer) to authenticated;

comment on function public.get_practice_progress_summary(text, integer, integer) is
'Server-verified practice summary for Practice Start UI. Excludes is_lab=true attempts and infers tour_no from practice_pool_questions/practice_pools.';

notify pgrst, 'reload schema';
