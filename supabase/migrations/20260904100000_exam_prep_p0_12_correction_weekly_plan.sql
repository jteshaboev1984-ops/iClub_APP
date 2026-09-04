-- P0-12: Core learning/correction/retest/mixed/weekly-plan baseline.
-- Additive only. No legacy mutation. No AI or Mentor dependency.
-- Correction closes only on fresh delayed retest evidence; calendar alone cannot close it.

begin;

alter table private.exam_prep_session_authorizations
  add column if not exists correction_case_id uuid null references private.exam_prep_correction_cases(id) on delete restrict;

create unique index if not exists exam_prep_one_unresolved_correction_per_skill_idx
  on private.exam_prep_correction_cases(user_id,component_code,skill_code)
  where status in ('open','remediating','retest_due','reopened');
create unique index if not exists exam_prep_one_active_retest_per_case_idx
  on private.exam_prep_retest_events(correction_case_id)
  where status in ('scheduled','authorized');

create table if not exists private.exam_prep_correction_actions (
  id uuid primary key default gen_random_uuid(),
  correction_case_id uuid not null references private.exam_prep_correction_cases(id) on delete restrict,
  user_id uuid not null references public.users(id) on delete cascade,
  component_code text not null check(component_code in ('P1','P5')),
  skill_code text not null,
  action_type text not null check(action_type in (
    'error_observed','remediation_authorized','remediation_incomplete','remediation_completed',
    'retest_scheduled','retest_authorized','retest_passed','retest_failed','case_closed','case_reopened'
  )),
  session_id uuid null references private.exam_prep_sessions(id) on delete restrict,
  evidence_id uuid null references private.exam_prep_evidence_events(id) on delete restrict,
  retest_event_id uuid null references private.exam_prep_retest_events(id) on delete restrict,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists private.exam_prep_weekly_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  active_week_no smallint not null check(active_week_no>=1),
  plan_version integer not null check(plan_version>=1),
  status text not null default 'active' check(status in ('active','superseded','completed')),
  recovery_mode text not null default 'normal' check(recovery_mode in ('normal','reserve_1w','recovery_2_3w','rebaseline_over_1mo')),
  max_priorities smallint not null default 3 check(max_priorities=3),
  policy_note text not null,
  generated_at timestamptz not null default now(),
  unique(user_id,component_code,active_week_no,plan_version)
);
create unique index if not exists exam_prep_one_active_weekly_plan_idx
  on private.exam_prep_weekly_plans(user_id,component_code)
  where status='active';

create table if not exists private.exam_prep_weekly_plan_items (
  plan_id uuid not null references private.exam_prep_weekly_plans(id) on delete cascade,
  priority_order smallint not null check(priority_order between 1 and 3),
  item_type text not null check(item_type in ('retest','correction','mixed_transfer','learning','prerequisite','rebaseline')),
  skill_code text null,
  correction_case_id uuid null references private.exam_prep_correction_cases(id) on delete restrict,
  due_at timestamptz null,
  action_code text not null,
  action_payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check(status in ('pending','completed','superseded')),
  created_at timestamptz not null default now(),
  primary key(plan_id,priority_order)
);

-- Private-only operational tables.
do $$ declare t text; begin
  foreach t in array array['exam_prep_correction_actions','exam_prep_weekly_plans','exam_prep_weekly_plan_items'] loop
    execute format('alter table private.%I enable row level security',t);
    execute format('revoke all on private.%I from public,anon,authenticated',t);
    execute format('grant all on private.%I to service_role',t);
  end loop;
end $$;

-- Correction actions are append-only facts.
drop trigger if exists exam_prep_correction_actions_immutable_v1 on private.exam_prep_correction_actions;
create trigger exam_prep_correction_actions_immutable_v1
before update or delete on private.exam_prep_correction_actions
for each row execute function private.exam_prep_block_immutable_mutation_v1();

