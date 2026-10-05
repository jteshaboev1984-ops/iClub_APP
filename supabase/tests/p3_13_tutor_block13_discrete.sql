\set ON_ERROR_STOP on

do $test$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft' and not is_runtime_allowed;
  if v<>228 then raise exception 'Block 13 expected 228 learner-first draft cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and (
      skill_code like 'P5-DRV-%'
      or skill_code like 'P5-BIN-%'
      or skill_code like 'P5-GEO-%'
    );
  if v<>27 then raise exception 'Block 13 expected 27 discrete/binomial/geometric cards, found %',v; end if;

  if exists(
    select 1 from (
      select skill_code,count(*) n,count(distinct locale) locales
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and (
          skill_code like 'P5-DRV-%'
          or skill_code like 'P5-BIN-%'
          or skill_code like 'P5-GEO-%'
        )
      group by skill_code
      having count(*)<>3 or count(distinct locale)<>3
    ) x
  ) then raise exception 'Block 13 locale parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DRV-01'
        and main_explanation like '%0.2 + k + 0.5 = 1%'
        and main_explanation like '%k = 0.3%')<>3
  then raise exception 'DRV01 distribution parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DRV-02'
        and main_explanation like '%0(0.2)+1(0.3)+2(0.5)%'
        and main_explanation like '%1.3%')<>3
  then raise exception 'DRV02 expectation parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DRV-03'
        and main_explanation like '%E(X²)=0²(0.2)+1²(0.3)+2²(0.5)%'
        and main_explanation like '%0.61%'
        and main_explanation like '%0.781%')<>3
  then raise exception 'DRV03 variance parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-BIN-01'
        and main_explanation like '%n=10%'
        and main_explanation like '%p=0.7%')<>3
  then raise exception 'BIN01 model-condition parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-BIN-02'
        and main_explanation like '%5C2(0.4)²(0.6)³%'
        and main_explanation like '%0.3456%'
        and main_explanation like '%0.33696%')<>3
  then raise exception 'BIN02 probability parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-BIN-03'
        and main_explanation like '%20p=6%'
        and main_explanation like '%p=0.3%'
        and main_explanation like '%4.2%')<>3
  then raise exception 'BIN03 moment/inverse parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-GEO-01'
        and main_explanation like '%p=0.2%'
        and main_explanation like '%1,2,3,...%')<>3
  then raise exception 'GEO01 model parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-GEO-02'
        and main_explanation like '%0.140625%'
        and main_explanation like '%0.421875%'
        and main_explanation like '%0.578125%')<>3
  then raise exception 'GEO02 probability parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-GEO-03'
        and main_explanation like '%1/p = 5%'
        and main_explanation like '%p = 1/5 = 0.2%')<>3
  then raise exception 'GEO03 expectation parity drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v2_learner_first'
      and (
        t.skill_code like 'P5-DRV-%'
        or t.skill_code like 'P5-BIN-%'
        or t.skill_code like 'P5-GEO-%'
      )
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
  ) then raise exception 'Block 13 source linkage drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and (
        skill_code like 'P5-DRV-%'
        or skill_code like 'P5-BIN-%'
        or skill_code like 'P5-GEO-%'
      )
      and (
        main_explanation like '%P1-%'
        or main_explanation like '%P5-DRV-%'
        or main_explanation like '%P5-BIN-%'
        or main_explanation like '%P5-GEO-%'
        or lower(main_explanation) like '%source_card%'
        or lower(main_explanation) like '%action_code%'
        or lower(main_explanation) like '%item_type%'
        or lower(main_explanation) like '%mastery%'
      )
  ) then raise exception 'Block 13 leaked internal/cross-component terminology'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and (
        skill_code like 'P5-DRV-%'
        or skill_code like 'P5-BIN-%'
        or skill_code like 'P5-GEO-%'
      )
      and (
        position(E'\\n' in main_explanation)>0
        or position(E'\\n' in simple_explanation)>0
        or position(E'\\n' in alternative_explanation)>0
        or position(E'\\n' in focus_explanation)>0
      )
  ) then raise exception 'Block 13 contains literal backslash-n formatting'; end if;

  if (select count(distinct skill_code)
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first')<>76
  then raise exception 'Block 13 expected 76 learner-first skills total'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards where is_runtime_allowed)<>0
  then raise exception 'Tutor content must remain runtime OFF'; end if;
end
$test$;

select 'P3-13 Block 13 P5 Discrete/Binomial/Geometric: GREEN' as result;
