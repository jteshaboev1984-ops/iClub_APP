\set ON_ERROR_STOP on
\echo 'P1-03 Stage-4 Timed Consolidation evidence prototype matrix'

begin;

-- TEST-ONLY reader. It is intentionally created in pg_temp and rolled back.
-- It computes Stage-4 evidence facts but cannot award Stage 4 because the
-- trend and corrective-plan qualification policies are still governance-pending.
create or replace function pg_temp.stage4_evidence_status_v0(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component_code text
)
returns jsonb
language plpgsql
as $$
declare
  v_stage3 jsonb;
  v_engine text;
  v_total_comparable int:=0;
  v_distinct_series int:=0;
  v_max_series_count int:=0;
  v_series jsonb:='[]'::jsonb;
  v_pair_key text;
  v_latest_unattempted_share numeric;
  v_previous_unattempted_share numeric;
  v_unattempted_share_delta numeric;
  v_latest_elapsed_share numeric;
  v_previous_elapsed_share numeric;
  v_elapsed_share_delta numeric;
  v_denominator int:=0;
  v_l3_or_higher int:=0;
  v_below_l3 int:=0;
  v_linked_corrective int:=0;
  v_reason text;
begin
  if p_component_code not in ('P1','P5') then
    raise exception 'p103_stage4_prototype_bad_component';
  end if;

  v_stage3:=private.exam_prep_stage3_exit_status_v1(p_user_id,p_program_version_id,p_component_code);

  select engine_version into v_engine
  from private.exam_prep_state_engine_versions
  where status='active'
  order by created_at desc limit 1;

  with eligible as (
    select t.*
    from private.exam_prep_timed_attempt_results t
    join private.exam_prep_sessions s on s.id=t.session_id
    join private.exam_prep_assessments a on a.id=t.assessment_id
    where t.user_id=p_user_id
      and t.component_code=p_component_code
      and s.user_id=p_user_id
      and s.program_version_id=p_program_version_id
      and s.component_code=p_component_code
      and s.session_type='paper'
      and s.status='finalized'
      and t.attempt_kind='full_paper'
      and t.timing_rule='official_full'
      and t.comparison_scope='full'
      and t.strict_timing
      and a.status='published'
      and private.exam_prep_timed_score_comparable_v1(t.session_id)
  ), grouped as (
    select comparability_key,count(*)::int as attempt_count,max(finalized_at) as latest_at
    from eligible
    group by comparability_key
  )
  select
    (select count(*)::int from eligible),
    (select count(*)::int from grouped),
    coalesce((select max(attempt_count) from grouped),0),
    coalesce((select jsonb_agg(jsonb_build_object(
      'comparability_key',comparability_key,
      'attempt_count',attempt_count,
      'latest_at',latest_at
    ) order by latest_at,comparability_key) from grouped),'[]'::jsonb)
  into v_total_comparable,v_distinct_series,v_max_series_count,v_series;

  -- Pick one deterministic compatible series only for raw trend display:
  -- highest attempt count, then most recent series. No gate is derived from it.
  with eligible as (
    select t.*
    from private.exam_prep_timed_attempt_results t
    join private.exam_prep_sessions s on s.id=t.session_id
    join private.exam_prep_assessments a on a.id=t.assessment_id
    where t.user_id=p_user_id
      and t.component_code=p_component_code
      and s.user_id=p_user_id
      and s.program_version_id=p_program_version_id
      and s.component_code=p_component_code
      and s.session_type='paper'
      and s.status='finalized'
      and t.attempt_kind='full_paper'
      and t.timing_rule='official_full'
      and t.comparison_scope='full'
      and t.strict_timing
      and a.status='published'
      and private.exam_prep_timed_score_comparable_v1(t.session_id)
  ), grouped as (
    select comparability_key,count(*)::int as attempt_count,max(finalized_at) as latest_at
    from eligible group by comparability_key
  )
  select comparability_key into v_pair_key
  from grouped
  where attempt_count>=2
  order by attempt_count desc,latest_at desc,comparability_key
  limit 1;

  if v_pair_key is not null then
    with ranked as (
      select t.*,
             row_number() over(order by t.finalized_at desc,t.session_id) as rn
      from private.exam_prep_timed_attempt_results t
      join private.exam_prep_sessions s on s.id=t.session_id
      where t.user_id=p_user_id
        and t.component_code=p_component_code
        and s.program_version_id=p_program_version_id
        and s.component_code=p_component_code
        and s.session_type='paper'
        and s.status='finalized'
        and t.attempt_kind='full_paper'
        and t.timing_rule='official_full'
        and t.comparison_scope='full'
        and t.strict_timing
        and t.comparability_key=v_pair_key
        and private.exam_prep_timed_score_comparable_v1(t.session_id)
    )
    select
      max((unattempted_marks::numeric/nullif(marks_available,0))) filter(where rn=1),
      max((unattempted_marks::numeric/nullif(marks_available,0))) filter(where rn=2),
      max((server_elapsed_sec::numeric/nullif(time_limit_sec,0))) filter(where rn=1),
      max((server_elapsed_sec::numeric/nullif(time_limit_sec,0))) filter(where rn=2)
    into v_latest_unattempted_share,v_previous_unattempted_share,
         v_latest_elapsed_share,v_previous_elapsed_share
    from ranked where rn<=2;

    v_unattempted_share_delta:=v_latest_unattempted_share-v_previous_unattempted_share;
    v_elapsed_share_delta:=v_latest_elapsed_share-v_previous_elapsed_share;
  end if;

  select count(*)::int,
         count(*) filter(where coalesce(ss.objective_level,0)>=3)::int,
         count(*) filter(where coalesce(ss.objective_level,0)<3)::int
  into v_denominator,v_l3_or_higher,v_below_l3
  from private.exam_prep_syllabus_nodes n
  left join private.exam_prep_skill_states ss
    on ss.user_id=p_user_id
   and ss.program_version_id=p_program_version_id
   and ss.component_code=p_component_code
   and ss.skill_code=n.skill_code
   and ss.engine_version=v_engine
  where n.program_version_id=p_program_version_id
    and n.component_code=p_component_code;

  with below as (
    select n.skill_code
    from private.exam_prep_syllabus_nodes n
    left join private.exam_prep_skill_states ss
      on ss.user_id=p_user_id
     and ss.program_version_id=p_program_version_id
     and ss.component_code=p_component_code
     and ss.skill_code=n.skill_code
     and ss.engine_version=v_engine
    where n.program_version_id=p_program_version_id
      and n.component_code=p_component_code
      and coalesce(ss.objective_level,0)<3
  )
  select count(*)::int into v_linked_corrective
  from below b
  where exists (
    select 1
    from private.exam_prep_correction_cases c
    where c.user_id=p_user_id
      and c.component_code=p_component_code
      and c.skill_code=b.skill_code
      and c.status in ('open','remediating','retest_due','reopened')
      and (
        exists (
          select 1
          from private.exam_prep_weekly_plan_items wpi
          join private.exam_prep_weekly_plans wp on wp.id=wpi.plan_id
          where wp.user_id=p_user_id
            and wp.component_code=p_component_code
            and wp.status='active'
            and wpi.correction_case_id=c.id
            and wpi.skill_code=b.skill_code
            and wpi.status='pending'
            and wpi.item_type in ('correction','retest')
        )
        or exists (
          select 1
          from private.exam_prep_retest_events r
          where r.correction_case_id=c.id
            and r.user_id=p_user_id
            and r.component_code=p_component_code
            and r.skill_code=b.skill_code
            and r.status in ('scheduled','authorized')
        )
      )
  );

  if not coalesce((v_stage3->>'ready')::boolean,false) then
    v_reason:='stage3_exit_incomplete';
  elsif v_max_series_count<2 then
    v_reason:='comparable_full_attempts_incomplete';
  else
    -- Deliberate fail-closed stop. The normative plan has not supplied an
    -- approved trend predicate or corrective-plan qualification predicate.
    v_reason:='trend_policy_pending';
  end if;

  return jsonb_build_object(
    'component_code',p_component_code,
    'stage3_exit_ready',coalesce((v_stage3->>'ready')::boolean,false),
    'comparable_full_attempt_count_total',v_total_comparable,
    'comparable_series_count',v_distinct_series,
    'max_compatible_series_attempt_count',v_max_series_count,
    'comparable_series',v_series,
    'trend_pair_comparability_key',v_pair_key,
    'latest_unattempted_share',v_latest_unattempted_share,
    'previous_unattempted_share',v_previous_unattempted_share,
    'unattempted_share_delta',v_unattempted_share_delta,
    'latest_elapsed_share',v_latest_elapsed_share,
    'previous_elapsed_share',v_previous_elapsed_share,
    'elapsed_share_delta',v_elapsed_share_delta,
    'trend_policy_status','pending',
    'trend_gate_ready',false,
    'canonical_skill_count',v_denominator,
    'l3_or_higher_count',v_l3_or_higher,
    'below_l3_count',v_below_l3,
    'below_l3_with_raw_corrective_link_count',v_linked_corrective,
    'corrective_plan_policy_status','pending',
    'corrective_plan_gate_ready',false,
    'stage4_exit_ready',false,
    'reason_code',v_reason,
    'stage5_unlocked',false
  );
