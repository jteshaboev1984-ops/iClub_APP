-- EMERGENCY REVERSION ONLY — Tutor Content approval/runtime-readiness v1.
-- Do not run during normal operation.
-- Reverts only governance fields for tutor_v2_learner_first.
-- It does not touch learner state, source cards, evidence, entitlements, Practice, Tours, ratings, certificates or localStorage.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $precheck$
declare
  v_ready integer;
begin
  select count(*) into v_ready
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='approved'
    and is_runtime_allowed;

  if v_ready<>243 then
    raise exception 'Tutor approval reversion requires exactly 243 approved/runtime cards, found %',v_ready;
  end if;
end
$precheck$;

update private.exam_prep_ai_tutor_cards
set approval_status='draft',
    is_runtime_allowed=false,
    approved_at=null,
    approved_by=null,
    updated_at=now()
where content_version='tutor_v2_learner_first'
  and approval_status='approved'
  and is_runtime_allowed;

do $postcheck$
begin
  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and approval_status='draft'
        and not is_runtime_allowed)<>243
  then
    raise exception 'Tutor approval reversion did not restore 243 DRAFT/runtime-OFF cards';
  end if;

  if coalesce((public.get_exam_prep_ai_tutor_card_coverage_service_v1()->>'ready')::integer,-1)<>0
  then
    raise exception 'Tutor approval reversion expected ready=0';
  end if;
end
$postcheck$;

commit;
