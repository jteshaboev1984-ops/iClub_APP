begin;

-- P2-19 hardens three beta paths discovered during post-implementation audit:
-- 1) every already-approved isolated R01/R02 retest reserve becomes reachable as a one-question variant;
-- 2) retest authorization chooses content the learner has not already seen in a retest session;
-- 3) weekly-plan actions are bound to the current active week and mixed work is bound to the exact planned assessment.
-- Existing assessments/evidence are not rewritten. Legacy Practice/Tour/history is untouched.

-- Materialize missing single-question retest variants from the already approved/withheld retest reserve.
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
  title_en,title_ru,title_uz,approved_at
)
select
  m.content_version_id,
  lower(replace(m.content_key,'-','_'))||'_single_retest',
  'av1',
  cv.component_code,
  'retest',
  'published',
  'Delayed retest · '||m.primary_skill_code,
  'Отложенная повторная проверка · '||m.primary_skill_code,
  'Kechiktirilgan qayta tekshiruv · '||m.primary_skill_code,
  coalesce(m.approved_at,now())
from private.exam_prep_question_content_meta m
join private.exam_prep_content_versions cv
  on cv.id=m.content_version_id and cv.status='published'
where m.reserve_role='retest'
  and m.lifecycle_state='reserve'
  and m.exposure_state='withheld'
  and m.qa_scope_status='pass'
  and m.qa_math_status='pass'
  and m.qa_language_status='pass'
  and m.qa_technical_status='pass'
  and m.primary_skill_code like cv.component_code||'-%'
  and not exists(
    select 1
    from private.exam_prep_assessments a
    where a.content_version_id=m.content_version_id
      and a.component_code=cv.component_code
      and a.assessment_type='retest'
      and a.status='published'
      and (select count(*) from private.exam_prep_assessment_items x where x.assessment_id=a.id)=1
      and exists(
        select 1 from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id
          and ai.question_id=m.question_id
          and ai.primary_skill_code=m.primary_skill_code
          and ai.reserve_role='retest'
      )
  )
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

