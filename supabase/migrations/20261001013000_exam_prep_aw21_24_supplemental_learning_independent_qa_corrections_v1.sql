-- AW21-24 supplemental learning independent QA corrections v1.
-- Draft/history-free content only. No publication or learner exposure.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4821,4822) and status='draft')<>2 then
    raise exception 'aw21_24 independent QA: target draft versions missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=4821)<>30
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4822)<>24
     or (select count(*) from private.exam_prep_written_tasks where content_version_id in (4821,4822))<>18
     or (select count(*) from private.exam_prep_written_understanding_checks c
         join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
         where wt.content_version_id in (4821,4822))<>18 then
    raise exception 'aw21_24 independent QA: candidate surface mismatch';
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
    raise exception 'aw21_24 independent QA: draft has learner/legacy history';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4821,4822)
    and (m.lifecycle_state<>'draft' or m.exposure_state<>'withheld' or q.is_active or q.quality_status<>'draft');
  if v_bad<>0 then
    raise exception 'aw21_24 independent QA: draft exposure drift rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4821,4822)
        and content_key in ('P1INT01-A01','P5DAT09-A01','P5NOR06-A01','P5NOR06-A02','P5NOR06-A03'))<>5 then
    raise exception 'aw21_24 independent QA: correction targets missing';
  end if;
end
$preflight$;

-- Academic correction: keep answer-key balance C while moving the correct
-- antiderivative into option C in all three learner languages.
update public.questions q
set options_text='["6x³−4x²+5x+C","3x²−4+C","2x³−2x²+5x+C","2x³−2x²+5+C"]',
    options_text_en='["6x³−4x²+5x+C","3x²−4+C","2x³−2x²+5x+C","2x³−2x²+5+C"]',
    options_text_ru='["6x³−4x²+5x+C","3x²−4+C","2x³−2x²+5x+C","2x³−2x²+5+C"]',
    options_text_uz='["6x³−4x²+5x+C","3x²−4+C","2x³−2x²+5x+C","2x³−2x²+5+C"]'
from private.exam_prep_question_content_meta m
where q.id=m.question_id
  and m.content_version_id=4821
  and m.content_key='P1INT01-A01'
  and q.is_active=false and q.quality_status='draft';

-- Language QA: remove English leakage from learner-facing RU/UZ while
-- preserving mathematical notation and the N(mu, variance) convention.
update public.questions q
set question_text_ru='Для n=6 наблюдений Σx=54 и Σx²=510. Используя формулу дисперсии Σx²/n − x̄², найдите среднее и стандартное отклонение.',
    question_text_uz='n=6 ta kuzatuv uchun Σx=54 va Σx²=510. Dispersiya formulasi Σx²/n − x̄² dan foydalanib o‘rtacha va standart og‘ishni toping.'
from private.exam_prep_question_content_meta m
where q.id=m.question_id
  and m.content_version_id=4822
  and m.content_key='P5DAT09-A01'
  and q.is_active=false and q.quality_status='draft';

update public.questions q
set question_text_ru='X~Bin(200,0.4). Какая запись нормального приближения верна для P(X≤90)?',
    question_text_uz='X~Bin(200,0.4). P(X≤90) uchun qaysi normal yaqinlashuv to‘g‘ri?',
    explanation_ru='Для Bin(n,p): среднее np=80, дисперсия np(1−p)=48. Поправка на непрерывность заменяет X≤90 на Y<90,5.',
    explanation_uz='Bin(n,p) uchun o‘rtacha=np=80 va dispersiya=np(1−p)=48. Uzluksizlik tuzatishi X≤90 ni Y<90.5 ga o‘zgartiradi.'
from private.exam_prep_question_content_meta m
where q.id=m.question_id
  and m.content_version_id=4822
  and m.content_key='P5NOR06-A01'
  and q.is_active=false and q.quality_status='draft';

update public.questions q
set question_text_ru='X~Bin(100,0.3). Какое событие нормального приближения соответствует P(X≥35)?',
    question_text_uz='X~Bin(100,0.3). P(X≥35) ga qaysi normal yaqinlashuv hodisasi mos?',
    explanation_ru='Аппроксимирующее нормальное распределение имеет среднее 30 и дисперсию 21. Поправка на непрерывность заменяет X≥35 на Y>34,5.',
    explanation_uz='Yaqinlashtiruvchi normal taqsimotning o‘rtachasi 30, dispersiyasi 21. Uzluksizlik tuzatishi X≥35 ni Y>34.5 ga o‘zgartiradi.'
from private.exam_prep_question_content_meta m
where q.id=m.question_id
  and m.content_version_id=4822
  and m.content_key='P5NOR06-A02'
  and q.is_active=false and q.quality_status='draft';

update public.questions q
set question_text_ru='Для X~Bin(50,0.5) введите дисперсию, используемую в нормальном приближении.',
    question_text_uz='X~Bin(50,0.5) uchun normal yaqinlashuvda ishlatiladigan dispersiyani kiriting.',
    explanation_uz='Binomial taqsimot dispersiyasi np(1−p)=50(0.5)(0.5)=12.5.'
from private.exam_prep_question_content_meta m
where q.id=m.question_id
  and m.content_version_id=4822
  and m.content_key='P5NOR06-A03'
  and q.is_active=false and q.quality_status='draft';

update private.exam_prep_written_tasks
set prompt_ru='Найдите ∫[4x³−6x+2(3x+1)²] dx. Покажите степенное правило и учёт внутреннего коэффициента в (3x+1)². Продифференцируйте итоговый ответ для проверки.'
where id=15669 and content_version_id=4821 and lifecycle_state='draft';

