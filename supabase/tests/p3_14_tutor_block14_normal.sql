\set ON_ERROR_STOP on

do $test$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft' and not is_runtime_allowed;
  if v<>243 then raise exception 'Block 14 expected 243 learner-first draft cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code like 'P5-NOR-%';
  if v<>18 then raise exception 'Block 14 expected 18 total normal-distribution cards, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code='P5-NOR-02')<>3
  then raise exception 'Existing P5-NOR-02 pilot card set was duplicated or lost'; end if;

  if exists(
    select 1 from (
      select skill_code,count(*) n,count(distinct locale) locales
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code like 'P5-NOR-%'
      group by skill_code
      having count(*)<>3 or count(distinct locale)<>3
    ) x
  ) then raise exception 'Block 14 locale parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-NOR-01'
        and main_explanation like '%X ~ N(70,8²)%'
        and main_explanation like '%μ-σ = 62%'
        and main_explanation like '%μ+σ = 78%')<>3
  then raise exception 'NOR01 model parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-NOR-03'
        and main_explanation like '%X ~ N(100,15²)%'
        and main_explanation like '%P(-1<Z<1)%'
        and main_explanation like '%0.6827%')<>3
  then raise exception 'NOR03 direct-probability parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-NOR-04'
        and main_explanation like '%P(X<x)=0.90%'
        and main_explanation like '%z≈1.282%'
        and main_explanation like '%62.82%')<>3
  then raise exception 'NOR04 inverse-normal parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-NOR-05'
        and main_explanation like '%P(X<44)=0.1587%'
        and main_explanation like '%P(X<56)=0.8413%'
        and main_explanation like '%μ=50%'
        and main_explanation like '%σ=6%')<>3
  then raise exception 'NOR05 unknown-parameter parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-NOR-06'
        and main_explanation like '%X ~ B(100,0.4)%'
        and main_explanation like '%P(Y<45.5)%'
        and main_explanation like '%1.123%'
        and main_explanation like '%0.8692%')<>3
  then raise exception 'NOR06 approximation parity drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v2_learner_first'
      and t.skill_code like 'P5-NOR-%'
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
  ) then raise exception 'Block 14 source linkage drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P5-NOR-%'
      and (
        main_explanation like '%P1-%'
        or main_explanation like '%P5-NOR-%'
        or lower(main_explanation) like '%source_card%'
        or lower(main_explanation) like '%action_code%'
        or lower(main_explanation) like '%item_type%'
        or lower(main_explanation) like '%mastery%'
      )
  ) then raise exception 'Block 14 leaked internal/cross-component terminology'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P5-NOR-%'
      and (
        position(E'\\n' in main_explanation)>0
        or position(E'\\n' in simple_explanation)>0
        or position(E'\\n' in alternative_explanation)>0
        or position(E'\\n' in focus_explanation)>0
      )
  ) then raise exception 'Block 14 contains literal backslash-n formatting'; end if;

  if (select count(distinct skill_code)
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first')<>81
  then raise exception 'Block 14 expected all 81 canonical skills authored'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards where is_runtime_allowed)<>0
  then raise exception 'Tutor content must remain runtime OFF after authoring completion'; end if;
end
$test$;

select 'P3-14 Block 14 P5 Normal Distribution — 243/243 authored: GREEN' as result;
