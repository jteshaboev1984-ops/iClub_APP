\set ON_ERROR_STOP on
\echo 'P1-03 Stage-3 -> Stage-4 transition candidate v1 rollback matrix'

begin;

create or replace function pg_temp.stage4_transition_trend_candidate_v1(
  p_previous_unattempted_share numeric,
  p_latest_unattempted_share numeric,
  p_previous_after_time_share numeric,
  p_latest_after_time_share numeric
)
returns boolean
language plpgsql
immutable
as $$
begin
  if p_previous_unattempted_share is null
     or p_latest_unattempted_share is null
     or p_previous_after_time_share is null
     or p_latest_after_time_share is null then
    return false;
  end if;
  if p_previous_unattempted_share<0 or p_previous_unattempted_share>1
     or p_latest_unattempted_share<0 or p_latest_unattempted_share>1
     or p_previous_after_time_share<0 or p_previous_after_time_share>1
     or p_latest_after_time_share<0 or p_latest_after_time_share>1 then
    return false;
  end if;
  return p_latest_unattempted_share<=p_previous_unattempted_share
     and p_latest_after_time_share<=p_previous_after_time_share
     and (
       p_latest_unattempted_share<p_previous_unattempted_share
       or p_latest_after_time_share<p_previous_after_time_share
       or (p_latest_unattempted_share=0 and p_latest_after_time_share=0)
     );
end;
$$;

create or replace function pg_temp.stage4_transition_corrective_candidate_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component_code text,
  p_skill_code text
)
returns boolean
language sql
stable
as $$
  select exists(
    select 1
    from private.exam_prep_correction_cases c
    where c.user_id=p_user_id
      and c.component_code=p_component_code
      and c.skill_code=p_skill_code
      and c.status in ('open','remediating','retest_due','reopened')
      and (
        exists(
          select 1
          from private.exam_prep_weekly_plan_items wpi
          join private.exam_prep_weekly_plans wp on wp.id=wpi.plan_id
          where wp.user_id=p_user_id
            and wp.program_version_id=p_program_version_id
            and wp.component_code=p_component_code
            and wp.status='active'
            and wpi.correction_case_id=c.id
            and wpi.skill_code=p_skill_code
            and wpi.item_type in ('correction','retest')
            and wpi.status='pending'
            and wpi.due_at is not null
            and wpi.due_at>=now()
        )
        or exists(
          select 1
          from private.exam_prep_retest_events r
          where r.correction_case_id=c.id
            and r.user_id=p_user_id
            and r.component_code=p_component_code
            and r.skill_code=p_skill_code
            and (
              (r.status='scheduled' and r.due_not_before is not null and r.due_not_before>=now())
              or (r.status='authorized' and r.authorization_id is not null)
            )
        )
      )
  );
$$;

-- Candidate evaluator: reads the deployed raw evidence reader, applies only the
-- rollback-only v1 policy, and explicitly refuses to unlock Stage 4 or Stage 5.
create or replace function pg_temp.stage4_transition_candidate_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component_code text
)
returns jsonb
language plpgsql
stable
as $$
declare
  v_raw jsonb;
  v_stage3_ready boolean:=false;
  v_family jsonb;
  v_max_family int:=0;
  v_trend_ready boolean:=false;
  v_below_l3 int:=0;
  v_corrective_qualified int:=0;
  v_corrective_ready boolean:=false;
  v_reason text;
