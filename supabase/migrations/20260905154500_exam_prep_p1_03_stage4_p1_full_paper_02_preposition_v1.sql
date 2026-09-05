-- P1-03 pre-live depth: pre-position second governed P1 full-paper form for later Stage-4 release.
-- 75 marks / 110 minutes under the existing Cambridge 9709 P1 profile once released.
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
select pv.id,'p1_stage4_full_paper_02_v1','P1','P1 Stage-4 full paper 02 pre-position','draft',
       'Original iClub-authored full-paper practice content. Cambridge 9709 2026-2027 official syllabus/profile defines scope, marks and timing only; no protected question wording copied. Assessment intentionally remains approved/not published until a later Stage-4 release.'
from pv
on conflict(program_version_id,content_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_stage4_full_paper_02_v1' and component_code='P1' and status='draft'
), defs(task_key,primary_skill,secondary_skills,prompt_en,prompt_ru,prompt_uz,rubric,self_en,self_ru,self_uz) as (values
(
  'P1FP02-Q01','P1-QUA-05',array['P1-QUA-03']::text[],
  'The line y=3x-2 intersects the curve y=x^2-x-6. Find the exact coordinates of both points of intersection.',
  'Прямая y=3x-2 пересекает кривую y=x^2-x-6. Найдите точные координаты обеих точек пересечения.',
  'y=3x-2 to‘g‘ri chiziq y=x^2-x-6 egri chiziqni kesadi. Ikkala kesishish nuqtasining aniq koordinatalarini toping.',
  '{"max_marks":6,"criteria":[{"id":"equate","marks":1,"rule":"Equates x^2-x-6=3x-2."},{"id":"quadratic","marks":1,"rule":"Obtains x^2-4x-4=0."},{"id":"x_formula","marks":1,"rule":"Uses the quadratic formula or completed square correctly."},{"id":"x_values","marks":1,"rule":"Gets x=2±2sqrt(2)."},{"id":"y_values","marks":1,"rule":"Gets y=4±6sqrt(2) with matching signs."},{"id":"coordinates","marks":1,"rule":"States both ordered pairs correctly."}]}'::jsonb,
  'For a line–quadratic system, eliminate one variable first and keep exact surd values until both coordinates are matched.',
  'В системе «прямая–квадратичная кривая» сначала исключите одну переменную и сохраняйте точные значения с корнями до получения обеих координат.',
  'Chiziq va kvadrat egri chiziq sistemasida avval bitta o‘zgaruvchini yo‘qoting va ikkala koordinata topilguncha ildizli aniq qiymatlarni saqlang.'
),
(
  'P1FP02-Q02','P1-FUN-08',array['P1-FUN-06','P1-FUN-02']::text[],
  'The graph y=f(x) has minimum point B(1,-1) and also passes through A(-2,5). Define g(x)=3f(2x-4)+1. (a) Describe the transformations from y=f(x) to y=g(x). (b) Find the images of A and B on y=g(x). (c) Hence state the minimum value of g and the x-coordinate where it occurs.',
  'График y=f(x) имеет точку минимума B(1,-1) и проходит через A(-2,5). Задано g(x)=3f(2x-4)+1. (a) Опишите преобразования графика y=f(x) в y=g(x). (b) Найдите образы точек A и B на y=g(x). (c) Укажите минимальное значение g и x-координату, при которой оно достигается.',
  'y=f(x) grafigining minimum nuqtasi B(1,-1) bo‘lib, u A(-2,5) nuqtadan ham o‘tadi. g(x)=3f(2x-4)+1. (a) y=f(x) dan y=g(x) ga o‘tishdagi o‘zgarishlarni tasvirlang. (b) A va B nuqtalarning y=g(x) dagi obrazlarini toping. (c) g ning minimum qiymati va u erishiladigan x koordinatani ayting.',
  '{"max_marks":7,"criteria":[{"id":"inside_form","marks":1,"rule":"Recognises 2x-4=2(x-2)."},{"id":"horizontal","marks":1,"rule":"States horizontal scale factor 1/2 followed by translation 2 units right, or equivalent point mapping."},{"id":"vertical","marks":1,"rule":"States vertical stretch factor 3 followed by translation 1 unit up."},{"id":"mapping","marks":1,"rule":"Uses point mapping (a,b)->((a+4)/2,3b+1)."},{"id":"map_a","marks":1,"rule":"Maps A(-2,5) to (1,16)."},{"id":"map_b","marks":1,"rule":"Maps B(1,-1) to (5/2,-2)."},{"id":"minimum","marks":1,"rule":"States minimum g=-2 at x=5/2."}]}'::jsonb,
  'For combined transformations, derive the point mapping from the function argument and output rather than relying only on verbal order.',
  'Для сочетания преобразований выведите отображение точки из аргумента и значения функции, а не полагайтесь только на словесный порядок.',
  'Bir nechta transformatsiyada faqat so‘zli tartibga tayanmang; argument va funksiya qiymatidan nuqta akslantirishini chiqaring.'
),
(
  'P1FP02-Q03','P1-COO-06',array['P1-COO-04','P1-QUA-02']::text[],
  'The line y=mx+13 is tangent to the circle x^2+y^2=25. (a) By substituting the line into the circle, find all possible values of m. (b) For m=12/5, find the exact coordinates of the point of tangency.',
  'Прямая y=mx+13 касается окружности x^2+y^2=25. (a) Подставив уравнение прямой в уравнение окружности, найдите все возможные значения m. (b) При m=12/5 найдите точные координаты точки касания.',
  'y=mx+13 chiziq x^2+y^2=25 aylanaga urinadi. (a) Chiziq tenglamasini aylana tenglamasiga qo‘yib, m ning barcha mumkin qiymatlarini toping. (b) m=12/5 bo‘lganda urinma nuqtasining aniq koordinatalarini toping.',
  '{"max_marks":7,"criteria":[{"id":"substitute","marks":1,"rule":"Gets (1+m^2)x^2+26mx+144=0."},{"id":"tangent_condition","marks":1,"rule":"Uses discriminant=0 for tangency."},{"id":"disc","marks":1,"rule":"Simplifies to 100m^2-576=0."},{"id":"m_values","marks":1,"rule":"Gets m=±12/5."},{"id":"repeated_root","marks":1,"rule":"For m=12/5 uses the repeated-root formula x=-b/(2a)."},{"id":"x_coord","marks":1,"rule":"Gets x=-60/13."},{"id":"y_coord","marks":1,"rule":"Gets y=25/13."}]}'::jsonb,
  'A tangent produces a repeated intersection root; use the discriminant first, then recover the repeated root and substitute back into the line.',
  'Касание даёт кратный корень уравнения пересечения; сначала используйте дискриминант, затем найдите кратный корень и подставьте его в уравнение прямой.',
  'Urinish kesishish tenglamasida takroriy ildiz beradi; avval diskriminantdan foydalaning, so‘ng takroriy ildizni topib chiziqqa qo‘ying.'
),
(
  'P1FP02-Q04','P1-CIR-02',array['P1-CIR-03']::text[],
  'A sector has arc length 10 cm and perimeter 26 cm. Find (a) the radius, (b) the angle in radians, and (c) the area of the sector.',
  'Сектор имеет длину дуги 10 см и периметр 26 см. Найдите (a) радиус, (b) угол в радианах и (c) площадь сектора.',
  'Sektor yoyining uzunligi 10 cm, perimetri 26 cm. (a) Radiusni, (b) radianlardagi burchakni va (c) sektor yuzini toping.',
  '{"max_marks":6,"criteria":[{"id":"perimeter","marks":1,"rule":"Uses 2r+10=26."},{"id":"radius","marks":1,"rule":"Gets r=8 cm."},{"id":"arc_relation","marks":1,"rule":"Uses s=r theta."},{"id":"theta","marks":1,"rule":"Gets theta=5/4 radians."},{"id":"area_setup","marks":1,"rule":"Uses A=(1/2)r^2 theta or A=(1/2)rs."},{"id":"area","marks":1,"rule":"Gets 40 cm^2."}]}'::jsonb,
  'The sector perimeter contains two radii plus the arc; once r is known, use radians consistently in s=r theta and the sector-area formula.',
  'Периметр сектора состоит из двух радиусов и дуги; после нахождения r последовательно используйте радианы в формулах s=r theta и площади сектора.',
  'Sektor perimetri ikki radius va yoydan iborat; r topilgach, s=r theta va yuza formulalarida radianlardan izchil foydalaning.'
),
(
  'P1FP02-Q05','P1-TRI-04',array['P1-TRI-05','P1-TRI-02']::text[],
  'For 0<=x<=2pi: (a) derive the identity cos(2x)=1-2sin^2(x); (b) solve cos(2x)=sin(x), giving every solution in the interval.',
  'Для 0<=x<=2pi: (a) выведите тождество cos(2x)=1-2sin^2(x); (b) решите cos(2x)=sin(x), указав все решения на интервале.',
  '0<=x<=2pi uchun: (a) cos(2x)=1-2sin^2(x) ayniyatini keltirib chiqaring; (b) cos(2x)=sin(x) tenglamani intervaldagi barcha yechimlari bilan yeching.',
  '{"max_marks":8,"criteria":[{"id":"double_angle_start","marks":1,"rule":"Uses cos(2x)=cos^2 x-sin^2 x or equivalent."},{"id":"identity_sub","marks":1,"rule":"Uses cos^2 x=1-sin^2 x."},{"id":"identity","marks":1,"rule":"Obtains cos(2x)=1-2sin^2 x."},{"id":"quadratic","marks":1,"rule":"Forms 2sin^2 x+sin x-1=0."},{"id":"factor","marks":1,"rule":"Factors as (2sin x-1)(sin x+1)=0."},{"id":"branches","marks":1,"rule":"Gets sin x=1/2 or sin x=-1."},{"id":"half_solutions","marks":1,"rule":"Gets x=pi/6 and 5pi/6."},{"id":"minus_one_solution","marks":1,"rule":"Gets x=3pi/2 and no extra solutions."}]}'::jsonb,
  'Use the identity to turn the equation into an algebraic equation in one trig function, then solve each valid branch over the whole interval.',
  'Используйте тождество, чтобы получить алгебраическое уравнение относительно одной тригонометрической функции, затем решите каждую допустимую ветвь на всём интервале.',
  'Ayniyat yordamida tenglamani bitta trigonometrik funksiya bo‘yicha algebraik tenglamaga aylantiring, so‘ng har bir mumkin tarmoqni butun intervalda yeching.'
),
(
  'P1FP02-Q06','P1-SER-04',array['P1-SER-05']::text[],
  'A geometric progression has first term 81 and common ratio 2/3. (a) Find the fifth term. (b) Find the sum of the first n terms. (c) Find the sum to infinity. (d) Find the least positive integer n for which the sum of the first n terms exceeds 235.',
  'Геометрическая прогрессия имеет первый член 81 и знаменатель 2/3. (a) Найдите пятый член. (b) Найдите сумму первых n членов. (c) Найдите сумму до бесконечности. (d) Найдите наименьшее положительное целое n, при котором сумма первых n членов превышает 235.',
  'Geometrik progressiyaning birinchi hadi 81, maxraji 2/3. (a) Beshinchi hadni toping. (b) Birinchi n had yig‘indisini toping. (c) Cheksiz yig‘indini toping. (d) Birinchi n had yig‘indisi 235 dan katta bo‘ladigan eng kichik musbat butun n ni toping.',
  '{"max_marks":8,"criteria":[{"id":"fifth_setup","marks":1,"rule":"Uses 81(2/3)^4."},{"id":"fifth","marks":1,"rule":"Gets fifth term 16."},{"id":"sn_formula","marks":1,"rule":"Uses a(1-r^n)/(1-r)."},{"id":"sn","marks":1,"rule":"Gets S_n=243[1-(2/3)^n]."},{"id":"infinity","marks":1,"rule":"Gets S_infinity=243."},{"id":"inequality","marks":1,"rule":"Reduces S_n>235 to (2/3)^n<8/243."},{"id":"boundary_check","marks":1,"rule":"Checks n=8 does not satisfy and n=9 does satisfy, or equivalent log/boundary work."},{"id":"least_n","marks":1,"rule":"States least n=9."}]}'::jsonb,
  'For an inverse finite-sum question, isolate r^n and verify the integer boundary; do not round n before checking the inequality.',
  'В обратной задаче на конечную сумму выделите r^n и проверьте соседние целые значения; не округляйте n до проверки неравенства.',
  'Teskari chekli yig‘indi masalasida r^n ni ajrating va qo‘shni butun qiymatlarni tekshiring; tengsizlikni tekshirmasdan n ni yaxlitlamang.'
),
(
  'P1FP02-Q07','P1-DIF-04',array['P1-DIF-03']::text[],
  'The curve is y=(2x-1)^4+3x. At the point where x=1: (a) find dy/dx; (b) find the equation of the tangent; (c) find the equation of the normal; (d) find where the normal meets the y-axis.',
  'Кривая задана y=(2x-1)^4+3x. В точке с x=1: (a) найдите dy/dx; (b) найдите уравнение касательной; (c) найдите уравнение нормали; (d) найдите точку пересечения нормали с осью y.',
  'Egri chiziq y=(2x-1)^4+3x bilan berilgan. x=1 bo‘lgan nuqtada: (a) dy/dx ni toping; (b) urinma tenglamasini; (c) normal tenglamasini; (d) normalning y-o‘q bilan kesishish nuqtasini toping.',
  '{"max_marks":8,"criteria":[{"id":"chain","marks":2,"rule":"Gets dy/dx=8(2x-1)^3+3 with correct chain factor."},{"id":"point","marks":1,"rule":"Gets point (1,4)."},{"id":"tangent_gradient","marks":1,"rule":"Gets tangent gradient 11."},{"id":"tangent","marks":1,"rule":"Gets y-4=11(x-1)."},{"id":"normal_gradient","marks":1,"rule":"Gets normal gradient -1/11."},{"id":"normal","marks":1,"rule":"Gets y-4=-(x-1)/11."},{"id":"intercept","marks":1,"rule":"Gets y-axis intercept (0,45/11)."}]}'::jsonb,
  'Differentiate the composite power with the chain rule before evaluating the gradient; the normal gradient is the negative reciprocal of a non-zero tangent gradient.',
  'Сначала продифференцируйте составную степень по правилу цепочки; градиент нормали равен отрицательному обратному ненулевого градиента касательной.',
  'Murakkab darajani avval zanjir qoidasi bilan differensiallang; normal gradienti noldan farqli urinma gradientining manfiy teskari qiymatidir.'
),
(
  'P1FP02-Q08','P1-DIF-05',array['P1-DIF-07']::text[],
  'For y=x^3-6x^2+9x+2: (a) find the stationary points; (b) determine the intervals on which the curve is increasing and decreasing; (c) state the nature of each stationary point.',
  'Для y=x^3-6x^2+9x+2: (a) найдите стационарные точки; (b) определите интервалы возрастания и убывания; (c) укажите характер каждой стационарной точки.',
  'y=x^3-6x^2+9x+2 uchun: (a) statsionar nuqtalarni toping; (b) egri chiziq o‘suvchi va kamayuvchi intervallarni aniqlang; (c) har bir statsionar nuqtaning turini ayting.',
  '{"max_marks":7,"criteria":[{"id":"derivative","marks":1,"rule":"Gets dy/dx=3x^2-12x+9."},{"id":"factor","marks":1,"rule":"Factors as 3(x-1)(x-3)."},{"id":"stationary_x","marks":1,"rule":"Gets x=1 and x=3."},{"id":"stationary_y","marks":1,"rule":"Gets points (1,6) and (3,2)."},{"id":"increasing","marks":1,"rule":"States increasing for x<1 and x>3."},{"id":"decreasing","marks":1,"rule":"States decreasing for 1<x<3."},{"id":"nature","marks":1,"rule":"Identifies (1,6) as local maximum and (3,2) as local minimum."}]}'::jsonb,
  'Use the factorised derivative to build a sign chart; the sign change determines both monotonic intervals and stationary-point nature.',
  'Используйте разложенную на множители производную для таблицы знаков; смена знака определяет интервалы монотонности и характер стационарных точек.',
  'Ko‘paytuvchilarga ajratilgan hosiladan ishora jadvali tuzing; ishora almashishi monotonlik intervallari va statsionar nuqta turini belgilaydi.'
),
(
  'P1FP02-Q09','P1-INT-02',array['P1-INT-04']::text[],
  'A curve passes through the origin and has dy/dx=6x^2-6x+1. (a) Find its equation. (b) Find all x-coordinates where it meets the x-axis. (c) Find the total area between the curve and the x-axis for 0<=x<=1.',
  'Кривая проходит через начало координат и имеет dy/dx=6x^2-6x+1. (a) Найдите её уравнение. (b) Найдите все x-координаты пересечения с осью x. (c) Найдите общую площадь между кривой и осью x при 0<=x<=1.',
  'Egri chiziq koordinatalar boshidan o‘tadi va dy/dx=6x^2-6x+1. (a) Uning tenglamasini toping. (b) x-o‘q bilan barcha kesishishlarning x koordinatalarini toping. (c) 0<=x<=1 da egri chiziq bilan x-o‘q orasidagi umumiy yuzani toping.',
  '{"max_marks":9,"criteria":[{"id":"integrate","marks":2,"rule":"Integrates to y=2x^3-3x^2+x+C."},{"id":"constant","marks":1,"rule":"Uses the origin to get C=0."},{"id":"factor","marks":1,"rule":"Factors y=x(2x-1)(x-1)."},{"id":"roots","marks":1,"rule":"Gets x=0,1/2,1."},{"id":"area_primitive","marks":1,"rule":"Uses an antiderivative F(x)=x^4/2-x^3+x^2/2."},{"id":"split","marks":1,"rule":"Splits the area at x=1/2 because the curve changes sign."},{"id":"half_area","marks":1,"rule":"Gets magnitude 1/32 on each half interval."},{"id":"total_area","marks":1,"rule":"Gets total area 1/16."}]}'::jsonb,
  'After finding the integration constant, locate all sign changes before computing geometric area; definite integral and total area are not always the same.',
  'После нахождения постоянной интегрирования найдите все смены знака перед вычислением геометрической площади; определённый интеграл и общая площадь не всегда совпадают.',
  'Integrallash doimiysini topgach, geometrik yuzani hisoblashdan oldin barcha ishora almashishlarini toping; aniq integral va umumiy yuza har doim bir xil emas.'
),
(
  'P1FP02-Q10','P1-INT-03',array['P1-INT-01']::text[],
  '(a) Evaluate integral from 1 to 3 of (2x-1)^3 dx. (b) Evaluate the improper-endpoint integral from 0 to 9 of x^(-1/2) dx, showing the limiting step. (c) Find a>0 such that the integral from 0 to a of x^(-1/2) dx equals 10.',
  '(a) Вычислите интеграл от 1 до 3 от (2x-1)^3 dx. (b) Вычислите интеграл с несобственной нижней границей от 0 до 9 от x^(-1/2) dx, показав предельный переход. (c) Найдите a>0, если интеграл от 0 до a от x^(-1/2) dx равен 10.',
  '(a) 1 dan 3 gacha (2x-1)^3 dx integralini hisoblang. (b) 0 dan 9 gacha x^(-1/2) dx integralini pastki chegaradagi limitni ko‘rsatib hisoblang. (c) 0 dan a gacha x^(-1/2) dx integrali 10 ga teng bo‘lsa, a>0 ni toping.',
  '{"max_marks":9,"criteria":[{"id":"first_primitive","marks":2,"rule":"Uses antiderivative (2x-1)^4/8."},{"id":"first_value","marks":1,"rule":"Gets (625-1)/8=78."},{"id":"limit_setup","marks":1,"rule":"Writes the second integral as a limit from epsilon to 9 with epsilon->0+."},{"id":"sqrt_primitive","marks":1,"rule":"Uses antiderivative 2sqrt(x)."},{"id":"convergence","marks":1,"rule":"Shows the epsilon term tends to 0, so the endpoint integral converges."},{"id":"second_value","marks":1,"rule":"Gets value 6."},{"id":"inverse_equation","marks":1,"rule":"Uses 2sqrt(a)=10."},{"id":"a_value","marks":1,"rule":"Gets a=25."}]}'::jsonb,
  'For the x^(-1/2) endpoint, use a positive lower limit first and then take the limit; do not substitute x=0 before establishing convergence.',
  'Для границы x=0 у x^(-1/2) сначала используйте положительную нижнюю границу и затем переходите к пределу; не подставляйте x=0 до проверки сходимости.',
  'x^(-1/2) uchun x=0 chegarada avval musbat pastki chegaradan foydalanib, keyin limitga o‘ting; yaqinlashuvni tekshirmasdan x=0 ni bevosita qo‘ymang.'
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
  where content_version='p1_stage4_full_paper_02_v1' and component_code='P1' and status='draft'
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
  title_en,title_ru,title_uz,approved_at
)
select cv.id,'p1_stage4_full_paper_02','av1','P1','paper','approved',
       'P1 Stage 4 full paper 02 (pre-positioned)','P1 Stage 4: full paper 02 (pre-positioned)','P1 Stage 4 full paper 02 (pre-positioned)',now()
from cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions where content_version='p1_stage4_full_paper_02_v1'
), a as (
  select a.id from private.exam_prep_assessments a join cv on cv.id=a.content_version_id
  where a.assessment_key='p1_stage4_full_paper_02' and a.assessment_version='av1'
), items(item_order,task_key,skill) as (values
  (1,'P1FP02-Q01','P1-QUA-05'),
  (2,'P1FP02-Q02','P1-FUN-08'),
  (3,'P1FP02-Q03','P1-COO-06'),
  (4,'P1FP02-Q04','P1-CIR-02'),
  (5,'P1FP02-Q05','P1-TRI-04'),
  (6,'P1FP02-Q06','P1-SER-04'),
  (7,'P1FP02-Q07','P1-DIF-04'),
  (8,'P1FP02-Q08','P1-DIF-05'),
  (9,'P1FP02-Q09','P1-INT-02'),
  (10,'P1FP02-Q10','P1-INT-03')
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
  where assessment_key='p1_stage4_full_paper_02' and assessment_version='av1'
), marks(item_order,max_marks) as (values
  (1::smallint,6::smallint),(2::smallint,7::smallint),(3::smallint,7::smallint),(4::smallint,6::smallint),
  (5::smallint,8::smallint),(6::smallint,8::smallint),(7::smallint,8::smallint),(8::smallint,7::smallint),
  (9::smallint,9::smallint),(10::smallint,9::smallint)
)
insert into private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks)
select a.id,m.item_order,m.max_marks from a cross join marks m
on conflict(assessment_id,item_order) do nothing;

