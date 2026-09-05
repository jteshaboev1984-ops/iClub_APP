-- P1-02 P5 AW9-12 data pack: DAT-05 cumulative frequency, DAT-03 box plots, DAT-07 spread.
-- Original iClub-authored content only. Atomic publish through the existing governed content-floor trigger.
-- public.questions rows remain draft + inactive and are used only through private Exam Prep memberships.

begin;

insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,'p5_aw09_12_data_v1','P5','P5 AW9-12 Data bridge: cumulative frequency, box plots and spread','draft','Original iClub content only; Cambridge 9709 official syllabus defines scope; Complete Probability & Statistics 1 is mapping/teaching reference only; no Cambridge/coursebook question, diagram, answer or mark-scheme wording copied.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,content_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_aw09_12_data_v1' and component_code='P5' and status='draft'
), src(skill,k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P5-DAT-05','P5DAT05-D01','diagnostic','medium','A cumulative-frequency graph represents 90 observations. At x = 32, the cumulative frequency is 54. What percentage of the observations are at most 32?','График накопленной частоты представляет 90 наблюдений. При x = 32 накопленная частота равна 54. Какой процент наблюдений не превышает 32?','Kumulyativ chastota grafigi 90 ta kuzatuvni ifodalaydi. x = 32 da kumulyativ chastota 54. Kuzatuvlarning necha foizi 32 dan katta emas?','["54%", "60%", "36%", "40%"]','["54%", "60%", "36%", "40%"]','["54%", "60%", "36%", "40%"]','B','Cumulative frequency 54 means 54 of 90 observations are at most 32. 54/90 = 0.60 = 60%.','Накопленная частота 54 означает, что 54 из 90 наблюдений не превышают 32. 54/90 = 0,60 = 60%.','Kumulyativ chastota 54 bo‘lsa, 90 ta kuzatuvdan 54 tasi 32 dan katta emas. 54/90 = 0.60 = 60%.',75),
('P5-DAT-05','P5DAT05-L01','learning','easy','A data set contains 120 values. Which cumulative frequency corresponds to the lower quartile Q1?','Набор данных содержит 120 значений. Какая накопленная частота соответствует нижнему квартилю Q1?','Ma’lumotlar to‘plamida 120 ta qiymat bor. Pastki kvartil Q1 ga qaysi kumulyativ chastota mos keladi?','["20", "30", "60", "90"]','["20", "30", "60", "90"]','["20", "30", "60", "90"]','B','Q1 is the 25th percentile, so use 0.25 × 120 = 30.','Q1 — это 25-й процентиль, поэтому используется 0,25 × 120 = 30.','Q1 25-foizli nuqta, shuning uchun 0.25 × 120 = 30.',50),
('P5-DAT-05','P5DAT05-L02','learning','medium','A cumulative-frequency curve for 80 observations gives x = 18 at cumulative frequency 20 and x = 31 at cumulative frequency 60. What is the interquartile range?','По кривой накопленной частоты для 80 наблюдений x = 18 при накопленной частоте 20 и x = 31 при накопленной частоте 60. Чему равен межквартильный размах?','80 ta kuzatuv uchun kumulyativ chastota egri chizig‘ida CF=20 da x=18 va CF=60 da x=31. Kvartillar oralig‘i nechaga teng?','["13", "20", "31", "49"]','["13", "20", "31", "49"]','["13", "20", "31", "49"]','A','For 80 observations, Q1 is at CF 20 and Q3 at CF 60. So IQR = 31 − 18 = 13.','Для 80 наблюдений Q1 соответствует CF 20, а Q3 — CF 60. Поэтому IQR = 31 − 18 = 13.','80 ta kuzatuvda Q1 CF=20, Q3 esa CF=60 da. IQR = 31 − 18 = 13.',70),
('P5-DAT-05','P5DAT05-L03','learning','medium','A cumulative-frequency graph for 200 observations shows cumulative frequency 150 at x = 47. Which statement is correct?','На графике накопленной частоты для 200 наблюдений при x = 47 накопленная частота равна 150. Какое утверждение верно?','200 ta kuzatuv uchun kumulyativ chastota grafigida x=47 da kumulyativ chastota 150. Qaysi fikr to‘g‘ri?','["25% are at most 47", "75% are at most 47", "75% are greater than 47", "150% are at most 47"]','["25% не превышают 47", "75% не превышают 47", "75% больше 47", "150% не превышают 47"]','["25% 47 dan katta emas", "75% 47 dan katta emas", "75% 47 dan katta", "150% 47 dan katta emas"]','B','150/200 = 0.75, so 75% of the observations are at most 47.','150/200 = 0,75, значит 75% наблюдений не превышают 47.','150/200 = 0.75, demak kuzatuvlarning 75% i 47 dan katta emas.',60),
('P5-DAT-05','P5DAT05-R01','retest','easy','A cumulative-frequency curve represents 64 observations. Which cumulative frequency should be used to estimate the median?','Кривая накопленной частоты представляет 64 наблюдения. Какую накопленную частоту нужно использовать для оценки медианы?','Kumulyativ chastota egri chizig‘i 64 ta kuzatuvni ifodalaydi. Medianani baholash uchun qaysi kumulyativ chastota olinadi?','["16", "24", "32", "48"]','["16", "24", "32", "48"]','["16", "24", "32", "48"]','C','The median is the 50th percentile, so use 0.5 × 64 = 32.','Медиана — 50-й процентиль, поэтому используется 0,5 × 64 = 32.','Mediana 50-foizli nuqta, shuning uchun 0.5 × 64 = 32.',50),
('P5-DAT-05','P5DAT05-R02','retest','medium','For 100 observations, the cumulative-frequency curve gives x = 12 at CF 25 and x = 29 at CF 75. Find the interquartile range.','Для 100 наблюдений кривая накопленной частоты даёт x = 12 при CF 25 и x = 29 при CF 75. Найдите межквартильный размах.','100 ta kuzatuv uchun kumulyativ chastota egri chizig‘ida CF=25 da x=12 va CF=75 da x=29. IQR ni toping.','["12", "17", "29", "41"]','["12", "17", "29", "41"]','["12", "17", "29", "41"]','B','Q1 = 12 and Q3 = 29, so IQR = 29 − 12 = 17.','Q1 = 12 и Q3 = 29, поэтому IQR = 29 − 12 = 17.','Q1=12 va Q3=29, demak IQR = 29 − 12 = 17.',60),
('P5-DAT-05','P5DAT05-M01','mixed','medium','A cumulative-frequency graph for 160 observations gives CF 44 at x = 25 and CF 116 at x = 40. How many observations lie in the interval 25 < x ≤ 40?','На графике накопленной частоты для 160 наблюдений CF = 44 при x = 25 и CF = 116 при x = 40. Сколько наблюдений лежит в интервале 25 < x ≤ 40?','160 ta kuzatuv uchun kumulyativ chastota grafigida x=25 da CF=44 va x=40 da CF=116. 25 < x ≤ 40 oralig‘ida nechta kuzatuv bor?','["44", "72", "116", "160"]','["44", "72", "116", "160"]','["44", "72", "116", "160"]','B','Subtract cumulative counts: 116 − 44 = 72 observations.','Вычитаем накопленные количества: 116 − 44 = 72 наблюдения.','Kumulyativ sonlarni ayiramiz: 116 − 44 = 72 ta kuzatuv.',70),
('P5-DAT-03','P5DAT03-D01','diagnostic','medium','A box plot has Q1 = 8 and Q3 = 15. Using the 1.5×IQR rule, which value would be classified as a high outlier?','У box plot Q1 = 8 и Q3 = 15. По правилу 1,5×IQR какое значение будет считаться верхним выбросом?','Box plot uchun Q1=8 va Q3=15. 1.5×IQR qoidasiga ko‘ra qaysi qiymat yuqori outlier bo‘ladi?','["20", "24", "25", "26"]','["20", "24", "25", "26"]','["20", "24", "25", "26"]','D','IQR = 7, so the upper fence is 15 + 1.5×7 = 25.5. A value above 25.5, such as 26, is a high outlier.','IQR = 7, верхняя граница равна 15 + 1,5×7 = 25,5. Значение выше 25,5, например 26, является верхним выбросом.','IQR=7, yuqori chegara 15 + 1.5×7 = 25.5. 25.5 dan katta qiymat, masalan 26, yuqori outlier.',80),
('P5-DAT-03','P5DAT03-L01','learning','easy','Which five values are used to construct a standard box-and-whisker plot?','Какие пять значений используются для построения стандартного box-and-whisker plot?','Oddiy box-and-whisker plot qurish uchun qaysi beshta qiymat ishlatiladi?','["minimum, Q1, median, Q3, maximum", "mean, Q1, median, Q3, standard deviation", "minimum, mean, median, mode, maximum", "Q1, Q2, Q3, variance, range"]','["минимум, Q1, медиана, Q3, максимум", "среднее, Q1, медиана, Q3, стандартное отклонение", "минимум, среднее, медиана, мода, максимум", "Q1, Q2, Q3, дисперсия, размах"]','["minimum, Q1, mediana, Q3, maksimum", "o‘rtacha, Q1, mediana, Q3, standart og‘ish", "minimum, o‘rtacha, mediana, moda, maksimum", "Q1, Q2, Q3, dispersiya, range"]','A','A standard box plot is based on the five-number summary: minimum, Q1, median, Q3 and maximum.','Стандартный box plot строится по пятичисловому набору: минимум, Q1, медиана, Q3 и максимум.','Oddiy box plot besh sonli xulosaga asoslanadi: minimum, Q1, mediana, Q3 va maximum.',50),
('P5-DAT-03','P5DAT03-L02','learning','medium','Box plot A has median 42 and IQR 10. Box plot B has median 38 and IQR 18. Which comparison is correct?','Для box plot A медиана 42 и IQR 10. Для box plot B медиана 38 и IQR 18. Какое сравнение верно?','A box plotda mediana 42 va IQR 10. B box plotda mediana 38 va IQR 18. Qaysi taqqoslash to‘g‘ri?','["A has lower centre and greater spread", "A has higher centre and smaller middle spread", "B has higher centre and smaller spread", "The two plots have the same centre and spread"]','["У A ниже центр и больше разброс", "У A выше центр и меньше разброс средних 50%", "У B выше центр и меньше разброс", "Центр и разброс одинаковы"]','["A markazi pastroq va tarqalishi kattaroq", "A markazi yuqoriroq va o‘rta 50% tarqalishi kichikroq", "B markazi yuqoriroq va tarqalishi kichikroq", "Markaz va tarqalish bir xil"]','B','A has the higher median (42 > 38) and the smaller IQR (10 < 18).','У A медиана выше (42 > 38), а IQR меньше (10 < 18).','A ning medianasi yuqori (42>38), IQR esa kichik (10<18).',65),
('P5-DAT-03','P5DAT03-L03','learning','medium','A data set has Q1 = 12 and Q3 = 20. What is the lower outlier fence using the 1.5×IQR rule?','В наборе данных Q1 = 12 и Q3 = 20. Какова нижняя граница выбросов по правилу 1,5×IQR?','Ma’lumotlarda Q1=12 va Q3=20. 1.5×IQR qoidasiga ko‘ra pastki outlier chegarasi nechaga teng?','["0", "4", "8", "12"]','["0", "4", "8", "12"]','["0", "4", "8", "12"]','A','IQR = 8, so lower fence = 12 − 1.5×8 = 12 − 12 = 0.','IQR = 8, поэтому нижняя граница = 12 − 1,5×8 = 0.','IQR=8, demak pastki chegara = 12 − 1.5×8 = 0.',65),
('P5-DAT-03','P5DAT03-R01','retest','easy','For a box plot with Q1 = 14 and Q3 = 22, what is the interquartile range?','Для box plot с Q1 = 14 и Q3 = 22 чему равен межквартильный размах?','Q1=14 va Q3=22 bo‘lgan box plot uchun IQR nechaga teng?','["8", "14", "22", "36"]','["8", "14", "22", "36"]','["8", "14", "22", "36"]','A','IQR = Q3 − Q1 = 22 − 14 = 8.','IQR = Q3 − Q1 = 22 − 14 = 8.','IQR = Q3 − Q1 = 22 − 14 = 8.',45),
('P5-DAT-03','P5DAT03-R02','retest','medium','A box plot has median 30, Q1 = 24 and Q3 = 35. Which statement is supported directly by the plot?','У box plot медиана 30, Q1 = 24 и Q3 = 35. Какое утверждение непосредственно следует из графика?','Box plotda mediana 30, Q1=24 va Q3=35. Qaysi fikr grafikdan bevosita kelib chiqadi?','["About 50% of values lie between 24 and 35", "The mean equals 30", "There are no outliers", "The range equals 11"]','["Около 50% значений лежат между 24 и 35", "Среднее равно 30", "Выбросов нет", "Размах равен 11"]','["Taxminan 50% qiymat 24 va 35 orasida", "O‘rtacha 30", "Outlier yo‘q", "Range 11"]','A','The interval from Q1 to Q3 contains the middle 50% of the data. The other statements do not follow from these quartiles alone.','Интервал от Q1 до Q3 содержит средние 50% данных. Остальные утверждения из этих квартилей сами по себе не следуют.','Q1 dan Q3 gacha bo‘lgan oraliqda ma’lumotlarning o‘rta 50% i joylashadi. Qolgan fikrlar faqat kvartillardan kelib chiqmaydi.',60),
('P5-DAT-03','P5DAT03-M01','mixed','medium','Two box plots have the same median. Plot X has IQR 6 and Plot Y has IQR 14. What can be concluded about the middle 50% of the data?','У двух box plot одинаковая медиана. У X IQR = 6, у Y IQR = 14. Что можно заключить о средних 50% данных?','Ikki box plotning medianasi bir xil. X uchun IQR=6, Y uchun IQR=14. Ma’lumotlarning o‘rta 50% i haqida nima deyish mumkin?','["X is more spread out in the middle", "Y is more spread out in the middle", "Both have identical middle spread", "Y must have the larger range"]','["У X больше разброс средних 50%", "У Y больше разброс средних 50%", "Средний разброс одинаков", "У Y обязательно больше размах"]','["X da o‘rta 50% ko‘proq tarqalgan", "Y da o‘rta 50% ko‘proq tarqalgan", "O‘rta tarqalish bir xil", "Y ning range i albatta kattaroq"]','B','A larger IQR means the middle 50% are more spread out. Therefore Y has greater middle spread.','Больший IQR означает больший разброс средних 50% данных. Поэтому у Y разброс больше.','Kattaroq IQR o‘rta 50% ko‘proq tarqalganini bildiradi. Demak Y ning o‘rta tarqalishi kattaroq.',60),
('P5-DAT-07','P5DAT07-D01','diagnostic','medium','Every value in a data set is increased by 5. Which statement about the standard deviation is correct?','Каждое значение в наборе данных увеличили на 5. Как изменится стандартное отклонение?','Ma’lumotlar to‘plamidagi har bir qiymat 5 ga oshirildi. Standart og‘ish haqida qaysi fikr to‘g‘ri?','["It increases by 5", "It is multiplied by 5", "It is unchanged", "It decreases by 5"]','["Увеличится на 5", "Умножится на 5", "Не изменится", "Уменьшится на 5"]','["5 ga oshadi", "5 ga ko‘payadi", "O‘zgarmaydi", "5 ga kamayadi"]','C','Adding the same constant shifts every value equally and does not change the spread, so the standard deviation is unchanged.','Прибавление одной и той же константы одинаково сдвигает все значения и не меняет разброс, поэтому стандартное отклонение не изменяется.','Bir xil konstantani qo‘shish barcha qiymatlarni bir xil siljitadi va tarqalishni o‘zgartirmaydi, shuning uchun standart og‘ish o‘zgarmaydi.',60),
('P5-DAT-07','P5DAT07-L01','learning','easy','The smallest value in a data set is 7 and the largest is 26. What is the range?','Наименьшее значение набора равно 7, наибольшее — 26. Чему равен размах?','Ma’lumotlar to‘plamida eng kichik qiymat 7, eng katta qiymat 26. Range nechaga teng?','["19", "26", "33", "182"]','["19", "26", "33", "182"]','["19", "26", "33", "182"]','A','Range = maximum − minimum = 26 − 7 = 19.','Размах = максимум − минимум = 26 − 7 = 19.','Range = maximum − minimum = 26 − 7 = 19.',45),
('P5-DAT-07','P5DAT07-L02','learning','medium','A data set has Q1 = 18 and Q3 = 31. What is its interquartile range?','В наборе данных Q1 = 18 и Q3 = 31. Чему равен межквартильный размах?','Ma’lumotlarda Q1=18 va Q3=31. IQR nechaga teng?','["13", "18", "31", "49"]','["13", "18", "31", "49"]','["13", "18", "31", "49"]','A','IQR = 31 − 18 = 13.','IQR = 31 − 18 = 13.','IQR = 31 − 18 = 13.',45),
('P5-DAT-07','P5DAT07-L03','learning','medium','The four values 2, 2, 4, 4 have mean 3. Using the population-data convention, what is the standard deviation?','Четыре значения 2, 2, 4, 4 имеют среднее 3. По формуле стандартного отклонения для набора данных чему оно равно?','2, 2, 4, 4 qiymatlarining o‘rtachasi 3. Ma’lumotlar to‘plami formulasi bo‘yicha standart og‘ish nechaga teng?','["1", "2", "√2", "4"]','["1", "2", "√2", "4"]','["1", "2", "√2", "4"]','A','Squared deviations are 1,1,1,1. Their mean is 1, so standard deviation = √1 = 1.','Квадраты отклонений равны 1,1,1,1. Их среднее равно 1, поэтому стандартное отклонение = √1 = 1.','Og‘ishlar kvadratlari 1,1,1,1. Ularning o‘rtachasi 1, shuning uchun standart og‘ish = √1 = 1.',75),
('P5-DAT-07','P5DAT07-R01','retest','easy','If Q1 = 9 and Q3 = 17, what is the IQR?','Если Q1 = 9 и Q3 = 17, чему равен IQR?','Agar Q1=9 va Q3=17 bo‘lsa, IQR nechaga teng?','["8", "9", "17", "26"]','["8", "9", "17", "26"]','["8", "9", "17", "26"]','A','IQR = 17 − 9 = 8.','IQR = 17 − 9 = 8.','IQR = 17 − 9 = 8.',40),
('P5-DAT-07','P5DAT07-R02','retest','medium','Every value in a data set is multiplied by 3. If the original standard deviation is 4, what is the new standard deviation?','Каждое значение набора умножили на 3. Если исходное стандартное отклонение равно 4, чему равно новое?','Ma’lumotlar to‘plamidagi har bir qiymat 3 ga ko‘paytirildi. Dastlabki standart og‘ish 4 bo‘lsa, yangi standart og‘ish nechaga teng?','["4", "7", "12", "16"]','["4", "7", "12", "16"]','["4", "7", "12", "16"]','C','Multiplying every value by 3 multiplies every deviation from the mean by 3, so standard deviation becomes 3×4 = 12.','Умножение всех значений на 3 умножает все отклонения от среднего на 3, поэтому стандартное отклонение становится 3×4 = 12.','Barcha qiymatlarni 3 ga ko‘paytirish o‘rtachadan og‘ishlarni ham 3 ga ko‘paytiradi, shuning uchun SD = 3×4 = 12.',60),
('P5-DAT-07','P5DAT07-M01','mixed','medium','Data set A has IQR 5 and standard deviation 3. Data set B is obtained by replacing every value x by 2x + 7. What are the IQR and standard deviation of B?','У набора A IQR = 5 и стандартное отклонение = 3. Набор B получен заменой каждого x на 2x + 7. Чему равны IQR и стандартное отклонение B?','A to‘plamda IQR=5 va standart og‘ish=3. B to‘plam har bir x ni 2x+7 ga almashtirish orqali olingan. B ning IQR va SD si nechaga teng?','["IQR 5, SD 3", "IQR 10, SD 6", "IQR 17, SD 13", "IQR 10, SD 13"]','["IQR 5, SD 3", "IQR 10, SD 6", "IQR 17, SD 13", "IQR 10, SD 13"]','["IQR 5, SD 3", "IQR 10, SD 6", "IQR 17, SD 13", "IQR 10, SD 13"]','B','Adding 7 does not change spread; multiplying by 2 doubles spread measures. So IQR = 10 and SD = 6.','Прибавление 7 не меняет разброс, а умножение на 2 удваивает меры разброса. Поэтому IQR = 10 и SD = 6.','7 ni qo‘shish tarqalishni o‘zgartirmaydi, 2 ga ko‘paytirish esa tarqalish o‘lchovlarini ikki baravar qiladi. IQR=10, SD=6.',75)
)
insert into public.questions(
  subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
  question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
  explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,'P5 Representation of Data',s.skill,s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,
       s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,
       'ExamPrep:P5:p5_aw09_12_data_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s
where not exists(
  select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw09_12_data_v1:'||s.k
);

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_aw09_12_data_v1' and component_code='P5' and status='draft'
), keys(skill,k,role) as (values
('P5-DAT-05','P5DAT05-D01','diagnostic'),
('P5-DAT-05','P5DAT05-L01','learning'),
('P5-DAT-05','P5DAT05-L02','learning'),
('P5-DAT-05','P5DAT05-L03','learning'),
('P5-DAT-05','P5DAT05-R01','retest'),
('P5-DAT-05','P5DAT05-R02','retest'),
('P5-DAT-05','P5DAT05-M01','mixed'),
('P5-DAT-03','P5DAT03-D01','diagnostic'),
('P5-DAT-03','P5DAT03-L01','learning'),
('P5-DAT-03','P5DAT03-L02','learning'),
('P5-DAT-03','P5DAT03-L03','learning'),
('P5-DAT-03','P5DAT03-R01','retest'),
('P5-DAT-03','P5DAT03-R02','retest'),
('P5-DAT-03','P5DAT03-M01','mixed'),
('P5-DAT-07','P5DAT07-D01','diagnostic'),
('P5-DAT-07','P5DAT07-L01','learning'),
('P5-DAT-07','P5DAT07-L02','learning'),
('P5-DAT-07','P5DAT07-L03','learning'),
('P5-DAT-07','P5DAT07-R01','retest'),
('P5-DAT-07','P5DAT07-R02','retest'),
('P5-DAT-07','P5DAT07-M01','mixed')
)
insert into private.exam_prep_question_content_meta(
  content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
  exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
  copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
select cv.id,k.k,q.id,k.skill,'{}'::text[],k.role,'withheld','draft',
       'Original iClub-authored stem, numbers, distractors, answer and explanation; no Cambridge/coursebook question, diagram or mark-scheme wording copied.',
       'Authored for p5_aw09_12_data_v1 from the canonical skill intent using independent examples.',
       'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data',
       'Complete Probability & Statistics 1; Representation of data (mapping only)',
       'pending','pending','pending','pending','pending',
       case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
       md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
         coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),
         coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),
         coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
         coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
         coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
         coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k
