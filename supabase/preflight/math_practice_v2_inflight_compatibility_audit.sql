-- READ-ONLY compatibility audit for already-started Practice sessions during v2 cutover.
-- The release retires old start/select entrypoints, but must not strand a session already
-- created by an older browser tab.

begin;
set transaction read only;

do $compat$
begin
  if not has_function_privilege('authenticated','public.get_practice_session_resume_safe_v4(bigint)','execute')
     or not has_function_privilege('authenticated','public.submit_practice_session_answer_safe_v4(bigint,bigint,text,integer,integer)','execute')
     or not has_function_privilege('authenticated','public.finalize_practice_session_safe_v4(bigint,integer)','execute')
     or not has_function_privilege('authenticated','public.get_practice_drill_resume_safe_v4(bigint)','execute')
     or not has_function_privilege('authenticated','public.submit_practice_drill_answer_safe_v4(bigint,bigint,text,integer,integer)','execute')
  then
    raise exception 'practice_v2_inflight_v4_compatibility_bridge_missing';
  end if;
end;
$compat$;

rollback;
