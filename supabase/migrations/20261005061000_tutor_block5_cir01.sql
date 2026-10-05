begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$
declare v_existing integer; v_sources integer; v_baseline integer;
begin
  select count(*) into v_existing from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and skill_code='P1-CIR-01';
  if v_existing<>0 then raise exception 'CIR01 already exists: %',v_existing; end if;

  select count(*) into v_sources from private.exam_prep_ai_source_cards
  where approval_status='approved' and is_runtime_allowed and card_type='theory'
    and component_code='P1' and skill_code='P1-CIR-01' and locale in ('en','ru','uz');
  if v_sources<>3 then raise exception 'CIR01 requires 3 approved theory sources, found %',v_sources; end if;

  select count(*) into v_baseline from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v_baseline<>63 then raise exception 'CIR01 expected 63 prior drafts, found %',v_baseline; end if;
end $pre$;

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p1:P1-CIR-01:tutor:en:v2','P1','P1-CIR-01','en','tutor_v2_learner_first','Degrees and radians',
$t$Radians measure an angle using the circle itself. One full turn is 360 degrees or 2π radians, so

180 degrees = π radians.

To convert degrees to radians, multiply by π/180. For example,

150 degrees × π/180 = 5π/6 radians.

To convert radians to degrees, multiply by 180/π. For example,

2.4 radians × 180/π ≈ 137.5 degrees.

Radians are especially useful because circle formulas such as arc length and sector area become simple when the angle is measured in radians. If an exact answer is requested, keep multiples of π exact instead of replacing π with a decimal too early.$t$,
$t$Use 180 degrees = π radians.

Degrees → radians: multiply by π/180. So 150 degrees = 5π/6 radians.

Radians → degrees: multiply by 180/π. So 2.4 radians ≈ 137.5 degrees.

Keep π when an exact answer is required.$t$,
$t$Think of angles as fractions of a full turn. A full turn is 360 degrees = 2π radians. Half a turn is 180 degrees = π radians, and a quarter turn is 90 degrees = π/2 radians.

Degree-radian conversion simply changes the unit used to describe the same fraction of a circle.$t$,
$t$Check the direction before multiplying: degrees to radians uses π/180; radians to degrees uses 180/π. Radian answers do not need a degree symbol. Keep exact π form when requested, and check calculator angle mode for later trigonometric work.$t$,
'p1:P1-CIR-01:theory:en:v1'
),
(
'p1:P1-CIR-01:tutor:ru:v2','P1','P1-CIR-01','ru','tutor_v2_learner_first','Градусы и радианы',
$t$Радианы измеряют угол через саму окружность. Полный оборот равен 360 градусам или 2π радианам, поэтому

180 градусов = π радиан.

Чтобы перевести градусы в радианы, умножайте на π/180. Например,

150 градусов × π/180 = 5π/6 радиан.

Чтобы перевести радианы в градусы, умножайте на 180/π. Например,

2.4 радиана × 180/π ≈ 137.5 градуса.

Радианы особенно удобны, потому что формулы длины дуги и площади сектора становятся простыми именно при угле в радианах. Если требуется точный ответ, сохраняйте π и не заменяйте его десятичным значением слишком рано.$t$,
$t$Используйте 180 градусов = π радиан.

Градусы → радианы: умножить на π/180. Поэтому 150 градусов = 5π/6 радиан.

Радианы → градусы: умножить на 180/π. Поэтому 2.4 радиана ≈ 137.5 градуса.

Если нужен точный ответ, оставляйте π.$t$,
$t$Представьте угол как долю полного оборота. Полный оборот — 360 градусов = 2π радиан. Половина оборота — 180 градусов = π радиан, четверть — 90 градусов = π/2 радиан.

Перевод между градусами и радианами просто меняет единицу, которой описывается одна и та же доля окружности.$t$,
$t$Сначала определите направление перевода: градусы в радианы — π/180, радианы в градусы — 180/π. У радианного ответа нет значка градусов. Если нужен точный вид, сохраняйте π. Для последующей тригонометрии проверяйте режим углов на калькуляторе.$t$,
'p1:P1-CIR-01:theory:ru:v1'
),
(
'p1:P1-CIR-01:tutor:uz:v2','P1','P1-CIR-01','uz','tutor_v2_learner_first','Gradus va radianlar',
$t$Radian burchakni aylananing o‘zi orqali o‘lchaydi. To‘liq aylanish 360 gradus yoki 2π radian, shuning uchun

180 gradus = π radian.

Gradusdan radianga o‘tish uchun π/180 ga ko‘paytiring. Masalan,

150 gradus × π/180 = 5π/6 radian.

Radiandan gradusga o‘tish uchun 180/π ga ko‘paytiring. Masalan,

2.4 radian × 180/π ≈ 137.5 gradus.

Radianlar ayniqsa qulay, chunki yoy uzunligi va sektor yuzi formulalari burchak radianlarda bo‘lganda sodda ko‘rinishga keladi. Aniq javob so‘ralsa, π ni juda erta o‘nli songa almashtirmang.$t$,
$t$Asosiy tenglik: 180 gradus = π radian.

Gradus → radian: π/180 ga ko‘paytiring. Demak, 150 gradus = 5π/6 radian.

Radian → gradus: 180/π ga ko‘paytiring. Demak, 2.4 radian ≈ 137.5 gradus.

Aniq javob kerak bo‘lsa, π ni saqlang.$t$,
$t$Burchakni to‘liq aylanishning bir qismi deb tasavvur qiling. To‘liq aylanish 360 gradus = 2π radian. Yarim aylanish 180 gradus = π radian, chorak aylanish 90 gradus = π/2 radian.

Demak, gradus va radian orasidagi o‘tish bir xil aylana ulushini boshqa birlikda ifodalashdir.$t$,
$t$Avval qaysi tomonga o‘tayotganingizni tekshiring: gradusdan radianga π/180, radiandan gradusga 180/π ishlatiladi. Radian javobida gradus belgisi bo‘lmaydi. Aniq ko‘rinish so‘ralsa π ni saqlang, keyingi trigonometrik hisoblarda kalkulyator rejimini tekshiring.$t$,
'p1:P1-CIR-01:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,
  source_card_key,approval_status,is_runtime_allowed,content_hash
)
select tutor_card_key,component_code,skill_code,locale,content_version,title,
       main_explanation,simple_explanation,alternative_explanation,focus_explanation,
       source_card_key,'draft',false,
       md5(concat_ws('||',content_version,title,main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key))
from seed;

do $post$
begin
  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P1-CIR-01'
        and approval_status='draft' and not is_runtime_allowed)<>3
  then raise exception 'CIR01 expected 3 draft cards'; end if;
end $post$;

commit;
