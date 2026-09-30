-- AW9-12 P1 annual-reserve top-up draft v1.
-- DRAFT ONLY: no learner-visible content and no existing evidence mutation.
-- Exact delta per skill: +2 diagnostics, +2 delayed retests, +1 mixed/transfer.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw09_12_annual_reserve_p1_draft canonical program missing'; end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4811 and content_version<>'p1_aw09_12_annual_reserve_topup_draft_v1')
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59200 and 59239 and content_version_id<>4811)
  then raise exception 'aw09_12_annual_reserve_p1_draft reserved id collision'; end if;

  if (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-QUA-04','P1-QUA-05','P1-QUA-06','P1-FUN-03','P1-FUN-04','P1-FUN-05','P1-COO-04','P1-CIR-02')
        and m.reserve_role='diagnostic')<>8
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-QUA-04','P1-QUA-05','P1-QUA-06','P1-FUN-03','P1-FUN-04','P1-FUN-05','P1-COO-04','P1-CIR-02')
        and m.reserve_role='retest')<>16
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-QUA-04','P1-QUA-05','P1-QUA-06','P1-FUN-03','P1-FUN-04','P1-FUN-05','P1-COO-04','P1-CIR-02')
        and m.reserve_role in ('learning','mixed'))<>56
  then raise exception 'aw09_12_annual_reserve_p1_draft baseline depth changed'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4811,pv.id,'p1_aw09_12_annual_reserve_topup_draft_v1','P1',
 'P1 AW9-12 annual reserve top-up draft v1','draft',
 'Original iClub-authored annual reserve expansion. Official Cambridge 9709 scope controls the learning objectives; Complete Pure Mathematics 1 is mapping/explanation support only. No protected Cambridge/coursebook question, solution, mark-scheme wording or diagram is copied. Independent academic, trilingual, technical, originality and reserve-isolation QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,reserve_role,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P1QUA04-D02','P1-QUA-04','diagnostic','medium','mcq','A quantity is positive when (x−1)(x−6)>0. Which set of x-values satisfies this condition?','["x<1 or x>6","1<x<6","x≤1 or x≥6","1≤x≤6"]','A','The product is positive outside the two roots, so x<1 or x>6.','Величина положительна, когда (x−1)(x−6)>0. Какие значения x удовлетворяют этому условию?','["x<1 или x>6","1<x<6","x≤1 или x≥6","1≤x≤6"]','Произведение положительно вне промежутка между корнями, поэтому x<1 или x>6.','Miqdor (x−1)(x−6)>0 bo‘lganda musbat. Qaysi x qiymatlar bu shartni qanoatlantiradi?','["x<1 yoki x>6","1<x<6","x≤1 yoki x≥6","1≤x≤6"]','Ko‘paytma ikki ildiz oralig‘idan tashqarida musbat, demak x<1 yoki x>6.',70),
