-- AW1-4 P5 annual-reserve top-up draft v1.
-- DRAFT ONLY: no learner exposure and no mutation of existing evidence.
-- Exact delta per skill: +2 diagnostics, +2 delayed retests, +1 mixed/transfer item.
-- Written annual target is already met for these skills, so no written task is duplicated.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(
    select 1 from private.exam_prep_program_versions
    where program_key='math_as_p1_p5'
      and version_key='p1_p5_canonical_v1_0'
      and status='active'
  ) then
    raise exception 'aw01_04_annual_reserve_p5_draft canonical program missing';
  end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4804 and content_version<>'p5_aw01_04_annual_reserve_topup_draft_v1')
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59026 and 59045 and content_version_id<>4804)
  then
    raise exception 'aw01_04_annual_reserve_p5_draft reserved id collision';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta m
      join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published'
        and m.primary_skill_code in ('P5-DAT-01','P5-DAT-02','P5-DAT-04','P5-DAT-06')
        and m.reserve_role='diagnostic' and m.lifecycle_state in ('published','reserve'))<>4
     or (select count(*) from private.exam_prep_question_content_meta m
      join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published'
        and m.primary_skill_code in ('P5-DAT-01','P5-DAT-02','P5-DAT-04','P5-DAT-06')
        and m.reserve_role='retest' and m.lifecycle_state in ('published','reserve'))<>8
  then
    raise exception 'aw01_04_annual_reserve_p5_draft baseline reserve counts changed';
  end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
  id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select
  4804,pv.id,'p5_aw01_04_annual_reserve_topup_draft_v1','P5',
  'P5 AW1-4 annual reserve top-up draft v1','draft',
  'Original iClub-authored annual reserve expansion. Cambridge 9709 scope and Complete Probability & Statistics 1 chapter mapping define objectives only; no protected source question, solution, mark-scheme wording or diagram is copied. Draft requires independent academic, trilingual, technical, originality and reserve-isolation QA before any publication.',
  3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5'
  and pv.version_key='p1_p5_canonical_v1_0'
  and pv.status='active'
on conflict (program_version_id,content_version) do nothing;

