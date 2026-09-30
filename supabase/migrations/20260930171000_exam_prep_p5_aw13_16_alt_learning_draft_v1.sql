-- AW13-16 supplemental learning pack draft for P5.
-- Derived runway slice: closes remaining E1/E2 P5 skills before E3 expansion.
-- DRAFT ONLY: no learner exposure, self-approval or publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw13_16_alt_p5_draft canonical program missing'; end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4814 and content_version<>'p5_aw13_16_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15645 and 15649 and content_version_id<>4814)
     or exists(select 1 from private.exam_prep_assessments where id between 35428 and 35432 and content_version_id<>4814)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59291 and 59305 and content_version_id<>4814)
  then raise exception 'aw13_16_alt_p5_draft reserved id collision'; end if;

  if (select count(*) from private.exam_prep_question_content_meta m
      join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P5-DAT-08','P5-DAT-09','P5-DAT-10','P5-PRO-05','P5-PRO-06')
        and m.reserve_role='learning')<>15
  then raise exception 'aw13_16_alt_p5_draft baseline learning depth changed'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4814,pv.id,'p5_aw13_16_alt_learning_draft_v1','P5',
 'P5 AW13-16 additional learning pack draft v1','draft',
 'Original iClub-authored learning content. The canonical Cambridge 9709 map and Complete Probability & Statistics 1 mappings define learning objectives only; no protected question, solution, diagram or mark-scheme wording is copied. Independent academic, EN/RU/UZ, technical and copyright QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,topic,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P5DAT08-B01','P5-DAT-08','P5 Data','medium','mcq','Class A has median score 68 and IQR 8. Class B has median score 72 and IQR 14. Which comparison is supported?','["B has the higher typical score, while A is more consistent","A has the higher typical score and is more consistent","B has the higher typical score and is more consistent","A and B have the same typical score"]','A','The median describes a typical score, so B is higher. The smaller IQR indicates less spread, so A is more consistent.','У класса A медиана результата 68 и IQR 8. У класса B медиана 72 и IQR 14. Какое сравнение подтверждается?','["У B выше типичный результат, а A более стабилен","У A выше типичный результат и он более стабилен","У B выше типичный результат и он более стабилен","У A и B одинаковый типичный результат"]','Медиана характеризует типичный результат, поэтому у B он выше. Меньший IQR означает меньший разброс, поэтому A более стабилен.','A sinfning median balli 68 va IQR 8. B sinfning medianasi 72 va IQR 14. Qaysi taqqoslash asosli?','["B ning odatiy natijasi yuqori, A esa barqarorroq","A ning odatiy natijasi yuqori va barqarorroq","B ning odatiy natijasi yuqori va barqarorroq","A va B ning odatiy natijasi bir xil"]','Mediana odatiy natijani bildiradi, shuning uchun B yuqori. Kichik IQR kamroq tarqalishni bildiradi, demak A barqarorroq.',70),
