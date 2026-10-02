-- AW21-24 annual-reserve top-up draft v1 contract.
-- Validates the hidden/history-free reserve candidate only; does not approve or publish it.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
  v_seq text;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4823,4824)
        and content_version in ('p1_aw21_24_annual_reserve_topup_draft_v1','p5_aw21_24_annual_reserve_topup_draft_v1')
        and status='draft')<>2 then
    raise exception 'aw21_24 annual reserve draft: target versions missing';
  end if;

  if exists(select 1 from private.exam_prep_content_release_profiles_v1 where content_version_id in (4823,4824)) then
    raise exception 'aw21_24 annual reserve draft: release profile exists before independent approval';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4823,4824)
        and lifecycle_state='draft' and exposure_state='withheld')<>90
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4823)<>50
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4824)<>40
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4823,4824) and reserve_role='diagnostic')<>36
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4823,4824) and reserve_role='retest')<>36
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4823,4824) and reserve_role='mixed')<>18 then
    raise exception 'aw21_24 annual reserve draft: question cardinality/role mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4823,4824)
    and (
      q.subject_id<>5
      or q.is_active
      or q.quality_status<>'draft'
      or m.lifecycle_state<>'draft'
      or m.exposure_state<>'withheld'
      or m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
      or (m.reserve_role='diagnostic' and (q.qtype<>'mcq' or m.diagnostic_rule_status<>'pending'))
      or (m.reserve_role<>'diagnostic' and m.diagnostic_rule_status<>'not_applicable')
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
  if v_bad<>0 then raise exception 'aw21_24 annual reserve draft: payload/trilingual/snapshot rows=%',v_bad; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
    into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4823;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(8,8,7,7,20) then
    raise exception 'aw21_24 annual reserve draft: P1 answer balance mismatch A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
    into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4824;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(6,6,6,6,16) then
    raise exception 'aw21_24 annual reserve draft: P5 answer balance mismatch A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D')
    into v_a,v_b,v_c,v_d
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4823 and m.reserve_role='diagnostic';
  if (v_a,v_b,v_c,v_d)<>(5,5,5,5) then
    raise exception 'aw21_24 annual reserve draft: P1 diagnostic answer balance mismatch A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D')
    into v_a,v_b,v_c,v_d
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4824 and m.reserve_role='diagnostic';
  if (v_a,v_b,v_c,v_d)<>(4,4,4,4) then
    raise exception 'aw21_24 annual reserve draft: P5 diagnostic answer balance mismatch A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  end if;

  for v_seq in
    select string_agg(q.correct_answer,'' order by m.id)
    from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id in (4823,4824) and q.qtype='mcq'
    group by m.content_version_id
  loop
    if v_seq like any(array['%ABCD%','%BCDA%','%CDAB%','%DABC%','%DCBA%','%CBAD%','%BADC%','%ADCB%'])
       or v_seq ~ '(AA|BB|CC|DD)' then
      raise exception 'aw21_24 annual reserve draft: sequential correct-option pattern detected: %',v_seq;
    end if;
  end loop;

  -- Check the order learners actually see inside each multi-item diagnostic form,
  -- not only the storage order of source rows.
  for v_seq in
    select string_agg(q.correct_answer,'' order by ai.item_order)
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    join public.questions q on q.id=ai.question_id
    where a.id in (35529,35530,35552,35553)
    group by a.id
  loop
    if v_seq like any(array['%ABCD%','%BCDA%','%CDAB%','%DABC%','%DCBA%','%CBAD%','%BADC%','%ADCB%'])
       or v_seq ~ '(AA|BB|CC|DD)' then
      raise exception 'aw21_24 annual reserve draft: learner-form sequential correct-option pattern detected: %',v_seq;
    end if;
  end loop;

  select count(*) into v_bad
  from (
    select a.id,l.letter,count(q.id) filter(where q.correct_answer=l.letter) as cnt
    from private.exam_prep_assessments a
    cross join (values('A'),('B'),('C'),('D')) l(letter)
    left join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    left join public.questions q on q.id=ai.question_id
    where a.id in (35529,35530)
    group by a.id,l.letter
  ) x
  where x.cnt not between 2 and 3;
  if v_bad<>0 then
    raise exception 'aw21_24 annual reserve draft: P1 learner-form answer balance failed cells=%',v_bad;
  end if;

  select count(*) into v_bad
  from (
    select a.id,l.letter,count(q.id) filter(where q.correct_answer=l.letter) as cnt
    from private.exam_prep_assessments a
    cross join (values('A'),('B'),('C'),('D')) l(letter)
    left join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    left join public.questions q on q.id=ai.question_id
    where a.id in (35552,35553)
    group by a.id,l.letter
  ) x
  where x.cnt<>2;
  if v_bad<>0 then
    raise exception 'aw21_24 annual reserve draft: P5 learner-form answer balance failed cells=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4823,4824) and status='draft')<>42
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4823,4824) and assessment_type='diagnostic')<>4
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4823,4824) and assessment_type='retest')<>36
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4823,4824) and assessment_type='mixed')<>2
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4823,4824))<>90 then
    raise exception 'aw21_24 annual reserve draft: assessment cardinality mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_assessment_items ai
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  join private.exam_prep_question_content_meta m
    on m.question_id=ai.question_id and m.content_version_id=a.content_version_id
  where a.content_version_id in (4823,4824)
    and (
      ai.written_task_id is not null
      or ai.is_holdout is not true
      or ai.primary_skill_code<>m.primary_skill_code
      or ai.reserve_role<>m.reserve_role
      or ai.reserve_role<>a.assessment_type
      or ai.primary_skill_code not like a.component_code||'-%'
    );
  if v_bad<>0 then raise exception 'aw21_24 annual reserve draft: assessment isolation/role rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_assessments a
  where a.content_version_id in (4823,4824) and a.assessment_type='retest'
    and (select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id)<>1;
  if v_bad<>0 then raise exception 'aw21_24 annual reserve draft: non-isolated retest rows=%',v_bad; end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4823,4824)
        and m.reserve_role='diagnostic'
        and r.rule_version='aw_reserve_v1'
        and r.status='draft')<>108 then
    raise exception 'aw21_24 annual reserve draft: diagnostic-rule cardinality mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4823,4824) and m.reserve_role='diagnostic'
    and (select count(*) from private.exam_prep_diagnostic_rules r
         where r.content_meta_id=m.id
           and r.rule_version='aw_reserve_v1'
           and r.status='draft'
           and r.answer_kind='mcq_option'
           and r.answer_match<>q.correct_answer
           and r.weak_skill_code=m.primary_skill_code
           and nullif(btrim(r.feedback_en),'') is not null
           and nullif(btrim(r.feedback_ru),'') is not null
           and nullif(btrim(r.feedback_uz),'') is not null
           and nullif(btrim(r.next_action_en),'') is not null
           and nullif(btrim(r.next_action_ru),'') is not null
           and nullif(btrim(r.next_action_uz),'') is not null)<>3;
  if v_bad<>0 then raise exception 'aw21_24 annual reserve draft: diagnostic misconception coverage rows=%',v_bad; end if;

  if exists(select 1 from private.exam_prep_written_tasks where content_version_id in (4823,4824)) then
    raise exception 'aw21_24 annual reserve draft: reserve-only version contains written tasks';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  where m.content_version_id in (4823,4824)
    and (
      (m.primary_skill_code in ('P1-COO-05','P1-COO-06')
        and (m.official_scope_ref not like '%P1 1.3 Coordinate geometry%' or m.coursebook_mapping_ref not like '%Ch3%48-67%'))
      or (m.primary_skill_code in ('P1-DIF-05','P1-DIF-06','P1-DIF-07')
        and (m.official_scope_ref not like '%P1 1.7 Differentiation%' or m.coursebook_mapping_ref not like '%Ch9%156-167%'))
      or (m.primary_skill_code like 'P1-INT-%'
        and (m.official_scope_ref not like '%P1 1.8 Integration%' or m.coursebook_mapping_ref not like '%Ch10%173-200%'))
      or (m.primary_skill_code='P5-DAT-08'
        and (m.official_scope_ref not like '%P5 5.1 Representation of data%' or m.coursebook_mapping_ref not like '%Ch2-3%14-59%'))
      or (m.primary_skill_code in ('P5-DAT-09','P5-DAT-10')
        and (m.official_scope_ref not like '%P5 5.1 Representation of data%' or m.coursebook_mapping_ref not like '%Ch2%14-29%'))
      or (m.primary_skill_code in ('P5-NOR-02','P5-NOR-03','P5-NOR-04','P5-NOR-05')
        and (m.official_scope_ref not like '%P5 5.5 The normal distribution%' or m.coursebook_mapping_ref not like '%Ch9%147-171%'))
      or (m.primary_skill_code='P5-NOR-06'
        and (m.official_scope_ref not like '%P5 5.5 The normal distribution%' or m.coursebook_mapping_ref not like '%Ch10%173-179%'))
    );
  if v_bad<>0 then raise exception 'aw21_24 annual reserve draft: source-map mismatch rows=%',v_bad; end if;

  select count(*) into v_bad
  from (
    with skills(component_code,skill_code) as (values ('P1','P1-COO-05'),('P1','P1-COO-06'),('P1','P1-DIF-05'),('P1','P1-DIF-06'),('P1','P1-DIF-07'),('P1','P1-INT-01'),('P1','P1-INT-02'),('P1','P1-INT-03'),('P1','P1-INT-04'),('P1','P1-INT-05'),('P5','P5-DAT-08'),('P5','P5-DAT-09'),('P5','P5-DAT-10'),('P5','P5-NOR-02'),('P5','P5-NOR-03'),('P5','P5-NOR-04'),('P5','P5-NOR-05'),('P5','P5-NOR-06'))
    select s.component_code,s.skill_code
    from skills s
    left join private.exam_prep_question_content_meta m on m.primary_skill_code=s.skill_code
    left join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    group by s.component_code,s.skill_code
    having count(distinct m.id) filter(where m.reserve_role='diagnostic' and (
             (cv.status='published' and m.lifecycle_state in ('published','reserve'))
             or (cv.id in (4823,4824) and cv.status='draft' and m.lifecycle_state='draft'))) < 3
        or count(distinct m.id) filter(where m.reserve_role='retest' and (
             (cv.status='published' and m.lifecycle_state in ('published','reserve'))
             or (cv.id in (4823,4824) and cv.status='draft' and m.lifecycle_state='draft'))) < 4
        or count(distinct m.id) filter(where m.reserve_role='mixed' and (
             (cv.status='published' and m.lifecycle_state in ('published','reserve'))
             or (cv.id in (4823,4824) and cv.status='draft' and m.lifecycle_state='draft'))) < 2
  ) x;
  if v_bad<>0 then raise exception 'aw21_24 annual reserve draft: prospective reserve depth failed rows=%',v_bad; end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>m.content_version_id
    join private.exam_prep_content_versions oldcv
      on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4823,4824)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw21_24 annual reserve draft: exact published stem reuse'; end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4823,4824)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4823,4824)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4823,4824)
  ) then raise exception 'aw21_24 annual reserve draft: history contamination'; end if;
END
$$;

\echo 'AW21-24 annual reserve top-up draft v1 contract: GREEN'
