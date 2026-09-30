-- AW17-20 annual reserve independent QA corrections v1.
-- Draft/history-free reserve content only. No publication or learner exposure.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4819,4820) and status='draft')<>2
  then raise exception 'aw17_20 reserve independent QA: target draft versions missing'; end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4819,4820))<>55
  then raise exception 'aw17_20 reserve independent QA: candidate surface mismatch'; end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4819,4820) and content_key in ('P1DIF03-D02','P1DIF03-R04','P1DIF04-R04','P5BIN02-R04','P5GEO02-D02','P5GEO02-R04','P5GEO03-D02','P5BIN03-R04','P5BIN02-D03','P1SER03-R04','P1DIF04-D02','P5BIN03-D02','P1SER03-D03','P1SER05-R04','P1SER05-D02','P5BIN02-D02','P1SER05-R03','P5NOR01-D02','P1DIF04-D03','P5GEO03-D03','P5GEO03-R04'))<>21
  then raise exception 'aw17_20 reserve independent QA: correction targets missing'; end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4819,4820)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4819,4820)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4819,4820)
  ) then raise exception 'aw17_20 reserve independent QA: draft has learner/legacy history'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4819,4820)
    and (m.lifecycle_state<>'draft' or m.exposure_state<>'withheld' or q.is_active or q.quality_status<>'draft');
  if v_bad<>0 then raise exception 'aw17_20 reserve independent QA: exposure boundary drift rows=%',v_bad; end if;
end
$preflight$;

