-- AW1-4 alternate learning pack drafts for P5.
-- DRAFT ONLY: no learner exposure, no QA self-approval, no publication.
-- Source authority: canonical P5 skill map + Complete Probability & Statistics 1 mapping.
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
    raise exception 'aw01_04_alt_p5_draft canonical program missing';
  end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4802 and content_version<>'p5_aw01_04_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15606 and 15609 and content_version_id<>4802)
     or exists(select 1 from private.exam_prep_assessments where id between 35206 and 35209 and content_version_id<>4802)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 58916 and 58927 and content_version_id<>4802)
  then
    raise exception 'aw01_04_alt_p5_draft reserved id collision';
  end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
  id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
select
  4802,pv.id,'p5_aw01_04_alt_learning_draft_v1','P5',
  'P5 AW1-4 alternate learning pack draft v1','draft',
  'Original iClub-authored alternate learning content. Canonical Cambridge 9709 skill scope and Complete Probability & Statistics 1 chapter mapping are used only to define learning objectives; no protected source question, solution, diagram or mark-scheme wording is copied. Draft requires independent academic, language, technical and copyright QA before approval/publication.',
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
('P5DAT01-A01','P5-DAT-01','P5 Representation of data','P5-DAT-01','medium','mcq',
 'A large set of continuous measurements is grouped into classes. Which graph is most suitable for estimating the median and quartiles from the grouped data?',
 '["Cumulative-frequency graph","Scatter plot","Pie chart","Stem-and-leaf diagram"]','A',
 'A cumulative-frequency graph is designed for reading approximate medians, quartiles and percentiles from grouped continuous data.',
 'Большой набор непрерывных измерений сгруппирован по интервалам. Какой график наиболее подходит для оценки медианы и квартилей по сгруппированным данным?',
 '["График накопленной частоты","Диаграмма рассеяния","Круговая диаграмма","Стебель-лист"]',
 'График накопленной частоты позволяет оценивать медиану, квартили и процентили по сгруппированным непрерывным данным.',
 'Katta uzluksiz o‘lchovlar to‘plami intervallarga guruhlangan. Guruhlangan ma’lumotlardan mediana va kvartillarni baholash uchun qaysi grafik eng mos?',
 '["Yig‘ma chastota grafigi","Nuqtali tarqalish diagrammasi","Doiraviy diagramma","Poya-barg diagrammasi"]',
 'Yig‘ma chastota grafigi guruhlangan uzluksiz ma’lumotlardan mediana, kvartil va percentillarni taxminiy o‘qish uchun mos.',60),

('P5DAT01-A02','P5-DAT-01','P5 Representation of data','P5-DAT-01','medium','mcq',
 'Two classes each have many test scores. A teacher wants to compare their medians and interquartile ranges quickly. Which display is most suitable?',
 '["Side-by-side box-and-whisker plots","Two pie charts","A scatter plot","A frequency table only"]','A',
 'Box-and-whisker plots show the median and quartiles directly, so they support a clear comparison of centre and spread.',
 'В двух классах много результатов теста. Учитель хочет быстро сравнить медианы и межквартильные размахи. Какое представление наиболее подходит?',
 '["Две диаграммы «ящик с усами» рядом","Две круговые диаграммы","Диаграмма рассеяния","Только таблица частот"]',
 'Диаграммы «ящик с усами» напрямую показывают медиану и квартили, поэтому удобны для сравнения центра и разброса.',
 'Ikki sinfda ko‘p test natijalari bor. O‘qituvchi medianalar va kvartillararo oraliqlarni tez taqqoslamoqchi. Qaysi tasvir eng mos?',
 '["Yonma-yon quti-mo‘ylov diagrammalari","Ikki doiraviy diagramma","Nuqtali tarqalish diagrammasi","Faqat chastota jadvali"]',
 'Quti-mo‘ylov diagrammalari mediana va kvartillarni bevosita ko‘rsatadi, shuning uchun markaz va tarqalishni taqqoslashga qulay.',60),