with src(
  content_key,skill_code,topic,subtopic,difficulty,qtype,
  q_en,opts_en,answer,exp_en,
  q_ru,opts_ru,exp_ru,
  q_uz,opts_uz,exp_uz,time_limit
) as (values
('P5DAT01-D02','P5-DAT-01','P5 Annual reserve','P5-DAT-01','medium','mcq','Two hundred continuous journey times are grouped into class intervals. The aim is to compare the shape of the distribution and identify modal regions. Which display is most suitable?','["Histogram","Cumulative-frequency graph","Pie chart","Scatter plot"]','A','A histogram is designed to show the shape of grouped continuous data. Bar areas represent frequencies, making modal regions visible.','Двести непрерывных значений времени поездки сгруппированы по интервалам. Нужно сравнить форму распределения и увидеть области с наибольшей частотой. Какое представление наиболее подходит?','["Гистограмма","График накопленных частот","Круговая диаграмма","Диаграмма рассеяния"]','Гистограмма показывает форму распределения сгруппированных непрерывных данных. Площади столбцов отражают частоты, поэтому области наибольшей частоты видны.','Ikki yuzta uzluksiz safar vaqti sinf oraliqlariga guruhlangan. Maqsad taqsimot shaklini solishtirish va eng ko‘p uchraydigan oraliqlarni aniqlash. Qaysi tasvir eng mos?','["Gistogramma","Yig‘ma chastota grafigi","Doiraviy diagramma","Tarqalish diagrammasi"]','Gistogramma guruhlangan uzluksiz ma’lumotlar taqsimotining shaklini ko‘rsatadi. Ustun yuzalari chastotalarni ifodalaydi, shuning uchun eng ko‘p uchraydigan oraliqlar ko‘rinadi.',70),
('P5DAT01-D03','P5-DAT-01','P5 Annual reserve','P5-DAT-01','medium','mcq','A large grouped continuous dataset is being used to estimate the median, quartiles and the proportion below a chosen value. Which display is most suitable?','["Histogram","Pie chart","Cumulative-frequency graph","Stem-and-leaf diagram"]','C','A cumulative-frequency graph is designed for reading medians, quartiles, percentiles and proportions from grouped continuous data.','Большой набор непрерывных данных сгруппирован по интервалам. Нужно оценить медиану, квартили и долю наблюдений ниже заданного значения. Какое представление наиболее подходит?','["Гистограмма","Круговая диаграмма","График накопленных частот","Стебле-листовая диаграмма"]','График накопленных частот позволяет оценивать медиану, квартили, процентили и доли по сгруппированным непрерывным данным.','Katta uzluksiz ma’lumotlar to‘plami oraliqlarga guruhlangan. Mediana, kvartillar va berilgan qiymatdan past kuzatuvlar ulushini baholash kerak. Qaysi tasvir eng mos?','["Gistogramma","Doiraviy diagramma","Yig‘ma chastota grafigi","Poya-barg diagrammasi"]','Yig‘ma chastota grafigi guruhlangan uzluksiz ma’lumotlardan mediana, kvartillar, protsentillar va ulushlarni baholash uchun mos.',65),
('P5DAT01-R03','P5-DAT-01','P5 Annual reserve','P5-DAT-01','medium','mcq','A school wants to compare the medians and interquartile ranges of test scores in five classes. Which display is most efficient?','["Pie charts","Scatter plots","Line graphs","Box-and-whisker plots"]','D','Box-and-whisker plots show the median and quartiles directly and are convenient for side-by-side comparison.','Школа хочет сравнить медианы и межквартильные размахи результатов пяти классов. Какое представление наиболее удобно?','["Круговые диаграммы","Диаграммы рассеяния","Линейные графики","Диаграммы размаха"]','Диаграммы размаха непосредственно показывают медиану и квартили и удобны для сравнения нескольких групп.','Maktab beshta sinf natijalarining medianalari va kvartillar oralig‘ini solishtirmoqchi. Qaysi tasvir eng qulay?','["Doiraviy diagrammalar","Tarqalish diagrammalari","Chiziqli grafiklar","Quti va mo‘ylov diagrammalari"]','Quti va mo‘ylov diagrammalari medianani va kvartillarni bevosita ko‘rsatadi hamda guruhlarni yonma-yon solishtirishga qulay.',70),
('P5DAT01-R04','P5-DAT-01','P5 Annual reserve','P5-DAT-01','medium','mcq','A researcher has 16 integer observations and wants a compact display that still preserves every original value. Which representation is best?','["Cumulative-frequency graph","Stem-and-leaf diagram","Histogram","Pie chart"]','B','A stem-and-leaf diagram preserves individual observations while also showing the distribution.','У исследователя есть 16 целочисленных наблюдений. Нужен компактный способ показать данные, сохранив каждое исходное значение. Какое представление лучше?','["График накопленных частот","Стебле-листовая диаграмма","Гистограмма","Круговая диаграмма"]','Стебле-листовая диаграмма сохраняет отдельные наблюдения и одновременно показывает распределение.','Tadqiqotchida 16 ta butun sonli kuzatuv bor. Har bir asl qiymatni saqlagan holda ixcham tasvir kerak. Qaysi tasvir eng mos?','["Yig‘ma chastota grafigi","Poya-barg diagrammasi","Gistogramma","Doiraviy diagramma"]','Poya-barg diagrammasi alohida kuzatuvlarni saqlaydi va bir vaqtning o‘zida taqsimotni ko‘rsatadi.',70),
('P5DAT01-M02','P5-DAT-01','P5 Annual reserve','P5-DAT-01','hard','mcq','Rainfall amounts are continuous and grouped into intervals of unequal width. Which choice gives both the appropriate display and the correct reason for using it?','["Histogram, because each bar height equals the raw frequency","Histogram, using frequency density so bar area represents frequency","Cumulative-frequency graph, because each bar area represents frequency","Scatter plot, because class width is unequal"]','B','For grouped continuous data with unequal class widths, a histogram is appropriate and its height must be frequency density so that bar area represents frequency.','Количество осадков — непрерывные данные, сгруппированные по интервалам разной ширины. Какой вариант правильно указывает и вид графика, и причину его использования?','["Гистограмма, потому что высота каждого столбца равна обычной частоте","Гистограмма с плотностью частоты, чтобы площадь столбца отражала частоту","График накопленных частот, потому что площадь каждого столбца отражает частоту","Диаграмма рассеяния, потому что ширины интервалов различаются"]','Для сгруппированных непрерывных данных с неравными ширинами интервалов подходит гистограмма; высота столбца должна быть плотностью частоты, чтобы площадь отражала частоту.','Yog‘in miqdori uzluksiz bo‘lib, kengligi turlicha oraliqlarga guruhlangan. Qaysi variant mos tasvirni va undan foydalanish sababini to‘g‘ri beradi?','["Gistogramma, chunki har bir ustun balandligi oddiy chastotaga teng","Chastota zichligidan foydalangan gistogramma, shunda ustun yuzi chastotani ifodalaydi","Yig‘ma chastota grafigi, chunki har bir ustun yuzi chastotani ifodalaydi","Tarqalish diagrammasi, chunki sinf kengliklari turlicha"]','Kengligi turlicha sinflarga guruhlangan uzluksiz ma’lumotlar uchun gistogramma mos; ustun balandligi chastota zichligi bo‘lishi kerak, shunda yuza chastotani ifodalaydi.',90),
('P5DAT02-D02','P5-DAT-02','P5 Annual reserve','P5-DAT-02','medium','mcq','A stem-and-leaf diagram has key 7 | 3 = 7.3. What value is represented by leaf 5 on stem 6?','["65","6.5","0.65","6.05"]','B','The key shows that the stem gives the units and the leaf gives the tenths, so 6 | 5 represents 6.5.','В стебле-листовой диаграмме ключ 7 | 3 = 7,3. Какое значение показывает лист 5 при стебле 6?','["65","6,5","0,65","6,05"]','Ключ показывает, что стебель задаёт единицы, а лист — десятые, поэтому 6 | 5 означает 6,5.','Poya-barg diagrammasida kalit 7 | 3 = 7.3. 6 poyadagi 5 barg qaysi qiymatni bildiradi?','["65","6.5","0.65","6.05"]','Kalit poya birliklarni, barg esa o‘ndan birlarni bildirishini ko‘rsatadi, demak 6 | 5 = 6.5.',55),
('P5DAT02-D03','P5-DAT-02','P5 Annual reserve','P5-DAT-02','medium','mcq','Which stem-and-leaf diagram correctly represents 4.1, 4.3, 4.3, 5.0 with key 4 | 1 = 4.1?','["4 | 1 3 ; 5 | 3 0","4 | 1 3 5 ; 5 | 0","4 | 1 3 3 0 ; 5 |","4 | 1 3 3 ; 5 | 0"]','D','The two 4.3 observations require two leaves 3 on stem 4, while 5.0 is leaf 0 on stem 5.','Какая стебле-листовая диаграмма правильно представляет 4,1; 4,3; 4,3; 5,0 при ключе 4 | 1 = 4,1?','["4 | 1 3 ; 5 | 3 0","4 | 1 3 5 ; 5 | 0","4 | 1 3 3 0 ; 5 |","4 | 1 3 3 ; 5 | 0"]','Два значения 4,3 требуют двух листьев 3 при стебле 4, а 5,0 записывается как лист 0 при стебле 5.','4 | 1 = 4.1 kalitida 4.1, 4.3, 4.3, 5.0 qiymatlarini qaysi poya-barg diagrammasi to‘g‘ri ko‘rsatadi?','["4 | 1 3 ; 5 | 3 0","4 | 1 3 5 ; 5 | 0","4 | 1 3 3 0 ; 5 |","4 | 1 3 3 ; 5 | 0"]','Ikki marta uchraydigan 4.3 uchun 4 poyada ikkita 3 barg kerak, 5.0 esa 5 poyadagi 0 barg sifatida yoziladi.',65),
('P5DAT02-R03','P5-DAT-02','P5 Annual reserve','P5-DAT-02','medium','input','A stem-and-leaf diagram has key 2 | 4 = 24 and rows 2 | 4 7 9 and 3 | 1 1 8. Enter the median.','[]','30','The values are 24,27,29,31,31,38. The median is the mean of the third and fourth values: (29+31)/2=30.','В стебле-листовой диаграмме ключ 2 | 4 = 24, строки: 2 | 4 7 9 и 3 | 1 1 8. Введите медиану.','[]','Значения: 24, 27, 29, 31, 31, 38. Медиана — среднее третьего и четвёртого значений: (29+31)/2=30.','Poya-barg diagrammasida kalit 2 | 4 = 24, qatorlar: 2 | 4 7 9 va 3 | 1 1 8. Medianani kiriting.','[]','Qiymatlar 24, 27, 29, 31, 31, 38. Mediana uchinchi va to‘rtinchi qiymatlarning o‘rtachasi: (29+31)/2=30.',70),
('P5DAT02-R04','P5-DAT-02','P5 Annual reserve','P5-DAT-02','medium','mcq','A stem-and-leaf diagram has key 5 | 2 = 5.2 and rows 5 | 2 8 and 6 | 0 1 7. What is the range?','["0.9","1.0","1.5","15"]','C','The smallest value is 5.2 and the largest is 6.7, so the range is 6.7−5.2=1.5.','В стебле-листовой диаграмме ключ 5 | 2 = 5,2, строки: 5 | 2 8 и 6 | 0 1 7. Чему равен размах?','["0,9","1,0","1,5","15"]','Наименьшее значение 5,2, наибольшее 6,7, поэтому размах равен 6,7−5,2=1,5.','Poya-barg diagrammasida kalit 5 | 2 = 5.2, qatorlar: 5 | 2 8 va 6 | 0 1 7. Oraliq kengligi qancha?','["0.9","1.0","1.5","15"]','Eng kichik qiymat 5.2, eng katta qiymat 6.7, demak oraliq kengligi 6.7−5.2=1.5.',60),
('P5DAT02-M02','P5-DAT-02','P5 Annual reserve','P5-DAT-02','hard','mcq','A stem-and-leaf diagram has key 3 | 2 = 32 and rows 3 | 2 2 5 8 and 4 | 0 1. Which statement is correct?','["The mode is 32 and the median is 36.5.","The mode is 35 and the median is 36.5.","The mode is 32 and the median is 35.","There is no mode and the median is 38."]','A','The values are 32,32,35,38,40,41. The repeated value 32 is the mode and the median is (35+38)/2=36.5.','В стебле-листовой диаграмме ключ 3 | 2 = 32, строки: 3 | 2 2 5 8 и 4 | 0 1. Какое утверждение верно?','["Мода равна 32, медиана — 36,5.","Мода равна 35, медиана — 36,5.","Мода равна 32, медиана — 35.","Моды нет, медиана — 38."]','Значения: 32, 32, 35, 38, 40, 41. Повторяющееся значение 32 — мода, а медиана равна (35+38)/2=36,5.','Poya-barg diagrammasida kalit 3 | 2 = 32, qatorlar: 3 | 2 2 5 8 va 4 | 0 1. Qaysi tasdiq to‘g‘ri?','["Moda 32, mediana 36.5.","Moda 35, mediana 36.5.","Moda 32, mediana 35.","Moda yo‘q, mediana 38."]','Qiymatlar 32, 32, 35, 38, 40, 41. Takrorlangan 32 — moda, mediana esa (35+38)/2=36.5.',80),
('P5DAT04-D02','P5-DAT-04','P5 Annual reserve','P5-DAT-04','medium','mcq','A histogram class has width 5 and frequency 30. What should the frequency density be?','["25","150","6","1/6"]','C','Frequency density = frequency ÷ class width = 30÷5=6.','Интервал гистограммы имеет ширину 5 и частоту 30. Какой должна быть плотность частоты?','["25","150","6","1/6"]','Плотность частоты = частота ÷ ширина интервала = 30÷5=6.','Gistogramma sinfining kengligi 5, chastotasi 30. Chastota zichligi qancha bo‘lishi kerak?','["25","150","6","1/6"]','Chastota zichligi = chastota ÷ sinf kengligi = 30÷5=6.',55),
('P5DAT04-D03','P5-DAT-04','P5 Annual reserve','P5-DAT-04','medium','mcq','In a histogram, class A has width 4 and frequency density 3, while class B has width 6 and frequency density 2. Which statement is correct?','["Class A has frequency 7.","Class B has frequency 8.","Class B has the greater frequency.","The two classes have equal frequencies."]','D','Frequency equals class width × frequency density. Class A has 4×3=12 and class B has 6×2=12.','На гистограмме интервал A имеет ширину 4 и плотность частоты 3, а интервал B — ширину 6 и плотность частоты 2. Какое утверждение верно?','["Частота интервала A равна 7.","Частота интервала B равна 8.","У интервала B частота больше.","Частоты двух интервалов равны."]','Частота равна ширине интервала × плотность частоты. Для A: 4×3=12, для B: 6×2=12.','Gistogrammada A sinf kengligi 4 va chastota zichligi 3, B sinf kengligi 6 va chastota zichligi 2. Qaysi tasdiq to‘g‘ri?','["A sinf chastotasi 7.","B sinf chastotasi 8.","B sinf chastotasi kattaroq.","Ikki sinfning chastotalari teng."]','Chastota = sinf kengligi × chastota zichligi. A uchun 4×3=12, B uchun 6×2=12.',70),
('P5DAT04-R03','P5-DAT-04','P5 Annual reserve','P5-DAT-04','medium','input','A histogram class has width 2.5 and frequency 15. Enter its frequency density.','[]','6','Frequency density = 15÷2.5=6.','Интервал гистограммы имеет ширину 2,5 и частоту 15. Введите плотность частоты.','[]','Плотность частоты = 15÷2,5=6.','Gistogramma sinfining kengligi 2.5, chastotasi 15. Chastota zichligini kiriting.','[]','Chastota zichligi = 15÷2.5=6.',55),
('P5DAT04-R04','P5-DAT-04','P5 Annual reserve','P5-DAT-04','medium','mcq','A histogram bar has frequency density 4.5 and class width 8. What frequency does the bar represent?','["36","12.5","4.5","1.777..."]','A','Frequency = frequency density × class width = 4.5×8=36.','Столбец гистограммы имеет плотность частоты 4,5 и ширину интервала 8. Какую частоту он представляет?','["36","12,5","4,5","1,777..."]','Частота = плотность частоты × ширина интервала = 4,5×8=36.','Gistogramma ustunining chastota zichligi 4.5, sinf kengligi 8. U qaysi chastotani ifodalaydi?','["36","12.5","4.5","1.777..."]','Chastota = chastota zichligi × sinf kengligi = 4.5×8=36.',60),
('P5DAT04-M02','P5-DAT-04','P5 Annual reserve','P5-DAT-04','hard','input','A histogram has two adjacent classes. The first has width 4 and frequency density 3; the second has width 6 and frequency density 2.5. Enter the total frequency in the two classes.','[]','27','The frequencies are 4×3=12 and 6×2.5=15, giving a total of 27.','На гистограмме два соседних интервала. Первый имеет ширину 4 и плотность частоты 3, второй — ширину 6 и плотность частоты 2,5. Введите суммарную частоту двух интервалов.','[]','Частоты равны 4×3=12 и 6×2,5=15, всего 27.','Gistogrammada ikkita yonma-yon sinf bor. Birinchisining kengligi 4 va chastota zichligi 3, ikkinchisining kengligi 6 va chastota zichligi 2.5. Ikki sinfdagi jami chastotani kiriting.','[]','Chastotalar 4×3=12 va 6×2.5=15, jami 27.',75),
('P5DAT06-D02','P5-DAT-06','P5 Annual reserve','P5-DAT-06','medium','mcq','The values 1, 2 and 3 occur with frequencies 2, 3 and 1 respectively. What is the mean?','["11/3","11/6","2","6/11"]','B','The weighted total is 1·2+2·3+3·1=11 and there are 6 observations, so the mean is 11/6.','Значения 1, 2 и 3 встречаются с частотами 2, 3 и 1 соответственно. Чему равно среднее?','["11/3","11/6","2","6/11"]','Взвешенная сумма равна 1·2+2·3+3·1=11, наблюдений 6, поэтому среднее равно 11/6.','1, 2 va 3 qiymatlar mos ravishda 2, 3 va 1 marta uchraydi. O‘rtacha qiymat qancha?','["11/3","11/6","2","6/11"]','Og‘irlikli yig‘indi 1·2+2·3+3·1=11, kuzatuvlar soni 6, demak o‘rtacha 11/6.',65),
('P5DAT06-D03','P5-DAT-06','P5 Annual reserve','P5-DAT-06','medium','mcq','What is the median of 4, 5, 6, 20?','["5","6","5.5","8.75"]','C','There are four ordered values, so the median is the mean of the middle two: (5+6)/2=5.5.','Чему равна медиана набора 4, 5, 6, 20?','["5","6","5,5","8,75"]','Значений четыре, поэтому медиана — среднее двух центральных: (5+6)/2=5,5.','4, 5, 6, 20 ma’lumotlarining medianasi qancha?','["5","6","5.5","8.75"]','To‘rtta tartiblangan qiymat bor, shuning uchun mediana o‘rtadagi ikkita qiymatning o‘rtachasi: (5+6)/2=5.5.',55),
('P5DAT06-R03','P5-DAT-06','P5 Annual reserve','P5-DAT-06','medium','input','The values 2, 4 and 6 occur with frequencies 1, 2 and 1 respectively. Enter the mean.','[]','4','The weighted total is 2·1+4·2+6·1=16 across 4 observations, so the mean is 4.','Значения 2, 4 и 6 встречаются с частотами 1, 2 и 1 соответственно. Введите среднее.','[]','Взвешенная сумма равна 2·1+4·2+6·1=16 при 4 наблюдениях, поэтому среднее равно 4.','2, 4 va 6 qiymatlar mos ravishda 1, 2 va 1 marta uchraydi. O‘rtacha qiymatni kiriting.','[]','Og‘irlikli yig‘indi 2·1+4·2+6·1=16, kuzatuvlar soni 4, demak o‘rtacha 4.',60),
('P5DAT06-R04','P5-DAT-06','P5 Annual reserve','P5-DAT-06','medium','mcq','For the data 3, 3, 5, 7, 12, which triple gives (mean, median, mode)?','["(5, 6, 3)","(6, 3, 5)","(6, 5, 5)","(6, 5, 3)"]','D','The total is 30, so the mean is 6. The middle value is 5 and the repeated value is 3.','Для данных 3, 3, 5, 7, 12 какая тройка задаёт (среднее, медиану, моду)?','["(5, 6, 3)","(6, 3, 5)","(6, 5, 5)","(6, 5, 3)"]','Сумма равна 30, поэтому среднее равно 6. Центральное значение — 5, повторяющееся значение — 3.','3, 3, 5, 7, 12 ma’lumotlari uchun qaysi uchlik (o‘rtacha, mediana, moda) ni beradi?','["(5, 6, 3)","(6, 3, 5)","(6, 5, 5)","(6, 5, 3)"]','Yig‘indi 30, demak o‘rtacha 6. O‘rtadagi qiymat 5, takrorlangan qiymat 3.',65),
('P5DAT06-M02','P5-DAT-06','P5 Annual reserve','P5-DAT-06','hard','mcq','Dataset A is 8, 9, 10, 11, 12. Dataset B is 8, 9, 10, 11, 32. Which statement is correct?','["The medians are equal, but B has the larger mean because of the high value 32.","The means are equal, but B has the larger median.","Both the means and medians are equal.","B has the smaller mean because 32 is an outlier."]','A','Both medians are 10. The mean of A is 10, while the mean of B is 14, showing the effect of the large value 32.','Набор A: 8, 9, 10, 11, 12. Набор B: 8, 9, 10, 11, 32. Какое утверждение верно?','["Медианы равны, но у B среднее больше из-за большого значения 32.","Средние равны, но у B медиана больше.","И средние, и медианы равны.","У B среднее меньше, потому что 32 — выброс."]','Обе медианы равны 10. Среднее A равно 10, а среднее B равно 14, что показывает влияние большого значения 32.','A to‘plam: 8, 9, 10, 11, 12. B to‘plam: 8, 9, 10, 11, 32. Qaysi tasdiq to‘g‘ri?','["Medianalar teng, ammo 32 katta qiymat bo‘lgani uchun B ning o‘rtachasi kattaroq.","O‘rtachalar teng, ammo B ning medianasi kattaroq.","O‘rtachalar ham, medianalar ham teng.","32 chet qiymat bo‘lgani uchun B ning o‘rtachasi kichikroq."]','Har ikkala mediana 10. A ning o‘rtachasi 10, B ning o‘rtachasi 14; bu 32 katta qiymatning ta’sirini ko‘rsatadi.',80)
)
insert into public.questions(
  subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
  question_text_ru,question_text_uz,question_text_en,
  options_text_ru,options_text_uz,options_text_en,
  explanation_ru,explanation_uz,explanation_en,
  book_ref,time_limit_sec,quality_flag,quality_status
)
select
  5,s.topic,s.subtopic,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
  s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
  'ExamPrep:P5:p5_aw01_04_annual_reserve_topup_draft_v1:'||s.content_key,
  s.time_limit,null,'draft'
