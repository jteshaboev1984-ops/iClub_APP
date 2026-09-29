-- AW5-8 annual reserve top-up independent QA corrections v1.
-- Draft/history-safe only. No learner-selectable content is published here.
--
-- Independent review result:
-- * all 70 candidate machine items were independently re-solved/rechecked;
-- * all 28 diagnostic items and 84 misconception rules were reviewed;
-- * 13 delayed-retest items were strengthened to reduce number-swap/template
--   proximity to already-published learning/retest surfaces;
-- * one awkward P1 reflection distractor ("translation through the origin")
--   is removed by the stronger inverse-mapping retest;
-- * RU/UZ wording for every corrected item is updated together with EN;
-- * versions 4807/4808 remain draft/withheld and history-free.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4807,4808) and status='draft')<>2 then
    raise exception 'aw05_08 annual reserve independent QA: target draft versions missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id=4807)<>40
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id=4808)<>30 then
    raise exception 'aw05_08 annual reserve independent QA: candidate surface mismatch';
  end if;

  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4807,4808)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4807,4808)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4807,4808)
  ) then
    raise exception 'aw05_08 annual reserve independent QA: draft has learner/legacy history';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4807,4808)
    and (m.lifecycle_state<>'draft'
      or m.exposure_state<>'withheld'
      or q.is_active
      or q.quality_status<>'draft');
  if v_bad<>0 then
    raise exception 'aw05_08 annual reserve independent QA: draft exposure drift rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4807,4808)
        and content_key in (
          'P1FUN06-R03','P1FUN07-R04','P1FUN08-R04',
          'P1COO01-R03','P1COO02-R04','P1COO03-R03',
          'P1CIR01-R03','P1TRI01-R03',
          'P5CNT01-R03','P5CNT02-R04','P5CNT03-R03',
          'P5CNT04-R03','P5PRO01-R03'
        ))<>13 then
    raise exception 'aw05_08 annual reserve independent QA: exact correction targets missing';
  end if;
end
$preflight$;

