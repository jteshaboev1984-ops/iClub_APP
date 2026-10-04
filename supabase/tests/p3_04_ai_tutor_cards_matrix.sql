\set ON_ERROR_STOP on

do $test$
declare
  v_total integer;
  v_runtime integer;
  v_bad_links integer;
  v_bad_locale_groups integer;
  v_coverage jsonb;
begin
  if to_regclass('private.exam_prep_ai_tutor_cards') is null then
    raise exception 'Tutor Card table missing';
  end if;

  select count(*),count(*) filter(where is_runtime_allowed)
    into v_total,v_runtime
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first';

  if v_total<>9 then
    raise exception 'Expected 9 learner-first pilot Tutor Cards, found %',v_total;
  end if;
  if v_runtime<>0 then
    raise exception 'Learner-first pilot Tutor Cards must remain runtime OFF';
  end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v1'
        and skill_code in ('P1-QUA-01','P1-COO-02','P5-NOR-02')
        and approval_status='retired'
        and not is_runtime_allowed)<>9
  then
    raise exception 'Original pilot was not preserved as 9 retired non-runtime rows';
  end if;

  select count(*) into v_bad_links
  from private.exam_prep_ai_tutor_cards t
  left join private.exam_prep_ai_source_cards s
    on s.source_card_key=t.source_card_key
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

  if v_bad_links<>0 then
    raise exception 'Tutor Card source linkage drift: % bad rows',v_bad_links;
  end if;

  select count(*) into v_bad_locale_groups
  from (
    select skill_code,count(*) as n,count(distinct locale) as locale_n
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
    group by skill_code
    having count(*)<>3 or count(distinct locale)<>3
  ) x;

  if v_bad_locale_groups<>0 then
    raise exception 'Tutor pilot locale parity drift';
  end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and (
        char_length(main_explanation)<120
        or char_length(simple_explanation)<80
        or char_length(alternative_explanation)<100
        or char_length(focus_explanation)<60
      )
  ) then
    raise exception 'Tutor pilot contains unexpectedly thin learner-facing content';
  end if;

  -- Learner-first pilot must contain the same reviewed worked-example facts across EN/RU/UZ.
  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code='P1-QUA-01'
        and main_explanation like '%x² + 6x + 5%'
        and main_explanation like '%(-3, -4)%')<>3
  then
    raise exception 'P1-QUA-01 multilingual worked-example parity drift';
  end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code='P1-COO-02'
        and main_explanation like '%A(1, 2)%'
        and main_explanation like '%B(5, 10)%'
        and main_explanation like '%4√5%')<>3
  then
    raise exception 'P1-COO-02 multilingual worked-example parity drift';
  end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code='P5-NOR-02'
        and main_explanation like '%N(50, 8²)%'
        and main_explanation like '%1.5%'
        and main_explanation like '%0.0668%')<>3
  then
    raise exception 'P5-NOR-02 multilingual worked-example parity drift';
  end if;

  -- Completing-the-square card must not drift back into the whole Quadratics family.
  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code='P1-QUA-01'
      and (
        lower(main_explanation) like '%discriminant%'
        or lower(main_explanation) like '%дискриминант%'
        or lower(main_explanation) like '%diskriminant%'
        or lower(main_explanation) like '%quadratic inequality%'
        or lower(main_explanation) like '%квадратн% неравен%'
        or lower(main_explanation) like '%kvadrat tengsizlik%'
      )
  ) then
    raise exception 'P1-QUA-01 learner-first card drifted outside exact skill boundary';
  end if;

  if has_table_privilege('authenticated','private.exam_prep_ai_tutor_cards','SELECT')
     or has_table_privilege('anon','private.exam_prep_ai_tutor_cards','SELECT')
  then
    raise exception 'Tutor Card private storage leaked to browser';
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
    raise exception 'Tutor Card service lookup leaked to browser';
  end if;

  v_coverage:=public.get_exam_prep_ai_tutor_card_coverage_service_v1();
  if coalesce((v_coverage->>'expected')::integer,-1)<>243 then
    raise exception 'Tutor Card expected coverage must be 243, got %',v_coverage;
  end if;
  if coalesce((v_coverage->>'ready')::integer,-1)<>0 then
    raise exception 'Pilot must not make any Tutor Card runtime-ready: %',v_coverage;
  end if;
end
$test$;

do $negative$
begin
  begin
    update private.exam_prep_ai_tutor_cards
    set is_runtime_allowed=true
    where tutor_card_key='p1:P1-QUA-01:tutor:en:v2';
    raise exception 'Expected runtime-draft constraint failure';
  exception
    when check_violation then null;
  end;
end
$negative$;

select 'P3-04 curated Tutor Card matrix: GREEN' as result;
