-- AW13-16 supplemental learning pack draft for P1.
-- DRAFT ONLY: no learner exposure, QA self-approval or publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active') then
    raise exception 'aw13_16_alt_p1_draft canonical program missing';
  end if;
  if exists(select 1 from private.exam_prep_content_versions where id=4813 and content_version<>'p1_aw13_16_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15638 and 15645 and content_version_id<>4813)
     or exists(select 1 from private.exam_prep_assessments where id between 35421 and 35428 and content_version_id<>4813)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59270 and 59293 and content_version_id<>4813)
  then raise exception 'aw13_16_alt_p1_draft reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4813,pv.id,'p1_aw13_16_alt_learning_draft_v1','P1',
 'P1 AW13-16 supplemental learning pack draft v1','draft',
 'Original iClub-authored supplemental learning content. Official Cambridge 9709 scope and Complete Pure Mathematics 1 mappings define learning objectives only; no protected source question, solution, diagram or mark-scheme wording is copied. Independent academic, language, technical and copyright QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,topic,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P1CIR03-A01','P1-CIR-03','P1 Circular measure','medium','mcq','A sector has radius 10 cm and angle 0.8 radians. The triangle formed by the two radii and the chord has area 24 cm². Find the area of the minor segment.','["16 cm²","24 cm²","40 cm²","64 cm²"]','A','The sector area is 1/2×10²×0.8=40 cm². The segment area is 40−24=16 cm².','Сектор имеет радиус 10 см и угол 0,8 радиана. Площадь треугольника, образованного двумя радиусами и хордой, равна 24 см². Найдите площадь меньшего сегмента.','["16 см²","24 см²","40 см²","64 см²"]','Площадь сектора равна 1/2×10²×0,8=40 см². Площадь сегмента: 40−24=16 см².','Sektor radiusi 10 cm va burchagi 0.8 radian. Ikki radius va vatar hosil qilgan uchburchak yuzi 24 cm². Kichik segment yuzini toping.','["16 cm²","24 cm²","40 cm²","64 cm²"]','Sektor yuzi 1/2×10²×0.8=40 cm². Segment yuzi 40−24=16 cm².',80),
