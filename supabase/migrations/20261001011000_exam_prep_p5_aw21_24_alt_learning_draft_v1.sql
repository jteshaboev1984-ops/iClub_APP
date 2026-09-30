-- AW21-24 supplemental learning pack draft for P5.
-- DRAFT ONLY: no learner exposure, QA self-approval or publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw21_24_alt_p5_draft canonical program missing'; end if;
  if exists(select 1 from private.exam_prep_content_versions where id=4822 and content_version<>'p5_aw21_24_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15674 and 15681 and content_version_id<>4822)
     or exists(select 1 from private.exam_prep_assessments where id between 35521 and 35528 and content_version_id<>4822)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59508 and 59531 and content_version_id<>4822)
  then raise exception 'aw21_24_alt_p5_draft reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4822,pv.id,'p5_aw21_24_alt_learning_draft_v1','P5',
 'P5 AW21-24 supplemental learning pack draft v1','draft',
 'Original iClub-authored supplemental learning content. Official Cambridge 9709 scope and Complete Probability & Statistics 1 mappings define learning objectives only; no protected source question, solution, diagram or mark-scheme wording is copied. Independent academic, language, technical and copyright QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,topic,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P5DAT08-A01','P5-DAT-08','P5 Data Representation','medium','mcq','Class A has median 50 and IQR 8. Class B has median 54 and IQR 14. Which comparison is supported?','["B has the higher typical value, but A is more consistent","A has the higher typical value and is more spread out","B is more consistent because its median is larger","The two classes have the same location and spread"]','A','The median measures location and the IQR measures spread. B has the higher median, while A has the smaller IQR.','У класса A медиана 50 и IQR 8. У класса B медиана 54 и IQR 14. Какое сравнение подтверждается?','["У B выше типичное значение, но A более стабилен","У A выше типичное значение и больше разброс","B более стабилен, потому что его медиана больше","У двух классов одинаковые положение и разброс"]','Медиана характеризует положение, а IQR — разброс. У B медиана выше, а у A IQR меньше.','A sinfda mediana 50 va IQR 8. B sinfda mediana 54 va IQR 14. Qaysi taqqoslash asosli?','["B ning odatiy qiymati yuqoriroq, lekin A barqarorroq","A ning odatiy qiymati yuqoriroq va tarqalishi kattaroq","B medianasi kattaroq bo‘lgani uchun barqarorroq","Ikki sinfning markazi va tarqalishi bir xil"]','Mediana markazni, IQR esa tarqalishni ko‘rsatadi. B medianasi yuqori, A ning IQR i kichik.',55),
