-- AW5-8 supplemental learning source/release contract v1.
-- The original draft payload is now governed/published through the
-- supplemental-learning release path; public source questions remain inactive.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4805,4806) and status='published')<>2 then
    raise exception 'aw05_08 supplemental source: expected two published content versions';
  end if;

  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4805,4806)
        and release_mode='supplemental_learning'
        and profile_version='aw05_08_alt_release_v1'
        and require_written_understanding)<>2 then
    raise exception 'aw05_08 supplemental source: release profile mismatch';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id=4805 and lifecycle_state='published'
        and reserve_role='learning' and exposure_state='released')<>24
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id=4806 and lifecycle_state='published'
           and reserve_role='learning' and exposure_state='released')<>18 then
    raise exception 'aw05_08 supplemental source: machine content state mismatch';
  end if;

  if (select count(*) from private.exam_prep_written_tasks
      where content_version_id=4805 and lifecycle_state='published')<>8
     or (select count(*) from private.exam_prep_written_tasks
         where content_version_id=4806 and lifecycle_state='published')<>6
     or (select count(*) from private.exam_prep_written_understanding_checks c
         join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
         where wt.content_version_id in (4805,4806) and c.lifecycle_state='published')<>14 then
    raise exception 'aw05_08 supplemental source: written/check state mismatch';
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id=4805 and assessment_type='learning' and status='published')<>8
     or (select count(*) from private.exam_prep_assessments
         where content_version_id=4806 and assessment_type='learning' and status='published')<>6
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4805,4806))<>56 then
    raise exception 'aw05_08 supplemental source: assessment shape mismatch';
  end if;

  select count(*) into v_bad
  from (
    select a.id,
      count(*) filter(where ai.question_id is not null and ai.reserve_role='learning' and not ai.is_holdout) machine_n,
      count(*) filter(where ai.written_task_id is not null and ai.reserve_role='written' and not ai.is_holdout) written_n,
      count(distinct ai.primary_skill_code) skill_n,
      count(*) total_n
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id in (4805,4806)
    group by a.id
    having count(*) filter(where ai.question_id is not null and ai.reserve_role='learning' and not ai.is_holdout)<>3
        or count(*) filter(where ai.written_task_id is not null and ai.reserve_role='written' and not ai.is_holdout)<>1
        or count(distinct ai.primary_skill_code)<>1
        or count(*)<>4
  ) x;
  if v_bad<>0 then
    raise exception 'aw05_08 supplemental source: per-assessment 3+1 mismatch rows=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4805,4806)
    and (
      m.copyright_status<>'pass'
      or m.qa_scope_status<>'pass'
      or m.qa_math_status<>'pass'
      or m.qa_language_status<>'pass'
      or m.qa_technical_status<>'pass'
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
    raise exception 'aw05_08 supplemental source: trilingual/type/options QA rows=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4805,4806)
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
    raise exception 'aw05_08 supplemental source: frozen snapshot mismatch rows=%',v_bad;
  end if;

  -- Independent QA corrections remain locked.
  if (select q.correct_answer
      from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
      where m.content_version_id=4805 and m.content_key='P1FUN06-A01')<>'D'
     or (select q.correct_answer
         from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
         where m.content_version_id=4805 and m.content_key='P1FUN07-A02')<>'A'
     or (select count(distinct v)
         from private.exam_prep_question_content_meta m
         join public.questions q on q.id=m.question_id
         cross join lateral jsonb_array_elements_text(q.options_text_en::jsonb) z(v)
         where m.content_version_id=4805 and m.content_key='P1TRI01-A02')<>4 then
    raise exception 'aw05_08 supplemental source: independent QA correction drift';
  end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4805;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,4,4,8) then
    raise exception 'aw05_08 supplemental source: P1 answer balance mismatch';
  end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4806;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(3,3,3,3,6) then
    raise exception 'aw05_08 supplemental source: P5 answer balance mismatch';
  end if;

  if coalesce((private.exam_prep_supplemental_learning_floor_v1(4805)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4806)->>'ready')::boolean,false) is not true then
    raise exception 'aw05_08 supplemental source: publication floor is RED';
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4805,4806)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4805,4806)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4805,4806)
  ) then
    raise exception 'aw05_08 supplemental source: history contamination';
  end if;
END
$$;

\echo 'AW5-8 supplemental learning source/release contract: GREEN'
