-- P2-08: non-destructive recovery amendment + progress revalidation.
-- User amendment 2026-09-08: time away changes planning, never erases knowledge/progress by itself.
-- Historical academic evidence stays immutable. A long/extended break may trigger a short NON-CREDITING
-- revalidation check. Passing confirms retained progress; failing recommends targeted refresh without
-- deleting prior evidence, lowering stages by calendar, or creating cross-component mastery.

begin;

-- 1) Recovery rows explicitly guarantee progress preservation.
alter table private.exam_prep_recovery_cases
  add column if not exists progress_retained boolean not null default true;
alter table private.exam_prep_recovery_cases
  add column if not exists revalidation_recommended boolean not null default false;
alter table private.exam_prep_recovery_cases
  add column if not exists revalidation_required_for_readiness boolean not null default false;

alter table private.exam_prep_recovery_cases
  drop constraint if exists exam_prep_recovery_cases_progress_retained_check;
alter table private.exam_prep_recovery_cases
  add constraint exam_prep_recovery_cases_progress_retained_check check(progress_retained is true);

-- 2) Session authorization can explicitly mark a check as non-crediting.
-- Existing authorizations remain academic-crediting by default.
alter table private.exam_prep_session_authorizations
  add column if not exists academic_credit boolean not null default true;
alter table private.exam_prep_session_authorizations
  add column if not exists credit_context text null;

alter table private.exam_prep_evidence_events
  drop constraint if exists exam_prep_evidence_events_verification_status_check;
alter table private.exam_prep_evidence_events
  add constraint exam_prep_evidence_events_verification_status_check
  check(verification_status in (
    'app_verified','app_checked_noncredit','self_reviewed',
    'human_review_recommended','mentor_verified','mentor_disputed'
  ));

-- Convert evidence from a non-crediting authorization BEFORE it can affect correction/mastery logic.
create or replace function private.exam_prep_noncredit_evidence_guard_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_credit boolean:=true;
  v_context text;
begin
  select a.academic_credit,a.credit_context into v_credit,v_context
  from private.exam_prep_sessions s
  join private.exam_prep_session_authorizations a on a.id=s.authorization_id
  where s.id=new.session_id;

  if coalesce(v_credit,true)=false then
    new.verification_status:='app_checked_noncredit';
    new.evidence_payload:=coalesce(new.evidence_payload,'{}'::jsonb) || jsonb_build_object(
      'academic_credit',false,
      'credit_context',coalesce(v_context,'progress_revalidation')
    );
  end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_noncredit_evidence_guard_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_noncredit_evidence_guard_v1 on private.exam_prep_evidence_events;
create trigger exam_prep_noncredit_evidence_guard_v1
before insert on private.exam_prep_evidence_events
for each row execute function private.exam_prep_noncredit_evidence_guard_v1();

-- 3) Separate revalidation state. This is confidence/recovery metadata, not mastery storage.
create table if not exists private.exam_prep_progress_revalidation_cases (
  id uuid primary key default gen_random_uuid(),
  recovery_case_id uuid not null unique references private.exam_prep_recovery_cases(id) on delete restrict,
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  status text not null default 'recommended'
    check(status in ('recommended','in_progress','confirmed','refresh_recommended','cancelled')),
  prior_stage smallint not null default 0 check(prior_stage between 0 and 6),
  prior_coverage_pct numeric(5,2) not null default 0 check(prior_coverage_pct between 0 and 100),
  prior_l2_count smallint not null default 0 check(prior_l2_count>=0),
  prior_l3_count smallint not null default 0 check(prior_l3_count>=0),
  selected_skill_count smallint not null default 0 check(selected_skill_count between 0 and 3),
  passed_skill_count smallint not null default 0 check(passed_skill_count between 0 and 3),
  failed_skill_count smallint not null default 0 check(failed_skill_count between 0 and 3),
  notice_required boolean not null default true,
  academic_state_mutation_allowed boolean not null default false,
  reason text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz null,
  check(academic_state_mutation_allowed is false)
);

create table if not exists private.exam_prep_progress_revalidation_items (
  case_id uuid not null references private.exam_prep_progress_revalidation_cases(id) on delete cascade,
  item_order smallint not null check(item_order between 1 and 3),
  skill_code text not null,
  prior_level smallint not null check(prior_level between 2 and 3),
  status text not null default 'pending' check(status in ('pending','authorized','completed')),
  authorization_id uuid null references private.exam_prep_session_authorizations(id) on delete restrict,
  session_id uuid null references private.exam_prep_sessions(id) on delete restrict,
  passed boolean null,
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  primary key(case_id,item_order),
  unique(case_id,skill_code)
);

