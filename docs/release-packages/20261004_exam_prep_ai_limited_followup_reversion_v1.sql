-- iClub Exam Prep AI limited-follow-up reversion v1.
-- NOT applied automatically. Removes only contextual follow-up availability.
-- Core AI explanations, entitlements, academic state and legacy history remain unchanged.

begin;
set local lock_timeout='3s';
set local statement_timeout='60s';

do $precheck$
declare
  v_policy private.exam_prep_ai_policy%rowtype;
begin
  select * into v_policy
  from private.exam_prep_ai_policy
  where id=1
  for update;

  if v_policy.id is null then
    raise exception 'AI policy missing; refusing follow-up reversion';
  end if;

  if not ('context_followup'=any(v_policy.allowed_interactions)) then
    raise exception 'context_followup is not enabled; refusing ambiguous reversion';
  end if;
end
$precheck$;

update private.exam_prep_ai_policy
set allowed_interactions=array_remove(allowed_interactions,'context_followup'),
    policy_version='exam_prep_ai_policy_v1_2_followup_reverted',
    prompt_version='exam_prep_ai_prompt_v1_2_followup_reverted',
    response_schema_version='exam_prep_ai_response_v1_1_followup_reverted',
    updated_at=now()
where id=1;

do $postcheck$
declare
  v_allowed text[];
begin
  select allowed_interactions into v_allowed
  from private.exam_prep_ai_policy
  where id=1;

  if 'context_followup'=any(v_allowed) then
    raise exception 'context_followup remained enabled after reversion';
  end if;

  if coalesce((
    public.get_exam_prep_ai_followup_policy_service_v1()
      ->> 'enabled'
  )::boolean,false) is true then
    raise exception 'follow-up policy service still exposes context_followup after reversion';
  end if;
end
$postcheck$;

commit;