end;
$$;

create or replace function pg_temp.insert_p1_full_attempt_v0(
  p_user_id uuid,
  p_program_version_id bigint,
  p_assessment_id bigint,
  p_content_version_id bigint,
  p_assessment_version text,
  p_comparability_key text,
  p_finalized_at timestamptz,
  p_unattempted_marks int,
  p_elapsed_sec int,
  p_suffix text
)
returns uuid
language plpgsql
as $$
declare
  v_auth uuid;
  v_session uuid;
  v_items int;
begin
  select count(*)::int into v_items
  from private.exam_prep_assessment_items where assessment_id=p_assessment_id;

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason
  ) values(
    p_user_id,p_assessment_id,'P1','paper','issued',now()+interval '1 hour',
    'P1-03 Stage-4 prototype rollback-only full-paper fixture '||p_suffix
  ) returning id into v_auth;

  insert into private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,started_at,last_activity_at,
    finalized_at,finalize_idempotency_key,timing_contract
  ) values(
    v_auth,p_user_id,p_program_version_id,p_content_version_id,p_assessment_id,p_assessment_version,
    'P1','paper','finalized','p103-s4proto-session-'||p_suffix,v_items,p_finalized_at-interval '100 minutes',p_finalized_at,
    p_finalized_at,'p103-s4proto-final-'||p_suffix,
    jsonb_build_object('attempt_kind','full_paper','timing_rule','official_full','comparison_scope','full',
      'strict_timing',true,'marks_available',75,'time_limit_sec',6600,'comparability_key',p_comparability_key)
  ) returning id into v_session;

  insert into private.exam_prep_session_items(
    session_id,item_order,item_kind,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout,
    content_meta_id,question_snapshot_md5,item_version
  )
  select v_session,ai.item_order,'written',null,ai.written_task_id,ai.primary_skill_code,ai.reserve_role,ai.is_holdout,
         null,null,'written:'||wt.task_version
  from private.exam_prep_assessment_items ai
  join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
  where ai.assessment_id=p_assessment_id;

  insert into private.exam_prep_timed_attempt_results(
    session_id,user_id,component_code,assessment_id,attempt_kind,timing_rule,comparison_scope,comparability_key,
    strict_timing,marks_available,time_limit_sec,server_elapsed_sec,answered_items,unattempted_items,
    objective_marks_in_time,objective_marks_after_time,objective_lost_in_time_marks,objective_lost_after_time_marks,
    pending_review_in_time_marks,pending_review_after_time_marks,unattempted_marks,completion_reason,
    timing_comparable,base_score_comparable,finalized_at
  ) values(
    v_session,p_user_id,'P1',p_assessment_id,'full_paper','official_full','full',p_comparability_key,
    true,75,6600,p_elapsed_sec,v_items,case when p_unattempted_marks>0 then 1 else 0 end,
    0,0,0,0,greatest(0,75-p_unattempted_marks),0,p_unattempted_marks,'submitted',
    true,false,p_finalized_at
  );

  -- Close written-review comparability using all governed written mark maxima.
  -- Awarded marks are intentionally synthetic and are not used as a Stage-4 gate here.
  insert into private.exam_prep_timed_written_self_marks(
    session_id,item_order,user_id,marks_awarded,max_marks,was_in_time,idempotency_key,review_note
  )
  select v_session,ti.item_order,p_user_id,greatest(ti.max_marks-1,0),ti.max_marks,true,
         'p103-s4proto-self-'||p_suffix||'-'||lpad(ti.item_order::text,2,'0'),
         'Rollback-only Stage-4 evidence prototype fixture'
  from private.exam_prep_timed_assessment_items ti
  where ti.assessment_id=p_assessment_id;

  if not private.exam_prep_timed_score_comparable_v1(v_session) then
    raise exception 'P1-03 Stage-4 prototype fixture did not become finally comparable suffix=%',p_suffix;
  end if;

  return v_session;