alter table private.exam_prep_progress_revalidation_cases enable row level security;
alter table private.exam_prep_progress_revalidation_items enable row level security;
revoke all on private.exam_prep_progress_revalidation_cases from public,anon,authenticated;
revoke all on private.exam_prep_progress_revalidation_items from public,anon,authenticated;
grant all on private.exam_prep_progress_revalidation_cases to service_role;
grant all on private.exam_prep_progress_revalidation_items to service_role;

drop trigger if exists exam_prep_progress_revalidation_cases_audit_v1 on private.exam_prep_progress_revalidation_cases;
create trigger exam_prep_progress_revalidation_cases_audit_v1
after insert or update or delete on private.exam_prep_progress_revalidation_cases
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_progress_revalidation_items_audit_v1 on private.exam_prep_progress_revalidation_items;
create trigger exam_prep_progress_revalidation_items_audit_v1
after insert or update or delete on private.exam_prep_progress_revalidation_items
for each row execute function private.exam_prep_audit_row_change_v1();

-- 4) User-amended interpretation of the previously undefined day ranges.
-- <=7: light reserve; 8-13: conservative re-entry review, no reset;
-- 14-21: source-defined 14-day 50/25/15/10 recovery;
-- 22-30: extended recovery + optional short revalidation if prior progress exists;
-- >=31: planning rebaseline + optional revalidation; academic progress remains retained.
create or replace function private.exam_prep_recovery_amendment_policy_v1(p_missed_days integer)
returns jsonb
language plpgsql
immutable
security definer
set search_path=''
as $$
begin
  if p_missed_days is null or p_missed_days<1 or p_missed_days>365 then
    raise exception 'exam_prep_bad_missed_days';
  end if;
  if p_missed_days<=7 then
    return jsonb_build_object(
      'day_band','1_7','planning_mode','reserve_1w','progress_retained',true,
      'revalidation_default','not_needed','automatic_stage_change',false
    );
  elsif p_missed_days<=13 then
    return jsonb_build_object(
      'day_band','8_13','planning_mode','source_gap_review','progress_retained',true,
      'revalidation_default','not_needed','automatic_ratio',false,'automatic_stage_change',false,
      'user_amendment','conservative_reentry_without_reset'
    );
  elsif p_missed_days<=21 then
    return jsonb_build_object(
      'day_band','14_21','planning_mode','recovery_2_3w','progress_retained',true,
      'revalidation_default','not_needed','automatic_stage_change',false,
      'allocation',jsonb_build_object('mandatory_uncovered_topics_pct',50,'questions_on_those_topics_pct',25,'older_topics_pct',15,'timed_practice_pct',10)
    );
  elsif p_missed_days<=30 then
    return jsonb_build_object(
      'day_band','22_30','planning_mode','source_gap_review','progress_retained',true,
      'revalidation_default','recommended_if_prior_progress','automatic_ratio',false,
      'automatic_stage_change',false,'user_amendment','extended_recovery_with_optional_revalidation'
    );
  end if;
  return jsonb_build_object(
    'day_band','31_plus','planning_mode','rebaseline_over_1mo','progress_retained',true,
    'revalidation_default','recommended_if_prior_progress',
    'readiness_revalidation_if_prior_stage_4_plus',true,
    'automatic_stage_change',false,'user_amendment','planning_rebaseline_not_progress_reset'
  );
end;
$$;
revoke all on function private.exam_prep_recovery_amendment_policy_v1(integer) from public,anon,authenticated;
grant execute on function private.exam_prep_recovery_amendment_policy_v1(integer) to service_role;

