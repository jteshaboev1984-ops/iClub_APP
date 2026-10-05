begin;
do $pre$
declare v integer;
begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>66 then raise exception 'CIR02 EN expected 66 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards where source_card_key='p1:P1-CIR-02:theory:en:v1' and approval_status='approved' and is_runtime_allowed)<>1
  then raise exception 'CIR02 EN approved source missing'; end if;
end $pre$;

insert into private.exam_prep_ai_tutor_cards(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,
  source_card_key,approval_status,is_runtime_allowed,content_hash
) values (
'p1:P1-CIR-02:tutor:en:v2','P1','P1-CIR-02','en','tutor_v2_learner_first','Arc length',
$t$When the central angle θ is measured in radians, arc length is

s = rθ,

where r is the radius.

For r=6 and θ=2π/3:

s = 6 × 2π/3 = 4π.

So the arc is 4π units long. The same formula can be rearranged: r=s/θ and θ=s/r.

The formula is simple because a radian compares arc length with radius. At θ=1 radian, the arc length is exactly one radius. This direct form works only when θ is in radians.$t$,
$t$For θ in radians, use s=rθ.

If r=6 and θ=2π/3, then s=4π.

If radius is unknown, r=s/θ. If angle is unknown, θ=s/r.

Always check that θ is in radians first.$t$,
$t$A full circle has angle 2π and circumference 2πr. Angle θ is the fraction θ/(2π) of a full turn.

Therefore

s = θ/(2π) × 2πr = rθ.

So the arc formula can be understood as a fraction of the whole circumference.$t$,
$t$Use s=rθ only with θ in radians. Keep radius and arc length in compatible length units. If solving backwards, rearrange first. Arc length is a length, so the answer uses cm, m or another length unit, not square units.$t$,
'p1:P1-CIR-02:theory:en:v1','draft',false,
md5(concat_ws('||','tutor_v2_learner_first','Arc length',
$t$When the central angle θ is measured in radians, arc length is

s = rθ,

where r is the radius.

For r=6 and θ=2π/3:

s = 6 × 2π/3 = 4π.

So the arc is 4π units long. The same formula can be rearranged: r=s/θ and θ=s/r.

The formula is simple because a radian compares arc length with radius. At θ=1 radian, the arc length is exactly one radius. This direct form works only when θ is in radians.$t$,
$t$For θ in radians, use s=rθ.

If r=6 and θ=2π/3, then s=4π.

If radius is unknown, r=s/θ. If angle is unknown, θ=s/r.

Always check that θ is in radians first.$t$,
$t$A full circle has angle 2π and circumference 2πr. Angle θ is the fraction θ/(2π) of a full turn.

Therefore

s = θ/(2π) × 2πr = rθ.

So the arc formula can be understood as a fraction of the whole circumference.$t$,
$t$Use s=rθ only with θ in radians. Keep radius and arc length in compatible length units. If solving backwards, rearrange first. Arc length is a length, so the answer uses cm, m or another length unit, not square units.$t$,
'p1:P1-CIR-02:theory:en:v1'))
);

commit;
