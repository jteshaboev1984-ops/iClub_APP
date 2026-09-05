-- P1-03 pre-live depth: first governed Stage-3 full P1 paper.
-- 75 marks / 110 minutes through the published Cambridge 9709 P1 paper profile.
-- Written-only, original iClub-authored content. No public.questions / legacy mutation.
begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active'
)
insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,'p1_stage3_full_paper_01_v1','P1','P1 Stage-3 full paper 01','draft',
       'Original iClub-authored full-paper practice content. Cambridge 9709 2026-2027 official syllabus/profile defines scope, marks and timing only; no protected question wording copied.'
from pv
on conflict(program_version_id,content_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_stage3_full_paper_01_v1' and component_code='P1' and status='draft'
), defs(task_key,primary_skill,secondary_skills,prompt_en,prompt_ru,prompt_uz,rubric,self_en,self_ru,self_uz) as (values
(
  'P1FP01-Q01','P1-QUA-02',array['P1-QUA-03']::text[],
  'The equation x^2-2(k+1)x+k^2-1=0 has real parameter k. (a) Find its discriminant in simplified form. (b) State the values of k for which the equation has two distinct real roots, one repeated real root, and no real roots. (c) Find the exact roots when k=3.',
  'Уравнение x^2-2(k+1)x+k^2-1=0 содержит действительный параметр k. (a) Найдите дискриминант в упрощённом виде. (b) Укажите значения k, при которых уравнение имеет два различных действительных корня, один кратный действительный корень и не имеет действительных корней. (c) Найдите точные корни при k=3.',
  'x^2-2(k+1)x+k^2-1=0 tenglamada k haqiqiy parametr. (a) Diskriminantni soddalashtirilgan ko‘rinishda toping. (b) Tenglama ikkita turli haqiqiy ildiz, bitta takroriy haqiqiy ildiz va haqiqiy ildizga ega bo‘lmaydigan k qiymatlarini ko‘rsating. (c) k=3 bo‘lganda aniq ildizlarni toping.',
  '{"max_marks":6,"criteria":[{"id":"disc_expand","marks":1,"rule":"Forms D=[-2(k+1)]^2-4(k^2-1)."},{"id":"disc_simplify","marks":1,"rule":"Gets D=8(k+1)."},{"id":"two_roots","marks":1,"rule":"States k>-1 for two distinct real roots."},{"id":"repeated","marks":1,"rule":"States k=-1 for a repeated real root, and hence k<-1 for no real roots."},{"id":"k3_setup","marks":1,"rule":"For k=3 obtains x^2-8x+8=0 or equivalent formula working."},{"id":"k3_roots","marks":1,"rule":"Gets x=4±2sqrt(2)."}]}'::jsonb,
  'For parameter root questions, reduce the sign of the discriminant to a simple inequality before substituting any special value of k.',
  'В задачах с параметром сначала сведите знак дискриминанта к простому неравенству и только затем подставляйте отдельное значение k.',
  'Parametrli ildiz masalalarida avval diskriminant ishorasini sodda tengsizlikka keltiring, keyin k ning alohida qiymatini qo‘ying.'
),
(
  'P1FP01-Q02','P1-FUN-04',array['P1-FUN-02','P1-FUN-03']::text[],
  'The function f is defined by f(x)=x^2-6x+5 for x>=3. (a) Write f(x) in completed-square form and state the range of f. (b) Find f^(-1)(x), including its domain. (c) Let g(x)=2x-1. Solve f^(-1)(g(x))=5.',
  'Функция f задана как f(x)=x^2-6x+5 при x>=3. (a) Представьте f(x) в виде полного квадрата и укажите область значений f. (b) Найдите f^(-1)(x), включая область определения. (c) Пусть g(x)=2x-1. Решите f^(-1)(g(x))=5.',
  'f funksiya x>=3 da f(x)=x^2-6x+5 bilan berilgan. (a) f(x) ni to‘liq kvadrat ko‘rinishida yozing va f ning qiymatlar sohasini ko‘rsating. (b) f^(-1)(x) ni uning aniqlanish sohasi bilan toping. (c) g(x)=2x-1 bo‘lsin. f^(-1)(g(x))=5 tenglamani yeching.',
  '{"max_marks":7,"criteria":[{"id":"square","marks":1,"rule":"Gets f(x)=(x-3)^2-4."},{"id":"range","marks":1,"rule":"States range y>=-4."},{"id":"inverse_working","marks":1,"rule":"Uses x>=3 to select the positive square-root branch."},{"id":"inverse","marks":1,"rule":"Gets f^(-1)(x)=3+sqrt(x+4)."},{"id":"inverse_domain","marks":1,"rule":"States domain x>=-4 for f^(-1)."},{"id":"composition","marks":1,"rule":"Forms 3+sqrt(2x+3)=5."},{"id":"solution","marks":1,"rule":"Gets x=1/2 and it satisfies the composite-domain condition."}]}'::jsonb,
  'The original domain restriction determines the sign in the inverse; carry the inverse domain into the composition check.',
  'Исходное ограничение области определения определяет знак в обратной функции; учитывайте область определения обратной функции при проверке композиции.',
  'Boshlang‘ich aniqlanish sohasi inverse dagi ildiz ishorasini belgilaydi; kompozitsiyani tekshirganda inverse aniqlanish sohasini ham hisobga oling.'
),
(
  'P1FP01-Q03','P1-COO-05',array['P1-COO-04','P1-COO-03']::text[],
  'The circle C has equation x^2+y^2-6x+4y-12=0. (a) Find the centre and radius of C. (b) Verify that P(6,2) lies on C. (c) Find the equation of the tangent to C at P. (d) Find the y-coordinate where this tangent meets the y-axis.',
  'Окружность C задана уравнением x^2+y^2-6x+4y-12=0. (a) Найдите центр и радиус C. (b) Проверьте, что P(6,2) лежит на C. (c) Найдите уравнение касательной к C в точке P. (d) Найдите y-координату точки пересечения этой касательной с осью y.',
  'C aylana x^2+y^2-6x+4y-12=0 tenglama bilan berilgan. (a) C ning markazi va radiusini toping. (b) P(6,2) nuqta C da yotishini tekshiring. (c) P nuqtadagi C ga urinma tenglamasini toping. (d) Bu urinmaning y-o‘qi bilan kesishishidagi y koordinatani toping.',
  '{"max_marks":7,"criteria":[{"id":"complete_square","marks":1,"rule":"Gets (x-3)^2+(y+2)^2=25."},{"id":"centre_radius","marks":1,"rule":"States centre (3,-2), radius 5."},{"id":"verify","marks":1,"rule":"Correctly verifies P(6,2) satisfies the circle equation."},{"id":"radius_gradient","marks":1,"rule":"Gets radius OP gradient 4/3."},{"id":"tangent_gradient","marks":1,"rule":"Gets tangent gradient -3/4."},{"id":"tangent","marks":1,"rule":"Gets y-2=-(3/4)(x-6) or equivalent."},{"id":"intercept","marks":1,"rule":"Gets y-intercept 13/2."}]}'::jsonb,
  'The tangent is perpendicular to the radius through the point of contact; calculate that radius gradient before writing the tangent.',
  'Касательная перпендикулярна радиусу, проведённому в точку касания; сначала найдите градиент этого радиуса.',
  'Urinma tegish nuqtasiga o‘tkazilgan radiusga perpendikulyar; avval shu radius gradientini toping.'
),
(
  'P1FP01-Q04','P1-CIR-03',array['P1-CIR-02']::text[],
  'A sector has radius 8 cm and arc length 12 cm. (a) Find its angle theta in radians. (b) Find the area of the sector. (c) The two radii and chord form a triangle. Find the area of the minor segment, giving an exact expression and a numerical value to 3 significant figures.',
  'Сектор имеет радиус 8 см и длину дуги 12 см. (a) Найдите угол theta в радианах. (b) Найдите площадь сектора. (c) Два радиуса и хорда образуют треугольник. Найдите площадь малого сегмента, дав точное выражение и численное значение до 3 значащих цифр.',
  'Sektor radiusi 8 cm va yoy uzunligi 12 cm. (a) theta burchakni radianlarda toping. (b) Sektor yuzasini toping. (c) Ikki radius va xorda uchburchak hosil qiladi. Kichik segment yuzasini aniq ifoda va 3 ta muhim raqamgacha sonli qiymat bilan toping.',
  '{"max_marks":6,"criteria":[{"id":"theta","marks":1,"rule":"Uses s=r theta and gets theta=3/2."},{"id":"sector_setup","marks":1,"rule":"Uses A=(1/2)r^2 theta."},{"id":"sector","marks":1,"rule":"Gets sector area 48 cm^2."},{"id":"triangle","marks":1,"rule":"Gets triangle area 32 sin(3/2) cm^2."},{"id":"segment_exact","marks":1,"rule":"Gets segment area 48-32 sin(3/2) cm^2."},{"id":"segment_numeric","marks":1,"rule":"Gets approximately 16.1 cm^2 to 3 s.f."}]}'::jsonb,
  'Use radians in both s=r theta and sector-area formulas; a minor segment is sector minus the triangle made by the two radii.',
  'В формулах s=r theta и площади сектора используйте радианы; площадь малого сегмента равна площади сектора минус площадь треугольника из двух радиусов.',
  's=r theta va sektor yuzi formulalarida radian ishlating; kichik segment yuzi sektor yuzidan ikki radius hosil qilgan uchburchak yuzini ayirishga teng.'
),
(
  'P1FP01-Q05','P1-TRI-05',array['P1-TRI-04','P1-TRI-02']::text[],
  'For 0<=x<=2pi, consider 2sin^2(x)+3cos(x)=0. (a) Using sin^2(x)=1-cos^2(x), reduce the equation to a quadratic in cos(x). (b) Solve the quadratic and reject any impossible cosine value. (c) Hence find all solutions for x in the given interval. (d) Verify the solutions by substitution into the original equation.',
  'При 0<=x<=2pi рассмотрите уравнение 2sin^2(x)+3cos(x)=0. (a) Используя sin^2(x)=1-cos^2(x), сведите его к квадратному уравнению относительно cos(x). (b) Решите квадратное уравнение и отбросьте невозможное значение косинуса. (c) Найдите все решения x на заданном интервале. (d) Проверьте решения подстановкой в исходное уравнение.',
  '0<=x<=2pi da 2sin^2(x)+3cos(x)=0 tenglamani ko‘ring. (a) sin^2(x)=1-cos^2(x) dan foydalanib tenglamani cos(x) bo‘yicha kvadrat tenglamaga keltiring. (b) Kvadrat tenglamani yeching va mumkin bo‘lmagan cosine qiymatini rad eting. (c) Berilgan oraliqda barcha x yechimlarni toping. (d) Yechimlarni asl tenglamaga qo‘yib tekshiring.',
  '{"max_marks":8,"criteria":[{"id":"identity","marks":1,"rule":"Substitutes sin^2 x=1-cos^2 x correctly."},{"id":"quadratic","marks":1,"rule":"Obtains 2cos^2 x-3cos x-2=0."},{"id":"factor","marks":1,"rule":"Factors as (2cos x+1)(cos x-2)=0 or equivalent."},{"id":"reject","marks":1,"rule":"Rejects cos x=2 as impossible."},{"id":"cos_value","marks":1,"rule":"Keeps cos x=-1/2."},{"id":"solution1","marks":1,"rule":"Gets x=2pi/3."},{"id":"solution2","marks":1,"rule":"Gets x=4pi/3 and no additional solutions in the interval."},{"id":"verify","marks":1,"rule":"Checks both values satisfy the original equation."}]}'::jsonb,
  'After converting to a quadratic, remember that algebraic roots for cos(x) must still lie in [-1,1] and then generate every angle in the interval.',
  'После сведения к квадратному уравнению помните, что значение cos(x) должно лежать в [-1,1], после чего найдите все углы на интервале.',
  'Kvadrat tenglamani yechgach, cos(x) qiymati [-1,1] oralig‘ida bo‘lishi kerakligini tekshiring va so‘ng intervaldagi barcha burchaklarni toping.'
),
(
  'P1FP01-Q06','P1-SER-01',array['P1-SER-05','P1-SER-04']::text[],
  '(a) Expand (1-2x)^6 up to and including the x^3 term. Hence find the coefficient of x^3 in (1-2x)^6(1+x). (b) A geometric series has first term 12 and common ratio 1/2. Find its sum to infinity and the least positive integer n for which the sum of the first n terms exceeds 23.5.',
  '(a) Разложите (1-2x)^6 до члена с x^3 включительно. Затем найдите коэффициент при x^3 в (1-2x)^6(1+x). (b) Геометрический ряд имеет первый член 12 и знаменатель 1/2. Найдите сумму до бесконечности и наименьшее положительное целое n, при котором сумма первых n членов превышает 23.5.',
  '(a) (1-2x)^6 ni x^3 hadi bilan birga shu hadgacha yoying. So‘ng (1-2x)^6(1+x) dagi x^3 koeffitsiyentini toping. (b) Geometrik qatorning birinchi hadi 12, umumiy nisbati 1/2. Cheksiz yig‘indini va dastlabki n had yig‘indisi 23.5 dan katta bo‘ladigan eng kichik musbat butun n ni toping.',
  '{"max_marks":8,"criteria":[{"id":"binomial_terms","marks":2,"rule":"Gets 1-12x+60x^2-160x^3 for the requested expansion, with correct binomial coefficients/signs."},{"id":"product_coeff","marks":1,"rule":"Gets x^3 coefficient -160+60=-100."},{"id":"convergence","marks":1,"rule":"Recognises |r|<1 and uses S_infinity=a/(1-r)."},{"id":"infinite_sum","marks":1,"rule":"Gets S_infinity=24."},{"id":"finite_formula","marks":1,"rule":"Uses S_n=24(1-2^(-n)) or equivalent."},{"id":"inequality","marks":1,"rule":"Reduces S_n>23.5 to 2^n>48 or equivalent."},{"id":"least_n","marks":1,"rule":"Gets least integer n=6."}]}'::jsonb,
  'For the product coefficient, combine contributions to x^3 from both factors; for the geometric inequality keep track of the strict sign when finding the least integer n.',
  'Для коэффициента произведения учтите все вклады в x^3 из обоих множителей; в геометрическом неравенстве сохраните строгий знак при поиске минимального n.',
  'Ko‘paytmadagi x^3 koeffitsiyenti uchun ikkala ko‘paytuvchidan keladigan barcha hissalarni qo‘shing; geometrik tengsizlikda eng kichik n ni topishda qat’iy ishorani saqlang.'
),
(
  'P1FP01-Q07','P1-DIF-07',array['P1-DIF-04','P1-DIF-05']::text[],
  'The curve has equation y=x^3-3x^2-9x+5. (a) Find dy/dx and the coordinates of all stationary points. (b) Determine the nature of each stationary point. (c) Find the equation of the tangent to the curve at x=1.',
  'Кривая задана уравнением y=x^3-3x^2-9x+5. (a) Найдите dy/dx и координаты всех стационарных точек. (b) Определите характер каждой стационарной точки. (c) Найдите уравнение касательной к кривой при x=1.',
  'Egri chiziq y=x^3-3x^2-9x+5 tenglama bilan berilgan. (a) dy/dx ni va barcha stationary nuqtalar koordinatalarini toping. (b) Har bir stationary nuqtaning turini aniqlang. (c) x=1 dagi urinma tenglamasini toping.',
  '{"max_marks":8,"criteria":[{"id":"derivative","marks":1,"rule":"Gets dy/dx=3x^2-6x-9=3(x-3)(x+1)."},{"id":"stationary_x","marks":1,"rule":"Gets x=-1 and x=3."},{"id":"stationary_coords","marks":2,"rule":"Gets (-1,10) and (3,-22)."},{"id":"second_derivative","marks":1,"rule":"Uses d2y/dx2=6x-6 or a correct derivative-sign test."},{"id":"nature","marks":1,"rule":"Classifies (-1,10) as local maximum and (3,-22) as local minimum."},{"id":"tangent_gradient","marks":1,"rule":"At x=1 gets point (1,-6) and gradient -12."},{"id":"tangent","marks":1,"rule":"Gets y+6=-12(x-1) or equivalent."}]}'::jsonb,
  'Solve dy/dx=0 before classifying the points; the tangent part is independent and needs both the point and derivative value at x=1.',
  'Сначала решите dy/dx=0 и затем классифицируйте точки; для касательной отдельно нужны точка и значение производной при x=1.',
  'Avval dy/dx=0 ni yeching, keyin nuqtalarni tasniflang; urinma uchun x=1 dagi nuqta va hosila qiymati alohida kerak.'
),
(
  'P1FP01-Q08','P1-DIF-06',array['P1-DIF-02']::text[],
  'A cube has side length x cm, volume V=x^3 cm^3 and surface area S=6x^2 cm^2. At an instant when x=6, the volume is increasing at 72 cm^3/s. (a) Find dx/dt. (b) Find dS/dt at the same instant. (c) State the units and signs of both rates and explain briefly why the signs are consistent with the situation.',
  'Куб имеет ребро x см, объём V=x^3 см^3 и площадь поверхности S=6x^2 см^2. В момент, когда x=6, объём увеличивается со скоростью 72 см^3/с. (a) Найдите dx/dt. (b) Найдите dS/dt в тот же момент. (c) Укажите единицы и знаки обеих скоростей и кратко объясните, почему знаки согласуются с условием.',
  'Kub qirrasi x cm, hajmi V=x^3 cm^3 va sirt yuzi S=6x^2 cm^2. x=6 bo‘lgan paytda hajm 72 cm^3/s tezlikda oshmoqda. (a) dx/dt ni toping. (b) Shu paytda dS/dt ni toping. (c) Ikkala tezlikning birliklari va ishoralarini ko‘rsating hamda nega ishoralar vaziyatga mosligini qisqacha tushuntiring.',
  '{"max_marks":7,"criteria":[{"id":"volume_diff","marks":1,"rule":"Differentiates to dV/dt=3x^2 dx/dt."},{"id":"dxdt_setup","marks":1,"rule":"Substitutes x=6 and dV/dt=72 correctly."},{"id":"dxdt","marks":1,"rule":"Gets dx/dt=2/3 cm/s."},{"id":"surface_diff","marks":1,"rule":"Differentiates to dS/dt=12x dx/dt."},{"id":"surface_sub","marks":1,"rule":"Substitutes x=6 and dx/dt=2/3."},{"id":"surface_rate","marks":1,"rule":"Gets dS/dt=48 cm^2/s."},{"id":"units_sign","marks":1,"rule":"States both rates are positive with correct units and links this to the expanding cube."}]}'::jsonb,
  'Differentiate each geometric quantity with respect to time before substituting the instant values; units reveal whether the rate belongs to length, area or volume.',
  'Сначала продифференцируйте каждую геометрическую величину по времени, затем подставляйте значения; единицы показывают, относится ли скорость к длине, площади или объёму.',
  'Avval har bir geometrik kattalikni vaqt bo‘yicha differensiallang, keyin shu paytdagi qiymatlarni qo‘ying; birliklar tezlik uzunlik, yuza yoki hajmga tegishli ekanini ko‘rsatadi.'
),
(
  'P1FP01-Q09','P1-INT-04',array['P1-COO-02','P1-QUA-03']::text[],
  'The curve y=x^2 and the line y=2x+3 enclose a finite region. (a) Find the x-coordinates of the intersection points. (b) Find the exact total area enclosed. (c) The y-axis divides the region into two parts. Find the exact area of each part and hence the ratio left:right.',
  'Кривая y=x^2 и прямая y=2x+3 ограничивают конечную область. (a) Найдите x-координаты точек пересечения. (b) Найдите точную общую площадь области. (c) Ось y делит область на две части. Найдите точную площадь каждой части и отношение левая:правая.',
  'y=x^2 egri chiziq va y=2x+3 to‘g‘ri chiziq chekli sohani chegaralaydi. (a) Kesishish nuqtalarining x koordinatalarini toping. (b) Chegaralangan umumiy yuzani aniq toping. (c) y-o‘qi sohani ikki qismga ajratadi. Har bir qism yuzasini va chap:o‘ng nisbatni aniq toping.',
  '{"max_marks":9,"criteria":[{"id":"intersections_eq","marks":1,"rule":"Sets x^2=2x+3 and obtains x^2-2x-3=0."},{"id":"intersections","marks":1,"rule":"Gets x=-1 and x=3."},{"id":"integrand","marks":1,"rule":"Uses upper-minus-lower integrand 2x+3-x^2."},{"id":"antiderivative","marks":2,"rule":"Integrates correctly to x^2+3x-x^3/3 and applies bounds."},{"id":"total_area","marks":1,"rule":"Gets total area 32/3."},{"id":"left_area","marks":1,"rule":"Gets area from -1 to 0 equal to 5/3."},{"id":"right_area","marks":1,"rule":"Gets area from 0 to 3 equal to 9."},{"id":"ratio","marks":1,"rule":"Gets left:right=5:27."}]}'::jsonb,
  'Sketch mentally which graph is above the other before integrating; when the y-axis splits the region, use the same antiderivative on two separate intervals.',
  'Перед интегрированием определите, какой график расположен выше; при делении области осью y используйте одну первообразную на двух отдельных интервалах.',
  'Integrallashdan oldin qaysi grafik yuqorida ekanini aniqlang; y-o‘qi sohani bo‘lsa, bir xil boshlang‘ich funksiyani ikki alohida intervalda qo‘llang.'
),
(
  'P1FP01-Q10','P1-INT-05',array['P1-INT-04']::text[],
  'For 0<=x<=4, the curve y=x(4-x) and the x-axis bound a region R. (a) Find the exact area of R. (b) R is rotated through 2pi radians about the x-axis. Write the volume integral, expand the integrand, and find the exact volume of the solid formed.',
  'При 0<=x<=4 кривая y=x(4-x) и ось x ограничивают область R. (a) Найдите точную площадь R. (b) Область R вращают на 2pi радиан вокруг оси x. Запишите интеграл для объёма, раскройте подынтегральное выражение и найдите точный объём полученного тела.',
  '0<=x<=4 da y=x(4-x) egri chiziq va x-o‘qi R sohani chegaralaydi. (a) R ning aniq yuzasini toping. (b) R soha x-o‘qi atrofida 2pi radian aylantiriladi. Hajm integralini yozing, integral ostidagi ifodani yoying va hosil bo‘lgan jism hajmini aniq toping.',
  '{"max_marks":9,"criteria":[{"id":"area_setup","marks":1,"rule":"Uses integral 0 to 4 of x(4-x) dx."},{"id":"area_antiderivative","marks":1,"rule":"Integrates 4x-x^2 correctly."},{"id":"area","marks":1,"rule":"Gets area 32/3."},{"id":"volume_formula","marks":1,"rule":"Uses V=pi integral 0 to 4 of [x(4-x)]^2 dx."},{"id":"expand","marks":1,"rule":"Expands to x^4-8x^3+16x^2."},{"id":"volume_antiderivative","marks":2,"rule":"Integrates the squared expression correctly and applies 0,4."},{"id":"integral_value","marks":1,"rule":"Gets integral value 512/15."},{"id":"volume","marks":1,"rule":"Gets V=512pi/15."}]}'::jsonb,
  'Area uses y, while volume about the x-axis uses pi times y^2; do not forget to square the full function before expanding.',
  'Для площади интегрируется y, а для объёма вокруг оси x — pi умножить на y^2; перед раскрытием обязательно возведите в квадрат всю функцию.',
  'Yuza uchun y integrallanadi, x-o‘qi atrofidagi hajm uchun esa pi*y^2; yoyishdan oldin butun funksiyani kvadratga oshiring.'
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
  where content_version='p1_stage3_full_paper_01_v1' and component_code='P1' and status='draft'
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
  title_en,title_ru,title_uz,approved_at
)
select cv.id,'p1_stage3_full_paper_01','av1','P1','paper','approved',
       'P1 Stage 3 full paper 01','P1 Stage 3: full paper 01','P1 Stage 3 full paper 01',now()
from cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions where content_version='p1_stage3_full_paper_01_v1'
), a as (
  select a.id from private.exam_prep_assessments a join cv on cv.id=a.content_version_id
  where a.assessment_key='p1_stage3_full_paper_01' and a.assessment_version='av1'
), items(item_order,task_key,skill) as (values
  (1,'P1FP01-Q01','P1-QUA-02'),
  (2,'P1FP01-Q02','P1-FUN-04'),
  (3,'P1FP01-Q03','P1-COO-05'),
  (4,'P1FP01-Q04','P1-CIR-03'),
  (5,'P1FP01-Q05','P1-TRI-05'),
  (6,'P1FP01-Q06','P1-SER-01'),
  (7,'P1FP01-Q07','P1-DIF-07'),
  (8,'P1FP01-Q08','P1-DIF-06'),
  (9,'P1FP01-Q09','P1-INT-04'),
  (10,'P1FP01-Q10','P1-INT-05')
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
  where assessment_key='p1_stage3_full_paper_01' and assessment_version='av1'
), marks(item_order,max_marks) as (values
  (1::smallint,6::smallint),(2::smallint,7::smallint),(3::smallint,7::smallint),(4::smallint,6::smallint),
  (5::smallint,8::smallint),(6::smallint,8::smallint),(7::smallint,8::smallint),(8::smallint,7::smallint),
  (9::smallint,9::smallint),(10::smallint,9::smallint)
)
insert into private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks)
select a.id,m.item_order,m.max_marks from a cross join marks m
on conflict(assessment_id,item_order) do nothing;

