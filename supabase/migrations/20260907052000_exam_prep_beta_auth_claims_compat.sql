-- Exam Prep controlled-beta self-consent: modern JWT-claims compatibility.
-- No rollout/access state changes. This only replaces legacy role-GUC reads with auth.role(),
-- which supports both request.jwt.claim.role and request.jwt.claims JSON.

create or replace function public.get_my_exam_prep_beta_invitation_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_role text;
  v_items jsonb;
begin
  v_uid := auth.uid();
  v_role := auth.role();

  if v_uid is null or v_role is distinct from 'authenticated' then
    raise exception 'exam_prep_beta_self_consent_auth_required';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'cohort_key', c.cohort_key,
    'cohort_status', c.cohort_status,
    'capacity', c.planned_size,
    'monitoring_hours', c.monitoring_hours,
    'service_mode', m.service_mode,
    'activation_wave', m.activation_wave,
    'member_status', m.member_status,
    'consent_status', coalesce(cs.consent_status, 'missing'),
    'consented_at', cs.consented_at,
    'revoked_at', cs.revoked_at,
    'consent_scope', 'exam_prep_controlled_beta_v1',
    'consent_copy_version', 'controlled_beta_v1_2026_09_04'
  ) order by c.id), '[]'::jsonb)
  into v_items
  from private.exam_prep_beta_members m
  join private.exam_prep_beta_cohorts c on c.id = m.cohort_id
  left join private.exam_prep_beta_consents cs
    on cs.cohort_id = m.cohort_id and cs.user_id = m.user_id
  where m.user_id = v_uid
    and m.member_status <> 'removed';

  return jsonb_build_object(
    'invited', jsonb_array_length(v_items) > 0,
    'user_id', v_uid,
    'consent_scope', 'exam_prep_controlled_beta_v1',
    'consent_copy_version', 'controlled_beta_v1_2026_09_04',
    'invitations', v_items
  );
end;
$function$;

create or replace function public.grant_my_exam_prep_beta_consent_v1(
  p_cohort_key text,
  p_acknowledgement text
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_role text;
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_m private.exam_prep_beta_members%rowtype;
  v_result jsonb;
begin
  v_uid := auth.uid();
  v_role := auth.role();

  if v_uid is null or v_role is distinct from 'authenticated' then
    raise exception 'exam_prep_beta_self_consent_auth_required';
  end if;
  if p_acknowledgement is distinct from 'I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1' then
    raise exception 'exam_prep_beta_self_consent_acknowledgement_required';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key = p_cohort_key;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode = 'P0002';
  end if;

  select * into v_m
  from private.exam_prep_beta_members
  where cohort_id = v_c.id and user_id = v_uid;
  if v_m.id is null or v_m.member_status <> 'candidate' then
    raise exception 'exam_prep_beta_self_consent_candidate_required';
  end if;

  v_result := public.record_exam_prep_beta_consent_v1(
    p_cohort_key,
    v_uid,
    'authenticated_self_consent_v1:controlled_beta_v1_2026_09_04',
    now()
  );

  return v_result || jsonb_build_object(
    'consent_copy_version', 'controlled_beta_v1_2026_09_04',
    'subject', 'self',
    'approval_state', 'unchanged',
    'activation_state', 'unchanged'
  );
end;
$function$;

create or replace function public.revoke_my_exam_prep_beta_consent_v1(
  p_cohort_key text,
  p_acknowledgement text
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_role text;
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_m private.exam_prep_beta_members%rowtype;
  v_result jsonb;
begin
  v_uid := auth.uid();
  v_role := auth.role();

  if v_uid is null or v_role is distinct from 'authenticated' then
    raise exception 'exam_prep_beta_self_consent_auth_required';
  end if;
  if p_acknowledgement is distinct from 'I_REVOKE_EXAM_PREP_CONTROLLED_BETA_V1' then
    raise exception 'exam_prep_beta_self_revocation_acknowledgement_required';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key = p_cohort_key;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode = 'P0002';
  end if;

  select * into v_m
  from private.exam_prep_beta_members
  where cohort_id = v_c.id and user_id = v_uid and member_status <> 'removed';
  if v_m.id is null then
    raise exception 'exam_prep_beta_self_consent_membership_required';
  end if;

  v_result := public.revoke_exam_prep_beta_consent_v1(
    p_cohort_key,
    v_uid,
    'authenticated_self_revocation_v1:controlled_beta_v1_2026_09_04'
  );

  return v_result || jsonb_build_object(
    'consent_copy_version', 'controlled_beta_v1_2026_09_04',
    'subject', 'self'
  );
end;
$function$;

create or replace function private.exam_prep_audit_row_change_v1()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_before jsonb;
  v_after jsonb;
  v_actor_text text;
  v_target_text text;
  v_component text;
  v_object_id text;
  v_program_key text;
begin
  if tg_op = 'INSERT' then v_before := null; v_after := to_jsonb(new);
  elsif tg_op = 'UPDATE' then v_before := to_jsonb(old); v_after := to_jsonb(new);
  else v_before := to_jsonb(old); v_after := null; end if;

  v_actor_text := coalesce(v_after->>'updated_by', v_after->>'created_by', v_before->>'updated_by', v_before->>'created_by');
  v_target_text := coalesce(v_after->>'user_id', v_after->>'learner_user_id', v_before->>'user_id', v_before->>'learner_user_id');
  v_component := coalesce(v_after->>'component_code', v_after->>'target_component_code', v_after->>'owner_component_code', v_before->>'component_code', v_before->>'target_component_code', v_before->>'owner_component_code');
  v_object_id := coalesce(v_after->>'id', v_after->>'program_key', v_after->>'user_id', v_after->>'learner_user_id', v_after->>'skill_code', v_after->>'prerequisite_code', v_after->>'mixed_code', v_before->>'id', v_before->>'program_key', v_before->>'user_id', v_before->>'learner_user_id', v_before->>'skill_code', v_before->>'prerequisite_code', v_before->>'mixed_code');
  v_program_key := coalesce(v_after->>'program_key', v_before->>'program_key', 'math_as_p1_p5');

  insert into private.exam_prep_audit_events(
    program_key, actor_user_id, actor_role, event_type, object_type, object_id,
    target_user_id, component_code, before_state, after_state, metadata
  )
  values(
    v_program_key,
    coalesce(nullif(v_actor_text, '')::uuid, auth.uid()),
    coalesce(auth.role(), session_user),
    lower(tg_op),
    tg_table_schema || '.' || tg_table_name,
    v_object_id,
    nullif(v_target_text, '')::uuid,
    case when v_component in ('P1','P5') then v_component else null end,
    v_before,
    v_after,
    jsonb_build_object('trigger', tg_name)
  );
  return null;
end;
$function$;
