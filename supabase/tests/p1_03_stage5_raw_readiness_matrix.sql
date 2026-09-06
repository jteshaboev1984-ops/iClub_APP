\set ON_ERROR_STOP on
\echo 'P1-03 Stage-5 raw Exam Readiness reader matrix'

begin;

-- CI-only Stage-4 dependency stub. The production Stage-4 evaluator remains absent;
-- this lets the raw Stage-5 reader prove its own evidence collection without wiring progression.
create or replace function private.exam_prep_stage4_exit_status_v1(
  p_user_id uuid,p_program_version_id bigint,p_component_code text
)
returns jsonb
language sql
stable
set search_path=''
as $$
  select jsonb_build_object(
    'ready',true,
    'reason_code','p103_stage5_raw_ci_stage4_ready',
    'stage4_unlocked',false,
    'stage5_unlocked',false
  );
$$;

create or replace function pg_temp.insert_stage5_p1_attempt_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_finalized_at timestamptz,
  p_skip_orders smallint[],
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
  v_form text;
begin
  select a.id,a.content_version_id,a.assessment_version,tc.comparability_key
  into v_ass,v_cv,v_ass_version,v_form
  from private.exam_prep_assessments a
  join private.exam_prep_timed_assessment_contracts tc
    on tc.assessment_id=a.id and tc.status='published'
  where a.assessment_key='p1_stage3_full_paper_01'
    and a.assessment_version='av1'
    and a.component_code='P1'
    and a.status='published'
    and tc.attempt_kind='full_paper'
    and tc.timing_rule='official_full'
    and tc.comparison_scope='full'
    and tc.strict_timing;
  if v_ass is null then raise exception 'P1-03 Stage-5 raw matrix P1 full paper missing'; end if;

  select count(*)::int into v_items
  from private.exam_prep_assessment_items where assessment_id=v_ass;
  select count(*)::int,coalesce(sum(ti.max_marks),0)::int
  into v_unattempted_items,v_unattempted_marks
  from private.exam_prep_timed_assessment_items ti
  where ti.assessment_id=v_ass and ti.item_order=any(p_skip_orders);

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason
  ) values(
    p_user_id,v_ass,'P1','paper','issued',now()+interval '1 hour',
    'P1-03 Stage-5 raw reader rollback fixture '||p_suffix
  ) returning id into v_auth;

  insert into private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,started_at,last_activity_at,
    finalized_at,finalize_idempotency_key,timing_contract
  ) values(
    v_auth,p_user_id,p_program_version_id,v_cv,v_ass,v_ass_version,
    'P1','paper','finalized','p103-s5raw-session-'||p_suffix,v_items,
    p_finalized_at-interval '100 minutes',p_finalized_at,p_finalized_at,
    'p103-s5raw-final-'||p_suffix,'{}'::jsonb
  ) returning id into v_session;

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
    v_session,p_user_id,'P1',v_ass,'full_paper','official_full','full',v_form,
    true,75,6600,6200,v_items-v_unattempted_items,v_unattempted_items,
    0,0,0,0,75-v_unattempted_marks,0,v_unattempted_marks,'submitted',true,false,p_finalized_at
  );

  insert into private.exam_prep_timed_written_self_marks(
    session_id,item_order,user_id,marks_awarded,max_marks,was_in_time,idempotency_key,review_note
  )
  select v_session,ti.item_order,p_user_id,greatest(ti.max_marks-1,0),ti.max_marks,true,
         'p103-s5raw-self-'||p_suffix||'-'||lpad(ti.item_order::text,2,'0'),
         'Rollback-only Stage-5 raw reader fixture'
  from private.exam_prep_timed_assessment_items ti
  where ti.assessment_id=v_ass
    and not (ti.item_order=any(p_skip_orders));

  if not private.exam_prep_timed_score_comparable_v1(v_session) then
    raise exception 'P1-03 Stage-5 raw fixture not finally comparable suffix=%',p_suffix;
  end if;

  return v_session;
end;
$$;