with fixes(content_key,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz) as (values
('P1DIF03-D02','mcq','A student differentiates y=(3x−2)^5 and writes 5(3x−2)^4. Which missing factor makes the derivative correct?','["3","5","−2","15"]','A','The inner derivative is 3. By the chain rule, dy/dx=5(3x−2)^4×3=15(3x−2)^4.','Ученик дифференцирует y=(3x−2)^5 и записывает 5(3x−2)^4. Какой пропущенный множитель делает производную верной?','["3","5","−2","15"]','Производная внутреннего выражения равна 3. По правилу цепочки dy/dx=5(3x−2)^4×3=15(3x−2)^4.','O‘quvchi y=(3x−2)^5 ni differensiallab, 5(3x−2)^4 deb yozdi. Qaysi yetishmayotgan ko‘paytuvchi hosilani to‘g‘ri qiladi?','["3","5","−2","15"]','Ichki ifodaning hosilasi 3. Zanjir qoidasiga ko‘ra dy/dx=5(3x−2)^4×3=15(3x−2)^4.'),
('P1DIF03-R04','input','For y=(5−2x)^(−1), enter the value of dy/dx at x=2.','[]','2','dy/dx=2(5−2x)^(−2). At x=2, this is 2(1)^(−2)=2.','Для y=(5−2x)^(−1) введите значение dy/dx при x=2.','[]','dy/dx=2(5−2x)^(−2). При x=2 это 2(1)^(−2)=2.','y=(5−2x)^(−1) uchun x=2 dagi dy/dx qiymatini kiriting.','[]','dy/dx=2(5−2x)^(−2). x=2 da bu 2(1)^(−2)=2.'),
('P1DIF04-R04','input','For y=x^2, the normal at x=−1 crosses the y-axis at y=b. Enter b as an exact fraction.','[]','3/2','At x=−1, the tangent gradient is −2, so the normal gradient is 1/2. Through (−1,1), y−1=(1/2)(x+1), hence b=3/2.','Для y=x^2 нормаль при x=−1 пересекает ось y в точке y=b. Введите b в виде точной дроби.','[]','При x=−1 градиент касательной равен −2, поэтому градиент нормали равен 1/2. Через точку (−1,1): y−1=(1/2)(x+1), значит b=3/2.','y=x^2 uchun x=−1 dagi normal y o‘qini y=b nuqtada kesadi. b ni aniq kasr ko‘rinishida kiriting.','[]','x=−1 da urinma gradienti −2, demak normal gradienti 1/2. (−1,1) nuqta orqali y−1=(1/2)(x+1), shuning uchun b=3/2.'),
('P5BIN02-R04','input','Eight independent sensors each fail with probability 0.1. Enter the probability that at most one sensor fails, to 4 decimal places.','[]','0.8131','Let X be the number of failed sensors. Then X~B(8,0.1) and P(X≤1)=0.9^8+8(0.1)(0.9)^7=0.81310473, so 0.8131.','Каждый из 8 независимых датчиков выходит из строя с вероятностью 0,1. Введите вероятность того, что выйдет из строя не более одного датчика, с точностью до 4 знаков.','[]','Пусть X — число вышедших из строя датчиков. Тогда X~B(8,0,1) и P(X≤1)=0,9^8+8(0,1)(0,9)^7=0,81310473, поэтому 0,8131.','8 ta mustaqil sensorning har biri 0.1 ehtimol bilan ishdan chiqadi. Ko‘pi bilan bitta sensor ishdan chiqish ehtimolini 4 ta o‘nli xonagacha kiriting.','[]','X — ishdan chiqqan sensorlar soni bo‘lsin. X~B(8,0.1) va P(X≤1)=0.9^8+8(0.1)(0.9)^7=0.81310473, demak 0.8131.'),
('P5GEO02-D02','mcq','In independent trials with success probability 0.2, the first success occurs on trial 3. Which product represents this probability?','["(0.8)^2(0.2)","(0.8)^3","(0.2)^2(0.8)","3(0.8)^2(0.2)"]','A','The first two trials must fail and the third must succeed, so the probability is (0.8)^2(0.2).','В независимых испытаниях вероятность успеха равна 0,2, а первый успех происходит в 3-м испытании. Какое произведение задаёт эту вероятность?','["(0,8)^2(0,2)","(0,8)^3","(0,2)^2(0,8)","3(0,8)^2(0,2)"]','Первые два испытания должны быть неудачными, а третье — успешным, поэтому вероятность равна (0,8)^2(0,2).','Mustaqil sinovlarda muvaffaqiyat ehtimoli 0.2 va birinchi muvaffaqiyat 3-sinovda sodir bo‘ladi. Qaysi ko‘paytma bu ehtimolni ifodalaydi?','["(0.8)^2(0.2)","(0.8)^3","(0.2)^2(0.8)","3(0.8)^2(0.2)"]','Dastlabki ikki sinov muvaffaqiyatsiz, uchinchi sinov muvaffaqiyatli bo‘lishi kerak, demak ehtimol (0.8)^2(0.2).'),
('P5GEO02-R04','input','For geometric X with p=1/4, given that X>1, enter P(X≤3 | X>1) as an exact fraction.','[]','7/16','Given X>1, trial 1 has failed. A success by trial 3 then means success on trial 2 or 3, so the conditional probability is 1−(3/4)^2=7/16.','Для геометрической X с p=1/4 известно, что X>1. Введите P(X≤3 | X>1) в виде точной дроби.','[]','При условии X>1 первое испытание было неудачным. Успех не позднее 3-го испытания означает успех во 2-м или 3-м испытании, поэтому условная вероятность равна 1−(3/4)^2=7/16.','p=1/4 bo‘lgan geometrik X uchun X>1 ma’lum. P(X≤3 | X>1) ni aniq kasr ko‘rinishida kiriting.','[]','X>1 shartida 1-sinov muvaffaqiyatsiz bo‘lgan. 3-sinovgacha muvaffaqiyat 2- yoki 3-sinovda muvaffaqiyatni anglatadi, shuning uchun shartli ehtimol 1−(3/4)^2=7/16.'),
('P5GEO03-D02','mcq','A quality check is repeated independently until the first acceptable item. The long-run average trial number of the first acceptable item is 5. Which success probability p is consistent with this geometric model?','["0.5","0.25","0.2","0.05"]','C','For a geometric trial-number variable, E(X)=1/p. Hence p=1/5=0.2.','Проверку качества независимо повторяют до первого подходящего изделия. Долгосрочный средний номер испытания первого подходящего изделия равен 5. Какая вероятность успеха p соответствует этой геометрической модели?','["0,5","0,25","0,2","0,05"]','Для геометрической величины, считающей номер испытания, E(X)=1/p. Поэтому p=1/5=0,2.','Sifat tekshiruvi birinchi yaroqli mahsulotgacha mustaqil takrorlanadi. Birinchi yaroqli mahsulotning uzoq muddatli o‘rtacha sinov raqami 5. Qaysi p muvaffaqiyat ehtimoli bu geometrik modelga mos?','["0.5","0.25","0.2","0.05"]','Sinov raqamini sanaydigan geometrik kattalik uchun E(X)=1/p. Demak p=1/5=0.2.'),
('P5BIN03-R04','input','If X~B(32,0.25), enter Var(X).','[]','6','Var(X)=np(1−p)=32(0.25)(0.75)=6.','Если X~B(32,0,25), введите Var(X).','[]','Var(X)=np(1−p)=32(0,25)(0,75)=6.','Agar X~B(32,0.25) bo‘lsa, Var(X) ni kiriting.','[]','Var(X)=np(1−p)=32(0.25)(0.75)=6.'),
('P5BIN02-D03','mcq','Six independent components each pass a test with probability 0.4. What is the probability that exactly two components pass, to 4 decimal places?','["0.1866","0.3119","0.3110","0.4000"]','C','Let X be the number that pass. X~B(6,0.4), so P(X=2)=6C2(0.4)^2(0.6)^4=0.31104, which rounds to 0.3110.','Каждый из 6 независимых компонентов проходит тест с вероятностью 0,4. Какова вероятность того, что ровно 2 компонента пройдут тест, с точностью до 4 знаков?','["0,1866","0,3119","0,3110","0,4000"]','Пусть X — число прошедших тест компонентов. X~B(6,0,4), поэтому P(X=2)=6C2(0,4)^2(0,6)^4=0,31104, что округляется до 0,3110.','6 ta mustaqil komponentning har biri 0.4 ehtimol bilan sinovdan o‘tadi. Aynan 2 ta komponent sinovdan o‘tish ehtimoli 4 ta o‘nli xonagacha qancha?','["0.1866","0.3119","0.3110","0.4000"]','X — sinovdan o‘tgan komponentlar soni bo‘lsin. X~B(6,0.4), demak P(X=2)=6C2(0.4)^2(0.6)^4=0.31104, 4 ta o‘nli xonagacha 0.3110.'),
('P1SER03-R04','input','For an arithmetic progression, S10=230 and S9=189. Enter u10.','[]','41','The tenth term is the increase in the partial sum: u10=S10−S9=230−189=41.','Для арифметической прогрессии S10=230 и S9=189. Введите u10.','[]','Десятый член равен увеличению частичной суммы: u10=S10−S9=230−189=41.','Arifmetik progressiya uchun S10=230 va S9=189. u10 ni kiriting.','[]','O‘ninchi had qisman yig‘indilar farqiga teng: u10=S10−S9=230−189=41.'),
('P1DIF04-D02','mcq','For y=x^2+4x, the tangent at x=1 is written y=mx+c. Which pair (m,c) is correct?','["(5,0)","(6,−1)","(6,1)","(5,1)"]','B','At x=1, y=5 and dy/dx=2x+4=6, so m=6. From 5=6(1)+c, c=−1.','Для y=x^2+4x касательная при x=1 записана как y=mx+c. Какая пара (m,c) верна?','["(5,0)","(6,−1)","(6,1)","(5,1)"]','При x=1 имеем y=5 и dy/dx=2x+4=6, поэтому m=6. Из 5=6(1)+c получаем c=−1.','y=x^2+4x uchun x=1 dagi urinma y=mx+c ko‘rinishida yozilgan. Qaysi (m,c) juftlik to‘g‘ri?','["(5,0)","(6,−1)","(6,1)","(5,1)"]','x=1 da y=5 va dy/dx=2x+4=6, demak m=6. 5=6(1)+c dan c=−1.'),
('P5BIN03-D02','mcq','For a non-degenerate binomial random variable X, Var(X)/E(X)=0.8. Which value of p is consistent with X~B(n,p)?','["0.8","0.2","0.64","0.1"]','B','For a binomial variable, Var(X)/E(X)=np(1−p)/(np)=1−p. Hence 1−p=0.8 and p=0.2.','Для невырожденной биномиальной случайной величины X отношение Var(X)/E(X)=0,8. Какое значение p соответствует X~B(n,p)?','["0,8","0,2","0,64","0,1"]','Для биномиальной величины Var(X)/E(X)=np(1−p)/(np)=1−p. Поэтому 1−p=0,8 и p=0,2.','Nolga aynan teng bo‘lmagan binomial X tasodifiy kattalik uchun Var(X)/E(X)=0.8. X~B(n,p) ga qaysi p qiymati mos?','["0.8","0.2","0.64","0.1"]','Binomial kattalik uchun Var(X)/E(X)=np(1−p)/(np)=1−p. Demak 1−p=0.8 va p=0.2.'),
('P1SER03-D03','mcq','An arithmetic progression starts with 7 and increases by 3 each term. What is the 12th term?','["37","43","40","33"]','C','u12=7+11(3)=40.','Арифметическая прогрессия начинается с 7, и каждый следующий член увеличивается на 3. Чему равен 12-й член?','["37","43","40","33"]','u12=7+11(3)=40.','Arifmetik progressiya 7 dan boshlanadi va har bir keyingi had 3 ga oshadi. 12-had qancha?','["37","43","40","33"]','u12=7+11(3)=40.'),
('P1SER05-R04','input','A convergent geometric series has first term 12 and sum to infinity 30. Enter the sum of all terms after the first two terms.','[]','10.8','From 30=12/(1−r), r=0.6. The second term is 7.2, so the remaining tail is 30−12−7.2=10.8.','Сходящийся геометрический ряд имеет первый член 12 и сумму до бесконечности 30. Введите сумму всех членов после первых двух.','[]','Из 30=12/(1−r) получаем r=0,6. Второй член равен 7,2, поэтому оставшийся хвост равен 30−12−7,2=10,8.','Yaqinlashuvchi geometrik qatorning birinchi hadi 12 va cheksiz yig‘indisi 30. Dastlabki ikki haddan keyingi barcha hadlar yig‘indisini kiriting.','[]','30=12/(1−r) dan r=0.6. Ikkinchi had 7.2, demak qolgan dum 30−12−7.2=10.8.'),
('P1SER05-D02','mcq','A geometric series begins 18+6+2+.... What is its sum to infinity?','["27","24","26","30"]','A','The common ratio is 1/3, so S∞=18/(1−1/3)=27.','Геометрический ряд начинается как 18+6+2+.... Чему равна его сумма до бесконечности?','["27","24","26","30"]','Знаменатель равен 1/3, поэтому S∞=18/(1−1/3)=27.','Geometrik qator 18+6+2+... ko‘rinishida boshlanadi. Uning cheksiz yig‘indisi qancha?','["27","24","26","30"]','Umumiy maxraj 1/3, demak S∞=18/(1−1/3)=27.'),
('P5BIN02-D02','mcq','Eight independent trials each have success probability 0.25. What is the probability of at least one success, to 4 decimal places?','["0.8999","0.1001","0.7500","0.2500"]','A','P(at least one)=1−P(no successes)=1−0.75^8=0.899887..., so 0.8999.','В 8 независимых испытаниях вероятность успеха в каждом равна 0,25. Какова вероятность хотя бы одного успеха с точностью до 4 знаков?','["0,8999","0,1001","0,7500","0,2500"]','P(хотя бы один)=1−P(ни одного успеха)=1−0,75^8=0,899887..., поэтому 0,8999.','8 ta mustaqil sinovning har birida muvaffaqiyat ehtimoli 0.25. Kamida bitta muvaffaqiyat ehtimoli 4 ta o‘nli xonagacha qancha?','["0.8999","0.1001","0.7500","0.2500"]','P(kamida bittasi)=1−P(hech qanday muvaffaqiyat)=1−0.75^8=0.899887..., demak 0.8999.'),
('P1SER05-R03','input','A convergent geometric series has first term 20 and common ratio −1/4. Enter the sum of all terms after the first term.','[]','-4','The whole sum is 20/(1+1/4)=16. Removing the first term gives 16−20=−4. Equivalently, the tail starts at −5 with ratio −1/4 and sums to −4.','Сходящийся геометрический ряд имеет первый член 20 и знаменатель −1/4. Введите сумму всех членов после первого.','[]','Полная сумма равна 20/(1+1/4)=16. После удаления первого члена получаем 16−20=−4. Эквивалентно, хвост начинается с −5 и имеет знаменатель −1/4, его сумма равна −4.','Yaqinlashuvchi geometrik qatorning birinchi hadi 20 va umumiy maxraji −1/4. Birinchi haddan keyingi barcha hadlar yig‘indisini kiriting.','[]','Umumiy yig‘indi 20/(1+1/4)=16. Birinchi hadni ayirsak 16−20=−4. Yoki dum −5 dan boshlanib, maxraji −1/4 bo‘lib, yig‘indisi −4.'),
('P5NOR01-D02','mcq','A normal model is written X~N(60,9). Which pair marks the points one standard deviation below and above the mean?','["57 and 63","51 and 69","59 and 61","60 and 69"]','A','The variance is 9, so σ=3. The one-standard-deviation points are 60−3=57 and 60+3=63.','Нормальная модель записана как X~N(60,9). Какая пара задаёт точки на одно стандартное отклонение ниже и выше среднего?','["57 и 63","51 и 69","59 и 61","60 и 69"]','Дисперсия равна 9, поэтому σ=3. Точки на одно стандартное отклонение: 60−3=57 и 60+3=63.','Normal model X~N(60,9) ko‘rinishida yozilgan. Qaysi juftlik o‘rtachadan bitta standart og‘ish past va yuqori nuqtalarni beradi?','["57 va 63","51 va 69","59 va 61","60 va 69"]','Dispersiya 9, demak σ=3. Bitta standart og‘ish nuqtalari 60−3=57 va 60+3=63.'),
('P1DIF04-D03','mcq','At x=1 on the curve y=x^3, the tangent gradient is 3. What is the gradient of the normal?','["3","1/3","−3","−1/3"]','D','For perpendicular non-vertical lines, the gradients multiply to −1. Hence the normal gradient is −1/3.','На кривой y=x^3 при x=1 градиент касательной равен 3. Каков градиент нормали?','["3","1/3","−3","−1/3"]','Для перпендикулярных невертикальных прямых произведение градиентов равно −1. Поэтому градиент нормали равен −1/3.','y=x^3 egri chizig‘ida x=1 da urinma gradienti 3. Normal gradienti qancha?','["3","1/3","−3","−1/3"]','Perpendikulyar, vertikal bo‘lmagan chiziqlar gradientlari ko‘paytmasi −1. Demak normal gradienti −1/3.'),
('P5GEO03-D03','mcq','Which pair (p,E(X)) is consistent with a geometric trial-number model?','["(0.125,0.125)","(0.125,4)","(0.125,6)","(0.125,8)"]','D','For a geometric trial-number variable, E(X)=1/p. With p=0.125=1/8, E(X)=8.','Какая пара (p,E(X)) соответствует геометрической модели номера испытания?','["(0,125; 0,125)","(0,125; 4)","(0,125; 6)","(0,125; 8)"]','Для геометрической величины, считающей номер испытания, E(X)=1/p. При p=0,125=1/8 получаем E(X)=8.','Qaysi (p,E(X)) juftlik sinov raqamini sanaydigan geometrik modelga mos?','["(0.125,0.125)","(0.125,4)","(0.125,6)","(0.125,8)"]','Sinov raqamini sanaydigan geometrik kattalik uchun E(X)=1/p. p=0.125=1/8 bo‘lsa, E(X)=8.'),
('P5GEO03-R04','input','Independent trials continue until the first success. Each trial takes 2 minutes and the expected total time is 10 minutes. Enter the success probability p.','[]','0.2','The expected number of trials is 10/2=5. Since E(X)=1/p, p=1/5=0.2.','Независимые испытания продолжаются до первого успеха. Каждое испытание занимает 2 минуты, а ожидаемое общее время равно 10 минут. Введите вероятность успеха p.','[]','Ожидаемое число испытаний равно 10/2=5. Так как E(X)=1/p, p=1/5=0,2.','Mustaqil sinovlar birinchi muvaffaqiyatgacha davom etadi. Har bir sinov 2 daqiqa, kutiladigan umumiy vaqt 10 daqiqa. Muvaffaqiyat ehtimoli p ni kiriting.','[]','Kutiladigan sinovlar soni 10/2=5. E(X)=1/p bo‘lgani uchun p=1/5=0.2.')
)
update public.questions q
set qtype=f.qtype,
    question_text=f.q_en,
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
  on m.content_version_id in (4819,4820)
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
  and m.content_version_id in (4819,4820)
  and m.content_key in ('P1DIF03-D02','P1DIF03-R04','P1DIF04-R04','P5BIN02-R04','P5GEO02-D02','P5GEO02-R04','P5GEO03-D02','P5BIN03-R04','P5BIN02-D03','P1SER03-R04','P1DIF04-D02','P5BIN03-D02','P1SER03-D03','P1SER05-R04','P1SER05-D02','P5BIN02-D02','P1SER05-R03','P5NOR01-D02','P1DIF04-D03','P5GEO03-D03','P5GEO03-R04');

