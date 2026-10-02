-- AW21-24 annual-reserve independent academic/language QA corrections v1.
-- Draft/history-free content only. No learner exposure and no publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4823,4824) and status='draft')<>2 then
    raise exception 'aw21_24 reserve independent QA: target draft versions missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4823,4824)
        and lifecycle_state='draft' and exposure_state='withheld')<>90 then
    raise exception 'aw21_24 reserve independent QA: draft/withheld surface mismatch';
  end if;

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
    raise exception 'aw21_24 reserve independent QA: target draft has learner/legacy history';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id=4824
        and content_key in (
          'P5DAT08-D02','P5DAT09-D02','P5DAT09-R04','P5NOR04-M02',
          'P5NOR06-D02','P5NOR06-D03','P5NOR06-R03','P5NOR06-R04','P5NOR06-M02'
        ))<>9 then
    raise exception 'aw21_24 reserve independent QA: correction targets missing';
  end if;
end
$preflight$;

-- P5-DAT-08: make the comparison explicitly contextual, as required by the canonical skill.
update public.questions q
set question_text='Route A delivery times have median 40 minutes and IQR 8 minutes. Route B delivery times have median 44 minutes and IQR 5 minutes. Which conclusion is supported?',
    question_text_en='Route A delivery times have median 40 minutes and IQR 8 minutes. Route B delivery times have median 44 minutes and IQR 5 minutes. Which conclusion is supported?',
    question_text_ru='Для времени доставки по маршруту A медиана равна 40 минутам, IQR — 8 минутам. Для маршрута B медиана равна 44 минутам, IQR — 5 минутам. Какой вывод подтверждается?',
    question_text_uz='A yo‘nalishida yetkazib berish vaqtining medianasi 40 daqiqa, IQR 8 daqiqa. B yo‘nalishida mediana 44 daqiqa, IQR 5 daqiqa. Qaysi xulosa asosli?',
    options_text='["Route A usually takes longer and is more consistent","Route B usually takes longer but is more consistent in its middle 50%","Route B usually takes less time and is less consistent","The two routes have the same typical time and spread"]',
    options_text_en='["Route A usually takes longer and is more consistent","Route B usually takes longer but is more consistent in its middle 50%","Route B usually takes less time and is less consistent","The two routes have the same typical time and spread"]',
    options_text_ru='["Маршрут A обычно занимает больше времени и более стабилен","Маршрут B обычно занимает больше времени, но его средние 50% значений менее разбросаны","Маршрут B обычно занимает меньше времени и менее стабилен","У двух маршрутов одинаковые типичное время и разброс"]',
    options_text_uz='["A yo‘nalishi odatda ko‘proq vaqt oladi va barqarorroq","B yo‘nalishi odatda ko‘proq vaqt oladi, lekin uning o‘rta 50% qiymatlari kamroq tarqalgan","B yo‘nalishi odatda kamroq vaqt oladi va beqarorroq","Ikki yo‘nalishning odatiy vaqti va tarqalishi bir xil"]',
    explanation='Route B has the larger median (44>40), so its typical delivery time is longer. It has the smaller IQR (5<8), so its middle 50% is less spread out.',
    explanation_en='Route B has the larger median (44>40), so its typical delivery time is longer. It has the smaller IQR (5<8), so its middle 50% is less spread out.',
    explanation_ru='У маршрута B медиана выше (44>40), поэтому его типичное время доставки больше. IQR меньше (5<8), поэтому средние 50% значений менее разбросаны.',
    explanation_uz='B yo‘nalishida mediana kattaroq (44>40), demak odatiy yetkazib berish vaqti uzunroq. IQR kichikroq (5<8), shuning uchun o‘rta 50% qiymatlar kamroq tarqalgan.'
from private.exam_prep_question_content_meta m
where q.id=m.question_id
  and m.content_version_id=4824
  and m.content_key='P5DAT08-D02'
  and q.is_active=false and q.quality_status='draft';