update private.exam_prep_content_versions
set status='published',approved_at=coalesce(approved_at,now()),published_at=coalesce(published_at,now())
where content_version='p1_stage3_full_paper_01_v1' and status='draft';

update private.exam_prep_assessments
set status='published',approved_at=coalesce(approved_at,now())
where assessment_key='p1_stage3_full_paper_01' and assessment_version='av1' and status='approved';

with a as (
  select a.id,a.component_code from private.exam_prep_assessments a
  where a.assessment_key='p1_stage3_full_paper_01' and a.assessment_version='av1' and a.status='published'
), p as (
  select id,component_code from private.exam_prep_component_paper_profiles
  where component_code='P1' and profile_version='9709_2026_2027_v1' and status='published'
)
insert into private.exam_prep_timed_assessment_contracts(
  assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
  strict_timing,comparison_scope,comparability_key,status,published_at
)
select a.id,p.id,'tcv1','full_paper','official_full',75,null,true,'full','p1-full-paper-01-v1','published',now()
from a join p using(component_code)
on conflict(assessment_id) do nothing;

-- Acceptance: official full-paper contract, all eight P1 syllabus sections, written-only governance and fail-closed beta state.
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
  where assessment_key='p1_stage3_full_paper_01' and assessment_version='av1' and status='published';
  if v_ass is null then raise exception 'P1-03 P1 full paper assessment missing'; end if;

  select count(*) into v_tasks
  from private.exam_prep_assessment_items ai
  join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
  where ai.assessment_id=v_ass and ai.question_id is null and ai.reserve_role='written'
    and wt.lifecycle_state='published' and wt.copyright_status='pass'
    and wt.qa_math_status='pass' and wt.qa_language_status='pass' and wt.qa_technical_status='pass';
  if v_tasks<>10 then raise exception 'P1-03 P1 full paper written floor tasks=%',v_tasks; end if;

  select count(*),coalesce(sum(max_marks),0) into v_items,v_marks
  from private.exam_prep_timed_assessment_items where assessment_id=v_ass;
  if v_items<>10 or v_marks<>75 then raise exception 'P1-03 P1 full paper marks items=% marks=%',v_items,v_marks; end if;

  select coalesce(sum((wt.rubric_json->>'max_marks')::int),0) into v_rubric_marks
  from private.exam_prep_assessment_items ai join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
  where ai.assessment_id=v_ass;
  if v_rubric_marks<>75 then raise exception 'P1-03 P1 full paper rubric marks=%',v_rubric_marks; end if;

  select count(distinct sn.official_syllabus_section) into v_sections
  from private.exam_prep_assessment_items ai
  join private.exam_prep_syllabus_nodes sn on sn.program_version_id=1 and sn.skill_code=ai.primary_skill_code and sn.component_code='P1'
  where ai.assessment_id=v_ass;
  if v_sections<>8 then raise exception 'P1-03 P1 full paper syllabus breadth sections=%',v_sections; end if;

  select * into v_contract from private.exam_prep_timed_assessment_contracts where assessment_id=v_ass and status='published';
  if v_contract.assessment_id is null or v_contract.attempt_kind<>'full_paper' or v_contract.timing_rule<>'official_full'
     or v_contract.comparison_scope<>'full' or v_contract.marks_available<>75 or v_contract.fixed_time_limit_sec is not null
     or not v_contract.strict_timing then raise exception 'P1-03 P1 full paper contract invalid'; end if;
  if private.exam_prep_timed_min_stage_v1(v_contract.attempt_kind)<>3 then raise exception 'P1-03 P1 full paper stage drift'; end if;
  v_time:=private.exam_prep_timed_time_limit_v1(v_contract.paper_profile_id,v_contract.timing_rule,v_contract.marks_available,v_contract.fixed_time_limit_sec);
  if v_time<>6600 then raise exception 'P1-03 P1 full paper timing drift seconds=%',v_time; end if;

  if exists(select 1 from public.questions q where q.book_ref like 'ExamPrep:%p1_stage3_full_paper_01%') then
    raise exception 'P1-03 P1 full paper must not create public.questions rows';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 P1 full paper publication requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 P1 full paper active entitlement residue=%',v_active; end if;
  if exists(select 1 from private.exam_prep_sessions) or exists(select 1 from private.exam_prep_evidence_events) or exists(select 1 from private.exam_prep_timed_attempt_results) then
    raise exception 'P1-03 P1 full paper publication must not create learner runtime evidence';
  end if;
end $$;

commit;