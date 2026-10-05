begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>75 then raise exception 'TRI02 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-TRI-02' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'TRI02 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-TRI-02:tutor:en:v2','P1','P1-TRI-02','en','tutor_v2_learner_first','Exact trigonometric values',
$t$Exact trig values come from a small set of reference angles. Keep the values for 0, π/6, π/4, π/3 and π/2 in exact form.

Examples:
sin(π/6)=1/2,
cos(π/3)=1/2,
tan(π/4)=1.

For a related angle, find the reference angle and then use the quadrant to choose the sign. Thus sin(5π/6)=1/2, while cos(2π/3)=-1/2. The reference angle gives the magnitude; the quadrant gives the sign.$t$,
$t$Use the standard angles 0, π/6, π/4, π/3 and π/2. For a related angle, keep the same reference-angle magnitude and choose the sign from the quadrant. So sin(5π/6)=1/2 and cos(2π/3)=-1/2.$t$,
$t$Think “reference angle + quadrant”. The reference angle tells you the exact magnitude. The quadrant tells you whether the value is positive or negative. This lets one small exact-value table cover many angles.$t$,
$t$Keep exact answers as fractions and roots, not decimals. Find the reference angle first, then apply the sign for the correct trig function in that quadrant.$t$,
'p1:P1-TRI-02:theory:en:v1'
),
(
'p1:P1-TRI-02:tutor:ru:v2','P1','P1-TRI-02','ru','tutor_v2_learner_first','Точные тригонометрические значения',
$t$Точные значения строятся вокруг небольшого набора опорных углов. Для 0, π/6, π/4, π/3 и π/2 сохраняйте ответы в точной форме.

Примеры:
sin(π/6)=1/2,
cos(π/3)=1/2,
tan(π/4)=1.

Для связанного угла сначала найдите опорный угол, затем по четверти выберите знак. Поэтому sin(5π/6)=1/2, а cos(2π/3)=-1/2. Опорный угол задаёт модуль значения, четверть — знак.$t$,
$t$Используйте стандартные углы 0, π/6, π/4, π/3 и π/2. Для связанного угла сохраните модуль опорного значения и выберите знак по четверти. Поэтому sin(5π/6)=1/2, а cos(2π/3)=-1/2.$t$,
$t$Думайте так: «опорный угол + четверть». Опорный угол даёт точный модуль, четверть определяет знак. Поэтому одна небольшая таблица точных значений работает для многих углов.$t$,
$t$Оставляйте точные ответы в виде дробей и корней, а не десятичных чисел. Сначала найдите опорный угол, затем определите знак именно для нужной функции в этой четверти.$t$,
'p1:P1-TRI-02:theory:ru:v1'
),
(
'p1:P1-TRI-02:tutor:uz:v2','P1','P1-TRI-02','uz','tutor_v2_learner_first','Aniq trigonometrik qiymatlar',
$t$Aniq trigonometrik qiymatlar kichik to‘plamdagi tayanch burchaklarga asoslanadi. 0, π/6, π/4, π/3 va π/2 uchun javoblarni aniq ko‘rinishda saqlang.

Misollar:
sin(π/6)=1/2,
cos(π/3)=1/2,
tan(π/4)=1.

Bog‘liq burchakda avval tayanch burchakni toping, keyin chorakdan ishorani oling. Shuning uchun sin(5π/6)=1/2, cos(2π/3)=-1/2. Tayanch burchak qiymat modulini, chorak esa ishorani beradi.$t$,
$t$0, π/6, π/4, π/3 va π/2 standart burchaklardan foydalaning. Bog‘liq burchak uchun tayanch qiymat modulini saqlang va ishorani chorakdan oling. Demak, sin(5π/6)=1/2 va cos(2π/3)=-1/2.$t$,
$t$“Tayanch burchak + chorak” deb o‘ylang. Tayanch burchak aniq qiymat kattaligini, chorak esa ishorani beradi. Shu sabab kichik aniq qiymatlar jadvali ko‘p burchaklar uchun yetadi.$t$,
$t$Aniq javoblarni kasr va ildizlarda saqlang, o‘nli songa o‘tkazmang. Avval tayanch burchakni toping, keyin aynan kerakli trigonometrik funksiya uchun chorak ishorasini qo‘llang.$t$,
'p1:P1-TRI-02:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
