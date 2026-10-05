begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>141 then raise exception 'DAT02 expected 141 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DAT-02' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DAT02 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-DAT-02:tutor:en:v2','P5','P5-DAT-02','en','tutor_v2_learner_first','Stem-and-leaf diagrams',
$t$A stem-and-leaf diagram organises data while keeping every original value visible.

For the data

12, 14, 17, 21, 21, 24, 29

a diagram can be written as

1 | 2 4 7
2 | 1 1 4 9

with the key

1 | 2 means 12.

The stem carries the leading digit and each leaf completes one data value. Leaves should be placed in order, and repeated values must appear repeatedly — the two 21s need two leaves.

This makes the diagram useful for both shape and exact values: you can see the spread of the data while still recovering any observation from the key.$t$,
$t$A stem-and-leaf diagram keeps the original values.

For

12, 14, 17, 21, 21, 24, 29

write

1 | 2 4 7
2 | 1 1 4 9

and give the key 1|2 = 12.

Order the leaves and keep duplicates. Each leaf represents one observation.$t$,
$t$Think of the stem as the shared beginning of a number and the leaf as the final digit.

The numbers 21, 21, 24 and 29 all share stem 2, so their leaves are 1, 1, 4 and 9.

Unlike many summary graphs, a stem-and-leaf diagram lets you reconstruct the original list. That is its main strength.$t$,
$t$Always include a key so the scale is unambiguous. Put leaves in ascending order unless the question specifies otherwise. Do not remove repeated values. Check that the number of leaves equals the number of observations.$t$,
'p5:P5-DAT-02:theory:en:v1'
),
(
'p5:P5-DAT-02:tutor:ru:v2','P5','P5-DAT-02','ru','tutor_v2_learner_first','Диаграмма «стебель и листья»',
$t$Диаграмма «стебель и листья» упорядочивает данные, но при этом сохраняет каждое исходное значение.

Для данных

12, 14, 17, 21, 21, 24, 29

можно записать

1 | 2 4 7
2 | 1 1 4 9

с ключом

1 | 2 означает 12.

«Стебель» содержит начальную часть числа, а каждый «лист» завершает одно значение. Листья нужно упорядочивать, а повторяющиеся значения записывать повторно — для двух значений 21 нужны два листа 1.

Такой вид одновременно показывает форму распределения и позволяет восстановить любое исходное наблюдение.$t$,
$t$Диаграмма «стебель и листья» сохраняет исходные значения.

Для

12, 14, 17, 21, 21, 24, 29

получаем

1 | 2 4 7
2 | 1 1 4 9

и ключ 1|2 = 12.

Листья располагайте по порядку и не удаляйте повторы. Один лист — одно наблюдение.$t$,
$t$Представьте, что «стебель» — общая начальная часть числа, а «лист» — последняя цифра.

У чисел 21, 21, 24 и 29 общий стебель 2, поэтому листья: 1, 1, 4, 9.

В отличие от многих сводных графиков, по такой диаграмме можно восстановить исходный список. В этом её главное преимущество.$t$,
$t$Всегда пишите ключ, чтобы масштаб был понятен. Листья обычно располагаются по возрастанию. Повторяющиеся значения нельзя убирать. Проверьте, что количество листьев совпадает с количеством наблюдений.$t$,
'p5:P5-DAT-02:theory:ru:v1'
),
(
'p5:P5-DAT-02:tutor:uz:v2','P5','P5-DAT-02','uz','tutor_v2_learner_first','Poya-barg diagrammasi',
$t$Poya-barg diagrammasi ma’lumotlarni tartiblaydi va shu bilan birga har bir boshlang‘ich qiymatni saqlab qoladi.

Quyidagi ma’lumotlar uchun

12, 14, 17, 21, 21, 24, 29

diagramma:

1 | 2 4 7
2 | 1 1 4 9

ko‘rinishida yoziladi. Kalit:

1 | 2 — 12 ni bildiradi.

Poya sonning boshlang‘ich qismini, har bir barg esa bitta qiymatning oxirgi qismini beradi. Barglarni tartiblab yozish va takroriy qiymatlarni takroran ko‘rsatish kerak — ikkita 21 uchun ikkita 1 barg yoziladi.

Shu sabab diagrammada ham taqsimot shaklini, ham asl qiymatlarni ko‘rish mumkin.$t$,
$t$Poya-barg diagrammasi asl qiymatlarni saqlaydi.

12, 14, 17, 21, 21, 24, 29 uchun:

1 | 2 4 7
2 | 1 1 4 9

Kalit: 1|2 = 12.

Barglarni tartiblang va takroriy qiymatlarni qoldiring. Har bir barg bitta kuzatuvni bildiradi.$t$,
$t$Poyani sonning umumiy boshlanishi, bargni esa oxirgi raqam deb tasavvur qiling.

21, 21, 24 va 29 sonlarining poyasi 2, barglari esa 1, 1, 4, 9.

Ko‘p grafiklardan farqli ravishda, poya-barg diagrammasidan boshlang‘ich ma’lumotlar ro‘yxatini qayta tiklash mumkin. Uning asosiy kuchi shunda.$t$,
$t$Masshtab tushunarli bo‘lishi uchun doim kalit yozing. Barglarni odatda o‘sish tartibida joylashtiring. Takroriy qiymatlarni olib tashlamang. Barglar soni kuzatuvlar soniga tengligini tekshiring.$t$,
'p5:P5-DAT-02:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
