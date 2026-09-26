-- P2 results/focus UX: finalized-session review, recent result history, bounded learner focus,
-- and a conservative new-week balance rule. Additive/read-model first; no response/evidence/history rewrites.
begin;
set local lock_timeout = '3s';
set local statement_timeout = '90s';

do $preflight$
begin
  if to_regprocedure('public.get_exam_prep_session_safe_v1(uuid,text)') is null
     or to_regprocedure('private.exam_prep_mcq_display_letter_v1(text,smallint[])') is null
     or to_regprocedure('private.exam_prep_written_understanding_feedback_v1(uuid,text)') is null
     or to_regprocedure('private.exam_prep_correction_queue_payload_v1(uuid,text)') is null
     or to_regprocedure('public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)') is null
  then
    raise exception 'results_focus_v1 prerequisite missing';
  end if;
  if md5(pg_get_functiondef('private.exam_prep_correction_queue_payload_v1(uuid,text)'::regprocedure))
       <> 'a0d2312869172b4199b15d5b2b70aae6'
     or md5(pg_get_functiondef('public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)'::regprocedure))
       <> '0304cbab6a544a1123a15eb61af4ab8d'
  then
    raise exception 'results_focus_v1 current production function drift; refuse install';
  end if;
end
$preflight$;

create or replace function public.get_exam_prep_session_review_safe_v1(
  p_session_id uuid,
  p_language text default 'en'
) returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $fn$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_lang text;
  v_items jsonb;
  v_machine_total integer;
  v_machine_correct integer;
  v_written_total integer;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  v_lang:=lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;

  select * into v_s
  from private.exam_prep_sessions
  where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  if v_s.status<>'finalized' or v_s.finalized_at is null then
    raise exception 'exam_prep_review_available_after_completion' using errcode='42501';
  end if;

  select
    count(*) filter(where r.response_kind='machine')::integer,
    count(*) filter(where r.response_kind='machine' and r.is_correct is true)::integer,
    count(*) filter(where r.response_kind='written')::integer
  into v_machine_total,v_machine_correct,v_written_total
  from private.exam_prep_responses r
  where r.session_id=v_s.id and r.user_id=v_uid;

  select coalesce(jsonb_agg(item_payload order by item_order),'[]'::jsonb)
  into v_items
  from (
    select si.item_order,
      jsonb_strip_nulls(jsonb_build_object(
        'item_order',si.item_order,
        'item_kind',si.item_kind,
        'skill_code',si.primary_skill_code,
        'qtype',case when si.item_kind='question' then q.qtype else null end,
        'text',case
          when si.item_kind='question' then
            case v_lang when 'ru' then q.question_text_ru when 'uz' then q.question_text_uz else q.question_text_en end
          else
            case v_lang when 'ru' then wt.prompt_ru when 'uz' then wt.prompt_uz else wt.prompt_en end
        end,
        'options',case
          when si.item_kind='question' and lower(coalesce(q.qtype,''))='mcq'
          then private.exam_prep_mcq_display_options_v1(
            coalesce(nullif(case v_lang when 'ru' then q.options_text_ru when 'uz' then q.options_text_uz else q.options_text_en end,''),'[]')::jsonb,
            si.display_to_source
          )
          else null
        end,
        'selected_answer',case
          when si.item_kind='question' and lower(coalesce(q.qtype,''))='mcq'
            then private.exam_prep_mcq_display_letter_v1(r.selected_answer,si.display_to_source)
          when si.item_kind='question' then r.selected_answer
          else null
        end,
        'correct_answer',case
          when si.item_kind='question' and lower(coalesce(q.qtype,''))='mcq'
            then private.exam_prep_mcq_display_letter_v1(upper(trim(q.correct_answer)),si.display_to_source)
          when si.item_kind='question' then q.correct_answer
          else null
        end,
        'is_correct',case when r.response_kind='machine' then r.is_correct else null end,
        'verification_status',case
          when r.response_kind='machine' then 'app_verified'
          when r.response_kind='written' then coalesce(ev.verification_status,'self_reviewed')
          else null
        end,
        'explanation',case
          when si.item_kind='question' then
            case v_lang when 'ru' then q.explanation_ru when 'uz' then q.explanation_uz else q.explanation_en end
          else null
        end,
        'diagnostic_feedback',dr.feedback,
        'next_action',dr.next_action,
        'learner_artifact',case when si.item_kind='written' then r.learner_artifact else null end,
        'written_self_review',case
          when si.item_kind='written' then
            case v_lang when 'ru' then wt.self_review_ru when 'uz' then wt.self_review_uz else wt.self_review_en end
          else null
        end,
        'written_rubric',case when si.item_kind='written' then wt.rubric_json else null end,
        'understanding_check',case
          when si.item_kind='written' and r.id is not null
            then private.exam_prep_written_understanding_feedback_v1(r.id,v_lang)
          else null
        end
      )) as item_payload
    from private.exam_prep_session_items si
    left join public.questions q on q.id=si.question_id
    left join private.exam_prep_written_tasks wt on wt.id=si.written_task_id
    left join private.exam_prep_responses r
      on r.session_id=si.session_id and r.item_order=si.item_order and r.user_id=v_uid
    left join lateral (
      select e.verification_status
      from private.exam_prep_evidence_events e
      where e.response_id=r.id and e.user_id=v_uid
      order by e.created_at desc
      limit 1
    ) ev on true
    left join lateral (
      select
        case v_lang when 'ru' then d.feedback_ru when 'uz' then d.feedback_uz else d.feedback_en end as feedback,
        case v_lang when 'ru' then d.next_action_ru when 'uz' then d.next_action_uz else d.next_action_en end as next_action
      from private.exam_prep_diagnostic_rules d
      where si.reserve_role='diagnostic'
        and r.response_kind='machine'
        and r.is_correct is false
        and d.content_meta_id=si.content_meta_id
        and d.status='approved'
        and d.answer_match=r.selected_answer
      order by d.approved_at desc nulls last,d.id desc
      limit 1
    ) dr on true
    where si.session_id=v_s.id
  ) review_rows;

  return jsonb_build_object(
    'session_id',v_s.id,
    'component_code',v_s.component_code,
    'session_type',v_s.session_type,
    'status',v_s.status,
    'finalized_at',v_s.finalized_at,
    'summary',jsonb_build_object(
      'machine_total',coalesce(v_machine_total,0),
      'machine_correct',coalesce(v_machine_correct,0),
      'machine_incorrect',greatest(coalesce(v_machine_total,0)-coalesce(v_machine_correct,0),0),
      'machine_accuracy_pct',case when coalesce(v_machine_total,0)>0
        then round((100.0*v_machine_correct/v_machine_total)::numeric,1) else null end,
      'written_total',coalesce(v_written_total,0),
      'written_completed',coalesce(v_written_total,0)
    ),
    'items',v_items
  );
