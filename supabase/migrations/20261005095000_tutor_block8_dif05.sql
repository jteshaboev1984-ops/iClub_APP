begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>114 then raise exception 'DIF05 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-DIF-05' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DIF05 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-DIF-05:tutor:en:v2','P1','P1-DIF-05','en','tutor_v2_learner_first','Increasing and decreasing functions',
$t$The sign of the derivative tells you the direction of a function.

If dy/dx>0, the function is increasing.
If dy/dx<0, the function is decreasing.

For

y=x³-3x,

dy/dx=3x²-3
=3(x-1)(x+1).

The derivative is zero at x=-1 and x=1. These values split the number line into three intervals.

Testing the sign gives:
- x<-1: derivative positive, so the function increases;
- -1<x<1: derivative negative, so the function decreases;
- x>1: derivative positive, so the function increases.

The zeros of the derivative mark possible changes of direction; the intervals come from the derivative sign between them.$t$,
$t$For y=x³-3x:

dy/dx=3(x-1)(x+1).

The derivative is zero at x=-1 and x=1.

Sign check:
x<-1 → positive → increasing.
-1<x<1 → negative → decreasing.
x>1 → positive → increasing.$t$,
$t$Think of dy/dx as a slope signal.

Positive means the graph is travelling uphill as x increases.
Negative means it is travelling downhill.
Zero marks a flat tangent, but you still need the signs on either side to know what the graph does next.

A sign chart turns derivative algebra into the shape of the graph.$t$,
$t$Do not stop after solving dy/dx=0. Those x-values only divide the intervals. Test the derivative sign inside each interval and state the final intervals clearly. Keep endpoint inclusion consistent with the question.$t$,
'p1:P1-DIF-05:theory:en:v1'
),
(
'p1:P1-DIF-05:tutor:ru:v2','P1','P1-DIF-05','ru','tutor_v2_learner_first','Возрастание и убывание',
$t$Знак производной показывает направление изменения функции.

Если dy/dx>0, функция возрастает.
Если dy/dx<0, функция убывает.

Для

y=x³-3x

получаем

dy/dx=3x²-3
=3(x-1)(x+1).

Производная равна нулю при x=-1 и x=1. Эти точки делят числовую прямую на три промежутка.

Проверка знака:
- x<-1: производная положительна, функция возрастает;
- -1<x<1: производная отрицательна, функция убывает;
- x>1: производная положительна, функция возрастает.

Нули производной показывают возможные места изменения направления, а сами интервалы определяются знаком производной между ними.$t$,
$t$Для y=x³-3x:

dy/dx=3(x-1)(x+1).

Производная равна нулю при x=-1 и x=1.

Проверка:
x<-1 → плюс → возрастает.
-1<x<1 → минус → убывает.
x>1 → плюс → возрастает.$t$,
$t$Считайте dy/dx сигналом наклона.

Положительный знак означает, что график идёт вверх при увеличении x.
Отрицательный — вниз.
Ноль означает горизонтальную касательную, но для понимания дальнейшего движения нужны знаки по обе стороны.

Таблица знаков переводит алгебру производной в форму графика.$t$,
$t$Не останавливайтесь после решения dy/dx=0. Эти значения только разделяют промежутки. Проверьте знак производной внутри каждого промежутка и запишите интервалы явно. Включение границ должно соответствовать формулировке задачи.$t$,
'p1:P1-DIF-05:theory:ru:v1'
),
(
'p1:P1-DIF-05:tutor:uz:v2','P1','P1-DIF-05','uz','tutor_v2_learner_first','O‘sish va kamayish',
$t$Hosila ishorasi funksiyaning qaysi yo‘nalishda o‘zgarishini ko‘rsatadi.

dy/dx>0 bo‘lsa, funksiya o‘sadi.
dy/dx<0 bo‘lsa, funksiya kamayadi.

Masalan,

y=x³-3x

uchun

dy/dx=3x²-3
=3(x-1)(x+1).

Hosila x=-1 va x=1 da nol. Bu nuqtalar sonlar o‘qini uchta oraliqqa bo‘ladi.

Ishora tekshiruvi:
- x<-1: hosila musbat, funksiya o‘sadi;
- -1<x<1: hosila manfiy, funksiya kamayadi;
- x>1: hosila musbat, funksiya o‘sadi.

Hosilaning nollari yo‘nalish o‘zgarishi mumkin bo‘lgan joylarni, oraliqlardagi ishora esa funksiyaning haqiqiy harakatini beradi.$t$,
$t$y=x³-3x uchun:

dy/dx=3(x-1)(x+1).

Hosila x=-1 va x=1 da nol.

Tekshiruv:
x<-1 → musbat → o‘sadi.
-1<x<1 → manfiy → kamayadi.
x>1 → musbat → o‘sadi.$t$,
$t$dy/dx ni qiyalik signali deb o‘ylang.

Musbat ishora grafik x oshganda yuqoriga ketayotganini bildiradi.
Manfiy ishora pastga ketayotganini bildiradi.
Nol gorizontal urinmani ko‘rsatadi, lekin keyingi yo‘nalishni bilish uchun ikki tomondagi ishoralar kerak.

Ishora jadvali hosila algebrasini grafik shakliga aylantiradi.$t$,
$t$dy/dx=0 ni topish bilan to‘xtamang. Bu x qiymatlar faqat oraliqlarni ajratadi. Har bir oraliqda hosila ishorasini tekshirib, yakuniy o‘sish va kamayish oraliqlarini aniq yozing.$t$,
'p1:P1-DIF-05:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
