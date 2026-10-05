\set ON_ERROR_STOP on

do $test$
declare
  v_total integer;
  v_block integer;
  v_bad_link integer;
begin
  select count(*) into v_total
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft'
    and not is_runtime_allowed;

  if v_total<>168 then
    raise exception 'Block 10 expected 168 learner-first draft cards, found %',v_total;
  end if;

  select count(*) into v_block
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code like 'P5-DAT-%';

  if v_block<>30 then
    raise exception 'Block 10 expected 30 P5 data cards, found %',v_block;
  end if;

  if exists(
    select 1 from (
      select skill_code,count(*) n,count(distinct locale) locales
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code like 'P5-DAT-%'
      group by skill_code
      having count(*)<>3 or count(distinct locale)<>3
    ) x
  ) then
    raise exception 'Block 10 locale parity drift';
  end if;

  select count(*) into v_bad_link
  from private.exam_prep_ai_tutor_cards t
  left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
  where t.content_version='tutor_v2_learner_first'
    and t.skill_code like 'P5-DAT-%'
    and (
      s.source_card_key is null
      or t.component_code<>'P5'
      or s.component_code<>t.component_code
      or s.skill_code<>t.skill_code
      or s.locale<>t.locale
      or s.card_type<>'theory'
      or s.approval_status<>'approved'
      or not s.is_runtime_allowed
    );

  if v_bad_link<>0 then raise exception 'Block 10 source linkage drift: %',v_bad_link; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DAT-02'
        and main_explanation like '%12%'
        and main_explanation like '%21%'
        and main_explanation like '%29%')<>3
  then raise exception 'DAT02 worked-example parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DAT-03'
        and main_explanation like '%Q1=7%'
        and main_explanation like '%Q3=15%'
        and main_explanation like '%IQR = 15 - 7 = 8%')<>3
  then raise exception 'DAT03 five-number-summary parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DAT-04'
        and main_explanation like '%0-10%'
        and main_explanation like '%20/10 = 2%'
        and main_explanation like '%30/20 = 1.5%')<>3
  then raise exception 'DAT04 histogram parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DAT-05'
        and main_explanation like '%80%'
        and main_explanation like '%20%'
        and main_explanation like '%40%'
        and main_explanation like '%60%'
        and main_explanation like '%72%')<>3
  then raise exception 'DAT05 cumulative-frequency parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DAT-06'
        and main_explanation like '%2, 4, 4, 7, 8%'
        and main_explanation like '%= 5%'
        and main_explanation like '%4%')<>3
  then raise exception 'DAT06 location-measures parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DAT-07'
        and main_explanation like '%Q1=4%'
        and main_explanation like '%Q3=10%'
        and main_explanation like '%IQR = 10 - 4 = 6%')<>3
  then raise exception 'DAT07 spread parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DAT-08'
        and main_explanation like '%52%'
        and main_explanation like '%8%'
        and main_explanation like '%48%'
        and main_explanation like '%14%')<>3
  then raise exception 'DAT08 comparison parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DAT-09'
        and main_explanation like '%n=5%'
        and main_explanation like '%Σx=30%'
        and main_explanation like '%Σx²=220%'
        and main_explanation like '%√8%')<>3
  then raise exception 'DAT09 summary-totals parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DAT-10'
        and main_explanation like '%20×50 = 1000%'
        and main_explanation like '%30×60 = 1800%'
        and main_explanation like '%2800/50 = 56%'
        and main_explanation like '%x=10y+50%'
        and main_explanation like '%x̄=10(1.2)+50=62%')<>3
  then raise exception 'DAT10 coded/combined parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code='P5-NOR-02')<>3
  then raise exception 'Existing P5-NOR-02 pilot was duplicated or lost'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P5-DAT-%'
      and (
        position(E'\\n' in main_explanation)>0
        or position(E'\\n' in simple_explanation)>0
        or position(E'\\n' in alternative_explanation)>0
        or position(E'\\n' in focus_explanation)>0
      )
  ) then raise exception 'Block 10 contains literal backslash-n formatting'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P5-DAT-%'
      and (
        main_explanation like '%P1-%'
        or main_explanation like '%P5-DAT-%'
        or lower(main_explanation) like '%source_card%'
        or lower(main_explanation) like '%action_code%'
        or lower(main_explanation) like '%item_type%'
      )
  ) then raise exception 'Block 10 learner-facing content leaked internal/cross-component terminology'; end if;

  if (select count(distinct skill_code) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first')<>56
  then raise exception 'Block 10 expected 56 learner-first skills total'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards where is_runtime_allowed)<>0
  then raise exception 'Tutor content must remain runtime OFF'; end if;
end
$test$;

select 'P3-10 Block 10 P5 Representation of Data: GREEN' as result;
