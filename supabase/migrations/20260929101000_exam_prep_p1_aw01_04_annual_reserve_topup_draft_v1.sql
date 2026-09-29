-- AW1-4 P1 annual-reserve top-up draft v1.
-- DRAFT ONLY: adds no learner-visible content and changes no existing evidence.
-- Exact delta per skill: +2 diagnostics, +2 delayed retests, +1 mixed/transfer item.
-- Written annual target is already met for these skills, so no written task is duplicated.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(
    select 1 from private.exam_prep_program_versions
    where program_key='math_as_p1_p5'
      and version_key='p1_p5_canonical_v1_0'
      and status='active'
  ) then
    raise exception 'aw01_04_annual_reserve_p1_draft canonical program missing';
  end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4803 and content_version<>'p1_aw01_04_annual_reserve_topup_draft_v1')
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59001 and 59025 and content_version_id<>4803)
  then
    raise exception 'aw01_04_annual_reserve_p1_draft reserved id collision';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta m
      join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published'
        and m.primary_skill_code in ('P1-QUA-01','P1-QUA-02','P1-QUA-03','P1-FUN-01','P1-FUN-02')
        and m.reserve_role='diagnostic' and m.lifecycle_state in ('published','reserve'))<>5
     or (select count(*) from private.exam_prep_question_content_meta m
      join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published'
        and m.primary_skill_code in ('P1-QUA-01','P1-QUA-02','P1-QUA-03','P1-FUN-01','P1-FUN-02')
        and m.reserve_role='retest' and m.lifecycle_state in ('published','reserve'))<>10
  then
    raise exception 'aw01_04_annual_reserve_p1_draft baseline reserve counts changed';
  end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
  id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select
  4803,pv.id,'p1_aw01_04_annual_reserve_topup_draft_v1','P1',
  'P1 AW1-4 annual reserve top-up draft v1','draft',
  'Original iClub-authored annual reserve expansion. Cambridge 9709 scope and Complete Pure Mathematics 1 chapter mapping define objectives only; no protected source question, solution, mark-scheme wording or diagram is copied. Draft requires independent academic, trilingual, technical, originality and reserve-isolation QA before any publication.',
  3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5'
  and pv.version_key='p1_p5_canonical_v1_0'
  and pv.status='active'
on conflict (program_version_id,content_version) do nothing;