('P5DAT08-A02','P5-DAT-08','P5 Data Representation','medium','mcq','Two datasets both have mean 20. Dataset A has standard deviation 3 and dataset B has standard deviation 6. Which statement is correct?','["B has the smaller spread","A has the smaller spread","A has the larger mean","The datasets must contain the same values"]','B','The means are equal, but the smaller standard deviation shows that A is less spread out.','Два набора данных имеют среднее 20. У набора A стандартное отклонение 3, у B — 6. Какое утверждение верно?','["У B меньше разброс","У A меньше разброс","У A больше среднее","Наборы обязательно содержат одинаковые значения"]','Средние равны, но меньшее стандартное отклонение означает, что у A меньше разброс.','Ikki ma’lumot to‘plamining o‘rtachasi 20. A ning standart og‘ishi 3, B ning 6. Qaysi fikr to‘g‘ri?','["B ning tarqalishi kichikroq","A ning tarqalishi kichikroq","A ning o‘rtachasi kattaroq","To‘plamlar aynan bir xil qiymatlardan iborat bo‘lishi shart"]','O‘rtachalar teng, lekin kichik standart og‘ish A ning tarqalishi kamroq ekanini ko‘rsatadi.',50),
('P5DAT08-A03','P5-DAT-08','P5 Data Representation','easy','input','Dataset A has median 42 and dataset B has median 47. Enter the difference between the medians.','[]','5','The difference is 47−42=5.','У набора A медиана 42, у набора B медиана 47. Введите разность медиан.','[]','Разность равна 47−42=5.','A to‘plam medianasi 42, B to‘plam medianasi 47. Medianalar farqini kiriting.','[]','Farq 47−42=5.',35),
('P5DAT09-A01','P5-DAT-09','P5 Data Representation','medium','mcq','For n=6 observations, Σx=54 and Σx²=510. Using variance = Σx²/n − mean², find the mean and standard deviation.','["mean 8, standard deviation 2","mean 9, standard deviation 4","mean 9, standard deviation 2","mean 8, standard deviation 4"]','C','The mean is 54/6=9. Variance=510/6−9²=85−81=4, so standard deviation=2.','Для n=6 наблюдений Σx=54 и Σx²=510. Используя variance = Σx²/n − mean², найдите среднее и стандартное отклонение.','["среднее 8, стандартное отклонение 2","среднее 9, стандартное отклонение 4","среднее 9, стандартное отклонение 2","среднее 8, стандартное отклонение 4"]','Среднее 54/6=9. Дисперсия=510/6−9²=85−81=4, поэтому стандартное отклонение равно 2.','n=6 kuzatuv uchun Σx=54 va Σx²=510. variance = Σx²/n − mean² dan foydalanib o‘rtacha va standart og‘ishni toping.','["o‘rtacha 8, standart og‘ish 2","o‘rtacha 9, standart og‘ish 4","o‘rtacha 9, standart og‘ish 2","o‘rtacha 8, standart og‘ish 4"]','O‘rtacha 54/6=9. Dispersiya=510/6−9²=85−81=4, demak standart og‘ish 2.',65),
('P5DAT09-A02','P5-DAT-09','P5 Data Representation','medium','mcq','The values 1, 2 and 3 have frequencies 2, 3 and 5 respectively. What is the mean?','["2.0","2.1","2.2","2.3"]','D','The total frequency is 10 and Σfx=1(2)+2(3)+3(5)=23, so the mean is 23/10=2.3.','Значения 1, 2 и 3 имеют частоты 2, 3 и 5 соответственно. Чему равно среднее?','["2,0","2,1","2,2","2,3"]','Общая частота 10, а Σfx=1(2)+2(3)+3(5)=23, поэтому среднее равно 23/10=2,3.','1, 2 va 3 qiymatlarining chastotalari mos ravishda 2, 3 va 5. O‘rtacha nechaga teng?','["2.0","2.1","2.2","2.3"]','Umumiy chastota 10, Σfx=1(2)+2(3)+3(5)=23, demak o‘rtacha 23/10=2.3.',55),
('P5DAT09-A03','P5-DAT-09','P5 Data Representation','easy','input','For 8 observations, Σx=96. Enter the mean.','[]','12','Mean=Σx/n=96/8=12.','Для 8 наблюдений Σx=96. Введите среднее.','[]','Среднее=Σx/n=96/8=12.','8 ta kuzatuv uchun Σx=96. O‘rtachani kiriting.','[]','O‘rtacha=Σx/n=96/8=12.',35),
('P5DAT10-A01','P5-DAT-10','P5 Data Representation','medium','mcq','Group A has 15 values with mean 24. Group B has 25 values with mean 30. Find the combined mean.','["27.75","27.00","28.50","54.00"]','A','The combined total is 15(24)+25(30)=1110 across 40 values, so the mean is 1110/40=27.75.','В группе A 15 значений со средним 24. В группе B 25 значений со средним 30. Найдите объединённое среднее.','["27,75","27,00","28,50","54,00"]','Общая сумма 15(24)+25(30)=1110 для 40 значений, поэтому среднее 1110/40=27,75.','A guruhda 15 ta qiymat, o‘rtacha 24. B guruhda 25 ta qiymat, o‘rtacha 30. Birlashtirilgan o‘rtachani toping.','["27.75","27.00","28.50","54.00"]','Umumiy yig‘indi 15(24)+25(30)=1110, 40 ta qiymat uchun o‘rtacha 1110/40=27.75.',60),
('P5DAT10-A02','P5-DAT-10','P5 Data Representation','medium','mcq','A variable is coded by y=(x−50)/5. If the mean of y is 2.4, what is the mean of x?','["60","62","52.4","250"]','B','Since x=50+5y, the mean transforms in the same linear way: mean x=50+5(2.4)=62.','Переменная кодируется формулой y=(x−50)/5. Если среднее y равно 2,4, чему равно среднее x?','["60","62","52,4","250"]','Так как x=50+5y, среднее преобразуется линейно: среднее x=50+5(2,4)=62.','O‘zgaruvchi y=(x−50)/5 bilan kodlangan. y ning o‘rtachasi 2.4 bo‘lsa, x ning o‘rtachasi qancha?','["60","62","52.4","250"]','x=50+5y bo‘lgani uchun o‘rtacha ham shu chiziqli usulda o‘zgaradi: x o‘rtachasi=50+5(2.4)=62.',55),
('P5DAT10-A03','P5-DAT-10','P5 Data Representation','medium','input','Group A has 12 values with total 180. Group B has 8 values. The combined mean is 17.5. Enter the mean of group B.','[]','21.25','The combined total is 20(17.5)=350. Group B total=350−180=170, so its mean is 170/8=21.25.','В группе A 12 значений с суммой 180. В группе B 8 значений. Объединённое среднее равно 17,5. Введите среднее группы B.','[]','Общая сумма равна 20(17,5)=350. Сумма группы B=350−180=170, поэтому её среднее 170/8=21,25.','A guruhda 12 ta qiymat va yig‘indi 180. B guruhda 8 ta qiymat. Birlashtirilgan o‘rtacha 17.5. B guruh o‘rtachasini kiriting.','[]','Umumiy yig‘indi 20(17.5)=350. B guruh yig‘indisi 350−180=170, o‘rtachasi 170/8=21.25.',65),
('P5NOR02-A01','P5-NOR-02','P5 Normal Distribution','medium','mcq','X~N(50,16). What is the standardised z-value for X=58?','["0.5","1","2","4"]','C','The standard deviation is √16=4, so z=(58−50)/4=2.','X~N(50,16). Чему равно стандартизированное z для X=58?','["0,5","1","2","4"]','Стандартное отклонение √16=4, поэтому z=(58−50)/4=2.','X~N(50,16). X=58 uchun standartlashtirilgan z qiymati nechaga teng?','["0.5","1","2","4"]','Standart og‘ish √16=4, demak z=(58−50)/4=2.',45),
('P5NOR02-A02','P5-NOR-02','P5 Normal Distribution','medium','mcq','X~N(100,25). What is the z-value corresponding to X=90?','["−0.4","−1","−5","−2"]','D','The standard deviation is 5, so z=(90−100)/5=−2.','X~N(100,25). Какому z соответствует X=90?','["−0,4","−1","−5","−2"]','Стандартное отклонение 5, поэтому z=(90−100)/5=−2.','X~N(100,25). X=90 ga mos z qiymati qaysi?','["−0.4","−1","−5","−2"]','Standart og‘ish 5, demak z=(90−100)/5=−2.',45),
('P5NOR02-A03','P5-NOR-02','P5 Normal Distribution','easy','input','X~N(30,9). Enter the z-value corresponding to X=36.','[]','2','The standard deviation is 3, so z=(36−30)/3=2.','X~N(30,9). Введите z, соответствующее X=36.','[]','Стандартное отклонение 3, поэтому z=(36−30)/3=2.','X~N(30,9). X=36 ga mos z qiymatini kiriting.','[]','Standart og‘ish 3, demak z=(36−30)/3=2.',40),
('P5NOR03-A01','P5-NOR-03','P5 Normal Distribution','medium','mcq','X~N(40,16). Find P(X<44), to 4 d.p.','["0.8413","0.1587","0.9772","0.5000"]','A','σ=4 and z=(44−40)/4=1. Hence P(X<44)=P(Z<1)=0.8413.','X~N(40,16). Найдите P(X<44) до 4 знаков.','["0,8413","0,1587","0,9772","0,5000"]','σ=4 и z=(44−40)/4=1. Поэтому P(X<44)=P(Z<1)=0,8413.','X~N(40,16). P(X<44) ni 4 xonagacha toping.','["0.8413","0.1587","0.9772","0.5000"]','σ=4 va z=(44−40)/4=1. Shuning uchun P(X<44)=P(Z<1)=0.8413.',55),
('P5NOR03-A02','P5-NOR-03','P5 Normal Distribution','medium','mcq','X~N(70,25). Find P(X>77.5), to 4 d.p.','["0.9332","0.0668","0.8413","0.1587"]','B','σ=5 and z=(77.5−70)/5=1.5. Thus P(X>77.5)=1−Φ(1.5)=0.0668.','X~N(70,25). Найдите P(X>77,5) до 4 знаков.','["0,9332","0,0668","0,8413","0,1587"]','σ=5 и z=(77,5−70)/5=1,5. Поэтому P(X>77,5)=1−Φ(1,5)=0,0668.','X~N(70,25). P(X>77.5) ni 4 xonagacha toping.','["0.9332","0.0668","0.8413","0.1587"]','σ=5 va z=(77.5−70)/5=1.5. Demak P(X>77.5)=1−Φ(1.5)=0.0668.',60),
('P5NOR03-A03','P5-NOR-03','P5 Normal Distribution','medium','input','X~N(10,4). Enter P(8<X<12) to 4 d.p.','[]','0.6827','σ=2, so the bounds standardise to −1 and 1. P(−1<Z<1)=0.6827 to 4 d.p.','X~N(10,4). Введите P(8<X<12) до 4 знаков.','[]','σ=2, поэтому границы стандартизируются в −1 и 1. P(−1<Z<1)=0,6827 до 4 знаков.','X~N(10,4). P(8<X<12) ni 4 xonagacha kiriting.','[]','σ=2, chegaralar −1 va 1 ga standartlanadi. P(−1<Z<1)=0.6827, 4 xonagacha.',60),
('P5NOR04-A01','P5-NOR-04','P5 Normal Distribution','hard','mcq','X~N(100,16). Approximately what is the 90th percentile of X?','["101.3","104.0","105.1","106.6"]','C','For cumulative probability 0.90, z≈1.2816. Thus x=100+4(1.2816)=105.1264≈105.1.','X~N(100,16). Чему приблизительно равен 90-й процентиль X?','["101,3","104,0","105,1","106,6"]','Для накопленной вероятности 0,90 z≈1,2816. Поэтому x=100+4(1,2816)=105,1264≈105,1.','X~N(100,16). X ning 90-percentili taxminan nechaga teng?','["101.3","104.0","105.1","106.6"]','Cumulative probability 0.90 uchun z≈1.2816. Demak x=100+4(1.2816)=105.1264≈105.1.',75),
('P5NOR04-A02','P5-NOR-04','P5 Normal Distribution','hard','mcq','X~N(50,9). Approximately what is the lower 2.5th percentile?','["47.1","45.1","44.7","44.1"]','D','For cumulative probability 0.025, z≈−1.960. Thus x=50+3(−1.960)=44.12≈44.1.','X~N(50,9). Чему приблизительно равен нижний 2,5-й процентиль?','["47,1","45,1","44,7","44,1"]','Для накопленной вероятности 0,025 z≈−1,960. Поэтому x=50+3(−1,960)=44,12≈44,1.','X~N(50,9). Pastki 2.5-percentil taxminan nechaga teng?','["47.1","45.1","44.7","44.1"]','Cumulative probability 0.025 uchun z≈−1.960. Demak x=50+3(−1.960)=44.12≈44.1.',75),
('P5NOR04-A03','P5-NOR-04','P5 Normal Distribution','medium','input','Enter the 95th percentile z-value of the standard normal distribution to 3 d.p.','[]','1.645','The standard-normal value satisfying P(Z<z)=0.95 is z≈1.645.','Введите z 95-го процентиля стандартного нормального распределения до 3 знаков.','[]','Значение стандартной нормали, для которого P(Z<z)=0,95, равно z≈1,645.','Standart normal taqsimotning 95-percentil z qiymatini 3 xonagacha kiriting.','[]','P(Z<z)=0.95 ni qanoatlantiradigan standart normal qiymat z≈1.645.',55),
('P5NOR05-A01','P5-NOR-05','P5 Normal Distribution','hard','mcq','X~N(μ,16) and P(X<58)=0.8413. Find μ.','["54","58","62","50"]','A','0.8413 corresponds to z=1. Since σ=4, (58−μ)/4=1, giving μ=54.','X~N(μ,16) и P(X<58)=0,8413. Найдите μ.','["54","58","62","50"]','0,8413 соответствует z=1. Так как σ=4, (58−μ)/4=1, откуда μ=54.','X~N(μ,16) va P(X<58)=0.8413. μ ni toping.','["54","58","62","50"]','0.8413 z=1 ga mos. σ=4, shuning uchun (58−μ)/4=1 va μ=54.',70),
('P5NOR05-A02','P5-NOR-05','P5 Normal Distribution','hard','mcq','X~N(70,σ²) and P(X<80)=0.9772. Find σ.','["2","5","10","25"]','B','0.9772 corresponds to z=2. Hence (80−70)/σ=2, so σ=5.','X~N(70,σ²) и P(X<80)=0,9772. Найдите σ.','["2","5","10","25"]','0,9772 соответствует z=2. Поэтому (80−70)/σ=2, откуда σ=5.','X~N(70,σ²) va P(X<80)=0.9772. σ ni toping.','["2","5","10","25"]','0.9772 z=2 ga mos. Demak (80−70)/σ=2 va σ=5.',70),
('P5NOR05-A03','P5-NOR-05','P5 Normal Distribution','hard','input','X~N(μ,36) and P(X<46)=0.1587. Enter μ.','[]','52','0.1587 corresponds to z=−1. Since σ=6, (46−μ)/6=−1, so μ=52.','X~N(μ,36) и P(X<46)=0,1587. Введите μ.','[]','0,1587 соответствует z=−1. Так как σ=6, (46−μ)/6=−1, поэтому μ=52.','X~N(μ,36) va P(X<46)=0.1587. μ ni kiriting.','[]','0.1587 z=−1 ga mos. σ=6, demak (46−μ)/6=−1 va μ=52.',70),
('P5NOR06-A01','P5-NOR-06','P5 Normal Distribution','hard','mcq','X~Bin(200,0.4). Which normal-approximation setup is correct for P(X≤90)?','["Y~N(80,48) and use P(Y<90)","Y~N(80,√48) and use P(Y<90.5)","Y~N(80,48) and use P(Y<90.5)","Y~N(120,48) and use P(Y<90.5)"]','C','For Bin(n,p), mean=np=80 and variance=np(1−p)=48. Continuity correction changes X≤90 to Y<90.5.','X~Bin(200,0,4). Какая запись normal approximation верна для P(X≤90)?','["Y~N(80,48) и P(Y<90)","Y~N(80,√48) и P(Y<90,5)","Y~N(80,48) и P(Y<90,5)","Y~N(120,48) и P(Y<90,5)"]','Для Bin(n,p): среднее np=80, дисперсия np(1−p)=48. Continuity correction заменяет X≤90 на Y<90,5.','X~Bin(200,0.4). P(X≤90) uchun qaysi normal approximation to‘g‘ri?','["Y~N(80,48) va P(Y<90)","Y~N(80,√48) va P(Y<90.5)","Y~N(80,48) va P(Y<90.5)","Y~N(120,48) va P(Y<90.5)"]','Bin(n,p) uchun mean=np=80 va variance=np(1−p)=48. Continuity correction X≤90 ni Y<90.5 ga o‘zgartiradi.',70),
('P5NOR06-A02','P5-NOR-06','P5 Normal Distribution','hard','mcq','X~Bin(100,0.3). Which normal-approximation event corresponds to P(X≥35)?','["Y≥35 for Y~N(30,21)","Y>35.5 for Y~N(30,21)","Y>34.5 for Y~N(30,√21)","Y>34.5 for Y~N(30,21)"]','D','The approximating normal has mean 30 and variance 21. Continuity correction changes X≥35 to Y>34.5.','X~Bin(100,0,3). Какое событие normal approximation соответствует P(X≥35)?','["Y≥35 для Y~N(30,21)","Y>35,5 для Y~N(30,21)","Y>34,5 для Y~N(30,√21)","Y>34,5 для Y~N(30,21)"]','Аппроксимирующая нормаль имеет среднее 30 и дисперсию 21. Continuity correction заменяет X≥35 на Y>34,5.','X~Bin(100,0.3). P(X≥35) ga qaysi normal approximation hodisasi mos?','["Y≥35, Y~N(30,21)","Y>35.5, Y~N(30,21)","Y>34.5, Y~N(30,√21)","Y>34.5, Y~N(30,21)"]','Yaqinlashtiruvchi normal taqsimot mean 30 va variance 21 ga ega. Continuity correction X≥35 ni Y>34.5 ga o‘zgartiradi.',70),
('P5NOR06-A03','P5-NOR-06','P5 Normal Distribution','medium','input','For X~Bin(50,0.5), enter the variance used in the normal approximation.','[]','12.5','The binomial variance is np(1−p)=50(0.5)(0.5)=12.5.','Для X~Bin(50,0,5) введите дисперсию, используемую в normal approximation.','[]','Биномиальная дисперсия np(1−p)=50(0,5)(0,5)=12,5.','X~Bin(50,0.5) uchun normal approximation da ishlatiladigan dispersiyani kiriting.','[]','Binomial dispersiya np(1−p)=50(0.5)(0.5)=12.5.',50)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,s.topic,s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P5:p5_aw21_24_alt_learning_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw21_24_alt_learning_draft_v1:'||s.content_key);