('P1CIR03-A02','P1-CIR-03','P1 Circular measure','hard','mcq','An annular sector has outer radius 7 cm, inner radius 3 cm and angle 1.5 radians. Find its area.','["24 cm²","30 cm²","42 cm²","60 cm²"]','B','The area is 1/2(7²−3²)(1.5)=1/2×40×1.5=30 cm².','Кольцевой сектор имеет внешний радиус 7 см, внутренний радиус 3 см и угол 1,5 радиана. Найдите его площадь.','["24 см²","30 см²","42 см²","60 см²"]','Площадь равна 1/2(7²−3²)(1,5)=1/2×40×1,5=30 см².','Halqasimon sektorning tashqi radiusi 7 cm, ichki radiusi 3 cm va burchagi 1.5 radian. Uning yuzini toping.','["24 cm²","30 cm²","42 cm²","60 cm²"]','Yuza 1/2(7²−3²)(1.5)=1/2×40×1.5=30 cm².',85),
('P1CIR03-A03','P1-CIR-03','P1 Circular measure','hard','input','A sector has radius 6 cm and angle 2.2 radians. The triangle formed by its radii and chord has area 14.4 cm². Enter the area of the corresponding segment in cm².','[]','25.2','The sector area is 1/2×6²×2.2=39.6 cm². Subtracting the triangle gives 39.6−14.4=25.2 cm².','Сектор имеет радиус 6 см и угол 2,2 радиана. Площадь треугольника, образованного радиусами и хордой, равна 14,4 см². Введите площадь соответствующего сегмента в см².','[]','Площадь сектора: 1/2×6²×2,2=39,6 см². Вычитаем площадь треугольника: 39,6−14,4=25,2 см².','Sektor radiusi 6 cm va burchagi 2.2 radian. Radiuslar va vatar hosil qilgan uchburchak yuzi 14.4 cm². Mos segment yuzini cm² da kiriting.','[]','Sektor yuzi 1/2×6²×2.2=39.6 cm². Uchburchak yuzini ayirsak 39.6−14.4=25.2 cm².',90),
('P1TRI02-A01','P1-TRI-02','P1 Trigonometry','medium','mcq','Find the exact value of sin 210°.','["−1/2","1/2","−√3/2","√3/2"]','C','210°=180°+30°. Sine is negative in quadrant III, so sin210°=−sin30°=−1/2.','Найдите точное значение sin 210°.','["−1/2","1/2","−√3/2","√3/2"]','210°=180°+30°. В III четверти синус отрицателен, поэтому sin210°=−sin30°=−1/2.','sin 210° ning aniq qiymatini toping.','["−1/2","1/2","−√3/2","√3/2"]','210°=180°+30°. III chorakda sinus manfiy, shuning uchun sin210°=−sin30°=−1/2.',60),
('P1TRI02-A02','P1-TRI-02','P1 Trigonometry','medium','mcq','Evaluate exactly: cos60°−tan135°.','["−3/2","−1/2","1/2","3/2"]','D','cos60°=1/2 and tan135°=−1, so 1/2−(−1)=3/2.','Вычислите точно: cos60°−tan135°.','["−3/2","−1/2","1/2","3/2"]','cos60°=1/2, tan135°=−1, поэтому 1/2−(−1)=3/2.','Aniq hisoblang: cos60°−tan135°.','["−3/2","−1/2","1/2","3/2"]','cos60°=1/2 va tan135°=−1, demak 1/2−(−1)=3/2.',65),
('P1TRI02-A03','P1-TRI-02','P1 Trigonometry','medium','input','Enter the exact value of 2sin150°−cos180°.','[]','2','sin150°=1/2 and cos180°=−1. Hence 2(1/2)−(−1)=2.','Введите точное значение 2sin150°−cos180°.','[]','sin150°=1/2, cos180°=−1. Поэтому 2(1/2)−(−1)=2.','2sin150°−cos180° ning aniq qiymatini kiriting.','[]','sin150°=1/2 va cos180°=−1. Demak 2(1/2)−(−1)=2.',60),
('P1TRI03-A01','P1-TRI-03','P1 Trigonometry','medium','mcq','Using principal values in degrees, evaluate sin⁻¹(−1/2).','["−30°","30°","150°","210°"]','A','The principal range of sin⁻¹ is −90° to 90°, so sin⁻¹(−1/2)=−30°.','Используя главные значения в градусах, вычислите sin⁻¹(−1/2).','["−30°","30°","150°","210°"]','Главный диапазон sin⁻¹ — от −90° до 90°, поэтому sin⁻¹(−1/2)=−30°.','Graduslardagi bosh qiymatlardan foydalanib sin⁻¹(−1/2) ni hisoblang.','["−30°","30°","150°","210°"]','sin⁻¹ ning bosh qiymatlar oralig‘i −90° dan 90° gacha, demak sin⁻¹(−1/2)=−30°.',55),
('P1TRI03-A02','P1-TRI-03','P1 Trigonometry','medium','mcq','What is the principal value of cos⁻¹(√3/2) in degrees?','["−30°","30°","150°","330°"]','B','The principal range of cos⁻¹ is 0° to 180°. Since cos30°=√3/2, the principal value is 30°.','Каково главное значение cos⁻¹(√3/2) в градусах?','["−30°","30°","150°","330°"]','Главный диапазон cos⁻¹ — от 0° до 180°. Поскольку cos30°=√3/2, главное значение равно 30°.','cos⁻¹(√3/2) ning graduslardagi bosh qiymati qaysi?','["−30°","30°","150°","330°"]','cos⁻¹ ning bosh qiymatlar oralig‘i 0° dan 180° gacha. cos30°=√3/2 bo‘lgani uchun bosh qiymat 30°.',55),
('P1TRI03-A03','P1-TRI-03','P1 Trigonometry','medium','input','Enter the principal value in degrees of cos⁻¹(1/2).','[]','60','On the principal range 0°≤θ≤180°, cosθ=1/2 at θ=60°.','Введите главное значение cos⁻¹(1/2) в градусах.','[]','На главном диапазоне 0°≤θ≤180° равенство cosθ=1/2 выполняется при θ=60°.','cos⁻¹(1/2) ning graduslardagi bosh qiymatini kiriting.','[]','0°≤θ≤180° bosh oraliqda cosθ=1/2 bo‘lishi θ=60° da yuz beradi.',55),
('P1TRI04-A01','P1-TRI-04','P1 Trigonometry','medium','mcq','For cos x≠0, simplify (1−sin²x)/cos x.','["1","sin x","cos x","tan x"]','C','Using sin²x+cos²x=1, the numerator is cos²x. Dividing by cos x gives cos x.','При cos x≠0 упростите (1−sin²x)/cos x.','["1","sin x","cos x","tan x"]','Из sin²x+cos²x=1 числитель равен cos²x. Деление на cos x даёт cos x.','cos x≠0 bo‘lganda (1−sin²x)/cos x ni soddalashtiring.','["1","sin x","cos x","tan x"]','sin²x+cos²x=1 dan surat cos²x. cos x ga bo‘lsak cos x chiqadi.',65),
('P1TRI04-A02','P1-TRI-04','P1 Trigonometry','medium','mcq','Simplify tan x·cos x, where cos x≠0.','["1","cos x","tan x","sin x"]','D','tan x=sin x/cos x, so tan x·cos x=sin x.','Упростите tan x·cos x при cos x≠0.','["1","cos x","tan x","sin x"]','tan x=sin x/cos x, поэтому tan x·cos x=sin x.','cos x≠0 bo‘lganda tan x·cos x ni soddalashtiring.','["1","cos x","tan x","sin x"]','tan x=sin x/cos x, shuning uchun tan x·cos x=sin x.',60),
('P1TRI04-A03','P1-TRI-04','P1 Trigonometry','medium','input','If sin x=0.6 and x is acute, enter the exact decimal value of cos²x.','[]','0.64','cos²x=1−sin²x=1−0.36=0.64.','Если sin x=0,6 и x — острый угол, введите точное десятичное значение cos²x.','[]','cos²x=1−sin²x=1−0,36=0,64.','Agar sin x=0.6 va x o‘tkir burchak bo‘lsa, cos²x ning aniq o‘nli qiymatini kiriting.','[]','cos²x=1−sin²x=1−0.36=0.64.',60),
('P1TRI05-A01','P1-TRI-05','P1 Trigonometry','medium','mcq','Solve sin θ=−1/2 for 0°≤θ<360°.','["210°, 330°","30°, 150°","150°, 210°","30°, 330°"]','A','The reference angle is 30°. Sine is negative in quadrants III and IV, giving 210° and 330°.','Решите sin θ=−1/2 при 0°≤θ<360°.','["210°, 330°","30°, 150°","150°, 210°","30°, 330°"]','Опорный угол 30°. Синус отрицателен в III и IV четвертях, поэтому θ=210° и 330°.','0°≤θ<360° da sin θ=−1/2 tenglamani yeching.','["210°, 330°","30°, 150°","150°, 210°","30°, 330°"]','Tayanch burchak 30°. Sinus III va IV choraklarda manfiy, demak θ=210° va 330°.',70),
('P1TRI05-A02','P1-TRI-05','P1 Trigonometry','medium','mcq','Solve cos θ=0 for −180°≤θ≤180°.','["0° only","−90°, 90°","−180°, 180°","−90° only"]','B','Cosine is zero at odd multiples of 90°. In the stated interval these are −90° and 90°.','Решите cos θ=0 при −180°≤θ≤180°.','["только 0°","−90°, 90°","−180°, 180°","только −90°"]','Косинус равен нулю при нечётных кратных 90°. В данном промежутке это −90° и 90°.','−180°≤θ≤180° da cos θ=0 tenglamani yeching.','["faqat 0°","−90°, 90°","−180°, 180°","faqat −90°"]','Kosinus 90° ning toq karralilarida nol. Berilgan oraliqda ular −90° va 90°.',65),
('P1TRI05-A03','P1-TRI-05','P1 Trigonometry','medium','input','How many solutions does tan θ=1 have for 0°≤θ<720°? Enter the number of solutions.','[]','4','tanθ=1 at 45°+180°k. In 0°≤θ<720° this gives 45°, 225°, 405° and 585°: four solutions.','Сколько решений имеет tan θ=1 при 0°≤θ<720°? Введите число решений.','[]','tanθ=1 при 45°+180°k. В промежутке 0°≤θ<720° получаем 45°, 225°, 405° и 585°: четыре решения.','0°≤θ<720° da tan θ=1 tenglama nechta yechimga ega? Yechimlar sonini kiriting.','[]','tanθ=1 45°+180°k da. 0°≤θ<720° oraliqda 45°, 225°, 405° va 585° chiqadi: to‘rtta yechim.',75),
('P1SER01-A01','P1-SER-01','P1 Series','medium','mcq','Find the coefficient of x³ in (2+x)⁵.','["20","32","40","80"]','C','The x³ term is 5C3·2²·x³=10·4x³, so the coefficient is 40.','Найдите коэффициент при x³ в разложении (2+x)⁵.','["20","32","40","80"]','Член с x³ равен 5C3·2²·x³=10·4x³, поэтому коэффициент равен 40.','(2+x)⁵ yoyilmasida x³ oldidagi koeffitsiyentni toping.','["20","32","40","80"]','x³ hadi 5C3·2²·x³=10·4x³, demak koeffitsiyent 40.',70),
('P1SER01-A02','P1-SER-01','P1 Series','medium','mcq','Find the coefficient of x² in (1−3x)⁴.','["−54","−18","18","54"]','D','The x² term is 4C2(−3x)²=6·9x²=54x².','Найдите коэффициент при x² в разложении (1−3x)⁴.','["−54","−18","18","54"]','Член с x² равен 4C2(−3x)²=6·9x²=54x².','(1−3x)⁴ yoyilmasida x² oldidagi koeffitsiyentni toping.','["−54","−18","18","54"]','x² hadi 4C2(−3x)²=6·9x²=54x².',70),
('P1SER01-A03','P1-SER-01','P1 Series','medium','input','Enter the coefficient of x in (3+2x)⁴.','[]','216','The x term is 4C1·3³·2x=4·27·2x=216x.','Введите коэффициент при x в разложении (3+2x)⁴.','[]','Член с x равен 4C1·3³·2x=4·27·2x=216x.','(3+2x)⁴ yoyilmasida x oldidagi koeffitsiyentni kiriting.','[]','x hadi 4C1·3³·2x=4·27·2x=216x.',65),
('P1SER02-A01','P1-SER-02','P1 Series','medium','mcq','The sequence 7, 12, 17, 22, ... is:','["arithmetic with common difference 5","geometric with common ratio 5","arithmetic with common difference 7","neither arithmetic nor geometric"]','A','Consecutive terms increase by 5, so the sequence is arithmetic with common difference 5.','Последовательность 7, 12, 17, 22, ... является:','["арифметической с разностью 5","геометрической со знаменателем 5","арифметической с разностью 7","ни арифметической, ни геометрической"]','Соседние члены увеличиваются на 5, поэтому это арифметическая прогрессия с разностью 5.','7, 12, 17, 22, ... ketma-ketligi:','["ayirmasi 5 bo‘lgan arifmetik progressiya","maxraji 5 bo‘lgan geometrik progressiya","ayirmasi 7 bo‘lgan arifmetik progressiya","na arifmetik, na geometrik"]','Ketma-ket hadlar 5 ga ortadi, demak bu ayirmasi 5 bo‘lgan arifmetik progressiya.',55),
('P1SER02-A02','P1-SER-02','P1 Series','medium','mcq','The sequence 96, 48, 24, 12, ... is:','["arithmetic with common difference −48","geometric with common ratio 1/2","geometric with common ratio 2","neither arithmetic nor geometric"]','B','Each term is obtained by multiplying the previous term by 1/2, so it is geometric with ratio 1/2.','Последовательность 96, 48, 24, 12, ... является:','["арифметической с разностью −48","геометрической со знаменателем 1/2","геометрической со знаменателем 2","ни арифметической, ни геометрической"]','Каждый следующий член получается умножением предыдущего на 1/2, поэтому это геометрическая прогрессия со знаменателем 1/2.','96, 48, 24, 12, ... ketma-ketligi:','["ayirmasi −48 bo‘lgan arifmetik progressiya","maxraji 1/2 bo‘lgan geometrik progressiya","maxraji 2 bo‘lgan geometrik progressiya","na arifmetik, na geometrik"]','Har bir keyingi had oldingisini 1/2 ga ko‘paytirib olinadi, demak bu maxraji 1/2 bo‘lgan geometrik progressiya.',55),
('P1SER02-A03','P1-SER-02','P1 Series','medium','input','The sequence 4, 9, 14, 19, ... is arithmetic. Enter its common difference.','[]','5','Each term increases by 5, so the common difference is 5.','Последовательность 4, 9, 14, 19, ... арифметическая. Введите её разность.','[]','Каждый член увеличивается на 5, поэтому разность равна 5.','4, 9, 14, 19, ... ketma-ketligi arifmetik. Uning umumiy ayirmasini kiriting.','[]','Har bir had 5 ga ortadi, shuning uchun umumiy ayirma 5.',50),
('P1DIF01-A01','P1-DIF-01','P1 Differentiation','medium','mcq','For f(x)=x²+3x, evaluate lim(h→0) [f(1+h)−f(1)]/h.','["2","3","5","8"]','C','The limit is f′(1). Since f′(x)=2x+3, f′(1)=5. Expanding the quotient gives the same result.','Для f(x)=x²+3x вычислите lim(h→0) [f(1+h)−f(1)]/h.','["2","3","5","8"]','Предел равен f′(1). Так как f′(x)=2x+3, получаем f′(1)=5. Раскрытие разностного отношения даёт тот же результат.','f(x)=x²+3x uchun lim(h→0) [f(1+h)−f(1)]/h ni hisoblang.','["2","3","5","8"]','Bu limit f′(1) ga teng. f′(x)=2x+3, demak f′(1)=5. Ayirmali nisbatni yoyish ham shu natijani beradi.',75),
('P1DIF01-A02','P1-DIF-01','P1 Differentiation','medium','mcq','At t=3 s, ds/dt=−4 m s⁻¹. What does this mean?','["s=−4 m at t=3","the speed is increasing by 4 m s⁻²","the object has moved 4 m in total","the position s is decreasing at 4 m per second at that instant"]','D','A negative derivative means the position variable is decreasing. Its instantaneous rate of change is 4 m per second in the negative direction.','При t=3 с значение ds/dt=−4 м/с. Что это означает?','["s=−4 м при t=3","скорость увеличивается на 4 м/с²","объект всего прошёл 4 м","в этот момент координата s уменьшается со скоростью 4 м в секунду"]','Отрицательная производная означает уменьшение координаты. Мгновенная скорость изменения равна 4 м/с в отрицательном направлении.','t=3 s da ds/dt=−4 m/s. Bu nimani anglatadi?','["t=3 da s=−4 m","tezlik 4 m/s² ga ortmoqda","jism jami 4 m yurgan","shu onda s koordinata soniyasiga 4 m tezlikda kamaymoqda"]','Manfiy hosila koordinata kamayishini bildiradi. Oniy o‘zgarish tezligi manfiy yo‘nalishda 4 m/s.',65),
('P1DIF01-A03','P1-DIF-01','P1 Differentiation','medium','input','Evaluate lim(h→0) [(2+h)³−8]/h.','[]','12','(2+h)³−8=12h+6h²+h³. Dividing by h and taking h→0 gives 12.','Вычислите lim(h→0) [(2+h)³−8]/h.','[]','(2+h)³−8=12h+6h²+h³. Делим на h и при h→0 получаем 12.','lim(h→0) [(2+h)³−8]/h ni hisoblang.','[]','(2+h)³−8=12h+6h²+h³. h ga bo‘lib, h→0 da 12 ni olamiz.',70)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,s.topic,s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P1:p1_aw13_16_alt_learning_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P1:p1_aw13_16_alt_learning_draft_v1:'||s.content_key);

