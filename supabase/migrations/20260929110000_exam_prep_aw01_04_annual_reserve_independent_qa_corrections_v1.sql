-- AW1-4 annual reserve top-up independent QA corrections v1.
-- Draft/history-safe only. No learner-selectable content is published here.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4803,4804) and status='draft')<>2 then
    raise exception 'annual reserve independent QA: target draft versions missing';
  end if;

  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4803,4804)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4803,4804)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4803,4804)
  ) then
    raise exception 'annual reserve independent QA: draft has learner/legacy history';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4803,4804)
    and (
      m.lifecycle_state<>'draft'
      or m.exposure_state<>'withheld'
      or q.is_active
      or q.quality_status<>'draft'
    );
  if v_bad<>0 then
    raise exception 'annual reserve independent QA: draft exposure drift rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id=4803
        and content_key in ('P1QUA02-R03','P1QUA02-R04','P1QUA03-M02','P1QUA03-R03'))<>4 then
    raise exception 'annual reserve independent QA: exact localization targets missing';
  end if;
end
$preflight$;

with fixes(content_key,options_ru,options_uz) as (values
  ('P1QUA02-R03',
   '["q < −2√10 или q > 2√10","−2√10 < q < 2√10","q ≤ −2√10 или q ≥ 2√10","q = ±2√10"]',
   '["q < −2√10 yoki q > 2√10","−2√10 < q < 2√10","q ≤ −2√10 yoki q ≥ 2√10","q = ±2√10"]'),
  ('P1QUA02-R04',
   '["только m = 1","только m = −1","m = −1 или m = 1","m = −2 или m = 2"]',
   '["faqat m = 1","faqat m = −1","m = −1 yoki m = 1","m = −2 yoki m = 2"]'),
  ('P1QUA03-M02',
   '["3 см","9 см","−9 см","6 см"]',
   '["3 sm","9 sm","−9 sm","6 sm"]'),
  ('P1QUA03-R03',
   '["x = −2 или x = 1/3","x = 2 или x = −1/3","x = 2 или x = 1/3","x = −2 или x = −1/3"]',
   '["x = −2 yoki x = 1/3","x = 2 yoki x = −1/3","x = 2 yoki x = 1/3","x = −2 yoki x = −1/3"]')
)
update public.questions q
set options_text_ru=f.options_ru,
    options_text_uz=f.options_uz
from fixes f
join private.exam_prep_question_content_meta m
  on m.content_version_id=4803 and m.content_key=f.content_key
where q.id=m.question_id
  and q.is_active=false
  and q.quality_status='draft';

-- Re-freeze only the four corrected draft snapshots.
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
  and m.content_version_id=4803
  and m.content_key in ('P1QUA02-R03','P1QUA02-R04','P1QUA03-M02','P1QUA03-R03');

do $postcheck$
declare v_bad int;
begin
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4803,4804)
    and (
      q.options_text_ru ~* '\m(or|only|cm)\M'
      or q.options_text_uz ~* '\m(or|only|cm)\M'
    );
  if v_bad<>0 then
    raise exception 'annual reserve independent QA: untranslated option tokens remain rows=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4803,4804)
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
    raise exception 'annual reserve independent QA: frozen snapshot mismatch rows=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4803,4804)
  ) then
    raise exception 'annual reserve independent QA: session appeared during correction';
  end if;
end
$postcheck$;

commit;