('P5DAT01-A03','P5-DAT-01','P5 Representation of data','P5-DAT-01','easy','mcq',
 'A survey records each student’s preferred school club. The aim is to show how the whole group is divided among the categories. Which representation is appropriate?',
 '["Pie chart","Histogram","Scatter plot","Cumulative-frequency graph"]','A',
 'The variable is categorical and the purpose is to show proportions of a whole, so a pie chart is appropriate.',
 'Опрос фиксирует предпочитаемый школьный кружок каждого ученика. Нужно показать, как вся группа распределена по категориям. Какое представление подходит?',
 '["Круговая диаграмма","Гистограмма","Диаграмма рассеяния","График накопленной частоты"]',
 'Переменная категориальная, а цель — показать доли от целого, поэтому подходит круговая диаграмма.',
 'So‘rovda har bir o‘quvchining yoqtirgan maktab to‘garagi qayd etiladi. Maqsad butun guruh kategoriyalarga qanday taqsimlanganini ko‘rsatish. Qaysi tasvir mos?',
 '["Doiraviy diagramma","Gistogramma","Nuqtali tarqalish diagrammasi","Yig‘ma chastota grafigi"]',
 'O‘zgaruvchi kategoriyali va maqsad butunning ulushlarini ko‘rsatish, shuning uchun doiraviy diagramma mos.',50),

('P5DAT02-A01','P5-DAT-02','P5 Representation of data','P5-DAT-02','easy','mcq',
 'A stem-and-leaf diagram has key 4 | 7 = 4.7. What value is represented by leaf 7 on stem 4?',
 '["4.7","47","0.47","11"]','A',
 'The key defines how to read the diagram: stem 4 with leaf 7 represents 4.7.',
 'В диаграмме «стебель-лист» дан ключ 4 | 7 = 4,7. Какое значение обозначает лист 7 при стебле 4?',
 '["4,7","47","0,47","11"]',
 'Ключ задаёт чтение диаграммы: стебель 4 и лист 7 обозначают 4,7.',
 'Poya-barg diagrammasida kalit 4 | 7 = 4.7. 4 poyadagi 7 barg qaysi qiymatni bildiradi?',
 '["4.7","47","0.47","11"]',
 'Kalit diagrammani qanday o‘qishni belgilaydi: 4 poya va 7 barg 4.7 ni bildiradi.',40),

('P5DAT02-A02','P5-DAT-02','P5 Representation of data','P5-DAT-02','medium','mcq',
 'Which stem-and-leaf diagram correctly represents 21, 24, 24, 29, 31, 36 with key 2 | 1 = 21?',
 '["2 | 1 4 4 9; 3 | 1 6","2 | 1 4 9; 3 | 1 4 6","2 | 1 2 4 9; 3 | 1 6","2 | 1 4 4; 3 | 1 6 9"]','A',
 'The 20s are 21,24,24,29, so the leaves on stem 2 are 1,4,4,9. The 30s are 31,36, giving leaves 1,6.',
 'Какая диаграмма «стебель-лист» правильно представляет 21, 24, 24, 29, 31, 36 при ключе 2 | 1 = 21?',
 '["2 | 1 4 4 9; 3 | 1 6","2 | 1 4 9; 3 | 1 4 6","2 | 1 2 4 9; 3 | 1 6","2 | 1 4 4; 3 | 1 6 9"]',
 'Числа из 20-х: 21,24,24,29, поэтому листья у стебля 2: 1,4,4,9. Числа из 30-х: 31,36, поэтому листья 1,6.',
 '2 | 1 = 21 kalitida 21, 24, 24, 29, 31, 36 ni qaysi poya-barg diagrammasi to‘g‘ri ko‘rsatadi?',
 '["2 | 1 4 4 9; 3 | 1 6","2 | 1 4 9; 3 | 1 4 6","2 | 1 2 4 9; 3 | 1 6","2 | 1 4 4; 3 | 1 6 9"]',
 '20-lik qiymatlar 21,24,24,29, demak 2 poyadagi barglar 1,4,4,9. 30-lik qiymatlar 31,36, barglar 1,6.',60),

