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
  if v<>201 then raise exception 'DRV01 expected 201 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DRV-01')<>0
  then raise exception 'DRV01 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DRV-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DRV01 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-DRV-01:tutor:en:v2','P5','P5-DRV-01','en','tutor_v2_learner_first',
'Discrete probability distributions',
$t$A discrete probability distribution lists the possible values of a random variable and the probability attached to each value.

Two checks must always hold:
- every probability is between 0 and 1;
- all probabilities add to 1.

Suppose X can take values 0, 1 and 2 with probabilities

0.2, k, 0.5.

Because the probabilities must total 1,

0.2 + k + 0.5 = 1,

so

k = 0.3.

Now the distribution is valid because all three probabilities are non-negative and sum to 1.

The key idea is that the probabilities are not separate numbers: together they describe the whole distribution. If one probability is unknown, the total-to-one condition usually gives the missing value.$t$,
$t$A valid discrete distribution has probabilities between 0 and 1, and their total is 1.

If X=0,1,2 has probabilities 0.2, k, 0.5, then

0.2+k+0.5=1,

so

k=0.3.

Always check the final probabilities are valid and add to 1.$t$,
$t$Think of total probability as one whole unit that must be shared among all possible values of X.

If 0.2 is assigned to X=0 and 0.5 to X=2, then 0.7 has already been used. The remaining probability mass is 0.3, so that must belong to X=1.$t$,
$t$Check both conditions: each probability must lie between 0 and 1, and the total must be exactly 1. When solving for an unknown probability, substitute it back and re-check the full distribution.$t$,
'p5:P5-DRV-01:theory:en:v1'
),
(
'p5:P5-DRV-01:tutor:ru:v2','P5','P5-DRV-01','ru','tutor_v2_learner_first',
'Дискретное распределение вероятностей',
$t$Дискретное распределение вероятностей показывает возможные значения случайной величины и вероятность каждого значения.

Всегда должны выполняться два условия:
- каждая вероятность находится от 0 до 1;
- сумма всех вероятностей равна 1.

Пусть X принимает значения 0, 1 и 2 с вероятностями

0.2, k, 0.5.

Так как сумма вероятностей равна 1,

0.2 + k + 0.5 = 1,

поэтому

k = 0.3.

Теперь распределение корректно: все вероятности неотрицательны и в сумме дают 1.

Главная идея: вероятности образуют единое распределение. Если одна вероятность неизвестна, условие суммы, равной 1, обычно позволяет её восстановить.$t$,
$t$В корректном дискретном распределении каждая вероятность находится от 0 до 1, а их сумма равна 1.

Если для X=0,1,2 вероятности равны 0.2, k, 0.5, то

0.2+k+0.5=1,

значит

k=0.3.

После этого проверьте, что все вероятности допустимы и их сумма равна 1.$t$,
$t$Представьте общую вероятность как одну целую единицу, которую нужно распределить между всеми возможными значениями X.

Для X=0 уже используется 0.2, для X=2 — 0.5. Всего занято 0.7. Оставшиеся 0.3 должны приходиться на X=1.$t$,
$t$Проверяйте оба условия: каждая вероятность должна быть между 0 и 1, а общая сумма — ровно 1. После нахождения неизвестной вероятности подставьте её обратно и перепроверьте всё распределение.$t$,
'p5:P5-DRV-01:theory:ru:v1'
),
(
'p5:P5-DRV-01:tutor:uz:v2','P5','P5-DRV-01','uz','tutor_v2_learner_first',
'Diskret ehtimollik taqsimoti',
$t$Diskret ehtimollik taqsimoti tasodifiy miqdorning mumkin bo‘lgan qiymatlarini va har bir qiymatga mos ehtimollikni ko‘rsatadi.

Ikki shart doimo bajarilishi kerak:
- har bir ehtimollik 0 dan 1 gacha bo‘lishi;
- barcha ehtimolliklar yig‘indisi 1 bo‘lishi.

X 0, 1 va 2 qiymatlarni mos ravishda

0.2, k, 0.5

ehtimolliklar bilan qabul qilsin.

Ehtimolliklar yig‘indisi 1 bo‘lgani uchun

0.2 + k + 0.5 = 1,

demak

k = 0.3.

Endi taqsimot to‘g‘ri: barcha ehtimolliklar manfiy emas va yig‘indisi 1.

Asosiy g‘oya: ehtimolliklar alohida sonlar emas, ular birgalikda butun taqsimotni tashkil qiladi.$t$,
$t$To‘g‘ri diskret taqsimotda har bir ehtimollik 0 dan 1 gacha va ularning yig‘indisi 1 bo‘ladi.

X=0,1,2 uchun ehtimolliklar 0.2, k, 0.5 bo‘lsa,

0.2+k+0.5=1,

shuning uchun

k=0.3.

Oxirida barcha ehtimolliklar yaroqli ekanini va yig‘indi 1 ekanini tekshiring.$t$,
$t$Umumiy ehtimollikni barcha mumkin qiymatlar orasida taqsimlanadigan bitta butun birlik deb o‘ylang.

X=0 uchun 0.2, X=2 uchun 0.5 allaqachon ishlatilgan. Jami 0.7. Qolgan 0.3 X=1 ga tegishli bo‘lishi kerak.$t$,
$t$Ikkala shartni tekshiring: har bir ehtimollik 0 va 1 orasida bo‘lsin, umumiy yig‘indi esa aynan 1 bo‘lsin. Noma’lum ehtimollikni topgach, uni qayta qo‘yib butun taqsimotni tekshiring.$t$,
'p5:P5-DRV-01:theory:uz:v1'
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
