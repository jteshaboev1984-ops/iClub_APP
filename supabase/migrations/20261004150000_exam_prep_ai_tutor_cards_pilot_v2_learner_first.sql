-- Curated Tutor Card pilot v2 — learner-first standard.
-- Supersedes the original never-runtime draft pilot without deleting history.
-- 3 skills x 3 locales = 9 new DRAFT cards. Runtime remains OFF.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $precheck$
declare
  v_old_total integer;
  v_old_runtime integer;
  v_old_approved integer;
begin
  select count(*),
         count(*) filter(where is_runtime_allowed),
         count(*) filter(where approval_status='approved')
    into v_old_total,v_old_runtime,v_old_approved
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v1'
    and skill_code in ('P1-QUA-01','P1-COO-02','P5-NOR-02');

  if v_old_total<>9 then
    raise exception 'Tutor pilot v2 expected exactly 9 original pilot rows, found %',v_old_total;
  end if;
  if v_old_runtime<>0 or v_old_approved<>0 then
    raise exception 'Tutor pilot v2 refuses to supersede runtime/approved content';
  end if;
end
$precheck$;

update private.exam_prep_ai_tutor_cards
set approval_status='retired',
    is_runtime_allowed=false,
    updated_at=now()
where content_version='tutor_v1'
  and skill_code in ('P1-QUA-01','P1-COO-02','P5-NOR-02')
  and approval_status='draft'
  and is_runtime_allowed=false;

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,
  source_card_key
) as (
values
(
'p1:P1-QUA-01:tutor:en:v2','P1','P1-QUA-01','en','tutor_v2_learner_first',
'Completing the square',
'Completing the square rewrites a quadratic so its shape and turning point are easier to see. For example:\n\nx² + 6x + 5\n\nHalf of 6 is 3, so start with (x + 3)². But (x + 3)² = x² + 6x + 9, so we must remove the extra 4:\n\nx² + 6x + 5 = (x + 3)² - 4.\n\nNow the quadratic is in completed-square form. For y = x² + 6x + 5, the turning point is (-3, -4). The main idea is simple: create a square bracket, but keep the expression exactly equivalent by compensating for whatever you added.',
'We want to turn part of the quadratic into one squared bracket.\n\nFor x² + 6x + 5, half of 6 is 3, so try (x + 3)². This expands to x² + 6x + 9, which is 4 too large. Therefore:\n\nx² + 6x + 5 = (x + 3)² - 4.\n\nThe expression has changed form, but not value.',
'Think of completing the square as expanding brackets in reverse.\n\nBecause (x + 3)² expands to x² + 6x + 9, the terms x² + 6x suggest that the square bracket should be (x + 3)². The original constant is 5 rather than 9, so the difference stays outside as -4.\n\nThat is why x² + 6x + 5 becomes (x + 3)² - 4.',
'Check three things: take half of the x-coefficient, not the whole coefficient; compensate for the number introduced when you create the square; and remember that in (x - h)² the turning-point x-coordinate is h, so the sign inside the bracket looks opposite.',
'p1:P1-QUA-01:theory:en:v1'
),
(
'p1:P1-QUA-01:tutor:ru:v2','P1','P1-QUA-01','ru','tutor_v2_learner_first',
'Выделение полного квадрата',
'Выделение полного квадрата позволяет переписать квадратное выражение так, чтобы легче увидеть форму параболы и её вершину. Например:\n\nx² + 6x + 5\n\nПоловина коэффициента 6 равна 3, поэтому начинаем с (x + 3)². Но (x + 3)² = x² + 6x + 9, то есть мы получили лишние 4. Значит:\n\nx² + 6x + 5 = (x + 3)² - 4.\n\nТеперь выражение записано в форме полного квадрата. Для y = x² + 6x + 5 вершина находится в точке (-3, -4). Главная идея: создать квадрат скобки и одновременно сохранить выражение равным исходному, компенсируя всё, что было добавлено.',
'Мы хотим превратить часть квадратного выражения в один квадрат скобки.\n\nДля x² + 6x + 5 половина от 6 равна 3, поэтому пробуем (x + 3)². После раскрытия это x² + 6x + 9 — на 4 больше, чем нужно. Поэтому:\n\nx² + 6x + 5 = (x + 3)² - 4.\n\nФорма записи изменилась, но значение выражения осталось тем же.',
'Представьте, что вы раскрываете скобки в обратную сторону.\n\nТак как (x + 3)² раскрывается в x² + 6x + 9, члены x² + 6x подсказывают, что квадратная скобка должна быть (x + 3)². В исходном выражении постоянный член равен 5, а не 9, поэтому разница -4 остаётся снаружи.\n\nОтсюда x² + 6x + 5 = (x + 3)² - 4.',
'Проверьте три вещи: берите половину коэффициента при x, а не весь коэффициент; компенсируйте число, появившееся при создании квадрата; в (x - h)² координата вершины по x равна h, поэтому знак внутри скобки выглядит противоположным.',
'p1:P1-QUA-01:theory:ru:v1'
),
(
'p1:P1-QUA-01:tutor:uz:v2','P1','P1-QUA-01','uz','tutor_v2_learner_first',
'To‘liq kvadratga keltirish',
'To‘liq kvadratga keltirish kvadrat ifodani parabola shakli va uning uchini osonroq ko‘rish mumkin bo‘lgan ko‘rinishda yozishga yordam beradi. Masalan:\n\nx² + 6x + 5\n\n6 ning yarmi 3, shuning uchun (x + 3)² dan boshlaymiz. Lekin (x + 3)² = x² + 6x + 9, ya’ni 4 ortiqcha hosil bo‘ladi. Demak:\n\nx² + 6x + 5 = (x + 3)² - 4.\n\nEndi ifoda to‘liq kvadrat ko‘rinishida. y = x² + 6x + 5 grafigining uchi (-3, -4) nuqtada. Asosiy g‘oya: kvadrat qavs hosil qiling, lekin qo‘shilgan qiymatni kompensatsiya qilib ifodani aynan teng saqlang.',
'Kvadrat ifodaning bir qismini bitta kvadrat qavsga aylantirmoqchimiz.\n\nx² + 6x + 5 uchun 6 ning yarmi 3, shuning uchun (x + 3)² ni olamiz. Uni ochsak x² + 6x + 9 chiqadi — bu kerakligidan 4 ga katta. Shuning uchun:\n\nx² + 6x + 5 = (x + 3)² - 4.\n\nYozilish shakli o‘zgardi, lekin ifodaning qiymati o‘zgarmadi.',
'Buni qavslarni ochish jarayonini teskari bajarish deb o‘ylang.\n\n(x + 3)² ochilganda x² + 6x + 9 hosil bo‘ladi. Demak, x² + 6x hadlari kvadrat qavs (x + 3)² bo‘lishini ko‘rsatadi. Boshlang‘ich doimiy had 9 emas, 5 bo‘lgani uchun farq -4 tashqarida qoladi.\n\nShu sabab x² + 6x + 5 = (x + 3)² - 4.',
'Uch narsani tekshiring: x oldidagi koeffitsiyentning yarmini oling, butun koeffitsiyentni emas; kvadrat hosil qilishda paydo bo‘lgan sonni kompensatsiya qiling; (x - h)² da uchning x-koordinatasi h bo‘ladi, shuning uchun qavs ichidagi ishora teskari ko‘rinadi.',
'p1:P1-QUA-01:theory:uz:v1'
),
(
'p1:P1-COO-02:tutor:en:v2','P1','P1-COO-02','en','tutor_v2_learner_first',
'Distance, midpoint and intersection',
'Coordinate geometry turns information about points into equations and measurements. Suppose A(1, 2) and B(5, 10). The gradient is\n\n(10 - 2)/(5 - 1) = 2,\n\nthe midpoint is ((1 + 5)/2, (2 + 10)/2) = (3, 6), and the distance is\n\n√((5 - 1)² + (10 - 2)²) = 4√5.\n\nKnowing point A and gradient 2 also gives the line y - 2 = 2(x - 1), or y = 2x. If another line is y = -x + 8, their intersection is found by solving 2x = -x + 8. The key is to identify what the question gives you, then choose the relation that connects it to what you need.',
'With coordinates, use the information you are given to choose the right tool. Two points can give gradient, midpoint or distance. A point plus a gradient gives a line equation. Two line equations give an intersection when you solve them together.\n\nFor A(1, 2) and B(5, 10), the gradient is 2 and the midpoint is (3, 6).',
'Think of coordinate geometry as a chain of connections.\n\nTwo points → gradient, midpoint or distance.\nPoint + gradient → equation of a line.\nTwo lines → intersection.\n\nYou do not need a separate strategy for every question. First identify which link you already have, then move along the chain to the quantity the question asks for.',
'Keep subtraction order consistent in the gradient: if you use y₂ - y₁, also use x₂ - x₁. For a midpoint, average x with x and y with y. For an intersection, the final point must satisfy both line equations, so substitute it back to check.',
'p1:P1-COO-02:theory:en:v1'
),
(
'p1:P1-COO-02:tutor:ru:v2','P1','P1-COO-02','ru','tutor_v2_learner_first',
'Расстояние, середина и пересечение',
'Координатная геометрия превращает информацию о точках в уравнения и измерения. Пусть A(1, 2) и B(5, 10). Тогда угловой коэффициент равен\n\n(10 - 2)/(5 - 1) = 2,\n\nсередина отрезка — ((1 + 5)/2, (2 + 10)/2) = (3, 6), а расстояние —\n\n√((5 - 1)² + (10 - 2)²) = 4√5.\n\nТочка A и коэффициент 2 также задают прямую y - 2 = 2(x - 1), то есть y = 2x. Если другая прямая имеет вид y = -x + 8, точку пересечения находим из 2x = -x + 8. Главная идея — определить, что дано в задаче, и выбрать связь, которая приводит к нужной величине.',
'В координатных задачах сначала смотрите, какая информация уже дана. Две точки позволяют найти угловой коэффициент, середину или расстояние. Точка и угловой коэффициент задают уравнение прямой. Две прямые дают точку пересечения, если решить их уравнения вместе.\n\nДля A(1, 2) и B(5, 10) угловой коэффициент равен 2, а середина — (3, 6).',
'Представьте координатную геометрию как цепочку связей.\n\nДве точки → угловой коэффициент, середина или расстояние.\nТочка + угловой коэффициент → уравнение прямой.\nДве прямые → точка пересечения.\n\nНе нужно искать отдельный способ для каждой задачи: определите, какое звено уже известно, и двигайтесь к величине, которую нужно найти.',
'При вычислении углового коэффициента сохраняйте один порядок вычитания: если в числителе y₂ - y₁, то в знаменателе x₂ - x₁. Для середины усредняйте x с x и y с y. Найденная точка пересечения должна удовлетворять обоим уравнениям — это хороший способ проверки.',
'p1:P1-COO-02:theory:ru:v1'
),
(
'p1:P1-COO-02:tutor:uz:v2','P1','P1-COO-02','uz','tutor_v2_learner_first',
'Masofa, o‘rta nuqta va kesishish',
'Koordinata geometriyasi nuqtalar haqidagi ma’lumotni tenglama va o‘lchovlarga aylantiradi. A(1, 2) va B(5, 10) bo‘lsin. Gradient\n\n(10 - 2)/(5 - 1) = 2,\n\no‘rta nuqta ((1 + 5)/2, (2 + 10)/2) = (3, 6), masofa esa\n\n√((5 - 1)² + (10 - 2)²) = 4√5.\n\nA nuqta va 2 gradient chiziqni ham aniqlaydi: y - 2 = 2(x - 1), ya’ni y = 2x. Agar ikkinchi chiziq y = -x + 8 bo‘lsa, kesishish nuqtasini 2x = -x + 8 tenglamadan topamiz. Asosiy g‘oya — masalada nima berilganini aniqlash va kerakli natijaga olib boradigan bog‘lanishni tanlash.',
'Koordinata masalalarida avval sizga nima berilganini aniqlang. Ikki nuqta orqali gradient, o‘rta nuqta yoki masofani topish mumkin. Nuqta va gradient chiziq tenglamasini beradi. Ikki chiziq esa tenglamalarni birgalikda yechish orqali kesishish nuqtasini beradi.\n\nA(1, 2) va B(5, 10) uchun gradient 2, o‘rta nuqta esa (3, 6).',
'Koordinata geometriyasini bog‘lanishlar zanjiri deb tasavvur qiling.\n\nIkki nuqta → gradient, o‘rta nuqta yoki masofa.\nNuqta + gradient → chiziq tenglamasi.\nIkki chiziq → kesishish nuqtasi.\n\nHar bir masala uchun alohida usul yodlash shart emas. Avval qaysi bog‘lanish sizda borligini aniqlang, so‘ng kerakli kattalikka o‘ting.',
'Gradientni topishda ayirish tartibini bir xil saqlang: suratda y₂ - y₁ bo‘lsa, maxrajda x₂ - x₁ bo‘lsin. O‘rta nuqta uchun x larni x lar bilan, y larni y lar bilan o‘rtachalang. Kesishish nuqtasi ikkala chiziq tenglamasini ham qanoatlantirishi kerak.',
'p1:P1-COO-02:theory:uz:v1'
),
(
'p5:P5-NOR-02:tutor:en:v2','P5','P5-NOR-02','en','tutor_v2_learner_first',
'Standardisation and z-values',
'Standardisation puts any normal variable onto the standard normal scale. If X has mean μ and standard deviation σ, use\n\nZ = (X - μ)/σ.\n\nSuppose X ~ N(50, 8²) and we want P(X > 62). First standardise the boundary:\n\nz = (62 - 50)/8 = 1.5.\n\nSo the question becomes P(Z > 1.5). If your table or calculator gives the left-tail value Φ(1.5), then the right-tail probability is\n\n1 - Φ(1.5) ≈ 0.0668.\n\nA z-value is simply a position measured in standard deviations from the mean. The calculation is usually easy; the important part is matching the original event to the correct side of the normal curve.',
'Standardising changes the scale, not the probability question. Subtract the mean and divide by the standard deviation:\n\nZ = (X - μ)/σ.\n\nFor X ~ N(50, 8²), the value 62 gives z = 1.5. That means 62 is 1.5 standard deviations above the mean. If the question asks for X > 62, you need the area to the right of z = 1.5.',
'Think of z as a position label on one universal normal curve. z = 0 is the mean, positive z-values are to the right, and negative z-values are to the left. Once you convert each boundary to z, the original distribution no longer matters for the calculation: you are choosing an area on the standard normal curve.',
'Write the probability event before using a table or calculator. Then check the sign of z and decide whether you need a left tail, right tail or interval. Finally check what your table/calculator returns before deciding whether to subtract from 1.',
'p5:P5-NOR-02:theory:en:v1'
),
(
'p5:P5-NOR-02:tutor:ru:v2','P5','P5-NOR-02','ru','tutor_v2_learner_first',
'Стандартизация и z-значение',
'Стандартизация переводит любую нормальную случайную величину на стандартную нормальную шкалу. Если X имеет среднее μ и стандартное отклонение σ, используйте\n\nZ = (X - μ)/σ.\n\nПусть X ~ N(50, 8²) и нужно найти P(X > 62). Сначала стандартизируем границу:\n\nz = (62 - 50)/8 = 1.5.\n\nТеперь задача стала P(Z > 1.5). Если таблица или калькулятор дают левую накопленную вероятность Φ(1.5), то вероятность правого хвоста равна\n\n1 - Φ(1.5) ≈ 0.0668.\n\nz-значение — это положение, измеренное в стандартных отклонениях от среднего. Вычисление обычно простое; главное — правильно связать исходное событие с нужной областью нормальной кривой.',
'Стандартизация меняет шкалу, но не смысл вероятностного события. Вычтите среднее и разделите на стандартное отклонение:\n\nZ = (X - μ)/σ.\n\nДля X ~ N(50, 8²) значение 62 даёт z = 1.5. Это означает, что 62 находится на 1.5 стандартного отклонения выше среднего. Если требуется X > 62, нужна область справа от z = 1.5.',
'Считайте z меткой положения на одной общей нормальной кривой. z = 0 соответствует среднему, положительные z находятся справа, отрицательные — слева. После перевода границы в z исходный масштаб уже не нужен для вычисления: остаётся выбрать правильную область под стандартной нормальной кривой.',
'Сначала запишите само событие вероятности. Затем проверьте знак z и определите, нужна область слева, справа или между двумя значениями. После этого уточните, какую именно вероятность возвращает ваша таблица или калькулятор, прежде чем вычитать что-либо из 1.',
'p5:P5-NOR-02:theory:ru:v1'
),
(
'p5:P5-NOR-02:tutor:uz:v2','P5','P5-NOR-02','uz','tutor_v2_learner_first',
'Standartlashtirish va z-qiymat',
'Standartlashtirish istalgan normal tasodifiy miqdorni standart normal shkala ustiga o‘tkazadi. Agar X ning o‘rtachasi μ va standart og‘ishi σ bo‘lsa,\n\nZ = (X - μ)/σ\n\nformuladan foydalaning. X ~ N(50, 8²) bo‘lsin va P(X > 62) ni topish kerak. Avval chegarani standartlashtiramiz:\n\nz = (62 - 50)/8 = 1.5.\n\nEndi savol P(Z > 1.5) ga aylandi. Agar jadval yoki kalkulyator chap tomondagi yig‘ma ehtimollik Φ(1.5) ni bersa, o‘ng dum ehtimoli\n\n1 - Φ(1.5) ≈ 0.0668.\n\nz-qiymat o‘rtachadan standart og‘ishlarda o‘lchangan joylashuvdir. Hisoblash odatda oson; eng muhim qadam — boshlang‘ich hodisani normal egri chiziqdagi to‘g‘ri sohaga moslashtirish.',
'Standartlashtirish shkalaning o‘zini o‘zgartiradi, ehtimollik hodisasining ma’nosini emas. O‘rtachani ayiring va standart og‘ishga bo‘ling:\n\nZ = (X - μ)/σ.\n\nX ~ N(50, 8²) uchun 62 qiymat z = 1.5 ni beradi. Bu 62 o‘rtachadan 1.5 standart og‘ish yuqorida ekanini bildiradi. X > 62 so‘ralsa, z = 1.5 ning o‘ng tomonidagi soha kerak.',
'z ni bitta umumiy normal egri chiziqdagi joylashuv belgisi deb o‘ylang. z = 0 o‘rtachaga mos keladi, musbat z o‘ng tomonda, manfiy z esa chap tomonda. Chegarani z ga o‘tkazgandan keyin hisoblash uchun boshlang‘ich shkala kerak bo‘lmaydi: standart normal egri chiziqdagi to‘g‘ri sohani tanlash qoladi.',
'Avval ehtimollik hodisasini yozing. Keyin z ishorasini tekshirib, chap dum, o‘ng dum yoki ikki qiymat orasidagi soha kerakligini aniqlang. Oxirida 1 dan ayirishdan oldin jadval yoki kalkulyator aynan qaysi ehtimollikni qaytarishini tekshiring.',
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
from seed;

do $postcheck$
declare
  v_new_count integer;
  v_new_runtime integer;
  v_old_retired integer;
begin
  select count(*),count(*) filter(where is_runtime_allowed)
    into v_new_count,v_new_runtime
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and skill_code in ('P1-QUA-01','P1-COO-02','P5-NOR-02');

  select count(*) into v_old_retired
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v1'
    and skill_code in ('P1-QUA-01','P1-COO-02','P5-NOR-02')
    and approval_status='retired'
    and is_runtime_allowed=false;

  if v_new_count<>9 then
    raise exception 'Tutor pilot v2 expected 9 new draft cards, found %',v_new_count;
  end if;
  if v_new_runtime<>0 then
    raise exception 'Tutor pilot v2 must remain runtime OFF';
  end if;
  if v_old_retired<>9 then
    raise exception 'Tutor pilot v2 expected 9 superseded v1 drafts to be retired, found %',v_old_retired;
  end if;
end
$postcheck$;

commit;
