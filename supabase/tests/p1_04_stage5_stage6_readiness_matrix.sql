\set ON_ERROR_STOP on
\echo 'P1-04 Stage-5/6 readiness matrix - rollback only'

begin;

create or replace function pg_temp.insert_p1_full_attempt_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_finalized_at timestamptz,
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
  if v_ass is null then raise exception 'P1-04: published P1 full-paper baseline missing'; end if;

  select count(*)::int into v_items
  from private.exam_prep_assessment_items where assessment_id=v_ass;

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason
  ) values(
    p_user_id,v_ass,'P1','paper','issued',now()+interval '1 hour',
    'P1-04 rollback-only Stage5/6 readiness fixture '||p_suffix
  ) returning id into v_auth;

  insert into private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,started_at,last_activity_at,
    finalized_at,finalize_idempotency_key,timing_contract
  ) values(
    v_auth,p_user_id,p_program_version_id,v_cv,v_ass,v_ass_version,
    'P1','paper','finalized','p104-stage56-session-'||p_suffix,v_items,
    p_finalized_at-interval '100 minutes',p_finalized_at,p_finalized_at,
    'p104-stage56-final-'||p_suffix,'{}'::jsonb
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
    true,75,6600,6000,v_items,0,
    0,0,0,0,75,0,0,'submitted',true,false,p_finalized_at
  );

  insert into private.exam_prep_timed_written_self_marks(
    session_id,item_order,user_id,marks_awarded,max_marks,was_in_time,idempotency_key,review_note
  )
  select v_session,ti.item_order,p_user_id,greatest(ti.max_marks-1,0),ti.max_marks,true,
         'p104-stage56-self-'||p_suffix||'-'||lpad(ti.item_order::text,2,'0'),
         'Rollback-only Stage5/6 readiness fixture'
  from private.exam_prep_timed_assessment_items ti
  where ti.assessment_id=v_ass;

  if not private.exam_prep_timed_score_comparable_v1(v_session) then
    raise exception 'P1-04: synthetic full attempt is not score-comparable suffix=%',p_suffix;
  end if;
  return v_session;
end;
$$;

create or replace function pg_temp.seed_p1_ready_skill_projection_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_engine text
)
returns void
language plpgsql
as $$
begin
  insert into private.exam_prep_skill_states(
    user_id,program_version_id,component_code,skill_code,engine_version,
    objective_level,coverage_confirmed,evidence_total,objective_evidence_count,correct_objective_count,
    objective_accuracy_pct,learning_count,diagnostic_count,mixed_count,timed_count,retest_count,written_count,
    has_transfer_evidence,has_successful_retest,has_delayed_successful_retest,has_written_evidence,
    has_mentor_verified_evidence,unresolved_correction_count,hold_reason,source_evidence_through
  )
  select p_user_id,p_program_version_id,'P1',n.skill_code,p_engine,
         3,true,6,4,4,100,1,1,1,1,1,1,true,true,true,true,false,0,
         'rollback_stage56_ready_fixture',now()
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=p_program_version_id and n.component_code='P1';
end;
$$;

create or replace function pg_temp.seed_p1_stage0_complete_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_engine text
)
returns void
language plpgsql
as $$
declare v_rule text;
begin
  select rule_version into v_rule
  from private.exam_prep_placement_rule_versions
  where program_version_id=p_program_version_id and status='active';

  insert into private.exam_prep_component_placements(
    user_id,program_version_id,component_code,rule_version,placement_status,route,
    profile_complete,content_ready,screening_required_items,screening_required_areas,
    screening_available_items,screening_available_areas,screening_answered_items,screening_answered_areas,
    screening_objective_items,screening_correct_items,screening_accuracy_pct,
    prerequisite_unknown_count,prerequisite_blocker_count,ambiguity,advanced_skip_requires_human,
    stage0_complete,route_reason,evidence_summary
  ) values(
    p_user_id,p_program_version_id,'P1',v_rule,'confirmed','foundation',
    true,true,24,8,24,8,24,8,24,24,100,
    0,0,false,false,true,'Rollback-only Stage5/6 progression fixture','{}'::jsonb
  );

  insert into private.exam_prep_component_access_gates(
    user_id,program_version_id,component_code,rule_version,current_operational_stage,max_unlocked_stage,
    placement_access,foundation_learning_access,advanced_route_access,mentor_required_for_core,
    gate_status,gate_reason
  ) values(
    p_user_id,p_program_version_id,'P1',v_rule,0,1,true,true,false,false,
    'stage0_complete','Rollback-only Stage5/6 progression fixture'
  );

  insert into private.exam_prep_stage_states(
    user_id,program_version_id,component_code,engine_version,
    denominator_count,l0_count,l1_count,l2_count,l3_count,coverage_count,coverage_pct,
    open_correction_count,retest_due_count,evidence_stage_candidate,operational_stage,
    stage_gate_status,stage_hold_reason,app_readiness_estimate,app_readiness_reason
  ) values(
    p_user_id,p_program_version_id,'P1',p_engine,
    45,0,0,0,45,45,100,
    0,0,2,0,'blocked_dependency','fixture','INSUFFICIENT_EVIDENCE','fixture'
  );