join public.questions q on q.book_ref='ExamPrep:P5:p5_aw09_12_data_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

with rules(ckey,match,dcode,mtype,weak_skill,fen,fru,fuz,nen,nru,nuz) as (values
('P5DAT05-D01','A','used_count_as_percent','concept','P5-DAT-05','The graph gives a cumulative count of 54, not 54%. Convert the count to a proportion of all 90 observations.','График даёт накопленное количество 54, а не 54%. Нужно разделить 54 на все 90 наблюдений.','Grafik 54 ta kumulyativ sonni beradi, 54% ni emas. 54 ni jami 90 ga bo‘ling.','Use percentage = cumulative frequency ÷ total × 100.','Используйте процент = накопленная частота ÷ общее число × 100.','Foiz = kumulyativ chastota ÷ jami son × 100 formulasidan foydalaning.'),
('P5DAT05-D01','C','used_complement_instead','concept','P5-DAT-05','36 is the number above 32, not the number at or below 32. The cumulative frequency already counts values up to 32.','36 — это число значений выше 32, а не не превышающих 32. Накопленная частота уже считает значения до 32 включительно.','36 — 32 dan katta qiymatlar soni. Kumulyativ chastota esa 32 gacha bo‘lgan qiymatlarni hisoblaydi.','Read the cumulative count first; only take a complement if the question asks for values above the threshold.','Сначала считайте накопленное количество; дополнение берите только если спрашивают значения выше порога.','Avval kumulyativ sonni o‘qing; faqat chegaradan yuqori qiymatlar so‘ralsa complement oling.'),
('P5DAT05-D01','D','wrong_fraction_conversion','method','P5-DAT-05','54/90 is 0.60, not 0.40. Check the division before converting to a percentage.','54/90 = 0,60, а не 0,40. Проверьте деление перед переводом в проценты.','54/90 = 0.60, 0.40 emas. Foizga o‘tkazishdan oldin bo‘lishni tekshiring.','Simplify 54/90 or divide directly, then multiply by 100.','Сократите 54/90 или выполните деление, затем умножьте на 100.','54/90 ni qisqartiring yoki bo‘ling, keyin 100 ga ko‘paytiring.'),
('P5DAT03-D01','A','ignored_outlier_fence','concept','P5-DAT-03','20 is below the upper outlier fence. First calculate IQR and then Q3 + 1.5×IQR.','20 ниже верхней границы выбросов. Сначала найдите IQR, затем Q3 + 1,5×IQR.','20 yuqori outlier chegarasidan past. Avval IQR ni, keyin Q3 + 1.5×IQR ni hisoblang.','Compute IQR = 15−8 and compare each candidate with the upper fence.','Вычислите IQR = 15−8 и сравните варианты с верхней границей.','IQR = 15−8 ni hisoblab, variantlarni yuqori chegara bilan solishtiring.'),
('P5DAT03-D01','B','used_q3_plus_iqr','method','P5-DAT-03','24 does not satisfy the 1.5×IQR rule. The upper fence is 25.5.','24 не соответствует правилу 1,5×IQR. Верхняя граница равна 25,5.','24 1.5×IQR qoidasiga mos emas. Yuqori chegara 25.5.','Write upper fence = Q3 + 1.5(Q3−Q1) explicitly.','Запишите верхнюю границу как Q3 + 1,5(Q3−Q1).','Yuqori chegarani Q3 + 1.5(Q3−Q1) ko‘rinishida yozing.'),
('P5DAT03-D01','C','treated_fence_as_outlier','concept','P5-DAT-03','25 is still below 25.5. A high outlier must be strictly above the upper fence.','25 всё ещё меньше 25,5. Верхний выброс должен быть строго выше верхней границы.','25 hali 25.5 dan kichik. Yuqori outlier yuqori chegaradan qat’iy katta bo‘lishi kerak.','Compare the value with 25.5 using a strict greater-than test.','Сравните значение с 25,5 по условию строго «больше».','Qiymatni 25.5 bilan qat’iy ''katta'' sharti bo‘yicha solishtiring.'),
('P5DAT07-D01','A','additive_shift_changes_sd','concept','P5-DAT-07','Adding a constant shifts the centre but leaves every distance from the mean unchanged, so SD does not increase by 5.','Прибавление константы сдвигает центр, но не меняет расстояния от среднего, поэтому SD не увеличивается на 5.','Konstantani qo‘shish markazni siljitadi, lekin o‘rtachadan masofalarni o‘zgartirmaydi; SD 5 ga oshmaydi.','Compare deviations before and after adding 5.','Сравните отклонения от среднего до и после прибавления 5.','5 qo‘shishdan oldin va keyin o‘rtachadan og‘ishlarni solishtiring.'),
('P5DAT07-D01','B','confused_addition_with_scaling','concept','P5-DAT-07','Multiplying all values scales SD; adding 5 does not. The transformation here is a shift, not a scale.','Умножение всех значений масштабирует SD; прибавление 5 — нет. Здесь сдвиг, а не масштабирование.','Barcha qiymatlarni ko‘paytirish SD ni masshtablaydi; 5 qo‘shish esa yo‘q. Bu siljish, masshtab emas.','Use the rule SD(aX+b)=|a|SD(X); here a=1.','Используйте правило SD(aX+b)=|a|SD(X); здесь a=1.','SD(aX+b)=|a|SD(X) qoidasidan foydalaning; bu yerda a=1.'),
('P5DAT07-D01','D','wrong_direction_for_shift','method','P5-DAT-07','A constant shift cannot reduce spread either. All pairwise differences remain the same.','Постоянный сдвиг также не уменьшает разброс. Все попарные разности остаются прежними.','Doimiy siljish tarqalishni kamaytirmaydi ham. Barcha juft farqlar o‘zgarmaydi.','Check that max−min and deviations from the mean are unchanged by +5.','Проверьте, что max−min и отклонения от среднего не меняются при +5.','+5 da max−min va o‘rtachadan og‘ishlar o‘zgarmasligini tekshiring.')
), meta as (
  select m.id,m.content_key
  from private.exam_prep_question_content_meta m
  join private.exam_prep_content_versions cv on cv.id=m.content_version_id
  where cv.content_version='p5_aw09_12_data_v1' and m.reserve_role='diagnostic'
)
insert into private.exam_prep_diagnostic_rules(
  content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,
  feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status,approved_at
)
select meta.id,'drv1','mcq_option',r.match,r.dcode,r.mtype,r.weak_skill,
       r.fen,r.fru,r.fuz,r.nen,r.nru,r.nuz,'approved',now()
