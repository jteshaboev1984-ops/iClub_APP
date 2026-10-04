-- Curated Tutor Cards Block 3: P1 Functions P1-FUN-01...08.
-- 8 skills x 3 locales = 24 new DRAFT cards. Runtime remains OFF.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $precheck$
declare
  v_existing integer;
  v_sources integer;
  v_baseline integer;
begin
  select count(*) into v_existing
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code in (
      'P1-FUN-01','P1-FUN-02','P1-FUN-03','P1-FUN-04',
      'P1-FUN-05','P1-FUN-06','P1-FUN-07','P1-FUN-08'
    );

  if v_existing<>0 then
    raise exception 'Block 3 refuses to overwrite existing learner-first Functions cards: %',v_existing;
  end if;

  select count(*) into v_sources
  from private.exam_prep_ai_source_cards
  where approval_status='approved'
    and is_runtime_allowed
    and card_type='theory'
    and component_code='P1'
    and skill_code in (
      'P1-FUN-01','P1-FUN-02','P1-FUN-03','P1-FUN-04',
      'P1-FUN-05','P1-FUN-06','P1-FUN-07','P1-FUN-08'
    )
    and locale in ('en','ru','uz');

  if v_sources<>24 then
    raise exception 'Block 3 requires exactly 24 approved/runtime theory sources, found %',v_sources;
  end if;

  select count(*) into v_baseline
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft'
    and not is_runtime_allowed;

  if v_baseline<>24 then
    raise exception 'Block 3 requires exactly 24 reviewed learner-first draft cards from Blocks 1-2, found %',v_baseline;
  end if;
