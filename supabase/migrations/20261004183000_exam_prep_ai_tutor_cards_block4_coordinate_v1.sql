-- Curated Tutor Cards Block 4: P1 Coordinate Geometry except P1-COO-02 already covered.
-- 5 skills x 3 locales = 15 new DRAFT cards. Runtime remains OFF.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $precheck$
declare
  v_existing integer;
  v_sources integer;
  v_baseline integer;
  v_coo02 integer;
begin
  select count(*) into v_existing
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code in ('P1-COO-01','P1-COO-03','P1-COO-04','P1-COO-05','P1-COO-06');
  if v_existing<>0 then
    raise exception 'Block 4 refuses to overwrite existing Coordinate Geometry cards: %',v_existing;
  end if;

  select count(*) into v_sources
  from private.exam_prep_ai_source_cards
  where approval_status='approved' and is_runtime_allowed and card_type='theory'
    and component_code='P1'
    and skill_code in ('P1-COO-01','P1-COO-03','P1-COO-04','P1-COO-05','P1-COO-06')
    and locale in ('en','ru','uz');
  if v_sources<>15 then
    raise exception 'Block 4 requires exactly 15 approved/runtime theory sources, found %',v_sources;
  end if;

  select count(*) into v_baseline
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft' and not is_runtime_allowed;
  if v_baseline<>48 then
    raise exception 'Block 4 requires 48 learner-first draft cards from prior blocks, found %',v_baseline;
  end if;

  select count(*) into v_coo02
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code='P1-COO-02'
    and approval_status='draft' and not is_runtime_allowed;
  if v_coo02<>3 then
    raise exception 'Block 4 requires the existing 3-locale P1-COO-02 pilot card set, found %',v_coo02;
  end if;
