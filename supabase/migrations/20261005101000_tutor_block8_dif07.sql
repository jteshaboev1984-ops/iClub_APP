begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>120 then raise exception 'DIF07 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-DIF-07' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DIF07 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-DIF-07:tutor:en:v2','P1','P1-DIF-07','en','tutor_v2_learner_first','Stationary points and optimisation',
$t$A stationary point occurs where

dy/dx=0.

To classify it, check how the derivative sign changes around the point.

For

y=x³-3x,

dy/dx=3(x-1)(x+1),

so stationary points occur at x=-1 and x=1.

Their coordinates are

(-1,2) and (1,-2).

Around x=-1 the derivative changes from positive to negative, so (-1,2) is a local maximum.

Around x=1 it changes from negative to positive, so (1,-2) is a local minimum.

In optimisation problems, first express the quantity to maximise or minimise as a function of one variable, then find and classify the relevant stationary point within the allowed domain.$t$,
$t$Stationary point means dy/dx=0.

For y=x³-3x:

dy/dx=3(x-1)(x+1),

so x=-1 and x=1.

Points:
(-1,2), (1,-2).

Sign change + to - gives a local maximum at (-1,2).
Sign change - to + gives a local minimum at (1,-2).$t$,
$t$Think of the derivative as telling you whether the graph is climbing or falling.

At a stationary point the slope is zero. If the graph changes from climbing to falling, you are at a local maximum. If it changes from falling to climbing, you are at a local minimum.

This sign-change picture is also what optimisation uses: a best value appears where the direction reverses inside the allowed region.$t$,
$t$Solving dy/dx=0 finds candidates, not the final classification. Find the corresponding y-coordinates and check the derivative sign on both sides. In optimisation, also respect the allowed domain and compare boundary values when the problem requires it.$t$,
'p1:P1-DIF-07:theory:en:v1'
),
(
'p1:P1-DIF-07:tutor:ru:v2','P1','P1-DIF-07','ru','tutor_v2_learner_first','Стационарные точки и оптимизация',
$t$Стационарная точка возникает там, где

dy/dx=0.

Чтобы определить её тип, проверьте изменение знака производной по обе стороны.

Для

y=x³-3x

получаем

dy/dx=3(x-1)(x+1),

поэтому стационарные точки соответствуют x=-1 и x=1.

Их координаты:

(-1,2) и (1,-2).

Около x=-1 производная меняется с плюса на минус, поэтому (-1,2) — локальный максимум.

Около x=1 знак меняется с минуса на плюс, поэтому (1,-2) — локальный минимум.

В задачах оптимизации сначала выразите нужную величину как функцию одной переменной, затем найдите и классифицируйте подходящую стационарную точку в допустимой области.$t$,
$t$Стационарная точка: dy/dx=0.

Для y=x³-3x:

dy/dx=3(x-1)(x+1),

поэтому x=-1 и x=1.

Точки:
(-1,2), (1,-2).

Плюс → минус даёт локальный максимум (-1,2).
Минус → плюс даёт локальный минимум (1,-2).$t$,
$t$Считайте производную указателем: график поднимается или опускается.

В стационарной точке наклон равен нулю. Переход от подъёма к спуску даёт локальный максимум. Переход от спуска к подъёму — локальный минимум.

Та же картина используется в оптимизации: лучшее значение появляется там, где направление меняется внутри допустимой области.$t$,
$t$Решение dy/dx=0 даёт только кандидатов. Найдите соответствующие y и проверьте знак производной по обе стороны. В оптимизации учитывайте допустимую область и при необходимости сравнивайте значения на её границах.$t$,
'p1:P1-DIF-07:theory:ru:v1'
),
(
'p1:P1-DIF-07:tutor:uz:v2','P1','P1-DIF-07','uz','tutor_v2_learner_first','Statsionar nuqtalar va optimallashtirish',
$t$Statsionar nuqta

dy/dx=0

bo‘lgan joyda paydo bo‘ladi.

Uning turini aniqlash uchun nuqtaning ikki tomonida hosila ishorasi qanday o‘zgarishini tekshiring.

Masalan,

y=x³-3x

uchun

dy/dx=3(x-1)(x+1),

shuning uchun statsionar nuqtalar x=-1 va x=1 da.

Koordinatalar:

(-1,2) va (1,-2).

x=-1 atrofida hosila musbatdan manfiyga o‘tadi, demak (-1,2) mahalliy maksimum.

x=1 atrofida manfiydan musbatga o‘tadi, demak (1,-2) mahalliy minimum.

Optimallashtirishda avval kerakli kattalikni bitta o‘zgaruvchili funksiya sifatida yozing, keyin ruxsat etilgan sohadagi mos statsionar nuqtani topib tasniflang.$t$,
$t$Statsionar nuqta uchun dy/dx=0.

y=x³-3x da:

dy/dx=3(x-1)(x+1),

shuning uchun x=-1 va x=1.

Nuqtalar:
(-1,2), (1,-2).

Musbat → manfiy: (-1,2) mahalliy maksimum.
Manfiy → musbat: (1,-2) mahalliy minimum.$t$,
$t$Hosilani grafik yuqoriga yoki pastga ketayotganini ko‘rsatadigan signal deb o‘ylang.

Statsionar nuqtada qiyalik nol. Grafik ko‘tarilishdan pasayishga o‘tsa, mahalliy maksimum hosil bo‘ladi. Pasayishdan ko‘tarilishga o‘tsa, mahalliy minimum hosil bo‘ladi.

Optimallashtirish ham shu g‘oyaga tayanadi: eng yaxshi qiymat ruxsat etilgan sohada yo‘nalish o‘zgargan joyda paydo bo‘lishi mumkin.$t$,
$t$dy/dx=0 ni yechish faqat nomzod nuqtalarni beradi. Mos y-koordinatalarni toping va ikki tomondagi hosila ishorasini tekshiring. Optimallashtirishda ruxsat etilgan sohani ham hisobga oling va kerak bo‘lsa chegara qiymatlarini taqqoslang.$t$,
'p1:P1-DIF-07:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
