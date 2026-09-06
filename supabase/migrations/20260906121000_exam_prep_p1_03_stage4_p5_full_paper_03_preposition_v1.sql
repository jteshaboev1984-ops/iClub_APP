-- P1-03 pre-live depth: pre-position third governed P5 full-paper form for later Stage-4/5 evidence depth.
-- 50 marks / 75 minutes under the existing Cambridge 9709 P5 profile once released.
-- Assessment remains approved and has NO timed contract. No learner access or legacy activation.
begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active'
)
insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,'p5_stage4_full_paper_03_v1','P5','P5 Stage-4 full paper 03 pre-position','draft',
       'Original iClub-authored full-paper practice content. Cambridge 9709 2026-2027 official syllabus/profile defines scope, marks and timing only; no protected question wording copied. Assessment intentionally remains approved/not published until a later governed release.'
from pv
on conflict(program_version_id,content_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_stage4_full_paper_03_v1' and component_code='P5' and status='draft'
), defs(task_key,primary_skill,secondary_skills,prompt_en,prompt_ru,prompt_uz,rubric,self_en,self_ru,self_uz) as (values
(
  'P5FP03-Q01','P5-DAT-10',array['P5-DAT-09','P5-DAT-08']::text[],
  'The grouped distribution is: 0<x<=10: 6 observations; 10<x<=20: 14; 20<x<=40: 20; 40<x<=60: 10. (a) Estimate the mean. (b) Estimate the standard deviation. (c) Estimate the median by linear interpolation.',
  'Сгруппированное распределение: 0<x<=10: 6 наблюдений; 10<x<=20: 14; 20<x<=40: 20; 40<x<=60: 10. (a) Оцените среднее. (b) Оцените стандартное отклонение. (c) Оцените медиану линейной интерполяцией.',
  'Guruhlangan taqsimot: 0<x<=10: 6 ta kuzatuv; 10<x<=20: 14; 20<x<=40: 20; 40<x<=60: 10. (a) O‘rtacha qiymatni baholang. (b) Standart og‘ishni baholang. (c) Medianani chiziqli interpolatsiya bilan baholang.',
  '{"max_marks":8,"criteria":[{"id":"midpoints","marks":1,"rule":"Uses class midpoints 5,15,30,50."},{"id":"mean_total","marks":1,"rule":"Gets sum fx=1340 for total frequency 50."},{"id":"mean","marks":1,"rule":"Gets estimated mean 26.8."},{"id":"second_moment","marks":1,"rule":"Gets sum fx^2=46300 and E(X^2)=926."},{"id":"variance","marks":1,"rule":"Gets estimated variance 926-26.8^2=207.76."},{"id":"sd","marks":1,"rule":"Gets estimated standard deviation about 14.4."},{"id":"median_setup","marks":1,"rule":"Locates the median in 20<x<=40 with 5 of the 20 class observations beyond cumulative frequency 20."},{"id":"median","marks":1,"rule":"Gets median 20+(5/20)20=25."}]}'::jsonb,
  'Use class midpoints consistently for moments and cumulative frequencies for the interpolated median.',
  'Для моментов последовательно используйте середины интервалов, а для медианы — накопленные частоты.',
  'Momentlar uchun sinf o‘rtalaridan, interpolatsion mediana uchun esa yig‘ma chastotalardan izchil foydalaning.'
),
(
  'P5FP03-Q02','P5-CNT-05',array['P5-CNT-03','P5-CNT-04']::text[],
  'A 5-digit code is formed from the digits 0,1,2,3,4,5,6,7 without repetition, and the first digit cannot be 0. (a) Find the total number of codes. (b) Find the number of even codes. (c) Find the number of codes divisible by 5.',
  'Пятизначный код составляется из цифр 0,1,2,3,4,5,6,7 без повторений, первая цифра не может быть 0. (a) Найдите общее число кодов. (b) Найдите число чётных кодов. (c) Найдите число кодов, делящихся на 5.',
  '5 xonali kod 0,1,2,3,4,5,6,7 raqamlaridan takrorlanmasdan tuziladi va birinchi raqam 0 bo‘la olmaydi. (a) Kodlarning umumiy sonini toping. (b) Juft kodlar sonini toping. (c) 5 ga bo‘linadigan kodlar sonini toping.',
  '{"max_marks":7,"criteria":[{"id":"total_setup","marks":1,"rule":"Uses 7 choices for the first digit and then P(7,4) for the remaining positions."},{"id":"total","marks":1,"rule":"Gets 5880."},{"id":"even_zero","marks":1,"rule":"Counts even codes ending in 0 as 7*P(6,3)=840."},{"id":"even_nonzero","marks":1,"rule":"Counts endings 2,4,6 as 3*6*P(6,3)=2160."},{"id":"even_total","marks":1,"rule":"Gets 3000 even codes."},{"id":"five_cases","marks":1,"rule":"Counts endings 0 and 5 separately: 840 and 720."},{"id":"divisible5","marks":1,"rule":"Gets 1560 codes divisible by 5."}]}'::jsonb,
  'Split restrictions by the final digit first, especially when zero changes the number of allowed leading digits.',
  'Сначала разделите случаи по последней цифре, особенно когда ноль меняет число допустимых первых цифр.',
  'Avval oxirgi raqam bo‘yicha holatlarga ajrating, ayniqsa 0 birinchi raqam tanloviga ta’sir qilganda.'
),
(
  'P5FP03-Q03','P5-PRO-05',array['P5-PRO-03','P5-PRO-06']::text[],
  'A bag contains 5 red, 4 blue and 3 green counters. Two counters are selected at random without replacement. (a) Find the probability that both counters have the same colour. (b) Find the probability that at least one counter is red. (c) Given that at least one counter is red, find the probability that both are red.',
  'В мешке 5 красных, 4 синих и 3 зелёных фишки. Две фишки выбираются случайно без возвращения. (a) Найдите вероятность того, что обе фишки одного цвета. (b) Найдите вероятность того, что хотя бы одна фишка красная. (c) При условии, что хотя бы одна фишка красная, найдите вероятность того, что обе красные.',
  'Qopda 5 qizil, 4 ko‘k va 3 yashil jeton bor. Ikki jeton tasodifiy qaytarmasdan tanlanadi. (a) Ikkala jeton bir xil rangda bo‘lish ehtimolini toping. (b) Kamida bitta jeton qizil bo‘lish ehtimolini toping. (c) Kamida bittasi qizil ekani ma’lum bo‘lsa, ikkalasi ham qizil bo‘lish ehtimolini toping.',
  '{"max_marks":7,"criteria":[{"id":"sample_space","marks":1,"rule":"Uses C(12,2)=66 unordered pairs or an equivalent sequential denominator."},{"id":"same_colour","marks":1,"rule":"Gets [C(5,2)+C(4,2)+C(3,2)]/66=19/66."},{"id":"no_red","marks":1,"rule":"Gets P(no red)=C(7,2)/66=21/66."},{"id":"at_least_red","marks":1,"rule":"Gets P(at least one red)=45/66=15/22."},{"id":"both_red","marks":1,"rule":"Gets P(both red)=10/66=5/33."},{"id":"conditional_setup","marks":1,"rule":"Uses P(both red | at least one red)=P(both red)/P(at least one red)."},{"id":"conditional","marks":1,"rule":"Gets 2/9."}]}'::jsonb,
  'For two draws without replacement, combinations make the colour-pair events compact; conditional probability then uses the event already calculated.',
  'Для двух выборов без возвращения удобно использовать сочетания; затем условная вероятность строится из уже найденных событий.',
  'Qaytarmasdan ikki tanlovda kombinatsiyalar rang juftliklarini ixcham hisoblaydi; keyin shartli ehtimolda topilgan hodisalardan foydalaning.'
),
(
  'P5FP03-Q04','P5-BIN-02',array['P5-BIN-01','P5-BIN-03']::text[],
  'Let X have a binomial distribution with n=8 and p=0.3. (a) Find P(X=3). (b) Find P(X>=2). (c) Find E(X) and Var(X). (d) Find P(X=3 | X>=2). Give probabilities to 4 significant figures where appropriate.',
  'Пусть X имеет биномиальное распределение с n=8 и p=0.3. (a) Найдите P(X=3). (b) Найдите P(X>=2). (c) Найдите E(X) и Var(X). (d) Найдите P(X=3 | X>=2). Вероятности дайте до 4 значащих цифр, где уместно.',
  'X n=8 va p=0.3 parametrli binomial taqsimotga ega bo‘lsin. (a) P(X=3) ni toping. (b) P(X>=2) ni toping. (c) E(X) va Var(X) ni toping. (d) P(X=3 | X>=2) ni toping. Zarur joyda ehtimollarni 4 ta muhim raqamgacha bering.',
  '{"max_marks":8,"criteria":[{"id":"x3_setup","marks":1,"rule":"Uses C(8,3)(0.3)^3(0.7)^5."},{"id":"x3","marks":1,"rule":"Gets P(X=3) approximately 0.2541."},{"id":"ge2_setup","marks":1,"rule":"Uses 1-P(X=0)-P(X=1)."},{"id":"ge2","marks":1,"rule":"Gets P(X>=2) approximately 0.7447."},{"id":"mean","marks":1,"rule":"Gets E(X)=np=2.4."},{"id":"variance","marks":1,"rule":"Gets Var(X)=np(1-p)=1.68."},{"id":"conditional_setup","marks":1,"rule":"Uses P(X=3)/P(X>=2)."},{"id":"conditional","marks":1,"rule":"Gets approximately 0.3412."}]}'::jsonb,
  'Use a complement for X>=2 and reuse those probabilities in the conditional part.',
  'Для X>=2 используйте дополнение, а затем повторно используйте найденные вероятности в условной части.',
  'X>=2 uchun komplementdan foydalaning va shartli qismda shu ehtimollardan qayta foydalaning.'
),
(
  'P5FP03-Q05','P5-GEO-02',array['P5-GEO-01','P5-GEO-03']::text[],
  'Independent trials have success probability 0.2. Let Y be the trial number of the first success. (a) Find P(Y=4). (b) Find P(Y>5). (c) Find P(3<=Y<=6). (d) Given Y>3, find P(Y>7).',
  'В независимых испытаниях вероятность успеха равна 0.2. Пусть Y — номер испытания, на котором впервые получен успех. (a) Найдите P(Y=4). (b) Найдите P(Y>5). (c) Найдите P(3<=Y<=6). (d) При условии Y>3 найдите P(Y>7).',
  'Mustaqil sinovlarda muvaffaqiyat ehtimoli 0.2. Y birinchi muvaffaqiyat sodir bo‘lgan sinov raqami bo‘lsin. (a) P(Y=4) ni toping. (b) P(Y>5) ni toping. (c) P(3<=Y<=6) ni toping. (d) Y>3 sharti ostida P(Y>7) ni toping.',
  '{"max_marks":6,"criteria":[{"id":"y4","marks":1,"rule":"Gets (0.8)^3(0.2)=0.1024."},{"id":"tail5","marks":1,"rule":"Gets P(Y>5)=(0.8)^5=0.32768."},{"id":"range_setup","marks":1,"rule":"Uses the geometric probabilities for Y=3,4,5,6 or an equivalent tail difference."},{"id":"range","marks":1,"rule":"Gets P(3<=Y<=6)=0.377856."},{"id":"conditional_memoryless","marks":1,"rule":"Recognises that after three failures, Y>7 requires four further failures."},{"id":"conditional","marks":1,"rule":"Gets (0.8)^4=0.4096."}]}'::jsonb,
  'Translate Y>k into k consecutive failures; the conditional tail restarts after the failures already known to have occurred.',
  'Событие Y>k означает k последовательных неудач; в условной части отсчёт продолжается после уже известных неудач.',
  'Y>k hodisasi k ta ketma-ket muvaffaqiyatsizlikni anglatadi; shartli qismda hisob ma’lum bo‘lgan muvaffaqiyatsizliklardan keyin davom etadi.'
),
(
  'P5FP03-Q06','P5-NOR-03',array['P5-NOR-02','P5-NOR-04']::text[],
  'A random variable X is normally distributed with mean 70 and standard deviation 8. (a) Find P(X>82). (b) Find P(62<X<78). (c) Find k such that P(X<k)=0.90. Give k to 3 significant figures.',
  'Случайная величина X имеет нормальное распределение со средним 70 и стандартным отклонением 8. (a) Найдите P(X>82). (b) Найдите P(62<X<78). (c) Найдите k, если P(X<k)=0.90. Дайте k до 3 значащих цифр.',
  'X tasodifiy miqdor o‘rtacha 70 va standart og‘ish 8 bo‘lgan normal taqsimotga ega. (a) P(X>82) ni toping. (b) P(62<X<78) ni toping. (c) P(X<k)=0.90 bo‘lsa, k ni toping. k ni 3 ta muhim raqamgacha bering.',
  '{"max_marks":7,"criteria":[{"id":"z82","marks":1,"rule":"Standardises 82 to z=1.5."},{"id":"tail","marks":1,"rule":"Gets P(X>82) approximately 0.0668."},{"id":"central_z","marks":1,"rule":"Standardises 62 and 78 to z=-1 and z=1."},{"id":"central_prob","marks":1,"rule":"Gets P(-1<Z<1) approximately 0.6827."},{"id":"z90","marks":1,"rule":"Uses z_0.90 approximately 1.282."},{"id":"k_setup","marks":1,"rule":"Uses k=70+8z_0.90."},{"id":"k","marks":1,"rule":"Gets k approximately 80.3."}]}'::jsonb,
  'Standardise each boundary with the same mean and standard deviation; for the percentile, reverse the standardisation.',
  'Стандартизируйте каждую границу с теми же средним и стандартным отклонением; для процентиля выполните обратное преобразование.',
  'Har bir chegarani bir xil o‘rtacha va standart og‘ish bilan standartlashtiring; percentil uchun standartlashtirishni teskari bajaring.'
),
(
  'P5FP03-Q07','P5-NOR-06',array['P5-BIN-03','P5-NOR-05']::text[],
  'Let X have a binomial distribution with n=200 and p=0.4. Use a normal approximation with continuity correction to estimate P(70<=X<=90). Give the answer to 3 significant figures.',
  'Пусть X имеет биномиальное распределение с n=200 и p=0.4. Используя нормальное приближение с поправкой на непрерывность, оцените P(70<=X<=90). Дайте ответ до 3 значащих цифр.',
  'X n=200 va p=0.4 parametrli binomial taqsimotga ega. Uzluksizlik tuzatishi bilan normal yaqinlashuvdan foydalanib P(70<=X<=90) ni baholang. Javobni 3 ta muhim raqamgacha bering.',
  '{"max_marks":7,"criteria":[{"id":"mean","marks":1,"rule":"Gets normal mean np=80."},{"id":"sd","marks":1,"rule":"Gets variance np(1-p)=48 and sd=sqrt(48) approximately 6.928."},{"id":"continuity_lower","marks":1,"rule":"Uses lower boundary 69.5."},{"id":"continuity_upper","marks":1,"rule":"Uses upper boundary 90.5."},{"id":"z_bounds","marks":1,"rule":"Gets z bounds approximately -1.516 and 1.516."},{"id":"normal_probability","marks":1,"rule":"Uses Phi(1.516)-Phi(-1.516)."},{"id":"answer","marks":1,"rule":"Gets approximately 0.870."}]}'::jsonb,
  'Apply the continuity correction before standardising; the interval is symmetric about the approximating normal mean.',
  'Сначала примените поправку на непрерывность, затем стандартизируйте; интервал симметричен относительно среднего приближающего нормального распределения.',
  'Standartlashtirishdan oldin uzluksizlik tuzatishini qo‘llang; interval yaqinlashtiruvchi normal taqsimot o‘rtachasiga nisbatan simmetrik.'
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
  where content_version='p5_stage4_full_paper_03_v1' and component_code='P5' and status='draft'
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
  title_en,title_ru,title_uz,approved_at
)
select cv.id,'p5_stage4_full_paper_03','av1','P5','paper','approved',
       'P5 Stage 4 full paper 03 (pre-positioned)','P5 Stage 4 full paper 03 (pre-positioned)','P5 Stage 4 full paper 03 (pre-positioned)',now()
from cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions where content_version='p5_stage4_full_paper_03_v1'
), a as (
  select a.id from private.exam_prep_assessments a join cv on cv.id=a.content_version_id
  where a.assessment_key='p5_stage4_full_paper_03' and a.assessment_version='av1'
), items(item_order,task_key,skill) as (values
  (1,'P5FP03-Q01','P5-DAT-10'),
  (2,'P5FP03-Q02','P5-CNT-05'),
  (3,'P5FP03-Q03','P5-PRO-05'),
  (4,'P5FP03-Q04','P5-BIN-02'),
  (5,'P5FP03-Q05','P5-GEO-02'),
  (6,'P5FP03-Q06','P5-NOR-03'),
  (7,'P5FP03-Q07','P5-NOR-06')
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
  where assessment_key='p5_stage4_full_paper_03' and assessment_version='av1'
), marks(item_order,max_marks) as (values
  (1::smallint,8::smallint),(2::smallint,7::smallint),(3::smallint,7::smallint),(4::smallint,8::smallint),
  (5::smallint,6::smallint),(6::smallint,7::smallint),(7::smallint,7::smallint)
)
insert into private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks)
select a.id,m.item_order,m.max_marks from a cross join marks m
on conflict(assessment_id,item_order) do nothing;

