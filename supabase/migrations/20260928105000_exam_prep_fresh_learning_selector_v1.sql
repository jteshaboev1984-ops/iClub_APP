-- Fresh-learning selector v1.
-- Prefer an unseen governed learning pack when one exists.
-- A pack is not "fresh" if the learner has seen that assessment OR any of its
-- question/written item IDs in any prior session for the same component.
-- Retest/mixed/timed/diagnostic reserves are never repurposed.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare
  v_plan text;
  v_corr text;
  v_state text;
  v_review text;
begin
  if to_regprocedure('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)') is null
     or to_regprocedure('private.exam_prep_legacy_correction_internal_v1(uuid)') is null
     or to_regprocedure('public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)') is null
     or to_regprocedure('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)') is null
  then
    raise exception 'fresh_learning_selector_v1 prerequisite missing';
  end if;

  v_plan:=pg_get_functiondef('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)'::regprocedure);
  v_corr:=pg_get_functiondef('private.exam_prep_legacy_correction_internal_v1(uuid)'::regprocedure);
  v_state:=pg_get_functiondef('public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)'::regprocedure);
  v_review:=pg_get_functiondef('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)'::regprocedure);

  if position('assessment_type=''learning''' in v_plan)=0
     or position('order by a.id limit 1' in v_plan)=0
     or position('assessment_type=''learning''' in v_corr)=0
     or position('order by a.id limit 1' in v_corr)=0
     or position('previously_seen_learning_pack' in v_state)=0
     or position('same_pack_learning_review' in v_state)=0
     or position('assessment_type=''learning''' in v_review)=0
  then
    raise exception 'fresh_learning_selector_v1 prerequisite contract drift';
  end if;
end
$preflight$;

create or replace function private.exam_prep_select_fresh_learning_assessment_v1(
  p_user_id uuid,
  p_component_code text,
  p_skill_code text
) returns bigint
language plpgsql
stable
security definer
set search_path=''
as $fn$
declare
  v_program bigint;
  v_ass bigint;
begin
  if p_user_id is null or p_component_code not in ('P1','P5')
     or coalesce(p_skill_code,'') not like p_component_code||'-%'
  then
    return null;
  end if;

  select ep.program_version_id into v_program
  from private.exam_prep_exam_profiles ep
  where ep.user_id=p_user_id;
  if v_program is null then return null; end if;

  select a.id into v_ass
  from private.exam_prep_assessments a
  join private.exam_prep_content_versions cv
    on cv.id=a.content_version_id
   and cv.program_version_id=v_program
   and cv.component_code=p_component_code
   and cv.status='published'
  where a.component_code=p_component_code
    and a.assessment_type='learning'
    and a.status='published'
    and (
      select count(*)
      from private.exam_prep_assessment_items ai
      where ai.assessment_id=a.id
        and ai.question_id is not null
        and ai.primary_skill_code=p_skill_code
        and ai.reserve_role='learning'
        and ai.is_holdout is false
    ) between 3 and 6
    and (
      select count(*)
      from private.exam_prep_assessment_items ai
      where ai.assessment_id=a.id
        and ai.written_task_id is not null
        and ai.primary_skill_code=p_skill_code
        and ai.reserve_role='written'
        and ai.is_holdout is false
    )=1
    and not exists(
      select 1
      from private.exam_prep_assessment_items ai
      where ai.assessment_id=a.id
        and (
          ai.primary_skill_code is distinct from p_skill_code
          or ai.is_holdout is true
          or ai.reserve_role not in ('learning','written')
        )
    )
    -- Starting a session exposes the pack. Active/abandoned/finalized all count as seen.
    and not exists(
      select 1
      from private.exam_prep_sessions s
      where s.user_id=p_user_id
        and s.component_code=p_component_code
        and s.assessment_id=a.id
    )
    -- Different assessment IDs cannot disguise repeated item IDs as fresh work.
    and not exists(
      select 1
      from private.exam_prep_assessment_items candidate
      join private.exam_prep_session_items seen
        on (
          candidate.question_id is not null
          and seen.question_id=candidate.question_id
        ) or (
          candidate.written_task_id is not null
          and seen.written_task_id=candidate.written_task_id
        )
      join private.exam_prep_sessions s
        on s.id=seen.session_id
       and s.user_id=p_user_id
       and s.component_code=p_component_code
      where candidate.assessment_id=a.id
    )
  order by cv.published_at desc nulls last,
           a.approved_at desc nulls last,
           a.id
  limit 1;

  return v_ass;
