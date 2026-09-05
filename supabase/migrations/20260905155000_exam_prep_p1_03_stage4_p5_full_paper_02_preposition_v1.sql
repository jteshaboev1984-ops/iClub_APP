-- P1-03 pre-live depth: pre-position second governed P5 full-paper form for later Stage-4 release.
-- 50 marks / 75 minutes under the existing Cambridge 9709 P5 profile once released.
-- Content/tasks are governed now; assessment remains approved and has NO published timed contract.
-- Written-only, original iClub-authored content. No public.questions / legacy mutation.
begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active'
)
insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,'p5_stage4_full_paper_02_v1','P5','P5 Stage-4 full paper 02 pre-position','draft',
       'Original iClub-authored full-paper practice content. Cambridge 9709 2026-2027 official syllabus/profile defines scope, marks and timing only; no protected question wording copied. Assessment intentionally remains approved/not published until a later Stage-4 release.'
from pv
on conflict(program_version_id,content_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_stage4_full_paper_02_v1' and component_code='P5' and status='draft'
), defs(task_key,primary_skill,secondary_skills,prompt_en,prompt_ru,prompt_uz,rubric,self_en,self_ru,self_uz) as (values
(
  'P5FP02-Q01','P5-DAT-10',array['P5-DAT-09','P5-DAT-08']::text[],
  'For 40 observations of x, the coded variable y=(x-50)/5 satisfies sum y=24 and sum y^2=136. (a) Find the mean and standard deviation of x. Ten further observations, each equal to 60, are added. (b) Find the mean and standard deviation of the combined 50 observations. Give standard deviations to 3 significant figures.',
  'Для 40 наблюдений x введена кодированная величина y=(x-50)/5, причём sum y=24 и sum y^2=136. (a) Найдите среднее и стандартное отклонение x. Затем добавляют ещё 10 наблюдений, каждое равно 60. (b) Найдите среднее и стандартное отклонение объединённых 50 наблюдений. Стандартные отклонения дайте до 3 значащих цифр.',
  'x ning 40 ta kuzatuvi uchun y=(x-50)/5 kodlangan o‘zgaruvchi bo‘lib, sum y=24 va sum y^2=136. (a) x ning o‘rtacha qiymati va standart og‘ishini toping. Keyin har biri 60 ga teng 10 ta kuzatuv qo‘shiladi. (b) Birlashtirilgan 50 ta kuzatuvning o‘rtacha qiymati va standart og‘ishini toping. Standart og‘ishlarni 3 ta muhim raqamgacha bering.',
  '{"max_marks":7,"criteria":[{"id":"coded_mean","marks":1,"rule":"Gets mean y=24/40=0.6 and hence mean x=53."},{"id":"coded_variance","marks":1,"rule":"Gets Var(y)=136/40-(0.6)^2=3.04."},{"id":"coded_sd","marks":1,"rule":"Gets sd(x)=5sqrt(3.04) approximately 8.72."},{"id":"original_totals","marks":1,"rule":"Uses sum x=2120 and sum x^2=115400 from the coding."},{"id":"combined_mean","marks":1,"rule":"Gets combined mean (2120+600)/50=54.4."},{"id":"combined_variance","marks":1,"rule":"Uses combined sum x^2=151400 and variance=151400/50-(54.4)^2=68.64."},{"id":"combined_sd","marks":1,"rule":"Gets combined standard deviation approximately 8.28."}]}'::jsonb,
  'Decode both first and second moments carefully: standard deviation scales by the absolute coding factor, while combined data require recomputing the overall totals.',
  'Аккуратно восстановите первый и второй моменты: стандартное отклонение масштабируется по модулю коэффициента кодирования, а для объединённых данных нужно пересчитать общие суммы.',
  'Birinchi va ikkinchi momentlarni kodlashdan ehtiyotkorlik bilan qaytaring: standart og‘ish kodlash koeffitsienti moduliga ko‘payadi, birlashtirilgan ma’lumotlarda esa umumiy yig‘indilar qayta hisoblanadi.'
),
(
  'P5FP02-Q02','P5-CNT-04',array['P5-CNT-03','P5-CNT-02']::text[],
  'Consider all distinct arrangements of the letters in BALLOON. (a) Find the total number of arrangements. (b) Find the number in which the two O letters are adjacent. (c) Find the number in which the two L letters are not adjacent.',
  'Рассмотрите все различные перестановки букв слова BALLOON. (a) Найдите общее число перестановок. (b) Найдите число перестановок, в которых две буквы O стоят рядом. (c) Найдите число перестановок, в которых две буквы L не стоят рядом.',
  'BALLOON so‘zidagi harflarning barcha turli joylashuvlarini ko‘ring. (a) Umumiy joylashuvlar sonini toping. (b) Ikki O harfi yonma-yon turgan joylashuvlar sonini toping. (c) Ikki L harfi yonma-yon bo‘lmagan joylashuvlar sonini toping.',
  '{"max_marks":7,"criteria":[{"id":"total_setup","marks":1,"rule":"Uses 7!/(2!2!) because L and O are repeated."},{"id":"total","marks":1,"rule":"Gets 1260."},{"id":"o_block_setup","marks":1,"rule":"Treats OO as one block, leaving six objects with two identical Ls."},{"id":"o_block","marks":1,"rule":"Gets 6!/2!=360."},{"id":"l_block_setup","marks":1,"rule":"Counts arrangements with LL adjacent as 6!/2! because the O letters remain identical."},{"id":"l_block","marks":1,"rule":"Gets 360 arrangements with LL adjacent."},{"id":"l_apart","marks":1,"rule":"Gets 1260-360=900 arrangements with Ls not adjacent."}]}'::jsonb,
  'Account for identical letters before applying a block restriction; for “not adjacent”, a complement is usually cleaner than direct placement.',
  'Сначала учитывайте одинаковые буквы, затем применяйте метод блока; для условия «не рядом» обычно проще использовать дополнение.',
  'Avval bir xil harflarni hisobga oling, keyin blok usulini qo‘llang; “yonma-yon emas” sharti uchun komplement odatda qulayroq.'
),
(
  'P5FP02-Q03','P5-PRO-06',array['P5-PRO-05','P5-PRO-03']::text[],
  'A box contains 4 white, 3 black and 2 red counters. Two counters are drawn at random without replacement. (a) Find the probability that the counters have different colours. (b) Find P(second counter is black). (c) Given that the second counter is black, find the probability that the first counter was white.',
  'В коробке 4 белых, 3 чёрных и 2 красных фишки. Наугад без возвращения извлекают две фишки. (a) Найдите вероятность того, что фишки разных цветов. (b) Найдите P(вторая фишка чёрная). (c) При условии, что вторая фишка чёрная, найдите вероятность того, что первая была белой.',
  'Qutida 4 oq, 3 qora va 2 qizil jeton bor. Ikki jeton tasodifiy va qaytarmasdan olinadi. (a) Jetonlar turli rangda bo‘lish ehtimolini toping. (b) Ikkinchi jeton qora bo‘lish ehtimolini toping. (c) Ikkinchi jeton qora ekani ma’lum bo‘lsa, birinchi jeton oq bo‘lgan ehtimolni toping.',
  '{"max_marks":7,"criteria":[{"id":"tree_structure","marks":1,"rule":"Uses without-replacement branch probabilities with denominator 9 then 8."},{"id":"same_colour","marks":1,"rule":"Gets P(same colour)=[C(4,2)+C(3,2)+C(2,2)]/C(9,2)=5/18 or equivalent tree sum."},{"id":"different","marks":1,"rule":"Gets P(different colours)=13/18."},{"id":"second_black","marks":1,"rule":"Gets P(second black)=1/3, by tree sum or symmetry."},{"id":"joint","marks":1,"rule":"Gets P(first white and second black)=(4/9)(3/8)=1/6."},{"id":"conditional_setup","marks":1,"rule":"Uses P(W first | B second)=P(W first and B second)/P(B second)."},{"id":"conditional","marks":1,"rule":"Gets 1/2."}]}'::jsonb,
  'For sequential draws without replacement, update the denominator and colour counts after the first draw; conditional probability uses the correct joint branch over the conditioning probability.',
  'При последовательном выборе без возвращения после первого выбора меняйте знаменатель и числа цветов; условная вероятность использует нужную совместную ветвь, делённую на вероятность условия.',
  'Qaytarmasdan ketma-ket tanlashda birinchi tanlovdan keyin maxraj va rang sonlarini yangilang; shartli ehtimolda tegishli qo‘shma tarmoq ehtimolini shart hodisasi ehtimoliga bo‘ling.'
),
(
  'P5FP02-Q04','P5-DRV-02',array['P5-DRV-01','P5-DRV-03']::text[],
  'A discrete random variable X takes values 0,1,2,3 with probabilities a,2a,3a,1-6a respectively. It is known that E(X)=1.8. (a) Find a and hence write the complete distribution. (b) Find P(X>=2). (c) Find Var(X) and the standard deviation of X.',
  'Дискретная случайная величина X принимает значения 0,1,2,3 с вероятностями a,2a,3a,1-6a соответственно. Известно, что E(X)=1.8. (a) Найдите a и запишите полное распределение. (b) Найдите P(X>=2). (c) Найдите Var(X) и стандартное отклонение X.',
  'Diskret tasodifiy miqdor X 0,1,2,3 qiymatlarni mos ravishda a,2a,3a,1-6a ehtimollar bilan qabul qiladi. E(X)=1.8 ekanligi ma’lum. (a) a ni toping va to‘liq taqsimotni yozing. (b) P(X>=2) ni toping. (c) Var(X) va X ning standart og‘ishini toping.',
  '{"max_marks":7,"criteria":[{"id":"expectation_equation","marks":1,"rule":"Forms 2a+6a+3(1-6a)=1.8."},{"id":"a_value","marks":1,"rule":"Gets a=0.12 and hence probabilities 0.12,0.24,0.36,0.28."},{"id":"tail","marks":1,"rule":"Gets P(X>=2)=0.36+0.28=0.64."},{"id":"second_moment_setup","marks":1,"rule":"Forms E(X^2)=0.24+4(0.36)+9(0.28)."},{"id":"second_moment","marks":1,"rule":"Gets E(X^2)=4.2."},{"id":"variance","marks":1,"rule":"Gets Var(X)=4.2-(1.8)^2=0.96."},{"id":"sd","marks":1,"rule":"Gets standard deviation sqrt(0.96) approximately 0.980."}]}'::jsonb,
  'Use the given expectation to determine the parameter, then keep E(X^2) separate from [E(X)]^2 when calculating variance.',
  'Используйте заданное математическое ожидание для нахождения параметра, затем не смешивайте E(X^2) и [E(X)]^2 при вычислении дисперсии.',
  'Berilgan matematik kutilmadan parametrni toping, keyin dispersiyada E(X^2) va [E(X)]^2 ni alohida hisoblang.'
),
(
  'P5FP02-Q05','P5-BIN-03',array['P5-BIN-01']::text[],
  'Let X~B(n,0.2) and E(X)=4. (a) Find n and Var(X). A second variable Y~B(50,p) has Var(Y)=8 and E(Y)>25. (b) Find all algebraic possibilities for p from the variance condition, then use the mean condition to determine p. (c) State E(Y).',
  'Пусть X~B(n,0.2) и E(X)=4. (a) Найдите n и Var(X). Вторая величина Y~B(50,p) имеет Var(Y)=8 и E(Y)>25. (b) Найдите все алгебраические значения p из условия на дисперсию, затем используйте условие на среднее для выбора p. (c) Укажите E(Y).',
  'X~B(n,0.2) va E(X)=4 bo‘lsin. (a) n va Var(X) ni toping. Ikkinchi Y~B(50,p) miqdor uchun Var(Y)=8 va E(Y)>25. (b) Dispersiya shartidan p ning barcha algebraik imkoniyatlarini toping, so‘ng o‘rtacha qiymat shartidan p ni aniqlang. (c) E(Y) ni ayting.',
  '{"max_marks":7,"criteria":[{"id":"n","marks":1,"rule":"Uses np=4 to get n=20."},{"id":"var_x","marks":1,"rule":"Gets Var(X)=20(0.2)(0.8)=3.2."},{"id":"var_y_equation","marks":1,"rule":"Forms 50p(1-p)=8, so p(1-p)=0.16."},{"id":"quadratic","marks":1,"rule":"Obtains p^2-p+0.16=0."},{"id":"p_candidates","marks":1,"rule":"Gets p=0.2 or p=0.8."},{"id":"select_p","marks":1,"rule":"Uses E(Y)=50p>25 to select p=0.8."},{"id":"mean_y","marks":1,"rule":"Gets E(Y)=40."}]}'::jsonb,
  'Inverse binomial parameter problems often produce two algebraic p values from variance; use any extra mean/context condition before choosing the model parameter.',
  'В обратной биномиальной задаче условие на дисперсию часто даёт два алгебраических значения p; используйте дополнительное условие на среднее или контекст до выбора параметра.',
  'Teskari binomial parametr masalasida dispersiya sharti ko‘pincha p uchun ikki algebraik qiymat beradi; parametrni tanlashdan oldin o‘rtacha qiymat yoki kontekst shartidan foydalaning.'
),
(
  'P5FP02-Q06','P5-GEO-02',array['P5-GEO-01','P5-GEO-03']::text[],
  'X is the trial number of the first success in independent trials with success probability 0.25. (a) Find P(X=4). (b) Find P(X>5). (c) Find P(3<=X<=6). (d) Find P(X>8 | X>5). Give exact expressions and decimal values to 4 decimal places where appropriate.',
  'X — номер испытания, на котором впервые происходит успех, в независимых испытаниях с вероятностью успеха 0.25. (a) Найдите P(X=4). (b) Найдите P(X>5). (c) Найдите P(3<=X<=6). (d) Найдите P(X>8 | X>5). При необходимости дайте точные выражения и десятичные значения до 4 знаков.',
  'X — mustaqil sinovlarda muvaffaqiyat ehtimoli 0.25 bo‘lganda birinchi muvaffaqiyat sodir bo‘ladigan sinov raqami. (a) P(X=4) ni toping. (b) P(X>5) ni toping. (c) P(3<=X<=6) ni toping. (d) P(X>8 | X>5) ni toping. Kerak joylarda aniq ifoda va 4 ta kasr xonasigacha qiymat bering.',
  '{"max_marks":7,"criteria":[{"id":"point_setup","marks":1,"rule":"Uses (0.75)^3(0.25)."},{"id":"point","marks":1,"rule":"Gets P(X=4)=0.10546875 approximately 0.1055."},{"id":"greater_five","marks":1,"rule":"Gets P(X>5)=(0.75)^5 approximately 0.2373."},{"id":"interval_setup","marks":1,"rule":"Uses P(X>=3)-P(X>=7)=(0.75)^2-(0.75)^6."},{"id":"interval","marks":1,"rule":"Gets approximately 0.3845."},{"id":"conditional_setup","marks":1,"rule":"Uses the memoryless/conditional ratio to reduce the extra wait to three further failures."},{"id":"conditional","marks":1,"rule":"Gets P(X>8|X>5)=(0.75)^3=0.421875 approximately 0.4219."}]}'::jsonb,
  'For a geometric waiting-time model, X>k means the first k trials are failures; conditional waiting beyond an already-failed prefix is memoryless.',
  'Для геометрического ожидания событие X>k означает неудачу в первых k испытаниях; после уже известной серии неудач дальнейшее ожидание сохраняет ту же структуру.',
  'Geometrik kutish modelida X>k birinchi k sinov muvaffaqiyatsizligini anglatadi; ma’lum muvaffaqiyatsiz prefiksdan keyin qolgan kutish xotirasiz xususiyatga ega.'
),
(
  'P5FP02-Q07','P5-NOR-05',array['P5-NOR-02','P5-NOR-03','P5-NOR-04']::text[],
  'A continuous random variable X has distribution N(mu,sigma^2). It is known that P(X<70)=0.90 and P(X<50)=0.10. (a) Find mu and sigma. (b) Hence find P(55<X<65). Give sigma to 3 significant figures and the final probability to 4 decimal places.',
  'Непрерывная случайная величина X имеет распределение N(mu,sigma^2). Известно, что P(X<70)=0.90 и P(X<50)=0.10. (a) Найдите mu и sigma. (b) Затем найдите P(55<X<65). Дайте sigma до 3 значащих цифр, итоговую вероятность — до 4 знаков после запятой.',
  'Uzluksiz tasodifiy miqdor X N(mu,sigma^2) taqsimotga ega. P(X<70)=0.90 va P(X<50)=0.10 ekanligi ma’lum. (a) mu va sigma ni toping. (b) So‘ng P(55<X<65) ni toping. sigma ni 3 ta muhim raqamgacha, yakuniy ehtimolni 4 ta kasr xonasigacha bering.',
  '{"max_marks":8,"criteria":[{"id":"z_values","marks":1,"rule":"Uses z_0.90 approximately 1.2816 and z_0.10 approximately -1.2816."},{"id":"equations","marks":1,"rule":"Forms (70-mu)/sigma=1.2816 and (50-mu)/sigma=-1.2816."},{"id":"mu","marks":1,"rule":"Uses symmetry/subtraction to get mu=60."},{"id":"sigma","marks":1,"rule":"Gets sigma=10/1.2816 approximately 7.80."},{"id":"interval_standardise","marks":1,"rule":"Standardises 55 and 65 to approximately -0.6408 and 0.6408."},{"id":"interval_symmetry","marks":1,"rule":"Uses Phi(0.6408)-Phi(-0.6408), or 2Phi(0.6408)-1."},{"id":"cdf_value","marks":1,"rule":"Uses Phi(0.6408) approximately 0.7392."},{"id":"probability","marks":1,"rule":"Gets P(55<X<65) approximately 0.4783."}]}'::jsonb,
  'Use paired inverse-normal conditions to form two linear equations in mu and sigma; exploit symmetry only after matching the correct z signs.',
  'Используйте два условия обратного нормального распределения для составления двух линейных уравнений относительно mu и sigma; симметрию применяйте после правильного выбора знаков z.',
  'Ikki inverse-normal shartdan mu va sigma bo‘yicha ikkita chiziqli tenglama tuzing; z ishoralarini to‘g‘ri tanlagandan keyingina simmetriyadan foydalaning.'
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
  where content_version='p5_stage4_full_paper_02_v1' and component_code='P5' and status='draft'
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
  title_en,title_ru,title_uz,approved_at
)
select cv.id,'p5_stage4_full_paper_02','av1','P5','paper','approved',
       'P5 Stage 4 full paper 02 (pre-positioned)','P5 Stage 4: full paper 02 (pre-positioned)','P5 Stage 4 full paper 02 (pre-positioned)',now()
from cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions where content_version='p5_stage4_full_paper_02_v1'
), a as (
  select a.id from private.exam_prep_assessments a join cv on cv.id=a.content_version_id
  where a.assessment_key='p5_stage4_full_paper_02' and a.assessment_version='av1'
), items(item_order,task_key,skill) as (values
  (1,'P5FP02-Q01','P5-DAT-10'),
  (2,'P5FP02-Q02','P5-CNT-04'),
  (3,'P5FP02-Q03','P5-PRO-06'),
  (4,'P5FP02-Q04','P5-DRV-02'),
  (5,'P5FP02-Q05','P5-BIN-03'),
  (6,'P5FP02-Q06','P5-GEO-02'),
  (7,'P5FP02-Q07','P5-NOR-05')
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
  where assessment_key='p5_stage4_full_paper_02' and assessment_version='av1'
), marks(item_order,max_marks) as (values
  (1::smallint,7::smallint),(2::smallint,7::smallint),(3::smallint,7::smallint),(4::smallint,7::smallint),
  (5::smallint,7::smallint),(6::smallint,7::smallint),(7::smallint,8::smallint)
)
insert into private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks)
select a.id,m.item_order,m.max_marks from a cross join marks m
on conflict(assessment_id,item_order) do nothing;