('P5DAT08-B02','P5-DAT-08','P5 Data','medium','mcq','Two machines have the same mean output. Machine P has standard deviation 6 and machine Q has standard deviation 2. Which conclusion is justified?','["P has the more consistent output","Q has the more consistent output","P has the higher average output","Q has the higher average output"]','B','The means are equal, so neither has a higher average. The smaller standard deviation for Q means its output is more consistent.','Две машины имеют одинаковое среднее значение выпуска. У машины P стандартное отклонение 6, у Q — 2. Какой вывод обоснован?','["У P более стабильный выпуск","У Q более стабильный выпуск","У P выше средний выпуск","У Q выше средний выпуск"]','Средние одинаковы, поэтому ни у одной машины средний выпуск не выше. Меньшее стандартное отклонение Q означает более стабильный выпуск.','Ikki mashinaning o‘rtacha ishlab chiqarishi bir xil. P mashinada standart og‘ish 6, Q da 2. Qaysi xulosa asosli?','["P ishlab chiqarishi barqarorroq","Q ishlab chiqarishi barqarorroq","P ning o‘rtacha ishlab chiqarishi yuqori","Q ning o‘rtacha ishlab chiqarishi yuqori"]','O‘rtachalar teng, shuning uchun hech biri yuqori o‘rtachaga ega emas. Q ning standart og‘ishi kichik, demak u barqarorroq.',65),
('P5DAT08-B03','P5-DAT-08','P5 Data','medium','input','Dataset X has IQR 15 and dataset Y has IQR 9. Enter the difference between their IQRs.','[]','6','The difference in IQR is 15−9=6.','У набора X IQR=15, у набора Y IQR=9. Введите разность их IQR.','[]','Разность IQR равна 15−9=6.','X ma’lumotlar to‘plamida IQR 15, Y da IQR 9. Ularning IQR lar farqini kiriting.','[]','IQR lar farqi 15−9=6.',55),
('P5DAT09-B01','P5-DAT-09','P5 Data','medium','mcq','For n=8 observations, Σx=40 and Σx²=232. Find the mean and standard deviation using variance=Σx²/n−mean².','["mean 5, standard deviation 4","mean 8, standard deviation 2","mean 5, standard deviation 2","mean 5, standard deviation √29"]','C','The mean is 40/8=5. The variance is 232/8−25=29−25=4, so the standard deviation is 2.','Для n=8 наблюдений Σx=40 и Σx²=232. Найдите среднее и стандартное отклонение, используя variance=Σx²/n−mean².','["среднее 5, стандартное отклонение 4","среднее 8, стандартное отклонение 2","среднее 5, стандартное отклонение 2","среднее 5, стандартное отклонение √29"]','Среднее равно 40/8=5. Дисперсия 232/8−25=29−25=4, поэтому стандартное отклонение равно 2.','n=8 kuzatuv uchun Σx=40 va Σx²=232. variance=Σx²/n−mean² formulasi bilan o‘rtacha va standart og‘ishni toping.','["o‘rtacha 5, standart og‘ish 4","o‘rtacha 8, standart og‘ish 2","o‘rtacha 5, standart og‘ish 2","o‘rtacha 5, standart og‘ish √29"]','O‘rtacha 40/8=5. Dispersiya 232/8−25=29−25=4, demak standart og‘ish 2.',80),
('P5DAT09-B02','P5-DAT-09','P5 Data','medium','mcq','The values 0, 2 and 4 have frequencies 1, 2 and 1 respectively. What are the mean and standard deviation, using division by n?','["mean 2, standard deviation 2","mean 1.5, standard deviation √2","mean 2, standard deviation 2√2","mean 2, standard deviation √2"]','D','There are 4 values. Σfx=8 gives mean 2. Σfx²=24, so variance=24/4−2²=2 and standard deviation=√2.','Значения 0, 2 и 4 имеют частоты 1, 2 и 1 соответственно. Найдите среднее и стандартное отклонение, используя деление на n.','["среднее 2, стандартное отклонение 2","среднее 1,5, стандартное отклонение √2","среднее 2, стандартное отклонение 2√2","среднее 2, стандартное отклонение √2"]','Всего 4 значения. Σfx=8, поэтому среднее 2. Σfx²=24, дисперсия 24/4−2²=2, стандартное отклонение √2.','0, 2 va 4 qiymatlar mos ravishda 1, 2 va 1 chastotaga ega. n ga bo‘lish orqali o‘rtacha va standart og‘ishni toping.','["o‘rtacha 2, standart og‘ish 2","o‘rtacha 1.5, standart og‘ish √2","o‘rtacha 2, standart og‘ish 2√2","o‘rtacha 2, standart og‘ish √2"]','Jami 4 qiymat. Σfx=8, o‘rtacha 2. Σfx²=24, dispersiya 24/4−2²=2, standart og‘ish √2.',85),
('P5DAT09-B03','P5-DAT-09','P5 Data','medium','input','For n=5 observations, Σx=30 and Σx²=190. Enter the variance using variance=Σx²/n−mean².','[]','2','The mean is 30/5=6. The variance is 190/5−36=38−36=2.','Для n=5 наблюдений Σx=30 и Σx²=190. Введите дисперсию, используя variance=Σx²/n−mean².','[]','Среднее 30/5=6. Дисперсия равна 190/5−36=38−36=2.','n=5 kuzatuv uchun Σx=30 va Σx²=190. variance=Σx²/n−mean² formulasi bilan dispersiyani kiriting.','[]','O‘rtacha 30/5=6. Dispersiya 190/5−36=38−36=2.',75),
('P5DAT10-B01','P5-DAT-10','P5 Data','medium','mcq','Group A has 12 values with mean 5. Group B has 8 values with mean 11. Find the combined mean.','["7.4","8.0","6.5","16.0"]','A','The combined total is 12×5+8×11=148 across 20 values, so the mean is 148/20=7.4.','В группе A 12 значений со средним 5. В группе B 8 значений со средним 11. Найдите общее среднее.','["7,4","8,0","6,5","16,0"]','Общая сумма равна 12×5+8×11=148 для 20 значений, поэтому среднее 148/20=7,4.','A guruhda 12 ta qiymat va o‘rtacha 5. B guruhda 8 ta qiymat va o‘rtacha 11. Birlashtirilgan o‘rtachani toping.','["7.4","8.0","6.5","16.0"]','Umumiy yig‘indi 12×5+8×11=148, jami 20 qiymat. O‘rtacha 148/20=7.4.',70),
('P5DAT10-B02','P5-DAT-10','P5 Data','medium','mcq','For 10 observations define y=(x−20)/4. If Σy=15, what is the mean of x?','["24","26","35","80"]','B','The mean of y is 15/10=1.5. Since x=4y+20, mean x=4(1.5)+20=26.','Для 10 наблюдений задано y=(x−20)/4. Если Σy=15, чему равно среднее x?','["24","26","35","80"]','Среднее y равно 15/10=1,5. Так как x=4y+20, среднее x=4(1,5)+20=26.','10 ta kuzatuv uchun y=(x−20)/4 deb olingan. Agar Σy=15 bo‘lsa, x ning o‘rtachasi qancha?','["24","26","35","80"]','y ning o‘rtachasi 15/10=1.5. x=4y+20 bo‘lgani uchun x o‘rtacha=4(1.5)+20=26.',75),
('P5DAT10-B03','P5-DAT-10','P5 Data','medium','input','A combined set of 25 values has mean 14. A subgroup of 10 values has mean 11. Enter the mean of the remaining 15 values.','[]','16','The combined total is 25×14=350. The subgroup total is 10×11=110, leaving 240 for 15 values. Their mean is 240/15=16.','Объединённый набор из 25 значений имеет среднее 14. Подгруппа из 10 значений имеет среднее 11. Введите среднее оставшихся 15 значений.','[]','Общая сумма 25×14=350. Сумма подгруппы 10×11=110, остаётся 240 для 15 значений. Их среднее 240/15=16.','25 ta qiymatdan iborat umumiy to‘plam o‘rtachasi 14. 10 ta qiymatli kichik guruh o‘rtachasi 11. Qolgan 15 ta qiymat o‘rtachasini kiriting.','[]','Umumiy yig‘indi 25×14=350. Kichik guruh yig‘indisi 10×11=110, 15 qiymat uchun 240 qoladi. O‘rtacha 240/15=16.',80),
('P5PRO05-B01','P5-PRO-05','P5 Probability','medium','mcq','P(A)=0.50, P(B)=0.60 and P(A∩B)=0.24. Find P(B|A).','["0.12","0.40","0.48","0.84"]','C','P(B|A)=P(A∩B)/P(A)=0.24/0.50=0.48.','P(A)=0,50, P(B)=0,60 и P(A∩B)=0,24. Найдите P(B|A).','["0,12","0,40","0,48","0,84"]','P(B|A)=P(A∩B)/P(A)=0,24/0,50=0,48.','P(A)=0.50, P(B)=0.60 va P(A∩B)=0.24. P(B|A) ni toping.','["0.12","0.40","0.48","0.84"]','P(B|A)=P(A∩B)/P(A)=0.24/0.50=0.48.',65),
('P5PRO05-B02','P5-PRO-05','P5 Probability','medium','mcq','Among 120 students, 70 study Mathematics and 40 study both Mathematics and Physics. A student is chosen from those who study Mathematics. What is the probability that the student also studies Physics?','["1/3","2/5","7/12","4/7"]','D','The conditioning group contains 70 Mathematics students, of whom 40 also study Physics. The probability is 40/70=4/7.','Из 120 учеников 70 изучают математику, а 40 изучают и математику, и физику. Ученика выбирают среди изучающих математику. Какова вероятность, что он также изучает физику?','["1/3","2/5","7/12","4/7"]','В условной группе 70 учеников, изучающих математику, из них 40 также изучают физику. Вероятность 40/70=4/7.','120 o‘quvchidan 70 tasi matematika o‘qiydi, 40 tasi esa matematika va fizikani ham o‘qiydi. Matematika o‘qiydiganlardan bitta o‘quvchi tanlanadi. U fizika ham o‘qish ehtimoli qancha?','["1/3","2/5","7/12","4/7"]','Shartli guruhda 70 ta matematika o‘quvchisi bor, ulardan 40 tasi fizika ham o‘qiydi. Ehtimol 40/70=4/7.',75),
('P5PRO05-B03','P5-PRO-05','P5 Probability','medium','input','P(A∩B)=0.18 and P(A|B)=0.60. Enter P(B).','[]','0.3','Since P(A|B)=P(A∩B)/P(B), 0.60=0.18/P(B), so P(B)=0.30.','P(A∩B)=0,18 и P(A|B)=0,60. Введите P(B).','[]','Так как P(A|B)=P(A∩B)/P(B), 0,60=0,18/P(B), поэтому P(B)=0,30.','P(A∩B)=0.18 va P(A|B)=0.60. P(B) ni kiriting.','[]','P(A|B)=P(A∩B)/P(B) bo‘lgani uchun 0.60=0.18/P(B), demak P(B)=0.30.',75),
('P5PRO06-B01','P5-PRO-06','P5 Probability','medium','mcq','A bag contains 6 white and 4 black counters. Two counters are drawn without replacement. Find P(white then black).','["4/15","2/5","3/10","8/25"]','A','P(white then black)=6/10×4/9=24/90=4/15.','В мешке 6 белых и 4 чёрных жетона. Без возвращения выбирают два. Найдите P(белый, затем чёрный).','["4/15","2/5","3/10","8/25"]','P(белый, затем чёрный)=6/10×4/9=24/90=4/15.','Qopda 6 oq va 4 qora jeton bor. Qaytarmasdan ikkita tanlanadi. P(oq, keyin qora) ni toping.','["4/15","2/5","3/10","8/25"]','P(oq, keyin qora)=6/10×4/9=24/90=4/15.',70),
('P5PRO06-B02','P5-PRO-06','P5 Probability','medium','mcq','A process uses route A with probability 0.4 and route B with probability 0.6. The success probabilities are 0.7 after A and 0.5 after B. Find the overall probability of success.','["0.42","0.58","0.62","0.70"]','B','Add the success branches: 0.4×0.7+0.6×0.5=0.28+0.30=0.58.','Процесс выбирает путь A с вероятностью 0,4 и путь B с вероятностью 0,6. Вероятности успеха после A и B равны 0,7 и 0,5. Найдите общую вероятность успеха.','["0,42","0,58","0,62","0,70"]','Складываем ветви успеха: 0,4×0,7+0,6×0,5=0,28+0,30=0,58.','Jarayon A yo‘lini 0.4, B yo‘lini 0.6 ehtimol bilan tanlaydi. A dan keyin muvaffaqiyat ehtimoli 0.7, B dan keyin 0.5. Umumiy muvaffaqiyat ehtimolini toping.','["0.42","0.58","0.62","0.70"]','Muvaffaqiyat shoxlarini qo‘shamiz: 0.4×0.7+0.6×0.5=0.28+0.30=0.58.',75),
('P5PRO06-B03','P5-PRO-06','P5 Probability','hard','input','A bag contains 5 red and 3 blue counters. Two are drawn without replacement. Enter the probability of drawing exactly one red counter as a simplified fraction.','[]','15/28','The two orders are red-blue and blue-red. Their total probability is 5/8×3/7+3/8×5/7=30/56=15/28.','В мешке 5 красных и 3 синих жетона. Без возвращения выбирают два. Введите вероятность получить ровно один красный жетон в виде несократимой дроби.','[]','Два порядка: красный-синий и синий-красный. Суммарная вероятность 5/8×3/7+3/8×5/7=30/56=15/28.','Qopda 5 qizil va 3 ko‘k jeton bor. Qaytarmasdan ikkita tanlanadi. Aynan bitta qizil chiqish ehtimolini qisqartirilgan kasr ko‘rinishida kiriting.','[]','Ikki tartib bor: qizil-ko‘k va ko‘k-qizil. Jami ehtimol 5/8×3/7+3/8×5/7=30/56=15/28.',85)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,s.topic,s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P5:p5_aw13_16_alt_learning_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw13_16_alt_learning_draft_v1:'||s.content_key);