from rules r join meta on meta.content_key=r.ckey
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_aw09_12_data_v1' and component_code='P5' and status='draft'
), defs(task_key,skill,en,ru,uz,rubric,sen,sru,suz) as (values
('P5DAT05-W01','P5-DAT-05','A cumulative-frequency curve summarises 160 delivery times. The graph gives Q1 = 18 minutes, median = 27 minutes and Q3 = 39 minutes. It also shows cumulative frequency 124 at 45 minutes. (a) State the cumulative frequencies used to read Q1, median and Q3. (b) Find the IQR. (c) Estimate the percentage of deliveries taking at most 45 minutes. (d) Explain what cumulative frequency means in part (c).','Кривая накопленной частоты описывает 160 времён доставки. По графику Q1 = 18 мин, медиана = 27 мин и Q3 = 39 мин. Также при 45 мин накопленная частота равна 124. (a) Укажите накопленные частоты, по которым считываются Q1, медиана и Q3. (b) Найдите IQR. (c) Оцените процент доставок не более 45 мин. (d) Объясните смысл накопленной частоты в (c).','Kumulyativ chastota egri chizig‘i 160 ta yetkazib berish vaqtini ko‘rsatadi. Grafikdan Q1=18 min, mediana=27 min va Q3=39 min. 45 minutda kumulyativ chastota 124. (a) Q1, mediana va Q3 ni o‘qish uchun ishlatiladigan kumulyativ chastotalarni yozing. (b) IQR ni toping. (c) 45 minutdan ko‘p bo‘lmagan yetkazib berishlar foizini toping. (d) (c) dagi kumulyativ chastota nimani anglatishini tushuntiring.','{"max_marks":10,"criteria":[{"id":"positions","marks":3,"rule":"Uses CF 40, 80 and 120 for Q1, median and Q3."},{"id":"iqr","marks":2,"rule":"Finds IQR = 39−18 = 21."},{"id":"percentage","marks":2,"rule":"Calculates 124/160×100 = 77.5%."},{"id":"meaning","marks":3,"rule":"Explains that cumulative frequency counts observations at or below the stated time and links 124 to at most 45 minutes."}]}','Check quartile positions as 25%, 50% and 75% of 160. For the percentage, divide the cumulative count by the total, not by the x-value.','Проверьте позиции квартилей как 25%, 50% и 75% от 160. Для процента делите накопленное количество на общее число, а не на значение x.','Kvartil o‘rinlarini 160 ning 25%, 50% va 75% i sifatida tekshiring. Foiz uchun kumulyativ sonni umumiy songa bo‘ling, x qiymatiga emas.'),
('P5DAT03-W01','P5-DAT-03','Two classes have the following five-number summaries. Class A: min 8, Q1 14, median 20, Q3 26, max 34. Class B: min 5, Q1 17, median 22, Q3 31, max 47. (a) Describe how the box plots would be positioned. (b) Compare centre using the medians. (c) Compare the middle spread using IQR. (d) For Class B, use the 1.5×IQR rule to determine whether 47 is a high outlier.','Для двух классов даны пятичисловые характеристики. Класс A: min 8, Q1 14, медиана 20, Q3 26, max 34. Класс B: min 5, Q1 17, медиана 22, Q3 31, max 47. (a) Опишите расположение box plot. (b) Сравните центр по медианам. (c) Сравните средний разброс по IQR. (d) Для класса B по правилу 1,5×IQR определите, является ли 47 верхним выбросом.','Ikki sinf uchun besh sonli xulosa berilgan. A: min 8, Q1 14, mediana 20, Q3 26, max 34. B: min 5, Q1 17, mediana 22, Q3 31, max 47. (a) Box plotlar qanday joylashishini tasvirlang. (b) Medianalar orqali markazni taqqoslang. (c) IQR orqali o‘rta tarqalishni taqqoslang. (d) B sinf uchun 1.5×IQR qoidasida 47 yuqori outlier ekanini tekshiring.','{"max_marks":10,"criteria":[{"id":"box_structure","marks":2,"rule":"Correctly identifies boxes A:14–26 with median 20 and B:17–31 with median 22, with whisker endpoints as given."},{"id":"centre","marks":2,"rule":"States B has slightly higher centre because median 22 > 20."},{"id":"spread","marks":3,"rule":"Computes IQR A=12, B=14 and concludes B has greater middle spread."},{"id":"outlier","marks":3,"rule":"For B, upper fence=31+1.5×14=52, so 47 is not a high outlier."}]}','Keep median, IQR and total range as different summaries. For the outlier check, calculate the fence before comparing 47.','Не смешивайте медиану, IQR и общий размах. Для выброса сначала вычислите границу, затем сравните с 47.','Mediana, IQR va umumiy range ni aralashtirmang. Outlier uchun avval chegarani hisoblang, keyin 47 bilan solishtiring.'),
('P5DAT07-W01','P5-DAT-07','Data set A has mean 12, range 9, IQR 4 and standard deviation 2.5. Data set B is formed by y = 3x − 7. (a) Find the mean of B. (b) Find the range, IQR and standard deviation of B. (c) Explain why subtracting 7 affects the mean but not any measure of spread, while multiplying by 3 scales all spread measures.','У набора A среднее 12, размах 9, IQR 4 и стандартное отклонение 2,5. Набор B получен по формуле y = 3x − 7. (a) Найдите среднее B. (b) Найдите размах, IQR и стандартное отклонение B. (c) Объясните, почему вычитание 7 меняет среднее, но не меры разброса, а умножение на 3 масштабирует все меры разброса.','A to‘plamning o‘rtachasi 12, range 9, IQR 4 va SD 2.5. B to‘plam y=3x−7 orqali olinadi. (a) B ning o‘rtachasini toping. (b) B ning range, IQR va SD sini toping. (c) Nima uchun −7 markazni o‘zgartirib, tarqalishni o‘zgartirmasligini, 3 ga ko‘paytirish esa barcha tarqalish o‘lchovlarini masshtablashini tushuntiring.','{"max_marks":10,"criteria":[{"id":"mean","marks":2,"rule":"Finds mean B = 3×12−7 = 29."},{"id":"range","marks":2,"rule":"Finds range B = 27."},{"id":"iqr","marks":2,"rule":"Finds IQR B = 12."},{"id":"sd","marks":2,"rule":"Finds SD B = 7.5."},{"id":"reasoning","marks":2,"rule":"Explains translation leaves deviations/differences unchanged while scale factor 3 multiplies them by 3."}]}','Use location transformation for the mean. For spread, the −7 disappears from differences, while the factor 3 remains.','Для среднего используйте преобразование положения. В мерах разброса −7 исчезает из разностей, а множитель 3 остаётся.','O‘rtacha uchun joylashuv o‘zgarishini qo‘llang. Tarqalishda −7 farqlardan yo‘qoladi, 3 ko‘paytuvchi esa qoladi.')
)
insert into private.exam_prep_written_tasks(
  content_version_id,task_key,component_code,primary_skill_code,task_version,
  prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
  lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select cv.id,d.task_key,'P5',d.skill,'wtv1',d.en,d.ru,d.uz,d.rubric::jsonb,d.sen,d.sru,d.suz,
       'approved','pass','pass','pass','pass',now()
from defs d cross join cv
on conflict(content_version_id,task_key,task_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_aw09_12_data_v1' and component_code='P5' and status='draft'
), defs(k,t,en,ru,uz) as (values
('p5_aw09_12_data_diagnostic','diagnostic','P5 AW9-12 data diagnostic','Диагностика P5 AW9–12: данные','P5 AW9–12 ma’lumotlar diagnostikasi'),
('p5_dat05_learning','learning','Cumulative frequency learning','Накопленная частота: обучение','Kumulyativ chastota: o‘rganish'),
('p5_dat03_learning','learning','Box plots learning','Box plot: обучение','Box plot: o‘rganish'),
('p5_dat07_learning','learning','Spread measures learning','Меры разброса: обучение','Tarqalish o‘lchovlari: o‘rganish'),
('p5_dat05_retest','retest','Cumulative frequency delayed retest','Отложенный ретест: накопленная частота','Kechiktirilgan retest: kumulyativ chastota'),
('p5_dat03_retest','retest','Box plots delayed retest','Отложенный ретест: box plot','Kechiktirilgan retest: box plot'),
('p5_dat07_retest','retest','Spread measures delayed retest','Отложенный ретест: разброс','Kechiktirilgan retest: tarqalish'),
('p5_aw09_12_data_mixed','mixed','P5 AW9-12 data mixed transfer','Смешанный перенос P5 AW9–12: данные','P5 AW9–12 data mixed transfer')
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
select cv.id,d.k,'av1','P5',d.t,'approved',d.en,d.ru,d.uz
from defs d cross join cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_aw09_12_data_v1'
), a as (
  select x.id,x.assessment_key from private.exam_prep_assessments x join cv on cv.id=x.content_version_id
), m as (
  select x.content_key,x.question_id from private.exam_prep_question_content_meta x join cv on cv.id=x.content_version_id
), w as (
  select x.id,x.task_key from private.exam_prep_written_tasks x join cv on cv.id=x.content_version_id
), items(akey,ord,ckey,wkey,skill,role,holdout) as (values
('p5_aw09_12_data_diagnostic',1,'P5DAT05-D01',null,'P5-DAT-05','diagnostic',true),
('p5_aw09_12_data_diagnostic',2,'P5DAT03-D01',null,'P5-DAT-03','diagnostic',true),
('p5_aw09_12_data_diagnostic',3,'P5DAT07-D01',null,'P5-DAT-07','diagnostic',true),
('p5_dat05_learning',1,'P5DAT05-L01',null,'P5-DAT-05','learning',false),
('p5_dat05_learning',2,'P5DAT05-L02',null,'P5-DAT-05','learning',false),
('p5_dat05_learning',3,'P5DAT05-L03',null,'P5-DAT-05','learning',false),
('p5_dat05_learning',4,null,'P5DAT05-W01','P5-DAT-05','written',false),
('p5_dat03_learning',1,'P5DAT03-L01',null,'P5-DAT-03','learning',false),
('p5_dat03_learning',2,'P5DAT03-L02',null,'P5-DAT-03','learning',false),
('p5_dat03_learning',3,'P5DAT03-L03',null,'P5-DAT-03','learning',false),
('p5_dat03_learning',4,null,'P5DAT03-W01','P5-DAT-03','written',false),
('p5_dat07_learning',1,'P5DAT07-L01',null,'P5-DAT-07','learning',false),
('p5_dat07_learning',2,'P5DAT07-L02',null,'P5-DAT-07','learning',false),
('p5_dat07_learning',3,'P5DAT07-L03',null,'P5-DAT-07','learning',false),
('p5_dat07_learning',4,null,'P5DAT07-W01','P5-DAT-07','written',false),
('p5_dat05_retest',1,'P5DAT05-R01',null,'P5-DAT-05','retest',true),
('p5_dat03_retest',1,'P5DAT03-R01',null,'P5-DAT-03','retest',true),
('p5_dat07_retest',1,'P5DAT07-R01',null,'P5-DAT-07','retest',true),
('p5_aw09_12_data_mixed',1,'P5DAT05-M01',null,'P5-DAT-05','mixed',true),
('p5_aw09_12_data_mixed',2,'P5DAT03-M01',null,'P5-DAT-03','mixed',true),
('p5_aw09_12_data_mixed',3,'P5DAT07-M01',null,'P5-DAT-07','mixed',true)
)
insert into private.exam_prep_assessment_items(
  assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select a.id,i.ord,m.question_id,w.id,i.skill,i.role,i.holdout
from items i
join a on a.assessment_key=i.akey
left join m on m.content_key=i.ckey
left join w on w.task_key=i.wkey
on conflict(assessment_id,item_order) do nothing;

-- Static QA before publication.
do $$
declare v_id bigint; v_skill text; v_bad int;
begin
  select id into v_id from private.exam_prep_content_versions
  where content_version='p5_aw09_12_data_v1' and component_code='P5' and status='draft';
  if v_id is null then raise exception 'P1-02 P5 AW9-12 data: draft content version missing'; end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id)<>21 then
    raise exception 'P1-02 P5 AW9-12 data: expected 21 question objects';
  end if;
  foreach v_skill in array array['P5-DAT-05','P5-DAT-03','P5-DAT-07'] loop
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='diagnostic')<>1 then raise exception 'P5 AW9 data % diagnostic floor',v_skill; end if;
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='learning')<>3 then raise exception 'P5 AW9 data % learning floor',v_skill; end if;
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='retest')<>2 then raise exception 'P5 AW9 data % retest floor',v_skill; end if;
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='mixed')<>1 then raise exception 'P5 AW9 data % mixed floor',v_skill; end if;
    if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_id and primary_skill_code=v_skill and lifecycle_state='approved')<>1 then raise exception 'P5 AW9 data % written floor',v_skill; end if;
  end loop;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=v_id and (
    q.subject_id<>5 or q.is_active or q.quality_status is distinct from 'draft'
    or nullif(trim(q.question_text_en),'') is null or nullif(trim(q.question_text_ru),'') is null or nullif(trim(q.question_text_uz),'') is null
    or nullif(trim(q.options_text_en),'') is null or nullif(trim(q.options_text_ru),'') is null or nullif(trim(q.options_text_uz),'') is null
    or jsonb_typeof(q.options_text_en::jsonb)<>'array' or jsonb_array_length(q.options_text_en::jsonb)<>4
    or jsonb_typeof(q.options_text_ru::jsonb)<>'array' or jsonb_array_length(q.options_text_ru::jsonb)<>4
    or jsonb_typeof(q.options_text_uz::jsonb)<>'array' or jsonb_array_length(q.options_text_uz::jsonb)<>4
    or q.correct_answer not in ('A','B','C','D')
    or nullif(trim(q.explanation_en),'') is null or nullif(trim(q.explanation_ru),'') is null or nullif(trim(q.explanation_uz),'') is null
    or md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),
      coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5
  );
  if v_bad<>0 then raise exception 'P1-02 P5 AW9 data payload/isolation/snapshot failures=%',v_bad; end if;

  select count(*) into v_bad from (
    select m.id
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    left join private.exam_prep_diagnostic_rules r on r.content_meta_id=m.id and r.status='approved' and r.answer_kind='mcq_option'
    where m.content_version_id=v_id and m.reserve_role='diagnostic'
    group by m.id,q.correct_answer
    having count(r.id)<>3 or count(r.id) filter(where r.answer_match=q.correct_answer)<>0
  ) x;
  if v_bad<>0 then raise exception 'P1-02 P5 AW9 data diagnostic-rule contract failures=%',v_bad; end if;

  if (select count(*) from private.exam_prep_question_content_meta m where m.content_version_id=v_id and m.reserve_role='retest'
      and not exists(select 1 from private.exam_prep_assessment_items i where i.question_id=m.question_id))<>3 then
    raise exception 'P1-02 P5 AW9 data expected 3 isolated R02 holdouts';
  end if;
