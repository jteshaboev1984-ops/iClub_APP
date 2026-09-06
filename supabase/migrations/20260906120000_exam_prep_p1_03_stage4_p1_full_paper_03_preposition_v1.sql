-- P1-03 pre-live depth: pre-position third governed P1 full-paper form for later Stage-4/5 evidence depth.
-- 75 marks / 110 minutes under the existing Cambridge 9709 P1 profile once released.
-- Assessment remains approved and has NO timed contract. No learner access or legacy activation.
begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active'
)
insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,'p1_stage4_full_paper_03_v1','P1','P1 Stage-4 full paper 03 pre-position','draft',
       'Original iClub-authored full-paper practice content. Cambridge 9709 2026-2027 official syllabus/profile defines scope, marks and timing only; no protected question wording copied. Assessment intentionally remains approved/not published until a later governed release.'
from pv
on conflict(program_version_id,content_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_stage4_full_paper_03_v1' and component_code='P1' and status='draft'
), defs(task_key,primary_skill,secondary_skills,prompt_en,prompt_ru,prompt_uz,rubric,self_en,self_ru,self_uz) as (values
(
  'P1FP03-Q01','P1-QUA-03',array['P1-QUA-01']::text[],
  'The quadratic equation x^2-6x+k=0 has roots alpha and beta, where alpha^2+beta^2=20. (a) Find k. (b) Hence find alpha and beta. (c) Find the set of real values of c for which x^2-6x+8=c has two distinct real solutions.',
  'Квадратное уравнение x^2-6x+k=0 имеет корни alpha и beta, причём alpha^2+beta^2=20. (a) Найдите k. (b) Затем найдите alpha и beta. (c) Найдите множество действительных c, при которых x^2-6x+8=c имеет два различных действительных решения.',
  'x^2-6x+k=0 kvadrat tenglamaning ildizlari alpha va beta bo‘lib, alpha^2+beta^2=20. (a) k ni toping. (b) So‘ng alpha va beta ni toping. (c) x^2-6x+8=c tenglama ikkita turli haqiqiy yechimga ega bo‘ladigan barcha haqiqiy c larni toping.',
  '{"max_marks":7,"criteria":[{"id":"vieta","marks":1,"rule":"Uses alpha+beta=6 and alpha beta=k."},{"id":"square_sum","marks":1,"rule":"Uses alpha^2+beta^2=(alpha+beta)^2-2 alpha beta."},{"id":"k","marks":1,"rule":"Gets 36-2k=20 and k=8."},{"id":"roots_setup","marks":1,"rule":"Solves x^2-6x+8=0."},{"id":"roots","marks":1,"rule":"Gets roots 2 and 4."},{"id":"completed_square","marks":1,"rule":"Writes x^2-6x+8=(x-3)^2-1."},{"id":"c_range","marks":1,"rule":"States c>-1 for two distinct real solutions."}]}'::jsonb,
  'Use Vieta first, then rewrite the shifted quadratic in completed-square form to read the two-root condition directly.',
  'Сначала используйте формулы Виета, затем представьте сдвинутую квадратичную функцию в виде полного квадрата.',
  'Avval Viyet formulalaridan foydalaning, keyin siljigan kvadrat ifodani to‘liq kvadrat ko‘rinishiga keltiring.'
),
(
  'P1FP03-Q02','P1-FUN-06',array['P1-FUN-02','P1-FUN-04']::text[],
  'Let f(x)=sqrt(2x+6)-1. (a) State the domain and range of f. (b) Find f^(-1)(x), including its domain. (c) Solve f(x)=x exactly.',
  'Пусть f(x)=sqrt(2x+6)-1. (a) Укажите область определения и множество значений f. (b) Найдите f^(-1)(x), включая его область определения. (c) Решите f(x)=x точно.',
  'f(x)=sqrt(2x+6)-1 bo‘lsin. (a) f ning aniqlanish sohasi va qiymatlar sohasini ayting. (b) f^(-1)(x) ni, uning aniqlanish sohasi bilan birga toping. (c) f(x)=x tenglamani aniq yeching.',
  '{"max_marks":7,"criteria":[{"id":"domain","marks":1,"rule":"States x>=-3."},{"id":"range","marks":1,"rule":"States f(x)>=-1."},{"id":"inverse_steps","marks":1,"rule":"Rearranges y+1=sqrt(2x+6) and squares with the correct restriction."},{"id":"inverse","marks":1,"rule":"Gets f^(-1)(x)=((x+1)^2-6)/2."},{"id":"inverse_domain","marks":1,"rule":"States inverse domain x>=-1."},{"id":"fixed_point_equation","marks":1,"rule":"Gets x^2=5 together with x+1>=0."},{"id":"fixed_point","marks":1,"rule":"Accepts only x=sqrt(5)."}]}'::jsonb,
  'Keep the square-root range restriction when finding the inverse and when checking the fixed point.',
  'При нахождении обратной функции и неподвижной точки сохраняйте ограничение, связанное с квадратным корнем.',
  'Teskari funksiyani va f(x)=x yechimini topishda kvadrat ildizdan keladigan cheklovni saqlang.'
),
(
  'P1FP03-Q03','P1-COO-04',array['P1-COO-01','P1-COO-03']::text[],
  'Points A(2,-1) and B(8,5) are given. (a) Find the equation of the perpendicular bisector of AB. (b) Find the equation of the circle with AB as diameter. (c) The perpendicular bisector meets the x-axis at C. Find C and the area of triangle ABC.',
  'Даны точки A(2,-1) и B(8,5). (a) Найдите уравнение серединного перпендикуляра к AB. (b) Найдите уравнение окружности с диаметром AB. (c) Серединный перпендикуляр пересекает ось x в точке C. Найдите C и площадь треугольника ABC.',
  'A(2,-1) va B(8,5) nuqtalar berilgan. (a) AB kesmaning o‘rta perpendikulyari tenglamasini toping. (b) AB diametr bo‘lgan aylana tenglamasini toping. (c) O‘rta perpendikulyar x o‘qini C nuqtada kesadi. C ni va ABC uchburchak yuzini toping.',
  '{"max_marks":8,"criteria":[{"id":"midpoint","marks":1,"rule":"Gets midpoint (5,2)."},{"id":"gradients","marks":1,"rule":"Gets gradient AB=1 and perpendicular gradient -1."},{"id":"bisector","marks":1,"rule":"Gets y=-x+7."},{"id":"radius","marks":1,"rule":"Gets radius squared 18."},{"id":"circle","marks":1,"rule":"Gets (x-5)^2+(y-2)^2=18."},{"id":"point_c","marks":1,"rule":"Gets C=(7,0)."},{"id":"height_or_det","marks":1,"rule":"Uses a valid base-height or determinant area method."},{"id":"area","marks":1,"rule":"Gets area 12 square units."}]}'::jsonb,
  'Use midpoint and gradient facts first; for the area, either a determinant or distance-to-line method is efficient.',
  'Сначала найдите середину и угловые коэффициенты; для площади удобно использовать определитель или расстояние до прямой.',
  'Avval o‘rta nuqta va qiyaliklarni toping; yuzani determinant yoki nuqtadan chiziqqacha masofa orqali hisoblash qulay.'
),
(
  'P1FP03-Q04','P1-CIR-03',array['P1-CIR-01','P1-CIR-02']::text[],
  'A sector has arc length 12 cm and area 54 cm^2. Find (a) its radius, (b) its angle in radians, (c) its perimeter, and (d) the chord length between the arc endpoints, giving the chord length to 3 significant figures.',
  'Сектор имеет длину дуги 12 см и площадь 54 см^2. Найдите (a) радиус, (b) угол в радианах, (c) периметр и (d) длину хорды между концами дуги, дав длину хорды до 3 значащих цифр.',
  'Sektor yoyining uzunligi 12 cm va yuzi 54 cm^2. (a) Radiusni, (b) radianlardagi burchakni, (c) perimetrni va (d) yoy uchlarini tutashtiruvchi vatar uzunligini 3 ta muhim raqamgacha toping.',
  '{"max_marks":6,"criteria":[{"id":"radius_relation","marks":1,"rule":"Uses A=(1/2)rs with s=12."},{"id":"radius","marks":1,"rule":"Gets r=9 cm."},{"id":"theta","marks":1,"rule":"Uses s=r theta and gets theta=4/3."},{"id":"perimeter","marks":1,"rule":"Gets 2r+s=30 cm."},{"id":"chord_formula","marks":1,"rule":"Uses chord=2r sin(theta/2)."},{"id":"chord","marks":1,"rule":"Gets 18 sin(2/3) approximately 11.1 cm."}]}'::jsonb,
  'The area can be written as one half times radius times arc length; use radians for the chord formula.',
  'Площадь можно записать как половину произведения радиуса на длину дуги; в формуле хорды используйте радианы.',
  'Yuzani radius va yoy uzunligi ko‘paytmasining yarmi sifatida yozish mumkin; vatar formulasida radianlardan foydalaning.'
),
(
  'P1FP03-Q05','P1-TRI-05',array['P1-TRI-03','P1-TRI-04']::text[],
  'For 0<=x<2pi solve 2cos^2(x)+3sin(x)-3=0, giving every solution exactly.',
  'Для 0<=x<2pi решите 2cos^2(x)+3sin(x)-3=0 и укажите все решения точно.',
  '0<=x<2pi uchun 2cos^2(x)+3sin(x)-3=0 tenglamani yeching va barcha yechimlarni aniq ko‘rsating.',
  '{"max_marks":8,"criteria":[{"id":"identity","marks":1,"rule":"Uses cos^2 x=1-sin^2 x."},{"id":"quadratic","marks":1,"rule":"Obtains 2sin^2 x-3sin x+1=0."},{"id":"factor","marks":1,"rule":"Factors as (2sin x-1)(sin x-1)=0."},{"id":"branches","marks":1,"rule":"Gets sin x=1/2 or sin x=1."},{"id":"half_reference","marks":1,"rule":"Uses reference angle pi/6 for sin x=1/2."},{"id":"half_solutions","marks":1,"rule":"Gets x=pi/6 and 5pi/6."},{"id":"one_solution","marks":1,"rule":"Gets x=pi/2 for sin x=1."},{"id":"complete_set","marks":1,"rule":"States exactly pi/6, pi/2, 5pi/6 with no extras."}]}'::jsonb,
  'Convert to a quadratic in sin x, then solve each branch over the full interval before combining the solutions.',
  'Преобразуйте уравнение в квадратное относительно sin x, затем решите каждую ветвь на всём интервале.',
  'Tenglamani sin x bo‘yicha kvadrat tenglamaga aylantiring, so‘ng har bir tarmoqni butun intervalda yeching.'
),
(
  'P1FP03-Q06','P1-SER-03',array['P1-SER-01']::text[],
  'An arithmetic progression has first term 5 and common difference 3. (a) Find the 20th term. (b) Find the sum of the first 20 terms. (c) Find the least positive integer n for which the sum of the first n terms exceeds 1000.',
  'Арифметическая прогрессия имеет первый член 5 и разность 3. (a) Найдите 20-й член. (b) Найдите сумму первых 20 членов. (c) Найдите наименьшее положительное целое n, при котором сумма первых n членов превышает 1000.',
  'Arifmetik progressiyaning birinchi hadi 5 va ayirmasi 3. (a) 20-hadni toping. (b) Birinchi 20 had yig‘indisini toping. (c) Birinchi n had yig‘indisi 1000 dan katta bo‘ladigan eng kichik musbat butun n ni toping.',
  '{"max_marks":7,"criteria":[{"id":"nth_term","marks":1,"rule":"Uses u_n=5+3(n-1)."},{"id":"term20","marks":1,"rule":"Gets u_20=62."},{"id":"sum_formula","marks":1,"rule":"Gets S_n=n(3n+7)/2 or equivalent."},{"id":"sum20","marks":1,"rule":"Gets S_20=670."},{"id":"inequality","marks":1,"rule":"Forms n(3n+7)/2>1000."},{"id":"boundary","marks":1,"rule":"Checks S_24=948 and S_25=1025, or an equivalent exact boundary check."},{"id":"least_n","marks":1,"rule":"States n=25."}]}'::jsonb,
  'For the least integer, use the exact sum inequality and verify the adjacent integer boundary.',
  'Для наименьшего целого используйте точное неравенство для суммы и проверьте соседние целые значения.',
  'Eng kichik butun son uchun yig‘indi tengsizligini aniq ishlating va qo‘shni butun qiymatlarni tekshiring.'
),
(
  'P1FP03-Q07','P1-DIF-04',array['P1-DIF-02','P1-DIF-03']::text[],
  'For y=x^3-6x^2+9x+4: (a) find the stationary points; (b) classify each stationary point; (c) find the equation of the tangent at x=2.',
  'Для y=x^3-6x^2+9x+4: (a) найдите стационарные точки; (b) классифицируйте каждую; (c) найдите уравнение касательной при x=2.',
  'y=x^3-6x^2+9x+4 uchun: (a) statsionar nuqtalarni toping; (b) har birini tasniflang; (c) x=2 dagi urinma tenglamasini toping.',
  '{"max_marks":8,"criteria":[{"id":"derivative","marks":1,"rule":"Gets dy/dx=3x^2-12x+9."},{"id":"factor","marks":1,"rule":"Factors derivative as 3(x-1)(x-3)."},{"id":"stationary_x","marks":1,"rule":"Gets x=1 and x=3."},{"id":"stationary_points","marks":1,"rule":"Gets (1,8) and (3,4)."},{"id":"second_derivative","marks":1,"rule":"Uses d2y/dx2=6x-12."},{"id":"classification","marks":1,"rule":"Classifies (1,8) as maximum and (3,4) as minimum."},{"id":"tangent_gradient","marks":1,"rule":"Gets gradient -3 at x=2 and point (2,6)."},{"id":"tangent","marks":1,"rule":"Gets y=-3x+12."}]}'::jsonb,
  'Factor the derivative before classifying; use the actual curve point together with the derivative value for the tangent.',
  'Сначала разложите производную на множители; для касательной используйте и точку кривой, и значение производной.',
  'Avval hosilani ko‘paytuvchilarga ajrating; urinma uchun egri chiziqdagi nuqta va hosila qiymatidan foydalaning.'
),
(
  'P1FP03-Q08','P1-DIF-07',array['P1-DIF-05']::text[],
  'The upper corners of a rectangle lie on the parabola y=12-x^2 and the lower corners lie on the x-axis, symmetrically about the y-axis. Let the upper-right corner be (x,12-x^2), where x>0. (a) Show that the area is A=24x-2x^3. (b) Find the dimensions of the rectangle of maximum area and the maximum area.',
  'Верхние вершины прямоугольника лежат на параболе y=12-x^2, нижние — на оси x, симметрично относительно оси y. Пусть верхняя правая вершина имеет координаты (x,12-x^2), x>0. (a) Покажите, что площадь A=24x-2x^3. (b) Найдите размеры прямоугольника максимальной площади и эту площадь.',
  'To‘g‘ri to‘rtburchakning yuqori uchlari y=12-x^2 parabolada, pastki uchlari x o‘qida va y o‘qiga nisbatan simmetrik joylashgan. Yuqori o‘ng uch (x,12-x^2), x>0 bo‘lsin. (a) Yuza A=24x-2x^3 ekanini ko‘rsating. (b) Eng katta yuzali to‘g‘ri to‘rtburchak o‘lchamlarini va maksimal yuzani toping.',
  '{"max_marks":8,"criteria":[{"id":"width","marks":1,"rule":"Uses rectangle width 2x."},{"id":"height","marks":1,"rule":"Uses height 12-x^2 and obtains A=24x-2x^3."},{"id":"derivative","marks":1,"rule":"Gets dA/dx=24-6x^2."},{"id":"stationary","marks":1,"rule":"Gets x=2 in the physical domain."},{"id":"maximum_check","marks":1,"rule":"Shows d2A/dx2=-12x<0 at x=2 or equivalent maximum argument."},{"id":"dimensions","marks":2,"rule":"Gets width 4 and height 8."},{"id":"max_area","marks":1,"rule":"Gets maximum area 32 square units."}]}'::jsonb,
  'Translate the geometry into width and height first, then optimize only within the physical domain.',
  'Сначала выразите ширину и высоту через геометрию, затем оптимизируйте только на физически допустимой области.',
  'Avval geometriyadan eni va bo‘yini ifodalang, keyin faqat fizik ma’noga ega sohada optimallashtiring.'
),
(
  'P1FP03-Q09','P1-INT-04',array['P1-INT-02']::text[],
  'The curve y=3x^2-4x+1 is considered for 0<=x<=2. Find the total area between the curve and the x-axis over this interval.',
  'Рассматривается кривая y=3x^2-4x+1 на 0<=x<=2. Найдите полную площадь между кривой и осью x на этом интервале.',
  '0<=x<=2 oraliqda y=3x^2-4x+1 egri chiziq berilgan. Shu intervalda egri chiziq bilan x o‘qi orasidagi umumiy yuzani toping.',
  '{"max_marks":8,"criteria":[{"id":"roots","marks":2,"rule":"Finds x=1/3 and x=1 as the sign-change points."},{"id":"primitive","marks":1,"rule":"Uses antiderivative x^3-2x^2+x."},{"id":"sign_split","marks":1,"rule":"Splits the area at both roots and treats the middle integral by absolute value."},{"id":"first_area","marks":1,"rule":"Gets area 4/27 on [0,1/3]."},{"id":"middle_area","marks":1,"rule":"Gets area 4/27 on [1/3,1]."},{"id":"last_area","marks":1,"rule":"Gets area 2 on [1,2]."},{"id":"total","marks":1,"rule":"Gets total area 62/27."}]}'::jsonb,
  'For geometric area, find every x-axis crossing first and take absolute contributions on intervals where the curve is below the axis.',
  'Для геометрической площади сначала найдите все пересечения с осью x и берите модули вкладов там, где кривая ниже оси.',
  'Geometrik yuza uchun avval x o‘qi bilan barcha kesishishlarni toping va egri chiziq o‘qdan past bo‘lgan qismlarda integral modulini oling.'
),
(
  'P1FP03-Q10','P1-INT-05',array['P1-INT-01','P1-DIF-01']::text[],
  'A curve has gradient dy/dx=6x^2-4x-2 and passes through (1,3). (a) Find its equation. (b) Find and classify its stationary points. (c) Find the area between the curve, the x-axis, x=0 and x=1.',
  'Кривая имеет градиент dy/dx=6x^2-4x-2 и проходит через (1,3). (a) Найдите её уравнение. (b) Найдите и классифицируйте стационарные точки. (c) Найдите площадь между кривой, осью x и прямыми x=0 и x=1.',
  'Egri chiziqning gradienti dy/dx=6x^2-4x-2 bo‘lib, u (1,3) nuqtadan o‘tadi. (a) Uning tenglamasini toping. (b) Statsionar nuqtalarni topib tasniflang. (c) Egri chiziq, x o‘qi, x=0 va x=1 orasidagi yuzani toping.',
  '{"max_marks":8,"criteria":[{"id":"integrate","marks":1,"rule":"Integrates to y=2x^3-2x^2-2x+C."},{"id":"constant","marks":1,"rule":"Uses (1,3) to get C=5."},{"id":"equation","marks":1,"rule":"States y=2x^3-2x^2-2x+5."},{"id":"stationary_x","marks":1,"rule":"Solves 6x^2-4x-2=0 to get x=-1/3 and x=1."},{"id":"stationary_coords","marks":1,"rule":"Gets (-1/3,145/27) and (1,3)."},{"id":"classification","marks":1,"rule":"Uses d2y/dx2=12x-4 to classify the first as maximum and the second as minimum."},{"id":"area_setup","marks":1,"rule":"Integrates the positive curve from 0 to 1."},{"id":"area","marks":1,"rule":"Gets area 23/6."}]}'::jsonb,
  'Recover the curve with the integration constant first; then use the original gradient for stationary points and a second integration for area.',
  'Сначала восстановите кривую с постоянной интегрирования; затем используйте исходный градиент для стационарных точек и ещё одно интегрирование для площади.',
  'Avval integrallash doimiysi bilan egri chiziqni tiklang; so‘ng statsionar nuqtalar uchun berilgan gradientdan va yuza uchun yana integraldan foydalaning.'
)
)
insert into private.exam_prep_written_tasks(
  content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
  prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
  lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select cv.id,d.task_key,'P1',d.primary_skill,d.secondary_skills,'wtv1',
       d.prompt_en,d.prompt_ru,d.prompt_uz,d.rubric,d.self_en,d.self_ru,d.self_uz,
       'published','pass','pass','pass','pass',now()
from cv cross join defs d
on conflict(content_version_id,task_key,task_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_stage4_full_paper_03_v1' and component_code='P1' and status='draft'
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
  title_en,title_ru,title_uz,approved_at
)
select cv.id,'p1_stage4_full_paper_03','av1','P1','paper','approved',
       'P1 Stage 4 full paper 03 (pre-positioned)','P1 Stage 4 full paper 03 (pre-positioned)','P1 Stage 4 full paper 03 (pre-positioned)',now()
from cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions where content_version='p1_stage4_full_paper_03_v1'
), a as (
  select a.id from private.exam_prep_assessments a join cv on cv.id=a.content_version_id
  where a.assessment_key='p1_stage4_full_paper_03' and a.assessment_version='av1'
), items(item_order,task_key,skill) as (values
  (1,'P1FP03-Q01','P1-QUA-03'),
  (2,'P1FP03-Q02','P1-FUN-06'),
  (3,'P1FP03-Q03','P1-COO-04'),
  (4,'P1FP03-Q04','P1-CIR-03'),
  (5,'P1FP03-Q05','P1-TRI-05'),
  (6,'P1FP03-Q06','P1-SER-03'),
  (7,'P1FP03-Q07','P1-DIF-04'),
  (8,'P1FP03-Q08','P1-DIF-07'),
  (9,'P1FP03-Q09','P1-INT-04'),
  (10,'P1FP03-Q10','P1-INT-05')
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
  where assessment_key='p1_stage4_full_paper_03' and assessment_version='av1'
), marks(item_order,max_marks) as (values
  (1::smallint,7::smallint),(2::smallint,7::smallint),(3::smallint,8::smallint),(4::smallint,6::smallint),
  (5::smallint,8::smallint),(6::smallint,7::smallint),(7::smallint,8::smallint),(8::smallint,8::smallint),
  (9::smallint,8::smallint),(10::smallint,8::smallint)
)
insert into private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks)
select a.id,m.item_order,m.max_marks from a cross join marks m
on conflict(assessment_id,item_order) do nothing;

