-- AW9-12 supplemental learning independent QA corrections v1.
-- Draft/history-free content only. No publication or learner exposure.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4809,4810) and status='draft')<>2 then
    raise exception 'aw09_12 independent QA: target draft versions missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id=4809)<>24
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id=4810)<>18 then
    raise exception 'aw09_12 independent QA: candidate surface mismatch';
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4809,4810)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4809,4810)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4809,4810)
  ) then
    raise exception 'aw09_12 independent QA: draft has learner/legacy history';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4809,4810)
    and (m.lifecycle_state<>'draft' or m.exposure_state<>'withheld' or q.is_active or q.quality_status<>'draft');
  if v_bad<>0 then
    raise exception 'aw09_12 independent QA: draft exposure drift rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4809,4810)
        and content_key in ('P1QUA04-A01','P1QUA04-A02','P1QUA05-A01','P1QUA06-A03','P1FUN05-A01','P1FUN05-A02','P1COO04-A02','P1CIR02-A01','P1CIR02-A02','P5DAT03-A02','P5DAT03-A03','P5DAT07-A03','P5CNT05-A01','P5CNT05-A02','P5PRO02-A01','P5PRO02-A02','P5PRO02-A03','P5PRO04-A01'))<>18 then
    raise exception 'aw09_12 independent QA: correction targets missing';
  end if;
end
$preflight$;