end $$;

-- QA approval and governed publication.
update private.exam_prep_question_content_meta m
set copyright_status='pass',qa_scope_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
    diagnostic_rule_status=case when reserve_role='diagnostic' then 'approved' else 'not_applicable' end,
    lifecycle_state='approved',approved_at=now(),updated_at=now()
from private.exam_prep_content_versions cv
where cv.id=m.content_version_id and cv.content_version='p5_aw09_12_data_v1' and cv.status='draft';

update private.exam_prep_content_versions
set status='approved',approved_at=now()
where content_version='p5_aw09_12_data_v1' and status='draft';

update private.exam_prep_question_content_meta m
set lifecycle_state=case when reserve_role='learning' then 'published' else 'reserve' end,
    exposure_state=case when reserve_role='learning' then 'released' else 'withheld' end,
    published_at=case when reserve_role='learning' then now() else null end,
    updated_at=now()
from private.exam_prep_content_versions cv
where cv.id=m.content_version_id and cv.content_version='p5_aw09_12_data_v1' and cv.status='approved';

update private.exam_prep_written_tasks w
set lifecycle_state='published'
from private.exam_prep_content_versions cv
where cv.id=w.content_version_id and cv.content_version='p5_aw09_12_data_v1' and cv.status='approved' and w.lifecycle_state='approved';