-- P5-DAT-09: restore direct standard-deviation evidence in both diagnostic and delayed-retest reserve.
update public.questions q
set question_text='For 5 observations, Σx=35 and Σx²=290. Find the standard deviation using variance = Σx²/n − x̄².',
    question_text_en='For 5 observations, Σx=35 and Σx²=290. Find the standard deviation using variance = Σx²/n − x̄².',
    question_text_ru='Для 5 наблюдений Σx=35 и Σx²=290. Найдите стандартное отклонение, используя дисперсию Σx²/n − x̄².',
    question_text_uz='5 ta kuzatuv uchun Σx=35 va Σx²=290. Dispersiya Σx²/n − x̄² formulasidan foydalanib standart og‘ishni toping.',
    options_text='["7","9","58","3"]',
    options_text_en='["7","9","58","3"]',
    options_text_ru='["7","9","58","3"]',
    options_text_uz='["7","9","58","3"]',
    explanation='The mean is 35/5=7. Variance=290/5−7²=58−49=9, so the standard deviation is √9=3.',
    explanation_en='The mean is 35/5=7. Variance=290/5−7²=58−49=9, so the standard deviation is √9=3.',
    explanation_ru='Среднее равно 35/5=7. Дисперсия=290/5−7²=58−49=9, поэтому стандартное отклонение равно √9=3.',
    explanation_uz='O‘rtacha 35/5=7. Dispersiya=290/5−7²=58−49=9, shuning uchun standart og‘ish √9=3.'
from private.exam_prep_question_content_meta m
where q.id=m.question_id
  and m.content_version_id=4824
  and m.content_key='P5DAT09-D02'
  and q.correct_answer='D'
  and q.is_active=false and q.quality_status='draft';

update public.questions q
set question_text='For 4 observations, Σx=20 and Σx²=136. Find the standard deviation using variance = Σx²/n − x̄².',
    question_text_en='For 4 observations, Σx=20 and Σx²=136. Find the standard deviation using variance = Σx²/n − x̄².',
    question_text_ru='Для 4 наблюдений Σx=20 и Σx²=136. Найдите стандартное отклонение, используя дисперсию Σx²/n − x̄².',
    question_text_uz='4 ta kuzatuv uchun Σx=20 va Σx²=136. Dispersiya Σx²/n − x̄² formulasidan foydalanib standart og‘ishni toping.',
    options_text='["25","34","9","3"]',
    options_text_en='["25","34","9","3"]',
    options_text_ru='["25","34","9","3"]',
    options_text_uz='["25","34","9","3"]',
    explanation='The mean is 5. Variance=136/4−5²=34−25=9, so the standard deviation is √9=3.',
    explanation_en='The mean is 5. Variance=136/4−5²=34−25=9, so the standard deviation is √9=3.',
    explanation_ru='Среднее равно 5. Дисперсия=136/4−5²=34−25=9, поэтому стандартное отклонение равно √9=3.',
    explanation_uz='O‘rtacha 5. Dispersiya=136/4−5²=34−25=9, shuning uchun standart og‘ish √9=3.'
from private.exam_prep_question_content_meta m
where q.id=m.question_id
  and m.content_version_id=4824
  and m.content_key='P5DAT09-R04'
  and q.correct_answer='D'
  and q.is_active=false and q.quality_status='draft';

-- P5-NOR-04: make the transfer item exercise a non-trivial inverse-normal quantile, not only symmetry at the median.
update public.questions q
set question_text='X~N(84,9). Using z=0.674 for the 75th percentile, enter the upper quartile of X to 2 d.p.',
    question_text_en='X~N(84,9). Using z=0.674 for the 75th percentile, enter the upper quartile of X to 2 d.p.',
    question_text_ru='X~N(84,9). Используя z=0,674 для 75-го процентиля, введите верхний квартиль X до 2 знаков.',
    question_text_uz='X~N(84,9). 75-percentil uchun z=0.674 dan foydalanib, X ning yuqori kvartilini 2 xonagacha kiriting.',
    correct_answer='86.02',
    explanation='Here σ=3. The upper quartile is the 75th percentile, so x=84+0.674(3)=86.022≈86.02.',
    explanation_en='Here σ=3. The upper quartile is the 75th percentile, so x=84+0.674(3)=86.022≈86.02.',
    explanation_ru='Здесь σ=3. Верхний квартиль — это 75-й процентиль, поэтому x=84+0,674(3)=86,022≈86,02.',
    explanation_uz='Bu yerda σ=3. Yuqori kvartil 75-percentil, shuning uchun x=84+0.674(3)=86.022≈86.02.'
