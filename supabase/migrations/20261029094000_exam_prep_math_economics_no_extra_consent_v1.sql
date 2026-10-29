-- Staged only. iClub Exam Prep Mathematics / Economics / future subjects.
-- Remove subject-specific consent as a *permission gate*; keep history immutable.
-- No row modifications, grants of learner seats, progress reset or content release.
-- Existing core entitlement and cohort controls remain mandatory.
BEGIN;
CREATE OR REPLACE FUNCTION private.enforce_exam_prep_beta_member_consent_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
BEGIN
 -- Legacy trigger name kept to avoid breaking existing database dependencies.
 -- A seat is authorized by cohort governance, capacity, identity firewall and
 -- owner-configured entitlement; no fabricated consent record is inserted.
 RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION public.approve_exam_prep_controlled_beta_v1(p_cohort_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_candidates int;
  v_total int;
  v_core int;
  v_ai int;
  v_mentor int;
  v_bad_wave int;
  v_bad_assignment int;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_initial boolean;
begin
  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key
  for update;

  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;
  if v_c.cohort_status not in ('draft','approved','canary','active') then
    raise exception 'exam_prep_beta_cohort_not_approvable_status=%',v_c.cohort_status;
  end if;

  v_initial:=(v_c.cohort_status='draft');

  select count(*),
         count(*) filter(where service_mode='core'),
         count(*) filter(where service_mode='ai_assist'),
         count(*) filter(where service_mode='mentor_care')
    into v_candidates,v_core,v_ai,v_mentor
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and member_status='candidate';

  if v_candidates=0 then
    raise exception 'exam_prep_beta_no_candidates_to_approve';
  end if;

  select count(*) into v_total
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and member_status<>'removed';

  if v_total>v_c.planned_size or v_total>12 then
    raise exception 'exam_prep_beta_member_count_outside_capacity: got %, capacity %',v_total,v_c.planned_size;
  end if;

  if v_initial then
    if v_total<3 then
      raise exception 'exam_prep_beta_initial_core_first_requires_at_least_3: got %',v_total;
    end if;
    if not exists(
      select 1 from private.exam_prep_beta_members
      where cohort_id=v_c.id and member_status<>'removed' and service_mode='core'
    ) then
      raise exception 'exam_prep_beta_initial_cohort_requires_core';
    end if;

    select * into v_cfg from private.exam_prep_feature_config where id=1;
    if v_cfg.rollout_state<>'off'
       or v_cfg.core_enabled
       or v_cfg.ai_enabled
       or v_cfg.mentor_enabled
       or not v_cfg.kill_switch then
      raise exception 'exam_prep_beta_initial_approval_requires_fail_closed_config';
    end if;
  else
    select count(*) into v_bad_wave
    from private.exam_prep_beta_members
    where cohort_id=v_c.id
      and member_status='candidate'
      and activation_wave<=v_c.current_wave;
    if v_bad_wave<>0 then
      raise exception 'exam_prep_beta_incremental_candidates_must_be_future_wave=%',v_bad_wave;
    end if;
  end if;

  -- Core/AI candidates must not leak into an active Mentor relationship.
  select count(*) into v_bad_assignment
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id
    and m.member_status='candidate'
    and m.service_mode<>'mentor_care'
    and (
      exists(
        select 1 from private.exam_prep_mentor_service_status s
        where s.learner_user_id=m.user_id
          and s.service_status='assigned_active'
      )
      or exists(
        select 1 from private.exam_prep_mentor_assignments a
        where a.learner_user_id=m.user_id
          and a.assignment_status='active'
          and a.valid_from<=now()
          and (a.valid_until is null or a.valid_until>now())
      )
    );
  if v_bad_assignment<>0 then
    raise exception 'exam_prep_beta_nonmentor_assignment_leakage=%',v_bad_assignment;
  end if;

  update private.exam_prep_beta_members
  set member_status='approved',updated_at=now(),updated_by=auth.uid()
  where cohort_id=v_c.id and member_status='candidate';

  if v_initial then
    update private.exam_prep_beta_cohorts
    set cohort_status='approved',approved_at=now(),updated_at=now(),updated_by=auth.uid()
    where id=v_c.id;
  end if;

  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'status',case when v_initial then 'approved' else v_c.cohort_status end,
    'approval_mode',case when v_initial then 'initial_core_first' else 'incremental' end,
    'approved_now',v_candidates,
    'occupied_size',v_total,
    'capacity',v_c.planned_size,
    'remaining_capacity',v_c.planned_size-v_total,
    'candidate_service_mix',jsonb_build_object('core',v_core,'ai_assist',v_ai,'mentor_care',v_mentor),
    'feature_state','unchanged',
    'ai_activation_gate','unchanged',
    'mentor_activation_gate','unchanged'
  );
