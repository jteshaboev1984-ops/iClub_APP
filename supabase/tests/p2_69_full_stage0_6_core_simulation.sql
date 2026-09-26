\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p269.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-69 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

-- Complete a normal non-timed Exam Prep session through the public learner RPCs.
-- Correct answers are read only inside this isolated rollback-only engineering test.
create or replace function pg_temp.p269_complete_session_correct_v1(
  p_session_id uuid,
  p_prefix text
)
returns void
language plpgsql
as $$
declare
  v_item record;
  v_payload jsonb;
begin
  for v_item in
    select si.item_order,si.item_kind,si.question_id,q.correct_answer
    from private.exam_prep_session_items si
    left join public.questions q on q.id=si.question_id
    where si.session_id=p_session_id
    order by si.item_order
  loop
    if v_item.item_kind='question' then
      v_payload:=jsonb_build_object('answer',v_item.correct_answer);
    else
      v_payload:=jsonb_build_object(
        'artifact',jsonb_build_object(
          'working','P2-69 isolated synthetic working',
          'method','checked',
          'conclusion','synthetic validation artefact'
        )
      );
    end if;

    perform public.submit_exam_prep_response_safe_v1(
      p_session_id,
      v_item.item_order,
      v_payload,
      p_prefix||'-i'||lpad(v_item.item_order::text,3,'0'),
      1000,
      'en'
    );
  end loop;

  perform public.finalize_exam_prep_session_safe_v1(
    p_session_id,
    p_prefix||'-final'
  );
end;
$$;

-- Deliberately make one valid MCQ mistake in a diagnostic package.
-- A broad-screen miss must remain evidence/a focus signal without opening a correction case.
create or replace function pg_temp.p269_complete_diagnostic_one_wrong_v1(
  p_session_id uuid,
  p_prefix text
)
returns void
language plpgsql
as $diagnostic$
declare
  v_item record;
  v_payload jsonb;
  v_wrong_used boolean:=false;
  v_answer text;
begin
  for v_item in
    select si.item_order,si.item_kind,si.question_id,q.qtype,q.correct_answer
    from private.exam_prep_session_items si
    left join public.questions q on q.id=si.question_id
    where si.session_id=p_session_id
    order by si.item_order
  loop
    if v_item.item_kind='question' then
      v_answer:=v_item.correct_answer;
      if not v_wrong_used and v_item.qtype='mcq' then
        v_answer:=case upper(trim(v_item.correct_answer)) when 'A' then 'B' else 'A' end;
        v_wrong_used:=true;
      end if;
      v_payload:=jsonb_build_object('answer',v_answer);
    else
      v_payload:=jsonb_build_object(
        'artifact',jsonb_build_object(
          'working','P2-69 diagnostic signal working',
          'method','screening'
        )
      );
    end if;

    perform public.submit_exam_prep_response_safe_v1(
      p_session_id,
      v_item.item_order,
      v_payload,
      p_prefix||'-i'||lpad(v_item.item_order::text,3,'0'),
      1000,
      'en'
    );
  end loop;

  if not v_wrong_used then
    raise exception 'P2-69 diagnostic signal fixture had no MCQ item';
  end if;

  perform public.finalize_exam_prep_session_safe_v1(
    p_session_id,
    p_prefix||'-final'
  );
end;
$diagnostic$;

-- Deliberately make exactly one valid MCQ mistake, then finish the session.
-- This is used to prove the real correction -> remediation -> delayed retest path.
create or replace function pg_temp.p269_complete_learning_one_wrong_v1(
  p_session_id uuid,
  p_prefix text
)
returns void
language plpgsql
as $$
declare
  v_item record;
  v_payload jsonb;
  v_wrong_used boolean:=false;
  v_answer text;
begin
  for v_item in
    select si.item_order,si.item_kind,si.question_id,q.qtype,q.correct_answer
    from private.exam_prep_session_items si
    left join public.questions q on q.id=si.question_id
    where si.session_id=p_session_id
    order by si.item_order
  loop
    if v_item.item_kind='question' then
      v_answer:=v_item.correct_answer;
      if not v_wrong_used and v_item.qtype='mcq' then
        v_answer:=case upper(trim(v_item.correct_answer)) when 'A' then 'B' else 'A' end;
        v_wrong_used:=true;
      end if;
      v_payload:=jsonb_build_object('answer',v_answer);
    else
      v_payload:=jsonb_build_object(
        'artifact',jsonb_build_object(
          'working','P2-69 correction trigger working',
          'method','checked'
        )
      );
    end if;

    perform public.submit_exam_prep_response_safe_v1(
      p_session_id,
      v_item.item_order,
      v_payload,
      p_prefix||'-i'||lpad(v_item.item_order::text,3,'0'),
      1000,
      'en'
    );
  end loop;

  if not v_wrong_used then
    raise exception 'P2-69 correction fixture had no MCQ item';
  end if;

  perform public.finalize_exam_prep_session_safe_v1(
    p_session_id,
    p_prefix||'-final'
  );
end;
$$;

create or replace function pg_temp.p269_start_direct_assessment_v1(
  p_user_id uuid,
  p_assessment_id bigint,
  p_component text,
  p_purpose text,
  p_prefix text
)
returns uuid
language plpgsql
as $$
declare
  v_auth uuid;
  v_start jsonb;