insert into private.exam_prep_written_tasks(
 id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
 prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
 lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(15645,4814,'P5DAT08-BW14','P5','P5-DAT-08','{}','v1','Two delivery services are compared. Service A has median delivery time 31 minutes, IQR 6 minutes and range 25 minutes. Service B has median 28 minutes, IQR 11 minutes and range 19 minutes. Compare the services in context, making separate claims about typical speed and consistency. Explain which statistic supports each claim and why no single service is better on every measure.','Сравниваются две службы доставки. У A медиана времени доставки 31 минута, IQR 6 минут и размах 25 минут. У B медиана 28 минут, IQR 11 минут и размах 19 минут. Сравните службы в контексте, сделав отдельные выводы о типичной скорости и стабильности. Объясните, какая статистика поддерживает каждый вывод и почему одна служба не лучше по всем показателям.','Ikki yetkazib berish xizmati taqqoslanadi. A xizmatida median vaqt 31 daqiqa, IQR 6 daqiqa va diapazon 25 daqiqa. B xizmatida mediana 28, IQR 11 va diapazon 19 daqiqa. Xizmatlarni kontekstda taqqoslab, odatiy tezlik va barqarorlik haqida alohida xulosalar bering. Har bir xulosani qaysi statistika qo‘llashini va nima uchun bitta xizmat barcha o‘lchovlarda yaxshiroq emasligini tushuntiring.','{"criteria":[{"id":"location","rule":"Uses medians to compare typical delivery time and notes lower is faster.","marks":2},{"id":"iqr","rule":"Uses IQR to compare central consistency.","marks":1},{"id":"range","rule":"Uses range as an additional whole-sample spread comparison.","marks":1},{"id":"context","rule":"States conclusions in delivery-time context.","marks":1},{"id":"balance","rule":"Recognises the measures do not all favour the same service.","marks":1}],"max_marks":6}'::jsonb,'Separate location from spread. Because lower delivery time is better, interpret the median direction in context before comparing IQR and range.','Отделите положение от разброса. Поскольку меньшее время доставки лучше, сначала интерпретируйте направление медианы в контексте, затем сравните IQR и размах.','Markaziy qiymatni tarqalishdan ajrating. Yetkazib berish vaqti kichik bo‘lsa yaxshiroq, shuning uchun avval median yo‘nalishini kontekstda talqin qiling, keyin IQR va diapazonni solishtiring.','draft','pending','pending','pending','pending'),
(15646,4814,'P5DAT09-BW14','P5','P5-DAT-09','{}','v1','For 12 observations, Σx=96 and Σx²=852. Find the mean, variance and standard deviation using division by n. Then a second data set has values 1, 3 and 5 with frequencies 2, 4 and 2. Calculate its mean and standard deviation and compare the spreads.','Для 12 наблюдений Σx=96 и Σx²=852. Найдите среднее, дисперсию и стандартное отклонение, используя деление на n. Затем второй набор имеет значения 1, 3 и 5 с частотами 2, 4 и 2. Найдите его среднее и стандартное отклонение и сравните разбросы.','12 ta kuzatuv uchun Σx=96 va Σx²=852. n ga bo‘lish orqali o‘rtacha, dispersiya va standart og‘ishni toping. Ikkinchi to‘plamda 1, 3 va 5 qiymatlar chastotalari 2, 4 va 2. Uning o‘rtacha va standart og‘ishini hisoblang hamda tarqalishlarni taqqoslang.','{"criteria":[{"id":"mean1","rule":"Finds the first mean correctly.","marks":1},{"id":"var1","rule":"Uses Σx²/n−mean² correctly for the first variance.","marks":1},{"id":"sd1","rule":"Finds the first standard deviation.","marks":1},{"id":"table","rule":"Builds correct Σf, Σfx and Σfx² for the frequency data.","marks":1},{"id":"sd2","rule":"Finds the second mean and standard deviation.","marks":1},{"id":"compare","rule":"Compares spread using the standard deviations.","marks":1}],"max_marks":6}'::jsonb,'Write n, Σx and Σx² before substituting. For the frequency data, build Σf, Σfx and Σfx² first.','Перед подстановкой запишите n, Σx и Σx². Для данных с частотами сначала найдите Σf, Σfx и Σfx².','Qo‘yishdan oldin n, Σx va Σx² ni yozing. Chastotali ma’lumot uchun avval Σf, Σfx va Σfx² ni toping.','draft','pending','pending','pending','pending'),
(15647,4814,'P5DAT10-BW14','P5','P5-DAT-10','{}','v1','Group A has 18 observations with mean 24. Group B has 12 observations with mean 31. (a) Find the combined mean. For a separate set of 20 observations define y=(x−40)/5, with Σy=12 and Σy²=38. (b) Find the mean of x. (c) Find the variance and standard deviation of x.','В группе A 18 наблюдений со средним 24. В группе B 12 наблюдений со средним 31. (a) Найдите объединённое среднее. Для отдельного набора из 20 наблюдений задано y=(x−40)/5, при этом Σy=12 и Σy²=38. (b) Найдите среднее x. (c) Найдите дисперсию и стандартное отклонение x.','A guruhda 18 ta kuzatuv, o‘rtacha 24. B guruhda 12 ta kuzatuv, o‘rtacha 31. (a) Birlashtirilgan o‘rtachani toping. Alohida 20 ta kuzatuv uchun y=(x−40)/5, Σy=12 va Σy²=38. (b) x ning o‘rtachasini toping. (c) x dispersiyasi va standart og‘ishini toping.','{"criteria":[{"id":"combined","rule":"Uses weighted totals to find the combined mean.","marks":2},{"id":"meany","rule":"Finds mean y=12/20.","marks":1},{"id":"meanx","rule":"Transforms mean y to mean x correctly.","marks":1},{"id":"vary","rule":"Finds variance of y from Σy² and mean y.","marks":1},{"id":"varx","rule":"Scales variance/standard deviation correctly from y to x.","marks":1}],"max_marks":6}'::jsonb,'For the combined mean, reconstruct each group total. For coding, calculate mean and variance in y first, then use x=5y+40.','Для общего среднего восстановите сумму каждой группы. Для кодирования сначала найдите среднее и дисперсию y, затем используйте x=5y+40.','Birlashtirilgan o‘rtacha uchun har bir guruh yig‘indisini tiklang. Kodlashda avval y ning o‘rtacha va dispersiyasini toping, keyin x=5y+40 dan foydalaning.','draft','pending','pending','pending','pending'),
(15648,4814,'P5PRO05-BW14','P5','P5-PRO-05','{}','v1','Events A and B satisfy P(A)=0.48, P(B)=0.50 and P(A∩B)=0.18. (a) Find P(B|A). (b) Find P(A|B). (c) Find the probability that exactly one of A and B occurs. (d) Determine whether A and B are independent, with a numerical justification.','События A и B удовлетворяют P(A)=0,48, P(B)=0,50 и P(A∩B)=0,18. (a) Найдите P(B|A). (b) Найдите P(A|B). (c) Найдите вероятность того, что произойдёт ровно одно из A и B. (d) Определите, независимы ли A и B, с численным обоснованием.','A va B hodisalari uchun P(A)=0.48, P(B)=0.50 va P(A∩B)=0.18. (a) P(B|A) ni toping. (b) P(A|B) ni toping. (c) A va B dan aynan bittasi sodir bo‘lish ehtimolini toping. (d) A va B mustaqilmi, sonli asos bilan aniqlang.','{"criteria":[{"id":"cond1","rule":"Finds P(B|A)=0.18/0.48.","marks":1},{"id":"cond2","rule":"Finds P(A|B)=0.18/0.50.","marks":1},{"id":"exactly","rule":"Computes P(A)+P(B)−2P(A∩B).","marks":2},{"id":"product","rule":"Computes P(A)P(B).","marks":1},{"id":"decision","rule":"Compares the product with the intersection and concludes correctly.","marks":1}],"max_marks":6}'::jsonb,'Use the same intersection in both conditional probabilities. For independence, compare P(A∩B) with P(A)P(B).','Используйте одно и то же пересечение в обеих условных вероятностях. Для независимости сравните P(A∩B) с P(A)P(B).','Har ikki shartli ehtimolda bir xil kesishmadan foydalaning. Mustaqillik uchun P(A∩B) ni P(A)P(B) bilan taqqoslang.','draft','pending','pending','pending','pending'),
(15649,4814,'P5PRO06-BW14','P5','P5-PRO-06','{}','v1','A bag contains 5 red, 3 blue and 2 green counters. Two counters are drawn without replacement. (a) Draw or describe a complete two-stage probability tree. (b) Find P(one red and one blue). (c) Find P(at least one green). (d) Given that the second counter is blue, find the probability that the first counter was red.','В мешке 5 красных, 3 синих и 2 зелёных жетона. Без возвращения выбирают два. (a) Постройте или опишите полное двухэтапное дерево вероятностей. (b) Найдите P(один красный и один синий). (c) Найдите P(хотя бы один зелёный). (d) При условии, что второй жетон синий, найдите вероятность того, что первый был красным.','Qopda 5 qizil, 3 ko‘k va 2 yashil jeton bor. Qaytarmasdan ikkita tanlanadi. (a) To‘liq ikki bosqichli ehtimollar daraxtini chizing yoki tasvirlang. (b) P(bitta qizil va bitta ko‘k) ni toping. (c) P(kamida bitta yashil) ni toping. (d) Ikkinchi jeton ko‘k ekani ma’lum bo‘lsa, birinchi jeton qizil bo‘lish ehtimolini toping.','{"criteria":[{"id":"tree","rule":"Gives correct first- and second-stage branch probabilities without replacement.","marks":2},{"id":"rb","rule":"Adds the red-blue and blue-red branches correctly.","marks":1},{"id":"green","rule":"Uses complement or branch addition correctly for at least one green.","marks":1},{"id":"conditional","rule":"Forms the required conditional probability for first red given second blue.","marks":1},{"id":"working","rule":"Shows which branch probabilities are multiplied and which outcomes are added.","marks":1}],"max_marks":6}'::jsonb,'Update the denominator after the first draw. Multiply along a branch and add disjoint branches. For the conditional part, restrict attention to branches ending in blue.','После первого выбора уменьшите знаменатель. Умножайте вероятности вдоль ветви и складывайте несовместимые ветви. Для условной части рассматривайте только ветви, заканчивающиеся синим.','Birinchi tanlovdan keyin maxrajni kamaytiring. Shox bo‘ylab ehtimollarni ko‘paytiring va o‘zaro istisno shoxlarni qo‘shing. Shartli qismda faqat ko‘k bilan tugaydigan shoxlarni ko‘ring.','draft','pending','pending','pending','pending')
on conflict(id) do nothing;

with src(content_key,skill_code,meta_id) as (values
('P5DAT08-B01','P5-DAT-08',59291),
('P5DAT08-B02','P5-DAT-08',59292),
('P5DAT08-B03','P5-DAT-08',59293),
('P5DAT09-B01','P5-DAT-09',59294),
('P5DAT09-B02','P5-DAT-09',59295),
('P5DAT09-B03','P5-DAT-09',59296),
('P5DAT10-B01','P5-DAT-10',59297),
('P5DAT10-B02','P5-DAT-10',59298),
('P5DAT10-B03','P5-DAT-10',59299),
('P5PRO05-B01','P5-PRO-05',59300),
('P5PRO05-B02','P5-PRO-05',59301),
('P5PRO05-B03','P5-PRO-05',59302),
('P5PRO06-B01','P5-PRO-06',59303),
('P5PRO06-B02','P5-PRO-06',59304),
('P5PRO06-B03','P5-PRO-06',59305)
), cv as (select id from private.exam_prep_content_versions where id=4814)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,cv.id,s.content_key,qn.id,s.skill_code,'{}'::text[],'learning','withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'AW13-16 P5 learning runway draft for the remaining E1/E2 canonical skills; separate from prior teaching and evidence versions.',
 case when s.skill_code like 'P5-DAT-%'
      then 'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data'
      else 'Cambridge 9709 2026-2027 v4; P5 5.3 Probability' end,
 case s.skill_code
   when 'P5-DAT-08' then 'Complete Probability & Statistics 1; representation/comparison of data (mapping only)'
   when 'P5-DAT-09' then 'Complete Probability & Statistics 1; numerical summaries (mapping only)'
   when 'P5-DAT-10' then 'Complete Probability & Statistics 1; coded and combined data (mapping only)'
   else 'Complete Probability & Statistics 1; Probability (mapping only)'
 end,
 'pending','pending','pending','pending','pending','not_applicable',
 md5(concat_ws(chr(31),
   qn.id::text,qn.subject_id::text,coalesce(qn.topic,''),coalesce(qn.subtopic,''),coalesce(qn.difficulty,''),coalesce(qn.qtype,''),
   coalesce(qn.question_text,''),coalesce(qn.options_text,''),coalesce(qn.correct_answer,''),coalesce(qn.explanation,''),
   coalesce(qn.image_url,''),coalesce(qn.is_active::text,''),coalesce(qn.question_text_ru,''),coalesce(qn.question_text_uz,''),
   coalesce(qn.question_text_en,''),coalesce(qn.options_text_ru,''),coalesce(qn.options_text_uz,''),coalesce(qn.options_text_en,''),
   coalesce(qn.explanation_ru,''),coalesce(qn.explanation_uz,''),coalesce(qn.explanation_en,''),coalesce(qn.book_ref,''),
   coalesce(qn.time_limit_sec::text,''),coalesce(qn.quality_flag,''),coalesce(qn.quality_status,'')
 ))
from cv cross join src s
join public.questions qn on qn.book_ref='ExamPrep:P5:p5_aw13_16_alt_learning_draft_v1:'||s.content_key
on conflict(id) do nothing;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35428,4814,'P5-DAT-08-learning-alt-02','v1','P5','learning','draft','Data: contextual comparison — additional practice','Данные: сравнение в контексте — дополнительная практика','Ma’lumotlar: kontekstli taqqoslash — qo‘shimcha mashq'),
(35429,4814,'P5-DAT-09-learning-alt-02','v1','P5','learning','draft','Data: mean and standard deviation — additional practice','Данные: среднее и стандартное отклонение — дополнительная практика','Ma’lumotlar: o‘rtacha va standart og‘ish — qo‘shimcha mashq'),
(35430,4814,'P5-DAT-10-learning-alt-02','v1','P5','learning','draft','Data: coded and combined data — additional practice','Данные: кодированные и объединённые данные — дополнительная практика','Ma’lumotlar: kodlangan va birlashtirilgan ma’lumotlar — qo‘shimcha mashq'),
(35431,4814,'P5-PRO-05-learning-alt-02','v1','P5','learning','draft','Probability: conditional probability — additional practice','Вероятность: условная вероятность — дополнительная практика','Ehtimollik: shartli ehtimol — qo‘shimcha mashq'),
(35432,4814,'P5-PRO-06-learning-alt-02','v1','P5','learning','draft','Probability: probability trees — additional practice','Вероятность: деревья вероятностей — дополнительная практика','Ehtimollik: ehtimollar daraxti — qo‘shimcha mashq')
on conflict(id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
(35428,1,'P5DAT08-B01',null::bigint,'P5-DAT-08'),
(35428,2,'P5DAT08-B02',null::bigint,'P5-DAT-08'),
(35428,3,'P5DAT08-B03',null::bigint,'P5-DAT-08'),
(35428,4,null,15645,'P5-DAT-08'),
(35429,1,'P5DAT09-B01',null::bigint,'P5-DAT-09'),
(35429,2,'P5DAT09-B02',null::bigint,'P5-DAT-09'),
(35429,3,'P5DAT09-B03',null::bigint,'P5-DAT-09'),
(35429,4,null,15646,'P5-DAT-09'),
(35430,1,'P5DAT10-B01',null::bigint,'P5-DAT-10'),
(35430,2,'P5DAT10-B02',null::bigint,'P5-DAT-10'),
(35430,3,'P5DAT10-B03',null::bigint,'P5-DAT-10'),
(35430,4,null,15647,'P5-DAT-10'),
(35431,1,'P5PRO05-B01',null::bigint,'P5-PRO-05'),
(35431,2,'P5PRO05-B02',null::bigint,'P5-PRO-05'),
(35431,3,'P5PRO05-B03',null::bigint,'P5-PRO-05'),
(35431,4,null,15648,'P5-PRO-05'),
(35432,1,'P5PRO06-B01',null::bigint,'P5-PRO-06'),
(35432,2,'P5PRO06-B02',null::bigint,'P5-PRO-06'),
(35432,3,'P5PRO06-B03',null::bigint,'P5-PRO-06'),
(35432,4,null,15649,'P5-PRO-06')
)
insert into private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select i.assessment_id,i.item_order,qn.id,i.written_id,i.skill_code,
 case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions qn on i.content_key is not null
 and qn.book_ref='ExamPrep:P5:p5_aw13_16_alt_learning_draft_v1:'||i.content_key