insert into private.exam_prep_assessment_items(
  assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select
  a.id,1,m.question_id,null,m.primary_skill_code,'retest',true
from private.exam_prep_question_content_meta m
join private.exam_prep_content_versions cv
  on cv.id=m.content_version_id and cv.status='published'
join private.exam_prep_assessments a
  on a.content_version_id=m.content_version_id
 and a.assessment_key=lower(replace(m.content_key,'-','_'))||'_single_retest'
 and a.assessment_version='av1'
 and a.component_code=cv.component_code
 and a.assessment_type='retest'
 and a.status='published'
where m.reserve_role='retest'
  and m.lifecycle_state='reserve'
  and m.exposure_state='withheld'
  and m.qa_scope_status='pass'
  and m.qa_math_status='pass'
  and m.qa_language_status='pass'
  and m.qa_technical_status='pass'
  and not exists(
    select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id
  );

create or replace function private.exam_prep_select_fresh_retest_assessment_v1(
  p_user_id uuid,p_component_code text,p_skill_code text
)
returns bigint
language sql
stable
security definer
set search_path=''
as $$
  select a.id
  from private.exam_prep_assessments a
  join private.exam_prep_assessment_items ai
    on ai.assessment_id=a.id
   and ai.question_id is not null
   and ai.primary_skill_code=p_skill_code
   and ai.reserve_role='retest'
  join private.exam_prep_question_content_meta m
    on m.question_id=ai.question_id
   and m.content_version_id=a.content_version_id
   and m.primary_skill_code=ai.primary_skill_code
  where p_user_id is not null
    and p_component_code in ('P1','P5')
    and p_skill_code like p_component_code||'-%'
    and a.component_code=p_component_code
    and a.assessment_type='retest'
    and a.status='published'
    and (select count(*) from private.exam_prep_assessment_items z where z.assessment_id=a.id)=1
    and m.reserve_role='retest'
    and m.lifecycle_state='reserve'
    and m.exposure_state='withheld'
    and m.qa_scope_status='pass'
    and m.qa_math_status='pass'
    and m.qa_language_status='pass'
    and m.qa_technical_status='pass'
    and not exists(
      select 1
      from private.exam_prep_sessions s
      join private.exam_prep_session_items si on si.session_id=s.id
      where s.user_id=p_user_id
        and s.component_code=p_component_code
        and s.session_type='retest'
        and si.question_id=ai.question_id
    )
    and not exists(
      select 1
      from private.exam_prep_session_authorizations sa
      where sa.user_id=p_user_id
        and sa.assessment_id=a.id
        and sa.purpose='retest'
        and sa.status='issued'
        and (sa.valid_until is null or sa.valid_until>now())
    )
  order by a.id
  limit 1;
$$;
revoke all on function private.exam_prep_select_fresh_retest_assessment_v1(uuid,text,text) from public,anon,authenticated;
grant execute on function private.exam_prep_select_fresh_retest_assessment_v1(uuid,text,text) to service_role;

create or replace function private.exam_prep_fresh_retest_content_ready_v1(
  p_user_id uuid,p_component_code text,p_skill_code text
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select private.exam_prep_select_fresh_retest_assessment_v1(
    p_user_id,p_component_code,p_skill_code
  ) is not null;
$$;
revoke all on function private.exam_prep_fresh_retest_content_ready_v1(uuid,text,text) from public,anon,authenticated;
grant execute on function private.exam_prep_fresh_retest_content_ready_v1(uuid,text,text) to service_role;

create or replace function public.authorize_exam_prep_retest_safe_v1(p_correction_case_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_case private.exam_prep_correction_cases%rowtype;
  v_rt private.exam_prep_retest_events%rowtype;
  v_ass bigint;
  v_auth uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_case
  from private.exam_prep_correction_cases
  where id=p_correction_case_id and user_id=v_uid;
  if v_case.id is null then raise exception 'exam_prep_correction_case_not_found' using errcode='P0002'; end if;
  if v_case.status<>'retest_due' then raise exception 'exam_prep_retest_not_due'; end if;

  select * into v_rt
  from private.exam_prep_retest_events
  where correction_case_id=v_case.id and user_id=v_uid and status='scheduled'
  order by created_at desc limit 1 for update;
  if v_rt.id is null then raise exception 'exam_prep_retest_event_not_found'; end if;
  if v_rt.due_not_before is not null and v_rt.due_not_before>now() then raise exception 'exam_prep_retest_too_early'; end if;

  v_ass:=private.exam_prep_select_fresh_retest_assessment_v1(v_uid,v_case.component_code,v_case.skill_code);
  if v_ass is null then raise exception 'exam_prep_retest_fresh_content_exhausted'; end if;

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,correction_case_id
  ) values(
    v_uid,v_ass,v_case.component_code,'retest','issued',now()+interval '1 hour',
    'Core delayed retest using fresh isolated reserve',v_case.id
  ) returning id into v_auth;

  update private.exam_prep_retest_events
  set status='authorized',authorization_id=v_auth
  where id=v_rt.id;

  perform private.exam_prep_log_correction_action_v1(
    v_case.id,'retest_authorized',null,null,v_rt.id,
    jsonb_build_object('authorization_id',v_auth,'assessment_id',v_ass,'fresh_reserve',true)
  );

  return jsonb_build_object(
    'authorization_id',v_auth,'assessment_id',v_ass,'retest_event_id',v_rt.id,
    'correction_case_id',v_case.id,'component_code',v_case.component_code,
    'skill_code',v_case.skill_code,'due_not_before',v_rt.due_not_before,
    'purpose','retest','fresh_reserve',true
  );
end;
$$;
revoke execute on function public.authorize_exam_prep_retest_safe_v1(uuid) from public,anon;
grant execute on function public.authorize_exam_prep_retest_safe_v1(uuid) to authenticated,service_role;

create or replace function public.authorize_exam_prep_plan_item_safe_v1(p_plan_id uuid,p_priority_order integer)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_plan private.exam_prep_weekly_plans%rowtype;
  v_item private.exam_prep_weekly_plan_items%rowtype;
  v_ass bigint;
  v_auth uuid;
  v_questions int;
  v_written int;
  v_result jsonb;
  v_state private.exam_prep_skill_states%rowtype;
  v_contract private.exam_prep_skill_contracts%rowtype;
  v_has_mixed boolean:=false;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_plan_id is null then raise exception 'exam_prep_plan_id_required'; end if;
  if p_priority_order is null or p_priority_order not between 1 and 3 then raise exception 'exam_prep_bad_plan_priority'; end if;

  select * into v_plan
  from private.exam_prep_weekly_plans
  where id=p_plan_id and user_id=v_uid and status='active';
  if v_plan.id is null then raise exception 'exam_prep_active_plan_not_found' using errcode='P0002'; end if;
  if v_plan.active_week_no<>private.exam_prep_effective_active_week_v1(v_uid) then
    raise exception 'exam_prep_stale_weekly_plan';
  end if;

  select * into v_item
  from private.exam_prep_weekly_plan_items
  where plan_id=v_plan.id and priority_order=p_priority_order::smallint and status='pending';
  if v_item.plan_id is null then raise exception 'exam_prep_pending_plan_item_not_found' using errcode='P0002'; end if;

  if v_item.item_type='correction' then
    if v_item.correction_case_id is null then raise exception 'exam_prep_plan_correction_case_required'; end if;
    v_result:=public.authorize_exam_prep_correction_safe_v1(v_item.correction_case_id);

  elsif v_item.item_type='retest' then
    if v_item.correction_case_id is not null then
      v_result:=public.authorize_exam_prep_retest_safe_v1(v_item.correction_case_id);
    else
      if v_item.action_code<>'COMPLETE_RETENTION_RETEST' then raise exception 'exam_prep_plan_retest_case_required'; end if;
      if v_item.skill_code is null then raise exception 'exam_prep_retention_retest_skill_required'; end if;
      if v_item.due_at is null then raise exception 'exam_prep_retention_retest_due_required'; end if;
      if v_item.due_at>now() then raise exception 'exam_prep_retest_too_early'; end if;

      perform private.rebuild_exam_prep_state_v1(v_uid,v_plan.component_code);

      select * into v_state
      from private.exam_prep_skill_states s
      where s.user_id=v_uid and s.program_version_id=v_plan.program_version_id
        and s.component_code=v_plan.component_code and s.skill_code=v_item.skill_code
        and s.engine_version='objective_state_v1';
      select * into v_contract
      from private.exam_prep_skill_contracts c
      where c.program_version_id=v_plan.program_version_id
        and c.component_code=v_plan.component_code and c.skill_code=v_item.skill_code;

      if v_state.skill_code is null or v_contract.skill_code is null then raise exception 'exam_prep_retention_retest_state_missing'; end if;
      if v_state.objective_level<2 then raise exception 'exam_prep_retention_retest_coverage_required'; end if;
      if v_state.has_delayed_successful_retest then raise exception 'exam_prep_retention_retest_already_satisfied'; end if;
      if coalesce(v_state.unresolved_correction_count,0)>0 then raise exception 'exam_prep_retention_retest_correction_open'; end if;
      if v_contract.requires_transfer_for_l3 and not v_state.has_transfer_evidence then raise exception 'exam_prep_retention_retest_transfer_required'; end if;

      if v_contract.requires_mixed_for_l3 then
        select exists(
          select 1
          from private.exam_prep_evidence_events e
          join private.exam_prep_sessions ses on ses.id=e.session_id
          where e.user_id=v_uid and e.component_code=v_plan.component_code
            and e.skill_code=v_item.skill_code and e.evidence_type='mixed'
            and e.verification_status='app_verified' and e.is_correct is true
            and ses.user_id=v_uid and ses.status='finalized'
        ) into v_has_mixed;
        if not v_has_mixed then raise exception 'exam_prep_retention_retest_mixed_required'; end if;
      end if;

      v_ass:=private.exam_prep_select_fresh_retest_assessment_v1(v_uid,v_plan.component_code,v_item.skill_code);
      if v_ass is null then raise exception 'exam_prep_retest_fresh_content_exhausted'; end if;

      insert into private.exam_prep_session_authorizations(
        user_id,assessment_id,component_code,purpose,status,valid_until,reason,correction_case_id
      ) values(
        v_uid,v_ass,v_plan.component_code,'retest','issued',now()+interval '1 hour',
        'Core delayed retention retest using fresh isolated reserve',null
      ) returning id into v_auth;

      v_result:=jsonb_build_object(
        'authorization_id',v_auth,'assessment_id',v_ass,'component_code',v_plan.component_code,
        'skill_code',v_item.skill_code,'due_not_before',v_item.due_at,'purpose','retest',
        'retest_kind','retention','fresh_reserve',true
      );
    end if;

  elsif v_item.item_type='mixed_transfer' then
    if coalesce(v_item.action_payload->>'assessment_id','') !~ '^[0-9]+$' then
      raise exception 'exam_prep_mixed_plan_assessment_required';
    end if;
    v_ass:=(v_item.action_payload->>'assessment_id')::bigint;
    if not private.exam_prep_mixed_assessment_eligible_v1(
      v_uid,v_plan.component_code,v_plan.active_week_no,v_ass
    ) then
      raise exception 'exam_prep_mixed_plan_stale';
    end if;

    insert into private.exam_prep_session_authorizations(
      user_id,assessment_id,component_code,purpose,status,valid_until,reason
    ) values(
      v_uid,v_ass,v_plan.component_code,'mixed','issued',now()+interval '1 hour',
      'Core exact planned same-component mixed transfer'
    ) returning id into v_auth;

    v_result:=jsonb_build_object(
      'authorization_id',v_auth,'assessment_id',v_ass,'component_code',v_plan.component_code,
      'purpose','mixed','selection_basis','exact_weekly_plan_binding','p1_p5_separate',true
    );

  elsif v_item.item_type='learning' then
    if v_item.skill_code is null then raise exception 'exam_prep_plan_learning_skill_required'; end if;
    if not private.exam_prep_skill_runway_ready_for_week_v1(
      v_plan.program_version_id,v_plan.component_code,v_item.skill_code,v_plan.active_week_no
    ) then
      raise exception 'exam_prep_plan_learning_outside_ready_runway';
    end if;

    select a.id into v_ass
    from private.exam_prep_assessments a
    where a.component_code=v_plan.component_code and a.assessment_type='learning' and a.status='published'
      and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=v_item.skill_code)
      and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>v_item.skill_code)
    order by a.id limit 1;
    if v_ass is null then raise exception 'exam_prep_plan_learning_content_not_ready'; end if;

    select count(*) filter(where question_id is not null),count(*) filter(where written_task_id is not null)
      into v_questions,v_written
    from private.exam_prep_assessment_items where assessment_id=v_ass;
    if v_questions<3 or v_written<1 then raise exception 'exam_prep_plan_learning_content_floor_not_met'; end if;

    insert into private.exam_prep_session_authorizations(
      user_id,assessment_id,component_code,purpose,status,valid_until,reason
    ) values(
      v_uid,v_ass,v_plan.component_code,'learning','issued',now()+interval '1 hour',
      'Active weekly plan learning priority '||p_priority_order::text||'; skill '||v_item.skill_code
    ) returning id into v_auth;

    v_result:=jsonb_build_object(
      'authorization_id',v_auth,'assessment_id',v_ass,'component_code',v_plan.component_code,
      'skill_code',v_item.skill_code,'purpose','learning'
    );
  else
    raise exception 'exam_prep_plan_item_not_session_actionable type=%',v_item.item_type;
  end if;

  return v_result || jsonb_build_object(
    'plan_id',v_plan.id,'priority_order',v_item.priority_order,
    'item_type',v_item.item_type,'action_code',v_item.action_code
  );
