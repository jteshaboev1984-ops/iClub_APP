-- AW9-12 P5 annual-reserve top-up draft v1.
-- DRAFT ONLY: no learner-visible content and no existing evidence mutation.
-- Exact delta per skill: +2 diagnostics, +2 delayed retests, +1 mixed/transfer.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw09_12_annual_reserve_p5_draft canonical program missing'; end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4812 and content_version<>'p5_aw09_12_annual_reserve_topup_draft_v1')
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59240 and 59269 and content_version_id<>4812)
  then raise exception 'aw09_12_annual_reserve_p5_draft reserved id collision'; end if;

  if (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P5-DAT-03','P5-DAT-05','P5-DAT-07','P5-CNT-05','P5-PRO-02','P5-PRO-04')
        and m.reserve_role='diagnostic')<>6
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P5-DAT-03','P5-DAT-05','P5-DAT-07','P5-CNT-05','P5-PRO-02','P5-PRO-04')
        and m.reserve_role='retest')<>12
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P5-DAT-03','P5-DAT-05','P5-DAT-07','P5-CNT-05','P5-PRO-02','P5-PRO-04')
        and m.reserve_role in ('learning','mixed'))<>42
  then raise exception 'aw09_12_annual_reserve_p5_draft baseline depth changed'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4812,pv.id,'p5_aw09_12_annual_reserve_topup_draft_v1','P5',
 'P5 AW9-12 annual reserve top-up draft v1','draft',
 'Original iClub-authored annual reserve expansion. Official Cambridge 9709 scope controls the learning objectives; Complete Probability & Statistics 1 is mapping/explanation support only. No protected Cambridge/coursebook question, solution, mark-scheme wording or diagram is copied. Independent academic, trilingual, technical, originality and reserve-isolation QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,reserve_role,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P5DAT03-D02','P5-DAT-03','diagnostic','medium','mcq','A box plot has Q1=12 and Q3=20. Using the 1.5×IQR rule, which statement is correct?','["33 is a high outlier","31 is a high outlier","20 is a high outlier","The upper fence is 28"]','A','IQR=8, so the upper fence is 20+1.5×8=32. Therefore 33 is a high outlier.','Для диаграммы размаха Q1=12 и Q3=20. Какое утверждение верно по правилу 1,5×IQR?','["33 является верхним выбросом","31 является верхним выбросом","20 является верхним выбросом","Верхняя граница равна 28"]','IQR=8, поэтому верхняя граница равна 20+1,5×8=32. Следовательно, 33 — верхний выброс.','Box plot uchun Q1=12 va Q3=20. 1.5×IQR qoidasiga ko‘ra qaysi fikr to‘g‘ri?','["33 yuqori chet qiymat","31 yuqori chet qiymat","20 yuqori chet qiymat","Yuqori chegara 28"]','IQR=8, shuning uchun yuqori chegara 20+1.5×8=32. Demak 33 yuqori chet qiymat.',65),
