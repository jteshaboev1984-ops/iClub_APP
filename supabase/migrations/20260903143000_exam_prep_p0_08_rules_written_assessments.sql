-- P0-08: complete beta-floor governance objects for the P5 Representation opening slice.
-- Adds diagnostic interpretations, Core-accessible written tasks/rubrics and reserve-isolated assessment memberships.
-- No learner delivery endpoint is created here.

begin;

-- Intentional diagnostic distractor rules: 3 per diagnostic item.
with cv as (select id from private.exam_prep_content_versions where content_version='p5_repr_beta_v1'), rules(content_key,answer_match,dcode,mtype,weak,fen,fru,fuz,nen,nru,nuz) as (values
('P5DAT01-D01','A','scatter_for_distribution','model_selection','P5-DAT-01','A scatter plot is for association between paired numerical variables, not for comparing medians and spread of several groups.','Диаграмма рассеяния предназначена для связи между парными числовыми переменными, а не для сравнения медиан и разброса нескольких групп.','Nuqtali diagramma juft sonli o‘zgaruvchilar orasidagi bog‘lanish uchun; bir nechta guruh medianasi va tarqalishini taqqoslash uchun emas.','Match the purpose of the analysis to what each representation displays.','Сопоставьте цель анализа с тем, какие характеристики показывает каждая диаграмма.','Tahlil maqsadini har bir tasvirlash usuli nimani ko‘rsatishi bilan moslang.'),
('P5DAT01-D01','B','part_whole_for_spread','model_selection','P5-DAT-01','A pie chart shows part-to-whole categorical proportions and does not show quartiles or spread.','Круговая диаграмма показывает доли категорий от целого и не показывает квартили или разброс.','Doira diagrammasi kategoriyalarning butundagi ulushini ko‘rsatadi, kvartillar yoki tarqalishni emas.','Review which displays preserve or summarise numerical distribution features.','Повторите, какие диаграммы сохраняют или суммируют характеристики числового распределения.','Sonli taqsimot xususiyatlarini qaysi diagrammalar saqlashi yoki umumlashtirishini ko‘rib chiqing.'),
('P5DAT01-D01','D','trend_for_distribution','model_selection','P5-DAT-01','A line graph is mainly for ordered or time-based change; it is not the best summary of median and quartiles across groups.','Линейный график в основном используют для изменения по порядку или времени; он не является лучшим способом сравнить медиану и квартили групп.','Chiziqli grafik asosan tartib yoki vaqt bo‘yicha o‘zgarish uchun; guruhlar medianasi va kvartillarini solishtirish uchun eng yaxshi usul emas.','Identify the statistics that must be visible before choosing the display.','Сначала определите, какие статистики должны быть видны, затем выбирайте диаграмму.','Avval qaysi statistikalar ko‘rinishi kerakligini aniqlang, keyin diagrammani tanlang.'),
('P5DAT04-D01','B','frequency_as_height','method','P5-DAT-04','With unequal class widths, histogram height is frequency density, not raw frequency.','При неравных интервалах высота столбца гистограммы — это плотность частоты, а не сама частота.','Teng bo‘lmagan intervallarda gistogramma balandligi oddiy chastota emas, chastota zichligidir.','Use frequency density = frequency ÷ class width.','Используйте: плотность частоты = частота ÷ ширина интервала.','Chastota zichligi = chastota ÷ interval kengligi formulasidan foydalaning.'),
('P5DAT04-D01','C','inverted_density','method','P5-DAT-04','0.25 comes from dividing class width by frequency; the required ratio is frequency divided by class width.','0,25 получается при делении ширины интервала на частоту; требуется делить частоту на ширину интервала.','0.25 interval kengligini chastotaga bo‘lishdan chiqadi; kerakli nisbat chastotani interval kengligiga bo‘lishdir.','Write the density formula before substituting numbers.','Перед подстановкой чисел запишите формулу плотности частоты.','Sonlarni qo‘yishdan oldin chastota zichligi formulasini yozing.'),
('P5DAT04-D01','D','multiplied_density','method','P5-DAT-04','Multiplying frequency by class width gives 400, but histogram density requires division.','Умножение частоты на ширину даёт 400, но для плотности гистограммы требуется деление.','Chastotani interval kengligiga ko‘paytirish 400 beradi, ammo gistogramma zichligi uchun bo‘lish kerak.','Check the units: bar area, not height alone, represents frequency.','Проверьте смысл: частоту представляет площадь столбца, а не только его высота.','Ma’noni tekshiring: chastotani faqat balandlik emas, ustun yuzi ifodalaydi.'),
('P5DAT06-D01','B','median_mode_for_mean','concept','P5-DAT-06','2 is both the median and the mode here, but the question asks for the mean.','Здесь 2 является и медианой, и модой, но требуется среднее арифметическое.','Bu yerda 2 ham mediana, ham moda, lekin savol o‘rtacha arifmetikni so‘raydi.','Distinguish mean, median and mode before calculating.','Перед вычислением различайте среднее, медиану и моду.','Hisoblashdan oldin o‘rtacha, mediana va modani farqlang.'),
('P5DAT06-D01','C','sum_not_mean','method','P5-DAT-06','20 is the total of the values, not the mean; divide the total by the number of values.','20 — это сумма значений, а не среднее; сумму нужно разделить на количество значений.','20 qiymatlar yig‘indisi, o‘rtacha emas; yig‘indini qiymatlar soniga bo‘ling.','Use mean = total ÷ number of values.','Используйте: среднее = сумма ÷ количество значений.','O‘rtacha = yig‘indi ÷ qiymatlar soni formulasidan foydalaning.'),
('P5DAT06-D01','D','wrong_count','method','P5-DAT-06','5 results from dividing the total 20 by 4, but there are five data values.','5 получается при делении суммы 20 на 4, но в наборе пять значений.','5 soni 20 ni 4 ga bo‘lishdan chiqadi, lekin ma’lumotlarda beshta qiymat bor.','Count all observations before dividing the total.','Перед делением суммы пересчитайте все наблюдения.','Yig‘indini bo‘lishdan oldin barcha kuzatuvlar sonini sanang.')
), meta as (
select m.id,m.content_key from private.exam_prep_question_content_meta m join cv on cv.id=m.content_version_id where m.reserve_role='diagnostic'
)
insert into private.exam_prep_diagnostic_rules(content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status,approved_at)
select meta.id,'drv1','mcq_option',r.answer_match,r.dcode,r.mtype,r.weak,r.fen,r.fru,r.fuz,r.nen,r.nru,r.nuz,'approved',now()
from rules r join meta on meta.content_key=r.content_key
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

