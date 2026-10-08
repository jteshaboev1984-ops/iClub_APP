-- Mathematics Practice v2 legacy-RPC exposure regression
-- Run after 20261007003000_math_practice_v2_close_legacy_answer_oracles_v1.sql.

do $$
begin
  if has_function_privilege(
    'authenticated',
    'public.submit_practice_attempt(bigint,integer,numeric,integer,jsonb)',
    'execute'
  ) then
    raise exception 'legacy_submit_practice_attempt_still_exposed';
  end if;

  if has_function_privilege(
    'authenticated',
    'public.submit_practice_answer_safe(bigint,bigint,text,integer,integer)',
    'execute'
  ) then
    raise exception 'legacy_submit_practice_answer_safe_still_exposed';
  end if;

  if has_function_privilege(
    'authenticated',
    'public.get_practice_review_safe_v4(bigint)',
    'execute'
  ) then
    raise exception 'legacy_get_practice_review_safe_v4_still_exposed';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.start_practice_session_auto_safe_v4(bigint,text)',
    'execute'
  ) then
    raise exception 'current_safe_start_not_exposed';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_practice_session_resume_safe_v4(bigint)',
    'execute'
  ) then
    raise exception 'current_safe_resume_not_exposed';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.submit_practice_session_answer_safe_v4(bigint,bigint,text,integer,integer)',
    'execute'
  ) then
    raise exception 'current_safe_submit_not_exposed';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.finalize_practice_session_safe_v4(bigint,integer)',
    'execute'
  ) then
    raise exception 'current_safe_finalize_not_exposed';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_practice_review_full_safe_v4(bigint)',
    'execute'
  ) then
    raise exception 'current_safe_review_not_exposed';
  end if;
end;
$$;
