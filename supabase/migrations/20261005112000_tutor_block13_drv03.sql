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
  if v<>207 then raise exception 'DRV03 expected 207 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DRV-03')<>0
  then raise exception 'DRV03 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DRV-03' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DRV03 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-DRV-03:tutor:en:v2','P5','P5-DRV-03','en','tutor_v2_learner_first',
'Variance and standard deviation',
$t$Variance measures how spread out a discrete random variable is around its mean.

A convenient formula is

Var(X)=E(X²)-[E(X)]².

Using X=0,1,2 with probabilities 0.2,0.3,0.5:

E(X)=1.3.

Next,

E(X²)=0²(0.2)+1²(0.3)+2²(0.5)
=0+0.3+2.0
=2.3.

Therefore

Var(X)=2.3-1.3²
=2.3-1.69
=0.61.

The standard deviation is

SD(X)=√0.61≈0.781.

Variance uses squared units; standard deviation returns to the same units as X. Both measure spread, but standard deviation is often easier to interpret alongside the original variable.$t$,
$t$Use

Var(X)=E(X²)-[E(X)]².

For X=0,1,2 with probabilities 0.2,0.3,0.5:

E(X)=1.3,
E(X²)=2.3.

So

Var(X)=2.3-1.3²=0.61,

and

SD(X)=√0.61≈0.781.$t$,
$t$Think of variance as measuring the typical squared distance from the mean. The formula E(X²)-[E(X)]² is a faster way to calculate the same spread.

Because the distances are squared, variance is in squared units. Taking the square root gives standard deviation, which returns to the original scale of X.$t$,
$t$Do not confuse E(X²) with [E(X)]²; calculate them separately. Keep enough accuracy before the final subtraction and square root. Variance cannot be negative, so a negative result signals an error.$t$,
'p5:P5-DRV-03:theory:en:v1'
),
(
'p5:P5-DRV-03:tutor:ru:v2','P5','P5-DRV-03','ru','tutor_v2_learner_first',
'Дисперсия и стандартное отклонение',
$t$Дисперсия измеряет разброс дискретной случайной величины относительно её среднего.

Удобная формула:

Var(X)=E(X²)-[E(X)]².

Для X=0,1,2 с вероятностями 0.2,0.3,0.5:

E(X)=1.3.

Далее

E(X²)=0²(0.2)+1²(0.3)+2²(0.5)
=0+0.3+2.0
=2.3.

Поэтому

Var(X)=2.3-1.3²
=2.3-1.69
=0.61.

Стандартное отклонение:

SD(X)=√0.61≈0.781.

Дисперсия имеет квадратные единицы, а стандартное отклонение возвращается к тем же единицам, что и X. Оба показателя описывают разброс.$t$,
$t$Используйте

Var(X)=E(X²)-[E(X)]².

Для X=0,1,2 с вероятностями 0.2,0.3,0.5:

E(X)=1.3,
E(X²)=2.3.

Тогда

Var(X)=2.3-1.3²=0.61,

а

SD(X)=√0.61≈0.781.$t$,
$t$Можно понимать дисперсию как меру типичного квадрата отклонения от среднего. Формула E(X²)-[E(X)]² позволяет вычислить тот же разброс быстрее.

Из-за возведения в квадрат дисперсия имеет квадратные единицы. После извлечения корня стандартное отклонение возвращается к исходному масштабу X.$t$,
$t$Не путайте E(X²) и [E(X)]² — это разные величины, их нужно считать отдельно. Сохраняйте достаточную точность до последнего шага. Дисперсия не может быть отрицательной: отрицательный результат означает ошибку.$t$,
'p5:P5-DRV-03:theory:ru:v1'
),
(
'p5:P5-DRV-03:tutor:uz:v2','P5','P5-DRV-03','uz','tutor_v2_learner_first',
'Dispersiya va standart og‘ish',
$t$Dispersiya diskret tasodifiy miqdorning o‘rtacha qiymat atrofida qanchalik tarqalganini o‘lchaydi.

Qulay formula:

Var(X)=E(X²)-[E(X)]².

X=0,1,2 va ehtimolliklar 0.2,0.3,0.5 bo‘lsa:

E(X)=1.3.

Keyin

E(X²)=0²(0.2)+1²(0.3)+2²(0.5)
=0+0.3+2.0
=2.3.

Demak,

Var(X)=2.3-1.3²
=2.3-1.69
=0.61.

Standart og‘ish:

SD(X)=√0.61≈0.781.

Dispersiya kvadrat birliklarda, standart og‘ish esa X bilan bir xil birliklarda bo‘ladi. Ikkalasi ham tarqalishni ifodalaydi.$t$,
$t$Quyidagidan foydalaning:

Var(X)=E(X²)-[E(X)]².

X=0,1,2 va ehtimolliklar 0.2,0.3,0.5 uchun:

E(X)=1.3,
E(X²)=2.3.

Shuning uchun

Var(X)=2.3-1.3²=0.61,

va

SD(X)=√0.61≈0.781.$t$,
$t$Dispersiyani o‘rtachadan bo‘lgan masofalarning kvadratlari orqali tarqalish o‘lchovi deb o‘ylang. E(X²)-[E(X)]² formulasi shu tarqalishni tezroq hisoblaydi.

Kvadrat sabab dispersiya kvadrat birliklarda bo‘ladi. Kvadrat ildiz olinsa, standart og‘ish X ning asl birliklariga qaytadi.$t$,
$t$E(X²) bilan [E(X)]² ni aralashtirmang — ularni alohida hisoblang. Yakuniy ayirish va ildizgacha yetarli aniqlikni saqlang. Dispersiya manfiy bo‘la olmaydi; manfiy natija xatoni bildiradi.$t$,
'p5:P5-DRV-03:theory:uz:v1'
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