create or replace function private.exam_prep_log_correction_action_v1(
  p_case_id uuid,p_action_type text,p_session_id uuid default null,p_evidence_id uuid default null,
  p_retest_event_id uuid default null,p_payload jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare v_case private.exam_prep_correction_cases%rowtype; v_id uuid;
begin
  select * into v_case from private.exam_prep_correction_cases where id=p_case_id;
  if v_case.id is null then raise exception 'exam_prep_correction_case_not_found'; end if;
  insert into private.exam_prep_correction_actions(correction_case_id,user_id,component_code,skill_code,action_type,session_id,evidence_id,retest_event_id,payload)
  values(v_case.id,v_case.user_id,v_case.component_code,v_case.skill_code,p_action_type,p_session_id,p_evidence_id,p_retest_event_id,coalesce(p_payload,'{}'::jsonb))
  returning id into v_id;
  return v_id;
end;
$$;
revoke all on function private.exam_prep_log_correction_action_v1(uuid,text,uuid,uuid,uuid,jsonb) from public,anon,authenticated;
grant execute on function private.exam_prep_log_correction_action_v1(uuid,text,uuid,uuid,uuid,jsonb) to service_role;

-- Reconcile a finalized session into correction/retest facts.
create or replace function private.exam_prep_reconcile_finalized_session_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_ev record; v_case private.exam_prep_correction_cases%rowtype; v_auth private.exam_prep_session_authorizations%rowtype;
  v_machine_correct int; v_machine_total int; v_written int; v_retest private.exam_prep_retest_events%rowtype;
  v_contract private.exam_prep_skill_contracts%rowtype; v_due timestamptz;
begin
  if old.status is not distinct from new.status or new.status<>'finalized' then return new; end if;

  -- Every finalized server-verified wrong response opens/reopens exactly one component+skill correction.
  for v_ev in
    select e.* from private.exam_prep_evidence_events e
    where e.session_id=new.id and e.user_id=new.user_id and e.verification_status='app_verified' and e.is_correct is false
  loop
    select * into v_case from private.exam_prep_correction_cases c
    where c.user_id=new.user_id and c.component_code=new.component_code and c.skill_code=v_ev.skill_code
      and c.status in ('open','remediating','retest_due','reopened')
    order by c.opened_at desc limit 1;
    if v_case.id is null then
      insert into private.exam_prep_correction_cases(user_id,component_code,skill_code,status,opened_from_evidence_id,engine_version,reason)
      values(new.user_id,new.component_code,v_ev.skill_code,'open',v_ev.id,'objective_state_v1',
        jsonb_build_object('source','finalized_incorrect_evidence','session_id',new.id,'evidence_type',v_ev.evidence_type))
      returning * into v_case;
    else
      update private.exam_prep_correction_cases set status='reopened',updated_at=now(),resolved_at=null,
        reason=reason || jsonb_build_object('latest_wrong_evidence_id',v_ev.id,'latest_wrong_session_id',new.id)
      where id=v_case.id returning * into v_case;
    end if;
    perform private.exam_prep_log_correction_action_v1(v_case.id,'error_observed',new.id,v_ev.id,null,
      jsonb_build_object('evidence_type',v_ev.evidence_type));
  end loop;

  select * into v_auth from private.exam_prep_session_authorizations where id=new.authorization_id;
  if v_auth.id is null or v_auth.correction_case_id is null then return new; end if;
  select * into v_case from private.exam_prep_correction_cases where id=v_auth.correction_case_id and user_id=new.user_id and component_code=new.component_code;
  if v_case.id is null then raise exception 'exam_prep_finalize_correction_scope_mismatch'; end if;

  if new.session_type='learning' then
    select count(*) filter(where r.response_kind='machine' and r.is_correct is true),
           count(*) filter(where r.response_kind='machine'),
           count(*) filter(where r.response_kind='written')
      into v_machine_correct,v_machine_total,v_written
    from private.exam_prep_responses r where r.session_id=new.id and r.user_id=new.user_id;

    if v_machine_correct>=3 and v_machine_total>=3 and v_written>=1 then
      update private.exam_prep_correction_cases set status='retest_due',updated_at=now() where id=v_case.id returning * into v_case;
      perform private.exam_prep_log_correction_action_v1(v_case.id,'remediation_completed',new.id,null,null,
        jsonb_build_object('correct_analogues',v_machine_correct,'machine_total',v_machine_total,'written_artifacts',v_written));

      select c.* into v_contract from private.exam_prep_skill_contracts c
      where c.program_version_id=new.program_version_id and c.skill_code=v_case.skill_code and c.component_code=v_case.component_code;
      v_due:=greatest(now()+interval '2 days',v_case.opened_at + (coalesce(v_contract.min_retest_delay_days,0)*interval '1 day'));
      insert into private.exam_prep_retest_events(correction_case_id,user_id,component_code,skill_code,status,due_not_before)
      values(v_case.id,v_case.user_id,v_case.component_code,v_case.skill_code,'scheduled',v_due)
      on conflict(correction_case_id) where status in ('scheduled','authorized') do nothing
      returning * into v_retest;
      if v_retest.id is null then select * into v_retest from private.exam_prep_retest_events where correction_case_id=v_case.id and status in ('scheduled','authorized') order by created_at desc limit 1; end if;
      perform private.exam_prep_log_correction_action_v1(v_case.id,'retest_scheduled',new.id,null,v_retest.id,jsonb_build_object('due_not_before',v_retest.due_not_before));
    else
      update private.exam_prep_correction_cases set status='remediating',updated_at=now() where id=v_case.id;
      perform private.exam_prep_log_correction_action_v1(v_case.id,'remediation_incomplete',new.id,null,null,
        jsonb_build_object('correct_analogues',v_machine_correct,'machine_total',v_machine_total,'written_artifacts',v_written,'required_correct_analogues',3,'written_required',true));
    end if;
  elsif new.session_type='retest' then
    select * into v_retest from private.exam_prep_retest_events
    where correction_case_id=v_case.id and authorization_id=v_auth.id and status='authorized'
    order by created_at desc limit 1;
    if v_retest.id is null then raise exception 'exam_prep_retest_event_not_authorized'; end if;
    select count(*) filter(where r.response_kind='machine' and r.is_correct is true),count(*) filter(where r.response_kind='machine')
      into v_machine_correct,v_machine_total from private.exam_prep_responses r where r.session_id=new.id and r.user_id=new.user_id;
    update private.exam_prep_retest_events set status='completed',completed_session_id=new.id,completed_at=now() where id=v_retest.id;
    if v_machine_total>0 and v_machine_correct=v_machine_total then
      update private.exam_prep_correction_cases set status='resolved',resolved_at=now(),updated_at=now() where id=v_case.id;
      perform private.exam_prep_log_correction_action_v1(v_case.id,'retest_passed',new.id,null,v_retest.id,jsonb_build_object('correct',v_machine_correct,'total',v_machine_total));
      perform private.exam_prep_log_correction_action_v1(v_case.id,'case_closed',new.id,null,v_retest.id,jsonb_build_object('closure_basis','fresh_delayed_retest'));
    else
      update private.exam_prep_correction_cases set status='reopened',resolved_at=null,updated_at=now() where id=v_case.id;
      perform private.exam_prep_log_correction_action_v1(v_case.id,'retest_failed',new.id,null,v_retest.id,jsonb_build_object('correct',v_machine_correct,'total',v_machine_total));
      perform private.exam_prep_log_correction_action_v1(v_case.id,'case_reopened',new.id,null,v_retest.id,jsonb_build_object('reason','failed_delayed_retest'));
    end if;
  end if;

  return new;
end;
$$;
revoke all on function private.exam_prep_reconcile_finalized_session_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_reconcile_finalized_session_v1 on private.exam_prep_sessions;
create trigger exam_prep_reconcile_finalized_session_v1
after update of status on private.exam_prep_sessions
for each row execute function private.exam_prep_reconcile_finalized_session_v1();

-- Core-safe authorizer for correction analogue work. Uses governed published learning assessment for the same skill.
create or replace function public.authorize_exam_prep_correction_safe_v1(p_correction_case_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_case private.exam_prep_correction_cases%rowtype; v_ass bigint; v_auth uuid; v_items int; v_written int;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_case from private.exam_prep_correction_cases where id=p_correction_case_id and user_id=v_uid;
  if v_case.id is null then raise exception 'exam_prep_correction_case_not_found' using errcode='P0002'; end if;
  if v_case.status not in ('open','remediating','reopened') then raise exception 'exam_prep_correction_not_remediating'; end if;
  select a.id into v_ass from private.exam_prep_assessments a
  where a.component_code=v_case.component_code and a.assessment_type='learning' and a.status='published'
    and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=v_case.skill_code)
    and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>v_case.skill_code)
  order by a.id limit 1;
  if v_ass is null then raise exception 'exam_prep_correction_content_not_ready'; end if;
  select count(*) filter(where question_id is not null),count(*) filter(where written_task_id is not null)
    into v_items,v_written from private.exam_prep_assessment_items where assessment_id=v_ass;
  if v_items<3 or v_written<1 then raise exception 'exam_prep_correction_content_floor_not_met'; end if;
  insert into private.exam_prep_session_authorizations(user_id,assessment_id,component_code,purpose,status,valid_until,reason,correction_case_id)
  values(v_uid,v_ass,v_case.component_code,'learning','issued',now()+interval '1 hour','Core correction analogue session',v_case.id)
  returning id into v_auth;
  update private.exam_prep_correction_cases set status='remediating',updated_at=now() where id=v_case.id;
  perform private.exam_prep_log_correction_action_v1(v_case.id,'remediation_authorized',null,null,null,jsonb_build_object('authorization_id',v_auth,'assessment_id',v_ass));
  return jsonb_build_object('authorization_id',v_auth,'correction_case_id',v_case.id,'component_code',v_case.component_code,'skill_code',v_case.skill_code,'purpose','learning');
