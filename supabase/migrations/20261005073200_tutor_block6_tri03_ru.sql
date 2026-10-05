begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>79 then raise exception 'TRI03 RU baseline %',v; end if;
end $pre$;

with x as (select
$t$Обратная тригонометрическая функция возвращает одно главное значение угла для заданного отношения. Поэтому калькулятор показывает один выбранный угол, а не все углы с тем же тригонометрическим значением.

Примеры:

arcsin(1/2)=π/6,
arccos(-1/2)=2π/3,
arctan(1)=π/4.

При решении уравнения главное значение — только начальная точка. Если нужно найти все решения на промежутке, остальные углы находятся по графику, симметрии и периоду.$t$::text m,
$t$Обратная тригонометрическая функция даёт одно главное значение. Например, arcsin(1/2)=π/6, arccos(-1/2)=2π/3 и arctan(1)=π/4. Ответ калькулятора не является автоматически полным набором решений уравнения.$t$::text simp,
$t$Одинаковое значение sin, cos или tan может соответствовать нескольким углам. Поэтому обратная функция выбирает один согласованный главный угол. Считайте его стандартным ответом калькулятора; поиск остальных решений на промежутке — отдельный шаг.$t$::text alt,
$t$Проверяйте режим углов на калькуляторе. Результат обратной тригонометрической функции воспринимайте как главное значение. Не считайте один ответ калькулятора всеми возможными углами уравнения.$t$::text focus)
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select 'p1:P1-TRI-03:tutor:ru:v2','P1','P1-TRI-03','ru','tutor_v2_learner_first',
'Обратные тригонометрические функции',m,simp,alt,focus,
'p1:P1-TRI-03:theory:ru:v1','draft',false,
md5(concat_ws('||','tutor_v2_learner_first','Обратные тригонометрические функции',m,simp,alt,focus,'p1:P1-TRI-03:theory:ru:v1'))
from x;

commit;
