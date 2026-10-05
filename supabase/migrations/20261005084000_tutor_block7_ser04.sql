begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>96 then raise exception 'SER04 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-SER-04' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'SER04 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-SER-04:tutor:en:v2','P1','P1-SER-04','en','tutor_v2_learner_first','Geometric progressions',
$t$For a geometric progression with first term a and common ratio r,

u_n = ar^(n-1)

gives the nth term, and

S_n = a(1-r^n)/(1-r),   r≠1,

gives the sum of the first n terms.

For example, let a=3 and r=2.

u_6 = 3×2^5 = 96.

S_6 = 3(1-2^6)/(1-2)
= 3(1-64)/(-1)
= 189.

Inverse problems work by substituting known terms or sums into the same formulas and solving for a, r or n. The important structural idea is that geometric progressions change multiplicatively: each step multiplies by r.$t$,
$t$Geometric progression formulas:

u_n = ar^(n-1)

S_n = a(1-r^n)/(1-r), for r≠1.

For a=3 and r=2:

u_6=96

and

S_6=189.

Use the same formulas backwards in inverse problems.$t$,
$t$Think of a geometric progression as repeated multiplication.

Starting from a, reaching term n requires n-1 multiplications by r. That gives

u_n = ar^(n-1).

The finite-sum formula collects all those repeated powers of r into one expression. So the nth-term formula describes one position, while S_n describes the accumulated total up to that position.$t$,
$t$The exponent is n-1, not n. Check the sign and size of r carefully: a negative ratio makes signs alternate. For the finite-sum formula, keep the denominator 1-r consistent with the numerator 1-r^n. If r=1, use the obvious repeated-term sum instead of this formula.$t$,
'p1:P1-SER-04:theory:en:v1'
),
(
'p1:P1-SER-04:tutor:ru:v2','P1','P1-SER-04','ru','tutor_v2_learner_first','Геометрическая прогрессия',
$t$Для геометрической прогрессии с первым членом a и постоянным отношением r:

u_n = ar^(n-1)

задаёт n-й член, а

S_n = a(1-r^n)/(1-r),   r≠1,

даёт сумму первых n членов.

Например, пусть a=3 и r=2.

u_6 = 3×2^5 = 96.

S_6 = 3(1-2^6)/(1-2)
= 3(1-64)/(-1)
= 189.

В обратных задачах подставляйте известные члены или суммы в те же формулы и находите a, r или n. Главное отличие геометрической прогрессии — каждый следующий шаг получается умножением на r.$t$,
$t$Формулы геометрической прогрессии:

u_n = ar^(n-1)

S_n = a(1-r^n)/(1-r), при r≠1.

При a=3 и r=2:

u_6=96,

S_6=189.

В обратных задачах используйте те же формулы в обратном направлении.$t$,
$t$Представьте геометрическую прогрессию как повторяющееся умножение.

От первого члена a до n-го нужно n-1 раз умножить на r. Поэтому

u_n = ar^(n-1).

Формула конечной суммы собирает все эти последовательные степени r в одно выражение. u_n описывает один конкретный член, а S_n — накопленную сумму до него.$t$,
$t$В показателе степени стоит n-1, а не n. Внимательно проверяйте знак и величину r: отрицательное r заставляет знаки чередоваться. В формуле суммы сохраняйте согласованную пару 1-r^n и 1-r. При r=1 используйте обычную сумму одинаковых членов.$t$,
'p1:P1-SER-04:theory:ru:v1'
),
(
'p1:P1-SER-04:tutor:uz:v2','P1','P1-SER-04','uz','tutor_v2_learner_first','Geometrik progressiya',
$t$Birinchi hadi a va doimiy nisbati r bo‘lgan geometrik progressiya uchun

u_n = ar^(n-1)

n-hadni, 

S_n = a(1-r^n)/(1-r),   r≠1,

esa birinchi n ta had yig‘indisini beradi.

Masalan, a=3 va r=2 bo‘lsin.

u_6 = 3×2^5 = 96.

S_6 = 3(1-2^6)/(1-2)
= 3(1-64)/(-1)
= 189.

Teskari masalalarda ma’lum hadlar yoki yig‘indilarni shu formulalarga qo‘yib a, r yoki n ni toping. Geometrik progressiyaning asosiy tuzilishi shuki, har bir keyingi qadam r ga ko‘paytirish orqali olinadi.$t$,
$t$Geometrik progressiya formulalari:

u_n = ar^(n-1)

S_n = a(1-r^n)/(1-r), r≠1.

a=3 va r=2 bo‘lsa:

u_6=96,

S_6=189.

Teskari masalalarda shu formulalardan orqaga qarab foydalaning.$t$,
$t$Geometrik progressiyani takroriy ko‘paytirish deb tasavvur qiling.

a dan n-hadgacha borish uchun r ga n-1 marta ko‘paytirish kerak. Shuning uchun

u_n = ar^(n-1).

Chekli yig‘indi formulasi r ning shu ketma-ket darajalarini bitta ifodada jamlaydi. u_n bitta hadni, S_n esa shu hadgacha bo‘lgan umumiy yig‘indini tasvirlaydi.$t$,
$t$Daraja ko‘rsatkichi n-1, n emas. r ning ishorasi va kattaligini tekshiring: manfiy r ishoralarni almashib borishiga olib keladi. Yig‘indi formulasida 1-r^n va 1-r tartibini bir xil saqlang. r=1 bo‘lsa, bir xil hadlarning oddiy yig‘indisini ishlating.$t$,
'p1:P1-SER-04:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