insert into private.exam_prep_written_tasks(
 id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
 prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
 lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(15674,4822,'P5DAT08-AW22','P5','P5-DAT-08','{}'::text[],'v1','Two classes sit the same test. Class A has median 68 and IQR 12; Class B has median 72 and IQR 20. Compare the location and spread, then write a contextual conclusion about typical performance and consistency. State what cannot be concluded from these summaries alone.','Два класса пишут один и тот же тест. У класса A медиана 68 и IQR 12; у класса B медиана 72 и IQR 20. Сравните положение и разброс, затем сделайте контекстный вывод о типичном результате и стабильности. Укажите, чего нельзя заключить только по этим показателям.','Ikki sinf bir xil testni topshiradi. A sinf medianasi 68 va IQR 12; B sinf medianasi 72 va IQR 20. Markaz va tarqalishni taqqoslang, odatiy natija va barqarorlik haqida kontekstli xulosa yozing. Faqat shu ko‘rsatkichlardan nimalarni xulosa qilib bo‘lmasligini ayting.','{"max_marks":6,"criteria":[{"id":"location","marks":1,"rule":"States B has the higher median."},{"id":"spread","marks":1,"rule":"States A has the smaller IQR."},{"id":"typical","marks":1,"rule":"Interprets B as having higher typical performance."},{"id":"consistency","marks":1,"rule":"Interprets A as more consistent/less spread."},{"id":"context","marks":1,"rule":"Uses the test context correctly."},{"id":"limit","marks":1,"rule":"States a valid limitation, e.g. no claim about every student or distribution shape."}]}'::jsonb,'Separate location from spread: compare medians first, then IQRs. Do not turn a summary statistic into a claim about every observation.','Сначала отдельно сравните положение по медианам, затем разброс по IQR. Не превращайте сводный показатель в утверждение о каждом наблюдении.','Avval markazni medianalar bilan, so‘ng tarqalishni IQR bilan alohida taqqoslang. Umumiy ko‘rsatkichni har bir kuzatuv haqidagi da’voga aylantirmang.','draft','pending','pending','pending','pending'),
(15675,4822,'P5DAT09-AW22','P5','P5-DAT-09','{}'::text[],'v1','For the data 2, 4, 5, 7, 7, 11, calculate the mean and standard deviation using variance = Σx²/n − mean². Show Σx, Σx², the variance and the final standard deviation.','Для данных 2, 4, 5, 7, 7, 11 вычислите среднее и стандартное отклонение по формуле variance = Σx²/n − mean². Покажите Σx, Σx², дисперсию и итоговое стандартное отклонение.','2, 4, 5, 7, 7, 11 ma’lumotlari uchun variance = Σx²/n − mean² formulasi bilan o‘rtacha va standart og‘ishni hisoblang. Σx, Σx², dispersiya va yakuniy standart og‘ishni ko‘rsating.','{"max_marks":6,"criteria":[{"id":"sum","marks":1,"rule":"Gets Σx=36."},{"id":"mean","marks":1,"rule":"Gets mean=6."},{"id":"sumsq","marks":1,"rule":"Gets Σx²=264."},{"id":"variance","marks":2,"rule":"Gets variance=264/6−36=8."},{"id":"sd","marks":1,"rule":"Gets standard deviation=√8 (about 2.83)."}]}'::jsonb,'Build Σx and Σx² separately before substituting into the variance formula. The standard deviation is the positive square root of the variance.','Сначала отдельно найдите Σx и Σx², затем подставьте их в формулу дисперсии. Стандартное отклонение — положительный квадратный корень из дисперсии.','Avval Σx va Σx² ni alohida toping, keyin dispersiya formulasiga qo‘ying. Standart og‘ish dispersiyaning musbat kvadrat ildizidir.','draft','pending','pending','pending','pending'),
(15676,4822,'P5DAT10-AW22','P5','P5-DAT-10','{}'::text[],'v1','Twenty observations are coded by y=(x−40)/5 and have Σy=36. Find the mean of the original x-values. A second group has 10 observations with mean 55. Find the combined mean of all 30 original observations.','20 наблюдений закодированы формулой y=(x−40)/5 и имеют Σy=36. Найдите среднее исходных x. Вторая группа содержит 10 наблюдений со средним 55. Найдите объединённое среднее всех 30 исходных наблюдений.','20 ta kuzatuv y=(x−40)/5 bilan kodlangan va Σy=36. Asl x qiymatlarining o‘rtachasini toping. Ikkinchi guruhda 10 ta kuzatuv va o‘rtacha 55. Barcha 30 ta asl kuzatuvning birlashtirilgan o‘rtachasini toping.','{"max_marks":6,"criteria":[{"id":"codedmean","marks":1,"rule":"Gets mean y=36/20=1.8."},{"id":"transform","marks":2,"rule":"Uses x=40+5y to get mean x=49."},{"id":"total1","marks":1,"rule":"Gets first-group total 20×49=980."},{"id":"total2","marks":1,"rule":"Gets second-group total 10×55=550."},{"id":"combined","marks":1,"rule":"Gets combined mean 1530/30=51."}]}'::jsonb,'Undo the coding on the mean using x=40+5y. For the combined mean, convert each group mean back to a total first.','Восстановите среднее по формуле x=40+5y. Для объединённого среднего сначала превратите среднее каждой группы в сумму.','O‘rtachani x=40+5y bilan koddan qaytaring. Birlashtirilgan o‘rtacha uchun avval har bir guruh o‘rtachasini yig‘indiga aylantiring.','draft','pending','pending','pending','pending'),
(15677,4822,'P5NOR02-AW22','P5','P5-NOR-02','{}'::text[],'v1','Let X~N(80,36). Standardise X=68 and X=86, then find P(68<X<86) using standard-normal values. Show the z-transformation and identify the two cumulative probabilities used.','Пусть X~N(80,36). Стандартизируйте X=68 и X=86, затем найдите P(68<X<86) по значениям стандартной нормали. Покажите z-преобразование и две использованные накопленные вероятности.','X~N(80,36) bo‘lsin. X=68 va X=86 ni standartlang, so‘ng standart normal qiymatlar orqali P(68<X<86) ni toping. z-o‘zgarishni va ishlatilgan ikki cumulative probability ni ko‘rsating.','{"max_marks":6,"criteria":[{"id":"sigma","marks":1,"rule":"Identifies σ=6."},{"id":"zlow","marks":1,"rule":"Gets z=-2 for 68."},{"id":"zhigh","marks":1,"rule":"Gets z=1 for 86."},{"id":"prob","marks":2,"rule":"Uses Φ(1)−Φ(−2)=0.8413−0.0228=0.8185."},{"id":"communication","marks":1,"rule":"Shows the standardisation formula and tail directions clearly."}]}'::jsonb,'Remember that the second normal parameter is variance here, so σ=√36. Convert both x-bounds before using the table.','Помните, что второй параметр нормального распределения здесь — дисперсия, поэтому σ=√36. Сначала преобразуйте обе границы в z.','Normal taqsimotdagi ikkinchi parametr bu yerda dispersiya, shuning uchun σ=√36. Jadvaldan oldin ikkala x chegarani z ga aylantiring.','draft','pending','pending','pending','pending'),
(15678,4822,'P5NOR03-AW22','P5','P5-NOR-03','{}'::text[],'v1','Let X~N(50,16). Find P(46<X<58) to 4 d.p. Show both z-values and the subtraction of cumulative probabilities.','Пусть X~N(50,16). Найдите P(46<X<58) до 4 знаков. Покажите оба z и вычитание накопленных вероятностей.','X~N(50,16) bo‘lsin. P(46<X<58) ni 4 xonagacha toping. Ikkala z qiymatni va cumulative probability lar ayirmasini ko‘rsating.','{"max_marks":6,"criteria":[{"id":"sigma","marks":1,"rule":"Identifies σ=4."},{"id":"zlow","marks":1,"rule":"Gets z=-1."},{"id":"zhigh","marks":1,"rule":"Gets z=2."},{"id":"values","marks":1,"rule":"Uses Φ(2)=0.9772 and Φ(-1)=0.1587."},{"id":"subtract","marks":1,"rule":"Gets 0.8185."},{"id":"communication","marks":1,"rule":"Keeps lower and upper tails in the correct order."}]}'::jsonb,'For an interval, subtract the lower cumulative probability from the upper cumulative probability after standardising both endpoints.','Для интервала после стандартизации обеих границ вычтите нижнюю накопленную вероятность из верхней.','Oraliq uchun ikkala chegarani standartlagach, pastki cumulative probability ni yuqorisidan ayiring.','draft','pending','pending','pending','pending'),
(15679,4822,'P5NOR04-AW22','P5','P5-NOR-04','{}'::text[],'v1','Let X~N(60,25). Find (a) the 90th percentile, (b) the lower 5th percentile, and (c) the central 90% interval. Give endpoints to 1 d.p. and state the z-values used.','Пусть X~N(60,25). Найдите (a) 90-й процентиль, (b) нижний 5-й процентиль и (c) центральный 90%-интервал. Дайте границы до 1 знака и укажите использованные z.','X~N(60,25) bo‘lsin. (a) 90-percentil, (b) pastki 5-percentil va (c) markaziy 90% intervalni toping. Chegaralarni 1 xonagacha va ishlatilgan z qiymatlarni yozing.','{"max_marks":6,"criteria":[{"id":"sigma","marks":1,"rule":"Identifies σ=5."},{"id":"p90","marks":1,"rule":"Uses z≈1.2816 and gets 66.4."},{"id":"p05","marks":1,"rule":"Uses z≈−1.6449 and gets 51.8."},{"id":"centralz","marks":1,"rule":"Uses z≈±1.6449 for 5% tails."},{"id":"central","marks":2,"rule":"Gets central interval approximately [51.8,68.2]."}]}'::jsonb,'Translate each percentile statement into a cumulative probability first, then use x=μ+zσ. Central 90% leaves 5% in each tail.','Сначала переведите каждый процентиль в накопленную вероятность, затем используйте x=μ+zσ. Центральные 90% оставляют по 5% в каждом хвосте.','Har bir percentilni avval cumulative probability ga aylantiring, keyin x=μ+zσ dan foydalaning. Markaziy 90% har bir dumda 5% qoldiradi.','draft','pending','pending','pending','pending'),
(15680,4822,'P5NOR05-AW22','P5','P5-NOR-05','{}'::text[],'v1','For X~N(μ,σ²), P(X<44)=0.1587 and P(X<68)=0.8413. Use the corresponding z-values to find μ and σ. Show the two equations before solving them.','Для X~N(μ,σ²) даны P(X<44)=0,1587 и P(X<68)=0,8413. Используйте соответствующие z, чтобы найти μ и σ. Покажите два уравнения до их решения.','X~N(μ,σ²) uchun P(X<44)=0.1587 va P(X<68)=0.8413. Mos z qiymatlar yordamida μ va σ ni toping. Yechishdan oldin ikki tenglamani ko‘rsating.','{"max_marks":6,"criteria":[{"id":"zvalues","marks":1,"rule":"Uses z=-1 and z=1."},{"id":"eq1","marks":1,"rule":"Forms (44−μ)/σ=-1."},{"id":"eq2","marks":1,"rule":"Forms (68−μ)/σ=1."},{"id":"sigma","marks":1,"rule":"Finds σ=12."},{"id":"mu","marks":1,"rule":"Finds μ=56."},{"id":"verify","marks":1,"rule":"Checks both probability conditions."}]}'::jsonb,'Convert each probability into a z-condition. The pair of linear equations in μ and σ can then be added or subtracted cleanly.','Преобразуйте каждую вероятность в условие для z. Затем два линейных уравнения относительно μ и σ удобно сложить или вычесть.','Har bir ehtimolni z shartiga aylantiring. So‘ng μ va σ uchun ikki chiziqli tenglamani qo‘shish yoki ayirish qulay.','draft','pending','pending','pending','pending'),
(15681,4822,'P5NOR06-AW22','P5','P5-NOR-06','{}'::text[],'v1','Let X~Bin(120,0.4). Use a normal approximation to estimate P(X≤55). State the mean and variance, check that the approximation conditions are reasonable, apply continuity correction, standardise and give the final probability to 4 d.p.','Пусть X~Bin(120,0,4). Используйте normal approximation для оценки P(X≤55). Укажите среднее и дисперсию, проверьте разумность условий аппроксимации, примените continuity correction, стандартизируйте и дайте итоговую вероятность до 4 знаков.','X~Bin(120,0.4) bo‘lsin. P(X≤55) ni normal approximation bilan baholang. O‘rtacha va dispersiyani yozing, approximation shartlari mosligini tekshiring, continuity correction qo‘llang, standartlang va yakuniy ehtimolni 4 xonagacha bering.','{"max_marks":6,"criteria":[{"id":"moments","marks":1,"rule":"Gets mean=48 and variance=28.8."},{"id":"conditions","marks":1,"rule":"Notes np=48 and n(1-p)=72 are sufficiently large."},{"id":"cc","marks":1,"rule":"Uses boundary 55.5."},{"id":"z","marks":1,"rule":"Gets z≈1.398."},{"id":"prob","marks":1,"rule":"Gets approximately 0.9189."},{"id":"notation","marks":1,"rule":"Uses Y~N(48,28.8) consistently."}]}'::jsonb,'Use variance np(1−p), not standard deviation, as the second N(μ,σ²) parameter. For X≤55, the continuity-corrected boundary is 55.5.','Используйте дисперсию np(1−p), а не стандартное отклонение, как второй параметр N(μ,σ²). Для X≤55 граница с continuity correction равна 55,5.','N(μ,σ²) ning ikkinchi parametri sifatida standart og‘ish emas, np(1−p) dispersiyani ishlating. X≤55 uchun continuity correction chegarasi 55.5.','draft','pending','pending','pending','pending')
on conflict(id) do nothing;

with src(meta_id,content_key,skill_code,official_ref,book_ref) as (values
(59508,'P5DAT08-A01','P5-DAT-08','Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2-3 pp. 14-59 (mapping only)'),
(59509,'P5DAT08-A02','P5-DAT-08','Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2-3 pp. 14-59 (mapping only)'),
(59510,'P5DAT08-A03','P5-DAT-08','Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2-3 pp. 14-59 (mapping only)'),
(59511,'P5DAT09-A01','P5-DAT-09','Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
(59512,'P5DAT09-A02','P5-DAT-09','Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
(59513,'P5DAT09-A03','P5-DAT-09','Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
(59514,'P5DAT10-A01','P5-DAT-10','Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
(59515,'P5DAT10-A02','P5-DAT-10','Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
(59516,'P5DAT10-A03','P5-DAT-10','Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
(59517,'P5NOR02-A01','P5-NOR-02','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
(59518,'P5NOR02-A02','P5-NOR-02','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
(59519,'P5NOR02-A03','P5-NOR-02','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
(59520,'P5NOR03-A01','P5-NOR-03','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
(59521,'P5NOR03-A02','P5-NOR-03','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
(59522,'P5NOR03-A03','P5-NOR-03','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
(59523,'P5NOR04-A01','P5-NOR-04','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
(59524,'P5NOR04-A02','P5-NOR-04','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
(59525,'P5NOR04-A03','P5-NOR-04','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
(59526,'P5NOR05-A01','P5-NOR-05','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
(59527,'P5NOR05-A02','P5-NOR-05','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
(59528,'P5NOR05-A03','P5-NOR-05','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
(59529,'P5NOR06-A01','P5-NOR-06','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch10 pp. 173-179 (mapping only)'),
(59530,'P5NOR06-A02','P5-NOR-06','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch10 pp. 173-179 (mapping only)'),
(59531,'P5NOR06-A03','P5-NOR-06','Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch10 pp. 173-179 (mapping only)')
)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,4822,s.content_key,q.id,s.skill_code,'{}'::text[],'learning','withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'Supplemental AW21-24 learning draft authored from the canonical skill intent with independent values and contexts, separate from the existing teaching pack.',
 s.official_ref,s.book_ref,
 'pending','pending','pending','pending','pending','not_applicable',
 md5(concat_ws(chr(31),
   q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),
   coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
   coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),
   coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
   coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),
   coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')
 ))
from src s
join public.questions q on q.book_ref='ExamPrep:P5:p5_aw21_24_alt_learning_draft_v1:'||s.content_key
on conflict(id) do nothing;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35521,4822,'P5-DAT-08-learning-alt-04','v1','P5','learning','draft','Comparing datasets','Сравнение наборов данных','Ma’lumot to‘plamlarini taqqoslash'),
(35522,4822,'P5-DAT-09-learning-alt-04','v1','P5','learning','draft','Mean and standard deviation','Среднее и стандартное отклонение','O‘rtacha va standart og‘ish'),
(35523,4822,'P5-DAT-10-learning-alt-04','v1','P5','learning','draft','Coded and combined data','Кодированные и объединённые данные','Kodlangan va birlashtirilgan ma’lumotlar'),
(35524,4822,'P5-NOR-02-learning-alt-04','v1','P5','learning','draft','Standardising normal variables','Стандартизация нормальной величины','Normal o‘zgaruvchini standartlash'),
(35525,4822,'P5-NOR-03-learning-alt-04','v1','P5','learning','draft','Normal probabilities','Вероятности нормального распределения','Normal taqsimot ehtimollari'),
(35526,4822,'P5-NOR-04-learning-alt-04','v1','P5','learning','draft','Inverse normal values','Обратные значения нормального распределения','Teskari normal qiymatlar'),
(35527,4822,'P5-NOR-05-learning-alt-04','v1','P5','learning','draft','Unknown normal parameters','Неизвестные параметры нормального распределения','Noma’lum normal parametrlar'),
(35528,4822,'P5-NOR-06-learning-alt-04','v1','P5','learning','draft','Normal approximation to binomial','Нормальная аппроксимация биномиального распределения','Binomial taqsimotning normal yaqinlashuvi')
on conflict(id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
(35521,1,'P5DAT08-A01',null::bigint,'P5-DAT-08'),
(35521,2,'P5DAT08-A02',null::bigint,'P5-DAT-08'),
(35521,3,'P5DAT08-A03',null::bigint,'P5-DAT-08'),
(35521,4,null,15674,'P5-DAT-08'),
(35522,1,'P5DAT09-A01',null::bigint,'P5-DAT-09'),
(35522,2,'P5DAT09-A02',null::bigint,'P5-DAT-09'),
(35522,3,'P5DAT09-A03',null::bigint,'P5-DAT-09'),
(35522,4,null,15675,'P5-DAT-09'),
(35523,1,'P5DAT10-A01',null::bigint,'P5-DAT-10'),
(35523,2,'P5DAT10-A02',null::bigint,'P5-DAT-10'),
(35523,3,'P5DAT10-A03',null::bigint,'P5-DAT-10'),
(35523,4,null,15676,'P5-DAT-10'),
(35524,1,'P5NOR02-A01',null::bigint,'P5-NOR-02'),
(35524,2,'P5NOR02-A02',null::bigint,'P5-NOR-02'),
(35524,3,'P5NOR02-A03',null::bigint,'P5-NOR-02'),
(35524,4,null,15677,'P5-NOR-02'),
(35525,1,'P5NOR03-A01',null::bigint,'P5-NOR-03'),
(35525,2,'P5NOR03-A02',null::bigint,'P5-NOR-03'),
(35525,3,'P5NOR03-A03',null::bigint,'P5-NOR-03'),
(35525,4,null,15678,'P5-NOR-03'),
(35526,1,'P5NOR04-A01',null::bigint,'P5-NOR-04'),
(35526,2,'P5NOR04-A02',null::bigint,'P5-NOR-04'),
(35526,3,'P5NOR04-A03',null::bigint,'P5-NOR-04'),
(35526,4,null,15679,'P5-NOR-04'),
(35527,1,'P5NOR05-A01',null::bigint,'P5-NOR-05'),
(35527,2,'P5NOR05-A02',null::bigint,'P5-NOR-05'),
(35527,3,'P5NOR05-A03',null::bigint,'P5-NOR-05'),
(35527,4,null,15680,'P5-NOR-05'),
(35528,1,'P5NOR06-A01',null::bigint,'P5-NOR-06'),
(35528,2,'P5NOR06-A02',null::bigint,'P5-NOR-06'),
(35528,3,'P5NOR06-A03',null::bigint,'P5-NOR-06'),
(35528,4,null,15681,'P5-NOR-06')
)
insert into private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select i.assessment_id,i.item_order,q.id,i.written_id,i.skill_code,
 case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions q on i.content_key is not null
 and q.book_ref='ExamPrep:P5:p5_aw21_24_alt_learning_draft_v1:'||i.content_key
on conflict(assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select status from private.exam_prep_content_versions where id=4822)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4822 and lifecycle_state='draft' and reserve_role='learning')<>24
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4822 and lifecycle_state='draft')<>8
     or (select count(*) from private.exam_prep_assessments where content_version_id=4822 and status='draft' and assessment_type='learning')<>8
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4822)<>32
  then raise exception 'aw21_24_alt_p5_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4822 and (
    m.exposure_state<>'withheld' or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or q.is_active or q.quality_status<>'draft'
  );
  if v_bad<>0 then raise exception 'aw21_24_alt_p5_draft exposure/QA boundary rows=%',v_bad; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id where m.content_version_id=4822;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,4,4,8) then
    raise exception 'aw21_24_alt_p5_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4822
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4822
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw21_24_alt_p5_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4822)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4822)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4822)
  then raise exception 'aw21_24_alt_p5_draft unexpected history'; end if;
end
$postcheck$;

commit;