end;
$$;
revoke execute on function public.authorize_exam_prep_correction_safe_v1(uuid) from public,anon;
grant execute on function public.authorize_exam_prep_correction_safe_v1(uuid) to authenticated,service_role;

create or replace function public.authorize_exam_prep_retest_safe_v1(p_correction_case_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_case private.exam_prep_correction_cases%rowtype; v_rt private.exam_prep_retest_events%rowtype; v_ass bigint; v_auth uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_case from private.exam_prep_correction_cases where id=p_correction_case_id and user_id=v_uid;
  if v_case.id is null then raise exception 'exam_prep_correction_case_not_found' using errcode='P0002'; end if;
  if v_case.status<>'retest_due' then raise exception 'exam_prep_retest_not_due'; end if;
  select * into v_rt from private.exam_prep_retest_events
    where correction_case_id=v_case.id and user_id=v_uid and status='scheduled'
    order by created_at desc limit 1 for update;
  if v_rt.id is null then raise exception 'exam_prep_retest_event_not_found'; end if;
  if v_rt.due_not_before is not null and v_rt.due_not_before>now() then raise exception 'exam_prep_retest_too_early'; end if;
  select a.id into v_ass from private.exam_prep_assessments a
  where a.component_code=v_case.component_code and a.assessment_type='retest' and a.status='published'
    and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=v_case.skill_code)
    and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>v_case.skill_code)
  order by a.id limit 1;
  if v_ass is null then raise exception 'exam_prep_retest_content_not_ready'; end if;
  insert into private.exam_prep_session_authorizations(user_id,assessment_id,component_code,purpose,status,valid_until,reason,correction_case_id)
  values(v_uid,v_ass,v_case.component_code,'retest','issued',now()+interval '1 hour','Core delayed retest',v_case.id) returning id into v_auth;
  update private.exam_prep_retest_events set status='authorized',authorization_id=v_auth where id=v_rt.id;
  perform private.exam_prep_log_correction_action_v1(v_case.id,'retest_authorized',null,null,v_rt.id,jsonb_build_object('authorization_id',v_auth,'assessment_id',v_ass));
  return jsonb_build_object('authorization_id',v_auth,'retest_event_id',v_rt.id,'correction_case_id',v_case.id,'due_not_before',v_rt.due_not_before,'purpose','retest');
