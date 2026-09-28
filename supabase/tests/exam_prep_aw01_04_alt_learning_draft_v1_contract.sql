-- Contract for AW1-4 alternate learning draft packs.
-- Draft rows must be complete, trilingual, unique, and impossible to select at runtime.
begin;
do $$
declare
  v_bad int;
begin
  if to_regclass('private.exam_prep_content_versions') is null then
    raise exception 'alt_learning_draft_v1 schema missing';
  end if;

  if (select count(*) from private.exam_prep_content_versions where id in (4801,4802) and status='draft')<>2 then
    raise exception 'alt_learning_draft_v1 content versions must stay draft';
  end if;

  if (select count(*) from private.exam_prep_assessments where content_version_id in (4801,4802) and status='draft')<>9
     or (select count(*) from private.exam_prep_written_tasks where content_version_id in (4801,4802) and lifecycle_state='draft')<>9
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4801,4802) and lifecycle_state='draft' and reserve_role='learning')<>27
  then
    raise exception 'alt_learning_draft_v1 cardinality mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4801,4802)
    and (
      nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
      or q.is_active
      or q.quality_status<>'draft'
      or m.exposure_state<>'withheld'
      or m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or m.diagnostic_rule_status<>'not_applicable'
    );
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 draft safety/trilingual rows invalid=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_tasks wt
  where wt.content_version_id in (4801,4802)
    and (
      nullif(btrim(wt.prompt_en),'') is null
      or nullif(btrim(wt.prompt_ru),'') is null
      or nullif(btrim(wt.prompt_uz),'') is null
      or nullif(btrim(wt.self_review_en),'') is null
      or nullif(btrim(wt.self_review_ru),'') is null
      or nullif(btrim(wt.self_review_uz),'') is null
      or coalesce((wt.rubric_json->>'max_marks')::int,0)<=0
      or jsonb_array_length(coalesce(wt.rubric_json->'criteria','[]'::jsonb))<2
      or wt.copyright_status<>'pending'
      or wt.qa_math_status<>'pending'
      or wt.qa_language_status<>'pending'
      or wt.qa_technical_status<>'pending'
    );
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 written draft rows invalid=%',v_bad;
  end if;

  select count(*) into v_bad
  from (
    select lower(regexp_replace(btrim(q.question_text_en),'\s+',' ','g')) norm,count(*) n
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    where m.content_version_id in (4801,4802)
    group by 1
    having count(*)>1
  ) d;
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 duplicate draft stems=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta d
  join public.questions dq on dq.id=d.question_id
  join public.questions pq
    on pq.id<>dq.id
   and lower(regexp_replace(btrim(pq.question_text_en),'\s+',' ','g'))
       =lower(regexp_replace(btrim(dq.question_text_en),'\s+',' ','g'))
  join private.exam_prep_question_content_meta pm on pm.question_id=pq.id
  join private.exam_prep_content_versions pcv on pcv.id=pm.content_version_id and pcv.status='published'
  where d.content_version_id in (4801,4802)
    and pm.reserve_role='learning';
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 exact published stem duplicates=%',v_bad;
  end if;

  with expected(book_ref,answer) as (values
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA01-A01','A'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA01-A02','B'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA01-A03','5'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA02-A01','A'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA02-A02','C'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA02-A03','D'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA03-A01','B'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA03-A02','C'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA03-A03','D'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN01-A01','A'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN01-A02','D'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN01-A03','25'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN02-A01','B'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN02-A02','C'),
    ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN02-A03','D'),
    ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT01-A01','A'),
    ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT01-A02','B'),
    ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT01-A03','C'),
    ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT02-A01','A'),
    ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT02-A02','B'),
    ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT02-A03','D'),
    ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT04-A01','7.5'),
    ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT04-A02','12'),
    ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT04-A03','C'),
    ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT06-A01','B'),
    ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT06-A02','10.625'),
    ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT06-A03','D')
  )
  select count(*) into v_bad
  from expected e
  left join public.questions q on q.book_ref=e.book_ref
  where q.id is null or q.correct_answer is distinct from e.answer;
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 machine answer snapshot mismatch=%',v_bad;
  end if;

  if (select jsonb_object_agg(correct_answer,n order by correct_answer)
      from (
        select q.correct_answer,count(*)::int n
        from private.exam_prep_question_content_meta m
        join public.questions q on q.id=m.question_id
        where m.content_version_id in (4801,4802) and q.qtype='mcq'
        group by q.correct_answer
      ) d)<>jsonb_build_object('A',5,'B',6,'C',5,'D',6)
  then
    raise exception 'alt_learning_draft_v1 stored MCQ answer-position balance drift';
  end if;

  if (select explanation_uz from public.questions
      where book_ref='ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN01-A01')
     <>'x≥0 da h funksiya bir-biriga bir qiymatli. y=x² da x va y ni almashtirib, manfiy bo‘lmagan tarmoqni olsak h⁻¹(x)=√x.'
  then
    raise exception 'alt_learning_draft_v1 Uzbek one-one terminology drift';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4801,4802)
    and (
      (q.qtype='mcq' and q.correct_answer not in ('A','B','C','D'))
      or
      (q.qtype='input' and q.correct_answer !~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$')
    );
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 evaluator-incompatible machine answers=%',v_bad;
  end if;

  with expected_mapping(content_version_id,skill_code,expected_ref,expected_n) as (values
    (4801,'P1-FUN-01','Complete Pure Mathematics 1, Ch2 Functions and transformations, pp.24-42 (mapping only)',3),
    (4801,'P1-FUN-02','Complete Pure Mathematics 1, Ch2 Functions and transformations, pp.24-42 (mapping only)',3),
    (4802,'P5-DAT-01','Complete Probability & Statistics 1, Ch2-3, pp.14-59 (mapping only)',3),
    (4802,'P5-DAT-02','Complete Probability & Statistics 1, Ch3 Representation of data, pp.34-59 (mapping only)',3),
    (4802,'P5-DAT-04','Complete Probability & Statistics 1, Ch3 Representation of data, pp.34-59 (mapping only)',3),
    (4802,'P5-DAT-06','Complete Probability & Statistics 1, Ch2 Measures of location and spread, pp.14-29 (mapping only)',3)
  ),
  actual as (
    select m.content_version_id,m.primary_skill_code skill_code,m.coursebook_mapping_ref,count(*) n
    from private.exam_prep_question_content_meta m
    where m.content_version_id in (4801,4802)
      and m.primary_skill_code in ('P1-FUN-01','P1-FUN-02','P5-DAT-01','P5-DAT-02','P5-DAT-04','P5-DAT-06')
    group by m.content_version_id,m.primary_skill_code,m.coursebook_mapping_ref
  )
  select count(*) into v_bad
  from expected_mapping e
  left join actual a
    on a.content_version_id=e.content_version_id
   and a.skill_code=e.skill_code
   and a.coursebook_mapping_ref=e.expected_ref
   and a.n=e.expected_n
  where a.skill_code is null;
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 canonical source mapping mismatch=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4801,4802)
  ) then
    raise exception 'alt_learning_draft_v1 learner session unexpectedly exists';
  end if;

  select count(*) into v_bad
  from (
    select a.id,
      count(*) filter(where ai.question_id is not null) machine_n,
      count(*) filter(where ai.written_task_id is not null) written_n,
      count(distinct ai.primary_skill_code) skills_n,
      count(*) filter(where ai.is_holdout) holdout_n,
      count(*) filter(where ai.question_id is not null and ai.reserve_role<>'learning') wrong_machine_role,
      count(*) filter(where ai.written_task_id is not null and ai.reserve_role<>'written') wrong_written_role
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id in (4801,4802)
    group by a.id
  ) x
  where machine_n<>3 or written_n<>1 or skills_n<>1 or holdout_n<>0 or wrong_machine_role<>0 or wrong_written_role<>0;
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 assessment shape invalid=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_assessments a
    join private.exam_prep_content_versions cv on cv.id=a.content_version_id
    where cv.id in (4801,4802)
      and (a.status='published' or cv.status='published')
  ) then
    raise exception 'alt_learning_draft_v1 accidentally learner-visible';
  end if;
end
$$;
rollback;
