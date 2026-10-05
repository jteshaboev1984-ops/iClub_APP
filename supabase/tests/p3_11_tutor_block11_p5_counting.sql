\set ON_ERROR_STOP on

do $test$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft' and not is_runtime_allowed;
  if v<>183 then raise exception 'Block 11 expected 183 learner-first draft cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code like 'P5-CNT-%';
  if v<>15 then raise exception 'Block 11 expected 15 counting cards, found %',v; end if;

  if exists(
    select 1 from (
      select skill_code,count(*) n,count(distinct locale) locales
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code like 'P5-CNT-%'
      group by skill_code
      having count(*)<>3 or count(distinct locale)<>3
    ) x
  ) then raise exception 'Block 11 locale parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-CNT-01'
        and main_explanation like '%4 × 3 × 2 = 24%'
        and main_explanation like '%4C3 = 4%')<>3
  then raise exception 'CNT01 ordered/unordered parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-CNT-02'
        and main_explanation like '%5! = 120%')<>3
  then raise exception 'CNT02 distinct-permutation parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-CNT-03'
        and main_explanation like '%LEVEL%'
        and main_explanation like '%5! / (2!2!) = 30%')<>3
  then raise exception 'CNT03 repeated-object parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-CNT-04'
        and main_explanation like '%4!×2 = 48%'
        and main_explanation like '%5! - 48 = 72%')<>3
  then raise exception 'CNT04 restriction parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-CNT-05'
        and main_explanation like '%8C3 = 56%'
        and main_explanation like '%8C3 × 3 = 56×3 = 168%')<>3
  then raise exception 'CNT05 combination parity drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v2_learner_first'
      and t.skill_code like 'P5-CNT-%'
      and (
        s.source_card_key is null
        or t.component_code<>'P5'
        or s.component_code<>t.component_code
        or s.skill_code<>t.skill_code
        or s.locale<>t.locale
        or s.card_type<>'theory'
        or s.approval_status<>'approved'
        or not s.is_runtime_allowed
      )
  ) then raise exception 'Block 11 source linkage drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first' and skill_code like 'P5-CNT-%'
      and (
        main_explanation like '%P1-%'
        or main_explanation like '%P5-CNT-%'
        or lower(main_explanation) like '%source_card%'
        or lower(main_explanation) like '%action_code%'
      )
  ) then raise exception 'Block 11 leaked internal/cross-component terminology'; end if;

  if (select count(distinct skill_code) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first')<>61
  then raise exception 'Block 11 expected 61 learner-first skills total'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards where is_runtime_allowed)<>0
  then raise exception 'Tutor content must remain runtime OFF'; end if;
end
$test$;

select 'P3-11 Block 11 P5 Permutations and Combinations: GREEN' as result;
