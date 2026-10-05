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
  if v<>228 then raise exception 'NOR01 expected 228 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-NOR-01')<>0
  then raise exception 'NOR01 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-NOR-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'NOR01 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-NOR-01:tutor:en:v2','P5','P5-NOR-01','en','tutor_v2_learner_first',
'The normal model',
$t$A normal distribution is a continuous, symmetric, bell-shaped model described by its mean μ and variance σ².

The notation

X ~ N(μ,σ²)

means that X is normally distributed with centre μ and standard deviation σ.

For example,

X ~ N(70,8²).

So

mean = 70,
standard deviation = 8,
variance = 64.

A useful sketch is centred at 70 and is symmetric about that value. Marking one standard deviation on each side gives

μ-σ = 62,
μ = 70,
μ+σ = 78.

The mean controls the horizontal centre of the curve, while σ controls its spread. This card is about recognising and describing the model; probability calculations come after the model and region are identified.$t$,
$t$For a normal distribution,

X ~ N(μ,σ²).

If

X ~ N(70,8²),

then

μ=70,
σ=8,
variance=64.

The curve is symmetric about 70. One standard deviation on either side is 62 and 78.$t$,
$t$Think of μ as where the bell curve is placed and σ as how wide it is.

Changing μ slides the whole curve left or right without changing its shape. Increasing σ spreads the curve out; decreasing σ makes it narrower. In X~N(70,8²), the centre is 70 and the spread is controlled by 8.$t$,
$t$Read the second normal parameter as variance, σ², not standard deviation. On a sketch, place μ at the centre and keep the curve symmetric. If useful, mark μ±σ to show the scale of the spread.$t$,
'p5:P5-NOR-01:theory:en:v1'
),
(
'p5:P5-NOR-01:tutor:ru:v2','P5','P5-NOR-01','ru','tutor_v2_learner_first',
'Нормальная модель',
$t$Нормальное распределение — непрерывная симметричная колоколообразная модель, которая задаётся средним μ и дисперсией σ².

Запись

X ~ N(μ,σ²)

означает, что X имеет нормальное распределение с центром μ и стандартным отклонением σ.

Например,

X ~ N(70,8²).

Тогда

среднее = 70,
стандартное отклонение = 8,
дисперсия = 64.

Полезный эскиз симметричен относительно 70. На расстоянии одного стандартного отклонения от среднего находятся точки

μ-σ = 62,
μ = 70,
μ+σ = 78.

Среднее задаёт положение центра кривой, а σ — её разброс. Здесь важно сначала правильно распознать и описать модель; вычисление вероятностей идёт следующим отдельным шагом.$t$,
$t$Для нормального распределения:

X ~ N(μ,σ²).

Если

X ~ N(70,8²),

то

μ=70,
σ=8,
дисперсия=64.

Кривая симметрична относительно 70. На одно стандартное отклонение влево и вправо находятся 62 и 78.$t$,
$t$Представьте μ как положение колокола на оси, а σ — как его ширину.

Изменение μ сдвигает всю кривую влево или вправо. Увеличение σ делает её шире, уменьшение — уже. Для X~N(70,8²) центр равен 70, а масштаб разброса задаётся числом 8.$t$,
$t$Второй параметр в N(μ,σ²) — дисперсия, а не стандартное отклонение. На эскизе ставьте μ в центре и сохраняйте симметрию. Для масштаба удобно отметить μ±σ.$t$,
'p5:P5-NOR-01:theory:ru:v1'
),
(
'p5:P5-NOR-01:tutor:uz:v2','P5','P5-NOR-01','uz','tutor_v2_learner_first',
'Normal model',
$t$Normal taqsimot — uzluksiz, simmetrik, qo‘ng‘iroqsimon model bo‘lib, o‘rtacha μ va dispersiya σ² bilan aniqlanadi.

Yozuv

X ~ N(μ,σ²)

X normal taqsimlanganini, markazi μ va standart og‘ishi σ ekanini bildiradi.

Masalan,

X ~ N(70,8²).

Unda

o‘rtacha = 70,
standart og‘ish = 8,
dispersiya = 64.

Foydali eskiz 70 atrofida simmetrik bo‘ladi. O‘rtachadan bitta standart og‘ish masofada:

μ-σ = 62,
μ = 70,
μ+σ = 78.

μ egri chiziqning gorizontal markazini, σ esa tarqalish kengligini belgilaydi. Bu kartada asosiy maqsad modelni to‘g‘ri aniqlash va tasvirlash; ehtimollik hisoblari keyingi alohida qadam.$t$,
$t$Normal taqsimot uchun:

X ~ N(μ,σ²).

Agar

X ~ N(70,8²)

bo‘lsa,

μ=70,
σ=8,
dispersiya=64.

Egri chiziq 70 atrofida simmetrik. Bir standart og‘ish chap va o‘ng tomonda 62 va 78 nuqtalarni beradi.$t$,
$t$μ ni qo‘ng‘iroq egri chizig‘ining joylashuvi, σ ni esa uning kengligi deb o‘ylang.

μ o‘zgarsa, butun egri chiziq chapga yoki o‘ngga siljiydi. σ kattalashsa egri chiziq kengayadi, kichraysa torayadi. X~N(70,8²) da markaz 70, tarqalish masshtabi esa 8.$t$,
$t$N(μ,σ²) dagi ikkinchi parametr standart og‘ish emas, dispersiya σ² ekanini unutmang. Eskizda μ ni markazga qo‘ying va simmetriyani saqlang. Masshtab uchun μ±σ ni belgilash foydali.$t$,
'p5:P5-NOR-01:theory:uz:v1'
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
