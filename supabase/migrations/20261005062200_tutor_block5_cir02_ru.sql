begin;
do $pre$
declare v integer;
begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>67 then raise exception 'CIR02 RU expected 67 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards where source_card_key='p1:P1-CIR-02:theory:ru:v1' and approval_status='approved' and is_runtime_allowed)<>1
  then raise exception 'CIR02 RU approved source missing'; end if;
end $pre$;

with x as (select
'p1:P1-CIR-02:tutor:ru:v2'::text k,'P1'::text c,'P1-CIR-02'::text s,'ru'::text l,
'tutor_v2_learner_first'::text v,'Длина дуги'::text title,
$t$Если центральный угол θ измерен в радианах, длина дуги равна

s = rθ,

где r — радиус.

При r=6 и θ=2π/3:

s = 6 × 2π/3 = 4π.

Значит, длина дуги равна 4π единиц. Эту же формулу можно перестроить: r=s/θ и θ=s/r.

Формула так проста потому, что радиан связывает угол с отношением длины дуги к радиусу. При θ=1 радиан длина дуги равна одному радиусу. Прямой вид s=rθ работает только для θ в радианах.$t$::text m,
$t$Для θ в радианах используйте s=rθ.

Если r=6 и θ=2π/3, то s=4π.

Если неизвестен радиус, r=s/θ. Если неизвестен угол, θ=s/r.

Сначала убедитесь, что θ задан в радианах.$t$::text simp,
$t$Полная окружность имеет угол 2π и длину 2πr. Угол θ составляет долю θ/(2π) от полного оборота.

Поэтому

s = θ/(2π) × 2πr = rθ.

Так формула длины дуги получается как доля всей длины окружности.$t$::text alt,
$t$Используйте s=rθ только для θ в радианах. Радиус и длина дуги должны быть в совместимых единицах длины. В обратной задаче сначала выразите неизвестную. Длина дуги измеряется в cm, m и других единицах длины, а не в квадратных единицах.$t$::text focus,
'p1:P1-CIR-02:theory:ru:v1'::text src)
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from x;

commit;