do $postcheck$
declare
  v_bad int;
  v_a int; v_b int; v_c int; v_d int;
begin
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4819,4820)
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
  if v_bad<>0 then raise exception 'aw17_20 reserve independent QA: trilingual/type rows=%',v_bad; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D')
  into v_a,v_b,v_c,v_d
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4819 and m.reserve_role='diagnostic';
  if (v_a,v_b,v_c,v_d)<>(3,3,3,3) then
    raise exception 'aw17_20 reserve independent QA: P1 diagnostic answer balance A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D')
  into v_a,v_b,v_c,v_d
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4820 and m.reserve_role='diagnostic';
  if (v_a,v_b,v_c,v_d)<>(3,3,2,2) then
    raise exception 'aw17_20 reserve independent QA: P5 diagnostic answer balance A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4819,4820)
    and m.reserve_role='diagnostic'
    and (
      q.qtype<>'mcq'
      or (select count(*) from private.exam_prep_diagnostic_rules r
          where r.content_meta_id=m.id and r.rule_version='aw_reserve_v1'
            and r.status='draft' and r.answer_kind='mcq_option'
            and r.answer_match<>q.correct_answer
            and r.weak_skill_code=m.primary_skill_code)<>3
    );
  if v_bad<>0 then raise exception 'aw17_20 reserve independent QA: diagnostic-rule alignment rows=%',v_bad; end if;

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
    where m.content_version_id in (4819,4820)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw17_20 reserve independent QA: exact published stem reuse'; end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4819 and m.content_key='P1DIF03-D02'
      and q.question_text_en like '%missing factor%' and q.correct_answer='A'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4819 and m.content_key='P1SER03-R04'
      and q.question_text_en like '%S10=230%' and q.correct_answer='41'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4820 and m.content_key='P5BIN03-D02'
      and q.question_text_en like '%Var(X)/E(X)=0.8%' and q.correct_answer='B'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4820 and m.content_key='P5GEO03-R04'
      and q.question_text_en like '%expected total time is 10 minutes%' and q.correct_answer='0.2'
  ) then raise exception 'aw17_20 reserve independent QA: reviewed surface pin missing'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4819,4820)
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
  if v_bad<>0 then raise exception 'aw17_20 reserve independent QA: snapshot drift rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4819,4820)
  ) or exists(
    select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4819,4820)
  ) or exists(
    select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4819,4820)
  ) then raise exception 'aw17_20 reserve independent QA: history appeared during correction'; end if;
end
$postcheck$;

commit;
