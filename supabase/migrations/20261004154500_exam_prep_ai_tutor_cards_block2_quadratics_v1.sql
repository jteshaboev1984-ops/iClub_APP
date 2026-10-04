-- Curated Tutor Cards Block 2: P1 Quadratics family P1-QUA-02...06.
-- 5 skills x 3 locales = 15 new DRAFT cards. Runtime remains OFF.
-- Also normalizes the never-runtime Block 1 v2 draft line breaks to real newlines.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $precheck$
declare
  v_existing integer;
  v_sources integer;
  v_pilot integer;
begin
  select count(*) into v_existing
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code in ('P1-QUA-02','P1-QUA-03','P1-QUA-04','P1-QUA-05','P1-QUA-06');

  if v_existing<>0 then
    raise exception 'Block 2 refuses to overwrite existing learner-first Quadratics cards: %',v_existing;
  end if;

  select count(*) into v_sources
  from private.exam_prep_ai_source_cards
  where approval_status='approved'
    and is_runtime_allowed
    and card_type='theory'
    and component_code='P1'
    and skill_code in ('P1-QUA-02','P1-QUA-03','P1-QUA-04','P1-QUA-05','P1-QUA-06')
    and locale in ('en','ru','uz');

  if v_sources<>15 then
    raise exception 'Block 2 requires exactly 15 approved/runtime theory sources, found %',v_sources;
  end if;

  select count(*) into v_pilot
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code in ('P1-QUA-01','P1-COO-02','P5-NOR-02')
    and approval_status='draft'
    and not is_runtime_allowed;

  if v_pilot<>9 then
    raise exception 'Block 2 requires the reviewed 9-card learner-first pilot baseline, found %',v_pilot;
  end if;
end
$precheck$;

-- Block 1 v2 was never runtime-visible. Normalize stored formatting before any future approval.
update private.exam_prep_ai_tutor_cards
set main_explanation=replace(main_explanation,'\n',E'\n'),
    simple_explanation=replace(simple_explanation,'\n',E'\n'),
    alternative_explanation=replace(alternative_explanation,'\n',E'\n'),
    focus_explanation=replace(focus_explanation,'\n',E'\n'),
    content_hash=md5(concat_ws(
      '||',
      content_version,
      title,
      replace(main_explanation,'\n',E'\n'),
      replace(simple_explanation,'\n',E'\n'),
      replace(alternative_explanation,'\n',E'\n'),
      replace(focus_explanation,'\n',E'\n'),
      source_card_key
    )),
    updated_at=now()
