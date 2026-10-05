\set ON_ERROR_STOP on

do $review$
declare
  v integer;
begin
  -- Exact canonical matrix: 81 skills x 3 locales.
  with expected as (
    select n.component_code,n.skill_code,l.locale
    from private.exam_prep_syllabus_nodes n
    join private.exam_prep_program_versions pv on pv.id=n.program_version_id
    cross join (values ('en'),('ru'),('uz')) l(locale)
    where pv.program_key='math_as_p1_p5'
      and pv.version_key='p1_p5_canonical_v1_0'
      and pv.status='active'
      and n.component_code in ('P1','P5')
  )
  select count(*) into v from expected;
  if v<>243 then
    raise exception 'Global Tutor review expected 243 canonical skill-locale rows, found %',v;
  end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first';
  if v<>243 then
    raise exception 'Global Tutor review expected 243 learner-first cards, found %',v;
  end if;

  select count(distinct skill_code) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first';
  if v<>81 then
    raise exception 'Global Tutor review expected 81 canonical skills, found %',v;
  end if;

  -- Every expected component+skill+locale exists exactly once and nothing unexpected exists.
  if exists(
    with expected as (
      select n.component_code,n.skill_code,l.locale
      from private.exam_prep_syllabus_nodes n
      join private.exam_prep_program_versions pv on pv.id=n.program_version_id
      cross join (values ('en'),('ru'),('uz')) l(locale)
      where pv.program_key='math_as_p1_p5'
        and pv.version_key='p1_p5_canonical_v1_0'
        and pv.status='active'
        and n.component_code in ('P1','P5')
    ),
    actual as (
      select component_code,skill_code,locale,count(*) n
      from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first'
      group by component_code,skill_code,locale
    )
    select 1
    from expected e
    left join actual a using(component_code,skill_code,locale)
    where coalesce(a.n,0)<>1
  ) then
    raise exception 'Global Tutor review has missing or duplicate expected skill-locale rows';
  end if;

  if exists(
    with expected as (
      select n.component_code,n.skill_code,l.locale
      from private.exam_prep_syllabus_nodes n
      join private.exam_prep_program_versions pv on pv.id=n.program_version_id
      cross join (values ('en'),('ru'),('uz')) l(locale)
      where pv.program_key='math_as_p1_p5'
        and pv.version_key='p1_p5_canonical_v1_0'
        and pv.status='active'
        and n.component_code in ('P1','P5')
    )
    select 1
    from private.exam_prep_ai_tutor_cards t
    left join expected e using(component_code,skill_code,locale)
    where t.content_version='tutor_v2_learner_first'
      and e.skill_code is null
  ) then
    raise exception 'Global Tutor review found unexpected skill-locale rows';
  end if;

  -- Exactly three locales per canonical skill.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
    group by component_code,skill_code
    having count(*)<>3
       or count(distinct locale)<>3
       or array_agg(distinct locale order by locale)<>array['en','ru','uz']::text[]
  ) then
    raise exception 'Global Tutor review locale-group parity drift';
  end if;

  -- Key and component ownership integrity.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards t
    where t.content_version='tutor_v2_learner_first'
      and (
        t.locale not in ('en','ru','uz')
        or t.tutor_card_key <> lower(t.component_code)||':'||t.skill_code||':tutor:'||t.locale||':v2'
        or (t.component_code='P1' and t.skill_code not like 'P1-%')
        or (t.component_code='P5' and t.skill_code not like 'P5-%')
        or t.component_code not in ('P1','P5')
      )
  ) then
    raise exception 'Global Tutor review key/component ownership drift';
  end if;

  -- Source-card linkage must be exact and source cards must remain approved/runtime-grounding sources.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v2_learner_first'
      and (
        s.source_card_key is null
        or s.component_code<>t.component_code
        or s.skill_code<>t.skill_code
        or s.locale<>t.locale
        or s.card_type<>'theory'
        or s.approval_status<>'approved'
        or not s.is_runtime_allowed
      )
  ) then
    raise exception 'Global Tutor review source-card linkage drift';
  end if;

  -- All learner-facing fields are present and have a minimum corpus-level thickness.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and (
        btrim(coalesce(title,''))=''
        or btrim(coalesce(main_explanation,''))=''
        or btrim(coalesce(simple_explanation,''))=''
        or btrim(coalesce(alternative_explanation,''))=''
        or btrim(coalesce(focus_explanation,''))=''
        or char_length(main_explanation)<300
        or char_length(simple_explanation)<100
        or char_length(alternative_explanation)<140
        or char_length(focus_explanation)<100
      )
  ) then
    raise exception 'Global Tutor review found blank or unexpectedly thin learner-facing content';
  end if;

  -- Four variants must be distinct within every card.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and (
        main_explanation=simple_explanation
        or main_explanation=alternative_explanation
        or main_explanation=focus_explanation
        or simple_explanation=alternative_explanation
        or simple_explanation=focus_explanation
        or alternative_explanation=focus_explanation
      )
  ) then
    raise exception 'Global Tutor review found duplicate explanation variants within a card';
  end if;

  -- No exact duplicated four-variant content package across distinct cards.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
    group by md5(concat_ws('||',
      main_explanation,simple_explanation,alternative_explanation,focus_explanation
    ))
    having count(*)>1
  ) then
    raise exception 'Global Tutor review found exact duplicated Tutor content packages';
  end if;

  -- Stored content hash must describe the current reviewed payload.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and content_hash <> md5(concat_ws('||',
        content_version,title,main_explanation,simple_explanation,
        alternative_explanation,focus_explanation,source_card_key
      ))
  ) then
    raise exception 'Global Tutor review found stale content hashes';
  end if;

  -- Learner-facing implementation-language firewall.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and concat_ws(' ',title,main_explanation,simple_explanation,alternative_explanation,focus_explanation)
        ~* '(P[15]-[A-Z]{2,4}-[0-9]{2}|source_card|action_code|item_type|process_step|learner_context|service mode|canonical skill|mastery)'
  ) then
    raise exception 'Global Tutor review leaked internal implementation terminology';
  end if;

  -- Paper firewall in learner-facing copy.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and (
        (component_code='P1' and concat_ws(' ',main_explanation,simple_explanation,alternative_explanation,focus_explanation) ~* 'Paper[[:space:]]*5')
        or
        (component_code='P5' and concat_ws(' ',main_explanation,simple_explanation,alternative_explanation,focus_explanation) ~* 'Paper[[:space:]]*1')
      )
  ) then
    raise exception 'Global Tutor review P1/P5 learner-facing firewall drift';
  end if;

  -- Formatting and unsafe markup hygiene.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and (
        position(E'\\n' in main_explanation)>0
        or position(E'\\n' in simple_explanation)>0
        or position(E'\\n' in alternative_explanation)>0
        or position(E'\\n' in focus_explanation)>0
        or concat_ws(' ',title,main_explanation,simple_explanation,alternative_explanation,focus_explanation)
           ~* '(<script|</script|<iframe|javascript:|onerror[[:space:]]*=|onload[[:space:]]*=)'
      )
  ) then
    raise exception 'Global Tutor review formatting/markup hygiene failure';
  end if;

  -- Global review itself must not silently activate content.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and (approval_status<>'draft' or is_runtime_allowed)
  ) then
    raise exception 'Global Tutor review requires all 243 cards to remain DRAFT/runtime OFF';
  end if;
end
$review$;

select 'P3-15 Global Tutor Content Review — 243/243 structural governance GREEN' as result;