end
$fn$;
revoke all on function public.get_exam_prep_session_review_safe_v1(uuid,text) from public,anon;
grant execute on function public.get_exam_prep_session_review_safe_v1(uuid,text) to authenticated,service_role;

create or replace function public.get_exam_prep_recent_results_safe_v1(
  p_component_code text,
  p_limit integer default 10
) returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $fn$
declare
  v_uid uuid;
  v_limit integer;
  v_rows jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  v_limit:=least(20,greatest(1,coalesce(p_limit,10)));

  with summarized as (
    select s.id as session_id,s.component_code,s.session_type,s.finalized_at,
      count(r.id) filter(where r.response_kind='machine')::integer as machine_total,
      count(r.id) filter(where r.response_kind='machine' and r.is_correct is true)::integer as machine_correct,
      count(r.id) filter(where r.response_kind='written')::integer as written_total
    from private.exam_prep_sessions s
    left join private.exam_prep_responses r
      on r.session_id=s.id and r.user_id=v_uid
    where s.user_id=v_uid
      and s.component_code=p_component_code
      and s.status='finalized'
      and s.finalized_at is not null
      and s.session_type not in ('timed','paper')
    group by s.id,s.component_code,s.session_type,s.finalized_at
    order by s.finalized_at desc,s.id desc
    limit v_limit
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'session_id',session_id,
    'component_code',component_code,
    'session_type',session_type,
    'finalized_at',finalized_at,
    'machine_total',machine_total,
    'machine_correct',machine_correct,
    'machine_accuracy_pct',case when machine_total>0 then round((100.0*machine_correct/machine_total)::numeric,1) else null end,
    'written_total',written_total,
    'written_completed',written_total
  ) order by finalized_at desc,session_id desc),'[]'::jsonb)
  into v_rows
  from summarized;

  return jsonb_build_object('component_code',p_component_code,'results',v_rows);