where content_version='tutor_v2_learner_first'
  and skill_code in ('P1-QUA-01','P1-COO-02','P5-NOR-02')
  and approval_status='draft'
  and not is_runtime_allowed;

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,
  source_card_key
) as (
values
(
'p1:P1-QUA-02:tutor:en:v2','P1','P1-QUA-02','en','tutor_v2_learner_first',
'Discriminant and roots',
$t$The discriminant tells you how many real roots a quadratic has without solving it first. For

ax² + bx + c = 0,

the discriminant is

D = b² - 4ac.

If D > 0, there are two distinct real roots. If D = 0, there is one repeated real root. If D < 0, there are no real roots.

For example, consider

x² - 4x + k = 0.

Here D = 16 - 4k. For two distinct real roots, require 16 - 4k > 0, so k < 4. A repeated root occurs when k = 4, and there are no real roots when k > 4. This is why the discriminant is especially useful in parameter questions: it converts information about roots into an equation or inequality.$t$,
$t$The discriminant is a quick test for the real roots of a quadratic.

D = b² - 4ac.

D > 0 means two different real roots, D = 0 means one repeated real root, and D < 0 means no real roots.

For x² - 4x + k = 0, D = 16 - 4k. So two different real roots require k < 4.$t$,
$t$Think about the graph y = ax² + bx + c and the x-axis. Real roots are exactly the x-coordinates where the parabola meets the x-axis.

D > 0: the graph crosses the axis twice.
D = 0: it just touches the axis once.
D < 0: it does not meet the axis.

So the discriminant is an algebraic way to describe the same geometric situation.$t$,
$t$Identify a, b and c with their signs before calculating D. For parameter questions, translate the required root condition into D > 0, D = 0 or D < 0. When solving the resulting inequality, remember that dividing by a negative number reverses the inequality sign.$t$,
'p1:P1-QUA-02:theory:en:v1'
),
(
'p1:P1-QUA-02:tutor:ru:v2','P1','P1-QUA-02','ru','tutor_v2_learner_first',
'Дискриминант и корни',
$t$Дискриминант позволяет определить число действительных корней квадратного уравнения, не решая его полностью. Для

ax² + bx + c = 0

дискриминант равен

D = b² - 4ac.

Если D > 0, есть два различных действительных корня. Если D = 0, есть один повторяющийся действительный корень. Если D < 0, действительных корней нет.

Например, рассмотрим

x² - 4x + k = 0.

Здесь D = 16 - 4k. Для двух различных действительных корней нужно 16 - 4k > 0, значит k < 4. Повторяющийся корень получается при k = 4, а при k > 4 действительных корней нет. Поэтому дискриминант особенно удобен в задачах с параметром: условие о корнях превращается в уравнение или неравенство.$t$,
$t$Дискриминант — это быстрый тест для действительных корней квадратного уравнения.

D = b² - 4ac.

D > 0 означает два разных действительных корня, D = 0 — один повторяющийся корень, D < 0 — действительных корней нет.

Для x² - 4x + k = 0 имеем D = 16 - 4k. Поэтому два разных действительных корня требуют k < 4.$t$,
$t$Представьте график y = ax² + bx + c и ось x. Действительные корни — это x-координаты точек, где парабола встречается с осью x.

D > 0: график пересекает ось дважды.
D = 0: график касается оси один раз.
D < 0: график не пересекает ось.

Дискриминант — это алгебраический способ описать ту же геометрическую ситуацию.$t$,
$t$Сначала правильно определите a, b и c вместе с их знаками. В задачах с параметром переведите условие о корнях в D > 0, D = 0 или D < 0. Решая полученное неравенство, помните: при делении на отрицательное число знак неравенства меняется.$t$,
'p1:P1-QUA-02:theory:ru:v1'
),
(
'p1:P1-QUA-02:tutor:uz:v2','P1','P1-QUA-02','uz','tutor_v2_learner_first',
'Diskriminant va ildizlar',
$t$Diskriminant kvadrat tenglamani to‘liq yechmasdan turib uning nechta haqiqiy ildizi borligini aniqlashga yordam beradi. Agar

ax² + bx + c = 0

bo‘lsa, diskriminant

D = b² - 4ac

ga teng.

D > 0 bo‘lsa, ikkita turli haqiqiy ildiz bor. D = 0 bo‘lsa, bitta takroriy haqiqiy ildiz bor. D < 0 bo‘lsa, haqiqiy ildiz yo‘q.

Masalan,

x² - 4x + k = 0.

Bu yerda D = 16 - 4k. Ikkita turli haqiqiy ildiz uchun 16 - 4k > 0, ya’ni k < 4. Takroriy ildiz k = 4 da, haqiqiy ildiz yo‘qligi esa k > 4 da yuz beradi. Shuning uchun diskriminant parametrli masalalarda ildiz haqidagi shartni tenglama yoki tengsizlikka aylantiradi.$t$,
$t$Diskriminant kvadrat tenglamaning haqiqiy ildizlarini tez tekshirish usuli.

D = b² - 4ac.

D > 0 — ikkita turli haqiqiy ildiz, D = 0 — bitta takroriy ildiz, D < 0 — haqiqiy ildiz yo‘q.

x² - 4x + k = 0 uchun D = 16 - 4k. Demak, ikkita turli haqiqiy ildiz bo‘lishi uchun k < 4.$t$,
$t$y = ax² + bx + c grafigi va x o‘qini tasavvur qiling. Haqiqiy ildizlar parabola x o‘qi bilan uchrashadigan nuqtalarning x-koordinatalaridir.

D > 0: grafik o‘qni ikki marta kesadi.
D = 0: grafik o‘qqa bir marta tegadi.
D < 0: grafik o‘q bilan uchrashmaydi.

Demak, diskriminant shu geometrik holatni algebra orqali ifodalaydi.$t$,
$t$D ni hisoblashdan oldin a, b va c ni ishoralari bilan to‘g‘ri aniqlang. Parametrli masalada ildiz shartini D > 0, D = 0 yoki D < 0 ga aylantiring. Hosil bo‘lgan tengsizlikni yechishda manfiy songa bo‘lganda tengsizlik ishorasi o‘zgarishini unutmang.$t$,
'p1:P1-QUA-02:theory:uz:v1'
),
(
'p1:P1-QUA-03:tutor:en:v2','P1','P1-QUA-03','en','tutor_v2_learner_first',
'Solving quadratic equations',
$t$A quadratic equation can be solved in several ways, so the first decision is which method is most efficient. Always rearrange the equation into

ax² + bx + c = 0

first.

If it factors easily, factorisation is usually fastest. For example,

x² - 5x + 6 = 0
(x - 2)(x - 3) = 0,

so x = 2 or x = 3.

If neat factors are not obvious, the quadratic formula

x = (-b ± √(b² - 4ac))/(2a)

works for any quadratic with a ≠ 0. Completing the square is especially useful when you also want the completed-square form or graph information. The important skill is not forcing one method every time, but recognising which route fits the equation.$t$,
$t$First put the quadratic equal to zero. Then choose a method.

If the expression factors neatly, factorise it. For

x² - 5x + 6 = 0,

we get (x - 2)(x - 3) = 0, so x = 2 or 3.

If factorisation is not clear, use the quadratic formula. Completing the square is another valid route and is useful when the form of the quadratic also matters.$t$,
$t$Think of the three methods as different routes to the same roots.

Factorisation is a shortcut when the factors are easy to see.
The quadratic formula is the reliable general route.
Completing the square rewrites the equation into a form where the square can be isolated.

A good solver checks the structure first and chooses the route that gives the roots with the least unnecessary work.$t$,
$t$Before solving, make sure one side is zero. In factorisation, each factor is set equal to zero. In the quadratic formula, copy a, b and c with their signs and keep the ±. If you take a square root while completing the square, remember both positive and negative possibilities.$t$,
'p1:P1-QUA-03:theory:en:v1'
),
(
'p1:P1-QUA-03:tutor:ru:v2','P1','P1-QUA-03','ru','tutor_v2_learner_first',
'Решение квадратных уравнений',
$t$Квадратное уравнение можно решать несколькими способами, поэтому сначала стоит выбрать самый удобный. Сначала приведите уравнение к виду

ax² + bx + c = 0.

Если выражение легко раскладывается на множители, это обычно самый быстрый путь. Например,

x² - 5x + 6 = 0
(x - 2)(x - 3) = 0,

поэтому x = 2 или x = 3.

Если удобные множители не видны, можно использовать формулу

x = (-b ± √(b² - 4ac))/(2a),

которая работает для любого квадратного уравнения при a ≠ 0. Выделение полного квадрата особенно полезно, когда одновременно нужна форма квадратного выражения или информация о графике. Главное — не применять один способ всегда, а выбрать тот, который подходит структуре уравнения.$t$,
$t$Сначала перенесите всё так, чтобы одна сторона была равна нулю. Затем выберите способ.

Для

x² - 5x + 6 = 0

удобно разложить: (x - 2)(x - 3) = 0, значит x = 2 или 3.

Если разложение не видно, используйте квадратную формулу. Выделение полного квадрата — ещё один правильный путь, особенно когда важна форма выражения.$t$,
$t$Считайте три метода разными маршрутами к одним и тем же корням.

Разложение на множители — короткий путь, когда множители легко увидеть.
Квадратная формула — универсальный путь.
Выделение полного квадрата превращает уравнение в форму, где можно изолировать квадрат.

Сначала посмотрите на структуру уравнения и выберите маршрут без лишней работы.$t$,
$t$Перед решением убедитесь, что одна сторона равна нулю. При разложении каждый множитель приравнивается к нулю. В квадратной формуле внимательно подставляйте a, b и c вместе со знаками и не теряйте ±. При извлечении квадратного корня учитывайте оба знака.$t$,
'p1:P1-QUA-03:theory:ru:v1'
),
(
'p1:P1-QUA-03:tutor:uz:v2','P1','P1-QUA-03','uz','tutor_v2_learner_first',
'Kvadrat tenglamalarni yechish',
$t$Kvadrat tenglamani bir necha usulda yechish mumkin, shuning uchun avval eng qulay usulni tanlash kerak. Tenglamani avval

ax² + bx + c = 0

ko‘rinishiga keltiring.

Agar ifoda oson ko‘paytuvchilarga ajralsa, bu odatda eng tez usul. Masalan,

x² - 5x + 6 = 0
(x - 2)(x - 3) = 0,

demak x = 2 yoki x = 3.

Agar qulay ko‘paytuvchilar ko‘rinmasa,

x = (-b ± √(b² - 4ac))/(2a)

kvadrat formuladan foydalanish mumkin; u a ≠ 0 bo‘lgan har qanday kvadrat tenglama uchun ishlaydi. To‘liq kvadratga keltirish esa ifodaning shakli yoki grafik haqidagi ma’lumot ham kerak bo‘lganda qulay. Muhimi — har safar bitta usulni majburan ishlatish emas, tenglamaga mos yo‘lni tanlash.$t$,
$t$Avval tenglamaning bir tomonini nolga teng qiling. Keyin usulni tanlang.

x² - 5x + 6 = 0

uchun ko‘paytuvchilarga ajratish qulay: (x - 2)(x - 3) = 0, demak x = 2 yoki 3.

Agar ajratish oson ko‘rinmasa, kvadrat formuladan foydalaning. To‘liq kvadratga keltirish ham to‘g‘ri usul, ayniqsa ifodaning shakli ham muhim bo‘lsa.$t$,
$t$Uch usulni bir xil ildizlarga olib boradigan turli yo‘llar deb o‘ylang.

Ko‘paytuvchilarga ajratish — ko‘paytuvchilar tez ko‘rinsa, qisqa yo‘l.
Kvadrat formula — umumiy va ishonchli yo‘l.
To‘liq kvadratga keltirish — kvadratni ajratib olish mumkin bo‘lgan shaklga o‘tkazadi.

Avval tenglama tuzilishiga qarab, ortiqcha ish qilmaydigan yo‘lni tanlang.$t$,
$t$Yechishdan oldin bir tomon nol ekanini tekshiring. Ko‘paytuvchilarga ajratishda har bir ko‘paytuvchini nolga tenglang. Kvadrat formulada a, b va c ni ishoralari bilan yozing va ± ni yo‘qotmang. Kvadrat ildiz olganda ikkala ishorani ham hisobga oling.$t$,
'p1:P1-QUA-03:theory:uz:v1'
),
(
'p1:P1-QUA-04:tutor:en:v2','P1','P1-QUA-04','en','tutor_v2_learner_first',
'Quadratic inequalities',
$t$To solve a quadratic inequality, first find the roots of the related quadratic equation. The roots split the number line into intervals where the quadratic keeps the same sign.

For example,

x² - 5x + 6 > 0
(x - 2)(x - 3) > 0.

The roots are 2 and 3. Because the coefficient of x² is positive, the parabola opens upward, so the expression is positive outside the roots and negative between them. Therefore

x < 2 or x > 3.

The inequality is strict, so 2 and 3 are not included. If the question were x² - 5x + 6 ≤ 0, the answer would instead be 2 ≤ x ≤ 3. The key is to solve for the roots first, then choose the intervals with the required sign.$t$,
$t$Find the roots first. They divide the number line into sign regions.

For

x² - 5x + 6 > 0,

the roots are 2 and 3. The parabola opens upward, so the expression is positive outside the roots.

Therefore x < 2 or x > 3.

A strict inequality does not include the roots; ≤ or ≥ does include them when the expression equals zero there.$t$,
$t$You can view a quadratic inequality as a graph question. Ask: where is the parabola above or below the x-axis?

For y = (x - 2)(x - 3), the graph crosses the axis at x = 2 and x = 3. Since it opens upward, it is above the axis before 2 and after 3, and below the axis between the roots.

That picture gives the same intervals as a sign chart.$t$,
$t$Do not stop after finding the roots: the answer is an interval or union of intervals. Check whether the leading coefficient makes the parabola open upward or downward, and check whether the endpoints are included. Use open endpoints for < or > and include roots for ≤ or ≥.$t$,
'p1:P1-QUA-04:theory:en:v1'
),
(
'p1:P1-QUA-04:tutor:ru:v2','P1','P1-QUA-04','ru','tutor_v2_learner_first',
'Квадратные неравенства',
$t$Чтобы решить квадратное неравенство, сначала найдите корни соответствующего квадратного уравнения. Корни делят числовую прямую на промежутки, на каждом из которых знак квадратного выражения постоянен.

Например,

x² - 5x + 6 > 0
(x - 2)(x - 3) > 0.

Корни равны 2 и 3. Коэффициент при x² положительный, поэтому парабола направлена вверх: выражение положительно вне корней и отрицательно между ними. Значит,

x < 2 или x > 3.

Неравенство строгое, поэтому 2 и 3 не входят в ответ. Если бы было x² - 5x + 6 ≤ 0, ответ был бы 2 ≤ x ≤ 3. Главная идея: сначала найти корни, затем выбрать промежутки с нужным знаком.$t$,
$t$Сначала найдите корни. Они делят числовую прямую на области с разными знаками.

Для

x² - 5x + 6 > 0

корни равны 2 и 3. Парабола направлена вверх, поэтому выражение положительно снаружи от корней.

Ответ: x < 2 или x > 3.

При строгом неравенстве корни не включаются; при ≤ или ≥ корни включаются, если выражение там равно нулю.$t$,
$t$Можно воспринимать квадратное неравенство как вопрос о графике: где парабола находится выше или ниже оси x?

Для y = (x - 2)(x - 3) график пересекает ось при x = 2 и x = 3. Так как ветви направлены вверх, график выше оси до 2 и после 3, а между корнями — ниже.

Эта картина даёт те же промежутки, что и таблица знаков.$t$,
$t$Не останавливайтесь после нахождения корней: ответ должен быть промежутком или объединением промежутков. Проверьте знак старшего коэффициента и включение границ. Для < или > корни не включаются, для ≤ или ≥ включаются.$t$,
'p1:P1-QUA-04:theory:ru:v1'
),
(
'p1:P1-QUA-04:tutor:uz:v2','P1','P1-QUA-04','uz','tutor_v2_learner_first',
'Kvadrat tengsizliklar',
$t$Kvadrat tengsizlikni yechish uchun avval unga mos kvadrat tenglamaning ildizlarini toping. Ildizlar sonlar o‘qini kvadrat ifodaning ishorasi o‘zgarmaydigan oraliqlarga ajratadi.

Masalan,

x² - 5x + 6 > 0
(x - 2)(x - 3) > 0.

Ildizlar 2 va 3. x² oldidagi koeffitsiyent musbat, shuning uchun parabola yuqoriga ochiladi: ifoda ildizlardan tashqarida musbat, ular orasida esa manfiy. Demak,

x < 2 yoki x > 3.

Tengsizlik qat’iy bo‘lgani uchun 2 va 3 javobga kirmaydi. Agar x² - 5x + 6 ≤ 0 bo‘lsa, javob 2 ≤ x ≤ 3 bo‘ladi. Asosiy g‘oya: avval ildizlarni toping, keyin kerakli ishoraga ega oraliqlarni tanlang.$t$,
$t$Avval ildizlarni toping. Ular sonlar o‘qini ishora oraliqlariga bo‘ladi.

x² - 5x + 6 > 0

uchun ildizlar 2 va 3. Parabola yuqoriga ochilgani sabab ifoda ildizlardan tashqarida musbat.

Javob: x < 2 yoki x > 3.

< yoki > da ildizlar kiritilmaydi; ≤ yoki ≥ da ifoda nol bo‘ladigan ildizlar kiritiladi.$t$,
$t$Kvadrat tengsizlikni grafik savoli deb ham ko‘rish mumkin: parabola x o‘qining qayerida yuqorida yoki pastda?

y = (x - 2)(x - 3) grafigi x = 2 va x = 3 da o‘qni kesadi. Parabola yuqoriga ochiladi, shuning uchun 2 dan oldin va 3 dan keyin o‘qdan yuqorida, ildizlar orasida esa pastda bo‘ladi.

Bu rasm ishoralar jadvali bilan bir xil oraliqlarni beradi.$t$,
$t$Ildizlarni topish bilan to‘xtamang: javob oraliq yoki oraliqlar birlashmasi bo‘ladi. Yetakchi koeffitsiyent parabola yuqoriga yoki pastga ochilishini tekshiring va chegaralar kiradimi-yo‘qmi aniqlang. < yoki > da ildizlar kirmaydi, ≤ yoki ≥ da kiradi.$t$,
'p1:P1-QUA-04:theory:uz:v1'
),
(
'p1:P1-QUA-05:tutor:en:v2','P1','P1-QUA-05','en','tutor_v2_learner_first',
'Linear–quadratic systems',
$t$A linear–quadratic system asks for values that satisfy both a line and a quadratic relation. Substitution turns the two equations into one quadratic.

For example,

y = x + 1
y = x² - 3x + 1.

Because both expressions equal y, set them equal:

x + 1 = x² - 3x + 1
x² - 4x = 0
x(x - 4) = 0.

So x = 0 or x = 4. Substitute each value back into y = x + 1:

x = 0 gives y = 1,
x = 4 gives y = 5.

The two solutions are therefore (0, 1) and (4, 5). These are exactly the intersection points of the line and the quadratic graph.$t$,
$t$Use substitution to reduce the system to one equation.

For

y = x + 1
and
y = x² - 3x + 1,

set the two expressions for y equal:

x + 1 = x² - 3x + 1.

This gives x² - 4x = 0, so x = 0 or 4. Then substitute back to get y = 1 or 5.

The solutions are (0, 1) and (4, 5).$t$,
$t$Think of the system as an intersection problem. A solution must lie on both graphs at the same time.

The line y = x + 1 and the parabola y = x² - 3x + 1 meet where their y-values are equal. Setting the equations equal finds the possible x-coordinates. Substituting each x back gives the matching y-coordinate.

That is why a linear–quadratic system can have two, one or no real intersection points.$t$,
$t$After substitution, solve the whole quadratic and keep every valid x-value. Then find the matching y-value for each one; x-values alone are not complete solutions. Present solutions as ordered pairs when the variables are coordinates, and check each pair satisfies both original equations.$t$,
'p1:P1-QUA-05:theory:en:v1'
),
(
'p1:P1-QUA-05:tutor:ru:v2','P1','P1-QUA-05','ru','tutor_v2_learner_first',
'Линейно-квадратные системы',
$t$Линейно-квадратная система требует найти значения, которые одновременно удовлетворяют прямой и квадратной зависимости. Подстановка превращает два уравнения в одно квадратное.

Например,

y = x + 1
y = x² - 3x + 1.

Оба выражения равны y, поэтому приравниваем их:

x + 1 = x² - 3x + 1
x² - 4x = 0
x(x - 4) = 0.

Отсюда x = 0 или x = 4. Подставляем каждое значение в y = x + 1:

при x = 0 получаем y = 1,
при x = 4 получаем y = 5.

Значит, решения системы — (0, 1) и (4, 5). Это именно точки пересечения прямой и графика квадратной функции.$t$,
$t$Используйте подстановку, чтобы превратить систему в одно уравнение.

Для

y = x + 1
и
y = x² - 3x + 1

приравниваем правые части:

x + 1 = x² - 3x + 1.

Получаем x² - 4x = 0, поэтому x = 0 или 4. Затем подставляем обратно и получаем y = 1 или 5.

Решения: (0, 1) и (4, 5).$t$,
$t$Представьте систему как задачу о пересечении графиков. Решение должно одновременно лежать и на прямой, и на параболе.

Прямая y = x + 1 и парабола y = x² - 3x + 1 пересекаются там, где их значения y одинаковы. Поэтому мы приравниваем уравнения, находим возможные x, а затем для каждого x восстанавливаем соответствующее y.

Так становится понятно, почему решений может быть два, одно или ни одного действительного.$t$,
$t$После подстановки решите квадратное уравнение полностью и сохраните все допустимые значения x. Затем найдите соответствующее y для каждого x: одних x недостаточно. Если переменные задают координаты, записывайте ответы парами и проверяйте их в обоих исходных уравнениях.$t$,
'p1:P1-QUA-05:theory:ru:v1'
),
(
'p1:P1-QUA-05:tutor:uz:v2','P1','P1-QUA-05','uz','tutor_v2_learner_first',
'Chiziqli-kvadrat sistemalar',
$t$Chiziqli-kvadrat sistema bir vaqtning o‘zida ham chiziqli, ham kvadrat bog‘lanishni qanoatlantiradigan qiymatlarni topishni talab qiladi. Almashtirish ikki tenglamani bitta kvadrat tenglamaga keltiradi.

Masalan,

y = x + 1
y = x² - 3x + 1.

Ikkala ifoda ham y ga teng, shuning uchun ularni tenglashtiramiz:

x + 1 = x² - 3x + 1
x² - 4x = 0
x(x - 4) = 0.

Demak, x = 0 yoki x = 4. Har birini y = x + 1 ga qo‘yamiz:

x = 0 bo‘lsa y = 1,
x = 4 bo‘lsa y = 5.

Shuning uchun yechimlar (0, 1) va (4, 5). Bular chiziq va kvadrat grafikning aynan kesishish nuqtalaridir.$t$,
$t$Almashtirish yordamida sistemani bitta tenglamaga keltiring.

y = x + 1
va
y = x² - 3x + 1

uchun o‘ng tomonlarni tenglashtiramiz:

x + 1 = x² - 3x + 1.

Bundan x² - 4x = 0, ya’ni x = 0 yoki 4. So‘ng orqaga qo‘yib y = 1 yoki 5 ni topamiz.

Yechimlar: (0, 1) va (4, 5).$t$,
$t$Sistemani grafiklar kesishishi deb tasavvur qiling. Yechim bir vaqtda ikkala grafikda ham yotishi kerak.

y = x + 1 chizig‘i va y = x² - 3x + 1 parabolasi ularning y qiymatlari teng bo‘lgan joyda kesishadi. Tenglamalarni tenglashtirish x koordinatalarni beradi, har bir x ni orqaga qo‘yish esa mos y ni beradi.

Shu sabab bunday sistema ikkita, bitta yoki hech qanday haqiqiy kesishish nuqtasiga ega bo‘lishi mumkin.$t$,
$t$Almashtirishdan keyin kvadrat tenglamani to‘liq yeching va barcha yaroqli x qiymatlarni saqlang. Keyin har bir x uchun mos y ni toping: faqat x qiymatlari to‘liq yechim emas. Koordinata masalasida javobni juftlik sifatida yozing va ikkala boshlang‘ich tenglamada tekshiring.$t$,
'p1:P1-QUA-05:theory:uz:v1'
),
(
'p1:P1-QUA-06:tutor:en:v2','P1','P1-QUA-06','en','tutor_v2_learner_first',
'Reducing to a quadratic',
$t$Some equations are not written as quadratics in x, but they become quadratic after a useful substitution. Look for the same expression appearing as a first power and a square.

For example,

x⁴ - 5x² + 4 = 0.

Because x⁴ = (x²)², let

u = x².

The equation becomes

u² - 5u + 4 = 0
(u - 1)(u - 4) = 0,

so u = 1 or u = 4.

Now return to the original variable:

x² = 1 gives x = ±1,
x² = 4 gives x = ±2.

Therefore x = -2, -1, 1 or 2. The substitution only simplifies the structure; the final answer must always be converted back to the original variable.$t$,
$t$If an equation contains something and its square, replace that repeated expression with a new variable.

For

x⁴ - 5x² + 4 = 0,

let u = x². Then

u² - 5u + 4 = 0,

so u = 1 or 4. Finally return to x:

x² = 1 gives x = ±1,
x² = 4 gives x = ±2.

So x = -2, -1, 1 or 2.$t$,
$t$Think of substitution as temporarily hiding a complicated expression behind a simpler name.

In x⁴ - 5x² + 4 = 0, the repeated building block is x². Calling it u reveals an ordinary quadratic:

u² - 5u + 4 = 0.

Once that easier equation is solved, remove the temporary label u and translate every solution back into x. The algebra is simpler, but the original variable still controls the final answer.$t$,
$t$Do not stop at the substituted variable. Every u-solution must be converted back to x, and that step can create more than one x-value. Also check restrictions created by the substitution: for example, if u = x² in real-number work, then u cannot be negative.$t$,
'p1:P1-QUA-06:theory:en:v1'
),
(
'p1:P1-QUA-06:tutor:ru:v2','P1','P1-QUA-06','ru','tutor_v2_learner_first',
'Сведение к квадратному уравнению',
$t$Некоторые уравнения не выглядят квадратными относительно x, но становятся квадратными после подходящей замены. Ищите одно и то же выражение в первой и второй степени.

Например,

x⁴ - 5x² + 4 = 0.

Так как x⁴ = (x²)², положим

u = x².

Тогда получаем

u² - 5u + 4 = 0
(u - 1)(u - 4) = 0,

поэтому u = 1 или u = 4.

Теперь возвращаемся к исходной переменной:

x² = 1 даёт x = ±1,
x² = 4 даёт x = ±2.

Итак, x = -2, -1, 1 или 2. Замена только упрощает структуру уравнения; окончательный ответ всегда нужно вернуть к исходной переменной.$t$,
$t$Если в уравнении встречаются некоторое выражение и его квадрат, временно замените это выражение новой переменной.

Для

x⁴ - 5x² + 4 = 0

положим u = x². Тогда получаем

u² - 5u + 4 = 0,

откуда u = 1 или 4. Возвращаемся к x:

x² = 1 даёт x = ±1,
x² = 4 даёт x = ±2.

Ответ: x = -2, -1, 1, 2.$t$,
$t$Представьте замену как временное короткое имя для сложного повторяющегося выражения.

В x⁴ - 5x² + 4 = 0 таким блоком является x². Если назвать его u, сразу появляется обычное квадратное уравнение:

u² - 5u + 4 = 0.

После его решения временное обозначение нужно убрать и перевести каждый найденный u обратно в x. Замена упрощает алгебру, но окончательный ответ остаётся в исходной переменной.$t$,
$t$Не останавливайтесь на значениях новой переменной. Каждый найденный u нужно вернуть к x, и один u может дать несколько значений x. Также проверяйте ограничения замены: например, если u = x² и рассматриваются действительные числа, u не может быть отрицательным.$t$,
'p1:P1-QUA-06:theory:ru:v1'
),
(
'p1:P1-QUA-06:tutor:uz:v2','P1','P1-QUA-06','uz','tutor_v2_learner_first',
'Kvadrat tenglamaga keltirish',
$t$Ba’zi tenglamalar x ga nisbatan kvadrat ko‘rinishda yozilmagan bo‘ladi, lekin mos almashtirishdan keyin kvadrat tenglamaga aylanadi. Bir xil ifoda birinchi va ikkinchi darajada takrorlanayotganini qidiring.

Masalan,

x⁴ - 5x² + 4 = 0.

x⁴ = (x²)² bo‘lgani uchun

u = x²

deb olamiz. Shunda

u² - 5u + 4 = 0
(u - 1)(u - 4) = 0,

ya’ni u = 1 yoki u = 4.

Endi boshlang‘ich o‘zgaruvchiga qaytamiz:

x² = 1 dan x = ±1,
x² = 4 dan x = ±2.

Demak, x = -2, -1, 1 yoki 2. Almashtirish faqat tenglama tuzilishini soddalashtiradi; yakuniy javob albatta boshlang‘ich o‘zgaruvchiga qaytarilishi kerak.$t$,
$t$Agar tenglamada biror ifoda va uning kvadrati takrorlansa, shu ifodani vaqtincha yangi o‘zgaruvchi bilan almashtiring.

x⁴ - 5x² + 4 = 0

uchun u = x² deb olamiz. Shunda

u² - 5u + 4 = 0,

demak u = 1 yoki 4. Endi x ga qaytamiz:

x² = 1 dan x = ±1,
x² = 4 dan x = ±2.

Javob: x = -2, -1, 1, 2.$t$,
$t$Almashtirishni murakkab takroriy ifodaga vaqtinchalik qisqa nom berish deb o‘ylang.

x⁴ - 5x² + 4 = 0 da takroriy blok x². Uni u deb atasak, oddiy kvadrat tenglama paydo bo‘ladi:

u² - 5u + 4 = 0.

Uni yechgach, vaqtinchalik u belgisini olib tashlab, har bir yechimni x ga qaytaramiz. Algebra soddalashadi, lekin yakuniy javob boshlang‘ich o‘zgaruvchida bo‘ladi.$t$,
$t$Yangi o‘zgaruvchi qiymatlarida to‘xtamang. Har bir u yechimni x ga qaytaring; bitta u bir nechta x qiymatini berishi mumkin. Almashtirish cheklovlarini ham tekshiring: masalan, haqiqiy sonlarda u = x² bo‘lsa, u manfiy bo‘la olmaydi.$t$,
'p1:P1-QUA-06:theory:uz:v1'
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
  v_runtime integer;
  v_all_v2 integer;
  v_bad_link integer;
begin
  select count(*),count(*) filter(where is_runtime_allowed)
    into v_new,v_runtime
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code in ('P1-QUA-02','P1-QUA-03','P1-QUA-04','P1-QUA-05','P1-QUA-06');

  if v_new<>15 then
    raise exception 'Block 2 expected 15 new Tutor Cards, found %',v_new;
  end if;
  if v_runtime<>0 then
    raise exception 'Block 2 Tutor Cards must remain runtime OFF';
  end if;

  select count(*) into v_all_v2
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft'
    and not is_runtime_allowed;

  if v_all_v2<>24 then
    raise exception 'Block 2 expected 24 learner-first draft cards after insert, found %',v_all_v2;
  end if;

  select count(*) into v_bad_link
  from private.exam_prep_ai_tutor_cards t
  join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
  where t.content_version='tutor_v2_learner_first'
    and t.skill_code in ('P1-QUA-02','P1-QUA-03','P1-QUA-04','P1-QUA-05','P1-QUA-06')
    and (
      s.component_code<>t.component_code
      or s.skill_code<>t.skill_code
      or s.locale<>t.locale
      or s.card_type<>'theory'
      or s.approval_status<>'approved'
      or not s.is_runtime_allowed
    );

  if v_bad_link<>0 then
    raise exception 'Block 2 source-card linkage drift: %',v_bad_link;
  end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and approval_status='draft'
      and not is_runtime_allowed
      and (
        position(E'\n' in main_explanation)=0
        or position(E'\n' in simple_explanation)=0
        or position(E'\n' in alternative_explanation)=0
      )
  ) then
    raise exception 'Learner-first Tutor Card formatting must contain real line breaks';
  end if;
end
$postcheck$;

commit;
