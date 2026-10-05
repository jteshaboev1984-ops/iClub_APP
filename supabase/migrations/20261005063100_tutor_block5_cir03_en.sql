begin;
do $pre$
declare v integer;
begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>69 then raise exception 'CIR03 EN expected 69 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards where source_card_key='p1:P1-CIR-03:theory:en:v1' and approval_status='approved' and is_runtime_allowed)<>1
  then raise exception 'CIR03 EN approved source missing'; end if;
end $pre$;

with x as (select
'p1:P1-CIR-03:tutor:en:v2'::text k,'P1'::text c,'P1-CIR-03'::text s,'en'::text l,
'tutor_v2_learner_first'::text v,'Sector area and circular segments'::text title,
$t$When the central angle θ is in radians, sector area is

A = 1/2 r²θ.

For r=8 and θ=π/3:

sector area = 1/2 × 8² × π/3 = 32π/3.

For the smaller circular segment, subtract the triangle formed by the two radii. Its area is

1/2 r² sinθ = 16√3.

So the segment area is

32π/3 - 16√3.

Composite circular problems use the same idea: identify familiar pieces, then add or subtract sector, triangle and other simple areas according to the diagram.$t$::text m,
$t$For θ in radians, A=1/2 r²θ.

With r=8 and θ=π/3, the sector area is 32π/3.

The triangle between the radii has area 16√3, so the smaller segment area is

32π/3 - 16√3.$t$::text simp,
$t$A sector is a fraction of a full circle. Since a full circle has angle 2π and area πr²,

θ/(2π) × πr² = 1/2 r²θ.

A circular segment is the curved part left after removing the triangle between the two radii. This “sector minus triangle” picture makes many shaded-region problems easier to read.$t$::text alt,
$t$Use 1/2 r²θ only when θ is in radians. Do not confuse sector area with arc length rθ. For a segment, subtract the correct triangle; for a composite region, mark the pieces before adding or subtracting. Area answers use square units.$t$::text focus,
'p1:P1-CIR-03:theory:en:v1'::text src)
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from x;

commit;
