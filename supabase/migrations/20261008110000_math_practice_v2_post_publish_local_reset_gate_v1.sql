-- Mathematics Practice v2: client cleanup may run only after an actual, atomic publish.
-- Additive definition only. No learner history, local data, or rollout state is changed.
begin;

create or replace function public.is_math_practice_v2_published_safe_v1()
returns boolean
language plpgsql
stable
security definer
set search_path = 'pg_catalog', 'public', 'private', 'auth', 'pg_temp'
as $function$
declare
  v_release constant text := 'math_p1_practice_v2_2026_10_07';
begin
  if auth.uid() is null then
    return false;
  end if;

  -- A staged, approved or rolled-back bank does not authorize cleanup.
  return exists (
    select 1
    from private.practice_v2_release_switch_audit a
    where a.release_version = v_release
      and a.status = 'published'
      and (
        select count(*) = 495
        from private.practice_v2_question_meta m
        join public.questions q on q.id = m.question_id
        where m.release_version = v_release
          and m.lifecycle_state = 'published'
          and m.is_runtime_allowed is true
          and q.is_active is true
      )
      and (
        select count(*) = 495
        from public.practice_pool_questions ppq
        join private.practice_v2_question_meta m on m.question_id = ppq.question_id
        where m.release_version = v_release
          and ppq.is_active is true
      )
  );
end;
$function$;

revoke all on function public.is_math_practice_v2_published_safe_v1() from public, anon;
grant execute on function public.is_math_practice_v2_published_safe_v1() to authenticated;

commit;
