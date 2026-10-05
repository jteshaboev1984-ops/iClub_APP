begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>90 then raise exception 'SER02 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-SER-02' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'SER02 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-SER-02:tutor:en:v2','P1','P1-SER-02','en','tutor_v2_learner_first','Arithmetic and geometric progressions',
$t$A progression is identified by how consecutive terms are related.

An arithmetic progression has a constant difference. For

3, 7, 11, 15, ...

each term increases by 4, so d=4.

A geometric progression has a constant ratio. For

2, 6, 18, 54, ...

each term is multiplied by 3, so r=3.

The sequence

1, 2, 4, 7, ...

is neither: the differences are not constant and the ratios are not constant.

Do not classify a progression from only the first two terms. Check the same difference or ratio across several consecutive terms.$t$,
$t$Arithmetic progression: add the same amount each time.

3, 7, 11, 15, ... has difference 4.

Geometric progression: multiply by the same factor each time.

2, 6, 18, 54, ... has ratio 3.

If neither the differences nor ratios stay constant, it is neither type.$t$,
$t$Ask two questions in order:

1. Are the consecutive differences equal?
2. If not, are the consecutive ratios equal?

For 3,7,11,15 the differences are all 4, so it is arithmetic.

For 2,6,18,54 the ratios are all 3, so it is geometric.

This test focuses on the structure of the terms rather than how large they become.$t$,
$t$Check at least two consecutive differences or ratios. A geometric ratio may be negative or fractional, so do not assume geometric means “growing”. Never decide from just the first two terms.$t$,
'p1:P1-SER-02:theory:en:v1'
),
(
'p1:P1-SER-02:tutor:ru:v2','P1','P1-SER-02','ru','tutor_v2_learner_first','Арифметическая и геометрическая прогрессии',
$t$Тип прогрессии определяется тем, как связаны соседние члены.

В арифметической прогрессии разность постоянна. Для

3, 7, 11, 15, ...

каждый следующий член больше на 4, поэтому d=4.

В геометрической прогрессии отношение постоянно. Для

2, 6, 18, 54, ...

каждый следующий член получается умножением на 3, поэтому r=3.

Последовательность

1, 2, 4, 7, ...

не относится ни к одному типу: разности и отношения не постоянны.

Не определяйте тип только по первым двум членам. Проверьте одну и ту же разность или отношение на нескольких соседних переходах.$t$,
$t$Арифметическая прогрессия: каждый раз прибавляется одно и то же число.

3, 7, 11, 15, ... имеет разность 4.

Геометрическая прогрессия: каждый раз умножаем на один и тот же коэффициент.

2, 6, 18, 54, ... имеет отношение 3.

Если постоянны ни разности, ни отношения, это другой тип последовательности.$t$,
$t$Задайте два вопроса по порядку:

1. Равны ли соседние разности?
2. Если нет, равны ли соседние отношения?

Для 3,7,11,15 все разности равны 4 — это арифметическая прогрессия.

Для 2,6,18,54 все отношения равны 3 — это геометрическая прогрессия.

Так вы смотрите на структуру последовательности, а не просто на рост чисел.$t$,
$t$Проверяйте минимум две соседние разности или отношения. Отношение геометрической прогрессии может быть отрицательным или дробным, поэтому она не обязана возрастать. Не делайте вывод только по первым двум членам.$t$,
'p1:P1-SER-02:theory:ru:v1'
),
(
'p1:P1-SER-02:tutor:uz:v2','P1','P1-SER-02','uz','tutor_v2_learner_first','Arifmetik va geometrik progressiyalar',
$t$Progressiya turi ketma-ket hadlar orasidagi bog‘lanish orqali aniqlanadi.

Arifmetik progressiyada ayirma o‘zgarmaydi. Masalan,

3, 7, 11, 15, ...

har safar 4 ga oshadi, demak d=4.

Geometrik progressiyada nisbat o‘zgarmaydi. Masalan,

2, 6, 18, 54, ...

har safar 3 ga ko‘payadi, demak r=3.

1, 2, 4, 7, ...

ketma-ketlik esa ikkala turga ham kirmaydi: ayirmalar ham, nisbatlar ham o‘zgarmas emas.

Faqat birinchi ikki hadga qarab turini aniqlamang. Bir xil ayirma yoki nisbat bir necha ketma-ket o‘tishda saqlanishini tekshiring.$t$,
$t$Arifmetik progressiya: har safar bir xil son qo‘shiladi.

3, 7, 11, 15, ... uchun ayirma 4.

Geometrik progressiya: har safar bir xil songa ko‘paytiriladi.

2, 6, 18, 54, ... uchun nisbat 3.

Ayirma ham, nisbat ham o‘zgarmas bo‘lmasa, bu ikki turdan biri emas.$t$,
$t$Ikki savolni ketma-ket bering:

1. Qo‘shni hadlarning ayirmalari tengmi?
2. Teng bo‘lmasa, qo‘shni hadlarning nisbatlari tengmi?

3,7,11,15 uchun barcha ayirmalar 4, shuning uchun arifmetik.

2,6,18,54 uchun barcha nisbatlar 3, shuning uchun geometrik.

Bu usul sonlarning kattaligiga emas, tuzilishiga qaraydi.$t$,
$t$Kamida ikki ketma-ket ayirma yoki nisbatni tekshiring. Geometrik progressiyada r manfiy yoki kasr bo‘lishi mumkin, shuning uchun geometrik degani doim o‘suvchi degani emas. Faqat birinchi ikki haddan xulosa qilmang.$t$,
'p1:P1-SER-02:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
