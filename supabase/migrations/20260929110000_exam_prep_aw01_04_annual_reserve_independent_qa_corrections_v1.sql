-- AW1-4 annual reserve top-up independent QA corrections v1.
-- Draft/history-safe only. No learner-selectable content is published here.
--
-- Independent review result:
-- * all 45 candidate machine items were re-solved;
-- * 18 diagnostic items and all 54 misconception rules were checked;
-- * 13 new retest items were strengthened so delayed evidence is not merely
--   a number-swapped copy of teaching practice;
-- * 4 localized option surfaces containing English tokens/units were fixed
--   (two overlap the retest rewrites).
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
      where content_version_id in (4803,4804)
        and content_key in (
          'P1QUA01-R03','P1QUA01-R04',
          'P1QUA02-R03','P1QUA02-R04',
          'P1QUA03-M02','P1QUA03-R03',
          'P1FUN01-R03','P1FUN01-R04',
          'P1FUN02-R03','P1FUN02-R04',
          'P5DAT02-R03',
          'P5DAT04-R03','P5DAT04-R04',
          'P5DAT06-R03','P5DAT06-R04'
        ))<>15 then
    raise exception 'annual reserve independent QA: exact correction targets missing';
  end if;
end
$preflight$;

with fixes(
  content_key,q_en,q_ru,q_uz,
  opts_en,opts_ru,opts_uz,answer,
  exp_en,exp_ru,exp_uz
) as (values

-- P1 QUA-01: retest asks for interpretation/transfer rather than repeating
-- the same completed-square teaching prompt.
('P1QUA01-R03',
 'For q(x)=5x²−20x+23, the equation q(x)=c has exactly one real solution. Enter c.',
 'Для q(x)=5x²−20x+23 уравнение q(x)=c имеет ровно одно действительное решение. Введите c.',
 'q(x)=5x²−20x+23 bo‘lsin. q(x)=c tenglama aynan bitta haqiqiy yechimga ega. c ni kiriting.',
 '[]','[]','[]','3',
 'q(x)=5(x−2)²+3. A horizontal level q(x)=c meets the parabola once only at its minimum, so c=3.',
 'q(x)=5(x−2)²+3. Горизонтальный уровень q(x)=c пересекает параболу ровно один раз только в её минимуме, поэтому c=3.',
 'q(x)=5(x−2)²+3. q(x)=c gorizontal sath parabola bilan faqat minimum nuqtasida bitta kesishishga ega, shuning uchun c=3.'),

('P1QUA01-R04',
 'Which statement about y=−x²+10x−18 is correct?',
 'Какое утверждение верно для y=−x²+10x−18?',
 'y=−x²+10x−18 uchun qaysi tasdiq to‘g‘ri?',
 '["The vertex is (−5, 7) and 7 is a maximum.","The vertex is (5, −7) and −7 is a minimum.","The vertex is (5, 7) and 7 is a minimum.","The vertex is (5, 7) and 7 is a maximum."]',
 '["Вершина (−5, 7), и 7 — максимум.","Вершина (5, −7), и −7 — минимум.","Вершина (5, 7), и 7 — минимум.","Вершина (5, 7), и 7 — максимум."]',
 '["Cho‘qqi (−5, 7), 7 esa maksimum.","Cho‘qqi (5, −7), −7 esa minimum.","Cho‘qqi (5, 7), 7 esa minimum.","Cho‘qqi (5, 7), 7 esa maksimum."]',
 'D',
 'y=−(x−5)²+7, so the vertex is (5,7). The negative squared-term coefficient makes 7 the maximum value.',
 'y=−(x−5)²+7, поэтому вершина равна (5,7). Отрицательный коэффициент при квадрате означает, что 7 — максимальное значение.',
 'y=−(x−5)²+7, demak cho‘qqi (5,7). Kvadrat had oldidagi manfiy koeffitsiyent 7 maksimal qiymat ekanini bildiradi.'),

-- P1 QUA-02: delayed checks use inequality/tangency interpretation.
('P1QUA02-R03',
 'For which values of q is 2x²+qx+5 positive for every real x?',
 'При каких значениях q выражение 2x²+qx+5 положительно для всех действительных x?',
 'Qaysi q qiymatlarida 2x²+qx+5 barcha haqiqiy x lar uchun musbat bo‘ladi?',
 '["−2√10 < q < 2√10","q < −2√10 or q > 2√10","q ≤ −2√10 or q ≥ 2√10","q = ±2√10"]',
 '["−2√10 < q < 2√10","q < −2√10 или q > 2√10","q ≤ −2√10 или q ≥ 2√10","q = ±2√10"]',
 '["−2√10 < q < 2√10","q < −2√10 yoki q > 2√10","q ≤ −2√10 yoki q ≥ 2√10","q = ±2√10"]',
 'A',
 'Because the leading coefficient is positive, the quadratic is positive for every real x exactly when it has no real roots. Thus q²−40<0, giving −2√10<q<2√10.',
 'Поскольку старший коэффициент положителен, выражение положительно для всех действительных x тогда и только тогда, когда действительных корней нет. Поэтому q²−40<0 и −2√10<q<2√10.',
 'Yetakchi koeffitsiyent musbat bo‘lgani uchun ifoda barcha haqiqiy x lar uchun musbat bo‘lishi uchun haqiqiy ildizlar bo‘lmasligi kerak. Demak q²−40<0 va −2√10<q<2√10.'),

('P1QUA02-R04',
 'The line y=4mx−4 is tangent to the parabola y=x². For which values of m does this happen?',
 'Прямая y=4mx−4 касается параболы y=x². При каких значениях m это возможно?',
 'y=4mx−4 to‘g‘ri chiziq y=x² parabolaga urinadi. Bu qaysi m qiymatlarida sodir bo‘ladi?',
 '["m = 1 only","m = −1 only","m = −1 or m = 1","m = −2 or m = 2"]',
 '["только m = 1","только m = −1","m = −1 или m = 1","m = −2 или m = 2"]',
 '["faqat m = 1","faqat m = −1","m = −1 yoki m = 1","m = −2 yoki m = 2"]',
 'C',
 'At an intersection x²=4mx−4, so x²−4mx+4=0. Tangency requires discriminant 0: 16m²−16=0, hence m=±1.',
 'В точке пересечения x²=4mx−4, то есть x²−4mx+4=0. Для касания дискриминант равен 0: 16m²−16=0, поэтому m=±1.',
 'Kesishishda x²=4mx−4, ya’ni x²−4mx+4=0. Urinish uchun diskriminant 0 bo‘lishi kerak: 16m²−16=0, demak m=±1.'),

-- Keep the QUA-03 mathematics but remove untranslated learner-facing option text.
('P1QUA03-M02',
 'A rectangle has width x cm and length (x+3) cm. Its area is 54 cm². What is its width?',
 'Ширина прямоугольника равна x см, а длина — (x+3) см. Его площадь равна 54 см². Чему равна ширина?',
 'To‘g‘ri to‘rtburchakning eni x sm, bo‘yi esa (x+3) sm. Uning yuzi 54 sm². Eni qancha?',
 '["3 cm","9 cm","−9 cm","6 cm"]',
 '["3 см","9 см","−9 см","6 см"]',
 '["3 sm","9 sm","−9 sm","6 sm"]',
 'D',
 'x(x+3)=54 gives x²+3x−54=0=(x+9)(x−6). A length must be positive, so x=6 cm.',
 'x(x+3)=54 даёт x²+3x−54=0=(x+9)(x−6). Длина должна быть положительной, поэтому x=6 см.',
 'x(x+3)=54 dan x²+3x−54=0=(x+9)(x−6) keladi. Uzunlik musbat bo‘lishi kerak, shuning uchun x=6 sm.'),

('P1QUA03-R03',
 'Solve 3x²−5x−2=0.',
 'Решите уравнение 3x²−5x−2=0.',
 '3x²−5x−2=0 tenglamani yeching.',
 '["x = −2 or x = 1/3","x = 2 or x = −1/3","x = 2 or x = 1/3","x = −2 or x = −1/3"]',
 '["x = −2 или x = 1/3","x = 2 или x = −1/3","x = 2 или x = 1/3","x = −2 или x = −1/3"]',
 '["x = −2 yoki x = 1/3","x = 2 yoki x = −1/3","x = 2 yoki x = 1/3","x = −2 yoki x = −1/3"]',
 'B',
 '3x²−5x−2=(3x+1)(x−2), so x=2 or x=−1/3.',
 '3x²−5x−2=(3x+1)(x−2), поэтому x=2 или x=−1/3.',
 '3x²−5x−2=(3x+1)(x−2), shuning uchun x=2 yoki x=−1/3.'),

-- P1 FUN-01: retests now use branch/domain reasoning and composition domain.
('P1FUN01-R03',
 'Let f(x)=x² with domain x≤0. Which formula gives f⁻¹(x)?',
 'Пусть f(x)=x² с областью определения x≤0. Какая формула задаёт f⁻¹(x)?',
 'f(x)=x² va aniqlanish sohasi x≤0 bo‘lsin. f⁻¹(x) ni qaysi formula beradi?',
 '["√x, x≥0","−√x, x≤0","x², x≤0","−√x, x≥0"]',
 '["√x, x≥0","−√x, x≤0","x², x≤0","−√x, x≥0"]',
 '["√x, x≥0","−√x, x≤0","x², x≤0","−√x, x≥0"]',
 'D',
 'On the stated domain f uses the non-positive branch. Reversing y=x² therefore gives x=−√y, so f⁻¹(x)=−√x for x≥0.',
 'На заданной области функция использует неположительную ветвь. При обращении y=x² получаем x=−√y, поэтому f⁻¹(x)=−√x при x≥0.',
 'Berilgan sohada funksiya manfiy bo‘lmagan emas, balki nomanfiy bo‘lmagan tarmoqdan foydalanadi. y=x² ni teskari yechganda x=−√y, demak f⁻¹(x)=−√x, x≥0.'),

('P1FUN01-R04',
 'Let f(x)=1/(x−3) and g(x)=2x+1. Enter the value of x that must be excluded from the domain of (f∘g)(x).',
 'Пусть f(x)=1/(x−3) и g(x)=2x+1. Введите значение x, которое нужно исключить из области определения (f∘g)(x).',
 'f(x)=1/(x−3) va g(x)=2x+1 bo‘lsin. (f∘g)(x) ning aniqlanish sohasidan chiqarilishi kerak bo‘lgan x qiymatini kiriting.',
 '[]','[]','[]','1',
 '(f∘g)(x)=1/(2x+1−3)=1/(2x−2). The denominator is zero at x=1, so x=1 must be excluded.',
 '(f∘g)(x)=1/(2x+1−3)=1/(2x−2). Знаменатель равен нулю при x=1, поэтому x=1 исключается.',
 '(f∘g)(x)=1/(2x+1−3)=1/(2x−2). Maxraj x=1 da nol bo‘ladi, shuning uchun x=1 chiqarib tashlanadi.'),

-- P1 FUN-02: retests add endpoint topology and a different function family.
('P1FUN02-R03',
 'For f(x)=(x−2)²+1 with −1<x≤4, what is the range?',
 'Для f(x)=(x−2)²+1 при −1<x≤4 какова область значений?',
 'f(x)=(x−2)²+1 va −1<x≤4 bo‘lsa, funksiyaning qiymatlar sohasi qaysi?',
 '["1<f(x)≤10","1≤f(x)≤10","1<f(x)<10","1≤f(x)<10"]',
 '["1<f(x)≤10","1≤f(x)≤10","1<f(x)<10","1≤f(x)<10"]',
 '["1<f(x)≤10","1≤f(x)≤10","1<f(x)<10","1≤f(x)<10"]',
 'D',
 'The minimum 1 occurs at x=2 and is included. As x approaches −1 from above, f(x) approaches 10 but never reaches it, so the range is 1≤f(x)<10.',
 'Минимум 1 достигается при x=2 и входит в область значений. При x→−1 справа f(x) стремится к 10, но не достигает его, поэтому 1≤f(x)<10.',
 'Minimum 1 x=2 da olinadi va kiradi. x −1 ga o‘ng tomondan yaqinlashganda f(x) 10 ga yaqinlashadi, lekin unga teng bo‘lmaydi. Demak 1≤f(x)<10.'),

('P1FUN02-R04',
 'For f(x)=2x+3 with −5≤x<4, enter the minimum value of f.',
 'Для f(x)=2x+3 при −5≤x<4 введите минимальное значение f.',
 'f(x)=2x+3 va −5≤x<4 bo‘lsa, f ning eng kichik qiymatini kiriting.',
 '[]','[]','[]','-7',
 'The function is increasing, so its minimum occurs at the included left endpoint x=−5. Hence f(−5)=−7.',
 'Функция возрастает, поэтому минимум достигается в включённой левой границе x=−5. Следовательно, f(−5)=−7.',
 'Funksiya o‘suvchi, shuning uchun minimum kiritilgan chap chegara x=−5 da olinadi. Demak f(−5)=−7.'),

-- P5 DAT-02: delayed evidence requires a fresh interpretation after a data change.
('P5DAT02-R03',
 'A stem-and-leaf diagram has key 2 | 4 = 24 and rows 2 | 4 7 9 and 3 | 1 1 8. One additional observation 30 is inserted. Enter the new median.',
 'В стебле-листовой диаграмме ключ 2 | 4 = 24, строки: 2 | 4 7 9 и 3 | 1 1 8. Добавили ещё одно наблюдение 30. Введите новую медиану.',
 'Poya-barg diagrammasida kalit 2 | 4 = 24, qatorlar: 2 | 4 7 9 va 3 | 1 1 8. Yana bitta 30 kuzatuvi qo‘shildi. Yangi medianani kiriting.',
 '[]','[]','[]','30',
 'The ordered values become 24,27,29,30,31,31,38. With seven observations, the fourth value is the median, so the new median is 30.',
 'Упорядоченные значения: 24,27,29,30,31,31,38. При семи наблюдениях медиана — четвёртое значение, то есть 30.',
 'Tartiblangan qiymatlar 24,27,29,30,31,31,38 bo‘ladi. Yetti kuzatuvda to‘rtinchi qiymat mediana, ya’ni 30.'),

-- P5 DAT-04: retests compare bar heights/areas rather than repeat one-step formulas.
('P5DAT04-R03',
 'Two histogram classes have widths 4 and 6 and frequencies 12 and 18 respectively. Enter the ratio (first bar height)/(second bar height).',
 'Два интервала гистограммы имеют ширины 4 и 6 и частоты 12 и 18 соответственно. Введите отношение (высота первого столбца)/(высота второго столбца).',
 'Gistogrammadagi ikki sinfning kengliklari 4 va 6, chastotalari esa mos ravishda 12 va 18. (Birinchi ustun balandligi)/(ikkinchi ustun balandligi) nisbatini kiriting.',
 '[]','[]','[]','1',
 'The frequency densities are 12÷4=3 and 18÷6=3. Histogram bar height is frequency density, so the ratio is 3/3=1.',
 'Плотности частоты равны 12÷4=3 и 18÷6=3. Высота столбца гистограммы равна плотности частоты, поэтому отношение 3/3=1.',
 'Chastota zichliklari 12÷4=3 va 18÷6=3. Gistogramma ustun balandligi chastota zichligiga teng, demak nisbat 3/3=1.'),

('P5DAT04-R04',
 'In a histogram, class A has width 4 and frequency density 6; class B has width 8 and frequency density 3. Which statement is correct?',
 'На гистограмме интервал A имеет ширину 4 и плотность частоты 6, а интервал B — ширину 8 и плотность частоты 3. Какое утверждение верно?',
 'Gistogrammada A sinf kengligi 4 va chastota zichligi 6, B sinf kengligi 8 va chastota zichligi 3. Qaysi tasdiq to‘g‘ri?',
 '["The two classes have equal frequencies.","Class A has the greater frequency.","Class B has the greater frequency.","The two bars have equal heights."]',
 '["Частоты двух интервалов равны.","У интервала A частота больше.","У интервала B частота больше.","Высоты двух столбцов равны."]',
 '["Ikki sinfning chastotalari teng.","A sinf chastotasi kattaroq.","B sinf chastotasi kattaroq.","Ikki ustunning balandligi teng."]',
 'A',
 'Frequency is bar area: A has 4×6=24 and B has 8×3=24. The heights differ, but the frequencies are equal.',
 'Частота соответствует площади столбца: для A это 4×6=24, для B — 8×3=24. Высоты различаются, но частоты равны.',
 'Chastota ustun yuziga teng: A uchun 4×6=24, B uchun 8×3=24. Balandliklar turlicha, lekin chastotalar teng.'),

-- P5 DAT-06: retests use inverse/robustness reasoning rather than repeat direct averages.
('P5DAT06-R03',
 'The values 2, 6 and 10 occur with frequencies 1, k and 2 respectively. The mean is 7. Enter k.',
 'Значения 2, 6 и 10 встречаются с частотами 1, k и 2 соответственно. Среднее равно 7. Введите k.',
 '2, 6 va 10 qiymatlar mos ravishda 1, k va 2 marta uchraydi. O‘rtacha 7 ga teng. k ni kiriting.',
 '[]','[]','[]','1',
 '(2·1+6k+10·2)/(k+3)=7. Thus 22+6k=7k+21, giving k=1.',
 '(2·1+6k+10·2)/(k+3)=7. Поэтому 22+6k=7k+21 и k=1.',
 '(2·1+6k+10·2)/(k+3)=7. Demak 22+6k=7k+21 va k=1.'),

('P5DAT06-R04',
 'The data are 3, 3, 5, 7, 12. If 12 is replaced by 22, which statement is correct?',
 'Даны значения 3, 3, 5, 7, 12. Если заменить 12 на 22, какое утверждение верно?',
 'Ma’lumotlar 3, 3, 5, 7, 12. Agar 12 o‘rniga 22 qo‘yilsa, qaysi tasdiq to‘g‘ri?',
 '["The mean is unchanged, but the median increases.","The mean increases by 10, while the median is unchanged.","The median increases by 2, while the mean is unchanged.","The mean increases by 2, while the median and mode are unchanged."]',
 '["Среднее не изменится, но медиана увеличится.","Среднее увеличится на 10, а медиана не изменится.","Медиана увеличится на 2, а среднее не изменится.","Среднее увеличится на 2, а медиана и мода не изменятся."]',
 '["O‘rtacha o‘zgarmaydi, ammo mediana oshadi.","O‘rtacha 10 ga oshadi, mediana esa o‘zgarmaydi.","Mediana 2 ga oshadi, o‘rtacha esa o‘zgarmaydi.","O‘rtacha 2 ga oshadi, mediana va moda esa o‘zgarmaydi."]',
 'D',
 'The total rises from 30 to 40, so the mean rises from 6 to 8, an increase of 2. The middle value remains 5 and the repeated value remains 3.',
 'Сумма возрастает с 30 до 40, поэтому среднее увеличивается с 6 до 8, то есть на 2. Центральное значение остаётся 5, а повторяющееся значение — 3.',
 'Yig‘indi 30 dan 40 ga oshadi, shuning uchun o‘rtacha 6 dan 8 ga, ya’ni 2 ga oshadi. O‘rta qiymat 5, takrorlanuvchi qiymat esa 3 bo‘lib qoladi.')
)
update public.questions q
set question_text=f.q_en,
    question_text_en=f.q_en,
    question_text_ru=f.q_ru,
    question_text_uz=f.q_uz,
    options_text=f.opts_en,
    options_text_en=f.opts_en,
    options_text_ru=f.opts_ru,
    options_text_uz=f.opts_uz,
    correct_answer=f.answer,
    explanation=f.exp_en,
    explanation_en=f.exp_en,
    explanation_ru=f.exp_ru,
    explanation_uz=f.exp_uz
