begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>108 then raise exception 'DIF03 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-DIF-03' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DIF03 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-DIF-03:tutor:en:v2','P1','P1-DIF-03','en','tutor_v2_learner_first','Chain rule',
$t$The chain rule is needed when one differentiable expression sits inside another. For Paper 1, a common form is

(ax+b)^n.

Differentiate the outside power first, then multiply by the derivative of the inside linear expression.

For example,

y=(3x-1)⁴.

Differentiate the fourth power:

4(3x-1)³,

then multiply by the derivative of 3x-1, which is 3:

dy/dx
=4(3x-1)³×3
=12(3x-1)³.

That final factor from the inside is the part most easily missed.$t$,
$t$For y=(ax+b)^n:

differentiate the outside power, then multiply by the derivative of ax+b.

Example:

y=(3x-1)⁴

dy/dx
=4(3x-1)³×3
=12(3x-1)³.$t$,
$t$Think of the function as two machines.

Inner machine:
x → 3x-1.

Outer machine:
u → u⁴.

The derivative records the change from both machines, so you multiply the outer derivative by the inner derivative:

4u³ × 3.

Then replace u by 3x-1.$t$,
$t$Keep the inner expression intact while reducing the outer power. Then multiply by the derivative of the inside. For (ax+b)^n, that extra factor is a. Do not expand first unless it genuinely makes the work simpler.$t$,
'p1:P1-DIF-03:theory:en:v1'
),
(
'p1:P1-DIF-03:tutor:ru:v2','P1','P1-DIF-03','ru','tutor_v2_learner_first','Цепное правило',
$t$Цепное правило используется, когда одно дифференцируемое выражение находится внутри другого. В Paper 1 часто встречается форма

(ax+b)^n.

Сначала дифференцируйте внешнюю степень, затем умножьте на производную внутреннего линейного выражения.

Например,

y=(3x-1)⁴.

Производная внешней четвёртой степени:

4(3x-1)³.

Производная внутреннего выражения 3x-1 равна 3, поэтому

dy/dx
=4(3x-1)³×3
=12(3x-1)³.

Именно дополнительный множитель от внутренней функции чаще всего забывают.$t$,
$t$Для y=(ax+b)^n:

дифференцируйте внешнюю степень, затем умножьте на производную ax+b.

Например,

y=(3x-1)⁴

dy/dx
=4(3x-1)³×3
=12(3x-1)³.$t$,
$t$Представьте функцию как две машины.

Внутренняя:
x → 3x-1.

Внешняя:
u → u⁴.

Общий темп изменения зависит от обеих машин, поэтому производные перемножаются:

4u³ × 3.

Затем верните u=3x-1.$t$,
$t$При уменьшении внешней степени сохраняйте внутреннее выражение целиком. Затем обязательно умножьте на его производную. Для (ax+b)^n дополнительный множитель равен a. Не раскрывайте скобки заранее, если это не упрощает решение.$t$,
'p1:P1-DIF-03:theory:ru:v1'
),
(
'p1:P1-DIF-03:tutor:uz:v2','P1','P1-DIF-03','uz','tutor_v2_learner_first','Zanjir qoidasi',
$t$Bir differensiallanuvchi ifoda boshqasining ichida turganda zanjir qoidasi kerak bo‘ladi. Paper 1 da ko‘p uchraydigan ko‘rinish:

(ax+b)^n.

Avval tashqi darajani differensiallang, keyin ichki chiziqli ifodaning hosilasiga ko‘paytiring.

Masalan,

y=(3x-1)⁴.

Tashqi to‘rtinchi daraja hosilasi:

4(3x-1)³.

Ichki 3x-1 ifodaning hosilasi 3, shuning uchun

dy/dx
=4(3x-1)³×3
=12(3x-1)³.

Eng ko‘p unutiladigan qism — ichki funksiyadan keladigan shu qo‘shimcha ko‘paytuvchi.$t$,
$t$y=(ax+b)^n uchun:

avval tashqi darajani differensiallang, keyin ax+b hosilasiga ko‘paytiring.

Masalan,

y=(3x-1)⁴

dy/dx
=4(3x-1)³×3
=12(3x-1)³.$t$,
$t$Funksiyani ikkita ketma-ket mashina deb tasavvur qiling.

Ichki mashina:
x → 3x-1.

Tashqi mashina:
u → u⁴.

Umumiy o‘zgarish ikkala mashinaga bog‘liq, shuning uchun hosilalar ko‘paytiriladi:

4u³ × 3.

So‘ng u o‘rniga 3x-1 ni qaytaring.$t$,
$t$Tashqi darajani kamaytirayotganda ichki ifodani o‘zgartirmang. Keyin uning hosilasiga albatta ko‘paytiring. (ax+b)^n uchun bu qo‘shimcha ko‘paytuvchi a ga teng. Qavslarni faqat ishni haqiqatan soddalashtirsa oching.$t$,
'p1:P1-DIF-03:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
