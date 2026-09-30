-- AW17-20 supplemental learning independent QA corrections v1.
-- Draft/history-free content only. No publication or learner exposure.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4817,4818) and status='draft')<>2 then
    raise exception 'aw17_20 independent QA: target draft versions missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=4817)<>18
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4818)<>15
     or (select count(*) from private.exam_prep_written_tasks where content_version_id in (4817,4818))<>11
     or (select count(*) from private.exam_prep_written_understanding_checks c
         join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
         where wt.content_version_id in (4817,4818))<>11 then
    raise exception 'aw17_20 independent QA: candidate surface mismatch';
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4817,4818)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4817,4818)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4817,4818)
  ) then
    raise exception 'aw17_20 independent QA: draft has learner/legacy history';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4817,4818)
    and (m.lifecycle_state<>'draft' or m.exposure_state<>'withheld' or q.is_active or q.quality_status<>'draft');
  if v_bad<>0 then
    raise exception 'aw17_20 independent QA: draft exposure drift rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4817,4818)
        and content_key in ('P1SER03-A02','P1SER03-A03','P1SER04-A01','P1SER05-A01','P1SER05-A02','P1DIF02-A01','P1DIF02-A02','P1DIF03-A01','P1DIF03-A02','P1DIF04-A01','P5BIN03-A02','P5GEO02-A01','P5GEO03-A02','P5NOR01-A03'))<>14 then
    raise exception 'aw17_20 independent QA: correction targets missing';
  end if;
end
$preflight$;

