begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>71 then raise exception 'CIR03 RU baseline %',v; end if;
end $pre$;

with x as (select
$t$Если θ измерен в радианах, площадь сектора равна

A = 1/2 r²θ.

При r=8 и θ=π/3 получаем 32π/3. Чтобы найти площадь области между дугой и хордой, из сектора вычитаем треугольник между радиусами. Его площадь равна 16√3.

Значит, искомая площадь:

32π/3 - 16√3.

В составной фигуре сначала выделите знакомые части, затем сложите или вычтите их площади по рисунку.$t$::text m,
$t$Для θ в радианах используйте A=1/2 r²θ. При r=8 и θ=π/3 площадь сектора 32π/3. Треугольник между радиусами имеет площадь 16√3, поэтому искомая область имеет площадь 32π/3 - 16√3.$t$::text simp,
$t$Сектор — доля полного круга: θ/(2π) × πr² = 1/2 r²θ. Область между дугой и хордой удобно видеть как «сектор минус треугольник». Так проще понимать составные заштрихованные области.$t$::text alt,
$t$Проверьте, что θ в радианах. Не путайте площадь сектора 1/2 r²θ с длиной дуги rθ. Вычитайте правильный треугольник и используйте квадратные единицы для площади.$t$::text focus)
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select 'p1:P1-CIR-03:tutor:ru:v2','P1','P1-CIR-03','ru','tutor_v2_learner_first',
'Площадь сектора и области между дугой и хордой',m,simp,alt,focus,
'p1:P1-CIR-03:theory:ru:v1','draft',false,
md5(concat_ws('||','tutor_v2_learner_first','Площадь сектора и области между дугой и хордой',m,simp,alt,focus,'p1:P1-CIR-03:theory:ru:v1'))
from x;

commit;
