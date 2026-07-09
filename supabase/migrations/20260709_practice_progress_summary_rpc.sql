-- Server-verified practice progress summary for Practice Start screen.
-- This is the source of truth for best result, trend and last attempts.
-- It excludes hidden AI-lab/test attempts.

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

  with rows as (
    select
      pa.id,
      pa.score,
      pa.percent,
      pa.time_seconds,
      pa.created_at,
      coalesce(ppa.tour_no, null) as tour_no,
      coalesce(ppa.pool_id, null) as pool_id,
      count(ans.id)::integer as answers_total
    from public.practice_attempts pa
    left join public.practice_answers ans on ans.attempt_id = pa.id
    left join public.practice_pool_attempts ppa on ppa.attempt_id = pa.id
    where pa.user_id = v_auth_user
      and pa.subject_id = v_subject_id
      and coalesce(pa.is_lab, false) is false
      and (
        v_tour_no is null
        or ppa.tour_no = v_tour_no
        or not exists (
          select 1 from public.practice_pool_attempts ppa2 where ppa2.attempt_id = pa.id
        )
      )
    group by pa.id, pa.score, pa.percent, pa.time_seconds, pa.created_at, ppa.tour_no, ppa.pool_id
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
'Server-verified practice summary for Practice Start UI. Excludes is_lab=true attempts and returns best + last attempts.';
