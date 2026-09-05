-- P1-03 pre-live depth: first governed Stage-3 full P5 paper.
-- 50 marks / 75 minutes through the published Cambridge 9709 P5 paper profile.
-- Written-only, original iClub-authored content. No public.questions / legacy mutation.
begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active'
)
insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,'p5_stage3_full_paper_01_v1','P5','P5 Stage-3 full paper 01','draft',
       'Original iClub-authored full-paper practice content. Cambridge 9709 2026-2027 official syllabus/profile defines scope, marks and timing only; no protected question wording copied.'
from pv
on conflict(program_version_id,content_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_stage3_full_paper_01_v1' and component_code='P5' and status='draft'
), defs(task_key,primary_skill,secondary_skills,prompt_en,prompt_ru,prompt_uz,rubric,self_en,self_ru,self_uz) as (values
(
  'P5FP01-Q01','P5-DAT-09',array['P5-DAT-06','P5-DAT-07','P5-DAT-08']::text[],
  'Two data sets A and B contain 20 and 30 observations respectively. For A, sum x=840 and sum x^2=35400. For B, sum x=1320 and sum x^2=58500. (a) Find the mean of each data set. (b) Find the mean and standard deviation of the combined 50 observations. (c) The median and interquartile range are 41 and 5 for A, and 45 and 8 for B. Compare the location and spread of the two data sets.',
  'Два набора данных A и B содержат соответственно 20 и 30 наблюдений. Для A: sum x=840 и sum x^2=35400. Для B: sum x=1320 и sum x^2=58500. (a) Найдите среднее каждого набора. (b) Найдите среднее и стандартное отклонение объединённых 50 наблюдений. (c) Медиана и межквартильный размах равны 41 и 5 для A, и 45 и 8 для B. Сравните положение и разброс двух наборов.',
  'A va B ma’lumot to‘plamlarida mos ravishda 20 va 30 ta kuzatuv bor. A uchun sum x=840 va sum x^2=35400. B uchun sum x=1320 va sum x^2=58500. (a) Har bir to‘plamning o‘rtacha qiymatini toping. (b) Birlashtirilgan 50 ta kuzatuvning o‘rtacha qiymati va standart og‘ishini toping. (c) A uchun median va interkvartil oralig‘i 41 va 5, B uchun 45 va 8. Ikki to‘plamning markaziy holati va tarqalishini taqqoslang.',
  '{"max_marks":7,"criteria":[{"id":"mean_a","marks":1,"rule":"Gets mean A=42."},{"id":"mean_b","marks":1,"rule":"Gets mean B=44."},{"id":"combined_mean","marks":1,"rule":"Gets combined mean 2160/50=43.2."},{"id":"combined_variance","marks":1,"rule":"Uses variance=93900/50-(43.2)^2=11.76."},{"id":"combined_sd","marks":1,"rule":"Gets standard deviation approximately 3.43."},{"id":"location_compare","marks":1,"rule":"States B has the higher central location because its median is higher."},{"id":"spread_compare","marks":1,"rule":"States B is more spread out because its IQR is larger, so A is more consistent by this measure."}]}'::jsonb,
  'For combined data, add both sums and both sums of squares before applying the population standard-deviation formula; compare location and spread with separate statements.',
  'Для объединённых данных сначала сложите суммы и суммы квадратов, затем примените формулу стандартного отклонения генеральной совокупности; положение и разброс сравнивайте отдельно.',
  'Birlashtirilgan ma’lumotlarda avval yig‘indilar va kvadratlar yig‘indilarini qo‘shing, so‘ng population standart og‘ish formulasini ishlating; markaz va tarqalishni alohida taqqoslang.'
),
(
  'P5FP01-Q02','P5-CNT-05',array['P5-CNT-04','P5-CNT-02']::text[],
  'A group contains 7 boys and 5 girls. A committee of 4 is selected. (a) Find the number of committees containing exactly 2 girls. (b) Find the number of committees containing at least 2 girls. (c) For committees containing exactly 2 girls, the four selected members are arranged in a row. Find the total number of selection-arrangements in which the two girls are adjacent.',
  'В группе 7 мальчиков и 5 девочек. Выбирают комитет из 4 человек. (a) Найдите число комитетов ровно с 2 девочками. (b) Найдите число комитетов как минимум с 2 девочками. (c) Для комитетов ровно с 2 девочками четырёх выбранных участников располагают в ряд. Найдите общее число вариантов выбора и расположения, в которых две девочки стоят рядом.',
  'Guruhda 7 o‘g‘il va 5 qiz bor. 4 kishilik qo‘mita tanlanadi. (a) Aynan 2 qiz bo‘lgan qo‘mitalar sonini toping. (b) Kamida 2 qiz bo‘lgan qo‘mitalar sonini toping. (c) Aynan 2 qizli qo‘mitalarda tanlangan to‘rt kishi qatorga joylashtiriladi. Ikki qiz yonma-yon turadigan tanlash-joylashtirishlar umumiy sonini toping.',
  '{"max_marks":7,"criteria":[{"id":"exact_two_setup","marks":1,"rule":"Uses C(5,2)C(7,2)."},{"id":"exact_two","marks":1,"rule":"Gets 210 committees."},{"id":"at_least_setup","marks":1,"rule":"Adds cases with 2, 3 and 4 girls."},{"id":"at_least","marks":1,"rule":"Gets 210+C(5,3)C(7,1)+C(5,4)=285."},{"id":"block_method","marks":1,"rule":"For a fixed exact-two committee treats the girls as one block with two boys."},{"id":"row_count","marks":1,"rule":"Gets 3! times 2!=12 row arrangements per selected committee."},{"id":"total_arrangements","marks":1,"rule":"Gets 210 times 12=2520 selection-arrangements."}]}'::jsonb,
  'Separate selection from arrangement: first count who is chosen, then apply a block method only after the committee composition is fixed.',
  'Отделяйте выбор от расположения: сначала посчитайте, кто выбран, и только затем применяйте метод блока к уже фиксированному составу.',
  'Tanlash va joylashtirishni ajrating: avval kim tanlanganini sanang, keyin tarkib aniqlangach blok usulini qo‘llang.'
),
(
  'P5FP01-Q03','P5-PRO-05',array['P5-PRO-02','P5-PRO-03','P5-PRO-06']::text[],
  'A bag contains 5 red, 4 blue and 3 green counters. Two counters are drawn at random without replacement. (a) Find the probability that the two counters have the same colour. (b) Find the probability that at least one counter is red. (c) Given that at least one counter is red, find the probability that both counters are red.',
  'В мешке 5 красных, 4 синих и 3 зелёных фишки. Наугад без возвращения извлекают две фишки. (a) Найдите вероятность, что фишки одного цвета. (b) Найдите вероятность, что хотя бы одна фишка красная. (c) При условии, что хотя бы одна фишка красная, найдите вероятность, что обе фишки красные.',
  'Xaltada 5 qizil, 4 ko‘k va 3 yashil jeton bor. Ikki jeton tasodifiy va qaytarmasdan olinadi. (a) Ikkala jeton bir xil rangda bo‘lish ehtimolini toping. (b) Kamida bitta jeton qizil bo‘lish ehtimolini toping. (c) Kamida bitta jeton qizil ekani ma’lum bo‘lsa, ikkala jeton qizil bo‘lish ehtimolini toping.',
  '{"max_marks":7,"criteria":[{"id":"same_colour_setup","marks":1,"rule":"Uses [C(5,2)+C(4,2)+C(3,2)]/C(12,2)."},{"id":"same_colour","marks":1,"rule":"Gets 19/66."},{"id":"red_complement","marks":1,"rule":"Uses 1-C(7,2)/C(12,2)."},{"id":"at_least_red","marks":1,"rule":"Gets 15/22."},{"id":"conditional_formula","marks":1,"rule":"Uses P(both red | at least one red)=P(both red)/P(at least one red)."},{"id":"both_red","marks":1,"rule":"Uses P(both red)=C(5,2)/C(12,2)=10/66."},{"id":"conditional_answer","marks":1,"rule":"Gets 2/9."}]}'::jsonb,
  'For without-replacement draws, combinations give a clean equiprobable sample space; conditional probability divides the intersection by the conditioning event.',
  'При выборе без возвращения удобно использовать сочетания для равновероятного пространства исходов; условная вероятность равна вероятности пересечения, делённой на вероятность условия.',
  'Qaytarmasdan tanlashda kombinatsiyalar teng ehtimolli natijalar fazosini qulay beradi; shartli ehtimol kesishma ehtimolini shart hodisasi ehtimoliga bo‘lish orqali topiladi.'
),
(
  'P5FP01-Q04','P5-DRV-03',array['P5-DRV-01','P5-DRV-02']::text[],
  'A discrete random variable X takes values 0, 1, 2 and 3 with probabilities k, 2k, 3k and 4k respectively. (a) Find k. (b) Find E(X). (c) Find Var(X). (d) Find P(X>=2) and the standard deviation of X.',
  'Дискретная случайная величина X принимает значения 0, 1, 2 и 3 с вероятностями k, 2k, 3k и 4k соответственно. (a) Найдите k. (b) Найдите E(X). (c) Найдите Var(X). (d) Найдите P(X>=2) и стандартное отклонение X.',
  'Diskret tasodifiy miqdor X 0, 1, 2 va 3 qiymatlarni mos ravishda k, 2k, 3k va 4k ehtimollar bilan qabul qiladi. (a) k ni toping. (b) E(X) ni toping. (c) Var(X) ni toping. (d) P(X>=2) va X ning standart og‘ishini toping.',
  '{"max_marks":7,"criteria":[{"id":"k","marks":1,"rule":"Uses 10k=1 and gets k=0.1."},{"id":"expectation_setup","marks":1,"rule":"Forms sum xP(X=x) correctly."},{"id":"expectation","marks":1,"rule":"Gets E(X)=2."},{"id":"second_moment","marks":1,"rule":"Gets E(X^2)=5."},{"id":"variance","marks":1,"rule":"Gets Var(X)=5-2^2=1."},{"id":"tail_probability","marks":1,"rule":"Gets P(X>=2)=0.3+0.4=0.7."},{"id":"sd","marks":1,"rule":"Gets standard deviation sqrt(1)=1."}]}'::jsonb,
  'Check that probabilities sum to one before calculating moments; variance is E(X^2)-[E(X)]^2, not simply E(X^2).',
  'Сначала проверьте, что вероятности суммируются к единице; дисперсия равна E(X^2)-[E(X)]^2, а не просто E(X^2).',
  'Avval ehtimollar yig‘indisi 1 ekanini tekshiring; dispersiya E(X^2)-[E(X)]^2 ga teng, faqat E(X^2) emas.'
),
(
  'P5FP01-Q05','P5-BIN-02',array['P5-BIN-01','P5-BIN-03']::text[],
  'Let X have the binomial distribution B(12,0.3). (a) Find P(X=4). (b) Find P(X>=2). (c) Find the mean and variance of X. Give probabilities to 3 significant figures.',
  'Пусть X имеет биномиальное распределение B(12,0.3). (a) Найдите P(X=4). (b) Найдите P(X>=2). (c) Найдите среднее и дисперсию X. Вероятности дайте до 3 значащих цифр.',
  'X B(12,0.3) binomial taqsimotga ega bo‘lsin. (a) P(X=4) ni toping. (b) P(X>=2) ni toping. (c) X ning o‘rtacha qiymati va dispersiyasini toping. Ehtimollarni 3 ta muhim raqamgacha bering.',
  '{"max_marks":7,"criteria":[{"id":"point_setup","marks":1,"rule":"Uses C(12,4)(0.3)^4(0.7)^8."},{"id":"point_answer","marks":1,"rule":"Gets P(X=4) approximately 0.231."},{"id":"tail_complement","marks":1,"rule":"Uses P(X>=2)=1-P(X=0)-P(X=1)."},{"id":"tail_terms","marks":1,"rule":"Uses (0.7)^12+12(0.3)(0.7)^11 for the excluded terms."},{"id":"tail_answer","marks":1,"rule":"Gets P(X>=2) approximately 0.915."},{"id":"mean","marks":1,"rule":"Gets E(X)=np=3.6."},{"id":"variance","marks":1,"rule":"Gets Var(X)=np(1-p)=2.52."}]}'::jsonb,
  'For an upper tail beginning at 2, the complement with X=0 and X=1 is shorter and less error-prone than summing eleven terms.',
  'Для верхнего хвоста начиная с 2 дополнение через X=0 и X=1 короче и надёжнее, чем суммирование множества членов.',
  '2 dan boshlanuvchi yuqori dum uchun X=0 va X=1 orqali complement ishlatish ko‘p hadni yig‘ishdan qisqaroq va ishonchliroq.'
),
(
  'P5FP01-Q06','P5-GEO-03',array['P5-GEO-01','P5-GEO-02','P5-PRO-04']::text[],
  'Independent trials are repeated until the first success, with success probability 0.2 on every trial. Let Y be the number of the trial on which the first success occurs. (a) State two features that justify a geometric model. (b) Find P(Y=4). (c) Find P(Y<=5). (d) Find E(Y). (e) Find P(Y>7 | Y>3).',
  'Независимые испытания повторяются до первого успеха, причём вероятность успеха в каждом испытании равна 0.2. Пусть Y — номер испытания, на котором впервые происходит успех. (a) Укажите два признака, обосновывающих геометрическую модель. (b) Найдите P(Y=4). (c) Найдите P(Y<=5). (d) Найдите E(Y). (e) Найдите P(Y>7 | Y>3).',
  'Mustaqil sinovlar birinchi muvaffaqiyatgacha takrorlanadi va har bir sinovda muvaffaqiyat ehtimoli 0.2. Y birinchi muvaffaqiyat sodir bo‘ladigan sinov raqami bo‘lsin. (a) Geometrik modelni asoslaydigan ikkita xususiyatni ayting. (b) P(Y=4) ni toping. (c) P(Y<=5) ni toping. (d) E(Y) ni toping. (e) P(Y>7 | Y>3) ni toping.',
  '{"max_marks":7,"criteria":[{"id":"assumptions","marks":2,"rule":"States independent repeated trials and constant success probability with Y measuring waiting time to first success."},{"id":"exact","marks":1,"rule":"Gets P(Y=4)=(0.8)^3(0.2)=0.1024."},{"id":"cumulative_setup","marks":1,"rule":"Uses P(Y<=5)=1-(0.8)^5."},{"id":"cumulative","marks":1,"rule":"Gets 0.67232."},{"id":"expectation","marks":1,"rule":"Gets E(Y)=1/0.2=5."},{"id":"conditional","marks":1,"rule":"Uses the memoryless structure or ratio of tails to get (0.8)^4=0.4096."}]}'::jsonb,
  'A geometric model counts failures before the first success through powers of 1-p; after conditioning on continued failure, the remaining waiting pattern is unchanged.',
  'Геометрическая модель описывает ожидание первого успеха степенями 1-p; после условия о продолжающихся неудачах структура оставшегося ожидания не меняется.',
  'Geometrik model birinchi muvaffaqiyatgacha kutishni 1-p darajalari bilan ifodalaydi; muvaffaqiyatsizlik davom etgani sharti ostida qolgan kutish tuzilishi o‘zgarmaydi.'
),
(
  'P5FP01-Q07','P5-NOR-06',array['P5-NOR-03','P5-NOR-04','P5-BIN-02','P5-BIN-03']::text[],
  'A continuous random variable X has distribution N(50,8^2). (a) Find P(42<X<62). (b) Find c such that P(X<c)=0.90. A second random variable Y has distribution B(100,0.5). (c) Using a normal approximation with continuity correction, estimate P(45<=Y<=60). Give final probabilities to 4 decimal places and c to 3 significant figures.',
  'Непрерывная случайная величина X имеет распределение N(50,8^2). (a) Найдите P(42<X<62). (b) Найдите c, если P(X<c)=0.90. Вторая случайная величина Y имеет распределение B(100,0.5). (c) Используя нормальное приближение с поправкой на непрерывность, оцените P(45<=Y<=60). Итоговые вероятности дайте до 4 знаков после запятой, c — до 3 значащих цифр.',
  'Uzluksiz tasodifiy miqdor X N(50,8^2) taqsimotga ega. (a) P(42<X<62) ni toping. (b) P(X<c)=0.90 bo‘lsa, c ni toping. Ikkinchi tasodifiy miqdor Y B(100,0.5) taqsimotga ega. (c) Uzluksizlik tuzatishi bilan normal yaqinlashuvdan foydalanib P(45<=Y<=60) ni baholang. Yakuniy ehtimollarni 4 ta kasr xonasigacha, c ni 3 ta muhim raqamgacha bering.',
  '{"max_marks":8,"criteria":[{"id":"interval_standardise","marks":1,"rule":"Standardises 42 and 62 to z=-1 and z=1.5."},{"id":"interval_tables","marks":1,"rule":"Uses Phi(1.5)-Phi(-1)."},{"id":"interval_answer","marks":1,"rule":"Gets P(42<X<62) approximately 0.7745."},{"id":"quantile_z","marks":1,"rule":"Uses z approximately 1.2816 for cumulative probability 0.90."},{"id":"quantile_c","marks":1,"rule":"Gets c=50+8(1.2816) approximately 60.3."},{"id":"approx_parameters","marks":1,"rule":"For Y uses normal mean 50 and standard deviation 5."},{"id":"continuity_correction","marks":1,"rule":"Uses boundaries 44.5 and 60.5, giving z=-1.1 and z=2.1."},{"id":"approx_answer","marks":1,"rule":"Gets approximate probability Phi(2.1)-Phi(-1.1)=0.8465."}]}'::jsonb,
  'Standardise normal variables carefully; for the binomial approximation, apply continuity correction to the integer endpoints before converting to z-scores.',
  'Тщательно стандартизируйте нормальные величины; при биномиальном приближении сначала примените поправку на непрерывность к целочисленным границам, затем переходите к z.',
  'Normal miqdorlarni ehtiyotkor standartlashtiring; binomial yaqinlashuvda avval butun son chegaralariga uzluksizlik tuzatishini qo‘llang, keyin z ga o‘ting.'
)
)
insert into private.exam_prep_written_tasks(
  content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
  prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
  lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select cv.id,d.task_key,'P5',d.primary_skill,d.secondary_skills,'wtv1',
       d.prompt_en,d.prompt_ru,d.prompt_uz,d.rubric,d.self_en,d.self_ru,d.self_uz,
       'published','pass','pass','pass','pass',now()
from cv cross join defs d
on conflict(content_version_id,task_key,task_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_stage3_full_paper_01_v1' and component_code='P5' and status='draft'
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
  title_en,title_ru,title_uz,approved_at
)
select cv.id,'p5_stage3_full_paper_01','av1','P5','paper','approved',
       'P5 Stage 3 full paper 01','P5 Stage 3: full paper 01','P5 Stage 3 full paper 01',now()
from cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions where content_version='p5_stage3_full_paper_01_v1'
), a as (
  select a.id from private.exam_prep_assessments a join cv on cv.id=a.content_version_id
  where a.assessment_key='p5_stage3_full_paper_01' and a.assessment_version='av1'
), items(item_order,task_key,skill) as (values
  (1,'P5FP01-Q01','P5-DAT-09'),
  (2,'P5FP01-Q02','P5-CNT-05'),
  (3,'P5FP01-Q03','P5-PRO-05'),
  (4,'P5FP01-Q04','P5-DRV-03'),
  (5,'P5FP01-Q05','P5-BIN-02'),
  (6,'P5FP01-Q06','P5-GEO-03'),
  (7,'P5FP01-Q07','P5-NOR-06')
), wt as (
  select w.id,w.task_key from private.exam_prep_written_tasks w join cv on cv.id=w.content_version_id
)
insert into private.exam_prep_assessment_items(
  assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select a.id,i.item_order,null,wt.id,i.skill,'written',true
from items i cross join a join wt on wt.task_key=i.task_key
on conflict(assessment_id,item_order) do nothing;

with a as (
  select id from private.exam_prep_assessments
  where assessment_key='p5_stage3_full_paper_01' and assessment_version='av1'
), marks(item_order,max_marks) as (values
  (1::smallint,7::smallint),(2::smallint,7::smallint),(3::smallint,7::smallint),(4::smallint,7::smallint),
  (5::smallint,7::smallint),(6::smallint,7::smallint),(7::smallint,8::smallint)
)
insert into private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks)
select a.id,m.item_order,m.max_marks from a cross join marks m
on conflict(assessment_id,item_order) do nothing;

