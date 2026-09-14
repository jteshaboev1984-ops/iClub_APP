begin;

-- P2-61 periodic self-audit: synthetic beta activation may predate the real
-- monitoring epoch. The 72-hour operational canary clock must therefore start
-- from the real-review epoch, not from stale synthetic activation timestamps.
--
-- Preserve the complete P2-38 residue guard. Real monitoring can be armed only
-- after every learner-scoped synthetic row reported by the authoritative
-- residue helper is gone.

create or replace function public.arm_exam_prep_beta_real_monitoring_v1(
  p_cohort_key text,
  p_cleanup_evidence_ref text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_ctl private.exam_prep_beta_expansion_controls%rowtype;
  v_residue jsonb;
  v_residue_total int:=0;
  v_now timestamptz:=now();
  v_monitoring_until timestamptz;
begin
  if p_cleanup_evidence_ref is null or char_length(trim(p_cleanup_evidence_ref))<8 then
    raise exception 'exam_prep_cleanup_evidence_ref_required';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key
  for update;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  select * into v_ctl
  from private.exam_prep_beta_expansion_controls
  where cohort_id=v_c.id
  for update;
  if v_ctl.cohort_id is null then
    raise exception 'exam_prep_expansion_control_missing';
  end if;
  if v_ctl.development_data_state='real_monitoring'
     or v_ctl.real_review_epoch_started_at is not null then
    raise exception 'exam_prep_real_monitoring_already_armed';
  end if;
  if v_ctl.development_data_state not in ('synthetic_present','clean') then
    raise exception 'exam_prep_real_monitoring_bad_development_state=%',v_ctl.development_data_state;
  end if;
  if exists(select 1 from private.exam_prep_beta_weekly_reviews r where r.cohort_id=v_c.id) then
    raise exception 'exam_prep_real_monitoring_requires_zero_prior_weekly_reviews';
  end if;

  v_residue:=private.exam_prep_beta_synthetic_residue_v2(v_c.id);
  v_residue_total:=coalesce((v_residue->>'total_rows')::int,0);
  if v_residue_total<>0 then
    raise exception 'exam_prep_synthetic_progress_cleanup_incomplete rows=%',v_residue_total;
  end if;

  v_monitoring_until:=v_now+(v_c.monitoring_hours||' hours')::interval;

  update private.exam_prep_beta_expansion_controls
  set development_data_state='real_monitoring',
      real_review_epoch_started_at=v_now,
      cleanup_evidence_ref=trim(p_cleanup_evidence_ref),
      updated_at=v_now
  where cohort_id=v_c.id;

  update private.exam_prep_beta_cohorts
  set monitoring_until=v_monitoring_until,
      updated_at=v_now
  where id=v_c.id;

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,metadata
  ) values(
    'math_as_p1_p5',auth.uid(),'service_role','beta_real_monitoring_armed',
    'private.exam_prep_beta_expansion_controls',v_c.id::text,
    jsonb_build_object(
      'cohort_key',p_cohort_key,
      'cleanup_evidence_ref',trim(p_cleanup_evidence_ref),
      'synthetic_progress_rows',v_residue_total,
      'blocking_counts',coalesce(v_residue->'counts','{}'::jsonb),
      'real_review_epoch_started_at',v_now,
      'monitoring_until',v_monitoring_until,
      'monitoring_hours',v_c.monitoring_hours
    )
  );

  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'development_data_state','real_monitoring',
    'real_review_epoch_started_at',v_now,
    'monitoring_until',v_monitoring_until,
    'monitoring_hours',v_c.monitoring_hours,
    'synthetic_progress_rows',v_residue_total
  );
end;
$$;

revoke all on function public.arm_exam_prep_beta_real_monitoring_v1(text,text) from public,anon,authenticated;
grant execute on function public.arm_exam_prep_beta_real_monitoring_v1(text,text) to service_role;

-- Repair only stale windows for cohorts already armed before P2-61. Never shorten
-- a later operator-set monitoring window.
update private.exam_prep_beta_cohorts c
set monitoring_until=ec.real_review_epoch_started_at+(c.monitoring_hours||' hours')::interval,
    updated_at=now()
from private.exam_prep_beta_expansion_controls ec
where ec.cohort_id=c.id
  and ec.development_data_state='real_monitoring'
  and ec.real_review_epoch_started_at is not null
  and (
    c.monitoring_until is null
    or c.monitoring_until < ec.real_review_epoch_started_at+(c.monitoring_hours||' hours')::interval
  );

commit;
