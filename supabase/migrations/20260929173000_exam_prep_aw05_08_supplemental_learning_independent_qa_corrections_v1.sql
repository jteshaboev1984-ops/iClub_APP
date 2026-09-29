-- AW5-8 supplemental learning independent QA corrections v1.
-- Draft/history-free content only. No publication or learner exposure.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4805,4806) and status='draft')<>2 then
    raise exception 'aw05_08 independent QA: target draft versions missing';
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4805,4806)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4805,4806)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4805,4806)
  ) then
    raise exception 'aw05_08 independent QA: draft has learner/legacy history';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id=4805
        and content_key in ('P1FUN06-A01','P1FUN07-A02','P1TRI01-A02'))<>3 then
    raise exception 'aw05_08 independent QA: exact correction targets missing';
  end if;
end
$preflight$;

-- FUN06: the stem/explanation correctly describe left 4, down 3; fix the answer key.
update public.questions q
set correct_answer='D'
from private.exam_prep_question_content_meta m
where m.question_id=q.id
  and m.content_version_id=4805
  and m.content_key='P1FUN06-A01'
  and q.is_active=false
  and q.quality_status='draft';

-- FUN07: retain exact mathematics while rotating the correct option to keep
-- the component-wide MCQ answer positions balanced after the FUN06 correction.
update public.questions q
set options_text='["Reflection in the x-axis","Translation down 1 unit","Rotation through 90°","Reflection in the y-axis"]',
    options_text_en='["Reflection in the x-axis","Translation down 1 unit","Rotation through 90°","Reflection in the y-axis"]',
    options_text_ru='["Отражение относительно оси x","Сдвиг на 1 единицу вниз","Поворот на 90°","Отражение относительно оси y"]',
    options_text_uz='["x o‘qiga nisbatan akslantirish","1 birlik pastga siljitish","90° ga burish","y o‘qiga nisbatan akslantirish"]',
    correct_answer='A'
from private.exam_prep_question_content_meta m
where m.question_id=q.id
  and m.content_version_id=4805
  and m.content_key='P1FUN07-A02'
  and q.is_active=false
  and q.quality_status='draft';

-- TRI01: remove an accidental duplicate English distractor.
update public.questions q
set options_text='["−1≤y≤5","1≤y≤5","−5≤y≤1","−3≤y≤3"]',
    options_text_en='["−1≤y≤5","1≤y≤5","−5≤y≤1","−3≤y≤3"]'
from private.exam_prep_question_content_meta m
where m.question_id=q.id
  and m.content_version_id=4805
  and m.content_key='P1TRI01-A02'
  and q.is_active=false
  and q.quality_status='draft';

-- Re-freeze only corrected draft snapshots.
update private.exam_prep_question_content_meta m
set question_snapshot_md5=md5(concat_ws(chr(31),
      q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
      coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
      coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
      coalesce(q.quality_flag,''),coalesce(q.quality_status,''))),
    updated_at=now()
from public.questions q
where q.id=m.question_id
  and m.content_version_id=4805
  and m.content_key in ('P1FUN06-A01','P1FUN07-A02','P1TRI01-A02');

do $postcheck$
declare
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  -- Independently re-solved answer contracts for the three corrected surfaces.
  if (select q.correct_answer
      from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
      where m.content_version_id=4805 and m.content_key='P1FUN06-A01')<>'D'
     or (select q.correct_answer
         from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
         where m.content_version_id=4805 and m.content_key='P1FUN07-A02')<>'A'
     or (select q.correct_answer
         from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
         where m.content_version_id=4805 and m.content_key='P1TRI01-A02')<>'A'
  then
    raise exception 'aw05_08 independent QA: corrected answer contract mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4805,4806)
    and q.qtype='mcq'
    and (
      (select count(distinct v) from jsonb_array_elements_text(q.options_text_en::jsonb) z(v))<>4
      or (select count(distinct v) from jsonb_array_elements_text(q.options_text_ru::jsonb) z(v))<>4
      or (select count(distinct v) from jsonb_array_elements_text(q.options_text_uz::jsonb) z(v))<>4
    );
  if v_bad<>0 then
    raise exception 'aw05_08 independent QA: duplicate option rows=%',v_bad;
  end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id=4805;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,4,4,8) then
    raise exception 'aw05_08 independent QA: P1 answer balance mismatch A=% B=% C=% D=% input=%',
      v_a,v_b,v_c,v_d,v_inputs;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4805,4806)
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
    raise exception 'aw05_08 independent QA: frozen snapshot mismatch rows=%',v_bad;
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4805,4806)
  ) then
    raise exception 'aw05_08 independent QA: session appeared during correction';
  end if;
end
$postcheck$;

commit;