-- Three original written tasks/rubrics, one per opened skill.
with cv as (select id from private.exam_prep_content_versions where content_version='p5_repr_beta_v1')
insert into private.exam_prep_written_tasks(content_version_id,task_key,component_code,primary_skill_code,task_version,prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at)
select cv.id,v.task_key,'P5',v.skill,'wtv1',v.en,v.ru,v.uz,v.rubric::jsonb,v.sen,v.sru,v.suz,'approved','pass','pass','pass','pass',now()
from cv cross join (values
('P5DAT01-W01','P5-DAT-01',
'A school records travel times (minutes). Group A: 12, 14, 15, 15, 18, 20, 22, 24. Group B: 9, 12, 16, 17, 17, 19, 25, 31. (a) Choose a representation for comparing typical value and spread between the groups. (b) State two features you would compare. (c) Explain one limitation of using only the mean for this comparison.',
'Школа записала время в пути (мин). Группа A: 12, 14, 15, 15, 18, 20, 22, 24. Группа B: 9, 12, 16, 17, 17, 19, 25, 31. (a) Выберите представление для сравнения типичного значения и разброса групп. (b) Назовите две характеристики для сравнения. (c) Объясните одно ограничение сравнения только по среднему.',
'Maktab yo‘l vaqtlarini (daqiqada) qayd etdi. A guruh: 12, 14, 15, 15, 18, 20, 22, 24. B guruh: 9, 12, 16, 17, 17, 19, 25, 31. (a) Guruhlarning tipik qiymati va tarqalishini taqqoslash uchun tasvirlash usulini tanlang. (b) Taqqoslanadigan ikkita xususiyatni ayting. (c) Faqat o‘rtacha qiymatdan foydalanishning bitta cheklovini tushuntiring.',
'{"max_marks":6,"criteria":[{"id":"choice","marks":2,"rule":"Chooses an appropriate comparative distribution display, e.g. side-by-side box plots, with reason."},{"id":"features","marks":2,"rule":"Identifies two valid comparison features such as median/IQR/range/outliers."},{"id":"critique","marks":2,"rule":"Explains that mean alone can hide spread/skew/extreme-value effects."}]}',
'Check that your chosen display directly supports comparison, that you named two distribution features, and that your limitation explains what the mean can hide.',
'Проверьте: выбранная диаграмма действительно позволяет сравнивать группы; названы две характеристики распределения; объяснено, что может скрыть среднее.',
'Tekshiring: tanlangan diagramma guruhlarni bevosita taqqoslaydi; taqsimotning ikkita xususiyati aytilgan; o‘rtacha nimani yashirishi mumkinligi tushuntirilgan.'),
('P5DAT04-W01','P5-DAT-04',
'Waiting times are grouped as follows: 0 ≤ t < 5: frequency 10; 5 ≤ t < 15: frequency 30; 15 ≤ t < 20: frequency 20. Calculate the frequency density for each class, then draw a histogram with labelled axes. Explain why the raw frequencies cannot be used directly as the three bar heights.',
'Время ожидания сгруппировано так: 0 ≤ t < 5: частота 10; 5 ≤ t < 15: частота 30; 15 ≤ t < 20: частота 20. Вычислите плотность частоты каждого интервала, затем постройте гистограмму с подписями осей. Объясните, почему исходные частоты нельзя напрямую использовать как высоты трёх столбцов.',
'Kutish vaqtlari quyidagicha guruhlangan: 0 ≤ t < 5: chastota 10; 5 ≤ t < 15: chastota 30; 15 ≤ t < 20: chastota 20. Har bir interval uchun chastota zichligini hisoblang, so‘ng o‘qlari nomlangan gistogramma chizing. Nega oddiy chastotalarni uchta ustun balandligi sifatida bevosita ishlatib bo‘lmasligini tushuntiring.',
'{"max_marks":7,"criteria":[{"id":"densities","marks":3,"rule":"Correct densities 2,3,4."},{"id":"histogram","marks":3,"rule":"Contiguous unequal-width bars, correct horizontal intervals, vertical frequency-density scale/labels and correct heights."},{"id":"reason","marks":1,"rule":"Explains that bar area represents frequency, so unequal widths require density heights."}]}',
'Check all three class widths before calculating density; verify that bar areas, not raw heights, correspond to frequencies; label both axes.',
'Проверьте ширину каждого интервала перед вычислением плотности; убедитесь, что частоте соответствует площадь столбца; подпишите обе оси.',
'Zichlikni hisoblashdan oldin har uch interval kengligini tekshiring; chastotaga ustun yuzi mos kelishini tekshiring; ikkala o‘qni nomlang.'),
('P5DAT06-W01','P5-DAT-06',
'The values are 4, 5, 5, 6, 30. Calculate the mean, median and mode. Decide which measure gives the most representative typical value for this dataset and justify your choice using the data.',
'Даны значения 4, 5, 5, 6, 30. Вычислите среднее, медиану и моду. Решите, какая мера лучше всего представляет типичное значение этого набора, и обоснуйте выбор по данным.',
'Qiymatlar: 4, 5, 5, 6, 30. O‘rtacha, mediana va modani hisoblang. Ushbu to‘plam uchun qaysi o‘lchov tipik qiymatni eng yaxshi ifodalashini tanlang va ma’lumotlar asosida izohlang.',
'{"max_marks":6,"criteria":[{"id":"mean","marks":1,"rule":"Mean = 10."},{"id":"median","marks":1,"rule":"Median = 5."},{"id":"mode","marks":1,"rule":"Mode = 5."},{"id":"choice","marks":1,"rule":"Chooses median (or defensibly mode) as more representative than mean."},{"id":"justification","marks":2,"rule":"Links choice to the extreme value 30 pulling the mean upward and explains effect on typical-value interpretation."}]}',
'Check the total and divisor for the mean, locate the middle ordered value for the median, identify the most frequent value, then explain the effect of 30 on the mean.',
'Проверьте сумму и делитель для среднего, найдите центральное значение для медианы, определите самое частое значение и объясните влияние 30 на среднее.',
'O‘rtacha uchun yig‘indi va bo‘luvchini tekshiring, mediana uchun tartiblangan o‘rtadagi qiymatni toping, eng ko‘p uchraydigan qiymatni aniqlang va 30 ning o‘rtachaga ta’sirini tushuntiring.')
) v(task_key,skill,en,ru,uz,rubric,sen,sru,suz)
on conflict(content_version_id,task_key,task_version) do nothing;