('P5DAT03-D03','P5-DAT-03','diagnostic','medium','mcq','Box plot A has median 28 and IQR 9. Box plot B has median 31 and IQR 6. Which comparison is supported?','["A has the higher median and smaller IQR","B has the higher median and smaller IQR","B has the lower median and larger IQR","The two plots have the same centre and spread"]','B','B has median 31>28 and IQR 6<9, so B has the higher median and smaller middle-50% spread.','Для диаграммы A медиана 28 и IQR 9. Для диаграммы B медиана 31 и IQR 6. Какое сравнение подтверждается?','["У A выше медиана и меньше IQR","У B выше медиана и меньше IQR","У B ниже медиана и больше IQR","Центр и разброс одинаковы"]','У B медиана 31>28, а IQR 6<9, поэтому у B выше медиана и меньше разброс средней половины данных.','A box plotda mediana 28 va IQR 9. B box plotda mediana 31 va IQR 6. Qaysi taqqoslash to‘g‘ri?','["A da mediana yuqori va IQR kichik","B da mediana yuqori va IQR kichik","B da mediana past va IQR katta","Markaz va tarqoqlik bir xil"]','B da mediana 31>28 va IQR 6<9, demak B da mediana yuqori va o‘rta 50% tarqoqligi kichik.',60),
('P5DAT03-R03','P5-DAT-03','retest','hard','input','A box plot has Q3=40 and upper outlier fence 58 under the 1.5×IQR rule. Enter Q1.','[]','28','58=40+1.5×IQR, so IQR=12. Hence Q1=40−12=28.','Для диаграммы размаха Q3=40, а верхняя граница выбросов по правилу 1,5×IQR равна 58. Введите Q1.','[]','58=40+1,5×IQR, поэтому IQR=12. Следовательно, Q1=40−12=28.','Box plot uchun Q3=40 va 1.5×IQR qoidasidagi yuqori chegara 58. Q1 ni kiriting.','[]','58=40+1.5×IQR, demak IQR=12. Shuning uchun Q1=40−12=28.',75),
('P5DAT03-R04','P5-DAT-03','retest','medium','mcq','A box plot has Q1=18 and Q3=30. Which value is a low outlier using the 1.5×IQR rule?','["2","0","−1","1"]','C','IQR=12, so the lower fence is 18−1.5×12=0. Only a value below 0 is a low outlier, so −1 qualifies.','Для диаграммы размаха Q1=18 и Q3=30. Какое значение является нижним выбросом по правилу 1,5×IQR?','["2","0","−1","1"]','IQR=12, нижняя граница равна 18−1,5×12=0. Нижним выбросом является значение меньше 0, то есть −1.','Box plot uchun Q1=18 va Q3=30. 1.5×IQR qoidasiga ko‘ra qaysi qiymat quyi chet qiymat?','["2","0","−1","1"]','IQR=12, quyi chegara 18−1.5×12=0. 0 dan kichik qiymat quyi chet qiymat bo‘ladi, ya’ni −1.',65),
('P5DAT03-M02','P5-DAT-03','mixed','hard','mcq','A data set has median 15 and IQR 6. Every value is transformed to y=2x+3. What are the new median and IQR?','["median 30, IQR 9","median 18, IQR 12","median 33, IQR 9","median 33, IQR 12"]','D','A positive linear transformation sends the median to 2(15)+3=33. Translation does not change spread, while multiplication by 2 doubles the IQR to 12.','У набора данных медиана 15 и IQR 6. Каждое значение преобразуют по формуле y=2x+3. Каковы новые медиана и IQR?','["медиана 30, IQR 9","медиана 18, IQR 12","медиана 33, IQR 9","медиана 33, IQR 12"]','Медиана переходит в 2·15+3=33. Сдвиг не меняет разброс, а умножение на 2 удваивает IQR до 12.','Ma’lumotlar to‘plamida mediana 15 va IQR 6. Har bir qiymat y=2x+3 ga o‘zgartiriladi. Yangi mediana va IQR qanday?','["mediana 30, IQR 9","mediana 18, IQR 12","mediana 33, IQR 9","mediana 33, IQR 12"]','Mediana 2·15+3=33 ga o‘tadi. Siljish tarqoqlikni o‘zgartirmaydi, 2 ga ko‘paytirish esa IQR ni 12 gacha ikki baravar oshiradi.',80),
('P5DAT05-D02','P5-DAT-05','diagnostic','easy','mcq','A cumulative-frequency graph represents 240 observations. Which cumulative frequency is used to read Q1?','["30","120","60","180"]','C','Q1 is the 25th percentile, so use 0.25×240=60.','График накопленной частоты представляет 240 наблюдений. Какую накопленную частоту используют для чтения Q1?','["30","120","60","180"]','Q1 — 25-й процентиль, поэтому используем 0,25×240=60.','Kumulyativ chastota grafigida 240 ta kuzatuv bor. Q1 ni o‘qish uchun qaysi kumulyativ chastota ishlatiladi?','["30","120","60","180"]','Q1 25-percentil, demak 0.25×240=60 ishlatiladi.',45),
('P5DAT05-D03','P5-DAT-05','diagnostic','medium','mcq','A cumulative-frequency curve gives CF=47 at x=18 and CF=131 at x=35. How many observations satisfy 18<x≤35?','["47","131","178","84"]','D','Subtract the cumulative counts: 131−47=84.','На кривой накопленной частоты CF=47 при x=18 и CF=131 при x=35. Сколько наблюдений удовлетворяют 18<x≤35?','["47","131","178","84"]','Вычитаем накопленные частоты: 131−47=84.','Kumulyativ chastota egri chizig‘ida x=18 da CF=47 va x=35 da CF=131. 18<x≤35 shartni nechta kuzatuv qanoatlantiradi?','["47","131","178","84"]','Kumulyativ chastotalarni ayiramiz: 131−47=84.',55),
('P5DAT05-R03','P5-DAT-05','retest','medium','input','A cumulative-frequency graph represents 180 observations. Enter the cumulative frequency corresponding to the 65th percentile.','[]','117','0.65×180=117.','График накопленной частоты представляет 180 наблюдений. Введите накопленную частоту, соответствующую 65-му процентилю.','[]','0,65×180=117.','Kumulyativ chastota grafigida 180 ta kuzatuv bor. 65-percentilga mos kumulyativ chastotani kiriting.','[]','0.65×180=117.',45),
('P5DAT05-R04','P5-DAT-05','retest','medium','mcq','On a cumulative-frequency graph, the median is read at cumulative frequency 45. How many observations are represented?','["90","45","180","22.5"]','A','The median is at 50% of the total, so N/2=45 and N=90.','На графике накопленной частоты медиана читается при накопленной частоте 45. Сколько наблюдений представлено?','["90","45","180","22,5"]','Медиана соответствует 50% общего числа, поэтому N/2=45 и N=90.','Kumulyativ chastota grafigida mediana 45 kumulyativ chastotada o‘qiladi. Nechta kuzatuv bor?','["90","45","180","22.5"]','Mediana umumiy sonning 50% iga mos, demak N/2=45 va N=90.',50),
('P5DAT05-M02','P5-DAT-05','mixed','hard','input','A cumulative-frequency graph represents 160 observations. CF=35 at x=20 and CF=110 at x=40. Enter the percentage of observations satisfying 20<x≤40.','[]','46.875','There are 110−35=75 observations in the interval. The percentage is 75/160×100=46.875.','График накопленной частоты представляет 160 наблюдений. CF=35 при x=20 и CF=110 при x=40. Введите процент наблюдений, удовлетворяющих 20<x≤40.','[]','В интервале 110−35=75 наблюдений. Процент равен 75/160×100=46,875.','Kumulyativ chastota grafigida 160 ta kuzatuv bor. x=20 da CF=35 va x=40 da CF=110. 20<x≤40 shartni qanoatlantiradigan kuzatuvlar foizini kiriting.','[]','Oraliqda 110−35=75 ta kuzatuv bor. Foiz 75/160×100=46.875.',75),
('P5DAT07-D02','P5-DAT-07','diagnostic','medium','mcq','A data set has standard deviation 3.2. Every value is transformed to y=−2x+7. What is the new standard deviation?','["6.4","1.6","−6.4","10.2"]','A','A shift does not change standard deviation, while multiplying by −2 multiplies it by |−2|=2. Thus 3.2×2=6.4.','Стандартное отклонение набора данных равно 3,2. Каждое значение преобразуют по формуле y=−2x+7. Каково новое стандартное отклонение?','["6,4","1,6","−6,4","10,2"]','Сдвиг не меняет стандартное отклонение, а умножение на −2 умножает его на |−2|=2. Получаем 3,2×2=6,4.','Ma’lumotlar to‘plamining standart og‘ishi 3.2. Har bir qiymat y=−2x+7 ga o‘zgartiriladi. Yangi standart og‘ish qancha?','["6.4","1.6","−6.4","10.2"]','Siljish standart og‘ishni o‘zgartirmaydi, −2 ga ko‘paytirish esa uni |−2|=2 marta oshiradi. 3.2×2=6.4.',55),
('P5DAT07-D03','P5-DAT-07','diagnostic','medium','mcq','A data set has IQR 9. Every value is transformed to y=3x−4. What is the new IQR?','["13","27","5","9"]','B','The translation does not affect spread; multiplication by 3 triples the IQR, giving 27.','IQR набора данных равен 9. Каждое значение преобразуют по формуле y=3x−4. Каков новый IQR?','["13","27","5","9"]','Сдвиг не меняет разброс; умножение на 3 утраивает IQR, получаем 27.','Ma’lumotlar to‘plamining IQR qiymati 9. Har bir qiymat y=3x−4 ga o‘zgartiriladi. Yangi IQR qancha?','["13","27","5","9"]','Siljish tarqoqlikni o‘zgartirmaydi; 3 ga ko‘paytirish IQR ni uch baravar oshiradi, natija 27.',50),
('P5DAT07-R03','P5-DAT-07','retest','medium','input','A data set has range 18. Every value is transformed to y=−1.5x+2. Enter the new range.','[]','27','Translation does not affect range. Multiplication by −1.5 scales the range by 1.5, so 18×1.5=27.','Размах набора данных равен 18. Каждое значение преобразуют по формуле y=−1,5x+2. Введите новый размах.','[]','Сдвиг не влияет на размах. Умножение на −1,5 увеличивает размах в 1,5 раза: 18×1,5=27.','Ma’lumotlar to‘plamining oraliq kengligi 18. Har bir qiymat y=−1.5x+2 ga o‘zgartiriladi. Yangi oraliq kengligini kiriting.','[]','Siljish oraliq kengligini o‘zgartirmaydi. −1.5 ga ko‘paytirish uni 1.5 marta oshiradi: 18×1.5=27.',50),
('P5DAT07-R04','P5-DAT-07','retest','medium','mcq','Data set A has standard deviation 4. Data set B has standard deviation 7. Which statement is supported?','["A has the greater spread","The means must be different","B has greater spread as measured by standard deviation","B must have the greater range"]','C','Standard deviation directly measures spread around the mean. Since 7>4, B has greater spread by this measure.','У набора A стандартное отклонение 4, у набора B — 7. Какое утверждение подтверждается?','["У A больше разброс","Средние обязательно различаются","У B больше разброс по стандартному отклонению","У B обязательно больше размах"]','Стандартное отклонение измеряет разброс относительно среднего. Так как 7>4, по этой мере у B разброс больше.','A to‘plamning standart og‘ishi 4, B to‘plamniki 7. Qaysi fikr tasdiqlanadi?','["A da tarqoqlik katta","O‘rtacha qiymatlar albatta farq qiladi","Standart og‘ish bo‘yicha B da tarqoqlik katta","B ning oraliq kengligi albatta katta"]','Standart og‘ish o‘rtacha atrofidagi tarqoqlikni o‘lchaydi. 7>4 bo‘lgani uchun shu o‘lchov bo‘yicha B da tarqoqlik katta.',55),
('P5DAT07-M02','P5-DAT-07','mixed','hard','input','A data set has standard deviation 4. After the transformation y=ax+7, the standard deviation is 10. Enter |a|.','[]','2.5','Standard deviation is multiplied by |a|, so 4|a|=10 and |a|=2.5.','Стандартное отклонение набора данных равно 4. После преобразования y=ax+7 стандартное отклонение равно 10. Введите |a|.','[]','Стандартное отклонение умножается на |a|, поэтому 4|a|=10 и |a|=2,5.','Ma’lumotlar to‘plamining standart og‘ishi 4. y=ax+7 almashtirishdan keyin standart og‘ish 10. |a| ni kiriting.','[]','Standart og‘ish |a| ga ko‘payadi, demak 4|a|=10 va |a|=2.5.',70),
('P5CNT05-D02','P5-CNT-05','diagnostic','medium','mcq','A group has 6 men and 5 women. How many 4-person committees contain exactly 2 women?','["120","90","150","210"]','C','Choose 2 women and 2 men: 5C2×6C2=10×15=150.','В группе 6 мужчин и 5 женщин. Сколько комитетов из 4 человек содержат ровно 2 женщин?','["120","90","150","210"]','Выбираем 2 женщин и 2 мужчин: 5C2×6C2=10×15=150.','Guruhda 6 erkak va 5 ayol bor. Aynan 2 ayol qatnashadigan 4 kishilik qo‘mitalar soni nechta?','["120","90","150","210"]','5 ayoldan 2 tasini va 6 erkakdan 2 tasini tanlaymiz: 5C2×6C2=10×15=150.',60),
('P5CNT05-D03','P5-CNT-05','diagnostic','medium','mcq','Nine people include A and B. How many 4-person committees contain at least one of A or B?','["35","70","126","91"]','D','Subtract committees containing neither A nor B: 9C4−7C4=126−35=91.','Среди 9 человек есть A и B. Сколько комитетов из 4 человек содержат хотя бы одного из A или B?','["35","70","126","91"]','Вычитаем комитеты, не содержащие ни A, ни B: 9C4−7C4=126−35=91.','9 kishi orasida A va B bor. A yoki B dan kamida bittasi qatnashadigan 4 kishilik qo‘mitalar nechta?','["35","70","126","91"]','A ham, B ham yo‘q qo‘mitalarni ayiramiz: 9C4−7C4=126−35=91.',65),
('P5CNT05-R03','P5-CNT-05','retest','medium','input','Ten people include A and B. A 5-person committee must contain exactly one of A or B. Enter the number of possible committees.','[]','140','Choose which of A or B is included in 2 ways, then choose 4 of the remaining 8 people: 2×8C4=2×70=140.','Среди 10 человек есть A и B. Комитет из 5 человек должен содержать ровно одного из A или B. Введите число возможных комитетов.','[]','Выбираем одного из A или B двумя способами, затем 4 из оставшихся 8: 2×8C4=2×70=140.','10 kishi orasida A va B bor. 5 kishilik qo‘mita A yoki B dan aynan bittasini o‘z ichiga olishi kerak. Mumkin qo‘mitalar sonini kiriting.','[]','A yoki B dan bittasini 2 usulda tanlaymiz, keyin qolgan 8 kishidan 4 tasini tanlaymiz: 2×8C4=2×70=140.',65),
('P5CNT05-R04','P5-CNT-05','retest','hard','mcq','A group has 5 women and 7 men. How many 4-person committees contain at least 2 women?','["210","285","350","455"]','B','Count 2, 3 or 4 women: 5C2·7C2 + 5C3·7C1 + 5C4 = 210+70+5=285.','В группе 5 женщин и 7 мужчин. Сколько комитетов из 4 человек содержат не менее 2 женщин?','["210","285","350","455"]','Считаем случаи с 2, 3 или 4 женщинами: 5C2·7C2 + 5C3·7C1 + 5C4 = 210+70+5=285.','Guruhda 5 ayol va 7 erkak bor. Kamida 2 ayol qatnashadigan 4 kishilik qo‘mitalar nechta?','["210","285","350","455"]','2, 3 yoki 4 ayolli holatlarni sanaymiz: 5C2·7C2 + 5C3·7C1 + 5C4 = 210+70+5=285.',80),
('P5CNT05-M02','P5-CNT-05','mixed','hard','input','A 3-person team is chosen from 8 people. Then a captain and a secretary are assigned to two different team members. Enter the number of possible outcomes.','[]','336','Choose the team in 8C3=56 ways. Choose captain and secretary in 3P2=6 ways. Total 56×6=336.','Из 8 человек выбирают команду из 3 человек. Затем двум разным членам команды назначают роли капитана и секретаря. Введите число возможных исходов.','[]','Команду выбираем 8C3=56 способами. Капитана и секретаря назначаем 3P2=6 способами. Всего 56×6=336.','8 kishidan 3 kishilik jamoa tanlanadi. So‘ng ikki turli a’zoga sardor va kotib rollari beriladi. Mumkin natijalar sonini kiriting.','[]','Jamoa 8C3=56 usulda tanlanadi. Sardor va kotib 3P2=6 usulda tayinlanadi. Jami 56×6=336.',80),
('P5PRO02-D02','P5-PRO-02','diagnostic','medium','mcq','A bag contains 6 red and 4 blue counters. Three are chosen without replacement. What is the probability of exactly 2 red counters?','["1/2","3/5","2/5","1/3"]','A','Favourable selections: 6C2×4C1=60. Total selections: 10C3=120. Probability=60/120=1/2.','В мешке 6 красных и 4 синих фишки. Без возвращения выбирают 3. Какова вероятность ровно 2 красных?','["1/2","3/5","2/5","1/3"]','Благоприятных выборов: 6C2×4C1=60. Всего выборов: 10C3=120. Вероятность=60/120=1/2.','Qopda 6 qizil va 4 ko‘k jeton bor. Qaytarmasdan 3 tasi tanlanadi. Aynan 2 qizil tanlash ehtimoli qancha?','["1/2","3/5","2/5","1/3"]','Qulay tanlovlar: 6C2×4C1=60. Jami tanlovlar: 10C3=120. Ehtimol=60/120=1/2.',65),
('P5PRO02-D03','P5-PRO-02','diagnostic','medium','mcq','Four people are chosen at random from 10 people. What is the probability that two particular people are both chosen?','["1/5","2/15","1/3","4/15"]','B','With the two particular people fixed, choose the other 2 from 8: 8C2=28. Total choices are 10C4=210, so probability=28/210=2/15.','Из 10 человек случайно выбирают 4. Какова вероятность того, что два конкретных человека оба будут выбраны?','["1/5","2/15","1/3","4/15"]','Два конкретных человека уже включены, остальные 2 выбираются из 8: 8C2=28. Всего 10C4=210, вероятность=28/210=2/15.','10 kishidan tasodifiy 4 kishi tanlanadi. Ikki aniq kishining ikkalasi ham tanlanish ehtimoli qancha?','["1/5","2/15","1/3","4/15"]','Ikki aniq kishi oldindan kiritilgan, qolgan 2 kishi 8 tadan tanlanadi: 8C2=28. Jami 10C4=210, ehtimol=28/210=2/15.',65),
('P5PRO02-R03','P5-PRO-02','retest','medium','input','A set contains 5 marked and 7 unmarked objects. Three are chosen at random. The probability of choosing exactly one marked object is simplified. Enter its numerator.','[]','21','P=5C1×7C2 / 12C3 = 105/220 = 21/44, so the numerator is 21.','В наборе 5 отмеченных и 7 неотмеченных объектов. Случайно выбирают 3. Вероятность выбрать ровно один отмеченный объект сокращена. Введите её числитель.','[]','P=5C1×7C2 / 12C3 = 105/220 = 21/44, поэтому числитель равен 21.','To‘plamda 5 belgilangan va 7 belgilanmagan obyekt bor. Tasodifiy 3 tasi tanlanadi. Aynan bitta belgilangan obyekt tanlash ehtimoli qisqartirilgan. Suratini kiriting.','[]','P=5C1×7C2 / 12C3 = 105/220 = 21/44, demak surat 21.',70),
('P5PRO02-R04','P5-PRO-02','retest','medium','mcq','From 6 girls and 4 boys, 3 students are chosen at random. What is the probability that at least one boy is chosen?','["1/6","2/3","5/6","1/3"]','C','Use the complement: P(no boys)=6C3/10C3=20/120=1/6. Hence P(at least one boy)=5/6.','Из 6 девочек и 4 мальчиков случайно выбирают 3 учеников. Какова вероятность выбрать хотя бы одного мальчика?','["1/6","2/3","5/6","1/3"]','Используем дополнение: P(без мальчиков)=6C3/10C3=20/120=1/6. Поэтому P(хотя бы один мальчик)=5/6.','6 qiz va 4 o‘g‘ildan tasodifiy 3 o‘quvchi tanlanadi. Kamida bitta o‘g‘il tanlanish ehtimoli qancha?','["1/6","2/3","5/6","1/3"]','To‘ldiruvchidan foydalanamiz: P(o‘g‘il yo‘q)=6C3/10C3=20/120=1/6. Demak P(kamida bitta o‘g‘il)=5/6.',65),
('P5PRO02-M02','P5-PRO-02','mixed','hard','input','A group has 3 seniors and 7 juniors. Four people are chosen at random. Enter the probability of choosing exactly 2 seniors as a decimal.','[]','0.3','P=3C2×7C2 / 10C4 = 3×21/210 = 63/210 = 0.3.','В группе 3 старших и 7 младших участников. Случайно выбирают 4 человек. Введите вероятность выбрать ровно 2 старших в виде десятичной дроби.','[]','P=3C2×7C2 / 10C4 = 3×21/210 = 63/210 = 0,3.','Guruhda 3 katta va 7 kichik ishtirokchi bor. Tasodifiy 4 kishi tanlanadi. Aynan 2 katta ishtirokchi tanlash ehtimolini o‘nli kasr ko‘rinishida kiriting.','[]','P=3C2×7C2 / 10C4 = 3×21/210 = 63/210 = 0.3.',75),
('P5PRO04-D02','P5-PRO-04','diagnostic','medium','mcq','P(A)=0.8 and P(B|A)=0.25. Find P(A∩B).','["0.55","0.32","0.20","0.05"]','C','P(A∩B)=P(A)P(B|A)=0.8×0.25=0.20.','P(A)=0,8 и P(B|A)=0,25. Найдите P(A∩B).','["0,55","0,32","0,20","0,05"]','P(A∩B)=P(A)P(B|A)=0,8×0,25=0,20.','P(A)=0.8 va P(B|A)=0.25. P(A∩B) ni toping.','["0.55","0.32","0.20","0.05"]','P(A∩B)=P(A)P(B|A)=0.8×0.25=0.20.',45),
('P5PRO04-D03','P5-PRO-04','diagnostic','medium','mcq','P(A)=0.6, P(B)=0.5 and P(A∩B)=0.3. Which statement is correct?','["A and B are mutually exclusive","P(A|B)=0","A and B are not independent","A and B are independent"]','D','P(A)P(B)=0.6×0.5=0.3=P(A∩B), so A and B are independent.','P(A)=0,6, P(B)=0,5 и P(A∩B)=0,3. Какое утверждение верно?','["A и B взаимоисключающие","P(A|B)=0","A и B не независимы","A и B независимы"]','P(A)P(B)=0,6×0,5=0,3=P(A∩B), поэтому A и B независимы.','P(A)=0.6, P(B)=0.5 va P(A∩B)=0.3. Qaysi fikr to‘g‘ri?','["A va B o‘zaro istisno","P(A|B)=0","A va B mustaqil emas","A va B mustaqil"]','P(A)P(B)=0.6×0.5=0.3=P(A∩B), shuning uchun A va B mustaqil.',50),
('P5PRO04-R03','P5-PRO-04','retest','medium','input','Events A and B are independent. P(A)=0.4 and P(A∩B)=0.18. Enter P(B).','[]','0.45','For independent events, P(A∩B)=P(A)P(B). Thus P(B)=0.18/0.4=0.45.','События A и B независимы. P(A)=0,4 и P(A∩B)=0,18. Введите P(B).','[]','Для независимых событий P(A∩B)=P(A)P(B). Поэтому P(B)=0,18/0,4=0,45.','A va B hodisalar mustaqil. P(A)=0.4 va P(A∩B)=0.18. P(B) ni kiriting.','[]','Mustaqil hodisalar uchun P(A∩B)=P(A)P(B). Demak P(B)=0.18/0.4=0.45.',50),
('P5PRO04-R04','P5-PRO-04','retest','medium','mcq','Three independent events have probabilities 0.5, 0.4 and 0.3. What is the probability that all three occur?','["0.12","0.06","0.20","0.40"]','B','For independent events, multiply: 0.5×0.4×0.3=0.06.','Три независимых события имеют вероятности 0,5, 0,4 и 0,3. Какова вероятность того, что произойдут все три?','["0,12","0,06","0,20","0,40"]','Для независимых событий перемножаем вероятности: 0,5×0,4×0,3=0,06.','Uchta mustaqil hodisaning ehtimollari 0.5, 0.4 va 0.3. Uchalasi ham sodir bo‘lish ehtimoli qancha?','["0.12","0.06","0.20","0.40"]','Mustaqil hodisalarda ehtimollarni ko‘paytiramiz: 0.5×0.4×0.3=0.06.',50),
('P5PRO04-M02','P5-PRO-04','mixed','hard','input','Independent events A and B have P(A)=0.4 and P(B)=0.3. Enter the probability that exactly one of A and B occurs.','[]','0.46','P(A only)=0.4×0.7=0.28 and P(B only)=0.6×0.3=0.18. Total=0.46.','Независимые события A и B имеют P(A)=0,4 и P(B)=0,3. Введите вероятность того, что произойдёт ровно одно из событий A и B.','[]','P(только A)=0,4×0,7=0,28, P(только B)=0,6×0,3=0,18. Итого 0,46.','Mustaqil A va B hodisalar uchun P(A)=0.4 va P(B)=0.3. A va B dan aynan bittasi sodir bo‘lish ehtimolini kiriting.','[]','P(faqat A)=0.4×0.7=0.28, P(faqat B)=0.6×0.3=0.18. Jami 0.46.',65)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,
 case when s.skill_code like 'P5-DAT-%' then 'P5 Representation of data'
      when s.skill_code='P5-CNT-05' then 'P5 Permutations and combinations'
      else 'P5 Probability' end,
 s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P5:p5_aw09_12_annual_reserve_topup_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw09_12_annual_reserve_topup_draft_v1:'||s.content_key);