update private.exam_prep_content_versions
set status='published',approved_at=coalesce(approved_at,now()),published_at=coalesce(published_at,now())
where content_version='p5_stage4_full_paper_02_v1' and status='draft';

-- Acceptance: complete 50-mark form is pre-positioned, covers all P5 sections, and remains invisible to timed catalog.
do $$
declare
  v_ass bigint;
  v_tasks int;
  v_items int;
  v_marks int;
  v_rubric_marks int;
  v_sections int;
  v_profile bigint;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  select id into v_ass from private.exam_prep_assessments
  where assessment_key='p5_stage4_full_paper_02' and assessment_version='av1' and status='approved';
  if v_ass is null then raise exception 'P1-03 P5 Paper02 approved assessment missing'; end if;

  select count(*) into v_tasks
  from private.exam_prep_assessment_items ai
  join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
  where ai.assessment_id=v_ass and ai.question_id is null and ai.reserve_role='written'
    and wt.lifecycle_state='published' and wt.copyright_status='pass'
    and wt.qa_math_status='pass' and wt.qa_language_status='pass' and wt.qa_technical_status='pass';
  if v_tasks<>7 then raise exception 'P1-03 P5 Paper02 written floor tasks=%',v_tasks; end if;

  select count(*),coalesce(sum(max_marks),0) into v_items,v_marks
  from private.exam_prep_timed_assessment_items where assessment_id=v_ass;
  if v_items<>7 or v_marks<>50 then raise exception 'P1-03 P5 Paper02 marks items=% marks=%',v_items,v_marks; end if;

  select coalesce(sum((wt.rubric_json->>'max_marks')::int),0) into v_rubric_marks
  from private.exam_prep_assessment_items ai join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
  where ai.assessment_id=v_ass;
  if v_rubric_marks<>50 then raise exception 'P1-03 P5 Paper02 rubric marks=%',v_rubric_marks; end if;

  select count(distinct sn.official_syllabus_section) into v_sections
  from private.exam_prep_assessment_items ai
  join private.exam_prep_syllabus_nodes sn on sn.skill_code=ai.primary_skill_code and sn.component_code='P5'
  join private.exam_prep_content_versions cv on cv.id=(select content_version_id from private.exam_prep_assessments where id=v_ass)
  where ai.assessment_id=v_ass and sn.program_version_id=cv.program_version_id;
  if v_sections<>5 then raise exception 'P1-03 P5 Paper02 syllabus breadth sections=%',v_sections; end if;

  select id into v_profile from private.exam_prep_component_paper_profiles
  where component_code='P5' and profile_version='9709_2026_2027_v1' and status='published';
  if v_profile is null or private.exam_prep_timed_time_limit_v1(v_profile,'official_full',50,null)<>4500 then
    raise exception 'P1-03 P5 Paper02 official profile/timing missing';
  end if;

  if exists(select 1 from private.exam_prep_timed_assessment_contracts where assessment_id=v_ass) then
    raise exception 'P1-03 P5 Paper02 must remain unreleased: timed contract exists';
  end if;
  if exists(select 1 from private.exam_prep_assessments where id=v_ass and status='published') then
    raise exception 'P1-03 P5 Paper02 must remain approved/not published';
  end if;
  if exists(select 1 from public.questions q where q.book_ref like 'ExamPrep:%p5_stage4_full_paper_02%') then
    raise exception 'P1-03 P5 Paper02 must not create public.questions rows';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 P5 Paper02 pre-position requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 P5 Paper02 active entitlement residue=%',v_active; end if;
  if exists(select 1 from private.exam_prep_sessions) or exists(select 1 from private.exam_prep_evidence_events) or exists(select 1 from private.exam_prep_timed_attempt_results) then
    raise exception 'P1-03 P5 Paper02 pre-position must not create learner runtime evidence';
  end if;
end $$;

commit;