end;
$function$

CREATE OR REPLACE FUNCTION private.iclub_exam_native_economics_beta_allowed_v1(p_user uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT p_user IS NOT NULL AND EXISTS (
   SELECT 1
   FROM private.exam_prep_beta_cohorts c
   JOIN private.exam_prep_beta_members m
     ON m.cohort_id=c.id AND m.user_id=p_user
   JOIN private.exam_prep_feature_entitlements ent
     ON ent.user_id=m.user_id
   JOIN private.exam_prep_feature_config cfg ON cfg.id=1
   WHERE c.cohort_key='math_as_p1_p5_beta_2026_09_01'
     AND c.program_key='math_as_p1_p5'
     AND c.cohort_status IN ('canary','active')
     AND m.member_status='active' AND m.activated_at IS NOT NULL
     AND m.service_mode IN ('core','ai_assist')
     AND m.activation_wave<=c.current_wave
     AND ent.entitlement_status='active'
     AND ent.core_access=true
     AND (ent.valid_from IS NULL OR ent.valid_from<=now())
     AND (ent.valid_until IS NULL OR ent.valid_until>now())
     AND cfg.program_key='math_as_p1_p5'
     AND cfg.core_enabled=true
     AND cfg.kill_switch=false
     AND cfg.rollout_state<>'off'
     AND EXISTS (
       SELECT 1 FROM public.users profile WHERE profile.id=p_user
     )
     AND EXISTS (
       SELECT 1 FROM public.user_subjects us
       JOIN public.subjects subj ON subj.id=us.subject_id
       WHERE us.user_id=p_user AND subj.subject_key='economics'
         AND subj.is_active=true
     )
 );
$function$

CREATE OR REPLACE FUNCTION private.iclub_econ_written_beta_eligible_v1(p_user uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT p_user IS NOT NULL
 AND EXISTS (
  SELECT 1 FROM private.exam_prep_beta_cohorts c
  JOIN private.exam_prep_beta_members m ON m.cohort_id=c.id
  WHERE c.program_key='math_as_p1_p5'
    AND c.cohort_key='math_as_p1_p5_beta_2026_09_01'
    AND c.cohort_status IN ('canary','active')
    AND m.user_id=p_user AND m.member_status='active'
    AND m.activated_at IS NOT NULL
    AND m.activation_wave<=c.current_wave
    AND EXISTS (
      SELECT 1 FROM private.exam_prep_feature_entitlements e
      JOIN private.exam_prep_feature_config cfg ON cfg.id=1
      WHERE e.user_id=p_user AND e.entitlement_status='active'
        AND e.core_access AND (e.valid_from IS NULL OR e.valid_from<=now())
        AND (e.valid_until IS NULL OR e.valid_until>now())
        AND cfg.program_key='math_as_p1_p5' AND cfg.core_enabled
        AND NOT cfg.kill_switch AND cfg.rollout_state<>'off'
    )
 )
 AND EXISTS(
  SELECT 1 FROM public.user_subjects us
  JOIN public.subjects s ON s.id=us.subject_id
  WHERE us.user_id=p_user AND s.subject_key='economics' AND s.is_active
 )
 AND EXISTS(
  SELECT 1 FROM private.iclub_exam_native_mcq_attempts_v1 a
  WHERE a.user_id=p_user AND a.program_key='economics_9708'
    AND a.version_key='economics_2026_2028_v1'
    AND a.paper_code='P1' AND a.session_kind='diagnostic'
    AND a.status='finalized'
 );
$function$

CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_p1_math_beta_eligible_v1(p_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT p_user_id IS NOT NULL AND EXISTS (
   SELECT 1 FROM private.exam_prep_beta_cohorts c
   JOIN private.exam_prep_beta_members m ON m.cohort_id=c.id
   WHERE c.cohort_key='math_as_p1_p5_beta_2026_09_01'
     AND c.program_key='math_as_p1_p5'
     AND c.cohort_status IN ('canary','active')
     AND m.user_id=p_user_id AND m.member_status='active'
     AND m.activated_at IS NOT NULL
 ) AND EXISTS (
   SELECT 1 FROM public.user_subjects us
   JOIN public.subjects s ON s.id=us.subject_id
   WHERE us.user_id=p_user_id AND s.subject_key='chemistry'
   AND s.is_active=true
 );
$function$

CREATE FUNCTION public.iclub_econ_written_start_v2()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid(); v_ctl record; v_plan uuid;
 v_keys text[]:=ARRAY[
  'P2.A.a','P2.A.b','P2.A.c','P2.A.d','P2.A.e','P2.A.f',
  'P2.B1.a','P2.C1.a','P4.A.a','P4.A.c','P4.B1','P4.C1'
 ];
 v_task_version text:='economics_9708_written_editorial_candidate_v3_20261027';
 v_program text:='economics_9708'; v_version text:='economics_2026_2028_v1';
BEGIN
 IF v_user IS NULL THEN RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 SELECT enabled,max_members INTO v_ctl
 FROM private.iclub_econ_written_beta_control_v1 WHERE singleton FOR UPDATE;
 IF NOT FOUND OR NOT v_ctl.enabled THEN
  RETURN jsonb_build_object('ok',false,'code','beta_closed');
 END IF;
 -- Existing active plan is a replay, not a new enrollment or consent.
 IF EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plans_v1 p
   JOIN private.iclub_exam_core_written_access_v1 a
    ON a.learner_user_id=p.learner_user_id AND a.program_key=p.program_key
       AND a.version_key=p.version_key
   WHERE p.learner_user_id=v_user AND p.program_key=v_program
    AND p.version_key=v_version AND p.status='active'
    AND a.status='active' AND a.core_access
    AND (a.valid_until IS NULL OR a.valid_until>now()))
 THEN RETURN jsonb_build_object('ok',true,'joined',true,'replayed',true); END IF;
 -- Historical withdrawals and expired plans stay untouched; no reset.
 IF EXISTS(SELECT 1 FROM private.iclub_econ_written_beta_optins_v1
   WHERE user_id=v_user AND status='withdrawn')
 THEN RETURN jsonb_build_object('ok',false,'code','existing_withdrawn_plan'); END IF;
 IF NOT private.iclub_econ_written_beta_eligible_v1(v_user) THEN
  RETURN jsonb_build_object('ok',false,'code','not_eligible');
 END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_access_v1
       WHERE program_key=v_program AND version_key=v_version)>=v_ctl.max_members THEN
  RETURN jsonb_build_object('ok',false,'code','beta_full');
 END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_core_written_access_v1
   WHERE learner_user_id=v_user AND program_key=v_program AND version_key=v_version)
  OR EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plans_v1
   WHERE learner_user_id=v_user AND program_key=v_program AND version_key=v_version)
 THEN RETURN jsonb_build_object('ok',false,'code','existing_written_plan');
 END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1 t
  WHERE t.program_key=v_program AND t.version_key=v_version
  AND t.task_version=v_task_version AND t.task_key=ANY(v_keys)
  AND t.status='approved' AND t.release_enabled
  AND t.academic_review='approved' AND t.language_review='approved'
  AND t.source_review='approved' AND t.questions ?& ARRAY['en','ru','uz']
  AND t.answer_requirements ?& ARRAY['en','ru','uz']
  AND private.iclub_exam_written_source_ready_v1(
    t.program_key,t.version_key,t.task_key,t.task_version)
 )<>12 THEN
  RETURN jsonb_build_object('ok',false,'code','beta_content_unavailable');
 END IF;
 INSERT INTO private.iclub_exam_core_written_access_v1
  (learner_user_id,program_key,version_key,core_access,status,valid_from,valid_until)
 VALUES(v_user,v_program,v_version,true,'active',now(),now()+INTERVAL '28 days');
 INSERT INTO private.iclub_exam_core_written_plans_v1
  (learner_user_id,program_key,version_key,status)
 VALUES(v_user,v_program,v_version,'active') RETURNING id INTO v_plan;
 INSERT INTO private.iclub_exam_core_written_plan_items_v1
  (plan_id,learner_user_id,program_key,version_key,task_key,task_version,priority_order,mode)
 SELECT v_plan,v_user,v_program,v_version,k,v_task_version,i::integer,'practice'
 FROM unnest(v_keys) WITH ORDINALITY AS v(k,i);
 RETURN jsonb_build_object('ok',true,'joined',true,'replayed',false);