begin
  v_raw:=private.exam_prep_stage4_raw_evidence_v1(p_user_id,p_program_version_id,p_component_code);
  v_stage3_ready:=coalesce((v_raw->'stage3_exit_status'->>'ready')::boolean,false);
  v_max_family:=coalesce((v_raw->>'max_compatible_family_attempt_count')::int,0);

  select e.value into v_family
  from jsonb_array_elements(v_raw->'comparison_families') as e(value)
  where coalesce((e.value->>'attempt_count')::int,0)>=2
  order by (e.value->>'attempt_count')::int desc,
           (e.value->>'latest_at')::timestamptz desc,
           e.value->>'family_key'
  limit 1;

  if v_family is not null then
    v_trend_ready:=pg_temp.stage4_transition_trend_candidate_v1(
      (v_family->>'previous_unattempted_share')::numeric,
      (v_family->>'latest_unattempted_share')::numeric,
      (v_family->>'previous_after_time_share')::numeric,
      (v_family->>'latest_after_time_share')::numeric
    );
  end if;

  with engine as (
    select engine_version
    from private.exam_prep_state_engine_versions
    where status='active'
    order by created_at desc limit 1
  ), below as (
    select n.skill_code
    from private.exam_prep_syllabus_nodes n
    left join private.exam_prep_skill_states ss
      on ss.user_id=p_user_id
     and ss.program_version_id=p_program_version_id
     and ss.component_code=p_component_code
     and ss.skill_code=n.skill_code
     and ss.engine_version=(select engine_version from engine)
    where n.program_version_id=p_program_version_id
      and n.component_code=p_component_code
      and coalesce(ss.objective_level,0)<3
  )
  select count(*)::int,
         count(*) filter(where pg_temp.stage4_transition_corrective_candidate_v1(
           p_user_id,p_program_version_id,p_component_code,b.skill_code
         ))::int
  into v_below_l3,v_corrective_qualified
  from below b;

  v_corrective_ready:=v_below_l3=0 or v_corrective_qualified=v_below_l3;

  if not v_stage3_ready then
    v_reason:='stage3_exit_incomplete';
  elsif v_max_family<2 then
    v_reason:='comparable_full_attempts_incomplete';
  elsif not v_trend_ready then
    v_reason:='timing_unattempted_trend_incomplete';
  elsif not v_corrective_ready then
    v_reason:='l3_or_corrective_plan_incomplete';
  else
    v_reason:='ready';
  end if;

  return jsonb_build_object(
    'candidate_version','stage4_transition_candidate_v1_2026_09_06',
    'component_code',p_component_code,
    'stage4_entry_eligible',v_stage3_ready,
    'stage4_entry_wired',false,
    'max_compatible_family_attempt_count',v_max_family,
    'trend_policy_status','candidate_v1_test_only',
    'trend_gate_ready',v_trend_ready,
    'below_l3_count',v_below_l3,
    'corrective_plan_qualified_count',v_corrective_qualified,
    'corrective_plan_policy_status','candidate_v1_test_only',
    'corrective_plan_gate_ready',v_corrective_ready,
    'stage4_exit_ready',v_reason='ready',
    'reason_code',v_reason,
    'stage4_unlocked',false,
    'stage5_unlocked',false,
    'raw_evidence',v_raw
  );
end;
$$;

-- Rollback-only helper that creates an immutable, finally reviewed strict P1
-- full-paper attempt through the real published assessment/timing-contract path.
create or replace function pg_temp.insert_stage4_transition_p1_attempt_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_assessment_key text,
  p_expected_form_key text,
  p_finalized_at timestamptz,
  p_skip_orders smallint[],
  p_after_time_lost int,
  p_suffix text
)
returns uuid
language plpgsql
as $$
declare
  v_ass bigint;
  v_cv bigint;
  v_ass_version text;
  v_auth uuid;
  v_session uuid;
  v_items int;
  v_unattempted_items int;
  v_unattempted_marks int;
  v_snapshot_key text;