with src(
  content_key,skill_code,topic,subtopic,difficulty,qtype,
  q_en,opts_en,answer,exp_en,
  q_ru,opts_ru,exp_ru,
  q_uz,opts_uz,exp_uz,time_limit
) as (values
('P1QUA01-D02','P1-QUA-01','P1 Annual reserve','P1-QUA-01','medium','mcq','Which is the correct completed-square form of 3x² − 18x + 31?','["3(x − 3)² + 4","3(x − 3)² + 31","3(x + 3)² + 4","3(x − 6)² − 77"]','A','3x²−18x+31 = 3(x²−6x)+31 = 3[(x−3)²−9]+31 = 3(x−3)²+4.','Какая форма полного квадрата верна для 3x² − 18x + 31?','["3(x − 3)² + 4","3(x − 3)² + 31","3(x + 3)² + 4","3(x − 6)² − 77"]','3x²−18x+31 = 3(x²−6x)+31 = 3[(x−3)²−9]+31 = 3(x−3)²+4.','3x² − 18x + 31 ifoda uchun qaysi to‘liq kvadrat ko‘rinishi to‘g‘ri?','["3(x − 3)² + 4","3(x − 3)² + 31","3(x + 3)² + 4","3(x − 6)² − 77"]','3x²−18x+31 = 3(x²−6x)+31 = 3[(x−3)²−9]+31 = 3(x−3)²+4.',75),
('P1QUA01-D03','P1-QUA-01','P1 Annual reserve','P1-QUA-01','medium','mcq','For y = −2x² − 8x + 1, which statement is correct?','["The vertex is (2, 9) and it is a maximum.","The vertex is (−2, −9) and it is a minimum.","The vertex is (−2, 9) and it is a maximum.","The vertex is (−4, 1) and it is a maximum."]','C','y = −2(x+2)²+9, so the vertex is (−2,9). The negative coefficient means the parabola opens downward, so 9 is the maximum.','Какое утверждение верно для y = −2x² − 8x + 1?','["Вершина (2, 9), и это максимум.","Вершина (−2, −9), и это минимум.","Вершина (−2, 9), и это максимум.","Вершина (−4, 1), и это максимум."]','y = −2(x+2)²+9, поэтому вершина равна (−2,9). Отрицательный коэффициент означает, что парабола направлена вниз, поэтому 9 — максимум.','y = −2x² − 8x + 1 uchun qaysi tasdiq to‘g‘ri?','["Cho‘qqi (2, 9), bu maksimum.","Cho‘qqi (−2, −9), bu minimum.","Cho‘qqi (−2, 9), bu maksimum.","Cho‘qqi (−4, 1), bu maksimum."]','y = −2(x+2)²+9, demak cho‘qqi (−2,9). Manfiy koeffitsiyent parabola pastga ochilishini bildiradi, shuning uchun 9 — maksimum.',75),
('P1QUA01-R03','P1-QUA-01','P1 Annual reserve','P1-QUA-01','medium','input','Enter the minimum value of 5x² − 20x + 23.','[]','3','5x²−20x+23 = 5(x−2)²+3. Since 5(x−2)²≥0, the minimum value is 3.','Введите минимальное значение выражения 5x² − 20x + 23.','[]','5x²−20x+23 = 5(x−2)²+3. Так как 5(x−2)²≥0, минимальное значение равно 3.','5x² − 20x + 23 ifodaning eng kichik qiymatini kiriting.','[]','5x²−20x+23 = 5(x−2)²+3. 5(x−2)²≥0 bo‘lgani uchun eng kichik qiymat 3.',75),
('P1QUA01-R04','P1-QUA-01','P1 Annual reserve','P1-QUA-01','medium','mcq','Write −x² + 10x − 18 in completed-square form.','["−(x+5)²+7","−(x−5)²−7","(x−5)²+7","−(x−5)²+7"]','D','−x²+10x−18 = −(x²−10x)−18 = −[(x−5)²−25]−18 = −(x−5)²+7.','Представьте −x² + 10x − 18 в форме полного квадрата.','["−(x+5)²+7","−(x−5)²−7","(x−5)²+7","−(x−5)²+7"]','−x²+10x−18 = −(x²−10x)−18 = −[(x−5)²−25]−18 = −(x−5)²+7.','−x² + 10x − 18 ifodani to‘liq kvadrat ko‘rinishida yozing.','["−(x+5)²+7","−(x−5)²−7","(x−5)²+7","−(x−5)²+7"]','−x²+10x−18 = −(x²−10x)−18 = −[(x−5)²−25]−18 = −(x−5)²+7.',75),
('P1QUA01-M02','P1-QUA-01','P1 Annual reserve','P1-QUA-01','hard','mcq','A model gives the height h(t)=−2t²+16t+3. Which pair gives the time of maximum height and the maximum height?','["(2, 27)","(4, 35)","(4, 19)","(8, 3)"]','B','h(t)=−2(t−4)²+35. Hence the maximum occurs at t=4 and equals 35.','Высота задаётся моделью h(t)=−2t²+16t+3. Какая пара показывает время достижения максимальной высоты и саму максимальную высоту?','["(2, 27)","(4, 35)","(4, 19)","(8, 3)"]','h(t)=−2(t−4)²+35. Следовательно, максимум достигается при t=4 и равен 35.','Balandlik h(t)=−2t²+16t+3 model bilan berilgan. Qaysi juftlik maksimal balandlikka erishish vaqtini va maksimal balandlikni ko‘rsatadi?','["(2, 27)","(4, 35)","(4, 19)","(8, 3)"]','h(t)=−2(t−4)²+35. Demak maksimum t=4 da bo‘ladi va 35 ga teng.',95),
('P1QUA02-D02','P1-QUA-02','P1 Annual reserve','P1-QUA-02','medium','mcq','How many real roots does x² + 6x + 10 = 0 have?','["Two distinct real roots","No real roots","One repeated real root","The number of roots cannot be determined"]','B','The discriminant is 6²−4·1·10=−4<0, so there are no real roots.','Сколько действительных корней имеет уравнение x² + 6x + 10 = 0?','["Два различных действительных корня","Действительных корней нет","Один повторяющийся действительный корень","Число корней определить нельзя"]','Дискриминант равен 6²−4·1·10=−4<0, поэтому действительных корней нет.','x² + 6x + 10 = 0 tenglama nechta haqiqiy ildizga ega?','["Ikkita turli haqiqiy ildiz","Haqiqiy ildizlar yo‘q","Bitta takroriy haqiqiy ildiz","Ildizlar sonini aniqlab bo‘lmaydi"]','Diskriminant 6²−4·1·10=−4<0, shuning uchun haqiqiy ildizlar yo‘q.',65),
('P1QUA02-D03','P1-QUA-02','P1 Annual reserve','P1-QUA-02','hard','mcq','For which value of p does x² + (p + 1)x + p = 0 have equal real roots?','["p = −1","p = 0","p = 2","p = 1"]','D','Equal roots require Δ=0. Here Δ=(p+1)²−4p=(p−1)², so p=1.','При каком значении p уравнение x² + (p + 1)x + p = 0 имеет равные действительные корни?','["p = −1","p = 0","p = 2","p = 1"]','Для равных корней нужно Δ=0. Здесь Δ=(p+1)²−4p=(p−1)², поэтому p=1.','Qaysi p qiymatida x² + (p + 1)x + p = 0 tenglama teng haqiqiy ildizlarga ega?','["p = −1","p = 0","p = 2","p = 1"]','Teng ildizlar uchun Δ=0 bo‘lishi kerak. Bu yerda Δ=(p+1)²−4p=(p−1)², demak p=1.',85),
('P1QUA02-R03','P1-QUA-02','P1 Annual reserve','P1-QUA-02','hard','mcq','For which values of q does 2x² + qx + 5 = 0 have two distinct real roots?','["q < −2√10 or q > 2√10","−2√10 < q < 2√10","q ≤ −2√10 or q ≥ 2√10","q = ±2√10"]','A','Two distinct real roots require q²−40>0, so |q|>2√10.','При каких значениях q уравнение 2x² + qx + 5 = 0 имеет два различных действительных корня?','["q < −2√10 or q > 2√10","−2√10 < q < 2√10","q ≤ −2√10 or q ≥ 2√10","q = ±2√10"]','Для двух различных действительных корней нужно q²−40>0, поэтому |q|>2√10.','Qaysi q qiymatlarida 2x² + qx + 5 = 0 tenglama ikkita turli haqiqiy ildizga ega?','["q < −2√10 or q > 2√10","−2√10 < q < 2√10","q ≤ −2√10 or q ≥ 2√10","q = ±2√10"]','Ikkita turli haqiqiy ildiz uchun q²−40>0, demak |q|>2√10.',90),
('P1QUA02-R04','P1-QUA-02','P1 Annual reserve','P1-QUA-02','hard','mcq','For which values of m does x² − 4mx + 4 = 0 have equal real roots?','["m = 1 only","m = −1 only","m = −1 or 1","m = −2 or 2"]','C','Δ=(−4m)²−16=16(m²−1). Equal roots require Δ=0, so m=±1.','При каких значениях m уравнение x² − 4mx + 4 = 0 имеет равные действительные корни?','["m = 1 only","m = −1 only","m = −1 or 1","m = −2 or 2"]','Δ=(−4m)²−16=16(m²−1). Для равных корней Δ=0, поэтому m=±1.','Qaysi m qiymatlarida x² − 4mx + 4 = 0 tenglama teng haqiqiy ildizlarga ega?','["m = 1 only","m = −1 only","m = −1 or 1","m = −2 or 2"]','Δ=(−4m)²−16=16(m²−1). Teng ildizlar uchun Δ=0, shuning uchun m=±1.',85),
('P1QUA02-M02','P1-QUA-02','P1 Annual reserve','P1-QUA-02','hard','mcq','The line y=3x+k is tangent to the parabola y=x²+x+4. Find k.','["1","3","4","7"]','B','At an intersection, x²+x+4=3x+k, so x²−2x+(4−k)=0. Tangency requires Δ=0: 4−4(4−k)=0, giving k=3.','Прямая y=3x+k касается параболы y=x²+x+4. Найдите k.','["1","3","4","7"]','В точке пересечения x²+x+4=3x+k, поэтому x²−2x+(4−k)=0. Для касания Δ=0: 4−4(4−k)=0, откуда k=3.','y=3x+k to‘g‘ri chiziq y=x²+x+4 parabolaga urinadi. k ni toping.','["1","3","4","7"]','Kesishishda x²+x+4=3x+k, ya’ni x²−2x+(4−k)=0. Urinish uchun Δ=0: 4−4(4−k)=0, bundan k=3.',100),
('P1QUA03-D02','P1-QUA-03','P1 Annual reserve','P1-QUA-03','medium','mcq','Solve x² + 2x − 7 = 0.','["x = 1 ± 2√2","x = −1 ± √2","x = −1 ± 2√2","x = 1 ± √8"]','C','x=[−2±√(4+28)]/2=[−2±4√2]/2=−1±2√2.','Решите уравнение x² + 2x − 7 = 0.','["x = 1 ± 2√2","x = −1 ± √2","x = −1 ± 2√2","x = 1 ± √8"]','x=[−2±√(4+28)]/2=[−2±4√2]/2=−1±2√2.','x² + 2x − 7 = 0 tenglamani yeching.','["x = 1 ± 2√2","x = −1 ± √2","x = −1 ± 2√2","x = 1 ± √8"]','x=[−2±√(4+28)]/2=[−2±4√2]/2=−1±2√2.',80),
('P1QUA03-D03','P1-QUA-03','P1 Annual reserve','P1-QUA-03','medium','mcq','Solve x² + 10x + 17 = 0 exactly.','["x = 5 ± 2√2","x = −5 ± √2","x = 5 ± √8","x = −5 ± 2√2"]','D','(x+5)²=8, so x=−5±√8=−5±2√2.','Решите уравнение x² + 10x + 17 = 0 точно.','["x = 5 ± 2√2","x = −5 ± √2","x = 5 ± √8","x = −5 ± 2√2"]','(x+5)²=8, поэтому x=−5±√8=−5±2√2.','x² + 10x + 17 = 0 tenglamani aniq yeching.','["x = 5 ± 2√2","x = −5 ± √2","x = 5 ± √8","x = −5 ± 2√2"]','(x+5)²=8, demak x=−5±√8=−5±2√2.',80),
('P1QUA03-R03','P1-QUA-03','P1 Annual reserve','P1-QUA-03','medium','mcq','Solve 3x² − 5x − 2 = 0.','["x = −2 or 1/3","x = 2 or −1/3","x = 2 or 1/3","x = −2 or −1/3"]','B','3x²−5x−2=(3x+1)(x−2), so x=2 or x=−1/3.','Решите уравнение 3x² − 5x − 2 = 0.','["x = −2 or 1/3","x = 2 or −1/3","x = 2 or 1/3","x = −2 or −1/3"]','3x²−5x−2=(3x+1)(x−2), поэтому x=2 или x=−1/3.','3x² − 5x − 2 = 0 tenglamani yeching.','["x = −2 or 1/3","x = 2 or −1/3","x = 2 or 1/3","x = −2 or −1/3"]','3x²−5x−2=(3x+1)(x−2), shuning uchun x=2 yoki x=−1/3.',75),
('P1QUA03-R04','P1-QUA-03','P1 Annual reserve','P1-QUA-03','hard','mcq','Solve 2x² + 3x − 4 = 0 exactly.','["x = (−3 ± √41)/4","x = (3 ± √41)/4","x = (−3 ± √17)/4","x = (−3 ± √41)/2"]','A','Using the quadratic formula gives x=[−3±√(9+32)]/4=(−3±√41)/4.','Решите уравнение 2x² + 3x − 4 = 0 точно.','["x = (−3 ± √41)/4","x = (3 ± √41)/4","x = (−3 ± √17)/4","x = (−3 ± √41)/2"]','По формуле корней x=[−3±√(9+32)]/4=(−3±√41)/4.','2x² + 3x − 4 = 0 tenglamani aniq yeching.','["x = (−3 ± √41)/4","x = (3 ± √41)/4","x = (−3 ± √17)/4","x = (−3 ± √41)/2"]','Kvadrat tenglama formulasi bo‘yicha x=[−3±√(9+32)]/4=(−3±√41)/4.',85),
('P1QUA03-M02','P1-QUA-03','P1 Annual reserve','P1-QUA-03','hard','mcq','A rectangle has width x cm and length (x+3) cm. Its area is 54 cm². What is its width?','["3 cm","9 cm","−9 cm","6 cm"]','D','x(x+3)=54 gives x²+3x−54=0=(x+9)(x−6). A length must be positive, so x=6 cm.','Ширина прямоугольника равна x см, а длина — (x+3) см. Его площадь равна 54 см². Чему равна ширина?','["3 cm","9 cm","−9 cm","6 cm"]','x(x+3)=54 даёт x²+3x−54=0=(x+9)(x−6). Длина должна быть положительной, поэтому x=6 см.','To‘g‘ri to‘rtburchakning eni x sm, bo‘yi esa (x+3) sm. Uning yuzi 54 sm². Eni qancha?','["3 cm","9 cm","−9 cm","6 cm"]','x(x+3)=54 dan x²+3x−54=0=(x+9)(x−6). Uzunlik musbat bo‘lishi kerak, demak x=6 sm.',100),
('P1FUN01-D02','P1-FUN-01','P1 Annual reserve','P1-FUN-01','medium','mcq','If f(x)=2x+1 and g(x)=x², what is (f ∘ g)(x)?','["2x²+1","(2x+1)²","x²+2x+1","2x+3"]','A','(f∘g)(x)=f(g(x))=f(x²)=2x²+1.','Если f(x)=2x+1 и g(x)=x², чему равно (f ∘ g)(x)?','["2x²+1","(2x+1)²","x²+2x+1","2x+3"]','(f∘g)(x)=f(g(x))=f(x²)=2x²+1.','Agar f(x)=2x+1 va g(x)=x² bo‘lsa, (f ∘ g)(x) nimaga teng?','["2x²+1","(2x+1)²","x²+2x+1","2x+3"]','(f∘g)(x)=f(g(x))=f(x²)=2x²+1.',65),
('P1FUN01-D03','P1-FUN-01','P1 Annual reserve','P1-FUN-01','medium','mcq','Which statement about f(x)=x² with domain all real numbers is correct?','["It is one-one because every x gives one y.","Its inverse is f⁻¹(x)=√x on all real x.","It has no inverse function on this domain because it is not one-one.","Its range is all real numbers."]','C','Both x and −x give the same output, so f is not one-one on all real numbers and therefore has no inverse function on that full domain.','Какое утверждение верно для f(x)=x² с областью определения всех действительных чисел?','["Она взаимно однозначна, потому что каждому x соответствует одно y.","Её обратная функция f⁻¹(x)=√x определена для всех действительных x.","На этой области у неё нет обратной функции, потому что она не взаимно однозначна.","Её область значений — все действительные числа."]','x и −x дают одно и то же значение, поэтому f не является взаимно однозначной на всех действительных числах и не имеет обратной функции на этой области.','Aniqlanish sohasi barcha haqiqiy sonlar bo‘lgan f(x)=x² uchun qaysi tasdiq to‘g‘ri?','["U bir-biriga bir qiymatli, chunki har bir x ga bitta y mos keladi.","Uning teskari funksiyasi f⁻¹(x)=√x barcha haqiqiy x lar uchun aniqlangan.","Bu sohada u bir-biriga bir qiymatli emas, shuning uchun teskari funksiyaga ega emas.","Uning qiymatlar sohasi barcha haqiqiy sonlar."]','x va −x bir xil qiymat beradi, shuning uchun f barcha haqiqiy sonlarda bir-biriga bir qiymatli emas va bu to‘liq sohada teskari funksiyaga ega emas.',65),
('P1FUN01-R03','P1-FUN-01','P1 Annual reserve','P1-FUN-01','medium','mcq','If f(x)=5−2x for real x, what is f⁻¹(x)?','["(x−5)/2","2x−5","5−2x","(5−x)/2"]','D','Let y=5−2x. Rearranging gives x=(5−y)/2, so f⁻¹(x)=(5−x)/2.','Если f(x)=5−2x для всех действительных x, чему равна f⁻¹(x)?','["(x−5)/2","2x−5","5−2x","(5−x)/2"]','Пусть y=5−2x. Тогда x=(5−y)/2, поэтому f⁻¹(x)=(5−x)/2.','Agar f(x)=5−2x barcha haqiqiy x lar uchun berilgan bo‘lsa, f⁻¹(x) nimaga teng?','["(x−5)/2","2x−5","5−2x","(5−x)/2"]','y=5−2x deb olsak, x=(5−y)/2. Demak f⁻¹(x)=(5−x)/2.',70),
('P1FUN01-R04','P1-FUN-01','P1 Annual reserve','P1-FUN-01','medium','input','Let f(x)=x+4 and g(x)=3x. Enter the value of (g ∘ f)(2).','[]','18','f(2)=6 and then g(6)=18, so (g∘f)(2)=18.','Пусть f(x)=x+4 и g(x)=3x. Введите значение (g ∘ f)(2).','[]','f(2)=6, затем g(6)=18, поэтому (g∘f)(2)=18.','f(x)=x+4 va g(x)=3x bo‘lsin. (g ∘ f)(2) qiymatini kiriting.','[]','f(2)=6, so‘ng g(6)=18, demak (g∘f)(2)=18.',60),
('P1FUN01-M02','P1-FUN-01','P1 Annual reserve','P1-FUN-01','hard','mcq','Let f(x)=1/x and g(x)=x−2. What is the domain of (f ∘ g)(x)?','["x>2","All real x except x=2","x≠0","x≥2"]','B','(f∘g)(x)=1/(x−2). The denominator cannot be zero, so x≠2.','Пусть f(x)=1/x и g(x)=x−2. Какова область определения (f ∘ g)(x)?','["x>2","Все действительные x, кроме x=2","x≠0","x≥2"]','(f∘g)(x)=1/(x−2). Знаменатель не может быть равен нулю, поэтому x≠2.','f(x)=1/x va g(x)=x−2 bo‘lsin. (f ∘ g)(x) ning aniqlanish sohasi qanday?','["x>2","x=2 dan tashqari barcha haqiqiy x lar","x≠0","x≥2"]','(f∘g)(x)=1/(x−2). Maxraj nol bo‘la olmaydi, shuning uchun x≠2.',80),
('P1FUN02-D02','P1-FUN-02','P1 Annual reserve','P1-FUN-02','medium','mcq','For f(x)=(x−4)²+2 with 4≤x≤7, what is the range?','["2≤f(x)≤9","0≤f(x)≤11","2≤f(x)≤11","4≤f(x)≤7"]','C','The minimum is 2 at x=4. The maximum on the restricted interval is f(7)=11, so the range is [2,11].','Для f(x)=(x−4)²+2 при 4≤x≤7 каков диапазон значений?','["2≤f(x)≤9","0≤f(x)≤11","2≤f(x)≤11","4≤f(x)≤7"]','Минимум равен 2 при x=4. Максимум на заданном промежутке f(7)=11, поэтому диапазон [2,11].','f(x)=(x−4)²+2 va 4≤x≤7 bo‘lsa, funksiyaning qiymatlar sohasi qaysi?','["2≤f(x)≤9","0≤f(x)≤11","2≤f(x)≤11","4≤f(x)≤7"]','Minimum x=4 da 2. Berilgan oraliqda maksimum f(7)=11, demak qiymatlar sohasi [2,11].',75),
('P1FUN02-D03','P1-FUN-02','P1 Annual reserve','P1-FUN-02','hard','mcq','For f(x)=3−2x with −1<x≤4, what is the range?','["−5≤f(x)<5","−5<f(x)≤5","−5≤f(x)≤5","−1<f(x)≤4"]','A','The function is decreasing. f(4)=−5 is included. As x approaches −1 from above, f(x) approaches 5 but never reaches it, so −5≤f(x)<5.','Для f(x)=3−2x при −1<x≤4 каков диапазон значений?','["−5≤f(x)<5","−5<f(x)≤5","−5≤f(x)≤5","−1<f(x)≤4"]','Функция убывает. Значение f(4)=−5 включено. При x→−1 справа f(x) стремится к 5, но не достигает его, поэтому −5≤f(x)<5.','f(x)=3−2x va −1<x≤4 bo‘lsa, funksiyaning qiymatlar sohasi qaysi?','["−5≤f(x)<5","−5<f(x)≤5","−5≤f(x)≤5","−1<f(x)≤4"]','Funksiya kamayuvchi. f(4)=−5 qiymati kiradi. x −1 ga o‘ngdan yaqinlashganda f(x) 5 ga yaqinlashadi, lekin 5 ga teng bo‘lmaydi, demak −5≤f(x)<5.',80),
('P1FUN02-R03','P1-FUN-02','P1 Annual reserve','P1-FUN-02','medium','mcq','For f(x)=−(x+1)²+6 with −3≤x≤2, what is the range?','["−3≤f(x)≤2","2≤f(x)≤6","−6≤f(x)≤3","−3≤f(x)≤6"]','D','The maximum is 6 at x=−1. The endpoint values are f(−3)=2 and f(2)=−3, so the minimum is −3.','Для f(x)=−(x+1)²+6 при −3≤x≤2 каков диапазон значений?','["−3≤f(x)≤2","2≤f(x)≤6","−6≤f(x)≤3","−3≤f(x)≤6"]','Максимум равен 6 при x=−1. На концах f(−3)=2 и f(2)=−3, поэтому минимум равен −3.','f(x)=−(x+1)²+6 va −3≤x≤2 bo‘lsa, funksiyaning qiymatlar sohasi qaysi?','["−3≤f(x)≤2","2≤f(x)≤6","−6≤f(x)≤3","−3≤f(x)≤6"]','Maksimum x=−1 da 6. Chekka qiymatlar f(−3)=2 va f(2)=−3, shuning uchun minimum −3.',75),
('P1FUN02-R04','P1-FUN-02','P1 Annual reserve','P1-FUN-02','medium','input','For f(x)=2(x−3)²−5 with 1≤x≤5, enter the maximum value of f.','[]','3','The vertex gives the minimum −5 at x=3. Both endpoints give 2·4−5=3, so the maximum is 3.','Для f(x)=2(x−3)²−5 при 1≤x≤5 введите максимальное значение f.','[]','Вершина даёт минимум −5 при x=3. На обоих концах получаем 2·4−5=3, поэтому максимум равен 3.','f(x)=2(x−3)²−5 va 1≤x≤5 bo‘lsa, f ning eng katta qiymatini kiriting.','[]','Cho‘qqi x=3 da minimum −5 ni beradi. Ikkala chekka nuqtada ham 2·4−5=3, demak maksimum 3.',70),
('P1FUN02-M02','P1-FUN-02','P1 Annual reserve','P1-FUN-02','hard','mcq','A temperature model is T(t)=−(t−4)²+20 for 1≤t≤6. What is the range of T on this interval?','["16≤T≤20","11≤T≤20","11≤T≤16","−5≤T≤20"]','B','The maximum is 20 at t=4. At the endpoints T(1)=11 and T(6)=16, so the minimum is 11 and the range is [11,20].','Температура задаётся моделью T(t)=−(t−4)²+20 при 1≤t≤6. Каков диапазон значений T на этом промежутке?','["16≤T≤20","11≤T≤20","11≤T≤16","−5≤T≤20"]','Максимум равен 20 при t=4. На концах T(1)=11 и T(6)=16, поэтому минимум равен 11, а диапазон [11,20].','Harorat T(t)=−(t−4)²+20 model bilan berilgan, 1≤t≤6. Shu oraliqda T ning qiymatlar sohasi qaysi?','["16≤T≤20","11≤T≤20","11≤T≤16","−5≤T≤20"]','Maksimum t=4 da 20. Chekka nuqtalarda T(1)=11 va T(6)=16, shuning uchun minimum 11, qiymatlar sohasi [11,20].',90)
)
insert into public.questions(
  subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
  question_text_ru,question_text_uz,question_text_en,
  options_text_ru,options_text_uz,options_text_en,
  explanation_ru,explanation_uz,explanation_en,
  book_ref,time_limit_sec,quality_flag,quality_status
)
select
  5,s.topic,s.subtopic,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
  s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
  'ExamPrep:P1:p1_aw01_04_annual_reserve_topup_draft_v1:'||s.content_key,
  s.time_limit,null,'draft'