begin
  perform set_config('request.jwt.claim.sub',p_user_id::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) values(
    p_user_id,p_assessment_id,p_component,p_purpose,'issued',clock_timestamp()+interval '1 hour',
    'P2-69 rollback-only governed evidence session',true
  ) returning id into v_auth;

  v_start:=public.start_exam_prep_session_safe_v1(
    v_auth,
    p_prefix||'-start'
  );

  return (v_start->>'session_id')::uuid;
end;
$$;

create or replace function pg_temp.p269_run_stage0_component_v1(
  p_user_id uuid,
  p_component text
)
returns integer
language plpgsql
as $$
declare
  v_program bigint;
  v_done boolean:=false;
  v_start jsonb;
  v_session uuid;
  v_loops int:=0;
begin
  select program_version_id into v_program
  from private.exam_prep_exam_profiles
  where user_id=p_user_id;

  perform set_config('request.jwt.claim.sub',p_user_id::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);

  loop
    perform private.rebuild_exam_prep_placement_v1(p_user_id,p_component);
    select coalesce(stage0_complete,false) into v_done
    from private.exam_prep_component_placements
    where user_id=p_user_id and program_version_id=v_program and component_code=p_component
    order by derived_at desc limit 1;

    exit when v_done;
    v_loops:=v_loops+1;
    if v_loops>30 then
      raise exception 'P2-69 Stage0 diagnostic loop did not converge component=%',p_component;
    end if;

    v_start:=public.start_exam_prep_next_diagnostic_safe_v1(
      p_component,
      'p269-diag-'||lower(p_component)||'-'||lpad(v_loops::text,3,'0')
    );
    v_session:=(v_start->>'session_id')::uuid;
    if v_loops=1 then
      perform pg_temp.p269_complete_diagnostic_one_wrong_v1(
        v_session,
        'p269-done-'||lower(p_component)||'-'||lpad(v_loops::text,3,'0')
      );
    else
      perform pg_temp.p269_complete_session_correct_v1(
        v_session,
        'p269-done-'||lower(p_component)||'-'||lpad(v_loops::text,3,'0')
      );
    end if;
  end loop;

  return v_loops;
end;
$$;

create or replace function pg_temp.p269_complete_learning_skill_v1(
  p_user_id uuid,
  p_component text,
  p_skill text,
  p_tag text
)
returns uuid
language plpgsql
as $$
declare
  v_ass bigint;
  v_session uuid;
begin
  select a.id into v_ass
  from private.exam_prep_assessments a
  where a.component_code=p_component
    and a.assessment_type='learning'
    and a.status='published'
    and exists(
      select 1 from private.exam_prep_assessment_items ai
      where ai.assessment_id=a.id and ai.primary_skill_code=p_skill
    )
    and not exists(
      select 1 from private.exam_prep_assessment_items ai
      where ai.assessment_id=a.id and ai.primary_skill_code<>p_skill
    )
  order by a.id
  limit 1;
  if v_ass is null then raise exception 'P2-69 learning assessment missing skill=%',p_skill; end if;

  v_session:=pg_temp.p269_start_direct_assessment_v1(
    p_user_id,v_ass,p_component,'learning','p269-learn-'||p_tag
  );
  perform pg_temp.p269_complete_session_correct_v1(v_session,'p269-learn-'||p_tag);
  return v_session;
end;
$$;

create or replace function pg_temp.p269_ensure_learning_first_n_v1(
  p_user_id uuid,
  p_program bigint,
  p_component text,
  p_target integer
)
returns void
language plpgsql
as $$
declare
  v_skill record;
  v_has_written boolean;
begin
  for v_skill in
    select n.skill_code,n.sequence_no
    from private.exam_prep_syllabus_nodes n
    where n.program_version_id=p_program and n.component_code=p_component
    order by n.sequence_no,n.skill_code
    limit p_target
  loop
    select exists(
      select 1
      from private.exam_prep_evidence_events e
      join private.exam_prep_sessions s on s.id=e.session_id and s.status='finalized'
      join private.exam_prep_session_authorizations sa on sa.id=s.authorization_id and sa.academic_credit
      where e.user_id=p_user_id and e.component_code=p_component and e.skill_code=v_skill.skill_code
        and e.evidence_type='written'
    ) into v_has_written;

    if not v_has_written then
      perform pg_temp.p269_complete_learning_skill_v1(
        p_user_id,p_component,v_skill.skill_code,
        lower(p_component)||'-'||lpad(v_skill.sequence_no::text,3,'0')
      );
    end if;
  end loop;
end;
$$;

create or replace function pg_temp.p269_complete_selected_mixed_v1(
  p_user_id uuid,
  p_program bigint,
  p_component text
)
returns integer
language plpgsql
as $$
declare
  v_ass record;
  v_session uuid;
  v_count int:=0;
begin
  for v_ass in
    with one_per_skill as (
      select distinct on (ai.primary_skill_code)
        ai.primary_skill_code,a.id as assessment_id
      from private.exam_prep_assessments a
      join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
      join private.exam_prep_syllabus_nodes n
        on n.program_version_id=p_program
       and n.component_code=p_component
       and n.skill_code=ai.primary_skill_code
      where a.component_code=p_component
        and a.assessment_type='mixed'
        and a.status='published'
        and private.exam_prep_mixed_mastery_assessment_qualifies_v1(a.id,p_component)
      order by ai.primary_skill_code,a.id
    )
    select distinct assessment_id from one_per_skill order by assessment_id
  loop
    v_count:=v_count+1;
    v_session:=pg_temp.p269_start_direct_assessment_v1(
      p_user_id,v_ass.assessment_id,p_component,'mixed',
      'p269-mix-'||lower(p_component)||'-'||lpad(v_count::text,3,'0')
    );
    perform pg_temp.p269_complete_session_correct_v1(
      v_session,'p269-mix-'||lower(p_component)||'-'||lpad(v_count::text,3,'0')
    );
  end loop;
  return v_count;
