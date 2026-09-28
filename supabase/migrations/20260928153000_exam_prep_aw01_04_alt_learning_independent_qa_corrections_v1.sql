-- Independent QA corrections for the withheld AW1-4 alternate learning drafts.
-- DRAFT-ONLY / HISTORY-SAFE:
--   * rebalances stored MCQ answer positions so content remains robust even if runtime permutation is rolled back;
--   * rebalances written-understanding answer positions;
--   * fixes one Uzbek one-one-function term to match the established canonical wording;
--   * changes no mathematical meaning, assessment membership, skill mapping, mastery, readiness or learner evidence.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare
  v_bad int;
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4801,4802)
        and content_version in ('p1_aw01_04_alt_learning_draft_v1','p5_aw01_04_alt_learning_draft_v1')
        and status='draft')<>2 then
    raise exception 'aw01_04_independent_qa: exact draft content versions missing';
  end if;

  if exists(
    select 1
    from private.exam_prep_assessments
    where content_version_id in (4801,4802)
      and status<>'draft'
  ) then
    raise exception 'aw01_04_independent_qa: target assessment no longer draft';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4801,4802)
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
    );
  if v_bad<>0 then
    raise exception 'aw01_04_independent_qa: target question state drift=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4801,4802)
  ) then
    raise exception 'aw01_04_independent_qa: learner session exists on target draft';
  end if;

  if exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4801,4802)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4801,4802)
  ) then
    raise exception 'aw01_04_independent_qa: legacy answer history exists on target draft';
  end if;

  if (select count(*) from private.exam_prep_written_understanding_checks
      where id between 8901 and 8909
        and lifecycle_state='draft'
        and qa_math_status='pending'
        and qa_language_status='pending'
        and qa_technical_status='pending')<>9 then
    raise exception 'aw01_04_independent_qa: written-understanding draft state drift';
  end if;
end
$preflight$;

-- Reorder stored MCQ options without changing the option multiset or mathematical content.
-- perm is source-index order (0-based) for the new displayed/stored A-D sequence.
with plan(book_ref,old_answer,new_answer,perm) as (values
  ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA01-A02','A','B',array[1,0,2,3]::int[]),
  ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA02-A03','C','D',array[0,1,3,2]::int[]),
  ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA03-A01','A','B',array[1,0,2,3]::int[]),
  ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA03-A02','A','C',array[1,2,0,3]::int[]),
  ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA03-A03','A','D',array[1,2,3,0]::int[]),
  ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN01-A02','A','D',array[1,2,3,0]::int[]),
  ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN02-A01','A','B',array[1,0,2,3]::int[]),
  ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN02-A02','A','C',array[1,2,0,3]::int[]),
  ('ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN02-A03','A','D',array[1,2,3,0]::int[]),
  ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT01-A02','A','B',array[1,0,2,3]::int[]),
  ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT01-A03','A','C',array[1,2,0,3]::int[]),
  ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT02-A02','A','B',array[1,0,2,3]::int[]),
  ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT02-A03','C','D',array[0,1,3,2]::int[]),
  ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT04-A03','A','C',array[1,2,0,3]::int[]),
  ('ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT06-A03','B','D',array[0,2,3,1]::int[])
),
eligible as (
  select q.id,q.book_ref,p.new_answer,p.perm,
         q.options_text_en::jsonb en,
         q.options_text_ru::jsonb ru,
         q.options_text_uz::jsonb uz
  from plan p
  join public.questions q on q.book_ref=p.book_ref and q.correct_answer=p.old_answer
  join private.exam_prep_question_content_meta m on m.question_id=q.id
  where m.content_version_id in (4801,4802)
    and m.lifecycle_state='draft'
    and m.exposure_state='withheld'
    and q.qtype='mcq'
    and q.is_active=false
    and q.quality_status='draft'
)
update public.questions q
set options_text_en=jsonb_build_array(e.en->e.perm[1],e.en->e.perm[2],e.en->e.perm[3],e.en->e.perm[4])::text,
    options_text_ru=jsonb_build_array(e.ru->e.perm[1],e.ru->e.perm[2],e.ru->e.perm[3],e.ru->e.perm[4])::text,
    options_text_uz=jsonb_build_array(e.uz->e.perm[1],e.uz->e.perm[2],e.uz->e.perm[3],e.uz->e.perm[4])::text,
    options_text=jsonb_build_array(e.en->e.perm[1],e.en->e.perm[2],e.en->e.perm[3],e.en->e.perm[4])::text,
    correct_answer=e.new_answer
from eligible e
where q.id=e.id;

do $machine_count$
begin
  if (select count(*) from public.questions q
      join private.exam_prep_question_content_meta m on m.question_id=q.id
      where m.content_version_id in (4801,4802)
        and q.book_ref in (
          'ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA01-A02',
          'ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA02-A03',
          'ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA03-A01',
          'ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA03-A02',
          'ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1QUA03-A03',
          'ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN01-A02',
          'ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN02-A01',
          'ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN02-A02',
          'ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN02-A03',
          'ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT01-A02',
          'ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT01-A03',
          'ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT02-A02',
          'ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT02-A03',
          'ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT04-A03',
          'ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:P5DAT06-A03'
        ))<>15 then
    raise exception 'aw01_04_independent_qa: expected 15 rebalanced MCQs';
  end if;
