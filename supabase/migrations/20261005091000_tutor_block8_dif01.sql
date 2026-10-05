begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>102 then raise exception 'DIF01 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-DIF-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DIF01 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-DIF-01:tutor:en:v2','P1','P1-DIF-01','en','tutor_v2_learner_first','Meaning of the derivative',
$t$The derivative tells you how fast a quantity is changing at one instant. On a graph, it is the gradient of the tangent.

For f(x)=x² at x=3, start from the average gradient over a small change h:

[f(3+h)-f(3)]/h
= [(3+h)²-9]/h
= 6+h.

As h approaches 0, this approaches 6. Therefore f'(3)=6.

So the derivative is the limit of nearby average gradients: the secant line becomes the tangent line. The same idea also describes instantaneous rates such as speed, growth or area change.$t$,
$t$Derivative = instantaneous gradient or rate of change.

For f(x)=x² at x=3:

[f(3+h)-f(3)]/h = 6+h.

As h→0, this becomes 6.

So the tangent gradient at x=3 is 6.$t$,
$t$Imagine zooming in on a smooth curve around one point. The curve looks more and more like a straight line. The gradient of that local straight line is the derivative.

The limit calculation measures gradients between two nearby points, then lets the gap shrink to zero.$t$,
$t$Average gradient uses two different points; derivative uses the limiting gradient at one point. In a limit-definition question, simplify before substituting h=0. Keep the interpretation attached to the answer: gradient or rate of change.$t$,
'p1:P1-DIF-01:theory:en:v1'
),
(
'p1:P1-DIF-01:tutor:ru:v2','P1','P1-DIF-01','ru','tutor_v2_learner_first','Смысл производной',
$t$Производная показывает, как быстро величина меняется в данный момент. На графике это угловой коэффициент касательной.

Для f(x)=x² в точке x=3 рассмотрим средний градиент при малом изменении h:

[f(3+h)-f(3)]/h
= [(3+h)²-9]/h
= 6+h.

При h→0 выражение стремится к 6. Поэтому f'(3)=6.

Производная — это предел средних градиентов между всё более близкими точками: секущая превращается в касательную. Та же идея описывает мгновенную скорость изменения.$t$,
$t$Производная — это мгновенный градиент или скорость изменения.

Для f(x)=x² при x=3:

[f(3+h)-f(3)]/h = 6+h.

При h→0 получаем 6.

Значит, градиент касательной равен 6.$t$,
$t$Представьте, что вы всё сильнее увеличиваете небольшой участок гладкого графика около точки. Кривая начинает выглядеть почти как прямая. Градиент этой локальной прямой и есть производная.

Предел берёт градиенты между двумя близкими точками и уменьшает расстояние между ними до нуля.$t$,
$t$Средний градиент относится к двум разным точкам, производная — к предельному градиенту в одной точке. В определении через предел сначала упростите выражение, только затем переходите к h=0. Связывайте ответ с его смыслом: градиент или скорость изменения.$t$,
'p1:P1-DIF-01:theory:ru:v1'
),
(
'p1:P1-DIF-01:tutor:uz:v2','P1','P1-DIF-01','uz','tutor_v2_learner_first','Hosilaning ma’nosi',
$t$Hosila kattalik ayni bir paytda qanchalik tez o‘zgarayotganini ko‘rsatadi. Grafikda bu urinma chiziqning gradientidir.

f(x)=x² va x=3 uchun kichik h o‘zgarishdagi o‘rtacha gradientni olaylik:

[f(3+h)-f(3)]/h
= [(3+h)²-9]/h
= 6+h.

h→0 bo‘lganda bu 6 ga yaqinlashadi. Demak, f'(3)=6.

Hosila — bir-biriga tobora yaqin ikki nuqta orasidagi o‘rtacha gradientlarning chegarasi. Sekuvchi chiziq urinmaga aylanadi. Shu g‘oya oniy o‘zgarish tezligini ham ifodalaydi.$t$,
$t$Hosila — oniy gradient yoki o‘zgarish tezligi.

f(x)=x² va x=3 uchun:

[f(3+h)-f(3)]/h = 6+h.

h→0 da bu 6 bo‘ladi.

Demak, urinma gradienti 6.$t$,
$t$Silliq grafikning bitta nuqta atrofini juda kattalashtirayotganingizni tasavvur qiling. Grafik asta-sekin to‘g‘ri chiziqqa o‘xshaydi. Shu mahalliy chiziq gradienti hosiladir.

Limit hisobida ikki yaqin nuqta gradienti olinadi va ular orasidagi masofa nolga yaqinlashtiriladi.$t$,
$t$O‘rtacha gradient ikki nuqta orasida, hosila esa bitta nuqtadagi limit gradientidir. Limit ta’rifida h=0 ni darhol qo‘ymang: avval ifodani soddalashtiring. Javobning ma’nosini ham saqlang — gradient yoki o‘zgarish tezligi.$t$,
'p1:P1-DIF-01:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
