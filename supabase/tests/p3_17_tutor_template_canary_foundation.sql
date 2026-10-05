\set ON_ERROR_STOP on

do $test$
declare
  v_policy private.exam_prep_ai_tutor_template_policy%rowtype;
  v_gate jsonb;
begin
  select * into strict v_policy
  from private.exam_prep_ai_tutor_template_policy
  where id=1;

  if v_policy.template_canary_enabled then
    raise exception 'P3-17 canary foundation must remain OFF before operational activation';
  end if;

  if not v_policy.preset_followups_enabled then
    raise exception 'P3-17 preset follow-up capability must be configured for the later canary';
  end if;

  if v_policy.cohort_key<>'math_as_p1_p5_beta_2026_09_01'
     or v_policy.policy_version<>'tutor_template_canary_v1' then
    raise exception 'P3-17 canary policy identity drift: %',row_to_json(v_policy);
  end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and approval_status='approved'
        and is_runtime_allowed)<>243
  then
    raise exception 'P3-17 requires 243 approved/runtime Tutor Cards';
  end if;

  if public.get_exam_prep_ai_tutor_card_coverage_service_v1()
     <> '{"expected":243,"ready":243,"missing":0,"p1_ready":135,"p5_ready":108}'::jsonb
  then
    raise exception 'P3-17 Tutor coverage is not 243/243: %',
      public.get_exam_prep_ai_tutor_card_coverage_service_v1();
  end if;

  v_gate:=public.get_exam_prep_ai_tutor_template_canary_service_v1(
    '00000000-0000-4000-8000-000000000001'::uuid
  );

  if coalesce((v_gate->>'enabled')::boolean,true) then
    raise exception 'P3-17 default-OFF canary unexpectedly enabled for an arbitrary user';
  end if;

  if coalesce((v_gate->>'preset_followups_enabled')::boolean,false) is not true then
    raise exception 'P3-17 service did not expose preset follow-up configuration';
  end if;

  if has_table_privilege(
       'authenticated',
       'private.exam_prep_ai_tutor_template_policy',
       'SELECT'
     )
     or has_table_privilege(
       'anon',
       'private.exam_prep_ai_tutor_template_policy',
       'SELECT'
     )
  then
    raise exception 'P3-17 Tutor Template policy leaked to browser role';
  end if;

  if has_function_privilege(
       'authenticated',
       'public.get_exam_prep_ai_tutor_template_canary_service_v1(uuid)',
       'EXECUTE'
     )
     or has_function_privilege(
       'anon',
       'public.get_exam_prep_ai_tutor_template_canary_service_v1(uuid)',
       'EXECUTE'
     )
  then
    raise exception 'P3-17 Tutor Template canary service leaked to browser role';
  end if;

  if not has_function_privilege(
       'service_role',
       'public.get_exam_prep_ai_tutor_template_canary_service_v1(uuid)',
       'EXECUTE'
     )
  then
    raise exception 'P3-17 Tutor Template canary service missing service-role access';
  end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards where is_runtime_allowed)<>243 then
    raise exception 'P3-17 canary foundation unexpectedly changed Tutor Card runtime count';
  end if;
end
$test$;

select 'P3-17 Tutor Template canary foundation — GREEN' as result;
