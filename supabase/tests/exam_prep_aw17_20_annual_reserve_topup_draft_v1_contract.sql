-- AW17-20 annual reserve top-up draft v1 contract.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_a int; v_b int; v_c int; v_d int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4819,4820) and status='draft')<>2 then
    raise exception 'aw17_20 annual reserve draft: expected two draft versions';
  end if;

  if exists(select 1 from private.exam_prep_content_release_profiles_v1 where content_version_id in (4819,4820)) then
    raise exception 'aw17_20 annual reserve draft: release profile exists before approval';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4819,4820)
        and lifecycle_state='draft' and exposure_state='withheld')<>55
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4819,4820) and reserve_role='diagnostic')<>22
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4819,4820) and reserve_role='retest')<>22
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4819,4820) and reserve_role='mixed')<>11
  then raise exception 'aw17_20 annual reserve draft: machine cardinality/state mismatch'; end if;

  if exists(select 1 from private.exam_prep_written_tasks where content_version_id in (4819,4820)) then
    raise exception 'aw17_20 annual reserve draft: reserve-only versions contain written tasks';
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4819,4820) and status='draft')<>28
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4819,4820) and assessment_type='diagnostic')<>4
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4819,4820) and assessment_type='retest')<>22
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4819,4820) and assessment_type='mixed')<>2
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4819,4820))<>55
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4819,4820) and ai.is_holdout)<>55
  then raise exception 'aw17_20 annual reserve draft: assessment/holdout mismatch'; end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4819,4820)
        and r.rule_version='aw_reserve_v1'
        and r.status='draft')<>66
  then raise exception 'aw17_20 annual reserve draft: diagnostic rules mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4819,4820)
    and (
      m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or (m.reserve_role='diagnostic' and m.diagnostic_rule_status<>'pending')
      or (m.reserve_role<>'diagnostic' and m.diagnostic_rule_status<>'not_applicable')
      or q.is_active
      or q.quality_status<>'draft'
      or nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
      or (q.qtype='mcq' and (
        q.correct_answer not in ('A','B','C','D')
        or jsonb_array_length(q.options_text_en::jsonb)<>4
        or jsonb_array_length(q.options_text_ru::jsonb)<>4
        or jsonb_array_length(q.options_text_uz::jsonb)<>4
        or (select count(distinct v) from jsonb_array_elements_text(q.options_text_en::jsonb) z(v))<>4
        or (select count(distinct v) from jsonb_array_elements_text(q.options_text_ru::jsonb) z(v))<>4
        or (select count(distinct v) from jsonb_array_elements_text(q.options_text_uz::jsonb) z(v))<>4
      ))
      or (q.qtype='input' and (
        nullif(btrim(q.correct_answer),'') is null
        or q.options_text_en::jsonb<>'[]'::jsonb
        or q.options_text_ru::jsonb<>'[]'::jsonb
        or q.options_text_uz::jsonb<>'[]'::jsonb
      ))
      or md5(concat_ws(chr(31),
        q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
        coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
        coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
        coalesce(q.image_url,''),coalesce(q.is_active::text,''),
        coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
        coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
        coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
        coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
        coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5
    );
  if v_bad<>0 then raise exception 'aw17_20 annual reserve draft: payload/QA/snapshot rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  where m.content_version_id in (4819,4820)
    and (
      (m.primary_skill_code like 'P1-SER-%' and (m.official_scope_ref not like '%P1 1.6 Series%' or m.coursebook_mapping_ref not like '%Ch7%120-133%'))
      or (m.primary_skill_code in ('P1-DIF-02','P1-DIF-03') and (m.official_scope_ref not like '%P1 1.7 Differentiation%' or m.coursebook_mapping_ref not like '%Ch8%138-153%'))
      or (m.primary_skill_code='P1-DIF-04' and (m.official_scope_ref not like '%P1 1.7 Differentiation%' or m.coursebook_mapping_ref not like '%Ch8-9%138-167%'))
      or (m.primary_skill_code like 'P5-BIN-%' and (m.official_scope_ref not like '%P5 5.4 Discrete random variables%' or m.coursebook_mapping_ref not like '%Ch7%115-131%'))
      or (m.primary_skill_code like 'P5-GEO-%' and (m.official_scope_ref not like '%P5 5.4 Discrete random variables%' or m.coursebook_mapping_ref not like '%Ch8%133-145%'))
      or (m.primary_skill_code='P5-NOR-01' and (m.official_scope_ref not like '%P5 5.5 The normal distribution%' or m.coursebook_mapping_ref not like '%Ch9%147-171%'))
    );
  if v_bad<>0 then raise exception 'aw17_20 annual reserve draft: source-map mismatch rows=%',v_bad; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D')
  into v_a,v_b,v_c,v_d
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4819 and m.reserve_role='diagnostic';
  if (v_a,v_b,v_c,v_d)<>(3,3,3,3) then
    raise exception 'aw17_20 annual reserve draft: P1 diagnostic balance mismatch A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D')
  into v_a,v_b,v_c,v_d
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4820 and m.reserve_role='diagnostic';
  if (v_a,v_b,v_c,v_d)<>(3,3,2,2) then
    raise exception 'aw17_20 annual reserve draft: P5 diagnostic balance mismatch A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4819,4820)
    and m.reserve_role='diagnostic'
    and (
      q.qtype<>'mcq'
      or (select count(*) from private.exam_prep_diagnostic_rules r
          where r.content_meta_id=m.id
            and r.rule_version='aw_reserve_v1'
            and r.status='draft'
            and r.answer_kind='mcq_option'
            and r.answer_match<>q.correct_answer
            and r.weak_skill_code=m.primary_skill_code)<>3
    );
  if v_bad<>0 then raise exception 'aw17_20 annual reserve draft: diagnostic rule coverage rows=%',v_bad; end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code
     and oldm.content_version_id<>m.content_version_id
    join private.exam_prep_content_versions oldcv
      on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4819,4820)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw17_20 annual reserve draft: exact published stem reuse'; end if;

  -- If the hidden reserve were approved, every AW17-20 skill would hit the
  -- annual content-depth floor: 3 diagnostic, 8 learning/transfer, 4 retest.
  select count(*) into v_bad
  from (
    with skills(skill_code) as (values
      ('P1-SER-03'),('P1-SER-04'),('P1-SER-05'),('P1-DIF-02'),('P1-DIF-03'),('P1-DIF-04'),
      ('P5-BIN-02'),('P5-BIN-03'),('P5-GEO-02'),('P5-GEO-03'),('P5-NOR-01')
    )
    select s.skill_code,
      count(distinct m.id) filter(where
        (cv.status='published' and m.lifecycle_state in ('published','reserve') and m.reserve_role='diagnostic')
        or (cv.id in (4819,4820) and cv.status='draft' and m.lifecycle_state='draft' and m.reserve_role='diagnostic')
      ) d,
      count(distinct m.id) filter(where
        (cv.status='published' and m.lifecycle_state in ('published','reserve') and m.reserve_role in ('learning','mixed'))
        or (cv.id in (4819,4820) and cv.status='draft' and m.lifecycle_state='draft' and m.reserve_role='mixed')
      ) lx,
      count(distinct m.id) filter(where
        (cv.status='published' and m.lifecycle_state in ('published','reserve') and m.reserve_role='retest')
        or (cv.id in (4819,4820) and cv.status='draft' and m.lifecycle_state='draft' and m.reserve_role='retest')
      ) r
    from skills s
    left join private.exam_prep_question_content_meta m on m.primary_skill_code=s.skill_code
    left join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    group by s.skill_code
  ) x
  where x.d<>3 or x.lx<>8 or x.r<>4;
  if v_bad<>0 then raise exception 'aw17_20 annual reserve draft: prospective annual depth floor failed rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4819,4820)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4819,4820)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4819,4820)
  ) then raise exception 'aw17_20 annual reserve draft: history contamination'; end if;

  -- Global feature-state assertions belong to the publication/production gate.
  -- P2-36/P2-80 intentionally mutate feature fixtures while validating isolated
  -- service-transition behavior, so this draft-only content contract must not
  -- couple reserve payload validity to the disposable fixture's runtime state.
END
$$;

\echo 'AW17-20 annual reserve top-up draft v1 contract: GREEN'
