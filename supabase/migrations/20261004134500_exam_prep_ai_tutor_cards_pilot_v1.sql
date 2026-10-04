-- Curated Tutor Card pilot v1.
-- 3 canonical skills x 3 locales = 9 DRAFT cards.
-- Runtime remains OFF. These rows exist for product/content review only.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,
  source_card_key
) as (
values
(
'p1:P1-QUA-01:tutor:en:v1','P1','P1-QUA-01','en','tutor_v1',
'Completing the square',
'Completing the square rewrites a quadratic so its shape is easier to read. The target form is a(x - h)² + k. In this form, the turning point is (h, k), and the sign of a tells you whether the parabola opens upward or downward. The key move is to create a perfect square from the x² and x terms. For x² + bx, use (x + b/2)² - (b/2)². If the coefficient of x² is not 1, factor it from the quadratic and linear terms first. The expression must stay equivalent throughout, so anything introduced to make the square must also be compensated for.',
'Completing the square means rewriting a quadratic so part of it becomes one squared bracket. For x² + bx, half the coefficient of x, put that value inside the bracket, square it, and subtract the same square outside. The final form makes the turning point of the parabola much easier to see.',
'Think of it as reversing an expansion. A bracket such as (x - h)² expands to x² - 2hx + h². When you complete the square, you look at the x-term to work out the value of h, then adjust the constant so the new expression is exactly equal to the original one. This exposes the geometry hidden inside the expanded quadratic.',
'Check three things: factor the x² coefficient first when necessary; whatever you add to create the square must be compensated for; and remember that (x - h)² gives x-coordinate h, so the sign inside the bracket is opposite to the coordinate.',
'p1:P1-QUA-01:theory:en:v1'
),
(
'p1:P1-QUA-01:tutor:ru:v1','P1','P1-QUA-01','ru','tutor_v1',
'Выделение полного квадрата',
'Выделение полного квадрата позволяет переписать квадратное выражение так, чтобы его форма стала понятнее. Цель — получить вид a(x - h)² + k. Из него сразу видно вершину параболы (h, k), а знак a показывает, направлены её ветви вверх или вниз. Главный шаг — превратить члены с x² и x в полный квадрат. Для x² + bx используйте (x + b/2)² - (b/2)². Если коэффициент при x² не равен 1, сначала вынесите его из членов с x² и x. Важно сохранять равенство: всё, что добавляется для получения квадрата, нужно компенсировать.',
'Выделить полный квадрат — значит переписать часть квадратного выражения в виде одного квадрата скобки. Для x² + bx возьмите половину коэффициента при x, поместите её в скобку, возведите в квадрат и вычтите такой же квадрат снаружи. После этого вершину параболы увидеть намного легче.',
'Представьте, что вы выполняете раскрытие скобок в обратную сторону. Например, (x - h)² раскрывается как x² - 2hx + h². При выделении полного квадрата коэффициент при x помогает определить h, а затем постоянный член корректируется так, чтобы новое выражение было точно равно исходному. Так из развёрнутой записи становится видна геометрическая форма параболы.',
'Проверьте три вещи: при необходимости сначала вынесите коэффициент при x²; добавленное для полного квадрата обязательно компенсируйте; в (x - h)² координата вершины по x равна h, поэтому знак внутри скобки выглядит противоположным.',
'p1:P1-QUA-01:theory:ru:v1'
),
(
'p1:P1-QUA-01:tutor:uz:v1','P1','P1-QUA-01','uz','tutor_v1',
'To‘liq kvadratga keltirish',
'To‘liq kvadratga keltirish kvadrat ifodani uning shakli aniq ko‘rinadigan tarzda qayta yozishga yordam beradi. Maqsad — a(x - h)² + k ko‘rinishiga kelish. Bu ko‘rinishda parabolaning uchi (h, k) bo‘ladi, a ning ishorasi esa parabola yuqoriga yoki pastga ochilishini ko‘rsatadi. Asosiy qadam x² va x li hadlardan to‘liq kvadrat hosil qilishdir. x² + bx uchun (x + b/2)² - (b/2)² dan foydalanish mumkin. Agar x² oldidagi koeffitsiyent 1 bo‘lmasa, avval uni x² va x li hadlardan tashqariga chiqaring. Ifoda teng bo‘lib qolishi uchun kvadrat hosil qilishda qo‘shilgan qiymat albatta kompensatsiya qilinadi.',
'To‘liq kvadratga keltirish — kvadrat ifodaning bir qismini bitta kvadrat qavs ko‘rinishida yozishdir. x² + bx uchun x oldidagi koeffitsiyentning yarmini oling, qavs ichiga yozing, kvadratini hosil qiling va xuddi shu kvadratni tashqarida ayiring. Shunda parabolaning uchini ko‘rish ancha osonlashadi.',
'Buni qavslarni ochish jarayonini teskari bajarish deb tasavvur qiling. (x - h)² ifoda x² - 2hx + h² ga ochiladi. To‘liq kvadratga keltirishda x li had orqali h ni aniqlaysiz, so‘ng doimiy hadni shunday moslaysizki, yangi ifoda boshlang‘ich ifodaga aynan teng bo‘lib qolsin. Natijada kvadrat ifodaning geometrik ma’nosi aniqroq ko‘rinadi.',
'Uch narsani tekshiring: kerak bo‘lsa avval x² koeffitsiyentini tashqariga chiqaring; kvadrat hosil qilish uchun qo‘shilgan qiymatni kompensatsiya qiling; (x - h)² da uchning x-koordinatasi h bo‘ladi, shuning uchun qavs ichidagi ishora koordinataga teskari ko‘rinadi.',
'p1:P1-QUA-01:theory:uz:v1'
),
(
'p1:P1-COO-02:tutor:en:v1','P1','P1-COO-02','en','tutor_v1',
'Distance, midpoint and intersection',
'Coordinate geometry turns geometric information into equations. For two points (x₁, y₁) and (x₂, y₂), the gradient is (y₂ - y₁)/(x₂ - x₁), the midpoint is ((x₁ + x₂)/2, (y₁ + y₂)/2), and the distance is √((x₂ - x₁)² + (y₂ - y₁)²). Once you know a gradient and a point, a convenient line form is y - y₁ = m(x - x₁). To find where two lines intersect, solve their equations simultaneously: the intersection coordinates must satisfy both equations. These tools are closely connected, so first identify what the question gives you — two points, a gradient, a midpoint, or two line equations — then choose the matching relation.',
'With coordinates, most line questions reduce to a few standard tools. Subtract y-values over x-values for gradient, average the coordinates for midpoint, use Pythagoras for distance, and solve two line equations together for an intersection. The intersection point is simply the point that lies on both lines.',
'Think of each coordinate question as asking for one missing link. Two points can give you gradient, distance or midpoint. A point plus a gradient gives a line. Two lines give an intersection. Instead of memorising separate procedures, identify which information you have and which connection turns it into the quantity you need.',
'Keep the order of subtraction consistent when finding gradient; average x with x and y with y for the midpoint; and when you find an intersection, substitute the point back into both line equations to check it.',
'p1:P1-COO-02:theory:en:v1'
),
(
'p1:P1-COO-02:tutor:ru:v1','P1','P1-COO-02','ru','tutor_v1',
'Расстояние, середина и пересечение',
'Координатная геометрия переводит геометрическую информацию в уравнения. Для точек (x₁, y₁) и (x₂, y₂) угловой коэффициент равен (y₂ - y₁)/(x₂ - x₁), середина отрезка — ((x₁ + x₂)/2, (y₁ + y₂)/2), а расстояние — √((x₂ - x₁)² + (y₂ - y₁)²). Если известны точка и угловой коэффициент m, удобно использовать форму y - y₁ = m(x - x₁). Чтобы найти пересечение двух прямых, решите их уравнения как систему: координаты точки пересечения должны удовлетворять обоим уравнениям. Сначала определите, что именно дано в задаче — две точки, коэффициент, середина или две прямые — и выберите соответствующую связь.',
'В задачах с координатами обычно нужны несколько стандартных инструментов. Угловой коэффициент находится как изменение y, делённое на изменение x; координаты середины получают усреднением; расстояние — по теореме Пифагора; точку пересечения — совместным решением двух уравнений прямых.',
'Смотрите на задачу как на цепочку связей. Две точки могут дать угловой коэффициент, расстояние или середину. Точка и угловой коэффициент задают прямую. Две прямые дают точку пересечения. Вместо поиска отдельной формулы для каждой задачи определите, какая информация у вас уже есть и какая связь ведёт к нужной величине.',
'При вычислении углового коэффициента сохраняйте один и тот же порядок вычитания в числителе и знаменателе; для середины усредняйте x с x и y с y; найденную точку пересечения полезно подставить в оба уравнения прямых.',
'p1:P1-COO-02:theory:ru:v1'
),
(
'p1:P1-COO-02:tutor:uz:v1','P1','P1-COO-02','uz','tutor_v1',
'Masofa, o‘rta nuqta va kesishish',
'Koordinata geometriyasi geometrik ma’lumotni tenglamalarga aylantiradi. (x₁, y₁) va (x₂, y₂) nuqtalar uchun gradient (y₂ - y₁)/(x₂ - x₁), o‘rta nuqta ((x₁ + x₂)/2, (y₁ + y₂)/2), masofa esa √((x₂ - x₁)² + (y₂ - y₁)²) ga teng. Gradient va bitta nuqta ma’lum bo‘lsa, y - y₁ = m(x - x₁) ko‘rinishi qulay. Ikki to‘g‘ri chiziqning kesishish nuqtasini topish uchun ularning tenglamalarini birgalikda yeching: kesishish koordinatalari ikkala tenglamani ham qanoatlantirishi kerak. Avval masalada nima berilganini aniqlang, so‘ng mos bog‘lanishni tanlang.',
'Koordinata masalalarida bir nechta asosiy vosita yetarli bo‘ladi. Gradient uchun y dagi o‘zgarishni x dagi o‘zgarishga bo‘ling, o‘rta nuqta uchun koordinatalarni o‘rtachalang, masofa uchun Pifagor teoremasidan foydalaning, kesishish uchun esa ikki chiziq tenglamasini birgalikda yeching.',
'Har bir masalani bog‘lanishlar zanjiri sifatida ko‘ring. Ikki nuqta gradient, masofa yoki o‘rta nuqtani beradi. Nuqta va gradient chiziq tenglamasini beradi. Ikki chiziq esa kesishish nuqtasini beradi. Alohida usullarni yodlash o‘rniga sizda qaysi ma’lumot borligini va u kerakli natijaga qanday olib borishini aniqlang.',
'Gradientni topishda surat va maxrajda ayirish tartibini bir xil saqlang; o‘rta nuqtada x larni x lar bilan, y larni y lar bilan o‘rtachalang; kesishish nuqtasini topgach, uni ikkala chiziq tenglamasiga qo‘yib tekshiring.',
'p1:P1-COO-02:theory:uz:v1'
),
(
'p5:P5-NOR-02:tutor:en:v1','P5','P5-NOR-02','en','tutor_v1',
'Standardisation and z-values',
'Standardisation converts a normal variable X with mean μ and standard deviation σ into the standard normal variable Z using Z = (X - μ)/σ. A z-value tells you how many standard deviations a value lies from the mean: positive z-values are above the mean and negative ones are below it. After standardising the boundary, translate the original probability statement into the matching interval or tail for Z. Then use the normal table or calculator in the direction it actually reports. If it gives the left-tail probability Φ(z), a right-tail probability is 1 - Φ(z). The most important part is not the arithmetic — it is matching the original event to the correct side of the normal curve.',
'Standardising puts different normal distributions onto the same scale. Subtract the mean from the value and divide by the standard deviation: Z = (X - μ)/σ. Then decide whether the question wants the area to the left, to the right, or between two values before reading a table or calculator result.',
'Think of z as a position label on the normal curve. z = 0 is the mean, positive z is to the right of the mean, and negative z is to the left. Once every boundary is converted to a z-value, the original probability question becomes an area question on one standard bell curve. Your final job is to choose the correct area, not just calculate z.',
'Write the probability event before using the calculator or table. Check the sign of z, check whether you need a left tail, right tail or interval, and confirm what your table/calculator returns before deciding whether to subtract from 1.',
'p5:P5-NOR-02:theory:en:v1'
),
(
'p5:P5-NOR-02:tutor:ru:v1','P5','P5-NOR-02','ru','tutor_v1',
'Стандартизация и z-значение',
'Стандартизация переводит нормальную случайную величину X со средним μ и стандартным отклонением σ к стандартной нормальной величине Z по формуле Z = (X - μ)/σ. Значение z показывает, на сколько стандартных отклонений исходное значение находится от среднего: положительное z — выше среднего, отрицательное — ниже. После стандартизации границы переведите исходное событие в соответствующий интервал или хвост для Z. Затем используйте таблицу или калькулятор с учётом того, какую площадь они возвращают. Если дана левая накопленная вероятность Φ(z), правая равна 1 - Φ(z). Главное здесь — правильно связать условие задачи с нужной областью под нормальной кривой.',
'Стандартизация переносит разные нормальные распределения на одну общую шкалу. Из значения вычтите среднее и разделите на стандартное отклонение: Z = (X - μ)/σ. Затем до обращения к таблице или калькулятору определите, какая область нужна: слева, справа или между двумя границами.',
'Считайте z координатой положения на нормальной кривой. z = 0 соответствует среднему, положительные z находятся справа от среднего, отрицательные — слева. После перевода всех границ в z исходная задача превращается в поиск площади на одной стандартной колоколообразной кривой. Поэтому важно не только найти z, но и выбрать правильную область.',
'Сначала запишите событие вероятности. Затем проверьте знак z, определите — нужен левый хвост, правый хвост или интервал — и убедитесь, какую вероятность показывает ваша таблица или калькулятор, прежде чем вычитать что-либо из 1.',
'p5:P5-NOR-02:theory:ru:v1'
),
(
'p5:P5-NOR-02:tutor:uz:v1','P5','P5-NOR-02','uz','tutor_v1',
'Standartlashtirish va z-qiymat',
'Standartlashtirish o‘rtachasi μ va standart og‘ishi σ bo‘lgan normal X tasodifiy miqdorni standart normal Z ga o‘tkazadi: Z = (X - μ)/σ. z-qiymat berilgan qiymat o‘rtachadan nechta standart og‘ish uzoqligini ko‘rsatadi: musbat z o‘rtachadan yuqorida, manfiy z esa pastda joylashadi. Chegarani standartlashtirgach, boshlang‘ich ehtimollik hodisasini Z uchun mos interval yoki dumga aylantiring. Keyin jadval yoki kalkulyator aynan qaysi maydonni qaytarishini hisobga olib foydalaning. Agar chap tomondagi yig‘ma ehtimollik Φ(z) berilsa, o‘ng dum 1 - Φ(z) bo‘ladi. Eng muhim qadam — masaladagi hodisani normal egri chiziqdagi to‘g‘ri sohaga moslashtirish.',
'Standartlashtirish turli normal taqsimotlarni bitta umumiy shkala ustiga olib keladi. Qiymatdan o‘rtachani ayiring va standart og‘ishga bo‘ling: Z = (X - μ)/σ. So‘ng jadval yoki kalkulyatordan oldin qaysi soha kerakligini aniqlang: chap tomon, o‘ng tomon yoki ikki chegara oralig‘i.',
'z ni normal egri chiziqdagi joylashuv belgisi deb o‘ylang. z = 0 o‘rtachaga mos keladi, musbat z o‘rtachaning o‘ngida, manfiy z esa chapida bo‘ladi. Barcha chegaralarni z ga aylantirgandan keyin boshlang‘ich ehtimollik savoli bitta standart qo‘ng‘iroqsimon egri chiziqdagi maydon savoliga aylanadi. Shuning uchun faqat z ni topish emas, to‘g‘ri sohani tanlash ham muhim.',
'Avval ehtimollik hodisasini yozib oling. Keyin z ishorasini tekshiring, chap dum, o‘ng dum yoki interval kerakligini aniqlang va 1 dan ayirishdan oldin jadval yoki kalkulyator aynan qaysi ehtimollikni qaytarishini tekshiring.',
'p5:P5-NOR-02:theory:uz:v1'
)
)
insert into private.exam_prep_ai_tutor_cards(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,
  source_card_key,approval_status,is_runtime_allowed,content_hash
)
select
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,
  source_card_key,'draft',false,
  md5(concat_ws('||',content_version,title,main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key))
from seed
on conflict (tutor_card_key) do update set
  title=excluded.title,
  main_explanation=excluded.main_explanation,
  simple_explanation=excluded.simple_explanation,
  alternative_explanation=excluded.alternative_explanation,
  focus_explanation=excluded.focus_explanation,
  source_card_key=excluded.source_card_key,
  content_hash=excluded.content_hash,
  updated_at=now()
where private.exam_prep_ai_tutor_cards.approval_status='draft'
  and private.exam_prep_ai_tutor_cards.is_runtime_allowed=false;

do $postcheck$
declare
  v_count integer;
  v_runtime integer;
begin
  select count(*),count(*) filter(where is_runtime_allowed)
    into v_count,v_runtime
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v1'
    and skill_code in ('P1-QUA-01','P1-COO-02','P5-NOR-02');

  if v_count<>9 then
    raise exception 'Tutor pilot expected 9 draft cards, found %',v_count;
  end if;
  if v_runtime<>0 then
    raise exception 'Tutor pilot must remain runtime OFF';
  end if;
end
$postcheck$;

commit;
