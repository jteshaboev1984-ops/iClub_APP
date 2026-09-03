-- Owner-only Practice progress reset for content-language changes.
-- Safe for the shared production database: current production frontend does not call it.
-- AI-lab attempts are intentionally preserved.

create or replace function public.reset_practice_progress_safe_v4()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_sessions integer := 0;
  v_drills integer := 0;
  v_attempts integer := 0;
begin
  if v_uid is null then
    raise exception 'authentication_required';
  end if;

  -- Session tables must be cleared before legacy attempts because
  -- practice_sessions_v4.legacy_attempt_id uses NO ACTION.
  delete from public.practice_drill_sessions_v4
  where user_id = v_uid;
  get diagnostics v_drills = row_count;

  delete from public.practice_sessions_v4
  where user_id = v_uid;
  get diagnostics v_sessions = row_count;

  -- Answers and answer diagnoses cascade from non-lab attempts.
  delete from public.practice_attempts
  where user_id = v_uid
    and coalesce(is_lab, false) = false;
  get diagnostics v_attempts = row_count;

  return jsonb_build_object(
    'ok', true,
    'deleted_practice_sessions', v_sessions,
    'deleted_drill_sessions', v_drills,
    'deleted_practice_attempts', v_attempts
  );
end;
$$;

revoke all on function public.reset_practice_progress_safe_v4() from public, anon;
grant execute on function public.reset_practice_progress_safe_v4() to authenticated, service_role;

comment on function public.reset_practice_progress_safe_v4() is
'Authenticated owner-only reset for non-lab Practice progress and v4 Practice sessions. Tours and AI-lab attempts are preserved.';
