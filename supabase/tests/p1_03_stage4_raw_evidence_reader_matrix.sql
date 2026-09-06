\set ON_ERROR_STOP on
\echo 'P1-03 Stage-4 raw evidence reader matrix'

begin;

-- Rollback-only helper: create a finally reviewed strict P1 full-paper attempt
-- through the real published assessment/timing-contract path.
create or replace function pg_temp.insert_stage4_raw_p1_attempt_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_assessment_key text,
  p_expected_form_key text,
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
  v_snapshot_key text;
begin
  select a.id,a.content_version_id,a.assessment_version
  into v_ass,v_cv,v_ass_version
  from private.exam_prep_assessments a
  join private.exam_prep_timed_assessment_contracts tc on tc.assessment_id=a.id and tc.status='published'
  where a.assessment_key=p_assessment_key
    and a.assessment_version='av1'
    and a.component_code='P1'
    and a.status='published'
    and tc.attempt_kind='full_paper'
    and tc.timing_rule='official_full'
    and tc.comparison_scope='full'
    and tc.comparability_key=p_expected_form_key;
  if v_ass is null then raise exception 'P1-03 Stage-4 raw reader fixture assessment/contract missing key=%',p_assessment_key; end if;

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
    'P1-03 Stage-4 raw reader rollback fixture '||p_suffix
  ) returning id into v_auth;

  insert into private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,started_at,last_activity_at,
    finalized_at,finalize_idempotency_key,timing_contract
  ) values(
    v_auth,p_user_id,p_program_version_id,v_cv,v_ass,v_ass_version,
    'P1','paper','finalized','p103-s4raw-session-'||p_suffix,v_items,p_finalized_at-interval '100 minutes',p_finalized_at,
    p_finalized_at,'p103-s4raw-final-'||p_suffix,'{}'::jsonb
  ) returning id into v_session;

  select timing_contract->>'comparability_key' into v_snapshot_key
  from private.exam_prep_sessions where id=v_session;
  if v_snapshot_key<>p_expected_form_key then
    raise exception 'P1-03 Stage-4 raw reader fixture timing snapshot key mismatch expected=% got=%',p_expected_form_key,v_snapshot_key;
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
    0,0,0,0,75-v_unattempted_marks,0,v_unattempted_marks,'submitted',
    true,false,p_finalized_at
  );

  insert into private.exam_prep_timed_written_self_marks(
    session_id,item_order,user_id,marks_awarded,max_marks,was_in_time,idempotency_key,review_note
  )
  select v_session,ti.item_order,p_user_id,greatest(ti.max_marks-1,0),ti.max_marks,true,
         'p103-s4raw-self-'||p_suffix||'-'||lpad(ti.item_order::text,2,'0'),
         'Rollback-only Stage-4 raw evidence reader fixture'
  from private.exam_prep_timed_assessment_items ti
  where ti.assessment_id=v_ass
    and not (ti.item_order=any(p_skip_orders));

  if not private.exam_prep_timed_score_comparable_v1(v_session) then
    raise exception 'P1-03 Stage-4 raw reader fixture did not become finally comparable suffix=%',p_suffix;
  end if;

  return v_session;
end;
$$;

-- The new production release guard correctly requires a deployed Stage-4 evaluator.
-- This CI-only stub exists only so this older raw-reader test can temporarily release
-- Paper02 inside the same rollback transaction; it never ships.
create or replace function private.exam_prep_stage4_exit_status_v1(
  p_user_id uuid,p_program_version_id bigint,p_component_code text
)
returns jsonb
language sql
stable
set search_path=''
as $$
  select jsonb_build_object('ready',false,'reason_code','p103_raw_reader_ci_stub','stage4_unlocked',false);
$$;