update private.exam_prep_content_versions
set status='published',approved_at=coalesce(approved_at,now()),published_at=coalesce(published_at,now())
where content_version='p5_stage3_full_paper_01_v1' and status='draft';

update private.exam_prep_assessments
set status='published',approved_at=coalesce(approved_at,now())
where assessment_key='p5_stage3_full_paper_01' and assessment_version='av1' and status='approved';

with a as (
  select a.id,a.component_code from private.exam_prep_assessments a
  where a.assessment_key='p5_stage3_full_paper_01' and a.assessment_version='av1' and a.status='published'
), p as (
  select id,component_code from private.exam_prep_component_paper_profiles
  where component_code='P5' and profile_version='9709_2026_2027_v1' and status='published'
)
insert into private.exam_prep_timed_assessment_contracts(
  assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
  strict_timing,comparison_scope,comparability_key,status,published_at
)
select a.id,p.id,'tcv1','full_paper','official_full',50,null,true,'full','p5-full-paper-01-v1','published',now()
from a join p using(component_code)
on conflict(assessment_id) do nothing;

-- Acceptance: official full-paper contract, all five P5 syllabus sections, written-only governance and fail-closed beta state.
do $$
declare
  v_ass bigint;
  v_tasks int;
  v_items int;
  v_marks int;
  v_rubric_marks int;
  v_sections int;
  v_contract private.exam_prep_timed_assessment_contracts%rowtype;
  v_time int;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  select id into v_ass from private.exam_prep_assessments
  where assessment_key='p5_stage3_full_paper_01' and assessment_version='av1' and status='published';
  if v_ass is null then raise exception 'P1-03 P5 full paper assessment missing'; end if;

  select count(*) into v_tasks
  from private.exam_prep_assessment_items ai
  join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
  where ai.assessment_id=v_ass and ai.question_id is null and ai.reserve_role='written'
    and wt.lifecycle_state='published' and wt.copyright_status='pass'
    and wt.qa_math_status='pass' and wt.qa_language_status='pass' and wt.qa_technical_status='pass';
  if v_tasks<>7 then raise exception 'P1-03 P5 full paper written floor tasks=%',v_tasks; end if;

  select count(*),coalesce(sum(max_marks),0) into v_items,v_marks
  from private.exam_prep_timed_assessment_items where assessment_id=v_ass;
  if v_items<>7 or v_marks<>50 then raise exception 'P1-03 P5 full paper marks items=% marks=%',v_items,v_marks; end if;

  select coalesce(sum((wt.rubric_json->>'max_marks')::int),0) into v_rubric_marks
  from private.exam_prep_assessment_items ai join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
  where ai.assessment_id=v_ass;
  if v_rubric_marks<>50 then raise exception 'P1-03 P5 full paper rubric marks=%',v_rubric_marks; end if;

  select count(distinct sn.official_syllabus_section) into v_sections
  from private.exam_prep_assessment_items ai
  join private.exam_prep_syllabus_nodes sn on sn.program_version_id=1 and sn.skill_code=ai.primary_skill_code and sn.component_code='P5'
  where ai.assessment_id=v_ass;
  if v_sections<>5 then raise exception 'P1-03 P5 full paper syllabus breadth sections=%',v_sections; end if;

  select * into v_contract from private.exam_prep_timed_assessment_contracts where assessment_id=v_ass and status='published';
  if v_contract.assessment_id is null or v_contract.attempt_kind<>'full_paper' or v_contract.timing_rule<>'official_full'
     or v_contract.comparison_scope<>'full' or v_contract.marks_available<>50 or v_contract.fixed_time_limit_sec is not null
     or not v_contract.strict_timing then raise exception 'P1-03 P5 full paper contract invalid'; end if;
  if private.exam_prep_timed_min_stage_v1(v_contract.attempt_kind)<>3 then raise exception 'P1-03 P5 full paper stage drift'; end if;
  v_time:=private.exam_prep_timed_time_limit_v1(v_contract.paper_profile_id,v_contract.timing_rule,v_contract.marks_available,v_contract.fixed_time_limit_sec);
  if v_time<>4500 then raise exception 'P1-03 P5 full paper timing drift seconds=%',v_time; end if;

  if exists(select 1 from public.questions q where q.book_ref like 'ExamPrep:%p5_stage3_full_paper_01%') then
    raise exception 'P1-03 P5 full paper must not create public.questions rows';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 P5 full paper publication requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 P5 full paper active entitlement residue=%',v_active; end if;
  if exists(select 1 from private.exam_prep_sessions) or exists(select 1 from private.exam_prep_evidence_events) or exists(select 1 from private.exam_prep_timed_attempt_results) then
    raise exception 'P1-03 P5 full paper publication must not create learner runtime evidence';
  end if;
end $$;

commit;