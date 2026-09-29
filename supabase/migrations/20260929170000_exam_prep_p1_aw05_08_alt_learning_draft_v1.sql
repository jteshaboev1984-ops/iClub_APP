-- AW5-8 supplemental learning pack draft for P1.
-- DRAFT ONLY: no learner exposure, QA self-approval or publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active') then
    raise exception 'aw05_08_alt_p1_draft canonical program missing';
  end if;
  if exists(select 1 from private.exam_prep_content_versions where id=4805 and content_version<>'p1_aw05_08_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15610 and 15617 and content_version_id<>4805)
     or exists(select 1 from private.exam_prep_assessments where id between 35325 and 35332 and content_version_id<>4805)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59046 and 59069 and content_version_id<>4805)
  then raise exception 'aw05_08_alt_p1_draft reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4805,pv.id,'p1_aw05_08_alt_learning_draft_v1','P1',
 'P1 AW5-8 supplemental learning pack draft v1','draft',
 'Original iClub-authored supplemental learning content. Official Cambridge 9709 scope and Complete Pure Mathematics 1 mappings define learning objectives only; no protected source question, solution, diagram or mark-scheme wording is copied. Independent academic, language, technical and copyright QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict (program_version_id,content_version) do nothing;

with src(content_key,skill_code,topic,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P1FUN06-A01','P1-FUN-06','P1 Functions','medium','mcq','What translation takes y=f(x) to y=f(x+4)−3?','["4 units right and 3 units down","4 units left and 3 units up","4 units right and 3 units up","4 units left and 3 units down"]','A','The +4 is inside the function, so it moves the graph 4 units left. The −3 is outside, so it moves the graph 3 units down.','Какой перенос переводит график y=f(x) в y=f(x+4)−3?','["на 4 единицы влево и на 3 единицы вниз","на 4 единицы вправо и на 3 единицы вверх","на 4 единицы вправо и на 3 единицы вниз","на 4 единицы влево и на 3 единицы вверх"]','Знак внутри функции действует в противоположном направлении: +4 сдвигает график на 4 влево. −3 снаружи сдвигает его на 3 вниз.','Qaysi ko‘chirish y=f(x) grafigini y=f(x+4)−3 ga o‘tkazadi?','["4 birlik chapga va 3 birlik pastga","4 birlik o‘ngga va 3 birlik yuqoriga","4 birlik o‘ngga va 3 birlik pastga","4 birlik chapga va 3 birlik yuqoriga"]','Funksiya ichidagi +4 grafikni 4 birlik chapga, tashqaridagi −3 esa 3 birlik pastga siljitadi.',55),
('P1FUN06-A02','P1-FUN-06','P1 Functions','medium','mcq','The point (−2,5) lies on y=f(x). Which point lies on y=f(x−3)+2?','["(−5,7)","(1,7)","(1,3)","(−5,3)"]','B','The graph moves 3 units right and 2 units up, so (−2,5) maps to (1,7).','(−2,5) лежит на графике y=f(x). Какая точка лежит на y=f(x−3)+2?','["(−5,7)","(1,7)","(1,3)","(−5,3)"]','График сдвигается на 3 вправо и на 2 вверх, поэтому (−2,5) переходит в (1,7).','(−2,5) nuqta y=f(x) grafigida yotadi. Qaysi nuqta y=f(x−3)+2 grafigida yotadi?','["(−5,7)","(1,7)","(1,3)","(−5,3)"]','Grafik 3 birlik o‘ngga va 2 birlik yuqoriga siljiydi, shuning uchun (−2,5) nuqta (1,7) ga o‘tadi.',55),
('P1FUN06-A03','P1-FUN-06','P1 Functions','medium','input','The minimum point of y=f(x) is (4,−1). Enter the x-coordinate of the minimum point of y=f(x+2)+6.','[]','2','The transformation moves the graph 2 units left and 6 units up, so the minimum moves from (4,−1) to (2,5).','Точка минимума y=f(x) равна (4,−1). Введите x-координату точки минимума графика y=f(x+2)+6.','[]','График сдвигается на 2 влево и на 6 вверх, поэтому минимум переходит из (4,−1) в (2,5).','y=f(x) grafigining minimum nuqtasi (4,−1). y=f(x+2)+6 grafigi minimum nuqtasining x-koordinatasini kiriting.','[]','Grafik 2 birlik chapga va 6 birlik yuqoriga siljiydi, shuning uchun minimum (4,−1) dan (2,5) ga o‘tadi.',50),
('P1FUN07-A01','P1-FUN-07','P1 Functions','medium','mcq','The point (3,−4) lies on y=f(x). Which point lies on y=f(−x)?','["(3,4)","(−3,4)","(−3,−4)","(4,−3)"]','C','Replacing x by −x reflects the graph in the y-axis, so (3,−4) maps to (−3,−4).','Точка (3,−4) лежит на y=f(x). Какая точка лежит на y=f(−x)?','["(3,4)","(−3,4)","(−3,−4)","(4,−3)"]','Замена x на −x отражает график относительно оси y, поэтому (3,−4) переходит в (−3,−4).','(3,−4) nuqta y=f(x) grafigida yotadi. Qaysi nuqta y=f(−x) grafigida yotadi?','["(3,4)","(−3,4)","(−3,−4)","(4,−3)"]','x ni −x ga almashtirish grafikni y o‘qiga nisbatan akslantiradi, shuning uchun (3,−4) nuqta (−3,−4) ga o‘tadi.',50),
('P1FUN07-A02','P1-FUN-07','P1 Functions','medium','mcq','Which transformation takes y=f(x) to y=−f(x)?','["Reflection in the y-axis","Translation down 1 unit","Rotation through 90°","Reflection in the x-axis"]','D','Multiplying every output by −1 changes y to −y while x is unchanged, which is reflection in the x-axis.','Какое преобразование переводит y=f(x) в y=−f(x)?','["Отражение относительно оси y","Сдвиг на 1 единицу вниз","Поворот на 90°","Отражение относительно оси x"]','Умножение каждого значения функции на −1 меняет y на −y при неизменном x, то есть отражает график относительно оси x.','Qaysi almashtirish y=f(x) ni y=−f(x) ga o‘tkazadi?','["y o‘qiga nisbatan akslantirish","1 birlik pastga siljitish","90° ga burish","x o‘qiga nisbatan akslantirish"]','Har bir funksiya qiymatini −1 ga ko‘paytirish x ni o‘zgartirmay y ni −y ga almashtiradi, ya’ni grafik x o‘qiga nisbatan akslanadi.',50),
('P1FUN07-A03','P1-FUN-07','P1 Functions','medium','input','The point (−5,6) lies on y=f(x). Enter the x-coordinate of the corresponding point on y=−f(−x).','[]','5','The inside −x reflects in the y-axis and the outside minus reflects in the x-axis. Thus (−5,6) maps to (5,−6).','Точка (−5,6) лежит на y=f(x). Введите x-координату соответствующей точки на y=−f(−x).','[]','Знак минус внутри отражает относительно оси y, а внешний минус — относительно оси x. Поэтому (−5,6) переходит в (5,−6).','(−5,6) nuqta y=f(x) grafigida yotadi. y=−f(−x) dagi mos nuqtaning x-koordinatasini kiriting.','[]','Ichkaridagi −x grafikni y o‘qiga, tashqaridagi minus esa x o‘qiga nisbatan akslantiradi. Demak (−5,6) nuqta (5,−6) ga o‘tadi.',55),
('P1FUN08-A01','P1-FUN-08','P1 Functions','hard','mcq','The point (6,−2) lies on y=f(x). Which point lies on y=2f(x/3)?','["(2,−6)","(18,−4)","(18,−6)","(2,−4)"]','B','For f(x/3), x-coordinates are multiplied by 3. The outside factor 2 doubles y-values, so (6,−2) maps to (18,−4).','Точка (6,−2) лежит на y=f(x). Какая точка лежит на y=2f(x/3)?','["(2,−6)","(18,−4)","(18,−6)","(2,−4)"]','Для f(x/3) x-координаты умножаются на 3. Внешний множитель 2 удваивает y-координаты, поэтому (6,−2) переходит в (18,−4).','(6,−2) nuqta y=f(x) grafigida yotadi. Qaysi nuqta y=2f(x/3) grafigida yotadi?','["(2,−6)","(18,−4)","(18,−6)","(2,−4)"]','f(x/3) da x-koordinatalar 3 ga ko‘payadi. Tashqaridagi 2 esa y-qiymatlarni ikki baravar qiladi, shuning uchun (6,−2) nuqta (18,−4) ga o‘tadi.',65),
('P1FUN08-A02','P1-FUN-08','P1 Functions','medium','mcq','What is the horizontal scale factor from y=f(x) to y=f(5x)?','["1/5","5","−5","1"]','A','To obtain the same input value of f, x must be divided by 5. Therefore all x-coordinates are scaled by 1/5.','Каков коэффициент горизонтального масштабирования при переходе от y=f(x) к y=f(5x)?','["1/5","5","−5","1"]','Чтобы получить тот же аргумент функции f, x нужно разделить на 5. Поэтому все x-координаты масштабируются с коэффициентом 1/5.','y=f(x) dan y=f(5x) ga o‘tganda gorizontal masshtab koeffitsiyenti qanday?','["1/5","5","−5","1"]','f ning bir xil argumentini olish uchun x ni 5 ga bo‘lish kerak. Shuning uchun barcha x-koordinatalar 1/5 koeffitsiyent bilan masshtablanadi.',50),
('P1FUN08-A03','P1-FUN-08','P1 Functions','hard','input','The point (4,10) lies on y=f(x). On y=0.5f(2x), enter the sum of the coordinates of the corresponding point.','[]','7','For f(2x), 4 becomes x=2. Multiplying the output by 0.5 changes 10 to 5. The point is (2,5), whose coordinate sum is 7.','Точка (4,10) лежит на y=f(x). На графике y=0.5f(2x) введите сумму координат соответствующей точки.','[]','Для f(2x) координата 4 превращается в x=2. Умножение значения функции на 0,5 превращает 10 в 5. Получаем точку (2,5), сумма координат равна 7.','(4,10) nuqta y=f(x) grafigida yotadi. y=0.5f(2x) dagi mos nuqta koordinatalari yig‘indisini kiriting.','[]','f(2x) da 4 koordinata x=2 ga aylanadi. Funksiya qiymatini 0.5 ga ko‘paytirish 10 ni 5 ga aylantiradi. Nuqta (2,5), koordinatalar yig‘indisi 7.',65),
('P1COO01-A01','P1-COO-01','P1 Coordinate geometry','medium','mcq','A line has gradient −3 and passes through (2,−5). Which equation represents the line?','["y=−3x−11","y=3x−11","y=−3x+1","y=3x+1"]','C','Using y−(−5)=−3(x−2) gives y+5=−3x+6, so y=−3x+1.','Прямая имеет градиент −3 и проходит через (2,−5). Какое уравнение задаёт эту прямую?','["y=−3x−11","y=3x−11","y=−3x+1","y=3x+1"]','По формуле y−(−5)=−3(x−2): y+5=−3x+6, поэтому y=−3x+1.','To‘g‘ri chiziq gradienti −3 va u (2,−5) nuqtadan o‘tadi. Qaysi tenglama shu chiziqni ifodalaydi?','["y=−3x−11","y=3x−11","y=−3x+1","y=3x+1"]','y−(−5)=−3(x−2) dan y+5=−3x+6, demak y=−3x+1.',60),
('P1COO01-A02','P1-COO-01','P1 Coordinate geometry','medium','mcq','Which equation is the line through (−2,1) and (4,13)?','["y=2x−5","y=2x+5","y=3x+7","y=−2x−3"]','B','The gradient is (13−1)/(4−(−2))=12/6=2. Using (−2,1), 1=2(−2)+c gives c=5.','Какое уравнение задаёт прямую через точки (−2,1) и (4,13)?','["y=2x−5","y=2x+5","y=3x+7","y=−2x−3"]','Градиент равен (13−1)/(4−(−2))=12/6=2. Подставляя (−2,1), получаем 1=2(−2)+c, поэтому c=5.','Qaysi tenglama (−2,1) va (4,13) nuqtalardan o‘tuvchi chiziqni ifodalaydi?','["y=2x−5","y=2x+5","y=3x+7","y=−2x−3"]','Gradient (13−1)/(4−(−2))=12/6=2. (−2,1) ni qo‘ysak, 1=2(−2)+c, demak c=5.',60),
('P1COO01-A03','P1-COO-01','P1 Coordinate geometry','medium','input','The line 4x+2y=14 is written as y=mx+c. Enter c.','[]','7','2y=14−4x, so y=−2x+7. Therefore the y-intercept c is 7.','Прямая 4x+2y=14 записана в виде y=mx+c. Введите c.','[]','2y=14−4x, поэтому y=−2x+7. Следовательно, c=7.','4x+2y=14 chiziq y=mx+c ko‘rinishida yozildi. c ni kiriting.','[]','2y=14−4x, demak y=−2x+7. Shuning uchun c=7.',45),
('P1COO02-A01','P1-COO-02','P1 Coordinate geometry','medium','mcq','What is the midpoint of the line segment joining (−5,2) and (3,10)?','["(−4,6)","(1,4)","(−1,4)","(−1,6)"]','D','Average corresponding coordinates: ((−5+3)/2,(2+10)/2)=(−1,6).','Какова середина отрезка с концами (−5,2) и (3,10)?','["(−4,6)","(1,4)","(−1,4)","(−1,6)"]','Усредняем соответствующие координаты: ((−5+3)/2,(2+10)/2)=(−1,6).','(−5,2) va (3,10) nuqtalarni tutashtiruvchi kesmaning o‘rta nuqtasi qaysi?','["(−4,6)","(1,4)","(−1,4)","(−1,6)"]','Mos koordinatalarni o‘rtachalaymiz: ((−5+3)/2,(2+10)/2)=(−1,6).',50),
('P1COO02-A02','P1-COO-02','P1 Coordinate geometry','medium','mcq','Find the distance between (−1,2) and (5,10).','["10","8","2√17","12"]','A','The coordinate differences are 6 and 8, so the distance is √(6²+8²)=√100=10.','Найдите расстояние между точками (−1,2) и (5,10).','["10","8","2√17","12"]','Разности координат равны 6 и 8, поэтому расстояние √(6²+8²)=√100=10.','(−1,2) va (5,10) nuqtalar orasidagi masofani toping.','["10","8","2√17","12"]','Koordinatalar farqi 6 va 8, shuning uchun masofa √(6²+8²)=√100=10.',50),
('P1COO02-A03','P1-COO-02','P1 Coordinate geometry','medium','input','The lines y=3x−4 and y=−x+8 intersect at one point. Enter its x-coordinate.','[]','3','At the intersection, 3x−4=−x+8. Hence 4x=12 and x=3.','Прямые y=3x−4 и y=−x+8 пересекаются в одной точке. Введите её x-координату.','[]','В точке пересечения 3x−4=−x+8. Отсюда 4x=12 и x=3.','y=3x−4 va y=−x+8 chiziqlar bitta nuqtada kesishadi. Shu nuqtaning x-koordinatasini kiriting.','[]','Kesishish nuqtasida 3x−4=−x+8. Bundan 4x=12 va x=3.',50),
('P1COO03-A01','P1-COO-03','P1 Coordinate geometry','medium','mcq','The line through (−2,1) and (4,−3) has gradient −2/3. What is the gradient of a perpendicular line?','["−3/2","2/3","3/2","−2/3"]','C','Perpendicular non-vertical gradients multiply to −1. The negative reciprocal of −2/3 is 3/2.','Прямая через (−2,1) и (4,−3) имеет градиент −2/3. Каков градиент перпендикулярной прямой?','["−3/2","2/3","3/2","−2/3"]','Градиенты перпендикулярных невертикальных прямых дают произведение −1. Отрицательная обратная величина к −2/3 равна 3/2.','(−2,1) va (4,−3) nuqtalardan o‘tuvchi chiziq gradienti −2/3. Unga perpendikulyar chiziq gradienti qanday?','["−3/2","2/3","3/2","−2/3"]','Perpendikulyar vertikal bo‘lmagan chiziqlar gradientlari ko‘paytmasi −1. −2/3 ning manfiy teskari qiymati 3/2.',55),
('P1COO03-A02','P1-COO-03','P1 Coordinate geometry','medium','mcq','Which line is parallel to 3x+2y=8?','["y=(3/2)x+1","y=(2/3)x−5","y=−(2/3)x+4","y=−(3/2)x−5"]','D','3x+2y=8 gives y=−(3/2)x+4. A parallel line must also have gradient −3/2.','Какая прямая параллельна 3x+2y=8?','["y=(3/2)x+1","y=(2/3)x−5","y=−(2/3)x+4","y=−(3/2)x−5"]','Из 3x+2y=8 получаем y=−(3/2)x+4. Параллельная прямая должна иметь тот же градиент −3/2.','Qaysi chiziq 3x+2y=8 chiziqqa parallel?','["y=(3/2)x+1","y=(2/3)x−5","y=−(2/3)x+4","y=−(3/2)x−5"]','3x+2y=8 dan y=−(3/2)x+4. Parallel chiziq ham −3/2 gradientga ega bo‘lishi kerak.',55),
('P1COO03-A03','P1-COO-03','P1 Coordinate geometry','hard','input','A line through (2,1) is perpendicular to y=4x−3. Enter the x-coordinate where this perpendicular line meets the x-axis.','[]','6','The perpendicular gradient is −1/4. Its equation is y−1=−(1/4)(x−2). Setting y=0 gives −1=−(x−2)/4, so x=6.','Прямая через (2,1) перпендикулярна y=4x−3. Введите x-координату точки, где эта прямая пересекает ось x.','[]','Градиент перпендикулярной прямой равен −1/4. Её уравнение y−1=−(1/4)(x−2). При y=0 получаем −1=−(x−2)/4, поэтому x=6.','(2,1) nuqtadan o‘tuvchi chiziq y=4x−3 ga perpendikulyar. Shu chiziq x o‘qini kesadigan nuqtaning x-koordinatasini kiriting.','[]','Perpendikulyar chiziq gradienti −1/4. Uning tenglamasi y−1=−(1/4)(x−2). y=0 deb olsak, −1=−(x−2)/4, demak x=6.',70),
('P1CIR01-A01','P1-CIR-01','P1 Circular measure','medium','mcq','Convert 210° to radians.','["5π/6","7π/6","4π/3","7π/12"]','B','Multiply by π/180: 210π/180=7π/6.','Переведите 210° в радианы.','["5π/6","7π/6","4π/3","7π/12"]','Умножаем на π/180: 210π/180=7π/6.','210° ni radianlarga o‘tkazing.','["5π/6","7π/6","4π/3","7π/12"]','π/180 ga ko‘paytiramiz: 210π/180=7π/6.',45),
('P1CIR01-A02','P1-CIR-01','P1 Circular measure','medium','mcq','Convert 11π/18 radians to degrees.','["100°","120°","110°","99°"]','C','Multiply by 180/π: (11π/18)(180/π)=110°.','Переведите 11π/18 радиан в градусы.','["100°","120°","110°","99°"]','Умножаем на 180/π: (11π/18)(180/π)=110°.','11π/18 radianlarni gradusga o‘tkazing.','["100°","120°","110°","99°"]','180/π ga ko‘paytiramiz: (11π/18)(180/π)=110°.',45),
('P1CIR01-A03','P1-CIR-01','P1 Circular measure','medium','input','An angle is π/4 radians plus 35°. Enter the total angle in degrees.','[]','80','π/4 radians is 45°. Therefore the total is 45°+35°=80°.','Угол равен π/4 радиан плюс 35°. Введите общий угол в градусах.','[]','π/4 радиан равно 45°. Поэтому общий угол 45°+35°=80°.','Burchak π/4 radian va yana 35° dan iborat. Umumiy burchakni gradusda kiriting.','[]','π/4 radian 45° ga teng. Demak umumiy burchak 45°+35°=80°.',45),
('P1TRI01-A01','P1-TRI-01','P1 Trigonometry','medium','mcq','What is the period of y=sin(2x)?','["4π","2π","π/2","π"]','D','For y=sin(kx), the period is 2π/|k|. With k=2, the period is π.','Каков период функции y=sin(2x)?','["4π","2π","π/2","π"]','Для y=sin(kx) период равен 2π/|k|. При k=2 получаем π.','y=sin(2x) funksiyaning davri qanday?','["4π","2π","π/2","π"]','y=sin(kx) uchun davr 2π/|k| ga teng. k=2 bo‘lsa, davr π.',50),
('P1TRI01-A02','P1-TRI-01','P1 Trigonometry','medium','mcq','What is the range of y=−3cos x+2?','["−1≤y≤5","−1≤y≤5","−5≤y≤1","−3≤y≤3"]','A','Since −1≤cos x≤1, multiplying by −3 gives −3≤−3cos x≤3. Adding 2 gives −1≤y≤5.','Какова область значений y=−3cos x+2?','["−1≤y≤5","1≤y≤5","−5≤y≤1","−3≤y≤3"]','Так как −1≤cos x≤1, после умножения на −3 получаем −3≤−3cos x≤3. Прибавляя 2, получаем −1≤y≤5.','y=−3cos x+2 funksiyaning qiymatlar sohasi qaysi?','["−1≤y≤5","1≤y≤5","−5≤y≤1","−3≤y≤3"]','−1≤cos x≤1 bo‘lgani uchun −3 ga ko‘paytirganda −3≤−3cos x≤3. 2 qo‘shsak, −1≤y≤5.',55),
('P1TRI01-A03','P1-TRI-01','P1 Trigonometry','medium','input','Enter the maximum value of y=2sin x+1.','[]','3','The maximum of sin x is 1, so the maximum value is 2(1)+1=3.','Введите максимальное значение y=2sin x+1.','[]','Максимум sin x равен 1, поэтому максимальное значение равно 2·1+1=3.','y=2sin x+1 funksiyaning eng katta qiymatini kiriting.','[]','sin x ning maksimumi 1, shuning uchun eng katta qiymat 2·1+1=3.',45)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,s.topic,s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P1:p1_aw05_08_alt_learning_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P1:p1_aw05_08_alt_learning_draft_v1:'||s.content_key);

insert into private.exam_prep_written_tasks(
 id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
 prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
 lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(15610,4805,'P1FUN06-AW06','P1','P1-FUN-06','{}','v1','The graph y=f(x) contains A(−3,2) and has minimum M(1,−4). For g(x)=f(x−5)+3, state the translation vector and the coordinates of the corresponding points A and M. Explain why the sign inside f gives a shift to the right.','График y=f(x) содержит точку A(−3,2) и имеет минимум M(1,−4). Для g(x)=f(x−5)+3 укажите вектор переноса и координаты соответствующих точек A и M. Объясните, почему знак внутри f задаёт сдвиг вправо.','y=f(x) grafigida A(−3,2) nuqta bor va minimum M(1,−4). g(x)=f(x−5)+3 uchun ko‘chirish vektorini hamda A va M nuqtalarning yangi koordinatalarini yozing. Nega f ichidagi ishora o‘ngga siljishni berishini tushuntiring.','{"criteria":[{"id":"vector","rule":"States translation vector (5,3).","marks":1},{"id":"A","rule":"Maps A to (2,5).","marks":1},{"id":"M","rule":"Maps M to (6,-1).","marks":1},{"id":"explain","rule":"Explains that f(x-a) requires x to increase by a to produce the same original input.","marks":2},{"id":"check","rule":"Checks both coordinate changes consistently.","marks":1}],"max_marks":6}'::jsonb,'Check the horizontal and vertical changes separately, then verify that both points moved by the same vector.','Проверьте горизонтальное и вертикальное изменения отдельно, затем убедитесь, что обе точки сдвинуты на один и тот же вектор.','Gorizontal va vertikal o‘zgarishlarni alohida tekshiring, keyin ikkala nuqta ham bir xil vektor bilan ko‘chganini tasdiqlang.','draft','pending','pending','pending','pending'),
(15611,4805,'P1FUN07-AW06','P1','P1-FUN-07','{}','v1','The graph y=f(x) contains P(2,5) and Q(−4,−1). Reflect the graph first in the y-axis and then in the x-axis. Give the final coordinates of P and Q, write the final graph as a function of f, and describe the combined point mapping.','График y=f(x) содержит P(2,5) и Q(−4,−1). Сначала отразите график относительно оси y, затем относительно оси x. Укажите итоговые координаты P и Q, запишите итоговый график через f и опишите общее преобразование координат.','y=f(x) grafigida P(2,5) va Q(−4,−1) nuqtalar bor. Avval grafikni y o‘qiga, keyin x o‘qiga nisbatan akslantiring. P va Q ning yakuniy koordinatalarini, yakuniy grafikni f orqali va umumiy nuqta almashtirishini yozing.','{"criteria":[{"id":"formula","rule":"Writes y=-f(-x).","marks":2},{"id":"P","rule":"Maps P to (-2,-5).","marks":1},{"id":"Q","rule":"Maps Q to (4,1).","marks":1},{"id":"mapping","rule":"States (x,y) maps to (-x,-y).","marks":1},{"id":"reason","rule":"Links the inside sign to y-axis reflection and outside sign to x-axis reflection.","marks":1}],"max_marks":6}'::jsonb,'Track x and y separately: the first reflection changes x only, the second changes y only.','Отслеживайте x и y отдельно: первое отражение меняет только x, второе — только y.','x va y ni alohida kuzating: birinchi akslantirish faqat x ni, ikkinchisi faqat y ni o‘zgartiradi.','draft','pending','pending','pending','pending'),
(15612,4805,'P1FUN08-AW06','P1','P1-FUN-08','{}','v1','The graph y=f(x) contains A(6,−2) and has an x-intercept at B(4,0). For g(x)=3f(2x), find the corresponding coordinates of A and B and state the horizontal and vertical scale factors.','График y=f(x) содержит A(6,−2) и пересекает ось x в B(4,0). Для g(x)=3f(2x) найдите соответствующие координаты A и B и укажите горизонтальный и вертикальный коэффициенты масштабирования.','y=f(x) grafigida A(6,−2) nuqta bor va x o‘qini B(4,0) da kesadi. g(x)=3f(2x) uchun A va B ning mos koordinatalarini hamda gorizontal va vertikal masshtab koeffitsiyentlarini toping.','{"criteria":[{"id":"horizontal","rule":"States horizontal scale factor 1/2.","marks":1},{"id":"vertical","rule":"States vertical scale factor 3.","marks":1},{"id":"A","rule":"Maps A to (3,-6).","marks":2},{"id":"B","rule":"Maps B to (2,0).","marks":1},{"id":"reason","rule":"Explains inside scaling acts inversely on x-coordinates.","marks":1}],"max_marks":6}'::jsonb,'Apply the inside factor to x-coordinates inversely and the outside factor directly to y-coordinates.','К x-координатам применяйте внутренний множитель обратным образом, а внешний множитель — напрямую к y-координатам.','Ichki koeffitsiyent x-koordinatalarga teskari, tashqi koeffitsiyent esa y-koordinatalarga to‘g‘ridan-to‘g‘ri ta’sir qiladi.','draft','pending','pending','pending','pending'),
(15613,4805,'P1COO01-AW06','P1','P1-COO-01','{}','v1','Find the equation of the straight line through A(−3,4) and B(5,−8). Give the answer in the form y=mx+c and then in the form ax+by+c=0 with integer coefficients. Verify that both A and B satisfy your equation.','Найдите уравнение прямой через A(−3,4) и B(5,−8). Запишите ответ в виде y=mx+c, затем в виде ax+by+c=0 с целыми коэффициентами. Проверьте, что обе точки удовлетворяют уравнению.','A(−3,4) va B(5,−8) nuqtalardan o‘tuvchi to‘g‘ri chiziq tenglamasini toping. Javobni avval y=mx+c, so‘ng butun koeffitsiyentli ax+by+c=0 ko‘rinishida yozing. A va B nuqtalar tenglamani qanoatlantirishini tekshiring.','{"criteria":[{"id":"gradient","rule":"Finds gradient -3/2.","marks":2},{"id":"slope_form","rule":"Obtains y=-(3/2)x-1/2.","marks":1},{"id":"integer_form","rule":"Gives 3x+2y+1=0 or an equivalent integer multiple.","marks":1},{"id":"verifyA","rule":"Checks A correctly.","marks":1},{"id":"verifyB","rule":"Checks B correctly.","marks":1}],"max_marks":6}'::jsonb,'Recalculate the gradient first. Then substitute each point into the final equation, not only the slope form.','Сначала ещё раз проверьте градиент. Затем подставьте каждую точку в итоговое уравнение, а не только в форму с угловым коэффициентом.','Avval gradientni qayta tekshiring. Keyin har bir nuqtani faqat qiyalik ko‘rinishiga emas, yakuniy tenglamaga qo‘yib tekshiring.','draft','pending','pending','pending','pending'),
(15614,4805,'P1COO02-AW06','P1','P1-COO-02','{}','v1','For A(−4,1) and B(6,5), find the midpoint M and the exact length AB. Then show that your midpoint is equally distant from A and B.','Для A(−4,1) и B(6,5) найдите середину M и точную длину AB. Затем покажите, что M находится на одинаковом расстоянии от A и B.','A(−4,1) va B(6,5) uchun o‘rta nuqta M ni va AB ning aniq uzunligini toping. So‘ng M nuqta A va B dan teng masofada ekanini ko‘rsating.','{"criteria":[{"id":"midpoint","rule":"Finds M=(1,3).","marks":2},{"id":"distance","rule":"Finds AB=sqrt(116)=2sqrt(29).","marks":2},{"id":"half1","rule":"Finds AM=sqrt(29).","marks":1},{"id":"half2","rule":"Finds BM=sqrt(29) and concludes equality.","marks":1}],"max_marks":6}'::jsonb,'Use coordinate averages for M and keep square roots exact when checking the three distances.','Для M используйте средние координат и сохраняйте корни в точном виде при проверке трёх расстояний.','M uchun koordinatalar o‘rtachasidan foydalaning va uchta masofani tekshirganda ildizlarni aniq ko‘rinishda qoldiring.','draft','pending','pending','pending','pending'),
(15615,4805,'P1COO03-AW06','P1','P1-COO-03','{}','v1','The line AB passes through A(−2,3) and B(4,−1). Find its gradient. Then find the equation of the line through B perpendicular to AB, and verify your perpendicularity condition.','Прямая AB проходит через A(−2,3) и B(4,−1). Найдите её градиент. Затем найдите уравнение прямой через B, перпендикулярной AB, и проверьте условие перпендикулярности.','AB chiziq A(−2,3) va B(4,−1) nuqtalardan o‘tadi. Uning gradientini toping. So‘ng B dan o‘tuvchi va AB ga perpendikulyar chiziq tenglamasini topib, perpendikulyarlik shartini tekshiring.','{"criteria":[{"id":"mAB","rule":"Finds gradient -2/3.","marks":2},{"id":"mperp","rule":"Finds perpendicular gradient 3/2.","marks":1},{"id":"equation","rule":"Obtains y+1=(3/2)(x-4) or an equivalent equation.","marks":2},{"id":"verify","rule":"Shows (-2/3)(3/2)=-1.","marks":1}],"max_marks":6}'::jsonb,'Check both signs when taking the negative reciprocal, then substitute B into your perpendicular-line equation.','Проверьте оба знака при нахождении отрицательной обратной величины, затем подставьте B в уравнение перпендикуляра.','Manfiy teskari qiymatni olayotganda ikkala ishorani tekshiring, keyin B nuqtani perpendikulyar chiziq tenglamasiga qo‘ying.','draft','pending','pending','pending','pending'),
(15616,4805,'P1CIR01-AW06','P1','P1-CIR-01','{}','v1','Convert 135° exactly to radians and convert 5π/6 radians to degrees. State which angle is larger and explain the conversion factor used in each direction.','Точно переведите 135° в радианы и 5π/6 радиан в градусы. Укажите, какой угол больше, и объясните коэффициент перевода в каждом направлении.','135° ni aniq radianlarga va 5π/6 radianlarni gradusga o‘tkazing. Qaysi burchak kattaroq ekanini ayting va har ikki yo‘nalishdagi o‘tkazish koeffitsiyentini tushuntiring.','{"criteria":[{"id":"deg_to_rad","rule":"Obtains 3pi/4.","marks":2},{"id":"rad_to_deg","rule":"Obtains 150 degrees.","marks":2},{"id":"compare","rule":"States 5pi/6 (150 degrees) is larger than 135 degrees.","marks":1},{"id":"factor","rule":"Explains degree-to-radian uses pi/180 and radian-to-degree uses 180/pi.","marks":1}],"max_marks":6}'::jsonb,'Use 180°=π radians as the single reference equality and simplify before comparing.','Используйте равенство 180°=π радиан как основное и упростите значения до сравнения.','180°=π radian tengligini asosiy bog‘lanish sifatida ishlating va taqqoslashdan oldin qiymatlarni soddalashtiring.','draft','pending','pending','pending','pending'),
(15617,4805,'P1TRI01-AW06','P1','P1-TRI-01','{}','v1','For y=2sin(x−π/4)+1, state the amplitude, period, midline, maximum and minimum values. On 0≤x≤2π, give one x-coordinate where the maximum occurs and explain the horizontal translation.','Для y=2sin(x−π/4)+1 укажите амплитуду, период, среднюю линию, максимальное и минимальное значения. На 0≤x≤2π укажите одну x-координату максимума и объясните горизонтальный сдвиг.','y=2sin(x−π/4)+1 uchun amplituda, davr, o‘rta chiziq, maksimum va minimum qiymatlarni yozing. 0≤x≤2π da maksimum yuz beradigan bitta x-koordinatani ko‘rsating va gorizontal siljishni tushuntiring.','{"criteria":[{"id":"amp","rule":"States amplitude 2.","marks":1},{"id":"period","rule":"States period 2pi.","marks":1},{"id":"midline","rule":"States midline y=1.","marks":1},{"id":"extremes","rule":"States maximum 3 and minimum -1.","marks":1},{"id":"xmax","rule":"Gives x=3pi/4 as a maximum point in the interval.","marks":1},{"id":"shift","rule":"Explains x-pi/4 shifts the sine graph pi/4 to the right.","marks":1}],"max_marks":6}'::jsonb,'Separate vertical features from the horizontal shift. For the maximum, solve x−π/4=π/2 within the stated interval.','Отделите вертикальные характеристики от горизонтального сдвига. Для максимума решите x−π/4=π/2 в заданном интервале.','Vertikal xususiyatlarni gorizontal siljishdan ajrating. Maksimum uchun berilgan oraliqda x−π/4=π/2 ni yeching.','draft','pending','pending','pending','pending')
on conflict (id) do nothing;

with src(content_key,skill_code,meta_id) as (values
('P1FUN06-A01','P1-FUN-06',59046),
('P1FUN06-A02','P1-FUN-06',59047),
('P1FUN06-A03','P1-FUN-06',59048),
('P1FUN07-A01','P1-FUN-07',59049),
('P1FUN07-A02','P1-FUN-07',59050),
('P1FUN07-A03','P1-FUN-07',59051),
('P1FUN08-A01','P1-FUN-08',59052),
('P1FUN08-A02','P1-FUN-08',59053),
('P1FUN08-A03','P1-FUN-08',59054),
('P1COO01-A01','P1-COO-01',59055),
('P1COO01-A02','P1-COO-01',59056),
('P1COO01-A03','P1-COO-01',59057),
('P1COO02-A01','P1-COO-02',59058),
('P1COO02-A02','P1-COO-02',59059),
('P1COO02-A03','P1-COO-02',59060),
('P1COO03-A01','P1-COO-03',59061),
('P1COO03-A02','P1-COO-03',59062),
('P1COO03-A03','P1-COO-03',59063),
('P1CIR01-A01','P1-CIR-01',59064),
('P1CIR01-A02','P1-CIR-01',59065),
('P1CIR01-A03','P1-CIR-01',59066),
('P1TRI01-A01','P1-TRI-01',59067),
('P1TRI01-A02','P1-TRI-01',59068),
('P1TRI01-A03','P1-TRI-01',59069)
), cv as (select id from private.exam_prep_content_versions where id=4805)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,cv.id,s.content_key,qn.id,s.skill_code,'{}'::text[],'learning','withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'Supplemental AW5-8 learning draft authored from the canonical skill intent with independent values and contexts, separate from the existing teaching pack.',
 case s.skill_code
 when 'P1-FUN-06' then 'Cambridge 9709 2026-2027 v4; P1 1.2 Functions'
 when 'P1-FUN-07' then 'Cambridge 9709 2026-2027 v4; P1 1.2 Functions'
 when 'P1-FUN-08' then 'Cambridge 9709 2026-2027 v4; P1 1.2 Functions'
 when 'P1-COO-01' then 'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry'
 when 'P1-COO-02' then 'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry'
 when 'P1-COO-03' then 'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry'
 when 'P1-CIR-01' then 'Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure'
 when 'P1-TRI-01' then 'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry'
 end,
 case s.skill_code
 when 'P1-FUN-06' then 'Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'
 when 'P1-FUN-07' then 'Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'
 when 'P1-FUN-08' then 'Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'
 when 'P1-COO-01' then 'Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'
 when 'P1-COO-02' then 'Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'
 when 'P1-COO-03' then 'Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'
 when 'P1-CIR-01' then 'Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'
 when 'P1-TRI-01' then 'Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'
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
join public.questions qn on qn.book_ref='ExamPrep:P1:p1_aw05_08_alt_learning_draft_v1:'||s.content_key
on conflict (id) do nothing;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35325,4805,'P1-FUN-06-learning-alt-02','v1','P1','learning','draft','Functions: graph translations - supplemental learning','Функции: сдвиги графиков — дополнительное обучение','Funksiyalar: grafiklarni siljitish — qo‘shimcha o‘rganish'),
(35326,4805,'P1-FUN-07-learning-alt-02','v1','P1','learning','draft','Functions: graph reflections - supplemental learning','Функции: отражения графиков — дополнительное обучение','Funksiyalar: grafiklarni akslantirish — qo‘shimcha o‘rganish'),
(35327,4805,'P1-FUN-08-learning-alt-02','v1','P1','learning','draft','Functions: graph stretches and compressions - supplemental learning','Функции: растяжения и сжатия графиков — дополнительное обучение','Funksiyalar: grafiklarni cho‘zish va siqish — qo‘shimcha o‘rganish'),
(35328,4805,'P1-COO-01-learning-alt-02','v1','P1','learning','draft','Coordinate geometry: equation of a line - supplemental learning','Координатная геометрия: уравнение прямой — дополнительное обучение','Koordinata geometriyasi: to‘g‘ri chiziq tenglamasi — qo‘shimcha o‘rganish'),
(35329,4805,'P1-COO-02-learning-alt-02','v1','P1','learning','draft','Coordinate geometry: distance, midpoint and intersection - supplemental learning','Координатная геометрия: расстояние, середина и пересечение — дополнительное обучение','Koordinata geometriyasi: masofa, o‘rta nuqta va kesishish — qo‘shimcha o‘rganish'),
(35330,4805,'P1-COO-03-learning-alt-02','v1','P1','learning','draft','Coordinate geometry: parallel and perpendicular lines - supplemental learning','Координатная геометрия: параллельные и перпендикулярные прямые — дополнительное обучение','Koordinata geometriyasi: parallel va perpendikulyar chiziqlar — qo‘shimcha o‘rganish'),
(35331,4805,'P1-CIR-01-learning-alt-02','v1','P1','learning','draft','Circular measure: degrees and radians - supplemental learning','Круговая мера: градусы и радианы — дополнительное обучение','Aylana o‘lchovi: gradus va radian — qo‘shimcha o‘rganish'),
(35332,4805,'P1-TRI-01-learning-alt-02','v1','P1','learning','draft','Trigonometry: graphs and transformations - supplemental learning','Тригонометрия: графики и преобразования — дополнительное обучение','Trigonometriya: grafiklar va almashtirishlar — qo‘shimcha o‘rganish')
on conflict (id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
(35325,1,'P1FUN06-A01',null::bigint,'P1-FUN-06'),
(35325,2,'P1FUN06-A02',null,'P1-FUN-06'),
(35325,3,'P1FUN06-A03',null,'P1-FUN-06'),
(35325,4,null,15610,'P1-FUN-06'),
(35326,1,'P1FUN07-A01',null::bigint,'P1-FUN-07'),
(35326,2,'P1FUN07-A02',null,'P1-FUN-07'),
(35326,3,'P1FUN07-A03',null,'P1-FUN-07'),
(35326,4,null,15611,'P1-FUN-07'),
(35327,1,'P1FUN08-A01',null::bigint,'P1-FUN-08'),
(35327,2,'P1FUN08-A02',null,'P1-FUN-08'),
(35327,3,'P1FUN08-A03',null,'P1-FUN-08'),
(35327,4,null,15612,'P1-FUN-08'),
(35328,1,'P1COO01-A01',null::bigint,'P1-COO-01'),
(35328,2,'P1COO01-A02',null,'P1-COO-01'),
(35328,3,'P1COO01-A03',null,'P1-COO-01'),
(35328,4,null,15613,'P1-COO-01'),
(35329,1,'P1COO02-A01',null::bigint,'P1-COO-02'),
(35329,2,'P1COO02-A02',null,'P1-COO-02'),
(35329,3,'P1COO02-A03',null,'P1-COO-02'),
(35329,4,null,15614,'P1-COO-02'),
(35330,1,'P1COO03-A01',null::bigint,'P1-COO-03'),
(35330,2,'P1COO03-A02',null,'P1-COO-03'),
(35330,3,'P1COO03-A03',null,'P1-COO-03'),
(35330,4,null,15615,'P1-COO-03'),
(35331,1,'P1CIR01-A01',null::bigint,'P1-CIR-01'),
(35331,2,'P1CIR01-A02',null,'P1-CIR-01'),
(35331,3,'P1CIR01-A03',null,'P1-CIR-01'),
(35331,4,null,15616,'P1-CIR-01'),
(35332,1,'P1TRI01-A01',null::bigint,'P1-TRI-01'),
(35332,2,'P1TRI01-A02',null,'P1-TRI-01'),
(35332,3,'P1TRI01-A03',null,'P1-TRI-01'),
(35332,4,null,15617,'P1-TRI-01')
)
insert into private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select i.assessment_id,i.item_order,qn.id,i.written_id,i.skill_code,
 case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions qn on i.content_key is not null
 and qn.book_ref='ExamPrep:P1:p1_aw05_08_alt_learning_draft_v1:'||i.content_key
on conflict (assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select status from private.exam_prep_content_versions where id=4805)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4805 and lifecycle_state='draft' and reserve_role='learning')<>24
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4805 and lifecycle_state='draft')<>8
     or (select count(*) from private.exam_prep_assessments where content_version_id=4805 and status='draft' and assessment_type='learning')<>8
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4805)<>32
  then raise exception 'aw05_08_alt_p1_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4805 and (
    m.exposure_state<>'withheld' or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or qn.is_active or qn.quality_status<>'draft'
  );
  if v_bad<>0 then raise exception 'aw05_08_alt_p1_draft exposure/QA boundary rows=%',v_bad; end if;

  select
    count(*) filter(where qn.correct_answer='A'),
    count(*) filter(where qn.correct_answer='B'),
    count(*) filter(where qn.correct_answer='C'),
    count(*) filter(where qn.correct_answer='D'),
    count(*) filter(where qn.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4805;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,4,4,8) then
    raise exception 'aw05_08_alt_p1_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions qn on qn.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4805
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4805
      and lower(regexp_replace(qn.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw05_08_alt_p1_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4805)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4805)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4805)
  then raise exception 'aw05_08_alt_p1_draft unexpected history'; end if;
end
$postcheck$;

commit;