do $$
declare
  v_program bigint;
  v_engine text;
  v_user uuid := '00000000-0000-4000-8000-000000001054'::uuid;
  v_profile bigint;
  v_p2 bigint;
  v_plan uuid;
  v_case uuid;
  v_s1 uuid;
  v_s2 uuid;
  v_status jsonb;
  v_family jsonb;
  v_qua jsonb;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select engine_version into v_engine
  from private.exam_prep_state_engine_versions where status='active'
  order by created_at desc limit 1;
  if v_program is null or v_engine is null then raise exception 'P1-03 Stage-4 raw reader matrix baseline missing'; end if;

  -- Paper02 must start pre-positioned and invisible.
  select id into v_p2 from private.exam_prep_assessments
  where assessment_key='p1_stage4_full_paper_02' and assessment_version='av1' and status='approved';
  if v_p2 is null then raise exception 'P1-03 Stage-4 raw reader matrix P1 Paper02 pre-position missing'; end if;
  if exists(select 1 from private.exam_prep_timed_assessment_contracts where assessment_id=v_p2) then
    raise exception 'P1-03 Stage-4 raw reader matrix Paper02 unexpectedly released before fixture';
  end if;

  insert into auth.users(id,email,role,aud)
  values(v_user,'p103-stage4-raw-reader@invalid.example','authenticated','authenticated');
  insert into public.users(id,first_name,last_name,language_code)
  values(v_user,'P103','Stage4RawReader','en');

  -- All P1 skills L3 except one L2 remediation obligation.
  insert into private.exam_prep_skill_states(
    user_id,program_version_id,component_code,skill_code,engine_version,objective_level,coverage_confirmed
  )
  select v_user,v_program,'P1',n.skill_code,v_engine,
         case when n.skill_code='P1-QUA-01' then 2 else 3 end,true
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program and n.component_code='P1';

  insert into private.exam_prep_correction_cases(
    user_id,component_code,skill_code,status,engine_version,reason
  ) values(
    v_user,'P1','P1-QUA-01','open',v_engine,'{"source":"rollback_stage4_raw_reader"}'::jsonb
  ) returning id into v_case;
  insert into private.exam_prep_weekly_plans(
    user_id,program_version_id,component_code,active_week_no,plan_version,status,recovery_mode,policy_note
  ) values(
    v_user,v_program,'P1',25,1,'active','normal','Rollback-only Stage-4 raw reader fixture.'
  ) returning id into v_plan;
  insert into private.exam_prep_weekly_plan_items(
    plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,action_code,action_payload,status
  ) values(
    v_plan,1,'correction','P1-QUA-01',v_case,now()+interval '1 day','stage4_raw_reader_followup','{}'::jsonb,'pending'
  );

  v_status:=private.exam_prep_stage4_raw_evidence_v1(v_user,v_program,'P1');
  if (v_status->>'comparable_full_attempt_count_total')::int<>0
     or (v_status->>'comparison_family_count')::int<>0
     or (v_status->>'below_l3_count')::int<>1
     or (v_status->>'stage4_exit_ready')::boolean
     or (v_status->>'stage4_unlocked')::boolean
     or (v_status->>'stage5_unlocked')::boolean
     or v_status->>'trend_policy_status'<>'not_deployed'
     or v_status->>'corrective_plan_policy_status'<>'not_deployed' then
    raise exception 'P1-03 Stage-4 raw reader matrix zero-attempt state wrong %',v_status::text;
  end if;
  select x into v_qua from jsonb_array_elements(v_status->'below_l3_details') x where x->>'skill_code'='P1-QUA-01';
  if v_qua is null
     or (v_qua->>'active_correction_cases')::int<>1
     or (v_qua->>'pending_plan_actions')::int<>1
     or (v_qua->>'pending_plan_actions_with_due')::int<>1 then
    raise exception 'P1-03 Stage-4 raw reader matrix corrective raw facts wrong %',coalesce(v_qua::text,'NULL');
  end if;

  -- First real published form attempt.
  v_s1:=pg_temp.insert_stage4_raw_p1_attempt_v1(
    v_user,v_program,'p1_stage3_full_paper_01','p1-full-paper-01-v1',now()-interval '10 days',array[1,4]::smallint[],'01'
  );

  -- Temporarily satisfy every NEW release guard inside this rollback transaction.
  -- These are fixtures, not governance decisions, and all are verified gone after rollback.
  update private.exam_prep_stage4_release_controls
  set stage4_policy_status='approved',paper02_release_status='approved',updated_at=now()
  where status='active';
  update private.exam_prep_stage3_exit_rules
  set key_registry_status='approved'
  where status='active';
  insert into private.exam_prep_stage3_key_skills(
    rule_version,program_version_id,component_code,skill_code,governance_basis
  )
  select rule_version,v_program,'P1','P1-QUA-01','P1-03 rollback-only raw-reader release fixture'
  from private.exam_prep_stage3_exit_rules where status='active'
  on conflict do nothing;

  -- Temporarily release the pre-positioned second form inside the rollback transaction.
  update private.exam_prep_assessments set status='published' where id=v_p2 and status='approved';
  select id into v_profile from private.exam_prep_component_paper_profiles
  where program_version_id=v_program and component_code='P1' and profile_version='9709_2026_2027_v1' and status='published';
  if v_profile is null then raise exception 'P1-03 Stage-4 raw reader matrix P1 paper profile missing'; end if;
  insert into private.exam_prep_timed_assessment_contracts(
    assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
    strict_timing,comparison_scope,comparability_key,min_operational_stage,status,published_at
  ) values(
    v_p2,v_profile,'tcv1','full_paper','official_full',75,null,true,'full','p1-full-paper-02-v1',4,'published',now()
  );

  v_s2:=pg_temp.insert_stage4_raw_p1_attempt_v1(
    v_user,v_program,'p1_stage4_full_paper_02','p1-full-paper-02-v1',now()-interval '4 days',array[1]::smallint[],'02'
  );

  v_status:=private.exam_prep_stage4_raw_evidence_v1(v_user,v_program,'P1');
  if (v_status->>'comparable_full_attempt_count_total')::int<>2
     or (v_status->>'exact_form_count_total')::int<>2
     or (v_status->>'comparison_family_count')::int<>1
     or (v_status->>'max_compatible_family_attempt_count')::int<>2
     or (v_status->>'stage4_exit_ready')::boolean
     or (v_status->>'stage4_unlocked')::boolean
     or (v_status->>'stage5_unlocked')::boolean then
    raise exception 'P1-03 Stage-4 raw reader matrix two-form family wrong %',v_status::text;
  end if;

  v_family:=v_status->'comparison_families'->0;
  if v_family->>'paper_profile_version'<>'9709_2026_2027_v1'
     or (v_family->>'attempt_count')::int<>2
     or (v_family->>'exact_form_count')::int<>2
     or abs((v_family->>'previous_unattempted_share')::numeric-(12::numeric/75))>0.0000001
     or abs((v_family->>'latest_unattempted_share')::numeric-(6::numeric/75))>0.0000001
     or abs((v_family->>'unattempted_share_delta')::numeric-(-6::numeric/75))>0.0000001
     or (v_family->>'latest_after_time_share')::numeric<>0
     or (v_family->>'previous_after_time_share')::numeric<>0 then
    raise exception 'P1-03 Stage-4 raw reader matrix family facts wrong %',v_family::text;
  end if;

  -- Component firewall: P1 paper facts cannot satisfy P5.
  v_status:=private.exam_prep_stage4_raw_evidence_v1(v_user,v_program,'P5');
  if (v_status->>'comparable_full_attempt_count_total')::int<>0
     or (v_status->>'comparison_family_count')::int<>0
     or (v_status->>'canonical_skill_count')::int<>36
     or (v_status->>'stage4_exit_ready')::boolean then
    raise exception 'P1-03 Stage-4 raw reader matrix component firewall failed %',v_status::text;
  end if;

  if (select max_automatic_stage from private.exam_prep_operational_stage_rules where status='active')<>3 then
    raise exception 'P1-03 Stage-4 raw reader matrix automatic stage ceiling moved';
  end if;

  raise notice 'P1-03 Stage-4 raw evidence reader matrix: GREEN';
