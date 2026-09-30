-- AW13-16 supplemental learning pack draft for P1.
-- Derived runway slice: closes remaining E1/E2 P1 skills before E3 expansion.
-- DRAFT ONLY: no learner exposure, self-approval or publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw13_16_alt_p1_draft canonical program missing'; end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4813 and content_version<>'p1_aw13_16_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15638 and 15644 and content_version_id<>4813)
     or exists(select 1 from private.exam_prep_assessments where id between 35421 and 35427 and content_version_id<>4813)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59270 and 59290 and content_version_id<>4813)
  then raise exception 'aw13_16_alt_p1_draft reserved id collision'; end if;

  -- These seven skills are the remaining P1 E2 runway after AW1-12.
  if (select count(*) from private.exam_prep_question_content_meta m
      join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-COO-05','P1-COO-06','P1-CIR-03','P1-TRI-02','P1-TRI-03','P1-TRI-04','P1-TRI-05')
        and m.reserve_role='learning')<>21
  then raise exception 'aw13_16_alt_p1_draft baseline learning depth changed'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4813,pv.id,'p1_aw13_16_alt_learning_draft_v1','P1',
 'P1 AW13-16 additional learning pack draft v1','draft',
 'Original iClub-authored learning content. The canonical Cambridge 9709 map and Complete Pure Mathematics 1 mappings define learning objectives only; no protected question, solution, diagram or mark-scheme wording is copied. Independent academic, EN/RU/UZ, technical and copyright QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,topic,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P1COO05-B01','P1-COO-05','P1 Coordinate geometry','medium','mcq','The circle x²+y²−6x−4y−12=0 is intersected by the y-axis. Which are the intersection points?','["(0,−2) and (0,6)","(−2,0) and (6,0)","(0,2) and (0,−6)","(2,0) and (−6,0)"]','A','On the y-axis x=0. Then y²−4y−12=0=(y−6)(y+2), so y=6 or −2.','Окружность x²+y²−6x−4y−12=0 пересекается с осью y. Каковы точки пересечения?','["(0,−2) и (0,6)","(−2,0) и (6,0)","(0,2) и (0,−6)","(2,0) и (−6,0)"]','На оси y имеем x=0. Тогда y²−4y−12=0=(y−6)(y+2), поэтому y=6 или −2.','x²+y²−6x−4y−12=0 aylana y o‘qi bilan kesishadi. Kesishish nuqtalari qaysi?','["(0,−2) va (0,6)","(−2,0) va (6,0)","(0,2) va (0,−6)","(2,0) va (−6,0)"]','y o‘qida x=0. Shunda y²−4y−12=0=(y−6)(y+2), demak y=6 yoki −2.',70),