-- 5) Record interruption v2: reuse existing source-faithful recovery creation, then apply the
-- non-destructive user amendment and prepare a small representative check only when useful.
create or replace function public.record_my_exam_prep_interruption_v2(
  p_interruption_started_on date,
  p_resumed_on date,
  p_interruption_kind text default 'absence'
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_base jsonb;
  v_days integer;
  v_policy jsonb;
  v_component text;
  v_recovery private.exam_prep_recovery_cases%rowtype;
  v_engine text;
  v_prior_confirmed int;
  v_l2 int;
  v_l3 int;
  v_reval_id uuid;
  v_selected int;
  v_cases jsonb:='[]'::jsonb;
  v_reval_recommended boolean;
  v_readiness_reval boolean;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  v_base:=public.record_my_exam_prep_interruption_v1(
    p_interruption_started_on,p_resumed_on,p_interruption_kind
  );
  v_days:=p_resumed_on-p_interruption_started_on;
  v_policy:=private.exam_prep_recovery_amendment_policy_v1(v_days);

  select engine_version into v_engine
  from private.exam_prep_state_engine_versions
  where status='active'
  order by created_at desc limit 1;
  if v_engine is null then raise exception 'exam_prep_state_engine_missing'; end if;

  foreach v_component in array array['P1','P5'] loop
    select * into v_recovery
    from private.exam_prep_recovery_cases
    where user_id=v_uid and component_code=v_component
      and interruption_started_on=p_interruption_started_on and resumed_on=p_resumed_on
      and status='active'
    order by created_at desc limit 1;
    if v_recovery.id is null then raise exception 'exam_prep_recovery_case_missing_after_record'; end if;

    select
      count(*) filter(where objective_level>=2)::int,
      count(*) filter(where objective_level=2)::int,
      count(*) filter(where objective_level>=3)::int
    into v_prior_confirmed,v_l2,v_l3
    from private.exam_prep_skill_states
    where user_id=v_uid and program_version_id=v_recovery.program_version_id
      and component_code=v_component and engine_version=v_engine;

    v_reval_recommended:=(v_days>=22 and coalesce(v_prior_confirmed,0)>0);
    v_readiness_reval:=(v_days>=31 and coalesce(v_recovery.stage_snapshot,0)>=4 and coalesce(v_prior_confirmed,0)>0);

    update private.exam_prep_recovery_cases
    set progress_retained=true,
        revalidation_recommended=v_reval_recommended,
        revalidation_required_for_readiness=v_readiness_reval,
        source_gap_note=case
          when v_days between 8 and 13 then 'User amendment 2026-09-08: 8-13 days use conservative re-entry planning. Prior progress is retained; no automatic ratio or stage reset.'
          when v_days between 22 and 30 then 'User amendment 2026-09-08: 22-30 days use extended recovery. Prior progress is retained; a short non-crediting revalidation may be offered.'
          when v_days>=31 then 'User amendment 2026-09-08: >1 month means planning rebaseline, not progress reset. Prior progress is retained; short revalidation may confirm current knowledge.'
          else source_gap_note
        end,
        allocation_policy=coalesce(allocation_policy,'{}'::jsonb) || jsonb_build_object(
          'progress_retained',true,
          'user_amendment_2026_09_08',true,
          'day_band',v_policy->>'day_band',
          'automatic_stage_change',false,
          'revalidation_recommended',v_reval_recommended
        ),
        updated_at=now()
    where id=v_recovery.id
    returning * into v_recovery;

    if v_reval_recommended then
      insert into private.exam_prep_progress_revalidation_cases(
        recovery_case_id,user_id,program_version_id,component_code,status,
        prior_stage,prior_coverage_pct,prior_l2_count,prior_l3_count,
        selected_skill_count,passed_skill_count,failed_skill_count,notice_required,
        academic_state_mutation_allowed,reason
      ) values(
        v_recovery.id,v_uid,v_recovery.program_version_id,v_component,'recommended',
        coalesce(v_recovery.stage_snapshot,0),coalesce(v_recovery.coverage_snapshot,0),
        coalesce(v_l2,0),coalesce(v_l3,0),0,0,0,true,false,
        case when v_days>=31 then 'long_break_progress_confirmation' else 'extended_break_progress_confirmation' end
      )
      on conflict(recovery_case_id) do update set
        prior_stage=excluded.prior_stage,prior_coverage_pct=excluded.prior_coverage_pct,
        prior_l2_count=excluded.prior_l2_count,prior_l3_count=excluded.prior_l3_count,
        notice_required=true,updated_at=now()
      returning id into v_reval_id;

      if not exists(select 1 from private.exam_prep_progress_revalidation_items where case_id=v_reval_id) then
        insert into private.exam_prep_progress_revalidation_items(case_id,item_order,skill_code,prior_level)
        select v_reval_id,row_number() over(order by q.key_skill desc,q.objective_level desc,q.source_evidence_through nulls first,q.skill_code)::smallint,
               q.skill_code,q.objective_level
        from (
          select s.skill_code,s.objective_level,s.source_evidence_through,
                 exists(
                   select 1 from private.exam_prep_stage3_key_skills k
                   where k.program_version_id=s.program_version_id
                     and k.component_code=s.component_code and k.skill_code=s.skill_code
                 ) as key_skill
          from private.exam_prep_skill_states s
          where s.user_id=v_uid and s.program_version_id=v_recovery.program_version_id
            and s.component_code=v_component and s.engine_version=v_engine and s.objective_level>=2
            and exists(
              select 1
              from private.exam_prep_assessments a
              join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
              where a.component_code=v_component and a.assessment_type='retest' and a.status='published'
                and ai.primary_skill_code=s.skill_code
            )
          order by key_skill desc,s.objective_level desc,s.source_evidence_through nulls first,s.skill_code
          limit 3
        ) q;
      end if;

      select count(*)::int into v_selected
      from private.exam_prep_progress_revalidation_items where case_id=v_reval_id;
      update private.exam_prep_progress_revalidation_cases
        set selected_skill_count=v_selected::smallint,updated_at=now()
      where id=v_reval_id;
    end if;

    v_cases:=v_cases || jsonb_build_array(jsonb_build_object(
      'component_code',v_component,
      'recovery_mode',v_recovery.recovery_mode,
      'missed_days',v_recovery.missed_days,
      'progress_retained',true,
      'prior_stage',coalesce(v_recovery.stage_snapshot,0),
      'prior_coverage_pct',coalesce(v_recovery.coverage_snapshot,0),
      'revalidation_recommended',v_reval_recommended,
      'revalidation_required_for_readiness',v_readiness_reval,
      'revalidation_case_id',v_reval_id
    ));
    v_reval_id:=null;
  end loop;

  return jsonb_build_object(
    'missed_days',v_days,
    'interruption_kind',p_interruption_kind,
    'recovery_mode',v_base->>'recovery_mode',
    'day_band',v_policy->>'day_band',
    'progress_retained',true,
    'automatic_stage_change',false,
    'components',v_cases,
    'p1_p5_separate',true
  );
end;
$$;
revoke execute on function public.record_my_exam_prep_interruption_v2(date,date,text) from public,anon;
grant execute on function public.record_my_exam_prep_interruption_v2(date,date,text) to authenticated,service_role;

-- 6) Learner-safe recovery read with retained-progress and revalidation status.
create or replace function public.get_exam_prep_recovery_safe_v2(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_case private.exam_prep_recovery_cases%rowtype;
  v_reval private.exam_prep_progress_revalidation_cases%rowtype;
  v_items jsonb:='[]'::jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select * into v_case
  from private.exam_prep_recovery_cases
  where user_id=v_uid and component_code=p_component_code and status='active'
  order by created_at desc limit 1;

  if v_case.id is null then
    return jsonb_build_object(
      'component_code',p_component_code,'active',false,'recovery_mode','normal',
      'progress_retained',true,'revalidation',jsonb_build_object('available',false),
      'evidence_standards_unchanged',true,'stage_changed_by_recovery',false
    );
  end if;

  select * into v_reval
  from private.exam_prep_progress_revalidation_cases
  where recovery_case_id=v_case.id and user_id=v_uid and component_code=p_component_code
  order by created_at desc limit 1;

  if v_reval.id is not null then
    select coalesce(jsonb_agg(jsonb_build_object(
      'item_order',i.item_order,
      'prior_level',i.prior_level,
      'status',i.status,
      'passed',i.passed
    ) order by i.item_order),'[]'::jsonb)
    into v_items
    from private.exam_prep_progress_revalidation_items i
    where i.case_id=v_reval.id;
  end if;

  return jsonb_build_object(
    'component_code',v_case.component_code,
    'active',true,
    'interruption_kind',v_case.interruption_kind,
    'missed_days',v_case.missed_days,
    'recovery_mode',v_case.recovery_mode,
    'source_gap',v_case.source_gap,
    'plan_review_required',v_case.plan_review_required,
    'feasibility_review_required',v_case.feasibility_review_required,
    'recovery_window_started_on',v_case.recovery_window_started_on,
    'recovery_window_ends_on',v_case.recovery_window_ends_on,
    'stage_snapshot',v_case.stage_snapshot,
    'coverage_snapshot',v_case.coverage_snapshot,
    'progress_retained',v_case.progress_retained,
    'revalidation_recommended',v_case.revalidation_recommended,
    'revalidation_required_for_readiness',v_case.revalidation_required_for_readiness,
    'allocation_policy',v_case.allocation_policy,
    'revalidation',case when v_reval.id is null then jsonb_build_object('available',false) else jsonb_build_object(
      'available',true,
      'case_id',v_reval.id,
      'status',v_reval.status,
      'prior_stage',v_reval.prior_stage,
      'prior_coverage_pct',v_reval.prior_coverage_pct,
      'selected_skill_count',v_reval.selected_skill_count,
      'passed_skill_count',v_reval.passed_skill_count,
      'failed_skill_count',v_reval.failed_skill_count,
      'notice_required',v_reval.notice_required,
      'academic_state_mutation_allowed',false,
      'items',v_items
    ) end,
    'evidence_standards_unchanged',true,
    'stage_changed_by_recovery',false,
    'p1_p5_separate',true
  );
end;
$$;
revoke execute on function public.get_exam_prep_recovery_safe_v2(text) from public,anon;
grant execute on function public.get_exam_prep_recovery_safe_v2(text) to authenticated,service_role;

-- 7) Non-crediting revalidation authorizer. It reuses the governed RETEST reserve for the same skill,
-- but academic_credit=false ensures the check can confirm confidence without silently changing mastery.
create or replace function public.authorize_exam_prep_revalidation_item_safe_v1(
  p_case_id uuid,
  p_item_order integer
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_case private.exam_prep_progress_revalidation_cases%rowtype;
  v_item private.exam_prep_progress_revalidation_items%rowtype;
  v_ass bigint;
  v_auth private.exam_prep_session_authorizations%rowtype;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_case_id is null then raise exception 'exam_prep_revalidation_case_required'; end if;
  if p_item_order is null or p_item_order not between 1 and 3 then raise exception 'exam_prep_bad_revalidation_item'; end if;

  select * into v_case
  from private.exam_prep_progress_revalidation_cases
  where id=p_case_id and user_id=v_uid and status in ('recommended','in_progress','refresh_recommended');
  if v_case.id is null then raise exception 'exam_prep_revalidation_case_not_available' using errcode='P0002'; end if;

  select * into v_item
  from private.exam_prep_progress_revalidation_items
  where case_id=v_case.id and item_order=p_item_order::smallint;
  if v_item.case_id is null then raise exception 'exam_prep_revalidation_item_not_found' using errcode='P0002'; end if;

  if v_item.status='authorized' and v_item.authorization_id is not null then
    select * into v_auth from private.exam_prep_session_authorizations where id=v_item.authorization_id;
    if v_auth.id is not null and v_auth.status in ('issued','consumed') then
      return jsonb_build_object(
        'authorization_id',v_auth.id,'case_id',v_case.id,'item_order',v_item.item_order,
        'component_code',v_case.component_code,'academic_credit',false,'resumed',true
      );
    end if;
  end if;

  select a.id into v_ass
  from private.exam_prep_assessments a
  where a.component_code=v_case.component_code and a.assessment_type='retest' and a.status='published'
    and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=v_item.skill_code)
    and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>v_item.skill_code)
  order by a.id limit 1;
  if v_ass is null then raise exception 'exam_prep_revalidation_content_not_ready'; end if;

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit,credit_context
  ) values(
    v_uid,v_ass,v_case.component_code,'retest','issued',now()+interval '1 hour',
    'Non-crediting progress revalidation after study interruption',false,'progress_revalidation'
  ) returning * into v_auth;

  update private.exam_prep_progress_revalidation_items
    set status='authorized',authorization_id=v_auth.id,session_id=null,passed=null,completed_at=null
  where case_id=v_case.id and item_order=v_item.item_order;
  update private.exam_prep_progress_revalidation_cases
    set status='in_progress',updated_at=now(),completed_at=null
  where id=v_case.id;

  return jsonb_build_object(
    'authorization_id',v_auth.id,'case_id',v_case.id,'item_order',v_item.item_order,
    'component_code',v_case.component_code,'academic_credit',false,'resumed',false
  );