end $$;

rollback;

-- Rollback must restore the pre-positioned release boundary AND every simulated governance prerequisite.
do $$
declare
  v_p2 bigint;
  v_control private.exam_prep_stage4_release_controls%rowtype;
begin
  select id into v_p2 from private.exam_prep_assessments
  where assessment_key='p1_stage4_full_paper_02' and assessment_version='av1' and status='approved';
  if v_p2 is null then raise exception 'P1-03 Stage-4 raw reader matrix rollback did not restore approved Paper02'; end if;
  if exists(select 1 from private.exam_prep_timed_assessment_contracts where assessment_id=v_p2) then
    raise exception 'P1-03 Stage-4 raw reader matrix rollback left Paper02 timed contract';
  end if;
  select * into v_control from private.exam_prep_stage4_release_controls where status='active';
  if v_control.stage4_policy_status<>'pending' or v_control.paper02_release_status<>'pending' then
    raise exception 'P1-03 Stage-4 raw reader matrix rollback left simulated release approval';
  end if;
  if exists(select 1 from private.exam_prep_stage3_key_skills) then
    raise exception 'P1-03 Stage-4 raw reader matrix rollback left simulated key registry rows';
  end if;
  if (select key_registry_status from private.exam_prep_stage3_exit_rules where status='active')<>'pending' then
    raise exception 'P1-03 Stage-4 raw reader matrix rollback left Stage3 key registry approved';
  end if;
  if to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is not null then
    raise exception 'P1-03 Stage-4 raw reader matrix rollback left CI-only Stage4 evaluator';
  end if;
end $$;

\echo 'P1-03 Stage-4 raw evidence reader matrix: GREEN'