('P5DAT02-A03','P5-DAT-02','P5 Representation of data','P5-DAT-02','medium','mcq',
 'A diagram with key 4 | 1 = 41 has 4 | 1 5 8 and 5 | 0 0 7 9. What is the median?',
 '["48","49","50","53.5"]','C',
 'The ordered values are 41,45,48,50,50,57,59. With seven values, the fourth value is the median, so the median is 50.',
 'В диаграмме с ключом 4 | 1 = 41 записано 4 | 1 5 8 и 5 | 0 0 7 9. Чему равна медиана?',
 '["48","49","50","53,5"]',
 'Упорядоченные значения: 41,45,48,50,50,57,59. При семи значениях медиана — четвёртое значение, то есть 50.',
 '4 | 1 = 41 kalitli diagrammada 4 | 1 5 8 va 5 | 0 0 7 9 berilgan. Mediana nechaga teng?',
 '["48","49","50","53.5"]',
 'Tartiblangan qiymatlar 41,45,48,50,50,57,59. Yetti qiymatda mediana to‘rtinchi qiymat, ya’ni 50.',60),

('P5DAT04-A01','P5-DAT-04','P5 Representation of data','P5-DAT-04','medium','input',
 'A histogram class has width 6 and frequency 45. Enter its frequency density.',
 '[]','7.5',
 'Frequency density = frequency ÷ class width = 45÷6 = 7.5.',
 'Интервал гистограммы имеет ширину 6 и частоту 45. Введите плотность частоты.',
 '[]',
 'Плотность частоты = частота ÷ ширина интервала = 45÷6 = 7,5.',
 'Gistogrammadagi interval kengligi 6, chastotasi 45. Chastota zichligini kiriting.',
 '[]',
 'Chastota zichligi = chastota ÷ interval kengligi = 45÷6 = 7.5.',50),

('P5DAT04-A02','P5-DAT-04','P5 Representation of data','P5-DAT-04','medium','input',
 'A histogram bar has frequency density 2.4 and class width 5. Enter the frequency represented by the bar.',
 '[]','12',
 'Frequency = frequency density × class width = 2.4×5 = 12.',
 'Столбец гистограммы имеет плотность частоты 2,4 и ширину интервала 5. Введите соответствующую частоту.',
 '[]',
 'Частота = плотность частоты × ширина интервала = 2,4×5 = 12.',
 'Gistogramma ustunining chastota zichligi 2.4, interval kengligi 5. Ustun ifodalagan chastotani kiriting.',
 '[]',
 'Chastota = chastota zichligi × interval kengligi = 2.4×5 = 12.',50),

('P5DAT04-A03','P5-DAT-04','P5 Representation of data','P5-DAT-04','hard','mcq',
 'In a histogram, class 0≤x<4 has frequency 16 and class 4≤x<10 has frequency 18. How do the bar heights compare?',
 '["The first bar is 4/3 times the height of the second","The bars have equal height","The second bar is 3/2 times the height of the first","The first bar is twice the height of the second"]','A',
 'The densities are 16/4=4 and 18/6=3. Histogram height is frequency density, so the first height is 4/3 of the second.',
 'В гистограмме интервал 0≤x<4 имеет частоту 16, а 4≤x<10 — частоту 18. Как соотносятся высоты столбцов?',
 '["Первый столбец в 4/3 раза выше второго","Столбцы одинаковой высоты","Второй столбец в 3/2 раза выше первого","Первый столбец вдвое выше второго"]',
 'Плотности равны 16/4=4 и 18/6=3. Высота столбца гистограммы — это плотность частоты, поэтому отношение высот равно 4/3.',
 'Gistogrammada 0≤x<4 interval chastotasi 16, 4≤x<10 interval chastotasi 18. Ustun balandliklari qanday taqqoslanadi?',
 '["Birinchi ustun ikkinchisidan 4/3 marta baland","Ustunlar balandligi teng","Ikkinchi ustun birinchisidan 3/2 marta baland","Birinchi ustun ikkinchisidan ikki marta baland"]',
 'Zichliklar 16/4=4 va 18/6=3. Gistogramma balandligi chastota zichligiga teng, shuning uchun balandliklar nisbati 4/3.',70),

('P5DAT06-A01','P5-DAT-06','P5 Representation of data','P5-DAT-06','easy','mcq',
 'The ordered data are 4, 6, 8, 8, 9, 15. What is the median?',
 '["7","8","9","10"]','B',
 'There are six values, so the median is the mean of the third and fourth values: (8+8)/2=8.',
 'Упорядоченные данные: 4, 6, 8, 8, 9, 15. Чему равна медиана?',
 '["7","8","9","10"]',
 'Значений шесть, поэтому медиана — среднее третьего и четвёртого значений: (8+8)/2=8.',
 'Tartiblangan ma’lumotlar 4, 6, 8, 8, 9, 15. Mediana nechaga teng?',
 '["7","8","9","10"]',
 'Oltita qiymat bor, shuning uchun mediana uchinchi va to‘rtinchi qiymatlarning o‘rtachasi: (8+8)/2=8.',45),

