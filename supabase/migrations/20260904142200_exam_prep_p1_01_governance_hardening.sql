-- P1-01 follow-up: close the only new advisor performance finding and
-- make per-service weekly review reasons explicit in the stored RPC contract.

begin;

create index if not exists exam_prep_beta_weekly_reviews_reviewer_idx
on private.exam_prep_beta_weekly_reviews(reviewer_user_id);

create or replace function public.record_exam_prep_beta_weekly_review_v1(
  p_cohort_key text,
  p_review_no smallint,
  p_period_end timestamptz,
  p_overall_decision text,
  p_core_decision text,
  p_ai_decision text,
  p_mentor_decision text,
  p_decision_reason text,
  p_core_reason text,
  p_ai_reason text,
  p_mentor_reason text,
  p_reviewer_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_snapshot jsonb;
  v_review uuid;
  v_expected int;
  v_ai_active int;
  v_mentor_active int;
  v_core_blockers int;
  v_mentor_blockers int;
  v_ai_status text;
begin
  if not private.exam_prep_beta_governance_reviewer_v1(p_reviewer_user_id) then
    raise exception 'exam_prep_beta_governance_reviewer_required' using errcode='42501';
  end if;
  if p_overall_decision not in ('continue','hold_expansion','pause_all') then raise exception 'exam_prep_beta_bad_overall_decision'; end if;
  if p_core_decision not in ('green','hold','rollback') then raise exception 'exam_prep_beta_bad_core_decision'; end if;
  if p_ai_decision not in ('green','hold','rollback','not_applicable') then raise exception 'exam_prep_beta_bad_ai_decision'; end if;
  if p_mentor_decision not in ('green','hold','rollback','not_applicable') then raise exception 'exam_prep_beta_bad_mentor_decision'; end if;
  if p_decision_reason is null or char_length(trim(p_decision_reason)) not between 10 and 4000 then raise exception 'exam_prep_beta_weekly_reason_required'; end if;
  if p_core_reason is null or char_length(trim(p_core_reason)) not between 10 and 4000 then raise exception 'exam_prep_beta_core_reason_required'; end if;
  if p_ai_reason is null or char_length(trim(p_ai_reason)) not between 10 and 4000 then raise exception 'exam_prep_beta_ai_reason_required'; end if;
  if p_mentor_reason is null or char_length(trim(p_mentor_reason)) not between 10 and 4000 then raise exception 'exam_prep_beta_mentor_reason_required'; end if;

  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key for update;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if v_c.cohort_status not in ('canary','active','paused') then raise exception 'exam_prep_beta_weekly_bad_cohort_status'; end if;

  select coalesce(max(review_no),0)+1 into v_expected
  from private.exam_prep_beta_weekly_reviews where cohort_id=v_c.id;
  if p_review_no<>v_expected then
    raise exception 'exam_prep_beta_weekly_review_must_be_sequential: expected %, got %',v_expected,p_review_no;
  end if;

  v_snapshot:=public.get_exam_prep_beta_weekly_snapshot_v1(p_cohort_key,p_period_end);
  v_ai_active:=coalesce((v_snapshot#>>'{service_metrics,ai_assist,active_members}')::int,0);
  v_mentor_active:=coalesce((v_snapshot#>>'{service_metrics,mentor_care,active_members}')::int,0);
  v_ai_status:=coalesce(v_snapshot->>'ai_runtime_status','not_deployed');

  if v_ai_active=0 and p_ai_decision<>'not_applicable' then raise exception 'exam_prep_beta_ai_decision_must_be_not_applicable_when_inactive'; end if;
  if v_ai_active>0 and p_ai_decision='not_applicable' then raise exception 'exam_prep_beta_ai_decision_required_when_active'; end if;
  if v_mentor_active=0 and p_mentor_decision<>'not_applicable' then raise exception 'exam_prep_beta_mentor_decision_must_be_not_applicable_when_inactive'; end if;
  if v_mentor_active>0 and p_mentor_decision='not_applicable' then raise exception 'exam_prep_beta_mentor_decision_required_when_active'; end if;

  v_core_blockers:=
    coalesce((v_snapshot#>>'{hard_blockers,entitlement_mismatches}')::int,0)+
    coalesce((v_snapshot#>>'{hard_blockers,component_evidence_mismatches}')::int,0)+
    coalesce((v_snapshot#>>'{hard_blockers,nonmentor_human_verified_state}')::int,0)+
    coalesce((v_snapshot#>>'{hard_blockers,open_sev0_sev1_incidents}')::int,0);
  v_mentor_blockers:=
    coalesce((v_snapshot#>>'{hard_blockers,mentor_readiness_violations}')::int,0)+
    coalesce((v_snapshot#>>'{hard_blockers,queue_leakage}')::int,0)+
    coalesce((v_snapshot#>>'{hard_blockers,open_urgent_critical_safeguarding}')::int,0);

  if p_core_decision='green' and v_core_blockers<>0 then raise exception 'exam_prep_beta_false_green_core_blockers=%',v_core_blockers; end if;
  if p_ai_decision='green' and v_ai_status<>'ready' then raise exception 'exam_prep_beta_false_green_ai_runtime_status=%',v_ai_status; end if;
  if p_mentor_decision='green' and v_mentor_blockers<>0 then raise exception 'exam_prep_beta_false_green_mentor_blockers=%',v_mentor_blockers; end if;
  if p_overall_decision='continue' and (
    p_core_decision<>'green' or
    (v_ai_active>0 and p_ai_decision<>'green') or
    (v_mentor_active>0 and p_mentor_decision<>'green')
  ) then raise exception 'exam_prep_beta_continue_requires_all_active_services_green'; end if;
  if p_core_decision='rollback' and p_overall_decision<>'pause_all' then raise exception 'exam_prep_beta_core_rollback_requires_pause_all'; end if;

  insert into private.exam_prep_beta_weekly_reviews(
    cohort_id,review_no,period_start,period_end,snapshot,snapshot_hash,
    overall_decision,decision_reason,reviewer_user_id
  ) values(
    v_c.id,p_review_no,(v_snapshot->>'period_start')::timestamptz,p_period_end,
    v_snapshot,md5(v_snapshot::text),p_overall_decision,trim(p_decision_reason),p_reviewer_user_id
  ) returning id into v_review;

  insert into private.exam_prep_beta_weekly_service_reviews(
    weekly_review_id,service_mode,decision,reason_text
  ) values
    (v_review,'core',p_core_decision,trim(p_core_reason)),
    (v_review,'ai_assist',p_ai_decision,trim(p_ai_reason)),
    (v_review,'mentor_care',p_mentor_decision,trim(p_mentor_reason));

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,metadata
  ) values(
    'math_as_p1_p5',p_reviewer_user_id,'beta_governance','beta_weekly_review_recorded',
    'private.exam_prep_beta_weekly_reviews',v_review::text,
    jsonb_build_object('cohort_key',p_cohort_key,'review_no',p_review_no,'overall_decision',p_overall_decision)
  );

  return jsonb_build_object(
    'review_id',v_review,'cohort_key',p_cohort_key,'review_no',p_review_no,
    'overall_decision',p_overall_decision,'snapshot_hash',md5(v_snapshot::text)
  );
end;
$$;

revoke all on function public.record_exam_prep_beta_weekly_review_v1(
  text,smallint,timestamptz,text,text,text,text,text,text,text,text,uuid
) from public,anon,authenticated;
grant execute on function public.record_exam_prep_beta_weekly_review_v1(
  text,smallint,timestamptz,text,text,text,text,text,text,text,text,uuid
) to service_role;

do $$
declare v_bad int;
begin
  if not exists(
    select 1 from pg_indexes
    where schemaname='private'
      and tablename='exam_prep_beta_weekly_reviews'
      and indexname='exam_prep_beta_weekly_reviews_reviewer_idx'
  ) then raise exception 'P1-01 reviewer FK index missing'; end if;

  select count(*) into v_bad
  from private.exam_prep_feature_config
  where id=1 and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch);
  if v_bad<>0 then raise exception 'P1-01 hardening must remain fail-closed'; end if;
end;
$$;

commit;
