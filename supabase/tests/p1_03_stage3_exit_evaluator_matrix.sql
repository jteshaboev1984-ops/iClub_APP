\set ON_ERROR_STOP on
\echo 'P1-03 Stage-3 Syllabus Closure exit evaluator matrix'

begin;

do $$
declare
  v_program bigint;
  v_engine text;
  v_user uuid := '00000000-0000-4000-8000-000000001051'::uuid;
  v_rule text;
  v_status jsonb;
  v_ass bigint;
  v_cv bigint;
  v_ass_version text;
  v_auth uuid;
  v_session uuid;
  v_comparable boolean;
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
    raise exception 'P1-03 Stage-3 exit matrix: baseline rule/program/engine missing';
  end if;
  if (select key_registry_status from private.exam_prep_stage3_exit_rules where rule_version=v_rule)<>'pending' then
    raise exception 'P1-03 Stage-3 exit matrix: production registry must begin pending';
  end if;
  if exists(select 1 from private.exam_prep_stage3_key_skills where rule_version=v_rule) then
    raise exception 'P1-03 Stage-3 exit matrix: production key registry must begin empty';
  end if;

  -- Pending governance is the first fail-closed reason, even before learner state exists.
  v_status:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P1');
  if (v_status->>'ready')::boolean or v_status->>'reason_code'<>'key_registry_pending'
     or (v_status->>'stage4_unlocked')::boolean then
    raise exception 'P1-03 Stage-3 exit matrix: pending registry did not fail closed %',v_status::text;
  end if;

  -- CI-only governance fixture. Production migration deliberately contains none of these rows.
  update private.exam_prep_stage3_exit_rules
  set key_registry_status='approved'
  where rule_version=v_rule;

  insert into private.exam_prep_stage3_key_skills(
    rule_version,program_version_id,component_code,skill_code,governance_basis
  ) values(v_rule,v_program,'P1','P1-DIF-07','Rollback-only CI key-skill registry fixture.');

  -- Cross-component registry spoofing must fail.
  v_failed:=false;
  begin
    insert into private.exam_prep_stage3_key_skills(
      rule_version,program_version_id,component_code,skill_code,governance_basis
    ) values(v_rule,v_program,'P5','P1-DIF-07','Invalid rollback-only component spoof fixture.');
  exception when others then
    if position('exam_prep_stage3_key_skill_component_mismatch' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 Stage-3 exit matrix: cross-component key skill spoof was accepted'; end if;

  -- P5 still has no approved key codes and therefore remains independently fail closed.
  v_status:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P5');
  if v_status->>'reason_code'<>'key_registry_empty' then
    raise exception 'P1-03 Stage-3 exit matrix: P5 empty registry did not fail closed %',v_status::text;
  end if;

  insert into auth.users(id,email,role,aud)
  values(v_user,'p103-stage3-exit@invalid.example','authenticated','authenticated');
  insert into public.users(id,first_name,last_name,language_code)
  values(v_user,'P103','Stage3Exit','en');

  -- Full P1 canonical closure: every point covered/L2, one CI key point at L3.
  insert into private.exam_prep_skill_states(
    user_id,program_version_id,component_code,skill_code,engine_version,objective_level,coverage_confirmed
  )
  select v_user,v_program,'P1',n.skill_code,v_engine,
         case when n.skill_code='P1-DIF-07' then 3 else 2 end,
         true
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program and n.component_code='P1';

  v_status:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P1');
  if (v_status->>'ready')::boolean
     or v_status->>'reason_code'<>'full_baseline_missing'
     or (v_status->>'coverage_count')::int<>45
     or (v_status->>'l2_or_higher_count')::int<>45
     or (v_status->>'key_skill_count')::int<>1
     or (v_status->>'key_l3_count')::int<>1
     or (v_status->>'covered_section_count')::int<>8 then
    raise exception 'P1-03 Stage-3 exit matrix: closed syllabus without baseline classified incorrectly %',v_status::text;
  end if;

  select a.id,a.content_version_id,a.assessment_version
    into v_ass,v_cv,v_ass_version
  from private.exam_prep_assessments a
  where a.assessment_key='p1_stage3_full_paper_01'
    and a.assessment_version='av1'
    and a.status='published';
  if v_ass is null then raise exception 'P1-03 Stage-3 exit matrix: governed P1 full paper missing'; end if;

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason
  ) values(
    v_user,v_ass,'P1','paper','issued',now()+interval '1 hour','P1-03 Stage-3 exit rollback-only full-paper fixture'
  ) returning id into v_auth;

  insert into private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,started_at,last_activity_at,
    finalized_at,finalize_idempotency_key,timing_contract
  ) values(
    v_auth,v_user,v_program,v_cv,v_ass,v_ass_version,
    'P1','paper','finalized','p103-s3exit-session-0001',10,now()-interval '100 minutes',now(),
    now(),'p103-s3exit-final-0001','{"attempt_kind":"full_paper","timing_rule":"official_full","comparison_scope":"full","strict_timing":true,"marks_available":75,"time_limit_sec":6600,"comparability_key":"p1-full-paper-01-v1"}'::jsonb
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
    v_session,v_user,'P1',v_ass,'full_paper','official_full','full','p1-full-paper-01-v1',
    true,75,6600,6000,10,0,
    0,0,0,0,75,0,0,'submitted',true,false,now()
  );

  -- Finalize-time snapshot is not enough while written review is pending.
  v_comparable:=private.exam_prep_timed_score_comparable_v1(v_session);
  if v_comparable then raise exception 'P1-03 Stage-3 exit matrix: pending written full paper incorrectly comparable'; end if;
  v_status:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P1');
  if v_status->>'reason_code'<>'full_baseline_missing' or (v_status->>'comparable_full_baseline_count')::int<>0 then
    raise exception 'P1-03 Stage-3 exit matrix: pending-review paper counted as baseline %',v_status::text;
  end if;

  -- Complete self-review for every written item using the governed max-mark specs.
  insert into private.exam_prep_timed_written_self_marks(
    session_id,item_order,user_id,marks_awarded,max_marks,was_in_time,idempotency_key,review_note
  )
  select v_session,ti.item_order,v_user,ti.max_marks,ti.max_marks,true,
         'p103-s3exit-self-'||lpad(ti.item_order::text,2,'0'),
         'Rollback-only Stage-3 exit comparability fixture'
  from private.exam_prep_timed_assessment_items ti
  where ti.assessment_id=v_ass;

  v_comparable:=private.exam_prep_timed_score_comparable_v1(v_session);
  if not v_comparable then raise exception 'P1-03 Stage-3 exit matrix: completed written self-review did not make paper comparable'; end if;

  v_status:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P1');
  if not (v_status->>'ready')::boolean
     or v_status->>'reason_code'<>'ready'
     or (v_status->>'comparable_full_baseline_count')::int<>1
     or (v_status->>'stage4_unlocked')::boolean then
    raise exception 'P1-03 Stage-3 exit matrix: complete Stage-3 exit evidence wrong %',v_status::text;
  end if;

  -- A reopened key skill must immediately fail the closure evaluator even though the paper remains comparable.
  update private.exam_prep_skill_states
  set objective_level=2,derived_at=now()
  where user_id=v_user and program_version_id=v_program and component_code='P1'
    and skill_code='P1-DIF-07' and engine_version=v_engine;
  v_status:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P1');
  if v_status->>'reason_code'<>'key_l3_incomplete' or (v_status->>'ready')::boolean then
    raise exception 'P1-03 Stage-3 exit matrix: reopened key skill did not fail closed %',v_status::text;
  end if;

  raise notice 'P1-03 Stage-3 Syllabus Closure exit evaluator matrix: GREEN';
end $$;

rollback;

\echo 'P1-03 Stage-3 Syllabus Closure exit evaluator matrix: GREEN'