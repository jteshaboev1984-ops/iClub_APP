-- Read-only contract checks for finalized result review and bounded correction focus.
begin;
do $$
declare
  v_review text;
  v_queue text;
  v_ensure text;
begin
  if to_regprocedure('public.get_exam_prep_session_review_safe_v1(uuid,text)') is null
     or to_regprocedure('public.get_exam_prep_recent_results_safe_v1(text,integer)') is null
     or to_regprocedure('private.exam_prep_balance_new_normal_plan_v1(uuid,bigint,text,smallint,uuid)') is null
     or to_regprocedure('public.ensure_exam_prep_balanced_weekly_plan_safe_v1(text)') is null
  then
    raise exception 'results_focus_v1 functions missing';
  end if;

  if has_function_privilege('anon','public.get_exam_prep_session_review_safe_v1(uuid,text)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_session_review_safe_v1(uuid,text)','EXECUTE')
     or has_function_privilege('anon','public.get_exam_prep_recent_results_safe_v1(text,integer)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_recent_results_safe_v1(text,integer)','EXECUTE')
  then
    raise exception 'results_focus_v1 public ACL mismatch';
  end if;

  v_review:=pg_get_functiondef('public.get_exam_prep_session_review_safe_v1(uuid,text)'::regprocedure);
  if position('exam_prep_review_available_after_completion' in v_review)=0
     or position('correct_answer' in v_review)=0
     or position('written_completed' in v_review)=0
     or position('machine_accuracy_pct' in v_review)=0
  then
    raise exception 'results_focus_v1 finalized review guard/summary missing';
  end if;

  v_queue:=pg_get_functiondef('private.exam_prep_correction_queue_payload_v1(uuid,text)'::regprocedure);
  if position('focus_limit' in v_queue)=0
     or position('focus_cases' in v_queue)=0
     or position('downstream_dependency_count' in v_queue)=0
  then
    raise exception 'results_focus_v1 bounded focus contract missing';
  end if;

  v_ensure:=pg_get_functiondef('public.ensure_exam_prep_balanced_weekly_plan_safe_v1(text)'::regprocedure);
  if position('exam_prep_balance_new_normal_plan_v1' in v_ensure)=0
     or position('ensure_exam_prep_stable_weekly_plan_safe_v1' in v_ensure)=0
     or md5(pg_get_functiondef('public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)'::regprocedure))
        <> '0304cbab6a544a1123a15eb61af4ab8d'
  then
    raise exception 'results_focus_v1 balanced wrapper or sealed base contract missing';
  end if;
end $$;
rollback;
