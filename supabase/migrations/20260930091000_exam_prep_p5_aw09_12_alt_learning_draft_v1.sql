-- AW9-12 supplemental learning pack draft for P5.
-- DRAFT ONLY: no learner exposure, QA self-approval or publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active') then
    raise exception 'aw09_12_alt_p5_draft canonical program missing';
  end if;
  if exists(select 1 from private.exam_prep_content_versions where id=4810 and content_version<>'p5_aw09_12_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15632 and 15637 and content_version_id<>4810)
     or exists(select 1 from private.exam_prep_assessments where id between 35381 and 35386 and content_version_id<>4810)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59182 and 59199 and content_version_id<>4810)
  then raise exception 'aw09_12_alt_p5_draft reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4810,pv.id,'p5_aw09_12_alt_learning_draft_v1','P5',
 'P5 AW9-12 supplemental learning pack draft v1','draft',
 'Original iClub-authored supplemental learning content. Official Cambridge 9709 scope and Complete Probability & Statistics 1 mappings define learning objectives only; no protected source question, solution, diagram or mark-scheme wording is copied. Independent academic, language, technical and copyright QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict (program_version_id,content_version) do nothing;

with src(content_key,skill_code,topic,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P5DAT03-A01','P5-DAT-03','P5 Representation of data','medium','mcq','A box plot has Q1=18, Q3=31 and maximum value 50. Using the 1.5×IQR rule, which statement is correct?','["50 is not an outlier","50 is an upper outlier","31 is an upper outlier","The IQR is 32"]','A','IQR=31−18=13. The upper fence is 31+1.5×13=50.5, so 50 is not above the fence and is not an outlier.','Для диаграммы размаха Q1=18, Q3=31, максимальное значение 50. Какое утверждение верно по правилу 1,5×IQR?','["50 не является выбросом","50 является верхним выбросом","31 является верхним выбросом","IQR равен 32"]','IQR=31−18=13. Верхняя граница равна 31+1,5×13=50,5, поэтому 50 не превышает границу и не является выбросом.','Box plot uchun Q1=18, Q3=31 va maksimum 50. 1.5×IQR qoidasiga ko‘ra qaysi fikr to‘g‘ri?','["50 chet qiymat emas","50 yuqori chet qiymat","31 yuqori chet qiymat","IQR 32 ga teng"]','IQR=31−18=13. Yuqori chegara 31+1.5×13=50.5, shuning uchun 50 chegaradan oshmaydi va chet qiymat emas.',60),
('P5DAT03-A02','P5-DAT-03','P5 Representation of data','medium','mcq','Box plot A has median 42 and IQR 8. Box plot B has median 39 and IQR 14. Which comparison is supported?','["B has the higher median and smaller spread","A has the higher median and smaller IQR","A has the lower median and larger IQR","The two data sets have the same centre and spread"]','B','A has median 42>39 and IQR 8<14. So A has the higher median and the smaller middle-50% spread.','Для диаграммы A медиана равна 42, IQR равен 8. Для диаграммы B медиана 39, IQR равен 14. Какое сравнение подтверждается?','["У B выше медиана и меньше разброс","У A выше медиана и меньше IQR","У A ниже медиана и больше IQR","У наборов одинаковые центр и разброс"]','У A медиана 42>39 и IQR 8<14. Значит, у A выше медиана и меньше разброс средней половины данных.','A box plotda mediana 42 va IQR 8. B box plotda mediana 39 va IQR 14. Qaysi taqqoslash to‘g‘ri?','["B da mediana yuqori va tarqoqlik kichik","A da mediana yuqori va IQR kichik","A da mediana past va IQR katta","Ikkala to‘plamning markazi va tarqoqligi bir xil"]','A uchun mediana 42>39 va IQR 8<14. Demak A da mediana yuqori va o‘rta 50% tarqoqligi kichik.',55),
('P5DAT03-A03','P5-DAT-03','P5 Representation of data','medium','input','For a box plot, Q1=22 and Q3=34. Enter the lower outlier fence using the 1.5×IQR rule.','[]','4','IQR=34−22=12. The lower fence is 22−1.5×12=22−18=4.','Для диаграммы размаха Q1=22 и Q3=34. Введите нижнюю границу выбросов по правилу 1,5×IQR.','[]','IQR=34−22=12. Нижняя граница: 22−1,5×12=22−18=4.','Box plot uchun Q1=22 va Q3=34. 1.5×IQR qoidasiga ko‘ra quyi chet qiymat chegarasini kiriting.','[]','IQR=34−22=12. Quyi chegara 22−1.5×12=22−18=4.',50),
('P5DAT05-A01','P5-DAT-05','P5 Representation of data','easy','mcq','A cumulative-frequency graph represents 160 observations. Which cumulative frequency is used to read the upper quartile Q3?','["40","80","120","140"]','C','Q3 is the 75th percentile. 0.75×160=120, so read the x-value at cumulative frequency 120.','График накопленной частоты представляет 160 наблюдений. Какую накопленную частоту используют для определения верхнего квартиля Q3?','["40","80","120","140"]','Q3 — это 75-й процентиль. 0,75×160=120, поэтому нужно читать значение x при накопленной частоте 120.','Kumulyativ chastota grafigida 160 ta kuzatuv bor. Yuqori kvartil Q3 ni o‘qish uchun qaysi kumulyativ chastota ishlatiladi?','["40","80","120","140"]','Q3 75-foizlik nuqta. 0.75×160=120, demak x qiymati kumulyativ chastota 120 da olinadi.',45),
('P5DAT05-A02','P5-DAT-05','P5 Representation of data','medium','mcq','A cumulative-frequency curve gives CF=38 at x=24 and CF=96 at x=41. How many observations satisfy 24<x≤41?','["38","96","134","58"]','D','The number in 24<x≤41 is the difference of cumulative counts: 96−38=58.','На кривой накопленной частоты CF=38 при x=24 и CF=96 при x=41. Сколько наблюдений удовлетворяют 24<x≤41?','["38","96","134","58"]','Число наблюдений в интервале 24<x≤41 равно разности накопленных частот: 96−38=58.','Kumulyativ chastota egri chizig‘ida x=24 da CF=38 va x=41 da CF=96. 24<x≤41 shartni nechta kuzatuv qanoatlantiradi?','["38","96","134","58"]','24<x≤41 oralig‘idagi kuzatuvlar soni kumulyativ chastotalar ayirmasi: 96−38=58.',50),
('P5DAT05-A03','P5-DAT-05','P5 Representation of data','easy','input','A cumulative-frequency graph represents 200 observations. Enter the cumulative frequency corresponding to the 35th percentile.','[]','70','35% of 200 is 0.35×200=70.','График накопленной частоты представляет 200 наблюдений. Введите накопленную частоту, соответствующую 35-му процентилю.','[]','35% от 200 равно 0,35×200=70.','Kumulyativ chastota grafigida 200 ta kuzatuv bor. 35-percentilga mos kumulyativ chastotani kiriting.','[]','200 ning 35% i 0.35×200=70.',40),
('P5DAT07-A01','P5-DAT-07','P5 Measures of location and spread','medium','mcq','A data set has standard deviation 2.4. Every value x is transformed to y=−3x+5. What is the new standard deviation?','["7.2","2.4","9.8","−7.2"]','A','Adding 5 does not change spread. Multiplying by −3 multiplies the standard deviation by |−3|=3, so the new standard deviation is 7.2.','Стандартное отклонение набора данных равно 2,4. Каждое значение x преобразуют по формуле y=−3x+5. Каково новое стандартное отклонение?','["7,2","2,4","9,8","−7,2"]','Прибавление 5 не меняет разброс. Умножение на −3 умножает стандартное отклонение на |−3|=3, поэтому новое значение равно 7,2.','Ma’lumotlar to‘plamining standart og‘ishi 2.4. Har bir x qiymat y=−3x+5 ga o‘zgartiriladi. Yangi standart og‘ish qancha?','["7.2","2.4","9.8","−7.2"]','5 ni qo‘shish tarqoqlikni o‘zgartirmaydi. −3 ga ko‘paytirish standart og‘ishni |−3|=3 marta oshiradi, demak yangi qiymat 7.2.',50),
('P5DAT07-A02','P5-DAT-07','P5 Measures of location and spread','medium','mcq','A data set has interquartile range 9. Each value is transformed to y=x/2−4. What is the new IQR?','["13","9","4.5","2.5"]','C','Subtracting 4 does not change spread. Dividing all values by 2 halves the IQR, so the new IQR is 9/2=4.5.','Межквартильный размах набора данных равен 9. Каждое значение преобразуют по формуле y=x/2−4. Каков новый IQR?','["13","9","4,5","2,5"]','Вычитание 4 не меняет разброс. Деление всех значений на 2 уменьшает IQR вдвое, поэтому новый IQR равен 9/2=4,5.','Ma’lumotlar to‘plamining kvartillar oralig‘i 9. Har bir qiymat y=x/2−4 ga o‘zgartiriladi. Yangi IQR qancha?','["13","9","4.5","2.5"]','4 ni ayirish tarqoqlikni o‘zgartirmaydi. Barcha qiymatlarni 2 ga bo‘lish IQR ni ikki baravar kamaytiradi, demak yangi IQR 9/2=4.5.',50),
('P5DAT07-A03','P5-DAT-07','P5 Measures of location and spread','easy','input','The smallest value in a data set is 14 and the largest is 39. Enter the range.','[]','25','Range=39−14=25.','Наименьшее значение в наборе данных равно 14, наибольшее — 39. Введите размах.','[]','Размах=39−14=25.','Ma’lumotlar to‘plamidagi eng kichik qiymat 14, eng kattasi 39. Oraliq kengligini kiriting.','[]','Oraliq kengligi=39−14=25.',35),
('P5CNT05-A01','P5-CNT-05','P5 Permutations and combinations','easy','mcq','A 3-person panel is selected from 9 people and no roles are assigned. How many panels are possible?','["504","84","27","729"]','B','Order does not matter, so use a combination: 9C3=84.','Из 9 человек выбирают комиссию из 3 человек без распределения ролей. Сколько комиссий возможно?','["504","84","27","729"]','Порядок не важен, поэтому используем сочетания: 9C3=84.','9 kishidan 3 kishilik hay’at tanlanadi, rollar berilmaydi. Nechta hay’at mumkin?','["504","84","27","729"]','Tartib muhim emas, shuning uchun kombinatsiya ishlatiladi: 9C3=84.',45),
('P5CNT05-A02','P5-CNT-05','P5 Permutations and combinations','medium','mcq','A group has 4 women and 6 men. How many 4-person committees contain exactly 2 women?','["60","120","45","90"]','D','Choose 2 of the 4 women and 2 of the 6 men: 4C2×6C2=6×15=90.','В группе 4 женщины и 6 мужчин. Сколько комитетов из 4 человек содержат ровно 2 женщин?','["60","120","45","90"]','Выбираем 2 из 4 женщин и 2 из 6 мужчин: 4C2×6C2=6×15=90.','Guruhda 4 ayol va 6 erkak bor. Aynan 2 ayol qatnashadigan 4 kishilik qo‘mitalar soni nechta?','["60","120","45","90"]','4 ayoldan 2 tasini va 6 erkakdan 2 tasini tanlaymiz: 4C2×6C2=6×15=90.',55),
('P5CNT05-A03','P5-CNT-05','P5 Permutations and combinations','medium','input','A 3-person team is selected from 8 people, then one member is appointed captain. Enter the number of possible outcomes.','[]','168','Choose the team in 8C3=56 ways, then choose its captain in 3 ways. Total 56×3=168.','Из 8 человек выбирают команду из 3 человек, затем одного участника назначают капитаном. Введите число возможных исходов.','[]','Команду можно выбрать 8C3=56 способами, затем капитана — 3 способами. Итого 56×3=168.','8 kishidan 3 kishilik jamoa tanlanadi, so‘ng bir a’zo sardor etib tayinlanadi. Mumkin bo‘lgan natijalar sonini kiriting.','[]','Jamoa 8C3=56 usulda tanlanadi, so‘ng sardor 3 usulda tanlanadi. Jami 56×3=168.',50),
('P5PRO02-A01','P5-PRO-02','P5 Probability','medium','mcq','A bag contains 5 red and 4 blue counters. Three counters are chosen without replacement. What is the probability of choosing exactly 2 red counters?','["10/21","5/9","20/27","4/21"]','A','Favourable selections: 5C2×4C1=10×4=40. Total selections: 9C3=84. Probability=40/84=10/21.','В мешке 5 красных и 4 синих фишки. Без возвращения выбирают 3 фишки. Какова вероятность выбрать ровно 2 красные?','["10/21","5/9","20/27","4/21"]','Благоприятных выборов: 5C2×4C1=10×4=40. Всего выборов: 9C3=84. Вероятность=40/84=10/21.','Qopda 5 qizil va 4 ko‘k jeton bor. Qaytarmasdan 3 ta jeton tanlanadi. Aynan 2 ta qizil tanlash ehtimoli qancha?','["10/21","5/9","20/27","4/21"]','Qulay tanlovlar: 5C2×4C1=10×4=40. Jami tanlovlar: 9C3=84. Ehtimol=40/84=10/21.',60),
('P5PRO02-A02','P5-PRO-02','P5 Probability','hard','mcq','Four people are chosen at random from 12 people. What is the probability that two particular people, A and B, are both chosen?','["2/11","1/6","1/22","1/11"]','D','With A and B fixed, choose the other 2 people from the remaining 10: 10C2=45. Total committees: 12C4=495. Thus 45/495=1/11.','Из 12 человек случайно выбирают 4. Какова вероятность того, что два конкретных человека A и B оба будут выбраны?','["2/11","1/6","1/22","1/11"]','A и B уже включены, поэтому остальных 2 выбираем из 10: 10C2=45. Всего комитетов 12C4=495. Поэтому 45/495=1/11.','12 kishidan tasodifiy 4 kishi tanlanadi. Ikki aniq A va B kishining ikkalasi ham tanlanish ehtimoli qancha?','["2/11","1/6","1/22","1/11"]','A va B oldindan kiritilgan, qolgan 2 kishini 10 kishidan tanlaymiz: 10C2=45. Jami qo‘mitalar 12C4=495. Demak 45/495=1/11.',65),
('P5PRO02-A03','P5-PRO-02','P5 Probability','medium','input','From 7 boys and 5 girls, 3 students are chosen at random. The probability that no girl is chosen simplifies to 7/44. Enter the numerator.','[]','7','P(no girls)=7C3/12C3=35/220=7/44, so the numerator is 7.','Из 7 мальчиков и 5 девочек случайно выбирают 3 учеников. Вероятность того, что не будет выбрана ни одна девочка, сокращается до 7/44. Введите числитель.','[]','P(без девочек)=7C3/12C3=35/220=7/44, поэтому числитель равен 7.','7 o‘g‘il va 5 qizdan tasodifiy 3 o‘quvchi tanlanadi. Hech bir qiz tanlanmaslik ehtimoli 7/44 gacha qisqaradi. Suratni kiriting.','[]','P(qiz tanlanmaydi)=7C3/12C3=35/220=7/44, demak surat 7.',55),
('P5PRO04-A01','P5-PRO-04','P5 Probability','medium','mcq','P(A)=0.6 and P(B|A)=0.35. Find P(A∩B).','["0.95","0.21","0.25","0.35"]','B','Use P(A∩B)=P(A)P(B|A)=0.6×0.35=0.21.','P(A)=0,6 и P(B|A)=0,35. Найдите P(A∩B).','["0,95","0,21","0,25","0,35"]','Используем P(A∩B)=P(A)P(B|A)=0,6×0,35=0,21.','P(A)=0.6 va P(B|A)=0.35. P(A∩B) ni toping.','["0.95","0.21","0.25","0.35"]','P(A∩B)=P(A)P(B|A)=0.6×0.35=0.21 dan foydalanamiz.',45),
('P5PRO04-A02','P5-PRO-04','P5 Probability','medium','mcq','P(A)=0.5, P(B)=0.4 and P(A∩B)=0.25. Which statement is correct?','["A and B are independent because 0.5+0.4=0.9","A and B are independent because 0.25<0.5","A and B are not independent because 0.5×0.4=0.20≠0.25","A and B are mutually exclusive"]','C','Independence requires P(A∩B)=P(A)P(B). Here 0.5×0.4=0.20, which is not 0.25, so A and B are not independent.','P(A)=0,5, P(B)=0,4 и P(A∩B)=0,25. Какое утверждение верно?','["A и B независимы, потому что 0,5+0,4=0,9","A и B независимы, потому что 0,25<0,5","A и B не независимы, потому что 0,5×0,4=0,20≠0,25","A и B взаимоисключающие"]','Для независимости нужно P(A∩B)=P(A)P(B). Здесь 0,5×0,4=0,20, что не равно 0,25, поэтому A и B не независимы.','P(A)=0.5, P(B)=0.4 va P(A∩B)=0.25. Qaysi fikr to‘g‘ri?','["A va B mustaqil, chunki 0.5+0.4=0.9","A va B mustaqil, chunki 0.25<0.5","A va B mustaqil emas, chunki 0.5×0.4=0.20≠0.25","A va B o‘zaro istisno"]','Mustaqillik uchun P(A∩B)=P(A)P(B) bo‘lishi kerak. Bu yerda 0.5×0.4=0.20, u 0.25 ga teng emas, demak A va B mustaqil emas.',50),
('P5PRO04-A03','P5-PRO-04','P5 Probability','medium','input','Events A and B are independent. P(A)=0.3 and P(A∩B)=0.12. Enter P(B).','[]','0.4','For independent events, P(A∩B)=P(A)P(B). Thus P(B)=0.12/0.3=0.4.','События A и B независимы. P(A)=0,3 и P(A∩B)=0,12. Введите P(B).','[]','Для независимых событий P(A∩B)=P(A)P(B). Поэтому P(B)=0,12/0,3=0,4.','A va B hodisalar mustaqil. P(A)=0.3 va P(A∩B)=0.12. P(B) ni kiriting.','[]','Mustaqil hodisalar uchun P(A∩B)=P(A)P(B). Demak P(B)=0.12/0.3=0.4.',45)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,s.topic,s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P5:p5_aw09_12_alt_learning_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw09_12_alt_learning_draft_v1:'||s.content_key);

insert into private.exam_prep_written_tasks(
 id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
 prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
 lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(15632,4810,'P5DAT03-AW10','P5','P5-DAT-03','{}','v1','Data set A has five-number summary 12, 18, 24, 30, 51. Data set B has five-number summary 10, 16, 26, 34, 43. For each set find the IQR, apply the 1.5×IQR outlier rule to the maximum, then compare the medians and middle-50% spread.','Для набора A пятичисловая сводка: 12, 18, 24, 30, 51. Для набора B: 10, 16, 26, 34, 43. Для каждого набора найдите IQR, примените правило 1,5×IQR к максимальному значению, затем сравните медианы и разброс средней половины данных.','A to‘plamning besh sonli xulosasi: 12, 18, 24, 30, 51. B to‘plam uchun: 10, 16, 26, 34, 43. Har bir to‘plam uchun IQR ni toping, maksimumga 1.5×IQR chet qiymat qoidasini qo‘llang, so‘ng medianalar va o‘rta 50% tarqoqligini taqqoslang.','{"criteria":[{"id":"iqra","rule":"Finds IQR(A)=12.","marks":1},{"id":"outa","rule":"Finds upper fence 48 and identifies 51 as an outlier.","marks":1},{"id":"iqrb","rule":"Finds IQR(B)=18.","marks":1},{"id":"outb","rule":"Finds upper fence 61 and identifies 43 as not an outlier.","marks":1},{"id":"median","rule":"States B has the higher median, 26 versus 24.","marks":1},{"id":"spread","rule":"States A has the smaller IQR and therefore smaller middle-50% spread.","marks":1}],"max_marks":6}'::jsonb,'Use Q3−Q1 for IQR, then Q3+1.5×IQR for the upper fence. Compare median and IQR separately.','Используйте Q3−Q1 для IQR, затем Q3+1,5×IQR для верхней границы. Сравнивайте медиану и IQR отдельно.','IQR uchun Q3−Q1, yuqori chegara uchun Q3+1.5×IQR dan foydalaning. Mediana va IQR ni alohida taqqoslang.','draft','pending','pending','pending','pending'),
(15633,4810,'P5DAT05-AW10','P5','P5-DAT-05','{}','v1','A cumulative-frequency graph represents 160 observations. It gives Q1=18, median=27 and Q3=39, and the cumulative frequency at x=42 is 126. Find the IQR, the number of observations between Q1 and Q3, and the percentage of observations at most 42.','График накопленной частоты представляет 160 наблюдений. По графику Q1=18, медиана=27, Q3=39, а накопленная частота при x=42 равна 126. Найдите IQR, число наблюдений между Q1 и Q3 и процент наблюдений не больше 42.','Kumulyativ chastota grafigida 160 ta kuzatuv bor. Grafikdan Q1=18, mediana=27, Q3=39 va x=42 da kumulyativ chastota 126. IQR ni, Q1 bilan Q3 orasidagi kuzatuvlar sonini va 42 dan katta bo‘lmagan kuzatuvlar foizini toping.','{"criteria":[{"id":"iqr","rule":"Finds IQR=39−18=21.","marks":2},{"id":"middle","rule":"Recognizes Q1 to Q3 contains 50% of 160, so 80 observations.","marks":2},{"id":"pct","rule":"Computes 126/160×100=78.75%.","marks":1},{"id":"interpret","rule":"States the cumulative-frequency meaning for values at most 42.","marks":1}],"max_marks":6}'::jsonb,'Use quartile positions for the middle 50%, and divide cumulative frequency by the total before converting to a percentage.','Для средней половины данных используйте положения квартилей, а накопленную частоту делите на общее число наблюдений перед переводом в проценты.','O‘rta 50% uchun kvartil joylashuvlaridan foydalaning, foizga o‘tishdan oldin kumulyativ chastotani umumiy kuzatuvlar soniga bo‘ling.','draft','pending','pending','pending','pending'),
(15634,4810,'P5DAT07-AW10','P5','P5-DAT-07','{}','v1','A data set has range 12, IQR 5 and standard deviation 2.6. Every value x is transformed to y=3x−4. Find the new range, IQR and standard deviation, and explain why subtracting 4 does not change any of these spread measures.','У набора данных размах 12, IQR 5 и стандартное отклонение 2,6. Каждое значение x преобразуют по формуле y=3x−4. Найдите новые размах, IQR и стандартное отклонение и объясните, почему вычитание 4 не меняет ни одну из этих мер разброса.','Ma’lumotlar to‘plamida oraliq kengligi 12, IQR 5 va standart og‘ish 2.6. Har bir x qiymat y=3x−4 ga o‘zgartiriladi. Yangi oraliq kengligi, IQR va standart og‘ishni toping hamda nega 4 ni ayirish bu tarqoqlik o‘lchovlarini o‘zgartirmasligini tushuntiring.','{"criteria":[{"id":"range","rule":"Finds new range 36.","marks":1},{"id":"iqr","rule":"Finds new IQR 15.","marks":1},{"id":"sd","rule":"Finds new standard deviation 7.8.","marks":2},{"id":"scale","rule":"Explains multiplication by 3 scales all spread measures by 3.","marks":1},{"id":"shift","rule":"Explains subtracting 4 shifts all values equally and does not change differences from each other or the mean.","marks":1}],"max_marks":6}'::jsonb,'Separate the scale factor from the translation. Spread changes with |3|, while a common shift leaves spread unchanged.','Отделите масштабирование от сдвига. Разброс меняется в |3| раз, а общий сдвиг всех значений не меняет разброс.','Masshtab koeffitsiyentini siljishdan ajrating. Tarqoqlik |3| marta o‘zgaradi, umumiy siljish esa tarqoqlikni o‘zgartirmaydi.','draft','pending','pending','pending','pending'),
(15635,4810,'P5CNT05-AW10','P5','P5-CNT-05','{}','v1','A group contains 7 boys and 5 girls. A 4-person committee with exactly 2 girls is selected, then one committee member is appointed chair. Find the total number of possible outcomes and explain where order matters and where it does not.','В группе 7 мальчиков и 5 девочек. Выбирают комитет из 4 человек ровно с 2 девочками, затем одного члена комитета назначают председателем. Найдите общее число возможных исходов и объясните, где порядок важен, а где нет.','Guruhda 7 o‘g‘il va 5 qiz bor. Aynan 2 qiz qatnashadigan 4 kishilik qo‘mita tanlanadi, so‘ng qo‘mita a’zolaridan biri rais etib tayinlanadi. Mumkin bo‘lgan natijalar sonini toping va qayerda tartib muhim, qayerda muhim emasligini tushuntiring.','{"criteria":[{"id":"girls","rule":"Computes 5C2=10.","marks":1},{"id":"boys","rule":"Computes 7C2=21.","marks":1},{"id":"committee","rule":"Finds 10×21=210 committees.","marks":1},{"id":"chair","rule":"Multiplies by 4 chair choices.","marks":1},{"id":"total","rule":"Obtains 840 outcomes.","marks":1},{"id":"reason","rule":"Explains committee selection is unordered but the chair role distinguishes outcomes.","marks":1}],"max_marks":6}'::jsonb,'Count the committee first with combinations, then count the role assignment separately.','Сначала посчитайте комитеты с помощью сочетаний, затем отдельно учтите назначение роли.','Avval qo‘mitani kombinatsiyalar bilan sanang, keyin rol tayinlashni alohida hisoblang.','draft','pending','pending','pending','pending'),
(15636,4810,'P5PRO02-AW10','P5','P5-PRO-02','{}','v1','A bag contains 8 red and 4 blue counters. Three counters are chosen without replacement. Using combinations, find the probability of exactly 2 red counters and the probability of at least 1 blue counter. Give both answers in simplest form.','В мешке 8 красных и 4 синих фишки. Без возвращения выбирают 3 фишки. Используя сочетания, найдите вероятность ровно 2 красных фишек и вероятность хотя бы 1 синей фишки. Сократите оба ответа.','Qopda 8 qizil va 4 ko‘k jeton bor. Qaytarmasdan 3 ta jeton tanlanadi. Kombinatsiyalardan foydalanib, aynan 2 ta qizil va kamida 1 ta ko‘k jeton tanlash ehtimollarini toping. Ikkala javobni ham qisqartiring.','{"criteria":[{"id":"total","rule":"Uses total 12C3=220.","marks":1},{"id":"exact","rule":"Uses 8C2×4C1=112 and obtains 28/55.","marks":2},{"id":"noneblue","rule":"Uses 8C3=56 for no blue.","marks":1},{"id":"atleast","rule":"Obtains 1−56/220=41/55.","marks":1},{"id":"reason","rule":"Explains why combinations are appropriate for unordered selections.","marks":1}],"max_marks":6}'::jsonb,'Use the same total sample space for both parts. For at least one blue, the complement of no blue is shorter.','Используйте одно и то же общее пространство исходов в обеих частях. Для «хотя бы одна синяя» удобнее взять дополнение события «ни одной синей».','Har ikki qism uchun bir xil umumiy natijalar fazosidan foydalaning. Kamida bitta ko‘k uchun ko‘k yo‘q hodisasining to‘ldiruvchisini olish osonroq.','draft','pending','pending','pending','pending'),
(15637,4810,'P5PRO04-AW10','P5','P5-PRO-04','{}','v1','For events A and B, P(A)=0.55, P(B)=0.32 and P(B|A)=0.40. Find P(A∩B), then P(A|B), and determine whether A and B are independent. Justify the independence decision numerically.','Для событий A и B даны P(A)=0,55, P(B)=0,32 и P(B|A)=0,40. Найдите P(A∩B), затем P(A|B) и определите, независимы ли A и B. Обоснуйте решение численно.','A va B hodisalar uchun P(A)=0.55, P(B)=0.32 va P(B|A)=0.40. P(A∩B) ni, so‘ng P(A|B) ni toping va A hamda B mustaqil ekanini aniqlang. Mustaqillik haqidagi xulosani sonlar bilan asoslang.','{"criteria":[{"id":"intersection","rule":"Finds P(A∩B)=0.55×0.40=0.22.","marks":2},{"id":"cond","rule":"Finds P(A|B)=0.22/0.32=0.6875.","marks":2},{"id":"product","rule":"Computes P(A)P(B)=0.176.","marks":1},{"id":"decision","rule":"Concludes not independent because 0.22≠0.176.","marks":1}],"max_marks":6}'::jsonb,'Use the multiplication rule first. Then compare the intersection with P(A)P(B), rather than comparing the conditional probabilities informally.','Сначала примените правило умножения. Затем сравните пересечение с P(A)P(B), а не делайте вывод по условным вероятностям без вычисления.','Avval ko‘paytirish qoidasidan foydalaning. Keyin kesishma ehtimolini P(A)P(B) bilan solishtiring; shartli ehtimollarni norasmiy taqqoslab xulosa qilmang.','draft','pending','pending','pending','pending')
on conflict (id) do nothing;

with src(content_key,skill_code,meta_id) as (values
('P5DAT03-A01','P5-DAT-03',59182),
('P5DAT03-A02','P5-DAT-03',59183),
('P5DAT03-A03','P5-DAT-03',59184),
('P5DAT05-A01','P5-DAT-05',59185),
('P5DAT05-A02','P5-DAT-05',59186),
('P5DAT05-A03','P5-DAT-05',59187),
('P5DAT07-A01','P5-DAT-07',59188),
('P5DAT07-A02','P5-DAT-07',59189),
('P5DAT07-A03','P5-DAT-07',59190),
('P5CNT05-A01','P5-CNT-05',59191),
('P5CNT05-A02','P5-CNT-05',59192),
('P5CNT05-A03','P5-CNT-05',59193),
('P5PRO02-A01','P5-PRO-02',59194),
('P5PRO02-A02','P5-PRO-02',59195),
('P5PRO02-A03','P5-PRO-02',59196),
('P5PRO04-A01','P5-PRO-04',59197),
('P5PRO04-A02','P5-PRO-04',59198),
('P5PRO04-A03','P5-PRO-04',59199)
), cv as (select id from private.exam_prep_content_versions where id=4810)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,cv.id,s.content_key,qn.id,s.skill_code,'{}'::text[],'learning','withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'Supplemental AW9-12 learning draft authored from the canonical skill intent with independent values and contexts, separate from the existing teaching pack.',
 case s.skill_code
 when 'P5-DAT-03' then 'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data'
 when 'P5-DAT-05' then 'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data'
 when 'P5-DAT-07' then 'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data'
 when 'P5-CNT-05' then 'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations'
 when 'P5-PRO-02' then 'Cambridge 9709 2026-2027 v4; P5 5.3 Probability'
 when 'P5-PRO-04' then 'Cambridge 9709 2026-2027 v4; P5 5.3 Probability'
 end,
 case s.skill_code
 when 'P5-DAT-03' then 'Complete Probability & Statistics 1, Ch3 pp.34-59 (mapping only)'
 when 'P5-DAT-05' then 'Complete Probability & Statistics 1, Ch3 pp.34-59 (mapping only)'
 when 'P5-DAT-07' then 'Complete Probability & Statistics 1, Ch2 pp.14-29 (mapping only)'
 when 'P5-CNT-05' then 'Complete Probability & Statistics 1, Ch6 pp.98-111 (mapping only)'
 when 'P5-PRO-02' then 'Complete Probability & Statistics 1, Ch4 pp.63-82 (mapping only)'
 when 'P5-PRO-04' then 'Complete Probability & Statistics 1, Ch4 pp.63-82 (mapping only)'
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
join public.questions qn on qn.book_ref='ExamPrep:P5:p5_aw09_12_alt_learning_draft_v1:'||s.content_key
on conflict (id) do nothing;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35381,4810,'P5-DAT-03-learning-alt-02','v1','P5','learning','draft','Data: box plots and outliers - supplemental learning','Данные: диаграммы размаха и выбросы — дополнительное обучение','Ma’lumotlar: box plot va chet qiymatlar — qo‘shimcha o‘rganish'),
(35382,4810,'P5-DAT-05-learning-alt-02','v1','P5','learning','draft','Data: cumulative frequency - supplemental learning','Данные: накопленная частота — дополнительное обучение','Ma’lumotlar: kumulyativ chastota — qo‘shimcha o‘rganish'),
(35383,4810,'P5-DAT-07-learning-alt-02','v1','P5','learning','draft','Data: measures of spread - supplemental learning','Данные: меры разброса — дополнительное обучение','Ma’lumotlar: tarqoqlik o‘lchovlari — qo‘shimcha o‘rganish'),
(35384,4810,'P5-CNT-05-learning-alt-02','v1','P5','learning','draft','Counting: combinations and mixed selection - supplemental learning','Подсчёт: сочетания и смешанный выбор — дополнительное обучение','Sanash: kombinatsiyalar va aralash tanlash — qo‘shimcha o‘rganish'),
(35385,4810,'P5-PRO-02-learning-alt-02','v1','P5','learning','draft','Probability: combinations - supplemental learning','Вероятность: сочетания — дополнительное обучение','Ehtimollik: kombinatsiyalar — qo‘shimcha o‘rganish'),
(35386,4810,'P5-PRO-04-learning-alt-02','v1','P5','learning','draft','Probability: multiplication and independence - supplemental learning','Вероятность: правило умножения и независимость — дополнительное обучение','Ehtimollik: ko‘paytirish qoidasi va mustaqillik — qo‘shimcha o‘rganish')
on conflict (id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
(35381,1,'P5DAT03-A01',null::bigint,'P5-DAT-03'),
(35381,2,'P5DAT03-A02',null::bigint,'P5-DAT-03'),
(35381,3,'P5DAT03-A03',null::bigint,'P5-DAT-03'),
(35381,4,null,15632,'P5-DAT-03'),
(35382,1,'P5DAT05-A01',null::bigint,'P5-DAT-05'),
(35382,2,'P5DAT05-A02',null::bigint,'P5-DAT-05'),
(35382,3,'P5DAT05-A03',null::bigint,'P5-DAT-05'),
(35382,4,null,15633,'P5-DAT-05'),
(35383,1,'P5DAT07-A01',null::bigint,'P5-DAT-07'),
(35383,2,'P5DAT07-A02',null::bigint,'P5-DAT-07'),
(35383,3,'P5DAT07-A03',null::bigint,'P5-DAT-07'),
(35383,4,null,15634,'P5-DAT-07'),
(35384,1,'P5CNT05-A01',null::bigint,'P5-CNT-05'),
(35384,2,'P5CNT05-A02',null::bigint,'P5-CNT-05'),
(35384,3,'P5CNT05-A03',null::bigint,'P5-CNT-05'),
(35384,4,null,15635,'P5-CNT-05'),
(35385,1,'P5PRO02-A01',null::bigint,'P5-PRO-02'),
(35385,2,'P5PRO02-A02',null::bigint,'P5-PRO-02'),
(35385,3,'P5PRO02-A03',null::bigint,'P5-PRO-02'),
(35385,4,null,15636,'P5-PRO-02'),
(35386,1,'P5PRO04-A01',null::bigint,'P5-PRO-04'),
(35386,2,'P5PRO04-A02',null::bigint,'P5-PRO-04'),
(35386,3,'P5PRO04-A03',null::bigint,'P5-PRO-04'),
(35386,4,null,15637,'P5-PRO-04')
)
insert into private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select i.assessment_id,i.item_order,qn.id,i.written_id,i.skill_code,
 case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions qn on i.content_key is not null
 and qn.book_ref='ExamPrep:P5:p5_aw09_12_alt_learning_draft_v1:'||i.content_key
on conflict (assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select status from private.exam_prep_content_versions where id=4810)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4810 and lifecycle_state='draft' and reserve_role='learning')<>18
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4810 and lifecycle_state='draft')<>6
     or (select count(*) from private.exam_prep_assessments where content_version_id=4810 and status='draft' and assessment_type='learning')<>6
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4810)<>24
  then raise exception 'aw09_12_alt_p5_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4810 and (
    m.exposure_state<>'withheld' or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or qn.is_active or qn.quality_status<>'draft'
  );
  if v_bad<>0 then raise exception 'aw09_12_alt_p5_draft exposure/QA boundary rows=%',v_bad; end if;

  select
    count(*) filter(where qn.correct_answer='A'),
    count(*) filter(where qn.correct_answer='B'),
    count(*) filter(where qn.correct_answer='C'),
    count(*) filter(where qn.correct_answer='D'),
    count(*) filter(where qn.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4810;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(3,3,3,3,6) then
    raise exception 'aw09_12_alt_p5_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions qn on qn.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4810
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4810
      and lower(regexp_replace(qn.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw09_12_alt_p5_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4810)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4810)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4810)
  then raise exception 'aw09_12_alt_p5_draft unexpected history'; end if;
end
$postcheck$;

commit;
