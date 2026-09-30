-- AW9-12 supplemental learning draft v1 contract.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4809,4810) and status='draft')<>2 then
    raise exception 'aw09_12 supplemental draft: expected two draft content versions';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id=4809 and lifecycle_state='draft' and reserve_role='learning' and exposure_state='withheld')<>24
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id=4810 and lifecycle_state='draft' and reserve_role='learning' and exposure_state='withheld')<>18
  then
    raise exception 'aw09_12 supplemental draft: machine-content cardinality/state mismatch';
  end if;

  if (select count(*) from private.exam_prep_written_tasks
      where content_version_id=4809 and lifecycle_state='draft')<>8
     or (select count(*) from private.exam_prep_written_tasks
         where content_version_id=4810 and lifecycle_state='draft')<>6
     or (select count(*) from private.exam_prep_written_understanding_checks
         where id between 8924 and 8937 and lifecycle_state='draft')<>14
  then
    raise exception 'aw09_12 supplemental draft: written/check cardinality mismatch';
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id=4809 and assessment_type='learning' and status='draft')<>8
     or (select count(*) from private.exam_prep_assessments
         where content_version_id=4810 and assessment_type='learning' and status='draft')<>6
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4809,4810))<>56
  then
    raise exception 'aw09_12 supplemental draft: assessment shape mismatch';
  end if;

  -- Every pack is exactly 3 machine learning items + 1 written task.
  select count(*) into v_bad
  from (
    select a.id,
      count(*) filter(where ai.question_id is not null and ai.reserve_role='learning' and not ai.is_holdout) machine_n,
      count(*) filter(where ai.written_task_id is not null and ai.reserve_role='written' and not ai.is_holdout) written_n,
      count(*) total_n
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id in (4809,4810)
    group by a.id
    having count(*) filter(where ai.question_id is not null and ai.reserve_role='learning' and not ai.is_holdout)<>3
        or count(*) filter(where ai.written_task_id is not null and ai.reserve_role='written' and not ai.is_holdout)<>1
        or count(*)<>4
  ) x;
  if v_bad<>0 then
    raise exception 'aw09_12 supplemental draft: per-assessment 3+1 shape mismatch rows=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4809,4810)
    and (
      m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or m.diagnostic_rule_status<>'not_applicable'
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
    );
  if v_bad<>0 then
    raise exception 'aw09_12 supplemental draft: trilingual/type/options QA rows=%',v_bad;
  end if;

  -- Frozen snapshots exact.
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4809,4810)
    and md5(concat_ws(chr(31),
      q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
      coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
      coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
      coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5;
  if v_bad<>0 then
    raise exception 'aw09_12 supplemental draft: frozen snapshot mismatch rows=%',v_bad;
  end if;

  -- Source-map refs must match the canonical AW9-12 component sections.
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  where m.content_version_id in (4809,4810)
    and (
      (m.primary_skill_code like 'P1-QUA-%' and (m.official_scope_ref not like '%P1 1.1 Quadratics%' or m.coursebook_mapping_ref not like '%Ch1%2-20%'))
      or (m.primary_skill_code like 'P1-FUN-%' and (m.official_scope_ref not like '%P1 1.2 Functions%' or m.coursebook_mapping_ref not like '%Ch2%24-42%'))
      or (m.primary_skill_code='P1-COO-04' and (m.official_scope_ref not like '%P1 1.3 Coordinate geometry%' or m.coursebook_mapping_ref not like '%Ch3%48-67%'))
      or (m.primary_skill_code='P1-CIR-02' and (m.official_scope_ref not like '%P1 1.4 Circular measure%' or m.coursebook_mapping_ref not like '%Ch4%74-81%'))
      or (m.primary_skill_code in ('P5-DAT-03','P5-DAT-05') and (m.official_scope_ref not like '%P5 5.1 Representation of data%' or m.coursebook_mapping_ref not like '%Ch3%34-59%'))
      or (m.primary_skill_code='P5-DAT-07' and (m.official_scope_ref not like '%P5 5.1 Representation of data%' or m.coursebook_mapping_ref not like '%Ch2%14-29%'))
      or (m.primary_skill_code='P5-CNT-05' and (m.official_scope_ref not like '%P5 5.2 Permutations and combinations%' or m.coursebook_mapping_ref not like '%Ch6%98-111%'))
      or (m.primary_skill_code in ('P5-PRO-02','P5-PRO-04') and (m.official_scope_ref not like '%P5 5.3 Probability%' or m.coursebook_mapping_ref not like '%Ch4%63-82%'))
    );
  if v_bad<>0 then
    raise exception 'aw09_12 supplemental draft: source-map mismatch rows=%',v_bad;
  end if;

  -- No exact English stem reuse inside the same skill against any already-published version.
  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code
     and oldm.content_version_id<>m.content_version_id
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4809,4810)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then
    raise exception 'aw09_12 supplemental draft: exact published stem duplicate';
  end if;

  -- Answer positions are balanced within each component.
  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4809;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,4,4,8) then
    raise exception 'aw09_12 supplemental draft: P1 answer balance mismatch';
  end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4810;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(3,3,3,3,6) then
    raise exception 'aw09_12 supplemental draft: P5 answer balance mismatch';
  end if;

  -- Written tasks and checks are trilingual, governed and structurally complete.
  select count(*) into v_bad
  from private.exam_prep_written_tasks wt
  left join private.exam_prep_written_understanding_checks c on c.written_task_id=wt.id
  where wt.content_version_id in (4809,4810)
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
      or jsonb_array_length(c.options_en)<>4
      or jsonb_array_length(c.options_ru)<>4
      or jsonb_array_length(c.options_uz)<>4
      or c.correct_index not between 0 and 3
    );
  if v_bad<>0 then
    raise exception 'aw09_12 supplemental draft: written/check QA rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_written_understanding_checks where id between 8924 and 8937 and correct_index=0)<>4
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8924 and 8937 and correct_index=1)<>4
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8924 and 8937 and correct_index=2)<>3
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8924 and 8937 and correct_index=3)<>3
  then
    raise exception 'aw09_12 supplemental draft: written-check answer balance mismatch';
  end if;

  -- Draft has no learner/legacy history.
  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4809,4810)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4809,4810)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4809,4810)
  ) then
    raise exception 'aw09_12 supplemental draft: history contamination';
  end if;
END
$$;

\echo 'AW9-12 supplemental learning draft v1 contract: GREEN'