with src(content_key,skill_code,meta_id) as (values
('P5DAT03-D02','P5-DAT-03',59240),
('P5DAT03-D03','P5-DAT-03',59241),
('P5DAT03-R03','P5-DAT-03',59242),
('P5DAT03-R04','P5-DAT-03',59243),
('P5DAT03-M02','P5-DAT-03',59244),
('P5DAT05-D02','P5-DAT-05',59245),
('P5DAT05-D03','P5-DAT-05',59246),
('P5DAT05-R03','P5-DAT-05',59247),
('P5DAT05-R04','P5-DAT-05',59248),
('P5DAT05-M02','P5-DAT-05',59249),
('P5DAT07-D02','P5-DAT-07',59250),
('P5DAT07-D03','P5-DAT-07',59251),
('P5DAT07-R03','P5-DAT-07',59252),
('P5DAT07-R04','P5-DAT-07',59253),
('P5DAT07-M02','P5-DAT-07',59254),
('P5CNT05-D02','P5-CNT-05',59255),
('P5CNT05-D03','P5-CNT-05',59256),
('P5CNT05-R03','P5-CNT-05',59257),
('P5CNT05-R04','P5-CNT-05',59258),
('P5CNT05-M02','P5-CNT-05',59259),
('P5PRO02-D02','P5-PRO-02',59260),
('P5PRO02-D03','P5-PRO-02',59261),
('P5PRO02-R03','P5-PRO-02',59262),
('P5PRO02-R04','P5-PRO-02',59263),
('P5PRO02-M02','P5-PRO-02',59264),
('P5PRO04-D02','P5-PRO-04',59265),
('P5PRO04-D03','P5-PRO-04',59266),
('P5PRO04-R03','P5-PRO-04',59267),
('P5PRO04-R04','P5-PRO-04',59268),
('P5PRO04-M02','P5-PRO-04',59269)
), cv as (select id from private.exam_prep_content_versions where id=4812)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,cv.id,s.content_key,qn.id,s.skill_code,'{}'::text[],r.reserve_role,'withheld','draft',
 'Original iClub-authored annual reserve item; stem, values, distractors, answer and explanation are independently authored.',
 'AW9-12 annual reserve draft. Official syllabus controls scope; coursebook mapping is used only to locate the learning objective.',
 case when s.skill_code like 'P5-DAT-%' then 'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data'
      when s.skill_code='P5-CNT-05' then 'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations'
      else 'Cambridge 9709 2026-2027 v4; P5 5.3 Probability' end,
 case when s.skill_code='P5-DAT-07' then 'Complete Probability & Statistics 1, Ch2 pp.14-29 (mapping only)'
      when s.skill_code like 'P5-DAT-%' then 'Complete Probability & Statistics 1, Ch3 pp.34-59 (mapping only)'
      when s.skill_code='P5-CNT-05' then 'Complete Probability & Statistics 1, Ch6 pp.98-111 (mapping only)'
      else 'Complete Probability & Statistics 1, Ch4 pp.63-82 (mapping only)' end,
 'pending','pending','pending','pending','pending',
 case when r.reserve_role='diagnostic' then 'pending' else 'not_applicable' end,
 md5(concat_ws(chr(31),
   qn.id::text,qn.subject_id::text,coalesce(qn.topic,''),coalesce(qn.subtopic,''),coalesce(qn.difficulty,''),coalesce(qn.qtype,''),
   coalesce(qn.question_text,''),coalesce(qn.options_text,''),coalesce(qn.correct_answer,''),coalesce(qn.explanation,''),
   coalesce(qn.image_url,''),coalesce(qn.is_active::text,''),coalesce(qn.question_text_ru,''),coalesce(qn.question_text_uz,''),
   coalesce(qn.question_text_en,''),coalesce(qn.options_text_ru,''),coalesce(qn.options_text_uz,''),coalesce(qn.options_text_en,''),
   coalesce(qn.explanation_ru,''),coalesce(qn.explanation_uz,''),coalesce(qn.explanation_en,''),coalesce(qn.book_ref,''),
   coalesce(qn.time_limit_sec::text,''),coalesce(qn.quality_flag,''),coalesce(qn.quality_status,'')
 ))
