-- AW21-24 supplemental learning independent-QA contract v1.
-- Published governed candidate. Pins the independently reviewed correction surface after release.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4821,4822) and status='published')<>2 then
    raise exception 'aw21_24 independent QA contract: target published versions missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4821,4822)
        and lifecycle_state='published' and exposure_state='released')<>54 then
    raise exception 'aw21_24 independent QA contract: machine published/released boundary mismatch';
  end if;

  if (select count(*) from private.exam_prep_written_tasks
      where content_version_id in (4821,4822) and lifecycle_state='published')<>18
     or (select count(*) from private.exam_prep_written_understanding_checks c
         join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
         where wt.content_version_id in (4821,4822) and c.lifecycle_state='published')<>18
  then
    raise exception 'aw21_24 independent QA contract: written/check published boundary mismatch';
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4821,4822) and status='published' and assessment_type='learning')<>18
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4821,4822))<>72 then
    raise exception 'aw21_24 independent QA contract: assessment published surface mismatch';
  end if;

  with expected(content_key,answer) as (values
    ('P1COO05-A01','A'),
    ('P1COO05-A02','B'),
    ('P1COO05-A03','10'),
    ('P1COO06-A01','C'),
    ('P1COO06-A02','D'),
    ('P1COO06-A03','5'),
    ('P1DIF05-A01','A'),
    ('P1DIF05-A02','B'),
    ('P1DIF05-A03','5'),
    ('P1DIF06-A01','C'),
    ('P1DIF06-A02','D'),
    ('P1DIF06-A03','-3'),
    ('P1DIF07-A01','A'),
    ('P1DIF07-A02','B'),
    ('P1DIF07-A03','2'),
    ('P1INT01-A01','C'),
    ('P1INT01-A02','D'),
    ('P1INT01-A03','2'),
    ('P1INT02-A01','A'),
    ('P1INT02-A02','B'),
    ('P1INT02-A03','2'),
    ('P1INT03-A01','C'),
    ('P1INT03-A02','D'),
    ('P1INT03-A03','7'),
    ('P1INT04-A01','A'),
    ('P1INT04-A02','B'),
    ('P1INT04-A03','4/3'),
    ('P1INT05-A01','C'),
    ('P1INT05-A02','D'),
    ('P1INT05-A03','12'),
    ('P5DAT08-A01','A'),
    ('P5DAT08-A02','B'),
    ('P5DAT08-A03','5'),
    ('P5DAT09-A01','C'),
    ('P5DAT09-A02','D'),
    ('P5DAT09-A03','12'),
    ('P5DAT10-A01','A'),
    ('P5DAT10-A02','B'),
    ('P5DAT10-A03','21.25'),
    ('P5NOR02-A01','C'),
    ('P5NOR02-A02','D'),
    ('P5NOR02-A03','2'),
    ('P5NOR03-A01','A'),
    ('P5NOR03-A02','B'),
    ('P5NOR03-A03','0.6827'),
    ('P5NOR04-A01','C'),
    ('P5NOR04-A02','D'),
    ('P5NOR04-A03','1.645'),
    ('P5NOR05-A01','A'),
    ('P5NOR05-A02','B'),
    ('P5NOR05-A03','52'),
    ('P5NOR06-A01','C'),
    ('P5NOR06-A02','D'),
    ('P5NOR06-A03','12.5')
  )
  select count(*) into v_bad
  from expected e
  left join private.exam_prep_question_content_meta m
    on m.content_version_id in (4821,4822) and m.content_key=e.content_key
  left join public.questions q on q.id=m.question_id
  where q.id is null or q.correct_answer<>e.answer;
  if v_bad<>0 then
    raise exception 'aw21_24 independent QA contract: reviewed answer map mismatch rows=%',v_bad;
  end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4821 and m.content_key='P1INT01-A01'
      and q.correct_answer='C'
      and q.options_text_en::jsonb->>2='2x³−2x²+5x+C'
      and q.options_text_ru::jsonb->>2='2x³−2x²+5x+C'
      and q.options_text_uz::jsonb->>2='2x³−2x²+5x+C'
  ) then
    raise exception 'aw21_24 independent QA contract: P1INT01-A01 semantic key pin missing';
  end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4822 and m.content_key='P5NOR06-A01'
      and q.question_text_ru like '%Bin(200,0.4)%'
      and q.question_text_ru like '%нормального приближения%'
      and q.explanation_ru like '%Поправка на непрерывность%'
      and q.question_text_uz like '%normal yaqinlashuv%'
      and q.explanation_uz like '%Uzluksizlik tuzatishi%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4822 and m.content_key='P5NOR06-A02'
      and q.question_text_ru like '%Bin(100,0.3)%'
      and q.question_text_ru like '%нормального приближения%'
      and q.explanation_ru like '%Поправка на непрерывность%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4822 and m.content_key='P5NOR06-A03'
      and q.question_text_ru like '%Bin(50,0.5)%'
      and q.question_text_ru like '%нормальном приближении%'
      and q.question_text_uz like '%normal yaqinlashuvda%'
  ) then
    raise exception 'aw21_24 independent QA contract: P5 normal-approximation language/notation pin missing';
  end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id in (4821,4822)
      and (
        q.is_active or q.quality_status<>'draft'
        or m.lifecycle_state<>'published' or m.exposure_state<>'released'
        or m.copyright_status<>'pass'
        or m.qa_scope_status<>'pass'
        or m.qa_math_status<>'pass'
        or m.qa_language_status<>'pass'
        or m.qa_technical_status<>'pass'
        or m.diagnostic_rule_status<>'not_applicable'
      )
  ) then
    raise exception 'aw21_24 independent QA contract: published governance state drift';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4821,4822)
    and (
      nullif(btrim(q.question_text_en),'') is null
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
    raise exception 'aw21_24 independent QA contract: trilingual/type rows=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4821,4822)
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
    raise exception 'aw21_24 independent QA contract: snapshot drift rows=%',v_bad;
  end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4821;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(5,5,5,5,10) then
    raise exception 'aw21_24 independent QA contract: P1 answer balance mismatch A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4822;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,4,4,8) then
    raise exception 'aw21_24 independent QA contract: P5 answer balance mismatch A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  -- Written arithmetic/scope pins from the independent pass.
  if not exists(
    select 1 from private.exam_prep_written_tasks where id=15665 and content_version_id=4821
      and (rubric_json->'criteria'->1->>'rule') like '%k=±10%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15667 and content_version_id=4821
      and (rubric_json->'criteria'->2->>'rule') like '%20π%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15668 and content_version_id=4821
      and (rubric_json->'criteria'->4->>'rule') like '%144%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15669 and content_version_id=4821
      and (rubric_json->'criteria'->2->>'rule') like '%2(3x+1)³/9%'
      and prompt_ru like '%Продифференцируйте%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15670 and content_version_id=4821
      and (rubric_json->'criteria'->2->>'rule') like '%C=7%'
      and (rubric_json->'criteria'->4->>'rule') like '%15%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15672 and content_version_id=4821
      and (rubric_json->'criteria'->5->>'rule') like '%46/3%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15673 and content_version_id=4821
      and (rubric_json->'criteria'->4->>'rule') like '%36π%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15675 and content_version_id=4822
      and (rubric_json->'criteria'->3->>'rule') like '%variance=264/6−36=8%'
      and prompt_ru like '%формуле дисперсии%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15676 and content_version_id=4822
      and (rubric_json->'criteria'->4->>'rule') like '%1530/30=51%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15677 and content_version_id=4822
      and (rubric_json->'criteria'->3->>'rule') like '%0.8185%'
      and prompt_uz like '%yig‘ma ehtimol%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15678 and content_version_id=4822
      and (rubric_json->'criteria'->4->>'rule') like '%0.8185%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15679 and content_version_id=4822
      and (rubric_json->'criteria'->4->>'rule') like '%[51.8,68.2]%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15680 and content_version_id=4822
      and (rubric_json->'criteria'->3->>'rule') like '%σ=12%'
      and (rubric_json->'criteria'->4->>'rule') like '%μ=56%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks where id=15681 and content_version_id=4822
      and (rubric_json->'criteria'->4->>'rule') like '%0.9189%'
      and prompt_ru like '%нормальное приближение%'
      and prompt_uz like '%normal yaqinlashuv%'
  ) then
    raise exception 'aw21_24 independent QA contract: written arithmetic/language pin missing';
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_tasks wt
  left join private.exam_prep_written_understanding_checks c on c.written_task_id=wt.id
  where wt.content_version_id in (4821,4822)
    and (
      wt.lifecycle_state<>'published'
      or wt.copyright_status<>'pass'
      or wt.qa_math_status<>'pass'
      or wt.qa_language_status<>'pass'
      or wt.qa_technical_status<>'pass'
      or coalesce((wt.rubric_json->>'max_marks')::int,0)<>6
      or nullif(btrim(wt.prompt_en),'') is null
      or nullif(btrim(wt.prompt_ru),'') is null
      or nullif(btrim(wt.prompt_uz),'') is null
      or c.id is null
      or c.lifecycle_state<>'published'
      or c.qa_math_status<>'pass'
      or c.qa_language_status<>'pass'
      or c.qa_technical_status<>'pass'
      or jsonb_array_length(c.options_en)<>4
      or jsonb_array_length(c.options_ru)<>4
      or jsonb_array_length(c.options_uz)<>4
      or c.correct_index not between 0 and 3
    );
  if v_bad<>0 then
    raise exception 'aw21_24 independent QA contract: written/check review rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_written_understanding_checks where id between 8964 and 8981 and correct_index=0)<>5
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8964 and 8981 and correct_index=1)<>5
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8964 and 8981 and correct_index=2)<>4
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8964 and 8981 and correct_index=3)<>4 then
    raise exception 'aw21_24 independent QA contract: written-check balance mismatch';
  end if;

  if not exists(
    select 1 from private.exam_prep_written_understanding_checks
    where id=8981
      and prompt_ru like '%поправке на непрерывность%'
      and prompt_uz like '%Uzluksizlik tuzatishida%'
      and correct_index=1
  ) then
    raise exception 'aw21_24 independent QA contract: continuity-check language pin missing';
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
    where m.content_version_id in (4821,4822)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then
    raise exception 'aw21_24 independent QA contract: exact published stem reuse';
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4821,4822)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4821,4822)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4821,4822)
  ) then
    raise exception 'aw21_24 independent QA contract: history contamination';
  end if;
END
$$;

\echo 'AW21-24 supplemental learning independent-QA v1 contract: GREEN'