-- Assessment definitions.
with cv as (select id from private.exam_prep_content_versions where content_version='p5_repr_beta_v1'), defs(k,t,en,ru,uz) as (values
('p5_repr_diagnostic','diagnostic','P5 Representation diagnostic','Диагностика P5: представление данных','P5: ma’lumotlarni tasvirlash diagnostikasi'),
('p5_dat01_learning','learning','Choosing data representations','Выбор представления данных','Ma’lumotlarni tasvirlash usulini tanlash'),
('p5_dat04_learning','learning','Histograms and frequency density','Гистограммы и плотность частоты','Gistogrammalar va chastota zichligi'),
('p5_dat06_learning','learning','Mean, median and mode','Среднее, медиана и мода','O‘rtacha, mediana va moda'),
('p5_dat01_retest','retest','Representation delayed retest','Отложенный ретест: представление данных','Tasvirlash bo‘yicha kechiktirilgan qayta test'),
('p5_dat04_retest','retest','Histogram delayed retest','Отложенный ретест: гистограммы','Gistogramma bo‘yicha kechiktirilgan qayta test'),
('p5_dat06_retest','retest','Averages delayed retest','Отложенный ретест: средние показатели','Markaziy ko‘rsatkichlar bo‘yicha kechiktirilgan qayta test'),
('p5_repr_mixed','mixed','P5 Representation mixed transfer','Смешанный перенос P5: представление данных','P5 aralash transfer: ma’lumotlarni tasvirlash'))
insert into private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz)
select cv.id,d.k,'av1','P5',d.t,'approved',d.en,d.ru,d.uz from cv cross join defs d
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

