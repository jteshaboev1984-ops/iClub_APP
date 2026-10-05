begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>135 then raise exception 'INT05 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-INT-05' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'INT05 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-INT-05:tutor:en:v2','P1','P1-INT-05','en','tutor_v2_learner_first','Volume of revolution',
$t$When a region is rotated around a coordinate axis, its volume can be built from thin circular discs. About the x-axis,

V = π∫ y² dx,

with the correct x-limits.

For example, rotate

y=x,   0≤x≤2

about the x-axis. The radius of each disc is y=x, so

V
= π∫ from 0 to 2 of x² dx
= π[x³/3] from 0 to 2
= 8π/3.

The key step is choosing the radius measured from the stated axis. Then square that radius before integrating.$t$,
$t$For rotation about the x-axis:

V=π∫y² dx.

If y=x for 0≤x≤2:

V
=π∫ from 0 to 2 x² dx
=8π/3.

Use the distance from the axis as the radius, then square it.$t$,
$t$Imagine slicing the solid into very thin discs perpendicular to the x-axis.

Each disc has area

π(radius)².

When the graph y=x rotates about the x-axis, the radius is x. Integration adds the volumes of all those thin discs from x=0 to x=2.$t$,
$t$Identify the axis first. The radius is the distance from that axis to the curve, not automatically just y or x. Square the radius, include π and use the geometric limits of the rotated region.$t$,
'p1:P1-INT-05:theory:en:v1'
),
(
'p1:P1-INT-05:tutor:ru:v2','P1','P1-INT-05','ru','tutor_v2_learner_first','Объём тела вращения',
$t$При вращении области вокруг координатной оси объём можно представить как сумму тонких круглых дисков. При вращении вокруг оси x:

V = π∫ y² dx

с правильными пределами по x.

Например, вращаем

y=x,   0≤x≤2

вокруг оси x. Радиус каждого диска равен y=x, поэтому

V
= π∫ от 0 до 2 x² dx
= π[x³/3] от 0 до 2
= 8π/3.

Главный шаг — правильно определить радиус как расстояние от указанной оси. Затем этот радиус нужно возвести в квадрат перед интегрированием.$t$,
$t$При вращении вокруг оси x:

V=π∫y² dx.

Если y=x при 0≤x≤2:

V
=π∫ от 0 до 2 x² dx
=8π/3.

Используйте расстояние от оси как радиус и возведите его в квадрат.$t$,
$t$Представьте тело как набор очень тонких дисков, перпендикулярных оси x.

Площадь каждого диска:

π(радиус)².

Когда y=x вращается вокруг оси x, радиус равен x. Интеграл складывает объёмы всех дисков от x=0 до x=2.$t$,
$t$Сначала определите ось вращения. Радиус — это расстояние от этой оси до кривой, а не автоматически y или x. Возведите радиус в квадрат, не забудьте π и используйте геометрически правильные пределы.$t$,
'p1:P1-INT-05:theory:ru:v1'
),
(
'p1:P1-INT-05:tutor:uz:v2','P1','P1-INT-05','uz','tutor_v2_learner_first','Aylanish jismi hajmi',
$t$Soha koordinata o‘qi atrofida aylantirilganda hajmni yupqa doira disklar yig‘indisi sifatida ko‘rish mumkin. x o‘qi atrofida aylantirishda

V = π∫ y² dx,

to‘g‘ri x chegaralari bilan ishlatiladi.

Masalan,

y=x,   0≤x≤2

grafigini x o‘qi atrofida aylantiraylik. Har bir disk radiusi y=x, shuning uchun

V
= π∫ 0 dan 2 gacha x² dx
= π[x³/3] 0 dan 2 gacha
= 8π/3.

Asosiy qadam — radiusni berilgan o‘qdan egri chiziqqacha bo‘lgan masofa sifatida to‘g‘ri aniqlash. Keyin radiusni kvadratga oshirib integrallang.$t$,
$t$x o‘qi atrofida aylantirish uchun:

V=π∫y² dx.

y=x va 0≤x≤2 bo‘lsa:

V
=π∫ 0 dan 2 gacha x² dx
=8π/3.

O‘qdan bo‘lgan masofani radius sifatida oling va uni kvadratga oshiring.$t$,
$t$Jismni x o‘qiga perpendikulyar juda yupqa disklar to‘plami deb tasavvur qiling.

Har bir disk yuzi:

π(radius)².

y=x grafigi x o‘qi atrofida aylanganda radius x ga teng. Integral x=0 dan x=2 gacha barcha yupqa disk hajmlarini qo‘shadi.$t$,
$t$Avval aylanish o‘qini aniqlang. Radius — shu o‘qdan egri chiziqqacha masofa; u avtomatik ravishda har doim y yoki x bo‘lavermaydi. Radiusni kvadratga oshiring, π ni qo‘shing va aylantirilayotgan sohaning to‘g‘ri chegaralarini ishlating.$t$,
'p1:P1-INT-05:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
