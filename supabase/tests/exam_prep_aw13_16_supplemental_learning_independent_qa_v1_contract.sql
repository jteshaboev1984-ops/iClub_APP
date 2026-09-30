-- AW13-16 supplemental learning independent-QA contract v1.
-- The candidate remains draft/withheld. This pins the reviewed correction surface.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4813,4814) and status='draft')<>2 then
    raise exception 'aw13_16 independent QA contract: target drafts missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4813,4814)
        and lifecycle_state='draft' and exposure_state='withheld')<>45 then
    raise exception 'aw13_16 independent QA contract: machine draft boundary mismatch';
  end if;

  -- Pin every answer changed or materially re-authored during independent QA.
  with expected(content_key,answer) as (values
    ('P1CIR03-A02','B'),
    ('P1TRI03-A02','B'),
    ('P1TRI05-A01','A'),
    ('P1SER01-A02','D'),
    ('P1SER02-A03','11'),
    ('P1DIF01-A01','C'),
    ('P1DIF01-A03','12'),
    ('P5PRO06-A01','C'),
    ('P5BIN01-A02','D'),
    ('P5GEO01-A02','B')
  )
  select count(*) into v_bad
  from expected e
  left join private.exam_prep_question_content_meta m
    on m.content_version_id in (4813,4814)
   and m.content_key=e.content_key
  left join public.questions q on q.id=m.question_id
  where q.id is null or q.correct_answer<>e.answer;
  if v_bad<>0 then
    raise exception 'aw13_16 independent QA contract: corrected answer map mismatch rows=%',v_bad;
  end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4813 and m.content_key='P1CIR03-A02'
      and q.question_text_en like '%area 36 cm²%' and q.correct_answer='B'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4813 and m.content_key='P1TRI03-A02'
      and q.question_text_en like '%principal value rather than 258.5°%' and q.correct_answer='B'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4813 and m.content_key='P1TRI05-A01'
      and q.question_text_en like '%y=3+6sinθ%' and q.correct_answer='A'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4813 and m.content_key='P1SER01-A02'
      and q.question_text_en like '%(1−2x)³(1+x)%' and q.correct_answer='D'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4813 and m.content_key='P1SER02-A03'
      and q.question_text_en like '%4, k and 18%' and q.correct_answer='11'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4813 and m.content_key='P1DIF01-A01'
      and q.question_text_en like '%secant gradient%' and q.correct_answer='C'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4813 and m.content_key='P1DIF01-A03'
      and q.question_text_en like '%average gradient%' and q.correct_answer='12'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4814 and m.content_key='P5PRO06-A01'
      and q.question_text_en like '%applicants%' and q.correct_answer='C'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4814 and m.content_key='P5BIN01-A02'
      and q.question_text_en like '%machine is adjusted%' and q.correct_answer='D'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4814 and m.content_key='P5GEO01-A02'
      and q.options_text_en like '%probability of scoring changes%' and q.correct_answer='B'
  ) then
    raise exception 'aw13_16 independent QA contract: reviewed stem surface mismatch';
  end if;

  -- Exact reuse against any already-published same-skill content is forbidden.
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
    where m.content_version_id in (4813,4814)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then
    raise exception 'aw13_16 independent QA contract: exact published stem reuse';
  end if;

  -- Frozen source snapshots must match after every correction.
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4813,4814)
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
    raise exception 'aw13_16 independent QA contract: snapshot drift rows=%',v_bad;
  end if;

  -- Written second-pass arithmetic pins.
  if not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15646 and content_version_id=4814
      and prompt_en like 'In a school club, 48 students%'
      and (rubric_json->'criteria'->2->>'rule') like '%Economics-only 18 and Chess-only 12%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15647 and content_version_id=4814
      and (rubric_json->'criteria'->1->>'rule') like '%14/45%'
  ) then
    raise exception 'aw13_16 independent QA contract: P5 written correction pin missing';
  end if;

  -- All 15 written tasks remain six-mark, trilingual and have one trilingual check.
  select count(*) into v_bad
  from private.exam_prep_written_tasks wt
  left join private.exam_prep_written_understanding_checks c on c.written_task_id=wt.id
  where wt.content_version_id in (4813,4814)
    and (
      wt.lifecycle_state<>'draft'
      or coalesce((wt.rubric_json->>'max_marks')::int,0)<>6
      or nullif(btrim(wt.prompt_en),'') is null
      or nullif(btrim(wt.prompt_ru),'') is null
      or nullif(btrim(wt.prompt_uz),'') is null
      or c.id is null
      or c.lifecycle_state<>'draft'
      or jsonb_array_length(c.options_en)<>4
      or jsonb_array_length(c.options_ru)<>4
      or jsonb_array_length(c.options_uz)<>4
      or c.correct_index not between 0 and 3
    );
  if v_bad<>0 then
    raise exception 'aw13_16 independent QA contract: written/check review rows=%',v_bad;
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4813,4814)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4813,4814)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4813,4814)
  ) then
    raise exception 'aw13_16 independent QA contract: history contamination';
  end if;
END
$$;

\echo 'AW13-16 supplemental learning independent-QA v1 contract: GREEN'
