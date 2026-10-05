begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>111 then raise exception 'DIF04 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-DIF-04' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DIF04 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-DIF-04:tutor:en:v2','P1','P1-DIF-04','en','tutor_v2_learner_first','Tangent and normal',
$t$At a point on a curve, the derivative gives the gradient of the tangent. The normal is perpendicular to the tangent, so its gradient is the negative reciprocal when that gradient is defined.

For

y=x²

at x=2, the point is (2,4).

dy/dx=2x, so the tangent gradient is 4.

Tangent:

y-4=4(x-2).

The normal gradient is -1/4, so

y-4=-(1/4)(x-2).

The safest route is: find the point, find the derivative gradient there, then use point-gradient form for the required line.$t$,
$t$For y=x² at x=2:

point = (2,4),

dy/dx=2x,

tangent gradient =4.

So the tangent is

y-4=4(x-2).

Normal gradient =-1/4, so

y-4=-(1/4)(x-2).$t$,
$t$The derivative gives the direction in which the curve is travelling at one point. The tangent follows that direction.

The normal turns through 90°, so for non-zero finite gradients m_tangent and m_normal satisfy

m_tangent × m_normal = -1.

That geometric relationship is why the normal gradient is the negative reciprocal.$t$,
$t$Find the actual point as well as the gradient. Use the derivative value at the specified x, not the whole derivative expression as the line gradient. For a normal, take the negative reciprocal of the tangent gradient and then use the same point.$t$,
'p1:P1-DIF-04:theory:en:v1'
),
(
'p1:P1-DIF-04:tutor:ru:v2','P1','P1-DIF-04','ru','tutor_v2_learner_first','Касательная и нормаль',
$t$В точке кривой производная задаёт угловой коэффициент касательной. Нормаль перпендикулярна касательной, поэтому её коэффициент равен отрицательной обратной величине, когда такой коэффициент определён.

Для

y=x²

при x=2 точка равна (2,4).

dy/dx=2x, поэтому коэффициент касательной равен 4.

Касательная:

y-4=4(x-2).

Коэффициент нормали равен -1/4, поэтому

y-4=-(1/4)(x-2).

Надёжный порядок: найдите точку, вычислите производную в этой точке и затем используйте уравнение прямой через точку с известным коэффициентом.$t$,
$t$Для y=x² при x=2:

точка = (2,4),

dy/dx=2x,

коэффициент касательной =4.

Касательная:

y-4=4(x-2).

Коэффициент нормали =-1/4, поэтому

y-4=-(1/4)(x-2).$t$,
$t$Производная показывает направление кривой в конкретной точке. Касательная идёт именно в этом направлении.

Нормаль повёрнута на 90°, поэтому для конечных ненулевых коэффициентов выполняется

m_касательной × m_нормали = -1.

Отсюда коэффициент нормали является отрицательной обратной величиной.$t$,
$t$Найдите не только градиент, но и саму точку. В уравнение касательной подставляйте значение производной при заданном x, а не всю формулу производной. Для нормали возьмите отрицательную обратную величину и используйте ту же точку.$t$,
'p1:P1-DIF-04:theory:ru:v1'
),
(
'p1:P1-DIF-04:tutor:uz:v2','P1','P1-DIF-04','uz','tutor_v2_learner_first','Urinma va normal',
$t$Egri chiziqning bir nuqtasida hosila urinma gradientini beradi. Normal urinmaga perpendikulyar, shuning uchun gradient mavjud bo‘lgan holatda uning qiymati manfiy teskari bo‘ladi.

Masalan,

y=x²

va x=2 bo‘lsa, nuqta (2,4).

dy/dx=2x, demak urinma gradienti 4.

Urinma:

y-4=4(x-2).

Normal gradienti -1/4, shuning uchun

y-4=-(1/4)(x-2).

Ishonchli tartib: nuqtani toping, shu nuqtadagi hosila gradientini hisoblang va kerakli chiziq uchun nuqta-gradient tenglamasidan foydalaning.$t$,
$t$y=x² va x=2 uchun:

nuqta = (2,4),

dy/dx=2x,

urinma gradienti =4.

Urinma:

y-4=4(x-2).

Normal gradienti =-1/4, shuning uchun

y-4=-(1/4)(x-2).$t$,
$t$Hosila egri chiziq ayni nuqtada qaysi yo‘nalishda ketayotganini ko‘rsatadi. Urinma shu yo‘nalishga ega.

Normal 90° ga burilgan bo‘ladi, shuning uchun nol bo‘lmagan chekli gradientlarda

m_urinma × m_normal = -1.

Shu sabab normal gradienti manfiy teskari qiymatdir.$t$,
$t$Gradient bilan birga nuqtaning o‘zini ham toping. Chiziq gradienti sifatida butun hosila formulasini emas, berilgan x dagi hosila qiymatini ishlating. Normal uchun urinma gradientining manfiy teskari qiymatini olib, o‘sha nuqtadan foydalaning.$t$,
'p1:P1-DIF-04:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