with fixes(
  content_key,q_en,q_ru,q_uz,
  opts_en,opts_ru,opts_uz,answer,
  exp_en,exp_ru,exp_uz
) as (values
('P1FUN06-R03',
 'On y=f(x−4)+1 the minimum point is (11,−1). Enter the x-coordinate of the minimum point of y=f(x).',
 'На графике y=f(x−4)+1 точка минимума равна (11,−1). Введите x-координату точки минимума графика y=f(x).',
 'y=f(x−4)+1 grafigining minimum nuqtasi (11,−1). y=f(x) grafigi minimum nuqtasining x-koordinatasini kiriting.',
 '[]','[]','[]','7',
 'The transformation y=f(x−4)+1 moves the original graph 4 units right and 1 unit up. Reversing the horizontal shift gives 11−4=7.',
 'Преобразование y=f(x−4)+1 сдвигает исходный график на 4 вправо и на 1 вверх. Обратный горизонтальный сдвиг даёт 11−4=7.',
 'y=f(x−4)+1 dastlabki grafikni 4 birlik o‘ngga va 1 birlik yuqoriga siljitadi. Gorizontal siljishni teskari qo‘llasak, 11−4=7.'),

('P1FUN07-R04',
 'The graph y=−f(−x) contains the point (4,−7). Which point must lie on y=f(x)?',
 'График y=−f(−x) содержит точку (4,−7). Какая точка должна лежать на y=f(x)?',
 'y=−f(−x) grafigida (4,−7) nuqta yotadi. y=f(x) grafigida qaysi nuqta yotishi kerak?',
 '["(−4,7)","(4,7)","(−4,−7)","(7,−4)"]',
 '["(−4,7)","(4,7)","(−4,−7)","(7,−4)"]',
 '["(−4,7)","(4,7)","(−4,−7)","(7,−4)"]',
 'A',
 'The mapping from y=f(x) to y=−f(−x) changes the signs of both coordinates. Reversing it changes both signs again, so (4,−7) comes from (−4,7).',
 'При переходе от y=f(x) к y=−f(−x) знаки обеих координат меняются. При обратном переходе они снова меняются, поэтому (4,−7) получается из (−4,7).',
 'y=f(x) dan y=−f(−x) ga o‘tishda ikkala koordinataning ishorasi o‘zgaradi. Teskari o‘tishda ishoralar yana o‘zgaradi, demak (4,−7) nuqta (−4,7) dan kelib chiqadi.'),

('P1FUN08-R04',
 'The point (−6,15) lies on y=3f(x/2). Which corresponding point lies on y=f(x)?',
 'Точка (−6,15) лежит на y=3f(x/2). Какая соответствующая точка лежит на y=f(x)?',
 '(−6,15) nuqta y=3f(x/2) grafigida yotadi. y=f(x) grafigidagi mos nuqta qaysi?',
 '["(−3,5)","(−12,5)","(−3,45)","(−6,5)"]',
 '["(−3,5)","(−12,5)","(−3,45)","(−6,5)"]',
 '["(−3,5)","(−12,5)","(−3,45)","(−6,5)"]',
 'A',
 'From y=f(x) to y=3f(x/2), x-coordinates are multiplied by 2 and y-coordinates by 3. Reversing gives (−6/2,15/3)=(−3,5).',
 'При переходе от y=f(x) к y=3f(x/2) x-координаты умножаются на 2, а y-координаты — на 3. Обратное преобразование даёт (−6/2,15/3)=(−3,5).',
 'y=f(x) dan y=3f(x/2) ga o‘tishda x-koordinatalar 2 ga, y-koordinatalar 3 ga ko‘payadi. Teskari o‘tishda (−6/2,15/3)=(−3,5).'),

('P1COO01-R03',
 'A line passes through (4,0) and (2,6). It is written as y=mx+c. Enter c.',
 'Прямая проходит через (4,0) и (2,6). Она записана как y=mx+c. Введите c.',
 'To‘g‘ri chiziq (4,0) va (2,6) nuqtalardan o‘tadi. U y=mx+c ko‘rinishida yozilgan. c ni kiriting.',
 '[]','[]','[]','12',
 'The gradient is (6−0)/(2−4)=−3. Using (4,0), 0=−3·4+c, so c=12.',
 'Градиент равен (6−0)/(2−4)=−3. Подставляя (4,0): 0=−3·4+c, поэтому c=12.',
 'Gradient (6−0)/(2−4)=−3. (4,0) ni qo‘ysak, 0=−3·4+c, demak c=12.'),

('P1COO02-R04',
 'The midpoint of AB is M(−1,1). If A=(−7,5), what is B?',
 'Середина отрезка AB — M(−1,1). Если A=(−7,5), чему равна точка B?',
 'AB kesmaning o‘rta nuqtasi M(−1,1). Agar A=(−7,5) bo‘lsa, B nuqta qaysi?',
 '["(5,−3)","(−6,2)","(1,−1)","(−1,4)"]',
 '["(5,−3)","(−6,2)","(1,−1)","(−1,4)"]',
 '["(5,−3)","(−6,2)","(1,−1)","(−1,4)"]',
 'A',
 'Since M=(A+B)/2, B=2M−A. Thus B=(−2,2)−(−7,5)=(5,−3).',
 'Так как M=(A+B)/2, то B=2M−A. Поэтому B=(−2,2)−(−7,5)=(5,−3).',
 'M=(A+B)/2 bo‘lgani uchun B=2M−A. Demak B=(−2,2)−(−7,5)=(5,−3).'),

('P1COO03-R03',
 'The line through A(−2,4) and B(4,1) is perpendicular to a line through P(3,−1). Enter the y-intercept of the perpendicular line.',
 'Прямая через A(−2,4) и B(4,1) перпендикулярна прямой, проходящей через P(3,−1). Введите y-пересечение перпендикулярной прямой.',
 'A(−2,4) va B(4,1) dan o‘tuvchi chiziqqa P(3,−1) dan o‘tuvchi chiziq perpendikulyar. Perpendikulyar chiziqning y o‘qi bilan kesishish qiymatini kiriting.',
 '[]','[]','[]','-7',
 'AB has gradient (1−4)/(4−(−2))=−1/2, so the perpendicular gradient is 2. Through P, y+1=2(x−3), hence y=2x−7 and the y-intercept is −7.',
 'Градиент AB равен (1−4)/(4−(−2))=−1/2, поэтому градиент перпендикуляра равен 2. Через P: y+1=2(x−3), откуда y=2x−7 и y-пересечение равно −7.',
 'AB gradienti (1−4)/(4−(−2))=−1/2, shuning uchun perpendikulyar gradient 2. P orqali y+1=2(x−3), demak y=2x−7 va y o‘qi bilan kesishish qiymati −7.'),

('P1CIR01-R03',
 'An angle is 5π/18 radians plus 40°. Enter the total angle in degrees.',
 'Угол равен сумме 5π/18 радиан и 40°. Введите величину угла в градусах.',
 'Burchak 5π/18 radian va 40° yig‘indisiga teng. Umumiy burchakni graduslarda kiriting.',
 '[]','[]','[]','90',
 '5π/18 radians equals 50°. Adding 40° gives 90°.',
 '5π/18 радиан = 50°. Добавляем 40° и получаем 90°.',
 '5π/18 radian = 50°. 40° qo‘shsak, 90° hosil bo‘ladi.'),

('P1TRI01-R03',
 'The graph y=a cos x+2 has range −3≤y≤7, where a>0. Enter a.',
 'График y=a cos x+2 имеет область значений −3≤y≤7, где a>0. Введите a.',
 'y=a cos x+2 grafigining qiymatlar sohasi −3≤y≤7, bunda a>0. a ni kiriting.',
 '[]','[]','[]','5',
 'The midline is 2 and the distance from the midline to either endpoint of the range is 5, so the amplitude is a=5.',
 'Средняя линия равна 2, а расстояние от неё до любого конца области значений равно 5, поэтому амплитуда a=5.',
 'O‘rta chiziq 2, qiymatlar sohasi chetlarigacha masofa 5. Demak amplituda a=5.'),

('P5CNT01-R03',
 'From 9 students, a 4-person committee is selected. A chair and a secretary are then chosen from the committee. Enter the number of possible outcomes.',
 'Из 9 учеников выбирают комитет из 4 человек. Затем из членов комитета выбирают председателя и секретаря. Введите число возможных исходов.',
 '9 nafar o‘quvchidan 4 kishilik qo‘mita tanlanadi. So‘ng qo‘mita a’zolaridan rais va kotib tanlanadi. Mumkin bo‘lgan natijalar sonini kiriting.',
 '[]','[]','[]','1512',
 'There are 9C4=126 committees. For each committee the two distinct roles can be assigned in 4P2=12 ways, giving 126×12=1512.',
 'Комитет можно выбрать 9C4=126 способами. Для каждого комитета две разные роли распределяются 4P2=12 способами, итого 126×12=1512.',
 'Qo‘mitani 9C4=126 usulda tanlash mumkin. Har bir qo‘mitada ikki turli vazifa 4P2=12 usulda taqsimlanadi, jami 126×12=1512.'),

('P5CNT02-R04',
 'Four ordered positions are filled from n distinct candidates without repetition. There are 360 possible outcomes. What is n?',
 'Четыре упорядоченные позиции заполняют из n разных кандидатов без повторений. Всего возможно 360 исходов. Чему равно n?',
 'Takrorlanmasdan n ta turli nomzoddan 4 ta tartibli o‘rin to‘ldiriladi. Jami 360 ta natija mumkin. n nechaga teng?',
 '["5","6","7","8"]','["5","6","7","8"]','["5","6","7","8"]','B',
 'We need nP4=360. Since 6×5×4×3=360, n=6.',
 'Нужно nP4=360. Так как 6×5×4×3=360, получаем n=6.',
 'nP4=360 bo‘lishi kerak. 6×5×4×3=360, demak n=6.'),

('P5CNT03-R03',
 'For the multiset A,A,A,A,B,B,C,D, by what factor does 8! overcount the number of distinct arrangements?',
 'Для набора A,A,A,A,B,B,C,D во сколько раз величина 8! завышает число различных перестановок?',
 'A,A,A,A,B,B,C,D to‘plami uchun 8! turli tartiblar sonini necha marta ortiqcha sanaydi?',
 '[]','[]','[]','48',
 'Permuting the four identical A symbols and the two identical B symbols does not create new arrangements. The overcount factor is 4!×2!=48.',
 'Перестановки четырёх одинаковых A и двух одинаковых B не создают новых вариантов. Коэффициент лишнего подсчёта равен 4!×2!=48.',
 'To‘rtta bir xil A va ikkita bir xil B ning o‘zaro almashishi yangi tartib yaratmaydi. Ortiqcha sanash koeffitsiyenti 4!×2!=48.'),

('P5CNT04-R03',
 'Six distinct people stand in a row. A and B must occupy the two end positions, in either order. Enter the number of arrangements.',
 'Шесть разных людей стоят в ряд. A и B должны занять две крайние позиции в любом порядке. Введите число расстановок.',
 'Olti xil odam qatorga turadi. A va B ikki chekka o‘rinni istalgan tartibda egallashi kerak. Tartiblar sonini kiriting.',
 '[]','[]','[]','48',
 'A and B can occupy the two ends in 2 ways, and the other four people can be arranged in 4! ways. Total: 2×4!=48.',
 'A и B могут занять два края 2 способами, а остальных четырёх людей можно расположить 4! способами. Итого 2×4!=48.',
 'A va B ikki chekka o‘rinni 2 usulda egallaydi, qolgan to‘rt odam esa 4! usulda joylashadi. Jami 2×4!=48.'),

('P5PRO01-R03',
 'A fair coin and an independent fair spinner have 14 equiprobable ordered outcomes in total. Enter the number of sectors on the spinner.',
 'Честная монета и независимый честный диск вместе дают 14 равновероятных упорядоченных исходов. Введите число секторов диска.',
 'Adolatli tanga va mustaqil adolatli aylantirgich birgalikda 14 ta teng ehtimolli tartibli natija beradi. Aylantirgichdagi sektorlar sonini kiriting.',
 '[]','[]','[]','7',
 'The coin contributes 2 outcomes. If the spinner has n sectors, the product sample space has 2n outcomes. Thus 2n=14 and n=7.',
 'Монета даёт 2 исхода. Если у диска n секторов, пространство исходов содержит 2n исходов. Поэтому 2n=14 и n=7.',
 'Tanga 2 ta natija beradi. Aylantirgichda n ta sektor bo‘lsa, ko‘paytma namunalar fazosida 2n ta natija bo‘ladi. Demak 2n=14 va n=7.')
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
  on m.content_version_id in (4807,4808)
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
  and m.content_version_id in (4807,4808)
  and m.content_key in (
    'P1FUN06-R03','P1FUN07-R04','P1FUN08-R04',
    'P1COO01-R03','P1COO02-R04','P1COO03-R03',
    'P1CIR01-R03','P1TRI01-R03',
    'P5CNT01-R03','P5CNT02-R04','P5CNT03-R03',
    'P5CNT04-R03','P5PRO01-R03'
  );

do $postcheck$
declare v_bad int;
begin
  -- Lock the independently re-solved answer map for the corrected delayed retests.
  with expected(content_key,answer) as (values
    ('P1FUN06-R03','7'),
    ('P1FUN07-R04','A'),
    ('P1FUN08-R04','A'),
    ('P1COO01-R03','12'),
    ('P1COO02-R04','A'),
    ('P1COO03-R03','-7'),
    ('P1CIR01-R03','90'),
    ('P1TRI01-R03','5'),
    ('P5CNT01-R03','1512'),
    ('P5CNT02-R04','B'),
    ('P5CNT03-R03','48'),
    ('P5CNT04-R03','48'),
    ('P5PRO01-R03','7')
  )
  select count(*) into v_bad
  from expected e
  left join private.exam_prep_question_content_meta m
    on m.content_key=e.content_key and m.content_version_id in (4807,4808)
  left join public.questions q on q.id=m.question_id
  where q.id is null or q.correct_answer<>e.answer;
  if v_bad<>0 then
    raise exception 'aw05_08 annual reserve independent QA: corrected answer-map mismatch rows=%',v_bad;
  end if;

  -- All trilingual corrected surfaces remain complete.
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4807,4808)
    and m.content_key in (
      'P1FUN06-R03','P1FUN07-R04','P1FUN08-R04',
      'P1COO01-R03','P1COO02-R04','P1COO03-R03',
      'P1CIR01-R03','P1TRI01-R03',
      'P5CNT01-R03','P5CNT02-R04','P5CNT03-R03',
      'P5CNT04-R03','P5PRO01-R03'
    )
    and (
      nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
    );
  if v_bad<>0 then
    raise exception 'aw05_08 annual reserve independent QA: corrected trilingual surface incomplete rows=%',v_bad;
  end if;

  -- The stronger retests must not exactly reuse a published same-skill English stem.
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
    where m.content_version_id in (4807,4808)
      and m.content_key in (
        'P1FUN06-R03','P1FUN07-R04','P1FUN08-R04',
        'P1COO01-R03','P1COO02-R04','P1COO03-R03',
        'P1CIR01-R03','P1TRI01-R03',
        'P5CNT01-R03','P5CNT02-R04','P5CNT03-R03',
        'P5CNT04-R03','P5PRO01-R03'
      )
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then
    raise exception 'aw05_08 annual reserve independent QA: corrected retest exact published stem duplicate';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4807,4808)
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
    raise exception 'aw05_08 annual reserve independent QA: frozen snapshot mismatch rows=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4807,4808)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4807,4808)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4807,4808)
  ) then
    raise exception 'aw05_08 annual reserve independent QA: history appeared during correction';
  end if;

  if (select count(*) from private.exam_prep_content_versions
      where id in (4807,4808) and status='draft')<>2 then
    raise exception 'aw05_08 annual reserve independent QA: draft lifecycle changed';
  end if;
end
$postcheck$;

commit;