on conflict(assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select status from private.exam_prep_content_versions where id=4814)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4814 and lifecycle_state='draft' and reserve_role='learning')<>15
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4814 and lifecycle_state='draft')<>5
     or (select count(*) from private.exam_prep_assessments where content_version_id=4814 and status='draft' and assessment_type='learning')<>5
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4814)<>20
  then raise exception 'aw13_16_alt_p5_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4814 and (
    m.exposure_state<>'withheld' or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or qn.is_active or qn.quality_status<>'draft'
    or nullif(btrim(qn.question_text_en),'') is null or nullif(btrim(qn.question_text_ru),'') is null or nullif(btrim(qn.question_text_uz),'') is null
    or nullif(btrim(qn.explanation_en),'') is null or nullif(btrim(qn.explanation_ru),'') is null or nullif(btrim(qn.explanation_uz),'') is null
  );
  if v_bad<>0 then raise exception 'aw13_16_alt_p5_draft exposure/trilingual boundary rows=%',v_bad; end if;

  select count(*) into v_bad from (
    select a.id,
      count(*) filter(where ai.question_id is not null and ai.reserve_role='learning' and not ai.is_holdout) machine_n,
      count(*) filter(where ai.written_task_id is not null and ai.reserve_role='written' and not ai.is_holdout) written_n,
      count(*) total_n
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id=4814
    group by a.id
  ) x where machine_n<>3 or written_n<>1 or total_n<>4;
  if v_bad<>0 then raise exception 'aw13_16_alt_p5_draft assessment 3+1 shape rows=%',v_bad; end if;

  select
    count(*) filter(where qn.correct_answer='A'),count(*) filter(where qn.correct_answer='B'),
    count(*) filter(where qn.correct_answer='C'),count(*) filter(where qn.correct_answer='D'),
    count(*) filter(where qn.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4814;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(3,3,2,2,5) then
    raise exception 'aw13_16_alt_p5_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m
    join public.questions qn on qn.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4814
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4814
      and lower(regexp_replace(qn.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw13_16_alt_p5_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4814)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4814)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4814)
  then raise exception 'aw13_16_alt_p5_draft unexpected history'; end if;
end
$postcheck$;

commit;
