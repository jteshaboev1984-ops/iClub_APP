-- AW21-24 annual-reserve independent academic/language/technical QA contract v1.
-- Candidate remains draft/withheld/history-free. Publication is a separate governed stage.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
  v_seq text;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4823,4824) and status='draft')<>2 then
    raise exception 'aw21_24 reserve independent QA: target drafts missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4823,4824)
        and lifecycle_state='draft' and exposure_state='withheld')<>90
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4823,4824) and reserve_role='diagnostic')<>36
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4823,4824) and reserve_role='retest')<>36
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4823,4824) and reserve_role='mixed')<>18 then
    raise exception 'aw21_24 reserve independent QA: reserve surface mismatch';
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
    raise exception 'aw21_24 reserve independent QA: reviewed 90-answer map mismatch rows=%',v_bad;
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
    raise exception 'aw21_24 reserve independent QA: trilingual/type/governance rows=%',v_bad;
  end if;

  -- Frozen source integrity.
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4823,4824)
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
    raise exception 'aw21_24 reserve independent QA: frozen snapshot drift rows=%',v_bad;
  end if;

  -- Correct-option balance across the full candidate and each diagnostic component.
  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
    into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4823;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(8,8,7,7,20) then
    raise exception 'aw21_24 reserve independent QA: P1 answer balance A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
    into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4824;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(6,6,6,6,16) then
    raise exception 'aw21_24 reserve independent QA: P5 answer balance A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  -- Reject obvious correct-option ladders in the actual multi-item learner forms.
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
      raise exception 'aw21_24 reserve independent QA: learner-form correct-option pattern detected: %',v_seq;
    end if;
  end loop;

  -- Academic pins from the independent review.
  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4823 and m.content_key='P1COO06-D03'
      and q.correct_answer='D'
      and q.explanation_en like '%discriminant 0%'
      and q.options_text_en::jsonb->>3='c=4 or c=−4'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4823 and m.content_key='P1DIF06-R04'
      and q.correct_answer='A'
      and q.options_text_en::jsonb->>0='20π cm³/s'
      and q.explanation_en like '%4π(25)(0.2)=20π%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4823 and m.content_key='P1INT03-M02'
      and q.correct_answer='4'
      and q.question_text_en like '%improper endpoint integral%'
      and q.explanation_en like '%lim(a→0+)%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4823 and m.content_key='P1INT04-M02'
      and q.correct_answer='4'
      and q.explanation_en like '%2(2/3+4/3)=4%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4823 and m.content_key='P1INT05-D02'
      and q.correct_answer='A'
      and q.options_text_en::jsonb->>0='π/5'
      and q.explanation_en like '%x⁴%'
  ) then
    raise exception 'aw21_24 reserve independent QA: P1 reviewed semantic pin missing';
  end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5DAT08-D02'
      and q.correct_answer='B'
      and q.question_text_en like 'Route A delivery times%'
      and q.options_text_en::jsonb->>1 like 'Route B usually takes longer%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5DAT09-D02'
      and q.correct_answer='D'
      and q.question_text_en like '%standard deviation%'
      and q.options_text_en::jsonb->>3='3'
      and q.explanation_en like '%Variance=290/5−7²=58−49=9%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5DAT09-R04'
      and q.correct_answer='D'
      and q.question_text_en like '%standard deviation%'
      and q.options_text_en::jsonb->>3='3'
      and q.explanation_en like '%Variance=136/4−5²=34−25=9%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5NOR04-M02'
      and q.correct_answer='86.02'
      and q.question_text_en like '%upper quartile%'
      and q.explanation_en like '%84+0.674(3)=86.022≈86.02%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5NOR05-R04'
      and q.correct_answer='D'
      and q.options_text_en::jsonb->>3='36'
      and q.explanation_en like '%72=2μ%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5NOR06-D03'
      and q.correct_answer='D'
      and q.options_text_en::jsonb->>3='Both np and n(1−p) should be sufficiently large'
      and q.explanation_en like '%both expected counts np and n(1−p)%'
  ) then
    raise exception 'aw21_24 reserve independent QA: P5 reviewed semantic pin missing';
  end if;

  -- Bin(n,p) notation: Russian prose may use decimal commas, but not inside Bin(n,p),
  -- where commas already separate the two parameters.
  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.primary_skill_code='P5-NOR-06'
      and q.question_text_ru ~ 'Bin\([0-9]+,0,[0-9]+\)'
  ) then
    raise exception 'aw21_24 reserve independent QA: ambiguous Russian Bin(n,p) decimal notation';
  end if;

  -- No common learner-facing English terminology leaked into RU/UZ prose.
  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id in (4823,4824)
      and (
        q.question_text_ru ~* '\m(mean|variance|standard deviation|normal approximation|continuity correction|percentile|range|median|circle|tangent|volume|area|increasing|decreasing|dataset)\M'
        or q.explanation_ru ~* '\m(mean|variance|standard deviation|normal approximation|continuity correction|percentile|range|median|circle|tangent|volume|area|increasing|decreasing|dataset)\M'
        or q.question_text_uz ~* '\m(mean|variance|standard deviation|normal approximation|continuity correction|percentile|range|median|circle|tangent|volume|area|increasing|decreasing|dataset)\M'
        or q.explanation_uz ~* '\m(mean|variance|standard deviation|normal approximation|continuity correction|percentile|range|median|circle|tangent|volume|area|increasing|decreasing|dataset)\M'
      )
  ) then
    raise exception 'aw21_24 reserve independent QA: learner-language leakage';
  end if;

  -- Diagnostic misconception coverage: exactly all three wrong choices, never the correct one.
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4823,4824) and m.reserve_role='diagnostic'
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
      or exists(select 1 from private.exam_prep_diagnostic_rules r
          where r.content_meta_id=m.id
            and r.rule_version='aw_reserve_v1'
            and r.answer_match=q.correct_answer)
    );
  if v_bad<>0 then
    raise exception 'aw21_24 reserve independent QA: diagnostic misconception coverage rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4823,4824)
        and r.rule_version='aw_reserve_v1' and r.status='draft')<>108 then
    raise exception 'aw21_24 reserve independent QA: diagnostic-rule total mismatch';
  end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id=4824 and m.content_key='P5NOR06-D03'
        and r.rule_version='aw_reserve_v1'
        and r.feedback_en like 'Your choice does not identify the condition%'
        and r.feedback_ru like 'Выбранный вариант неверно определяет условие%'
        and r.feedback_uz like 'Tanlangan javob binomial taqsimotni normal yaqinlashtirish%'
      )<>3 then
    raise exception 'aw21_24 reserve independent QA: tailored approximation-condition feedback missing';
  end if;

  -- Assessment containers and holdout isolation.
  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4823,4824) and status='draft')<>42
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4823,4824))<>90
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4823,4824) and ai.is_holdout)<>90 then
    raise exception 'aw21_24 reserve independent QA: assessment/holdout mismatch';
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
    raise exception 'aw21_24 reserve independent QA: assessment role/isolation mismatch';
  end if;

  if exists(select 1 from private.exam_prep_written_tasks where content_version_id in (4823,4824)) then
    raise exception 'aw21_24 reserve independent QA: reserve-only candidate contains written tasks';
  end if;

  -- Exact stem originality against every already-published version in the same skill.
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
    where m.content_version_id in (4823,4824)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then
    raise exception 'aw21_24 reserve independent QA: exact published stem reuse';
  end if;

  -- Candidate must still be history-free.
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
    raise exception 'aw21_24 reserve independent QA: history contamination';
  end if;

  if not exists(
    select 1 from private.exam_prep_feature_config
    where id=1 and rollout_state='controlled_beta'
      and core_enabled and ai_enabled=false and mentor_enabled=false and kill_switch=false
  ) then
    raise exception 'aw21_24 reserve independent QA: controlled-beta service boundary changed';
  end if;
END
$$;

\echo 'AW21-24 annual reserve independent QA v1 contract: GREEN'