with fixes(content_key,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz) as (values
('P1QUA04-A01','A profit model is p(x)=−x²+6x−5. For which values of x is p(x)≥0?','["1≤x≤5","x≤1 or x≥5","1<x<5","x<1 or x>5"]','A','p(x)=−(x−1)(x−5). The downward-opening quadratic is non-negative between its roots, including the roots, so 1≤x≤5.','Модель прибыли задаётся p(x)=−x²+6x−5. При каких x выполняется p(x)≥0?','["1≤x≤5","x≤1 или x≥5","1<x<5","x<1 или x>5"]','p(x)=−(x−1)(x−5). Парабола направлена вниз и неотрицательна между корнями, включая сами корни, поэтому 1≤x≤5.','Foyda modeli p(x)=−x²+6x−5 bilan berilgan. Qaysi x qiymatlarda p(x)≥0?','["1≤x≤5","x≤1 yoki x≥5","1<x<5","x<1 yoki x>5"]','p(x)=−(x−1)(x−5). Parabola pastga ochiladi va ildizlar orasida, ildizlarni ham qo‘shgan holda, manfiy emas. Demak 1≤x≤5.'),
('P1QUA04-A02','Solve 3x²−14x+8<0.','["x<2/3 or x>4","2/3<x<4","2/3≤x≤4","x≤2/3 or x≥4"]','B','3x²−14x+8=(3x−2)(x−4). The quadratic opens upward, so it is negative strictly between the roots: 2/3<x<4.','Решите неравенство 3x²−14x+8<0.','["x<2/3 или x>4","2/3<x<4","2/3≤x≤4","x≤2/3 или x≥4"]','3x²−14x+8=(3x−2)(x−4). Парабола направлена вверх, поэтому выражение отрицательно строго между корнями: 2/3<x<4.','3x²−14x+8<0 tengsizlikni yeching.','["x<2/3 yoki x>4","2/3<x<4","2/3≤x≤4","x≤2/3 yoki x≥4"]','3x²−14x+8=(3x−2)(x−4). Parabola yuqoriga ochiladi, shuning uchun ifoda ildizlar orasida qat’iy manfiy: 2/3<x<4.'),
('P1QUA05-A01','The line y=2x−1 intersects the parabola y=x²−4x+5. Which are the x-coordinates of the intersection points?','["2±√3","3±2√3","3±√3","4±√3"]','C','Set the equations equal: 2x−1=x²−4x+5, so x²−6x+6=0. Hence x=(6±√12)/2=3±√3.','Прямая y=2x−1 пересекает параболу y=x²−4x+5. Каковы x-координаты точек пересечения?','["2±√3","3±2√3","3±√3","4±√3"]','Приравниваем: 2x−1=x²−4x+5, поэтому x²−6x+6=0. Отсюда x=(6±√12)/2=3±√3.','y=2x−1 chiziq y=x²−4x+5 parabola bilan kesishadi. Kesishish nuqtalarining x-koordinatalari qaysilar?','["2±√3","3±2√3","3±√3","4±√3"]','Tenglashtiramiz: 2x−1=x²−4x+5, bundan x²−6x+6=0. Shuning uchun x=(6±√12)/2=3±√3.'),
('P1QUA06-A03','Solve (x−3)⁴−13(x−3)²+36=0. Enter the sum of all distinct real solutions.','[]','12','Let u=(x−3)². Then u²−13u+36=0, so u=4 or 9. Hence x−3=±2 or ±3, giving x=1,5,0,6. Their sum is 12.','Решите (x−3)⁴−13(x−3)²+36=0. Введите сумму всех различных действительных решений.','[]','Положим u=(x−3)². Тогда u²−13u+36=0, поэтому u=4 или 9. Отсюда x−3=±2 или ±3, то есть x=1,5,0,6. Их сумма равна 12.','(x−3)⁴−13(x−3)²+36=0 tenglamani yeching. Barcha turli haqiqiy yechimlar yig‘indisini kiriting.','[]','u=(x−3)² deb olamiz. Unda u²−13u+36=0, demak u=4 yoki 9. Shundan x−3=±2 yoki ±3, ya’ni x=1,5,0,6. Ularning yig‘indisi 12.'),
('P1FUN05-A01','The point P=(−3,7) lies on y=f(x), and Q is the corresponding point on y=f⁻¹(x). Which statement is correct?','["Q=(−7,3)","Q=(3,−7)","Q=(7,−3) and the midpoint of PQ is (2,2)","Q=(−3,7)"]','C','Reflection in y=x swaps coordinates, so Q=(7,−3). The midpoint of P and Q is ((−3+7)/2,(7−3)/2)=(2,2), which lies on y=x.','Точка P=(−3,7) лежит на y=f(x), а Q — соответствующая точка на y=f⁻¹(x). Какое утверждение верно?','["Q=(−7,3)","Q=(3,−7)","Q=(7,−3), а середина PQ равна (2,2)","Q=(−3,7)"]','Отражение относительно y=x меняет координаты местами, поэтому Q=(7,−3). Середина P и Q равна ((−3+7)/2,(7−3)/2)=(2,2), и она лежит на y=x.','P=(−3,7) nuqta y=f(x) grafigida, Q esa y=f⁻¹(x) dagi mos nuqta. Qaysi fikr to‘g‘ri?','["Q=(−7,3)","Q=(3,−7)","Q=(7,−3) va PQ kesmaning o‘rta nuqtasi (2,2)","Q=(−3,7)"]','y=x ga nisbatan akslantirish koordinatalarni almashtiradi, shuning uchun Q=(7,−3). P va Q ning o‘rta nuqtasi ((−3+7)/2,(7−3)/2)=(2,2) bo‘lib, u y=x da yotadi.'),
('P1FUN05-A02','For f(x)=2x−5, which point lies on both y=f(x) and y=f⁻¹(x)?','["(0,−5)","(5,0)","(−5,−5)","(5,5)"]','D','Here f⁻¹(x)=(x+5)/2. At an intersection, 2x−5=(x+5)/2, so 4x−10=x+5 and x=5. Then y=5, giving the common point (5,5).','Для f(x)=2x−5 какая точка лежит одновременно на y=f(x) и y=f⁻¹(x)?','["(0,−5)","(5,0)","(−5,−5)","(5,5)"]','Здесь f⁻¹(x)=(x+5)/2. В точке пересечения 2x−5=(x+5)/2, поэтому 4x−10=x+5 и x=5. Тогда y=5, значит общая точка — (5,5).','f(x)=2x−5 uchun qaysi nuqta ham y=f(x), ham y=f⁻¹(x) grafigida yotadi?','["(0,−5)","(5,0)","(−5,−5)","(5,5)"]','Bu yerda f⁻¹(x)=(x+5)/2. Kesishish nuqtasida 2x−5=(x+5)/2, demak 4x−10=x+5 va x=5. Shunda y=5, umumiy nuqta (5,5).'),
('P1COO04-A02','A circle has diameter endpoints A=(−1,2) and B=(5,6). Which equation is correct?','["(x−2)²+(y−4)²=26","(x+2)²+(y+4)²=13","(x−2)²+(y−4)²=13","(x−5)²+(y−6)²=13"]','C','The centre is the midpoint (2,4). The diameter length is √(6²+4²)=2√13, so the radius is √13 and r²=13. Thus (x−2)²+(y−4)²=13.','Диаметр окружности имеет концы A=(−1,2) и B=(5,6). Какое уравнение окружности верно?','["(x−2)²+(y−4)²=26","(x+2)²+(y+4)²=13","(x−2)²+(y−4)²=13","(x−5)²+(y−6)²=13"]','Центр — середина отрезка AB: (2,4). Длина диаметра √(6²+4²)=2√13, значит радиус √13 и r²=13. Поэтому (x−2)²+(y−4)²=13.','Aylana diametrining uchlari A=(−1,2) va B=(5,6). Qaysi tenglama to‘g‘ri?','["(x−2)²+(y−4)²=26","(x+2)²+(y+4)²=13","(x−2)²+(y−4)²=13","(x−5)²+(y−6)²=13"]','Markaz AB kesmaning o‘rta nuqtasi: (2,4). Diametr uzunligi √(6²+4²)=2√13, demak radius √13 va r²=13. Shuning uchun (x−2)²+(y−4)²=13.'),
('P1CIR02-A01','A sector has radius 5 cm and perimeter 18 cm. What is its central angle in radians?','["1.6","3.6","0.625","8"]','A','The perimeter is 2r+s, so the arc length is s=18−10=8 cm. Then θ=s/r=8/5=1.6 radians.','Сектор имеет радиус 5 см и периметр 18 см. Каков его центральный угол в радианах?','["1,6","3,6","0,625","8"]','Периметр равен 2r+s, поэтому длина дуги s=18−10=8 см. Тогда θ=s/r=8/5=1,6 радиана.','Sektor radiusi 5 sm va perimetri 18 sm. Uning markaziy burchagi necha radian?','["1.6","3.6","0.625","8"]','Perimetr 2r+s ga teng, demak yoy uzunligi s=18−10=8 sm. Shunda θ=s/r=8/5=1.6 radian.'),
('P1CIR02-A02','Two arcs subtend the same central angle. The first has radius 8 cm and arc length 12 cm. The second has radius 6 cm. Find the second arc length.','["6 cm","9 cm","16 cm","18 cm"]','B','The common angle is θ=12/8=1.5 radians. For the second circle, s=rθ=6×1.5=9 cm.','Две дуги стягивают одинаковый центральный угол. У первой радиус 8 см и длина дуги 12 см. У второй радиус 6 см. Найдите длину второй дуги.','["6 см","9 см","16 см","18 см"]','Общий угол θ=12/8=1,5 радиана. Для второй окружности s=rθ=6×1,5=9 см.','Ikki yoy bir xil markaziy burchak hosil qiladi. Birinchi aylana radiusi 8 sm va yoy uzunligi 12 sm. Ikkinchi aylana radiusi 6 sm. Ikkinchi yoy uzunligini toping.','["6 sm","9 sm","16 sm","18 sm"]','Umumiy burchak θ=12/8=1.5 radian. Ikkinchi aylana uchun s=rθ=6×1.5=9 sm.'),
('P5DAT03-A02','Box plot A has Q1=22, median 30 and Q3=36. Box plot B has Q1=18, median 33 and Q3=42. Which comparison is supported?','["A has the higher median and larger IQR","B has the higher median and larger IQR","The medians and IQRs are equal","A has the larger IQR"]','B','A has median 30 and IQR 36−22=14. B has median 33 and IQR 42−18=24. Therefore B has both the higher median and the larger IQR.','Для диаграммы A: Q1=22, медиана 30, Q3=36. Для диаграммы B: Q1=18, медиана 33, Q3=42. Какое сравнение подтверждается?','["У A выше медиана и больше IQR","У B выше медиана и больше IQR","Медианы и IQR одинаковы","У A больше IQR"]','У A медиана 30 и IQR=36−22=14. У B медиана 33 и IQR=42−18=24. Значит, у B и медиана выше, и IQR больше.','A box plot uchun Q1=22, mediana 30, Q3=36. B uchun Q1=18, mediana 33, Q3=42. Qaysi taqqoslash to‘g‘ri?','["A da mediana yuqori va IQR katta","B da mediana yuqori va IQR katta","Mediana va IQR lar teng","A da IQR katta"]','A da mediana 30 va IQR=36−22=14. B da mediana 33 va IQR=42−18=24. Demak B da ham mediana yuqori, ham IQR katta.'),
('P5DAT03-A03','A box plot has Q3=40 and an upper outlier fence of 58 using the 1.5×IQR rule. Enter Q1.','[]','28','58=40+1.5×IQR, so IQR=12. Since IQR=Q3−Q1, Q1=40−12=28.','Для диаграммы размаха Q3=40, а верхняя граница выбросов по правилу 1,5×IQR равна 58. Введите Q1.','[]','58=40+1,5×IQR, поэтому IQR=12. Так как IQR=Q3−Q1, получаем Q1=40−12=28.','Box plot uchun Q3=40, 1.5×IQR qoidasidagi yuqori chet qiymat chegarasi 58. Q1 ni kiriting.','[]','58=40+1.5×IQR, demak IQR=12. IQR=Q3−Q1 bo‘lgani uchun Q1=40−12=28.'),
('P5DAT07-A03','A data set has range 14. Every value x is transformed to y=−2x+3. Enter the range of the transformed data.','[]','28','Adding 3 does not change spread. Multiplying by −2 multiplies the range by |−2|=2, so the new range is 28.','Размах набора данных равен 14. Каждое значение x преобразуют по формуле y=−2x+3. Введите размах преобразованных данных.','[]','Прибавление 3 не меняет разброс. Умножение на −2 умножает размах на |−2|=2, поэтому новый размах равен 28.','Ma’lumotlar to‘plamining oraliq kengligi 14. Har bir x qiymat y=−2x+3 ga o‘zgartiriladi. Yangi ma’lumotlarning oraliq kengligini kiriting.','[]','3 ni qo‘shish tarqoqlikni o‘zgartirmaydi. −2 ga ko‘paytirish oraliq kengligini |−2|=2 marta oshiradi, demak yangi qiymat 28.'),
('P5CNT05-A01','A 3-person committee is chosen from 8 people, including A and B. Exactly one of A and B must be chosen. How many committees are possible?','["20","30","40","56"]','B','Choose which one of A or B is included in 2 ways, then choose the other 2 members from the remaining 6: 2×6C2=2×15=30.','Из 8 человек, среди которых A и B, выбирают комитет из 3 человек. Ровно один из A и B должен войти в комитет. Сколько комитетов возможно?','["20","30","40","56"]','Сначала выбираем одного из A и B — 2 способа, затем ещё 2 человек из оставшихся 6: 2×6C2=2×15=30.','8 kishidan, jumladan A va B dan, 3 kishilik qo‘mita tanlanadi. A va B dan aynan bittasi qo‘mitaga kirishi kerak. Nechta qo‘mita mumkin?','["20","30","40","56"]','A yoki B dan bittasini 2 usulda tanlaymiz, keyin qolgan 6 kishidan yana 2 tasini tanlaymiz: 2×6C2=2×15=30.'),
('P5CNT05-A02','A group of 10 people includes 3 seniors. How many 4-person committees contain at least one senior?','["35","105","210","175"]','D','Count all committees and subtract those with no senior: 10C4−7C4=210−35=175.','В группе из 10 человек есть 3 старших участника. Сколько комитетов из 4 человек содержат хотя бы одного старшего участника?','["35","105","210","175"]','Считаем все комитеты и вычитаем комитеты без старших участников: 10C4−7C4=210−35=175.','10 kishilik guruhda 3 nafar katta ishtirokchi bor. Kamida bitta katta ishtirokchi bo‘lgan 4 kishilik qo‘mitalar nechta?','["35","105","210","175"]','Barcha qo‘mitalardan katta ishtirokchisiz qo‘mitalarni ayiramiz: 10C4−7C4=210−35=175.'),
('P5PRO02-A01','A bag contains 5 red and 7 blue counters. Four counters are chosen without replacement. What is the probability of choosing exactly 3 red counters?','["14/99","7/33","28/99","5/12"]','A','Favourable selections are 5C3×7C1=10×7=70. Total selections are 12C4=495. Thus the probability is 70/495=14/99.','В мешке 5 красных и 7 синих фишек. Без возвращения выбирают 4 фишки. Какова вероятность выбрать ровно 3 красные?','["14/99","7/33","28/99","5/12"]','Благоприятных выборов: 5C3×7C1=10×7=70. Всего выборов: 12C4=495. Вероятность равна 70/495=14/99.','Qopda 5 qizil va 7 ko‘k jeton bor. Qaytarmasdan 4 ta jeton tanlanadi. Aynan 3 ta qizil tanlash ehtimoli qancha?','["14/99","7/33","28/99","5/12"]','Qulay tanlovlar: 5C3×7C1=10×7=70. Jami tanlovlar: 12C4=495. Ehtimol 70/495=14/99.'),
('P5PRO02-A02','From 8 girls and 4 boys, 3 students are chosen at random. What is the probability that at least one boy is chosen?','["14/55","8/11","3/5","41/55"]','D','Use the complement. P(no boys)=8C3/12C3=56/220=14/55. Therefore P(at least one boy)=1−14/55=41/55.','Из 8 девочек и 4 мальчиков случайно выбирают 3 учеников. Какова вероятность выбрать хотя бы одного мальчика?','["14/55","8/11","3/5","41/55"]','Используем дополнение. P(без мальчиков)=8C3/12C3=56/220=14/55. Поэтому P(хотя бы один мальчик)=1−14/55=41/55.','8 qiz va 4 o‘g‘ildan tasodifiy 3 o‘quvchi tanlanadi. Kamida bitta o‘g‘il tanlanish ehtimoli qancha?','["14/55","8/11","3/5","41/55"]','To‘ldiruvchidan foydalanamiz. P(o‘g‘il yo‘q)=8C3/12C3=56/220=14/55. Demak P(kamida bitta o‘g‘il)=1−14/55=41/55.'),
('P5PRO02-A03','From 7 boys and 5 girls, 3 students are chosen at random. Enter the numerator of the simplified probability that no girl is chosen.','[]','7','P(no girls)=7C3/12C3=35/220=7/44, so the numerator is 7.','Из 7 мальчиков и 5 девочек случайно выбирают 3 учеников. Введите числитель сокращённой вероятности того, что не будет выбрана ни одна девочка.','[]','P(без девочек)=7C3/12C3=35/220=7/44, поэтому числитель равен 7.','7 o‘g‘il va 5 qizdan tasodifiy 3 o‘quvchi tanlanadi. Hech bir qiz tanlanmaslik ehtimolining qisqartirilgan kasridagi suratni kiriting.','[]','P(qiz tanlanmaydi)=7C3/12C3=35/220=7/44, demak surat 7.'),
('P5PRO04-A01','P(A)=0.7 and P(A∩B)=0.28. Find P(B|A).','["0.98","0.40","0.196","0.12"]','B','P(B|A)=P(A∩B)/P(A)=0.28/0.7=0.40.','P(A)=0,7 и P(A∩B)=0,28. Найдите P(B|A).','["0,98","0,40","0,196","0,12"]','P(B|A)=P(A∩B)/P(A)=0,28/0,7=0,40.','P(A)=0.7 va P(A∩B)=0.28. P(B|A) ni toping.','["0.98","0.40","0.196","0.12"]','P(B|A)=P(A∩B)/P(A)=0.28/0.7=0.40.')
)
update public.questions q
set question_text=f.q_en,
    question_text_en=f.q_en,
    question_text_ru=f.q_ru,
    question_text_uz=f.q_uz,
    options_text=f.opts_en,
    options_text_en=f.opts_en,
    options_text_ru=f.opts_ru,
    options_text_uz=f.opts_uz,
    correct_answer=f.answer,
    explanation=f.exp_en,
    explanation_en=f.exp_en,
    explanation_ru=f.exp_ru,
    explanation_uz=f.exp_uz