end;
$$;

do $$
declare
  v_program bigint;
  v_engine text;
  v_strong uuid := '00000000-0000-4000-8000-000000001061'::uuid;
  v_border uuid := '00000000-0000-4000-8000-000000001062'::uuid;
  v_weak uuid := '00000000-0000-4000-8000-000000001063'::uuid;
  v_status jsonb;
  v_cal jsonb;
  v_stage smallint;
  v_threshold_count int;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select engine_version into v_engine
  from private.exam_prep_state_engine_versions where status='active'
  order by created_at desc limit 1;
  if v_program is null or v_engine is null then raise exception 'P1-04: canonical program/engine missing'; end if;

  if (select max_automatic_stage from private.exam_prep_operational_stage_rules where status='active')<>6 then
    raise exception 'P1-04: full Stage 0-6 taxonomy not deployed';
  end if;
  if (select stage5_policy_status from private.exam_prep_stage5_release_controls where status='active')<>'approved'
     or (select paper03_release_status from private.exam_prep_stage5_release_controls where status='active')<>'approved' then
    raise exception 'P1-04: Stage5 policy/Paper03 release not fully governed';
  end if;

  insert into auth.users(id,email,role,aud) values
    (v_strong,'p104-strong@invalid.example','authenticated','authenticated'),
    (v_border,'p104-border@invalid.example','authenticated','authenticated'),
    (v_weak,'p104-weak@invalid.example','authenticated','authenticated');
  insert into public.users(id,first_name,last_name,language_code) values
    (v_strong,'P104','Strong','en'),
    (v_border,'P104','Border','en'),
    (v_weak,'P104','Weak','en');

  insert into private.exam_prep_exam_profiles(
    user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,active_week_no
  ) values
    (v_strong,v_program,'CI_TEST_STRONG','A',12,6,32),
    (v_border,v_program,'CI_TEST_BORDERLINE','A*',12,6,32),
    (v_weak,v_program,'CI_TEST_WEAK','B',12,6,32);

  insert into private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) values
    (v_strong,'active',true,false,false,'ci-stage56-rollback',now()),
    (v_border,'active',true,false,false,'ci-stage56-rollback',now()),
    (v_weak,'active',true,false,false,'ci-stage56-rollback',now());

  perform pg_temp.seed_p1_ready_skill_projection_v1(v_strong,v_program,v_engine);
  perform pg_temp.seed_p1_ready_skill_projection_v1(v_border,v_program,v_engine);
  perform pg_temp.seed_p1_ready_skill_projection_v1(v_weak,v_program,v_engine);

  -- Three same-condition strict papers for strong/borderline; two for weak.
  perform pg_temp.insert_p1_full_attempt_v1(v_strong,v_program,now()-interval '14 days','strong01');
  perform pg_temp.insert_p1_full_attempt_v1(v_strong,v_program,now()-interval '7 days','strong02');
  perform pg_temp.insert_p1_full_attempt_v1(v_strong,v_program,now()-interval '1 day','strong03');
  perform pg_temp.insert_p1_full_attempt_v1(v_border,v_program,now()-interval '14 days','border01');
  perform pg_temp.insert_p1_full_attempt_v1(v_border,v_program,now()-interval '7 days','border02');
  perform pg_temp.insert_p1_full_attempt_v1(v_border,v_program,now()-interval '1 day','border03');
  perform pg_temp.insert_p1_full_attempt_v1(v_weak,v_program,now()-interval '7 days','weak01');
  perform pg_temp.insert_p1_full_attempt_v1(v_weak,v_program,now()-interval '1 day','weak02');

  -- CI-only thresholds are intentionally synthetic and disappear at ROLLBACK.
  insert into private.exam_prep_stage5_thresholds(
    threshold_version,program_version_id,component_code,exam_series_key,target_grade,
    min_in_time_score_pct,max_unattempted_share,max_after_time_share,status,source_ref,policy_note,approved_at
  ) values
    ('ci_stage56_strong_v1',v_program,'P1','CI_TEST_STRONG','A',80,0,0,'approved','rollback-only CI fixture','Synthetic regression threshold; not a Cambridge rule and never persisted.',now()),
    ('ci_stage56_border_v1',v_program,'P1','CI_TEST_BORDERLINE','A*',90,0,0,'approved','rollback-only CI fixture','Synthetic regression threshold; not a Cambridge rule and never persisted.',now()),
    ('ci_stage56_weak_v1',v_program,'P1','CI_TEST_WEAK','B',70,0,0,'approved','rollback-only CI fixture','Synthetic regression threshold; not a Cambridge rule and never persisted.',now());

  -- Strong: all three comparable papers exceed the synthetic target and Stage-5 readiness is true.
  v_status:=private.exam_prep_stage5_readiness_status_v1(v_strong,v_program,'P1');
  if not coalesce((v_status->>'ready')::boolean,false)
     or v_status->>'reason_code'<>'ready'
     or (v_status->>'last_three_count')::int<>3
     or (v_status->>'below_l3_count')::int<>0
     or (v_status->>'unresolved_correction_case_count')::int<>0 then
    raise exception 'P1-04 strong readiness failed %',v_status::text;
  end if;

  -- Same P1 evidence must never lift P5.
  v_status:=private.exam_prep_stage5_readiness_status_v1(v_strong,v_program,'P5');
  if coalesce((v_status->>'ready')::boolean,false)
     or v_status->>'reason_code'<>'stage4_exit_incomplete' then
    raise exception 'P1-04 P1/P5 firewall failed %',v_status::text;
  end if;

  -- Borderline: identical evidence, stricter synthetic target, deterministic hold.
  v_status:=private.exam_prep_stage5_readiness_status_v1(v_border,v_program,'P1');
  if coalesce((v_status->>'ready')::boolean,false)
     or v_status->>'reason_code'<>'last_three_below_individual_threshold'
     or (v_status->>'last_three_count')::int<>3 then
    raise exception 'P1-04 borderline readiness failed %',v_status::text;
  end if;

  -- Weak: only two full papers, so Stage-5 readiness cannot be awarded even with a lower threshold.
  v_status:=private.exam_prep_stage5_readiness_status_v1(v_weak,v_program,'P1');
  if coalesce((v_status->>'ready')::boolean,false)
     or v_status->>'reason_code'<>'three_comparable_attempts_incomplete'
     or (v_status->>'last_three_count')::int<>2 then
    raise exception 'P1-04 weak readiness failed %',v_status::text;
  end if;

  -- Exercise the actual operational Stage trigger: strong reaches 6; other two stop at 5.
  perform pg_temp.seed_p1_stage0_complete_v1(v_strong,v_program,v_engine);
  perform pg_temp.seed_p1_stage0_complete_v1(v_border,v_program,v_engine);
  perform pg_temp.seed_p1_stage0_complete_v1(v_weak,v_program,v_engine);

  select operational_stage into v_stage from private.exam_prep_stage_states
  where user_id=v_strong and program_version_id=v_program and component_code='P1' and engine_version=v_engine;
  if v_stage<>6 then raise exception 'P1-04 strong progression expected Stage6 got=%',v_stage; end if;
  select operational_stage into v_stage from private.exam_prep_stage_states
  where user_id=v_border and program_version_id=v_program and component_code='P1' and engine_version=v_engine;
  if v_stage<>5 then raise exception 'P1-04 borderline progression expected Stage5 got=%',v_stage; end if;
  select operational_stage into v_stage from private.exam_prep_stage_states
  where user_id=v_weak and program_version_id=v_program and component_code='P1' and engine_version=v_engine;
  if v_stage<>5 then raise exception 'P1-04 weak progression expected Stage5 got=%',v_stage; end if;

  -- Safe learner surface for strong evidence must open Final Calibration without Mentor Care.
  perform set_config('request.jwt.claim.sub',v_strong::text,true);
  v_cal:=public.get_exam_prep_final_calibration_safe_v1('P1');
  if not coalesce((v_cal->>'available')::boolean,false)
     or (v_cal->>'operational_stage')::int<>6
     or coalesce((v_cal->>'new_mastery_allowed')::boolean,true)
     or coalesce((v_cal->>'mentor_verified_readiness')::boolean,true)
     or jsonb_array_length(coalesce(v_cal->'actions','[]'::jsonb))<3 then
    raise exception 'P1-04 Final Calibration safe surface failed %',v_cal::text;
  end if;

  select count(*) into v_threshold_count
  from private.exam_prep_stage5_thresholds
  where threshold_version like 'ci_stage56_%';
  if v_threshold_count<>3 then raise exception 'P1-04 synthetic threshold fixture mismatch=%',v_threshold_count; end if;

  raise notice 'P1-04 Stage-5/6 strong + borderline + weak matrix: GREEN';
end $$;

rollback;

\echo 'P1-04 Stage-5/6 readiness matrix: GREEN'