update private.exam_prep_content_versions
set status='published',approved_at=coalesce(approved_at,now()),published_at=coalesce(published_at,now())
where content_version='p1_stage4_full_paper_03_v1' and status='draft';

do $$
declare
  v_ass bigint; v_tasks int; v_items int; v_marks int; v_rubric_marks int; v_sections int; v_profile bigint;
  v_cfg private.exam_prep_feature_config%rowtype; v_active int;
begin
  select id into v_ass from private.exam_prep_assessments
  where assessment_key='p1_stage4_full_paper_03' and assessment_version='av1' and status='approved';
  if v_ass is null then raise exception 'P1-03 P1 Paper03 approved assessment missing'; end if;
  select count(*) into v_tasks from private.exam_prep_assessment_items ai
  join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
  where ai.assessment_id=v_ass and ai.question_id is null and ai.reserve_role='written'
    and wt.lifecycle_state='published' and wt.copyright_status='pass'
    and wt.qa_math_status='pass' and wt.qa_language_status='pass' and wt.qa_technical_status='pass';
  if v_tasks<>10 then raise exception 'P1-03 P1 Paper03 written tasks=%',v_tasks; end if;
  select count(*),coalesce(sum(max_marks),0) into v_items,v_marks from private.exam_prep_timed_assessment_items where assessment_id=v_ass;
  if v_items<>10 or v_marks<>75 then raise exception 'P1-03 P1 Paper03 marks items=% marks=%',v_items,v_marks; end if;
  select coalesce(sum((wt.rubric_json->>'max_marks')::int),0) into v_rubric_marks
  from private.exam_prep_assessment_items ai join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id where ai.assessment_id=v_ass;
  if v_rubric_marks<>75 then raise exception 'P1-03 P1 Paper03 rubric marks=%',v_rubric_marks; end if;
  select count(distinct sn.official_syllabus_section) into v_sections
  from private.exam_prep_assessment_items ai
  join private.exam_prep_syllabus_nodes sn on sn.skill_code=ai.primary_skill_code and sn.component_code='P1'
  join private.exam_prep_content_versions cv on cv.id=(select content_version_id from private.exam_prep_assessments where id=v_ass)
  where ai.assessment_id=v_ass and sn.program_version_id=cv.program_version_id;
  if v_sections<>8 then raise exception 'P1-03 P1 Paper03 syllabus breadth sections=%',v_sections; end if;
  select id into v_profile from private.exam_prep_component_paper_profiles
  where component_code='P1' and profile_version='9709_2026_2027_v1' and status='published';
  if v_profile is null or private.exam_prep_timed_time_limit_v1(v_profile,'official_full',75,null)<>6600 then
    raise exception 'P1-03 P1 Paper03 official profile/timing missing';
  end if;
  if exists(select 1 from private.exam_prep_timed_assessment_contracts where assessment_id=v_ass) then raise exception 'P1-03 P1 Paper03 timed contract must not exist'; end if;
  if exists(select 1 from private.exam_prep_assessments where id=v_ass and status='published') then raise exception 'P1-03 P1 Paper03 must remain approved/not published'; end if;
  if exists(select 1 from public.questions q where q.book_ref like 'ExamPrep:%p1_stage4_full_paper_03%') then raise exception 'P1-03 P1 Paper03 legacy question residue'; end if;
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then raise exception 'P1-03 P1 Paper03 requires fail-closed feature state'; end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 P1 Paper03 active entitlement residue=%',v_active; end if;
end $$;

commit;