end;
$$;
revoke execute on function public.authorize_exam_prep_retest_safe_v1(uuid) from public,anon;
grant execute on function public.authorize_exam_prep_retest_safe_v1(uuid) to authenticated,service_role;

create or replace function public.authorize_exam_prep_mixed_safe_v1(p_component_code text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_program bigint; v_rule text; v_gate private.exam_prep_component_access_gates%rowtype; v_ass bigint; v_auth uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  perform private.rebuild_exam_prep_placement_v1(v_uid,p_component_code);
  select id into v_program from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select rule_version into v_rule from private.exam_prep_placement_rule_versions where program_version_id=v_program and status='active';
  select * into v_gate from private.exam_prep_component_access_gates where user_id=v_uid and program_version_id=v_program and component_code=p_component_code and rule_version=v_rule;
  if v_gate.user_id is null or not v_gate.foundation_learning_access then raise exception 'exam_prep_stage0_not_complete'; end if;
  select a.id into v_ass from private.exam_prep_assessments a where a.component_code=p_component_code and a.assessment_type='mixed' and a.status='published' order by a.id limit 1;
  if v_ass is null then raise exception 'exam_prep_mixed_content_not_ready'; end if;
  insert into private.exam_prep_session_authorizations(user_id,assessment_id,component_code,purpose,status,valid_until,reason)
  values(v_uid,v_ass,p_component_code,'mixed','issued',now()+interval '1 hour','Core same-component mixed transfer') returning id into v_auth;
  return jsonb_build_object('authorization_id',v_auth,'assessment_id',v_ass,'component_code',p_component_code,'purpose','mixed');
end;
$$;
revoke execute on function public.authorize_exam_prep_mixed_safe_v1(text) from public,anon;
grant execute on function public.authorize_exam_prep_mixed_safe_v1(text) to authenticated,service_role;

create or replace function public.generate_exam_prep_weekly_plan_safe_v1(p_component_code text,p_recovery_mode text default 'normal')
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_program bigint; v_week smallint; v_plan uuid; v_version int; v_order smallint:=0; v_case record; v_skill text; v_due timestamptz; v_note text;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  if p_recovery_mode not in ('normal','reserve_1w','recovery_2_3w','rebaseline_over_1mo') then raise exception 'exam_prep_bad_recovery_mode'; end if;
  select program_version_id,active_week_no into v_program,v_week from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_program is null or v_week<1 then raise exception 'exam_prep_profile_required'; end if;
  perform private.rebuild_exam_prep_state_v1(v_uid,p_component_code);
  perform private.rebuild_exam_prep_placement_v1(v_uid,p_component_code);

  update private.exam_prep_weekly_plans set status='superseded' where user_id=v_uid and component_code=p_component_code and status='active';
  select coalesce(max(plan_version),0)+1 into v_version from private.exam_prep_weekly_plans where user_id=v_uid and component_code=p_component_code and active_week_no=v_week;
  v_note:=case p_recovery_mode
    when 'normal' then 'Evidence-gated Core plan; at most three priorities; no calendar promotion.'
    when 'reserve_1w' then 'Absence <=1 week: use reserve/recovery; preserve key retest; do not lower evidence standards or auto-downgrade stage.'
    when 'recovery_2_3w' then 'Absence 2-3 weeks: 14-day recovery; retain retest/timed evidence; reprioritize at most three blockers; low-value work reduced. Source 50/25/15/10 split is recorded but not decomposed here because category semantics are not machine-defined in the approved source.'
    else 'Absence >1 month: rebaseline component feasibility, remaining weeks and must-do syllabus; no catch-up overload and no lowered evidence standard.' end;
  insert into private.exam_prep_weekly_plans(user_id,program_version_id,component_code,active_week_no,plan_version,status,recovery_mode,policy_note)
  values(v_uid,v_program,p_component_code,v_week,v_version,'active',p_recovery_mode,v_note) returning id into v_plan;

  if p_recovery_mode='rebaseline_over_1mo' then
    insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,action_code,action_payload)
    values(v_plan,1,'rebaseline','REBASELINE_COMPONENT',jsonb_build_object('component_code',p_component_code,'reason','prolonged_absence_over_one_month'));
    v_order:=1;
  else
    -- 1) Due retest first.
    for v_case in
      select c.id,c.skill_code,r.due_not_before from private.exam_prep_correction_cases c
      join private.exam_prep_retest_events r on r.correction_case_id=c.id and r.status in ('scheduled','authorized')
      where c.user_id=v_uid and c.component_code=p_component_code and c.status='retest_due'
      order by r.due_not_before nulls first,c.opened_at
    loop
      exit when v_order>=3; v_order:=v_order+1;
      insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,action_code,action_payload)
      values(v_plan,v_order,'retest',v_case.skill_code,v_case.id,v_case.due_not_before,'COMPLETE_DELAYED_RETEST',jsonb_build_object('preserve_in_recovery',true));
    end loop;

    -- 2) Open/reopened remediation next.
    for v_case in
      select c.id,c.skill_code from private.exam_prep_correction_cases c
      where c.user_id=v_uid and c.component_code=p_component_code and c.status in ('open','remediating','reopened')
      order by c.opened_at
    loop
      exit when v_order>=3;
      if not exists(select 1 from private.exam_prep_weekly_plan_items i where i.plan_id=v_plan and i.correction_case_id=v_case.id) then
        v_order:=v_order+1;
        insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,correction_case_id,action_code,action_payload)
        values(v_plan,v_order,'correction',v_case.skill_code,v_case.id,'COMPLETE_CORRECTION_ANALOGUES',jsonb_build_object('analogue_floor',3,'analogue_ceiling',6,'written_or_unprompted_required',true));
      end if;
    end loop;

    -- 3) Normal mode may add low-level governed learning; recovery modes deliberately avoid bulk new content.
    if v_order<3 and p_recovery_mode='normal' then
      for v_skill in
        select st.skill_code from private.exam_prep_skill_states st
        where st.user_id=v_uid and st.component_code=p_component_code and st.engine_version='objective_state_v1' and st.objective_level<=1
          and exists(select 1 from private.exam_prep_assessments a join private.exam_prep_assessment_items ai on ai.assessment_id=a.id where a.component_code=p_component_code and a.assessment_type='learning' and a.status='published' and ai.primary_skill_code=st.skill_code)
        order by st.objective_level,st.skill_code
      loop
        exit when v_order>=3; v_order:=v_order+1;
        insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,action_code,action_payload)
        values(v_plan,v_order,'learning',v_skill,'BUILD_FIRST_COVERAGE',jsonb_build_object('component_code',p_component_code));
      end loop;
    end if;
  end if;

  return jsonb_build_object('plan_id',v_plan,'component_code',p_component_code,'active_week_no',v_week,'plan_version',v_version,'recovery_mode',p_recovery_mode,'priority_count',v_order);
