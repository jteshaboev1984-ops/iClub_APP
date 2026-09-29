-- AW5-8 P1 annual-reserve top-up draft v1.
-- DRAFT ONLY: no learner-visible content and no existing evidence mutation.
-- Exact delta per skill: +2 diagnostics, +2 delayed retests, +1 mixed/transfer.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw05_08_annual_reserve_p1_draft canonical program missing'; end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4807 and content_version<>'p1_aw05_08_annual_reserve_topup_draft_v1')
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59088 and 59127 and content_version_id<>4807)
  then raise exception 'aw05_08_annual_reserve_p1_draft reserved id collision'; end if;

  if (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-FUN-06','P1-FUN-07','P1-FUN-08','P1-COO-01','P1-COO-02','P1-COO-03','P1-CIR-01','P1-TRI-01')
        and m.reserve_role='diagnostic')<>8
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-FUN-06','P1-FUN-07','P1-FUN-08','P1-COO-01','P1-COO-02','P1-COO-03','P1-CIR-01','P1-TRI-01')
        and m.reserve_role='retest')<>16
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-FUN-06','P1-FUN-07','P1-FUN-08','P1-COO-01','P1-COO-02','P1-COO-03','P1-CIR-01','P1-TRI-01')
        and m.reserve_role in ('learning','mixed'))<>56
  then raise exception 'aw05_08_annual_reserve_p1_draft baseline depth changed'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4807,pv.id,'p1_aw05_08_annual_reserve_topup_draft_v1','P1',
 'P1 AW5-8 annual reserve top-up draft v1','draft',
 'Original iClub-authored annual reserve expansion. Official Cambridge 9709 scope controls the learning objectives; Complete Pure Mathematics 1 is mapping/explanation support only. No protected Cambridge/coursebook question, solution, mark-scheme wording or diagram is copied. Independent academic, trilingual, technical, originality and reserve-isolation QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,reserve_role,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P1FUN06-D02','P1-FUN-06','diagnostic','medium','mcq','The point (−4,2) lies on y=f(x). Which point lies on y=f(x−6)−3?','["(2,−1)","(−10,−1)","(2,5)","(−10,5)"]','A','The graph moves 6 units right and 3 units down, so (−4,2) maps to (2,−1).','Точка (−4,2) лежит на y=f(x). Какая точка лежит на y=f(x−6)−3?','["(2,−1)","(−10,−1)","(2,5)","(−10,5)"]','График сдвигается на 6 вправо и на 3 вниз, поэтому (−4,2) переходит в (2,−1).','(−4,2) nuqta y=f(x) grafigida yotadi. Qaysi nuqta y=f(x−6)−3 grafigida yotadi?','["(2,−1)","(−10,−1)","(2,5)","(−10,5)"]','Grafik 6 birlik o‘ngga va 3 birlik pastga siljiydi, shuning uchun (−4,2) nuqta (2,−1) ga o‘tadi.',70),