begin
  select a.id,a.content_version_id,a.assessment_version
  into v_ass,v_cv,v_ass_version
  from private.exam_prep_assessments a
  join private.exam_prep_timed_assessment_contracts tc
    on tc.assessment_id=a.id and tc.status='published'
  where a.assessment_key=p_assessment_key
    and a.assessment_version='av1'
    and a.component_code='P1'
    and a.status='published'
    and tc.attempt_kind='full_paper'
    and tc.timing_rule='official_full'
    and tc.comparison_scope='full'
    and tc.comparability_key=p_expected_form_key;
  if v_ass is null then
    raise exception 'P1-03 Stage-4 transition fixture assessment/contract missing key=%',p_assessment_key;
  end if;

  select count(*)::int into v_items
  from private.exam_prep_assessment_items where assessment_id=v_ass;
  select count(*)::int,coalesce(sum(ti.max_marks),0)::int
  into v_unattempted_items,v_unattempted_marks
  from private.exam_prep_timed_assessment_items ti
  where ti.assessment_id=v_ass and ti.item_order=any(p_skip_orders);

  if p_after_time_lost<0 or p_after_time_lost>75-v_unattempted_marks then
    raise exception 'P1-03 Stage-4 transition fixture invalid after-time marks=% unattempted=%',p_after_time_lost,v_unattempted_marks;
  end if;

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason
  ) values(
    p_user_id,v_ass,'P1','paper','issued',now()+interval '1 hour',
    'P1-03 Stage-4 transition candidate rollback fixture '||p_suffix
  ) returning id into v_auth;

  insert into private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,started_at,last_activity_at,
    finalized_at,finalize_idempotency_key,timing_contract
  ) values(
    v_auth,p_user_id,p_program_version_id,v_cv,v_ass,v_ass_version,
    'P1','paper','finalized','p103-s4transition-session-'||p_suffix,v_items,
    p_finalized_at-interval '100 minutes',p_finalized_at,p_finalized_at,
    'p103-s4transition-final-'||p_suffix,'{}'::jsonb
  ) returning id into v_session;

  select timing_contract->>'comparability_key' into v_snapshot_key
  from private.exam_prep_sessions where id=v_session;
  if v_snapshot_key<>p_expected_form_key then
    raise exception 'P1-03 Stage-4 transition fixture timing snapshot mismatch expected=% got=%',p_expected_form_key,v_snapshot_key;
  end if;

  insert into private.exam_prep_session_items(
    session_id,item_order,item_kind,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout,
    content_meta_id,question_snapshot_md5,item_version
  )
  select v_session,ai.item_order,'written',null,ai.written_task_id,ai.primary_skill_code,ai.reserve_role,ai.is_holdout,
         null,null,'written:'||wt.task_version
  from private.exam_prep_assessment_items ai
  join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
  where ai.assessment_id=v_ass;

  insert into private.exam_prep_timed_attempt_results(
    session_id,user_id,component_code,assessment_id,attempt_kind,timing_rule,comparison_scope,comparability_key,
    strict_timing,marks_available,time_limit_sec,server_elapsed_sec,answered_items,unattempted_items,
    objective_marks_in_time,objective_marks_after_time,objective_lost_in_time_marks,objective_lost_after_time_marks,
    pending_review_in_time_marks,pending_review_after_time_marks,unattempted_marks,completion_reason,
    timing_comparable,base_score_comparable,finalized_at
  ) values(
    v_session,p_user_id,'P1',v_ass,'full_paper','official_full','full',p_expected_form_key,
    true,75,6600,6200,v_items-v_unattempted_items,v_unattempted_items,
    0,0,0,p_after_time_lost,75-v_unattempted_marks-p_after_time_lost,0,v_unattempted_marks,
    'submitted',true,false,p_finalized_at
  );

  insert into private.exam_prep_timed_written_self_marks(
    session_id,item_order,user_id,marks_awarded,max_marks,was_in_time,idempotency_key,review_note
  )
  select v_session,ti.item_order,p_user_id,greatest(ti.max_marks-1,0),ti.max_marks,true,
         'p103-s4transition-self-'||p_suffix||'-'||lpad(ti.item_order::text,2,'0'),
         'Rollback-only Stage-4 transition candidate fixture'
  from private.exam_prep_timed_assessment_items ti
  where ti.assessment_id=v_ass
    and not (ti.item_order=any(p_skip_orders));

  if not private.exam_prep_timed_score_comparable_v1(v_session) then
    raise exception 'P1-03 Stage-4 transition fixture not finally comparable suffix=%',p_suffix;
  end if;

  return v_session;
end;
$$;