end
$fn$;
revoke all on function public.get_exam_prep_recent_results_safe_v1(text,integer) from public,anon;
grant execute on function public.get_exam_prep_recent_results_safe_v1(text,integer) to authenticated,service_role;

create or replace function private.exam_prep_correction_queue_payload_v1(p_user_id uuid, p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $fn$
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
      (select count(*)::integer
       from private.exam_prep_prerequisite_edges pe
       where pe.program_version_id=v_program
         and pe.from_node_code=c.skill_code
         and pe.target_component_code=p_component_code) as downstream_dependency_count,
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
      order by a.created_at desc,private.exam_prep_correction_action_rank_v1(a.action_type) desc,a.id desc limit 1
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
      case
        when status='retest_due' and retest_due_at is not null and retest_due_at<=now() then 'retest_due'
        when status in ('reopened','remediating') then 'repeated_gap'
        when downstream_dependency_count>0 then 'foundation_dependency'
        else 'needs_attention'
      end as focus_reason,
      (status in ('open','remediating','reopened') and correction_content_ready) as can_start_correction,
      (status='retest_due' and retest_status='scheduled' and retest_due_at is not null and retest_due_at<=now() and retest_content_ready) as can_start_retest
    from active_cases
  ), ranked as (
    select n.*,
      row_number() over(order by
        case when status='retest_due' and retest_due_at is not null and retest_due_at<=now() then 0
             when status='reopened' then 1
             when status='remediating' then 2
             when status='open' then 3
             when status='retest_due' then 4 else 9 end,
        case when status in ('reopened','remediating') then updated_at end desc nulls last,
        downstream_dependency_count desc,
        sequence_no,opened_at,skill_code
      ) as focus_rank
    from normalized n
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
    'active_count',(select count(*) from ranked),
    'focus_limit',5,
    'focus_count',least((select count(*) from ranked),5),
    'deferred_count',greatest((select count(*) from ranked)-5,0),
    'retest_due_count',(select count(*) from ranked where status='retest_due'),
    'focus_cases',coalesce((select jsonb_agg(jsonb_build_object(
      'correction_case_id',id,'skill_code',skill_code,
      'official_syllabus_section',official_syllabus_section,'description',canonical_description,
      'status',status,'origin',origin,'process_step',process_step,'focus_reason',focus_reason,
      'downstream_dependency_count',downstream_dependency_count,
      'opened_at',opened_at,'updated_at',updated_at,
      'retest_event_id',retest_event_id,'retest_status',retest_status,'retest_due_at',retest_due_at,
      'latest_action_type',latest_action_type,'latest_action_at',latest_action_at,
      'correction_content_ready',correction_content_ready,'retest_content_ready',retest_content_ready,
      'can_start_correction',can_start_correction,'can_start_retest',can_start_retest
    ) order by focus_rank) from ranked where focus_rank<=5),'[]'::jsonb),
    'cases',coalesce((select jsonb_agg(jsonb_build_object(
      'correction_case_id',id,'skill_code',skill_code,
      'official_syllabus_section',official_syllabus_section,'description',canonical_description,
      'status',status,'origin',origin,'process_step',process_step,'focus_reason',focus_reason,
      'downstream_dependency_count',downstream_dependency_count,
      'opened_at',opened_at,'updated_at',updated_at,
      'retest_event_id',retest_event_id,'retest_status',retest_status,'retest_due_at',retest_due_at,
      'latest_action_type',latest_action_type,'latest_action_at',latest_action_at,
      'correction_content_ready',correction_content_ready,'retest_content_ready',retest_content_ready,
      'can_start_correction',can_start_correction,'can_start_retest',can_start_retest
    ) order by focus_rank) from ranked),'[]'::jsonb),
    'recent_resolved',coalesce((select jsonb_agg(jsonb_build_object(
      'correction_case_id',id,'skill_code',skill_code,'official_syllabus_section',official_syllabus_section,
      'description',canonical_description,'opened_at',opened_at,'resolved_at',resolved_at
    ) order by resolved_at desc) from resolved_recent),'[]'::jsonb)
  ) into v_payload;

  return v_payload;