('P1QUA04-D03','P1-QUA-04','diagnostic','medium','mcq','Solve −2x²+7x−3≥0.','["x≤1/2 or x≥3","1/2≤x≤3","1/2<x<3","x<1/2 or x>3"]','B','−2x²+7x−3=−(2x−1)(x−3). The downward-opening quadratic is non-negative between its roots, including the roots.','Решите неравенство −2x²+7x−3≥0.','["x≤1/2 или x≥3","1/2≤x≤3","1/2<x<3","x<1/2 или x>3"]','−2x²+7x−3=−(2x−1)(x−3). Парабола направлена вниз и неотрицательна между корнями, включая корни.','−2x²+7x−3≥0 tengsizlikni yeching.','["x≤1/2 yoki x≥3","1/2≤x≤3","1/2<x<3","x<1/2 yoki x>3"]','−2x²+7x−3=−(2x−1)(x−3). Parabola pastga ochiladi va ildizlar orasida, ildizlarni ham qo‘shib, manfiy emas.',70),
('P1QUA04-R03','P1-QUA-04','retest','hard','input','The solution of x²−kx+12<0 is exactly 3<x<4. Enter k.','[]','7','The roots are 3 and 4, so the quadratic is (x−3)(x−4)=x²−7x+12. Hence k=7.','Решением x²−kx+12<0 является ровно 3<x<4. Введите k.','[]','Корни равны 3 и 4, поэтому квадратный трёхчлен равен (x−3)(x−4)=x²−7x+12. Следовательно, k=7.','x²−kx+12<0 tengsizlikning yechimi aynan 3<x<4. k ni kiriting.','[]','Ildizlar 3 va 4, shuning uchun kvadrat ifoda (x−3)(x−4)=x²−7x+12. Demak k=7.',80),
('P1QUA04-R04','P1-QUA-04','retest','medium','mcq','Solve (x−2)²≥16.','["−2≤x≤6","x≤−2 or x≥6","x<−2 or x>6","−6≤x≤2"]','B','|x−2|≥4, so x−2≤−4 or x−2≥4. Hence x≤−2 or x≥6.','Решите неравенство (x−2)²≥16.','["−2≤x≤6","x≤−2 или x≥6","x<−2 или x>6","−6≤x≤2"]','|x−2|≥4, поэтому x−2≤−4 или x−2≥4. Следовательно, x≤−2 или x≥6.','(x−2)²≥16 tengsizlikni yeching.','["−2≤x≤6","x≤−2 yoki x≥6","x<−2 yoki x>6","−6≤x≤2"]','|x−2|≥4, demak x−2≤−4 yoki x−2≥4. Shuning uchun x≤−2 yoki x≥6.',70),
('P1QUA04-M02','P1-QUA-04','mixed','hard','input','How many integer values of x satisfy both x²−9≤0 and x²−5x+4>0?','[]','4','The first gives −3≤x≤3. The second gives x<1 or x>4. Their intersection is −3≤x<1, containing −3,−2,−1,0: four integers.','Сколько целых значений x одновременно удовлетворяют x²−9≤0 и x²−5x+4>0?','[]','Первое неравенство даёт −3≤x≤3. Второе даёт x<1 или x>4. Пересечение: −3≤x<1, то есть −3,−2,−1,0 — четыре целых числа.','x²−9≤0 va x²−5x+4>0 tengsizliklarning ikkalasini ham nechta butun x qanoatlantiradi?','[]','Birinchi tengsizlik −3≤x≤3 ni beradi. Ikkinchisi x<1 yoki x>4. Kesishma −3≤x<1, ya’ni −3,−2,−1,0 — to‘rtta butun son.',95),
('P1QUA05-D02','P1-QUA-05','diagnostic','medium','mcq','The line y=3x−2 intersects the parabola y=x²−2x−1. Which are the x-coordinates of the intersections?','["1 and 4","−1 and 5","(5−√21)/2 and (5+√21)/2","2 and 3"]','C','Set the equations equal: 3x−2=x²−2x−1, so x²−5x+1=0. Thus x=(5±√21)/2.','Прямая y=3x−2 пересекает параболу y=x²−2x−1. Каковы x-координаты точек пересечения?','["1 и 4","−1 и 5","(5−√21)/2 и (5+√21)/2","2 и 3"]','Приравниваем: 3x−2=x²−2x−1, поэтому x²−5x+1=0. Отсюда x=(5±√21)/2.','y=3x−2 chiziq y=x²−2x−1 parabola bilan kesishadi. Kesishish nuqtalarining x-koordinatalari qaysilar?','["1 va 4","−1 va 5","(5−√21)/2 va (5+√21)/2","2 va 3"]','Tenglashtiramiz: 3x−2=x²−2x−1, bundan x²−5x+1=0. Shuning uchun x=(5±√21)/2.',70),
('P1QUA05-D03','P1-QUA-05','diagnostic','medium','mcq','The system x+y=5 and xy=4 has two ordered solutions. Which pair is correct?','["(2,3) and (3,2)","(−1,6) and (6,−1)","(2,2) and (3,3)","(1,4) and (4,1)"]','D','x and y have sum 5 and product 4, so they are roots of t²−5t+4=0=(t−1)(t−4). The ordered solutions are (1,4) and (4,1).','Система x+y=5 и xy=4 имеет два упорядоченных решения. Какая пара верна?','["(2,3) и (3,2)","(−1,6) и (6,−1)","(2,2) и (3,3)","(1,4) и (4,1)"]','x и y имеют сумму 5 и произведение 4, поэтому являются корнями t²−5t+4=0=(t−1)(t−4). Решения: (1,4) и (4,1).','x+y=5 va xy=4 sistema ikkita tartibli yechimga ega. Qaysi juft to‘g‘ri?','["(2,3) va (3,2)","(−1,6) va (6,−1)","(2,2) va (3,3)","(1,4) va (4,1)"]','x va y yig‘indisi 5, ko‘paytmasi 4, demak ular t²−5t+4=0=(t−1)(t−4) tenglamaning ildizlari. Yechimlar (1,4) va (4,1).',70),
('P1QUA05-R03','P1-QUA-05','retest','medium','input','The line y=2x+3 intersects y=x²−2x+6 at two points. Enter the sum of the two x-coordinates.','[]','4','Equating gives x²−4x+3=0. The sum of its roots is 4.','Прямая y=2x+3 пересекает y=x²−2x+6 в двух точках. Введите сумму двух x-координат.','[]','Приравнивая, получаем x²−4x+3=0. Сумма корней равна 4.','y=2x+3 chiziq y=x²−2x+6 bilan ikki nuqtada kesishadi. Ikki x-koordinata yig‘indisini kiriting.','[]','Tenglashtirib x²−4x+3=0 ni olamiz. Ildizlar yig‘indisi 4.',70),
('P1QUA05-R04','P1-QUA-05','retest','hard','mcq','For what value of k is the line y=2x+k tangent to the parabola y=x²+1?','["−1","0","1","2"]','B','Tangency gives one repeated solution: x²+1=2x+k, so x²−2x+(1−k)=0. Its discriminant is 4−4(1−k)=4k, so k=0.','При каком k прямая y=2x+k касается параболы y=x²+1?','["−1","0","1","2"]','Для касания должно быть одно повторное решение: x²+1=2x+k, то есть x²−2x+(1−k)=0. Дискриминант 4−4(1−k)=4k, поэтому k=0.','Qaysi k qiymatda y=2x+k chiziq y=x²+1 parabola bilan urinadi?','["−1","0","1","2"]','Urinish uchun bitta takroriy yechim bo‘lishi kerak: x²+1=2x+k, ya’ni x²−2x+(1−k)=0. Diskriminant 4−4(1−k)=4k, demak k=0.',85),
('P1QUA05-M02','P1-QUA-05','mixed','hard','input','The line y=x+k intersects the parabola y=x²−3x+5 at points whose x-coordinates differ by 2. Enter k.','[]','2','Intersections satisfy x²−4x+(5−k)=0. For roots differing by 2, (r1−r2)²=(r1+r2)²−4r1r2=16−4(5−k)=4k−4=4, so k=2. Therefore the correct value is 2.','Прямая y=x+k пересекает параболу y=x²−3x+5 в точках, x-координаты которых отличаются на 2. Введите k.','[]','Точки пересечения удовлетворяют x²−4x+(5−k)=0. Для корней с разностью 2: (r1−r2)²=(r1+r2)²−4r1r2=16−4(5−k)=4k−4=4, поэтому k=2.','y=x+k chiziq y=x²−3x+5 parabola bilan x-koordinatalari 2 ga farq qiladigan nuqtalarda kesishadi. k ni kiriting.','[]','Kesishishlar x²−4x+(5−k)=0 ni qanoatlantiradi. Ildizlar farqi 2 bo‘lsa: (r1−r2)²=(r1+r2)²−4r1r2=16−4(5−k)=4k−4=4, demak k=2.',95),
('P1QUA06-D02','P1-QUA-06','diagnostic','medium','mcq','How many real solutions does (x²+1)²−6(x²+1)+8=0 have?','["4","2","3","0"]','A','Let u=x²+1. Then u²−6u+8=0, so u=2 or 4. Thus x²=1 or 3, giving four real solutions.','Сколько действительных решений имеет (x²+1)²−6(x²+1)+8=0?','["4","2","3","0"]','Положим u=x²+1. Тогда u²−6u+8=0, поэтому u=2 или 4. Получаем x²=1 или 3, то есть четыре действительных решения.','(x²+1)²−6(x²+1)+8=0 tenglama nechta haqiqiy yechimga ega?','["4","2","3","0"]','u=x²+1 deb olamiz. Unda u²−6u+8=0, demak u=2 yoki 4. Shundan x²=1 yoki 3, ya’ni to‘rtta haqiqiy yechim.',75),
('P1QUA06-D03','P1-QUA-06','diagnostic','medium','mcq','Solve x⁶−7x³+12=0 over the real numbers. How many real solutions are there?','["4","2","6","1"]','B','Let u=x³. Then u²−7u+12=0, so u=3 or 4. Each gives one real cube root, so there are two real solutions.','Решите x⁶−7x³+12=0 в действительных числах. Сколько действительных решений?','["4","2","6","1"]','Положим u=x³. Тогда u²−7u+12=0, поэтому u=3 или 4. Каждое значение даёт один действительный кубический корень, всего два решения.','x⁶−7x³+12=0 tenglamani haqiqiy sonlarda yeching. Nechta haqiqiy yechim bor?','["4","2","6","1"]','u=x³ deb olamiz. Unda u²−7u+12=0, demak u=3 yoki 4. Har biri bitta haqiqiy kub ildiz beradi, jami ikkita yechim.',75),
('P1QUA06-R03','P1-QUA-06','retest','hard','input','How many distinct real solutions does (x²−4x+5)²−5(x²−4x+5)+4=0 have?','[]','3','Let u=x²−4x+5=(x−2)²+1. The equation gives u=1 or 4. For u=1, x=2; for u=4, (x−2)²=3, giving two more solutions. Total: 3.','Сколько различных действительных решений имеет (x²−4x+5)²−5(x²−4x+5)+4=0?','[]','Пусть u=x²−4x+5=(x−2)²+1. Тогда u=1 или 4. При u=1 получаем x=2; при u=4 имеем (x−2)²=3 и ещё два решения. Всего 3.','(x²−4x+5)²−5(x²−4x+5)+4=0 tenglama nechta turli haqiqiy yechimga ega?','[]','u=x²−4x+5=(x−2)²+1 deb olamiz. Unda u=1 yoki 4. u=1 da x=2; u=4 da (x−2)²=3 bo‘lib yana ikki yechim chiqadi. Jami 3.',90),
('P1QUA06-R04','P1-QUA-06','retest','medium','mcq','How many real solutions does (x+2)⁴−17(x+2)²+16=0 have?','["2","4","3","0"]','B','Let u=(x+2)². Then u²−17u+16=0, so u=1 or 16. Each positive u gives two real x-values, so there are four.','Сколько действительных решений имеет (x+2)⁴−17(x+2)²+16=0?','["2","4","3","0"]','Положим u=(x+2)². Тогда u²−17u+16=0, поэтому u=1 или 16. Каждое положительное u даёт два значения x, всего четыре.','(x+2)⁴−17(x+2)²+16=0 tenglama nechta haqiqiy yechimga ega?','["2","4","3","0"]','u=(x+2)² deb olamiz. Unda u²−17u+16=0, demak u=1 yoki 16. Har bir musbat u ikkita x qiymat beradi, jami to‘rtta.',80),
('P1QUA06-M02','P1-QUA-06','mixed','hard','input','For all real solutions of (x²−1)²−5(x²−1)+4=0, enter the sum of the squares of the solutions.','[]','14','Let u=x²−1. Then u=1 or 4, so x²=2 or 5. The four solutions have squares 2,2,5,5, whose sum is 14.','Для всех действительных решений (x²−1)²−5(x²−1)+4=0 введите сумму квадратов решений.','[]','Пусть u=x²−1. Тогда u=1 или 4, значит x²=2 или 5. Квадраты четырёх решений: 2,2,5,5; их сумма 14.','(x²−1)²−5(x²−1)+4=0 tenglamaning barcha haqiqiy yechimlari kvadratlari yig‘indisini kiriting.','[]','u=x²−1 deb olamiz. Unda u=1 yoki 4, demak x²=2 yoki 5. To‘rtta yechim kvadratlari 2,2,5,5 bo‘lib, yig‘indisi 14.',95),
('P1FUN03-D02','P1-FUN-03','diagnostic','medium','mcq','Let f(x)=√(x−3) and g(x)=2−x. What is the real domain of (f∘g)(x)?','["x≥−1","x≥1","x≤−1","x≤1"]','C','f(g(x))=√((2−x)−3)=√(−x−1), which requires −x−1≥0, so x≤−1.','Пусть f(x)=√(x−3), g(x)=2−x. Какова действительная область определения (f∘g)(x)?','["x≥−1","x≥1","x≤−1","x≤1"]','f(g(x))=√((2−x)−3)=√(−x−1), поэтому нужно −x−1≥0, то есть x≤−1.','f(x)=√(x−3), g(x)=2−x bo‘lsin. (f∘g)(x) ning haqiqiy aniqlanish sohasi qanday?','["x≥−1","x≥1","x≤−1","x≤1"]','f(g(x))=√((2−x)−3)=√(−x−1), demak −x−1≥0 bo‘lishi kerak, ya’ni x≤−1.',70),
('P1FUN03-D03','P1-FUN-03','diagnostic','hard','mcq','Let f(x)=1/(x−1) and g(x)=√x. Which restrictions define the real domain of (f∘g)(x)?','["x>0 only","x≠1 only","x≥1","x≥0 and x≠1"]','D','g requires x≥0. Also f(g(x)) is undefined when √x=1, so x≠1.','Пусть f(x)=1/(x−1), g(x)=√x. Какие ограничения задают действительную область определения (f∘g)(x)?','["только x>0","только x≠1","x≥1","x≥0 и x≠1"]','Для g нужно x≥0. Кроме того, f(g(x)) не определена при √x=1, поэтому x≠1.','f(x)=1/(x−1), g(x)=√x bo‘lsin. (f∘g)(x) ning haqiqiy aniqlanish sohasini qaysi cheklovlar beradi?','["faqat x>0","faqat x≠1","x≥1","x≥0 va x≠1"]','g uchun x≥0 kerak. Bundan tashqari √x=1 bo‘lganda f(g(x)) aniqlanmagan, shuning uchun x≠1.',80),
('P1FUN03-R03','P1-FUN-03','retest','medium','input','Let f(x)=1/x and g(x)=x²−5x+6. The domain of (f∘g)(x) excludes two values. Enter their sum.','[]','5','f(g(x)) is undefined when g(x)=0. Since x²−5x+6=(x−2)(x−3), the excluded values are 2 and 3, whose sum is 5.','Пусть f(x)=1/x, g(x)=x²−5x+6. Из области определения (f∘g)(x) исключены два значения. Введите их сумму.','[]','f(g(x)) не определена, когда g(x)=0. Так как x²−5x+6=(x−2)(x−3), исключаются 2 и 3; их сумма 5.','f(x)=1/x, g(x)=x²−5x+6 bo‘lsin. (f∘g)(x) aniqlanish sohasidan ikkita qiymat chiqariladi. Ularning yig‘indisini kiriting.','[]','g(x)=0 bo‘lganda f(g(x)) aniqlanmagan. x²−5x+6=(x−2)(x−3), shuning uchun 2 va 3 chiqariladi; yig‘indisi 5.',70),
('P1FUN03-R04','P1-FUN-03','retest','hard','mcq','Let f(x)=x²−4 with domain x≥0 and g(x)=√(x+1). What is the real domain of (g∘f)(x)?','["x≥0","x≥√3","x≤−√3 or x≥√3","all real x"]','B','The domain of f already requires x≥0. Also g(f(x))=√(x²−3), so x²−3≥0. Combining with x≥0 gives x≥√3.','Пусть f(x)=x²−4 при x≥0, g(x)=√(x+1). Какова действительная область определения (g∘f)(x)?','["x≥0","x≥√3","x≤−√3 или x≥√3","все действительные x"]','Область f уже требует x≥0. Кроме того, g(f(x))=√(x²−3), поэтому x²−3≥0. Вместе получаем x≥√3.','f(x)=x²−4, x≥0 va g(x)=√(x+1) bo‘lsin. (g∘f)(x) ning haqiqiy aniqlanish sohasi qanday?','["x≥0","x≥√3","x≤−√3 yoki x≥√3","barcha haqiqiy x"]','f sohasi x≥0 ni talab qiladi. Bundan tashqari g(f(x))=√(x²−3), demak x²−3≥0. Birgalikda x≥√3.',85),
('P1FUN03-M02','P1-FUN-03','mixed','hard','mcq','Let f(x)=√x and g(x)=x²−5x+4. What is the real domain of (f∘g)(x)?','["1≤x≤4","x≤1 or x≥4","x<1 or x>4","all real x"]','B','The square-root input must be non-negative: x²−5x+4=(x−1)(x−4)≥0. Hence x≤1 or x≥4.','Пусть f(x)=√x, g(x)=x²−5x+4. Какова действительная область определения (f∘g)(x)?','["1≤x≤4","x≤1 или x≥4","x<1 или x>4","все действительные x"]','Подкоренное выражение должно быть неотрицательным: x²−5x+4=(x−1)(x−4)≥0. Поэтому x≤1 или x≥4.','f(x)=√x, g(x)=x²−5x+4 bo‘lsin. (f∘g)(x) ning haqiqiy aniqlanish sohasi qanday?','["1≤x≤4","x≤1 yoki x≥4","x<1 yoki x>4","barcha haqiqiy x"]','Ildiz ostidagi ifoda manfiy bo‘lmasligi kerak: x²−5x+4=(x−1)(x−4)≥0. Demak x≤1 yoki x≥4.',85),
('P1FUN04-D02','P1-FUN-04','diagnostic','hard','mcq','Let f(x)=(x+1)/(2x−3), x≠3/2. Which formula gives f⁻¹(x)?','["(3x+1)/(2x−1)","(3x−1)/(2x+1)","(x−3)/(2x+1)","(3x+1)/(1−2x)"]','A','From y=(x+1)/(2x−3), 2xy−3y=x+1, so x(2y−1)=3y+1 and x=(3y+1)/(2y−1).','Пусть f(x)=(x+1)/(2x−3), x≠3/2. Какая формула задаёт f⁻¹(x)?','["(3x+1)/(2x−1)","(3x−1)/(2x+1)","(x−3)/(2x+1)","(3x+1)/(1−2x)"]','Из y=(x+1)/(2x−3): 2xy−3y=x+1, поэтому x(2y−1)=3y+1 и x=(3y+1)/(2y−1).','f(x)=(x+1)/(2x−3), x≠3/2 bo‘lsin. f⁻¹(x) ni qaysi formula beradi?','["(3x+1)/(2x−1)","(3x−1)/(2x+1)","(x−3)/(2x+1)","(3x+1)/(1−2x)"]','y=(x+1)/(2x−3) dan 2xy−3y=x+1, demak x(2y−1)=3y+1 va x=(3y+1)/(2y−1).',90),
('P1FUN04-D03','P1-FUN-04','diagnostic','hard','mcq','Let f(x)=x²+6x+5 with domain x≥−3. Which inverse is correct?','["−3−√(x+4)","−3+√(x+4)","3+√(x−4)","−3+√(x−4)"]','B','f(x)=(x+3)²−4. On x≥−3, x+3≥0, so f⁻¹(y)=−3+√(y+4).','Пусть f(x)=x²+6x+5 при x≥−3. Какая обратная функция верна?','["−3−√(x+4)","−3+√(x+4)","3+√(x−4)","−3+√(x−4)"]','f(x)=(x+3)²−4. При x≥−3 имеем x+3≥0, поэтому f⁻¹(y)=−3+√(y+4).','f(x)=x²+6x+5, x≥−3 bo‘lsin. Qaysi teskari funksiya to‘g‘ri?','["−3−√(x+4)","−3+√(x+4)","3+√(x−4)","−3+√(x−4)"]','f(x)=(x+3)²−4. x≥−3 da x+3≥0, shuning uchun f⁻¹(y)=−3+√(y+4).',90),
('P1FUN04-R03','P1-FUN-04','retest','medium','input','Let f(x)=(4x−1)/(x+2). Enter f⁻¹(3).','[]','7','f⁻¹(3) is the x-value satisfying f(x)=3. Solve 4x−1=3x+6 to get x=7.','Пусть f(x)=(4x−1)/(x+2). Введите f⁻¹(3).','[]','f⁻¹(3) — это x, для которого f(x)=3. Решаем 4x−1=3x+6 и получаем x=7.','f(x)=(4x−1)/(x+2) bo‘lsin. f⁻¹(3) ni kiriting.','[]','f⁻¹(3) — f(x)=3 bo‘ladigan x. 4x−1=3x+6 ni yechib x=7 ni olamiz.',70),
('P1FUN04-R04','P1-FUN-04','retest','medium','mcq','Let f(x)=3x+k. If f⁻¹(5)=2, what is k?','["1","−1","5","−5"]','B','f⁻¹(5)=2 means f(2)=5. Thus 6+k=5, so k=−1.','Пусть f(x)=3x+k. Если f⁻¹(5)=2, чему равно k?','["1","−1","5","−5"]','f⁻¹(5)=2 означает f(2)=5. Поэтому 6+k=5 и k=−1.','f(x)=3x+k bo‘lsin. Agar f⁻¹(5)=2 bo‘lsa, k nechaga teng?','["1","−1","5","−5"]','f⁻¹(5)=2 degani f(2)=5. Demak 6+k=5 va k=−1.',65),
('P1FUN04-M02','P1-FUN-04','mixed','hard','input','Let f(x)=x²−6x+11 with domain x≥3. Enter f⁻¹(27).','[]','8','f(x)=(x−3)²+2, so f⁻¹(y)=3+√(y−2). Hence f⁻¹(27)=3+5=8.','Пусть f(x)=x²−6x+11 при x≥3. Введите f⁻¹(27).','[]','f(x)=(x−3)²+2, поэтому f⁻¹(y)=3+√(y−2). Значит, f⁻¹(27)=3+5=8.','f(x)=x²−6x+11, x≥3 bo‘lsin. f⁻¹(27) ni kiriting.','[]','f(x)=(x−3)²+2, demak f⁻¹(y)=3+√(y−2). Shuning uchun f⁻¹(27)=3+5=8.',80),
('P1FUN05-D02','P1-FUN-05','diagnostic','medium','mcq','The graph y=f(x) passes through (−2,6). Which point must lie on y=f⁻¹(x)?','["(2,−6)","(−6,2)","(6,−2)","(−2,6)"]','C','Reflection in y=x swaps coordinates, so (−2,6) becomes (6,−2).','График y=f(x) проходит через (−2,6). Какая точка обязательно лежит на y=f⁻¹(x)?','["(2,−6)","(−6,2)","(6,−2)","(−2,6)"]','Отражение относительно y=x меняет координаты местами: (−2,6) переходит в (6,−2).','y=f(x) grafigi (−2,6) nuqtadan o‘tadi. y=f⁻¹(x) grafigida qaysi nuqta albatta yotadi?','["(2,−6)","(−6,2)","(6,−2)","(−2,6)"]','y=x ga nisbatan akslantirish koordinatalarni almashtiradi: (−2,6) → (6,−2).',60),
('P1FUN05-D03','P1-FUN-05','diagnostic','medium','mcq','If y=f(x) has y-intercept (0,−4), which intercept does y=f⁻¹(x) have?','["y-intercept (0,4)","x-intercept (4,0)","y-intercept (0,−4)","x-intercept (−4,0)"]','D','Reflection in y=x changes (0,−4) to (−4,0), an x-intercept.','Если график y=f(x) пересекает ось y в точке (0,−4), какое пересечение имеет y=f⁻¹(x)?','["с осью y в (0,4)","с осью x в (4,0)","с осью y в (0,−4)","с осью x в (−4,0)"]','Отражение относительно y=x переводит (0,−4) в (−4,0), то есть в точку пересечения с осью x.','Agar y=f(x) grafigining y o‘qi bilan kesishishi (0,−4) bo‘lsa, y=f⁻¹(x) qaysi kesishishga ega?','["y o‘qi bilan (0,4)","x o‘qi bilan (4,0)","y o‘qi bilan (0,−4)","x o‘qi bilan (−4,0)"]','y=x ga nisbatan akslantirish (0,−4) ni (−4,0) ga o‘tkazadi, bu x o‘qi bilan kesishish.',60),
('P1FUN05-R03','P1-FUN-05','retest','medium','input','A point P=(−2,5) on y=f(x) corresponds to Q on y=f⁻¹(x). Enter the x-coordinate of the midpoint of PQ.','[]','1.5','Q=(5,−2). The midpoint x-coordinate is (−2+5)/2=1.5.','Точке P=(−2,5) на y=f(x) соответствует точка Q на y=f⁻¹(x). Введите x-координату середины PQ.','[]','Q=(5,−2). x-координата середины равна (−2+5)/2=1,5.','y=f(x) dagi P=(−2,5) nuqtaga y=f⁻¹(x) da Q nuqta mos keladi. PQ kesma o‘rta nuqtasining x-koordinatasini kiriting.','[]','Q=(5,−2). O‘rta nuqtaning x-koordinatasi (−2+5)/2=1.5.',65),
('P1FUN05-R04','P1-FUN-05','retest','medium','mcq','The graph y=f(x) has x-intercept (−7,0). Which point lies on y=f⁻¹(x)?','["(7,0)","(0,−7)","(−7,0)","(0,7)"]','B','Reflection in y=x swaps the coordinates, so (−7,0) becomes (0,−7).','График y=f(x) пересекает ось x в точке (−7,0). Какая точка лежит на y=f⁻¹(x)?','["(7,0)","(0,−7)","(−7,0)","(0,7)"]','Отражение относительно y=x меняет координаты местами, поэтому (−7,0) переходит в (0,−7).','y=f(x) grafigi x o‘qini (−7,0) nuqtada kesadi. y=f⁻¹(x) da qaysi nuqta yotadi?','["(7,0)","(0,−7)","(−7,0)","(0,7)"]','y=x ga nisbatan akslantirish koordinatalarni almashtiradi, shuning uchun (−7,0) → (0,−7).',60),
('P1FUN05-M02','P1-FUN-05','mixed','hard','input','A point P=(1,5) on y=f(x) is reflected to Q on y=f⁻¹(x). Enter the sum of the coordinates of the midpoint of PQ.','[]','6','Q=(5,1). The midpoint is (3,3), whose coordinate sum is 6.','Точка P=(1,5) на y=f(x) отражается в точку Q на y=f⁻¹(x). Введите сумму координат середины PQ.','[]','Q=(5,1). Середина равна (3,3), сумма координат 6.','y=f(x) dagi P=(1,5) nuqta y=f⁻¹(x) dagi Q ga akslanadi. PQ o‘rta nuqtasi koordinatalari yig‘indisini kiriting.','[]','Q=(5,1). O‘rta nuqta (3,3), koordinatalar yig‘indisi 6.',70),
('P1COO04-D02','P1-COO-04','diagnostic','medium','mcq','Find the centre and radius of x²+y²−8x+6y−11=0.','["centre (4,−3), radius 6","centre (−4,3), radius 6","centre (4,−3), radius 36","centre (−4,3), radius 36"]','A','Complete squares: (x−4)²+(y+3)²=36. The centre is (4,−3) and the radius is 6.','Найдите центр и радиус окружности x²+y²−8x+6y−11=0.','["центр (4,−3), радиус 6","центр (−4,3), радиус 6","центр (4,−3), радиус 36","центр (−4,3), радиус 36"]','Дополняем до квадратов: (x−4)²+(y+3)²=36. Центр (4,−3), радиус 6.','x²+y²−8x+6y−11=0 aylananing markazi va radiusini toping.','["markaz (4,−3), radius 6","markaz (−4,3), radius 6","markaz (4,−3), radius 36","markaz (−4,3), radius 36"]','Kvadratlarni to‘ldiramiz: (x−4)²+(y+3)²=36. Markaz (4,−3), radius 6.',75),
('P1COO04-D03','P1-COO-04','diagnostic','medium','mcq','A circle has diameter endpoints (−2,1) and (4,5). Which equation is correct?','["(x−1)²+(y−3)²=52","(x−1)²+(y−3)²=13","(x+1)²+(y+3)²=13","(x−4)²+(y−5)²=13"]','B','The centre is the midpoint (1,3). The diameter length is √52=2√13, so the radius is √13 and r²=13.','Диаметр окружности имеет концы (−2,1) и (4,5). Какое уравнение верно?','["(x−1)²+(y−3)²=52","(x−1)²+(y−3)²=13","(x+1)²+(y+3)²=13","(x−4)²+(y−5)²=13"]','Центр — середина (1,3). Длина диаметра √52=2√13, поэтому радиус √13 и r²=13.','Aylana diametrining uchlari (−2,1) va (4,5). Qaysi tenglama to‘g‘ri?','["(x−1)²+(y−3)²=52","(x−1)²+(y−3)²=13","(x+1)²+(y+3)²=13","(x−4)²+(y−5)²=13"]','Markaz o‘rta nuqta (1,3). Diametr uzunligi √52=2√13, demak radius √13 va r²=13.',80),
('P1COO04-R03','P1-COO-04','retest','medium','input','A circle has centre (3,−4) and is tangent to the x-axis. Enter its radius.','[]','4','The radius equals the perpendicular distance from the centre to the x-axis, which is |−4|=4.','Окружность имеет центр (3,−4) и касается оси x. Введите её радиус.','[]','Радиус равен перпендикулярному расстоянию от центра до оси x: |−4|=4.','Aylana markazi (3,−4) va u x o‘qiga urinadi. Radiusni kiriting.','[]','Radius markazdan x o‘qigacha perpendikulyar masofa bo‘lib, |−4|=4.',60),
('P1COO04-R04','P1-COO-04','retest','medium','mcq','The circle x²+y²−6x+4y+k=0 passes through (3,2). Find k.','["3","−3","9","−9"]','B','Substitute (3,2): 9+4−18+8+k=0, so 3+k=0 and k=−3.','Окружность x²+y²−6x+4y+k=0 проходит через (3,2). Найдите k.','["3","−3","9","−9"]','Подставляем (3,2): 9+4−18+8+k=0, поэтому 3+k=0 и k=−3.','x²+y²−6x+4y+k=0 aylana (3,2) nuqtadan o‘tadi. k ni toping.','["3","−3","9","−9"]','(3,2) ni qo‘yamiz: 9+4−18+8+k=0, demak 3+k=0 va k=−3.',65),
('P1COO04-M02','P1-COO-04','mixed','hard','mcq','A circle has its centre on the x-axis and passes through (2,3) and (6,3). Which equation is correct?','["(x−4)²+y²=13","(x−2)²+y²=13","(x−4)²+(y−3)²=4","x²+(y−3)²=13"]','A','The centre lies on the perpendicular bisector of the chord joining the two points, so its x-coordinate is 4; being on the x-axis gives centre (4,0). The radius squared is (2−4)²+3²=13.','Центр окружности лежит на оси x, а окружность проходит через (2,3) и (6,3). Какое уравнение верно?','["(x−4)²+y²=13","(x−2)²+y²=13","(x−4)²+(y−3)²=4","x²+(y−3)²=13"]','Центр лежит на серединном перпендикуляре к хорде, поэтому его x-координата 4; на оси x получаем центр (4,0). r²=(2−4)²+3²=13.','Aylana markazi x o‘qida yotadi va aylana (2,3) hamda (6,3) nuqtalardan o‘tadi. Qaysi tenglama to‘g‘ri?','["(x−4)²+y²=13","(x−2)²+y²=13","(x−4)²+(y−3)²=4","x²+(y−3)²=13"]','Markaz ushbu xordaning o‘rta perpendikulyarida, demak x-koordinatasi 4; x o‘qida bo‘lgani uchun markaz (4,0). r²=(2−4)²+3²=13.',90),
('P1CIR02-D02','P1-CIR-02','diagnostic','medium','mcq','A sector has radius 6 cm and perimeter 21 cm. What is its central angle in radians?','["3.5","0.75","1.5","1.25"]','C','The arc length is 21−2(6)=9 cm. Hence θ=s/r=9/6=1.5 radians.','Сектор имеет радиус 6 см и периметр 21 см. Каков его центральный угол в радианах?','["3,5","0,75","1,5","1,25"]','Длина дуги равна 21−2·6=9 см. Поэтому θ=s/r=9/6=1,5 радиана.','Sektor radiusi 6 sm va perimetri 21 sm. Markaziy burchak necha radian?','["3.5","0.75","1.5","1.25"]','Yoy uzunligi 21−2·6=9 sm. Demak θ=s/r=9/6=1.5 radian.',70),
('P1CIR02-D03','P1-CIR-02','diagnostic','medium','mcq','Two arcs subtend the same angle. The first has radius 4 cm and arc length 7 cm. The second has radius 10 cm. What is the second arc length?','["2.8 cm","13 cm","14 cm","17.5 cm"]','D','The common angle is θ=7/4. The second arc length is 10×7/4=17.5 cm.','Две дуги стягивают одинаковый угол. У первой радиус 4 см и длина дуги 7 см. У второй радиус 10 см. Какова длина второй дуги?','["2,8 см","13 см","14 см","17,5 см"]','Общий угол θ=7/4. Длина второй дуги равна 10×7/4=17,5 см.','Ikki yoy bir xil burchak hosil qiladi. Birinchi yoy radiusi 4 sm va uzunligi 7 sm. Ikkinchi radius 10 sm. Ikkinchi yoy uzunligi qancha?','["2.8 sm","13 sm","14 sm","17.5 sm"]','Umumiy burchak θ=7/4. Ikkinchi yoy uzunligi 10×7/4=17.5 sm.',70),
('P1CIR02-R03','P1-CIR-02','retest','hard','input','An arc has length 10π cm and subtends 150° at the centre. Enter the radius in cm.','[]','12','150°=5π/6 radians. Using s=rθ gives r=10π/(5π/6)=12.','Длина дуги равна 10π см, а центральный угол — 150°. Введите радиус в см.','[]','150°=5π/6 радиана. По s=rθ получаем r=10π/(5π/6)=12.','Yoy uzunligi 10π sm va markaziy burchak 150°. Radiusni sm da kiriting.','[]','150°=5π/6 radian. s=rθ dan r=10π/(5π/6)=12.',80),
('P1CIR02-R04','P1-CIR-02','retest','medium','mcq','An arc has length 5π cm in a circle of radius 6 cm. What angle does it subtend at the centre in degrees?','["120°","150°","75°","300°"]','B','θ=s/r=5π/6 radians, which is 150°.','Дуга длиной 5π см лежит на окружности радиуса 6 см. Какой угол в градусах она стягивает в центре?','["120°","150°","75°","300°"]','θ=s/r=5π/6 радиана, что равно 150°.','Uzunligi 5π sm bo‘lgan yoy radiusi 6 sm aylanada. U markazda necha gradus burchak hosil qiladi?','["120°","150°","75°","300°"]','θ=s/r=5π/6 radian, bu 150° ga teng.',70),
('P1CIR02-M02','P1-CIR-02','mixed','hard','input','Two arcs have equal length. The first has radius 8 cm and angle 1.5 radians. The second has radius 5 cm. Enter the second angle in radians.','[]','2.4','The common arc length is 8×1.5=12 cm. For the second arc, θ=12/5=2.4 radians.','Две дуги имеют одинаковую длину. У первой радиус 8 см и угол 1,5 радиана. У второй радиус 5 см. Введите второй угол в радианах.','[]','Общая длина дуги равна 8×1,5=12 см. Для второй дуги θ=12/5=2,4 радиана.','Ikki yoy uzunligi teng. Birinchi yoy radiusi 8 sm va burchagi 1.5 radian. Ikkinchi yoy radiusi 5 sm. Ikkinchi burchakni radianlarda kiriting.','[]','Umumiy yoy uzunligi 8×1.5=12 sm. Ikkinchi yoy uchun θ=12/5=2.4 radian.',80)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,
 case when s.skill_code like 'P1-QUA-%' then 'P1 Quadratics'
      when s.skill_code like 'P1-FUN-%' then 'P1 Functions'
      when s.skill_code='P1-COO-04' then 'P1 Coordinate geometry'
      else 'P1 Circular measure' end,
 s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P1:p1_aw09_12_annual_reserve_topup_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P1:p1_aw09_12_annual_reserve_topup_draft_v1:'||s.content_key);