END;
$function$

REVOKE ALL ON FUNCTION public.iclub_econ_written_start_v2() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_econ_written_start_v2() TO authenticated;
CREATE OR REPLACE FUNCTION public.iclub_econ_written_beta_status_v1()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid(); v_row record; v_joined boolean;
BEGIN
 IF v_user IS NULL THEN RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 SELECT enabled,max_members INTO v_row
 FROM private.iclub_econ_written_beta_control_v1 WHERE singleton;
 SELECT EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plans_v1 p
  JOIN private.iclub_exam_core_written_access_v1 a
    ON a.learner_user_id=p.learner_user_id AND a.program_key=p.program_key
     AND a.version_key=p.version_key
   WHERE p.learner_user_id=v_user AND p.program_key='economics_9708'
    AND p.version_key='economics_2026_2028_v1' AND p.status='active'
    AND a.core_access AND a.status='active'
    AND (a.valid_until IS NULL OR a.valid_until>now()))
 INTO v_joined;
 RETURN jsonb_build_object('ok',true,'joined',v_joined,
   'eligible',COALESCE(v_row.enabled,false) AND NOT v_joined
     AND private.iclub_econ_written_beta_eligible_v1(v_user)
     AND NOT EXISTS(SELECT 1 FROM private.iclub_econ_written_beta_optins_v1 o
       WHERE o.user_id=v_user AND o.status='withdrawn')
     AND NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plans_v1 p
       WHERE p.learner_user_id=v_user AND p.program_key='economics_9708'
         AND p.version_key='economics_2026_2028_v1')
     AND NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_written_access_v1 a
       WHERE a.learner_user_id=v_user AND a.program_key='economics_9708'
         AND a.version_key='economics_2026_2028_v1')
     AND (SELECT count(*) FROM private.iclub_exam_core_written_access_v1 a
       WHERE a.program_key='economics_9708' AND a.version_key='economics_2026_2028_v1') <
         COALESCE(v_row.max_members,0));