end
$fn$;
revoke all on function private.exam_prep_correction_queue_payload_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_correction_queue_payload_v1(uuid,text) to service_role;

create or replace function private.exam_prep_balance_new_normal_plan_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component_code text,
  p_active_week_no smallint,
  p_plan_id uuid
) returns boolean
language plpgsql
security definer
set search_path=''
as $fn$
declare
  v_plan private.exam_prep_weekly_plans%rowtype;
  v_skill text;
  v_slot smallint;
  v_count integer;
begin
  if p_user_id is null or p_program_version_id is null or p_component_code not in ('P1','P5') or p_plan_id is null then
    return false;
  end if;

  select * into v_plan
  from private.exam_prep_weekly_plans p
  where p.id=p_plan_id and p.user_id=p_user_id and p.program_version_id=p_program_version_id
    and p.component_code=p_component_code and p.active_week_no=p_active_week_no and p.status='active'
  for update;
  if v_plan.id is null or coalesce(v_plan.recovery_mode,'normal')<>'normal' then return false; end if;

  if exists(
    select 1 from private.exam_prep_weekly_plan_items i
    where i.plan_id=p_plan_id and i.item_type='learning' and i.action_code='BUILD_FIRST_COVERAGE'
  ) then return false; end if;

  select s.skill_code into v_skill
  from private.exam_prep_skill_states s
  where s.user_id=p_user_id and s.program_version_id=p_program_version_id
    and s.component_code=p_component_code and s.engine_version='objective_state_v1'
    and s.objective_level<=1
    and private.exam_prep_skill_content_ready_v1(p_program_version_id,p_component_code,s.skill_code)
    and not exists(
      select 1 from private.exam_prep_correction_cases c
      where c.user_id=p_user_id and c.component_code=p_component_code and c.skill_code=s.skill_code
        and c.status in ('open','remediating','retest_due','reopened')
    )
    and not exists(
      select 1 from private.exam_prep_weekly_plan_items i
      where i.plan_id=p_plan_id and i.skill_code=s.skill_code
    )
    and exists(
      select 1
      from private.exam_prep_content_runway_releases rr
      join private.exam_prep_content_runway_release_skills rs
        on rs.release_id=rr.id and rs.required_for_release and rs.skill_code=s.skill_code
      where rr.program_version_id=p_program_version_id
        and rr.component_code=p_component_code
        and rr.schedule_status='active'
        and rr.active_week_from<=p_active_week_no
    )
    and exists(
      select 1
      from private.exam_prep_assessments a
      join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
      where a.component_code=p_component_code and a.assessment_type='learning' and a.status='published'
        and ai.primary_skill_code=s.skill_code
    )
  order by
    s.objective_level,
    (select count(*) from private.exam_prep_prerequisite_edges pe
      where pe.program_version_id=p_program_version_id
        and pe.from_node_code=s.skill_code
        and pe.target_component_code=p_component_code) desc,
    s.skill_code
  limit 1;

  if v_skill is null then return false; end if;

  select count(*)::integer into v_count
  from private.exam_prep_weekly_plan_items i where i.plan_id=p_plan_id;

  if v_count<3 then
    select min(gs)::smallint into v_slot
    from generate_series(1,3) gs
    where not exists(select 1 from private.exam_prep_weekly_plan_items i where i.plan_id=p_plan_id and i.priority_order=gs);
  else
    select max(i.priority_order)::smallint into v_slot
    from private.exam_prep_weekly_plan_items i
    where i.plan_id=p_plan_id and i.item_type='correction';
  end if;

  -- Never remove a due retest merely to make room. If all three priorities are retests,
  -- the evidence cycle is genuinely due and the plan remains unchanged.
  if v_slot is null then return false; end if;

  if exists(select 1 from private.exam_prep_weekly_plan_items i where i.plan_id=p_plan_id and i.priority_order=v_slot) then
    delete from private.exam_prep_weekly_plan_items
    where plan_id=p_plan_id and priority_order=v_slot and item_type='correction';
    if not found then return false; end if;
  end if;

  insert into private.exam_prep_weekly_plan_items(
    plan_id,priority_order,item_type,skill_code,action_code,action_payload
  ) values(
    p_plan_id,v_slot,'learning',v_skill,'BUILD_FIRST_COVERAGE',
    jsonb_build_object('component_code',p_component_code,'balanced_new_learning',true)
  );
  return true;