from cv cross join src s
join public.questions qn on qn.book_ref='ExamPrep:P5:p5_aw09_12_annual_reserve_topup_draft_v1:'||s.content_key
join (values ('P5DAT03-D02','diagnostic'),('P5DAT03-D03','diagnostic'),('P5DAT03-R03','retest'),('P5DAT03-R04','retest'),('P5DAT03-M02','mixed'),('P5DAT05-D02','diagnostic'),('P5DAT05-D03','diagnostic'),('P5DAT05-R03','retest'),('P5DAT05-R04','retest'),('P5DAT05-M02','mixed'),('P5DAT07-D02','diagnostic'),('P5DAT07-D03','diagnostic'),('P5DAT07-R03','retest'),('P5DAT07-R04','retest'),('P5DAT07-M02','mixed'),('P5CNT05-D02','diagnostic'),('P5CNT05-D03','diagnostic'),('P5CNT05-R03','retest'),('P5CNT05-R04','retest'),('P5CNT05-M02','mixed'),('P5PRO02-D02','diagnostic'),('P5PRO02-D03','diagnostic'),('P5PRO02-R03','retest'),('P5PRO02-R04','retest'),('P5PRO02-M02','mixed'),('P5PRO04-D02','diagnostic'),('P5PRO04-D03','diagnostic'),('P5PRO04-R03','retest'),('P5PRO04-R04','retest'),('P5PRO04-M02','mixed')) r(content_key,reserve_role) using(content_key)
on conflict(id) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select status from private.exam_prep_content_versions where id=4812)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4812)<>30
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4812 and reserve_role='diagnostic')<>12
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4812 and reserve_role='retest')<>12
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4812 and reserve_role='mixed')<>6
  then raise exception 'aw09_12_annual_reserve_p5_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4812 and (
    m.lifecycle_state<>'draft' or m.exposure_state<>'withheld'
    or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or q.is_active or q.quality_status<>'draft'
  );
  if v_bad<>0 then raise exception 'aw09_12_annual_reserve_p5_draft exposure/QA boundary rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4812
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4812
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw09_12_annual_reserve_p5_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4812)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4812)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4812)
  then raise exception 'aw09_12_annual_reserve_p5_draft unexpected history'; end if;
end
$postcheck$;

commit;
