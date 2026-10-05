-- Tutor Content governance approval / runtime-readiness v1.
-- Makes the fully reviewed tutor_v2_learner_first corpus service-readable.
-- DOES NOT switch the production AI topic-explanation path to Tutor Cards.
-- Additive governance state only; no learner academic state, entitlement, legacy, or localStorage writes.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $precheck$
declare
  v_total integer;
  v_skills integer;
  v_draft integer;
  v_approved integer;
  v_runtime integer;
  v_bad_source integer;
  v_bad_hash integer;
begin
  select count(*),count(distinct skill_code),
         count(*) filter(where approval_status='draft' and not is_runtime_allowed),
         count(*) filter(where approval_status='approved'),
         count(*) filter(where is_runtime_allowed)
    into v_total,v_skills,v_draft,v_approved,v_runtime
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first';

  if v_total<>243 or v_skills<>81 then
    raise exception 'Tutor approval requires exact 243 cards / 81 skills, found % / %',v_total,v_skills;
  end if;

  if v_draft<>243 or v_approved<>0 or v_runtime<>0 then
    raise exception 'Tutor approval requires all 243 cards DRAFT/runtime OFF before promotion: draft %, approved %, runtime %',
      v_draft,v_approved,v_runtime;
  end if;

  select count(*) into v_bad_source
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
    );

  if v_bad_source<>0 then
    raise exception 'Tutor approval source-link precheck failed for % cards',v_bad_source;
  end if;

  select count(*) into v_bad_hash
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and content_hash <> md5(concat_ws('||',
      content_version,title,main_explanation,simple_explanation,
      alternative_explanation,focus_explanation,source_card_key
    ));

  if v_bad_hash<>0 then
    raise exception 'Tutor approval found % stale content hashes',v_bad_hash;
  end if;
end
$precheck$;

update private.exam_prep_ai_tutor_cards
set approval_status='approved',
    is_runtime_allowed=true,
    approved_at=now(),
    approved_by=null,
    updated_at=now()
where content_version='tutor_v2_learner_first'
  and approval_status='draft'
  and not is_runtime_allowed;

do $postcheck$
declare
  v_promoted integer;
  v_lookup_ready integer;
  v_coverage jsonb;
begin
  select count(*) into v_promoted
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='approved'
    and is_runtime_allowed
    and approved_at is not null;

  if v_promoted<>243 then
    raise exception 'Tutor approval expected 243 approved/runtime cards, found %',v_promoted;
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
  select count(*) into v_lookup_ready
  from expected e
  where public.get_exam_prep_ai_tutor_card_service_v1(
    e.component_code,e.skill_code,e.locale
  ) <> '{}'::jsonb;

  if v_lookup_ready<>243 then
    raise exception 'Tutor approval expected 243 service-readable cards, found %',v_lookup_ready;
  end if;

  v_coverage:=public.get_exam_prep_ai_tutor_card_coverage_service_v1();

  if coalesce((v_coverage->>'expected')::integer,-1)<>243
     or coalesce((v_coverage->>'ready')::integer,-1)<>243
     or coalesce((v_coverage->>'missing')::integer,-1)<>0
     or coalesce((v_coverage->>'p1_ready')::integer,-1)<>135
     or coalesce((v_coverage->>'p5_ready')::integer,-1)<>108
  then
    raise exception 'Tutor approval coverage mismatch: %',v_coverage;
  end if;

  if has_table_privilege('authenticated','private.exam_prep_ai_tutor_cards','SELECT')
     or has_table_privilege('anon','private.exam_prep_ai_tutor_cards','SELECT')
  then
    raise exception 'Tutor approval leaked private Tutor storage to browser role';
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
    raise exception 'Tutor approval leaked service lookup to browser role';
  end if;
end
$postcheck$;

commit;