from private.exam_prep_question_content_meta m
where q.id=m.question_id
  and m.content_version_id=4824
  and m.content_key='P5NOR04-M02'
  and q.qtype='input'
  and q.is_active=false and q.quality_status='draft';

-- P5-NOR-06: add direct conditions evidence and keep Bin(n,p) notation unambiguous in Russian.
update public.questions q
set question_text='For a binomial distribution to be approximated well by a normal distribution, which check is the relevant one?',
    question_text_en='For a binomial distribution to be approximated well by a normal distribution, which check is the relevant one?',
    question_text_ru='Какую проверку нужно выполнить, чтобы нормальное приближение биномиального распределения было обоснованным?',
    question_text_uz='Binomial taqsimotni normal taqsimot bilan yaxshi yaqinlashtirish uchun qaysi tekshiruv muhim?',
    options_text='["Only n must be at least 30","p must be close to 0.5","The binomial variance must equal the mean","Both np and n(1−p) should be sufficiently large"]',
    options_text_en='["Only n must be at least 30","p must be close to 0.5","The binomial variance must equal the mean","Both np and n(1−p) should be sufficiently large"]',
    options_text_ru='["Достаточно, чтобы только n было не меньше 30","p обязательно должно быть близко к 0,5","Дисперсия биномиального распределения должна быть равна среднему","И np, и n(1−p) должны быть достаточно большими"]',
    options_text_uz='["Faqat n kamida 30 bo‘lishi kifoya","p albatta 0.5 ga yaqin bo‘lishi kerak","Binomial taqsimot dispersiyasi o‘rtachaga teng bo‘lishi kerak","np ham, n(1−p) ham yetarlicha katta bo‘lishi kerak"]',
    explanation='A normal approximation is appropriate when both expected counts np and n(1−p) are sufficiently large; checking n alone or p alone is not enough.',
    explanation_en='A normal approximation is appropriate when both expected counts np and n(1−p) are sufficiently large; checking n alone or p alone is not enough.',
    explanation_ru='Нормальное приближение обосновано, когда оба ожидаемых количества np и n(1−p) достаточно велики; проверки только n или только p недостаточно.',
    explanation_uz='Normal yaqinlashuv np va n(1−p) kutiladigan sonlarning ikkalasi ham yetarlicha katta bo‘lganda mos keladi; faqat n yoki faqat p ni tekshirish yetarli emas.'
from private.exam_prep_question_content_meta m
where q.id=m.question_id
  and m.content_version_id=4824
  and m.content_key='P5NOR06-D03'
  and q.correct_answer='D'
  and q.is_active=false and q.quality_status='draft';

update public.questions q
set question_text_ru='X~Bin(100,0.5). Какая запись нормального приближения верна для P(X≤55)?'
from private.exam_prep_question_content_meta m
where q.id=m.question_id and m.content_version_id=4824 and m.content_key='P5NOR06-D02'
  and q.is_active=false and q.quality_status='draft';

update public.questions q
set question_text_ru='Для X~Bin(80,0.25) нормальное приближение используется для P(X≥25). Введите нижнюю границу с поправкой на непрерывность.'
from private.exam_prep_question_content_meta m
where q.id=m.question_id and m.content_version_id=4824 and m.content_key='P5NOR06-R03'
  and q.is_active=false and q.quality_status='draft';

update public.questions q
set question_text_ru='Для X~Bin(120,0.4) какой интервал с поправкой на непрерывность соответствует P(45≤X≤55)?'
from private.exam_prep_question_content_meta m
where q.id=m.question_id and m.content_version_id=4824 and m.content_key='P5NOR06-R04'
  and q.is_active=false and q.quality_status='draft';

update public.questions q
set question_text_ru='Для X~Bin(150,0.3) введите дисперсию np(1−p), используемую в нормальном приближении.'
from private.exam_prep_question_content_meta m
where q.id=m.question_id and m.content_version_id=4824 and m.content_key='P5NOR06-M02'
  and q.is_active=false and q.quality_status='draft';