END;
$function$

-- Math Beta approval no longer depends on historical cohort opt-in; model-specific AI
-- eligibility remains controlled by its independent provider/AI policy.
CREATE OR REPLACE FUNCTION private.iclub_ai_math_beta_pro_quota_eligible_v1(p_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT p_user_id IS NOT NULL AND EXISTS(
  SELECT 1 FROM private.iclub_ai_practice_beta_grants_v1 g
  JOIN private.exam_prep_beta_members bm ON bm.user_id=g.user_id
    AND bm.member_status='active' AND bm.service_mode='ai_assist'
  JOIN private.exam_prep_beta_cohorts c ON c.id=bm.cohort_id
    AND c.program_key='math_as_p1_p5' AND c.cohort_status='canary'
  JOIN private.exam_prep_feature_entitlements ent ON ent.user_id=g.user_id
    AND ent.entitlement_status='active' AND ent.core_access AND ent.ai_assist
    AND (ent.valid_from IS NULL OR ent.valid_from<=now())
    AND (ent.valid_until IS NULL OR ent.valid_until>now())
  JOIN private.iclub_ai_v21_beta_members global_ai ON global_ai.user_id=g.user_id
    AND global_ai.enabled AND global_ai.consent_at IS NOT NULL
    AND global_ai.consent_version='global_ai_beta_v21'
  JOIN private.iclub_plan_policies plan ON plan.plan_code='pro'
    AND plan.is_active AND plan.policy_version='global_ai_tariffs_v1'
    AND plan.ai_usage_policy_code='pro_v1'
  JOIN private.iclub_ai_usage_policies pol
    ON pol.usage_policy_code=plan.ai_usage_policy_code
    AND pol.is_active AND pol.policy_version='global_ai_tariffs_v1'
    AND pol.period_seconds=18000 AND pol.allowance_units=14
    AND pol.prepared_weight=1 AND pol.generation_weight=5
  WHERE g.user_id=p_user_id AND g.enabled
    AND EXISTS(SELECT 1 FROM private.iclub_ai_practice_context_v1_control
       WHERE singleton=1 AND enabled AND owner_user_id IS NULL)
    AND EXISTS(SELECT 1 FROM private.iclub_ai_practice_freeform_pc3_control
       WHERE singleton=1 AND enabled)
    AND EXISTS(SELECT 1 FROM private.iclub_ai_practice_receipt_v1_control
       WHERE singleton=1 AND enabled)
 )
$function$

-- Phase 1 only: leave legacy RPC grants temporarily unchanged to avoid breaking
-- already-open browser tabs with pre-cutover cached frontend code. Phase 2
-- revokes obsolete enrollment and grants only after the new client is verified.

COMMIT;
