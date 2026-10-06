\set ON_ERROR_STOP on

do $test$
declare
  v integer;
  v_cov jsonb;
begin
  -- Runtime ownership.
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v3_learner_first'
    and approval_status='approved' and is_runtime_allowed;
  if v<>243 then raise exception 'P3-18 expected 243 active v3 Tutor Cards, found %',v; end if;

  select count(distinct skill_code) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v3_learner_first'
    and approval_status='approved' and is_runtime_allowed;
  if v<>81 then raise exception 'P3-18 expected 81 active v3 skills, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='retired' and not is_runtime_allowed;
  if v<>243 then raise exception 'P3-18 expected 243 retired v2 Tutor Cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_source_cards
  where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
    and approval_status='approved' and is_runtime_allowed
    and rights_status='original_iclub';
  if v<>243 then raise exception 'P3-18 expected 243 active source-v2 cards, found %',v; end if;

  -- Exact canonical triad coverage.
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
      where content_version='tutor_v3_learner_first'
        and approval_status='approved' and is_runtime_allowed
      group by component_code,skill_code,locale
    )
    select 1 from expected e
    left join actual a using(component_code,skill_code,locale)
    where coalesce(a.n,0)<>1
  ) then raise exception 'P3-18 missing/duplicate v3 canonical triad'; end if;

  -- Only 21 audited locale cards may differ in learner-facing copy from v2.
  select count(*) into v
  from private.exam_prep_ai_tutor_cards n
  join private.exam_prep_ai_tutor_cards o
    on o.skill_code=n.skill_code and o.locale=n.locale
   and o.content_version='tutor_v2_learner_first'
  where n.content_version='tutor_v3_learner_first'
    and (n.title,n.main_explanation,n.simple_explanation,n.alternative_explanation,n.focus_explanation)
        is distinct from
        (o.title,o.main_explanation,o.simple_explanation,o.alternative_explanation,o.focus_explanation);
  if v<>21 then raise exception 'P3-18 expected exactly 21 changed locale cards, found %',v; end if;

  if exists(
    with expected(skill_code,locale) as (
      values
        ('P1-QUA-06','en'),('P1-QUA-06','ru'),('P1-QUA-06','uz'),
        ('P1-CIR-03','ru'),
        ('P1-TRI-05','ru'),('P1-TRI-05','uz'),
        ('P5-DAT-01','ru'),
        ('P5-DAT-03','ru'),('P5-DAT-03','uz'),
        ('P5-DAT-07','uz'),
        ('P5-DAT-09','ru'),('P5-DAT-09','uz'),
        ('P5-BIN-02','en'),('P5-BIN-02','ru'),('P5-BIN-02','uz'),
        ('P5-GEO-03','uz'),
        ('P5-NOR-04','ru'),('P5-NOR-04','uz'),
        ('P5-NOR-06','en'),('P5-NOR-06','ru'),('P5-NOR-06','uz')
    ),
    actual as (
      select n.skill_code,n.locale
      from private.exam_prep_ai_tutor_cards n
      join private.exam_prep_ai_tutor_cards o
        on o.skill_code=n.skill_code and o.locale=n.locale
       and o.content_version='tutor_v2_learner_first'
      where n.content_version='tutor_v3_learner_first'
        and (n.title,n.main_explanation,n.simple_explanation,n.alternative_explanation,n.focus_explanation)
            is distinct from
            (o.title,o.main_explanation,o.simple_explanation,o.alternative_explanation,o.focus_explanation)
    )
    select 1
    from (
      (select * from expected except select * from actual)
      union all
      (select * from actual except select * from expected)
    ) drift
  ) then raise exception 'P3-18 changed-card set drift'; end if;

  -- Hash and source-link integrity.
  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and content_hash<>md5(concat_ws('||',
        content_version,title,main_explanation,simple_explanation,
        alternative_explanation,focus_explanation,source_card_key
      ))
  ) then raise exception 'P3-18 stale Tutor v3 hash'; end if;

  if exists(
    select 1 from private.exam_prep_ai_source_cards
    where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
      and content_hash<>encode(digest(convert_to(body_text,'UTF8'),'sha256'),'hex')
  ) then raise exception 'P3-18 stale source-v2 hash'; end if;

  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v3_learner_first'
      and (
        s.source_card_key is null
        or s.component_code<>t.component_code
        or s.skill_code<>t.skill_code
        or s.locale<>t.locale
        or s.card_type<>'theory'
        or s.approval_status<>'approved'
        or not s.is_runtime_allowed
      )
  ) then raise exception 'P3-18 source binding drift'; end if;

  -- Atomic source architecture.
  select count(distinct body_text) into v
  from private.exam_prep_ai_source_cards
  where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06';
  if v<>243 then raise exception 'P3-18 expected 243 distinct source-v2 bodies, found %',v; end if;

  -- F-001 BLOCKER closed in every Tutor variant and bound source.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards t
    join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v3_learner_first'
      and t.skill_code='P5-NOR-06'
      and not (
        t.main_explanation like '%np>5%' and t.main_explanation like '%nq>5%'
        and t.simple_explanation like '%np>5%' and t.simple_explanation like '%nq>5%'
        and t.alternative_explanation like '%np>5%' and t.alternative_explanation like '%nq>5%'
        and t.focus_explanation like '%np>5%' and t.focus_explanation like '%nq>5%'
        and s.body_text like '%np>5%' and s.body_text like '%nq>5%'
      )
  ) then raise exception 'P3-18 P5-NOR-06 blocker not fully closed'; end if;

  -- F-002 closed.
  if not exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and skill_code='P1-CIR-03' and locale='ru'
      and main_explanation like '%1/2 r² sinθ = 16√3%'
  ) then raise exception 'P3-18 P1-CIR-03 RU method repair missing'; end if;

  -- F-003/F-004 originality replacements.
  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and skill_code='P1-QUA-06'
      and concat_ws(' ',main_explanation,simple_explanation,alternative_explanation)
          like '%x⁴ - 5x² + 4%'
  ) then raise exception 'P3-18 old P1-QUA-06 worked example remains'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v3_learner_first'
        and skill_code='P1-QUA-06'
        and concat_ws(' ',main_explanation,simple_explanation,alternative_explanation)
            like '%x⁴ - 13x² + 36%')<>3
  then raise exception 'P3-18 new P1-QUA-06 example not present in all locales'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and skill_code='P5-BIN-02'
      and concat_ws(' ',main_explanation,simple_explanation) like '%n=5%'
      and concat_ws(' ',main_explanation,simple_explanation) like '%p=0.4%'
  ) then raise exception 'P3-18 old P5-BIN-02 example remains'; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v3_learner_first'
        and skill_code='P5-BIN-02'
        and main_explanation like '%0.324135%'
        and main_explanation like '%0.420175%')<>3
  then raise exception 'P3-18 new P5-BIN-02 example not present in all locales'; end if;

  -- Language/localization regressions from the audit must be absent.
  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and (
        (locale='ru' and lower(concat_ws(' ',main_explanation,simple_explanation,alternative_explanation,focus_explanation))
          ~ '(sine|box plot|inverse normal|convention)')
        or
        (locale='uz' and lower(concat_ws(' ',main_explanation,simple_explanation,alternative_explanation,focus_explanation))
          ~ '(sine|outlier|range|inverse normal|convention)')
      )
  ) then raise exception 'P3-18 audited mixed-language defect remains'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and locale='uz' and skill_code='P5-GEO-03'
      and alternative_explanation like '%p va kutish vaqtini qarama-qarshi%'
  ) then raise exception 'P3-18 P5-GEO-03 UZ grammar defect remains'; end if;

  -- RU P5-DAT source family no longer inherits raw "box plot".
  if exists(
    select 1 from private.exam_prep_ai_source_cards
    where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
      and locale='ru'
      and skill_code like 'P5-DAT-%'
      and lower(body_text) like '%box plot%'
  ) then raise exception 'P3-18 RU P5-DAT source localization defect remains'; end if;

  -- No leading/trailing whitespace on any learner-facing explanation.
  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and (
        main_explanation<>regexp_replace(main_explanation,'^[[:space:]]+|[[:space:]]+$','','g')
        or simple_explanation<>regexp_replace(simple_explanation,'^[[:space:]]+|[[:space:]]+$','','g')
        or alternative_explanation<>regexp_replace(alternative_explanation,'^[[:space:]]+|[[:space:]]+$','','g')
        or focus_explanation<>regexp_replace(focus_explanation,'^[[:space:]]+|[[:space:]]+$','','g')
      )
  ) then raise exception 'P3-18 leading/trailing Tutor whitespace remains'; end if;

  -- Variant uniqueness and minimum thickness.
  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and (
        btrim(coalesce(title,''))=''
        or char_length(main_explanation)<300
        or char_length(simple_explanation)<100
        or char_length(alternative_explanation)<140
        or char_length(focus_explanation)<100
        or main_explanation=simple_explanation
        or main_explanation=alternative_explanation
        or main_explanation=focus_explanation
        or simple_explanation=alternative_explanation
        or simple_explanation=focus_explanation
        or alternative_explanation=focus_explanation
      )
  ) then raise exception 'P3-18 learner-facing thickness/variant uniqueness failure'; end if;

  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
    group by md5(concat_ws('||',
      main_explanation,simple_explanation,alternative_explanation,focus_explanation
    ))
    having count(*)>1
  ) then raise exception 'P3-18 exact duplicate v3 content package'; end if;

  -- Runtime service and coverage.
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
  select count(*) into v
  from expected e
  where public.get_exam_prep_ai_tutor_card_service_v1(
    e.component_code,e.skill_code,e.locale
  )->>'content_version'='tutor_v3_learner_first';
  if v<>243 then raise exception 'P3-18 runtime Tutor service v3 count=%',v; end if;

  v_cov:=public.get_exam_prep_ai_tutor_card_coverage_service_v1();
  if coalesce((v_cov->>'expected')::integer,-1)<>243
     or coalesce((v_cov->>'ready')::integer,-1)<>243
     or coalesce((v_cov->>'missing')::integer,-1)<>0
     or coalesce((v_cov->>'p1_ready')::integer,-1)<>135
     or coalesce((v_cov->>'p5_ready')::integer,-1)<>108
  then raise exception 'P3-18 coverage mismatch: %',v_cov; end if;

  -- Browser privilege boundary unchanged.
  if has_table_privilege('authenticated','private.exam_prep_ai_tutor_cards','SELECT')
     or has_table_privilege('anon','private.exam_prep_ai_tutor_cards','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_ai_source_cards','SELECT')
     or has_table_privilege('anon','private.exam_prep_ai_source_cards','SELECT')
     or has_function_privilege('authenticated','public.get_exam_prep_ai_tutor_card_service_v1(text,text,text)','EXECUTE')
     or has_function_privilege('anon','public.get_exam_prep_ai_tutor_card_service_v1(text,text,text)','EXECUTE')
  then raise exception 'P3-18 privilege boundary drift'; end if;
end
$test$;

select 'P3-18 Tutor v3 Audit Repair — GREEN' as result;
