-- AW17-20 supplemental learning draft v1 contract.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4817,4818) and status='draft')<>2 then
    raise exception 'aw17_20 supplemental draft: expected two draft content versions';
  end if;

  if exists(select 1 from private.exam_prep_content_release_profiles_v1 where content_version_id in (4817,4818)) then
    raise exception 'aw17_20 supplemental draft: release profile exists before approval';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id=4817 and lifecycle_state='draft' and reserve_role='learning' and exposure_state='withheld')<>18
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id=4818 and lifecycle_state='draft' and reserve_role='learning' and exposure_state='withheld')<>15
  then raise exception 'aw17_20 supplemental draft: machine cardinality/state mismatch'; end if;

  if (select count(*) from private.exam_prep_written_tasks
      where content_version_id=4817 and lifecycle_state='draft')<>6
     or (select count(*) from private.exam_prep_written_tasks
         where content_version_id=4818 and lifecycle_state='draft')<>5
     or (select count(*) from private.exam_prep_written_understanding_checks
         where id between 8953 and 8963 and lifecycle_state='draft')<>11
  then raise exception 'aw17_20 supplemental draft: written/check cardinality mismatch'; end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id=4817 and assessment_type='learning' and status='draft')<>6
     or (select count(*) from private.exam_prep_assessments
         where content_version_id=4818 and assessment_type='learning' and status='draft')<>5
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4817,4818))<>44
  then raise exception 'aw17_20 supplemental draft: assessment shape mismatch'; end if;

  select count(*) into v_bad
  from (
    select a.id
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id in (4817,4818)
    group by a.id
    having count(*) filter(where ai.question_id is not null and ai.reserve_role='learning' and not ai.is_holdout)<>3
        or count(*) filter(where ai.written_task_id is not null and ai.reserve_role='written' and not ai.is_holdout)<>1
        or count(*)<>4
  ) x;
  if v_bad<>0 then
    raise exception 'aw17_20 supplemental draft: per-assessment 3+1 shape mismatch rows=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4817,4818)
    and (
      m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or m.diagnostic_rule_status<>'not_applicable'
      or m.lifecycle_state<>'draft'
      or m.exposure_state<>'withheld'
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
  if v_bad<>0 then raise exception 'aw17_20 supplemental draft: machine QA/type/snapshot rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_assessments
    where content_version_id in (4817,4818)
      and (
        lower(coalesce(title_en,'')) like '%supplemental%'
        or lower(coalesce(title_en,'')) like '%draft%'
        or lower(coalesce(title_ru,'')) like '%дополнительн%'
        or lower(coalesce(title_ru,'')) like '%чернов%'
        or lower(coalesce(title_uz,'')) like '%qo‘shimcha%'
      )
  ) then raise exception 'aw17_20 supplemental draft: internal wording in learner titles'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  where m.content_version_id in (4817,4818)
    and (
      (m.primary_skill_code like 'P1-SER-%' and (m.official_scope_ref not like '%P1 1.6 Series%' or m.coursebook_mapping_ref not like '%Ch7%120-133%'))
      or (m.primary_skill_code in ('P1-DIF-02','P1-DIF-03') and (m.official_scope_ref not like '%P1 1.7 Differentiation%' or m.coursebook_mapping_ref not like '%Ch8%138-153%'))
      or (m.primary_skill_code='P1-DIF-04' and (m.official_scope_ref not like '%P1 1.7 Differentiation%' or m.coursebook_mapping_ref not like '%Ch8-9%138-167%'))
      or (m.primary_skill_code like 'P5-BIN-%' and (m.official_scope_ref not like '%P5 5.4 Discrete random variables%' or m.coursebook_mapping_ref not like '%Ch7%115-131%'))
      or (m.primary_skill_code like 'P5-GEO-%' and (m.official_scope_ref not like '%P5 5.4 Discrete random variables%' or m.coursebook_mapping_ref not like '%Ch8%133-145%'))
      or (m.primary_skill_code='P5-NOR-01' and (m.official_scope_ref not like '%P5 5.5 The normal distribution%' or m.coursebook_mapping_ref not like '%Ch9%147-171%'))
    );
  if v_bad<>0 then raise exception 'aw17_20 supplemental draft: source-map mismatch rows=%',v_bad; end if;

  if (select count(*)
      from private.exam_prep_content_runway_releases r
      join private.exam_prep_content_runway_release_skills rs on rs.release_id=r.id
      where r.release_key='aw17_20_core_coverage_iv'
        and r.active_week_from=17 and r.active_week_through=20
        and r.schedule_status='active'
        and rs.required_for_release)<>11
  then raise exception 'aw17_20 supplemental draft: governed runway target set mismatch'; end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code
     and oldm.content_version_id<>m.content_version_id
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4817,4818)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw17_20 supplemental draft: exact published stem duplicate'; end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4817;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(3,3,3,3,6) then
    raise exception 'aw17_20 supplemental draft: P1 answer balance mismatch';
  end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4818;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(2,2,3,3,5) then
    raise exception 'aw17_20 supplemental draft: P5 answer balance mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_tasks wt
  left join private.exam_prep_written_understanding_checks c on c.written_task_id=wt.id
  where wt.content_version_id in (4817,4818)
    and (
      wt.lifecycle_state<>'draft'
      or wt.copyright_status<>'pending'
      or wt.qa_math_status<>'pending'
      or wt.qa_language_status<>'pending'
      or wt.qa_technical_status<>'pending'
      or coalesce((wt.rubric_json->>'max_marks')::int,0)<>6
      or nullif(btrim(wt.prompt_en),'') is null
      or nullif(btrim(wt.prompt_ru),'') is null
      or nullif(btrim(wt.prompt_uz),'') is null
      or nullif(btrim(wt.self_review_en),'') is null
      or nullif(btrim(wt.self_review_ru),'') is null
      or nullif(btrim(wt.self_review_uz),'') is null
      or c.id is null
      or c.lifecycle_state<>'draft'
      or c.qa_math_status<>'pending'
      or c.qa_language_status<>'pending'
      or c.qa_technical_status<>'pending'
      or jsonb_array_length(c.options_en)<>4
      or jsonb_array_length(c.options_ru)<>4
      or jsonb_array_length(c.options_uz)<>4
      or c.correct_index not between 0 and 3
    );
  if v_bad<>0 then raise exception 'aw17_20 supplemental draft: written/check QA rows=%',v_bad; end if;

  if (select count(*) from private.exam_prep_written_understanding_checks where id between 8953 and 8963 and correct_index=0)<>3
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8953 and 8963 and correct_index=1)<>3
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8953 and 8963 and correct_index=2)<>3
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8953 and 8963 and correct_index=3)<>2
  then raise exception 'aw17_20 supplemental draft: written-check balance mismatch'; end if;

  -- Prospective learning/written floor after this hidden draft is eventually approved.
  select count(*) into v_bad
  from (
    with skills(skill_code) as (values
      ('P1-SER-03'),('P1-SER-04'),('P1-SER-05'),('P1-DIF-02'),('P1-DIF-03'),('P1-DIF-04'),
      ('P5-BIN-02'),('P5-BIN-03'),('P5-GEO-02'),('P5-GEO-03'),('P5-NOR-01')
    )
    select s.skill_code
    from skills s
    left join private.exam_prep_question_content_meta m on m.primary_skill_code=s.skill_code
    left join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    left join private.exam_prep_written_tasks wt on wt.primary_skill_code=s.skill_code
      and (wt.lifecycle_state='published' or (wt.content_version_id in (4817,4818) and wt.lifecycle_state='draft'))
    group by s.skill_code
    having count(distinct m.id) filter(where
      (cv.status='published' and m.lifecycle_state in ('published','reserve') and m.reserve_role in ('learning','mixed'))
      or (cv.id in (4817,4818) and cv.status='draft' and m.lifecycle_state='draft' and m.reserve_role='learning')
    )<7
       or count(distinct wt.id)<2
  ) x;
  if v_bad<>0 then raise exception 'aw17_20 supplemental draft: prospective learning/written floor failed rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4817,4818)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4817,4818)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4817,4818)
  ) then raise exception 'aw17_20 supplemental draft: history contamination'; end if;
END
$$;

\echo 'AW17-20 supplemental learning draft v1 contract: GREEN'
