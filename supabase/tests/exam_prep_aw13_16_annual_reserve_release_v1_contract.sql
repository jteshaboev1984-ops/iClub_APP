-- AW13-16 annual reserve release v1 contract.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4815,4816) and status='published')<>2 then
    raise exception 'aw13_16 reserve release: expected two published versions';
  end if;

  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4815,4816)
        and release_mode='supplemental_reserve'
        and profile_version='aw13_16_annual_reserve_release_v1'
        and require_written_understanding=false)<>2 then
    raise exception 'aw13_16 reserve release: release profile mismatch';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4815,4816)
        and lifecycle_state='reserve'
        and exposure_state='withheld'
        and copyright_status='pass'
        and qa_scope_status='pass'
        and qa_math_status='pass'
        and qa_language_status='pass'
        and qa_technical_status='pass')<>75
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4815,4816) and reserve_role='diagnostic')<>30
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4815,4816) and reserve_role='retest')<>30
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4815,4816) and reserve_role='mixed')<>15
  then raise exception 'aw13_16 reserve release: governed reserve cardinality/state mismatch'; end if;

  if exists(select 1 from private.exam_prep_written_tasks where content_version_id in (4815,4816))
  then raise exception 'aw13_16 reserve release: reserve-only versions contain written tasks'; end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4815,4816)
        and m.reserve_role='diagnostic'
        and r.rule_version='aw_reserve_v1'
        and r.status='approved')<>90 then
    raise exception 'aw13_16 reserve release: approved diagnostic-rule cardinality mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
    and (
      q.is_active
      or q.quality_status<>'draft'
      or nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
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
  if v_bad<>0 then raise exception 'aw13_16 reserve release: public-source/trilingual/snapshot rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
    and (
      (q.qtype='mcq' and (
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
    );
  if v_bad<>0 then raise exception 'aw13_16 reserve release: type/options rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id in (4815,4816)
      and (q.options_text_ru ~* '\m(or|only|cm)\M' or q.options_text_uz ~* '\m(or|only|cm)\M')
  ) then raise exception 'aw13_16 reserve release: untranslated learner option token'; end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4815,4816) and status='published')<>36
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4815,4816))<>75
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4815,4816) and ai.is_holdout)<>75
  then raise exception 'aw13_16 reserve release: assessment/holdout shape mismatch'; end if;

  with expected(content_key,answer) as (values
    ('P1SER02-D03','D'),('P1TRI03-D02','A'),('P1TRI03-R03','113.6'),
    ('P1TRI05-D02','A'),('P1TRI05-D03','B'),
    ('P1SER01-D02','A'),('P1SER01-D03','C'),('P1SER01-R04','B'),
    ('P1CIR03-D02','A'),('P1DIF01-D02','A'),('P1TRI04-D02','A'),
    ('P5PRO06-D02','D'),('P5PRO06-D03','A'),
    ('P5DRV02-D02','B'),('P5DRV02-R04','D'),
    ('P5DRV03-D02','A'),('P5DRV03-D03','B'),('P5GEO01-R03','0')
  )
  select count(*) into v_bad
  from expected e
  left join private.exam_prep_question_content_meta m
    on m.content_version_id in (4815,4816) and m.content_key=e.content_key
  left join public.questions q on q.id=m.question_id
  where q.id is null or q.correct_answer<>e.answer;
  if v_bad<>0 then raise exception 'aw13_16 reserve release: independent-QA answer map mismatch rows=%',v_bad; end if;

  if coalesce((private.exam_prep_supplemental_reserve_floor_v1(4815)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4816)->>'ready')::boolean,false) is not true
  then raise exception 'aw13_16 reserve release: reserve floor RED'; end if;

  with expected(component_code,skill_code) as (values
    ('P1','P1-CIR-03'),('P1','P1-TRI-02'),('P1','P1-TRI-03'),('P1','P1-TRI-04'),('P1','P1-TRI-05'),('P1','P1-SER-01'),('P1','P1-SER-02'),('P1','P1-DIF-01'),
    ('P5','P5-PRO-05'),('P5','P5-PRO-06'),('P5','P5-DRV-01'),('P5','P5-DRV-02'),('P5','P5-DRV-03'),('P5','P5-BIN-01'),('P5','P5-GEO-01')
  ), q as (
    select cv.component_code,m.primary_skill_code skill_code,
      count(*) filter(where m.reserve_role='diagnostic') d,
      count(*) filter(where m.reserve_role='learning') l,
      count(*) filter(where m.reserve_role='retest') r,
      count(*) filter(where m.reserve_role='mixed') x
    from private.exam_prep_question_content_meta m
    join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    join expected e on e.component_code=cv.component_code and e.skill_code=m.primary_skill_code
    where cv.status='published' and m.lifecycle_state in ('published','reserve')
    group by cv.component_code,m.primary_skill_code
  ), w as (
    select component_code,primary_skill_code skill_code,count(*) n
    from private.exam_prep_written_tasks
    where lifecycle_state='published'
      and primary_skill_code in (
        'P1-CIR-03','P1-TRI-02','P1-TRI-03','P1-TRI-04','P1-TRI-05','P1-SER-01','P1-SER-02','P1-DIF-01',
        'P5-PRO-05','P5-PRO-06','P5-DRV-01','P5-DRV-02','P5-DRV-03','P5-BIN-01','P5-GEO-01'
      )
    group by component_code,primary_skill_code
  )
  select count(*) into v_bad
  from expected e left join q using(component_code,skill_code) left join w using(component_code,skill_code)
  where coalesce(q.d,0)<>3
     or coalesce(q.l,0)+coalesce(q.x,0)<>8
     or coalesce(q.r,0)<>4
     or coalesce(w.n,0)<2;
  if v_bad<>0 then raise exception 'aw13_16 reserve release: final annual depth mismatch rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4815,4816)
  ) or exists(
    select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4815,4816)
  ) or exists(
    select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4815,4816)
  ) then raise exception 'aw13_16 reserve release: history contamination'; end if;

  if not exists(
    select 1 from private.exam_prep_feature_config
    where id=1 and rollout_state='controlled_beta' and core_enabled
      and ai_enabled=false and mentor_enabled=false and kill_switch=false
  ) then raise exception 'aw13_16 reserve release: feature/service boundary drift'; end if;
END
$$;

\echo 'AW13-16 annual reserve release v1 contract: GREEN'