-- Question memberships. Learning includes the governed written task as a fourth item; second retest item per skill is holdout.
with cv as (select id from private.exam_prep_content_versions where content_version='p5_repr_beta_v1'),
a as (select id,assessment_key from private.exam_prep_assessments where content_version_id=(select id from cv)),
m as (select content_key,question_id,primary_skill_code from private.exam_prep_question_content_meta where content_version_id=(select id from cv)),
w as (select id,task_key,primary_skill_code from private.exam_prep_written_tasks where content_version_id=(select id from cv)),
items(akey,ord,ckey,wkey,skill,role,holdout) as (values
('p5_repr_diagnostic',1,'P5DAT01-D01',null,'P5-DAT-01','diagnostic',true),('p5_repr_diagnostic',2,'P5DAT04-D01',null,'P5-DAT-04','diagnostic',true),('p5_repr_diagnostic',3,'P5DAT06-D01',null,'P5-DAT-06','diagnostic',true),
('p5_dat01_learning',1,'P5DAT01-L01',null,'P5-DAT-01','learning',false),('p5_dat01_learning',2,'P5DAT01-L02',null,'P5-DAT-01','learning',false),('p5_dat01_learning',3,'P5DAT01-L03',null,'P5-DAT-01','learning',false),('p5_dat01_learning',4,null,'P5DAT01-W01','P5-DAT-01','written',false),
('p5_dat04_learning',1,'P5DAT04-L01',null,'P5-DAT-04','learning',false),('p5_dat04_learning',2,'P5DAT04-L02',null,'P5-DAT-04','learning',false),('p5_dat04_learning',3,'P5DAT04-L03',null,'P5-DAT-04','learning',false),('p5_dat04_learning',4,null,'P5DAT04-W01','P5-DAT-04','written',false),
('p5_dat06_learning',1,'P5DAT06-L01',null,'P5-DAT-06','learning',false),('p5_dat06_learning',2,'P5DAT06-L02',null,'P5-DAT-06','learning',false),('p5_dat06_learning',3,'P5DAT06-L03',null,'P5-DAT-06','learning',false),('p5_dat06_learning',4,null,'P5DAT06-W01','P5-DAT-06','written',false),
('p5_dat01_retest',1,'P5DAT01-R01',null,'P5-DAT-01','retest',false),('p5_dat01_retest',2,'P5DAT01-R02',null,'P5-DAT-01','retest',true),
('p5_dat04_retest',1,'P5DAT04-R01',null,'P5-DAT-04','retest',false),('p5_dat04_retest',2,'P5DAT04-R02',null,'P5-DAT-04','retest',true),
('p5_dat06_retest',1,'P5DAT06-R01',null,'P5-DAT-06','retest',false),('p5_dat06_retest',2,'P5DAT06-R02',null,'P5-DAT-06','retest',true),
('p5_repr_mixed',1,'P5MIX-M01',null,'P5-DAT-04','mixed',true),('p5_repr_mixed',2,'P5MIX-M02',null,'P5-DAT-06','mixed',true),('p5_repr_mixed',3,'P5MIX-M03',null,'P5-DAT-01','mixed',true)
)
insert into private.exam_prep_assessment_items(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout)
select a.id,i.ord,m.question_id,w.id,i.skill,i.role,i.holdout from items i join a on a.assessment_key=i.akey left join m on m.content_key=i.ckey left join w on w.task_key=i.wkey
on conflict(assessment_id,item_order) do nothing;

