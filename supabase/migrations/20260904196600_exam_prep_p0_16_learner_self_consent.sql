-- P0-16 authenticated learner self-consent overlay.
--
-- This removes the operational need for an administrator to impersonate learner
-- intent while preserving every controlled-beta hold point:
-- * only an already allowlisted, non-removed learner can see their own invite;
-- * grant/revoke always acts on auth.uid(); there is no user_id input;
-- * grant requires an explicit acknowledgement token tied to consent copy v1;
-- * self-consent never approves a cohort, activates a wave, or grants entitlement;
-- * live self-revocation delegates to the fail-closed global pause path.

begin;

create or replace function public.get_my_exam_prep_beta_invitation_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_role text;
  v_items jsonb;
begin
  v_uid:=auth.uid();
  v_role:=nullif(current_setting('request.jwt.claim.role',true),'');

  if v_uid is null or v_role is distinct from 'authenticated' then
    raise exception 'exam_prep_beta_self_consent_auth_required';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'cohort_key',c.cohort_key,
    'cohort_status',c.cohort_status,
    'capacity',c.planned_size,
    'monitoring_hours',c.monitoring_hours,
    'service_mode',m.service_mode,
    'activation_wave',m.activation_wave,
    'member_status',m.member_status,
    'consent_status',coalesce(cs.consent_status,'missing'),
    'consented_at',cs.consented_at,
    'revoked_at',cs.revoked_at,
    'consent_scope','exam_prep_controlled_beta_v1',
    'consent_copy_version','controlled_beta_v1_2026_09_04'
  ) order by c.id),'[]'::jsonb)
  into v_items
  from private.exam_prep_beta_members m
  join private.exam_prep_beta_cohorts c on c.id=m.cohort_id
  left join private.exam_prep_beta_consents cs
    on cs.cohort_id=m.cohort_id and cs.user_id=m.user_id
  where m.user_id=v_uid
    and m.member_status<>'removed';

  return jsonb_build_object(
    'invited',jsonb_array_length(v_items)>0,
    'user_id',v_uid,
    'consent_scope','exam_prep_controlled_beta_v1',
    'consent_copy_version','controlled_beta_v1_2026_09_04',
    'invitations',v_items
  );
end;
$$;
revoke all on function public.get_my_exam_prep_beta_invitation_v1()
from public,anon,service_role;
grant execute on function public.get_my_exam_prep_beta_invitation_v1()
to authenticated;

create or replace function public.grant_my_exam_prep_beta_consent_v1(
  p_cohort_key text,
  p_acknowledgement text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_role text;
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_m private.exam_prep_beta_members%rowtype;
  v_result jsonb;
begin
  v_uid:=auth.uid();
  v_role:=nullif(current_setting('request.jwt.claim.role',true),'');

  if v_uid is null or v_role is distinct from 'authenticated' then
    raise exception 'exam_prep_beta_self_consent_auth_required';
  end if;
  if p_acknowledgement is distinct from 'I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1' then
    raise exception 'exam_prep_beta_self_consent_acknowledgement_required';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  select * into v_m
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and user_id=v_uid;
  if v_m.id is null or v_m.member_status<>'candidate' then
    raise exception 'exam_prep_beta_self_consent_candidate_required';
  end if;

  v_result:=public.record_exam_prep_beta_consent_v1(
    p_cohort_key,
    v_uid,
    'authenticated_self_consent_v1:controlled_beta_v1_2026_09_04',
    now()
  );

  return v_result || jsonb_build_object(
    'consent_copy_version','controlled_beta_v1_2026_09_04',
    'subject','self',
    'approval_state','unchanged',
    'activation_state','unchanged'
  );
end;
$$;
revoke all on function public.grant_my_exam_prep_beta_consent_v1(text,text)
from public,anon,service_role;
grant execute on function public.grant_my_exam_prep_beta_consent_v1(text,text)
to authenticated;

create or replace function public.revoke_my_exam_prep_beta_consent_v1(
  p_cohort_key text,
  p_acknowledgement text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_role text;
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_m private.exam_prep_beta_members%rowtype;
  v_result jsonb;
begin
  v_uid:=auth.uid();
  v_role:=nullif(current_setting('request.jwt.claim.role',true),'');

  if v_uid is null or v_role is distinct from 'authenticated' then
    raise exception 'exam_prep_beta_self_consent_auth_required';
  end if;
  if p_acknowledgement is distinct from 'I_REVOKE_EXAM_PREP_CONTROLLED_BETA_V1' then
    raise exception 'exam_prep_beta_self_revocation_acknowledgement_required';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  select * into v_m
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and user_id=v_uid and member_status<>'removed';
  if v_m.id is null then
    raise exception 'exam_prep_beta_self_consent_membership_required';
  end if;

  v_result:=public.revoke_exam_prep_beta_consent_v1(
    p_cohort_key,
    v_uid,
    'authenticated_self_revocation_v1:controlled_beta_v1_2026_09_04'
  );

  return v_result || jsonb_build_object(
    'consent_copy_version','controlled_beta_v1_2026_09_04',
    'subject','self'
  );
end;
$$;
revoke all on function public.revoke_my_exam_prep_beta_consent_v1(text,text)
from public,anon,service_role;
grant execute on function public.revoke_my_exam_prep_beta_consent_v1(text,text)
to authenticated;

-- Deployment invariants: the learner-facing overlay must remain dormant and may
-- not manufacture consent for any existing production candidate.
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
    raise exception 'P0-16 learner self-consent overlay requires fail-closed feature state';
  end if;

  select count(*) into v_active
  from private.exam_prep_feature_entitlements
  where entitlement_status='active';
  if v_active<>0 then
    raise exception 'P0-16 learner self-consent overlay found active entitlements=%',v_active;
  end if;
end
$$;

commit;
