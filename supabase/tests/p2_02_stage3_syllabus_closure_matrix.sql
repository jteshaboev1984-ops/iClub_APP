-- P2-02 Stage 3 Syllabus Closure current-schema matrix.
-- Rollback-only synthetic learner. Verifies P1/P5 closure independently.
\set ON_ERROR_STOP on
\echo 'P2-02 Stage 3 Syllabus Closure matrix'

BEGIN;

DO $$
DECLARE
  v_program bigint;
  v_engine text;
  v_rule text;
  v_user uuid:='00000000-0000-4000-8000-000000002202'::uuid;
  v_status jsonb;
  v_other jsonb;
  v_payload jsonb;
  v_key text;
  r record;
  v_ass bigint;
  v_cv bigint;
  v_ass_version text;
  v_auth uuid;
  v_session uuid;
  v_total_items int;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';

  select engine_version into v_engine
  from private.exam_prep_state_engine_versions
  where status='active'
  order by activated_at desc nulls last,created_at desc
  limit 1;

  select rule_version into v_rule
  from private.exam_prep_stage3_exit_rules
  where status='active';

  if v_program is null or v_engine is null or v_rule is null then
    raise exception 'P2-02 program/engine/Stage-3 rule missing';
  end if;

  if not exists(
    select 1 from private.exam_prep_stage3_exit_rules
    where rule_version=v_rule
      and min_all_skill_level=2
      and min_key_skill_level=3
      and require_comparable_full_baseline
      and key_registry_status='approved'
  ) then
    raise exception 'P2-02 Stage-3 closure law drift';
  end if;

  if (select count(*) from private.exam_prep_stage3_key_skills
      where rule_version=v_rule and program_version_id=v_program and component_code='P1')<>8
     or (select count(*) from private.exam_prep_stage3_key_skills
      where rule_version=v_rule and program_version_id=v_program and component_code='P5')<>7
     or (select count(distinct n.official_syllabus_section)
         from private.exam_prep_stage3_key_skills k
         join private.exam_prep_syllabus_nodes n
           on n.program_version_id=k.program_version_id
          and n.component_code=k.component_code
          and n.skill_code=k.skill_code
         where k.rule_version=v_rule and k.program_version_id=v_program and k.component_code='P1')<>8
     or (select count(distinct n.official_syllabus_section)
         from private.exam_prep_stage3_key_skills k
         join private.exam_prep_syllabus_nodes n
           on n.program_version_id=k.program_version_id
          and n.component_code=k.component_code
          and n.skill_code=k.skill_code
         where k.rule_version=v_rule and k.program_version_id=v_program and k.component_code='P5')<>5
     or not exists(
       select 1 from private.exam_prep_stage3_key_skills
       where rule_version=v_rule and program_version_id=v_program
         and component_code='P5' and skill_code='P5-GEO-01'
     )
  then
    raise exception 'P2-02 approved key-skill registry/breadth mismatch';
  end if;

  if to_regprocedure('private.exam_prep_stage3_exit_status_v1(uuid,bigint,text)') is null
     or to_regprocedure('private.exam_prep_stage3_closure_payload_v1(uuid,text)') is null
     or to_regprocedure('public.get_exam_prep_stage3_closure_safe_v1(text)') is null
     or to_regprocedure('public.get_exam_prep_syllabus_tracker_safe_v1(text)') is null
  then
    raise exception 'P2-02 closure/tracker APIs missing';
  end if;

  if has_function_privilege('anon','public.get_exam_prep_stage3_closure_safe_v1(text)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_stage3_closure_safe_v1(text)','EXECUTE')
  then
    raise exception 'P2-02 public closure API privilege boundary drift';
  end if;

  insert into auth.users(id,email,role,aud)
  values(v_user,'p202-stage3-closure@invalid.example','authenticated','authenticated');
  insert into public.users(id,first_name,last_name,language_code)
  values(v_user,'P202','Stage3Closure','en');

  insert into private.exam_prep_exam_profiles(
    user_id,program_version_id,exam_series,target_grade,
    total_student_hours_available,mathematics_hours_budget,active_week_no,
    created_by,updated_by
  ) values(
    v_user,v_program,'May/June 2027','A',12,6,24,v_user,v_user
  );

  -- Build component-complete coverage ledger state:
  -- every canonical skill >=L2, all governed key skills >=L3.
  insert into private.exam_prep_skill_states(
    user_id,program_version_id,component_code,skill_code,engine_version,
    objective_level,coverage_confirmed
  )
  select
    v_user,v_program,n.component_code,n.skill_code,v_engine,
    case when exists(
      select 1 from private.exam_prep_stage3_key_skills k
      where k.rule_version=v_rule
        and k.program_version_id=v_program
        and k.component_code=n.component_code
        and k.skill_code=n.skill_code
    ) then 3 else 2 end,
    true
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program
    and n.component_code in ('P1','P5');

  -- Coverage/L2/L3 are complete, so both components must stop specifically
  -- on the missing first comparable full-paper baseline.
  foreach v_key in array array['P1','P5']
  loop
    v_status:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,v_key);
    if (v_status->>'ready')::boolean
       or v_status->>'reason_code'<>'full_baseline_missing'
       or (v_status->>'coverage_count')::int<>(case when v_key='P1' then 45 else 36 end)
       or (v_status->>'l2_or_higher_count')::int<>(case when v_key='P1' then 45 else 36 end)
       or (v_status->>'key_skill_count')::int<>(case when v_key='P1' then 8 else 7 end)
       or (v_status->>'key_l3_count')::int<>(case when v_key='P1' then 8 else 7 end)
       or (v_status->>'stage4_unlocked')::boolean
    then
      raise exception 'P2-02 pre-baseline closure state wrong component=% payload=%',v_key,v_status;
    end if;

    v_payload:=private.exam_prep_stage3_closure_payload_v1(v_user,v_key);
    if (v_payload->>'component_code')<>v_key
       or (v_payload->'coverage_ledger'->>'denominator_count')::int<>(case when v_key='P1' then 45 else 36 end)
       or (v_payload->'coverage_ledger'->>'coverage_count')::int<>(case when v_key='P1' then 45 else 36 end)
       or (v_payload->'baseline_workflow'->>'modified_paper_available_count')::int<1
       or (v_payload->'baseline_workflow'->>'full_paper_available_count')::int<1
       or (v_payload->'gate_law'->>'coverage_required_pct')::int<>100
       or (v_payload->'gate_law'->>'all_skills_min_level')::int<>2
       or (v_payload->'gate_law'->>'key_skills_min_level')::int<>3
       or coalesce((v_payload->'gate_law'->>'calendar_can_close')::boolean,true)
       or coalesce((v_payload->'gate_law'->>'product_content_complete_can_close')::boolean,true)
       or coalesce((v_payload->'gate_law'->>'cross_component_compensation')::boolean,true)
    then
      raise exception 'P2-02 closure payload wrong component=% payload=%',v_key,v_payload;
    end if;
  end loop;

  -- Create one fully reviewed comparable full-paper baseline for each component.
  -- After P1 completes, P5 must remain independently blocked.
  for r in
    select *
    from (values
      ('P1'::text,'p1_stage3_full_paper_01'::text,'p1-full-paper-01-v1'::text,75::int,6600::int),
      ('P5'::text,'p5_stage3_full_paper_01'::text,'p5-full-paper-01-v1'::text,50::int,4500::int)
    ) v(component_code,assessment_key,comparability_key,official_marks,official_time)
  loop
    select a.id,a.content_version_id,a.assessment_version,count(ai.*)::int
      into v_ass,v_cv,v_ass_version,v_total_items
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.assessment_key=r.assessment_key
      and a.assessment_version='av1'
      and a.status='published'
    group by a.id,a.content_version_id,a.assessment_version;

    if v_ass is null or v_total_items=0 then
      raise exception 'P2-02 governed full-paper baseline missing component=%',r.component_code;
    end if;

    insert into private.exam_prep_session_authorizations(
      user_id,assessment_id,component_code,purpose,status,valid_until,reason
    ) values(
      v_user,v_ass,r.component_code,'paper','issued',now()+interval '1 hour',
      'P2-02 rollback-only Stage-3 full-paper baseline fixture'
    ) returning id into v_auth;

    insert into private.exam_prep_sessions(
      authorization_id,user_id,program_version_id,content_version_id,
      assessment_id,assessment_version,component_code,session_type,status,
      client_idempotency_key,total_items,started_at,last_activity_at,
      finalized_at,finalize_idempotency_key,timing_contract
    ) values(
      v_auth,v_user,v_program,v_cv,v_ass,v_ass_version,
      r.component_code,'paper','finalized',
      'p202-s3-'||lower(r.component_code)||'-session',
      v_total_items,now()-interval '100 minutes',now(),now(),
      'p202-s3-'||lower(r.component_code)||'-final',
      jsonb_build_object(
        'attempt_kind','full_paper',
        'timing_rule','official_full',
        'comparison_scope','full',
        'strict_timing',true,
        'marks_available',r.official_marks,
        'time_limit_sec',r.official_time,
        'comparability_key',r.comparability_key
      )
    ) returning id into v_session;

    insert into private.exam_prep_session_items(
      session_id,item_order,item_kind,question_id,written_task_id,
      primary_skill_code,reserve_role,is_holdout,content_meta_id,
      question_snapshot_md5,item_version
    )
    select
      v_session,ai.item_order,'written',null,ai.written_task_id,
      ai.primary_skill_code,ai.reserve_role,ai.is_holdout,null,null,
      'written:'||wt.task_version
    from private.exam_prep_assessment_items ai
    join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
    where ai.assessment_id=v_ass;

    insert into private.exam_prep_timed_attempt_results(
      session_id,user_id,component_code,assessment_id,attempt_kind,timing_rule,
      comparison_scope,comparability_key,strict_timing,marks_available,
      time_limit_sec,server_elapsed_sec,answered_items,unattempted_items,
      objective_marks_in_time,objective_marks_after_time,
      objective_lost_in_time_marks,objective_lost_after_time_marks,
      pending_review_in_time_marks,pending_review_after_time_marks,
      unattempted_marks,completion_reason,timing_comparable,
      base_score_comparable,finalized_at
    ) values(
      v_session,v_user,r.component_code,v_ass,'full_paper','official_full',
      'full',r.comparability_key,true,r.official_marks,r.official_time,
      greatest(r.official_time-60,1),v_total_items,0,
      0,0,0,0,r.official_marks,0,0,'submitted',true,false,now()
    );

    if private.exam_prep_timed_score_comparable_v1(v_session) then
      raise exception 'P2-02 pending written review incorrectly comparable component=%',r.component_code;
    end if;

    insert into private.exam_prep_timed_written_self_marks(
      session_id,item_order,user_id,marks_awarded,max_marks,was_in_time,
      idempotency_key,review_note
    )
    select
      v_session,ti.item_order,v_user,ti.max_marks,ti.max_marks,true,
      'p202-s3-'||lower(r.component_code)||'-self-'||lpad(ti.item_order::text,2,'0'),
      'Rollback-only P2-02 comparability fixture'
    from private.exam_prep_timed_assessment_items ti
    where ti.assessment_id=v_ass;

    if not private.exam_prep_timed_score_comparable_v1(v_session) then
      raise exception 'P2-02 completed written review not comparable component=%',r.component_code;
    end if;

    v_status:=private.exam_prep_stage3_exit_status_v1(
      v_user,v_program,r.component_code
    );
    if not (v_status->>'ready')::boolean
       or v_status->>'reason_code'<>'ready'
       or (v_status->>'comparable_full_baseline_count')::int<>1
       or (v_status->>'stage4_unlocked')::boolean
    then
      raise exception 'P2-02 component did not meet Stage-3 closure after baseline component=% payload=%',
        r.component_code,v_status;
    end if;

    if r.component_code='P1' then
      v_other:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P5');
      if (v_other->>'ready')::boolean
         or v_other->>'reason_code'<>'full_baseline_missing'
      then
        raise exception 'P2-02 P1 closure incorrectly promoted P5 payload=%',v_other;
      end if;
    end if;
  end loop;

  -- Both components can now independently satisfy the closure evaluator.
  v_status:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P1');
  v_other:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P5');
  if not (v_status->>'ready')::boolean or not (v_other->>'ready')::boolean then
    raise exception 'P2-02 symmetric P1/P5 closure failed P1=% P5=%',v_status,v_other;
  end if;

  -- Reopen one governed P1 key skill: P1 must fail, P5 must remain ready.
  select k.skill_code into v_key
  from private.exam_prep_stage3_key_skills k
  where k.rule_version=v_rule and k.program_version_id=v_program and k.component_code='P1'
  order by k.skill_code limit 1;

  update private.exam_prep_skill_states
  set objective_level=2,derived_at=now()
  where user_id=v_user and program_version_id=v_program
    and component_code='P1' and skill_code=v_key and engine_version=v_engine;

  v_status:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P1');
  v_other:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P5');
  if (v_status->>'ready')::boolean
     or v_status->>'reason_code'<>'key_l3_incomplete'
     or not (v_other->>'ready')::boolean
  then
    raise exception 'P2-02 key L3/component firewall failed P1=% P5=%',v_status,v_other;
  end if;

  update private.exam_prep_skill_states
  set objective_level=3,derived_at=now()
  where user_id=v_user and program_version_id=v_program
    and component_code='P1' and skill_code=v_key and engine_version=v_engine;

  -- Reopen one non-key P5 skill to L1: P5 must fail L2, P1 must remain ready.
  select n.skill_code into v_key
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program and n.component_code='P5'
    and not exists(
      select 1 from private.exam_prep_stage3_key_skills k
      where k.rule_version=v_rule and k.program_version_id=v_program
        and k.component_code='P5' and k.skill_code=n.skill_code
    )
  order by n.sequence_no limit 1;

  update private.exam_prep_skill_states
  set objective_level=1,derived_at=now()
  where user_id=v_user and program_version_id=v_program
    and component_code='P5' and skill_code=v_key and engine_version=v_engine;

  v_status:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P5');
  v_other:=private.exam_prep_stage3_exit_status_v1(v_user,v_program,'P1');
  if (v_status->>'ready')::boolean
     or v_status->>'reason_code'<>'l2_incomplete'
     or not (v_other->>'ready')::boolean
  then
    raise exception 'P2-02 all-skills L2/component firewall failed P5=% P1=%',v_status,v_other;
  end if;

  -- Calendar/Product clocks cannot manufacture learner closure.
  if not exists(
    select 1 from private.exam_prep_product_roadmap_milestones
    where milestone_key='product_content_complete'
      and milestone_status='met'
      and can_force_learner_stage=false
      and can_raise_learner_mastery=false
      and can_label_learner_exam_ready=false
  ) then
    raise exception 'P2-02 Product Content-Complete / learner closure firewall missing';
  end if;

  raise notice 'P2-02 Stage 3 Syllabus Closure current-schema matrix: GREEN';
end
$$;

ROLLBACK;

\echo 'P2-02 Stage 3 Syllabus Closure matrix: GREEN'
