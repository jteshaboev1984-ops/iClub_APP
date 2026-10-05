\set ON_ERROR_STOP on

do $test$
declare
  v integer;
  v_cov jsonb;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='approved'
    and is_runtime_allowed
    and approved_at is not null;
  if v<>243 then
    raise exception 'P3-16 expected 243 approved/runtime Tutor Cards, found %',v;
  end if;

  select count(distinct skill_code) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='approved'
    and is_runtime_allowed;
  if v<>81 then
    raise exception 'P3-16 expected 81 approved/runtime skills, found %',v;
  end if;

  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and (
        approval_status<>'approved'
        or not is_runtime_allowed
        or approved_at is null
      )
  ) then
    raise exception 'P3-16 found learner-first card not fully approved/runtime-ready';
  end if;

  with expected as (
    select n.component_code,n.skill_code,l.locale
    from private.exam_prep_syllabus_nodes n
    join private.exam_prep_program_versions pv on pv.id=n.program_version_id
    cross join (values ('en'),('ru'),('uz')) l(locale)
    where pv.program_key='math_as_p1_p5'
      and pv.version_key='p1_p5_canonical_v1_0'
      and pv.status='active'
      and n.component_code in ('P1','P5')
  )
  select count(*) into v
  from expected e
  where public.get_exam_prep_ai_tutor_card_service_v1(
    e.component_code,e.skill_code,e.locale
  ) <> '{}'::jsonb;

  if v<>243 then
    raise exception 'P3-16 expected 243 service-readable Tutor Cards, found %',v;
  end if;

  v_cov:=public.get_exam_prep_ai_tutor_card_coverage_service_v1();

  if coalesce((v_cov->>'expected')::integer,-1)<>243
     or coalesce((v_cov->>'ready')::integer,-1)<>243
     or coalesce((v_cov->>'missing')::integer,-1)<>0
     or coalesce((v_cov->>'p1_ready')::integer,-1)<>135
     or coalesce((v_cov->>'p5_ready')::integer,-1)<>108
  then
    raise exception 'P3-16 coverage mismatch: %',v_cov;
  end if;

  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v2_learner_first'
      and (
        s.source_card_key is null
        or s.component_code<>t.component_code
        or s.skill_code<>t.skill_code
        or s.locale<>t.locale
        or s.card_type<>'theory'
        or s.approval_status<>'approved'
        or not s.is_runtime_allowed
      )
  ) then
    raise exception 'P3-16 source-card linkage drift';
  end if;

  if has_table_privilege('authenticated','private.exam_prep_ai_tutor_cards','SELECT')
     or has_table_privilege('anon','private.exam_prep_ai_tutor_cards','SELECT')
  then
    raise exception 'P3-16 private Tutor storage leaked to browser role';
  end if;

  if has_function_privilege(
       'authenticated',
       'public.get_exam_prep_ai_tutor_card_service_v1(text,text,text)',
       'EXECUTE'
     )
     or has_function_privilege(
       'anon',
       'public.get_exam_prep_ai_tutor_card_service_v1(text,text,text)',
       'EXECUTE'
     )
  then
    raise exception 'P3-16 Tutor lookup leaked to browser role';
  end if;

  if not has_function_privilege(
       'service_role',
       'public.get_exam_prep_ai_tutor_card_service_v1(text,text,text)',
       'EXECUTE'
     )
  then
    raise exception 'P3-16 Tutor lookup missing service-role access';
  end if;
end
$test$;

select 'P3-16 Tutor 243 Approval / Runtime-Readiness — GREEN' as result;
