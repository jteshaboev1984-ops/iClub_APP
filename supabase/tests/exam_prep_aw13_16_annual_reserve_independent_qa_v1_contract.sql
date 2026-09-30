-- AW13-16 annual-reserve independent QA v1 contract.
-- Corrections are pinned after governed publication; reserve exposure remains withheld.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4815,4816) and status='published')<>2 then
    raise exception 'aw13_16 annual reserve QA contract: published target versions missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4815,4816)
        and lifecycle_state='reserve'
        and exposure_state='withheld')<>75 then
    raise exception 'aw13_16 annual reserve QA contract: reserve/withheld surface mismatch';
  end if;

  with expected(content_key,answer) as (values
    ('P1SER02-D03','D'),
    ('P1TRI03-D02','A'),('P1TRI03-R03','113.6'),
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
  if v_bad<>0 then
    raise exception 'aw13_16 annual reserve QA contract: reviewed answer map mismatch rows=%',v_bad;
  end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4815 and m.content_key='P1SER02-D03'
      and q.question_text_en like '%uₙ=7(−2)^(n−1)%' and q.correct_answer='D'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4815 and m.content_key='P1TRI03-D02'
      and q.question_text_en like '%cannot be returned%' and q.correct_answer='A'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4815 and m.content_key='P1DIF01-D02'
      and q.question_text_en like '%Which limit is the derivative%' and q.correct_answer='A'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4816 and m.content_key='P5PRO06-D03'
      and q.question_text_en like '%factory uses machine A%' and q.correct_answer='A'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4816 and m.content_key='P5GEO01-R03'
      and q.question_text_en like '%0.40 after a failure%' and q.correct_answer='0'
  ) then
    raise exception 'aw13_16 annual reserve QA contract: reviewed correction missing';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
    and (
      m.copyright_status<>'pass'
      or m.qa_scope_status<>'pass'
      or m.qa_math_status<>'pass'
      or m.qa_language_status<>'pass'
      or m.qa_technical_status<>'pass'
      or q.is_active
      or q.quality_status<>'draft'
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
    raise exception 'aw13_16 annual reserve QA contract: QA/source/snapshot rows=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code
     and oldm.content_version_id not in (4815,4816)
    join private.exam_prep_content_versions oldcv
      on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4815,4816)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw13_16 annual reserve QA contract: exact published stem reuse'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
    and m.reserve_role='diagnostic'
    and (
      q.qtype<>'mcq'
      or m.diagnostic_rule_status<>'approved'
      or (select count(*) from private.exam_prep_diagnostic_rules r
          where r.content_meta_id=m.id
            and r.rule_version='aw_reserve_v1'
            and r.status='approved'
            and r.answer_kind='mcq_option'
            and r.answer_match<>q.correct_answer
            and r.weak_skill_code=m.primary_skill_code)<>3
    );
  if v_bad<>0 then
    raise exception 'aw13_16 annual reserve QA contract: diagnostic misconception mapping rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4815,4816)
        and r.rule_version='aw_reserve_v1'
        and r.status='approved')<>90
  then raise exception 'aw13_16 annual reserve QA contract: expected 90 approved diagnostic rules'; end if;

  if exists(
    select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4815,4816)
  ) or exists(
    select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4815,4816)
  ) or exists(
    select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4815,4816)
  ) then raise exception 'aw13_16 annual reserve QA contract: history contamination'; end if;
END
$$;

\echo 'AW13-16 annual reserve independent QA v1 contract: GREEN'