end
$machine_count$;

-- Language QA correction: use the established Uzbek one-one-function term.
update public.questions
set explanation_uz='x≥0 da h funksiya bir-biriga bir qiymatli. y=x² da x va y ni almashtirib, manfiy bo‘lmagan tarmoqni olsak h⁻¹(x)=√x.'
where book_ref='ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN01-A01'
  and is_active=false
  and quality_status='draft';

update private.exam_prep_written_tasks
set prompt_uz='f(x)=x−2 barcha haqiqiy x lar uchun, g(x)=x² esa x≥0 da berilgan bo‘lsin. g ning aniqlanish va qiymatlar sohasini ko‘rsating, nima uchun u bu sohada bir-biriga bir qiymatli ekanini tushuntiring, g⁻¹(x) ni toping, so‘ng (g∘f)(x) formulasini va uning aniqlanish sohasini aniqlang.'
where id=15604
  and content_version_id=4801
  and task_key='P1FUN01-AW02'
  and lifecycle_state='draft';

-- Rebalance the nine draft written-understanding checks to 2/2/2/3 positions.
with plan(id,old_index,new_index,perm) as (values
  (8903,0,2,array[1,2,0,3]::int[]),
  (8904,1,3,array[0,2,3,1]::int[]),
  (8905,2,0,array[2,0,1,3]::int[]),
  (8907,1,2,array[0,2,1,3]::int[]),
  (8908,1,3,array[0,2,3,1]::int[]),
  (8909,0,3,array[1,2,3,0]::int[])
),
eligible as (
  select c.id,p.new_index,p.perm,c.options_en,c.options_ru,c.options_uz
  from plan p
  join private.exam_prep_written_understanding_checks c
    on c.id=p.id and c.correct_index=p.old_index
  where c.lifecycle_state='draft'
    and c.qa_math_status='pending'
    and c.qa_language_status='pending'
    and c.qa_technical_status='pending'
)
update private.exam_prep_written_understanding_checks c
set options_en=jsonb_build_array(e.options_en->e.perm[1],e.options_en->e.perm[2],e.options_en->e.perm[3],e.options_en->e.perm[4]),
    options_ru=jsonb_build_array(e.options_ru->e.perm[1],e.options_ru->e.perm[2],e.options_ru->e.perm[3],e.options_ru->e.perm[4]),
    options_uz=jsonb_build_array(e.options_uz->e.perm[1],e.options_uz->e.perm[2],e.options_uz->e.perm[3],e.options_uz->e.perm[4]),
    correct_index=e.new_index
from eligible e
where c.id=e.id;

-- Any draft question text/options/answer/language change must refresh the immutable draft snapshot.
update private.exam_prep_question_content_meta m
set question_snapshot_md5=md5(concat_ws(chr(31),
      q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),
      coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
      coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),
      coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),
      coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,''))),
    updated_at=now()
from public.questions q
where q.id=m.question_id
  and m.content_version_id in (4801,4802)
  and m.lifecycle_state='draft'
  and m.exposure_state='withheld';

do $postcheck$
declare
  v_bad int;
  v_dist jsonb;
  v_check_dist jsonb;
begin
  select jsonb_object_agg(correct_answer,n order by correct_answer) into v_dist
  from (
    select q.correct_answer,count(*)::int n
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    where m.content_version_id in (4801,4802) and q.qtype='mcq'
    group by q.correct_answer
  ) x;
  if v_dist<>jsonb_build_object('A',5,'B',6,'C',5,'D',6) then
    raise exception 'aw01_04_independent_qa: machine answer-position distribution unexpected=%',v_dist;
  end if;

  select jsonb_object_agg(correct_index,n order by correct_index) into v_check_dist
  from (
    select correct_index,count(*)::int n
    from private.exam_prep_written_understanding_checks
    where id between 8901 and 8909
    group by correct_index
  ) x;
  if v_check_dist<>jsonb_build_object('0',2,'1',2,'2',2,'3',3) then
    raise exception 'aw01_04_independent_qa: written-check distribution unexpected=%',v_check_dist;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4801,4802)
    and (
      q.is_active
      or q.quality_status<>'draft'
      or m.lifecycle_state<>'draft'
      or m.exposure_state<>'withheld'
      or m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or md5(concat_ws(chr(31),
        q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),
        coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
        coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),
        coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
        coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),
        coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5
    );
  if v_bad<>0 then
    raise exception 'aw01_04_independent_qa: draft safety/snapshot postcheck failed=%',v_bad;
  end if;

  if (select explanation_uz from public.questions
      where book_ref='ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:P1FUN01-A01')
     <>'x≥0 da h funksiya bir-biriga bir qiymatli. y=x² da x va y ni almashtirib, manfiy bo‘lmagan tarmoqni olsak h⁻¹(x)=√x.' then
    raise exception 'aw01_04_independent_qa: Uzbek one-one wording correction missing';
  end if;

  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4801,4802)
  ) then
    raise exception 'aw01_04_independent_qa: learner session appeared during draft QA';
  end if;
end
$postcheck$;

commit;