-- Hard structural floor before QA/publish.
do $$ declare v_bad int; begin
  select count(*) into v_bad from (select primary_skill_code,
    count(*) filter(where reserve_role='diagnostic') d,
    count(*) filter(where reserve_role='learning') l,
    count(*) filter(where reserve_role='retest') r
    from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    where cv.content_version='p5_repr_beta_v1' and m.primary_skill_code in ('P5-DAT-01','P5-DAT-04','P5-DAT-06') and m.reserve_role<>'mixed'
    group by primary_skill_code) x where d<>1 or l<>3 or r<>2;
  if v_bad<>0 then raise exception 'P0-08 per-skill reserve floor incomplete'; end if;
  if (select count(*) from private.exam_prep_written_tasks w join private.exam_prep_content_versions cv on cv.id=w.content_version_id where cv.content_version='p5_repr_beta_v1' and w.lifecycle_state='approved')<>3 then raise exception 'P0-08 written-task floor incomplete'; end if;
  if (select count(*) from private.exam_prep_diagnostic_rules r join private.exam_prep_question_content_meta m on m.id=r.content_meta_id join private.exam_prep_content_versions cv on cv.id=m.content_version_id where cv.content_version='p5_repr_beta_v1' and r.status='approved')<>9 then raise exception 'P0-08 diagnostic rules incomplete'; end if;
end $$;
commit;