end;
$$;

create or replace function pg_temp.p269_complete_retests_all_skills_v1(
  p_user_id uuid,
  p_program bigint,
  p_component text
)
returns integer
language plpgsql
as $$
declare
  v_skill record;
  v_ass bigint;
  v_session uuid;
  v_count int:=0;
begin
  for v_skill in
    select n.skill_code,n.sequence_no
    from private.exam_prep_syllabus_nodes n
    where n.program_version_id=p_program and n.component_code=p_component
    order by n.sequence_no,n.skill_code
  loop
    select a.id into v_ass
    from private.exam_prep_assessments a
    where a.component_code=p_component
      and a.assessment_type='retest'
      and a.status='published'
      and exists(
        select 1 from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id and ai.primary_skill_code=v_skill.skill_code
      )
    order by a.id
    limit 1;
    if v_ass is null then raise exception 'P2-69 retest assessment missing skill=%',v_skill.skill_code; end if;

    v_count:=v_count+1;
    v_session:=pg_temp.p269_start_direct_assessment_v1(
      p_user_id,v_ass,p_component,'retest',
      'p269-retest-'||lower(p_component)||'-'||lpad(v_skill.sequence_no::text,3,'0')
    );
    perform pg_temp.p269_complete_session_correct_v1(
      v_session,'p269-retest-'||lower(p_component)||'-'||lpad(v_skill.sequence_no::text,3,'0')
    );
  end loop;
  return v_count;
end;
$$;

-- Strict timed/paper authorization and session creation use the real public RPC.
-- The deterministic score row is then filled by the isolated harness so P2-69
-- can focus on the Stage engine. P2-71 separately attacks timed failure paths.
create or replace function pg_temp.p269_complete_timed_assessment_v1(
  p_user_id uuid,
  p_assessment_id bigint,
  p_tag text
)
returns uuid
language plpgsql
as $$
declare
  v_auth jsonb;
  v_start jsonb;
  v_session uuid;
  v_component text;
  v_kind text;
  v_rule text;
  v_scope text;
  v_key text;
  v_strict boolean;
  v_marks int;
  v_time int;
  v_items int;
  v_virtual timestamptz;
begin
  perform set_config('request.jwt.claim.sub',p_user_id::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);

  v_auth:=public.authorize_exam_prep_timed_safe_v1(p_assessment_id);
  v_start:=public.start_exam_prep_session_safe_v1(
    (v_auth->>'authorization_id')::uuid,
    'p269-timed-'||p_tag||'-start'
  );
  v_session:=(v_start->>'session_id')::uuid;

  select a.component_code,tc.attempt_kind,tc.timing_rule,tc.comparison_scope,
         tc.comparability_key,tc.strict_timing,tc.marks_available,
         coalesce(nullif(s.timing_contract->>'time_limit_sec','')::int,tc.fixed_time_limit_sec),
         s.total_items
  into v_component,v_kind,v_rule,v_scope,v_key,v_strict,v_marks,v_time,v_items
  from private.exam_prep_assessments a
  join private.exam_prep_timed_assessment_contracts tc on tc.assessment_id=a.id and tc.status='published'
  join private.exam_prep_sessions s on s.id=v_session
  where a.id=p_assessment_id;

  if v_component is null or v_time is null or v_time<=0 then
    raise exception 'P2-69 timed contract snapshot missing assessment=%',p_assessment_id;
  end if;

  v_virtual:=private.exam_prep_effective_academic_now_v1(p_user_id);

  update private.exam_prep_sessions
  set status='finalized',finalized_at=clock_timestamp(),last_activity_at=clock_timestamp(),
      finalize_idempotency_key='p269-timed-'||p_tag||'-final'
  where id=v_session;

  insert into private.exam_prep_timed_attempt_results(
    session_id,user_id,component_code,assessment_id,attempt_kind,timing_rule,comparison_scope,comparability_key,
    strict_timing,marks_available,time_limit_sec,server_elapsed_sec,answered_items,unattempted_items,
    objective_marks_in_time,objective_marks_after_time,objective_lost_in_time_marks,objective_lost_after_time_marks,
    pending_review_in_time_marks,pending_review_after_time_marks,unattempted_marks,completion_reason,
    timing_comparable,base_score_comparable,finalized_at
  ) values(
    v_session,p_user_id,v_component,p_assessment_id,v_kind,v_rule,v_scope,v_key,
    v_strict,v_marks,v_time,greatest(1,least(v_time-1,round(v_time*0.85)::int)),v_items,0,
    v_marks,0,0,0,0,0,0,'submitted',true,true,v_virtual
  );

  if not private.exam_prep_timed_score_comparable_v1(v_session) then
    raise exception 'P2-69 timed fixture was not comparable assessment=% session=%',p_assessment_id,v_session;
  end if;

  return v_session;
end;
$$;

