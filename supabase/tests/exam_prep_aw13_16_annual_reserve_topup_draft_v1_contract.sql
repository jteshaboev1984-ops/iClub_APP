-- AW13-16 annual-reserve top-up draft v1 contract.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4815,4816) and status='draft')<>2 then
    raise exception 'aw13_16 annual reserve draft: expected two draft content versions';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4815,4816) and lifecycle_state='draft' and exposure_state='withheld')<>75
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4815,4816) and reserve_role='diagnostic')<>30
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4815,4816) and reserve_role='retest')<>30
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4815,4816) and reserve_role='mixed')<>15
  then raise exception 'aw13_16 annual reserve draft: question cardinality/state mismatch'; end if;

  if exists(select 1 from private.exam_prep_written_tasks where content_version_id in (4815,4816)) then
    raise exception 'aw13_16 annual reserve draft: reserve-only version contains written tasks';
  end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4815,4816)
        and m.reserve_role='diagnostic'
        and r.rule_version='aw_reserve_v1'
        and r.status='draft')<>90
  then raise exception 'aw13_16 annual reserve draft: diagnostic-rule cardinality mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
    and (
      m.lifecycle_state<>'draft'
      or m.exposure_state<>'withheld'
      or m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or (m.reserve_role='diagnostic' and m.diagnostic_rule_status<>'pending')
      or (m.reserve_role<>'diagnostic' and m.diagnostic_rule_status<>'not_applicable')
      or q.is_active
      or q.quality_status<>'draft'
      or nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
      or nullif(btrim(m.originality_attestation),'') is null
      or nullif(btrim(m.provenance_note),'') is null
      or nullif(btrim(m.official_scope_ref),'') is null
      or nullif(btrim(m.coursebook_mapping_ref),'') is null
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
  if v_bad<>0 then raise exception 'aw13_16 annual reserve draft: QA/source/snapshot rows=%',v_bad; end if;

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
  if v_bad<>0 then raise exception 'aw13_16 annual reserve draft: type/options rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
    and (
      q.options_text_ru ~* '\m(or|only|cm)\M'
      or q.options_text_uz ~* '\m(or|only|cm)\M'
    );
  if v_bad<>0 then raise exception 'aw13_16 annual reserve draft: untranslated option token rows=%',v_bad; end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4815,4816) and status='draft')<>36
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4815,4816) and assessment_type='diagnostic')<>4
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4815,4816) and assessment_type='retest')<>30
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4815,4816) and assessment_type='mixed')<>2
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4815,4816))<>75
  then raise exception 'aw13_16 annual reserve draft: assessment cardinality mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_assessment_items ai
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  join private.exam_prep_question_content_meta m on m.question_id=ai.question_id and m.content_version_id=a.content_version_id
  where a.content_version_id in (4815,4816)
    and (
      ai.written_task_id is not null
      or ai.is_holdout is not true
      or ai.primary_skill_code<>m.primary_skill_code
      or ai.reserve_role<>m.reserve_role
      or ai.reserve_role<>a.assessment_type
      or ai.primary_skill_code not like a.component_code||'-%'
    );
  if v_bad<>0 then raise exception 'aw13_16 annual reserve draft: assessment role/holdout rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
    and m.reserve_role='diagnostic'
    and (
      q.qtype<>'mcq'
      or (select count(*) from private.exam_prep_diagnostic_rules r
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
            and nullif(btrim(r.next_action_uz),'') is not null)<>3
    );
  if v_bad<>0 then raise exception 'aw13_16 annual reserve draft: diagnostic misconception rows=%',v_bad; end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code
     and oldm.content_version_id<>m.content_version_id
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4815,4816)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw13_16 annual reserve draft: exact published stem duplicate'; end if;

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
  if v_bad<>0 then raise exception 'aw13_16 annual reserve draft: source-map rows=%',v_bad; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4815;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(7,7,5,5,16) then
    raise exception 'aw13_16 annual reserve draft: P1 answer balance mismatch';
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4816;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(6,5,5,5,14) then
    raise exception 'aw13_16 annual reserve draft: P5 answer balance mismatch';
  end if;

  -- Prospective annual numeric floor after publishing these withheld reserve items.
  select count(*) into v_bad
  from (
    with skills(component_code,skill_code) as (values
      ('P1','P1-CIR-03'),('P1','P1-TRI-02'),('P1','P1-TRI-03'),('P1','P1-TRI-04'),('P1','P1-TRI-05'),('P1','P1-SER-01'),('P1','P1-SER-02'),('P1','P1-DIF-01'),
      ('P5','P5-PRO-05'),('P5','P5-PRO-06'),('P5','P5-DRV-01'),('P5','P5-DRV-02'),('P5','P5-DRV-03'),('P5','P5-BIN-01'),('P5','P5-GEO-01')
    ), q as (
      select s.component_code,s.skill_code,
        count(distinct m.id) filter(where (
          (cv.status='published' and m.lifecycle_state in ('published','reserve'))
          or (cv.id in (4815,4816) and cv.status='draft' and m.lifecycle_state='draft')
        ) and m.reserve_role='diagnostic') d,
        count(distinct m.id) filter(where (
          (cv.status='published' and m.lifecycle_state in ('published','reserve'))
          or (cv.id in (4815,4816) and cv.status='draft' and m.lifecycle_state='draft')
        ) and m.reserve_role='learning') l,
        count(distinct m.id) filter(where (
          (cv.status='published' and m.lifecycle_state in ('published','reserve'))
          or (cv.id in (4815,4816) and cv.status='draft' and m.lifecycle_state='draft')
        ) and m.reserve_role='mixed') x,
        count(distinct m.id) filter(where (
          (cv.status='published' and m.lifecycle_state in ('published','reserve'))
          or (cv.id in (4815,4816) and cv.status='draft' and m.lifecycle_state='draft')
        ) and m.reserve_role='retest') r
      from skills s
      left join private.exam_prep_question_content_meta m on m.primary_skill_code=s.skill_code
      left join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      group by s.component_code,s.skill_code
    ), w as (
      select s.component_code,s.skill_code,
        count(distinct wt.id) filter(where wt.lifecycle_state='published') n
      from skills s
      left join private.exam_prep_written_tasks wt on wt.primary_skill_code=s.skill_code
      group by s.component_code,s.skill_code
    )
    select s.skill_code
    from skills s join q using(component_code,skill_code) join w using(component_code,skill_code)
    where q.d<>3 or q.l+q.x<>8 or q.r<>4 or w.n<2
  ) z;
  if v_bad<>0 then raise exception 'aw13_16 annual reserve draft: prospective annual floor failed rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4815,4816)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4815,4816)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4815,4816)
  ) then raise exception 'aw13_16 annual reserve draft: history contamination'; end if;
END
$$;

\echo 'AW13-16 annual reserve top-up draft v1 contract: GREEN'