('P5DAT06-A02','P5-DAT-06','P5 Representation of data','P5-DAT-06','hard','input',
 'Grouped data have frequencies 2, 4, 2 in the intervals 0≤x<5, 5≤x<15, 15≤x<25. Using class midpoints, enter the estimated mean.',
 '[]','10.625',
 'The midpoints are 2.5, 10 and 20. The estimated mean is (2·2.5 + 4·10 + 2·20)/8 = 85/8 = 10.625.',
 'Сгруппированные данные имеют частоты 2, 4, 2 в интервалах 0≤x<5, 5≤x<15, 15≤x<25. Используя середины интервалов, введите оценку среднего.',
 '[]',
 'Середины интервалов: 2,5; 10; 20. Оценка среднего: (2·2,5 + 4·10 + 2·20)/8 = 85/8 = 10,625.',
 'Guruhlangan ma’lumotlarda 0≤x<5, 5≤x<15, 15≤x<25 intervallar uchun chastotalar 2, 4, 2. Interval o‘rtalaridan foydalanib, taxminiy o‘rtachani kiriting.',
 '[]',
 'Interval o‘rtalari 2.5, 10 va 20. Taxminiy o‘rtacha: (2·2.5 + 4·10 + 2·20)/8 = 85/8 = 10.625.',80),

('P5DAT06-A03','P5-DAT-06','P5 Representation of data','P5-DAT-06','medium','mcq',
 'The values are 8, 9, 10, 11, 12, 60. Which measure is the most representative typical value if the effect of the extreme value 60 should be limited?',
 '["Mean","Median","Mode","Range"]','B',
 'There is no mode and the value 60 pulls the mean upward. The median uses the two central ordered values and is much less affected by the extreme value.',
 'Даны значения 8, 9, 10, 11, 12, 60. Какая мера наиболее подходит как типичное значение, если нужно уменьшить влияние экстремального значения 60?',
 '["Среднее","Медиана","Мода","Размах"]',
 'Моды нет, а значение 60 сильно увеличивает среднее. Медиана определяется центральными упорядоченными значениями и намного меньше зависит от экстремального значения.',
 'Qiymatlar 8, 9, 10, 11, 12, 60. 60 ekstremal qiymatining ta’sirini kamaytirish kerak bo‘lsa, tipik qiymat uchun qaysi o‘lchov eng mos?',
 '["O‘rtacha","Mediana","Moda","Oraliq"]',
 'Moda yo‘q, 60 esa o‘rtachani yuqoriga tortadi. Mediana tartiblangan markaziy qiymatlardan olinadi va ekstremal qiymatdan ancha kam ta’sirlanadi.',60)
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
  'ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:'||s.content_key,
  s.time_limit,null,'draft'
from src s
where not exists(
  select 1 from public.questions q
  where q.book_ref='ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:'||s.content_key
);

