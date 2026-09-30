-- AW13-16 P1 annual-reserve top-up draft v1.
-- DRAFT ONLY: no learner-visible content and no existing evidence mutation.
-- Exact delta per skill: +2 diagnostics, +2 delayed retests, +1 mixed/transfer.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw13_16_annual_reserve_p1_draft canonical program missing'; end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4815 and content_version<>'p1_aw13_16_annual_reserve_topup_draft_v1')
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59315 and 59354 and content_version_id<>4815)
  then raise exception 'aw13_16_annual_reserve_p1_draft reserved id collision'; end if;

  if (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-CIR-03','P1-TRI-02','P1-TRI-03','P1-TRI-04','P1-TRI-05','P1-SER-01','P1-SER-02','P1-DIF-01')
        and m.reserve_role='diagnostic')<>8
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-CIR-03','P1-TRI-02','P1-TRI-03','P1-TRI-04','P1-TRI-05','P1-SER-01','P1-SER-02','P1-DIF-01')
        and m.reserve_role='retest')<>16
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-CIR-03','P1-TRI-02','P1-TRI-03','P1-TRI-04','P1-TRI-05','P1-SER-01','P1-SER-02','P1-DIF-01')
        and m.reserve_role in ('learning','mixed'))<>56
  then raise exception 'aw13_16_annual_reserve_p1_draft baseline depth changed'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4815,pv.id,'p1_aw13_16_annual_reserve_topup_draft_v1','P1',
 'P1 AW13-16 annual reserve top-up draft v1','draft',
 'Original iClub-authored annual reserve expansion. Official Cambridge 9709 scope controls the learning objectives; Complete Pure Mathematics 1 is mapping/explanation support only. No protected Cambridge/coursebook question, solution, mark-scheme wording or diagram is copied. Independent academic, trilingual, technical, originality and reserve-isolation QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,reserve_role,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P1CIR03-D02','P1-CIR-03','diagnostic','medium','mcq','A sector has radius 8 cm and angle 1.25 radians. What is its area?','["40 cm²","32 cm²","50 cm²","80 cm²"]','A','The sector area is 1/2 r²θ=1/2×8²×1.25=40 cm².','Сектор имеет радиус 8 см и угол 1,25 радиана. Какова его площадь?','["40 см²","32 см²","50 см²","80 см²"]','Площадь сектора равна 1/2 r²θ=1/2×8²×1,25=40 см².','Sektor radiusi 8 sm va burchagi 1.25 radian. Uning yuzi qancha?','["40 sm²","32 sm²","50 sm²","80 sm²"]','Sektor yuzi 1/2 r²θ=1/2×8²×1.25=40 sm².',70),