('P1FUN06-D03','P1-FUN-06','diagnostic','medium','mcq','Which translation takes y=f(x) to y=f(x+3)+5?','["3 right, 5 up","3 left, 5 up","3 right, 5 down","3 left, 5 down"]','B','The +3 inside f shifts the graph 3 left; +5 outside shifts it 5 up.','Какой перенос переводит y=f(x) в y=f(x+3)+5?','["3 вправо, 5 вверх","3 влево, 5 вверх","3 вправо, 5 вниз","3 влево, 5 вниз"]','+3 внутри f сдвигает график на 3 влево; +5 снаружи — на 5 вверх.','Qaysi ko‘chirish y=f(x) ni y=f(x+3)+5 ga o‘tkazadi?','["3 o‘ngga, 5 yuqoriga","3 chapga, 5 yuqoriga","3 o‘ngga, 5 pastga","3 chapga, 5 pastga"]','f ichidagi +3 grafikni 3 birlik chapga, tashqaridagi +5 esa 5 birlik yuqoriga siljitadi.',70),
('P1FUN06-R03','P1-FUN-06','retest','medium','input','The minimum point of y=f(x) is (7,−2). Enter the x-coordinate of the minimum point of y=f(x−4)+1.','[]','11','The graph moves 4 units right, so the x-coordinate becomes 11.','Точка минимума y=f(x) равна (7,−2). Введите x-координату минимума y=f(x−4)+1.','[]','График сдвигается на 4 вправо, поэтому x-координата становится 11.','y=f(x) grafigining minimum nuqtasi (7,−2). y=f(x−4)+1 minimumining x-koordinatasini kiriting.','[]','Grafik 4 birlik o‘ngga siljiydi, shuning uchun x-koordinata 11 bo‘ladi.',70),
('P1FUN06-R04','P1-FUN-06','retest','medium','mcq','The point (1,−6) lies on y=f(x). Which point lies on y=f(x+2)+4?','["(3,−2)","(−1,−10)","(3,−10)","(−1,−2)"]','D','The graph moves 2 left and 4 up, so (1,−6) maps to (−1,−2).','Точка (1,−6) лежит на y=f(x). Какая точка лежит на y=f(x+2)+4?','["(3,−2)","(−1,−10)","(3,−10)","(−1,−2)"]','График сдвигается на 2 влево и на 4 вверх, поэтому (1,−6) переходит в (−1,−2).','(1,−6) nuqta y=f(x) grafigida yotadi. Qaysi nuqta y=f(x+2)+4 grafigida yotadi?','["(3,−2)","(−1,−10)","(3,−10)","(−1,−2)"]','Grafik 2 birlik chapga va 4 birlik yuqoriga siljiydi, shuning uchun (1,−6) nuqta (−1,−2) ga o‘tadi.',70),
('P1FUN06-M02','P1-FUN-06','mixed','hard','mcq','A graph has a point at (−2,0). Where is the corresponding point on y=f(x−5)+7?','["(3,7)","(−7,7)","(3,−7)","(−7,−7)"]','A','The transformation shifts every point 5 right and 7 up, so (−2,0) maps to (3,7).','На графике есть точка (−2,0). Где окажется соответствующая точка графика y=f(x−5)+7?','["(3,7)","(−7,7)","(3,−7)","(−7,−7)"]','Преобразование сдвигает каждую точку на 5 вправо и на 7 вверх, поэтому (−2,0) переходит в (3,7).','Grafikda (−2,0) nuqta bor. y=f(x−5)+7 grafigidagi mos nuqta qayerda bo‘ladi?','["(3,7)","(−7,7)","(3,−7)","(−7,−7)"]','Almashtirish har bir nuqtani 5 birlik o‘ngga va 7 birlik yuqoriga siljitadi, shuning uchun (−2,0) nuqta (3,7) ga o‘tadi.',90),
('P1FUN07-D02','P1-FUN-07','diagnostic','medium','mcq','The point (−3,7) lies on y=f(x). Which point lies on y=−f(x)?','["(3,7)","(3,−7)","(−3,−7)","(−7,−3)"]','C','Multiplying the output by −1 reflects in the x-axis, so x stays −3 and y becomes −7.','Точка (−3,7) лежит на y=f(x). Какая точка лежит на y=−f(x)?','["(3,7)","(3,−7)","(−3,−7)","(−7,−3)"]','Умножение значения функции на −1 отражает график относительно оси x: x остаётся −3, а y становится −7.','(−3,7) nuqta y=f(x) grafigida yotadi. Qaysi nuqta y=−f(x) grafigida yotadi?','["(3,7)","(3,−7)","(−3,−7)","(−7,−3)"]','Funksiya qiymatini −1 ga ko‘paytirish grafikni x o‘qiga nisbatan akslantiradi: x −3 bo‘lib qoladi, y esa −7 bo‘ladi.',70),
('P1FUN07-D03','P1-FUN-07','diagnostic','medium','mcq','The point (5,−2) lies on y=f(x). Which point lies on y=f(−x)?','["(5,2)","(−5,2)","(2,−5)","(−5,−2)"]','D','Replacing x by −x reflects in the y-axis, so (5,−2) maps to (−5,−2).','Точка (5,−2) лежит на y=f(x). Какая точка лежит на y=f(−x)?','["(5,2)","(−5,2)","(2,−5)","(−5,−2)"]','Замена x на −x отражает график относительно оси y, поэтому (5,−2) переходит в (−5,−2).','(5,−2) nuqta y=f(x) grafigida yotadi. Qaysi nuqta y=f(−x) grafigida yotadi?','["(5,2)","(−5,2)","(2,−5)","(−5,−2)"]','x ni −x ga almashtirish grafikni y o‘qiga nisbatan akslantiradi, shuning uchun (5,−2) nuqta (−5,−2) ga o‘tadi.',70),
('P1FUN07-R03','P1-FUN-07','retest','medium','input','The point (−6,4) lies on y=f(x). On y=−f(−x), enter the sum of the coordinates of the corresponding point.','[]','2','Both coordinates change sign, giving (6,−4); the sum is 2.','Точка (−6,4) лежит на y=f(x). Для y=−f(−x) введите сумму координат соответствующей точки.','[]','Обе координаты меняют знак: получаем (6,−4), сумма равна 2.','(−6,4) nuqta y=f(x) grafigida yotadi. y=−f(−x) dagi mos nuqta koordinatalari yig‘indisini kiriting.','[]','Ikkala koordinata ishorasi o‘zgaradi: (6,−4), yig‘indi 2.',70),
('P1FUN07-R04','P1-FUN-07','retest','medium','mcq','What is the combined effect of y=−f(−x) on the graph y=f(x)?','["Reflection in the x-axis only","Reflection in the y-axis only","Translation through the origin","Reflection in both coordinate axes"]','D','The inside minus reflects in the y-axis and the outside minus reflects in the x-axis.','Каково совместное действие y=−f(−x) на график y=f(x)?','["Только отражение относительно оси x","Только отражение относительно оси y","Перенос через начало координат","Отражение относительно обеих координатных осей"]','Внутренний минус даёт отражение относительно оси y, внешний минус — относительно оси x.','y=−f(−x) y=f(x) grafigiga qanday umumiy ta’sir qiladi?','["Faqat x o‘qiga nisbatan akslantirish","Faqat y o‘qiga nisbatan akslantirish","Koordinata boshidan ko‘chirish","Ikkala koordinata o‘qiga nisbatan akslantirish"]','Ichki minus y o‘qiga, tashqi minus x o‘qiga nisbatan akslantirish beradi.',70),
('P1FUN07-M02','P1-FUN-07','mixed','hard','mcq','A point P(a,b) on y=f(x) is mapped to P′(−a,−b). Which transformed graph produces this mapping?','["y=f(−x)","y=−f(x)","y=−f(−x)","y=f(x)+1"]','C','Both x and y change sign, so the graph is reflected in both coordinate axes: y=−f(−x).','Точка P(a,b) на y=f(x) переходит в P′(−a,−b). Какой преобразованный график даёт такое отображение?','["y=f(−x)","y=−f(x)","y=−f(−x)","y=f(x)+1"]','И x, и y меняют знак, поэтому график отражается относительно обеих осей: y=−f(−x).','y=f(x) dagi P(a,b) nuqta P′(−a,−b) ga o‘tadi. Qaysi o‘zgargan grafik bunday akslantirishni beradi?','["y=f(−x)","y=−f(x)","y=−f(−x)","y=f(x)+1"]','x ham, y ham ishorasini o‘zgartiradi, demak grafik ikkala o‘qqa nisbatan akslanadi: y=−f(−x).',90),
('P1FUN08-D02','P1-FUN-08','diagnostic','medium','mcq','The point (8,−3) lies on y=f(x). Which point lies on y=4f(2x)?','["(4,−12)","(16,−12)","(4,−3/4)","(16,−3/4)"]','A','For f(2x), x-coordinates are halved; the outside factor 4 multiplies y-values by 4. Thus (8,−3) maps to (4,−12).','Точка (8,−3) лежит на y=f(x). Какая точка лежит на y=4f(2x)?','["(4,−12)","(16,−12)","(4,−3/4)","(16,−3/4)"]','Для f(2x) x-координаты уменьшаются вдвое; внешний множитель 4 умножает y на 4. Поэтому (8,−3) переходит в (4,−12).','(8,−3) nuqta y=f(x) grafigida yotadi. Qaysi nuqta y=4f(2x) grafigida yotadi?','["(4,−12)","(16,−12)","(4,−3/4)","(16,−3/4)"]','f(2x) da x-koordinatalar ikki marta kamayadi; tashqi 4 y-qiymatlarni 4 ga ko‘paytiradi. Demak (8,−3) nuqta (4,−12) ga o‘tadi.',70),
('P1FUN08-D03','P1-FUN-08','diagnostic','medium','mcq','What is the horizontal scale factor from y=f(x) to y=f(x/4)?','["1/4","4","−4","1"]','B','To reproduce an original input u, x/4=u, so x=4u. Horizontal coordinates are multiplied by 4.','Каков коэффициент горизонтального масштабирования при переходе от y=f(x) к y=f(x/4)?','["1/4","4","−4","1"]','Чтобы получить исходный аргумент u, нужно x/4=u, то есть x=4u. Горизонтальные координаты умножаются на 4.','y=f(x) dan y=f(x/4) ga o‘tganda gorizontal masshtab koeffitsiyenti qanday?','["1/4","4","−4","1"]','Dastlabki u argumentni olish uchun x/4=u, ya’ni x=4u. Gorizontal koordinatalar 4 ga ko‘payadi.',70),
('P1FUN08-R03','P1-FUN-08','retest','medium','input','The point (−10,6) lies on y=f(x). On y=0.5f(5x), enter the sum of the coordinates of the corresponding point.','[]','1','The point maps to (−2,3), so the coordinate sum is 1.','Точка (−10,6) лежит на y=f(x). Для y=0.5f(5x) введите сумму координат соответствующей точки.','[]','Точка переходит в (−2,3), поэтому сумма координат равна 1.','(−10,6) nuqta y=f(x) grafigida yotadi. y=0.5f(5x) dagi mos nuqta koordinatalari yig‘indisini kiriting.','[]','Nuqta (−2,3) ga o‘tadi, koordinatalar yig‘indisi 1.',70),
('P1FUN08-R04','P1-FUN-08','retest','medium','mcq','The point (−3,5) lies on y=f(x). Which point lies on y=3f(x)?','["(−9,5)","(−1,5)","(−3,15)","(−3,5/3)"]','C','The outside factor 3 multiplies y-values only, so (−3,5) maps to (−3,15).','Точка (−3,5) лежит на y=f(x). Какая точка лежит на y=3f(x)?','["(−9,5)","(−1,5)","(−3,15)","(−3,5/3)"]','Внешний множитель 3 умножает только y-координаты, поэтому (−3,5) переходит в (−3,15).','(−3,5) nuqta y=f(x) grafigida yotadi. Qaysi nuqta y=3f(x) grafigida yotadi?','["(−9,5)","(−1,5)","(−3,15)","(−3,5/3)"]','Tashqi 3 faqat y-qiymatlarni ko‘paytiradi, shuning uchun (−3,5) nuqta (−3,15) ga o‘tadi.',70),
('P1FUN08-M02','P1-FUN-08','mixed','hard','mcq','The point (9,4) lies on y=f(x). Which point lies on y=−2f(x/3)?','["(3,−8)","(27,8)","(3,8)","(27,−8)"]','D','For f(x/3), x-coordinates are multiplied by 3, and −2 multiplies y-values by −2. Thus (9,4) maps to (27,−8).','Точка (9,4) лежит на y=f(x). Какая точка лежит на y=−2f(x/3)?','["(3,−8)","(27,8)","(3,8)","(27,−8)"]','Для f(x/3) x-координаты умножаются на 3, а −2 умножает y на −2. Поэтому (9,4) переходит в (27,−8).','(9,4) nuqta y=f(x) grafigida yotadi. Qaysi nuqta y=−2f(x/3) grafigida yotadi?','["(3,−8)","(27,8)","(3,8)","(27,−8)"]','f(x/3) da x-koordinatalar 3 ga ko‘payadi, −2 esa y-qiymatni −2 ga ko‘paytiradi. Demak (9,4) nuqta (27,−8) ga o‘tadi.',90),
('P1COO01-D02','P1-COO-01','diagnostic','medium','mcq','A line has gradient 5 and passes through (−1,2). Which equation represents the line?','["y=5x−3","y=−5x−3","y=5x+7","y=−5x+7"]','C','Using y−2=5(x+1) gives y=5x+7.','Прямая имеет градиент 5 и проходит через (−1,2). Какое уравнение задаёт эту прямую?','["y=5x−3","y=−5x−3","y=5x+7","y=−5x+7"]','По формуле y−2=5(x+1) получаем y=5x+7.','To‘g‘ri chiziq gradienti 5 va u (−1,2) nuqtadan o‘tadi. Qaysi tenglama shu chiziqni ifodalaydi?','["y=5x−3","y=−5x−3","y=5x+7","y=−5x+7"]','y−2=5(x+1) dan y=5x+7 hosil bo‘ladi.',70),
('P1COO01-D03','P1-COO-01','diagnostic','medium','mcq','Which equation is the line through (3,−2) and (7,10)?','["y=3x+11","y=−3x+7","y=2x−8","y=3x−11"]','D','The gradient is (10−(−2))/(7−3)=12/4=3. Using (3,−2), −2=9+c, so c=−11.','Какое уравнение задаёт прямую через точки (3,−2) и (7,10)?','["y=3x+11","y=−3x+7","y=2x−8","y=3x−11"]','Градиент равен (10−(−2))/(7−3)=12/4=3. Подставляя (3,−2): −2=9+c, поэтому c=−11.','Qaysi tenglama (3,−2) va (7,10) nuqtalardan o‘tuvchi chiziqni ifodalaydi?','["y=3x+11","y=−3x+7","y=2x−8","y=3x−11"]','Gradient (10−(−2))/(7−3)=12/4=3. (3,−2) ni qo‘ysak, −2=9+c, demak c=−11.',70),
('P1COO01-R03','P1-COO-01','retest','medium','input','The line 6x+3y=21 is written as y=mx+c. Enter c.','[]','7','3y=21−6x, so y=−2x+7 and c=7.','Прямая 6x+3y=21 записана в виде y=mx+c. Введите c.','[]','3y=21−6x, поэтому y=−2x+7 и c=7.','6x+3y=21 chiziq y=mx+c ko‘rinishida yozildi. c ni kiriting.','[]','3y=21−6x, demak y=−2x+7 va c=7.',70),
('P1COO01-R04','P1-COO-01','retest','medium','mcq','A line has gradient −2 and passes through (4,1). Which equation is correct?','["y=−2x−7","y=2x−7","y=2x+9","y=−2x+9"]','D','Using y−1=−2(x−4) gives y=−2x+9.','Прямая имеет градиент −2 и проходит через (4,1). Какое уравнение верно?','["y=−2x−7","y=2x−7","y=2x+9","y=−2x+9"]','По формуле y−1=−2(x−4) получаем y=−2x+9.','To‘g‘ri chiziq gradienti −2 va u (4,1) nuqtadan o‘tadi. Qaysi tenglama to‘g‘ri?','["y=−2x−7","y=2x−7","y=2x+9","y=−2x+9"]','y−1=−2(x−4) dan y=−2x+9 hosil bo‘ladi.',70),
('P1COO01-M02','P1-COO-01','mixed','hard','mcq','The line through A(−4,7) and B(2,−5) is written as y=mx+c. Which pair (m,c) is correct?','["(−2,−1)","(2,−1)","(−2,1)","(2,1)"]','A','The gradient is (−5−7)/(2−(−4))=−12/6=−2. Substitution gives c=−1.','Прямая через A(−4,7) и B(2,−5) записана как y=mx+c. Какая пара (m,c) верна?','["(−2,−1)","(2,−1)","(−2,1)","(2,1)"]','Градиент равен (−5−7)/(2−(−4))=−12/6=−2. Подстановка даёт c=−1.','A(−4,7) va B(2,−5) nuqtalardan o‘tuvchi chiziq y=mx+c ko‘rinishida. Qaysi (m,c) juftlik to‘g‘ri?','["(−2,−1)","(2,−1)","(−2,1)","(2,1)"]','Gradient (−5−7)/(2−(−4))=−12/6=−2. Qo‘yib hisoblasak c=−1.',90),
('P1COO02-D02','P1-COO-02','diagnostic','medium','mcq','What is the midpoint of the line segment joining (−6,4) and (2,−8)?','["(−2,−2)","(−4,−4)","(2,2)","(−2,2)"]','A','Average the coordinates: ((−6+2)/2,(4−8)/2)=(−2,−2).','Какова середина отрезка с концами (−6,4) и (2,−8)?','["(−2,−2)","(−4,−4)","(2,2)","(−2,2)"]','Усредняем координаты: ((−6+2)/2,(4−8)/2)=(−2,−2).','(−6,4) va (2,−8) nuqtalarni tutashtiruvchi kesmaning o‘rta nuqtasi qaysi?','["(−2,−2)","(−4,−4)","(2,2)","(−2,2)"]','Koordinatalarni o‘rtachalaymiz: ((−6+2)/2,(4−8)/2)=(−2,−2).',70),
('P1COO02-D03','P1-COO-02','diagnostic','medium','mcq','Find the distance between (2,−1) and (8,7).','["8","10","14","√68"]','B','The differences are 6 and 8, so the distance is √(6²+8²)=10.','Найдите расстояние между точками (2,−1) и (8,7).','["8","10","14","√68"]','Разности координат равны 6 и 8, поэтому расстояние √(6²+8²)=10.','(2,−1) va (8,7) nuqtalar orasidagi masofani toping.','["8","10","14","√68"]','Koordinatalar farqi 6 va 8, shuning uchun masofa √(6²+8²)=10.',70),
('P1COO02-R03','P1-COO-02','retest','medium','input','The lines y=4x−1 and y=−2x+11 intersect. Enter the x-coordinate of the intersection.','[]','2','At the intersection, 4x−1=−2x+11, so 6x=12 and x=2.','Прямые y=4x−1 и y=−2x+11 пересекаются. Введите x-координату точки пересечения.','[]','В точке пересечения 4x−1=−2x+11, поэтому 6x=12 и x=2.','y=4x−1 va y=−2x+11 chiziqlar kesishadi. Kesishish nuqtasining x-koordinatasini kiriting.','[]','Kesishish nuqtasida 4x−1=−2x+11, demak 6x=12 va x=2.',70),
('P1COO02-R04','P1-COO-02','retest','medium','mcq','The midpoint of A(−7,5) and B(5,−3) is:','["(−1,1)","(−6,2)","(1,−1)","(−1,4)"]','A','The midpoint is ((−7+5)/2,(5−3)/2)=(−1,1).','Середина отрезка с концами A(−7,5) и B(5,−3) равна:','["(−1,1)","(−6,2)","(1,−1)","(−1,4)"]','Середина равна ((−7+5)/2,(5−3)/2)=(−1,1).','A(−7,5) va B(5,−3) kesmaning o‘rta nuqtasi:','["(−1,1)","(−6,2)","(1,−1)","(−1,4)"]','O‘rta nuqta ((−7+5)/2,(5−3)/2)=(−1,1).',70),
('P1COO02-M02','P1-COO-02','mixed','hard','mcq','A=(0,0) and B=(6,8). M is the midpoint of AB. What is the distance AM?','["4","5","6","10"]','B','M=(3,4), so AM=√(3²+4²)=5.','A=(0,0), B=(6,8). M — середина AB. Чему равно расстояние AM?','["4","5","6","10"]','M=(3,4), поэтому AM=√(3²+4²)=5.','A=(0,0), B=(6,8). M — AB kesmaning o‘rta nuqtasi. AM masofa qancha?','["4","5","6","10"]','M=(3,4), shuning uchun AM=√(3²+4²)=5.',90),
('P1COO03-D02','P1-COO-03','diagnostic','medium','mcq','A line has gradient −4/5. What is the gradient of a perpendicular line?','["−5/4","4/5","5/4","−4/5"]','C','The perpendicular gradient is the negative reciprocal, so it is 5/4.','Прямая имеет градиент −4/5. Каков градиент перпендикулярной прямой?','["−5/4","4/5","5/4","−4/5"]','Градиент перпендикуляра — отрицательная обратная величина, то есть 5/4.','To‘g‘ri chiziq gradienti −4/5. Unga perpendikulyar chiziq gradienti qanday?','["−5/4","4/5","5/4","−4/5"]','Perpendikulyar gradient manfiy teskari qiymat bo‘ladi, ya’ni 5/4.',70),
('P1COO03-D03','P1-COO-03','diagnostic','medium','mcq','Which line is parallel to 2x−3y=6?','["y=−(2/3)x+1","y=(3/2)x−4","y=−(3/2)x+2","y=(2/3)x+5"]','D','2x−3y=6 gives y=(2/3)x−2. A parallel line must also have gradient 2/3.','Какая прямая параллельна 2x−3y=6?','["y=−(2/3)x+1","y=(3/2)x−4","y=−(3/2)x+2","y=(2/3)x+5"]','Из 2x−3y=6 получаем y=(2/3)x−2. Параллельная прямая должна иметь тот же градиент 2/3.','Qaysi chiziq 2x−3y=6 chiziqqa parallel?','["y=−(2/3)x+1","y=(3/2)x−4","y=−(3/2)x+2","y=(2/3)x+5"]','2x−3y=6 dan y=(2/3)x−2. Parallel chiziq ham 2/3 gradientga ega bo‘lishi kerak.',70),
('P1COO03-R03','P1-COO-03','retest','medium','input','A line through (1,3) is perpendicular to y=−2x+5. Enter the x-coordinate where this perpendicular line meets the x-axis.','[]','-5','The perpendicular gradient is 1/2. y−3=(1/2)(x−1); setting y=0 gives x=−5.','Прямая через (1,3) перпендикулярна y=−2x+5. Введите x-координату её пересечения с осью x.','[]','Градиент перпендикуляра равен 1/2. y−3=(1/2)(x−1); при y=0 получаем x=−5.','(1,3) nuqtadan o‘tuvchi chiziq y=−2x+5 ga perpendikulyar. Uning x o‘qini kesish nuqtasining x-koordinatasini kiriting.','[]','Perpendikulyar gradient 1/2. y−3=(1/2)(x−1); y=0 bo‘lsa x=−5.',70),
('P1COO03-R04','P1-COO-03','retest','medium','mcq','Which line is perpendicular to y=−(1/3)x+4?','["y=−3x+1","y=(1/3)x−2","y=3x−5","y=−(1/3)x+9"]','C','The negative reciprocal of −1/3 is 3, so a perpendicular line has gradient 3.','Какая прямая перпендикулярна y=−(1/3)x+4?','["y=−3x+1","y=(1/3)x−2","y=3x−5","y=−(1/3)x+9"]','Отрицательная обратная величина к −1/3 равна 3, поэтому перпендикуляр имеет градиент 3.','Qaysi chiziq y=−(1/3)x+4 ga perpendikulyar?','["y=−3x+1","y=(1/3)x−2","y=3x−5","y=−(1/3)x+9"]','−1/3 ning manfiy teskari qiymati 3, shuning uchun perpendikulyar chiziq gradienti 3.',70),
('P1COO03-M02','P1-COO-03','mixed','hard','mcq','The line through A(−1,2) and B(3,4) has gradient 1/2. Which equation is the line through P(2,−3) perpendicular to AB?','["y=2x−7","y=−2x+1","y=(1/2)x−4","y=−(1/2)x−2"]','B','The perpendicular gradient is −2. Using P gives y+3=−2(x−2), hence y=−2x+1.','Прямая через A(−1,2) и B(3,4) имеет градиент 1/2. Какое уравнение задаёт прямую через P(2,−3), перпендикулярную AB?','["y=2x−7","y=−2x+1","y=(1/2)x−4","y=−(1/2)x−2"]','Градиент перпендикуляра равен −2. Через P: y+3=−2(x−2), откуда y=−2x+1.','A(−1,2) va B(3,4) dan o‘tuvchi chiziq gradienti 1/2. P(2,−3) dan o‘tib AB ga perpendikulyar chiziq tenglamasi qaysi?','["y=2x−7","y=−2x+1","y=(1/2)x−4","y=−(1/2)x−2"]','Perpendikulyar gradient −2. P orqali: y+3=−2(x−2), demak y=−2x+1.',90),
('P1CIR01-D02','P1-CIR-01','diagnostic','medium','mcq','Convert 330° to radians.','["11π/6","5π/6","11π/12","3π/2"]','A','330×π/180=11π/6.','Переведите 330° в радианы.','["11π/6","5π/6","11π/12","3π/2"]','330×π/180=11π/6.','330° ni radianlarga o‘tkazing.','["11π/6","5π/6","11π/12","3π/2"]','330×π/180=11π/6.',70),
('P1CIR01-D03','P1-CIR-01','diagnostic','medium','mcq','Convert 13π/12 radians to degrees.','["165°","195°","210°","225°"]','B','(13π/12)×180/π=195°.','Переведите 13π/12 радиан в градусы.','["165°","195°","210°","225°"]','(13π/12)×180/π=195°.','13π/12 radianlarni gradusga o‘tkazing.','["165°","195°","210°","225°"]','(13π/12)×180/π=195°.',70),
('P1CIR01-R03','P1-CIR-01','retest','medium','input','Enter 5π/9 radians in degrees.','[]','100','(5π/9)×180/π=100°.','Введите 5π/9 радиан в градусах.','[]','(5π/9)×180/π=100°.','5π/9 radianni gradusda kiriting.','[]','(5π/9)×180/π=100°.',70),
('P1CIR01-R04','P1-CIR-01','retest','medium','mcq','Convert 72° to radians.','["3π/5","2π/5","π/5","5π/2"]','B','72×π/180=2π/5.','Переведите 72° в радианы.','["3π/5","2π/5","π/5","5π/2"]','72×π/180=2π/5.','72° ni radianlarga o‘tkazing.','["3π/5","2π/5","π/5","5π/2"]','72×π/180=2π/5.',70),
('P1CIR01-M02','P1-CIR-01','mixed','hard','mcq','An angle is 7π/12 radians plus 15°. What is the total angle in radians?','["3π/4","2π/3","5π/6","7π/9"]','B','7π/12=105°; adding 15° gives 120°=2π/3.','Угол равен 7π/12 радиан плюс 15°. Чему равен общий угол в радианах?','["3π/4","2π/3","5π/6","7π/9"]','7π/12=105°; прибавляем 15° и получаем 120°=2π/3.','Burchak 7π/12 radian va yana 15° dan iborat. Umumiy burchak radianlarda qancha?','["3π/4","2π/3","5π/6","7π/9"]','7π/12=105°; 15° qo‘shilsa 120°=2π/3.',90),
('P1TRI01-D02','P1-TRI-01','diagnostic','medium','mcq','What is the period of y=cos(3x)?','["6π","3π","2π/3","π/3"]','C','For cos(kx), the period is 2π/|k|, so it is 2π/3.','Каков период функции y=cos(3x)?','["6π","3π","2π/3","π/3"]','Для cos(kx) период равен 2π/|k|, поэтому получаем 2π/3.','y=cos(3x) funksiyaning davri qanday?','["6π","3π","2π/3","π/3"]','cos(kx) uchun davr 2π/|k|, shuning uchun 2π/3.',70),
('P1TRI01-D03','P1-TRI-01','diagnostic','medium','mcq','What is the range of y=4sin x−2?','["−4≤y≤4","−2≤y≤6","−8≤y≤0","−6≤y≤2"]','D','Since −1≤sin x≤1, 4sin x lies between −4 and 4; subtracting 2 gives −6≤y≤2.','Какова область значений y=4sin x−2?','["−4≤y≤4","−2≤y≤6","−8≤y≤0","−6≤y≤2"]','Так как −1≤sin x≤1, 4sin x находится между −4 и 4; после вычитания 2 получаем −6≤y≤2.','y=4sin x−2 funksiyaning qiymatlar sohasi qaysi?','["−4≤y≤4","−2≤y≤6","−8≤y≤0","−6≤y≤2"]','−1≤sin x≤1 bo‘lgani uchun 4sin x −4 va 4 orasida; 2 ayirilsa −6≤y≤2.',70),
('P1TRI01-R03','P1-TRI-01','retest','medium','input','Enter the maximum value of y=−2cos x+5.','[]','7','The maximum occurs when cos x=−1, giving −2(−1)+5=7.','Введите максимальное значение y=−2cos x+5.','[]','Максимум достигается при cos x=−1: −2(−1)+5=7.','y=−2cos x+5 funksiyaning eng katta qiymatini kiriting.','[]','Maksimum cos x=−1 bo‘lganda: −2(−1)+5=7.',70),
('P1TRI01-R04','P1-TRI-01','retest','medium','mcq','Where is the first positive vertical asymptote of y=tan(2x)?','["x=π/8","x=π/2","x=π/4","x=π"]','C','tan u has an asymptote at u=π/2. Setting 2x=π/2 gives x=π/4.','Где находится первая положительная вертикальная асимптота y=tan(2x)?','["x=π/8","x=π/2","x=π/4","x=π"]','У tan u асимптота при u=π/2. Из 2x=π/2 получаем x=π/4.','y=tan(2x) funksiyaning birinchi musbat vertikal asimptotasi qayerda?','["x=π/8","x=π/2","x=π/4","x=π"]','tan u da asimptota u=π/2. 2x=π/2 dan x=π/4.',70),
('P1TRI01-M02','P1-TRI-01','mixed','hard','mcq','For y=3cos(x−π/6)−1, which statement is correct?','["The maximum value is 2 and one maximum occurs at x=π/6.","The maximum value is 4 and one maximum occurs at x=π/6.","The minimum value is −3 and one minimum occurs at x=π/6.","The period is π and the midline is y=−1."]','A','The cosine maximum is 1, so the graph reaches 3(1)−1=2 when x−π/6=0, i.e. x=π/6.','Какое утверждение верно для y=3cos(x−π/6)−1?','["Максимум равен 2, и один максимум достигается при x=π/6.","Максимум равен 4, и один максимум достигается при x=π/6.","Минимум равен −3, и один минимум достигается при x=π/6.","Период равен π, средняя линия y=−1."]','Максимум cos равен 1, поэтому график достигает 3·1−1=2 при x−π/6=0, то есть x=π/6.','y=3cos(x−π/6)−1 uchun qaysi tasdiq to‘g‘ri?','["Maksimum 2 va maksimumlardan biri x=π/6 da.","Maksimum 4 va maksimumlardan biri x=π/6 da.","Minimum −3 va minimumlardan biri x=π/6 da.","Davr π, o‘rta chiziq y=−1."]','cos ning maksimumi 1, shuning uchun grafik 3·1−1=2 ga x−π/6=0, ya’ni x=π/6 da erishadi.',95)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,'P1 Annual reserve',s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P1:p1_aw05_08_annual_reserve_topup_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P1:p1_aw05_08_annual_reserve_topup_draft_v1:'||s.content_key);

