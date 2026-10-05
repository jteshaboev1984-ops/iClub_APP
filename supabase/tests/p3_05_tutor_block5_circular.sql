\set ON_ERROR_STOP on

do $test$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft' and not is_runtime_allowed;
  if v<>72 then raise exception 'Expected 72 learner-first drafts, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code in ('P1-CIR-01','P1-CIR-02','P1-CIR-03');
  if v<>9 then raise exception 'Expected 9 Circular Measure cards, found %',v; end if;

  if exists(
    select 1 from (
      select skill_code,count(*) n,count(distinct locale) locales
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code in ('P1-CIR-01','P1-CIR-02','P1-CIR-03')
      group by skill_code
      having count(*)<>3 or count(distinct locale)<>3
    ) x
  ) then raise exception 'Circular locale parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-CIR-01'
        and main_explanation like '%150%' and main_explanation like '%5π/6%'
        and main_explanation like '%2.4%' and main_explanation like '%137.5%')<>3
  then raise exception 'CIR01 example parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-CIR-02'
        and main_explanation like '%r=6%' and main_explanation like '%2π/3%'
        and main_explanation like '%4π%')<>3
  then raise exception 'CIR02 example parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-CIR-03'
        and main_explanation like '%r=8%' and main_explanation like '%π/3%'
        and main_explanation like '%32π/3%' and main_explanation like '%16√3%')<>3
  then raise exception 'CIR03 example parity drift'; end if;

  if (select count(distinct skill_code) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first')<>24
  then raise exception 'Expected 24 learner-first skills'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards where is_runtime_allowed)<>0
  then raise exception 'Tutor cards must remain runtime OFF'; end if;
end
$test$;

select 'P3-05 Block 5 Circular Measure: GREEN' as result;