create or replace function pg_temp.p269_advance_days_v1(
  p_run_id text,
  p_days integer,
  p_reason text
)
returns timestamptz
language plpgsql
as $$
declare
  v_left int:=p_days;
  v_step int;
  v_clock jsonb;
  v_now timestamptz;
begin
  if p_days<0 then raise exception 'P2-69 negative virtual advance'; end if;
  select virtual_now into v_now from private.exam_prep_synthetic_run_clocks where run_id=p_run_id;
  while v_left>0 loop
    v_step:=least(v_left,14);
    v_clock:=private.advance_exam_prep_synthetic_clock_v1(
      p_run_id,v_now,(v_step::bigint*86400),p_reason||' +'||v_step::text||'d'
    );
    v_now:=(v_clock->>'virtual_now')::timestamptz;
    v_left:=v_left-v_step;
  end loop;
  return v_now;
end;
$$;

create or replace function pg_temp.p269_assert_stage_v1(
  p_user_id uuid,
  p_program bigint,
  p_component text,
  p_expected integer,
  p_label text
)
returns void
language plpgsql
as $$
declare v_stage int;
begin
  perform private.rebuild_exam_prep_state_v1(p_user_id,p_component);
  select operational_stage into v_stage
  from private.exam_prep_stage_states
  where user_id=p_user_id and program_version_id=p_program
    and component_code=p_component and engine_version='objective_state_v1';
  if v_stage is distinct from p_expected then
    raise exception 'P2-69 % expected stage % got % component=%',p_label,p_expected,v_stage,p_component;
  end if;
end;
$$;

DO $$
DECLARE
  v_run text:='SV-P269CI-RUN-0001';
  v_uid uuid;
  v_program bigint;
  v_clock jsonb;
  v_week smallint;
  v_p1_diag int;
  v_p5_diag int;
  v_p1_screen int;
  v_p5_screen int;
  v_plan jsonb;
  v_plan_id uuid;
  v_priority smallint;
  v_auth jsonb;
  v_session uuid;
  v_corr_skill text;
  v_signal_skill text;
  v_corr_ass bigint;
  v_case uuid;
  v_retest jsonb;
  v_mixed_p1 int;
  v_mixed_p5 int;
  v_retests_p1 int;
  v_retests_p5 int;
  v_p1_paper1 bigint;
  v_p1_paper2 bigint;
  v_p1_paper3 bigint;
  v_p5_paper1 bigint;
  v_p5_paper2 bigint;
  v_p5_paper3 bigint;
  v_ass bigint;
  v_status jsonb;
  v_inventory jsonb;
  v_complete jsonb;
  v_cleanup jsonb;
  v_legacy_before jsonb;
  v_beta_before jsonb;
  v_users_before bigint;
  v_l3_p1 int;
  v_l3_p5 int;
  v_stage_p1 int;
  v_stage_p5 int;
