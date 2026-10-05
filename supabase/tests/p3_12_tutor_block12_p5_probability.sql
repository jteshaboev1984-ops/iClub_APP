\set ON_ERROR_STOP on

do $test$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft' and not is_runtime_allowed;
  if v<>201 then raise exception 'Block 12 expected 201 learner-first draft cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code like 'P5-PRO-%';
  if v<>18 then raise exception 'Block 12 expected 18 probability cards, found %',v; end if;

  if exists(
    select 1 from (
      select skill_code,count(*) n,count(distinct locale) locales
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code like 'P5-PRO-%'
      group by skill_code
      having count(*)<>3 or count(distinct locale)<>3
    ) x
  ) then raise exception 'Block 12 locale parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-01'
        and main_explanation like '%{HH, HT, TH, TT}%'
        and main_explanation like '%2/4 = 1/2%')<>3
  then raise exception 'PRO01 sample-space parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-02'
        and main_explanation like '%C(6,2)=15%'
        and main_explanation like '%C(3,2)=3%'
        and main_explanation like '%3/15=1/5%')<>3
  then raise exception 'PRO02 counting-probability parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-03'
        and main_explanation like '%P(A ∪ B)=P(A)+P(B)-P(A ∩ B)%'
        and main_explanation like '%3/6+2/6-1/6=4/6=2/3%')<>3
  then raise exception 'PRO03 addition/complement parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-04'
        and main_explanation like '%P(A ∩ B)=P(A)P(B|A)%'
        and main_explanation like '%1/2 × 1/6 = 1/12%')<>3
  then raise exception 'PRO04 multiplication/independence parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-05'
        and main_explanation like '%P(A|B)=P(A ∩ B)/P(B)%'
        and main_explanation like '%5/12%')<>3
  then raise exception 'PRO05 conditional-probability parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-06'
        and main_explanation like '%3/5 × 2/4 = 3/10%'
        and main_explanation like '%2/5 × 3/4 = 3/10%'
        and main_explanation like '%3/10+3/10=3/5%')<>3
  then raise exception 'PRO06 probability-tree parity drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v2_learner_first'
      and t.skill_code like 'P5-PRO-%'
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
  ) then raise exception 'Block 12 source linkage drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P5-PRO-%'
      and (
        main_explanation like '%P1-%'
        or main_explanation like '%P5-PRO-%'
        or lower(main_explanation) like '%source_card%'
        or lower(main_explanation) like '%action_code%'
        or lower(main_explanation) like '%item_type%'
        or lower(main_explanation) like '%mastery%'
      )
  ) then raise exception 'Block 12 leaked internal/cross-component terminology'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P5-PRO-%'
      and (
        position(E'\\n' in main_explanation)>0
        or position(E'\\n' in simple_explanation)>0
        or position(E'\\n' in alternative_explanation)>0
        or position(E'\\n' in focus_explanation)>0
      )
  ) then raise exception 'Block 12 contains literal backslash-n formatting'; end if;

  if (select count(distinct skill_code)
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first')<>67
  then raise exception 'Block 12 expected 67 learner-first skills total'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards where is_runtime_allowed)<>0
  then raise exception 'Tutor content must remain runtime OFF'; end if;
end
$test$;

select 'P3-12 Block 12 P5 Probability: GREEN' as result;