end;
$$;
revoke execute on function public.authorize_exam_prep_revalidation_item_safe_v1(uuid,integer) from public,anon;
grant execute on function public.authorize_exam_prep_revalidation_item_safe_v1(uuid,integer) to authenticated,service_role;

-- Revalidation finalization only updates revalidation metadata. It cannot alter mastery/stage/evidence facts.
create or replace function private.exam_prep_revalidation_finalize_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_item private.exam_prep_progress_revalidation_items%rowtype;
  v_passed boolean;
  v_total int;
  v_done int;
  v_pass int;
  v_fail int;
begin
  if old.status is not distinct from new.status or new.status<>'finalized' then return new; end if;

  select * into v_item
  from private.exam_prep_progress_revalidation_items
  where authorization_id=new.authorization_id;
  if v_item.case_id is null then return new; end if;

  select coalesce(bool_and(r.is_correct),false)
    into v_passed
  from private.exam_prep_responses r
  where r.session_id=new.id and r.user_id=new.user_id and r.response_kind='machine';

  update private.exam_prep_progress_revalidation_items
    set status='completed',session_id=new.id,passed=v_passed,completed_at=now()
  where case_id=v_item.case_id and item_order=v_item.item_order;

  select count(*)::int,
         count(*) filter(where status='completed')::int,
         count(*) filter(where status='completed' and passed is true)::int,
         count(*) filter(where status='completed' and passed is false)::int
    into v_total,v_done,v_pass,v_fail
  from private.exam_prep_progress_revalidation_items
  where case_id=v_item.case_id;

  update private.exam_prep_progress_revalidation_cases
  set passed_skill_count=coalesce(v_pass,0)::smallint,
      failed_skill_count=coalesce(v_fail,0)::smallint,
      status=case when v_done=v_total and v_total>0 then case when v_fail=0 then 'confirmed' else 'refresh_recommended' end else 'in_progress' end,
      completed_at=case when v_done=v_total and v_total>0 then now() else null end,
      updated_at=now()
  where id=v_item.case_id;

  return new;
