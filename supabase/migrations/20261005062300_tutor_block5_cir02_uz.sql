begin;
do $pre$
declare v integer;
begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>68 then raise exception 'CIR02 UZ expected 68 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards where source_card_key='p1:P1-CIR-02:theory:uz:v1' and approval_status='approved' and is_runtime_allowed)<>1
  then raise exception 'CIR02 UZ approved source missing'; end if;
end $pre$;

with x as (select
'p1:P1-CIR-02:tutor:uz:v2'::text k,'P1'::text c,'P1-CIR-02'::text s,'uz'::text l,
'tutor_v2_learner_first'::text v,'Yoy uzunligi'::text title,
$t$Markaziy burchak θ radianlarda bo‘lsa, yoy uzunligi

s = rθ

formula bilan topiladi, bu yerda r — radius.

r=6 va θ=2π/3 bo‘lsa:

s = 6 × 2π/3 = 4π.

Demak, yoy uzunligi 4π birlik. Shu formulani qayta yozib r=s/θ va θ=s/r ni ham olish mumkin.

Formula sodda bo‘lishining sababi radian burchakni yoy uzunligining radiusga nisbatiga bog‘laydi. θ=1 radian bo‘lsa, yoy uzunligi aynan bir radiusga teng. s=rθ ko‘rinishi θ radianlarda bo‘lgandagina ishlaydi.$t$::text m,
$t$θ radianlarda bo‘lsa, s=rθ dan foydalaning.

r=6 va θ=2π/3 uchun s=4π.

Radius noma’lum bo‘lsa r=s/θ, burchak noma’lum bo‘lsa θ=s/r.

Avval θ radianlarda ekanini tekshiring.$t$::text simp,
$t$To‘liq aylana burchagi 2π, uzunligi esa 2πr. θ burchak to‘liq aylananing θ/(2π) qismini egallaydi.

Shuning uchun

s = θ/(2π) × 2πr = rθ.

Demak, yoy uzunligi formulasi butun aylana uzunligining ulushi sifatida ham tushuniladi.$t$::text alt,
$t$s=rθ formulasida θ albatta radianlarda bo‘lsin. Radius va yoy uzunligi mos uzunlik birliklarida bo‘lishi kerak. Teskari masalada avval noma’lum kattalikni ajrating. Yoy uzunligi cm, m kabi uzunlik birliklarida yoziladi, kvadrat birlikda emas.$t$::text focus,
'p1:P1-CIR-02:theory:uz:v1'::text src)
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from x;

commit;