update private.exam_prep_written_tasks
set prompt_ru='Для данных 2, 4, 5, 7, 7, 11 вычислите среднее и стандартное отклонение по формуле дисперсии Σx²/n − x̄². Покажите Σx, Σx², дисперсию и итоговое стандартное отклонение.',
    prompt_uz='2, 4, 5, 7, 7, 11 ma’lumotlari uchun dispersiya formulasi Σx²/n − x̄² bilan o‘rtacha va standart og‘ishni hisoblang. Σx, Σx², dispersiya va yakuniy standart og‘ishni ko‘rsating.'
where id=15675 and content_version_id=4822 and lifecycle_state='draft';

update private.exam_prep_written_tasks
set prompt_uz='X~N(80,36) bo‘lsin. X=68 va X=86 ni standartlang, so‘ng standart normal qiymatlar orqali P(68<X<86) ni toping. z-o‘zgarishni va ishlatilgan ikki yig‘ma ehtimolni ko‘rsating.'
where id=15677 and content_version_id=4822 and lifecycle_state='draft';

update private.exam_prep_written_tasks
set prompt_ru='Пусть X~Bin(120,0.4). Используйте нормальное приближение для оценки P(X≤55). Укажите среднее и дисперсию, проверьте разумность условий аппроксимации, примените поправку на непрерывность, стандартизируйте и дайте итоговую вероятность до 4 знаков.',
    prompt_uz='X~Bin(120,0.4) bo‘lsin. P(X≤55) ni normal yaqinlashuv bilan baholang. O‘rtacha va dispersiyani yozing, yaqinlashuv shartlari mosligini tekshiring, uzluksizlik tuzatishini qo‘llang, standartlang va yakuniy ehtimolni 4 xonagacha bering.',
    self_review_ru='Используйте дисперсию np(1−p), а не стандартное отклонение, как второй параметр N(μ,σ²). Для X≤55 граница с поправкой на непрерывность равна 55,5.',
    self_review_uz='N(μ,σ²) ning ikkinchi parametri sifatida standart og‘ish emas, np(1−p) dispersiyani ishlating. X≤55 uchun uzluksizlik tuzatishi chegarasi 55.5.'
where id=15681 and content_version_id=4822 and lifecycle_state='draft';

update private.exam_prep_written_understanding_checks
set prompt_ru='При поправке на непрерывность какая граница нормального распределения соответствует биномиальному событию X≥35?',
    prompt_uz='Uzluksizlik tuzatishida binomial X≥35 hodisasiga qaysi normal chegara mos?'
where id=8981 and written_task_id=15681 and lifecycle_state='draft';

-- Refresh frozen source snapshots only for machine rows corrected above.
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
  and m.content_version_id in (4821,4822)
  and m.content_key in ('P1INT01-A01','P5DAT09-A01','P5NOR06-A01','P5NOR06-A02','P5NOR06-A03');

do $postcheck$
declare
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4821 and m.content_key='P1INT01-A01'
      and q.correct_answer='C'
      and q.options_text_en::jsonb->>2='2x³−2x²+5x+C'
      and q.options_text_ru::jsonb->>2='2x³−2x²+5x+C'
      and q.options_text_uz::jsonb->>2='2x³−2x²+5x+C'
  ) then
    raise exception 'aw21_24 independent QA: P1INT01-A01 corrected option surface missing';
  end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4822
      and m.content_key in ('P5DAT09-A01','P5NOR06-A01','P5NOR06-A02','P5NOR06-A03')
      and (
        lower(q.question_text_ru) like '%normal approximation%'
        or lower(q.question_text_ru) like '%continuity correction%'
        or lower(q.question_text_ru) like '%variance%'
        or lower(q.question_text_ru) like '% mean%'
        or lower(q.question_text_uz) like '%normal approximation%'
        or lower(q.question_text_uz) like '%continuity correction%'
        or lower(q.question_text_uz) like '%variance%'
        or lower(q.question_text_uz) like '% mean%'
        or lower(q.explanation_ru) like '%continuity correction%'
        or lower(q.explanation_uz) like '%continuity correction%'
        or lower(q.explanation_uz) like '%variance%'
        or lower(q.explanation_uz) like '% mean%'
      )
  ) then
    raise exception 'aw21_24 independent QA: learner language leakage remains';
  end if;

  if exists(
    select 1 from private.exam_prep_written_tasks
    where id in (15675,15677,15681)
      and (
        lower(prompt_ru) like '%normal approximation%'
        or lower(prompt_ru) like '%continuity correction%'
        or lower(prompt_ru) like '%variance%'
        or lower(prompt_ru) like '% mean%'
        or lower(prompt_uz) like '%normal approximation%'
        or lower(prompt_uz) like '%continuity correction%'
        or lower(prompt_uz) like '%variance%'
        or lower(prompt_uz) like '% mean%'
        or lower(self_review_ru) like '%continuity correction%'
        or lower(self_review_uz) like '%continuity correction%'
      )
  ) then
    raise exception 'aw21_24 independent QA: written language leakage remains';
  end if;

  if exists(
    select 1 from private.exam_prep_written_understanding_checks
    where id=8981
      and (lower(prompt_ru) like '%continuity correction%' or lower(prompt_uz) like '%continuity correction%')
  ) then
    raise exception 'aw21_24 independent QA: written-check language leakage remains';
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4821;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(5,5,5,5,10) then
    raise exception 'aw21_24 independent QA: P1 answer balance mismatch A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4822;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,4,4,8) then
    raise exception 'aw21_24 independent QA: P5 answer balance mismatch A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
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
    raise exception 'aw21_24 independent QA: frozen snapshot mismatch rows=%',v_bad;
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
    raise exception 'aw21_24 independent QA: history appeared during correction';
  end if;
end
$postcheck$;

commit;