-- The release guard deliberately requires a production-named evaluator before
-- Paper02 can be released. This stub is CI-only and is removed by rollback.
create or replace function private.exam_prep_stage4_exit_status_v1(
  p_user_id uuid,p_program_version_id bigint,p_component_code text
)
returns jsonb
language sql
stable
set search_path=''
as $$
  select jsonb_build_object(
    'ready',false,
    'reason_code','p103_stage4_transition_ci_stub',
    'stage4_unlocked',false,
    'stage5_unlocked',false
  );
$$;

do $$
declare
  v_program bigint;
  v_engine text;
  v_rule text;
  v_user uuid := '00000000-0000-4000-8000-000000001056'::uuid;
  v_p2 bigint;
  v_profile bigint;
  v_s1 uuid;
  v_s2 uuid;
  v_s3 uuid;
  v_s4 uuid;
  v_case uuid;
  v_plan uuid;
  v_status jsonb;
  v_feature text;
  v_failed boolean;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select engine_version into v_engine
  from private.exam_prep_state_engine_versions where status='active'
  order by created_at desc limit 1;
  select rule_version into v_rule
  from private.exam_prep_stage3_exit_rules where status='active';
  if v_program is null or v_engine is null or v_rule is null then
    raise exception 'P1-03 Stage-4 transition candidate baseline missing';
  end if;

  -- Production-like baseline is still locked before the rollback fixture begins.
  if (select key_registry_status from private.exam_prep_stage3_exit_rules where rule_version=v_rule)<>'pending'
     or exists(select 1 from private.exam_prep_stage3_key_skills where rule_version=v_rule)
     or (select stage4_policy_status from private.exam_prep_stage4_release_controls where status='active')<>'pending'
     or (select paper02_release_status from private.exam_prep_stage4_release_controls where status='active')<>'pending'
     or (select max_automatic_stage from private.exam_prep_operational_stage_rules where status='active')<>3 then
    raise exception 'P1-03 Stage-4 transition candidate did not start from locked production-like baseline';
  end if;

  -- Use the complete Stage-3 key-skill proposal as a CI fixture only. This is not approval.
  update private.exam_prep_stage3_exit_rules
  set key_registry_status='approved'
  where rule_version=v_rule;

  insert into private.exam_prep_stage3_key_skills(
    rule_version,program_version_id,component_code,skill_code,governance_basis
  ) values
    (v_rule,v_program,'P1','P1-QUA-03','Rollback-only candidate fixture: quadratic method-selection bottleneck.'),
    (v_rule,v_program,'P1','P1-FUN-01','Rollback-only candidate fixture: functions model-selection bottleneck.'),
    (v_rule,v_program,'P1','P1-COO-05','Rollback-only candidate fixture: integrated line-circle transfer.'),
    (v_rule,v_program,'P1','P1-CIR-03','Rollback-only candidate fixture: composite circular-measure modelling.'),
    (v_rule,v_program,'P1','P1-TRI-05','Rollback-only candidate fixture: interval trigonometric equation transfer.'),
    (v_rule,v_program,'P1','P1-SER-02','Rollback-only candidate fixture: sequence model selection.'),
    (v_rule,v_program,'P1','P1-DIF-07','Rollback-only candidate fixture: optimisation/stationary-point reasoning.'),
    (v_rule,v_program,'P1','P1-INT-04','Rollback-only candidate fixture: area/limits/decomposition reasoning.'),
    (v_rule,v_program,'P5','P5-DAT-08','Rollback-only candidate fixture: contextual data comparison.'),
    (v_rule,v_program,'P5','P5-CNT-05','Rollback-only candidate fixture: mixed counting model choice.'),
    (v_rule,v_program,'P5','P5-PRO-05','Rollback-only candidate fixture: conditional probability modelling.'),
    (v_rule,v_program,'P5','P5-DRV-01','Rollback-only candidate fixture: discrete distribution construction.'),
    (v_rule,v_program,'P5','P5-BIN-01','Rollback-only candidate fixture: Binomial model recognition.'),
    (v_rule,v_program,'P5','P5-GEO-01','Rollback-only candidate fixture: Geometric model recognition.'),
    (v_rule,v_program,'P5','P5-NOR-06','Rollback-only candidate fixture: normal approximation transfer.');

  insert into auth.users(id,email,role,aud)
  values(v_user,'p103-stage4-transition@invalid.example','authenticated','authenticated');
  insert into public.users(id,first_name,last_name,language_code)
  values(v_user,'P103','Stage4Transition','en');

  -- Stage 3 permits a non-key L2 skill, but all eight proposed P1 key skills are L3.
  insert into private.exam_prep_skill_states(
    user_id,program_version_id,component_code,skill_code,engine_version,objective_level,coverage_confirmed
  )
  select v_user,v_program,'P1',n.skill_code,v_engine,
         case when n.skill_code='P1-QUA-01' then 2 else 3 end,true
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program and n.component_code='P1';

  v_status:=pg_temp.stage4_transition_candidate_v1(v_user,v_program,'P1');
  if v_status->>'reason_code'<>'stage3_exit_incomplete'
     or (v_status->>'stage4_entry_eligible')::boolean
     or (v_status->>'stage4_exit_ready')::boolean
     or (v_status->>'stage4_unlocked')::boolean then
    raise exception 'P1-03 Stage-4 transition candidate no-baseline state wrong %',v_status::text;
  end if;

  -- First strict comparable full paper completes Stage-3 exit evidence only.
  v_s1:=pg_temp.insert_stage4_transition_p1_attempt_v1(
    v_user,v_program,'p1_stage3_full_paper_01','p1-full-paper-01-v1',
    now()-interval '10 days',array[1,4]::smallint[],0,'01'
  );

  v_status:=pg_temp.stage4_transition_candidate_v1(v_user,v_program,'P1');
  if not (v_status->>'stage4_entry_eligible')::boolean
     or v_status->>'reason_code'<>'comparable_full_attempts_incomplete'
     or (v_status->>'max_compatible_family_attempt_count')::int<>1
     or (v_status->>'stage4_entry_wired')::boolean
     or (v_status->>'stage4_unlocked')::boolean then
    raise exception 'P1-03 Stage-4 transition candidate one-baseline state wrong %',v_status::text;
  end if;

  -- Simulate every release prerequisite inside rollback only so Paper02 can
  -- provide the second comparable form. Production remains pending after rollback.
  update private.exam_prep_stage4_release_controls
  set stage4_policy_status='approved',paper02_release_status='approved',updated_at=now()
  where status='active';

  select id into v_p2
  from private.exam_prep_assessments
  where assessment_key='p1_stage4_full_paper_02' and assessment_version='av1' and status='approved';
  if v_p2 is null then raise exception 'P1-03 Stage-4 transition candidate Paper02 pre-position missing'; end if;

  update private.exam_prep_assessments set status='published' where id=v_p2;

  select id into v_profile
  from private.exam_prep_component_paper_profiles
  where program_version_id=v_program and component_code='P1'
    and profile_version='9709_2026_2027_v1' and status='published';
  if v_profile is null then raise exception 'P1-03 Stage-4 transition candidate P1 profile missing'; end if;

  insert into private.exam_prep_timed_assessment_contracts(
    assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
    strict_timing,comparison_scope,comparability_key,min_operational_stage,status,published_at
  ) values(
    v_p2,v_profile,'tcv1','full_paper','official_full',75,null,
    true,'full','p1-full-paper-02-v1',4,'published',now()
  );

  v_s2:=pg_temp.insert_stage4_transition_p1_attempt_v1(
    v_user,v_program,'p1_stage4_full_paper_02','p1-full-paper-02-v1',
    now()-interval '4 days',array[1]::smallint[],0,'02'
  );

  -- Two compatible forms + improving timing is not enough while one L2 skill
  -- lacks an explicit current corrective action.
  v_status:=pg_temp.stage4_transition_candidate_v1(v_user,v_program,'P1');
  if v_status->>'reason_code'<>'l3_or_corrective_plan_incomplete'
     or not (v_status->>'stage4_entry_eligible')::boolean
     or not (v_status->>'trend_gate_ready')::boolean
     or (v_status->>'below_l3_count')::int<>1
     or (v_status->>'corrective_plan_qualified_count')::int<>0
     or (v_status->>'stage4_exit_ready')::boolean then
    raise exception 'P1-03 Stage-4 transition candidate missing corrective-plan state wrong %',v_status::text;
  end if;

  insert into private.exam_prep_correction_cases(
    user_id,component_code,skill_code,status,engine_version,reason
  ) values(
    v_user,'P1','P1-QUA-01','open',v_engine,'{"source":"rollback_stage4_transition_candidate_v1"}'::jsonb
  ) returning id into v_case;
  insert into private.exam_prep_weekly_plans(
    user_id,program_version_id,component_code,active_week_no,plan_version,status,recovery_mode,policy_note
  ) values(
    v_user,v_program,'P1',25,1,'active','normal','Rollback-only Stage-4 transition candidate plan.'
  ) returning id into v_plan;
  insert into private.exam_prep_weekly_plan_items(
    plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,action_code,action_payload,status
  ) values(
    v_plan,1,'correction','P1-QUA-01',v_case,now()-interval '1 minute',
    'stage4_transition_candidate_correction','{}'::jsonb,'pending'
  );

  -- Stale action still fails.
  v_status:=pg_temp.stage4_transition_candidate_v1(v_user,v_program,'P1');
  if v_status->>'reason_code'<>'l3_or_corrective_plan_incomplete'
     or (v_status->>'corrective_plan_qualified_count')::int<>0 then
    raise exception 'P1-03 Stage-4 transition candidate stale action incorrectly qualified %',v_status::text;
  end if;

  update private.exam_prep_weekly_plan_items
  set due_at=now()+interval '1 day'
  where plan_id=v_plan and priority_order=1;

  -- Candidate policy can now report ready, but it still must not unlock anything.
  v_status:=pg_temp.stage4_transition_candidate_v1(v_user,v_program,'P1');
  if v_status->>'reason_code'<>'ready'
     or not (v_status->>'stage4_exit_ready')::boolean
     or not (v_status->>'corrective_plan_gate_ready')::boolean
     or (v_status->>'corrective_plan_qualified_count')::int<>1
     or (v_status->>'stage4_entry_wired')::boolean
     or (v_status->>'stage4_unlocked')::boolean
     or (v_status->>'stage5_unlocked')::boolean then
    raise exception 'P1-03 Stage-4 transition candidate ready-but-locked state wrong %',v_status::text;
  end if;

  -- Completed timed facts are immutable. A bad trend must be represented by a
  -- new attempt, never by editing history.
  v_failed:=false;
  begin
    update private.exam_prep_timed_attempt_results
    set objective_lost_after_time_marks=1
    where session_id=v_s2;
  exception when others then
    if position('immutable_exam_prep_fact' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then
    raise exception 'P1-03 Stage-4 transition candidate allowed completed attempt mutation';
  end if;

  -- New attempt: unattempted share does not worsen, but after-time loss does.
  -- The timing gate must fail even though the corrective plan remains valid.
  v_s3:=pg_temp.insert_stage4_transition_p1_attempt_v1(
    v_user,v_program,'p1_stage4_full_paper_02','p1-full-paper-02-v1',
    now()-interval '2 days',array[1]::smallint[],3,'03'
  );

  v_status:=pg_temp.stage4_transition_candidate_v1(v_user,v_program,'P1');
  if v_status->>'reason_code'<>'timing_unattempted_trend_incomplete'
     or (v_status->>'trend_gate_ready')::boolean
     or not (v_status->>'corrective_plan_gate_ready')::boolean
     or (v_status->>'stage4_exit_ready')::boolean then
    raise exception 'P1-03 Stage-4 transition candidate worsening timing was bypassed %',v_status::text;
  end if;

  -- Recovery must also be proven by a new attempt. The latest attempt improves
  -- both unattempted and after-time shares relative to the bad attempt.
  v_s4:=pg_temp.insert_stage4_transition_p1_attempt_v1(
    v_user,v_program,'p1_stage4_full_paper_02','p1-full-paper-02-v1',
    now()-interval '1 day',array[]::smallint[],0,'04'
  );

  v_status:=pg_temp.stage4_transition_candidate_v1(v_user,v_program,'P1');
  if v_status->>'reason_code'<>'ready'
     or not (v_status->>'trend_gate_ready')::boolean
     or not (v_status->>'stage4_exit_ready')::boolean
     or (v_status->>'stage4_unlocked')::boolean then
    raise exception 'P1-03 Stage-4 transition candidate did not recover through new evidence %',v_status::text;
  end if;

  -- P1 evidence and plans never satisfy P5.
  v_status:=pg_temp.stage4_transition_candidate_v1(v_user,v_program,'P5');
  if v_status->>'reason_code'<>'stage3_exit_incomplete'
     or (v_status->>'stage4_entry_eligible')::boolean
     or (v_status->>'max_compatible_family_attempt_count')::int<>0
     or (v_status->>'stage4_exit_ready')::boolean then
    raise exception 'P1-03 Stage-4 transition candidate component firewall failed %',v_status::text;
  end if;

  select rollout_state||'|'||core_enabled||'|'||ai_enabled||'|'||mentor_enabled||'|'||kill_switch
  into v_feature from private.exam_prep_feature_config where id=1;
  if v_feature<>'off|false|false|false|true' then
    raise exception 'P1-03 Stage-4 transition candidate feature state changed %',v_feature;
  end if;
  if exists(select 1 from private.exam_prep_feature_entitlements where entitlement_status='active') then
    raise exception 'P1-03 Stage-4 transition candidate activated an entitlement';
  end if;
  if (select max_automatic_stage from private.exam_prep_operational_stage_rules where status='active')<>3 then
    raise exception 'P1-03 Stage-4 transition candidate moved automatic stage ceiling';
  end if;

  raise notice 'P1-03 Stage-3 -> Stage-4 transition candidate v1 rollback matrix: GREEN';
end $$;

rollback;

-- Verify every simulated approval, learner and Paper02 release disappeared.
do $$
declare
  v_p2 bigint;
  v_user uuid := '00000000-0000-4000-8000-000000001056'::uuid;
begin
  if (select key_registry_status from private.exam_prep_stage3_exit_rules where status='active')<>'pending'
     or exists(select 1 from private.exam_prep_stage3_key_skills) then
    raise exception 'P1-03 Stage-4 transition candidate rollback left key governance residue';
  end if;
  if (select stage4_policy_status from private.exam_prep_stage4_release_controls where status='active')<>'pending'
     or (select paper02_release_status from private.exam_prep_stage4_release_controls where status='active')<>'pending' then
    raise exception 'P1-03 Stage-4 transition candidate rollback left release approval';
  end if;
  if to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is not null then
    raise exception 'P1-03 Stage-4 transition candidate rollback left CI-only evaluator';
  end if;
  select id into v_p2
  from private.exam_prep_assessments
  where assessment_key='p1_stage4_full_paper_02' and assessment_version='av1' and status='approved';
  if v_p2 is null then raise exception 'P1-03 Stage-4 transition candidate rollback did not restore Paper02'; end if;
  if exists(select 1 from private.exam_prep_timed_assessment_contracts where assessment_id=v_p2) then
    raise exception 'P1-03 Stage-4 transition candidate rollback left Paper02 contract';
  end if;
  if exists(select 1 from public.users where id=v_user)
     or exists(select 1 from private.exam_prep_sessions where user_id=v_user)
     or exists(select 1 from private.exam_prep_timed_attempt_results where user_id=v_user) then
    raise exception 'P1-03 Stage-4 transition candidate rollback left learner/runtime residue';
  end if;
end $$;

\echo 'P1-03 Stage-3 -> Stage-4 transition candidate v1 rollback matrix: GREEN'