end
$fn$;

create or replace function private.exam_prep_select_seen_learning_assessment_v1(
  p_user_id uuid,
  p_component_code text,
  p_skill_code text
) returns bigint
language plpgsql
stable
security definer
set search_path=''
as $fn$
declare
  v_program bigint;
  v_ass bigint;
begin
  if p_user_id is null or p_component_code not in ('P1','P5')
     or coalesce(p_skill_code,'') not like p_component_code||'-%'
  then
    return null;
  end if;

  select ep.program_version_id into v_program
  from private.exam_prep_exam_profiles ep
  where ep.user_id=p_user_id;
  if v_program is null then return null; end if;

  select a.id into v_ass
  from private.exam_prep_assessments a
  join private.exam_prep_content_versions cv
    on cv.id=a.content_version_id
   and cv.program_version_id=v_program
   and cv.component_code=p_component_code
   and cv.status='published'
  where a.component_code=p_component_code
    and a.assessment_type='learning'
    and a.status='published'
    and (
      select count(*)
      from private.exam_prep_assessment_items ai
      where ai.assessment_id=a.id
        and ai.question_id is not null
        and ai.primary_skill_code=p_skill_code
        and ai.reserve_role='learning'
        and ai.is_holdout is false
    ) between 3 and 6
    and (
      select count(*)
      from private.exam_prep_assessment_items ai
      where ai.assessment_id=a.id
        and ai.written_task_id is not null
        and ai.primary_skill_code=p_skill_code
        and ai.reserve_role='written'
        and ai.is_holdout is false
    )=1
    and not exists(
      select 1
      from private.exam_prep_assessment_items ai
      where ai.assessment_id=a.id
        and (
          ai.primary_skill_code is distinct from p_skill_code
          or ai.is_holdout is true
          or ai.reserve_role not in ('learning','written')
        )
    )
    and exists(
      select 1
      from private.exam_prep_sessions s
      where s.user_id=p_user_id
        and s.component_code=p_component_code
        and s.assessment_id=a.id
    )
  order by (
      select max(coalesce(s.finalized_at,s.started_at))
      from private.exam_prep_sessions s
      where s.user_id=p_user_id
        and s.component_code=p_component_code
        and s.assessment_id=a.id
    ) desc nulls last,
    a.id desc
  limit 1;

  return v_ass;
end
$fn$;

