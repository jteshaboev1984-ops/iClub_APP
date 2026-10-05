begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>117 then raise exception 'DIF06 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-DIF-06' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DIF06 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-DIF-06:tutor:en:v2','P1','P1-DIF-06','en','tutor_v2_learner_first','Rates of change',
$t$Connected-rate problems link two changing quantities through a shared variable.

Suppose the area of a circle is

A=πr²

and the radius is increasing at

dr/dt=2 cm/s.

Differentiate A with respect to r:

dA/dr=2πr.

Then connect the rates:

dA/dt
= dA/dr × dr/dt
= 2πr × 2.

At r=5 cm,

dA/dt=20π cm²/s.

The sign matters: a decreasing quantity should have a negative rate. The units also change with the quantity, so an area rate uses square units per unit time.$t$,
$t$Use a shared variable to connect rates.

A=πr²,
dr/dt=2 cm/s.

Then

dA/dr=2πr,

so

dA/dt=(dA/dr)(dr/dt).

At r=5:

dA/dt=20π cm²/s.$t$,
$t$Think of the changing quantities as links in a chain.

Time changes r, and r changes A:

t → r → A.

The total rate from time to area is found by multiplying the rate from t to r by the rate from r to A.

That is why dA/dt=(dA/dr)(dr/dt).$t$,
$t$Write the relationship between the variables before differentiating. Keep track of which variable each derivative is with respect to. Use negative signs for decreasing quantities and carry the correct units through to the final rate.$t$,
'p1:P1-DIF-06:theory:en:v1'
),
(
'p1:P1-DIF-06:tutor:ru:v2','P1','P1-DIF-06','ru','tutor_v2_learner_first','Скорости изменения',
$t$В задачах на связанные скорости две изменяющиеся величины соединяются через общую переменную.

Пусть площадь круга

A=πr²,

а радиус увеличивается со скоростью

dr/dt=2 cm/s.

Сначала дифференцируем A по r:

dA/dr=2πr.

Затем связываем скорости:

dA/dt
= dA/dr × dr/dt
= 2πr × 2.

При r=5 cm:

dA/dt=20π cm²/s.

Знак важен: для уменьшающейся величины скорость должна быть отрицательной. Единицы тоже должны соответствовать величине, поэтому скорость изменения площади записывается в квадратных единицах за единицу времени.$t$,
$t$Свяжите скорости через общую переменную.

A=πr²,
dr/dt=2 cm/s.

Тогда

dA/dr=2πr,

и

dA/dt=(dA/dr)(dr/dt).

При r=5:

dA/dt=20π cm²/s.$t$,
$t$Представьте изменяющиеся величины как цепочку.

Время меняет r, а r меняет A:

t → r → A.

Общая скорость от времени к площади получается умножением скорости изменения r по времени на скорость изменения A по r.

Поэтому dA/dt=(dA/dr)(dr/dt).$t$,
$t$Сначала запишите связь между переменными, затем дифференцируйте. Следите, по какой переменной взята каждая производная. Для убывающей величины используйте отрицательный знак и обязательно сохраните правильные единицы в финальном ответе.$t$,
'p1:P1-DIF-06:theory:ru:v1'
),
(
'p1:P1-DIF-06:tutor:uz:v2','P1','P1-DIF-06','uz','tutor_v2_learner_first','O‘zgarish tezligi',
$t$Bog‘langan tezlik masalalarida ikki o‘zgaruvchi umumiy o‘zgaruvchi orqali bog‘lanadi.

Masalan, doira yuzi

A=πr²,

radius esa

dr/dt=2 cm/s

tezlik bilan oshsin.

Avval A ni r bo‘yicha differensiallaymiz:

dA/dr=2πr.

Keyin tezliklarni bog‘laymiz:

dA/dt
= dA/dr × dr/dt
= 2πr × 2.

r=5 cm bo‘lganda:

dA/dt=20π cm²/s.

Ishora muhim: kamayuvchi kattalik tezligi manfiy bo‘lishi kerak. Birliklar ham kattalikka mos bo‘ladi, shuning uchun yuza tezligi vaqt birligiga kvadrat birliklarda yoziladi.$t$,
$t$Tezliklarni umumiy o‘zgaruvchi orqali bog‘lang.

A=πr²,
dr/dt=2 cm/s.

Shunda

dA/dr=2πr,

va

dA/dt=(dA/dr)(dr/dt).

r=5 da:

dA/dt=20π cm²/s.$t$,
$t$O‘zgarayotgan kattaliklarni zanjir sifatida tasavvur qiling.

Vaqt r ni, r esa A ni o‘zgartiradi:

t → r → A.

Vaqtdan yuzagacha bo‘lgan umumiy tezlik t dan r gacha va r dan A gacha tezliklarni ko‘paytirish orqali topiladi.

Shuning uchun dA/dt=(dA/dr)(dr/dt).$t$,
$t$Differensiallashdan oldin o‘zgaruvchilar orasidagi bog‘lanishni yozing. Har bir hosila qaysi o‘zgaruvchi bo‘yicha olinganini tekshiring. Kamayuvchi kattalik uchun manfiy ishora ishlating va yakuniy tezlik birliklarini to‘g‘ri saqlang.$t$,
'p1:P1-DIF-06:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