('P1CIR03-D03','P1-CIR-03','diagnostic','hard','mcq','A sector of radius 6 cm has angle π/3 radians. What is the exact area of the minor segment cut off by its chord?','["6π+9√3 cm²","18π−9√3 cm²","6π−9√3 cm²","6π−18√3 cm²"]','C','The sector area is 1/2×6²×π/3=6π. The triangle area is 1/2×6²×sin(π/3)=9√3, so the minor segment area is 6π−9√3 cm².','Сектор радиуса 6 см имеет угол π/3 радиана. Какова точная площадь меньшего сегмента, отсечённого хордой?','["6π+9√3 см²","18π−9√3 см²","6π−9√3 см²","6π−18√3 см²"]','Площадь сектора равна 1/2×6²×π/3=6π. Площадь треугольника равна 1/2×6²×sin(π/3)=9√3, поэтому площадь меньшего сегмента равна 6π−9√3 см².','Radiusi 6 sm bo‘lgan sektorning burchagi π/3 radian. Vatar ajratgan kichik segmentning aniq yuzi qancha?','["6π+9√3 sm²","18π−9√3 sm²","6π−9√3 sm²","6π−18√3 sm²"]','Sektor yuzi 1/2×6²×π/3=6π. Uchburchak yuzi 1/2×6²×sin(π/3)=9√3, demak kichik segment yuzi 6π−9√3 sm².',90),
('P1CIR03-R03','P1-CIR-03','retest','medium','input','An annular sector has outer radius 10 cm, inner radius 6 cm and angle 0.5 radians. Enter its area in cm².','[]','16','The area is 1/2(10²−6²)(0.5)=1/2×64×0.5=16 cm².','Кольцевой сектор имеет внешний радиус 10 см, внутренний радиус 6 см и угол 0,5 радиана. Введите его площадь в см².','[]','Площадь равна 1/2(10²−6²)(0,5)=1/2×64×0,5=16 см².','Halqasimon sektorning tashqi radiusi 10 sm, ichki radiusi 6 sm va burchagi 0.5 radian. Uning yuzini sm² da kiriting.','[]','Yuza 1/2(10²−6²)(0.5)=1/2×64×0.5=16 sm².',75),
('P1CIR03-R04','P1-CIR-03','retest','medium','mcq','A sector has radius 6 cm and area 27 cm². Find its angle in radians.','["0.75","1.5","3","4.5"]','B','27=1/2×6²×θ=18θ, so θ=27/18=1.5 radians.','Сектор имеет радиус 6 см и площадь 27 см². Найдите его угол в радианах.','["0,75","1,5","3","4,5"]','27=1/2×6²×θ=18θ, поэтому θ=27/18=1,5 радиана.','Sektor radiusi 6 sm va yuzi 27 sm². Uning burchagini radianlarda toping.','["0.75","1.5","3","4.5"]','27=1/2×6²×θ=18θ, demak θ=27/18=1.5 radian.',70),
('P1CIR03-M02','P1-CIR-03','mixed','hard','input','A design is made from a semicircular sector of radius 4 cm and a separate quarter-circle sector of radius 4 cm, with no overlap. Its total area is kπ cm². Enter k.','[]','12','The semicircle area is 1/2π(4²)=8π and the quarter-circle area is 1/4π(4²)=4π. Total area=12π, so k=12.','Фигура состоит из полукруглого сектора радиуса 4 см и отдельного сектора-четверти круга радиуса 4 см без перекрытия. Общая площадь равна kπ см². Введите k.','[]','Площадь полукруга равна 1/2π(4²)=8π, площадь четверти круга равна 1/4π(4²)=4π. Общая площадь 12π, поэтому k=12.','Shakl radiusi 4 sm bo‘lgan yarim doira sektori va u bilan ustma-ust tushmaydigan radiusi 4 sm bo‘lgan chorak doira sektoridan tuzilgan. Umumiy yuza kπ sm². k ni kiriting.','[]','Yarim doira yuzi 1/2π(4²)=8π, chorak doira yuzi 1/4π(4²)=4π. Jami 12π, demak k=12.',90),
('P1TRI02-D02','P1-TRI-02','diagnostic','medium','mcq','Find the exact value of cos225°.','["√2/2","1/2","−√2/2","−1/2"]','C','225°=180°+45°. Cosine is negative in quadrant III, so cos225°=−√2/2.','Найдите точное значение cos225°.','["√2/2","1/2","−√2/2","−1/2"]','225°=180°+45°. В III четверти косинус отрицателен, поэтому cos225°=−√2/2.','cos225° ning aniq qiymatini toping.','["√2/2","1/2","−√2/2","−1/2"]','225°=180°+45°. III chorakda kosinus manfiy, demak cos225°=−√2/2.',60),
('P1TRI02-D03','P1-TRI-02','diagnostic','medium','mcq','Find the exact value of tan330°.','["√3","√3/3","−1","−√3/3"]','D','330°=360°−30°. Tangent is negative in quadrant IV, so tan330°=−tan30°=−√3/3.','Найдите точное значение tan330°.','["√3","√3/3","−1","−√3/3"]','330°=360°−30°. В IV четверти тангенс отрицателен, поэтому tan330°=−tan30°=−√3/3.','tan330° ning aniq qiymatini toping.','["√3","√3/3","−1","−√3/3"]','330°=360°−30°. IV chorakda tangens manfiy, demak tan330°=−tan30°=−√3/3.',65),
('P1TRI02-R03','P1-TRI-02','retest','medium','input','Enter the exact value of 2cos60°+tan45°.','[]','2','2cos60°+tan45°=2(1/2)+1=2.','Введите точное значение 2cos60°+tan45°.','[]','2cos60°+tan45°=2(1/2)+1=2.','2cos60°+tan45° ning aniq qiymatini kiriting.','[]','2cos60°+tan45°=2(1/2)+1=2.',55),
('P1TRI02-R04','P1-TRI-02','retest','medium','mcq','Evaluate exactly: sin270°·cos180°.','["−1","1","0","1/2"]','B','sin270°=−1 and cos180°=−1, so the product is 1.','Вычислите точно: sin270°·cos180°.','["−1","1","0","1/2"]','sin270°=−1 и cos180°=−1, поэтому произведение равно 1.','Aniq hisoblang: sin270°·cos180°.','["−1","1","0","1/2"]','sin270°=−1 va cos180°=−1, shuning uchun ko‘paytma 1.',55),
('P1TRI02-M02','P1-TRI-02','mixed','hard','input','Enter the exact value of 4sin30°cos60°−tan225°.','[]','0','4sin30°cos60°=4(1/2)(1/2)=1 and tan225°=1, so the expression is 0.','Введите точное значение 4sin30°cos60°−tan225°.','[]','4sin30°cos60°=4(1/2)(1/2)=1 и tan225°=1, поэтому выражение равно 0.','4sin30°cos60°−tan225° ning aniq qiymatini kiriting.','[]','4sin30°cos60°=4(1/2)(1/2)=1 va tan225°=1, demak ifoda 0.',70),
('P1TRI03-D02','P1-TRI-03','diagnostic','medium','mcq','Using principal values in degrees, evaluate sin⁻¹(√2/2).','["45°","135°","−45°","315°"]','A','The principal range of sin⁻¹ is −90°≤θ≤90°, and sin45°=√2/2, so the principal value is 45°.','Используя главные значения в градусах, вычислите sin⁻¹(√2/2).','["45°","135°","−45°","315°"]','Главный диапазон sin⁻¹: −90°≤θ≤90°. Так как sin45°=√2/2, главное значение равно 45°.','Graduslardagi bosh qiymatlardan foydalanib sin⁻¹(√2/2) ni hisoblang.','["45°","135°","−45°","315°"]','sin⁻¹ ning bosh oralig‘i −90°≤θ≤90°. sin45°=√2/2 bo‘lgani uchun bosh qiymat 45°.',60),
('P1TRI03-D03','P1-TRI-03','diagnostic','medium','mcq','Using principal values in degrees, evaluate tan⁻¹(−√3).','["60°","120°","−120°","−60°"]','D','The principal range of tan⁻¹ is −90°<θ<90°. Since tan60°=√3, tan⁻¹(−√3)=−60°.','Используя главные значения в градусах, вычислите tan⁻¹(−√3).','["60°","120°","−120°","−60°"]','Главный диапазон tan⁻¹: −90°<θ<90°. Так как tan60°=√3, tan⁻¹(−√3)=−60°.','Graduslardagi bosh qiymatlardan foydalanib tan⁻¹(−√3) ni hisoblang.','["60°","120°","−120°","−60°"]','tan⁻¹ ning bosh oralig‘i −90°<θ<90°. tan60°=√3 bo‘lgani uchun tan⁻¹(−√3)=−60°.',60),
('P1TRI03-R03','P1-TRI-03','retest','medium','input','Enter the principal value in degrees of cos⁻¹(−√2/2).','[]','135','On the principal range 0°≤θ≤180°, cosθ=−√2/2 at θ=135°.','Введите главное значение cos⁻¹(−√2/2) в градусах.','[]','На главном диапазоне 0°≤θ≤180° значение cosθ=−√2/2 достигается при θ=135°.','cos⁻¹(−√2/2) ning graduslardagi bosh qiymatini kiriting.','[]','0°≤θ≤180° bosh oraliqda cosθ=−√2/2 bo‘lishi θ=135° da yuz beradi.',55),
('P1TRI03-R04','P1-TRI-03','retest','medium','mcq','Which interval is the principal-value range of tan⁻¹ in degrees?','["0°≤θ≤180°","−180°<θ≤180°","−90°<θ<90°","0°≤θ<360°"]','C','The inverse tangent function uses the principal range −90°<θ<90°.','Какой промежуток является диапазоном главных значений tan⁻¹ в градусах?','["0°≤θ≤180°","−180°<θ≤180°","−90°<θ<90°","0°≤θ<360°"]','Для обратного тангенса используется главный диапазон −90°<θ<90°.','tan⁻¹ ning graduslardagi bosh qiymatlar oralig‘i qaysi?','["0°≤θ≤180°","−180°<θ≤180°","−90°<θ<90°","0°≤θ<360°"]','Teskari tangensning bosh oralig‘i −90°<θ<90°.',55),
('P1TRI03-M02','P1-TRI-03','mixed','hard','input','In degree mode, a calculator gives sin⁻¹(0.3). Enter the principal value to 1 decimal place.','[]','17.5','sin⁻¹(0.3)≈17.4576°, which rounds to 17.5°.','В градусном режиме калькулятор вычисляет sin⁻¹(0,3). Введите главное значение с точностью до 1 десятичного знака.','[]','sin⁻¹(0,3)≈17,4576°, что округляется до 17,5°.','Gradus rejimida kalkulyator sin⁻¹(0.3) ni hisoblaydi. Bosh qiymatni 1 ta o‘nli xonagacha kiriting.','[]','sin⁻¹(0.3)≈17.4576°, 1 ta o‘nli xonagacha 17.5°.',75),
('P1TRI04-D02','P1-TRI-04','diagnostic','medium','mcq','For sin x cos x≠0, simplify tan x/sin x.','["1/cos x","cos x","sin x","1"]','A','tan x/sin x=(sin x/cos x)/sin x=1/cos x.','При sin x cos x≠0 упростите tan x/sin x.','["1/cos x","cos x","sin x","1"]','tan x/sin x=(sin x/cos x)/sin x=1/cos x.','sin x cos x≠0 bo‘lganda tan x/sin x ni soddalashtiring.','["1/cos x","cos x","sin x","1"]','tan x/sin x=(sin x/cos x)/sin x=1/cos x.',65),
('P1TRI04-D03','P1-TRI-04','diagnostic','medium','mcq','Simplify 1−cos²x.','["1","cos²x","tan²x","sin²x"]','D','From sin²x+cos²x=1, we have 1−cos²x=sin²x.','Упростите 1−cos²x.','["1","cos²x","tan²x","sin²x"]','Из sin²x+cos²x=1 следует 1−cos²x=sin²x.','1−cos²x ni soddalashtiring.','["1","cos²x","tan²x","sin²x"]','sin²x+cos²x=1 dan 1−cos²x=sin²x.',55),
('P1TRI04-R03','P1-TRI-04','retest','medium','input','If cos x=0.8, enter the exact decimal value of sin²x.','[]','0.36','sin²x=1−cos²x=1−0.64=0.36.','Если cos x=0,8, введите точное десятичное значение sin²x.','[]','sin²x=1−cos²x=1−0,64=0,36.','Agar cos x=0.8 bo‘lsa, sin²x ning aniq o‘nli qiymatini kiriting.','[]','sin²x=1−cos²x=1−0.64=0.36.',55),
('P1TRI04-R04','P1-TRI-04','retest','medium','mcq','If tan x=3/4 and cos x=4/5, find sin x.','["4/5","3/5","5/4","3/4"]','B','Using tan x=sin x/cos x, sin x=tan x·cos x=(3/4)(4/5)=3/5.','Если tan x=3/4 и cos x=4/5, найдите sin x.','["4/5","3/5","5/4","3/4"]','Из tan x=sin x/cos x получаем sin x=tan x·cos x=(3/4)(4/5)=3/5.','Agar tan x=3/4 va cos x=4/5 bo‘lsa, sin x ni toping.','["4/5","3/5","5/4","3/4"]','tan x=sin x/cos x dan sin x=tan x·cos x=(3/4)(4/5)=3/5.',60),
('P1TRI04-M02','P1-TRI-04','mixed','hard','input','If sin x=12/13 and x is acute, cos²x is a fraction in simplest form. Enter its numerator.','[]','25','cos²x=1−sin²x=1−144/169=25/169, so the numerator is 25.','Если sin x=12/13 и x — острый угол, cos²x записано несократимой дробью. Введите её числитель.','[]','cos²x=1−sin²x=1−144/169=25/169, поэтому числитель равен 25.','Agar sin x=12/13 va x o‘tkir burchak bo‘lsa, cos²x qisqartirilgan kasr ko‘rinishida. Uning suratini kiriting.','[]','cos²x=1−sin²x=1−144/169=25/169, demak surat 25.',70),
('P1TRI05-D02','P1-TRI-05','diagnostic','medium','mcq','Solve cos θ=−√2/2 for 0°≤θ<360°.','["135°, 225°","45°, 315°","135°, 315°","45°, 225°"]','A','The reference angle is 45°. Cosine is negative in quadrants II and III, giving 135° and 225°.','Решите cos θ=−√2/2 при 0°≤θ<360°.','["135°, 225°","45°, 315°","135°, 315°","45°, 225°"]','Опорный угол 45°. Косинус отрицателен во II и III четвертях, поэтому θ=135° и 225°.','0°≤θ<360° da cos θ=−√2/2 tenglamani yeching.','["135°, 225°","45°, 315°","135°, 315°","45°, 225°"]','Tayanch burchak 45°. Kosinus II va III choraklarda manfiy, demak θ=135° va 225°.',70),
('P1TRI05-D03','P1-TRI-05','diagnostic','medium','mcq','Solve tan θ=√3 for 0°≤θ<360°.','["30°, 210°","60°, 240°","120°, 300°","60°, 300°"]','B','The reference angle is 60°. Tangent is positive in quadrants I and III, giving 60° and 240°.','Решите tan θ=√3 при 0°≤θ<360°.','["30°, 210°","60°, 240°","120°, 300°","60°, 300°"]','Опорный угол 60°. Тангенс положителен в I и III четвертях, поэтому θ=60° и 240°.','0°≤θ<360° da tan θ=√3 tenglamani yeching.','["30°, 210°","60°, 240°","120°, 300°","60°, 300°"]','Tayanch burchak 60°. Tangens I va III choraklarda musbat, demak θ=60° va 240°.',70),
('P1TRI05-R03','P1-TRI-05','retest','medium','input','How many solutions does sin θ=0 have on −360°≤θ≤360°? Enter the number of solutions.','[]','5','sinθ=0 at integer multiples of 180°. In the interval these are −360°, −180°, 0°, 180° and 360°: five solutions.','Сколько решений имеет sin θ=0 на промежутке −360°≤θ≤360°? Введите число решений.','[]','sinθ=0 при целых кратных 180°. На данном промежутке это −360°, −180°, 0°, 180° и 360°: пять решений.','−360°≤θ≤360° oraliqda sin θ=0 nechta yechimga ega? Yechimlar sonini kiriting.','[]','sinθ=0 180° ning butun karralilarida. Berilgan oraliqda −360°, −180°, 0°, 180° va 360° bor: beshta yechim.',60),
('P1TRI05-R04','P1-TRI-05','retest','medium','mcq','Solve 2cos θ+1=0 for 0°≤θ<360°.','["60°, 300°","120°, 300°","120°, 240°","60°, 240°"]','C','2cosθ+1=0 gives cosθ=−1/2. The reference angle is 60°, and cosine is negative in quadrants II and III: 120° and 240°.','Решите 2cos θ+1=0 при 0°≤θ<360°.','["60°, 300°","120°, 300°","120°, 240°","60°, 240°"]','Получаем cosθ=−1/2. Опорный угол 60°, косинус отрицателен во II и III четвертях: 120° и 240°.','0°≤θ<360° da 2cos θ+1=0 tenglamani yeching.','["60°, 300°","120°, 300°","120°, 240°","60°, 240°"]','cosθ=−1/2. Tayanch burchak 60°, kosinus II va III choraklarda manfiy: 120° va 240°.',70),
('P1TRI05-M02','P1-TRI-05','mixed','hard','input','Find all solutions of sin θ=cos θ for 0°≤θ<360°. Enter the sum of the solutions in degrees.','[]','270','Where cosθ≠0, sinθ=cosθ gives tanθ=1. The solutions are 45° and 225°, whose sum is 270°.','Найдите все решения sin θ=cos θ при 0°≤θ<360°. Введите сумму решений в градусах.','[]','При cosθ≠0 равенство sinθ=cosθ даёт tanθ=1. Решения: 45° и 225°, их сумма 270°.','0°≤θ<360° da sin θ=cos θ ning barcha yechimlarini toping. Yechimlar yig‘indisini graduslarda kiriting.','[]','cosθ≠0 bo‘lganda sinθ=cosθ dan tanθ=1. Yechimlar 45° va 225°, yig‘indisi 270°.',80),
('P1SER01-D02','P1-SER-01','diagnostic','medium','mcq','Find the coefficient of x² in (2+3x)⁴.','["216","108","54","324"]','A','The x² term is 4C2·2²·(3x)²=6×4×9x²=216x².','Найдите коэффициент при x² в разложении (2+3x)⁴.','["216","108","54","324"]','Член с x² равен 4C2·2²·(3x)²=6×4×9x²=216x².','(2+3x)⁴ yoyilmasida x² oldidagi koeffitsiyentni toping.','["216","108","54","324"]','x² hadi 4C2·2²·(3x)²=6×4×9x²=216x².',70),
('P1SER01-D03','P1-SER-01','diagnostic','medium','mcq','Find the coefficient of x³ in (1−2x)⁵.','["80","−40","−80","160"]','C','The x³ term is 5C3(−2x)³=10(−8)x³=−80x³.','Найдите коэффициент при x³ в разложении (1−2x)⁵.','["80","−40","−80","160"]','Член с x³ равен 5C3(−2x)³=10(−8)x³=−80x³.','(1−2x)⁵ yoyilmasida x³ oldidagi koeffitsiyentni toping.','["80","−40","−80","160"]','x³ hadi 5C3(−2x)³=10(−8)x³=−80x³.',65),
('P1SER01-R03','P1-SER-01','retest','medium','input','Enter the constant term in (5−2x)⁴.','[]','625','The constant term is 5⁴=625.','Введите свободный член в разложении (5−2x)⁴.','[]','Свободный член равен 5⁴=625.','(5−2x)⁴ yoyilmasidagi o‘zgarmas hadni kiriting.','[]','O‘zgarmas had 5⁴=625.',50),
('P1SER01-R04','P1-SER-01','retest','medium','mcq','Find the coefficient of x in (3+x)⁶.','["729","1458","486","2187"]','B','The x term is 6C1·3⁵·x=6×243x=1458x.','Найдите коэффициент при x в разложении (3+x)⁶.','["729","1458","486","2187"]','Член с x равен 6C1·3⁵·x=6×243x=1458x.','(3+x)⁶ yoyilmasida x oldidagi koeffitsiyentni toping.','["729","1458","486","2187"]','x hadi 6C1·3⁵·x=6×243x=1458x.',65),
('P1SER01-M02','P1-SER-01','mixed','hard','input','Enter the coefficient of x² in (1+x)⁴(1−x).','[]','2','In (1+x)⁴ the coefficients of x and x² are 4 and 6. After multiplying by (1−x), the x² coefficient is 6−4=2.','Введите коэффициент при x² в произведении (1+x)⁴(1−x).','[]','В (1+x)⁴ коэффициенты при x и x² равны 4 и 6. После умножения на (1−x) коэффициент при x² равен 6−4=2.','(1+x)⁴(1−x) ko‘paytmada x² oldidagi koeffitsiyentni kiriting.','[]','(1+x)⁴ da x va x² koeffitsiyentlari 4 va 6. (1−x) ga ko‘paytirilganda x² koeffitsiyenti 6−4=2.',80),
('P1SER02-D02','P1-SER-02','diagnostic','medium','mcq','The sequence has nth term uₙ=5+3n. Which description is correct?','["geometric with ratio 3","arithmetic with difference 3","arithmetic with difference 5","neither"]','B','uₙ₊₁−uₙ=[5+3(n+1)]−(5+3n)=3, so the sequence is arithmetic with common difference 3.','Последовательность имеет общий член uₙ=5+3n. Какое описание верно?','["геометрическая со знаменателем 3","арифметическая с разностью 3","арифметическая с разностью 5","ни одна"]','uₙ₊₁−uₙ=[5+3(n+1)]−(5+3n)=3, поэтому это арифметическая прогрессия с разностью 3.','Ketma-ketlikning n-hadi uₙ=5+3n. Qaysi tavsif to‘g‘ri?','["maxraji 3 bo‘lgan geometrik","ayirmasi 3 bo‘lgan arifmetik","ayirmasi 5 bo‘lgan arifmetik","hech qaysi"]','uₙ₊₁−uₙ=[5+3(n+1)]−(5+3n)=3, demak bu ayirmasi 3 bo‘lgan arifmetik progressiya.',65),
('P1SER02-D03','P1-SER-02','diagnostic','medium','mcq','The sequence 2, −6, 18, −54, ... is:','["arithmetic with difference −8","geometric with ratio 3","arithmetic with difference −3","geometric with ratio −3"]','D','Each term is obtained by multiplying the previous term by −3, so it is geometric with common ratio −3.','Последовательность 2, −6, 18, −54, ... является:','["арифметической с разностью −8","геометрической со знаменателем 3","арифметической с разностью −3","геометрической со знаменателем −3"]','Каждый следующий член получается умножением предыдущего на −3, поэтому это геометрическая прогрессия со знаменателем −3.','2, −6, 18, −54, ... ketma-ketligi:','["ayirmasi −8 bo‘lgan arifmetik","maxraji 3 bo‘lgan geometrik","ayirmasi −3 bo‘lgan arifmetik","maxraji −3 bo‘lgan geometrik"]','Har bir keyingi had oldingisini −3 ga ko‘paytirib olinadi, demak bu maxraji −3 bo‘lgan geometrik progressiya.',60),
('P1SER02-R03','P1-SER-02','retest','medium','input','The sequence 7, 3, −1, −5, ... is arithmetic. Enter its common difference.','[]','-4','Each term decreases by 4, so the common difference is −4.','Последовательность 7, 3, −1, −5, ... арифметическая. Введите её разность.','[]','Каждый следующий член уменьшается на 4, поэтому разность равна −4.','7, 3, −1, −5, ... ketma-ketligi arifmetik. Uning umumiy ayirmasini kiriting.','[]','Har bir keyingi had 4 ga kamayadi, demak umumiy ayirma −4.',50),
('P1SER02-R04','P1-SER-02','retest','medium','mcq','The sequence 5, 15, 45, 135, ... is:','["geometric with ratio 3","arithmetic with difference 10","geometric with ratio 5","neither"]','A','Each term is three times the previous term, so the sequence is geometric with ratio 3.','Последовательность 5, 15, 45, 135, ... является:','["геометрической со знаменателем 3","арифметической с разностью 10","геометрической со знаменателем 5","ни одной"]','Каждый следующий член в три раза больше предыдущего, поэтому это геометрическая прогрессия со знаменателем 3.','5, 15, 45, 135, ... ketma-ketligi:','["maxraji 3 bo‘lgan geometrik","ayirmasi 10 bo‘lgan arifmetik","maxraji 5 bo‘lgan geometrik","hech qaysi"]','Har bir keyingi had oldingisidan 3 marta katta, demak bu maxraji 3 bo‘lgan geometrik progressiya.',55),
('P1SER02-M02','P1-SER-02','mixed','hard','input','The sequence 2, 6, 18, 54, ... continues with the same structure. Enter its fifth term.','[]','162','The sequence is geometric with common ratio 3, so the fifth term is 54×3=162.','Последовательность 2, 6, 18, 54, ... продолжается по той же закономерности. Введите пятый член.','[]','Это геометрическая прогрессия со знаменателем 3, поэтому пятый член равен 54×3=162.','2, 6, 18, 54, ... ketma-ketligi shu tuzilishda davom etadi. Beshinchi hadni kiriting.','[]','Bu maxraji 3 bo‘lgan geometrik progressiya, demak beshinchi had 54×3=162.',65),
('P1DIF01-D02','P1-DIF-01','diagnostic','medium','mcq','For f(x)=x², evaluate lim(h→0) [(4+h)²−16]/h.','["8","4","16","0"]','A','[(4+h)²−16]/h=(8h+h²)/h=8+h, which tends to 8.','Для f(x)=x² вычислите lim(h→0) [(4+h)²−16]/h.','["8","4","16","0"]','[(4+h)²−16]/h=(8h+h²)/h=8+h, при h→0 получаем 8.','f(x)=x² uchun lim(h→0) [(4+h)²−16]/h ni hisoblang.','["8","4","16","0"]','[(4+h)²−16]/h=(8h+h²)/h=8+h, h→0 da 8 chiqadi.',65),
('P1DIF01-D03','P1-DIF-01','diagnostic','medium','mcq','Secant gradients near x=a are −3.2, −3.02, −2.99 and −3.001 as the interval width approaches 0. What derivative value is suggested at x=a?','["3","−2","0","−3"]','D','The secant gradients approach −3 from nearby values, so the instantaneous gradient is −3.','Градиенты секущих около x=a равны −3,2; −3,02; −2,99 и −3,001 при стремлении ширины промежутка к нулю. Какое значение производной предполагается при x=a?','["3","−2","0","−3"]','Значения градиента секущей приближаются к −3, поэтому мгновенный градиент равен −3.','x=a yaqinida kesuvchi gradientlari oraliq kengligi 0 ga yaqinlashganda −3.2, −3.02, −2.99 va −3.001. x=a dagi hosila qaysi qiymatga yaqin?','["3","−2","0","−3"]','Kesuvchi gradientlari −3 ga yaqinlashadi, demak oniy gradient −3.',65),
('P1DIF01-R03','P1-DIF-01','retest','medium','input','For f(x)=3x², use the limit idea to enter the tangent gradient at x=2.','[]','12','The difference quotient tends to f′(2)=6×2=12.','Для f(x)=3x², используя идею предела, введите градиент касательной при x=2.','[]','Разностное отношение стремится к f′(2)=6×2=12.','f(x)=3x² uchun limit g‘oyasidan foydalanib x=2 dagi urinma gradientini kiriting.','[]','Ayirmali nisbat f′(2)=6×2=12 ga intiladi.',60),
('P1DIF01-R04','P1-DIF-01','retest','medium','mcq','At t=5 s, ds/dt=0. Which statement is correct?','["The displacement s must be 0","The instantaneous rate of change of displacement is 0","The object has never moved","The acceleration must be 0"]','B','ds/dt=0 means the displacement has zero instantaneous rate of change at that moment. It does not imply zero displacement or zero acceleration.','При t=5 с значение ds/dt=0. Какое утверждение верно?','["Перемещение s обязательно равно 0","Мгновенная скорость изменения перемещения равна 0","Объект никогда не двигался","Ускорение обязательно равно 0"]','ds/dt=0 означает, что в этот момент мгновенная скорость изменения перемещения равна нулю. Это не означает нулевое перемещение или ускорение.','t=5 s da ds/dt=0. Qaysi fikr to‘g‘ri?','["Ko‘chish s albatta 0","Ko‘chishning oniy o‘zgarish tezligi 0","Jism hech qachon harakatlanmagan","Tezlanish albatta 0"]','ds/dt=0 shu onda ko‘chishning oniy o‘zgarish tezligi nol ekanini bildiradi. Bu ko‘chish yoki tezlanishning nol bo‘lishini anglatmaydi.',55),
('P1DIF01-M02','P1-DIF-01','mixed','hard','input','For f(x)=x²+x, the derivative is obtained from the limit of the difference quotient. Enter the tangent gradient at x=3.','[]','7','From the difference quotient, f′(x)=2x+1. Hence f′(3)=7.','Для f(x)=x²+x производная получается как предел разностного отношения. Введите градиент касательной при x=3.','[]','Из разностного отношения получаем f′(x)=2x+1. Поэтому f′(3)=7.','f(x)=x²+x uchun hosila ayirmali nisbat limitidan olinadi. x=3 dagi urinma gradientini kiriting.','[]','Ayirmali nisbatdan f′(x)=2x+1. Demak f′(3)=7.',70)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,'P1 annual reserve',s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P1:p1_aw13_16_annual_reserve_topup_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P1:p1_aw13_16_annual_reserve_topup_draft_v1:'||s.content_key);