end
$fn$;
revoke all on function private.exam_prep_balance_new_normal_plan_v1(uuid,bigint,text,smallint,uuid) from public,anon,authenticated,service_role;

create or replace function public.ensure_exam_prep_balanced_weekly_plan_safe_v1(
  p_component_code text
) returns jsonb
language plpgsql
security definer
set search_path=''
as $fn$
declare
  v_uid uuid;
  v_program bigint;
  v_week smallint;
  v_existing_plan uuid;
  v_result jsonb;
  v_current jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select program_version_id into v_program
  from private.exam_prep_exam_profiles
  where user_id=v_uid;
  v_week:=private.exam_prep_effective_active_week_v1(v_uid);
  if v_program is null or v_week is null then raise exception 'exam_prep_profile_required'; end if;

  -- Use the same learner/component lock as the released weekly-flow authority.
  perform pg_advisory_xact_lock(hashtextextended('ep-stable-plan:'||v_uid::text||':'||p_component_code,0));

  select p.id into v_existing_plan
  from private.exam_prep_weekly_plans p
  where p.user_id=v_uid
    and p.program_version_id=v_program
    and p.component_code=p_component_code
    and p.active_week_no=v_week
    and p.status='active'
  order by p.created_at desc
  limit 1;

  -- Keep the sealed released function unchanged. It remains the sole creator
  -- of the stable weekly plan and keeps all recovery/concurrency guarantees.
  v_result:=public.ensure_exam_prep_stable_weekly_plan_safe_v1(p_component_code);

  -- Never rewrite an already active plan. Balance only a plan created by this
  -- exact call, before it is exposed to the learner for the first time.
  if v_existing_plan is null
     and v_result->>'status'='created'
     and v_result->>'plan_id' is not null
  then
    perform private.exam_prep_balance_new_normal_plan_v1(
      v_uid,v_program,p_component_code,v_week,(v_result->>'plan_id')::uuid
    );
    v_current:=public.get_exam_prep_weekly_plan_safe_v2(p_component_code);
    if v_current->>'plan_id' is distinct from v_result->>'plan_id' then
      raise exception 'exam_prep_balanced_plan_projection_mismatch';
    end if;
    return v_current || jsonb_build_object(
      'contract_version','stable_weekly_plan_v1',
      'status','created',
      'created',true
    );
  end if;

  return v_result;
end
$fn$;
revoke all on function public.ensure_exam_prep_balanced_weekly_plan_safe_v1(text) from public,anon;
grant execute on function public.ensure_exam_prep_balanced_weekly_plan_safe_v1(text) to authenticated,service_role;

do $postcheck$
begin
  if has_function_privilege('anon','public.get_exam_prep_session_review_safe_v1(uuid,text)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_session_review_safe_v1(uuid,text)','EXECUTE')
     or has_function_privilege('anon','public.get_exam_prep_recent_results_safe_v1(text,integer)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_recent_results_safe_v1(text,integer)','EXECUTE')
     or has_function_privilege('anon','public.ensure_exam_prep_balanced_weekly_plan_safe_v1(text)','EXECUTE')
     or not has_function_privilege('authenticated','public.ensure_exam_prep_balanced_weekly_plan_safe_v1(text)','EXECUTE')
     or md5(pg_get_functiondef('public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)'::regprocedure))
        <> '0304cbab6a544a1123a15eb61af4ab8d'
  then
    raise exception 'results_focus_v1 postcheck failed';
  end if;
end
$postcheck$;

commit;