-- Tailor the diagnostic feedback for the newly explicit approximation-conditions item.
update private.exam_prep_diagnostic_rules r
set feedback_en='Your choice does not identify the condition that makes a normal approximation to a binomial distribution reliable.',
    feedback_ru='Выбранный вариант неверно определяет условие, при котором нормальное приближение биномиального распределения является обоснованным.',
    feedback_uz='Tanlangan javob binomial taqsimotni normal yaqinlashtirish ishonchli bo‘ladigan shartni noto‘g‘ri aniqlaydi.',
    next_action_en='Before approximating, calculate or inspect both np and n(1−p). Both should be sufficiently large; n alone or p alone is not the criterion.',
    next_action_ru='Перед приближением вычислите или оцените и np, и n(1−p). Оба значения должны быть достаточно большими; одного n или одного p недостаточно.',
    next_action_uz='Yaqinlashtirishdan oldin np va n(1−p) ni hisoblang yoki baholang. Ikkalasi ham yetarlicha katta bo‘lishi kerak; faqat n yoki faqat p mezon emas.'
from private.exam_prep_question_content_meta m
where r.content_meta_id=m.id
  and m.content_version_id=4824
  and m.content_key='P5NOR06-D03'
  and r.rule_version='aw_reserve_v1'
  and r.status='draft';

-- Refresh frozen source snapshots only for corrected source-question rows.
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
  and m.content_version_id=4824
  and m.content_key in (
    'P5DAT08-D02','P5DAT09-D02','P5DAT09-R04','P5NOR04-M02',
    'P5NOR06-D02','P5NOR06-D03','P5NOR06-R03','P5NOR06-R04','P5NOR06-M02'
  );

do $postcheck$
declare v_bad int;
begin
  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5DAT08-D02'
      and q.correct_answer='B'
      and q.question_text_en like 'Route A delivery times%'
      and q.options_text_en::jsonb->>1 like 'Route B usually takes longer%'
  ) then raise exception 'aw21_24 reserve independent QA: contextual comparison correction missing'; end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5DAT09-D02'
      and q.correct_answer='D'
      and q.question_text_en like '%standard deviation%'
      and q.options_text_en::jsonb->>3='3'
      and q.explanation_en like '%standard deviation is √9=3%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5DAT09-R04'
      and q.correct_answer='D'
      and q.question_text_en like '%standard deviation%'
      and q.options_text_en::jsonb->>3='3'
  ) then raise exception 'aw21_24 reserve independent QA: standard-deviation evidence correction missing'; end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5NOR04-M02'
      and q.qtype='input' and q.correct_answer='86.02'
      and q.question_text_en like '%upper quartile%'
      and q.explanation_en like '%86.022≈86.02%'
  ) then raise exception 'aw21_24 reserve independent QA: inverse-normal transfer correction missing'; end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5NOR06-D03'
      and q.correct_answer='D'
      and q.options_text_en::jsonb->>3='Both np and n(1−p) should be sufficiently large'
      and q.explanation_en like '%both expected counts np and n(1−p)%'
  ) then raise exception 'aw21_24 reserve independent QA: approximation-condition correction missing'; end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824
      and m.content_key in ('P5NOR06-D02','P5NOR06-R03','P5NOR06-R04','P5NOR06-M02')
      and q.question_text_ru ~ 'Bin\([0-9]+,0,[0-9]+\)'
  ) then raise exception 'aw21_24 reserve independent QA: ambiguous Russian Bin decimal notation remains'; end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id=4824 and m.content_key='P5NOR06-D03'
        and r.rule_version='aw_reserve_v1'
        and r.status='draft'
        and r.feedback_en like 'Your choice does not identify the condition%'
        and r.feedback_ru like 'Выбранный вариант неверно определяет условие%'
        and r.feedback_uz like 'Tanlangan javob binomial taqsimotni normal yaqinlashtirish%'
      )<>3 then
    raise exception 'aw21_24 reserve independent QA: approximation-condition diagnostic feedback mismatch';
  end if;

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
  if v_bad<>0 then raise exception 'aw21_24 reserve independent QA: frozen snapshot mismatch rows=%',v_bad; end if;

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
  ) then raise exception 'aw21_24 reserve independent QA: history appeared during correction'; end if;
end
$postcheck$;

commit;