update private.exam_prep_assessments a
set status='published',approved_at=coalesce(a.approved_at,now())
from private.exam_prep_content_versions cv
where cv.id=a.content_version_id and cv.content_version='p5_aw09_12_data_v1' and cv.status='approved' and a.status='approved';

update private.exam_prep_content_versions
set status='published',published_at=now()
where content_version='p5_aw09_12_data_v1' and status='approved';

-- Final acceptance: 3/6 P5 AW9-12 skills ready; release stays RED; beta remains fail-closed.
do $$
declare v_program bigint; v_skill text; v_ready int; v_r jsonb; v_cfg private.exam_prep_feature_config%rowtype;
begin
  select id into v_program from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';

  foreach v_skill in array array['P5-DAT-05','P5-DAT-03','P5-DAT-07'] loop
    if not private.exam_prep_skill_content_ready_v1(v_program,'P5',v_skill) then
      raise exception 'P1-02 P5 AW9 data final skill not ready=%',v_skill;
    end if;
  end loop;

  select count(*) into v_ready
  from private.exam_prep_content_runway_release_skills rs
  join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.release_key='aw09_12_core_coverage_ii' and r.component_code='P5' and rs.required_for_release
    and private.exam_prep_skill_content_ready_v1(v_program,'P5',rs.skill_code);
  if v_ready<>3 then raise exception 'P1-02 P5 AW9 data expected P5 readiness=3 got=%',v_ready; end if;

  v_r:=public.get_exam_prep_content_runway_v1(9::smallint);
  if coalesce((v_r->>'hard_floor_green')::boolean,false) then
    raise exception 'P1-02 P5 AW9 data must leave global AW9 runway RED until all six P5 skills are ready';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-02 P5 AW9 data feature escaped fail-closed';
  end if;
  if exists(select 1 from private.exam_prep_feature_entitlements where entitlement_status='active') then
    raise exception 'P1-02 P5 AW9 data active entitlement residue';
  end if;
  if exists(select 1 from public.questions where book_ref like 'ExamPrep:P5:p5_aw09_12_data_v1:%' and is_active) then
    raise exception 'P1-02 P5 AW9 data legacy question activation detected';
  end if;
end $$;

commit;