end;
$$;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v1(text,text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v1(text,text) to authenticated,service_role;

create or replace function public.get_exam_prep_weekly_plan_safe_v1(p_component_code text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_plan private.exam_prep_weekly_plans%rowtype; v_result jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  select * into v_plan from private.exam_prep_weekly_plans where user_id=v_uid and component_code=p_component_code and status='active' order by generated_at desc limit 1;
  if v_plan.id is null then return jsonb_build_object('component_code',p_component_code,'plan',null,'items','[]'::jsonb); end if;
  select jsonb_build_object('plan_id',v_plan.id,'component_code',v_plan.component_code,'active_week_no',v_plan.active_week_no,'plan_version',v_plan.plan_version,'recovery_mode',v_plan.recovery_mode,'policy_note',v_plan.policy_note,
    'items',coalesce(jsonb_agg(jsonb_build_object('priority_order',i.priority_order,'item_type',i.item_type,'skill_code',i.skill_code,'correction_case_id',i.correction_case_id,'due_at',i.due_at,'action_code',i.action_code,'action_payload',i.action_payload,'status',i.status) order by i.priority_order) filter(where i.plan_id is not null),'[]'::jsonb)) into v_result
  from private.exam_prep_weekly_plan_items i where i.plan_id=v_plan.id;
  return v_result;
end;
$$;
revoke execute on function public.get_exam_prep_weekly_plan_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_weekly_plan_safe_v1(text) to authenticated,service_role;

-- Static acceptance: append-only action table, max 3 priorities, client access only through safe RPCs.
do $$ begin
  if exists(select 1 from information_schema.role_table_grants where table_schema='private' and table_name in ('exam_prep_correction_actions','exam_prep_weekly_plans','exam_prep_weekly_plan_items') and grantee in ('anon','authenticated')) then
    raise exception 'P0-12 gate: private correction/plan grants exposed';
  end if;
  if not exists(select 1 from pg_trigger where tgrelid='private.exam_prep_sessions'::regclass and tgname='exam_prep_reconcile_finalized_session_v1' and not tgisinternal) then
    raise exception 'P0-12 gate: finalized-session reconciliation trigger missing';
  end if;
end $$;

commit;
