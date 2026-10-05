begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>126 then raise exception 'INT02 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-INT-02' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'INT02 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-INT-02:tutor:en:v2','P1','P1-INT-02','en','tutor_v2_learner_first','Constant of integration',
$t$An indefinite integral gives a family of curves, so you need a constant C. A point or boundary condition selects the one curve that fits the question.

Suppose

dy/dx = 6x - 4

and the curve passes through (2,5).

Integrating gives

y = 3x² - 4x + C.

Now use the point:

5 = 3(2²) - 4(2) + C
= 12 - 8 + C.

So C=1, and the curve is

y = 3x² - 4x + 1.

The derivative alone determines the shape; the condition determines the vertical position.$t$,
$t$Integrate first, but keep C.

dy/dx=6x-4

gives

y=3x²-4x+C.

Using the point (2,5):

5=12-8+C,

so C=1.

Therefore

y=3x²-4x+1.$t$,
$t$Think of C as the vertical shift that differentiation cannot detect.

All curves

y=3x²-4x+C

have the same derivative 6x-4. The given point tells you which vertical shift is correct.

So the boundary condition does not change the derivative rule; it chooses one member of the antiderivative family.$t$,
$t$Do not drop C before using the given point or boundary condition. Substitute both x and y carefully. Once C is found, write the complete curve equation, not just the value of C.$t$,
'p1:P1-INT-02:theory:en:v1'
),
(
'p1:P1-INT-02:tutor:ru:v2','P1','P1-INT-02','ru','tutor_v2_learner_first','Постоянная интегрирования',
$t$Неопределённый интеграл задаёт семейство кривых, поэтому нужна постоянная C. Точка или граничное условие выбирает одну конкретную кривую.

Пусть

dy/dx = 6x - 4,

а кривая проходит через (2,5).

После интегрирования:

y = 3x² - 4x + C.

Используем точку:

5 = 3(2²) - 4(2) + C
= 12 - 8 + C.

Значит, C=1, и уравнение кривой:

y = 3x² - 4x + 1.

Производная определяет форму, а дополнительное условие — вертикальное положение.$t$,
$t$Сначала проинтегрируйте и сохраните C.

dy/dx=6x-4

даёт

y=3x²-4x+C.

Используем точку (2,5):

5=12-8+C,

поэтому C=1.

Итак,

y=3x²-4x+1.$t$,
$t$Считайте C вертикальным сдвигом, который производная не замечает.

Все кривые

y=3x²-4x+C

имеют одну и ту же производную 6x-4. Заданная точка показывает, какой именно вертикальный сдвиг нужен.

Граничное условие не меняет правило интегрирования — оно выбирает одну кривую из семейства.$t$,
$t$Не убирайте C до использования точки или граничного условия. Внимательно подставьте и x, и y. После нахождения C запишите полное уравнение кривой, а не только значение постоянной.$t$,
'p1:P1-INT-02:theory:ru:v1'
),
(
'p1:P1-INT-02:tutor:uz:v2','P1','P1-INT-02','uz','tutor_v2_learner_first','Integrallash doimiysi',
$t$Aniqlanmagan integral funksiyalar oilasini beradi, shuning uchun C doimiysi kerak. Berilgan nuqta yoki chegara sharti shu oiladan bitta aniq funksiyani tanlaydi.

Masalan,

dy/dx = 6x - 4

va egri chiziq (2,5) nuqtadan o‘tsin.

Integrallashdan so‘ng:

y = 3x² - 4x + C.

Nuqtani qo‘yamiz:

5 = 3(2²) - 4(2) + C
= 12 - 8 + C.

Demak, C=1 va egri chiziq

y = 3x² - 4x + 1.

Hosila shaklni belgilaydi, qo‘shimcha shart esa vertikal joylashuvni tanlaydi.$t$,
$t$Avval integrallang va C ni saqlang.

dy/dx=6x-4

dan

y=3x²-4x+C.

(2,5) nuqtani qo‘ysak:

5=12-8+C,

demak C=1.

Shuning uchun

y=3x²-4x+1.$t$,
$t$C ni differensiallash sezmaydigan vertikal siljish deb tasavvur qiling.

Barcha

y=3x²-4x+C

funksiyalarining hosilasi bir xil: 6x-4. Berilgan nuqta qaysi vertikal siljish to‘g‘ri ekanini ko‘rsatadi.

Chegara sharti integrallash qoidasini o‘zgartirmaydi; u funksiyalar oilasidan bittasini tanlaydi.$t$,
$t$Nuqta yoki chegara shartidan foydalanishdan oldin C ni tushirib qoldirmang. x va y ni ehtiyotkor qo‘ying. C topilgach, faqat C ni emas, to‘liq funksiya tenglamasini yozing.$t$,
'p1:P1-INT-02:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