-- Publish governed written content, but intentionally keep the assessment approved/not published.
update private.exam_prep_content_versions
set status='published',approved_at=coalesce(approved_at,now()),published_at=coalesce(published_at,now())
where content_version='p1_stage4_full_paper_02_v1' and status='draft';

-- Acceptance: complete 75-mark form is pre-positioned, covers all P1 sections, and remains invisible to timed catalog.
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
  where assessment_key='p1_stage4_full_paper_02' and assessment_version='av1' and status='approved';
  if v_ass is null then raise exception 'P1-03 P1 Paper02 approved assessment missing'; end if;

  select count(*) into v_tasks
  from private.exam_prep_assessment_items ai
  join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
  where ai.assessment_id=v_ass and ai.question_id is null and ai.reserve_role='written'
    and wt.lifecycle_state='published' and wt.copyright_status='pass'
    and wt.qa_math_status='pass' and wt.qa_language_status='pass' and wt.qa_technical_status='pass';
  if v_tasks<>10 then raise exception 'P1-03 P1 Paper02 written floor tasks=%',v_tasks; end if;

  select count(*),coalesce(sum(max_marks),0) into v_items,v_marks
  from private.exam_prep_timed_assessment_items where assessment_id=v_ass;
  if v_items<>10 or v_marks<>75 then raise exception 'P1-03 P1 Paper02 marks items=% marks=%',v_items,v_marks; end if;

  select coalesce(sum((wt.rubric_json->>'max_marks')::int),0) into v_rubric_marks
  from private.exam_prep_assessment_items ai join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
  where ai.assessment_id=v_ass;
  if v_rubric_marks<>75 then raise exception 'P1-03 P1 Paper02 rubric marks=%',v_rubric_marks; end if;

  select count(distinct sn.official_syllabus_section) into v_sections
  from private.exam_prep_assessment_items ai
  join private.exam_prep_syllabus_nodes sn on sn.skill_code=ai.primary_skill_code and sn.component_code='P1'
  join private.exam_prep_content_versions cv on cv.id=(select content_version_id from private.exam_prep_assessments where id=v_ass)
  where ai.assessment_id=v_ass and sn.program_version_id=cv.program_version_id;
  if v_sections<>8 then raise exception 'P1-03 P1 Paper02 syllabus breadth sections=%',v_sections; end if;

  select id into v_profile from private.exam_prep_component_paper_profiles
  where component_code='P1' and profile_version='9709_2026_2027_v1' and status='published';
  if v_profile is null or private.exam_prep_timed_time_limit_v1(v_profile,'official_full',75,null)<>6600 then
    raise exception 'P1-03 P1 Paper02 official profile/timing missing';
  end if;

  if exists(select 1 from private.exam_prep_timed_assessment_contracts where assessment_id=v_ass) then
    raise exception 'P1-03 P1 Paper02 must remain unreleased: timed contract exists';
  end if;
  if exists(select 1 from private.exam_prep_assessments where id=v_ass and status='published') then
    raise exception 'P1-03 P1 Paper02 must remain approved/not published';
  end if;
  if exists(select 1 from public.questions q where q.book_ref like 'ExamPrep:%p1_stage4_full_paper_02%') then
    raise exception 'P1-03 P1 Paper02 must not create public.questions rows';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 P1 Paper02 pre-position requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 P1 Paper02 active entitlement residue=%',v_active; end if;
  if exists(select 1 from private.exam_prep_sessions) or exists(select 1 from private.exam_prep_evidence_events) or exists(select 1 from private.exam_prep_timed_attempt_results) then
    raise exception 'P1-03 P1 Paper02 pre-position must not create learner runtime evidence';
  end if;
end $$;

commit;
