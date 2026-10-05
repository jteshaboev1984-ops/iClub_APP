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
  if v<>231 then raise exception 'NOR03 expected 231 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-NOR-03')<>0
  then raise exception 'NOR03 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-NOR-03' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'NOR03 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-NOR-03:tutor:en:v2','P5','P5-NOR-03','en','tutor_v2_learner_first',
'Normal probabilities',
$t$To find a probability from a normal distribution, first identify the interval or tail, then standardise its boundary values:

Z=(X-μ)/σ.

Suppose

X ~ N(100,15²)

and we want

P(85<X<115).

Standardising the two boundaries:

z₁=(85-100)/15=-1,
z₂=(115-100)/15=1.

So

P(85<X<115)
=P(-1<Z<1)
≈0.6827.

A sketch helps prevent tail mistakes: shade the region you actually need before using a table or calculator. For one-sided probabilities, use the correct left or right tail; for an interval, use the area between the two standardised boundaries.$t$,
$t$Use

Z=(X-μ)/σ.

For

X ~ N(100,15²),

the interval 85<X<115 becomes

-1<Z<1.

Therefore

P(85<X<115)≈0.6827.

Sketch the required region first so you know which area the calculator or table should return.$t$,
$t$Standardisation does not change the probability region; it only changes the horizontal scale.

The original interval from 85 to 115 sits one standard deviation below and above the mean 100. On the standard normal curve, that same region is from z=-1 to z=1. The area stays the same.$t$,
$t$Write the event before calculating. Standardise every boundary separately, check the sign of each z-value, and match the calculation to the shaded region. Do not automatically subtract from 1 unless the required region is a complement/tail.$t$,
'p5:P5-NOR-03:theory:en:v1'
),
(
'p5:P5-NOR-03:tutor:ru:v2','P5','P5-NOR-03','ru','tutor_v2_learner_first',
'Вероятности нормального распределения',
$t$Чтобы найти вероятность для нормального распределения, сначала определите нужный интервал или хвост, затем стандартизируйте границы:

Z=(X-μ)/σ.

Пусть

X ~ N(100,15²)

и требуется

P(85<X<115).

Стандартизируем обе границы:

z₁=(85-100)/15=-1,
z₂=(115-100)/15=1.

Поэтому

P(85<X<115)
=P(-1<Z<1)
≈0.6827.

Эскиз помогает не перепутать области: сначала заштрихуйте именно ту часть кривой, которая нужна. Для односторонней вероятности выберите правильный левый или правый хвост; для интервала найдите площадь между двумя стандартизированными границами.$t$,
$t$Используйте

Z=(X-μ)/σ.

Для

X ~ N(100,15²)

интервал 85<X<115 превращается в

-1<Z<1.

Следовательно,

P(85<X<115)≈0.6827.

Перед расчётом полезно нарисовать нужную область.$t$,
$t$Стандартизация не меняет саму вероятность, а только меняет горизонтальную шкалу.

Интервал от 85 до 115 находится на одно стандартное отклонение ниже и выше среднего 100. На стандартной нормальной кривой это тот же участок от z=-1 до z=1. Площадь остаётся той же.$t$,
$t$Сначала запишите событие. Каждую границу стандартизируйте отдельно, проверьте знак z и сопоставьте расчёт с заштрихованной областью. Не вычитайте из 1 автоматически — это нужно только для соответствующего хвоста или дополнения.$t$,
'p5:P5-NOR-03:theory:ru:v1'
),
(
'p5:P5-NOR-03:tutor:uz:v2','P5','P5-NOR-03','uz','tutor_v2_learner_first',
'Normal ehtimolliklar',
$t$Normal taqsimotdan ehtimollik topishda avval kerakli interval yoki dumni aniqlang, keyin chegaralarni standartlashtiring:

Z=(X-μ)/σ.

Masalan,

X ~ N(100,15²)

va

P(85<X<115)

topilishi kerak.

Ikki chegarani standartlashtiramiz:

z₁=(85-100)/15=-1,
z₂=(115-100)/15=1.

Shuning uchun

P(85<X<115)
=P(-1<Z<1)
≈0.6827.

Eskiz dumni adashtirmaslikka yordam beradi: jadval yoki kalkulyatordan oldin aynan kerakli sohani belgilang. Bir tomonlama ehtimollikda to‘g‘ri chap yoki o‘ng dumni, intervalda esa ikki standart chegara orasidagi yuzani oling.$t$,
$t$Quyidagidan foydalaning:

Z=(X-μ)/σ.

X ~ N(100,15²) uchun 85<X<115 interval

-1<Z<1

ga aylanadi.

Demak,

P(85<X<115)≈0.6827.

Hisoblashdan oldin kerakli sohani eskizda belgilash foydali.$t$,
$t$Standartlashtirish ehtimollik sohasini o‘zgartirmaydi, faqat gorizontal shkalani almashtiradi.

85 dan 115 gacha interval 100 o‘rtachadan bir standart og‘ish past va yuqori chegaralarda turadi. Standart normal egri chiziqda ayni soha z=-1 dan z=1 gacha bo‘ladi. Yuzasi o‘zgarmaydi.$t$,
$t$Avval hodisani yozing. Har bir chegarani alohida standartlashtiring, z ishoralarini tekshiring va hisobni kerakli sohaga moslang. Faqat dum yoki to‘ldiruvchi soha kerak bo‘lgandagina 1 dan ayiring.$t$,
'p5:P5-NOR-03:theory:uz:v1'
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