insert into private.exam_prep_written_tasks(
  id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
  prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
  lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
) values
(15606,4802,'P5DAT01-AW02','P5','P5-DAT-01','{}','v1',
 'Two clinics record a large number of patient waiting times. The manager wants to compare typical waiting time and spread between the clinics without preserving every individual value. Choose a suitable representation, justify the choice, state two features you would compare, and explain why a scatter plot would not answer this question.',
 'Две клиники записывают большое число времён ожидания пациентов. Руководитель хочет сравнить типичное время ожидания и разброс между клиниками, не сохраняя каждое отдельное значение на графике. Выберите подходящее представление, обоснуйте выбор, укажите две характеристики для сравнения и объясните, почему диаграмма рассеяния не отвечает этой задаче.',
 'Ikki klinika ko‘p sonli bemor kutish vaqtlarini qayd etadi. Rahbar har bir alohida qiymatni grafikda saqlamasdan, klinikalar orasida tipik kutish va tarqalishni taqqoslamoqchi. Mos tasvirni tanlang, tanlovni asoslang, taqqoslanadigan ikki xususiyatni ayting va nima uchun nuqtali tarqalish diagrammasi bu savolga javob bermasligini tushuntiring.',
 '{"criteria":[{"id":"choice","rule":"Chooses side-by-side box-and-whisker plots or an equivalently justified distribution-comparison display.","marks":2},{"id":"features","rule":"Identifies two relevant features such as median, IQR/range or outliers.","marks":2},{"id":"critique","rule":"Explains scatter plots require paired values for two variables and are not for comparing two univariate waiting-time distributions.","marks":2}],"max_marks":6}',
 'Your representation should match the purpose: compare centre and spread of two one-variable datasets. Name concrete features visible on the chosen display and distinguish this from a two-variable association problem.',
 'Представление должно соответствовать цели: сравнить центр и разброс двух одномерных наборов. Назовите конкретные характеристики, видимые на выбранном графике, и отличите это от задачи о связи двух переменных.',
 'Tasvir maqsadga mos bo‘lsin: ikki bir o‘zgaruvchili to‘plamning markazi va tarqalishini taqqoslash. Tanlangan grafikda ko‘rinadigan aniq xususiyatlarni ayting va buni ikki o‘zgaruvchi orasidagi bog‘lanish masalasidan ajrating.',
 'draft','pending','pending','pending','pending'),

(15607,4802,'P5DAT02-AW02','P5','P5-DAT-02','{}','v1',
 'The observations are 2.3, 2.8, 3.1, 3.1, 3.5, 4.0, 4.2. Construct an ordered stem-and-leaf diagram with a key. Then find the median and range.',
 'Наблюдения: 2,3; 2,8; 3,1; 3,1; 3,5; 4,0; 4,2. Постройте упорядоченную диаграмму «стебель-лист» с ключом. Затем найдите медиану и размах.',
 'Kuzatuvlar: 2.3, 2.8, 3.1, 3.1, 3.5, 4.0, 4.2. Kalit bilan tartiblangan poya-barg diagrammasini tuzing. So‘ng mediana va oraliqni toping.',
 '{"criteria":[{"id":"diagram","rule":"Constructs correct ordered stems/leaves, retaining the repeated 3.1 and giving an unambiguous key such as 2|3=2.3.","marks":3},{"id":"median","rule":"Finds median 3.1.","marks":1},{"id":"range","rule":"Finds range 4.2-2.3=1.9.","marks":1}],"max_marks":5}',
 'Keep the duplicate 3.1, order all leaves, make the decimal place clear in the key, then use the central ordered value and largest-minus-smallest.',
 'Сохраните повтор 3,1, расположите листья по порядку, однозначно покажите десятичный разряд в ключе, затем используйте центральное значение и разность максимума и минимума.',
 'Takrorlangan 3.1 ni saqlang, barcha barglarni tartiblang, kalitda o‘nlik xonasini aniq ko‘rsating, so‘ng markaziy qiymat va eng katta-minus-eng kichik qiymatdan foydalaning.',
 'draft','pending','pending','pending','pending'),

(15608,4802,'P5DAT04-AW02','P5','P5-DAT-04','{}','v1',
 'Waiting times are grouped as follows: 0≤t<4: frequency 8; 4≤t<10: frequency 18; 10≤t<20: frequency 20. Calculate each frequency density, draw the histogram with labelled axes, and explain why the unequal class widths make raw frequencies unsuitable as bar heights.',
 'Время ожидания сгруппировано так: 0≤t<4: частота 8; 4≤t<10: частота 18; 10≤t<20: частота 20. Найдите каждую плотность частоты, постройте гистограмму с подписями осей и объясните, почему при неравных ширинах интервалов нельзя использовать обычные частоты как высоты столбцов.',
 'Kutish vaqtlari quyidagicha guruhlangan: 0≤t<4: chastota 8; 4≤t<10: chastota 18; 10≤t<20: chastota 20. Har bir chastota zichligini hisoblang, o‘qlari belgilangan gistogrammani chizing va nega interval kengliklari teng bo‘lmaganda oddiy chastotalarni ustun balandligi sifatida ishlatib bo‘lmasligini tushuntiring.',
 '{"criteria":[{"id":"densities","rule":"Finds densities 2,3,2.","marks":3},{"id":"histogram","rule":"Draws contiguous bars over the correct unequal intervals with vertical frequency-density scale and heights 2,3,2.","marks":3},{"id":"reason","rule":"Explains that frequency is represented by bar area, so unequal widths require density heights.","marks":1}],"max_marks":7}',
 'Use density = frequency/class width for all three classes. In the drawing, widths come from the intervals and heights from density; check that each bar area matches its frequency up to the common scale.',
 'Для всех трёх интервалов используйте плотность = частота/ширина интервала. На рисунке ширины берутся из интервалов, высоты — из плотности; проверьте, что площадь каждого столбца соответствует частоте.',
 'Uchala interval uchun zichlik = chastota/interval kengligi formulasidan foydalaning. Chizmada kengliklar intervallardan, balandliklar zichlikdan olinadi; har bir ustun yuzi chastotaga mosligini tekshiring.',
 'draft','pending','pending','pending','pending'),

