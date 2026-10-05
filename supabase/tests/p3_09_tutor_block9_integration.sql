\set ON_ERROR_STOP on

do $test$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft'
    and not is_runtime_allowed;
  if v<>138 then raise exception 'Block 9 expected 138 learner-first draft cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code like 'P1-INT-%';
  if v<>15 then raise exception 'Block 9 expected 15 Integration cards, found %',v; end if;

  if exists(
    select 1 from (
      select skill_code,count(*) n,count(distinct locale) locales
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code like 'P1-INT-%'
      group by skill_code
      having count(*)<>3 or count(distinct locale)<>3
    ) x
  ) then raise exception 'Block 9 locale parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-INT-01'
        and main_explanation like '%6x²%'
        and main_explanation like '%4(2x+1)³%'
        and main_explanation like '%2x³%'
        and main_explanation like '%1/2(2x+1)⁴%')<>3
  then raise exception 'INT01 antiderivative parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-INT-02'
        and main_explanation like '%dy/dx = 6x - 4%'
        and main_explanation like '%(2,5)%'
        and main_explanation like '%C=1%'
        and main_explanation like '%3x² - 4x + 1%')<>3
  then raise exception 'INT02 constant-of-integration parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-INT-03'
        and main_explanation like '%0%'
        and main_explanation like '%4%'
        and main_explanation like '%x^(-1/2)%'
        and main_explanation like '%2√x%'
        and main_explanation like '%= 4%')<>3
  then raise exception 'INT03 definite-integral parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-INT-04'
        and main_explanation like '%y=x%'
        and main_explanation like '%y=x²%'
        and main_explanation like '%0≤x≤1%'
        and main_explanation like '%1/6%')<>3
  then raise exception 'INT04 area parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-INT-05'
        and main_explanation like '%y=x%'
        and main_explanation like '%0≤x≤2%'
        and main_explanation like '%8π/3%')<>3
  then raise exception 'INT05 volume parity drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v2_learner_first'
      and t.skill_code like 'P1-INT-%'
      and (
        s.source_card_key is null
        or s.component_code<>t.component_code
        or s.skill_code<>t.skill_code
        or s.locale<>t.locale
        or s.card_type<>'theory'
        or s.approval_status<>'approved'
        or not s.is_runtime_allowed
      )
  ) then raise exception 'Block 9 source-card linkage drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P1-INT-%'
      and (
        lower(main_explanation) like '%integration by parts%'
        or lower(main_explanation) like '%logarithm%'
        or lower(main_explanation) like '%exponential integral%'
        or lower(main_explanation) like '%trigonometric integration%'
      )
  ) then raise exception 'Block 9 leaked post-P1 integration content'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P1-INT-%'
      and (
        position(E'\\n' in main_explanation)>0
        or position(E'\\n' in simple_explanation)>0
        or position(E'\\n' in alternative_explanation)>0
        or position(E'\\n' in focus_explanation)>0
      )
  ) then raise exception 'Block 9 contains literal backslash-n formatting'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code like 'P1-%')<>135
  then raise exception 'P1 milestone expected 135 learner-first cards'; end if;

  if (select count(distinct skill_code) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code like 'P1-%')<>45
  then raise exception 'P1 milestone expected all 45 canonical skills'; end if;

  if (select count(distinct skill_code)
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first')<>46
  then raise exception 'Block 9 expected 46 learner-first skills total including P5 pilot'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards where is_runtime_allowed)<>0
  then raise exception 'Tutor content must remain runtime OFF'; end if;
end
$test$;

select 'P3-09 Block 9 Integration and full P1 Tutor coverage: GREEN' as result;