with keys(content_key,skill_code,reserve_role,meta_id,official_ref,book_ref) as (values
('P1FUN06-D02','P1-FUN-06','diagnostic',59088,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN06-D03','P1-FUN-06','diagnostic',59089,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN06-R03','P1-FUN-06','retest',59090,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN06-R04','P1-FUN-06','retest',59091,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN06-M02','P1-FUN-06','mixed',59092,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN07-D02','P1-FUN-07','diagnostic',59093,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN07-D03','P1-FUN-07','diagnostic',59094,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN07-R03','P1-FUN-07','retest',59095,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN07-R04','P1-FUN-07','retest',59096,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN07-M02','P1-FUN-07','mixed',59097,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN08-D02','P1-FUN-08','diagnostic',59098,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN08-D03','P1-FUN-08','diagnostic',59099,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN08-R03','P1-FUN-08','retest',59100,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN08-R04','P1-FUN-08','retest',59101,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1FUN08-M02','P1-FUN-08','mixed',59102,'Cambridge 9709 2026-2027 v4; P1 1.2 Functions','Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'),
('P1COO01-D02','P1-COO-01','diagnostic',59103,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO01-D03','P1-COO-01','diagnostic',59104,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO01-R03','P1-COO-01','retest',59105,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO01-R04','P1-COO-01','retest',59106,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO01-M02','P1-COO-01','mixed',59107,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO02-D02','P1-COO-02','diagnostic',59108,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO02-D03','P1-COO-02','diagnostic',59109,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO02-R03','P1-COO-02','retest',59110,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO02-R04','P1-COO-02','retest',59111,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO02-M02','P1-COO-02','mixed',59112,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO03-D02','P1-COO-03','diagnostic',59113,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO03-D03','P1-COO-03','diagnostic',59114,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO03-R03','P1-COO-03','retest',59115,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO03-R04','P1-COO-03','retest',59116,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1COO03-M02','P1-COO-03','mixed',59117,'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'),
('P1CIR01-D02','P1-CIR-01','diagnostic',59118,'Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
('P1CIR01-D03','P1-CIR-01','diagnostic',59119,'Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
('P1CIR01-R03','P1-CIR-01','retest',59120,'Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
('P1CIR01-R04','P1-CIR-01','retest',59121,'Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
('P1CIR01-M02','P1-CIR-01','mixed',59122,'Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure','Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'),
('P1TRI01-D02','P1-TRI-01','diagnostic',59123,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI01-D03','P1-TRI-01','diagnostic',59124,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI01-R03','P1-TRI-01','retest',59125,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI01-R04','P1-TRI-01','retest',59126,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)'),
('P1TRI01-M02','P1-TRI-01','mixed',59127,'Cambridge 9709 2026-2027 v4; P1 1.5 Trigonometry','Complete Pure Mathematics 1, Ch5 Trigonometry pp.86-104 (mapping only)')
)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,
 reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,
 official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,
 qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select k.meta_id,4807,k.content_key,q.id,k.skill_code,'{}'::text[],k.reserve_role,'withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'AW5-8 annual reserve top-up for future diagnostic, delayed-retest and transfer depth. It does not reinterpret any existing learner evidence.',
 k.official_ref,k.book_ref,'pending','pending','pending','pending','pending',
 case when k.reserve_role='diagnostic' then 'pending' else 'not_applicable' end,
 md5(concat_ws(chr(31),
   q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
   coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
   coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
   coalesce(q.image_url,''),coalesce(q.is_active::text,''),
   coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
   coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
   coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
   coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')
 ))
from keys k join public.questions q
 on q.book_ref='ExamPrep:P1:p1_aw05_08_annual_reserve_topup_draft_v1:'||k.content_key
on conflict(content_version_id,content_key) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int;
begin
 if (select status from private.exam_prep_content_versions where id=4807)<>'draft'
    or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4807)<>40
    or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4807 and reserve_role='diagnostic')<>16
    or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4807 and reserve_role='retest')<>16
    or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4807 and reserve_role='mixed')<>8
 then raise exception 'aw05_08_annual_reserve_p1_draft cardinality/state failure'; end if;

 select count(*) into v_bad from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
 where m.content_version_id=4807 and (
   m.lifecycle_state<>'draft' or m.exposure_state<>'withheld'
   or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
   or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
   or q.is_active or q.quality_status<>'draft'
   or nullif(btrim(q.question_text_en),'') is null or nullif(btrim(q.question_text_ru),'') is null or nullif(btrim(q.question_text_uz),'') is null
   or nullif(btrim(q.explanation_en),'') is null or nullif(btrim(q.explanation_ru),'') is null or nullif(btrim(q.explanation_uz),'') is null
 );
 if v_bad<>0 then raise exception 'aw05_08_annual_reserve_p1_draft governance/exposure rows=%',v_bad; end if;

 select
   count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
   count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D')
 into v_a,v_b,v_c,v_d
 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
 where m.content_version_id=4807 and m.reserve_role='diagnostic';
 if (v_a,v_b,v_c,v_d)<>(4,4,4,4) then
   raise exception 'aw05_08_annual_reserve_p1_draft diagnostic answer balance A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
 end if;

 if exists(
   select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
   join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4807
   join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
   join public.questions oldq on oldq.id=oldm.question_id
   where m.content_version_id=4807
     and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
 ) then raise exception 'aw05_08_annual_reserve_p1_draft exact published stem duplicate'; end if;

 if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4807)
    or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4807)
    or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4807)
 then raise exception 'aw05_08_annual_reserve_p1_draft unexpected history'; end if;
end
$postcheck$;

commit;