end
$precheck$;

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,
  source_card_key
) as (
values
(
'p1:P1-FUN-01:tutor:en:v2','P1','P1-FUN-01','en','tutor_v2_learner_first',
'Functions: domain and range',
$t$A function is a rule that gives exactly one output for each allowed input. The domain is the set of inputs you are allowed to use, while the range is the set of outputs the function actually produces.

For example, if f(x)=2x+1 with domain all real numbers, every real x is allowed and every real output is possible, so the range is also all real numbers. For example, f(3)=7.

A function is one-to-one when different allowed inputs never produce the same output. That matters because only then can the mapping be reversed to make an inverse function. A composition such as f(g(x)) means “apply g first, then feed its output into f”. These words all describe the same idea: how inputs are allowed, transformed and connected to outputs.$t$,
$t$Think of a function as an input-output machine. The domain tells you which inputs may enter. The range tells you which outputs can come out.

For f(x)=2x+1, the input 3 gives 7. If the domain is all real numbers, both domain and range are all real numbers.

“One-to-one” means one output does not come from two different allowed inputs. An inverse reverses a one-to-one machine, and a composition connects two machines in order.$t$,
$t$A useful way to read function notation is as a mapping.

x → f(x).

The domain lives on the input side; the range lives on the output side. An inverse swaps the direction of a one-to-one mapping. A composition joins mappings: in f(g(x)), x goes through g first and then through f.

So domain, range, one-to-one, inverse and composition are not separate pieces of vocabulary — they describe different parts of the same mapping process.$t$,
$t$Do not confuse domain with range: domain is about allowed x-values, range is about resulting outputs. In f(g(x)), work from the inside out: g first, then f. Before talking about an inverse, check that the function is one-to-one on the stated domain.$t$,
'p1:P1-FUN-01:theory:en:v1'
),
(
'p1:P1-FUN-01:tutor:ru:v2','P1','P1-FUN-01','ru','tutor_v2_learner_first',
'Функция: область и значения',
$t$Функция — это правило, которое каждому допустимому входному значению ставит в соответствие ровно одно выходное значение. Область определения — это множество значений x, которые разрешено подставлять, а область значений — множество результатов, которые функция действительно может принимать.

Например, для f(x)=2x+1 с областью определения всех действительных чисел разрешено любое действительное x, и получить можно любое действительное значение, поэтому область значений тоже состоит из всех действительных чисел. При x=3 получаем f(3)=7.

Функция взаимно однозначна, если разные допустимые входы не дают один и тот же выход. Тогда отображение можно обратить и получить обратную функцию. Запись f(g(x)) означает: сначала применить g, затем результат подставить в f. Все эти понятия описывают один процесс — как входы превращаются в выходы.$t$,
$t$Представьте функцию как машину «вход → выход». Область определения говорит, какие входы разрешены. Область значений показывает, какие результаты могут получиться.

Для f(x)=2x+1 вход 3 даёт 7. Если разрешены все действительные x, то и область определения, и область значений — все действительные числа.

«Взаимно однозначная» означает, что один выход не получается из двух разных допустимых входов. Обратная функция разворачивает такое соответствие, а композиция соединяет две функции по порядку.$t$,
$t$Удобно воспринимать функцию как отображение

x → f(x).

Область определения находится на стороне входов, область значений — на стороне выходов. Обратная функция разворачивает взаимно однозначное отображение. Композиция соединяет два отображения: в f(g(x)) значение x сначала проходит через g, а затем через f.

Поэтому область, значения, взаимная однозначность, обратная функция и композиция — это разные стороны одной идеи отображения.$t$,
$t$Не путайте область определения и область значений: первая относится к допустимым x, вторая — к получаемым результатам. В f(g(x)) начинайте изнутри: сначала g, затем f. Перед нахождением обратной функции обязательно проверьте взаимную однозначность на заданной области.$t$,
'p1:P1-FUN-01:theory:ru:v1'
),
(
'p1:P1-FUN-01:tutor:uz:v2','P1','P1-FUN-01','uz','tutor_v2_learner_first',
'Funksiya: soha va qiymatlar',
$t$Funksiya — har bir ruxsat etilgan kirish qiymatiga aynan bitta chiqish qiymatini mos qo‘yadigan qoida. Aniqlanish sohasi — x uchun ruxsat etilgan qiymatlar to‘plami, qiymatlar to‘plami esa funksiya haqiqatan hosil qiladigan natijalardir.

Masalan, f(x)=2x+1 va aniqlanish sohasi barcha haqiqiy sonlar bo‘lsin. Istalgan haqiqiy x ni qo‘yish mumkin va istalgan haqiqiy natijani olish mumkin, shuning uchun qiymatlar to‘plami ham barcha haqiqiy sonlar bo‘ladi. x=3 bo‘lsa, f(3)=7.

Funksiya bir-biriga mos, ya’ni one-to-one bo‘lsa, turli ruxsat etilgan kirishlar bir xil chiqishni bermaydi. Shunda moslikni teskariga aylantirib teskari funksiya tuzish mumkin. f(g(x)) yozuvi avval g ni, keyin uning natijasiga f ni qo‘llashni bildiradi. Bu tushunchalarning barchasi kirishdan chiqishga bo‘lgan bitta moslikni tasvirlaydi.$t$,
$t$Funksiyani «kirish → chiqish» mashinasi deb tasavvur qiling. Aniqlanish sohasi qaysi kirishlar mumkinligini, qiymatlar to‘plami esa qaysi natijalar chiqishini aytadi.

f(x)=2x+1 uchun 3 kirishi 7 natijani beradi. Agar barcha haqiqiy x lar ruxsat etilgan bo‘lsa, aniqlanish sohasi ham, qiymatlar to‘plami ham barcha haqiqiy sonlardir.

One-to-one funksiya bir xil chiqishni ikki xil kirishdan bermaydi. Teskari funksiya shu moslikni teskariga o‘giradi, kompozitsiya esa ikki funksiyani ketma-ket bog‘laydi.$t$,
$t$Funksiyani moslik sifatida o‘qing:

x → f(x).

Aniqlanish sohasi kirish tomonida, qiymatlar to‘plami chiqish tomonida turadi. Teskari funksiya one-to-one moslik yo‘nalishini teskariga o‘giradi. Kompozitsiya ikki moslikni ulaydi: f(g(x)) da x avval g dan, keyin f dan o‘tadi.

Demak, soha, qiymatlar, one-to-one, teskari funksiya va kompozitsiya bitta jarayonning turli qismlaridir.$t$,
$t$Aniqlanish sohasi bilan qiymatlar to‘plamini aralashtirmang: birinchisi ruxsat etilgan x lar, ikkinchisi hosil bo‘ladigan natijalar haqida. f(g(x)) da ichkaridan boshlang: avval g, so‘ng f. Teskari funksiya tuzishdan oldin berilgan sohada funksiya one-to-one ekanini tekshiring.$t$,
'p1:P1-FUN-01:theory:uz:v1'
),
(
'p1:P1-FUN-02:tutor:en:v2','P1','P1-FUN-02','en','tutor_v2_learner_first',
'Range of a function',
$t$The range depends on the outputs produced by the allowed inputs, so a domain restriction can change it.

Suppose

f(x)=x²,  -2≤x≤3.

The smallest output is 0, reached at x=0. At the endpoints, f(-2)=4 and f(3)=9, so the largest output is 9. Therefore the range is

0≤f(x)≤9.

It would be wrong to use the unrestricted range x²≥0 and stop there, because the domain tells us that x may only run from -2 to 3. For a curve with a turning point inside the allowed domain, check that turning point as well as the endpoints. The range is the complete set of y-values the restricted part of the graph actually reaches.$t$,
$t$The domain tells you which x-values you may use. The range is what those allowed x-values produce.

For f(x)=x² with -2≤x≤3, the graph includes x=0, so the minimum output is 0. The endpoint outputs are 4 and 9, so the maximum is 9.

Hence the range is

0≤f(x)≤9.$t$,
$t$Instead of thinking only algebraically, imagine covering the graph except for the part above the allowed domain. Then ask: which y-values are still visible?

For y=x² on -2≤x≤3, the visible part reaches down to y=0 and up to y=9. Every y-value between them occurs somewhere on that part of the graph.

That vertical span is the range.$t$,
$t$Use the stated domain, not the function’s unrestricted graph. For a restricted interval, check endpoints and any turning point inside the interval. Do not confuse input bounds with output bounds: -2≤x≤3 does not mean -2≤y≤3.$t$,
'p1:P1-FUN-02:theory:en:v1'
),
(
'p1:P1-FUN-02:tutor:ru:v2','P1','P1-FUN-02','ru','tutor_v2_learner_first',
'Область значений функции',
$t$Область значений зависит от результатов, которые дают разрешённые входы, поэтому ограничение области определения может её изменить.

Пусть

f(x)=x²,  -2≤x≤3.

Наименьшее значение равно 0 и достигается при x=0. На концах промежутка f(-2)=4 и f(3)=9, поэтому наибольшее значение равно 9. Значит, область значений:

0≤f(x)≤9.

Недостаточно просто вспомнить, что для x² значения неотрицательны: здесь x разрешён только от -2 до 3. Если внутри заданной области есть вершина или другая точка экстремума, её нужно проверить вместе с концами промежутка. Область значений — это все y, которых действительно достигает разрешённая часть графика.$t$,
$t$Область определения говорит, какие x можно использовать. Область значений — какие результаты дают именно эти x.

Для f(x)=x² при -2≤x≤3 точка x=0 разрешена, поэтому минимум равен 0. На концах получаем 4 и 9, значит максимум равен 9.

Итак,

0≤f(x)≤9.$t$,
$t$Можно представить, что весь график закрыт, кроме части над разрешённой областью x. Затем спросите: какие значения y остаются видимыми?

Для y=x² при -2≤x≤3 видимая часть опускается до y=0 и поднимается до y=9. Все промежуточные значения тоже достигаются.

Этот вертикальный диапазон и есть область значений.$t$,
$t$Всегда используйте указанную область определения, а не неограниченный график функции. На ограниченном промежутке проверяйте концы и вершину/экстремум, если он лежит внутри. Не переносите границы x напрямую на y: из -2≤x≤3 не следует -2≤y≤3.$t$,
'p1:P1-FUN-02:theory:ru:v1'
),
(
'p1:P1-FUN-02:tutor:uz:v2','P1','P1-FUN-02','uz','tutor_v2_learner_first',
'Funksiyaning qiymatlar to‘plami',
$t$Qiymatlar to‘plami ruxsat etilgan kirishlardan hosil bo‘ladigan natijalarga bog‘liq, shuning uchun aniqlanish sohasidagi cheklov uni o‘zgartirishi mumkin.

Masalan,

f(x)=x²,  -2≤x≤3.

Eng kichik qiymat 0 bo‘lib, x=0 da olinadi. Chegara nuqtalarda f(-2)=4 va f(3)=9, shuning uchun eng katta qiymat 9. Demak, qiymatlar to‘plami:

0≤f(x)≤9.

Faqat x²≥0 deb yozib to‘xtash noto‘g‘ri, chunki bu masalada x faqat -2 dan 3 gacha. Agar ruxsat etilgan oraliq ichida burilish yoki ekstremum nuqta bo‘lsa, uni ham chegaralar bilan birga tekshirish kerak. Qiymatlar to‘plami — grafikning ruxsat etilgan qismi oladigan barcha y qiymatlardir.$t$,
$t$Aniqlanish sohasi qaysi x larni ishlatish mumkinligini aytadi. Qiymatlar to‘plami esa aynan shu x lar qanday natijalar berishini ko‘rsatadi.

f(x)=x² va -2≤x≤3 bo‘lsa, x=0 ruxsat etilgan, demak minimum 0. Chegaralarda 4 va 9 chiqadi, demak maksimum 9.

Shuning uchun

0≤f(x)≤9.$t$,
$t$Grafikning faqat ruxsat etilgan x lar ustidagi qismini ko‘rib, qolganini yopib qo‘yganingizni tasavvur qiling. Endi qaysi y qiymatlar ko‘rinib turishini so‘rang.

y=x² uchun -2≤x≤3 da ko‘rinadigan qism y=0 gacha tushadi va y=9 gacha ko‘tariladi. Ularning orasidagi barcha qiymatlar ham olinadi.

Shu vertikal oraliq qiymatlar to‘plamidir.$t$,
$t$Berilgan aniqlanish sohasini ishlating, funksiyaning cheklanmagan grafigini emas. Cheklangan oraliqda chegaralarni va ichkaridagi burilish/ekstremum nuqtani tekshiring. x chegaralarini y ga ko‘chirib yozmang: -2≤x≤3 dan -2≤y≤3 kelib chiqmaydi.$t$,
'p1:P1-FUN-02:theory:uz:v1'
),
(
'p1:P1-FUN-03:tutor:en:v2','P1','P1-FUN-03','en','tutor_v2_learner_first',
'Composite functions',
$t$A composite function applies one function and then another. In

f(g(x)),

g acts first because it is closest to x; its output becomes the input of f.

Let

f(x)=2x+1,  g(x)=x².

Then

f(g(x))=f(x²)=2x²+1,

but

g(f(x))=g(2x+1)=(2x+1)².

So order matters: f∘g is usually not the same as g∘f. Composition is only valid for inputs where the inner function produces a value that the outer function is allowed to accept. In other words, the range produced at the first step must fit the domain required at the next step.$t$,
$t$For f(g(x)), start with g.

If f(x)=2x+1 and g(x)=x², then

f(g(x))=2x²+1.

If the order is reversed,

g(f(x))=(2x+1)².

These are different, so always read a composition from the inside out. Also check that the first output is allowed as an input to the next function.$t$,
$t$Imagine two machines connected in a line. The first machine changes x, then passes its result into the second.

In f(g(x)), the route is

x → g(x) → f(g(x)).

Changing the order changes the route, which is why f(g(x)) and g(f(x)) can be different. A route also fails if the first machine produces a value outside the second machine’s allowed input domain.$t$,
$t$Read compositions from the inside out. Substitute the whole inner expression into the outer function, using brackets. Do not assume f(g(x))=g(f(x)). If either function has a restricted domain, check that the intermediate output is permitted before accepting the composition.$t$,
'p1:P1-FUN-03:theory:en:v1'
),
(
'p1:P1-FUN-03:tutor:ru:v2','P1','P1-FUN-03','ru','tutor_v2_learner_first',
'Композиция функций',
$t$Композиция означает последовательное применение двух функций. В записи

f(g(x))

сначала действует g, потому что она находится ближе к x; её результат становится входом для f.

Пусть

f(x)=2x+1,  g(x)=x².

Тогда

f(g(x))=f(x²)=2x²+1,

а

g(f(x))=g(2x+1)=(2x+1)².

Порядок важен: обычно f∘g не совпадает с g∘f. Композиция допустима только для тех входов, при которых внутренняя функция выдаёт значение, разрешённое для внешней функции. Иначе говоря, результат первого шага должен попадать в область определения следующего.$t$,
$t$В f(g(x)) начинайте с g.

Если f(x)=2x+1, а g(x)=x², то

f(g(x))=2x²+1.

Если поменять порядок,

g(f(x))=(2x+1)².

Результаты разные, поэтому композицию всегда читайте изнутри наружу. Также проверьте, можно ли результат первой функции подставлять во вторую.$t$,
$t$Представьте две машины, соединённые последовательно. Первая меняет x, затем передаёт результат второй.

В f(g(x)) путь такой:

x → g(x) → f(g(x)).

Если поменять машины местами, путь изменится — поэтому f(g(x)) и g(f(x)) могут быть разными. Цепочка также не работает, если первая функция выдаёт значение вне допустимой области второй.$t$,
$t$Читайте композицию изнутри наружу. Всё внутреннее выражение подставляйте во внешнюю функцию в скобках. Не считайте f(g(x)) и g(f(x)) одинаковыми. При ограничениях области определения проверяйте, допустим ли промежуточный результат.$t$,
'p1:P1-FUN-03:theory:ru:v1'
),
(
'p1:P1-FUN-03:tutor:uz:v2','P1','P1-FUN-03','uz','tutor_v2_learner_first',
'Funksiyalar kompozitsiyasi',
$t$Funksiyalar kompozitsiyasi bir funksiyadan keyin ikkinchisini qo‘llashni anglatadi. Yozuvda

f(g(x))

avval g ishlaydi, chunki u x ga yaqinroq; uning natijasi f uchun kirish bo‘ladi.

f(x)=2x+1,  g(x)=x²

bo‘lsin. Unda

f(g(x))=f(x²)=2x²+1,

ammo

g(f(x))=g(2x+1)=(2x+1)².

Demak, tartib muhim: odatda f∘g va g∘f bir xil emas. Kompozitsiya faqat ichki funksiya hosil qilgan qiymat tashqi funksiyaning aniqlanish sohasiga kirganda ma’noli bo‘ladi. Ya’ni birinchi qadamdagi chiqish keyingi qadam uchun ruxsat etilgan kirish bo‘lishi kerak.$t$,
$t$f(g(x)) da g dan boshlang.

Agar f(x)=2x+1 va g(x)=x² bo‘lsa,

f(g(x))=2x²+1.

Tartibni almashtirsak,

g(f(x))=(2x+1)².

Natijalar turlicha, shuning uchun kompozitsiyani doimo ichkaridan tashqariga o‘qing. Birinchi natijani keyingi funksiyaga kiritish mumkinligini ham tekshiring.$t$,
$t$Ikkita mashina ketma-ket ulanganini tasavvur qiling. Birinchi mashina x ni o‘zgartiradi va natijani ikkinchisiga uzatadi.

f(g(x)) da yo‘l:

x → g(x) → f(g(x)).

Mashinalar tartibini o‘zgartirish yo‘lni ham o‘zgartiradi, shuning uchun f(g(x)) va g(f(x)) bir xil bo‘lmasligi mumkin. Birinchi mashina ikkinchisi qabul qilmaydigan qiymat bersa, zanjir ishlamaydi.$t$,
$t$Kompozitsiyani ichkaridan tashqariga o‘qing. Ichki ifodaning hammasini tashqi funksiyaga qavs bilan qo‘ying. f(g(x))=g(f(x)) deb faraz qilmang. Aniqlanish sohasi cheklangan bo‘lsa, oraliq natija ruxsat etilganini tekshiring.$t$,
'p1:P1-FUN-03:theory:uz:v1'
),
(
'p1:P1-FUN-04:tutor:en:v2','P1','P1-FUN-04','en','tutor_v2_learner_first',
'Inverse functions',
$t$An inverse function reverses a function: it takes an output back to the input that produced it. This only works as a function when the original function is one-to-one on its stated domain.

For

f(x)=2x+3,

write y=2x+3, swap x and y, then solve for y:

x=2y+3,
y=(x-3)/2.

So

f⁻¹(x)=(x-3)/2.

You can check the reversal: f(4)=11 and f⁻¹(11)=4.

By contrast, f(x)=x² is not one-to-one on all real numbers because 2 and -2 both give 4. A restriction such as x≥0 is needed before it has a single-valued inverse. The domain of the inverse comes from the range of the original function.$t$,
$t$An inverse undoes a function.

For f(x)=2x+3:

y=2x+3,
swap x and y:
x=2y+3,
then solve:
y=(x-3)/2.

Therefore f⁻¹(x)=(x-3)/2.

Always check that the original function is one-to-one on its domain. For example, x² is not one-to-one on all real x because 2 and -2 give the same output.$t$,
$t$Think of a one-to-one function as a reversible route.

f sends 4 → 11.
The inverse must send 11 → 4.

That is why the input and output roles swap when you find an inverse. If two different inputs arrive at the same output, the route cannot be uniquely reversed. This is exactly why a domain restriction may be needed before an inverse exists as a function.$t$,
$t$First check one-to-one behavior on the stated domain. When finding the inverse, swap x and y and then solve for y. Do not confuse f⁻¹(x) with 1/f(x). Also remember: the original range becomes the inverse domain, and the original domain becomes the inverse range.$t$,
'p1:P1-FUN-04:theory:en:v1'
),
(
'p1:P1-FUN-04:tutor:ru:v2','P1','P1-FUN-04','ru','tutor_v2_learner_first',
'Обратная функция',
$t$Обратная функция разворачивает действие функции: по выходному значению она возвращает тот вход, который его создал. Это возможно как функция только тогда, когда исходная функция взаимно однозначна на заданной области.

Для

f(x)=2x+3

запишем y=2x+3, поменяем x и y местами и выразим y:

x=2y+3,
y=(x-3)/2.

Значит,

f⁻¹(x)=(x-3)/2.

Проверка показывает обратимость: f(4)=11, а f⁻¹(11)=4.

Функция f(x)=x² на всех действительных числах не взаимно однозначна: 2 и -2 дают 4. Поэтому для однозначной обратной функции нужно ограничение, например x≥0. Область определения обратной функции получается из области значений исходной.$t$,
$t$Обратная функция отменяет действие исходной.

Для f(x)=2x+3:

y=2x+3,
меняем x и y:
x=2y+3,
выражаем y:
y=(x-3)/2.

Поэтому f⁻¹(x)=(x-3)/2.

Сначала убедитесь, что исходная функция взаимно однозначна. Например, x² на всех действительных x не подходит: 2 и -2 дают одинаковый результат.$t$,
$t$Представьте взаимно однозначную функцию как маршрут, который можно пройти назад.

f отправляет 4 → 11.
Обратная функция должна отправить 11 → 4.

Поэтому при нахождении обратной функции роли входа и выхода меняются местами. Если два разных входа приходят к одному выходу, однозначно вернуться назад нельзя — именно поэтому иногда приходится ограничивать область определения.$t$,
$t$Сначала проверьте взаимную однозначность на заданной области. При нахождении обратной функции поменяйте x и y местами и выразите y. Не путайте f⁻¹(x) с 1/f(x). Область значений исходной функции становится областью определения обратной, и наоборот.$t$,
'p1:P1-FUN-04:theory:ru:v1'
),
(
'p1:P1-FUN-04:tutor:uz:v2','P1','P1-FUN-04','uz','tutor_v2_learner_first',
'Teskari funksiya',
$t$Teskari funksiya funksiyaning ishini ortga qaytaradi: chiqish qiymatidan uni hosil qilgan kirishga qaytadi. Bu faqat boshlang‘ich funksiya berilgan sohada one-to-one bo‘lganda yagona funksiya sifatida ishlaydi.

Masalan,

f(x)=2x+3.

y=2x+3 deb yozamiz, x va y ni almashtiramiz va y ni topamiz:

x=2y+3,
y=(x-3)/2.

Demak,

f⁻¹(x)=(x-3)/2.

Tekshiruv: f(4)=11 va f⁻¹(11)=4.

f(x)=x² barcha haqiqiy sonlarda one-to-one emas, chunki 2 ham, -2 ham 4 ni beradi. Shuning uchun yagona teskari funksiya uchun, masalan, x≥0 kabi soha cheklovi kerak. Teskari funksiyaning aniqlanish sohasi boshlang‘ich funksiyaning qiymatlar to‘plamidan keladi.$t$,
$t$Teskari funksiya boshlang‘ich funksiyaning amalini bekor qiladi.

f(x)=2x+3 uchun:

y=2x+3,
x va y ni almashtiramiz:
x=2y+3,
y ni topamiz:
y=(x-3)/2.

Shunday qilib, f⁻¹(x)=(x-3)/2.

Avval funksiya one-to-one ekanini tekshiring. Masalan, x² barcha haqiqiy x larda one-to-one emas: 2 va -2 bir xil natija beradi.$t$,
$t$One-to-one funksiyani ortga yurish mumkin bo‘lgan yo‘l deb tasavvur qiling.

f: 4 → 11.
Teskari funksiya: 11 → 4.

Shuning uchun teskari funksiyada kirish va chiqish rollari almashadi. Agar ikki xil kirish bir xil chiqishga kelsa, orqaga yagona yo‘l bilan qaytib bo‘lmaydi. Shu sabab ayrim funksiyalarda sohani cheklash kerak.$t$,
$t$Avval berilgan sohada one-to-one ekanini tekshiring. Teskari funksiyani topishda x va y ni almashtirib, y ni ajrating. f⁻¹(x) ni 1/f(x) bilan aralashtirmang. Boshlang‘ich qiymatlar to‘plami teskari funksiyaning aniqlanish sohasiga, boshlang‘ich soha esa uning qiymatlar to‘plamiga aylanadi.$t$,
'p1:P1-FUN-04:theory:uz:v1'
),
(
'p1:P1-FUN-05:tutor:en:v2','P1','P1-FUN-05','en','tutor_v2_learner_first',
'Graphs of inverse functions',
$t$A function and its inverse swap input and output values, so their graph coordinates swap too. If the point

(1,5)

lies on y=f(x), then

(5,1)

lies on y=f⁻¹(x).

Swapping every point (x,y) to (y,x) is exactly a reflection in the line

y=x.

So the graph of an inverse function is the reflection of the original graph in y=x, provided the inverse exists as a function on the chosen domain. Points on y=x stay fixed because swapping their coordinates changes nothing. This geometric rule lets you sketch an inverse graph without re-deriving every coordinate algebraically.$t$,
$t$For an inverse, x and y swap roles.

If (1,5) is on y=f(x), then (5,1) is on y=f⁻¹(x).

Doing this to every point reflects the graph in the line

y=x.

So you can sketch an inverse by mirroring the original graph across y=x.$t$,
$t$Imagine folding the coordinate plane along the diagonal line y=x. The graph of f and the graph of f⁻¹ match when reflected across that fold.

A point 1 unit across and 5 units up becomes 5 units across and 1 unit up. That coordinate swap is the visual meaning of reversing a function.$t$,
$t$Use point mapping: (x,y)→(y,x). Draw or imagine the mirror line y=x. Do not confuse f⁻¹(x) with the reciprocal 1/f(x); those are different ideas. The inverse graph also swaps the original domain and range.$t$,
'p1:P1-FUN-05:theory:en:v1'
),
(
'p1:P1-FUN-05:tutor:ru:v2','P1','P1-FUN-05','ru','tutor_v2_learner_first',
'График обратной функции',
$t$Функция и её обратная меняют местами вход и выход, поэтому на графике координаты тоже меняются местами. Если точка

(1,5)

лежит на y=f(x), то точка

(5,1)

лежит на y=f⁻¹(x).

Замена каждой точки (x,y) на (y,x) — это ровно отражение относительно прямой

y=x.

Поэтому график обратной функции является зеркальным отражением исходного графика относительно y=x, если обратная функция существует на выбранной области. Точки на самой прямой y=x остаются на месте, потому что их координаты при перестановке не меняются. Это правило позволяет строить обратный график без повторного вычисления каждой точки.$t$,
$t$У обратной функции x и y меняются ролями.

Если (1,5) лежит на y=f(x), то (5,1) лежит на y=f⁻¹(x).

Такая перестановка всех точек отражает график относительно прямой

y=x.

Поэтому обратный график можно получить зеркальным отражением исходного.$t$,
$t$Представьте, что координатную плоскость складывают по диагонали y=x. Графики f и f⁻¹ совмещаются при таком отражении.

Точка с координатами (1,5) после отражения становится (5,1). Именно эта перестановка координат показывает на графике, что функция действует в обратном направлении.$t$,
$t$Используйте правило точек: (x,y)→(y,x), и ориентируйтесь на прямую y=x как на зеркало. Не путайте f⁻¹(x) с 1/f(x): это разные понятия. У обратной функции область определения и область значений исходной функции меняются местами.$t$,
'p1:P1-FUN-05:theory:ru:v1'
),
(
'p1:P1-FUN-05:tutor:uz:v2','P1','P1-FUN-05','uz','tutor_v2_learner_first',
'Teskari funksiya grafigi',
$t$Funksiya va uning teskarisi kirish va chiqish qiymatlarini almashtiradi, shuning uchun grafikdagi koordinatalar ham o‘rin almashadi. Agar

(1,5)

nuqta y=f(x) grafigida bo‘lsa,

(5,1)

nuqta y=f⁻¹(x) grafigida bo‘ladi.

Har bir (x,y) nuqtani (y,x) ga almashtirish aynan

y=x

to‘g‘ri chizig‘iga nisbatan akslantirishdir.

Shuning uchun tanlangan sohada teskari funksiya mavjud bo‘lsa, uning grafigi boshlang‘ich grafikning y=x ga nisbatan aksidir. y=x ustidagi nuqtalar o‘zgarmaydi, chunki ularning koordinatalarini almashtirish hech narsani o‘zgartirmaydi. Bu qoida teskari grafikni barcha nuqtalarni qayta hisoblamasdan chizishga yordam beradi.$t$,
$t$Teskari funksiyada x va y rollari almashadi.

Agar (1,5) nuqta y=f(x) da bo‘lsa, (5,1) nuqta y=f⁻¹(x) da bo‘ladi.

Barcha nuqtalarni shunday almashtirish grafikni

y=x

chizig‘iga nisbatan akslantiradi.

Demak, teskari grafikni boshlang‘ich grafikni y=x ga nisbatan oynadagi kabi akslantirib chizish mumkin.$t$,
$t$Koordinata tekisligini y=x diagonal chizig‘i bo‘ylab buklayotganingizni tasavvur qiling. f va f⁻¹ grafiklari shu buklashda bir-biriga mos tushadi.

(1,5) nuqta (5,1) ga o‘tadi. Koordinatalarning aynan shu almashishi funksiyaning teskari yo‘nalishini grafikda ko‘rsatadi.$t$,
$t$Nuqtalar uchun (x,y)→(y,x) qoidasidan foydalaning va y=x ni oyna chizig‘i deb o‘ylang. f⁻¹(x) ni 1/f(x) bilan aralashtirmang. Teskari funksiyada boshlang‘ich aniqlanish sohasi va qiymatlar to‘plami o‘rin almashadi.$t$,
'p1:P1-FUN-05:theory:uz:v1'
),
(
'p1:P1-FUN-06:tutor:en:v2','P1','P1-FUN-06','en','tutor_v2_learner_first',
'Graph translations',
$t$A translation moves a graph without changing its shape.

Starting from y=f(x):

y=f(x)+a

moves the graph vertically by a: up if a>0, down if a<0.

For a horizontal shift,

y=f(x-a)

moves the graph right by a. The sign inside the function looks opposite to the direction of movement.

For example, from y=x²,

y=(x-3)²+2

is the same parabola shifted 3 units right and 2 units up. Its vertex moves from (0,0) to (3,2). A translation changes every point by the same amount, so the graph keeps the same shape and size.$t$,
$t$Translations slide a graph.

y=f(x)+2 moves it up 2.
y=f(x)-2 moves it down 2.
y=f(x-3) moves it right 3.
y=f(x+3) moves it left 3.

So y=(x-3)²+2 is y=x² shifted right 3 and up 2.$t$,
$t$Track a point instead of memorising only formulas. If (x,y) lies on y=f(x), then under

y=f(x-3)+2

that point moves to

(x+3, y+2).

Every point moves by the same vector, so the whole graph slides without changing shape. This point-mapping view explains why the horizontal sign appears reversed inside f.$t$,
$t$Changes outside f(x) move the graph vertically in the same signed direction. Changes inside f move it horizontally in the opposite-looking direction: f(x-a) is right by a. Check a known point or the vertex to confirm the direction.$t$,
'p1:P1-FUN-06:theory:en:v1'
),
(
'p1:P1-FUN-06:tutor:ru:v2','P1','P1-FUN-06','ru','tutor_v2_learner_first',
'Сдвиги графиков',
$t$Сдвиг перемещает график, не изменяя его форму.

Для y=f(x):

y=f(x)+a

сдвигает график по вертикали на a: вверх при a>0 и вниз при a<0.

Для горизонтального сдвига

y=f(x-a)

перемещает график вправо на a. Знак внутри функции выглядит противоположным направлению движения.

Например, из y=x² получаем

y=(x-3)²+2.

Это та же парабола, сдвинутая на 3 вправо и на 2 вверх. Её вершина перемещается из (0,0) в (3,2). При сдвиге каждая точка перемещается одинаково, поэтому форма и размеры графика сохраняются.$t$,
$t$Сдвиг просто перемещает график.

y=f(x)+2 — вверх на 2.
y=f(x)-2 — вниз на 2.
y=f(x-3) — вправо на 3.
y=f(x+3) — влево на 3.

Поэтому y=(x-3)²+2 — это y=x², сдвинутый на 3 вправо и на 2 вверх.$t$,
$t$Можно следить не за формулой, а за одной точкой. Если (x,y) лежит на y=f(x), то при преобразовании

y=f(x-3)+2

эта точка переходит в

(x+3, y+2).

Все точки двигаются на один и тот же вектор, поэтому весь график просто скользит. Так видно, почему знак горизонтального сдвига внутри f выглядит противоположным.$t$,
$t$Изменение снаружи f(x) двигает график по вертикали в том же направлении знака. Изменение внутри f действует по горизонтали с «обратным» знаком: f(x-a) — вправо на a. Проверяйте направление по знакомой точке или вершине.$t$,
'p1:P1-FUN-06:theory:ru:v1'
),
(
'p1:P1-FUN-06:tutor:uz:v2','P1','P1-FUN-06','uz','tutor_v2_learner_first',
'Grafiklarni siljitish',
$t$Siljitish grafikning shaklini o‘zgartirmasdan uning joyini o‘zgartiradi.

y=f(x) dan boshlasak,

y=f(x)+a

grafikni vertikal yo‘nalishda a ga siljitadi: a>0 bo‘lsa yuqoriga, a<0 bo‘lsa pastga.

Gorizontal siljitishda

y=f(x-a)

grafikni a birlik o‘ngga siljitadi. Funksiya ichidagi ishora harakat yo‘nalishiga teskari ko‘rinadi.

Masalan, y=x² dan

y=(x-3)²+2

hosil qilinsa, parabola 3 birlik o‘ngga va 2 birlik yuqoriga siljiydi. Uning uchi (0,0) dan (3,2) ga o‘tadi. Siljitishda barcha nuqtalar bir xil miqdorga ko‘chadi, shuning uchun grafikning shakli va o‘lchami saqlanadi.$t$,
$t$Siljitish grafikni joyidan ko‘chiradi.

y=f(x)+2 — 2 birlik yuqoriga.
y=f(x)-2 — 2 birlik pastga.
y=f(x-3) — 3 birlik o‘ngga.
y=f(x+3) — 3 birlik chapga.

Demak, y=(x-3)²+2 grafigi y=x² ni 3 o‘ngga va 2 yuqoriga siljitishdan hosil bo‘ladi.$t$,
$t$Faqat formulani yodlash o‘rniga bitta nuqtani kuzating. Agar (x,y) nuqta y=f(x) da bo‘lsa,

y=f(x-3)+2

da u

(x+3, y+2)

nuqtaga o‘tadi.

Barcha nuqtalar bir xil vektor bilan ko‘chadi, shuning uchun butun grafik sirpanadi. Shu qarash f ichidagi gorizontal ishora nega teskari ko‘rinishini tushuntiradi.$t$,
$t$f(x) tashqarisidagi o‘zgarish grafikni vertikal ravishda ishora ko‘rsatgan tomonga siljitadi. f ichidagi o‘zgarish gorizontal yo‘nalishda teskari ko‘rinadi: f(x-a) — a birlik o‘ngga. Yo‘nalishni tanish nuqta yoki uch orqali tekshiring.$t$,
'p1:P1-FUN-06:theory:uz:v1'
),
(
'p1:P1-FUN-07:tutor:en:v2','P1','P1-FUN-07','en','tutor_v2_learner_first',
'Graph reflections',
$t$A reflection flips a graph across an axis.

For y=f(x),

y=-f(x)

reflects the graph in the x-axis. Every point (x,y) becomes (x,-y).

By contrast,

y=f(-x)

reflects the graph in the y-axis. Every point (x,y) becomes (-x,y).

So if (2,6) lies on the original graph, an x-axis reflection gives (2,-6), while a y-axis reflection gives (-2,6). The useful distinction is where the minus sign appears: outside f changes the output y; inside f changes the input x. The shape stays the same, but its orientation is mirrored.$t$,
$t$There are two basic reflection rules.

y=-f(x): reflect in the x-axis, so (x,y)→(x,-y).

y=f(-x): reflect in the y-axis, so (x,y)→(-x,y).

For the point (2,6), these give (2,-6) and (-2,6) respectively.$t$,
$t$Ask which coordinate must change sign.

Reflecting in the x-axis keeps the x-position but flips height, so y changes sign.

Reflecting in the y-axis keeps height but flips left and right, so x changes sign.

That is exactly why -f(x) acts on y, while f(-x) acts on x.$t$,
$t$Look at the location of the minus sign. Outside the function, -f(x), means an x-axis reflection. Inside the input, f(-x), means a y-axis reflection. Map a known point to check: only one coordinate should change sign.$t$,
'p1:P1-FUN-07:theory:en:v1'
),
(
'p1:P1-FUN-07:tutor:ru:v2','P1','P1-FUN-07','ru','tutor_v2_learner_first',
'Отражения графиков',
$t$Отражение зеркально переворачивает график относительно оси.

Для y=f(x)

y=-f(x)

отражает график относительно оси x. Каждая точка (x,y) переходит в (x,-y).

А

y=f(-x)

отражает график относительно оси y. Каждая точка (x,y) переходит в (-x,y).

Если точка (2,6) лежит на исходном графике, после отражения относительно оси x получаем (2,-6), а относительно оси y — (-2,6). Главное — смотреть, где стоит минус: снаружи f меняется выход y, внутри f меняется вход x. Форма сохраняется, меняется только зеркальная ориентация.$t$,
$t$Есть два основных правила.

y=-f(x): отражение относительно оси x, поэтому (x,y)→(x,-y).

y=f(-x): отражение относительно оси y, поэтому (x,y)→(-x,y).

Для точки (2,6) получаем соответственно (2,-6) и (-2,6).$t$,
$t$Спросите, какая координата должна поменять знак.

При отражении относительно оси x положение по x остаётся тем же, но высота меняется на противоположную — значит меняется знак y.

При отражении относительно оси y высота сохраняется, а лево и право меняются местами — значит меняется знак x.

Поэтому -f(x) действует на y, а f(-x) — на x.$t$,
$t$Смотрите, где стоит минус. Снаружи функции, -f(x), означает отражение относительно оси x. Внутри аргумента, f(-x), — отражение относительно оси y. Для проверки возьмите известную точку: знак должна изменить только одна координата.$t$,
'p1:P1-FUN-07:theory:ru:v1'
),
(
'p1:P1-FUN-07:tutor:uz:v2','P1','P1-FUN-07','uz','tutor_v2_learner_first',
'Grafiklarni akslantirish',
$t$Akslantirish grafikni o‘qqa nisbatan oynadagi kabi teskariga o‘giradi.

y=f(x) uchun

y=-f(x)

grafikni x o‘qiga nisbatan akslantiradi. Har bir (x,y) nuqta (x,-y) ga o‘tadi.

y=f(-x)

esa grafikni y o‘qiga nisbatan akslantiradi. Har bir (x,y) nuqta (-x,y) ga o‘tadi.

Agar (2,6) nuqta boshlang‘ich grafikda bo‘lsa, x o‘qiga nisbatan akslantirish (2,-6) ni, y o‘qiga nisbatan akslantirish esa (-2,6) ni beradi. Muhimi, minus qayerda turganiga qarang: f tashqarisidagi minus chiqish y ni, f ichidagi minus kirish x ni o‘zgartiradi.$t$,
$t$Ikki asosiy qoida bor.

y=-f(x): x o‘qiga nisbatan akslantirish, ya’ni (x,y)→(x,-y).

y=f(-x): y o‘qiga nisbatan akslantirish, ya’ni (x,y)→(-x,y).

(2,6) nuqta mos ravishda (2,-6) va (-2,6) ga o‘tadi.$t$,
$t$Qaysi koordinata ishorasi o‘zgarishi kerakligini so‘rang.

x o‘qiga nisbatan akslantirishda x joyi saqlanadi, balandlik teskarilanadi — y ishorasi o‘zgaradi.

y o‘qiga nisbatan akslantirishda balandlik saqlanadi, chap va o‘ng almashadi — x ishorasi o‘zgaradi.

Shuning uchun -f(x) y ga, f(-x) esa x ga ta’sir qiladi.$t$,
$t$Minus qayerda turganini tekshiring. -f(x) dagi tashqi minus x o‘qiga nisbatan akslantirishni, f(-x) dagi ichki minus y o‘qiga nisbatan akslantirishni bildiradi. Tanish nuqta bilan tekshiring: faqat bitta koordinataning ishorasi o‘zgarishi kerak.$t$,
'p1:P1-FUN-07:theory:uz:v1'
),
(
'p1:P1-FUN-08:tutor:en:v2','P1','P1-FUN-08','en','tutor_v2_learner_first',
'Graph stretches and compressions',
$t$Stretches and compressions change the scale of a graph.

For

y=af(x),

the y-coordinate is multiplied by a. With a positive a, this is a vertical scale factor a. So a point (1,1) on y=f(x) becomes (1,2) on y=2f(x).

For

y=f(bx),

the horizontal scale factor is 1/|b|. So the same point (1,1) corresponds to (1/2,1) on y=f(2x).

In a simple combination such as

y=2f(x-3)+1,

a point (x,y) on the original graph maps to

(x+3, 2y+1).

The key distinction is that changes outside f act directly on y, while changes inside f act inversely on x.$t$,
$t$Outside the function changes vertical size:

y=2f(x)

doubles every y-value, so (1,1)→(1,2).

Inside the function changes horizontal size inversely:

y=f(2x)

has horizontal scale factor 1/2, so (1,1)→(1/2,1).

For combinations, transform the coordinates step by step.$t$,
$t$Track coordinates rather than the whole curve.

If (x,y) is on y=f(x), then:
- y=af(x) sends it to (x,ay);
- y=f(bx) sends it to (x/b,y).

That explains the “inverse” horizontal factor. In y=2f(x-3)+1, the original point becomes (x+3,2y+1): shift x first, then scale and shift y.$t$,
$t$Outside f affects y directly; inside f affects x inversely. So f(2x) is a horizontal compression with factor 1/2, not a stretch by 2. When several transformations are combined, use point mapping to avoid mixing horizontal and vertical effects.$t$,
'p1:P1-FUN-08:theory:en:v1'
),
(
'p1:P1-FUN-08:tutor:ru:v2','P1','P1-FUN-08','ru','tutor_v2_learner_first',
'Растяжения и сжатия графиков',
$t$Растяжения и сжатия изменяют масштаб графика.

Для

y=af(x)

координата y умножается на a. При положительном a это вертикальный коэффициент масштаба a. Поэтому точка (1,1) на y=f(x) переходит в (1,2) на y=2f(x).

Для

y=f(bx)

горизонтальный коэффициент масштаба равен 1/|b|. Поэтому та же точка (1,1) соответствует точке (1/2,1) на y=f(2x).

В простом сочетании

y=2f(x-3)+1

точка (x,y) исходного графика переходит в

(x+3, 2y+1).

Главное различие: преобразования снаружи f прямо действуют на y, а преобразования внутри f действуют на x с обратным масштабом.$t$,
$t$Изменение снаружи функции меняет вертикальный масштаб:

y=2f(x)

удваивает каждое y, поэтому (1,1)→(1,2).

Изменение внутри функции действует по горизонтали обратно:

y=f(2x)

имеет горизонтальный коэффициент 1/2, поэтому (1,1)→(1/2,1).

При сочетании преобразований удобно менять координаты по шагам.$t$,
$t$Следите за координатами точки, а не за всем графиком.

Если (x,y) лежит на y=f(x), то:
- y=af(x) переводит её в (x,ay);
- y=f(bx) переводит её в (x/b,y).

Так становится понятен «обратный» горизонтальный коэффициент. В y=2f(x-3)+1 исходная точка становится (x+3,2y+1): x сначала сдвигается, а y затем масштабируется и сдвигается.$t$,
$t$Снаружи f преобразование действует на y напрямую, внутри f — на x обратно. Поэтому f(2x) — горизонтальное сжатие с коэффициентом 1/2, а не растяжение в 2 раза. При нескольких преобразованиях используйте отображение точек, чтобы не смешивать горизонтальные и вертикальные изменения.$t$,
'p1:P1-FUN-08:theory:ru:v1'
),
(
'p1:P1-FUN-08:tutor:uz:v2','P1','P1-FUN-08','uz','tutor_v2_learner_first',
'Grafiklarni cho‘zish va siqish',
$t$Cho‘zish va siqish grafik masshtabini o‘zgartiradi.

y=af(x)

da y-koordinata a ga ko‘payadi. a musbat bo‘lsa, bu vertikal masshtab koeffitsiyenti a. Masalan, y=f(x) dagi (1,1) nuqta y=2f(x) da (1,2) ga o‘tadi.

y=f(bx)

da gorizontal masshtab koeffitsiyenti 1/|b| bo‘ladi. Shu sabab (1,1) nuqta y=f(2x) da (1/2,1) ga mos keladi.

Oddiy kombinatsiyada

y=2f(x-3)+1

boshlang‘ich (x,y) nuqta

(x+3, 2y+1)

ga o‘tadi.

Asosiy farq: f tashqarisidagi o‘zgarish y ga to‘g‘ridan-to‘g‘ri, f ichidagi o‘zgarish esa x ga teskari masshtab bilan ta’sir qiladi.$t$,
$t$Funksiya tashqarisidagi o‘zgarish vertikal o‘lchamni o‘zgartiradi:

y=2f(x)

har bir y ni ikki baravar qiladi, demak (1,1)→(1,2).

Funksiya ichidagi o‘zgarish gorizontal o‘lchamga teskari ta’sir qiladi:

y=f(2x)

uchun gorizontal koeffitsiyent 1/2, demak (1,1)→(1/2,1).

Kombinatsiyada koordinatalarni bosqichma-bosqich o‘zgartiring.$t$,
$t$Butun grafik o‘rniga bitta nuqta koordinatalarini kuzating.

Agar (x,y) nuqta y=f(x) da bo‘lsa:
- y=af(x) uni (x,ay) ga o‘tkazadi;
- y=f(bx) uni (x/b,y) ga o‘tkazadi.

Shu sabab gorizontal koeffitsiyent «teskari» ko‘rinadi. y=2f(x-3)+1 da boshlang‘ich nuqta (x+3,2y+1) ga o‘tadi: avval x siljiydi, keyin y masshtablanib siljiydi.$t$,
$t$f tashqarisidagi o‘zgarish y ga bevosita, f ichidagi o‘zgarish x ga teskari ta’sir qiladi. Shuning uchun f(2x) gorizontal yo‘nalishda 2 marta cho‘zilish emas, 1/2 koeffitsiyentli siqilishdir. Bir nechta o‘zgarish bo‘lsa, gorizontal va vertikal ta’sirlarni aralashtirmaslik uchun nuqta tasviridan foydalaning.$t$,
'p1:P1-FUN-08:theory:uz:v1'
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
    and skill_code in (
      'P1-FUN-01','P1-FUN-02','P1-FUN-03','P1-FUN-04',
      'P1-FUN-05','P1-FUN-06','P1-FUN-07','P1-FUN-08'
    );

  if v_new<>24 then
    raise exception 'Block 3 expected 24 new Tutor Cards, found %',v_new;
  end if;
  if v_runtime<>0 then
    raise exception 'Block 3 Tutor Cards must remain runtime OFF';
  end if;

  select count(*) into v_all_v2
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft'
    and not is_runtime_allowed;

  if v_all_v2<>48 then
    raise exception 'Block 3 expected 48 learner-first draft cards after insert, found %',v_all_v2;
  end if;

  select count(*) into v_bad_link
  from private.exam_prep_ai_tutor_cards t
  join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
  where t.content_version='tutor_v2_learner_first'
    and t.skill_code in (
      'P1-FUN-01','P1-FUN-02','P1-FUN-03','P1-FUN-04',
      'P1-FUN-05','P1-FUN-06','P1-FUN-07','P1-FUN-08'
    )
    and (
      s.component_code<>t.component_code
      or s.skill_code<>t.skill_code
      or s.locale<>t.locale
      or s.card_type<>'theory'
      or s.approval_status<>'approved'
      or not s.is_runtime_allowed
    );

  if v_bad_link<>0 then
    raise exception 'Block 3 source-card linkage drift: %',v_bad_link;
  end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v2_learner_first'
      and skill_code like 'P1-FUN-%'
      and (
        position(E'\\n' in main_explanation)>0
        or position(E'\\n' in simple_explanation)>0
        or position(E'\\n' in alternative_explanation)>0
        or position(E'\\n' in focus_explanation)>0
      )
  ) then
    raise exception 'Block 3 contains literal backslash-n formatting';
  end if;
end
$postcheck$;

commit;
