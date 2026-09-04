-- P0-16 incremental consent compatibility.
--
-- The Core-first overlay allows future-wave candidates to be added after the
-- controlled beta has started. Consent must therefore remain recordable for an
-- allowlisted candidate in a future wave while the cohort is approved/canary/active.
-- This does not approve a member, activate a wave, or grant any entitlement.

begin;

create or replace function public.record_exam_prep_beta_consent_v1(
  p_cohort_key text,
  p_user_id uuid,
  p_evidence_ref text,
  p_consented_at timestamptz default now()
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_m private.exam_prep_beta_members%rowtype;
  v_id bigint;
begin
  if p_evidence_ref is null or char_length(trim(p_evidence_ref)) not between 5 and 500 then
    raise exception 'exam_prep_beta_consent_evidence_required';
  end if;
  if p_consented_at is null or p_consented_at>now()+interval '5 minutes' then
    raise exception 'exam_prep_beta_consent_bad_timestamp';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key
  for update;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;
  if v_c.cohort_status not in ('draft','approved','canary','active') then
    raise exception 'exam_prep_beta_consent_grant_cohort_not_open=%',v_c.cohort_status;
  end if;

  select * into v_m
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and user_id=p_user_id
  for update;
  if v_m.id is null then
    raise exception 'exam_prep_beta_member_not_found' using errcode='P0002';
  end if;
  if v_m.member_status<>'candidate' then
    raise exception 'exam_prep_beta_consent_grant_requires_candidate';
  end if;
  if v_c.current_wave>0 and v_m.activation_wave<=v_c.current_wave then
    raise exception 'exam_prep_beta_consent_requires_future_wave: current %, member wave %',
      v_c.current_wave,v_m.activation_wave;
  end if;

  insert into private.exam_prep_beta_consents(
    cohort_id,user_id,consent_scope,consent_status,consented_at,grant_evidence_ref,
    revoked_at,revocation_evidence_ref,created_by,updated_by
  ) values (
    v_c.id,p_user_id,'exam_prep_controlled_beta_v1','granted',p_consented_at,trim(p_evidence_ref),
    null,null,auth.uid(),auth.uid()
  )
  on conflict(cohort_id,user_id) do update set
    consent_scope='exam_prep_controlled_beta_v1',
    consent_status='granted',
    consented_at=excluded.consented_at,
    grant_evidence_ref=excluded.grant_evidence_ref,
    revoked_at=null,
    revocation_evidence_ref=null,
    updated_at=now(),
    updated_by=auth.uid()
  returning id into v_id;

  return jsonb_build_object(
    'consent_id',v_id,
    'cohort_key',p_cohort_key,
    'user_id',p_user_id,
    'consent_status','granted',
    'member_wave',v_m.activation_wave,
    'current_wave',v_c.current_wave,
    'feature_state','unchanged',
    'approval_state','unchanged',
    'activation_state','unchanged'
  );
end;
$$;
revoke all on function public.record_exam_prep_beta_consent_v1(text,uuid,text,timestamptz)
from public,anon,authenticated;
grant execute on function public.record_exam_prep_beta_consent_v1(text,uuid,text,timestamptz)
to service_role;

-- Deployment invariant: this overlay is being introduced before the first live
-- production wave and must not itself open access.
do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off'
     or v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not v_cfg.kill_switch then
    raise exception 'P0-16 incremental consent compatibility requires fail-closed deployment state';
  end if;

  select count(*) into v_active
  from private.exam_prep_feature_entitlements
  where entitlement_status='active';
  if v_active<>0 then
    raise exception 'P0-16 incremental consent compatibility found active entitlements=%',v_active;
  end if;
end
$$;

commit;
