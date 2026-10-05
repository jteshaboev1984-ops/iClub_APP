begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>132 then raise exception 'INT04 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-INT-04' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'INT04 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-INT-04:tutor:en:v2','P1','P1-INT-04','en','tutor_v2_learner_first','Area between curves',
$t$Geometric area must be positive. Between two curves, integrate

upper curve - lower curve

over the interval where that ordering is correct.

For y=x and y=x² on 0≤x≤1, we have x>x² inside the interval. Therefore

Area
= ∫ from 0 to 1 of (x-x²) dx
= [x²/2 - x³/3] from 0 to 1
= 1/2 - 1/3
= 1/6.

If the curves cross inside a wider interval, the upper/lower order can change. Split the region at intersection points and add the positive areas.$t$,
$t$For area between two curves, use

upper - lower.

Between y=x and y=x² on 0≤x≤1:

Area
= ∫ from 0 to 1 of (x-x²) dx
= 1/6.

If the curves swap order, split the integral where they intersect.$t$,
$t$Think of the vertical gap between the curves.

At each x, the gap is

top y-value - bottom y-value.

Integration adds all those thin vertical strips across the interval. If the two curves cross, the identity of “top” and “bottom” changes, so the region must be split there.$t$,
$t$Find intersections before integrating. Use top minus bottom, or right minus left only when integrating with respect to y. Geometric area must be positive, so split at crossings or sign changes instead of allowing cancellation.$t$,
'p1:P1-INT-04:theory:en:v1'
),
(
'p1:P1-INT-04:tutor:ru:v2','P1','P1-INT-04','ru','tutor_v2_learner_first','Площадь между кривыми',
$t$Геометрическая площадь должна быть положительной. Между двумя кривыми интегрируйте

верхняя функция - нижняя функция

на том промежутке, где этот порядок верен.

Для y=x и y=x² при 0≤x≤1 внутри промежутка x>x². Поэтому

Площадь
= ∫ от 0 до 1 (x-x²) dx
= [x²/2 - x³/3] от 0 до 1
= 1/2 - 1/3
= 1/6.

Если на более широком промежутке кривые пересекаются, верхняя и нижняя функции могут поменяться местами. Разбейте область в точках пересечения и сложите положительные площади.$t$,
$t$Для площади между двумя кривыми используйте

верхняя - нижняя.

Между y=x и y=x² при 0≤x≤1:

Площадь
= ∫ от 0 до 1 (x-x²) dx
= 1/6.

Если кривые меняются местами, разбейте интеграл в точке пересечения.$t$,
$t$Представьте вертикальный промежуток между двумя графиками.

Для каждого x его высота равна

верхнее значение y - нижнее значение y.

Интеграл складывает такие тонкие вертикальные полосы по всему промежутку. Если графики пересекаются, роли «верхнего» и «нижнего» меняются, поэтому область нужно разбить.$t$,
$t$Перед интегрированием найдите точки пересечения. Используйте «верхняя минус нижняя» при интегрировании по x. Геометрическая площадь всегда положительна, поэтому при пересечениях или смене знака разбивайте область вместо взаимного уничтожения частей.$t$,
'p1:P1-INT-04:theory:ru:v1'
),
(
'p1:P1-INT-04:tutor:uz:v2','P1','P1-INT-04','uz','tutor_v2_learner_first','Egri chiziqlar orasidagi yuza',
$t$Geometrik yuza musbat bo‘lishi kerak. Ikki egri chiziq orasida

yuqoridagi funksiya - pastdagi funksiya

ni shu tartib to‘g‘ri bo‘lgan oraliqda integrallang.

y=x va y=x² uchun 0≤x≤1 da x>x². Shuning uchun

Yuza
= ∫ 0 dan 1 gacha (x-x²) dx
= [x²/2 - x³/3] 0 dan 1 gacha
= 1/2 - 1/3
= 1/6.

Kengroq oraliqda grafiklar kesishsa, yuqori va pastki funksiya o‘rin almashishi mumkin. Kesishish nuqtasida sohani bo‘lib, musbat yuzalarni qo‘shing.$t$,
$t$Ikki egri chiziq orasidagi yuza uchun

yuqori - pastki

ifodani integrallang.

y=x va y=x² uchun 0≤x≤1 da:

Yuza
= ∫ 0 dan 1 gacha (x-x²) dx
= 1/6.

Grafiklar o‘rin almashsa, integralni kesishish nuqtasida bo‘ling.$t$,
$t$Ikki grafik orasidagi vertikal masofani tasavvur qiling.

Har bir x da masofa

yuqoridagi y - pastdagi y.

Integral shu yupqa vertikal bo‘laklarning barchasini qo‘shadi. Grafiklar kesishsa, “yuqori” va “pastki” rollari o‘zgaradi, shuning uchun sohani o‘sha nuqtada bo‘lish kerak.$t$,
$t$Integrallashdan oldin kesishish nuqtalarini toping. x bo‘yicha integrallaganda “yuqori minus pastki” ishlating. Geometrik yuza musbat bo‘ladi, shuning uchun kesishish yoki ishora almashish joylarida sohani bo‘ling.$t$,
'p1:P1-INT-04:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
