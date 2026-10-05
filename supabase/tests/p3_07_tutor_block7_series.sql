\set ON_ERROR_STOP on

do $test$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft'
    and not is_runtime_allowed;
  if v<>102 then raise exception 'Block 7 expected 102 learner-first draft cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code in ('P1-SER-01','P1-SER-02','P1-SER-03','P1-SER-04','P1-SER-05');
  if v<>15 then raise exception 'Block 7 expected 15 Series cards, found %',v; end if;

  if exists(
    select 1 from (
      select skill_code,count(*) n,count(distinct locale) locales
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
        and skill_code like 'P1-SER-%'
      group by skill_code
      having count(*)<>3 or count(distinct locale)<>3
    ) x
  ) then raise exception 'Block 7 locale parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-SER-01'
        and main_explanation like '%(2+x)⁴%'
        and main_explanation like '%16 + 32x + 24x² + 8x³ + x⁴%'
        and main_explanation like '%24%')<>3
  then raise exception 'SER01 binomial-example parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-SER-02'
        and main_explanation like '%3, 7, 11, 15%'
        and main_explanation like '%2, 6, 18, 54%'
        and main_explanation like '%1, 2, 4, 7%')<>3
  then raise exception 'SER02 recognition-example parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-SER-03'
        and main_explanation like '%a=5%'
        and main_explanation like '%d=3%'
        and main_explanation like '%u_10%'
        and main_explanation like '%185%')<>3
  then raise exception 'SER03 arithmetic-example parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-SER-04'
        and main_explanation like '%a=3%'
        and main_explanation like '%r=2%'
        and main_explanation like '%u_6%'
        and main_explanation like '%189%')<>3
  then raise exception 'SER04 geometric-example parity drift'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-SER-05'
        and main_explanation like '%|r| < 1%'
        and main_explanation like '%a=12%'
        and main_explanation like '%r=1/3%'
        and main_explanation like '%18%')<>3
  then raise exception 'SER05 infinity-example parity drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v2_learner_first'
      and t.skill_code like 'P1-SER-%'
      and (
        s.source_card_key is null
        or s.component_code<>t.component_code
        or s.skill_code<>t.skill_code
        or s.locale<>t.locale
        or s.card_type<>'theory'
        or s.approval_status<>'approved'
        or not s.is_runtime_allowed
      )
  ) then raise exception 'Block 7 source-card linkage drift'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code='P1-SER-01'
      and (
        lower(main_explanation) like '%negative power%'
        or lower(main_explanation) like '%rational power%'
        or lower(main_explanation) like '%approximation%'
      )
  ) then raise exception 'SER01 drifted into post-P1 binomial content'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P1-SER-%'
      and (
        position(E'\\n' in main_explanation)>0
        or position(E'\\n' in simple_explanation)>0
        or position(E'\\n' in alternative_explanation)>0
        or position(E'\\n' in focus_explanation)>0
      )
  ) then raise exception 'Block 7 contains literal backslash-n formatting'; end if;

  if (select count(distinct skill_code)
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first')<>34
  then raise exception 'Block 7 expected 34 learner-first skills total'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards where is_runtime_allowed)<>0
  then raise exception 'Tutor content must remain runtime OFF'; end if;
end
$test$;

select 'P3-07 Block 7 Series: GREEN' as result;