end;
$$;

do $$
declare
  v_program bigint;
  v_engine text;
  v_rule text;
  v_user uuid := '00000000-0000-4000-8000-000000001052'::uuid;
  v_ass bigint;
  v_cv bigint;
  v_ass_version text;
  v_s1 uuid;
  v_s2 uuid;
  v_s3 uuid;
  v_case uuid;
  v_plan uuid;
  v_status jsonb;
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
    raise exception 'P1-03 Stage-4 prototype: baseline program/engine/rule missing';
  end if;

  -- CI-only Stage-3 governance fixture. Production remains pending/empty after rollback.
  update private.exam_prep_stage3_exit_rules
  set key_registry_status='approved'
  where rule_version=v_rule;
  insert into private.exam_prep_stage3_key_skills(
    rule_version,program_version_id,component_code,skill_code,governance_basis
  ) values(v_rule,v_program,'P1','P1-DIF-07','Rollback-only Stage-4 prototype Stage-3 prerequisite fixture.');

  insert into auth.users(id,email,role,aud)
  values(v_user,'p103-stage4-prototype@invalid.example','authenticated','authenticated');
  insert into public.users(id,first_name,last_name,language_code)
  values(v_user,'P103','Stage4Prototype','en');

  -- Every P1 skill is L3 except one non-key skill held at L2. This is valid Stage-3 closure
  -- after a full baseline, but Stage 4 must expose the L2 remediation obligation.
  insert into private.exam_prep_skill_states(
    user_id,program_version_id,component_code,skill_code,engine_version,objective_level,coverage_confirmed
  )
  select v_user,v_program,'P1',n.skill_code,v_engine,
         case when n.skill_code='P1-QUA-01' then 2 else 3 end,
         true
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program and n.component_code='P1';

  select a.id,a.content_version_id,a.assessment_version
  into v_ass,v_cv,v_ass_version
  from private.exam_prep_assessments a
  where a.assessment_key='p1_stage3_full_paper_01'
    and a.assessment_version='av1'
    and a.status='published';
  if v_ass is null then raise exception 'P1-03 Stage-4 prototype: governed P1 full paper missing'; end if;

  -- No paper: Stage 3 itself is incomplete.
  v_status:=pg_temp.stage4_evidence_status_v0(v_user,v_program,'P1');
  if v_status->>'reason_code'<>'stage3_exit_incomplete'
     or (v_status->>'stage4_exit_ready')::boolean then
    raise exception 'P1-03 Stage-4 prototype: no-baseline state wrong %',v_status::text;
  end if;

  -- First finally comparable baseline completes Stage 3, but Stage 4 still needs a second compatible full attempt.
  v_s1:=pg_temp.insert_p1_full_attempt_v0(
    v_user,v_program,v_ass,v_cv,v_ass_version,'p1-full-paper-01-v1',now()-interval '10 days',12,6500,'01'
  );
  v_status:=pg_temp.stage4_evidence_status_v0(v_user,v_program,'P1');
  if not (v_status->>'stage3_exit_ready')::boolean
     or v_status->>'reason_code'<>'comparable_full_attempts_incomplete'
     or (v_status->>'max_compatible_series_attempt_count')::int<>1
     or (v_status->>'below_l3_count')::int<>1
     or (v_status->>'below_l3_with_raw_corrective_link_count')::int<>0 then
    raise exception 'P1-03 Stage-4 prototype: one-attempt state wrong %',v_status::text;
  end if;

  -- Second compatible full attempt supplies the raw count and raw trend facts.
  v_s2:=pg_temp.insert_p1_full_attempt_v0(
    v_user,v_program,v_ass,v_cv,v_ass_version,'p1-full-paper-01-v1',now()-interval '4 days',6,6200,'02'
  );
  v_status:=pg_temp.stage4_evidence_status_v0(v_user,v_program,'P1');
  if v_status->>'reason_code'<>'trend_policy_pending'
     or (v_status->>'max_compatible_series_attempt_count')::int<>2
     or (v_status->>'comparable_series_count')::int<>1
     or (v_status->>'trend_gate_ready')::boolean
     or (v_status->>'corrective_plan_gate_ready')::boolean
     or (v_status->>'stage4_exit_ready')::boolean
     or (v_status->>'stage5_unlocked')::boolean
     or (v_status->>'unattempted_share_delta')::numeric>=0 then
    raise exception 'P1-03 Stage-4 prototype: two-attempt pending-policy state wrong %',v_status::text;
  end if;

  -- Existing correction + active weekly-plan linkage is exposed as a RAW signal only.
  insert into private.exam_prep_correction_cases(
    user_id,component_code,skill_code,status,engine_version,reason
  ) values(
    v_user,'P1','P1-QUA-01','open',v_engine,'{"source":"rollback_stage4_prototype"}'::jsonb
  ) returning id into v_case;

  insert into private.exam_prep_weekly_plans(
    user_id,program_version_id,component_code,active_week_no,plan_version,status,recovery_mode,policy_note
  ) values(
    v_user,v_program,'P1',25,1,'active','normal','Rollback-only Stage-4 corrective linkage prototype.'
  ) returning id into v_plan;

  insert into private.exam_prep_weekly_plan_items(
    plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,action_code,action_payload,status
  ) values(
    v_plan,1,'correction','P1-QUA-01',v_case,now()+interval '1 day','stage4_corrective_followup','{}'::jsonb,'pending'
  );

  v_status:=pg_temp.stage4_evidence_status_v0(v_user,v_program,'P1');
  if (v_status->>'below_l3_count')::int<>1
     or (v_status->>'below_l3_with_raw_corrective_link_count')::int<>1
     or v_status->>'corrective_plan_policy_status'<>'pending'
     or (v_status->>'corrective_plan_gate_ready')::boolean
     or (v_status->>'stage4_exit_ready')::boolean then
    raise exception 'P1-03 Stage-4 prototype: raw corrective linkage was treated incorrectly %',v_status::text;
  end if;

  -- An incompatible comparability key creates another series; it must not inflate the existing compatible-series count.
  v_s3:=pg_temp.insert_p1_full_attempt_v0(
    v_user,v_program,v_ass,v_cv,v_ass_version,'p1-full-paper-prototype-incompatible-v2',now()-interval '1 day',4,6100,'03'
  );
  v_status:=pg_temp.stage4_evidence_status_v0(v_user,v_program,'P1');
  if (v_status->>'comparable_full_attempt_count_total')::int<>3
     or (v_status->>'comparable_series_count')::int<>2
     or (v_status->>'max_compatible_series_attempt_count')::int<>2 then
    raise exception 'P1-03 Stage-4 prototype: incompatible series were merged %',v_status::text;
  end if;

  -- P1 evidence must never satisfy P5.
  v_status:=pg_temp.stage4_evidence_status_v0(v_user,v_program,'P5');
  if v_status->>'reason_code'<>'stage3_exit_incomplete'
     or (v_status->>'comparable_full_attempt_count_total')::int<>0
     or (v_status->>'stage4_exit_ready')::boolean then
    raise exception 'P1-03 Stage-4 prototype: P1 evidence leaked into P5 %',v_status::text;
  end if;

  if (select max_automatic_stage from private.exam_prep_operational_stage_rules where status='active')<>3 then
    raise exception 'P1-03 Stage-4 prototype: automatic Stage ceiling moved above 3';
  end if;

  raise notice 'P1-03 Stage-4 Timed Consolidation evidence prototype matrix: GREEN';
end $$;

rollback;

\echo 'P1-03 Stage-4 Timed Consolidation evidence prototype matrix: GREEN'
