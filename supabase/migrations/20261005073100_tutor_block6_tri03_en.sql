begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>78 then raise exception 'TRI03 EN baseline %',v; end if;
end $pre$;

with x as (select
$t$An inverse trigonometric function returns one principal angle for a given ratio. A calculator therefore gives one selected angle, not every angle with the same trigonometric value.

The principal ranges are: arcsin from -π/2 to π/2, arccos from 0 to π, and arctan from -π/2 to π/2.

Examples:

arcsin(1/2)=π/6,
arccos(-1/2)=2π/3,
arctan(1)=π/4.

For equation solving, the principal value is only the starting point. If the question asks for every solution in an interval, use the graph, symmetry and period to find the remaining angles.$t$::text m,
$t$Inverse trig gives one principal angle. For example, arcsin(1/2)=π/6, arccos(-1/2)=2π/3 and arctan(1)=π/4. The calculator output is not automatically the full solution set of a trig equation.$t$::text simp,
$t$Many angles can share the same sine, cosine or tangent. The inverse function therefore chooses one agreed principal angle. Think of it as the standard calculator answer; finding other interval solutions is a separate step.$t$::text alt,
$t$Check calculator angle mode. Treat the inverse-trig result as a principal value. Do not assume one calculator answer is every possible angle in an equation.$t$::text focus)
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select 'p1:P1-TRI-03:tutor:en:v2','P1','P1-TRI-03','en','tutor_v2_learner_first',
'Inverse trigonometric functions',m,simp,alt,focus,
'p1:P1-TRI-03:theory:en:v1','draft',false,
md5(concat_ws('||','tutor_v2_learner_first','Inverse trigonometric functions',m,simp,alt,focus,'p1:P1-TRI-03:theory:en:v1'))
from x;

commit;
