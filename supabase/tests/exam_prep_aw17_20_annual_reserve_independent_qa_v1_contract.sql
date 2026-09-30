-- AW17-20 annual reserve independent-QA contract v1.
-- Draft/history-free candidate. Pins the independently reviewed correction surface.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4819,4820) and status='draft')<>2 then
    raise exception 'aw17_20 reserve independent QA contract: target drafts missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4819,4820)
        and lifecycle_state='draft' and exposure_state='withheld')<>55 then
    raise exception 'aw17_20 reserve independent QA contract: machine draft boundary mismatch';
  end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4819,4820)
        and r.rule_version='aw_reserve_v1' and r.status='draft')<>66 then
    raise exception 'aw17_20 reserve independent QA contract: diagnostic-rule surface mismatch';
  end if;

  with expected(content_key,answer,qtype) as (values
    ('P1DIF03-D02','A','mcq'),
    ('P1DIF03-R04','2','input'),
    ('P1DIF04-R04','3/2','input'),
    ('P5BIN02-R04','0.8131','input'),
    ('P5GEO02-D02','A','mcq'),
    ('P5GEO02-R04','7/16','input'),
    ('P5GEO03-D02','C','mcq'),
    ('P5BIN03-R04','6','input'),
    ('P5BIN02-D03','C','mcq'),
    ('P1SER03-R04','41','input'),
    ('P1DIF04-D02','B','mcq'),
    ('P5BIN03-D02','B','mcq'),
    ('P1SER03-D03','C','mcq'),
    ('P1SER05-R04','10.8','input'),
    ('P1SER05-D02','A','mcq'),
    ('P5BIN02-D02','A','mcq'),
    ('P1SER05-R03','-4','input'),
    ('P5NOR01-D02','A','mcq'),
    ('P1DIF04-D03','D','mcq'),
    ('P5GEO03-D03','D','mcq'),
    ('P5GEO03-R04','0.2','input')
  )
  select count(*) into v_bad
  from expected e
  left join private.exam_prep_question_content_meta m
    on m.content_version_id in (4819,4820) and m.content_key=e.content_key
  left join public.questions q on q.id=m.question_id
  where q.id is null or q.correct_answer<>e.answer or q.qtype<>e.qtype;
  if v_bad<>0 then
    raise exception 'aw17_20 reserve independent QA contract: corrected answer/type map mismatch rows=%',v_bad;
  end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4819 and m.content_key='P1DIF03-D02'
      and q.question_text_en like '%missing factor%' and q.correct_answer='A'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4819 and m.content_key='P1DIF04-R04'
      and q.question_text_en like '%crosses the y-axis%' and q.correct_answer='3/2'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4819 and m.content_key='P1SER03-R04'
      and q.question_text_en like '%S10=230%' and q.correct_answer='41'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4819 and m.content_key='P1SER05-R04'
      and q.question_text_en like '%after the first two terms%' and q.correct_answer='10.8'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4820 and m.content_key='P5BIN03-D02'
      and q.question_text_en like '%Var(X)/E(X)=0.8%' and q.correct_answer='B'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4820 and m.content_key='P5GEO02-R04'
      and q.question_text_en like '%P(X≤3 | X>1)%' and q.correct_answer='7/16'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4820 and m.content_key='P5NOR01-D02'
      and q.question_text_en like '%one standard deviation below and above%' and q.correct_answer='A'
  ) then
    raise exception 'aw17_20 reserve independent QA contract: reviewed stem surface mismatch';
  end if;

  -- Diagnostic answer positions were deliberately preserved so the already
  -- authored three-wrong-option misconception rules remain semantically aligned.
  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    where m.content_version_id in (4819,4820)
      and m.reserve_role='diagnostic'
      and (
        q.qtype<>'mcq'
        or m.diagnostic_rule_status<>'pending'
        or (select count(*) from private.exam_prep_diagnostic_rules r
            where r.content_meta_id=m.id
              and r.rule_version='aw_reserve_v1'
              and r.status='draft'
              and r.answer_kind='mcq_option'
              and r.answer_match<>q.correct_answer
              and r.weak_skill_code=m.primary_skill_code)<>3
      )
  ) then
    raise exception 'aw17_20 reserve independent QA contract: diagnostic/rule alignment changed';
  end if;

  -- Exact reuse against any already-published same-skill content remains forbidden.
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
    where m.content_version_id in (4819,4820)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then
    raise exception 'aw17_20 reserve independent QA contract: exact published stem reuse';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4819,4820)
    and (
      m.lifecycle_state<>'draft'
      or m.exposure_state<>'withheld'
      or m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
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
  if v_bad<>0 then
    raise exception 'aw17_20 reserve independent QA contract: payload/snapshot rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4819,4820) and status='draft')<>28
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4819,4820) and ai.is_holdout)<>55
  then
    raise exception 'aw17_20 reserve independent QA contract: assessment/holdout surface changed';
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4819,4820)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4819,4820)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4819,4820)
  ) then
    raise exception 'aw17_20 reserve independent QA contract: history contamination';
  end if;
END
$$;

\echo 'AW17-20 annual reserve independent-QA v1 contract: GREEN'
