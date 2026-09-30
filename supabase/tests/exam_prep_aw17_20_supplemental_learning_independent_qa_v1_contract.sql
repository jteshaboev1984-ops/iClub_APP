-- AW17-20 supplemental learning independent-QA contract v1.
-- Draft/history-free candidate. Pins the independently reviewed correction surface.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4817,4818) and status='draft')<>2 then
    raise exception 'aw17_20 independent QA contract: target draft versions missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4817,4818)
        and lifecycle_state='draft' and exposure_state='withheld')<>33 then
    raise exception 'aw17_20 independent QA contract: machine draft boundary mismatch';
  end if;

  with expected(content_key,answer) as (values
    ('P1SER03-A02','D'),
    ('P1SER03-A03','3'),
    ('P1SER04-A01','A'),
    ('P1SER05-A01','C'),
    ('P1SER05-A02','D'),
    ('P1DIF02-A01','A'),
    ('P1DIF02-A02','B'),
    ('P1DIF03-A01','C'),
    ('P1DIF03-A02','D'),
    ('P1DIF04-A01','A'),
    ('P5BIN03-A02','C'),
    ('P5GEO02-A01','A'),
    ('P5GEO03-A02','B'),
    ('P5NOR01-A03','144')
  )
  select count(*) into v_bad
  from expected e
  left join private.exam_prep_question_content_meta m
    on m.content_version_id in (4817,4818)
   and m.content_key=e.content_key
  left join public.questions q on q.id=m.question_id
  where q.id is null or q.correct_answer<>e.answer;
  if v_bad<>0 then
    raise exception 'aw17_20 independent QA contract: corrected answer map mismatch rows=%',v_bad;
  end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4817 and m.content_key='P1SER03-A02'
      and q.question_text_en like '%S₁₀=220%' and q.correct_answer='D'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4817 and m.content_key='P1SER05-A01'
      and q.question_text_en like '%finite sum to infinity%' and q.correct_answer='C'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4817 and m.content_key='P1DIF02-A01'
      and q.question_text_en like '%derivative of y=kx^(3/2)%' and q.correct_answer='A'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4817 and m.content_key='P1DIF03-A01'
      and q.question_text_en like '%student differentiates%' and q.correct_answer='C'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4817 and m.content_key='P1DIF04-A01'
      and q.question_text_en like '%y=9x+c%' and q.correct_answer='A'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4818 and m.content_key='P5BIN03-A02'
      and q.question_text_en like '%E(X)=24%' and q.correct_answer='C'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4818 and m.content_key='P5GEO02-A01'
      and q.question_text_en like '%P(X≤4)%' and q.correct_answer='A'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4818 and m.content_key='P5GEO03-A02'
      and q.question_text_en like '%increases to 0.40%' and q.correct_answer='B'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4818 and m.content_key='P5NOR01-A03'
      and q.question_text_en like '%standard deviation 12%' and q.correct_answer='144'
  ) then
    raise exception 'aw17_20 independent QA contract: reviewed stem surface mismatch';
  end if;

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
    where m.content_version_id in (4817,4818)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then
    raise exception 'aw17_20 independent QA contract: exact published stem reuse';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4817,4818)
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
    raise exception 'aw17_20 independent QA contract: snapshot drift rows=%',v_bad;
  end if;

  if not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15653 and content_version_id=4817
      and (rubric_json->'criteria'->4->>'rule') like '%S30=1800%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15654 and content_version_id=4817
      and (rubric_json->'criteria'->4->>'rule') like '%S8=1530%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15655 and content_version_id=4817
      and (rubric_json->'criteria'->4->>'rule') like '%tail after four terms as 1/2%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15656 and content_version_id=4817
      and (rubric_json->'criteria'->4->>'rule') like '%89/8%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15657 and content_version_id=4817
      and (rubric_json->'criteria'->3->>'rule') like '%3/8%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15658 and content_version_id=4817
      and (rubric_json->'criteria'->4->>'rule') like '%−(1/9)%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15660 and content_version_id=4818
      and (rubric_json->'criteria'->2->>'rule') like '%n=50%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15662 and content_version_id=4818
      and (rubric_json->'criteria'->1->>'rule') like '%8 minutes%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15663 and content_version_id=4818
      and (rubric_json->'criteria'->4->>'rule') like '%496 and 504%'
  ) then
    raise exception 'aw17_20 independent QA contract: written arithmetic/scope pin missing';
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_tasks wt
  left join private.exam_prep_written_understanding_checks c on c.written_task_id=wt.id
  where wt.content_version_id in (4817,4818)
    and (
      wt.lifecycle_state<>'draft'
      or coalesce((wt.rubric_json->>'max_marks')::int,0)<>6
      or wt.copyright_status<>'pending'
      or wt.qa_math_status<>'pending'
      or wt.qa_language_status<>'pending'
      or wt.qa_technical_status<>'pending'
      or nullif(btrim(wt.prompt_en),'') is null
      or nullif(btrim(wt.prompt_ru),'') is null
      or nullif(btrim(wt.prompt_uz),'') is null
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
  if v_bad<>0 then
    raise exception 'aw17_20 independent QA contract: written/check review rows=%',v_bad;
  end if;

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
  ) then
    raise exception 'aw17_20 independent QA contract: history contamination';
  end if;
END
$$;

\echo 'AW17-20 supplemental learning independent-QA v1 contract: GREEN'
