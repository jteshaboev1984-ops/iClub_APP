-- AW13-16 annual-reserve source/release contract v1.
-- The original draft payload is now governed/published through the reserve release path.
-- Public source questions remain inactive/draft and every reserve item remains withheld.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4815,4816) and status='published')<>2 then
    raise exception 'aw13_16 annual reserve source: expected two published versions';
  end if;

  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4815,4816)
        and release_mode='supplemental_reserve'
        and profile_version='aw13_16_annual_reserve_release_v1'
        and require_written_understanding=false)<>2 then
    raise exception 'aw13_16 annual reserve source: release profile mismatch';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4815,4816)
        and lifecycle_state='reserve'
        and exposure_state='withheld')<>75
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4815,4816) and reserve_role='diagnostic')<>30
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4815,4816) and reserve_role='retest')<>30
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4815,4816) and reserve_role='mixed')<>15
  then raise exception 'aw13_16 annual reserve source: reserve cardinality/state mismatch'; end if;

  if exists(select 1 from private.exam_prep_written_tasks where content_version_id in (4815,4816))
  then raise exception 'aw13_16 annual reserve source: reserve-only versions contain written tasks'; end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4815,4816) and status='published')<>36
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4815,4816))<>75
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4815,4816) and ai.is_holdout)<>75
  then raise exception 'aw13_16 annual reserve source: assessment/holdout mismatch'; end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4815,4816)
        and r.rule_version='aw_reserve_v1'
        and r.status='approved')<>90
  then raise exception 'aw13_16 annual reserve source: diagnostic rules mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
    and (
      m.copyright_status<>'pass'
      or m.qa_scope_status<>'pass'
      or m.qa_math_status<>'pass'
      or m.qa_language_status<>'pass'
      or m.qa_technical_status<>'pass'
      or (m.reserve_role='diagnostic' and m.diagnostic_rule_status<>'approved')
      or (m.reserve_role<>'diagnostic' and m.diagnostic_rule_status<>'not_applicable')
      or q.is_active
      or q.quality_status<>'draft'
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
  if v_bad<>0 then raise exception 'aw13_16 annual reserve source: QA/public-source/snapshot rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  where m.content_version_id in (4815,4816)
    and (
      (m.primary_skill_code='P1-CIR-03' and (m.official_scope_ref not like '%P1 1.4 Circular measure%' or m.coursebook_mapping_ref not like '%Ch4%74-81%'))
      or (m.primary_skill_code like 'P1-TRI-%' and (m.official_scope_ref not like '%P1 1.5 Trigonometry%' or m.coursebook_mapping_ref not like '%Ch5%86-104%'))
      or (m.primary_skill_code='P1-SER-01' and (m.official_scope_ref not like '%P1 1.6 Series%' or m.coursebook_mapping_ref not like '%Ch6%109-116%'))
      or (m.primary_skill_code='P1-SER-02' and (m.official_scope_ref not like '%P1 1.6 Series%' or m.coursebook_mapping_ref not like '%Ch7%120-133%'))
      or (m.primary_skill_code='P1-DIF-01' and (m.official_scope_ref not like '%P1 1.7 Differentiation%' or m.coursebook_mapping_ref not like '%Ch8%138-153%'))
      or (m.primary_skill_code in ('P5-PRO-05','P5-PRO-06') and (m.official_scope_ref not like '%P5 5.3 Probability%' or m.coursebook_mapping_ref not like '%Ch4%63-82%'))
      or (m.primary_skill_code in ('P5-DRV-01','P5-DRV-02','P5-DRV-03') and (m.official_scope_ref not like '%P5 5.4 Discrete random variables%' or m.coursebook_mapping_ref not like '%Ch5%84-96%'))
      or (m.primary_skill_code='P5-BIN-01' and (m.official_scope_ref not like '%P5 5.4 Discrete random variables%' or m.coursebook_mapping_ref not like '%Ch7%115-131%'))
      or (m.primary_skill_code='P5-GEO-01' and (m.official_scope_ref not like '%P5 5.4 Discrete random variables%' or m.coursebook_mapping_ref not like '%Ch8%133-145%'))
    );
  if v_bad<>0 then raise exception 'aw13_16 annual reserve source: source-map rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4815,4816)
  ) or exists(
    select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4815,4816)
  ) or exists(
    select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4815,4816)
  ) then raise exception 'aw13_16 annual reserve source: history contamination'; end if;
END
$$;

\echo 'AW13-16 annual reserve source/release v1 contract: GREEN'
