\set ON_ERROR_STOP on

do $test$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft'
    and not is_runtime_allowed;
  if v<>87 then raise exception 'Block 6 expected 87 learner-first draft cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code in ('P1-TRI-01','P1-TRI-02','P1-TRI-03','P1-TRI-04','P1-TRI-05');
  if v<>15 then raise exception 'Block 6 expected 15 Trigonometry cards, found %',v; end if;

  if exists(
    select 1 from (
      select skill_code,count(*) n,count(distinct locale) locales
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code like 'P1-TRI-%'
      group by skill_code
      having count(*)<>3 or count(distinct locale)<>3
    ) x
  ) then raise exception 'Block 6 locale parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-TRI-01'
        and main_explanation like '%2 sin x + 1%'
        and main_explanation like '%2π%'
        and main_explanation like '%3%'
        and main_explanation like '%-1%')<>3
  then raise exception 'TRI01 transformation parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-TRI-02'
        and main_explanation like '%sin(5π/6)=1/2%'
        and main_explanation like '%cos(2π/3)=-1/2%')<>3
  then raise exception 'TRI02 exact-value parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-TRI-03'
        and main_explanation like '%arcsin(1/2)=π/6%'
        and main_explanation like '%arccos(-1/2)=2π/3%'
        and main_explanation like '%arctan(1)=π/4%')<>3
  then raise exception 'TRI03 inverse-trig parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-TRI-04'
        and main_explanation like '%sin²x + cos²x = 1%'
        and main_explanation like '%tan x = sin x / cos x%'
        and main_explanation like '%1 + cos x%')<>3
  then raise exception 'TRI04 identity parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-TRI-05'
        and main_explanation like '%sin x = 1/2%'
        and main_explanation like '%0 ≤ x ≤ 2π%'
        and main_explanation like '%π/6%'
        and main_explanation like '%5π/6%')<>3
  then raise exception 'TRI05 equation parity drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v2_learner_first'
      and t.skill_code like 'P1-TRI-%'
      and (
        s.source_card_key is null
        or s.component_code<>t.component_code
        or s.skill_code<>t.skill_code
        or s.locale<>t.locale
        or s.card_type<>'theory'
        or s.approval_status<>'approved'
        or not s.is_runtime_allowed
      )
  ) then raise exception 'Block 6 source-card linkage drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P1-TRI-%'
      and (
        main_explanation like '%sin(x+y)%'
        or main_explanation like '%cos(x+y)%'
        or main_explanation like '%sin(2x)%'
        or main_explanation like '%cos(2x)%'
      )
  ) then raise exception 'Block 6 leaked post-P1 trig formulae'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P1-TRI-%'
      and (
        position(E'\\n' in main_explanation)>0
        or position(E'\\n' in simple_explanation)>0
        or position(E'\\n' in alternative_explanation)>0
        or position(E'\\n' in focus_explanation)>0
      )
  ) then raise exception 'Block 6 contains literal backslash-n formatting'; end if;

  if (select count(distinct skill_code)
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first')<>29
  then raise exception 'Block 6 expected 29 learner-first skills total'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards where is_runtime_allowed)<>0
  then raise exception 'Tutor content must remain runtime OFF'; end if;
end
$test$;

select 'P3-06 Block 6 Trigonometry: GREEN' as result;