('P1COO05-B02','P1-COO-05','P1 Coordinate geometry','hard','mcq','The line x+y=7 cuts the circle x²+y²=25 at two points. Which are the intersection points?','["(2,5) and (5,2)","(3,4) and (4,3)","(−3,−4) and (−4,−3)","(1,6) and (6,1)"]','B','Since (x+y)²=x²+y²+2xy, 49=25+2xy gives xy=12. The numbers with sum 7 and product 12 are 3 and 4.','Прямая x+y=7 пересекает окружность x²+y²=25 в двух точках. Каковы точки пересечения?','["(2,5) и (5,2)","(3,4) и (4,3)","(−3,−4) и (−4,−3)","(1,6) и (6,1)"]','Так как (x+y)²=x²+y²+2xy, получаем 49=25+2xy и xy=12. Числа с суммой 7 и произведением 12 — это 3 и 4.','x+y=7 chiziq x²+y²=25 aylanani ikki nuqtada kesadi. Kesishish nuqtalari qaysi?','["(2,5) va (5,2)","(3,4) va (4,3)","(−3,−4) va (−4,−3)","(1,6) va (6,1)"]','(x+y)²=x²+y²+2xy bo‘lgani uchun 49=25+2xy va xy=12. Yig‘indisi 7, ko‘paytmasi 12 bo‘lgan sonlar 3 va 4.',85),
('P1COO05-B03','P1-COO-05','P1 Coordinate geometry','medium','input','The line x=5 cuts the circle (x−2)²+(y+1)²=25 at two points. Enter the distance between the two intersection points.','[]','8','Substitute x=5: 9+(y+1)²=25, so y=3 or −5. The vertical distance is 3−(−5)=8.','Прямая x=5 пересекает окружность (x−2)²+(y+1)²=25 в двух точках. Введите расстояние между точками пересечения.','[]','Подставляем x=5: 9+(y+1)²=25, поэтому y=3 или −5. Вертикальное расстояние равно 3−(−5)=8.','x=5 chiziq (x−2)²+(y+1)²=25 aylanani ikki nuqtada kesadi. Kesishish nuqtalari orasidagi masofani kiriting.','[]','x=5 ni qo‘yamiz: 9+(y+1)²=25, demak y=3 yoki −5. Vertikal masofa 3−(−5)=8.',75),
('P1COO06-B01','P1-COO-06','P1 Coordinate geometry','medium','mcq','A circle has centre (3,−2) and radius 4. Which pair gives the two vertical tangent lines?','["x=−4 and x=4","x=−1 and x=4","x=−1 and x=7","x=3 and x=7"]','C','Vertical tangents are one radius to the left and right of the centre: x=3−4=−1 and x=3+4=7.','Окружность имеет центр (3,−2) и радиус 4. Какая пара задаёт две вертикальные касательные?','["x=−4 и x=4","x=−1 и x=4","x=−1 и x=7","x=3 и x=7"]','Вертикальные касательные находятся на один радиус слева и справа от центра: x=3−4=−1 и x=3+4=7.','Aylana markazi (3,−2), radiusi 4. Qaysi juftlik ikkita vertikal urinma chiziqni beradi?','["x=−4 va x=4","x=−1 va x=4","x=−1 va x=7","x=3 va x=7"]','Vertikal urinmalar markazdan bir radius chap va o‘ngda: x=3−4=−1 va x=3+4=7.',70),
('P1COO06-B02','P1-COO-06','P1 Coordinate geometry','hard','mcq','The line y=x+c is tangent to the circle (x−2)²+(y+1)²=9. Which values of c are possible?','["3±3√2","−3±√2","3±√2","−3±3√2"]','D','Write the line as x−y+c=0. The distance from centre (2,−1) to the line is |3+c|/√2. Tangency requires |3+c|/√2=3, so c=−3±3√2.','Прямая y=x+c касается окружности (x−2)²+(y+1)²=9. Какие значения c возможны?','["3±3√2","−3±√2","3±√2","−3±3√2"]','Запишем прямую как x−y+c=0. Расстояние от центра (2,−1) до прямой равно |3+c|/√2. Для касания |3+c|/√2=3, поэтому c=−3±3√2.','y=x+c chiziq (x−2)²+(y+1)²=9 aylanaga urinadi. c ning qaysi qiymatlari mumkin?','["3±3√2","−3±√2","3±√2","−3±3√2"]','Chiziqni x−y+c=0 ko‘rinishda yozamiz. Markaz (2,−1) dan chiziqqacha masofa |3+c|/√2. Urinish uchun |3+c|/√2=3, demak c=−3±3√2.',95),
('P1COO06-B03','P1-COO-06','P1 Coordinate geometry','hard','input','The line y=mx+10 is tangent to the circle x²+y²=20. Enter the positive value of m.','[]','2','The distance from the origin to mx−y+10=0 is 10/√(m²+1). Set this equal to √20. Then 100=20(m²+1), so m²=4 and the positive value is 2.','Прямая y=mx+10 касается окружности x²+y²=20. Введите положительное значение m.','[]','Расстояние от начала координат до mx−y+10=0 равно 10/√(m²+1). Приравниваем его к √20. Тогда 100=20(m²+1), поэтому m²=4 и положительное значение равно 2.','y=mx+10 chiziq x²+y²=20 aylanaga urinadi. m ning musbat qiymatini kiriting.','[]','Koordinata boshidan mx−y+10=0 chiziqqacha masofa 10/√(m²+1). Uni √20 ga tenglaymiz. 100=20(m²+1), demak m²=4 va musbat qiymat 2.',100),
('P1CIR03-B01','P1-CIR-03','P1 Circular measure','medium','mcq','A sector has radius 7 cm and angle 0.8 radians. Find its area.','["19.6 cm²","39.2 cm²","5.6 cm²","24.5 cm²"]','A','Sector area is ½r²θ=½×49×0.8=19.6 cm².','Сектор имеет радиус 7 см и угол 0,8 радиана. Найдите его площадь.','["19,6 см²","39,2 см²","5,6 см²","24,5 см²"]','Площадь сектора равна ½r²θ=½×49×0,8=19,6 см².','Sektor radiusi 7 cm va burchagi 0.8 radian. Uning yuzini toping.','["19.6 cm²","39.2 cm²","5.6 cm²","24.5 cm²"]','Sektor yuzi ½r²θ=½×49×0.8=19.6 cm².',70),
('P1CIR03-B02','P1-CIR-03','P1 Circular measure','medium','mcq','A sector has area 54 cm² and angle 1.5 radians. Find its radius.','["6 cm","6√2 cm","9 cm","3√2 cm"]','B','54=½r²(1.5)=0.75r², so r²=72 and r=6√2 cm.','Площадь сектора равна 54 см², угол — 1,5 радиана. Найдите радиус.','["6 см","6√2 см","9 см","3√2 см"]','54=½r²(1,5)=0,75r², поэтому r²=72 и r=6√2 см.','Sektor yuzi 54 cm², burchagi 1.5 radian. Radiusni toping.','["6 cm","6√2 cm","9 cm","3√2 cm"]','54=½r²(1.5)=0.75r², demak r²=72 va r=6√2 cm.',80),
('P1CIR03-B03','P1-CIR-03','P1 Circular measure','hard','input','An annular sector has outer radius 8 cm, inner radius 5 cm and angle 1.2 radians. Enter its area in cm².','[]','23.4','The area is ½(8²−5²)(1.2)=½(39)(1.2)=23.4 cm².','Кольцевой сектор имеет внешний радиус 8 см, внутренний радиус 5 см и угол 1,2 радиана. Введите его площадь в см².','[]','Площадь равна ½(8²−5²)(1,2)=½(39)(1,2)=23,4 см².','Halqasimon sektorning tashqi radiusi 8 cm, ichki radiusi 5 cm va burchagi 1.2 radian. Yuzini cm² da kiriting.','[]','Yuzi ½(8²−5²)(1.2)=½(39)(1.2)=23.4 cm².',90),
('P1TRI02-B01','P1-TRI-02','P1 Trigonometry','medium','mcq','Find the exact value of cos 150°.','["√3/2","1/2","−√3/2","−1/2"]','C','150°=180°−30°. Cosine is negative in quadrant II, so cos150°=−cos30°=−√3/2.','Найдите точное значение cos 150°.','["√3/2","1/2","−√3/2","−1/2"]','150°=180°−30°. Во II четверти косинус отрицателен, поэтому cos150°=−cos30°=−√3/2.','cos 150° ning aniq qiymatini toping.','["√3/2","1/2","−√3/2","−1/2"]','150°=180°−30°. II chorakda kosinus manfiy, demak cos150°=−cos30°=−√3/2.',60),
('P1TRI02-B02','P1-TRI-02','P1 Trigonometry','medium','mcq','Find the exact value of tan 330°.','["√3","1/√3","−√3","−√3/3"]','D','330°=360°−30°. Tangent is negative in quadrant IV, so tan330°=−tan30°=−1/√3=−√3/3.','Найдите точное значение tan 330°.','["√3","1/√3","−√3","−√3/3"]','330°=360°−30°. В IV четверти тангенс отрицателен, поэтому tan330°=−tan30°=−1/√3=−√3/3.','tan 330° ning aniq qiymatini toping.','["√3","1/√3","−√3","−√3/3"]','330°=360°−30°. IV chorakda tangens manfiy, demak tan330°=−tan30°=−1/√3=−√3/3.',60),
('P1TRI02-B03','P1-TRI-02','P1 Trigonometry','medium','input','Evaluate exactly 4sin²30°+2cos180°.','[]','-1','sin30°=1/2 and cos180°=−1. Hence 4(1/2)²+2(−1)=1−2=−1.','Вычислите точно 4sin²30°+2cos180°.','[]','sin30°=1/2 и cos180°=−1. Поэтому 4(1/2)²+2(−1)=1−2=−1.','4sin²30°+2cos180° ni aniq hisoblang.','[]','sin30°=1/2 va cos180°=−1. Shuning uchun 4(1/2)²+2(−1)=1−2=−1.',65),
('P1TRI03-B01','P1-TRI-03','P1 Trigonometry','medium','mcq','Using principal values in degrees, evaluate sin⁻¹(−√2/2).','["−45°","45°","135°","315°"]','A','The principal range of sin⁻¹ is −90° to 90°. The angle in that range with sine −√2/2 is −45°.','Используя главные значения в градусах, вычислите sin⁻¹(−√2/2).','["−45°","45°","135°","315°"]','Главный диапазон sin⁻¹ — от −90° до 90°. В этом диапазоне синус −√2/2 имеет угол −45°.','Graduslarda asosiy qiymatlardan foydalanib sin⁻¹(−√2/2) ni hisoblang.','["−45°","45°","135°","315°"]','sin⁻¹ ning asosiy oralig‘i −90° dan 90° gacha. Shu oraliqda sinusi −√2/2 bo‘lgan burchak −45°.',65),
('P1TRI03-B02','P1-TRI-03','P1 Trigonometry','medium','mcq','Using principal values in degrees, evaluate cos⁻¹(−√2/2).','["45°","135°","225°","−135°"]','B','The principal range of cos⁻¹ is 0° to 180°. The angle in that range with cosine −√2/2 is 135°.','Используя главные значения в градусах, вычислите cos⁻¹(−√2/2).','["45°","135°","225°","−135°"]','Главный диапазон cos⁻¹ — от 0° до 180°. В этом диапазоне косинус −√2/2 имеет угол 135°.','Graduslarda asosiy qiymatlardan foydalanib cos⁻¹(−√2/2) ni hisoblang.','["45°","135°","225°","−135°"]','cos⁻¹ ning asosiy oralig‘i 0° dan 180° gacha. Shu oraliqda kosinusi −√2/2 bo‘lgan burchak 135°.',65),
('P1TRI03-B03','P1-TRI-03','P1 Trigonometry','medium','input','Using principal values in degrees, evaluate tan⁻¹(−√3/3). Enter the angle in degrees.','[]','-30','The principal range of tan⁻¹ is −90° to 90°. Since tan30°=√3/3, the required principal value is −30°.','Используя главные значения в градусах, вычислите tan⁻¹(−√3/3). Введите угол в градусах.','[]','Главный диапазон tan⁻¹ — от −90° до 90°. Так как tan30°=√3/3, требуемое главное значение равно −30°.','Graduslarda asosiy qiymatlardan foydalanib tan⁻¹(−√3/3) ni hisoblang. Burchakni gradusda kiriting.','[]','tan⁻¹ ning asosiy oralig‘i −90° dan 90° gacha. tan30°=√3/3 bo‘lgani uchun asosiy qiymat −30°.',65),
('P1TRI04-B01','P1-TRI-04','P1 Trigonometry','medium','mcq','For cos x≠0, simplify (1−sin²x)/cos x.','["sin x","tan x","cos x","1"]','C','Using sin²x+cos²x=1, the numerator is cos²x. Dividing by cos x gives cos x.','При cos x≠0 упростите (1−sin²x)/cos x.','["sin x","tan x","cos x","1"]','По тождеству sin²x+cos²x=1 числитель равен cos²x. Деление на cos x даёт cos x.','cos x≠0 bo‘lganda (1−sin²x)/cos x ni soddalashtiring.','["sin x","tan x","cos x","1"]','sin²x+cos²x=1 dan surat cos²x. cos x ga bo‘lsak cos x hosil bo‘ladi.',70),
('P1TRI04-B02','P1-TRI-04','P1 Trigonometry','medium','mcq','For cos x≠0, simplify tan x cos x.','["cos x","1","tan x","sin x"]','D','tan x=sin x/cos x, so tan x cos x=sin x.','При cos x≠0 упростите tan x cos x.','["cos x","1","tan x","sin x"]','tan x=sin x/cos x, поэтому tan x cos x=sin x.','cos x≠0 bo‘lganda tan x cos x ni soddalashtiring.','["cos x","1","tan x","sin x"]','tan x=sin x/cos x, shuning uchun tan x cos x=sin x.',65),
('P1TRI04-B03','P1-TRI-04','P1 Trigonometry','medium','input','An acute angle x satisfies sin x=5/13. Enter the value of 13cos x.','[]','12','Since x is acute, cos x is positive. cos²x=1−25/169=144/169, so cos x=12/13 and 13cos x=12.','Острый угол x удовлетворяет sin x=5/13. Введите значение 13cos x.','[]','Так как x острый, cos x положителен. cos²x=1−25/169=144/169, поэтому cos x=12/13 и 13cos x=12.','O‘tkir x burchak uchun sin x=5/13. 13cos x qiymatini kiriting.','[]','x o‘tkir bo‘lgani uchun cos x musbat. cos²x=1−25/169=144/169, demak cos x=12/13 va 13cos x=12.',70),
('P1TRI05-B01','P1-TRI-05','P1 Trigonometry','medium','mcq','Solve sin θ=−1/2 for 0°≤θ<360°.','["210°, 330°","30°, 150°","150°, 210°","30°, 330°"]','A','The reference angle is 30°. Sine is negative in quadrants III and IV, giving 210° and 330°.','Решите sin θ=−1/2 при 0°≤θ<360°.','["210°, 330°","30°, 150°","150°, 210°","30°, 330°"]','Опорный угол 30°. Синус отрицателен в III и IV четвертях, поэтому θ=210° и 330°.','0°≤θ<360° da sin θ=−1/2 ni yeching.','["210°, 330°","30°, 150°","150°, 210°","30°, 330°"]','Tayanch burchak 30°. Sinus III va IV choraklarda manfiy, demak θ=210° va 330°.',75),
('P1TRI05-B02','P1-TRI-05','P1 Trigonometry','medium','mcq','Solve 2cos θ+√2=0 for 0°≤θ<360°.','["45°, 315°","135°, 225°","45°, 225°","135°, 315°"]','B','cosθ=−√2/2. The reference angle is 45°, and cosine is negative in quadrants II and III, giving 135° and 225°.','Решите 2cos θ+√2=0 при 0°≤θ<360°.','["45°, 315°","135°, 225°","45°, 225°","135°, 315°"]','cosθ=−√2/2. Опорный угол 45°, косинус отрицателен во II и III четвертях, поэтому θ=135° и 225°.','0°≤θ<360° da 2cos θ+√2=0 ni yeching.','["45°, 315°","135°, 225°","45°, 225°","135°, 315°"]','cosθ=−√2/2. Tayanch burchak 45°, kosinus II va III choraklarda manfiy, demak θ=135° va 225°.',80),
('P1TRI05-B03','P1-TRI-05','P1 Trigonometry','medium','input','How many solutions does tan θ=1/√3 have for 0°≤θ≤720°?','[]','4','tanθ=1/√3 at θ=30°+180°k. In the interval the solutions are 30°, 210°, 390° and 570°, so there are 4.','Сколько решений имеет tan θ=1/√3 при 0°≤θ≤720°?','[]','tanθ=1/√3 при θ=30°+180°k. В данном промежутке решения: 30°, 210°, 390° и 570°, всего 4.','0°≤θ≤720° da tan θ=1/√3 tenglama nechta yechimga ega?','[]','tanθ=1/√3 uchun θ=30°+180°k. Oraliqdagi yechimlar 30°, 210°, 390° va 570°, jami 4.',85)
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
(15638,4813,'P1COO05-BW14','P1','P1-COO-05','{}','v1','The circle x²+y²−4x+2y−20=0 is cut by the line x+y=6. Find both intersection points. Then find the midpoint and length of the chord joining them. Show the substitution or elimination clearly and verify one intersection in the original equations.','Окружность x²+y²−4x+2y−20=0 пересекается прямой x+y=6. Найдите обе точки пересечения. Затем найдите середину и длину хорды, соединяющей эти точки. Чётко покажите подстановку или исключение и проверьте одну точку в исходных уравнениях.','x²+y²−4x+2y−20=0 aylana x+y=6 chiziq bilan kesishadi. Ikkala kesishish nuqtasini toping. So‘ng ularni tutashtiruvchi vatar o‘rta nuqtasi va uzunligini toping. Almashtirish yoki yo‘qotishni aniq ko‘rsating va bitta nuqtani dastlabki tenglamalarda tekshiring.','{"criteria":[{"id":"equations","rule":"Reduces the simultaneous equations to a correct quadratic.","marks":1},{"id":"points","rule":"Finds both intersection points correctly.","marks":2},{"id":"midpoint","rule":"Finds the chord midpoint correctly.","marks":1},{"id":"length","rule":"Finds the chord length correctly.","marks":1},{"id":"verify","rule":"Verifies an intersection in both original equations.","marks":1}],"max_marks":6}'::jsonb,'Use x+y=6 to express one variable, substitute into the circle, and keep both roots. After finding both points, use midpoint and distance formulas.','Из x+y=6 выразите одну переменную и подставьте в уравнение окружности, сохранив оба корня. После нахождения точек используйте формулы середины и расстояния.','x+y=6 dan bir o‘zgaruvchini ifodalab, aylana tenglamasiga qo‘ying va ikkala ildizni saqlang. Nuqtalarni topgach, o‘rta nuqta va masofa formulalaridan foydalaning.','draft','pending','pending','pending','pending'),
(15639,4813,'P1COO06-BW14','P1','P1-COO-06','{}','v1','The line y=x+c is tangent to the circle (x−1)²+(y+2)²=8. Find all possible values of c. First use substitution and a zero discriminant; then verify your result using the perpendicular distance from the centre to the line.','Прямая y=x+c касается окружности (x−1)²+(y+2)²=8. Найдите все возможные значения c. Сначала используйте подстановку и нулевой дискриминант, затем проверьте результат по перпендикулярному расстоянию от центра до прямой.','y=x+c chiziq (x−1)²+(y+2)²=8 aylanaga urinadi. c ning barcha mumkin bo‘lgan qiymatlarini toping. Avval almashtirish va nol diskriminantdan foydalaning, so‘ng markazdan chiziqqacha perpendikulyar masofa bilan natijani tekshiring.','{"criteria":[{"id":"substitute","rule":"Forms the quadratic produced by substitution.","marks":1},{"id":"discriminant","rule":"Sets the discriminant equal to zero.","marks":1},{"id":"values","rule":"Finds all valid values of c.","marks":2},{"id":"distance","rule":"Uses the centre-to-line distance correctly.","marks":1},{"id":"verify","rule":"Shows the distance result agrees with the discriminant result.","marks":1}],"max_marks":6}'::jsonb,'Keep c symbolic after substitution. Tangency means exactly one intersection, so the quadratic must have discriminant zero.','После подстановки оставьте c параметром. Касание означает ровно одну точку пересечения, поэтому дискриминант квадратного уравнения равен нулю.','Almashtirishdan keyin c ni parametr sifatida qoldiring. Urinish bitta kesishish nuqtasini bildiradi, shuning uchun kvadrat tenglama diskriminanti nol bo‘lishi kerak.','draft','pending','pending','pending','pending'),
(15640,4813,'P1CIR03-BW14','P1','P1-CIR-03','{}','v1','A sector has radius 10 cm and angle 1.2 radians. Find (a) the sector area, (b) the area of the triangle formed by the two radii and the chord, and hence (c) the minor-segment area. A concentric sector of radius 6 cm with the same angle is then removed; find the remaining annular-sector area.','Сектор имеет радиус 10 см и угол 1,2 радиана. Найдите (a) площадь сектора, (b) площадь треугольника, образованного двумя радиусами и хордой, и затем (c) площадь малого сегмента. Затем удаляют концентрический сектор радиуса 6 см с тем же углом; найдите площадь оставшегося кольцевого сектора.','Sektor radiusi 10 cm va burchagi 1.2 radian. (a) sektor yuzini, (b) ikki radius va vatar hosil qilgan uchburchak yuzini, so‘ng (c) kichik segment yuzini toping. Keyin xuddi shu burchakli radiusi 6 cm bo‘lgan konsentrik sektor olib tashlanadi; qolgan halqasimon sektor yuzini toping.','{"criteria":[{"id":"sector","rule":"Uses ½r²θ to find the sector area.","marks":1},{"id":"triangle","rule":"Uses ½r²sinθ for the triangle area.","marks":2},{"id":"segment","rule":"Subtracts triangle area from sector area correctly.","marks":1},{"id":"annular","rule":"Finds ½(10²−6²)(1.2).","marks":1},{"id":"working","rule":"Keeps radians, units and method clear.","marks":1}],"max_marks":6}'::jsonb,'Use ½r²θ for a sector and ½r²sinθ for the isosceles triangle. The segment is sector minus triangle.','Используйте ½r²θ для сектора и ½r²sinθ для равнобедренного треугольника. Площадь сегмента равна площади сектора минус площадь треугольника.','Sektor uchun ½r²θ, teng yonli uchburchak uchun ½r²sinθ dan foydalaning. Segment yuzi sektor yuzidan uchburchak yuzini ayirish bilan topiladi.','draft','pending','pending','pending','pending'),
(15641,4813,'P1TRI02-BW14','P1','P1-TRI-02','{}','v1','Without a calculator, find the exact values of cos150°, sin225° and tan330°. Then evaluate exactly 2cos150°−tan225°. For each single angle, state the reference angle and the quadrant sign.','Без калькулятора найдите точные значения cos150°, sin225° и tan330°. Затем точно вычислите 2cos150°−tan225°. Для каждого отдельного угла укажите опорный угол и знак в четверти.','Kalkulyatorsiz cos150°, sin225° va tan330° ning aniq qiymatlarini toping. So‘ng 2cos150°−tan225° ni aniq hisoblang. Har bir burchak uchun tayanch burchak va chorakdagi ishorani ko‘rsating.','{"criteria":[{"id":"cos","rule":"Finds cos150°=−√3/2 with correct quadrant reasoning.","marks":1},{"id":"sin","rule":"Finds sin225°=−√2/2 with correct quadrant reasoning.","marks":1},{"id":"tan","rule":"Finds tan330°=−√3/3 with correct quadrant reasoning.","marks":1},{"id":"expression","rule":"Evaluates 2cos150°−tan225°=−√3−1.","marks":2},{"id":"reason","rule":"States appropriate reference angles/signs.","marks":1}],"max_marks":6}'::jsonb,'Reduce each angle to a standard reference angle and determine the sign from the quadrant before substituting exact values.','Сведите каждый угол к стандартному опорному углу и определите знак по четверти до подстановки точных значений.','Har bir burchakni standart tayanch burchakka keltiring va aniq qiymatni qo‘yishdan oldin chorak bo‘yicha ishorani aniqlang.','draft','pending','pending','pending','pending'),
(15642,4813,'P1TRI03-BW14','P1','P1-TRI-03','{}','v1','Using degrees, state the principal-value ranges for sin⁻¹, cos⁻¹ and tan⁻¹. Then evaluate sin⁻¹(−√2/2), cos⁻¹(√3/2) and tan⁻¹(−√3/3). Explain why the principal inverse value is only one angle and is not automatically the complete solution set of a trigonometric equation.','В градусах укажите диапазоны главных значений sin⁻¹, cos⁻¹ и tan⁻¹. Затем вычислите sin⁻¹(−√2/2), cos⁻¹(√3/2) и tan⁻¹(−√3/3). Объясните, почему главное значение обратной функции — это только один угол и оно не является автоматически полным множеством решений тригонометрического уравнения.','Graduslarda sin⁻¹, cos⁻¹ va tan⁻¹ ning asosiy qiymat oraliqlarini yozing. So‘ng sin⁻¹(−√2/2), cos⁻¹(√3/2) va tan⁻¹(−√3/3) ni hisoblang. Nega teskari funksiyaning asosiy qiymati faqat bitta burchak bo‘lib, trigonometrik tenglamaning to‘liq yechimlar to‘plami emasligini tushuntiring.','{"criteria":[{"id":"ranges","rule":"States the three principal-value ranges correctly.","marks":2},{"id":"asin","rule":"Finds −45°.","marks":1},{"id":"acos","rule":"Finds 30°.","marks":1},{"id":"atan","rule":"Finds −30°.","marks":1},{"id":"explain","rule":"Explains principal inverse output versus full periodic equation solutions.","marks":1}],"max_marks":6}'::jsonb,'Check the output range of each inverse function before choosing an angle. Treat solving a trigonometric equation as a separate periodic/quadrant step.','Перед выбором угла проверьте диапазон значений каждой обратной функции. Решение тригонометрического уравнения рассматривайте как отдельный шаг с периодичностью и четвертями.','Burchakni tanlashdan oldin har bir teskari funksiyaning qiymatlar oralig‘ini tekshiring. Trigonometrik tenglamani yechishni davriylik va choraklar bilan alohida qadam sifatida ko‘ring.','draft','pending','pending','pending','pending'),
(15643,4813,'P1TRI04-BW14','P1','P1-TRI-04','{}','v1','Using only sin²x+cos²x=1 and tanx=sinx/cosx, simplify (1−sin²x)/(cos x) and (1−cos²x)/(sin x cos x), stating all denominator restrictions. Then, if x is acute and sinx=8/17, find cosx exactly.','Используя только sin²x+cos²x=1 и tanx=sinx/cosx, упростите (1−sin²x)/(cos x) и (1−cos²x)/(sin x cos x), указав все ограничения знаменателей. Затем, если x острый и sinx=8/17, найдите cosx точно.','Faqat sin²x+cos²x=1 va tanx=sinx/cosx dan foydalanib, (1−sin²x)/(cos x) va (1−cos²x)/(sin x cos x) ni soddalashtiring, barcha maxraj cheklovlarini yozing. So‘ng x o‘tkir va sinx=8/17 bo‘lsa, cosx ni aniq toping.','{"criteria":[{"id":"first","rule":"Simplifies the first expression to cos x.","marks":1},{"id":"second","rule":"Simplifies the second expression to tan x.","marks":2},{"id":"restrictions","rule":"States the required non-zero denominator restrictions.","marks":1},{"id":"exact","rule":"Finds cosx=15/17.","marks":1},{"id":"sign","rule":"Uses the acute-angle condition to choose the positive root.","marks":1}],"max_marks":6}'::jsonb,'Replace 1−sin²x or 1−cos²x using the Pythagorean identity before cancelling, and record what must be non-zero.','Замените 1−sin²x или 1−cos²x по основному тождеству до сокращения и запишите, что должно быть ненулевым.','Qisqartirishdan oldin 1−sin²x yoki 1−cos²x ni Pifagor ayniyati bilan almashtiring va qaysi ifodalar nol bo‘lmasligini yozing.','draft','pending','pending','pending','pending'),
(15644,4813,'P1TRI05-BW14','P1','P1-TRI-05','{}','v1','Solve 2cos²θ+sinθ−1=0 for 0°≤θ<360°. Use sin²θ+cos²θ=1 to reduce the equation to a quadratic in sinθ, reject any impossible value, and list every solution in the interval. Verify the final angles in the original equation.','Решите 2cos²θ+sinθ−1=0 при 0°≤θ<360°. Используйте sin²θ+cos²θ=1, чтобы свести уравнение к квадратному относительно sinθ, отбросьте недопустимое значение и перечислите все решения на промежутке. Проверьте конечные углы в исходном уравнении.','0°≤θ<360° da 2cos²θ+sinθ−1=0 tenglamani yeching. Tenglamani sinθ bo‘yicha kvadrat tenglamaga keltirish uchun sin²θ+cos²θ=1 dan foydalaning, mumkin bo‘lmagan qiymatni rad eting va oraliqdagi barcha yechimlarni yozing. Yakuniy burchaklarni dastlabki tenglamada tekshiring.','{"criteria":[{"id":"reduce","rule":"Obtains 2sin²θ−sinθ−1=0 or equivalent.","marks":1},{"id":"factor","rule":"Factors to (2sinθ+1)(sinθ−1)=0.","marks":1},{"id":"values","rule":"Finds sinθ=−1/2 or 1.","marks":1},{"id":"solutions","rule":"Lists θ=90°,210°,330°.","marks":2},{"id":"verify","rule":"Checks the final angles in the original equation.","marks":1}],"max_marks":6}'::jsonb,'Replace cos²θ by 1−sin²θ, solve the quadratic for sinθ, then use reference angles and quadrants to obtain all angles.','Замените cos²θ на 1−sin²θ, решите квадратное уравнение относительно sinθ, затем используйте опорные углы и четверти для всех углов.','cos²θ ni 1−sin²θ bilan almashtiring, sinθ bo‘yicha kvadrat tenglamani yeching, so‘ng barcha burchaklarni topish uchun tayanch burchak va choraklardan foydalaning.','draft','pending','pending','pending','pending')
on conflict(id) do nothing;