with src(content_key,skill_code,meta_id) as (values
('P1QUA04-D02','P1-QUA-04',59200),
('P1QUA04-D03','P1-QUA-04',59201),
('P1QUA04-R03','P1-QUA-04',59202),
('P1QUA04-R04','P1-QUA-04',59203),
('P1QUA04-M02','P1-QUA-04',59204),
('P1QUA05-D02','P1-QUA-05',59205),
('P1QUA05-D03','P1-QUA-05',59206),
('P1QUA05-R03','P1-QUA-05',59207),
('P1QUA05-R04','P1-QUA-05',59208),
('P1QUA05-M02','P1-QUA-05',59209),
('P1QUA06-D02','P1-QUA-06',59210),
('P1QUA06-D03','P1-QUA-06',59211),
('P1QUA06-R03','P1-QUA-06',59212),
('P1QUA06-R04','P1-QUA-06',59213),
('P1QUA06-M02','P1-QUA-06',59214),
('P1FUN03-D02','P1-FUN-03',59215),
('P1FUN03-D03','P1-FUN-03',59216),
('P1FUN03-R03','P1-FUN-03',59217),
('P1FUN03-R04','P1-FUN-03',59218),
('P1FUN03-M02','P1-FUN-03',59219),
('P1FUN04-D02','P1-FUN-04',59220),
('P1FUN04-D03','P1-FUN-04',59221),
('P1FUN04-R03','P1-FUN-04',59222),
('P1FUN04-R04','P1-FUN-04',59223),
('P1FUN04-M02','P1-FUN-04',59224),
('P1FUN05-D02','P1-FUN-05',59225),
('P1FUN05-D03','P1-FUN-05',59226),
('P1FUN05-R03','P1-FUN-05',59227),
('P1FUN05-R04','P1-FUN-05',59228),
('P1FUN05-M02','P1-FUN-05',59229),
('P1COO04-D02','P1-COO-04',59230),
('P1COO04-D03','P1-COO-04',59231),
('P1COO04-R03','P1-COO-04',59232),
('P1COO04-R04','P1-COO-04',59233),
('P1COO04-M02','P1-COO-04',59234),
('P1CIR02-D02','P1-CIR-02',59235),
('P1CIR02-D03','P1-CIR-02',59236),
('P1CIR02-R03','P1-CIR-02',59237),
('P1CIR02-R04','P1-CIR-02',59238),
('P1CIR02-M02','P1-CIR-02',59239)
), cv as (select id from private.exam_prep_content_versions where id=4811)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,cv.id,s.content_key,qn.id,s.skill_code,'{}'::text[],r.reserve_role,'withheld','draft',
 'Original iClub-authored annual reserve item; stem, values, distractors, answer and explanation are independently authored.',
 'AW9-12 annual reserve draft. Official syllabus controls scope; coursebook mapping is used only to locate the learning objective.',
 case when s.skill_code like 'P1-QUA-%' then 'Cambridge 9709 2026-2027 v4; P1 1.1 Quadratics'
      when s.skill_code like 'P1-FUN-%' then 'Cambridge 9709 2026-2027 v4; P1 1.2 Functions'
      when s.skill_code='P1-COO-04' then 'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry'
      else 'Cambridge 9709 2026-2027 v4; P1 1.4 Circular measure' end,
 case when s.skill_code like 'P1-QUA-%' then 'Complete Pure Mathematics 1, Ch1 Quadratics pp.2-20 (mapping only)'
      when s.skill_code like 'P1-FUN-%' then 'Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)'
      when s.skill_code='P1-COO-04' then 'Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)'
      else 'Complete Pure Mathematics 1, Ch4 Circular measure pp.74-81 (mapping only)' end,
 'pending','pending','pending','pending','pending',
 case when r.reserve_role='diagnostic' then 'draft' else 'not_applicable' end,
 md5(concat_ws(chr(31),
   qn.id::text,qn.subject_id::text,coalesce(qn.topic,''),coalesce(qn.subtopic,''),coalesce(qn.difficulty,''),coalesce(qn.qtype,''),
   coalesce(qn.question_text,''),coalesce(qn.options_text,''),coalesce(qn.correct_answer,''),coalesce(qn.explanation,''),
   coalesce(qn.image_url,''),coalesce(qn.is_active::text,''),coalesce(qn.question_text_ru,''),coalesce(qn.question_text_uz,''),
   coalesce(qn.question_text_en,''),coalesce(qn.options_text_ru,''),coalesce(qn.options_text_uz,''),coalesce(qn.options_text_en,''),
   coalesce(qn.explanation_ru,''),coalesce(qn.explanation_uz,''),coalesce(qn.explanation_en,''),coalesce(qn.book_ref,''),
   coalesce(qn.time_limit_sec::text,''),coalesce(qn.quality_flag,''),coalesce(qn.quality_status,'')
 ))