from fixes f
join private.exam_prep_question_content_meta m
  on m.content_version_id in (4809,4810)
 and m.content_key=f.content_key
where q.id=m.question_id
  and q.is_active=false
  and q.quality_status='draft';

with titles(id,title_en,title_ru,title_uz) as (values
(35373,'Quadratics: inequalities — additional practice','Квадратные неравенства — дополнительная практика','Kvadrat tengsizliklar — qo‘shimcha mashq'),
(35374,'Quadratics: simultaneous relations — additional practice','Линейно-квадратичные системы — дополнительная практика','Chiziqli-kvadrat sistemalar — qo‘shimcha mashq'),
(35375,'Quadratics: transformed equations — additional practice','Уравнения с заменой переменной — дополнительная практика','O‘zgaruvchi almashtirishli tenglamalar — qo‘shimcha mashq'),
(35376,'Functions: compositions and domains — additional practice','Композиции функций и области определения — дополнительная практика','Funksiya kompozitsiyalari va aniqlanish sohalari — qo‘shimcha mashq'),
(35377,'Functions: inverses — additional practice','Обратные функции — дополнительная практика','Teskari funksiyalar — qo‘shimcha mashq'),
(35378,'Functions: inverse graphs — additional practice','Графики обратных функций — дополнительная практика','Teskari funksiya grafiklari — qo‘shimcha mashq'),
(35379,'Coordinate geometry: circles — additional practice','Координатная геометрия: окружности — дополнительная практика','Koordinata geometriyasi: aylanalar — qo‘shimcha mashq'),
(35380,'Circular measure: arc length — additional practice','Круговая мера: длина дуги — дополнительная практика','Aylana o‘lchovi: yoy uzunligi — qo‘shimcha mashq'),
(35381,'Data: box plots and outliers — additional practice','Данные: диаграммы размаха и выбросы — дополнительная практика','Ma’lumotlar: box plot va chet qiymatlar — qo‘shimcha mashq'),
(35382,'Data: cumulative frequency — additional practice','Данные: накопленная частота — дополнительная практика','Ma’lumotlar: kumulyativ chastota — qo‘shimcha mashq'),
(35383,'Data: measures of spread — additional practice','Данные: меры разброса — дополнительная практика','Ma’lumotlar: tarqoqlik o‘lchovlari — qo‘shimcha mashq'),
(35384,'Counting: combinations and restrictions — additional practice','Подсчёт: сочетания и ограничения — дополнительная практика','Sanash: kombinatsiyalar va cheklovlar — qo‘shimcha mashq'),
(35385,'Probability with combinations — additional practice','Вероятность с сочетаниями — дополнительная практика','Kombinatsiyalar bilan ehtimollik — qo‘shimcha mashq'),
(35386,'Probability: multiplication and independence — additional practice','Вероятность: умножение и независимость — дополнительная практика','Ehtimollik: ko‘paytirish va mustaqillik — qo‘shimcha mashq')
)
update private.exam_prep_assessments a
set title_en=t.title_en,title_ru=t.title_ru,title_uz=t.title_uz
from titles t
where a.id=t.id
  and a.content_version_id in (4809,4810)
  and a.status='draft';

