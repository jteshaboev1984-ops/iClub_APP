-- P1-03 hardening: governed-role parity + deterministic RPC compile order.
-- Still additive/fail-closed; no learner access or legacy mutation.

begin;

-- Published timed contracts must point to a published assessment/content version,
-- and every machine item must be backed by an actual governed TIMED reserve object.
create or replace function private.exam_prep_validate_timed_contract_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_a private.exam_prep_assessments%rowtype;
  v_cv private.exam_prep_content_versions%rowtype;
  v_p private.exam_prep_component_paper_profiles%rowtype;
  v_sum integer;
  v_count integer;
  v_ass_count integer;
  v_limit integer;
  v_bad_roles integer;
begin
  select * into v_a from private.exam_prep_assessments where id=new.assessment_id;
  if v_a.id is null or v_a.assessment_type not in ('timed','paper') then
    raise exception 'exam_prep_timed_contract_requires_timed_or_paper_assessment';
  end if;
  select * into v_cv from private.exam_prep_content_versions where id=v_a.content_version_id;
  if v_cv.id is null or v_cv.component_code<>v_a.component_code then
    raise exception 'exam_prep_timed_contract_content_scope_mismatch';
  end if;
  select * into v_p from private.exam_prep_component_paper_profiles where id=new.paper_profile_id;
  if v_p.id is null or v_p.status<>'published' or v_p.component_code<>v_a.component_code then
    raise exception 'exam_prep_timed_contract_profile_scope_mismatch';
  end if;
  if new.attempt_kind='full_paper' and (new.timing_rule<>'official_full' or new.comparison_scope<>'full') then
    raise exception 'exam_prep_full_paper_contract_invalid';
  end if;
  if new.attempt_kind='modified_paper' and (new.timing_rule<>'proportional_marks' or new.comparison_scope<>'modified') then
    raise exception 'exam_prep_modified_paper_contract_invalid';
  end if;
  if new.attempt_kind='diagnostic_full' and new.comparison_scope<>'diagnostic' then
    raise exception 'exam_prep_diagnostic_full_scope_invalid';
  end if;
  if new.attempt_kind='timed_section' and new.comparison_scope<>'section' then
    raise exception 'exam_prep_timed_section_scope_invalid';
  end if;
  v_limit:=private.exam_prep_timed_time_limit_v1(new.paper_profile_id,new.timing_rule,new.marks_available,new.fixed_time_limit_sec);

  if new.status='published' then
    if v_a.status<>'published' or v_cv.status<>'published' then
      raise exception 'exam_prep_timed_contract_requires_published_assessment_and_content';
    end if;

    select count(*),coalesce(sum(i.max_marks),0)
      into v_count,v_sum
    from private.exam_prep_timed_assessment_items i
    where i.assessment_id=new.assessment_id;
    select count(*) into v_ass_count
    from private.exam_prep_assessment_items ai
    where ai.assessment_id=new.assessment_id;
    if v_count=0 or v_count<>v_ass_count or v_sum<>new.marks_available then
      raise exception 'exam_prep_timed_item_mark_floor_not_met items=% assessment_items=% marks=% expected=%',
        v_count,v_ass_count,v_sum,new.marks_available;
    end if;

    select count(*) into v_bad_roles
    from private.exam_prep_assessment_items ai
    left join private.exam_prep_question_content_meta m
      on m.question_id=ai.question_id and m.content_version_id=v_a.content_version_id
    left join private.exam_prep_written_tasks wt
      on wt.id=ai.written_task_id and wt.content_version_id=v_a.content_version_id
    where ai.assessment_id=new.assessment_id and (
      (ai.question_id is not null and (
        ai.reserve_role<>'timed' or m.id is null or m.reserve_role<>'timed'
        or m.lifecycle_state<>'reserve' or m.exposure_state<>'withheld'
        or m.copyright_status<>'pass' or m.qa_scope_status<>'pass'
        or m.qa_math_status<>'pass' or m.qa_language_status<>'pass' or m.qa_technical_status<>'pass'
      ))
      or
      (ai.written_task_id is not null and (
        ai.reserve_role<>'written' or wt.id is null or wt.lifecycle_state<>'published'
        or wt.copyright_status<>'pass' or wt.qa_math_status<>'pass'
        or wt.qa_language_status<>'pass' or wt.qa_technical_status<>'pass'
      ))
    );
    if v_bad_roles<>0 then
      raise exception 'exam_prep_timed_governed_role_mismatch count=%',v_bad_roles;
    end if;
  end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_validate_timed_contract_v1() from public,anon,authenticated;

-- Compile-order placeholder. The complete safe implementation replaces this
-- signature in the following migration inside the same transactional release.
create or replace function public.get_exam_prep_timed_result_safe_v1(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
begin
  perform private.exam_prep_require_core_access_v1();
  raise exception 'exam_prep_timed_result_rpc_not_ready';
end;
$$;
revoke execute on function public.get_exam_prep_timed_result_safe_v1(uuid) from public,anon;
grant execute on function public.get_exam_prep_timed_result_safe_v1(uuid) to service_role;

-- No client may ever observe this placeholder between migrations because the
-- whole feature remains server-flag OFF and kill-switch ON.
do $$ begin
  if exists(
    select 1 from private.exam_prep_feature_config
    where program_key='math_as_p1_p5'
      and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch)
  ) then raise exception 'P1-03 hardening requires fail-closed feature state'; end if;
end $$;

commit;
