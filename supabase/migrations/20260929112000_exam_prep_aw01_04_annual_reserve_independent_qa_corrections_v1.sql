-- Independent trilingual QA corrections for AW1-4 annual reserve top-up.
-- DRAFT-ONLY / HISTORY-SAFE: localizes four P1 option sets that still carried
-- English joining words/units in RU/UZ. Mathematical meaning and answers do not change.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4803,4804) and status='draft')<>2 then
    raise exception 'annual_reserve_independent_qa: exact draft versions missing';
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
    raise exception 'annual_reserve_independent_qa: draft state drift=%',v_bad;
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
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
    raise exception 'annual_reserve_independent_qa: target draft has history';
  end if;
end
$preflight$;

update public.questions
set options_text_ru='["q < −2√10 или q > 2√10","−2√10 < q < 2√10","q ≤ −2√10 или q ≥ 2√10","q = ±2√10"]',
    options_text_uz='["q < −2√10 yoki q > 2√10","−2√10 < q < 2√10","q ≤ −2√10 yoki q ≥ 2√10","q = ±2√10"]'
where book_ref='ExamPrep:P1:p1_aw01_04_annual_reserve_topup_draft_v1:P1QUA02-R03'
  and is_active=false and quality_status='draft' and correct_answer='A';

update public.questions
set options_text_ru='["m = 1 только","m = −1 только","m = −1 или 1","m = −2 или 2"]',
    options_text_uz='["faqat m = 1","faqat m = −1","m = −1 yoki 1","m = −2 yoki 2"]'
where book_ref='ExamPrep:P1:p1_aw01_04_annual_reserve_topup_draft_v1:P1QUA02-R04'
  and is_active=false and quality_status='draft' and correct_answer='C';

update public.questions
set options_text_ru='["x = −2 или 1/3","x = 2 или −1/3","x = 2 или 1/3","x = −2 или −1/3"]',
    options_text_uz='["x = −2 yoki 1/3","x = 2 yoki −1/3","x = 2 yoki 1/3","x = −2 yoki −1/3"]'
where book_ref='ExamPrep:P1:p1_aw01_04_annual_reserve_topup_draft_v1:P1QUA03-R03'
  and is_active=false and quality_status='draft' and correct_answer='B';

update public.questions
set options_text_ru='["3 см","9 см","−9 см","6 см"]',
    options_text_uz='["3 sm","9 sm","−9 sm","6 sm"]'
where book_ref='ExamPrep:P1:p1_aw01_04_annual_reserve_topup_draft_v1:P1QUA03-M02'
  and is_active=false and quality_status='draft' and correct_answer='D';

-- Refresh immutable draft snapshots after language-only corrections.
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
  and m.lifecycle_state='draft'
  and m.exposure_state='withheld';

do $postcheck$
declare v_bad int;
begin
  if (select count(*) from public.questions
      where book_ref in (
        'ExamPrep:P1:p1_aw01_04_annual_reserve_topup_draft_v1:P1QUA02-R03',
        'ExamPrep:P1:p1_aw01_04_annual_reserve_topup_draft_v1:P1QUA02-R04',
        'ExamPrep:P1:p1_aw01_04_annual_reserve_topup_draft_v1:P1QUA03-R03',
        'ExamPrep:P1:p1_aw01_04_annual_reserve_topup_draft_v1:P1QUA03-M02'
      ))<>4 then
    raise exception 'annual_reserve_independent_qa: correction target cardinality mismatch';
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
    raise exception 'annual_reserve_independent_qa: snapshot mismatch rows=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    where m.content_version_id=4803
      and lower(q.qtype)='mcq'
      and (
        (q.options_text_ru=q.options_text_en and q.options_text_en ~ '[A-Za-z]{2,}')
        or
        (q.options_text_uz=q.options_text_en and q.options_text_en ~ '[A-Za-z]{2,}')
      )
  ) then
    raise exception 'annual_reserve_independent_qa: untranslated P1 option text remains';
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4803,4804)
  ) then
    raise exception 'annual_reserve_independent_qa: learner session appeared';
  end if;
end
$postcheck$;

commit;
