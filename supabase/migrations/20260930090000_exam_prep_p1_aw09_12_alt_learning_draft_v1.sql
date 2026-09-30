-- AW9-12 supplemental learning pack draft for P1.
-- DRAFT ONLY: no learner exposure, QA self-approval or publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active') then
    raise exception 'aw09_12_alt_p1_draft canonical program missing';
  end if;
  if exists(select 1 from private.exam_prep_content_versions where id=4809 and content_version<>'p1_aw09_12_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15624 and 15631 and content_version_id<>4809)
     or exists(select 1 from private.exam_prep_assessments where id between 35373 and 35380 and content_version_id<>4809)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59158 and 59181 and content_version_id<>4809)
  then raise exception 'aw09_12_alt_p1_draft reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4809,pv.id,'p1_aw09_12_alt_learning_draft_v1','P1',
 'P1 AW9-12 supplemental learning pack draft v1','draft',
 'Original iClub-authored supplemental learning content. Official Cambridge 9709 scope and Complete Pure Mathematics 1 mappings define learning objectives only; no protected source question, solution, diagram or mark-scheme wording is copied. Independent academic, language, technical and copyright QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict (program_version_id,content_version) do nothing;

with src(content_key,skill_code,topic,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P1QUA04-A01','P1-QUA-04','P1 Quadratics','medium','mcq','Solve x²−5x+6<0.','["2<x<3","x<2 or x>3","x≤2 or x≥3","2≤x≤3"]','A','Factor x²−5x+6=(x−2)(x−3). The upward-opening quadratic is negative between its roots, so 2<x<3.','Решите неравенство x²−5x+6<0.','["2<x<3","x<2 или x>3","x≤2 или x≥3","2≤x≤3"]','Разложим: x²−5x+6=(x−2)(x−3). Парабола направлена вверх и отрицательна между корнями, поэтому 2<x<3.','x²−5x+6<0 tengsizlikni yeching.','["2<x<3","x<2 yoki x>3","x≤2 yoki x≥3","2≤x≤3"]','x²−5x+6=(x−2)(x−3). Parabola yuqoriga ochiladi va ildizlar orasida manfiy, shuning uchun 2<x<3.',55),
('P1QUA04-A02','P1-QUA-04','P1 Quadratics','medium','mcq','Solve 2x²+x−3≥0.','["−3/2≤x≤1","x≤−3/2 or x≥1","−1≤x≤3/2","x<−3/2 or x>1"]','B','2x²+x−3=(2x+3)(x−1). The quadratic opens upward, so it is non-negative outside the roots, including the endpoints.','Решите неравенство 2x²+x−3≥0.','["−3/2≤x≤1","x≤−3/2 или x≥1","−1≤x≤3/2","x<−3/2 или x>1"]','2x²+x−3=(2x+3)(x−1). Парабола направлена вверх, поэтому выражение неотрицательно вне промежутка между корнями, включая сами корни.','2x²+x−3≥0 tengsizlikni yeching.','["−3/2≤x≤1","x≤−3/2 yoki x≥1","−1≤x≤3/2","x<−3/2 yoki x>1"]','2x²+x−3=(2x+3)(x−1). Parabola yuqoriga ochiladi, shuning uchun ifoda ildizlar oralig‘idan tashqarida, chegaralarni ham qo‘shgan holda, manfiy emas.',60),
('P1QUA04-A03','P1-QUA-04','P1 Quadratics','medium','input','The solution of x²−8x+12≤0 is a closed interval. Enter the length of this interval.','[]','4','x²−8x+12=(x−2)(x−6), so the solution is 2≤x≤6. Its length is 6−2=4.','Решение неравенства x²−8x+12≤0 является замкнутым промежутком. Введите длину этого промежутка.','[]','x²−8x+12=(x−2)(x−6), поэтому 2≤x≤6. Длина промежутка равна 6−2=4.','x²−8x+12≤0 tengsizlik yechimi yopiq oraliqdir. Shu oraliq uzunligini kiriting.','[]','x²−8x+12=(x−2)(x−6), demak 2≤x≤6. Oraliq uzunligi 6−2=4.',55),
('P1QUA05-A01','P1-QUA-05','P1 Quadratics','medium','mcq','The curves y=x+1 and y=x²−3x+3 intersect at two points. Which are the x-coordinates of the intersections?','["1±√2","3±√2","2±√2","2±2√2"]','C','Set the equations equal: x+1=x²−3x+3, so x²−4x+2=0. Hence x=(4±√8)/2=2±√2.','Кривые y=x+1 и y=x²−3x+3 пересекаются в двух точках. Каковы x-координаты точек пересечения?','["1±√2","3±√2","2±√2","2±2√2"]','Приравниваем: x+1=x²−3x+3, поэтому x²−4x+2=0. Отсюда x=(4±√8)/2=2±√2.','y=x+1 va y=x²−3x+3 egri chiziqlar ikki nuqtada kesishadi. Kesishish nuqtalarining x-koordinatalari qaysilar?','["1±√2","3±√2","2±√2","2±2√2"]','Tenglashtiramiz: x+1=x²−3x+3, bundan x²−4x+2=0. Shuning uchun x=(4±√8)/2=2±√2.',65),
('P1QUA05-A02','P1-QUA-05','P1 Quadratics','medium','mcq','The system x+y=7 and xy=12 has two ordered solutions. Which pair of points is correct?','["(2,5) and (5,2)","(1,6) and (6,1)","(−3,−4) and (−4,−3)","(3,4) and (4,3)"]','D','If x and y have sum 7 and product 12, they are the roots of t²−7t+12=0=(t−3)(t−4). Thus the ordered solutions are (3,4) and (4,3).','Система x+y=7 и xy=12 имеет два упорядоченных решения. Какая пара точек верна?','["(2,5) и (5,2)","(1,6) и (6,1)","(−3,−4) и (−4,−3)","(3,4) и (4,3)"]','Если сумма x и y равна 7, а произведение 12, то они являются корнями t²−7t+12=0=(t−3)(t−4). Поэтому решения: (3,4) и (4,3).','x+y=7 va xy=12 sistema ikkita tartibli yechimga ega. Qaysi nuqtalar jufti to‘g‘ri?','["(2,5) va (5,2)","(1,6) va (6,1)","(−3,−4) va (−4,−3)","(3,4) va (4,3)"]','x va y yig‘indisi 7, ko‘paytmasi 12 bo‘lsa, ular t²−7t+12=0=(t−3)(t−4) tenglama ildizlari. Demak yechimlar (3,4) va (4,3).',60),
('P1QUA05-A03','P1-QUA-05','P1 Quadratics','hard','input','The line y=x+1 intersects the circle x²+y²=25 at two points. Enter the sum of the x-coordinates of the two intersection points.','[]','-1','Substitute y=x+1: x²+(x+1)²=25, giving 2x²+2x−24=0 or x²+x−12=0. The sum of the roots is −1.','Прямая y=x+1 пересекает окружность x²+y²=25 в двух точках. Введите сумму x-координат этих точек.','[]','Подставляем y=x+1: x²+(x+1)²=25, получаем 2x²+2x−24=0, то есть x²+x−12=0. Сумма корней равна −1.','y=x+1 chiziq x²+y²=25 aylanani ikki nuqtada kesadi. Shu ikki nuqta x-koordinatalari yig‘indisini kiriting.','[]','y=x+1 ni qo‘yamiz: x²+(x+1)²=25, bundan 2x²+2x−24=0, ya’ni x²+x−12=0. Ildizlar yig‘indisi −1.',70),
('P1QUA06-A01','P1-QUA-06','P1 Quadratics','hard','mcq','How many real solutions does (x+1)⁴−5(x+1)²+4=0 have?','["4","2","3","0"]','A','Let u=(x+1)². Then u²−5u+4=0, so u=1 or 4. Thus x+1=±1 or ±2, giving four distinct real solutions.','Сколько действительных решений имеет уравнение (x+1)⁴−5(x+1)²+4=0?','["4","2","3","0"]','Положим u=(x+1)². Тогда u²−5u+4=0, поэтому u=1 или 4. Получаем x+1=±1 или ±2, то есть четыре различных действительных решения.','(x+1)⁴−5(x+1)²+4=0 tenglama nechta haqiqiy yechimga ega?','["4","2","3","0"]','u=(x+1)² deb olamiz. Unda u²−5u+4=0, demak u=1 yoki 4. Shundan x+1=±1 yoki ±2, ya’ni to‘rtta turli haqiqiy yechim chiqadi.',70),
('P1QUA06-A02','P1-QUA-06','P1 Quadratics','medium','mcq','For (x²−3x)²−5(x²−3x)+6=0, which values should the transformed variable u=x²−3x take?','["u=−2 or −3","u=1 or 6","u=2 or 3","u=−1 or 6"]','C','With u=x²−3x, the equation becomes u²−5u+6=0=(u−2)(u−3), so u=2 or 3.','Для уравнения (x²−3x)²−5(x²−3x)+6=0 какие значения принимает новая переменная u=x²−3x?','["u=−2 или −3","u=1 или 6","u=2 или 3","u=−1 или 6"]','При u=x²−3x получаем u²−5u+6=0=(u−2)(u−3), поэтому u=2 или 3.','(x²−3x)²−5(x²−3x)+6=0 tenglama uchun u=x²−3x yangi o‘zgaruvchi qaysi qiymatlarni oladi?','["u=−2 yoki −3","u=1 yoki 6","u=2 yoki 3","u=−1 yoki 6"]','u=x²−3x deb olsak, u²−5u+6=0=(u−2)(u−3) hosil bo‘ladi, demak u=2 yoki 3.',60),
('P1QUA06-A03','P1-QUA-06','P1 Quadratics','hard','input','Solve (2x−1)⁴−10(2x−1)²+9=0. Enter the sum of all distinct real solutions.','[]','2','Let u=(2x−1)². Then u²−10u+9=0, so u=1 or 9. Hence 2x−1=±1 or ±3, giving x=0,1,−1,2. Their sum is 2.','Решите (2x−1)⁴−10(2x−1)²+9=0. Введите сумму всех различных действительных решений.','[]','Положим u=(2x−1)². Тогда u²−10u+9=0, поэтому u=1 или 9. Отсюда 2x−1=±1 или ±3, то есть x=0,1,−1,2. Их сумма равна 2.','(2x−1)⁴−10(2x−1)²+9=0 tenglamani yeching. Barcha turli haqiqiy yechimlar yig‘indisini kiriting.','[]','u=(2x−1)² deb olamiz. Unda u²−10u+9=0, demak u=1 yoki 9. Shundan 2x−1=±1 yoki ±3, ya’ni x=0,1,−1,2. Ularning yig‘indisi 2.',75),
('P1FUN03-A01','P1-FUN-03','P1 Functions','medium','mcq','Let f(x)=√(x+1) and g(x)=2x−3. What is the real domain of (f∘g)(x)?','["x>1","x≥1","x≥−1","all real x"]','B','f(g(x))=√((2x−3)+1)=√(2x−2). For real values, 2x−2≥0, so x≥1.','Пусть f(x)=√(x+1), g(x)=2x−3. Какова область определения (f∘g)(x) в действительных числах?','["x>1","x≥1","x≥−1","все действительные x"]','f(g(x))=√((2x−3)+1)=√(2x−2). Для действительных значений нужно 2x−2≥0, поэтому x≥1.','f(x)=√(x+1), g(x)=2x−3 bo‘lsin. (f∘g)(x) ning haqiqiy sonlardagi aniqlanish sohasi qanday?','["x>1","x≥1","x≥−1","barcha haqiqiy x"]','f(g(x))=√((2x−3)+1)=√(2x−2). Haqiqiy qiymatlar uchun 2x−2≥0, demak x≥1.',60),
('P1FUN03-A02','P1-FUN-03','P1 Functions','hard','mcq','Let f(x)=1/(x−4) and g(x)=x²+1. Which restriction is required for the domain of (f∘g)(x)?','["x≠4","x≠±2","x≠3","x≠±√3"]','D','f(g(x))=1/(x²+1−4)=1/(x²−3). The denominator must be non-zero, so x≠±√3.','Пусть f(x)=1/(x−4), g(x)=x²+1. Какое ограничение требуется для области определения (f∘g)(x)?','["x≠4","x≠±2","x≠3","x≠±√3"]','f(g(x))=1/(x²+1−4)=1/(x²−3). Знаменатель не должен быть равен нулю, поэтому x≠±√3.','f(x)=1/(x−4), g(x)=x²+1 bo‘lsin. (f∘g)(x) aniqlanish sohasi uchun qaysi cheklov kerak?','["x≠4","x≠±2","x≠3","x≠±√3"]','f(g(x))=1/(x²+1−4)=1/(x²−3). Maxraj nol bo‘lmasligi kerak, shuning uchun x≠±√3.',65),
('P1FUN03-A03','P1-FUN-03','P1 Functions','medium','input','Let f(x)=3x−2 and g(x)=x². Enter the value of (g∘f)(2).','[]','16','f(2)=3(2)−2=4, and then g(4)=4²=16.','Пусть f(x)=3x−2, g(x)=x². Введите значение (g∘f)(2).','[]','f(2)=3·2−2=4, затем g(4)=4²=16.','f(x)=3x−2, g(x)=x² bo‘lsin. (g∘f)(2) qiymatini kiriting.','[]','f(2)=3·2−2=4, so‘ng g(4)=4²=16.',45),
('P1FUN04-A01','P1-FUN-04','P1 Functions','hard','mcq','Let f(x)=x²−4x+1 with domain x≥2. Which inverse is correct?','["f⁻¹(x)=2+√(x+3), x≥−3","f⁻¹(x)=2−√(x+3), x≥−3","f⁻¹(x)=√(x−1)+4, x≥1","f⁻¹(x)=±√(x+3)+2, all real x"]','A','f(x)=(x−2)²−3. On x≥2 the inverse uses the positive branch: x=2+√(y+3). The range of f, hence the domain of f⁻¹, is x≥−3.','Пусть f(x)=x²−4x+1 при x≥2. Какая обратная функция верна?','["f⁻¹(x)=2+√(x+3), x≥−3","f⁻¹(x)=2−√(x+3), x≥−3","f⁻¹(x)=√(x−1)+4, x≥1","f⁻¹(x)=±√(x+3)+2, все действительные x"]','f(x)=(x−2)²−3. При x≥2 для обратной функции берём положительную ветвь: x=2+√(y+3). Область значений f, а значит область определения f⁻¹, равна x≥−3.','f(x)=x²−4x+1, x≥2 bo‘lsin. Qaysi teskari funksiya to‘g‘ri?','["f⁻¹(x)=2+√(x+3), x≥−3","f⁻¹(x)=2−√(x+3), x≥−3","f⁻¹(x)=√(x−1)+4, x≥1","f⁻¹(x)=±√(x+3)+2, barcha haqiqiy x"]','f(x)=(x−2)²−3. x≥2 da teskari funksiya uchun musbat tarmoq olinadi: x=2+√(y+3). f ning qiymatlar sohasi, demak f⁻¹ ning aniqlanish sohasi x≥−3.',75),
('P1FUN04-A02','P1-FUN-04','P1 Functions','hard','mcq','Let f(x)=(2x+1)/(x−3), x≠3. Which formula and domain describe f⁻¹?','["(3x−1)/(x+2), x≠−2","(x+3)/(2x−1), x≠1/2","(3x+1)/(x+2), x≠−2","(3x+1)/(x−2), x≠2"]','D','From y=(2x+1)/(x−3), yx−3y=2x+1, so x(y−2)=3y+1. Hence x=(3y+1)/(y−2), giving f⁻¹(x)=(3x+1)/(x−2), x≠2.','Пусть f(x)=(2x+1)/(x−3), x≠3. Какая формула и область определения описывают f⁻¹?','["(3x−1)/(x+2), x≠−2","(x+3)/(2x−1), x≠1/2","(3x+1)/(x+2), x≠−2","(3x+1)/(x−2), x≠2"]','Из y=(2x+1)/(x−3) получаем yx−3y=2x+1, значит x(y−2)=3y+1. Поэтому x=(3y+1)/(y−2), и f⁻¹(x)=(3x+1)/(x−2), x≠2.','f(x)=(2x+1)/(x−3), x≠3 bo‘lsin. f⁻¹ ni qaysi formula va aniqlanish sohasi to‘g‘ri ifodalaydi?','["(3x−1)/(x+2), x≠−2","(x+3)/(2x−1), x≠1/2","(3x+1)/(x+2), x≠−2","(3x+1)/(x−2), x≠2"]','y=(2x+1)/(x−3) dan yx−3y=2x+1, ya’ni x(y−2)=3y+1. Demak x=(3y+1)/(y−2), shuning uchun f⁻¹(x)=(3x+1)/(x−2), x≠2.',75),
('P1FUN04-A03','P1-FUN-04','P1 Functions','medium','input','Let f(x)=5−3x. Enter f⁻¹(11).','[]','-2','f⁻¹(11) is the x-value for which f(x)=11. Solve 5−3x=11 to get x=−2.','Пусть f(x)=5−3x. Введите f⁻¹(11).','[]','f⁻¹(11) — это значение x, при котором f(x)=11. Решаем 5−3x=11 и получаем x=−2.','f(x)=5−3x bo‘lsin. f⁻¹(11) ni kiriting.','[]','f⁻¹(11) — f(x)=11 bo‘ladigan x qiymati. 5−3x=11 ni yechib, x=−2 ni olamiz.',45),
('P1FUN05-A01','P1-FUN-05','P1 Functions','medium','mcq','The point (−3,7) lies on the graph of a one-one function y=f(x). Which point lies on y=f⁻¹(x)?','["(7,−3)","(−7,3)","(3,−7)","(−3,7)"]','A','The graph of the inverse is the reflection of y=f(x) in y=x, so coordinates are swapped: (−3,7) becomes (7,−3).','Точка (−3,7) лежит на графике взаимно однозначной функции y=f(x). Какая точка лежит на y=f⁻¹(x)?','["(7,−3)","(−7,3)","(3,−7)","(−3,7)"]','График обратной функции получается отражением y=f(x) относительно y=x, поэтому координаты меняются местами: (−3,7) переходит в (7,−3).','(−3,7) nuqta bir qiymatli y=f(x) grafigida yotadi. y=f⁻¹(x) grafigida qaysi nuqta yotadi?','["(7,−3)","(−7,3)","(3,−7)","(−3,7)"]','Teskari funksiya grafigi y=f(x) ni y=x ga nisbatan akslantirish orqali olinadi, shuning uchun koordinatalar almashadi: (−3,7) → (7,−3).',50),
('P1FUN05-A02','P1-FUN-05','P1 Functions','medium','mcq','For f(x)=2x−5, which point lies on both y=f(x) and y=f⁻¹(x)?','["(0,−5)","(5,0)","(−5,−5)","(5,5)"]','D','A function and its inverse can intersect only on y=x. Solve 2x−5=x to get x=5, so the common point is (5,5).','Для f(x)=2x−5 какая точка лежит одновременно на y=f(x) и y=f⁻¹(x)?','["(0,−5)","(5,0)","(−5,−5)","(5,5)"]','Функция и её обратная могут пересекаться только на y=x. Решаем 2x−5=x и получаем x=5, поэтому общая точка — (5,5).','f(x)=2x−5 uchun qaysi nuqta ham y=f(x), ham y=f⁻¹(x) grafigida yotadi?','["(0,−5)","(5,0)","(−5,−5)","(5,5)"]','Funksiya va uning teskarisi faqat y=x chiziqda kesishishi mumkin. 2x−5=x dan x=5, demak umumiy nuqta (5,5).',55),
('P1FUN05-A03','P1-FUN-05','P1 Functions','medium','input','A one-one function y=f(x) has x-intercept (4,0). Enter the y-coordinate of the corresponding y-intercept of y=f⁻¹(x).','[]','4','Reflection in y=x swaps coordinates. The point (4,0) on f becomes (0,4) on f⁻¹, so the y-intercept is 4.','График взаимно однозначной функции y=f(x) пересекает ось x в точке (4,0). Введите y-координату соответствующей точки пересечения графика y=f⁻¹(x) с осью y.','[]','При отражении относительно y=x координаты меняются местами. Точка (4,0) переходит в (0,4), поэтому y-пересечение равно 4.','Bir qiymatli y=f(x) funksiya grafigi x o‘qini (4,0) nuqtada kesadi. y=f⁻¹(x) grafigining mos y o‘qi bilan kesishish nuqtasidagi y-koordinatani kiriting.','[]','y=x ga nisbatan akslantirish koordinatalarni almashtiradi. (4,0) nuqta (0,4) ga o‘tadi, demak y-kesishish qiymati 4.',45),
('P1COO04-A01','P1-COO-04','P1 Coordinate geometry','medium','mcq','Find the centre and radius of x²+y²+6x−8y−11=0.','["centre (3,−4), radius 6","centre (−3,4), radius 6","centre (−3,4), radius 36","centre (3,−4), radius 36"]','B','Complete the squares: (x+3)²−9+(y−4)²−16−11=0, so (x+3)²+(y−4)²=36. The centre is (−3,4) and the radius is 6.','Найдите центр и радиус окружности x²+y²+6x−8y−11=0.','["центр (3,−4), радиус 6","центр (−3,4), радиус 6","центр (−3,4), радиус 36","центр (3,−4), радиус 36"]','Дополняем до квадратов: (x+3)²−9+(y−4)²−16−11=0, поэтому (x+3)²+(y−4)²=36. Центр (−3,4), радиус 6.','x²+y²+6x−8y−11=0 aylananing markazi va radiusini toping.','["markaz (3,−4), radius 6","markaz (−3,4), radius 6","markaz (−3,4), radius 36","markaz (3,−4), radius 36"]','Kvadratlarni to‘ldiramiz: (x+3)²−9+(y−4)²−16−11=0, bundan (x+3)²+(y−4)²=36. Markaz (−3,4), radius 6.',65),
('P1COO04-A02','P1-COO-04','P1 Coordinate geometry','medium','mcq','A circle has centre (2,−3) and passes through (5,1). Which equation is correct?','["(x+2)²+(y−3)²=25","(x−2)²+(y+3)²=5","(x−2)²+(y+3)²=25","(x−5)²+(y−1)²=25"]','C','The radius is √((5−2)²+(1+3)²)=√25=5. Therefore (x−2)²+(y+3)²=25.','Окружность имеет центр (2,−3) и проходит через (5,1). Какое уравнение верно?','["(x+2)²+(y−3)²=25","(x−2)²+(y+3)²=5","(x−2)²+(y+3)²=25","(x−5)²+(y−1)²=25"]','Радиус равен √((5−2)²+(1+3)²)=√25=5. Поэтому уравнение: (x−2)²+(y+3)²=25.','Aylana markazi (2,−3) bo‘lib, u (5,1) nuqtadan o‘tadi. Qaysi tenglama to‘g‘ri?','["(x+2)²+(y−3)²=25","(x−2)²+(y+3)²=5","(x−2)²+(y+3)²=25","(x−5)²+(y−1)²=25"]','Radius √((5−2)²+(1+3)²)=√25=5. Shuning uchun tenglama (x−2)²+(y+3)²=25.',60),
('P1COO04-A03','P1-COO-04','P1 Coordinate geometry','medium','input','The circle x²+y²−4x+10y+13=0 has radius r. Enter r.','[]','4','Complete the squares: (x−2)²−4+(y+5)²−25+13=0, so (x−2)²+(y+5)²=16. Hence r=4.','Окружность x²+y²−4x+10y+13=0 имеет радиус r. Введите r.','[]','Дополняем до квадратов: (x−2)²−4+(y+5)²−25+13=0, поэтому (x−2)²+(y+5)²=16. Следовательно, r=4.','x²+y²−4x+10y+13=0 aylananing radiusi r. r ni kiriting.','[]','Kvadratlarni to‘ldiramiz: (x−2)²−4+(y+5)²−25+13=0, bundan (x−2)²+(y+5)²=16. Demak r=4.',55),
('P1CIR02-A01','P1-CIR-02','P1 Circular measure','medium','mcq','A circle has radius 7 cm and a central angle of 1.4 radians. Find the arc length.','["9.8 cm","5 cm","8.4 cm","4.9 cm"]','A','For radians, arc length s=rθ=7×1.4=9.8 cm.','Окружность имеет радиус 7 см и центральный угол 1,4 радиана. Найдите длину дуги.','["9,8 см","5 см","8,4 см","4,9 см"]','При угле в радианах длина дуги s=rθ=7×1,4=9,8 см.','Aylana radiusi 7 sm, markaziy burchagi 1.4 radian. Yoy uzunligini toping.','["9.8 sm","5 sm","8.4 sm","4.9 sm"]','Radianlarda yoy uzunligi s=rθ=7×1.4=9.8 sm.',45),
('P1CIR02-A02','P1-CIR-02','P1 Circular measure','medium','mcq','An arc has length 15 cm and subtends 2.5 radians at the centre. Find the radius.','["37.5 cm","6 cm","12.5 cm","17.5 cm"]','B','Using s=rθ, r=s/θ=15/2.5=6 cm.','Дуга длиной 15 см стягивает в центре угол 2,5 радиана. Найдите радиус.','["37,5 см","6 см","12,5 см","17,5 см"]','По формуле s=rθ получаем r=s/θ=15/2,5=6 см.','Uzunligi 15 sm bo‘lgan yoy markazda 2.5 radian burchak hosil qiladi. Radiusni toping.','["37.5 sm","6 sm","12.5 sm","17.5 sm"]','s=rθ dan r=s/θ=15/2.5=6 sm.',45),
('P1CIR02-A03','P1-CIR-02','P1 Circular measure','medium','input','An arc of length 18 cm lies on a circle of radius 12 cm. Enter the angle in radians.','[]','1.5','θ=s/r=18/12=1.5 radians.','Дуга длиной 18 см лежит на окружности радиуса 12 см. Введите угол в радианах.','[]','θ=s/r=18/12=1,5 радиана.','Uzunligi 18 sm bo‘lgan yoy radiusi 12 sm aylana ustida yotadi. Burchakni radianlarda kiriting.','[]','θ=s/r=18/12=1.5 radian.',45)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,s.topic,s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P1:p1_aw09_12_alt_learning_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P1:p1_aw09_12_alt_learning_draft_v1:'||s.content_key);

insert into private.exam_prep_written_tasks(
 id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
 prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
 lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(15624,4809,'P1QUA04-AW10','P1','P1-QUA-04','{}','v1','Solve x²−7x+10≤0 and 2x²−5x−3>0. Give each solution set in interval form, then find their intersection. Explain how the sign of an upward-opening quadratic changes across its roots.','Решите x²−7x+10≤0 и 2x²−5x−3>0. Запишите каждое множество решений в интервальной форме, затем найдите их пересечение. Объясните, как меняется знак квадратичной функции с положительным старшим коэффициентом при переходе через корни.','x²−7x+10≤0 va 2x²−5x−3>0 tengsizliklarni yeching. Har bir yechim to‘plamini oraliq ko‘rinishida yozing, so‘ng ularning kesishmasini toping. Yuqoriga ochiladigan kvadrat funksiyaning ishorasi ildizlar atrofida qanday o‘zgarishini tushuntiring.','{"criteria":[{"id":"first","rule":"Obtains 2≤x≤5.","marks":2},{"id":"second","rule":"Obtains x<−1/2 or x>3.","marks":2},{"id":"intersection","rule":"Finds 3<x≤5.","marks":1},{"id":"reason","rule":"Explains the sign pattern for an upward-opening quadratic across its roots.","marks":1}],"max_marks":6}'::jsonb,'Factor each quadratic, mark the roots on a number line, and check endpoint inclusion from the inequality signs.','Разложите каждую квадратичную функцию на множители, отметьте корни на числовой прямой и проверьте включение границ по знакам неравенств.','Har bir kvadrat ifodani ko‘paytuvchilarga ajrating, ildizlarni sonlar o‘qida belgilang va tengsizlik belgilariga qarab chegara nuqtalari kirishini tekshiring.','draft','pending','pending','pending','pending'),
(15625,4809,'P1QUA05-AW10','P1','P1-QUA-05','{}','v1','The line y=2x+1 intersects the parabola y=x²−2x+4. Find both intersection points and verify each point in both original equations.','Прямая y=2x+1 пересекает параболу y=x²−2x+4. Найдите обе точки пересечения и проверьте каждую точку в обоих исходных уравнениях.','y=2x+1 chiziq y=x²−2x+4 parabola bilan kesishadi. Ikkala kesishish nuqtasini toping va har bir nuqtani ikkala dastlabki tenglamada tekshiring.','{"criteria":[{"id":"equate","rule":"Forms x²−4x+3=0.","marks":1},{"id":"roots","rule":"Finds x=1 and x=3.","marks":2},{"id":"points","rule":"Obtains (1,3) and (3,7).","marks":1},{"id":"verify1","rule":"Verifies (1,3) in both equations.","marks":1},{"id":"verify2","rule":"Verifies (3,7) in both equations.","marks":1}],"max_marks":6}'::jsonb,'Set the two y-expressions equal first. After solving for x, calculate y from the line and substitute each point back into both equations.','Сначала приравняйте два выражения для y. После нахождения x вычислите y по уравнению прямой и подставьте каждую точку в оба исходных уравнения.','Avval y uchun ikki ifodani tenglashtiring. x ni topgach, y ni chiziq tenglamasidan hisoblang va har bir nuqtani ikkala dastlabki tenglamaga qo‘yib tekshiring.','draft','pending','pending','pending','pending'),
(15626,4809,'P1QUA06-AW10','P1','P1-QUA-06','{}','v1','Solve (x²−2x)²−5(x²−2x)+4=0 by introducing a transformed variable. Give all exact real solutions and explain why the substitution is valid.','Решите (x²−2x)²−5(x²−2x)+4=0, введя новую переменную. Запишите все точные действительные решения и объясните, почему такая замена допустима.','(x²−2x)²−5(x²−2x)+4=0 tenglamani yangi o‘zgaruvchi kiritib yeching. Barcha aniq haqiqiy yechimlarni yozing va nega bunday almashtirish mumkinligini tushuntiring.','{"criteria":[{"id":"sub","rule":"Sets u=x²−2x and obtains u²−5u+4=0.","marks":1},{"id":"u","rule":"Finds u=1 and u=4.","marks":1},{"id":"u1","rule":"Solves x²−2x=1 to get x=1±√2.","marks":2},{"id":"u4","rule":"Solves x²−2x=4 to get x=1±√5.","marks":1},{"id":"reason","rule":"Explains the repeated expression can be treated as one variable and then substituted back.","marks":1}],"max_marks":6}'::jsonb,'Treat the repeated expression as one variable, solve the quadratic in that variable, then solve the two resulting quadratics in x.','Рассмотрите повторяющееся выражение как одну переменную, решите квадратное уравнение относительно неё, затем решите два получившихся квадратных уравнения относительно x.','Takrorlanadigan ifodani bitta o‘zgaruvchi deb oling, shu o‘zgaruvchi bo‘yicha kvadrat tenglamani yeching, keyin x bo‘yicha hosil bo‘lgan ikkita kvadrat tenglamani yeching.','draft','pending','pending','pending','pending'),
(15627,4809,'P1FUN03-AW10','P1','P1-FUN-03','{}','v1','Let f(x)=√(x+2) and g(x)=3x−1. Find formulas and real domains for (f∘g)(x) and (g∘f)(x). Explain why the two domain restrictions are different.','Пусть f(x)=√(x+2), g(x)=3x−1. Найдите формулы и действительные области определения для (f∘g)(x) и (g∘f)(x). Объясните, почему ограничения областей определения различаются.','f(x)=√(x+2), g(x)=3x−1 bo‘lsin. (f∘g)(x) va (g∘f)(x) formulalarini hamda haqiqiy aniqlanish sohalarini toping. Nega bu ikki soha cheklovlari turlicha ekanini tushuntiring.','{"criteria":[{"id":"fog","rule":"Obtains (f∘g)(x)=√(3x+1).","marks":1},{"id":"fogdom","rule":"Gives x≥−1/3.","marks":1},{"id":"gof","rule":"Obtains (g∘f)(x)=3√(x+2)−1.","marks":1},{"id":"gofdom","rule":"Gives x≥−2.","marks":1},{"id":"reason1","rule":"Links the first restriction to the input entering f after g.","marks":1},{"id":"reason2","rule":"Links the second restriction to the original domain of f before applying g.","marks":1}],"max_marks":6}'::jsonb,'Build each composition in the stated order. Apply the square-root restriction exactly where f receives its input.','Составьте каждую композицию в указанном порядке. Ограничение для квадратного корня применяйте именно к тому выражению, которое поступает на вход f.','Har bir kompozitsiyani berilgan tartibda tuzing. Kvadrat ildiz cheklovini f funksiyasiga kiradigan ifodaga aynan qo‘llang.','draft','pending','pending','pending','pending'),
(15628,4809,'P1FUN04-AW10','P1','P1-FUN-04','{}','v1','For f(x)=(3x−2)/(x+4), x≠−4, derive f⁻¹(x), state its domain, and verify algebraically that f(f⁻¹(x))=x on the valid domain.','Для f(x)=(3x−2)/(x+4), x≠−4, выведите формулу f⁻¹(x), укажите её область определения и алгебраически проверьте, что f(f⁻¹(x))=x на допустимой области.','f(x)=(3x−2)/(x+4), x≠−4 uchun f⁻¹(x) formulasini chiqaring, uning aniqlanish sohasini yozing va ruxsat etilgan sohada f(f⁻¹(x))=x ekanini algebraik tekshiring.','{"criteria":[{"id":"rearrange","rule":"Rearranges y=(3x−2)/(x+4) correctly.","marks":1},{"id":"inverse","rule":"Obtains f⁻¹(x)=(-2−4x)/(x−3), or an equivalent form.","marks":2},{"id":"domain","rule":"States x≠3 for the inverse.","marks":1},{"id":"verify","rule":"Correctly simplifies f(f⁻¹(x)) to x.","marks":1},{"id":"restriction","rule":"Keeps the valid-domain restriction during verification.","marks":1}],"max_marks":6}'::jsonb,'Swap the roles of input and output only after solving the original equation for x. Keep track of the value excluded from the inverse domain.','Меняйте роли входа и выхода только после того, как выразите x из исходного уравнения. Следите за значением, исключённым из области определения обратной функции.','Kirish va chiqish rollarini faqat dastlabki tenglamadan x ni ifodalagandan keyin almashtiring. Teskari funksiya aniqlanish sohasidan chiqariladigan qiymatni kuzating.','draft','pending','pending','pending','pending'),
(15629,4809,'P1FUN05-AW10','P1','P1-FUN-05','{}','v1','For f(x)=2x−6, write f⁻¹(x). State the x- and y-intercepts of both graphs, identify their common point, and explain how reflection in y=x links all of these features.','Для f(x)=2x−6 запишите f⁻¹(x). Укажите точки пересечения обоих графиков с осями x и y, найдите их общую точку и объясните, как отражение относительно y=x связывает все эти характеристики.','f(x)=2x−6 uchun f⁻¹(x) ni yozing. Ikkala grafikning x va y o‘qlari bilan kesishish nuqtalarini, ularning umumiy nuqtasini toping va y=x ga nisbatan akslantirish bu xususiyatlarni qanday bog‘lashini tushuntiring.','{"criteria":[{"id":"inverse","rule":"Obtains f⁻¹(x)=(x+6)/2.","marks":1},{"id":"fints","rule":"Finds f intercepts (3,0) and (0,-6).","marks":1},{"id":"invints","rule":"Finds inverse intercepts (−6,0) and (0,3).","marks":1},{"id":"common","rule":"Finds common point (6,6).","marks":2},{"id":"reflect","rule":"Explains coordinate swapping under reflection in y=x.","marks":1}],"max_marks":6}'::jsonb,'Find the inverse by swapping x and y, then use coordinate swapping to check the intercepts before solving f(x)=x for the common point.','Найдите обратную функцию, поменяв x и y местами, затем используйте перестановку координат для проверки пересечений с осями и решите f(x)=x для общей точки.','Teskari funksiyani x va y ni almashtirib toping, so‘ng o‘qlar bilan kesishishlarni koordinatalar almashishi orqali tekshiring va umumiy nuqta uchun f(x)=x ni yeching.','draft','pending','pending','pending','pending'),
(15630,4809,'P1COO04-AW10','P1','P1-COO-04','{}','v1','For the circle x²+y²−6x+8y−11=0, find the centre and radius, write the equation in centre-radius form, and determine whether the point (3,2) lies on the circle. Show your substitution.','Для окружности x²+y²−6x+8y−11=0 найдите центр и радиус, запишите уравнение в форме с центром и радиусом и определите, лежит ли точка (3,2) на окружности. Покажите подстановку.','x²+y²−6x+8y−11=0 aylana uchun markaz va radiusni toping, tenglamani markaz-radius ko‘rinishida yozing va (3,2) nuqta aylanada yotishini aniqlang. Almashtirishni ko‘rsating.','{"criteria":[{"id":"complete","rule":"Completes squares to obtain (x−3)²+(y+4)²=36.","marks":2},{"id":"centre","rule":"States centre (3,−4).","marks":1},{"id":"radius","rule":"States radius 6.","marks":1},{"id":"sub","rule":"Substitutes (3,2) to obtain 0²+6²=36.","marks":1},{"id":"conclude","rule":"Concludes that (3,2) lies on the circle.","marks":1}],"max_marks":6}'::jsonb,'Complete the x- and y-squares separately. When testing the point, substitute into the centre-radius form to make the distance check clear.','Отдельно дополните квадраты по x и y. При проверке точки подставьте её в форму с центром и радиусом, чтобы явно увидеть проверку расстояния.','x va y bo‘yicha kvadratlarni alohida to‘ldiring. Nuqtani tekshirganda masofa shartini aniq ko‘rish uchun uni markaz-radius ko‘rinishiga qo‘ying.','draft','pending','pending','pending','pending'),
(15631,4809,'P1CIR02-AW10','P1','P1-CIR-02','{}','v1','A sector has radius 9 cm and central angle 1.6 radians. Find its arc length. A second sector has arc length 18 cm and central angle 1.2 radians; find its radius. Explain why the formula s=rθ requires θ in radians.','Сектор имеет радиус 9 см и центральный угол 1,6 радиана. Найдите длину его дуги. У второго сектора длина дуги 18 см и центральный угол 1,2 радиана; найдите его радиус. Объясните, почему формула s=rθ требует, чтобы θ был задан в радианах.','Sektor radiusi 9 sm va markaziy burchagi 1.6 radian. Uning yoy uzunligini toping. Ikkinchi sektorda yoy uzunligi 18 sm va markaziy burchak 1.2 radian; radiusni toping. Nega s=rθ formula θ radianlarda bo‘lishini talab qilishini tushuntiring.','{"criteria":[{"id":"arc","rule":"Finds s=9×1.6=14.4 cm.","marks":2},{"id":"radius","rule":"Finds r=18/1.2=15 cm.","marks":2},{"id":"units","rule":"Keeps lengths in centimetres and angle in radians.","marks":1},{"id":"reason","rule":"Explains that radian measure is defined as arc length divided by radius, giving s=rθ directly.","marks":1}],"max_marks":6}'::jsonb,'Use s=rθ in each direction and keep the radian unit explicit. Link the formula to the definition θ=s/r.','Используйте s=rθ в обоих направлениях и явно сохраняйте единицу «радиан». Свяжите формулу с определением θ=s/r.','s=rθ formulasini har ikki yo‘nalishda ishlating va radian birligini aniq ko‘rsating. Formulani θ=s/r ta’rifi bilan bog‘lang.','draft','pending','pending','pending','pending')
on conflict (id) do nothing;

with src(content_key,skill_code,meta_id) as (values
('P1QUA04-A01','P1-QUA-04',59158),
('P1QUA04-A02','P1-QUA-04',59159),
('P1QUA04-A03','P1-QUA-04',59160),
('P1QUA05-A01','P1-QUA-05',59161),
('P1QUA05-A02','P1-QUA-05',59162),
('P1QUA05-A03','P1-QUA-05',59163),
('P1QUA06-A01','P1-QUA-06',59164),
('P1QUA06-A02','P1-QUA-06',59165),
('P1QUA06-A03','P1-QUA-06',59166),
('P1FUN03-A01','P1-FUN-03',59167),
('P1FUN03-A02','P1-FUN-03',59168),
('P1FUN03-A03','P1-FUN-03',59169),
('P1FUN04-A01','P1-FUN-04',59170),
('P1FUN04-A02','P1-FUN-04',59171),
('P1FUN04-A03','P1-FUN-04',59172),
('P1FUN05-A01','P1-FUN-05',59173),
('P1FUN05-A02','P1-FUN-05',59174),
('P1FUN05-A03','P1-FUN-05',59175),
('P1COO04-A01','P1-COO-04',59176),
('P1COO04-A02','P1-COO-04',59177),
('P1COO04-A03','P1-COO-04',59178),
('P1CIR02-A01','P1-CIR-02',59179),
('P1CIR02-A02','P1-CIR-02',59180),
('P1CIR02-A03','P1-CIR-02',59181)
), cv as (select id from private.exam_prep_content_versions where id=4809)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,cv.id,s.content_key,qn.id,s.skill_code,'{}'::text[],'learning','withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'Supplemental AW9-12 learning draft authored from the canonical skill intent with independent values and contexts, separate from the existing teaching pack.',
 case s.skill_code
 when 'P1-QUA-04' then 'Cambridge 9709 2026-2027 v4; P1 1.1 Quadratics'
 when 'P1-QUA-05' then 'Cambridge 9709 2026-2027 v4; P1 1.1 Quadratics'
 when 'P1-QUA-06' then 'Cambridge 9709 2026-2027 v4; P1 1.1 Quadratics'
 when 'P1-FUN-03' then 'Cambridge 9709 2026-2027 v4; P1 1.2 Functions'
 when 'P1-FUN-04' then 'Cambridge 9709 2026-2027 v4; P1 1.2 Functions'
 when 'P1-FUN-05' then 'Cambridge 9709 2026-2027 v4; P1 1.2 Functions'
 when 'P1-COO-04' then 'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry'
 when 'P1-CIR-02' then 'Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure'
 end,
 case s.skill_code
 when 'P1-QUA-04' then 'Complete Pure Mathematics 1, Ch1 Quadratics pp.2-20 (mapping only)'
 when 'P1-QUA-05' then 'Complete Pure Mathematics 1, Ch1 Quadratics pp.2-20 (mapping only)'
 when 'P1-QUA-06' then 'Complete Pure Mathematics 1, Ch1 Quadratics pp.2-20 (mapping only)'
 when 'P1-FUN-03' then 'Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'
 when 'P1-FUN-04' then 'Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'
 when 'P1-FUN-05' then 'Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'
 when 'P1-COO-04' then 'Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'
 when 'P1-CIR-02' then 'Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)'
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
join public.questions qn on qn.book_ref='ExamPrep:P1:p1_aw09_12_alt_learning_draft_v1:'||s.content_key
on conflict (id) do nothing;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35373,4809,'P1-QUA-04-learning-alt-02','v1','P1','learning','draft','Quadratics: inequalities - supplemental learning','Квадратные функции: неравенства — дополнительное обучение','Kvadrat funksiyalar: tengsizliklar — qo‘shimcha o‘rganish'),
(35374,4809,'P1-QUA-05-learning-alt-02','v1','P1','learning','draft','Quadratics: simultaneous linear and quadratic relations - supplemental learning','Квадратные функции: линейно-квадратичные системы — дополнительное обучение','Kvadrat funksiyalar: chiziqli-kvadrat sistemalar — qo‘shimcha o‘rganish'),
(35375,4809,'P1-QUA-06-learning-alt-02','v1','P1','learning','draft','Quadratics: transformed quadratic equations - supplemental learning','Квадратные функции: уравнения после замены переменной — дополнительное обучение','Kvadrat funksiyalar: o‘zgaruvchi almashtirishli tenglamalar — qo‘shimcha o‘rganish'),
(35376,4809,'P1-FUN-03-learning-alt-02','v1','P1','learning','draft','Functions: composite functions and domains - supplemental learning','Функции: композиции и области определения — дополнительное обучение','Funksiyalar: kompozitsiyalar va aniqlanish sohalari — qo‘shimcha o‘rganish'),
(35377,4809,'P1-FUN-04-learning-alt-02','v1','P1','learning','draft','Functions: one-one functions and inverses - supplemental learning','Функции: взаимно однозначные и обратные функции — дополнительное обучение','Funksiyalar: bir qiymatli va teskari funksiyalar — qo‘shimcha o‘rganish'),
(35378,4809,'P1-FUN-05-learning-alt-02','v1','P1','learning','draft','Functions: inverse graphs and y=x reflection - supplemental learning','Функции: графики обратных функций и отражение относительно y=x — дополнительное обучение','Funksiyalar: teskari grafiklar va y=x ga nisbatan akslantirish — qo‘shimcha o‘rganish'),
(35379,4809,'P1-COO-04-learning-alt-02','v1','P1','learning','draft','Coordinate geometry: circles - supplemental learning','Координатная геометрия: окружности — дополнительное обучение','Koordinata geometriyasi: aylanalar — qo‘shimcha o‘rganish'),
(35380,4809,'P1-CIR-02-learning-alt-02','v1','P1','learning','draft','Circular measure: arc length - supplemental learning','Круговая мера: длина дуги — дополнительное обучение','Aylana o‘lchovi: yoy uzunligi — qo‘shimcha o‘rganish')
on conflict (id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
(35373,1,'P1QUA04-A01',null::bigint,'P1-QUA-04'),
(35373,2,'P1QUA04-A02',null::bigint,'P1-QUA-04'),
(35373,3,'P1QUA04-A03',null::bigint,'P1-QUA-04'),
(35373,4,null,15624,'P1-QUA-04'),
(35374,1,'P1QUA05-A01',null::bigint,'P1-QUA-05'),
(35374,2,'P1QUA05-A02',null::bigint,'P1-QUA-05'),
(35374,3,'P1QUA05-A03',null::bigint,'P1-QUA-05'),
(35374,4,null,15625,'P1-QUA-05'),
(35375,1,'P1QUA06-A01',null::bigint,'P1-QUA-06'),
(35375,2,'P1QUA06-A02',null::bigint,'P1-QUA-06'),
(35375,3,'P1QUA06-A03',null::bigint,'P1-QUA-06'),
(35375,4,null,15626,'P1-QUA-06'),
(35376,1,'P1FUN03-A01',null::bigint,'P1-FUN-03'),
(35376,2,'P1FUN03-A02',null::bigint,'P1-FUN-03'),
(35376,3,'P1FUN03-A03',null::bigint,'P1-FUN-03'),
(35376,4,null,15627,'P1-FUN-03'),
(35377,1,'P1FUN04-A01',null::bigint,'P1-FUN-04'),
(35377,2,'P1FUN04-A02',null::bigint,'P1-FUN-04'),
(35377,3,'P1FUN04-A03',null::bigint,'P1-FUN-04'),
(35377,4,null,15628,'P1-FUN-04'),
(35378,1,'P1FUN05-A01',null::bigint,'P1-FUN-05'),
(35378,2,'P1FUN05-A02',null::bigint,'P1-FUN-05'),
(35378,3,'P1FUN05-A03',null::bigint,'P1-FUN-05'),
(35378,4,null,15629,'P1-FUN-05'),
(35379,1,'P1COO04-A01',null::bigint,'P1-COO-04'),
(35379,2,'P1COO04-A02',null::bigint,'P1-COO-04'),
(35379,3,'P1COO04-A03',null::bigint,'P1-COO-04'),
(35379,4,null,15630,'P1-COO-04'),
(35380,1,'P1CIR02-A01',null::bigint,'P1-CIR-02'),
(35380,2,'P1CIR02-A02',null::bigint,'P1-CIR-02'),
(35380,3,'P1CIR02-A03',null::bigint,'P1-CIR-02'),
(35380,4,null,15631,'P1-CIR-02')
)
insert into private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select i.assessment_id,i.item_order,qn.id,i.written_id,i.skill_code,
 case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions qn on i.content_key is not null
 and qn.book_ref='ExamPrep:P1:p1_aw09_12_alt_learning_draft_v1:'||i.content_key
on conflict (assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select status from private.exam_prep_content_versions where id=4809)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4809 and lifecycle_state='draft' and reserve_role='learning')<>24
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4809 and lifecycle_state='draft')<>8
     or (select count(*) from private.exam_prep_assessments where content_version_id=4809 and status='draft' and assessment_type='learning')<>8
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4809)<>32
  then raise exception 'aw09_12_alt_p1_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4809 and (
    m.exposure_state<>'withheld' or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or qn.is_active or qn.quality_status<>'draft'
  );
  if v_bad<>0 then raise exception 'aw09_12_alt_p1_draft exposure/QA boundary rows=%',v_bad; end if;

  select
    count(*) filter(where qn.correct_answer='A'),
    count(*) filter(where qn.correct_answer='B'),
    count(*) filter(where qn.correct_answer='C'),
    count(*) filter(where qn.correct_answer='D'),
    count(*) filter(where qn.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4809;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,4,4,8) then
    raise exception 'aw09_12_alt_p1_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions qn on qn.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4809
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4809
      and lower(regexp_replace(qn.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw09_12_alt_p1_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4809)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4809)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4809)
  then raise exception 'aw09_12_alt_p1_draft unexpected history'; end if;
end
$postcheck$;

commit;