with src(meta_id,content_key,skill_code,reserve_role,official_ref,book_ref) as (values
(59315,'P1CIR03-D02','P1-CIR-03','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
(59316,'P1CIR03-D03','P1-CIR-03','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
(59317,'P1CIR03-R03','P1-CIR-03','retest','Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
(59318,'P1CIR03-R04','P1-CIR-03','retest','Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
(59319,'P1CIR03-M02','P1-CIR-03','mixed','Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
(59320,'P1TRI02-D02','P1-TRI-02','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59321,'P1TRI02-D03','P1-TRI-02','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59322,'P1TRI02-R03','P1-TRI-02','retest','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59323,'P1TRI02-R04','P1-TRI-02','retest','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59324,'P1TRI02-M02','P1-TRI-02','mixed','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59325,'P1TRI03-D02','P1-TRI-03','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59326,'P1TRI03-D03','P1-TRI-03','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59327,'P1TRI03-R03','P1-TRI-03','retest','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59328,'P1TRI03-R04','P1-TRI-03','retest','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59329,'P1TRI03-M02','P1-TRI-03','mixed','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59330,'P1TRI04-D02','P1-TRI-04','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59331,'P1TRI04-D03','P1-TRI-04','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59332,'P1TRI04-R03','P1-TRI-04','retest','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59333,'P1TRI04-R04','P1-TRI-04','retest','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59334,'P1TRI04-M02','P1-TRI-04','mixed','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59335,'P1TRI05-D02','P1-TRI-05','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59336,'P1TRI05-D03','P1-TRI-05','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59337,'P1TRI05-R03','P1-TRI-05','retest','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59338,'P1TRI05-R04','P1-TRI-05','retest','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59339,'P1TRI05-M02','P1-TRI-05','mixed','Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
(59340,'P1SER01-D02','P1-SER-01','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch6 Binomial expansion pp.109-116 (mapping only)'),
(59341,'P1SER01-D03','P1-SER-01','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch6 Binomial expansion pp.109-116 (mapping only)'),
(59342,'P1SER01-R03','P1-SER-01','retest','Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch6 Binomial expansion pp.109-116 (mapping only)'),
(59343,'P1SER01-R04','P1-SER-01','retest','Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch6 Binomial expansion pp.109-116 (mapping only)'),
(59344,'P1SER01-M02','P1-SER-01','mixed','Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch6 Binomial expansion pp.109-116 (mapping only)'),
(59345,'P1SER02-D02','P1-SER-02','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
(59346,'P1SER02-D03','P1-SER-02','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
(59347,'P1SER02-R03','P1-SER-02','retest','Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
(59348,'P1SER02-R04','P1-SER-02','retest','Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
(59349,'P1SER02-M02','P1-SER-02','mixed','Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
(59350,'P1DIF01-D02','P1-DIF-01','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
(59351,'P1DIF01-D03','P1-DIF-01','diagnostic','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
(59352,'P1DIF01-R03','P1-DIF-01','retest','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
(59353,'P1DIF01-R04','P1-DIF-01','retest','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
(59354,'P1DIF01-M02','P1-DIF-01','mixed','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)')
)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,4815,s.content_key,q.id,s.skill_code,'{}'::text[],s.reserve_role,'withheld','draft',
 'Original iClub-authored annual-reserve item with independent stem, values, distractors, answer and explanation; no protected source wording copied.',
 'AW13-16 annual reserve top-up. Withheld role is fixed before exposure and remains separate from the released learning pack.',
 s.official_ref,s.book_ref,
 'pending','pending','pending','pending','pending',
 case when s.reserve_role='diagnostic' then 'pending' else 'not_applicable' end,
 md5(concat_ws(chr(31),
   q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),
   coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
   coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),
   coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
   coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),
   coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')
 ))
from src s
join public.questions q on q.book_ref='ExamPrep:P1:p1_aw13_16_annual_reserve_topup_draft_v1:'||s.content_key
on conflict(id) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select status from private.exam_prep_content_versions where id=4815)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4815)<>40
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4815 and reserve_role='diagnostic')<>16
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4815 and reserve_role='retest')<>16
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4815 and reserve_role='mixed')<>8
  then raise exception 'aw13_16_annual_reserve_p1_draft cardinality mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4815 and (
    m.lifecycle_state<>'draft' or m.exposure_state<>'withheld'
    or m.copyright_status<>'pending' or m.qa_scope_status<>'pending' or m.qa_math_status<>'pending'
    or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or (m.reserve_role='diagnostic' and m.diagnostic_rule_status<>'pending')
    or (m.reserve_role<>'diagnostic' and m.diagnostic_rule_status<>'not_applicable')
    or q.is_active or q.quality_status<>'draft'
    or nullif(btrim(q.question_text_en),'') is null or nullif(btrim(q.question_text_ru),'') is null or nullif(btrim(q.question_text_uz),'') is null
    or nullif(btrim(q.explanation_en),'') is null or nullif(btrim(q.explanation_ru),'') is null or nullif(btrim(q.explanation_uz),'') is null
  );
  if v_bad<>0 then raise exception 'aw13_16_annual_reserve_p1_draft QA/exposure rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4815
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4815
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw13_16_annual_reserve_p1_draft exact published stem duplicate'; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4815;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(7,7,5,5,16) then
    raise exception 'aw13_16_annual_reserve_p1_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4815)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4815)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4815)
  then raise exception 'aw13_16_annual_reserve_p1_draft unexpected history'; end if;
end
$postcheck$;

commit;