with src(content_key,skill_code,meta_id) as (values
('P1COO05-B01','P1-COO-05',59270),
('P1COO05-B02','P1-COO-05',59271),
('P1COO05-B03','P1-COO-05',59272),
('P1COO06-B01','P1-COO-06',59273),
('P1COO06-B02','P1-COO-06',59274),
('P1COO06-B03','P1-COO-06',59275),
('P1CIR03-B01','P1-CIR-03',59276),
('P1CIR03-B02','P1-CIR-03',59277),
('P1CIR03-B03','P1-CIR-03',59278),
('P1TRI02-B01','P1-TRI-02',59279),
('P1TRI02-B02','P1-TRI-02',59280),
('P1TRI02-B03','P1-TRI-02',59281),
('P1TRI03-B01','P1-TRI-03',59282),
('P1TRI03-B02','P1-TRI-03',59283),
('P1TRI03-B03','P1-TRI-03',59284),
('P1TRI04-B01','P1-TRI-04',59285),
('P1TRI04-B02','P1-TRI-04',59286),
('P1TRI04-B03','P1-TRI-04',59287),
('P1TRI05-B01','P1-TRI-05',59288),
('P1TRI05-B02','P1-TRI-05',59289),
('P1TRI05-B03','P1-TRI-05',59290)
), cv as (select id from private.exam_prep_content_versions where id=4813)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,cv.id,s.content_key,qn.id,s.skill_code,'{}'::text[],'learning','withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'AW13-16 P1 learning runway draft for the remaining E2 canonical skills; separate from prior teaching and evidence versions.',
 case
   when s.skill_code in ('P1-COO-05','P1-COO-06') then 'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry'
   when s.skill_code='P1-CIR-03' then 'Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure'
   else 'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry'
 end,
 case
   when s.skill_code in ('P1-COO-05','P1-COO-06') then 'Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'
   when s.skill_code='P1-CIR-03' then 'Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'
   else 'Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'
 end,
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
(35421,4813,'P1-COO-05-learning-alt-02','v1','P1','learning','draft','Coordinate geometry: circle-line intersections — additional practice','Координатная геометрия: пересечение прямой и окружности — дополнительная практика','Koordinata geometriyasi: aylana va chiziq kesishishi — qo‘shimcha mashq'),
(35422,4813,'P1-COO-06-learning-alt-02','v1','P1','learning','draft','Coordinate geometry: tangency conditions — additional practice','Координатная геометрия: условия касания — дополнительная практика','Koordinata geometriyasi: urinish shartlari — qo‘shimcha mashq'),
(35423,4813,'P1-CIR-03-learning-alt-02','v1','P1','learning','draft','Circular measure: sector and segment area — additional practice','Круговая мера: площади сектора и сегмента — дополнительная практика','Doiraviy o‘lchov: sektor va segment yuzi — qo‘shimcha mashq'),
(35424,4813,'P1-TRI-02-learning-alt-02','v1','P1','learning','draft','Trigonometry: exact values — additional practice','Тригонометрия: точные значения — дополнительная практика','Trigonometriya: aniq qiymatlar — qo‘shimcha mashq'),
(35425,4813,'P1-TRI-03-learning-alt-02','v1','P1','learning','draft','Trigonometry: inverse principal values — additional practice','Тригонометрия: главные значения обратных функций — дополнительная практика','Trigonometriya: teskari funksiyalarning asosiy qiymatlari — qo‘shimcha mashq'),
(35426,4813,'P1-TRI-04-learning-alt-02','v1','P1','learning','draft','Trigonometry: identities — additional practice','Тригонометрия: тождества — дополнительная практика','Trigonometriya: ayniyatlar — qo‘shimcha mashq'),
(35427,4813,'P1-TRI-05-learning-alt-02','v1','P1','learning','draft','Trigonometry: equations — additional practice','Тригонометрия: уравнения — дополнительная практика','Trigonometriya: tenglamalar — qo‘shimcha mashq')
on conflict(id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
(35421,1,'P1COO05-B01',null::bigint,'P1-COO-05'),
(35421,2,'P1COO05-B02',null::bigint,'P1-COO-05'),
(35421,3,'P1COO05-B03',null::bigint,'P1-COO-05'),
(35421,4,null,15638,'P1-COO-05'),
(35422,1,'P1COO06-B01',null::bigint,'P1-COO-06'),
(35422,2,'P1COO06-B02',null::bigint,'P1-COO-06'),
(35422,3,'P1COO06-B03',null::bigint,'P1-COO-06'),
(35422,4,null,15639,'P1-COO-06'),
(35423,1,'P1CIR03-B01',null::bigint,'P1-CIR-03'),
(35423,2,'P1CIR03-B02',null::bigint,'P1-CIR-03'),
(35423,3,'P1CIR03-B03',null::bigint,'P1-CIR-03'),
(35423,4,null,15640,'P1-CIR-03'),
(35424,1,'P1TRI02-B01',null::bigint,'P1-TRI-02'),
(35424,2,'P1TRI02-B02',null::bigint,'P1-TRI-02'),
(35424,3,'P1TRI02-B03',null::bigint,'P1-TRI-02'),
(35424,4,null,15641,'P1-TRI-02'),
(35425,1,'P1TRI03-B01',null::bigint,'P1-TRI-03'),
(35425,2,'P1TRI03-B02',null::bigint,'P1-TRI-03'),
(35425,3,'P1TRI03-B03',null::bigint,'P1-TRI-03'),
(35425,4,null,15642,'P1-TRI-03'),
(35426,1,'P1TRI04-B01',null::bigint,'P1-TRI-04'),
(35426,2,'P1TRI04-B02',null::bigint,'P1-TRI-04'),
(35426,3,'P1TRI04-B03',null::bigint,'P1-TRI-04'),
(35426,4,null,15643,'P1-TRI-04'),
(35427,1,'P1TRI05-B01',null::bigint,'P1-TRI-05'),
(35427,2,'P1TRI05-B02',null::bigint,'P1-TRI-05'),
(35427,3,'P1TRI05-B03',null::bigint,'P1-TRI-05'),
(35427,4,null,15644,'P1-TRI-05')
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
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4813 and lifecycle_state='draft' and reserve_role='learning')<>21
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4813 and lifecycle_state='draft')<>7
     or (select count(*) from private.exam_prep_assessments where content_version_id=4813 and status='draft' and assessment_type='learning')<>7
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4813)<>28
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
  if v_bad<>0 then raise exception 'aw13_16_alt_p1_draft exposure/trilingual boundary rows=%',v_bad; end if;

  select count(*) into v_bad from (
    select a.id,
      count(*) filter(where ai.question_id is not null and ai.reserve_role='learning' and not ai.is_holdout) machine_n,
      count(*) filter(where ai.written_task_id is not null and ai.reserve_role='written' and not ai.is_holdout) written_n,
      count(*) total_n
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id=4813
    group by a.id
  ) x where machine_n<>3 or written_n<>1 or total_n<>4;
  if v_bad<>0 then raise exception 'aw13_16_alt_p1_draft assessment 3+1 shape rows=%',v_bad; end if;

  select
    count(*) filter(where qn.correct_answer='A'),count(*) filter(where qn.correct_answer='B'),
    count(*) filter(where qn.correct_answer='C'),count(*) filter(where qn.correct_answer='D'),
    count(*) filter(where qn.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4813;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,3,3,7) then
    raise exception 'aw13_16_alt_p1_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m
    join public.questions qn on qn.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4813
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4813
      and lower(regexp_replace(qn.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw13_16_alt_p1_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4813)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4813)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4813)
  then raise exception 'aw13_16_alt_p1_draft unexpected history'; end if;
end
$postcheck$;

commit;
