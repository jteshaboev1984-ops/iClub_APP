\set ON_ERROR_STOP on

do $test$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft'
    and not is_runtime_allowed;
  if v<>123 then raise exception 'Block 8 expected 123 learner-first draft cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code like 'P1-DIF-%';
  if v<>21 then raise exception 'Block 8 expected 21 Differentiation cards, found %',v; end if;

  if exists(
    select 1 from (
      select skill_code,count(*) n,count(distinct locale) locales
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code like 'P1-DIF-%'
      group by skill_code
      having count(*)<>3 or count(distinct locale)<>3
    ) x
  ) then raise exception 'Block 8 locale parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-DIF-01'
        and main_explanation like '%f(x)=x²%'
        and main_explanation like '%x=3%'
        and main_explanation like '%6+h%'
        and main_explanation like '%f''(3)=6%')<>3
  then raise exception 'DIF01 derivative-meaning parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-DIF-02'
        and main_explanation like '%y=4x³+3√x%'
        and main_explanation like '%12x²%'
        and main_explanation like '%3/(2√x)%')<>3
  then raise exception 'DIF02 power-rule parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-DIF-03'
        and main_explanation like '%y=(3x-1)^4%'
        and main_explanation like '%12(3x-1)^3%')<>3
  then raise exception 'DIF03 chain-rule parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-DIF-04'
        and main_explanation like '%(2,4)%'
        and main_explanation like '%y-4=4(x-2)%'
        and main_explanation like '%y-4=-(1/4)(x-2)%')<>3
  then raise exception 'DIF04 tangent-normal parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-DIF-05'
        and main_explanation like '%y=x³-3x%'
        and main_explanation like '%x<-1%'
        and main_explanation like '%-1<x<1%'
        and main_explanation like '%x>1%')<>3
  then raise exception 'DIF05 monotonicity parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-DIF-06'
        and main_explanation like '%A=πr²%'
        and main_explanation like '%dr/dt=2 cm/s%'
        and main_explanation like '%r=5%'
        and main_explanation like '%20π cm²/s%')<>3
  then raise exception 'DIF06 connected-rate parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-DIF-07'
        and main_explanation like '%y=x³-3x%'
        and main_explanation like '%(-1,2)%'
        and main_explanation like '%(1,-2)%')<>3
  then raise exception 'DIF07 stationary-point parity drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v2_learner_first'
      and t.skill_code like 'P1-DIF-%'
      and (
        s.source_card_key is null
        or s.component_code<>t.component_code
        or s.skill_code<>t.skill_code
        or s.locale<>t.locale
        or s.card_type<>'theory'
        or s.approval_status<>'approved'
        or not s.is_runtime_allowed
      )
  ) then raise exception 'Block 8 source-card linkage drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P1-DIF-%'
      and (
        lower(main_explanation) like '%product rule%'
        or lower(main_explanation) like '%quotient rule%'
        or lower(main_explanation) like '%implicit differentiation%'
        or lower(main_explanation) like '%parametric differentiation%'
        or lower(main_explanation) like '%ln x%'
        or lower(main_explanation) like '%e^x%'
      )
  ) then raise exception 'Block 8 leaked post-P1 differentiation content'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P1-DIF-%'
      and (
        position(E'\\n' in main_explanation)>0
        or position(E'\\n' in simple_explanation)>0
        or position(E'\\n' in alternative_explanation)>0
        or position(E'\\n' in focus_explanation)>0
      )
  ) then raise exception 'Block 8 contains literal backslash-n formatting'; end if;

  if (select count(distinct skill_code)
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first')<>41
  then raise exception 'Block 8 expected 41 learner-first skills total'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards where is_runtime_allowed)<>0
  then raise exception 'Tutor content must remain runtime OFF'; end if;
end
$test$;

select 'P3-08 Block 8 Differentiation: GREEN' as result;