do $$
declare
  v_program bigint;
  v_engine text;
  v_user uuid := '00000000-0000-4000-8000-000000001057'::uuid;
  v_status jsonb;
  v_case uuid;
  v_first numeric;
  v_second numeric;
  v_third numeric;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select engine_version into v_engine
  from private.exam_prep_state_engine_versions where status='active'
  order by created_at desc limit 1;
  if v_program is null or v_engine is null then raise exception 'P1-03 Stage-5 raw matrix baseline missing'; end if;

  insert into auth.users(id,email,role,aud)
  values(v_user,'p103-stage5-raw@invalid.example','authenticated','authenticated');
  insert into public.users(id,first_name,last_name,language_code)
  values(v_user,'P103','Stage5Raw','en');

  insert into private.exam_prep_skill_states(
    user_id,program_version_id,component_code,skill_code,engine_version,objective_level,coverage_confirmed
  )
  select v_user,v_program,'P1',n.skill_code,v_engine,3,true
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program and n.component_code='P1';

  v_status:=private.exam_prep_stage5_raw_readiness_v1(v_user,v_program,'P1');
  if v_status->>'reason_code'<>'three_comparable_attempts_incomplete'
     or not (v_status->>'stage4_evaluator_deployed')::boolean
     or (v_status->>'last_three_count')::int<>0
     or (v_status->>'stage5_ready')::boolean
     or (v_status->>'stage5_unlocked')::boolean then
    raise exception 'P1-03 Stage-5 raw matrix zero-attempt state wrong %',v_status::text;
  end if;

  perform pg_temp.insert_stage5_p1_attempt_v1(
    v_user,v_program,now()-interval '14 days',array[1,4]::smallint[],'01'
  );
  perform pg_temp.insert_stage5_p1_attempt_v1(
    v_user,v_program,now()-interval '7 days',array[1]::smallint[],'02'
  );
  perform pg_temp.insert_stage5_p1_attempt_v1(
    v_user,v_program,now()-interval '1 day',array[]::smallint[],'03'
  );

  v_status:=private.exam_prep_stage5_raw_readiness_v1(v_user,v_program,'P1');
  if v_status->>'reason_code'<>'stage5_policy_not_deployed'
     or (v_status->>'comparable_full_attempt_count_total')::int<>3
     or (v_status->>'comparison_family_count')::int<>1
     or (v_status->>'selected_family_attempt_count')::int<>3
     or (v_status->>'last_three_count')::int<>3
     or not (v_status->>'has_three_comparable_strict_attempts')::boolean
     or (v_status->>'canonical_skill_count')::int<>45
     or (v_status->>'l3_or_higher_count')::int<>45
     or (v_status->>'below_l3_count')::int<>0
     or v_status->>'minimal_unattempted_threshold_status'<>'not_defined_in_source_plan'
     or (v_status->>'stage5_ready')::boolean
     or (v_status->>'stage5_unlocked')::boolean
     or (v_status->>'stage6_unlocked')::boolean then
    raise exception 'P1-03 Stage-5 raw matrix three-attempt state wrong %',v_status::text;
  end if;

  v_first:=(v_status->'last_three_attempts'->0->>'unattempted_share')::numeric;
  v_second:=(v_status->'last_three_attempts'->1->>'unattempted_share')::numeric;
  v_third:=(v_status->'last_three_attempts'->2->>'unattempted_share')::numeric;
  if not (v_first>v_second and v_second>v_third and v_third=0) then
    raise exception 'P1-03 Stage-5 raw matrix chronological last-three evidence wrong %',v_status->'last_three_attempts';
  end if;

  insert into private.exam_prep_correction_cases(
    user_id,component_code,skill_code,status,engine_version,reason
  ) values(
    v_user,'P1','P1-QUA-01','open',v_engine,'{"source":"rollback_stage5_raw_reader"}'::jsonb
  ) returning id into v_case;

  v_status:=private.exam_prep_stage5_raw_readiness_v1(v_user,v_program,'P1');
  if (v_status->>'unresolved_correction_case_count')::int<>1
     or (v_status->>'unresolved_correction_skill_count')::int<>1
     or (v_status->>'stage5_ready')::boolean then
    raise exception 'P1-03 Stage-5 raw matrix unresolved correction facts wrong %',v_status::text;
  end if;

  -- Component firewall: P1 attempts/corrections cannot count for P5.
  v_status:=private.exam_prep_stage5_raw_readiness_v1(v_user,v_program,'P5');
  if v_status->>'reason_code'<>'three_comparable_attempts_incomplete'
     or (v_status->>'comparable_full_attempt_count_total')::int<>0
     or (v_status->>'last_three_count')::int<>0
     or (v_status->>'unresolved_correction_case_count')::int<>0
     or (v_status->>'canonical_skill_count')::int<>36
     or (v_status->>'stage5_ready')::boolean then
    raise exception 'P1-03 Stage-5 raw matrix component firewall failed %',v_status::text;
  end if;

  raise notice 'P1-03 Stage-5 raw Exam Readiness reader matrix: GREEN';
end $$;

rollback;

\echo 'P1-03 Stage-5 raw Exam Readiness reader matrix: GREEN'