from fixes f
join private.exam_prep_question_content_meta m
  on m.content_version_id in (4803,4804)
 and m.content_key=f.content_key
where q.id=m.question_id
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
  and m.content_version_id in (4803,4804)
  and m.content_key in (
    'P1QUA01-R03','P1QUA01-R04',
    'P1QUA02-R03','P1QUA02-R04',
    'P1QUA03-M02','P1QUA03-R03',
    'P1FUN01-R03','P1FUN01-R04',
    'P1FUN02-R03','P1FUN02-R04',
    'P5DAT02-R03',
    'P5DAT04-R03','P5DAT04-R04',
    'P5DAT06-R03','P5DAT06-R04'
  );

do $postcheck$
declare v_bad int;
begin
  -- Learner-facing RU/UZ option strings may contain mathematical variable names,
  -- but not the English connectors/units found during review.
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

  -- Correct-answer positions remain balanced exactly as authored; only three
  -- numeric input answers changed.
  if (select count(*) from private.exam_prep_question_content_meta m
      join public.questions q on q.id=m.question_id
      where m.content_version_id in (4803,4804) and lower(q.qtype)='input'
        and nullif(btrim(q.correct_answer),'') is null)<>0 then
    raise exception 'annual reserve independent QA: empty corrected input answer';
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
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4803,4804)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4803,4804)
  ) then
    raise exception 'annual reserve independent QA: history appeared during correction';
  end if;
end
$postcheck$;

commit;
