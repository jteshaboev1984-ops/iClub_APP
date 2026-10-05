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
  if v<>234 then raise exception 'NOR04 expected 234 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-NOR-04')<>0
  then raise exception 'NOR04 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-NOR-04' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'NOR04 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-NOR-04:tutor:en:v2','P5','P5-NOR-04','en','tutor_v2_learner_first',
'Normal quantiles',
$t$An inverse-normal question gives a probability and asks for the boundary value that creates that area.

Suppose

X ~ N(50,10²)

and we want the 90th percentile. This means

P(X<x)=0.90.

For the standard normal distribution, a left-tail area of 0.90 gives

z≈1.282.

Convert back to the X-scale:

x=μ+zσ
=50+1.282(10)
≈62.82.

So about 90% of the distribution lies below 62.82.

The important distinction is direction: an ordinary normal calculation starts with x and finds probability; an inverse-normal calculation starts with probability and finds x. Always check whether the given area is a left tail, right tail or central region before using the inverse function.$t$,
$t$Inverse normal works from probability to boundary.

For

X ~ N(50,10²),

the 90th percentile satisfies

P(X<x)=0.90.

This gives z≈1.282, so

x=50+1.282(10)≈62.82.

Therefore about 90% of values lie below 62.82.$t$,
$t$Think of the percentile as a cut on the bell curve.

The 90th percentile is the x-value that leaves 90% of the area to its left and 10% to its right. Inverse normal finds the position of that cut. Standardising first tells you the z-position; then μ and σ return you to the original scale.$t$,
$t$Do not confuse a probability with a data value. Identify which area is given before using inverse normal. If the question gives a right-tail probability, convert it to the corresponding left-tail area if your calculator expects left-tail input.$t$,
'p5:P5-NOR-04:theory:en:v1'
),
(
'p5:P5-NOR-04:tutor:ru:v2','P5','P5-NOR-04','ru','tutor_v2_learner_first',
'Квантили нормального распределения',
$t$В задаче на обратное нормальное распределение дана вероятность, а нужно найти граничное значение, которое создаёт такую площадь.

Пусть

X ~ N(50,10²)

и требуется 90-й процентиль. Это означает

P(X<x)=0.90.

Для стандартного нормального распределения площадь 0.90 слева даёт

z≈1.282.

Возвращаемся к шкале X:

x=μ+zσ
=50+1.282(10)
≈62.82.

Значит, примерно 90% распределения находится ниже 62.82.

Главное различие: обычная нормальная задача начинается с x и находит вероятность, а обратная — начинается с вероятности и находит x. Перед вычислением определите, дана ли площадь слева, справа или в центре.$t$,
$t$Обратное нормальное распределение работает от вероятности к границе.

Для

X ~ N(50,10²)

90-й процентиль удовлетворяет

P(X<x)=0.90.

Получаем z≈1.282, поэтому

x=50+1.282(10)≈62.82.

Около 90% значений находятся ниже 62.82.$t$,
$t$Представьте процентиль как вертикальный разрез колоколообразной кривой.

90-й процентиль — это значение x, слева от которого находится 90% площади, а справа — 10%. Обратная нормальная функция находит положение этого разреза. Сначала можно найти z, затем через μ и σ вернуться к исходной шкале.$t$,
$t$Не путайте вероятность и значение случайной величины. До применения inverse normal определите, какая именно площадь дана. Если дана вероятность правого хвоста, при необходимости переведите её в соответствующую площадь слева.$t$,
'p5:P5-NOR-04:theory:ru:v1'
),
(
'p5:P5-NOR-04:tutor:uz:v2','P5','P5-NOR-04','uz','tutor_v2_learner_first',
'Normal taqsimot kvantillari',
$t$Teskari normal masalada ehtimollik beriladi va shu yuzani hosil qiladigan chegara qiymati topiladi.

Masalan,

X ~ N(50,10²)

va 90-percentil kerak bo‘lsin. Bu

P(X<x)=0.90

degani.

Standart normal taqsimotda chap tomondagi 0.90 yuza

z≈1.282

ni beradi.

Endi X shkalasiga qaytamiz:

x=μ+zσ
=50+1.282(10)
≈62.82.

Demak, taqsimotning taxminan 90% qismi 62.82 dan pastda.

Muhim farq: oddiy normal hisob x dan ehtimollikka boradi, teskari normal esa ehtimollikdan x ga boradi. Hisoblashdan oldin berilgan yuza chap dum, o‘ng dum yoki markaziy soha ekanini aniqlang.$t$,
$t$Teskari normal ehtimollikdan chegara qiymatiga o‘tadi.

X ~ N(50,10²) uchun 90-percentil

P(X<x)=0.90

shartni bajaradi.

Bu z≈1.282 beradi, demak

x=50+1.282(10)≈62.82.

Qiymatlarning taxminan 90% qismi 62.82 dan pastda.$t$,
$t$Percentilni qo‘ng‘iroq egri chizig‘idagi vertikal kesim deb tasavvur qiling.

90-percentil — chap tomonda 90%, o‘ng tomonda 10% yuza qoldiradigan x qiymati. Teskari normal shu kesim joyini topadi. Avval z-shkaladagi o‘rin topiladi, keyin μ va σ orqali asl shkalaga qaytiladi.$t$,
$t$Ehtimollik bilan x qiymatini aralashtirmang. Inverse normal ishlatishdan oldin qaysi yuza berilganini aniqlang. Agar o‘ng dum ehtimoli berilgan bo‘lsa, kalkulyator chap dum yuzasini talab qilsa uni mos ravishda o‘zgartiring.$t$,
'p5:P5-NOR-04:theory:uz:v1'
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