end
$precheck$;

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (
values
(
'p1:P1-COO-01:tutor:en:v2','P1','P1-COO-01','en','tutor_v2_learner_first',
'Equation of a straight line',
$t$A straight line is fixed once you know its gradient and one point on it. The most useful form is

y - y₁ = m(x - x₁),

where m is the gradient and (x₁,y₁) is a point on the line.

For example, suppose a line has gradient 4 and passes through (2,3). Then

y - 3 = 4(x - 2),

so

y = 4x - 5.

If instead you are given two points, first find the gradient using change in y divided by change in x, then use either point in the point-gradient formula. The important idea is that the gradient controls the direction of the line, while one known point fixes its position.$t$,
$t$To build a line equation, you need a gradient and one point.

Use

y - y₁ = m(x - x₁).

For gradient 4 through (2,3):

y - 3 = 4(x - 2),

so y = 4x - 5.

If two points are given, find the gradient first, then use either point.$t$,
$t$Think of a line as having two pieces of information: direction and position. The gradient gives the direction. A point tells you where that directed line must pass.

That is why y - y₁ = m(x - x₁) works: y - y₁ measures vertical change from the known point, while x - x₁ measures horizontal change, and their ratio must stay equal to m.$t$,
$t$Do not use y=mx+c until you know c. Point-gradient form is safer when a point is given. With two points, keep the subtraction order consistent when finding m. After forming the equation, substitute the known point back in to check it lies on the line.$t$,
'p1:P1-COO-01:theory:en:v1'
),
(
'p1:P1-COO-01:tutor:ru:v2','P1','P1-COO-01','ru','tutor_v2_learner_first',
'Уравнение прямой',
$t$Прямая однозначно задаётся, если известны её угловой коэффициент и одна точка. Удобнее всего использовать форму

y - y₁ = m(x - x₁),

где m — угловой коэффициент, а (x₁,y₁) — точка на прямой.

Например, пусть прямая имеет угловой коэффициент 4 и проходит через (2,3). Тогда

y - 3 = 4(x - 2),

откуда

y = 4x - 5.

Если даны две точки, сначала найдите угловой коэффициент как изменение y, делённое на изменение x, затем подставьте любую из точек в формулу. Главная идея: коэффициент задаёт направление прямой, а известная точка фиксирует её положение.$t$,
$t$Чтобы составить уравнение прямой, нужны угловой коэффициент и одна точка.

Используйте

y - y₁ = m(x - x₁).

Для коэффициента 4 и точки (2,3):

y - 3 = 4(x - 2),

поэтому y = 4x - 5.

Если даны две точки, сначала найдите коэффициент, затем используйте любую из них.$t$,
$t$Можно представить прямую как сочетание двух вещей: направления и положения. Угловой коэффициент задаёт направление. Одна точка показывает, через какое место должна пройти эта прямая.

Поэтому в y - y₁ = m(x - x₁) величины y - y₁ и x - x₁ описывают изменения от известной точки, а их отношение остаётся равным m.$t$,
$t$Не спешите переходить к y=mx+c, если c ещё неизвестно. При заданной точке форма y - y₁ = m(x - x₁) надёжнее. Если даны две точки, сохраняйте одинаковый порядок вычитания. Готовое уравнение проверьте подстановкой известной точки.$t$,
'p1:P1-COO-01:theory:ru:v1'
),
(
'p1:P1-COO-01:tutor:uz:v2','P1','P1-COO-01','uz','tutor_v2_learner_first',
'To‘g‘ri chiziq tenglamasi',
$t$To‘g‘ri chiziq uning gradienti va undagi bitta nuqta ma’lum bo‘lsa, to‘liq aniqlanadi. Eng qulay ko‘rinish:

y - y₁ = m(x - x₁),

bu yerda m — gradient, (x₁,y₁) esa chiziqdagi nuqta.

Masalan, gradient 4 bo‘lib, chiziq (2,3) nuqtadan o‘tsin. Unda

y - 3 = 4(x - 2),

ya’ni

y = 4x - 5.

Agar ikkita nuqta berilgan bo‘lsa, avval y dagi o‘zgarishni x dagi o‘zgarishga bo‘lib gradientni toping, keyin nuqtalardan birini formulaga qo‘ying. Asosiy g‘oya: gradient chiziq yo‘nalishini, bitta nuqta esa uning joylashuvini belgilaydi.$t$,
$t$Chiziq tenglamasini tuzish uchun gradient va bitta nuqta kerak.

y - y₁ = m(x - x₁)

formuladan foydalaning.

Gradient 4 va nuqta (2,3) bo‘lsa:

y - 3 = 4(x - 2),

demak y = 4x - 5.

Ikki nuqta berilsa, avval gradientni toping, keyin ulardan birini ishlating.$t$,
$t$Chiziqni ikki ma’lumotdan tashkil topgan deb o‘ylang: yo‘nalish va joylashuv. Gradient yo‘nalishni beradi. Bitta nuqta esa shu yo‘nalishdagi chiziq qayerdan o‘tishini belgilaydi.

Shuning uchun y - y₁ = m(x - x₁) da y - y₁ va x - x₁ ma’lum nuqtadan o‘zgarishni ko‘rsatadi, ularning nisbati esa m ga teng bo‘lib qoladi.$t$,
$t$c noma’lum bo‘lsa, darhol y=mx+c ga o‘tish shart emas. Nuqta berilganda y - y₁ = m(x - x₁) qulayroq. Ikki nuqtadan gradient topishda ayirish tartibini bir xil saqlang. Tayyor tenglamani ma’lum nuqtani qo‘yib tekshiring.$t$,
'p1:P1-COO-01:theory:uz:v1'
),
(
'p1:P1-COO-03:tutor:en:v2','P1','P1-COO-03','en','tutor_v2_learner_first',
'Parallel and perpendicular lines',
$t$The gradient tells you how two straight lines are related. Parallel lines have the same gradient. For non-vertical perpendicular lines, the gradients satisfy

m₁m₂ = -1,

so the perpendicular gradient is the negative reciprocal.

Take the line

y = 3x - 2.

A parallel line has gradient 3. Through (1,4), its equation is

y - 4 = 3(x - 1),
so y = 3x + 1.

A perpendicular line has gradient -1/3. Through the same point,

y - 4 = -(1/3)(x - 1).

The relationship determines the new gradient; the given point then determines which particular parallel or perpendicular line you need.$t$,
$t$Parallel lines have equal gradients.

If one line has gradient 3, any parallel line also has gradient 3.

Perpendicular gradients are negative reciprocals. So if one gradient is 3, the perpendicular gradient is -1/3.

After choosing the correct gradient, use the given point in

y - y₁ = m(x - x₁).$t$,
$t$Think of gradient as direction. Parallel lines point in exactly the same direction, so their gradients match. Perpendicular lines turn through 90°, which changes a non-zero gradient m into -1/m.

For y=3x-2, the direction numbers are therefore 3 for a parallel and -1/3 for a perpendicular. A point then fixes where the new line sits.$t$,
$t$For parallel lines, copy the gradient, not the intercept. For perpendicular lines, take the negative reciprocal: change the sign and invert the fraction. The rule m₁m₂=-1 applies to non-vertical lines; vertical/horizontal lines should be handled geometrically.$t$,
'p1:P1-COO-03:theory:en:v1'
),
(
'p1:P1-COO-03:tutor:ru:v2','P1','P1-COO-03','ru','tutor_v2_learner_first',
'Параллельные и перпендикулярные прямые',
$t$Угловой коэффициент показывает взаимное направление прямых. У параллельных прямых коэффициенты одинаковы. Для непараллельных осям перпендикулярных прямых выполняется

m₁m₂ = -1,

то есть коэффициент перпендикулярной прямой — отрицательная обратная величина.

Рассмотрим

y = 3x - 2.

Параллельная прямая имеет коэффициент 3. Через точку (1,4):

y - 4 = 3(x - 1),
поэтому y = 3x + 1.

У перпендикулярной прямой коэффициент -1/3. Через ту же точку:

y - 4 = -(1/3)(x - 1).

Сначала условие параллельности или перпендикулярности задаёт новый коэффициент, затем точка определяет конкретную прямую.$t$,
$t$У параллельных прямых угловые коэффициенты равны.

Если у одной прямой коэффициент 3, у любой параллельной тоже 3.

Для перпендикулярной прямой берите отрицательную обратную величину. Поэтому для 3 получаем -1/3.

После этого используйте заданную точку в

y - y₁ = m(x - x₁).$t$,
$t$Считайте угловой коэффициент направлением. Параллельные прямые смотрят в одном направлении, поэтому их коэффициенты совпадают. Поворот на 90° превращает ненулевой коэффициент m в -1/m.

Поэтому для y=3x-2 коэффициент параллельной прямой равен 3, а перпендикулярной — -1/3. Точка затем фиксирует положение новой прямой.$t$,
$t$Для параллельной прямой копируйте угловой коэффициент, а не свободный член. Для перпендикулярной возьмите отрицательную обратную величину: поменяйте знак и переверните дробь. Правило m₁m₂=-1 относится к непараллельным осям прямым; вертикальную и горизонтальную прямые лучше рассматривать геометрически.$t$,
'p1:P1-COO-03:theory:ru:v1'
),
(
'p1:P1-COO-03:tutor:uz:v2','P1','P1-COO-03','uz','tutor_v2_learner_first',
'Parallel va perpendikulyar chiziqlar',
$t$Gradient ikki to‘g‘ri chiziqning yo‘nalish munosabatini ko‘rsatadi. Parallel chiziqlarning gradientlari teng. Koordinata o‘qlariga parallel bo‘lmagan perpendikulyar chiziqlar uchun

m₁m₂ = -1,

ya’ni perpendikulyar gradient manfiy teskari qiymat bo‘ladi.

Masalan,

y = 3x - 2.

Parallel chiziq gradienti 3. U (1,4) nuqtadan o‘tsa:

y - 4 = 3(x - 1),
demak y = 3x + 1.

Perpendikulyar chiziq gradienti -1/3. Shu nuqtadan:

y - 4 = -(1/3)(x - 1).

Avval parallel yoki perpendikulyar sharti yangi gradientni beradi, keyin nuqta aynan qaysi chiziq kerakligini belgilaydi.$t$,
$t$Parallel chiziqlarning gradientlari bir xil.

Agar bir chiziq gradienti 3 bo‘lsa, unga parallel chiziq gradienti ham 3.

Perpendikulyar gradient manfiy teskari qiymat: 3 uchun -1/3.

So‘ng berilgan nuqtani

y - y₁ = m(x - x₁)

formulaga qo‘ying.$t$,
$t$Gradientni yo‘nalish deb tasavvur qiling. Parallel chiziqlar aynan bir yo‘nalishda ketadi, shuning uchun gradientlar teng. 90° burilish esa nol bo‘lmagan m gradientni -1/m ga aylantiradi.

Shuning uchun y=3x-2 ga parallel chiziq uchun gradient 3, perpendikulyar chiziq uchun -1/3. Nuqta esa yangi chiziqning joyini aniqlaydi.$t$,
$t$Parallel chiziq uchun gradientni nusxalang, erkin hadni emas. Perpendikulyar uchun ishorani o‘zgartirib, kasrni teskari qiling. m₁m₂=-1 qoidasi vertikal bo‘lmagan chiziqlar uchun; vertikal va gorizontal chiziqlarni geometrik ko‘ring.$t$,
'p1:P1-COO-03:theory:uz:v1'
),
(
'p1:P1-COO-04:tutor:en:v2','P1','P1-COO-04','en','tutor_v2_learner_first',
'Equation of a circle',
$t$A circle is the set of points a fixed distance r from its centre (a,b). That gives the standard equation

(x-a)² + (y-b)² = r².

For centre (2,-1) and radius 3:

(x-2)² + (y+1)² = 9.

Expanding gives

x² + y² - 4x + 2y - 4 = 0.

You can also work backwards from an expanded equation by completing the square in x and y. The signs in the standard form are easy to misread: (x-2) means centre x-coordinate 2, while (y+1) means centre y-coordinate -1. The standard form makes centre and radius visible immediately.$t$,
$t$For centre (a,b) and radius r:

(x-a)² + (y-b)² = r².

So centre (2,-1), radius 3 gives

(x-2)² + (y+1)² = 9.

The bracket signs look opposite to the centre coordinates. If the circle is expanded, complete the square in x and y to recover the standard form.$t$,
$t$The circle equation comes directly from distance. Any point (x,y) on the circle is exactly r units from the centre (a,b).

Using Pythagoras:

(x-a)² + (y-b)² = r².

So the formula is not just something to memorise — it is the distance formula with the distance fixed at r. Completing squares reverses the same idea when the equation is expanded.$t$,
$t$Read the centre with opposite bracket signs: (x-a) gives a and (y-b) gives b. The right side is r², not r. In expanded form, group x-terms and y-terms separately before completing each square.$t$,
'p1:P1-COO-04:theory:en:v1'
),
(
'p1:P1-COO-04:tutor:ru:v2','P1','P1-COO-04','ru','tutor_v2_learner_first',
'Уравнение окружности',
$t$Окружность — это множество точек, находящихся на постоянном расстоянии r от центра (a,b). Поэтому её стандартное уравнение:

(x-a)² + (y-b)² = r².

Для центра (2,-1) и радиуса 3:

(x-2)² + (y+1)² = 9.

После раскрытия скобок получаем

x² + y² - 4x + 2y - 4 = 0.

Из развёрнутого уравнения можно вернуться к стандартному виду, выделяя полные квадраты отдельно по x и y. Знаки внутри скобок легко прочитать неправильно: (x-2) означает координату центра 2, а (y+1) — координату -1. Стандартный вид сразу показывает центр и радиус.$t$,
$t$Для центра (a,b) и радиуса r:

(x-a)² + (y-b)² = r².

Поэтому центр (2,-1), радиус 3 дают

(x-2)² + (y+1)² = 9.

Знаки в скобках выглядят противоположными координатам центра. Если уравнение раскрыто, выделите полный квадрат отдельно по x и y.$t$,
$t$Уравнение окружности прямо следует из формулы расстояния. Любая точка (x,y) на окружности находится ровно на расстоянии r от центра (a,b).

По теореме Пифагора:

(x-a)² + (y-b)² = r².

То есть эту формулу не обязательно запоминать как отдельную: это формула расстояния с постоянным расстоянием r. Выделение квадратов восстанавливает ту же структуру из развёрнутой записи.$t$,
$t$Координаты центра читаются с противоположными знаками в скобках: (x-a) даёт a, (y-b) даёт b. Справа стоит r², а не r. В развёрнутом виде сначала сгруппируйте члены с x и y, затем отдельно выделяйте полный квадрат.$t$,
'p1:P1-COO-04:theory:ru:v1'
),
(
'p1:P1-COO-04:tutor:uz:v2','P1','P1-COO-04','uz','tutor_v2_learner_first',
'Aylana tenglamasi',
$t$Aylana — markaz (a,b) dan bir xil r masofada joylashgan nuqtalar to‘plami. Shuning uchun standart tenglama

(x-a)² + (y-b)² = r².

Markaz (2,-1), radius 3 bo‘lsa:

(x-2)² + (y+1)² = 9.

Qavslarni ochsak,

x² + y² - 4x + 2y - 4 = 0.

Yoyilgan tenglamadan standart ko‘rinishga x va y bo‘yicha alohida to‘liq kvadrat ajratib qaytish mumkin. Qavs ichidagi ishoralar markaz koordinatalariga teskari ko‘rinadi: (x-2) markazning x-koordinatasi 2, (y+1) esa y-koordinatasi -1 ekanini bildiradi. Standart ko‘rinish markaz va radiusni darhol ko‘rsatadi.$t$,
$t$Markaz (a,b), radius r uchun:

(x-a)² + (y-b)² = r².

Shuning uchun markaz (2,-1), radius 3 bo‘lsa

(x-2)² + (y+1)² = 9.

Qavs ishoralari markaz koordinatalariga teskari ko‘rinadi. Tenglama yoyilgan bo‘lsa, x va y bo‘yicha alohida to‘liq kvadratga keltiring.$t$,
$t$Aylana tenglamasi masofa formulasidan keladi. Aylanadagi istalgan (x,y) nuqta markaz (a,b) dan aynan r masofada turadi.

Pifagor teoremasi bo‘yicha:

(x-a)² + (y-b)² = r².

Demak, bu shunchaki yodlanadigan formula emas — masofa doim r ga teng bo‘lgan holat. To‘liq kvadrat ajratish yoyilgan tenglamadan shu tuzilmani qayta tiklaydi.$t$,
$t$Markaz koordinatalarini qavsdagi teskari ishoralar orqali o‘qing: (x-a) dan a, (y-b) dan b olinadi. O‘ng tomonda r emas, r² turadi. Yoyilgan tenglamada x va y hadlarini alohida guruhlab, keyin kvadratlarni ajrating.$t$,
'p1:P1-COO-04:theory:uz:v1'
),
(
'p1:P1-COO-05:tutor:en:v2','P1','P1-COO-05','en','tutor_v2_learner_first',
'Lines and circles',
$t$To find where a line and a circle meet, solve their equations simultaneously. The line lets you replace one variable in the circle equation, leaving an equation in one variable.

For example,

x² + y² = 25,
y = 3.

Substitute y=3 into the circle:

x² + 9 = 25,
x² = 16,
x = ±4.

So the intersection points are

(-4,3) and (4,3).

The two algebraic solutions match the geometry: the horizontal line crosses the circle in two places. After finding x, always recover the matching y-coordinate and write complete points. Coordinate-geometry problems often become much simpler when you move back and forth between the diagram and the algebra.$t$,
$t$Solve a line and a circle together by substitution.

For

x² + y² = 25
and y=3,

put y=3 into the circle:

x² + 9 = 25,
so x=±4.

Therefore the intersections are

(-4,3) and (4,3).

Each algebraic solution gives one geometric intersection point.$t$,
$t$Think of the algebra as asking the same question as the diagram: “Which points belong to both shapes?”

The line y=3 fixes the height. Substituting that height into x²+y²=25 finds the x-positions where the circle reaches it. The two values x=-4 and x=4 are the two crossing points visible on the circle.$t$,
$t$Substitute carefully and solve the resulting equation completely; a square can give two x-values. Then pair each x with its correct y. Check the final coordinates in both original equations. Do not report x-values alone when the question asks for intersection points.$t$,
'p1:P1-COO-05:theory:en:v1'
),
(
'p1:P1-COO-05:tutor:ru:v2','P1','P1-COO-05','ru','tutor_v2_learner_first',
'Прямая и окружность',
$t$Чтобы найти точки пересечения прямой и окружности, решите их уравнения совместно. Уравнение прямой позволяет заменить одну переменную в уравнении окружности и получить уравнение с одной переменной.

Например,

x² + y² = 25,
y = 3.

Подставляем y=3 в окружность:

x² + 9 = 25,
x² = 16,
x = ±4.

Значит, точки пересечения:

(-4,3) и (4,3).

Два алгебраических решения соответствуют геометрии: горизонтальная прямая пересекает окружность в двух местах. После нахождения x обязательно восстановите соответствующее y и запишите полные координаты. В координатной геометрии полезно постоянно связывать алгебру с рисунком.$t$,
$t$Прямую и окружность решайте совместно подстановкой.

Для

x² + y² = 25
и y=3

подставляем y=3:

x² + 9 = 25,
поэтому x=±4.

Точки пересечения:

(-4,3) и (4,3).

Каждое алгебраическое решение соответствует одной точке пересечения.$t$,
$t$Смотрите на алгебру как на тот же вопрос, что и на рисунке: «Какие точки одновременно принадлежат обеим фигурам?»

Прямая y=3 фиксирует высоту. Подстановка этой высоты в x²+y²=25 показывает, при каких x окружность достигает этой высоты. Значения -4 и 4 — две видимые точки пересечения.$t$,
$t$Подставляйте аккуратно и решайте полученное уравнение полностью: квадрат может дать два значения x. Затем каждому x сопоставьте правильное y. Проверьте готовые точки в обоих исходных уравнениях. Не оставляйте только значения x, если нужны координаты точек.$t$,
'p1:P1-COO-05:theory:ru:v1'
),
(
'p1:P1-COO-05:tutor:uz:v2','P1','P1-COO-05','uz','tutor_v2_learner_first',
'To‘g‘ri chiziq va aylana',
$t$To‘g‘ri chiziq bilan aylana qayerda kesishishini topish uchun ularning tenglamalarini birgalikda yeching. Chiziq tenglamasi bir o‘zgaruvchini aylana tenglamasiga qo‘yib, bitta o‘zgaruvchili tenglama olishga imkon beradi.

Masalan,

x² + y² = 25,
y = 3.

y=3 ni aylana tenglamasiga qo‘yamiz:

x² + 9 = 25,
x² = 16,
x = ±4.

Demak, kesishish nuqtalari

(-4,3) va (4,3).

Ikki algebraik yechim geometriyaga mos: gorizontal chiziq aylanani ikki joyda kesadi. x ni topgach, mos y ni ham yozib, to‘liq nuqtalarni ko‘rsating. Koordinata geometriyasida algebra va chizmani bir-biriga bog‘lab borish masalani ancha tushunarli qiladi.$t$,
$t$Chiziq va aylanani almashtirish orqali birgalikda yeching.

x² + y² = 25
va y=3

uchun y=3 ni qo‘yamiz:

x² + 9 = 25,
demak x=±4.

Kesishish nuqtalari:

(-4,3) va (4,3).

Har bir algebraik yechim bitta geometrik kesishish nuqtasiga mos keladi.$t$,
$t$Algebrani chizmadagi savolning boshqa ko‘rinishi deb o‘ylang: «Qaysi nuqtalar ikkala shaklga ham tegishli?»

y=3 chizig‘i balandlikni belgilaydi. Shu y ni x²+y²=25 ga qo‘yish aylana bu balandlikka qaysi x larda yetishini ko‘rsatadi. x=-4 va x=4 — chizmadagi ikki kesishish nuqtasi.$t$,
$t$Almashtirishni ehtiyotkor bajaring va hosil bo‘lgan tenglamani to‘liq yeching: kvadrat ikki x qiymat berishi mumkin. So‘ng har bir x ga mos y ni yozing. Yakuniy nuqtalarni ikkala boshlang‘ich tenglamada tekshiring. Nuqta so‘ralganda faqat x qiymatlarini qoldirmang.$t$,
'p1:P1-COO-05:theory:uz:v1'
),
(
'p1:P1-COO-06:tutor:en:v2','P1','P1-COO-06','en','tutor_v2_learner_first',
'Intersections and tangency',
$t$When a line is substituted into a circle equation, the resulting quadratic describes their intersection points. Its roots have a direct geometric meaning: two distinct real roots mean two intersections, one repeated root means tangency, and no real roots mean no intersection.

For example, take

x² + y² = 25
and y = k.

Substitution gives

x² + k² - 25 = 0.

As a quadratic in x, its discriminant is

D = 100 - 4k².

For the line to be tangent, require exactly one real solution:

D = 0.

So

100 - 4k² = 0,
k² = 25,
k = ±5.

Thus y=5 and y=-5 are the two horizontal tangents. The discriminant converts a geometric contact condition into an algebraic parameter condition.$t$,
$t$After substituting a line into a circle, look at the quadratic roots.

Two real roots → two intersections.
One repeated root → tangent.
No real roots → no intersection.

For x²+y²=25 and y=k:

x²+k²-25=0.

Tangency means D=0, which gives

100-4k²=0,
so k=±5.$t$,
$t$Imagine moving the horizontal line y=k up and down across the circle. Far away it misses the circle, closer in it cuts the circle twice, and at the exact top or bottom it touches once.

The quadratic after substitution records the same change. Two roots become one repeated root at the instant of tangency. That is why setting the discriminant to zero finds the tangent parameter.$t$,
$t$For a tangent, use the condition “exactly one intersection”, not merely “the equations can be solved”. After substitution, form the quadratic correctly and set its discriminant to zero. In parameter questions, solve all resulting parameter values and check they make geometric sense.$t$,
'p1:P1-COO-06:theory:en:v1'
),
(
'p1:P1-COO-06:tutor:ru:v2','P1','P1-COO-06','ru','tutor_v2_learner_first',
'Пересечение и касание',
$t$После подстановки уравнения прямой в уравнение окружности получается квадратное уравнение, корни которого описывают точки пересечения. Два различных действительных корня означают две точки пересечения, один повторяющийся корень — касание, отсутствие действительных корней — отсутствие пересечения.

Например,

x² + y² = 25,
y = k.

После подстановки:

x² + k² - 25 = 0.

Как квадратное уравнение по x оно имеет дискриминант

D = 100 - 4k².

Для касания нужна ровно одна действительная точка:

D = 0.

Тогда

100 - 4k² = 0,
k² = 25,
k = ±5.

Значит, y=5 и y=-5 — две горизонтальные касательные. Дискриминант переводит геометрическое условие касания в алгебраическое условие на параметр.$t$,
$t$После подстановки прямой в окружность смотрите на корни полученного квадратного уравнения.

Два действительных корня → два пересечения.
Один повторяющийся корень → касание.
Нет действительных корней → пересечения нет.

Для x²+y²=25 и y=k:

x²+k²-25=0.

Условие касания D=0 даёт k=±5.$t$,
$t$Представьте, что горизонтальная прямая y=k движется вверх и вниз через окружность. Далеко она не пересекает окружность, ближе — пересекает дважды, а в самой верхней или нижней точке касается ровно один раз.

Квадратное уравнение после подстановки отражает то же изменение: два корня в момент касания превращаются в один повторяющийся. Поэтому для касательной дискриминант равен нулю.$t$,
$t$Для касательной используйте условие «ровно одна точка пересечения», а не просто возможность решить систему. После подстановки правильно составьте квадратное уравнение и приравняйте дискриминант к нулю. В задачах с параметром сохраните все найденные значения и проверьте их геометрический смысл.$t$,
'p1:P1-COO-06:theory:ru:v1'
),
(
'p1:P1-COO-06:tutor:uz:v2','P1','P1-COO-06','uz','tutor_v2_learner_first',
'Kesishish va urinma',
$t$Chiziq tenglamasini aylana tenglamasiga qo‘yganda hosil bo‘lgan kvadrat tenglama ularning kesishish nuqtalarini tasvirlaydi. Ikkita turli haqiqiy ildiz — ikkita kesishish, bitta takroriy ildiz — urinma, haqiqiy ildiz yo‘qligi — kesishish yo‘qligini bildiradi.

Masalan,

x² + y² = 25,
y = k.

Almashtirishdan so‘ng:

x² + k² - 25 = 0.

x ga nisbatan kvadrat tenglamaning diskriminanti

D = 100 - 4k².

Urinma uchun aynan bitta haqiqiy yechim kerak:

D = 0.

Demak,

100 - 4k² = 0,
k² = 25,
k = ±5.

Shuning uchun y=5 va y=-5 ikkita gorizontal urinma. Diskriminant geometrik tegish shartini parametr uchun algebraik shartga aylantiradi.$t$,
$t$Chiziqni aylanaga qo‘ygandan keyin kvadrat tenglama ildizlariga qarang.

Ikki haqiqiy ildiz → ikki kesishish.
Bitta takroriy ildiz → urinma.
Haqiqiy ildiz yo‘q → kesishish yo‘q.

x²+y²=25 va y=k uchun

x²+k²-25=0.

Urinma sharti D=0 dan k=±5 chiqadi.$t$,
$t$y=k gorizontal chiziq aylana bo‘ylab yuqoriga-pastga siljiyotganini tasavvur qiling. U uzoqda bo‘lsa aylanani kesmaydi, yaqinroq bo‘lsa ikki joyda kesadi, aynan yuqori yoki pastki nuqtada esa bir marta tegadi.

Almashtirishdan chiqqan kvadrat tenglama ham shu holatni ko‘rsatadi: ikkita ildiz urinma paytida bitta takroriy ildizga aylanadi. Shuning uchun diskriminant nol qilinadi.$t$,
$t$Urinma uchun «aynan bitta kesishish» shartini ishlating. Almashtirishdan keyin kvadrat tenglamani to‘g‘ri tuzib, diskriminantni nolga tenglang. Parametrli masalada barcha topilgan parametr qiymatlarini saqlang va ularning geometrik ma’nosini tekshiring.$t$,
'p1:P1-COO-06:theory:uz:v1'
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
from seed;

do $postcheck$
declare
  v_new integer;
  v_all integer;
  v_bad_link integer;
begin
  select count(*) into v_new
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code in ('P1-COO-01','P1-COO-03','P1-COO-04','P1-COO-05','P1-COO-06')
    and approval_status='draft' and not is_runtime_allowed;
  if v_new<>15 then raise exception 'Block 4 expected 15 new draft cards, found %',v_new; end if;

  select count(*) into v_all
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft' and not is_runtime_allowed;
  if v_all<>63 then raise exception 'Block 4 expected 63 learner-first draft cards total, found %',v_all; end if;

  select count(*) into v_bad_link
  from private.exam_prep_ai_tutor_cards t
  join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
  where t.content_version='tutor_v2_learner_first'
    and t.skill_code in ('P1-COO-01','P1-COO-03','P1-COO-04','P1-COO-05','P1-COO-06')
    and (
      s.component_code<>t.component_code or s.skill_code<>t.skill_code or s.locale<>t.locale
      or s.card_type<>'theory' or s.approval_status<>'approved' or not s.is_runtime_allowed
    );
  if v_bad_link<>0 then raise exception 'Block 4 source-card linkage drift: %',v_bad_link; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P1-COO-%'
      and (
        position(E'\\n' in main_explanation)>0 or position(E'\\n' in simple_explanation)>0
        or position(E'\\n' in alternative_explanation)>0 or position(E'\\n' in focus_explanation)>0
      )
  ) then raise exception 'Block 4 contains literal backslash-n formatting'; end if;
end
$postcheck$;

commit;