end;
$$;
revoke execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) from public,anon;
grant execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) to authenticated,service_role;

create or replace function private.exam_prep_correction_queue_payload_v1(p_user_id uuid,p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_program bigint;
  v_payload jsonb;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_correction_queue_user_not_found' using errcode='P0002';
  end if;
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select pv.id into v_program
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active';
  if v_program is null then raise exception 'exam_prep_correction_queue_program_missing'; end if;

  with active_cases as (
    select
      c.id,c.skill_code,c.status,c.opened_at,c.updated_at,
      n.sequence_no,n.official_syllabus_section,n.canonical_description,
      case when c.reason->>'source'='finalized_incorrect_evidence' then 'incorrect_evidence' else coalesce(c.reason->>'source','other') end as origin,
      rt.id as retest_event_id,rt.status as retest_status,rt.due_not_before as retest_due_at,
      ca.action_type as latest_action_type,ca.created_at as latest_action_at,
      exists(
        select 1 from private.exam_prep_assessments a
        where a.component_code=p_component_code and a.assessment_type='learning' and a.status='published'
          and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=c.skill_code)
          and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>c.skill_code)
      ) as correction_content_ready,
      private.exam_prep_fresh_retest_content_ready_v1(p_user_id,p_component_code,c.skill_code) as retest_content_ready
    from private.exam_prep_correction_cases c
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=v_program and n.component_code=c.component_code and n.skill_code=c.skill_code
    left join lateral (
      select r.id,r.status,r.due_not_before
      from private.exam_prep_retest_events r
      where r.correction_case_id=c.id and r.user_id=p_user_id
      order by r.created_at desc limit 1
    ) rt on true
    left join lateral (
      select a.action_type,a.created_at
      from private.exam_prep_correction_actions a
      where a.correction_case_id=c.id and a.user_id=p_user_id
      order by a.created_at desc,a.id desc limit 1
    ) ca on true
    where c.user_id=p_user_id and c.component_code=p_component_code
      and c.status in ('open','remediating','retest_due','reopened')
  ), normalized as (
    select *,
      case
        when status in ('open','reopened') then 'review_error'
        when status='remediating' then 'practice_analogues'
        when status='retest_due' and retest_due_at is not null and retest_due_at>now() then 'wait_delayed_retest'
        when status='retest_due' and not retest_content_ready then 'retest_content_wait'
        when status='retest_due' then 'delayed_retest'
        else 'review_error'
      end as process_step,
      (status in ('open','remediating','reopened') and correction_content_ready) as can_start_correction,
      (status='retest_due' and retest_status='scheduled' and retest_due_at is not null and retest_due_at<=now() and retest_content_ready) as can_start_retest
    from active_cases
  ), resolved_recent as (
    select c.id,c.skill_code,c.opened_at,c.resolved_at,n.official_syllabus_section,n.canonical_description
    from private.exam_prep_correction_cases c
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=v_program and n.component_code=c.component_code and n.skill_code=c.skill_code
    where c.user_id=p_user_id and c.component_code=p_component_code and c.status='resolved'
    order by c.resolved_at desc nulls last,c.updated_at desc limit 10
  )
  select jsonb_build_object(
    'component_code',p_component_code,
    'active_count',(select count(*) from normalized),
    'retest_due_count',(select count(*) from normalized where status='retest_due'),
    'cases',coalesce((select jsonb_agg(jsonb_build_object(
      'correction_case_id',id,'skill_code',skill_code,
      'official_syllabus_section',official_syllabus_section,'description',canonical_description,
      'status',status,'origin',origin,'process_step',process_step,
      'opened_at',opened_at,'updated_at',updated_at,
      'retest_event_id',retest_event_id,'retest_status',retest_status,'retest_due_at',retest_due_at,
      'latest_action_type',latest_action_type,'latest_action_at',latest_action_at,
      'correction_content_ready',correction_content_ready,'retest_content_ready',retest_content_ready,
      'can_start_correction',can_start_correction,'can_start_retest',can_start_retest
    ) order by sequence_no,opened_at) from normalized),'[]'::jsonb),
    'recent_resolved',coalesce((select jsonb_agg(jsonb_build_object(
      'correction_case_id',id,'skill_code',skill_code,'official_syllabus_section',official_syllabus_section,
      'description',canonical_description,'opened_at',opened_at,'resolved_at',resolved_at
    ) order by resolved_at desc) from resolved_recent),'[]'::jsonb)
  ) into v_payload;

  return v_payload;
