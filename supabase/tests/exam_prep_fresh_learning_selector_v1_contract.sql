-- Read-only contract for unseen-first governed learning selection.
begin;
do $$
declare
  v_fresh text;
  v_seen text;
  v_plan text;
  v_corr text;
  v_state text;
  v_review text;
begin
  if to_regprocedure('private.exam_prep_select_fresh_learning_assessment_v1(uuid,text,text)') is null
     or to_regprocedure('private.exam_prep_select_seen_learning_assessment_v1(uuid,text,text)') is null
  then
    raise exception 'fresh_learning_selector_v1 helpers missing';
  end if;

  v_fresh:=pg_get_functiondef('private.exam_prep_select_fresh_learning_assessment_v1(uuid,text,text)'::regprocedure);
  v_seen:=pg_get_functiondef('private.exam_prep_select_seen_learning_assessment_v1(uuid,text,text)'::regprocedure);
  v_plan:=pg_get_functiondef('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)'::regprocedure);
  v_corr:=pg_get_functiondef('private.exam_prep_legacy_correction_internal_v1(uuid)'::regprocedure);
  v_state:=pg_get_functiondef('public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)'::regprocedure);
  v_review:=pg_get_functiondef('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)'::regprocedure);

  if position('a.assessment_type=''learning''' in v_fresh)=0
     or position('cv.status=''published''' in v_fresh)=0
     or position('ai.reserve_role=''learning''' in v_fresh)=0
     or position('ai.reserve_role=''written''' in v_fresh)=0
     or position('ai.is_holdout is false' in v_fresh)=0
     or position('s.assessment_id=a.id' in v_fresh)=0
     or position('seen.question_id=candidate.question_id' in v_fresh)=0
     or position('seen.written_task_id=candidate.written_task_id' in v_fresh)=0
     or position('s.component_code=p_component_code' in v_fresh)=0
  then
    raise exception 'fresh_learning_selector_v1 freshness guard missing';
  end if;

  if position('a.assessment_type=''learning''' in v_seen)=0
     or position('exists(' in v_seen)=0
     or position('s.assessment_id=a.id' in v_seen)=0
     or position('ai.is_holdout is false' in v_seen)=0
  then
    raise exception 'fresh_learning_selector_v1 seen-pack selector guard missing';
  end if;

  if position('exam_prep_select_fresh_learning_assessment_v1' in v_plan)=0
     or position('exam_prep_plan_learning_fresh_content_exhausted' in v_plan)=0
     or position('exam_prep_select_fresh_learning_assessment_v1' in v_corr)=0
     or position('exam_prep_correction_fresh_content_exhausted' in v_corr)=0
     or position('exam_prep_select_fresh_learning_assessment_v1' in v_state)=0
     or position('exam_prep_select_seen_learning_assessment_v1' in v_state)=0
     or position('exam_prep_select_seen_learning_assessment_v1' in v_review)=0
     or position('same_pack_learning_review' in v_state)=0
  then
    raise exception 'fresh_learning_selector_v1 routing contract missing';
  end if;

  if position('order by a.id limit 1' in v_plan)>0
     or position('order by a.id limit 1' in v_corr)>0
  then
    raise exception 'fresh_learning_selector_v1 legacy first-pack selector survived';
  end if;

  if has_function_privilege('anon','private.exam_prep_select_fresh_learning_assessment_v1(uuid,text,text)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_select_fresh_learning_assessment_v1(uuid,text,text)','EXECUTE')
     or has_function_privilege('anon','private.exam_prep_select_seen_learning_assessment_v1(uuid,text,text)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_select_seen_learning_assessment_v1(uuid,text,text)','EXECUTE')
  then
    raise exception 'fresh_learning_selector_v1 private helper ACL widened';
  end if;
end $$;
rollback;
