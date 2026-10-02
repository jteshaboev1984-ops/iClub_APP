-- AW21-24 annual reserve release v1 contract.
-- Runs after the full migration stack and verifies the governed withheld reserve.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_seq text;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4823,4824) and status='published')<>2 then
    raise exception 'aw21_24 reserve release: expected two published versions';
  end if;

  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4823,4824)
        and release_mode='supplemental_reserve'
        and profile_version='aw21_24_annual_reserve_release_v1'
        and require_written_understanding=false)<>2 then
    raise exception 'aw21_24 reserve release: release profile mismatch';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4823,4824)
        and lifecycle_state='reserve'
        and exposure_state='withheld'
        and copyright_status='pass'
        and qa_scope_status='pass'
        and qa_math_status='pass'
        and qa_language_status='pass'
        and qa_technical_status='pass')<>90
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4823,4824) and reserve_role='diagnostic')<>36
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4823,4824) and reserve_role='retest')<>36
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4823,4824) and reserve_role='mixed')<>18 then
    raise exception 'aw21_24 reserve release: governed reserve cardinality/state mismatch';
  end if;

  if exists(select 1 from private.exam_prep_written_tasks where content_version_id in (4823,4824)) then
    raise exception 'aw21_24 reserve release: reserve-only versions contain written tasks';
  end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4823,4824)
        and m.reserve_role='diagnostic'
        and r.rule_version='aw_reserve_v1'
        and r.status='approved')<>108 then
    raise exception 'aw21_24 reserve release: approved diagnostic-rule cardinality mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4823,4824)
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
  if v_bad<>0 then
    raise exception 'aw21_24 reserve release: public-source/trilingual/snapshot rows=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4823,4824)
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
  if v_bad<>0 then
    raise exception 'aw21_24 reserve release: type/options rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4823,4824) and status='published')<>42
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4823,4824))<>90
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4823,4824) and ai.is_holdout)<>90 then
    raise exception 'aw21_24 reserve release: assessment/holdout shape mismatch';
  end if;

  if exists(
    select 1 from private.exam_prep_assessment_items ai
    join private.exam_prep_assessments a on a.id=ai.assessment_id
    join private.exam_prep_question_content_meta m
      on m.question_id=ai.question_id and m.content_version_id=a.content_version_id
    where a.content_version_id in (4823,4824)
      and (
        ai.written_task_id is not null
        or ai.primary_skill_code<>m.primary_skill_code
        or ai.reserve_role<>m.reserve_role
        or ai.reserve_role<>a.assessment_type
        or ai.is_holdout is not true
      )
  ) then
    raise exception 'aw21_24 reserve release: assessment role/isolation mismatch';
  end if;

  with expected(content_key,answer) as (values
    ('P1COO05-D02','B'),
    ('P1COO05-D03','A'),
    ('P1COO05-R03','4'),
    ('P1COO05-R04','C'),
    ('P1COO05-M02','2'),
    ('P1COO06-D02','A'),
    ('P1COO06-D03','D'),
    ('P1COO06-R03','2'),
    ('P1COO06-R04','A'),
    ('P1COO06-M02','4'),
    ('P1DIF05-D02','C'),
    ('P1DIF05-D03','B'),
    ('P1DIF05-R03','6'),
    ('P1DIF05-R04','C'),
    ('P1DIF05-M02','2'),
    ('P1DIF06-D02','A'),
    ('P1DIF06-D03','C'),
    ('P1DIF06-R03','3'),
    ('P1DIF06-R04','A'),
    ('P1DIF06-M02','15'),
    ('P1DIF07-D02','B'),
    ('P1DIF07-D03','D'),
    ('P1DIF07-R03','1'),
    ('P1DIF07-R04','B'),
    ('P1DIF07-M02','2'),
    ('P1INT01-D02','D'),
    ('P1INT01-D03','B'),
    ('P1INT01-R03','3'),
    ('P1INT01-R04','D'),
    ('P1INT01-M02','2'),
    ('P1INT02-D02','C'),
    ('P1INT02-D03','D'),
    ('P1INT02-R03','-3'),
    ('P1INT02-R04','B'),
    ('P1INT02-M02','38'),
    ('P1INT03-D02','D'),
    ('P1INT03-D03','C'),
    ('P1INT03-R03','12'),
    ('P1INT03-R04','A'),
    ('P1INT03-M02','4'),
    ('P1INT04-D02','B'),
    ('P1INT04-D03','A'),
    ('P1INT04-R03','32/3'),
    ('P1INT04-R04','D'),
    ('P1INT04-M02','4'),
    ('P1INT05-D02','A'),
    ('P1INT05-D03','C'),
    ('P1INT05-R03','8'),
    ('P1INT05-R04','B'),
    ('P1INT05-M02','18'),
    ('P5DAT08-D02','B'),
    ('P5DAT08-D03','C'),
    ('P5DAT08-R03','8'),
    ('P5DAT08-R04','B'),
    ('P5DAT08-M02','4'),
    ('P5DAT09-D02','D'),
    ('P5DAT09-D03','B'),
    ('P5DAT09-R03','13'),
    ('P5DAT09-R04','D'),
    ('P5DAT09-M02','6'),
    ('P5DAT10-D02','C'),
    ('P5DAT10-D03','D'),
    ('P5DAT10-R03','84'),
    ('P5DAT10-R04','B'),
    ('P5DAT10-M02','15'),
    ('P5NOR02-D02','D'),
    ('P5NOR02-D03','B'),
    ('P5NOR02-R03','2'),
    ('P5NOR02-R04','A'),
    ('P5NOR02-M02','-2'),
    ('P5NOR03-D02','B'),
    ('P5NOR03-D03','A'),
    ('P5NOR03-R03','0.1357'),
    ('P5NOR03-R04','C'),
    ('P5NOR03-M02','0.95'),
    ('P5NOR04-D02','A'),
    ('P5NOR04-D03','C'),
    ('P5NOR04-R03','33.59'),
    ('P5NOR04-R04','A'),
    ('P5NOR04-M02','86.02'),
    ('P5NOR05-D02','C'),
    ('P5NOR05-D03','A'),
    ('P5NOR05-R03','43'),
    ('P5NOR05-R04','D'),
    ('P5NOR05-M02','60'),
    ('P5NOR06-D02','A'),
    ('P5NOR06-D03','D'),
    ('P5NOR06-R03','24.5'),
    ('P5NOR06-R04','C'),
    ('P5NOR06-M02','31.5')
  )
  select count(*) into v_bad
  from expected e
  left join private.exam_prep_question_content_meta m
    on m.content_version_id in (4823,4824) and m.content_key=e.content_key
  left join public.questions q on q.id=m.question_id
  where q.id is null or q.correct_answer<>e.answer;
  if v_bad<>0 then
    raise exception 'aw21_24 reserve release: independent-QA 90-answer map mismatch rows=%',v_bad;
  end if;

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
      raise exception 'aw21_24 reserve release: sequential correct-option pattern detected: %',v_seq;
    end if;
  end loop;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5DAT08-D02'
      and q.correct_answer='B'
      and q.question_text_en like 'Route A delivery times%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5DAT09-D02'
      and q.correct_answer='D'
      and q.question_text_en like '%standard deviation%'
      and q.options_text_en::jsonb->>3='3'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5NOR04-M02'
      and q.correct_answer='86.02'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5NOR06-D03'
      and q.correct_answer='D'
      and q.options_text_en::jsonb->>3='Both np and n(1−p) should be sufficiently large'
  ) then
    raise exception 'aw21_24 reserve release: independent-QA semantic pin missing';
  end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code
     and oldm.content_version_id<>m.content_version_id
    join private.exam_prep_content_versions oldcv
      on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4823,4824)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then
    raise exception 'aw21_24 reserve release: exact published stem reuse';
  end if;

  if coalesce((private.exam_prep_supplemental_reserve_floor_v1(4823)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4824)->>'ready')::boolean,false) is not true then
    raise exception 'aw21_24 reserve release: reserve floor RED';
  end if;

  with expected(component_code,skill_code) as (values
    ('P1','P1-COO-05'),
    ('P1','P1-COO-06'),
    ('P1','P1-DIF-05'),
    ('P1','P1-DIF-06'),
    ('P1','P1-DIF-07'),
    ('P1','P1-INT-01'),
    ('P1','P1-INT-02'),
    ('P1','P1-INT-03'),
    ('P1','P1-INT-04'),
    ('P1','P1-INT-05'),
    ('P5','P5-DAT-08'),
    ('P5','P5-DAT-09'),
    ('P5','P5-DAT-10'),
    ('P5','P5-NOR-02'),
    ('P5','P5-NOR-03'),
    ('P5','P5-NOR-04'),
    ('P5','P5-NOR-05'),
    ('P5','P5-NOR-06')
  ), q as (
    select cv.component_code,m.primary_skill_code skill_code,
      count(*) filter(where m.reserve_role='diagnostic') d,
      count(*) filter(where m.reserve_role='learning') l,
      count(*) filter(where m.reserve_role='retest') r,
      count(*) filter(where m.reserve_role='mixed') x
    from private.exam_prep_question_content_meta m
    join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    join expected e
      on e.component_code=cv.component_code and e.skill_code=m.primary_skill_code
    where cv.status='published' and m.lifecycle_state in ('published','reserve')
    group by cv.component_code,m.primary_skill_code
  ), w as (
    select component_code,primary_skill_code skill_code,count(*) n
    from private.exam_prep_written_tasks
    where lifecycle_state='published'
      and primary_skill_code in ('P1-COO-05','P1-COO-06','P1-DIF-05','P1-DIF-06','P1-DIF-07','P1-INT-01','P1-INT-02','P1-INT-03','P1-INT-04','P1-INT-05','P5-DAT-08','P5-DAT-09','P5-DAT-10','P5-NOR-02','P5-NOR-03','P5-NOR-04','P5-NOR-05','P5-NOR-06')
    group by component_code,primary_skill_code
  )
  select count(*) into v_bad
  from expected e
  left join q using(component_code,skill_code)
  left join w using(component_code,skill_code)
  where coalesce(q.d,0)<>3
     or coalesce(q.l,0)+coalesce(q.x,0)<>8
     or coalesce(q.r,0)<>4
     or coalesce(w.n,0)<2;
  if v_bad<>0 then
    raise exception 'aw21_24 reserve release: final annual depth mismatch rows=%',v_bad;
  end if;

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
  ) then
    raise exception 'aw21_24 reserve release: history contamination';
  end if;

  -- Feature/service state is enforced by the publication migration itself.
  -- CI may intentionally exercise alternate service modes before this contract.
END
$$;

\echo 'AW21-24 annual reserve release v1 contract: GREEN'