end;
$$;
revoke all on function private.exam_prep_correction_queue_payload_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_correction_queue_payload_v1(uuid,text) to service_role;

-- Keep P2-18 planner behavior, but only schedule a retention retest when a fresh isolated reserve is actually available.
create or replace function public.generate_exam_prep_weekly_plan_safe_v3(p_component_code text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_effective_week smallint;
  v_base jsonb;
  v_plan uuid;
  v_case private.exam_prep_progress_revalidation_cases%rowtype;
  v_failed record;
  v_corr record;
  v_replace smallint;
  v_count int;
  v_learning_count int;
  v_applied int:=0;
  v_mixed_assessment bigint;
  v_mixed_key text;
  v_mixed_planned boolean:=false;
  v_retention_skill text;
  v_retention_due timestamptz;
  v_retention_planned boolean:=false;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  v_effective_week:=private.exam_prep_effective_active_week_v1(v_uid);
  if v_effective_week is null then raise exception 'exam_prep_profile_required'; end if;

  update private.exam_prep_exam_profiles
  set active_week_no=v_effective_week,updated_at=now(),updated_by=v_uid
  where user_id=v_uid and active_week_no<v_effective_week;

  v_base:=public.generate_exam_prep_weekly_plan_safe_v2(p_component_code);
  v_plan:=(v_base->>'plan_id')::uuid;

  if coalesce(v_base->>'recovery_mode','normal')='normal' then
    delete from private.exam_prep_weekly_plan_items i
    where i.plan_id=v_plan and i.item_type='retest'
      and i.priority_order<>(
        select min(k.priority_order) from private.exam_prep_weekly_plan_items k
        where k.plan_id=v_plan and k.item_type='retest'
      );

    for v_corr in
      select c.id,c.skill_code
      from private.exam_prep_correction_cases c
      where c.user_id=v_uid and c.component_code=p_component_code
        and c.status in ('open','remediating','reopened')
        and not exists(select 1 from private.exam_prep_weekly_plan_items i where i.plan_id=v_plan and i.correction_case_id=c.id)
      order by c.opened_at
    loop
      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;
      exit when v_count>=3;
      select min(gs)::smallint into v_replace
      from generate_series(1,3) gs
      where not exists(select 1 from private.exam_prep_weekly_plan_items i where i.plan_id=v_plan and i.priority_order=gs);
      exit when v_replace is null;
      insert into private.exam_prep_weekly_plan_items(
        plan_id,priority_order,item_type,skill_code,correction_case_id,action_code,action_payload
      ) values(
        v_plan,v_replace,'correction',v_corr.skill_code,v_corr.id,'COMPLETE_CORRECTION_ANALOGUES',
        jsonb_build_object('analogue_floor',3,'analogue_ceiling',6,'written_or_unprompted_required',true,'preserve_in_recovery',true)
      );
    end loop;
  end if;

  select rv.* into v_case
  from private.exam_prep_progress_revalidation_cases rv
  join private.exam_prep_recovery_cases rc on rc.id=rv.recovery_case_id
  where rv.user_id=v_uid and rv.component_code=p_component_code
    and rv.status='refresh_recommended' and rc.status='active'
  order by rv.updated_at desc limit 1;

  if v_case.id is not null then
    for v_failed in
      select i.skill_code
      from private.exam_prep_progress_revalidation_items i
      where i.case_id=v_case.id and i.status='completed' and i.passed is false
      order by i.item_order
    loop
      continue when exists(select 1 from private.exam_prep_weekly_plan_items x where x.plan_id=v_plan and x.skill_code=v_failed.skill_code and x.item_type in ('retest','correction'));
      continue when exists(select 1 from private.exam_prep_weekly_plan_items x where x.plan_id=v_plan and x.skill_code=v_failed.skill_code and x.action_code='RECOVERY_REFRESH_RETAINED_SKILL');
      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;
      select max(priority_order)::smallint into v_replace
      from private.exam_prep_weekly_plan_items
      where plan_id=v_plan and item_type='learning' and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';
      if v_replace is not null then
        delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
      elsif v_count<3 then
        select min(gs)::smallint into v_replace from generate_series(1,3) gs
        where not exists(select 1 from private.exam_prep_weekly_plan_items x where x.plan_id=v_plan and x.priority_order=gs);
      else
        continue;
      end if;
      insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,action_code,action_payload)
      values(v_plan,v_replace,'learning',v_failed.skill_code,'RECOVERY_REFRESH_RETAINED_SKILL',
        jsonb_build_object('progress_retained',true,'revalidation_failed',true,'academic_stage_unchanged',true));
      v_applied:=v_applied+1;
    end loop;
  end if;

  if coalesce(v_base->>'recovery_mode','normal') in ('normal','reserve_1w','recovery_2_3w')
     and not exists(select 1 from private.exam_prep_weekly_plan_items x where x.plan_id=v_plan and x.item_type='retest') then
    with first_ev as (
      select e.skill_code,min(e.created_at) as first_non_retest_at
      from private.exam_prep_evidence_events e
      join private.exam_prep_sessions ses on ses.id=e.session_id
      where e.user_id=v_uid and e.component_code=p_component_code and e.evidence_type<>'retest'
        and ses.user_id=v_uid and ses.status='finalized'
      group by e.skill_code
    )
    select s.skill_code,
      greatest(f.first_non_retest_at+(coalesce(c.min_retest_delay_days,0)*interval '1 day'),f.first_non_retest_at+interval '2 days')
    into v_retention_skill,v_retention_due
    from private.exam_prep_skill_states s
    join private.exam_prep_skill_contracts c
      on c.program_version_id=s.program_version_id and c.component_code=s.component_code and c.skill_code=s.skill_code
    join first_ev f on f.skill_code=s.skill_code
    where s.user_id=v_uid
      and s.program_version_id=(select program_version_id from private.exam_prep_exam_profiles where user_id=v_uid)
      and s.component_code=p_component_code and s.engine_version='objective_state_v1' and s.objective_level=2
      and c.requires_retest_for_l3 and not s.has_delayed_successful_retest
      and coalesce(s.unresolved_correction_count,0)=0
      and (not c.requires_transfer_for_l3 or s.has_transfer_evidence)
      and (not c.requires_mixed_for_l3 or exists(
        select 1 from private.exam_prep_evidence_events me
        join private.exam_prep_sessions ms on ms.id=me.session_id
        where me.user_id=v_uid and me.component_code=p_component_code and me.skill_code=s.skill_code
          and me.evidence_type='mixed' and me.verification_status='app_verified' and me.is_correct is true
          and ms.user_id=v_uid and ms.status='finalized'
      ))
      and greatest(f.first_non_retest_at+(coalesce(c.min_retest_delay_days,0)*interval '1 day'),f.first_non_retest_at+interval '2 days')<=now()+interval '7 days'
      and private.exam_prep_fresh_retest_content_ready_v1(v_uid,p_component_code,s.skill_code)
    order by
      (greatest(f.first_non_retest_at+(coalesce(c.min_retest_delay_days,0)*interval '1 day'),f.first_non_retest_at+interval '2 days')<=now()) desc,
      greatest(f.first_non_retest_at+(coalesce(c.min_retest_delay_days,0)*interval '1 day'),f.first_non_retest_at+interval '2 days'),s.skill_code
    limit 1;

    if v_retention_skill is not null then
      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;
      v_replace:=null;
      if v_retention_due<=now() then
        select max(priority_order)::smallint into v_replace
        from private.exam_prep_weekly_plan_items
        where plan_id=v_plan and item_type='learning' and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';
        if v_replace is null and v_count<3 then
          select min(gs)::smallint into v_replace from generate_series(1,3) gs
          where not exists(select 1 from private.exam_prep_weekly_plan_items x where x.plan_id=v_plan and x.priority_order=gs);
        end if;
      elsif v_count<3 then
        select min(gs)::smallint into v_replace from generate_series(1,3) gs
        where not exists(select 1 from private.exam_prep_weekly_plan_items x where x.plan_id=v_plan and x.priority_order=gs);
      end if;
      if v_replace is not null then
        if exists(select 1 from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace) then
          delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
        end if;
        insert into private.exam_prep_weekly_plan_items(
          plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,action_code,action_payload
        ) values(
          v_plan,v_replace,'retest',v_retention_skill,null,v_retention_due,'COMPLETE_RETENTION_RETEST',
          jsonb_build_object('retest_kind','retention','correction_required',false,'atomic_coverage_required',true,'transfer_requirement_preserved',true,'calendar_auto_promotion',false,'fresh_reserve_required',true)
        );
        v_retention_planned:=true;
      end if;
    end if;
  end if;

  if coalesce(v_base->>'recovery_mode','normal')='normal' then
    v_mixed_assessment:=private.exam_prep_select_mixed_assessment_v1(v_uid,p_component_code,v_effective_week);
    if v_mixed_assessment is not null then
      select assessment_key into v_mixed_key from private.exam_prep_assessments where id=v_mixed_assessment;
      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;
      select count(*)::int into v_learning_count
      from private.exam_prep_weekly_plan_items
      where plan_id=v_plan and item_type='learning' and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';
      v_replace:=null;
      if v_count<3 then
        select min(gs)::smallint into v_replace from generate_series(1,3) gs
        where not exists(select 1 from private.exam_prep_weekly_plan_items x where x.plan_id=v_plan and x.priority_order=gs);
      elsif v_learning_count>=2 then
        select max(priority_order)::smallint into v_replace
        from private.exam_prep_weekly_plan_items
        where plan_id=v_plan and item_type='learning' and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';
      end if;
      if v_replace is not null then
        if exists(select 1 from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace) then
          delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
        end if;
        insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,action_code,action_payload)
        values(
          v_plan,v_replace,'mixed_transfer',null,'COMPLETE_MIXED_TRANSFER',
          jsonb_build_object('assessment_id',v_mixed_assessment,'assessment_key',v_mixed_key,'component_code',p_component_code,'atomic_coverage_required',true,'same_component_only',true,'calendar_auto_promotion',false)
        );
        v_mixed_planned:=true;
      end if;
    end if;
  end if;

  select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;
  return v_base || jsonb_build_object(
    'active_week_no',v_effective_week,'priority_count',v_count,'progress_retained',true,
    'revalidation_refresh_applied',(v_applied>0),'revalidation_refresh_count',v_applied,
    'academic_stage_changed_by_recovery',false,'calendar_auto_promotion',false,
    'retention_retest_planned',v_retention_planned,'retention_retest_skill',v_retention_skill,
    'retention_retest_due_at',v_retention_due,'mixed_transfer_planned',v_mixed_planned,
    'mixed_assessment_id',v_mixed_assessment
  );
end;
$$;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) to authenticated,service_role;

commit;