(15609,4802,'P5DAT06-AW02','P5','P5-DAT-06','{}','v1',
 'A frequency table has values x=1,2,3,4 with frequencies 2,5,4,1 respectively. Calculate the mean, median and mode. Then explain briefly why the mean is larger than the median and mode for this distribution.',
 'В таблице частот значения x=1,2,3,4 имеют частоты 2,5,4,1 соответственно. Вычислите среднее, медиану и моду. Затем кратко объясните, почему среднее больше медианы и моды в этом распределении.',
 'Chastota jadvalida x=1,2,3,4 qiymatlariga mos chastotalar 2,5,4,1. O‘rtacha, mediana va modani hisoblang. So‘ng nima uchun bu taqsimotda o‘rtacha mediana va modadan kattaroq ekanini qisqacha tushuntiring.',
 '{"criteria":[{"id":"mean","rule":"Finds mean (1·2+2·5+3·4+4·1)/12=28/12=7/3≈2.33.","marks":2},{"id":"median_mode","rule":"Finds median 2 and mode 2.","marks":2},{"id":"explanation","rule":"Explains that the higher values 3 and 4 pull the arithmetic mean upward while the middle/more frequent position remains at 2.","marks":2}],"max_marks":6}',
 'Use frequencies as multiplicities, confirm the total frequency is 12, locate positions 6 and 7 for the median, and identify the highest frequency for the mode.',
 'Используйте частоты как число повторений, проверьте общий объём 12, найдите 6-е и 7-е значения для медианы и максимальную частоту для моды.',
 'Chastotalarni takrorlanish soni sifatida ishlating, jami chastota 12 ekanini tekshiring, mediana uchun 6- va 7-o‘rinlarni toping va moda uchun eng katta chastotani aniqlang.',
 'draft','pending','pending','pending','pending')
on conflict (id) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where id=4802 and content_version='p5_aw01_04_alt_learning_draft_v1'
),
src(meta_id,content_key,skill_code) as (values
 (58916,'P5DAT01-A01','P5-DAT-01'),(58917,'P5DAT01-A02','P5-DAT-01'),(58918,'P5DAT01-A03','P5-DAT-01'),
 (58919,'P5DAT02-A01','P5-DAT-02'),(58920,'P5DAT02-A02','P5-DAT-02'),(58921,'P5DAT02-A03','P5-DAT-02'),
 (58922,'P5DAT04-A01','P5-DAT-04'),(58923,'P5DAT04-A02','P5-DAT-04'),(58924,'P5DAT04-A03','P5-DAT-04'),
 (58925,'P5DAT06-A01','P5-DAT-06'),(58926,'P5DAT06-A02','P5-DAT-06'),(58927,'P5DAT06-A03','P5-DAT-06')
)
insert into private.exam_prep_question_content_meta(
  id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
  exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
  copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
select
  s.meta_id,cv.id,s.content_key,q.id,s.skill_code,'{}'::text[],'learning',
  'withheld','draft',
  'Original iClub-authored stem, data, distractors, answer and explanation; no Cambridge/coursebook question, diagram or mark-scheme wording copied.',
  'Alternate learning draft authored from the canonical skill intent. Independent values and contexts were chosen to avoid duplicating the current learning pack.',
  'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data',
  case when s.skill_code in ('P5-DAT-01','P5-DAT-02','P5-DAT-06')
       then 'Complete Probability & Statistics 1, Representation of data, Ch2 pp.14-29 (mapping only)'
       else 'Complete Probability & Statistics 1, Representation of data, Ch3 pp.34-59 (mapping only)' end,
  'pending','pending','pending','pending','pending','not_applicable',
  md5(concat_ws(chr(31),
    q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),
    coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
    coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),
    coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
    coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),
    coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')
  ))
