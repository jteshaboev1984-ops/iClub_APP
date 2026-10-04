-- P1-04 limited contextual AI follow-up v1.
-- Additive and fail-closed. Adds one governed learner follow-up interaction and
-- a service-only audit lookup. No academic state, legacy history, cohort size,
-- entitlements, Practice, Tours, ratings, certificates or localStorage are changed.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

update private.exam_prep_ai_policy
set allowed_interactions = case
      when 'context_followup'=any(allowed_interactions) then allowed_interactions
      else array_append(allowed_interactions,'context_followup')
    end,
    policy_version='exam_prep_ai_policy_v1_2_followup',
    prompt_version='exam_prep_ai_prompt_v1_2_followup',
    response_schema_version='exam_prep_ai_response_v1_1_followup',
    updated_at=now()
where id=1;

create or replace function public.get_exam_prep_ai_followup_policy_service_v1()
returns jsonb
language sql
stable
security definer
set search_path=''
as $fn$
  select jsonb_build_object(
    'enabled',coalesce('context_followup'=any(p.allowed_interactions),false),
    'policy_version',p.policy_version,
    'prompt_version',p.prompt_version,
    'response_schema_version',p.response_schema_version
  )
  from private.exam_prep_ai_policy p
  where p.id=1;
$fn$;

revoke all on function public.get_exam_prep_ai_followup_policy_service_v1()
  from public,anon,authenticated;
grant execute on function public.get_exam_prep_ai_followup_policy_service_v1()
  to service_role;

create or replace function public.get_exam_prep_ai_thread_parent_service_v1(
  p_user_id uuid,
  p_request_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path=''
as $fn$
  select coalesce((
    select jsonb_build_object(
      'request_id',a.request_id,
      'component_code',a.component_code,
      'interaction_type',a.interaction_type,
      'requested_locale',a.requested_locale,
      'mode',a.mode,
      'deterministic_snapshot_hash',a.deterministic_snapshot_hash,
      'source_card_keys',a.source_card_keys,
      'guard_decisions',a.guard_decisions,
      'output_hash',a.output_hash,
      'created_at',a.created_at
    )
    from private.exam_prep_ai_audit a
    where a.request_id=p_request_id
      and a.user_id=p_user_id
    limit 1
  ),'{}'::jsonb);
$fn$;

revoke all on function public.get_exam_prep_ai_thread_parent_service_v1(uuid,uuid)
  from public,anon,authenticated;
grant execute on function public.get_exam_prep_ai_thread_parent_service_v1(uuid,uuid)
  to service_role;

do $postcheck$
declare
  v_allowed text[];
begin
  select allowed_interactions into v_allowed
  from private.exam_prep_ai_policy
  where id=1;

  if v_allowed is null or not ('context_followup'=any(v_allowed)) then
    raise exception 'P1-04 limited follow-up interaction was not added';
  end if;

  if coalesce((
    public.get_exam_prep_ai_followup_policy_service_v1()
      ->> 'enabled'
  )::boolean,false) is not true then
    raise exception 'P1-04 follow-up policy service does not expose enabled state';
  end if;

  if has_function_privilege(
      'authenticated',
      'public.get_exam_prep_ai_followup_policy_service_v1()',
      'EXECUTE'
    )
     or has_function_privilege(
      'anon',
      'public.get_exam_prep_ai_followup_policy_service_v1()',
      'EXECUTE'
    )
  then
    raise exception 'P1-04 follow-up policy service leaked to browser role';
  end if;

  if not has_function_privilege(
      'service_role',
      'public.get_exam_prep_ai_followup_policy_service_v1()',
      'EXECUTE'
    )
  then
    raise exception 'P1-04 follow-up policy service missing service_role access';
  end if;

  if has_function_privilege(
      'authenticated',
      'public.get_exam_prep_ai_thread_parent_service_v1(uuid,uuid)',
      'EXECUTE'
    )
     or has_function_privilege(
      'anon',
      'public.get_exam_prep_ai_thread_parent_service_v1(uuid,uuid)',
      'EXECUTE'
    )
  then
    raise exception 'P1-04 thread parent service reader leaked to browser role';
  end if;

  if not has_function_privilege(
      'service_role',
      'public.get_exam_prep_ai_thread_parent_service_v1(uuid,uuid)',
      'EXECUTE'
    )
  then
    raise exception 'P1-04 thread parent service reader missing service_role access';
  end if;
end
$postcheck$;

commit;