BEGIN
  select count(*) into v_users_before from public.users;
  select jsonb_build_object(
    'practice_attempts',(select count(*) from public.practice_attempts),
    'practice_answers',(select count(*) from public.practice_answers),
    'tour_attempts',(select count(*) from public.tour_attempts),
    'tour_answers',(select count(*) from public.tour_answers),
    'certificates',(select count(*) from public.certificates)
  ) into v_legacy_before;
  select jsonb_build_object(
    'members',(select count(*) from private.exam_prep_beta_members),
    'consents',(select count(*) from private.exam_prep_beta_consents),
    'weekly_reviews',(select count(*) from private.exam_prep_beta_weekly_reviews)
  ) into v_beta_before;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_program is null then raise exception 'P2-69 canonical program missing'; end if;

  if (select count(*) from private.exam_prep_syllabus_nodes where program_version_id=v_program and component_code='P1')<>45
     or (select count(*) from private.exam_prep_syllabus_nodes where program_version_id=v_program and component_code='P5')<>36 then
    raise exception 'P2-69 canonical 45/36 denominator drift';
  end if;

  perform private.register_exam_prep_canonical_synthetic_run_v2(
    v_run,'p2_67_canonical_v2_0','5a52e40b1c8c732f4cd498595f1fce2d0ced4242',
    'p2-69',26901,'core','p2-69-full-stage-run'
  );
  v_uid:=private.create_exam_prep_synthetic_identity_v1(
    v_run,'learner','SVF-P269-LEARNER-01','p2-69-identity-proof',
    'Dedicated full Stage 0-6 Core learner.','en'
  );
  perform private.transition_exam_prep_synthetic_validation_run_v1(
    v_run,'registered','running',null,null,jsonb_build_object('p2_69','stage0-6-start')
  );
  v_clock:=private.initialize_exam_prep_synthetic_clock_v1(v_run,'p2-69-clock-init');

  insert into private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) values(v_uid,'active',true,false,false,null,clock_timestamp()-interval '1 minute');

  perform set_config('request.jwt.claim.sub',v_uid::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);

  perform public.save_exam_prep_exam_profile_v2('CI_P269_STAGE06','A',12,6);

  -- Stage 0: real profile + real diagnostic session RPCs, P1/P5 independently.
  v_p1_diag:=pg_temp.p269_run_stage0_component_v1(v_uid,'P1');
  v_p5_diag:=pg_temp.p269_run_stage0_component_v1(v_uid,'P5');
  if v_p1_diag<1 or v_p5_diag<1 then raise exception 'P2-69 Stage0 did not execute both component diagnostics'; end if;

  perform private.rebuild_exam_prep_placement_v1(v_uid,null);
  select screening_answered_items into v_p1_screen
  from private.exam_prep_component_placements
  where user_id=v_uid and program_version_id=v_program and component_code='P1'
  order by derived_at desc limit 1;
  select screening_answered_items into v_p5_screen
  from private.exam_prep_component_placements
  where user_id=v_uid and program_version_id=v_program and component_code='P5'
  order by derived_at desc limit 1;
  if v_p1_screen<>24 or v_p5_screen<>15 then
    raise exception 'P2-69 Stage0 exact screening target mismatch P1=%/24 P5=%/15',v_p1_screen,v_p5_screen;
  end if;

  perform private.rebuild_exam_prep_state_v1(v_uid,null);
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P1',1,'after Stage0 P1');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',1,'after Stage0 P5');

  if exists(
    select 1 from private.exam_prep_correction_cases
    where user_id=v_uid and status in ('open','remediating','retest_due','reopened')
  ) then
    raise exception 'P2-69 broad diagnostic miss incorrectly opened a correction case';
  end if;
  if not exists(
    select 1 from private.exam_prep_evidence_events e
    join private.exam_prep_sessions s on s.id=e.session_id and s.user_id=v_uid
    where e.user_id=v_uid
      and s.session_type='diagnostic'
      and s.status='finalized'
      and e.verification_status='app_verified'
      and e.is_correct is false
  ) then
    raise exception 'P2-69 diagnostic miss evidence was not preserved';
  end if;
  if coalesce((private.exam_prep_correction_queue_payload_v1(v_uid,'P1')->>'signal_count')::int,0)<1
     or coalesce((private.exam_prep_correction_queue_payload_v1(v_uid,'P5')->>'signal_count')::int,0)<1 then
    raise exception 'P2-69 diagnostic misses were not surfaced as confirmation signals';
  end if;

  -- One P1 screening signal is confirmed on the first unseen governed learning pack.
  -- P5 intentionally remains unresolved to prove component isolation later.
  select x.value->>'skill_code' into v_signal_skill
  from jsonb_array_elements(
    private.exam_prep_correction_queue_payload_v1(v_uid,'P1')->'focus_cases'
  ) x
  where x.value->>'focus_kind'='screening_signal'
    and private.exam_prep_skill_runway_ready_for_week_v1(
      v_program,'P1',x.value->>'skill_code',private.exam_prep_effective_active_week_v1(v_uid)
    )
  order by (x.value->>'downstream_dependency_count')::int desc nulls last,
           x.value->>'skill_code'
  limit 1;
  if v_signal_skill is null then
    raise exception 'P2-69 no actionable P1 screening signal in current governed runway';
  end if;

  v_auth:=public.authorize_exam_prep_signal_confirmation_safe_v1('P1',v_signal_skill);
  if v_auth->>'status'<>'authorized'
     or coalesce((v_auth->>'fresh_questions')::boolean,false) is not true
     or coalesce((v_auth->>'uses_retest_reserve')::boolean,true) is not false then
    raise exception 'P2-69 signal confirmation authorization invalid: %',v_auth;
  end if;
  v_session:=(public.start_exam_prep_session_safe_v1(
    (v_auth->>'authorization_id')::uuid,
    'p269-signal-confirm-p1-start'
  )->>'session_id')::uuid;
  perform pg_temp.p269_complete_session_correct_v1(v_session,'p269-signal-confirm-p1');

  if coalesce((private.exam_prep_correction_queue_payload_v1(v_uid,'P1')->>'signal_count')::int,-1)<>0 then
    raise exception 'P2-69 successful P1 signal confirmation did not clear the screening signal';
  end if;
  if exists(
    select 1 from private.exam_prep_correction_cases
    where user_id=v_uid and component_code='P1' and skill_code=v_signal_skill
      and status in ('open','remediating','retest_due','reopened')
  ) then
    raise exception 'P2-69 successful screening confirmation incorrectly opened correction';
  end if;

  v_auth:=public.authorize_exam_prep_signal_confirmation_safe_v1('P1',v_signal_skill);
  if v_auth->>'status'<>'already_confirmed' then
    raise exception 'P2-69 confirmed signal was re-authorized instead of staying closed: %',v_auth;
  end if;
  if coalesce((private.exam_prep_correction_queue_payload_v1(v_uid,'P5')->>'signal_count')::int,0)<1 then
    raise exception 'P2-69 P1 confirmation leaked into independent P5 screening signal';
  end if;

  -- Weekly plan: execute one real Core learning action in each component.
  foreach v_corr_skill in array array['P1','P5'] loop
    perform set_config('request.jwt.claim.sub',v_uid::text,true);
    v_plan:=public.generate_exam_prep_weekly_plan_safe_v3(v_corr_skill);
    v_plan_id:=(v_plan->>'plan_id')::uuid;
    select priority_order into v_priority
    from private.exam_prep_weekly_plan_items
    where plan_id=v_plan_id and item_type='learning' and status='pending'
    order by priority_order limit 1;
    if v_priority is null then raise exception 'P2-69 weekly plan had no learning action component=% payload=%',v_corr_skill,v_plan; end if;
    v_auth:=public.authorize_exam_prep_plan_item_safe_v1(v_plan_id,v_priority);
    v_session:=(public.start_exam_prep_session_safe_v1(
      (v_auth->>'authorization_id')::uuid,
      'p269-plan-'||lower(v_corr_skill)||'-start'
    )->>'session_id')::uuid;
    perform pg_temp.p269_complete_session_correct_v1(v_session,'p269-plan-'||lower(v_corr_skill));
  end loop;

  -- Reach the Stage-2 evidence floor independently: 7/45 P1 and 6/36 P5 at L2.
  perform pg_temp.p269_ensure_learning_first_n_v1(v_uid,v_program,'P1',7);
  perform pg_temp.p269_ensure_learning_first_n_v1(v_uid,v_program,'P5',6);
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P1',2,'15 percent P1');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',2,'15 percent P5');

  -- Moving four weeks forward must not change Stage without new evidence.
  perform pg_temp.p269_advance_days_v1(v_run,28,'P2-69 calendar-only Stage2 hold');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P1',2,'calendar-only P1 hold');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',2,'calendar-only P5 hold');
  v_week:=private.exam_prep_effective_active_week_v1(v_uid);
  if v_week<5 then raise exception 'P2-69 virtual active week did not advance expected>=5 got=%',v_week; end if;

  -- One genuine error -> correction -> remediation -> delayed fresh retest.
  select n.skill_code into v_corr_skill
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program and n.component_code='P1'
  order by n.sequence_no,n.skill_code offset 7 limit 1;
  select a.id into v_corr_ass
  from private.exam_prep_assessments a
  where a.component_code='P1' and a.assessment_type='learning' and a.status='published'
    and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=v_corr_skill)
    and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>v_corr_skill)
  order by a.id limit 1;
  if v_corr_ass is null then raise exception 'P2-69 correction learning assessment missing'; end if;

  v_session:=pg_temp.p269_start_direct_assessment_v1(v_uid,v_corr_ass,'P1','learning','p269-corr-wrong');
  perform pg_temp.p269_complete_learning_one_wrong_v1(v_session,'p269-corr-wrong');
  select id into v_case
  from private.exam_prep_correction_cases
  where user_id=v_uid and component_code='P1' and skill_code=v_corr_skill
    and status in ('open','remediating','retest_due','reopened')
  order by opened_at desc limit 1;
  if v_case is null then raise exception 'P2-69 wrong evidence did not open correction'; end if;

  v_auth:=public.authorize_exam_prep_correction_safe_v1(v_case);
  v_session:=(public.start_exam_prep_session_safe_v1(
    (v_auth->>'authorization_id')::uuid,'p269-corr-remediate-start'
  )->>'session_id')::uuid;
  perform pg_temp.p269_complete_session_correct_v1(v_session,'p269-corr-remediate');

  begin
    perform public.authorize_exam_prep_retest_safe_v1(v_case);
    raise exception 'P2-69 delayed correction retest was authorized too early';
  exception when others then
    if SQLERRM<>'exam_prep_retest_too_early' then raise; end if;
  end;

  perform pg_temp.p269_advance_days_v1(v_run,7,'P2-69 correction delayed retest wait');
  v_retest:=public.authorize_exam_prep_retest_safe_v1(v_case);
  v_session:=(public.start_exam_prep_session_safe_v1(
    (v_retest->>'authorization_id')::uuid,'p269-corr-retest-start'
  )->>'session_id')::uuid;
  perform pg_temp.p269_complete_session_correct_v1(v_session,'p269-corr-retest');
  if (select status from private.exam_prep_correction_cases where id=v_case)<>'resolved' then
    raise exception 'P2-69 governed correction cycle did not resolve';
  end if;

  -- P1 advances to Stage 3 while P5 intentionally stays Stage 2.
  perform pg_temp.p269_ensure_learning_first_n_v1(v_uid,v_program,'P1',36);
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P1',3,'80 percent P1 after successful screening confirmation');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',2,'P5 must remain independent');

  perform pg_temp.p269_ensure_learning_first_n_v1(v_uid,v_program,'P5',30);
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',3,'80 percent P5 with one unresolved screening signal');

  -- Full first coverage/L2 for all 81 skills. Stage 3 remains because L3/full-paper closure evidence is incomplete.
  perform pg_temp.p269_ensure_learning_first_n_v1(v_uid,v_program,'P1',45);
  perform pg_temp.p269_ensure_learning_first_n_v1(v_uid,v_program,'P5',36);
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P1',3,'100 percent L2 P1');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',3,'100 percent L2 P5');

  -- Real governed mixed assessments supply transfer evidence. Retest is still missing.
  v_mixed_p1:=pg_temp.p269_complete_selected_mixed_v1(v_uid,v_program,'P1');
  v_mixed_p5:=pg_temp.p269_complete_selected_mixed_v1(v_uid,v_program,'P5');
  if v_mixed_p1<1 or v_mixed_p5<1 then raise exception 'P2-69 mixed transfer fixtures missing'; end if;
  perform private.rebuild_exam_prep_state_v1(v_uid,null);

  select l3_count into v_l3_p1 from private.exam_prep_stage_states
  where user_id=v_uid and program_version_id=v_program and component_code='P1' and engine_version='objective_state_v1';
  select l3_count into v_l3_p5 from private.exam_prep_stage_states
  where user_id=v_uid and program_version_id=v_program and component_code='P5' and engine_version='objective_state_v1';
  if v_l3_p1>=45 or v_l3_p5>=36 then raise exception 'P2-69 all skills reached L3 before delayed retest'; end if;

  -- Time passing alone still cannot close the missing retest evidence.
  perform pg_temp.p269_advance_days_v1(v_run,7,'P2-69 all-skill delayed retest wait');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P1',3,'time-only pre-retest P1');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',3,'time-only pre-retest P5');

  v_retests_p1:=pg_temp.p269_complete_retests_all_skills_v1(v_uid,v_program,'P1');
  v_retests_p5:=pg_temp.p269_complete_retests_all_skills_v1(v_uid,v_program,'P5');
  if v_retests_p1<>45 or v_retests_p5<>36 then
    raise exception 'P2-69 retest count mismatch P1=% P5=%',v_retests_p1,v_retests_p5;
  end if;

  perform private.rebuild_exam_prep_state_v1(v_uid,null);
  select l3_count,operational_stage into v_l3_p1,v_stage_p1
  from private.exam_prep_stage_states
  where user_id=v_uid and program_version_id=v_program and component_code='P1' and engine_version='objective_state_v1';
  select l3_count,operational_stage into v_l3_p5,v_stage_p5
  from private.exam_prep_stage_states
  where user_id=v_uid and program_version_id=v_program and component_code='P5' and engine_version='objective_state_v1';
  if v_l3_p1<>45 or v_l3_p5<>36 or v_stage_p1<>3 or v_stage_p5<>3 then
    raise exception 'P2-69 Stage3 closure pre-paper mismatch P1 L3/stage=%/% P5=%/%',v_l3_p1,v_stage_p1,v_l3_p5,v_stage_p5;
  end if;

  select id into v_p1_paper1 from private.exam_prep_assessments where assessment_key='p1_stage3_full_paper_01' and status='published';
  select id into v_p1_paper2 from private.exam_prep_assessments where assessment_key='p1_stage4_full_paper_02' and status='published';
  select id into v_p1_paper3 from private.exam_prep_assessments where assessment_key='p1_stage4_full_paper_03' and status='published';
  select id into v_p5_paper1 from private.exam_prep_assessments where assessment_key='p5_stage3_full_paper_01' and status='published';
  select id into v_p5_paper2 from private.exam_prep_assessments where assessment_key='p5_stage4_full_paper_02' and status='published';
  select id into v_p5_paper3 from private.exam_prep_assessments where assessment_key='p5_stage4_full_paper_03' and status='published';
  if v_p1_paper1 is null or v_p1_paper2 is null or v_p1_paper3 is null
     or v_p5_paper1 is null or v_p5_paper2 is null or v_p5_paper3 is null then
    raise exception 'P2-69 governed full-paper assessments missing';
  end if;

  -- First comparable full baseline unlocks Stage 4 separately for P1/P5.
  perform pg_temp.p269_complete_timed_assessment_v1(v_uid,v_p1_paper1,'p1-paper01');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P1',4,'first P1 full baseline');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',3,'P5 waits for own full baseline');
  perform pg_temp.p269_complete_timed_assessment_v1(v_uid,v_p5_paper1,'p5-paper01');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',4,'first P5 full baseline');

  -- Stage 4 requires the majority timed-section scope (2/2 here) plus a second compatible full attempt.
  for v_ass in
    select a.id
    from private.exam_prep_assessments a
    join private.exam_prep_stage4_timed_section_scope sc on sc.assessment_id=a.id and sc.required
    join private.exam_prep_stage4_exit_rules r on r.rule_version=sc.rule_version and r.status='active'
    where a.component_code='P1' and a.status='published'
    order by a.id
  loop
    perform pg_temp.p269_complete_timed_assessment_v1(v_uid,v_ass,'p1-sec-'||v_ass::text);
  end loop;
  for v_ass in
    select a.id
    from private.exam_prep_assessments a
    join private.exam_prep_stage4_timed_section_scope sc on sc.assessment_id=a.id and sc.required
    join private.exam_prep_stage4_exit_rules r on r.rule_version=sc.rule_version and r.status='active'
    where a.component_code='P5' and a.status='published'
    order by a.id
  loop
    perform pg_temp.p269_complete_timed_assessment_v1(v_uid,v_ass,'p5-sec-'||v_ass::text);
  end loop;

  perform pg_temp.p269_complete_timed_assessment_v1(v_uid,v_p1_paper2,'p1-paper02');
  perform pg_temp.p269_complete_timed_assessment_v1(v_uid,v_p5_paper2,'p5-paper02');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P1',5,'two comparable P1 papers');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',5,'two comparable P5 papers');

  -- Synthetic target thresholds exist only inside this rollback transaction.
  insert into private.exam_prep_stage5_thresholds(
    threshold_version,program_version_id,component_code,exam_series_key,target_grade,
    min_in_time_score_pct,max_unattempted_share,max_after_time_share,status,source_ref,policy_note,approved_at
  ) values
    ('p269_ci_p1_v1',v_program,'P1','CI_P269_STAGE06','A',80,0,0,'approved',
     'P2-69 rollback-only synthetic threshold','Engineering fixture only; not a Cambridge threshold.',clock_timestamp()),
    ('p269_ci_p5_v1',v_program,'P5','CI_P269_STAGE06','A',80,0,0,'approved',
     'P2-69 rollback-only synthetic threshold','Engineering fixture only; not a Cambridge threshold.',clock_timestamp());

  -- Simulate the rest of the academic year. Calendar movement alone must keep Stage 5.
  perform pg_temp.p269_advance_days_v1(v_run,182,'P2-69 accelerate to final calibration window');
  v_week:=private.exam_prep_effective_active_week_v1(v_uid);
  if v_week<33 or v_week>36 then raise exception 'P2-69 expected final-window active week 33-36 got=%',v_week; end if;
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P1',5,'calendar-only Stage5 P1 hold');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',5,'calendar-only Stage5 P5 hold');

  -- Third comparable full paper + stable L3/corrections closed => App Readiness => Stage 6.
  perform pg_temp.p269_complete_timed_assessment_v1(v_uid,v_p1_paper3,'p1-paper03');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P1',6,'third P1 paper readiness');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',5,'P5 cannot inherit P1 readiness');
  perform pg_temp.p269_complete_timed_assessment_v1(v_uid,v_p5_paper3,'p5-paper03');
  perform pg_temp.p269_assert_stage_v1(v_uid,v_program,'P5',6,'third P5 paper readiness');

  v_status:=private.exam_prep_stage5_readiness_status_v1(v_uid,v_program,'P1');
  if coalesce((v_status->>'ready')::boolean,false) is not true
     or (v_status->>'last_three_count')::int<>3
     or (v_status->>'below_l3_count')::int<>0
     or (v_status->>'unresolved_correction_case_count')::int<>0 then
    raise exception 'P2-69 final P1 readiness invalid: %',v_status;
  end if;
  v_status:=private.exam_prep_stage5_readiness_status_v1(v_uid,v_program,'P5');
  if coalesce((v_status->>'ready')::boolean,false) is not true
     or (v_status->>'last_three_count')::int<>3
     or (v_status->>'below_l3_count')::int<>0
     or (v_status->>'unresolved_correction_case_count')::int<>0 then
    raise exception 'P2-69 final P5 readiness invalid: %',v_status;
  end if;

  if exists(select 1 from private.exam_prep_beta_members where user_id=v_uid)
     or exists(select 1 from private.exam_prep_beta_consents where user_id=v_uid)
     or exists(select 1 from private.exam_prep_beta_weekly_reviews where reviewer_user_id=v_uid) then
    raise exception 'P2-69 synthetic learner contaminated real beta controls';
  end if;

  v_inventory:=private.exam_prep_synthetic_run_inventory_v1(v_run);
  if coalesce((v_inventory->>'clean_boundary')::boolean,false) is not true
     or coalesce((v_inventory#>>'{legacy_refs,total_refs}')::bigint,0)<>0 then
    raise exception 'P2-69 synthetic boundary/legacy check failed: %',v_inventory;
  end if;

  v_complete:=private.complete_exam_prep_synthetic_run_v1(
    v_run,1,jsonb_build_object(
      'p2_69','stage0-6-green',
      'p1_stage',6,'p5_stage',6,
      'p1_skills',45,'p5_skills',36,
      'active_week',v_week
    )
  );
  if v_complete->>'run_status'<>'completed' then raise exception 'P2-69 run completion failed: %',v_complete; end if;

  v_cleanup:=private.cleanup_exam_prep_synthetic_run_v1(
    v_run,1,'p2-69-cleanup-proof','I_CONFIRM_SYNTHETIC_RUN_CLEANUP_V1'
  );
  if v_cleanup->>'cleanup_status'<>'clean' or coalesce((v_cleanup->>'deleted_identity_count')::int,-1)<>1 then
    raise exception 'P2-69 cleanup failed: %',v_cleanup;
  end if;

  if exists(select 1 from private.exam_prep_synthetic_identities where run_id=v_run)
     or exists(select 1 from public.users where id=v_uid)
     or exists(select 1 from auth.users where id=v_uid) then
    raise exception 'P2-69 cleanup left synthetic learner residue';
  end if;

  if v_legacy_before is distinct from jsonb_build_object(
    'practice_attempts',(select count(*) from public.practice_attempts),
    'practice_answers',(select count(*) from public.practice_answers),
    'tour_attempts',(select count(*) from public.tour_attempts),
    'tour_answers',(select count(*) from public.tour_answers),
    'certificates',(select count(*) from public.certificates)
  ) then
    raise exception 'P2-69 changed legacy Practice/Tour/certificate state';
  end if;

  if v_beta_before is distinct from jsonb_build_object(
    'members',(select count(*) from private.exam_prep_beta_members),
    'consents',(select count(*) from private.exam_prep_beta_consents),
    'weekly_reviews',(select count(*) from private.exam_prep_beta_weekly_reviews)
  ) then
    raise exception 'P2-69 changed real beta controls';
  end if;

  if (select count(*) from public.users)<>v_users_before then
    raise exception 'P2-69 public user count did not return to baseline inside cleanup';
  end if;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  select count(*) into v_count from private.exam_prep_synthetic_validation_runs where run_id='SV-P269CI-RUN-0001';
  if v_count<>0 then raise exception 'P2-69 rollback left synthetic run rows=%',v_count; end if;
  select count(*) into v_count from private.exam_prep_synthetic_run_clocks where run_id='SV-P269CI-RUN-0001';
  if v_count<>0 then raise exception 'P2-69 rollback left synthetic clock rows=%',v_count; end if;
  select count(*) into v_count from private.exam_prep_synthetic_timeline_events where run_id='SV-P269CI-RUN-0001';
  if v_count<>0 then raise exception 'P2-69 rollback left synthetic timeline rows=%',v_count; end if;
END
$$;

\echo 'P2-69 full Stage 0-6 Core synthetic simulation: GREEN'
