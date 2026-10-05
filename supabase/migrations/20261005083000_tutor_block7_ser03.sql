begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>93 then raise exception 'SER03 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-SER-03' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'SER03 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-SER-03:tutor:en:v2','P1','P1-SER-03','en','tutor_v2_learner_first','Arithmetic progressions',
$t$For an arithmetic progression with first term a and common difference d,

u_n = a + (n-1)d

gives the nth term, and

S_n = n/2 [2a + (n-1)d]

gives the sum of the first n terms.

For example, let a=5 and d=3.

u_10 = 5 + 9×3 = 32.

S_10 = 10/2 [2×5 + 9×3]
= 5(37)
= 185.

Inverse problems use the same formulas backwards. If a term, sum or position is known, substitute the known values and solve the resulting equation for a, d or n.$t$,
$t$Arithmetic progression formulas:

u_n = a + (n-1)d

S_n = n/2 [2a + (n-1)d].

For a=5 and d=3:

u_10=32

and

S_10=185.

For an inverse problem, put the known information into the same formulas and solve for the missing quantity.$t$,
$t$Think of an arithmetic progression as repeated equal steps.

Starting from a, reaching term n requires n-1 steps of size d. That gives

u_n = a + (n-1)d.

For the sum, the first and last terms can be paired. Every pair has the same total, which leads to the arithmetic-series sum formula.

The formulas are therefore descriptions of the pattern, not unrelated rules to memorise.$t$,
$t$The nth term uses n-1 differences, not n. Keep u_n and S_n separate: one is a single term, the other is a sum. In inverse problems, write one equation for each piece of information before solving.$t$,
'p1:P1-SER-03:theory:en:v1'
),
(
'p1:P1-SER-03:tutor:ru:v2','P1','P1-SER-03','ru','tutor_v2_learner_first','Арифметическая прогрессия',
$t$Для арифметической прогрессии с первым членом a и постоянной разностью d:

u_n = a + (n-1)d

задаёт n-й член, а

S_n = n/2 [2a + (n-1)d]

даёт сумму первых n членов.

Например, пусть a=5 и d=3.

u_10 = 5 + 9×3 = 32.

S_10 = 10/2 [2×5 + 9×3]
= 5(37)
= 185.

В обратных задачах используются те же формулы. Если известны член, сумма или номер, подставьте известные величины и решите полученное уравнение относительно a, d или n.$t$,
$t$Формулы арифметической прогрессии:

u_n = a + (n-1)d

S_n = n/2 [2a + (n-1)d].

При a=5 и d=3:

u_10=32,

S_10=185.

В обратной задаче подставьте известные данные в те же формулы и найдите неизвестную величину.$t$,
$t$Представьте арифметическую прогрессию как одинаковые шаги.

От первого члена a до n-го нужно сделать n-1 шагов величины d. Поэтому

u_n = a + (n-1)d.

Для суммы можно попарно складывать первый и последний члены: каждая такая пара имеет одну и ту же сумму. Отсюда получается формула S_n.

То есть формулы описывают сам рисунок прогрессии, а не являются отдельными правилами без связи.$t$,
$t$До n-го члена выполняется n-1 шагов, а не n. Не путайте u_n и S_n: первое — один член, второе — сумма. В обратной задаче сначала составьте отдельное уравнение для каждого известного условия.$t$,
'p1:P1-SER-03:theory:ru:v1'
),
(
'p1:P1-SER-03:tutor:uz:v2','P1','P1-SER-03','uz','tutor_v2_learner_first','Arifmetik progressiya',
$t$Birinchi hadi a va doimiy ayirmasi d bo‘lgan arifmetik progressiya uchun

u_n = a + (n-1)d

n-hadni, 

S_n = n/2 [2a + (n-1)d]

esa birinchi n ta had yig‘indisini beradi.

Masalan, a=5 va d=3 bo‘lsin.

u_10 = 5 + 9×3 = 32.

S_10 = 10/2 [2×5 + 9×3]
= 5(37)
= 185.

Teskari masalalarda ham shu formulalar ishlatiladi. Had, yig‘indi yoki tartib raqami ma’lum bo‘lsa, ma’lum qiymatlarni formulaga qo‘yib a, d yoki n ni toping.$t$,
$t$Arifmetik progressiya formulalari:

u_n = a + (n-1)d

S_n = n/2 [2a + (n-1)d].

a=5 va d=3 bo‘lsa:

u_10=32,

S_10=185.

Teskari masalada ma’lum qiymatlarni shu formulalarga qo‘yib noma’lum kattalikni toping.$t$,
$t$Arifmetik progressiyani teng qadamlar deb tasavvur qiling.

a dan n-hadgacha borish uchun d kattalikdagi n-1 ta qadam kerak. Shuning uchun

u_n = a + (n-1)d.

Yig‘indida birinchi va oxirgi hadlarni juftlab ko‘rish mumkin: har bir juftning yig‘indisi bir xil bo‘ladi. Shu fikr S_n formulasiga olib keladi.

Demak, formulalar progressiya tuzilishini ifodalaydi.$t$,
$t$n-hadgacha n ta emas, n-1 ta ayirma qadam bor. u_n va S_n ni aralashtirmang: biri bitta had, ikkinchisi yig‘indi. Teskari masalada har bir berilgan shart uchun alohida tenglama yozing.$t$,
'p1:P1-SER-03:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
