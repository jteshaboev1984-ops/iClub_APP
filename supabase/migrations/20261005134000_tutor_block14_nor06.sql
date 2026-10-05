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
  if v<>240 then raise exception 'NOR06 expected 240 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-NOR-06')<>0
  then raise exception 'NOR06 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-NOR-06' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'NOR06 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-NOR-06:tutor:en:v2','P5','P5-NOR-06','en','tutor_v2_learner_first',
'Normal approximation to the binomial',
$t$A binomial distribution can sometimes be approximated by a normal distribution when the approximation conditions are satisfied.

For

X ~ B(n,p),

use the normal model with

mean = np

and

variance = np(1-p).

Suppose

X ~ B(100,0.4).

Then the approximating normal variable Y has

mean = 40,
variance = 24.

To approximate

P(X≤45),

translate the discrete boundary using continuity correction:

P(X≤45) ≈ P(Y<45.5).

Now standardise:

z=(45.5-40)/√24≈1.123.

Therefore

P(X≤45)≈0.8692.

The continuity correction is applied before standardisation because it translates an integer boundary from a discrete distribution to a continuous one.$t$,
$t$If a binomial distribution is suitable for normal approximation, use

mean=np,
variance=np(1-p).

For X~B(100,0.4):

mean=40,
variance=24.

For P(X≤45), continuity correction gives

P(Y<45.5).

Then z≈1.123, so

P(X≤45)≈0.8692.$t$,
$t$Think of each binomial value as a bar centred on an integer. A continuous normal curve replaces those bars.

The event X≤45 includes the whole bar centred at 45, so the matching continuous boundary is halfway to the next integer: 45.5. That half-unit shift is the continuity correction.$t$,
$t$First confirm the normal approximation is appropriate. Use μ=np and σ²=np(1-p), not σ=np(1-p). Apply the continuity correction to the discrete boundary before calculating z. The direction of the half-unit shift depends on the event.$t$,
'p5:P5-NOR-06:theory:en:v1'
),
(
'p5:P5-NOR-06:tutor:ru:v2','P5','P5-NOR-06','ru','tutor_v2_learner_first',
'Нормальное приближение биномиального распределения',
$t$Биномиальное распределение иногда можно приближать нормальным, если условия такого приближения выполняются.

Для

X ~ B(n,p)

используйте нормальную модель со

средним = np

и

дисперсией = np(1-p).

Пусть

X ~ B(100,0.4).

Тогда приближающая нормальная величина Y имеет

среднее = 40,
дисперсию = 24.

Чтобы приблизить

P(X≤45),

сначала применяем поправку на непрерывность:

P(X≤45) ≈ P(Y<45.5).

Затем стандартизируем:

z=(45.5-40)/√24≈1.123.

Поэтому

P(X≤45)≈0.8692.

Поправка на непрерывность применяется до стандартизации, потому что она переводит дискретную целочисленную границу в непрерывную шкалу.$t$,
$t$Если биномиальное распределение подходит для нормального приближения, используйте

среднее=np,
дисперсия=np(1-p).

Для X~B(100,0.4):

среднее=40,
дисперсия=24.

Для P(X≤45) поправка даёт

P(Y<45.5).

Тогда z≈1.123 и

P(X≤45)≈0.8692.$t$,
$t$Представьте биномиальные значения как столбики с центрами в целых числах. Непрерывная нормальная кривая заменяет эти столбики.

Событие X≤45 включает весь столбик с центром 45, поэтому соответствующая непрерывная граница проходит посередине до следующего целого числа — в 45.5. Этот сдвиг на половину единицы и есть поправка на непрерывность.$t$,
$t$Сначала убедитесь, что нормальное приближение уместно. Используйте μ=np и σ²=np(1-p), не путайте дисперсию со стандартным отклонением. Поправку на непрерывность применяйте к дискретной границе до вычисления z. Направление сдвига зависит от события.$t$,
'p5:P5-NOR-06:theory:ru:v1'
),
(
'p5:P5-NOR-06:tutor:uz:v2','P5','P5-NOR-06','uz','tutor_v2_learner_first',
'Binomial taqsimotga normal yaqinlashuv',
$t$Binomial taqsimotni ayrim hollarda, yaqinlashuv shartlari bajarilganda, normal taqsimot bilan yaqinlashtirish mumkin.

X ~ B(n,p)

uchun normal modelda

o‘rtacha = np

va

dispersiya = np(1-p).

Masalan,

X ~ B(100,0.4).

Yaqinlashtiruvchi normal Y uchun

o‘rtacha = 40,
dispersiya = 24.

P(X≤45) ni yaqinlashtirish uchun avval uzluksizlik tuzatishini qo‘llaymiz:

P(X≤45) ≈ P(Y<45.5).

Keyin standartlashtiramiz:

z=(45.5-40)/√24≈1.123.

Demak,

P(X≤45)≈0.8692.

Uzluksizlik tuzatishi standartlashtirishdan oldin qo‘llanadi, chunki u diskret butun sonli chegarani uzluksiz shkalaga o‘tkazadi.$t$,
$t$Binomial taqsimot normal yaqinlashuv uchun mos bo‘lsa,

o‘rtacha=np,
dispersiya=np(1-p).

X~B(100,0.4) uchun:

o‘rtacha=40,
dispersiya=24.

P(X≤45) uchun uzluksizlik tuzatishi:

P(Y<45.5).

Shundan z≈1.123 va

P(X≤45)≈0.8692.$t$,
$t$Binomial qiymatlarni butun sonlar markazidagi ustunlar deb tasavvur qiling. Uzluksiz normal egri chiziq shu ustunlarni almashtiradi.

X≤45 hodisasi 45 markazli ustunning hammasini o‘z ichiga oladi. Shuning uchun uzluksiz chegara keyingi butun songacha bo‘lgan o‘rtada — 45.5 da olinadi. Shu yarim birlik siljish uzluksizlik tuzatishidir.$t$,
$t$Avval normal yaqinlashuv mos ekanini tekshiring. μ=np va σ²=np(1-p) dan foydalaning; dispersiyani standart og‘ish bilan aralashtirmang. Uzluksizlik tuzatishini z ni hisoblashdan oldin diskret chegaraga qo‘llang. Yarim birlik siljish yo‘nalishi hodisaga bog‘liq.$t$,
'p5:P5-NOR-06:theory:uz:v1'
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
