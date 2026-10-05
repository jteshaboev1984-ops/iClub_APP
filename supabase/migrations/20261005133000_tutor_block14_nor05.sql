begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft' and not is_runtime_allowed;
  if v<>237 then raise exception 'NOR05 expected 237 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-NOR-05')<>0
  then raise exception 'NOR05 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-NOR-05' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'NOR05 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-NOR-05:tutor:en:v2','P5','P5-NOR-05','en','tutor_v2_learner_first',
'Finding μ and σ',
$t$When μ or σ is unknown, turn each probability condition into a standardised z-equation.

Suppose

P(X<44)=0.1587

and

P(X<56)=0.8413.

These left-tail probabilities correspond to

z=-1

and

z=1.

So

(44-μ)/σ=-1

and

(56-μ)/σ=1.

Rearranging gives

44=μ-σ,
56=μ+σ.

Adding the equations:

100=2μ,
so μ=50.

Then σ=6.

The important step is matching each probability to the correct signed z-value before doing the algebra. With two unknown parameters, two independent probability conditions are needed.$t$,
$t$Convert each probability condition to a z-equation.

P(X<44)=0.1587 gives z=-1.
P(X<56)=0.8413 gives z=1.

Therefore

(44-μ)/σ=-1,
(56-μ)/σ=1.

So

44=μ-σ,
56=μ+σ,

which gives

μ=50,
σ=6.$t$,
$t$Think of the two probability statements as locating two known points on the same normal curve.

The lower point 44 is one standard deviation below the mean; the upper point 56 is one standard deviation above it. Their midpoint is therefore the mean:

(44+56)/2=50.

The distance from 50 to either point is 6, so σ=6.$t$,
$t$Draw the tail direction before choosing z. A lower-tail probability below 0.5 should give a negative z; one above 0.5 gives a positive z. With two unknowns, make sure the two equations are independent before solving.$t$,
'p5:P5-NOR-05:theory:en:v1'
),
(
'p5:P5-NOR-05:tutor:ru:v2','P5','P5-NOR-05','ru','tutor_v2_learner_first',
'Нахождение μ и σ',
$t$Если μ или σ неизвестны, каждое вероятностное условие нужно превратить в уравнение со стандартизированным z.

Пусть

P(X<44)=0.1587

и

P(X<56)=0.8413.

Этим вероятностям левого хвоста соответствуют

z=-1

и

z=1.

Поэтому

(44-μ)/σ=-1

и

(56-μ)/σ=1.

После преобразования:

44=μ-σ,
56=μ+σ.

Складываем уравнения:

100=2μ,
значит μ=50.

Затем σ=6.

Главный шаг — правильно связать каждую вероятность со знаком z до начала алгебры. Если неизвестны два параметра, нужны два независимых вероятностных условия.$t$,
$t$Преобразуйте каждое условие вероятности в уравнение с z.

P(X<44)=0.1587 даёт z=-1.
P(X<56)=0.8413 даёт z=1.

Значит,

(44-μ)/σ=-1,
(56-μ)/σ=1.

Отсюда

44=μ-σ,
56=μ+σ,

поэтому

μ=50,
σ=6.$t$,
$t$Представьте два вероятностных условия как две известные точки на одной нормальной кривой.

Значение 44 находится на одно стандартное отклонение ниже среднего, а 56 — на одно стандартное отклонение выше. Их середина:

(44+56)/2=50,

это μ. Расстояние от 50 до каждой точки равно 6, значит σ=6.$t$,
$t$Перед выбором z определите направление хвоста. Для левой накопленной вероятности меньше 0.5 z должен быть отрицательным, больше 0.5 — положительным. При двух неизвестных убедитесь, что у вас два независимых условия.$t$,
'p5:P5-NOR-05:theory:ru:v1'
),
(
'p5:P5-NOR-05:tutor:uz:v2','P5','P5-NOR-05','uz','tutor_v2_learner_first',
'μ va σ ni topish',
$t$μ yoki σ noma’lum bo‘lsa, har bir ehtimollik shartini standartlashtirilgan z tenglamasiga aylantiring.

Masalan,

P(X<44)=0.1587

va

P(X<56)=0.8413.

Bu chap dum ehtimollariga

z=-1

va

z=1

mos keladi.

Shuning uchun

(44-μ)/σ=-1

va

(56-μ)/σ=1.

Qayta yozsak:

44=μ-σ,
56=μ+σ.

Tenglamalarni qo‘shamiz:

100=2μ,
demak μ=50.

Keyin σ=6.

Asosiy qadam — algebra boshlanishidan oldin har bir ehtimollikni to‘g‘ri ishorali z qiymatiga moslash. Ikki noma’lum parametr bo‘lsa, ikkita mustaqil ehtimollik sharti kerak.$t$,
$t$Har bir ehtimollik shartini z tenglamasiga aylantiring.

P(X<44)=0.1587 → z=-1.
P(X<56)=0.8413 → z=1.

Demak,

(44-μ)/σ=-1,
(56-μ)/σ=1.

Shundan

44=μ-σ,
56=μ+σ,

va

μ=50,
σ=6.$t$,
$t$Ikki ehtimollik shartini bir normal egri chiziqdagi ikki ma’lum nuqta deb tasavvur qiling.

44 o‘rtachadan bir standart og‘ish pastda, 56 esa bir standart og‘ish yuqorida. Ularning o‘rtasi

(44+56)/2=50,

ya’ni μ. 50 dan har bir nuqtagacha masofa 6, demak σ=6.$t$,
$t$z ishorasini tanlashdan oldin dum yo‘nalishini aniqlang. Chap yig‘ma ehtimollik 0.5 dan kichik bo‘lsa z manfiy, 0.5 dan katta bo‘lsa musbat bo‘ladi. Ikki noma’lum uchun ikkita mustaqil shart bo‘lishini tekshiring.$t$,
'p5:P5-NOR-05:theory:uz:v1'
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

commit;