insert into private.exam_prep_written_tasks(
 id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
 prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
 lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(15638,4813,'P1CIR03-AW14','P1','P1-CIR-03','{}','v1','A sector has radius 9 cm and angle 1.2 radians. (a) Find its area. (b) The triangle formed by the two radii and the chord has area 32 cm². Find the area of the minor segment. (c) A concentric inner sector of radius 5 cm with the same angle is removed. Find the area of the remaining annular sector. Show the formula used in each part.','Сектор имеет радиус 9 см и угол 1,2 радиана. (a) Найдите его площадь. (b) Площадь треугольника, образованного двумя радиусами и хордой, равна 32 см². Найдите площадь меньшего сегмента. (c) Из сектора удаляют концентрический внутренний сектор радиуса 5 см с тем же углом. Найдите площадь оставшегося кольцевого сектора. Покажите формулу в каждой части.','Sektor radiusi 9 cm va burchagi 1.2 radian. (a) Uning yuzini toping. (b) Ikki radius va vatar hosil qilgan uchburchak yuzi 32 cm². Kichik segment yuzini toping. (c) Shu burchakli radiusi 5 cm bo‘lgan konsentrik ichki sektor olib tashlanadi. Qolgan halqasimon sektor yuzini toping. Har qismda ishlatilgan formulani ko‘rsating.','{"criteria":[{"id":"sector","rule":"Finds sector area 48.6 cm² using 1/2 r²θ.","marks":2},{"id":"segment","rule":"Finds minor segment area 16.6 cm².","marks":1},{"id":"inner","rule":"Finds inner sector area 15 cm².","marks":1},{"id":"annular","rule":"Finds remaining annular-sector area 33.6 cm².","marks":1},{"id":"method","rule":"Shows the correct area formula and units consistently.","marks":1}],"max_marks":6}'::jsonb,'Use 1/2 r²θ for each sector. For a segment subtract the triangle; for an annular sector subtract the inner sector from the outer sector.','Используйте 1/2 r²θ для каждого сектора. Для сегмента вычтите треугольник; для кольцевого сектора вычтите внутренний сектор из внешнего.','Har bir sektor uchun 1/2 r²θ dan foydalaning. Segment uchun uchburchak yuzini ayiring; halqasimon sektor uchun ichki sektorni tashqi sektordan ayiring.','draft','pending','pending','pending','pending'),
(15639,4813,'P1TRI02-AW14','P1','P1-TRI-02','{}','v1','Without a calculator, find the exact values of sin210°, cos330°, tan315° and 2cos60°−sin270°. For each single angle, state the reference angle and the quadrant sign.','Без калькулятора найдите точные значения sin210°, cos330°, tan315° и 2cos60°−sin270°. Для каждого отдельного угла укажите опорный угол и знак в четверти.','Kalkulyatorsiz sin210°, cos330°, tan315° va 2cos60°−sin270° ning aniq qiymatlarini toping. Har bir alohida burchak uchun tayanch burchak va chorakdagi ishorani ko‘rsating.','{"criteria":[{"id":"sin","rule":"Obtains sin210°=−1/2 with correct quadrant reasoning.","marks":1},{"id":"cos","rule":"Obtains cos330°=√3/2 with correct quadrant reasoning.","marks":1},{"id":"tan","rule":"Obtains tan315°=−1 with correct quadrant reasoning.","marks":1},{"id":"expr","rule":"Obtains 2cos60°−sin270°=2.","marks":1},{"id":"reference","rule":"States the correct 30°/45° reference angles.","marks":1},{"id":"signs","rule":"Explains the relevant quadrant signs.","marks":1}],"max_marks":6}'::jsonb,'Reduce each angle to a standard reference angle first, then decide the sign from its quadrant before using the exact value.','Сначала сведите каждый угол к стандартному опорному углу, затем определите знак по четверти и только после этого используйте точное значение.','Avval har bir burchakni standart tayanch burchakka keltiring, keyin chorakka qarab ishorani aniqlab, so‘ng aniq qiymatdan foydalaning.','draft','pending','pending','pending','pending'),
(15640,4813,'P1TRI03-AW14','P1','P1-TRI-03','{}','v1','State the principal-value ranges in degrees for sin⁻¹, cos⁻¹ and tan⁻¹. Then find sin⁻¹(−√3/2), cos⁻¹(−1/2) and tan⁻¹(1). Explain why the principal value from an inverse trigonometric function is not automatically the complete solution set of a trigonometric equation.','Укажите диапазоны главных значений в градусах для sin⁻¹, cos⁻¹ и tan⁻¹. Затем найдите sin⁻¹(−√3/2), cos⁻¹(−1/2) и tan⁻¹(1). Объясните, почему главное значение обратной тригонометрической функции не является автоматически полным множеством решений тригонометрического уравнения.','sin⁻¹, cos⁻¹ va tan⁻¹ uchun graduslardagi bosh qiymatlar oraliqlarini yozing. So‘ng sin⁻¹(−√3/2), cos⁻¹(−1/2) va tan⁻¹(1) ni toping. Nega teskari trigonometrik funksiyaning bosh qiymati trigonometrik tenglamaning barcha yechimlari bo‘lavermasligini tushuntiring.','{"criteria":[{"id":"ranges","rule":"States the three principal-value ranges correctly.","marks":2},{"id":"asin","rule":"Obtains −60°.","marks":1},{"id":"acos","rule":"Obtains 120°.","marks":1},{"id":"atan","rule":"Obtains 45°.","marks":1},{"id":"explain","rule":"Explains that inverse functions return one principal value while an equation may have periodic/symmetric solutions in its stated interval.","marks":1}],"max_marks":6}'::jsonb,'Keep principal-value ranges separate from equation-solving intervals. An inverse function returns one selected angle, not every coterminal or symmetric solution.','Не смешивайте диапазоны главных значений с промежутками решения уравнений. Обратная функция возвращает один выбранный угол, а не все симметричные или периодические решения.','Bosh qiymatlar oralig‘ini tenglama yechiladigan oraliqdan ajrating. Teskari funksiya bitta tanlangan burchakni qaytaradi, barcha simmetrik yoki davriy yechimlarni emas.','draft','pending','pending','pending','pending'),
(15641,4813,'P1TRI04-AW14','P1','P1-TRI-04','{}','v1','Prove, where the expressions are defined, that (1−sin²x)/(cos x)=cos x and that tan x·cos x=sin x. Then simplify (sin²x+cos²x)/(1−sin²x), stating any denominator restrictions.','Докажите там, где выражения определены, что (1−sin²x)/(cos x)=cos x и tan x·cos x=sin x. Затем упростите (sin²x+cos²x)/(1−sin²x), указав ограничения на знаменатели.','Ifodalar aniqlangan joylarda (1−sin²x)/(cos x)=cos x va tan x·cos x=sin x ekanini isbotlang. So‘ng (sin²x+cos²x)/(1−sin²x) ni soddalashtirib, maxraj cheklovlarini yozing.','{"criteria":[{"id":"pyth","rule":"Uses sin²x+cos²x=1 correctly.","marks":1},{"id":"first","rule":"Derives (1−sin²x)/cos x=cos x with cos x≠0.","marks":1},{"id":"tan","rule":"Uses tan x=sin x/cos x.","marks":1},{"id":"second","rule":"Derives tan x·cos x=sin x with cos x≠0.","marks":1},{"id":"final","rule":"Simplifies the final expression to sec²x or 1/cos²x.","marks":1},{"id":"restrictions","rule":"States cos x≠0 for the denominators used.","marks":1}],"max_marks":6}'::jsonb,'Start from identities that are valid for all x, then record restrictions introduced by division.','Начните с тождеств, верных для всех x, а затем отдельно укажите ограничения, появившиеся из-за деления.','Barcha x uchun to‘g‘ri bo‘lgan ayniyatlardan boshlang, keyin bo‘lish sababli paydo bo‘lgan cheklovlarni alohida yozing.','draft','pending','pending','pending','pending'),
(15642,4813,'P1TRI05-AW14','P1','P1-TRI-05','{}','v1','Solve on 0°≤θ<360°: (a) sinθ=−√3/2, (b) cosθ=√2/2, (c) tanθ=−1. For each equation, show the reference angle, identify the valid quadrants and list every solution in the interval.','Решите при 0°≤θ<360°: (a) sinθ=−√3/2, (b) cosθ=√2/2, (c) tanθ=−1. Для каждого уравнения покажите опорный угол, укажите подходящие четверти и перечислите все решения на промежутке.','0°≤θ<360° da yeching: (a) sinθ=−√3/2, (b) cosθ=√2/2, (c) tanθ=−1. Har bir tenglama uchun tayanch burchakni, mos choraklarni va oraliqdagi barcha yechimlarni ko‘rsating.','{"criteria":[{"id":"sin","rule":"Finds 240° and 300°.","marks":2},{"id":"cos","rule":"Finds 45° and 315°.","marks":1},{"id":"tan","rule":"Finds 135° and 315°.","marks":1},{"id":"reference","rule":"Uses the correct 60°/45° reference angles.","marks":1},{"id":"complete","rule":"Uses quadrant signs to show that no valid solution in the interval is omitted.","marks":1}],"max_marks":6}'::jsonb,'Find the reference angle before using quadrant signs. Check the interval endpoint convention after listing the periodic solutions.','Сначала найдите опорный угол, затем используйте знаки по четвертям. После получения периодических решений проверьте, какие концы промежутка включены.','Avval tayanch burchakni toping, keyin chorak ishoralaridan foydalaning. Davriy yechimlarni yozgach, oraliq chegaralari kiritilgan-kiritilmaganini tekshiring.','draft','pending','pending','pending','pending'),
(15643,4813,'P1SER01-AW14','P1','P1-SER-01','{}','v1','Expand (2−x)⁵ up to and including the x³ term. Hence state the coefficients of x, x² and x³. Then find the coefficient of x² in (2−x)⁵(1+x). Show the binomial coefficients used.','Разложите (2−x)⁵ до члена с x³ включительно. Укажите коэффициенты при x, x² и x³. Затем найдите коэффициент при x² в (2−x)⁵(1+x). Покажите использованные биномиальные коэффициенты.','(2−x)⁵ ni x³ hadi bilan birga shu hadgacha yoying. x, x² va x³ oldidagi koeffitsiyentlarni yozing. So‘ng (2−x)⁵(1+x) da x² oldidagi koeffitsiyentni toping. Ishlatilgan binomial koeffitsiyentlarni ko‘rsating.','{"criteria":[{"id":"expand","rule":"Obtains 32−80x+80x²−40x³+…","marks":2},{"id":"coeffs","rule":"States the x, x² and x³ coefficients correctly.","marks":1},{"id":"product","rule":"Identifies the x² coefficient in the product as 80−80=0.","marks":2},{"id":"method","rule":"Shows the relevant binomial coefficients and powers.","marks":1}],"max_marks":6}'::jsonb,'Use 5Cr·2^(5−r)(−x)^r. For the product coefficient, combine only terms whose powers add to x².','Используйте 5Cr·2^(5−r)(−x)^r. Для коэффициента в произведении складывайте только произведения членов, степени которых дают x².','5Cr·2^(5−r)(−x)^r dan foydalaning. Ko‘paytmadagi x² koeffitsiyenti uchun darajalari x² ni beradigan hadlargina qo‘shiladi.','draft','pending','pending','pending','pending'),
(15644,4813,'P1SER02-AW14','P1','P1-SER-02','{}','v1','For each sequence, decide whether it is arithmetic, geometric or neither, and justify your decision: (a) 5, 9, 13, 17, ...; (b) 81, 27, 9, 3, ...; (c) 2, 5, 10, 17, ... . State the common difference or ratio whenever it exists.','Для каждой последовательности определите, является ли она арифметической, геометрической или ни той ни другой, и обоснуйте ответ: (a) 5, 9, 13, 17, ...; (b) 81, 27, 9, 3, ...; (c) 2, 5, 10, 17, ... . Укажите постоянную разность или знаменатель, если они существуют.','Har bir ketma-ketlikni arifmetik, geometrik yoki hech qaysi ekanini aniqlang va asoslang: (a) 5, 9, 13, 17, ...; (b) 81, 27, 9, 3, ...; (c) 2, 5, 10, 17, ... . Mavjud bo‘lsa, umumiy ayirma yoki maxrajni yozing.','{"criteria":[{"id":"a","rule":"Classifies (a) as arithmetic with difference 4.","marks":2},{"id":"b","rule":"Classifies (b) as geometric with ratio 1/3.","marks":2},{"id":"c","rule":"Classifies (c) as neither.","marks":1},{"id":"justify","rule":"Justifies classifications using consecutive differences/ratios rather than appearance alone.","marks":1}],"max_marks":6}'::jsonb,'Check consecutive differences first for arithmetic structure and consecutive ratios for geometric structure. A single matching pair is not enough.','Сначала проверьте последовательные разности для арифметической прогрессии и последовательные отношения для геометрической. Одной совпавшей пары недостаточно.','Arifmetik tuzilma uchun ketma-ket ayirmalarni, geometrik tuzilma uchun ketma-ket nisbatlarni tekshiring. Bitta mos juftlik yetarli emas.','draft','pending','pending','pending','pending'),
(15645,4813,'P1DIF01-AW14','P1','P1-DIF-01','{}','v1','For f(x)=x²+2x, use the limit definition to find the gradient at x=3. Then explain what a derivative value of −5 metres per second means when the function represents displacement s(t). Finally, state the difference between an average rate of change over an interval and an instantaneous rate of change.','Для f(x)=x²+2x с помощью определения через предел найдите градиент при x=3. Затем объясните, что означает значение производной −5 метров в секунду, если функция описывает перемещение s(t). Наконец, укажите различие между средней скоростью изменения на промежутке и мгновенной скоростью изменения.','f(x)=x²+2x uchun limit ta’rifidan foydalanib x=3 dagi gradientni toping. So‘ng funksiya s(t) ko‘chishni ifodalasa, hosilaning −5 metr/sekund qiymati nimani anglatishini tushuntiring. Oxirida oraliqdagi o‘rtacha o‘zgarish tezligi bilan oniy o‘zgarish tezligi farqini yozing.','{"criteria":[{"id":"quotient","rule":"Forms and simplifies the correct difference quotient at x=3.","marks":2},{"id":"limit","rule":"Obtains gradient 8.","marks":1},{"id":"negative","rule":"Explains that displacement is decreasing at 5 m/s at that instant.","marks":1},{"id":"average","rule":"Describes average rate as a secant/finite-interval change.","marks":1},{"id":"instant","rule":"Describes instantaneous rate as the limiting tangent rate at one point.","marks":1}],"max_marks":6}'::jsonb,'Write [f(3+h)−f(3)]/h before simplifying. Keep the interpretation of the sign separate from the magnitude of the rate.','Сначала запишите [f(3+h)−f(3)]/h, затем упрощайте. При интерпретации отделяйте знак скорости изменения от её величины.','Avval [f(3+h)−f(3)]/h ni yozing, keyin soddalashtiring. Talqinda o‘zgarish tezligining ishorasi va modulini alohida ko‘ring.','draft','pending','pending','pending','pending')
on conflict(id) do nothing;

with src(content_key,skill_code,meta_id,official_ref,book_ref) as (values
('P1CIR03-A01','P1-CIR-03',59270,'Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
('P1CIR03-A02','P1-CIR-03',59271,'Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
('P1CIR03-A03','P1-CIR-03',59272,'Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
('P1TRI02-A01','P1-TRI-02',59273,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI02-A02','P1-TRI-02',59274,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI02-A03','P1-TRI-02',59275,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI03-A01','P1-TRI-03',59276,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI03-A02','P1-TRI-03',59277,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI03-A03','P1-TRI-03',59278,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI04-A01','P1-TRI-04',59279,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI04-A02','P1-TRI-04',59280,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI04-A03','P1-TRI-04',59281,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI05-A01','P1-TRI-05',59282,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI05-A02','P1-TRI-05',59283,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI05-A03','P1-TRI-05',59284,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1SER01-A01','P1-SER-01',59285,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch6 Binomial expansion pp.109-116 (mapping only)'),
('P1SER01-A02','P1-SER-01',59286,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch6 Binomial expansion pp.109-116 (mapping only)'),
('P1SER01-A03','P1-SER-01',59287,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch6 Binomial expansion pp.109-116 (mapping only)'),
('P1SER02-A01','P1-SER-02',59288,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER02-A02','P1-SER-02',59289,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER02-A03','P1-SER-02',59290,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1DIF01-A01','P1-DIF-01',59291,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF01-A02','P1-DIF-01',59292,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF01-A03','P1-DIF-01',59293,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)')
), cv as (select id from private.exam_prep_content_versions where id=4813)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,cv.id,s.content_key,qn.id,s.skill_code,'{}'::text[],'learning','withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'Supplemental AW13-16 learning draft authored from the canonical skill intent with independent values and contexts, separate from the existing teaching pack.',
 s.official_ref,s.book_ref,
 'pending','pending','pending','pending','pending','not_applicable',
 md5(concat_ws(chr(31),
   qn.id::text,qn.subject_id::text,coalesce(qn.topic,''),coalesce(qn.subtopic,''),coalesce(qn.difficulty,''),coalesce(qn.qtype,''),
   coalesce(qn.question_text,''),coalesce(qn.options_text,''),coalesce(qn.correct_answer,''),coalesce(qn.explanation,''),
   coalesce(qn.image_url,''),coalesce(qn.is_active::text,''),coalesce(qn.question_text_ru,''),coalesce(qn.question_text_uz,''),
   coalesce(qn.question_text_en,''),coalesce(qn.options_text_ru,''),coalesce(qn.options_text_uz,''),coalesce(qn.options_text_en,''),
   coalesce(qn.explanation_ru,''),coalesce(qn.explanation_uz,''),coalesce(qn.explanation_en,''),coalesce(qn.book_ref,''),
   coalesce(qn.time_limit_sec::text,''),coalesce(qn.quality_flag,''),coalesce(qn.quality_status,'')
 ))
from cv cross join src s
join public.questions qn on qn.book_ref='ExamPrep:P1:p1_aw13_16_alt_learning_draft_v1:'||s.content_key
on conflict(id) do nothing;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35421,4813,'P1-CIR-03-learning-alt-03','v1','P1','learning','draft','Sector and segment area','Площади секторов и сегментов','Sektor va segment yuzlari'),
(35422,4813,'P1-TRI-02-learning-alt-03','v1','P1','learning','draft','Exact trigonometric values','Точные тригонометрические значения','Aniq trigonometrik qiymatlar'),
(35423,4813,'P1-TRI-03-learning-alt-03','v1','P1','learning','draft','Inverse trigonometric principal values','Главные значения обратных тригонометрических функций','Teskari trigonometrik funksiyalarning bosh qiymatlari'),
(35424,4813,'P1-TRI-04-learning-alt-03','v1','P1','learning','draft','Trigonometric identities','Тригонометрические тождества','Trigonometrik ayniyatlar'),
(35425,4813,'P1-TRI-05-learning-alt-03','v1','P1','learning','draft','Trigonometric equations','Тригонометрические уравнения','Trigonometrik tenglamalar'),
(35426,4813,'P1-SER-01-learning-alt-03','v1','P1','learning','draft','Binomial expansion','Биномиальное разложение','Binomial yoyilma'),
(35427,4813,'P1-SER-02-learning-alt-03','v1','P1','learning','draft','Arithmetic and geometric progressions','Арифметические и геометрические прогрессии','Arifmetik va geometrik progressiyalar'),
(35428,4813,'P1-DIF-01-learning-alt-03','v1','P1','learning','draft','Derivative as gradient and rate','Производная как градиент и скорость изменения','Hosila gradient va o‘zgarish tezligi sifatida')
on conflict(id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
(35421,1,'P1CIR03-A01',null::bigint,'P1-CIR-03'),
(35421,2,'P1CIR03-A02',null::bigint,'P1-CIR-03'),
(35421,3,'P1CIR03-A03',null::bigint,'P1-CIR-03'),
(35421,4,null,15638,'P1-CIR-03'),
(35422,1,'P1TRI02-A01',null::bigint,'P1-TRI-02'),
(35422,2,'P1TRI02-A02',null::bigint,'P1-TRI-02'),
(35422,3,'P1TRI02-A03',null::bigint,'P1-TRI-02'),
(35422,4,null,15639,'P1-TRI-02'),
(35423,1,'P1TRI03-A01',null::bigint,'P1-TRI-03'),
(35423,2,'P1TRI03-A02',null::bigint,'P1-TRI-03'),
(35423,3,'P1TRI03-A03',null::bigint,'P1-TRI-03'),
(35423,4,null,15640,'P1-TRI-03'),
(35424,1,'P1TRI04-A01',null::bigint,'P1-TRI-04'),
(35424,2,'P1TRI04-A02',null::bigint,'P1-TRI-04'),
(35424,3,'P1TRI04-A03',null::bigint,'P1-TRI-04'),
(35424,4,null,15641,'P1-TRI-04'),
(35425,1,'P1TRI05-A01',null::bigint,'P1-TRI-05'),
(35425,2,'P1TRI05-A02',null::bigint,'P1-TRI-05'),
(35425,3,'P1TRI05-A03',null::bigint,'P1-TRI-05'),
(35425,4,null,15642,'P1-TRI-05'),
(35426,1,'P1SER01-A01',null::bigint,'P1-SER-01'),
(35426,2,'P1SER01-A02',null::bigint,'P1-SER-01'),
(35426,3,'P1SER01-A03',null::bigint,'P1-SER-01'),
(35426,4,null,15643,'P1-SER-01'),
(35427,1,'P1SER02-A01',null::bigint,'P1-SER-02'),
(35427,2,'P1SER02-A02',null::bigint,'P1-SER-02'),
(35427,3,'P1SER02-A03',null::bigint,'P1-SER-02'),
(35427,4,null,15644,'P1-SER-02'),
(35428,1,'P1DIF01-A01',null::bigint,'P1-DIF-01'),
(35428,2,'P1DIF01-A02',null::bigint,'P1-DIF-01'),
(35428,3,'P1DIF01-A03',null::bigint,'P1-DIF-01'),
(35428,4,null,15645,'P1-DIF-01')
)
insert into private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select i.assessment_id,i.item_order,qn.id,i.written_id,i.skill_code,
 case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions qn on i.content_key is not null
 and qn.book_ref='ExamPrep:P1:p1_aw13_16_alt_learning_draft_v1:'||i.content_key
on conflict(assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select status from private.exam_prep_content_versions where id=4813)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4813 and lifecycle_state='draft' and reserve_role='learning')<>24
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4813 and lifecycle_state='draft')<>8
     or (select count(*) from private.exam_prep_assessments where content_version_id=4813 and status='draft' and assessment_type='learning')<>8
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4813)<>32
  then raise exception 'aw13_16_alt_p1_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4813 and (
    m.exposure_state<>'withheld' or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or qn.is_active or qn.quality_status<>'draft'
    or nullif(btrim(qn.question_text_en),'') is null or nullif(btrim(qn.question_text_ru),'') is null or nullif(btrim(qn.question_text_uz),'') is null
    or nullif(btrim(qn.explanation_en),'') is null or nullif(btrim(qn.explanation_ru),'') is null or nullif(btrim(qn.explanation_uz),'') is null
  );
  if v_bad<>0 then raise exception 'aw13_16_alt_p1_draft exposure/QA boundary rows=%',v_bad; end if;

  select
    count(*) filter(where qn.correct_answer='A'),
    count(*) filter(where qn.correct_answer='B'),
    count(*) filter(where qn.correct_answer='C'),
    count(*) filter(where qn.correct_answer='D'),
    count(*) filter(where qn.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4813;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,4,4,8) then
    raise exception 'aw13_16_alt_p1_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions qn on qn.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4813
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4813
      and lower(regexp_replace(qn.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw13_16_alt_p1_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4813)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4813)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4813)
  then raise exception 'aw13_16_alt_p1_draft unexpected history'; end if;
end
$postcheck$;

commit;
