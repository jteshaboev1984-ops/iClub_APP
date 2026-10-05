begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>99 then raise exception 'SER05 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-SER-05' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'SER05 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-SER-05:tutor:en:v2','P1','P1-SER-05','en','tutor_v2_learner_first','Infinite geometric series',
$t$An infinite geometric series has a finite sum only when the terms shrink towards zero, which happens when

|r| < 1.

In that case,

S∞ = a/(1-r).

For example, let a=12 and r=1/3.

S∞
= 12/(1-1/3)
= 12/(2/3)
= 18.

So the infinite series has sum 18.

If |r|≥1, the terms do not shrink to zero in the required way, so there is no finite sum to infinity. Always check convergence before using the formula.$t$,
$t$First check

|r|<1.

Only then use

S∞ = a/(1-r).

For a=12 and r=1/3:

S∞=18.

If |r|≥1, do not use the sum-to-infinity formula.$t$,
$t$Imagine adding more and more terms of a geometric series.

When |r|<1, each new term is smaller in magnitude than the previous one, so the running total settles towards a fixed number. That fixed number is the sum to infinity.

When |r|≥1, the terms do not decay in the required way, so the running total cannot settle to a finite limit.$t$,
$t$Check convergence before calculating: |r|<1 is required. Do not confuse the finite-sum formula with S∞. A negative r can still converge if its magnitude is below 1. If the condition fails, state that the series does not have a finite sum to infinity.$t$,
'p1:P1-SER-05:theory:en:v1'
),
(
'p1:P1-SER-05:tutor:ru:v2','P1','P1-SER-05','ru','tutor_v2_learner_first','Бесконечный геометрический ряд',
$t$Бесконечный геометрический ряд имеет конечную сумму только тогда, когда его члены стремятся к нулю. Для геометрической прогрессии это происходит при

|r| < 1.

Тогда

S∞ = a/(1-r).

Например, пусть a=12 и r=1/3.

S∞
= 12/(1-1/3)
= 12/(2/3)
= 18.

Значит, сумма бесконечного ряда равна 18.

Если |r|≥1, члены не уменьшаются к нулю нужным образом, поэтому конечной суммы до бесконечности нет. Сначала всегда проверяйте условие сходимости.$t$,
$t$Сначала проверьте

|r|<1.

Только после этого используйте

S∞ = a/(1-r).

При a=12 и r=1/3:

S∞=18.

Если |r|≥1, формулу суммы до бесконечности применять нельзя.$t$,
$t$Представьте, что к сумме добавляются всё новые члены геометрического ряда.

При |r|<1 каждый следующий член меньше по модулю, и накопленная сумма постепенно приближается к фиксированному числу. Это и есть сумма до бесконечности.

При |r|≥1 члены не уменьшаются нужным образом, поэтому сумма не может стабилизироваться около конечного значения.$t$,
$t$Сначала проверяйте сходимость: обязательно |r|<1. Не путайте формулу конечной суммы с S∞. Отрицательное r тоже может давать сходящийся ряд, если |r|<1. Если условие не выполняется, у ряда нет конечной суммы до бесконечности.$t$,
'p1:P1-SER-05:theory:ru:v1'
),
(
'p1:P1-SER-05:tutor:uz:v2','P1','P1-SER-05','uz','tutor_v2_learner_first','Cheksiz geometrik qator',
$t$Cheksiz geometrik qator faqat hadlari nolga yaqinlashganda chekli yig‘indiga ega bo‘ladi. Geometrik progressiya uchun bu shart

|r| < 1.

Shunda

S∞ = a/(1-r).

Masalan, a=12 va r=1/3 bo‘lsin.

S∞
= 12/(1-1/3)
= 12/(2/3)
= 18.

Demak, cheksiz qator yig‘indisi 18.

Agar |r|≥1 bo‘lsa, hadlar kerakli tarzda nolga yaqinlashmaydi va chekli cheksizlik yig‘indisi mavjud bo‘lmaydi. Formulani ishlatishdan oldin har doim yaqinlashish shartini tekshiring.$t$,
$t$Avval

|r|<1

ekanini tekshiring.

Faqat shundan keyin

S∞ = a/(1-r)

formulasidan foydalaning.

a=12 va r=1/3 bo‘lsa, S∞=18.

|r|≥1 bo‘lsa, cheksizlik yig‘indisi formulasini ishlatmang.$t$,
$t$Geometrik qatorga tobora ko‘proq had qo‘shilayotganini tasavvur qiling.

|r|<1 bo‘lsa, har bir keyingi hadning moduli kichrayadi va yig‘indi asta-sekin bitta o‘zgarmas songa yaqinlashadi. Shu son cheksizlikdagi yig‘indi bo‘ladi.

|r|≥1 bo‘lsa, hadlar kerakli darajada kichraymaydi va yig‘indi chekli songa yaqinlashmaydi.$t$,
$t$Hisoblashdan oldin yaqinlashishni tekshiring: |r|<1 bo‘lishi shart. Chekli yig‘indi formulasini S∞ bilan aralashtirmang. r manfiy bo‘lsa ham |r|<1 bo‘lsa qator yaqinlashishi mumkin. Shart bajarilmasa, chekli cheksizlik yig‘indisi mavjud emas.$t$,
'p1:P1-SER-05:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
