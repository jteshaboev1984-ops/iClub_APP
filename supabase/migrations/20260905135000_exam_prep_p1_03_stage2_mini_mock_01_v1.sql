-- P1-03 pre-live depth: first Stage-2 cumulative mini-mock / modified-paper for P1 and P5.
-- Written-only, original iClub-authored content. No public.questions / legacy mutation.
-- All primary skills are distinct from Stage-2 timed blocks 01-02.
begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active'
), defs(component_code,content_version,release_label) as (values
  ('P1','p1_stage2_mini_mock_01_v1','P1 Stage-2 cumulative mini-mock 01'),
  ('P5','p5_stage2_mini_mock_01_v1','P5 Stage-2 cumulative mini-mock 01')
)
insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,d.content_version,d.component_code,d.release_label,'draft',
       'Original iClub-authored exam-prep modified-paper content. Cambridge 9709 2026-2027 official syllabus defines scope/timing only; no protected question wording copied.'
from pv cross join defs d
on conflict(program_version_id,content_version) do nothing;

-- P1: transformed quadratic, circular measure, finite GP, rates of change.
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_stage2_mini_mock_01_v1' and component_code='P1' and status='draft'
), defs(task_key,primary_skill,secondary_skills,prompt_en,prompt_ru,prompt_uz,rubric,self_en,self_ru,self_uz) as (values
(
  'P1MM01-Q01','P1-QUA-06',array['P1-QUA-03']::text[],
  'Solve (x+1)^4-5(x+1)^2+4=0. Show clearly how you reduce the equation to a quadratic in a transformed expression and give all real values of x.',
  'Решите (x+1)^4-5(x+1)^2+4=0. Покажите, как вы сводите уравнение к квадратному относительно новой переменной, и найдите все действительные значения x.',
  '(x+1)^4-5(x+1)^2+4=0 tenglamani yeching. Tenglamani almashtirilgan ifoda bo‘yicha kvadrat tenglamaga qanday keltirganingizni ko‘rsating va barcha haqiqiy x qiymatlarini toping.',
  '{"max_marks":5,"criteria":[{"id":"substitution","marks":1,"rule":"Sets u=(x+1)^2 and obtains u^2-5u+4=0."},{"id":"quadratic_roots","marks":1,"rule":"Gets u=1 or u=4."},{"id":"first_pair","marks":1,"rule":"From (x+1)^2=1 gets x=0,-2."},{"id":"second_pair","marks":1,"rule":"From (x+1)^2=4 gets x=1,-3."},{"id":"complete_set","marks":1,"rule":"States all four real solutions with no extras."}]}'::jsonb,
  'After solving the quadratic in u, return to the original transformed expression and solve both square equations completely.',
  'После решения квадратного уравнения по u вернитесь к исходному выражению и полностью решите оба квадратных уравнения.',
  'u bo‘yicha kvadrat tenglamani yechgach, asl almashtirilgan ifodaga qayting va ikkala kvadrat tenglamani to‘liq yeching.'
),
(
  'P1MM01-Q02','P1-CIR-03',array['P1-CIR-02']::text[],
  'A sector of a circle has radius 6 cm and angle 2pi/3 radians. Find (i) the area of the sector, (ii) the area of the triangle formed by the two radii and the chord, and hence (iii) the area of the minor segment. Give exact answers.',
  'Сектор окружности имеет радиус 6 см и угол 2pi/3 радиан. Найдите (i) площадь сектора, (ii) площадь треугольника, образованного двумя радиусами и хордой, и затем (iii) площадь малого сегмента. Дайте точные ответы.',
  'Aylana sektorining radiusi 6 cm, burchagi 2pi/3 radian. (i) sektor yuzasini, (ii) ikki radius va xorda hosil qilgan uchburchak yuzasini va (iii) kichik segment yuzasini toping. Aniq javoblarni bering.',
  '{"max_marks":5,"criteria":[{"id":"sector_formula","marks":1,"rule":"Uses A_sector=(1/2)r^2 theta."},{"id":"sector_area","marks":1,"rule":"Gets 12pi cm^2."},{"id":"triangle_formula","marks":1,"rule":"Uses A_triangle=(1/2)r^2 sin(theta)."},{"id":"triangle_area","marks":1,"rule":"Gets 9sqrt(3) cm^2."},{"id":"segment","marks":1,"rule":"Gets 12pi-9sqrt(3) cm^2."}]}'::jsonb,
  'A segment is sector minus triangle; keep the angle in radians for the sector formula.',
  'Площадь сегмента равна площади сектора минус площадь треугольника; в формуле сектора используйте радианы.',
  'Segment yuzi sektor yuzidan uchburchak yuzini ayirish bilan topiladi; sektor formulasida radian ishlating.'
),
(
  'P1MM01-Q03','P1-SER-04',array['P1-SER-02']::text[],
  'A geometric progression has first term 3 and common ratio 2. Write the nth term, derive a formula for S_n, and find n if S_n=93.',
  'Геометрическая прогрессия имеет первый член 3 и знаменатель 2. Запишите n-й член, выведите формулу для S_n и найдите n, если S_n=93.',
  'Geometrik progressiyaning birinchi hadi 3, umumiy nisbati 2. n-hadni yozing, S_n formulasini chiqaring va S_n=93 bo‘lsa n ni toping.',
  '{"max_marks":5,"criteria":[{"id":"nth_term","marks":1,"rule":"Gets u_n=3*2^(n-1)."},{"id":"sum_formula","marks":1,"rule":"Uses S_n=3(2^n-1)/(2-1)=3(2^n-1)."},{"id":"inverse_setup","marks":1,"rule":"From S_n=93 gets 2^n-1=31."},{"id":"power","marks":1,"rule":"Gets 2^n=32."},{"id":"n_value","marks":1,"rule":"Gets n=5."}]}'::jsonb,
  'Use the finite geometric-sum formula before solving the inverse problem for n.',
  'Сначала используйте формулу конечной геометрической суммы, затем решайте обратную задачу относительно n.',
  'Avval chekli geometrik yig‘indi formulasini ishlating, keyin n bo‘yicha teskari masalani yeching.'
),
(
  'P1MM01-Q04','P1-DIF-06',array['P1-DIF-03']::text[],
  'A spherical balloon has radius r cm and volume V=4pi r^3/3. At an instant when r=3 cm, its volume is increasing at 36pi cm^3/s. Find dr/dt and then find the rate of change of its surface area S=4pi r^2 at that instant. Include units.',
  'Сферический шар имеет радиус r см и объём V=4pi r^3/3. В момент, когда r=3 см, объём увеличивается со скоростью 36pi см^3/с. Найдите dr/dt, затем скорость изменения площади поверхности S=4pi r^2 в этот момент. Укажите единицы.',
  'Sferik sharning radiusi r cm va hajmi V=4pi r^3/3. r=3 cm bo‘lgan paytda hajm 36pi cm^3/s tezlikda oshmoqda. dr/dt ni, so‘ng S=4pi r^2 sirt yuzasining o‘zgarish tezligini toping. Birliklarni ko‘rsating.',
  '{"max_marks":5,"criteria":[{"id":"volume_rate","marks":1,"rule":"Differentiates to dV/dt=4pi r^2 dr/dt."},{"id":"radius_rate","marks":1,"rule":"At r=3 gets dr/dt=1 cm/s."},{"id":"surface_rate","marks":1,"rule":"Differentiates to dS/dt=8pi r dr/dt."},{"id":"surface_value","marks":1,"rule":"Gets dS/dt=24pi cm^2/s."},{"id":"units_sign","marks":1,"rule":"Reports positive rates with correct cm/s and cm^2/s units."}]}'::jsonb,
  'Differentiate each geometric relation with respect to time before substituting the instant values.',
  'Сначала продифференцируйте каждое геометрическое соотношение по времени, затем подставляйте значения в данный момент.',
  'Avval har bir geometrik bog‘lanishni vaqt bo‘yicha differensiallang, keyin shu paytdagi qiymatlarni qo‘ying.'
)
)
insert into private.exam_prep_written_tasks(
  content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
  prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
  lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select cv.id,d.task_key,'P1',d.primary_skill,d.secondary_skills,'wtv1',d.prompt_en,d.prompt_ru,d.prompt_uz,d.rubric,d.self_en,d.self_ru,d.self_uz,
       'published','pass','pass','pass','pass',now()
from cv cross join defs d
on conflict(content_version_id,task_key,task_version) do nothing;

-- P5: coded totals, conditional probability, geometric expectation, normal approximation.
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_stage2_mini_mock_01_v1' and component_code='P5' and status='draft'
), defs(task_key,primary_skill,secondary_skills,prompt_en,prompt_ru,prompt_uz,rubric,self_en,self_ru,self_uz) as (values
(
  'P5MM01-Q01','P5-DAT-10',array['P5-DAT-09']::text[],
  'Data set A contains 20 observations. With coding y=x-10, the total sum of the coded values is sum y=40. Data set B contains 30 observations with mean 18. Find the mean of A and the mean of the combined 50 observations.',
  'Набор A содержит 20 наблюдений. При кодировании y=x-10 сумма кодированных значений равна sum y=40. Набор B содержит 30 наблюдений со средним 18. Найдите среднее набора A и среднее объединённых 50 наблюдений.',
  'A to‘plamda 20 ta kuzatuv bor. y=x-10 kodlashda kodlangan qiymatlar yig‘indisi sum y=40. B to‘plamda 30 ta kuzatuv va o‘rtacha qiymat 18. A ning o‘rtacha qiymatini va 50 ta birlashtirilgan kuzatuv o‘rtachasini toping.',
  '{"max_marks":5,"criteria":[{"id":"decode_sum","marks":1,"rule":"Uses sum x=sum(y+10)=40+20*10=240 for A."},{"id":"mean_a","marks":1,"rule":"Gets mean A=240/20=12."},{"id":"sum_b","marks":1,"rule":"Gets sum B=30*18=540."},{"id":"combined_sum","marks":1,"rule":"Gets combined sum=780."},{"id":"combined_mean","marks":1,"rule":"Gets combined mean=780/50=15.6."}]}'::jsonb,
  'Undo the coding at the total level: each of the 20 observations contributes the +10 shift.',
  'Отменяйте кодирование на уровне суммы: каждое из 20 наблюдений добавляет сдвиг +10.',
  'Kodlashni yig‘indi darajasida qaytaring: 20 ta kuzatuvning har biri +10 siljishni qo‘shadi.'
),
(
  'P5MM01-Q02','P5-PRO-05',array['P5-PRO-03']::text[],
  'Events A and B satisfy P(A)=0.6, P(B)=0.5 and P(A intersection B)=0.3. Find P(A|B), P(B|A), the probability that exactly one of A and B occurs, and state with justification whether A and B are independent.',
  'Для событий A и B даны P(A)=0.6, P(B)=0.5 и P(A intersection B)=0.3. Найдите P(A|B), P(B|A), вероятность того, что произойдёт ровно одно из событий A и B, и с обоснованием определите, независимы ли A и B.',
  'A va B hodisalar uchun P(A)=0.6, P(B)=0.5 va P(A intersection B)=0.3. P(A|B), P(B|A), A va B dan aynan bittasi sodir bo‘lish ehtimolini toping va A hamda B mustaqil yoki yo‘qligini asoslang.',
  '{"max_marks":5,"criteria":[{"id":"a_given_b","marks":1,"rule":"Gets P(A|B)=0.3/0.5=0.6."},{"id":"b_given_a","marks":1,"rule":"Gets P(B|A)=0.3/0.6=0.5."},{"id":"exactly_one_setup","marks":1,"rule":"Uses P(A)+P(B)-2P(A intersection B)."},{"id":"exactly_one","marks":1,"rule":"Gets exactly-one probability=0.5."},{"id":"independence","marks":1,"rule":"States independent because P(A intersection B)=P(A)P(B)=0.3 (or equivalent conditional test)."}]}'::jsonb,
  'Conditional probability divides the intersection by the conditioning event; independence needs an explicit equality test.',
  'Условная вероятность делит пересечение на вероятность условия; независимость нужно подтвердить явным равенством.',
  'Shartli ehtimolda kesishma shart hodisasi ehtimoliga bo‘linadi; mustaqillikni aniq tenglik bilan tekshiring.'
),
(
  'P5MM01-Q03','P5-GEO-03',array['P5-GEO-02','P5-DRV-02']::text[],
  'X is the number of independent trials up to and including the first success, with constant success probability p. Given E(X)=4, find p, P(X>3), and P(X=5). Give exact fractions.',
  'X — число независимых испытаний до первого успеха включительно, вероятность успеха в каждом испытании равна p. Известно E(X)=4. Найдите p, P(X>3) и P(X=5). Дайте точные дроби.',
  'X — doimiy p muvaffaqiyat ehtimoli bilan birinchi muvaffaqiyatgacha, uni ham qo‘shib, mustaqil sinovlar soni. E(X)=4 bo‘lsa, p, P(X>3) va P(X=5) ni toping. Aniq kasrlarni bering.',
  '{"max_marks":5,"criteria":[{"id":"expectation_formula","marks":1,"rule":"Uses E(X)=1/p for the geometric model."},{"id":"p_value","marks":1,"rule":"Gets p=1/4."},{"id":"tail_setup","marks":1,"rule":"Uses P(X>3)=(1-p)^3."},{"id":"tail_value","marks":1,"rule":"Gets P(X>3)=27/64."},{"id":"exact_value","marks":1,"rule":"Gets P(X=5)=(3/4)^4(1/4)=81/1024."}]}'::jsonb,
  'For X counting trials until the first success, X>3 means the first three trials all fail.',
  'Если X считает испытания до первого успеха, событие X>3 означает, что первые три испытания завершились неудачей.',
  'X birinchi muvaffaqiyatgacha sinovlarni sanasa, X>3 degani dastlabki uchta sinovning barchasi muvaffaqiyatsiz.'
),
(
  'P5MM01-Q04','P5-NOR-06',array['P5-BIN-02','P5-NOR-03']::text[],
  'Let X~Bin(80,0.4). Explain briefly why a normal approximation is reasonable, then use a normal approximation with continuity correction to estimate P(28<=X<=38). Give the probability to 4 d.p.',
  'Пусть X~Bin(80,0.4). Кратко объясните, почему normal approximation применима, затем с continuity correction оцените P(28<=X<=38). Дайте вероятность до 4 знаков после запятой.',
  'X~Bin(80,0.4) bo‘lsin. Normal approximation nega mosligini qisqacha tushuntiring, so‘ng continuity correction bilan P(28<=X<=38) ni baholang. Ehtimolni 4 o‘nli xonagacha bering.',
  '{"max_marks":5,"criteria":[{"id":"conditions","marks":1,"rule":"Notes np=32 and n(1-p)=48 are both sufficiently large."},{"id":"normal_parameters","marks":1,"rule":"Uses Y~N(32,19.2), so sigma=sqrt(19.2)."},{"id":"continuity","marks":1,"rule":"Uses corrected interval 27.5<Y<38.5."},{"id":"standardise","marks":1,"rule":"Gets z-bounds about -1.0270 and 1.4834."},{"id":"probability","marks":1,"rule":"Gets probability about 0.7788 to 4 d.p."}]}'::jsonb,
  'Write the continuity-corrected boundaries before standardising; the normal model uses variance np(1-p), not standard deviation as its second N(mu,sigma^2) parameter.',
  'Сначала запишите границы с continuity correction, затем стандартизируйте; в N(mu,sigma^2) вторым параметром является дисперсия np(1-p).',
  'Avval continuity correction chegaralarini yozing, keyin standartlang; N(mu,sigma^2) da ikkinchi parametr variance np(1-p).' 
)
)
insert into private.exam_prep_written_tasks(
  content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
  prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
  lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select cv.id,d.task_key,'P5',d.primary_skill,d.secondary_skills,'wtv1',d.prompt_en,d.prompt_ru,d.prompt_uz,d.rubric,d.self_en,d.self_ru,d.self_uz,
       'published','pass','pass','pass','pass',now()
from cv cross join defs d
on conflict(content_version_id,task_key,task_version) do nothing;

with cv as (
  select id,component_code from private.exam_prep_content_versions
  where content_version in ('p1_stage2_mini_mock_01_v1','p5_stage2_mini_mock_01_v1') and status='draft'
), defs(component_code,assessment_key,title_en,title_ru,title_uz) as (values
  ('P1','p1_stage2_mini_mock_01','P1 Stage 2 cumulative mini-mock 01','P1 Stage 2: cumulative mini-mock 01','P1 Stage 2 cumulative mini-mock 01'),
  ('P5','p5_stage2_mini_mock_01','P5 Stage 2 cumulative mini-mock 01','P5 Stage 2: cumulative mini-mock 01','P5 Stage 2 cumulative mini-mock 01')
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
  title_en,title_ru,title_uz,approved_at
)
select cv.id,d.assessment_key,'av1',d.component_code,'paper','approved',d.title_en,d.title_ru,d.title_uz,now()
from cv join defs d using(component_code)
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (
  select id,component_code from private.exam_prep_content_versions
  where content_version in ('p1_stage2_mini_mock_01_v1','p5_stage2_mini_mock_01_v1')
), a as (
  select a.id,a.component_code from private.exam_prep_assessments a join cv on cv.id=a.content_version_id
  where a.assessment_key in ('p1_stage2_mini_mock_01','p5_stage2_mini_mock_01') and a.assessment_version='av1'
), items(component_code,item_order,task_key,skill) as (values
  ('P1',1,'P1MM01-Q01','P1-QUA-06'),('P1',2,'P1MM01-Q02','P1-CIR-03'),('P1',3,'P1MM01-Q03','P1-SER-04'),('P1',4,'P1MM01-Q04','P1-DIF-06'),
  ('P5',1,'P5MM01-Q01','P5-DAT-10'),('P5',2,'P5MM01-Q02','P5-PRO-05'),('P5',3,'P5MM01-Q03','P5-GEO-03'),('P5',4,'P5MM01-Q04','P5-NOR-06')
), wt as (
  select w.id,w.task_key,w.component_code from private.exam_prep_written_tasks w join cv on cv.id=w.content_version_id
)
insert into private.exam_prep_assessment_items(
  assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select a.id,i.item_order,null,wt.id,i.skill,'written',true
from items i join a using(component_code) join wt on wt.component_code=i.component_code and wt.task_key=i.task_key
on conflict(assessment_id,item_order) do nothing;

with a as (
  select id from private.exam_prep_assessments
  where assessment_key in ('p1_stage2_mini_mock_01','p5_stage2_mini_mock_01') and assessment_version='av1'
)
insert into private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks)
select a.id,v.item_order,5 from a cross join (values (1::smallint),(2::smallint),(3::smallint),(4::smallint)) v(item_order)
on conflict(assessment_id,item_order) do nothing;

update private.exam_prep_content_versions
set status='published',approved_at=coalesce(approved_at,now()),published_at=coalesce(published_at,now())
where content_version in ('p1_stage2_mini_mock_01_v1','p5_stage2_mini_mock_01_v1') and status='draft';

update private.exam_prep_assessments
set status='published',approved_at=coalesce(approved_at,now())
where assessment_key in ('p1_stage2_mini_mock_01','p5_stage2_mini_mock_01') and assessment_version='av1' and status='approved';

with a as (
  select a.id,a.component_code from private.exam_prep_assessments a
  where a.assessment_key in ('p1_stage2_mini_mock_01','p5_stage2_mini_mock_01') and a.assessment_version='av1' and a.status='published'
), p as (
  select id,component_code from private.exam_prep_component_paper_profiles
  where profile_version='9709_2026_2027_v1' and status='published'
)
insert into private.exam_prep_timed_assessment_contracts(
  assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
  strict_timing,comparison_scope,comparability_key,status,published_at
)
select a.id,p.id,'tcv1','modified_paper','proportional_marks',20,null,true,'modified',
       case a.component_code when 'P1' then 'p1-stage2-mini-mock-01-v1' else 'p5-stage2-mini-mock-01-v1' end,
       'published',now()
from a join p using(component_code)
on conflict(assessment_id) do nothing;

-- Acceptance: 4 written tasks/20 marks, no primary overlap with short blocks, proportional timing and fail-closed runtime.
do $$
declare
  v_component text;
  v_ass bigint;
  v_tasks int;
  v_items int;
  v_marks int;
  v_rubric_marks int;
  v_overlap int;
  v_contract private.exam_prep_timed_assessment_contracts%rowtype;
  v_expected_time int;
  v_actual_time int;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  foreach v_component in array array['P1','P5'] loop
    select a.id into v_ass from private.exam_prep_assessments a
    where a.assessment_key=case v_component when 'P1' then 'p1_stage2_mini_mock_01' else 'p5_stage2_mini_mock_01' end
      and a.assessment_version='av1' and a.status='published';
    if v_ass is null then raise exception 'P1-03 mini-mock assessment missing component=%',v_component; end if;

    select count(*) into v_tasks
    from private.exam_prep_assessment_items ai join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
    where ai.assessment_id=v_ass and ai.question_id is null and ai.reserve_role='written'
      and wt.lifecycle_state='published' and wt.copyright_status='pass'
      and wt.qa_math_status='pass' and wt.qa_language_status='pass' and wt.qa_technical_status='pass';
    if v_tasks<>4 then raise exception 'P1-03 mini-mock written floor component=% tasks=%',v_component,v_tasks; end if;

    select count(*),coalesce(sum(max_marks),0) into v_items,v_marks
    from private.exam_prep_timed_assessment_items where assessment_id=v_ass;
    if v_items<>4 or v_marks<>20 then raise exception 'P1-03 mini-mock marks component=% items=% marks=%',v_component,v_items,v_marks; end if;

    select coalesce(sum((wt.rubric_json->>'max_marks')::int),0) into v_rubric_marks
    from private.exam_prep_assessment_items ai join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
    where ai.assessment_id=v_ass;
    if v_rubric_marks<>20 then raise exception 'P1-03 mini-mock rubric mismatch component=% marks=%',v_component,v_rubric_marks; end if;

    select count(*) into v_overlap
    from private.exam_prep_assessment_items newer
    join private.exam_prep_assessments olda on olda.assessment_key in (
      case v_component when 'P1' then 'p1_stage2_timed_block_01' else 'p5_stage2_timed_block_01' end,
      case v_component when 'P1' then 'p1_stage2_timed_block_02' else 'p5_stage2_timed_block_02' end
    ) and olda.assessment_version='av1'
    join private.exam_prep_assessment_items older on older.assessment_id=olda.id and older.primary_skill_code=newer.primary_skill_code
    where newer.assessment_id=v_ass;
    if v_overlap<>0 then raise exception 'P1-03 mini-mock primary-skill overlap component=% count=%',v_component,v_overlap; end if;

    select * into v_contract from private.exam_prep_timed_assessment_contracts where assessment_id=v_ass and status='published';
    if v_contract.assessment_id is null or v_contract.attempt_kind<>'modified_paper' or v_contract.timing_rule<>'proportional_marks'
       or v_contract.comparison_scope<>'modified' or v_contract.marks_available<>20 or v_contract.fixed_time_limit_sec is not null
       or not v_contract.strict_timing then raise exception 'P1-03 mini-mock contract invalid component=%',v_component; end if;
    if private.exam_prep_timed_min_stage_v1(v_contract.attempt_kind)<>2 then raise exception 'P1-03 mini-mock stage drift component=%',v_component; end if;

    v_expected_time:=case v_component when 'P1' then 1760 else 1800 end;
    v_actual_time:=private.exam_prep_timed_time_limit_v1(v_contract.paper_profile_id,v_contract.timing_rule,v_contract.marks_available,v_contract.fixed_time_limit_sec);
    if v_actual_time<>v_expected_time then raise exception 'P1-03 mini-mock timing drift component=% seconds=% expected=%',v_component,v_actual_time,v_expected_time; end if;
  end loop;

  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 mini-mock publication requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 mini-mock active entitlement residue=%',v_active; end if;
  if exists(select 1 from private.exam_prep_sessions) or exists(select 1 from private.exam_prep_evidence_events) then
    raise exception 'P1-03 mini-mock publication must not create learner runtime evidence';
  end if;
end $$;

commit;
