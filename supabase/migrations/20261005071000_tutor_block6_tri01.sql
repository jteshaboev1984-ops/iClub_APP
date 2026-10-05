begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$
declare v integer;
begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>72 then raise exception 'TRI01 expected 72 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-TRI-01')<>0
  then raise exception 'TRI01 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-TRI-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'TRI01 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p1:P1-TRI-01:tutor:en:v2','P1','P1-TRI-01','en','tutor_v2_learner_first','Graphs of sin, cos and tan',
$t$The graphs of sin x, cos x and tan x repeat in predictable patterns.

sin x and cos x both have period 2π and range from -1 to 1. tan x has period π and has vertical asymptotes where cos x=0, such as x=π/2 and x=3π/2.

Simple transformations change the graph in the same way as other functions. For example,

y = 2 sin x + 1

doubles every y-value of sin x and then shifts the graph up by 1. Its period stays 2π, its midline is y=1, and its maximum and minimum are 3 and -1.

The useful habit is to start from the basic trig graph, then track exactly what each transformation changes: height, position or horizontal scale.$t$,
$t$Remember the basic patterns:

sin x and cos x repeat every 2π and stay between -1 and 1.

tan x repeats every π and has vertical asymptotes where cos x=0.

For y=2 sin x+1, multiply all sin y-values by 2, then shift them up 1. The period is still 2π.$t$,
$t$Think of a trig graph as a repeating template.

For sin x, one complete wave from 0 to 2π is copied again and again. cos x is the same type of repeating wave but starts at 1. tan x repeats a rising branch between vertical asymptotes.

A transformation edits that repeating template. In y=2 sin x+1, the template becomes twice as tall and moves upward, but the horizontal repeat length does not change.$t$,
$t$Check the base graph before transforming it. For sin and cos, keep period 2π unless x is scaled inside the function. For tan, keep track of vertical asymptotes as well as zeros. In y=2 sin x+1, transform y-values only: multiply by 2, then add 1.$t$,
'p1:P1-TRI-01:theory:en:v1'
),
(
'p1:P1-TRI-01:tutor:ru:v2','P1','P1-TRI-01','ru','tutor_v2_learner_first','Графики sin, cos и tan',
$t$Графики sin x, cos x и tan x повторяются по предсказуемому закону.

У sin x и cos x период равен 2π, а значения находятся от -1 до 1. У tan x период π, а вертикальные асимптоты находятся там, где cos x=0, например при x=π/2 и x=3π/2.

Простые преобразования действуют так же, как для других функций. Например,

y = 2 sin x + 1

удваивает все значения y графика sin x, а затем сдвигает график вверх на 1. Период остаётся 2π, средняя линия становится y=1, максимум равен 3, минимум -1.

Полезно сначала представить базовый тригонометрический график, а затем отдельно проследить, что меняет каждое преобразование: высоту, положение или горизонтальный масштаб.$t$,
$t$Запомните базовые формы:

sin x и cos x повторяются через 2π и принимают значения от -1 до 1.

tan x повторяется через π и имеет вертикальные асимптоты там, где cos x=0.

Для y=2 sin x+1 сначала умножьте все значения y на 2, затем сдвиньте их вверх на 1. Период остаётся 2π.$t$,
$t$Представьте тригонометрический график как повторяющийся шаблон.

У sin x одна полная волна от 0 до 2π затем повторяется. cos x имеет такой же тип повторения, но начинается со значения 1. tan x состоит из повторяющихся возрастающих ветвей между вертикальными асимптотами.

Преобразование меняет этот шаблон. В y=2 sin x+1 он становится вдвое выше и сдвигается вверх, но длина периода не меняется.$t$,
$t$Сначала восстановите базовый график. Для sin и cos период остаётся 2π, пока x внутри функции не масштабируется. Для tan отмечайте не только нули, но и вертикальные асимптоты. В y=2 sin x+1 меняются только значения y: сначала умножить на 2, потом прибавить 1.$t$,
'p1:P1-TRI-01:theory:ru:v1'
),
(
'p1:P1-TRI-01:tutor:uz:v2','P1','P1-TRI-01','uz','tutor_v2_learner_first','sin, cos va tan grafiklari',
$t$sin x, cos x va tan x grafiklari ma’lum davr bilan takrorlanadi.

sin x va cos x ning davri 2π, qiymatlari esa -1 dan 1 gacha. tan x ning davri π va cos x=0 bo‘lgan joylarda vertikal asimptotalari bor, masalan x=π/2 va x=3π/2 da.

Oddiy grafik o‘zgarishlari boshqa funksiyalardagi kabi ishlaydi. Masalan,

y = 2 sin x + 1

sin x grafigidagi barcha y qiymatlarni 2 marta oshiradi va keyin grafikni 1 birlik yuqoriga siljitadi. Davr 2π bo‘lib qoladi, o‘rta chiziq y=1, maksimum 3, minimum -1 bo‘ladi.

Eng qulay usul: avval asosiy trigonometrik grafikni tasavvur qiling, keyin har bir o‘zgarish nimani - balandlikni, joylashuvni yoki gorizontal masshtabni - o‘zgartirishini alohida kuzating.$t$,
$t$Asosiy shakllarni eslab qoling:

sin x va cos x har 2π da takrorlanadi va -1 dan 1 gacha qiymat oladi.

tan x har π da takrorlanadi va cos x=0 bo‘lgan joylarda vertikal asimptotalarga ega.

y=2 sin x+1 uchun avval barcha y qiymatlarni 2 ga ko‘paytiring, keyin 1 birlik yuqoriga siljiting. Davr 2π bo‘lib qoladi.$t$,
$t$Trigonometrik grafikni takrorlanadigan shablon deb tasavvur qiling.

sin x ning 0 dan 2π gacha bo‘lgan bir to‘liq to‘lqini qayta-qayta takrorlanadi. cos x ham shu turdagi to‘lqin, lekin 1 dan boshlanadi. tan x esa vertikal asimptotalar orasidagi o‘suvchi tarmoqlarni takrorlaydi.

y=2 sin x+1 da shablon vertikal yo‘nalishda ikki marta kattalashadi va yuqoriga siljiydi, lekin gorizontal takrorlanish uzunligi o‘zgarmaydi.$t$,
$t$O‘zgartirishdan oldin asosiy grafikni tekshiring. sin va cos uchun x ichida masshtab bo‘lmasa davr 2π bo‘lib qoladi. tan uchun nollar bilan birga vertikal asimptotalarni ham belgilang. y=2 sin x+1 da faqat y qiymatlar o‘zgaradi: avval 2 ga ko‘payadi, keyin 1 qo‘shiladi.$t$,
'p1:P1-TRI-01:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,
  source_card_key,approval_status,is_runtime_allowed,content_hash)
select tutor_card_key,component_code,skill_code,locale,content_version,title,
       main_explanation,simple_explanation,alternative_explanation,focus_explanation,
       source_card_key,'draft',false,
       md5(concat_ws('||',content_version,title,main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key))
from seed;

do $post$
begin
  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-TRI-01'
        and approval_status='draft' and not is_runtime_allowed)<>3
  then raise exception 'TRI01 expected 3 draft cards'; end if;
end $post$;

commit;