with fixes(content_key,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz) as (values
('P1SER03-A02','An arithmetic progression has first term 4 and S₁₀=220. Find the common difference.','["2","3","5","4"]','D','S₁₀=10/2[2(4)+9d]=5(8+9d)=220. Hence 8+9d=44, so d=4.','В арифметической прогрессии первый член равен 4 и S₁₀=220. Найдите разность.','["2","3","5","4"]','S₁₀=10/2[2(4)+9d]=5(8+9d)=220. Поэтому 8+9d=44, значит d=4.','Arifmetik progressiyaning birinchi hadi 4 va S₁₀=220. Umumiy ayirmani toping.','["2","3","5","4"]','S₁₀=10/2[2(4)+9d]=5(8+9d)=220. Demak 8+9d=44, shuning uchun d=4.'),
('P1SER03-A03','In an arithmetic progression, u₃=11 and u₈=31. Enter the first term.','[]','3','u₈−u₃=5d=20, so d=4. Then u₃=a+2d=11 gives a=3.','В арифметической прогрессии u₃=11 и u₈=31. Введите первый член.','[]','u₈−u₃=5d=20, поэтому d=4. Затем u₃=a+2d=11 даёт a=3.','Arifmetik progressiyada u₃=11 va u₈=31. Birinchi hadni kiriting.','[]','u₈−u₃=5d=20, demak d=4. So‘ng u₃=a+2d=11 dan a=3.'),
('P1SER04-A01','A geometric progression has u₂=10 and u₄=40, with positive common ratio. Find the first term.','["5","2","10","20"]','A','u₄/u₂=r²=40/10=4. Since r>0, r=2. Then u₂=ar=10 gives a=5.','В геометрической прогрессии u₂=10 и u₄=40, а знаменатель положительный. Найдите первый член.','["5","2","10","20"]','u₄/u₂=r²=40/10=4. Так как r>0, r=2. Затем u₂=ar=10 даёт a=5.','Geometrik progressiyada u₂=10 va u₄=40, umumiy maxraj musbat. Birinchi hadni toping.','["5","2","10","20"]','u₄/u₂=r²=40/10=4. r>0 bo‘lgani uchun r=2. So‘ng u₂=ar=10 dan a=5.'),
('P1SER05-A01','Which geometric series has a finite sum to infinity?','["4+8+16+...","6−7.2+8.64−...","10−5+2.5−...","3+3+3+..."]','C','A geometric series has a finite sum to infinity only when |r|<1. The ratios are 2, −1.2, −0.5 and 1 respectively, so only the third series converges.','Какой геометрический ряд имеет конечную сумму до бесконечности?','["4+8+16+...","6−7,2+8,64−...","10−5+2,5−...","3+3+3+..."]','Геометрический ряд имеет конечную сумму до бесконечности только при |r|<1. Знаменатели равны 2, −1,2, −0,5 и 1 соответственно, поэтому сходится только третий ряд.','Qaysi geometrik qatorning chekli cheksiz yig‘indisi mavjud?','["4+8+16+...","6−7.2+8.64−...","10−5+2.5−...","3+3+3+..."]','Geometrik qatorning chekli cheksiz yig‘indisi faqat |r|<1 bo‘lganda mavjud. Maxrajlar mos ravishda 2, −1.2, −0.5 va 1, shuning uchun faqat uchinchi qator yaqinlashadi.'),
('P1SER05-A02','A convergent geometric series has first term 18. The sum of all terms after the first term is 12. Find the common ratio.','["−0.4","0.6","2/3","0.4"]','D','The total sum to infinity is 18+12=30. Thus 30=18/(1−r), so 1−r=0.6 and r=0.4.','У сходящегося геометрического ряда первый член равен 18. Сумма всех членов после первого равна 12. Найдите знаменатель.','["−0,4","0,6","2/3","0,4"]','Полная сумма до бесконечности равна 18+12=30. Поэтому 30=18/(1−r), откуда 1−r=0,6 и r=0,4.','Yaqinlashuvchi geometrik qatorning birinchi hadi 18. Birinchi haddan keyingi barcha hadlar yig‘indisi 12. Umumiy maxrajni toping.','["−0.4","0.6","2/3","0.4"]','Cheksiz umumiy yig‘indi 18+12=30. Demak 30=18/(1−r), bundan 1−r=0.6 va r=0.4.'),
('P1DIF02-A01','The derivative of y=kx^(3/2) is 12x^(1/2). Find k.','["8","6","12","18"]','A','dy/dx=(3k/2)x^(1/2). Hence 3k/2=12, so k=8.','Производная y=kx^(3/2) равна 12x^(1/2). Найдите k.','["8","6","12","18"]','dy/dx=(3k/2)x^(1/2). Поэтому 3k/2=12, значит k=8.','y=kx^(3/2) funksiyaning hosilasi 12x^(1/2) ga teng. k ni toping.','["8","6","12","18"]','dy/dx=(3k/2)x^(1/2). Demak 3k/2=12, shuning uchun k=8.'),
('P1DIF02-A02','For y=ax^(3/2), the gradient at x=4 is 9. Find a.','["2","3","4","6"]','B','dy/dx=(3a/2)x^(1/2). At x=4, the gradient is (3a/2)×2=3a. Hence 3a=9 and a=3.','Для y=ax^(3/2) градиент при x=4 равен 9. Найдите a.','["2","3","4","6"]','dy/dx=(3a/2)x^(1/2). При x=4 градиент равен (3a/2)×2=3a. Поэтому 3a=9 и a=3.','y=ax^(3/2) uchun x=4 dagi gradient 9 ga teng. a ni toping.','["2","3","4","6"]','dy/dx=(3a/2)x^(1/2). x=4 da gradient (3a/2)×2=3a. Demak 3a=9 va a=3.'),
('P1DIF03-A01','A student differentiates y=(2x+3)^4 as 4(2x+3)^3. Which is the correct derivative?','["4(2x+3)^3","6(2x+3)^3","8(2x+3)^3","8(2x+3)^4"]','C','The outer derivative is 4(2x+3)^3 and the inner derivative is 2. By the chain rule, dy/dx=8(2x+3)^3.','Ученик дифференцирует y=(2x+3)^4 как 4(2x+3)^3. Какая производная верна?','["4(2x+3)^3","6(2x+3)^3","8(2x+3)^3","8(2x+3)^4"]','Производная внешней функции равна 4(2x+3)^3, а внутренней — 2. По правилу цепочки dy/dx=8(2x+3)^3.','O‘quvchi y=(2x+3)^4 ni 4(2x+3)^3 deb differensiallagan. Qaysi hosila to‘g‘ri?','["4(2x+3)^3","6(2x+3)^3","8(2x+3)^3","8(2x+3)^4"]','Tashqi funksiya hosilasi 4(2x+3)^3, ichki funksiya hosilasi esa 2. Zanjir qoidasiga ko‘ra dy/dx=8(2x+3)^3.'),
('P1DIF03-A02','For y=(ax+1)^4, the value of dy/dx at x=0 is 12. Find a.','["1/3","4","12","3"]','D','dy/dx=4a(ax+1)^3. At x=0 this is 4a, so 4a=12 and a=3.','Для y=(ax+1)^4 значение dy/dx при x=0 равно 12. Найдите a.','["1/3","4","12","3"]','dy/dx=4a(ax+1)^3. При x=0 это 4a, поэтому 4a=12 и a=3.','y=(ax+1)^4 uchun x=0 dagi dy/dx qiymati 12 ga teng. a ni toping.','["1/3","4","12","3"]','dy/dx=4a(ax+1)^3. x=0 da bu 4a, demak 4a=12 va a=3.'),
('P1DIF04-A01','For y=x³−3x, the tangent at x=2 has equation y=9x+c. Find c.','["−16","−14","2","16"]','A','At x=2 the point is (2,2), and dy/dx=3x²−3 gives gradient 9. Hence 2=9(2)+c, so c=−16.','Для y=x³−3x касательная при x=2 имеет уравнение y=9x+c. Найдите c.','["−16","−14","2","16"]','При x=2 точка равна (2,2), а dy/dx=3x²−3 даёт градиент 9. Поэтому 2=9(2)+c, значит c=−16.','y=x³−3x uchun x=2 dagi urinma y=9x+c tenglamaga ega. c ni toping.','["−16","−14","2","16"]','x=2 da nuqta (2,2), dy/dx=3x²−3 esa 9 gradientni beradi. Demak 2=9(2)+c, shuning uchun c=−16.'),
('P5BIN03-A02','For a binomial random variable, E(X)=24 and Var(X)=14.4. Find 1−p.','["0.2","0.4","0.6","0.8"]','C','For a binomial variable, Var(X)/E(X)=1−p. Thus 1−p=14.4/24=0.6.','Для биномиальной случайной величины E(X)=24 и Var(X)=14,4. Найдите 1−p.','["0,2","0,4","0,6","0,8"]','Для биномиальной величины Var(X)/E(X)=1−p. Поэтому 1−p=14,4/24=0,6.','Binomial tasodifiy kattalik uchun E(X)=24 va Var(X)=14.4. 1−p ni toping.','["0.2","0.4","0.6","0.8"]','Binomial kattalik uchun Var(X)/E(X)=1−p. Demak 1−p=14.4/24=0.6.'),
('P5GEO02-A01','For geometric X with success probability p=1/4, find P(X≤4).','["175/256","81/256","27/64","3/4"]','A','P(X≤4)=1−P(X>4)=1−(3/4)^4=1−81/256=175/256.','Для геометрической X с вероятностью успеха p=1/4 найдите P(X≤4).','["175/256","81/256","27/64","3/4"]','P(X≤4)=1−P(X>4)=1−(3/4)^4=1−81/256=175/256.','p=1/4 muvaffaqiyat ehtimolli geometrik X uchun P(X≤4) ni toping.','["175/256","81/256","27/64","3/4"]','P(X≤4)=1−P(X>4)=1−(3/4)^4=1−81/256=175/256.'),
('P5GEO03-A02','A geometric waiting-time model has p=0.20. If p increases to 0.40, which pair gives the old and new expected trial numbers, respectively?','["4 and 2.5","5 and 2.5","5 and 4","2.5 and 5"]','B','For the trial-number convention, E(X)=1/p. The old expectation is 1/0.20=5 and the new expectation is 1/0.40=2.5.','В геометрической модели времени ожидания p=0,20. Если p увеличивается до 0,40, какая пара задаёт старый и новый ожидаемые номера испытания соответственно?','["4 и 2,5","5 и 2,5","5 и 4","2,5 и 5"]','Для соглашения с номером испытания E(X)=1/p. Старое ожидание равно 1/0,20=5, новое — 1/0,40=2,5.','Geometrik kutish modelida p=0.20. Agar p 0.40 gacha oshsa, qaysi juftlik mos ravishda eski va yangi kutiladigan sinov raqamlarini beradi?','["4 va 2.5","5 va 2.5","5 va 4","2.5 va 5"]','Sinov raqami konvensiyasida E(X)=1/p. Eski kutilma 1/0.20=5, yangi kutilma 1/0.40=2.5.'),
('P5NOR01-A03','A normal model has mean 100 and standard deviation 12. It is written as Y~N(100,k). Enter k.','[]','144','In the notation N(μ,σ²), the second parameter is the variance. Thus k=12²=144.','Нормальная модель имеет среднее 100 и стандартное отклонение 12. Она записана как Y~N(100,k). Введите k.','[]','В записи N(μ,σ²) второй параметр — дисперсия. Поэтому k=12²=144.','Normal modelning o‘rtachasi 100 va standart og‘ishi 12. U Y~N(100,k) ko‘rinishida yozilgan. k ni kiriting.','[]','N(μ,σ²) yozuvida ikkinchi parametr dispersiya. Demak k=12²=144.')
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
  on m.content_version_id in (4817,4818)
 and m.content_key=f.content_key
where q.id=m.question_id
  and q.is_active=false
  and q.quality_status='draft';

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
  and m.content_version_id in (4817,4818)
  and m.content_key in ('P1SER03-A02','P1SER03-A03','P1SER04-A01','P1SER05-A01','P1SER05-A02','P1DIF02-A01','P1DIF02-A02','P1DIF03-A01','P1DIF03-A02','P1DIF04-A01','P5BIN03-A02','P5GEO02-A01','P5GEO03-A02','P5NOR01-A03');

do $postcheck$
declare
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4817,4818)
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
  if v_bad<>0 then raise exception 'aw17_20 independent QA: trilingual/type rows=%',v_bad; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4817;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(3,3,3,3,6) then
    raise exception 'aw17_20 independent QA: P1 answer balance mismatch A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4818;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(2,2,3,3,5) then
    raise exception 'aw17_20 independent QA: P5 answer balance mismatch A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
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
    where m.content_version_id in (4817,4818)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then
    raise exception 'aw17_20 independent QA: exact published stem duplicate';
  end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4817 and m.content_key='P1SER03-A02'
      and q.question_text_en like '%S₁₀=220%' and q.correct_answer='D'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4817 and m.content_key='P1DIF03-A01'
      and q.question_text_en like '%student differentiates%' and q.correct_answer='C'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4818 and m.content_key='P5BIN03-A02'
      and q.question_text_en like '%E(X)=24%' and q.correct_answer='C'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4818 and m.content_key='P5NOR01-A03'
      and q.question_text_en like '%standard deviation 12%' and q.correct_answer='144'
  ) then
    raise exception 'aw17_20 independent QA: corrected transfer surface missing';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4817,4818)
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
  if v_bad<>0 then raise exception 'aw17_20 independent QA: frozen snapshot mismatch rows=%',v_bad; end if;

  -- Written arithmetic and scope pins from the second academic pass.
  if not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15653 and content_version_id=4817
      and (rubric_json->'criteria'->4->>'rule') like '%S30=1800%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15654 and content_version_id=4817
      and (rubric_json->'criteria'->4->>'rule') like '%S8=1530%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15656 and content_version_id=4817
      and (rubric_json->'criteria'->4->>'rule') like '%89/8%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15660 and content_version_id=4818
      and (rubric_json->'criteria'->2->>'rule') like '%n=50%'
  ) or not exists(
    select 1 from private.exam_prep_written_tasks
    where id=15663 and content_version_id=4818
      and (rubric_json->'criteria'->4->>'rule') like '%496 and 504%'
  ) then
    raise exception 'aw17_20 independent QA: written arithmetic/scope pin missing';
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_tasks wt
  left join private.exam_prep_written_understanding_checks c on c.written_task_id=wt.id
  where wt.content_version_id in (4817,4818)
    and (
      wt.lifecycle_state<>'draft'
      or coalesce((wt.rubric_json->>'max_marks')::int,0)<>6
      or nullif(btrim(wt.prompt_en),'') is null
      or nullif(btrim(wt.prompt_ru),'') is null
      or nullif(btrim(wt.prompt_uz),'') is null
      or c.id is null
      or c.lifecycle_state<>'draft'
      or jsonb_array_length(c.options_en)<>4
      or jsonb_array_length(c.options_ru)<>4
      or jsonb_array_length(c.options_uz)<>4
      or c.correct_index not between 0 and 3
    );
  if v_bad<>0 then raise exception 'aw17_20 independent QA: written/check review rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4817,4818)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4817,4818)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4817,4818)
  ) then
    raise exception 'aw17_20 independent QA: history appeared during correction';
  end if;
end
$postcheck$;

commit;