update private.exam_prep_question_content_meta m
set question_snapshot_md5=md5(concat_ws(chr(31),
      q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
      coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
      coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
      coalesce(q.quality_flag,''),coalesce(q.quality_status,''))),
    updated_at=now()
from public.questions q
where q.id=m.question_id
  and m.content_version_id in (4809,4810)
  and m.content_key in ('P1QUA04-A01','P1QUA04-A02','P1QUA05-A01','P1QUA06-A03','P1FUN05-A01','P1FUN05-A02','P1COO04-A02','P1CIR02-A01','P1CIR02-A02','P5DAT03-A02','P5DAT03-A03','P5DAT07-A03','P5CNT05-A01','P5CNT05-A02','P5PRO02-A01','P5PRO02-A02','P5PRO02-A03','P5PRO04-A01');

do $postcheck$
declare
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4809,4810)
    and q.qtype='mcq'
    and (
      (select count(distinct v) from jsonb_array_elements_text(q.options_text_en::jsonb) z(v))<>4
      or (select count(distinct v) from jsonb_array_elements_text(q.options_text_ru::jsonb) z(v))<>4
      or (select count(distinct v) from jsonb_array_elements_text(q.options_text_uz::jsonb) z(v))<>4
    );
  if v_bad<>0 then
    raise exception 'aw09_12 independent QA: duplicate option rows=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4809,4810)
    and (
      nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
    );
  if v_bad<>0 then
    raise exception 'aw09_12 independent QA: trilingual surface incomplete rows=%',v_bad;
  end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4809;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,4,4,8) then
    raise exception 'aw09_12 independent QA: P1 answer balance mismatch A=% B=% C=% D=% input=%',
      v_a,v_b,v_c,v_d,v_inputs;
  end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4810;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(3,3,3,3,6) then
    raise exception 'aw09_12 independent QA: P5 answer balance mismatch A=% B=% C=% D=% input=%',
      v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code
     and oldm.content_version_id<>m.content_version_id
    join private.exam_prep_content_versions oldcv
      on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4809,4810)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then
    raise exception 'aw09_12 independent QA: exact published stem duplicate';
  end if;

  if exists(
    select 1 from private.exam_prep_assessments
    where content_version_id in (4809,4810)
      and (lower(coalesce(title_en,'')) like '%supplemental%'
        or lower(coalesce(title_ru,'')) like '%дополнительное обучение%'
        or lower(coalesce(title_uz,'')) like '%qo‘shimcha o‘rganish%')
  ) then
    raise exception 'aw09_12 independent QA: internal release wording remains in learner title';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4809,4810)
    and md5(concat_ws(chr(31),
      q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
      coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
      coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
      coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5;
  if v_bad<>0 then
    raise exception 'aw09_12 independent QA: frozen snapshot mismatch rows=%',v_bad;
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4809,4810)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4809,4810)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4809,4810)
  ) then
    raise exception 'aw09_12 independent QA: history appeared during correction';
  end if;
end
$postcheck$;

commit;