end;
$$;
revoke all on function private.exam_prep_revalidation_finalize_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_revalidation_finalize_v1 on private.exam_prep_sessions;
create trigger exam_prep_revalidation_finalize_v1
after update of status on private.exam_prep_sessions
for each row execute function private.exam_prep_revalidation_finalize_v1();

-- 8) Recovery-aware plan wrapper: failed revalidation becomes targeted refresh, but corrections/retests stay higher priority.
create or replace function public.generate_exam_prep_weekly_plan_safe_v3(p_component_code text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_base jsonb;
  v_plan uuid;
  v_case private.exam_prep_progress_revalidation_cases%rowtype;
  v_failed record;
  v_replace smallint;
  v_count int;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  v_base:=public.generate_exam_prep_weekly_plan_safe_v2(p_component_code);
  v_plan:=(v_base->>'plan_id')::uuid;

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
      exit when exists(
        select 1 from private.exam_prep_weekly_plan_items x
        where x.plan_id=v_plan and x.skill_code=v_failed.skill_code
          and x.item_type in ('retest','correction')
      );

      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;
      select max(priority_order)::smallint into v_replace
      from private.exam_prep_weekly_plan_items
      where plan_id=v_plan and item_type='learning';

      if v_replace is not null then
        delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
      elsif v_count<3 then
        v_replace:=(v_count+1)::smallint;
      else
        continue;
      end if;

      insert into private.exam_prep_weekly_plan_items(
        plan_id,priority_order,item_type,skill_code,action_code,action_payload
      ) values(
        v_plan,v_replace,'learning',v_failed.skill_code,'RECOVERY_REFRESH_RETAINED_SKILL',
        jsonb_build_object('progress_retained',true,'revalidation_failed',true,'academic_stage_unchanged',true)
      );
    end loop;
  end if;

  return v_base || jsonb_build_object(
    'progress_retained',true,
    'revalidation_refresh_applied',(v_case.id is not null),
    'academic_stage_changed_by_recovery',false
  );
end;
$$;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) to authenticated,service_role;

-- 9) Hard release guards: current beta boundary and legacy data remain untouched.
do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_approved int;
begin
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'controlled_beta' or not v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or v_cfg.kill_switch then
    raise exception 'P2-08 release: Core-only controlled-beta boundary drift';
  end if;
  select count(*) into v_approved from private.exam_prep_stage5_thresholds where status='approved';
  if v_approved<>0 then raise exception 'P2-08 release must not approve Stage-5 thresholds'; end if;
  if exists(
    select 1 from information_schema.role_table_grants
    where table_schema='private'
      and table_name in ('exam_prep_progress_revalidation_cases','exam_prep_progress_revalidation_items')
      and grantee in ('anon','authenticated')
  ) then raise exception 'P2-08 revalidation private tables exposed'; end if;
end $$;

commit;