update private.exam_prep_content_versions
set status='published',approved_at=coalesce(approved_at,now()),published_at=coalesce(published_at,now())
where content_version='p5_stage4_full_paper_03_v1' and status='draft';

do $$
declare
  v_ass bigint; v_tasks int; v_items int; v_marks int; v_rubric_marks int; v_sections int; v_profile bigint;
  v_cfg private.exam_prep_feature_config%rowtype; v_active int;
begin
  select id into v_ass from private.exam_prep_assessments
  where assessment_key='p5_stage4_full_paper_03' and assessment_version='av1' and status='approved';
  if v_ass is null then raise exception 'P1-03 P5 Paper03 approved assessment missing'; end if;
  select count(*) into v_tasks from private.exam_prep_assessment_items ai
  join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
  where ai.assessment_id=v_ass and ai.question_id is null and ai.reserve_role='written'
    and wt.lifecycle_state='published' and wt.copyright_status='pass'
    and wt.qa_math_status='pass' and wt.qa_language_status='pass' and wt.qa_technical_status='pass';
  if v_tasks<>7 then raise exception 'P1-03 P5 Paper03 written tasks=%',v_tasks; end if;
  select count(*),coalesce(sum(max_marks),0) into v_items,v_marks from private.exam_prep_timed_assessment_items where assessment_id=v_ass;
  if v_items<>7 or v_marks<>50 then raise exception 'P1-03 P5 Paper03 marks items=% marks=%',v_items,v_marks; end if;
  select coalesce(sum((wt.rubric_json->>'max_marks')::int),0) into v_rubric_marks
  from private.exam_prep_assessment_items ai join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id where ai.assessment_id=v_ass;
  if v_rubric_marks<>50 then raise exception 'P1-03 P5 Paper03 rubric marks=%',v_rubric_marks; end if;
  select count(distinct sn.official_syllabus_section) into v_sections
  from private.exam_prep_assessment_items ai
  join private.exam_prep_syllabus_nodes sn on sn.skill_code=ai.primary_skill_code and sn.component_code='P5'
  join private.exam_prep_content_versions cv on cv.id=(select content_version_id from private.exam_prep_assessments where id=v_ass)
  where ai.assessment_id=v_ass and sn.program_version_id=cv.program_version_id;
  if v_sections<>5 then raise exception 'P1-03 P5 Paper03 syllabus breadth sections=%',v_sections; end if;
  select id into v_profile from private.exam_prep_component_paper_profiles
  where component_code='P5' and profile_version='9709_2026_2027_v1' and status='published';
  if v_profile is null or private.exam_prep_timed_time_limit_v1(v_profile,'official_full',50,null)<>4500 then
    raise exception 'P1-03 P5 Paper03 official profile/timing missing';
  end if;
  if exists(select 1 from private.exam_prep_timed_assessment_contracts where assessment_id=v_ass) then raise exception 'P1-03 P5 Paper03 timed contract must not exist'; end if;
  if exists(select 1 from private.exam_prep_assessments where id=v_ass and status='published') then raise exception 'P1-03 P5 Paper03 must remain approved/not published'; end if;
  if exists(select 1 from public.questions q where q.book_ref like 'ExamPrep:%p5_stage4_full_paper_03%') then raise exception 'P1-03 P5 Paper03 legacy question residue'; end if;
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then raise exception 'P1-03 P5 Paper03 requires fail-closed feature state'; end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 P5 Paper03 active entitlement residue=%',v_active; end if;
end $$;

commit;