revoke all on function private.exam_prep_select_fresh_learning_assessment_v1(uuid,text,text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_select_fresh_learning_assessment_v1(uuid,text,text)
  to service_role;
revoke all on function private.exam_prep_select_seen_learning_assessment_v1(uuid,text,text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_select_seen_learning_assessment_v1(uuid,text,text)
  to service_role;

do $patch_plan$
declare
  v_def text;
  v_old text;
  v_new text;
begin
  v_def:=pg_get_functiondef('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)'::regprocedure);
  v_old:=
'    select a.id into v_ass'||chr(10)||
'    from private.exam_prep_assessments a'||chr(10)||
'    where a.component_code=v_plan.component_code and a.assessment_type=''learning'' and a.status=''published'''||chr(10)||
'      and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=v_item.skill_code)'||chr(10)||
'      and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>v_item.skill_code)'||chr(10)||
'    order by a.id limit 1;'||chr(10)||
'    if v_ass is null then raise exception ''exam_prep_plan_learning_content_not_ready''; end if;';

  if (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) then
    raise exception 'fresh_learning_selector_v1 plan patch anchor drift';
  end if;

  v_new:=
'    v_ass:=private.exam_prep_select_fresh_learning_assessment_v1('||chr(10)||
'      v_uid,v_plan.component_code,v_item.skill_code'||chr(10)||
'    );'||chr(10)||
'    if v_ass is null then raise exception ''exam_prep_plan_learning_fresh_content_exhausted''; end if;';

  execute replace(v_def,v_old,v_new);
end
$patch_plan$;

do $patch_correction$
declare
  v_def text;
  v_old text;
  v_new text;
begin
  v_def:=pg_get_functiondef('private.exam_prep_legacy_correction_internal_v1(uuid)'::regprocedure);
  v_old:=
'  select a.id into v_ass from private.exam_prep_assessments a'||chr(10)||
'  where a.component_code=v_case.component_code and a.assessment_type=''learning'' and a.status=''published'''||chr(10)||
'    and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=v_case.skill_code)'||chr(10)||
'    and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>v_case.skill_code)'||chr(10)||
'  order by a.id limit 1;'||chr(10)||
'  if v_ass is null then raise exception ''exam_prep_correction_content_not_ready''; end if;';

  if (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) then
    raise exception 'fresh_learning_selector_v1 correction patch anchor drift';
  end if;

  v_new:=
'  v_ass:=private.exam_prep_select_fresh_learning_assessment_v1('||chr(10)||
'    v_uid,v_case.component_code,v_case.skill_code'||chr(10)||
'  );'||chr(10)||
'  if v_ass is null then raise exception ''exam_prep_correction_fresh_content_exhausted''; end if;';

  execute replace(v_def,v_old,v_new);
end
$patch_correction$;

do $patch_review$
declare
  v_def text;
  v_old text;
  v_new text;
begin
  v_def:=pg_get_functiondef('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)'::regprocedure);
  v_old:=
' SELECT a.id INTO v_ass FROM private.exam_prep_assessments a'||chr(10)||
' WHERE a.component_code=p_component_code AND a.assessment_type=''learning'' AND a.status=''published'''||chr(10)||
' AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai'||chr(10)||
'            WHERE ai.assessment_id=a.id AND ai.primary_skill_code=v_item.skill_code)'||chr(10)||
' AND NOT EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai'||chr(10)||
'                WHERE ai.assessment_id=a.id AND ai.primary_skill_code<>v_item.skill_code)'||chr(10)||
' ORDER BY a.id LIMIT 1;'||chr(10)||
' IF v_ass IS NULL THEN RETURN jsonb_build_object(''status'',''waiting'',''reason'',''content_unavailable''); END IF;';

  if (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) then
    raise exception 'fresh_learning_selector_v1 review patch anchor drift';
  end if;

  v_new:=
' v_ass:=private.exam_prep_select_seen_learning_assessment_v1('||chr(10)||
'   v_uid,p_component_code,v_item.skill_code'||chr(10)||
' );'||chr(10)||
' IF v_ass IS NULL THEN RETURN jsonb_build_object(''status'',''waiting'',''reason'',''seen_review_content_unavailable''); END IF;';

  execute replace(v_def,v_old,v_new);
end
$patch_review$;

do $patch_goal_state$
declare
  v_def text;
  v_decl_old text;
  v_decl_new text;
  v_old text;
  v_new text;
begin
  v_def:=pg_get_functiondef('public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)'::regprocedure);

  v_decl_old:='  v_assessment bigint;'||chr(10)||'  v_now timestamptz;';
  v_decl_new:='  v_assessment bigint;'||chr(10)||'  v_review_verdict jsonb;'||chr(10)||'  v_now timestamptz;';
  if (length(v_def)-length(replace(v_def,v_decl_old,'')))<>length(v_decl_old) then
    raise exception 'fresh_learning_selector_v1 goal-state declaration drift';
  end if;
  v_def:=replace(v_def,v_decl_old,v_decl_new);

  v_old:=
'    select a.id into v_assessment from private.exam_prep_assessments a'||chr(10)||
'    where a.component_code=p_component_code and a.assessment_type=''learning'''||chr(10)||
'      and a.status=''published'''||chr(10)||
'      and exists(select 1 from private.exam_prep_assessment_items ai'||chr(10)||
'                 where ai.assessment_id=a.id and ai.primary_skill_code=v_item.skill_code)'||chr(10)||
'      and not exists(select 1 from private.exam_prep_assessment_items ai'||chr(10)||
'                     where ai.assessment_id=a.id and ai.primary_skill_code<>v_item.skill_code)'||chr(10)||
'    order by a.id limit 1;'||chr(10)||
'    if v_assessment is null then'||chr(10)||
'      return jsonb_build_object(''status'',''waiting'',''reason'',''approved_content_unavailable'');'||chr(10)||
'    end if;'||chr(10)||
'    if exists(select 1 from private.exam_prep_sessions s'||chr(10)||
'              where s.user_id=v_uid and s.program_version_id=v_program'||chr(10)||
'                and s.component_code=p_component_code and s.assessment_id=v_assessment'||chr(10)||
'                and s.status=''finalized'') then'||chr(10)||
'      IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) AND (private.exam_prep_learning_review_verdict_v1(v_uid,v_program,p_component_code,v_item.skill_code,v_assessment)->>''status'')=''repeat_learning'' THEN'||chr(10)||
'        RETURN jsonb_build_object(''status'',''review_ready'',''reason'',''same_pack_learning_review'', ''component_code'',p_component_code,''goal_id'',v_goal.id,''plan_id'',v_plan.id, ''priority_order'',v_item.priority_order,''skill_code'',v_item.skill_code,''item_type'',v_item.item_type, ''fresh_assessment'',false);'||chr(10)||
'      END IF;'||chr(10)||
'      return jsonb_build_object(''status'',''content_exhausted'','||chr(10)||
'        ''reason'',''previously_seen_learning_pack'');'||chr(10)||
'    end if;';

  if (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) then
    raise exception 'fresh_learning_selector_v1 goal-state body drift';
  end if;

  v_new:=
'    v_assessment:=private.exam_prep_select_fresh_learning_assessment_v1('||chr(10)||
'      v_uid,p_component_code,v_item.skill_code'||chr(10)||
'    );'||chr(10)||
'    if v_assessment is null then'||chr(10)||
'      v_assessment:=private.exam_prep_select_seen_learning_assessment_v1('||chr(10)||
'        v_uid,p_component_code,v_item.skill_code'||chr(10)||
'      );'||chr(10)||
'      if v_assessment is null then'||chr(10)||
'        return jsonb_build_object(''status'',''waiting'',''reason'',''approved_content_unavailable'');'||chr(10)||
'      end if;'||chr(10)||
'      v_review_verdict:=private.exam_prep_learning_review_verdict_v1('||chr(10)||
'        v_uid,v_program,p_component_code,v_item.skill_code,v_assessment'||chr(10)||
'      );'||chr(10)||
'      if v_review_verdict->>''status''=''resume_first'' then'||chr(10)||
'        return jsonb_build_object(''status'',''waiting'',''reason'',''resume_existing_session_first'');'||chr(10)||
'      end if;'||chr(10)||
'      IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) AND v_review_verdict->>''status''=''repeat_learning'' THEN'||chr(10)||
'        RETURN jsonb_build_object(''status'',''review_ready'',''reason'',''same_pack_learning_review'', ''component_code'',p_component_code,''goal_id'',v_goal.id,''plan_id'',v_plan.id, ''priority_order'',v_item.priority_order,''skill_code'',v_item.skill_code,''item_type'',v_item.item_type, ''fresh_assessment'',false);'||chr(10)||
'      END IF;'||chr(10)||
'      if v_review_verdict->>''status''=''fresh_retest_pending'' then'||chr(10)||
'        return jsonb_build_object(''status'',''waiting'',''reason'',''fresh_retest_pending'');'||chr(10)||
'      end if;'||chr(10)||
'      return jsonb_build_object(''status'',''content_exhausted'','||chr(10)||
'        ''reason'',''previously_seen_learning_pack'');'||chr(10)||
'    end if;';

  execute replace(v_def,v_old,v_new);
end
$patch_goal_state$;

do $postcheck$
declare
  v_plan text;
  v_corr text;
  v_state text;
  v_review text;
begin
  v_plan:=pg_get_functiondef('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)'::regprocedure);
  v_corr:=pg_get_functiondef('private.exam_prep_legacy_correction_internal_v1(uuid)'::regprocedure);
  v_state:=pg_get_functiondef('public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)'::regprocedure);
  v_review:=pg_get_functiondef('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)'::regprocedure);

  if to_regprocedure('private.exam_prep_select_fresh_learning_assessment_v1(uuid,text,text)') is null
     or to_regprocedure('private.exam_prep_select_seen_learning_assessment_v1(uuid,text,text)') is null
     or position('exam_prep_select_fresh_learning_assessment_v1' in v_plan)=0
     or position('exam_prep_select_fresh_learning_assessment_v1' in v_corr)=0
     or position('exam_prep_select_fresh_learning_assessment_v1' in v_state)=0
     or position('exam_prep_select_seen_learning_assessment_v1' in v_state)=0
     or position('exam_prep_select_seen_learning_assessment_v1' in v_review)=0
     or position('order by a.id limit 1' in v_plan)>0
     or position('order by a.id limit 1' in v_corr)>0
  then
    raise exception 'fresh_learning_selector_v1 postcheck failed';
  end if;
end
$postcheck$;

commit;