from src s
where not exists(
  select 1 from public.questions q
  where q.book_ref='ExamPrep:P1:p1_aw01_04_annual_reserve_topup_draft_v1:'||s.content_key
);

with keys(content_key,skill_code,reserve_role,meta_id) as (values
('P1QUA01-D02','P1-QUA-01','diagnostic',59001),
('P1QUA01-D03','P1-QUA-01','diagnostic',59002),
('P1QUA01-R03','P1-QUA-01','retest',59003),
('P1QUA01-R04','P1-QUA-01','retest',59004),
('P1QUA01-M02','P1-QUA-01','mixed',59005),
('P1QUA02-D02','P1-QUA-02','diagnostic',59006),
('P1QUA02-D03','P1-QUA-02','diagnostic',59007),
('P1QUA02-R03','P1-QUA-02','retest',59008),
('P1QUA02-R04','P1-QUA-02','retest',59009),
('P1QUA02-M02','P1-QUA-02','mixed',59010),
('P1QUA03-D02','P1-QUA-03','diagnostic',59011),
('P1QUA03-D03','P1-QUA-03','diagnostic',59012),
('P1QUA03-R03','P1-QUA-03','retest',59013),
('P1QUA03-R04','P1-QUA-03','retest',59014),
('P1QUA03-M02','P1-QUA-03','mixed',59015),
('P1FUN01-D02','P1-FUN-01','diagnostic',59016),
('P1FUN01-D03','P1-FUN-01','diagnostic',59017),
('P1FUN01-R03','P1-FUN-01','retest',59018),
('P1FUN01-R04','P1-FUN-01','retest',59019),
('P1FUN01-M02','P1-FUN-01','mixed',59020),
('P1FUN02-D02','P1-FUN-02','diagnostic',59021),
('P1FUN02-D03','P1-FUN-02','diagnostic',59022),
('P1FUN02-R03','P1-FUN-02','retest',59023),
('P1FUN02-R04','P1-FUN-02','retest',59024),
('P1FUN02-M02','P1-FUN-02','mixed',59025)
)
insert into private.exam_prep_question_content_meta(
  id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,
  reserve_role,exposure_state,lifecycle_state,
  originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
  copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,
  diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select
  k.meta_id,4803,k.content_key,q.id,k.skill_code,'{}'::text[],
  k.reserve_role,'withheld','draft',
  'Original iClub-authored stem, data, distractors, answer and explanation; no Cambridge/coursebook question, diagram, solution or mark-scheme wording copied.',
  'Authored as AW1-4 annual-reserve top-up. Purpose is future diagnostic/retest/transfer depth, not reinterpretation of existing learner evidence.',
  case when k.skill_code like 'P1-QUA-%'
       then 'Cambridge 9709 2026-2027 v4; P1 1.1 Quadratics'
       else 'Cambridge 9709 2026-2027 v4; P1 1.2 Functions' end,
  case when k.skill_code like 'P1-QUA-%'
       then 'Complete Pure Mathematics 1, Ch1 Quadratics pp.2-20 (mapping only)'
       else 'Complete Pure Mathematics 1, Ch2 Functions and transformations pp.24-42 (mapping only)' end,
  'pending','pending','pending','pending','pending',
  case when k.reserve_role='diagnostic' then 'pending' else 'not_applicable' end,
  md5(concat_ws(chr(31),
    q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
    coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
    coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
    coalesce(q.image_url,''),coalesce(q.is_active::text,''),
    coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
    coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
    coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
    coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
    coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from keys k
join public.questions q
  on q.book_ref='ExamPrep:P1:p1_aw01_04_annual_reserve_topup_draft_v1:'||k.content_key
on conflict(content_version_id,content_key) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select status from private.exam_prep_content_versions where id=4803)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4803)<>25
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4803 and reserve_role='diagnostic')<>10
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4803 and reserve_role='retest')<>10
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4803 and reserve_role='mixed')<>5
  then
    raise exception 'aw01_04_annual_reserve_p1_draft cardinality/state postcheck failed';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id=4803
    and (
      m.lifecycle_state<>'draft' or m.exposure_state<>'withheld'
      or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending' or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or q.is_active<>false or q.quality_status<>'draft'
      or nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
    );
  if v_bad<>0 then
    raise exception 'aw01_04_annual_reserve_p1_draft governance/exposure failure rows=%',v_bad;
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id=4803
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id=4803
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id=4803
  ) then
    raise exception 'aw01_04_annual_reserve_p1_draft unexpected learner/legacy history';
  end if;
end
$postcheck$;

commit;