from cv cross join src s
join public.questions qn on qn.book_ref='ExamPrep:P1:p1_aw09_12_annual_reserve_topup_draft_v1:'||s.content_key
join (values ('P1QUA04-D02','diagnostic'),('P1QUA04-D03','diagnostic'),('P1QUA04-R03','retest'),('P1QUA04-R04','retest'),('P1QUA04-M02','mixed'),('P1QUA05-D02','diagnostic'),('P1QUA05-D03','diagnostic'),('P1QUA05-R03','retest'),('P1QUA05-R04','retest'),('P1QUA05-M02','mixed'),('P1QUA06-D02','diagnostic'),('P1QUA06-D03','diagnostic'),('P1QUA06-R03','retest'),('P1QUA06-R04','retest'),('P1QUA06-M02','mixed'),('P1FUN03-D02','diagnostic'),('P1FUN03-D03','diagnostic'),('P1FUN03-R03','retest'),('P1FUN03-R04','retest'),('P1FUN03-M02','mixed'),('P1FUN04-D02','diagnostic'),('P1FUN04-D03','diagnostic'),('P1FUN04-R03','retest'),('P1FUN04-R04','retest'),('P1FUN04-M02','mixed'),('P1FUN05-D02','diagnostic'),('P1FUN05-D03','diagnostic'),('P1FUN05-R03','retest'),('P1FUN05-R04','retest'),('P1FUN05-M02','mixed'),('P1COO04-D02','diagnostic'),('P1COO04-D03','diagnostic'),('P1COO04-R03','retest'),('P1COO04-R04','retest'),('P1COO04-M02','mixed'),('P1CIR02-D02','diagnostic'),('P1CIR02-D03','diagnostic'),('P1CIR02-R03','retest'),('P1CIR02-R04','retest'),('P1CIR02-M02','mixed')) r(content_key,reserve_role) using(content_key)
on conflict(id) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select status from private.exam_prep_content_versions where id=4811)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4811)<>40
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4811 and reserve_role='diagnostic')<>16
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4811 and reserve_role='retest')<>16
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4811 and reserve_role='mixed')<>8
  then raise exception 'aw09_12_annual_reserve_p1_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4811 and (
    m.lifecycle_state<>'draft' or m.exposure_state<>'withheld'
    or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or q.is_active or q.quality_status<>'draft'
  );
  if v_bad<>0 then raise exception 'aw09_12_annual_reserve_p1_draft exposure/QA boundary rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4811
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4811
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw09_12_annual_reserve_p1_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4811)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4811)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4811)
  then raise exception 'aw09_12_annual_reserve_p1_draft unexpected history'; end if;
end
$postcheck$;

commit;