from src s
where not exists(
  select 1 from public.questions q
  where q.book_ref='ExamPrep:P5:p5_aw01_04_annual_reserve_topup_draft_v1:'||s.content_key
);

with keys(content_key,skill_code,reserve_role,meta_id,coursebook_ref) as (values
('P5DAT01-D02','P5-DAT-01','diagnostic',59026,'Complete Probability & Statistics 1, Ch2-3 pp.14-59 (mapping only)'),
('P5DAT01-D03','P5-DAT-01','diagnostic',59027,'Complete Probability & Statistics 1, Ch2-3 pp.14-59 (mapping only)'),
('P5DAT01-R03','P5-DAT-01','retest',59028,'Complete Probability & Statistics 1, Ch2-3 pp.14-59 (mapping only)'),
('P5DAT01-R04','P5-DAT-01','retest',59029,'Complete Probability & Statistics 1, Ch2-3 pp.14-59 (mapping only)'),
('P5DAT01-M02','P5-DAT-01','mixed',59030,'Complete Probability & Statistics 1, Ch2-3 pp.14-59 (mapping only)'),
('P5DAT02-D02','P5-DAT-02','diagnostic',59031,'Complete Probability & Statistics 1, Ch3 Representation of data pp.34-59 (mapping only)'),
('P5DAT02-D03','P5-DAT-02','diagnostic',59032,'Complete Probability & Statistics 1, Ch3 Representation of data pp.34-59 (mapping only)'),
('P5DAT02-R03','P5-DAT-02','retest',59033,'Complete Probability & Statistics 1, Ch3 Representation of data pp.34-59 (mapping only)'),
('P5DAT02-R04','P5-DAT-02','retest',59034,'Complete Probability & Statistics 1, Ch3 Representation of data pp.34-59 (mapping only)'),
('P5DAT02-M02','P5-DAT-02','mixed',59035,'Complete Probability & Statistics 1, Ch3 Representation of data pp.34-59 (mapping only)'),
('P5DAT04-D02','P5-DAT-04','diagnostic',59036,'Complete Probability & Statistics 1, Ch3 Representation of data pp.34-59 (mapping only)'),
('P5DAT04-D03','P5-DAT-04','diagnostic',59037,'Complete Probability & Statistics 1, Ch3 Representation of data pp.34-59 (mapping only)'),
('P5DAT04-R03','P5-DAT-04','retest',59038,'Complete Probability & Statistics 1, Ch3 Representation of data pp.34-59 (mapping only)'),
('P5DAT04-R04','P5-DAT-04','retest',59039,'Complete Probability & Statistics 1, Ch3 Representation of data pp.34-59 (mapping only)'),
('P5DAT04-M02','P5-DAT-04','mixed',59040,'Complete Probability & Statistics 1, Ch3 Representation of data pp.34-59 (mapping only)'),
('P5DAT06-D02','P5-DAT-06','diagnostic',59041,'Complete Probability & Statistics 1, Ch2 Measures of location and spread pp.14-29 (mapping only)'),
('P5DAT06-D03','P5-DAT-06','diagnostic',59042,'Complete Probability & Statistics 1, Ch2 Measures of location and spread pp.14-29 (mapping only)'),
('P5DAT06-R03','P5-DAT-06','retest',59043,'Complete Probability & Statistics 1, Ch2 Measures of location and spread pp.14-29 (mapping only)'),
('P5DAT06-R04','P5-DAT-06','retest',59044,'Complete Probability & Statistics 1, Ch2 Measures of location and spread pp.14-29 (mapping only)'),
('P5DAT06-M02','P5-DAT-06','mixed',59045,'Complete Probability & Statistics 1, Ch2 Measures of location and spread pp.14-29 (mapping only)')
)
insert into private.exam_prep_question_content_meta(
  id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,
  reserve_role,exposure_state,lifecycle_state,
  originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
  copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,
  diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select
  k.meta_id,4804,k.content_key,q.id,k.skill_code,'{}'::text[],
  k.reserve_role,'withheld','draft',
  'Original iClub-authored stem, data, distractors, answer and explanation; no Cambridge/coursebook question, diagram, solution or mark-scheme wording copied.',
  'Authored as AW1-4 annual-reserve top-up. Purpose is future diagnostic/retest/transfer depth, not reinterpretation of existing learner evidence.',
  'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data',
  k.coursebook_ref,
  'pending','pending','pending','pending','pending',
  case when k.reserve_role='diagnostic' then 'pending' else 'not_applicable' end,
  md5(concat_ws(chr(31),
    q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
    coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
    coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
    coalesce(q.image_url,''),coalesce(q.is_active::text,''),
    coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
    coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
    coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
    coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
    coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from keys k
join public.questions q
  on q.book_ref='ExamPrep:P5:p5_aw01_04_annual_reserve_topup_draft_v1:'||k.content_key
on conflict(content_version_id,content_key) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select status from private.exam_prep_content_versions where id=4804)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4804)<>20
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4804 and reserve_role='diagnostic')<>8
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4804 and reserve_role='retest')<>8
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4804 and reserve_role='mixed')<>4
  then
    raise exception 'aw01_04_annual_reserve_p5_draft cardinality/state postcheck failed';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id=4804
    and (
      m.lifecycle_state<>'draft' or m.exposure_state<>'withheld'
      or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending' or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or q.is_active<>false or q.quality_status<>'draft'
      or nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
    );
  if v_bad<>0 then
    raise exception 'aw01_04_annual_reserve_p5_draft governance/exposure failure rows=%',v_bad;
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id=4804
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id=4804
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id=4804
  ) then
    raise exception 'aw01_04_annual_reserve_p5_draft unexpected learner/legacy history';
  end if;
end
$postcheck$;

commit;