from cv cross join src s
join public.questions q
  on q.book_ref='ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:'||s.content_key
on conflict (id) do nothing;

insert into private.exam_prep_assessments(
  id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
) values
(35206,4802,'P5-DAT-01-learning-alt-02','v1','P5','learning','draft','Data representation choice - alternate learning','Выбор представления данных - дополнительное обучение','Ma’lumotlarni tasvirlashni tanlash - qo‘shimcha o‘rganish'),
(35207,4802,'P5-DAT-02-learning-alt-02','v1','P5','learning','draft','Stem-and-leaf diagrams - alternate learning','Диаграммы «стебель-лист» - дополнительное обучение','Poya-barg diagrammalari - qo‘shimcha o‘rganish'),
(35208,4802,'P5-DAT-04-learning-alt-02','v1','P5','learning','draft','Histograms and frequency density - alternate learning','Гистограммы и плотность частоты - дополнительное обучение','Gistogrammalar va chastota zichligi - qo‘shimcha o‘rganish'),
(35209,4802,'P5-DAT-06-learning-alt-02','v1','P5','learning','draft','Mean, median and mode - alternate learning','Среднее, медиана и мода - дополнительное обучение','O‘rtacha, mediana va moda - qo‘shimcha o‘rganish')
on conflict (id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
 (35206,1,'P5DAT01-A01',null::bigint,'P5-DAT-01'),(35206,2,'P5DAT01-A02',null,'P5-DAT-01'),(35206,3,'P5DAT01-A03',null,'P5-DAT-01'),(35206,4,null,15606,'P5-DAT-01'),
 (35207,1,'P5DAT02-A01',null,'P5-DAT-02'),(35207,2,'P5DAT02-A02',null,'P5-DAT-02'),(35207,3,'P5DAT02-A03',null,'P5-DAT-02'),(35207,4,null,15607,'P5-DAT-02'),
 (35208,1,'P5DAT04-A01',null,'P5-DAT-04'),(35208,2,'P5DAT04-A02',null,'P5-DAT-04'),(35208,3,'P5DAT04-A03',null,'P5-DAT-04'),(35208,4,null,15608,'P5-DAT-04'),
 (35209,1,'P5DAT06-A01',null,'P5-DAT-06'),(35209,2,'P5DAT06-A02',null,'P5-DAT-06'),(35209,3,'P5DAT06-A03',null,'P5-DAT-06'),(35209,4,null,15609,'P5-DAT-06')
)
insert into private.exam_prep_assessment_items(
  assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select
  i.assessment_id,i.item_order,q.id,i.written_id,i.skill_code,
  case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions q
  on i.content_key is not null
 and q.book_ref='ExamPrep:P5:p5_aw01_04_alt_learning_draft_v1:'||i.content_key
on conflict (assessment_id,item_order) do nothing;

do $postcheck$
declare
  v_bad int;
begin
  if (select status from private.exam_prep_content_versions where id=4802)<>'draft'
     or (select count(*) from private.exam_prep_assessments where content_version_id=4802 and status='draft')<>4
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4802 and lifecycle_state='draft')<>4
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4802 and lifecycle_state='draft' and reserve_role='learning')<>12
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4802)<>16
  then
    raise exception 'aw01_04_alt_p5_draft cardinality/state postcheck failed';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id=4802
    and (
      m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or q.is_active<>false
      or q.quality_status<>'draft'
    );
  if v_bad<>0 then
    raise exception 'aw01_04_alt_p5_draft accidentally approved/exposed rows=%',v_bad;
  end if;

  if exists(
    select 1 from private.exam_prep_assessments a
    where a.content_version_id=4802 and a.status='published'
  ) then
    raise exception 'aw01_04_alt_p5_draft published assessment detected';
  end if;
end
$postcheck$;

commit;
