-- AW1-4 alternate learning pack drafts for P1.
-- DRAFT ONLY: no learner exposure, no QA self-approval, no publication.
-- Source authority: canonical P1 skill map + Complete Pure Mathematics 1 mapping.
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
    raise exception 'aw01_04_alt_p1_draft canonical program missing';
  end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4801 and content_version<>'p1_aw01_04_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15601 and 15605 and content_version_id<>4801)
     or exists(select 1 from private.exam_prep_assessments where id between 35201 and 35205 and content_version_id<>4801)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 58901 and 58915 and content_version_id<>4801)
  then
    raise exception 'aw01_04_alt_p1_draft reserved id collision';
  end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
  id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select
  4801,pv.id,'p1_aw01_04_alt_learning_draft_v1','P1',
  'P1 AW1-4 alternate learning pack draft v1','draft',
  'Original iClub-authored alternate learning content. Canonical Cambridge 9709 skill scope and Complete Pure Mathematics 1 chapter mapping are used only to define learning objectives; no protected source question, solution or mark-scheme wording is copied. Draft requires independent academic, language, technical and copyright QA before approval/publication.',
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
('P1QUA01-A01','P1-QUA-01','P1 Quadratics','P1-QUA-01','medium','mcq',
 'Write 2x² + 12x + 11 in completed-square form.',
 '["2(x + 3)² − 7","2(x + 3)² + 11","2(x − 3)² − 7","2(x + 6)² − 61"]','A',
 'Factor out 2 from the quadratic terms: 2(x²+6x)+11 = 2[(x+3)²−9]+11 = 2(x+3)²−7.',
 'Представьте 2x² + 12x + 11 в форме полного квадрата.',
 '["2(x + 3)² − 7","2(x + 3)² + 11","2(x − 3)² − 7","2(x + 6)² − 61"]',
 'Вынесите 2 у квадратного и линейного членов: 2(x²+6x)+11 = 2[(x+3)²−9]+11 = 2(x+3)²−7.',
 '2x² + 12x + 11 ifodani to‘liq kvadrat ko‘rinishiga keltiring.',
 '["2(x + 3)² − 7","2(x + 3)² + 11","2(x − 3)² − 7","2(x + 6)² − 61"]',
 'Kvadrat va chiziqli hadlardan 2 ni ajrating: 2(x²+6x)+11 = 2[(x+3)²−9]+11 = 2(x+3)²−7.',70),

('P1QUA01-A02','P1-QUA-01','P1 Quadratics','P1-QUA-01','medium','mcq',
 'What is the vertex of y = −3x² + 12x − 1?',
 '["(2, 11)","(−2, 11)","(2, −11)","(4, −1)"]','A',
 'y = −3(x²−4x)−1 = −3[(x−2)²−4]−1 = −3(x−2)²+11, so the vertex is (2,11).',
 'Какова вершина параболы y = −3x² + 12x − 1?',
 '["(2, 11)","(−2, 11)","(2, −11)","(4, −1)"]',
 'y = −3(x²−4x)−1 = −3[(x−2)²−4]−1 = −3(x−2)²+11, поэтому вершина — (2,11).',
 'y = −3x² + 12x − 1 parabolaning cho‘qqisi qaysi?',
 '["(2, 11)","(−2, 11)","(2, −11)","(4, −1)"]',
 'y = −3(x²−4x)−1 = −3[(x−2)²−4]−1 = −3(x−2)²+11, demak cho‘qqi (2,11).',70),

('P1QUA01-A03','P1-QUA-01','P1 Quadratics','P1-QUA-01','medium','input',
 'Enter the minimum value of 4x² + 8x + 9.',
 '[]','5',
 '4x²+8x+9 = 4(x+1)²+5. Since 4(x+1)² ≥ 0, the minimum value is 5.',
 'Введите минимальное значение выражения 4x² + 8x + 9.',
 '[]',
 '4x²+8x+9 = 4(x+1)²+5. Так как 4(x+1)² ≥ 0, минимальное значение равно 5.',
 '4x² + 8x + 9 ifodaning eng kichik qiymatini kiriting.',
 '[]',
 '4x²+8x+9 = 4(x+1)²+5. 4(x+1)² ≥ 0 bo‘lgani uchun eng kichik qiymat 5.',60),

('P1QUA02-A01','P1-QUA-02','P1 Quadratics','P1-QUA-02','medium','mcq',
 'How many real roots does 3x² + 4x + 5 = 0 have?',
 '["0","1","2","3"]','A',
 'The discriminant is 4²−4·3·5 = 16−60 = −44 < 0, so there are no real roots.',
 'Сколько действительных корней имеет уравнение 3x² + 4x + 5 = 0?',
 '["0","1","2","3"]',
 'Дискриминант равен 4²−4·3·5 = 16−60 = −44 < 0, поэтому действительных корней нет.',
 '3x² + 4x + 5 = 0 tenglama nechta haqiqiy ildizga ega?',
 '["0","1","2","3"]',
 'Diskriminant 4²−4·3·5 = 16−60 = −44 < 0, shuning uchun haqiqiy ildizlar yo‘q.',60),

('P1QUA02-A02','P1-QUA-02','P1 Quadratics','P1-QUA-02','hard','mcq',
 'For which values of k does x² + (k − 2)x + 4 = 0 have two distinct real roots?',
 '["−2 < k < 6","k ≤ −2 or k ≥ 6","k < −2 or k > 6","k > 6 only"]','C',
 'Two distinct real roots require (k−2)²−16 > 0. Hence |k−2|>4, so k<−2 or k>6.',
 'При каких значениях k уравнение x² + (k − 2)x + 4 = 0 имеет два различных действительных корня?',
 '["−2 < k < 6","k ≤ −2 или k ≥ 6","k < −2 или k > 6","только k > 6"]',
 'Для двух различных действительных корней нужно (k−2)²−16 > 0. Поэтому |k−2|>4, то есть k<−2 или k>6.',
 'Qaysi k qiymatlarida x² + (k − 2)x + 4 = 0 tenglama ikkita turli haqiqiy ildizga ega?',
 '["−2 < k < 6","k ≤ −2 yoki k ≥ 6","k < −2 yoki k > 6","faqat k > 6"]',
 'Ikkita turli haqiqiy ildiz uchun (k−2)²−16 > 0 bo‘lishi kerak. Demak |k−2|>4, ya’ni k<−2 yoki k>6.',80),

('P1QUA02-A03','P1-QUA-02','P1 Quadratics','P1-QUA-02','hard','mcq',
 'For which values of m does 4x² − 4mx + 9 = 0 have equal roots?',
 '["m = −3 only","m = 3 only","m = −3 or 3","m = −3/2 or 3/2"]','C',
 'Equal roots require Δ=0: (−4m)²−4·4·9=16m²−144=0, so m²=9 and m=±3.',
 'При каких значениях m уравнение 4x² − 4mx + 9 = 0 имеет равные корни?',
 '["только m = −3","только m = 3","m = −3 или 3","m = −3/2 или 3/2"]',
 'Для равных корней Δ=0: (−4m)²−4·4·9=16m²−144=0, поэтому m²=9 и m=±3.',
 'Qaysi m qiymatlarida 4x² − 4mx + 9 = 0 tenglama teng ildizlarga ega?',
 '["faqat m = −3","faqat m = 3","m = −3 yoki 3","m = −3/2 yoki 3/2"]',
 'Teng ildizlar uchun Δ=0: (−4m)²−4·4·9=16m²−144=0. Shuning uchun m²=9 va m=±3.',80),

('P1QUA03-A01','P1-QUA-03','P1 Quadratics','P1-QUA-03','medium','mcq',
 'Solve 2x² − 7x + 3 = 0.',
 '["x = 3 or 1/2","x = −3 or −1/2","x = 1 or 3/2","x = 7/2 or 3"]','A',
 '2x²−7x+3=(2x−1)(x−3), so x=1/2 or x=3.',
 'Решите уравнение 2x² − 7x + 3 = 0.',
 '["x = 3 или 1/2","x = −3 или −1/2","x = 1 или 3/2","x = 7/2 или 3"]',
 '2x²−7x+3=(2x−1)(x−3), поэтому x=1/2 или x=3.',
 '2x² − 7x + 3 = 0 tenglamani yeching.',
 '["x = 3 yoki 1/2","x = −3 yoki −1/2","x = 1 yoki 3/2","x = 7/2 yoki 3"]',
 '2x²−7x+3=(2x−1)(x−3), shuning uchun x=1/2 yoki x=3.',70),

('P1QUA03-A02','P1-QUA-03','P1 Quadratics','P1-QUA-03','medium','mcq',
 'Solve x² − 4x − 1 = 0.',
 '["x = 2 ± √5","x = −2 ± √5","x = 4 ± √17","x = 2 ± 5"]','A',
 'Using the quadratic formula, x=(4±√(16+4))/2=(4±2√5)/2=2±√5.',
 'Решите уравнение x² − 4x − 1 = 0.',
 '["x = 2 ± √5","x = −2 ± √5","x = 4 ± √17","x = 2 ± 5"]',
 'По формуле корней x=(4±√(16+4))/2=(4±2√5)/2=2±√5.',
 'x² − 4x − 1 = 0 tenglamani yeching.',
 '["x = 2 ± √5","x = −2 ± √5","x = 4 ± √17","x = 2 ± 5"]',
 'Kvadrat tenglama formulasi bo‘yicha x=(4±√(16+4))/2=(4±2√5)/2=2±√5.',70),

('P1QUA03-A03','P1-QUA-03','P1 Quadratics','P1-QUA-03','medium','mcq',
 'Which method is the most direct for solving x² − 13x + 40 = 0 exactly?',
 '["Factorisation","Numerical iteration","Differentiation","Graph transformation only"]','A',
 'The integers 5 and 8 multiply to 40 and add to 13, so the quadratic factorises immediately as (x−5)(x−8)=0.',
 'Какой метод наиболее прямой для точного решения x² − 13x + 40 = 0?',
 '["Разложение на множители","Численная итерация","Дифференцирование","Только преобразование графика"]',
 'Числа 5 и 8 дают произведение 40 и сумму 13, поэтому квадратный трёхчлен сразу раскладывается: (x−5)(x−8)=0.',
 'x² − 13x + 40 = 0 tenglamani aniq yechish uchun qaysi usul eng to‘g‘ri?',
 '["Ko‘paytuvchilarga ajratish","Sonli iteratsiya","Differensiallash","Faqat grafikni o‘zgartirish"]',
 '5 va 8 sonlarining ko‘paytmasi 40, yig‘indisi 13. Shuning uchun tenglama darhol (x−5)(x−8)=0 ko‘rinishida ajraladi.',60),

('P1FUN01-A01','P1-FUN-01','P1 Functions','P1-FUN-01','medium','mcq',
 'For h(x)=x² with domain x ≥ 0, what is h⁻¹(x)?',
 '["√x for x ≥ 0","−√x for x ≥ 0","x² for x ≥ 0","1/x² for x > 0"]','A',
 'On x≥0 the function h is one-one. Interchanging x and y in y=x² and taking the nonnegative branch gives h⁻¹(x)=√x.',
 'Для h(x)=x² с областью определения x ≥ 0 чему равна h⁻¹(x)?',
 '["√x при x ≥ 0","−√x при x ≥ 0","x² при x ≥ 0","1/x² при x > 0"]',
 'На x≥0 функция h взаимно однозначна. Меняя x и y в y=x² и выбирая неотрицательную ветвь, получаем h⁻¹(x)=√x.',
 'h(x)=x² funksiyaning aniqlanish sohasi x ≥ 0 bo‘lsa, h⁻¹(x) nimaga teng?',
 '["√x, x ≥ 0","−√x, x ≥ 0","x², x ≥ 0","1/x², x > 0"]',
 'x≥0 da h funksiya bir qiymatli teskari funksiyaga ega. y=x² da x va y ni almashtirib, manfiy bo‘lmagan tarmoqni olsak h⁻¹(x)=√x.',70),

('P1FUN01-A02','P1-FUN-01','P1 Functions','P1-FUN-01','medium','mcq',
 'If f(x)=3x−7 for real x, what is f⁻¹(x)?',
 '["(x+7)/3","(x−7)/3","3x+7","1/(3x−7)"]','A',
 'Let y=3x−7. Rearranging gives x=(y+7)/3, so f⁻¹(x)=(x+7)/3.',
 'Если f(x)=3x−7 для всех действительных x, чему равна f⁻¹(x)?',
 '["(x+7)/3","(x−7)/3","3x+7","1/(3x−7)"]',
 'Пусть y=3x−7. Тогда x=(y+7)/3, следовательно f⁻¹(x)=(x+7)/3.',
 'Agar f(x)=3x−7 barcha haqiqiy x lar uchun berilgan bo‘lsa, f⁻¹(x) nimaga teng?',
 '["(x+7)/3","(x−7)/3","3x+7","1/(3x−7)"]',
 'y=3x−7 deb oling. Bundan x=(y+7)/3, demak f⁻¹(x)=(x+7)/3.',60),

('P1FUN01-A03','P1-FUN-01','P1 Functions','P1-FUN-01','medium','input',
 'Let f(x)=x² and g(x)=2x−1. Enter the value of (f∘g)(3).',
 '[]','25',
 'g(3)=5, then f(5)=25. Therefore (f∘g)(3)=25.',
 'Пусть f(x)=x² и g(x)=2x−1. Введите значение (f∘g)(3).',
 '[]',
 'g(3)=5, затем f(5)=25. Поэтому (f∘g)(3)=25.',
 'f(x)=x² va g(x)=2x−1 bo‘lsin. (f∘g)(3) qiymatini kiriting.',
 '[]',
 'g(3)=5, so‘ng f(5)=25. Demak (f∘g)(3)=25.',50),

('P1FUN02-A01','P1-FUN-02','P1 Functions','P1-FUN-02','medium','mcq',
 'For f(x)=(x+2)²−1 with −5 ≤ x ≤ 1, what is the range?',
 '["−1 ≤ f(x) ≤ 8","0 ≤ f(x) ≤ 9","−1 ≤ f(x) ≤ 3","−5 ≤ f(x) ≤ 1"]','A',
 'The turning point x=−2 lies in the domain and gives the minimum −1. Both endpoints give 8, so the range is [−1,8].',
 'Для f(x)=(x+2)²−1 при −5 ≤ x ≤ 1 каков диапазон значений?',
 '["−1 ≤ f(x) ≤ 8","0 ≤ f(x) ≤ 9","−1 ≤ f(x) ≤ 3","−5 ≤ f(x) ≤ 1"]',
 'Точка поворота x=−2 входит в область определения и даёт минимум −1. На обоих концах получается 8, поэтому диапазон — [−1,8].',
 'f(x)=(x+2)²−1 va −5 ≤ x ≤ 1 bo‘lsa, funksiyaning qiymatlar sohasi qaysi?',
 '["−1 ≤ f(x) ≤ 8","0 ≤ f(x) ≤ 9","−1 ≤ f(x) ≤ 3","−5 ≤ f(x) ≤ 1"]',
 'Burilish nuqtasi x=−2 aniqlanish sohasida va minimum −1 ni beradi. Ikkala chekka nuqtada ham 8 chiqadi, demak qiymatlar sohasi [−1,8].',70),

('P1FUN02-A02','P1-FUN-02','P1 Functions','P1-FUN-02','hard','mcq',
 'For f(x)=−2(x−1)²+5 with 0 ≤ x ≤ 4, what is the range?',
 '["−13 ≤ f(x) ≤ 5","−3 ≤ f(x) ≤ 5","−18 ≤ f(x) ≤ 5","0 ≤ f(x) ≤ 5"]','A',
 'The maximum is 5 at x=1. At x=0, f=3; at x=4, f=−13, so the minimum is −13.',
 'Для f(x)=−2(x−1)²+5 при 0 ≤ x ≤ 4 каков диапазон значений?',
 '["−13 ≤ f(x) ≤ 5","−3 ≤ f(x) ≤ 5","−18 ≤ f(x) ≤ 5","0 ≤ f(x) ≤ 5"]',
 'Максимум 5 достигается при x=1. При x=0 получаем 3, при x=4 получаем −13, поэтому минимум равен −13.',
 'f(x)=−2(x−1)²+5 va 0 ≤ x ≤ 4 bo‘lsa, funksiyaning qiymatlar sohasi qaysi?',
 '["−13 ≤ f(x) ≤ 5","−3 ≤ f(x) ≤ 5","−18 ≤ f(x) ≤ 5","0 ≤ f(x) ≤ 5"]',
 'Maksimum 5 x=1 da. x=0 da f=3, x=4 da f=−13, shuning uchun minimum −13.',80),

('P1FUN02-A03','P1-FUN-02','P1 Functions','P1-FUN-02','medium','mcq',
 'For f(x)=7−3x with −2 ≤ x ≤ 5, what is the range?',
 '["−8 ≤ f(x) ≤ 13","−2 ≤ f(x) ≤ 5","−13 ≤ f(x) ≤ 8","−8 < f(x) < 13"]','A',
 'The function is decreasing. f(−2)=13 and f(5)=−8, with both endpoints included.',
 'Для f(x)=7−3x при −2 ≤ x ≤ 5 каков диапазон значений?',
 '["−8 ≤ f(x) ≤ 13","−2 ≤ f(x) ≤ 5","−13 ≤ f(x) ≤ 8","−8 < f(x) < 13"]',
 'Функция убывает. f(−2)=13 и f(5)=−8, причём обе границы включены.',
 'f(x)=7−3x va −2 ≤ x ≤ 5 bo‘lsa, funksiyaning qiymatlar sohasi qaysi?',
 '["−8 ≤ f(x) ≤ 13","−2 ≤ f(x) ≤ 5","−13 ≤ f(x) ≤ 8","−8 < f(x) < 13"]',
 'Funksiya kamayuvchi. f(−2)=13 va f(5)=−8, ikkala chegara ham kiritiladi.',60)
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
  'ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:'||s.content_key,
  s.time_limit,null,'draft'
from src s
where not exists(
  select 1 from public.questions q
  where q.book_ref='ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:'||s.content_key
);

insert into private.exam_prep_written_tasks(
  id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
  prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
  lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(15601,4801,'P1QUA01-AW02','P1','P1-QUA-01','{}','v1',
 'Write y=3x²−18x+20 in completed-square form. Hence state the vertex, axis of symmetry and minimum value. Expand your completed-square form to verify it.',
 'Представьте y=3x²−18x+20 в форме полного квадрата. Затем укажите вершину, ось симметрии и минимальное значение. Раскройте скобки, чтобы проверить полученную форму.',
 'y=3x²−18x+20 ni to‘liq kvadrat ko‘rinishiga keltiring. So‘ng cho‘qqi, simmetriya o‘qi va eng kichik qiymatni ko‘rsating. Natijani tekshirish uchun qavslarni oching.',
 '{"criteria":[{"id":"form","rule":"Obtains 3(x-3)^2-7 with valid working.","marks":2},{"id":"features","rule":"States vertex (3,-7), axis x=3 and minimum -7.","marks":3},{"id":"verification","rule":"Expands back to 3x^2-18x+20 correctly.","marks":1}],"max_marks":6}',
 'Check the factor 3, the half-coefficient inside the bracket, the constant compensation, all three graph features and the final expansion.',
 'Проверьте множитель 3, половину коэффициента при x внутри скобок, компенсацию постоянного члена, все три характеристики графика и обратное раскрытие скобок.',
 '3 koeffitsiyentini, qavs ichidagi x koeffitsiyentining yarmini, doimiy had kompensatsiyasini, uchta grafik xususiyatini va yakuniy yoyishni tekshiring.',
 'draft','pending','pending','pending','pending'),

(15602,4801,'P1QUA02-AW02','P1','P1-QUA-02','{}','v1',
 'The equation 2x²+(p−1)x+3=0 has no real roots. Find the complete interval of values of p and explain what happens at both boundary values.',
 'Уравнение 2x²+(p−1)x+3=0 не имеет действительных корней. Найдите полный интервал значений p и объясните, что происходит на обеих границах интервала.',
 '2x²+(p−1)x+3=0 tenglama haqiqiy ildizlarga ega emas. p ning to‘liq oralig‘ini toping va oraliqning ikkala chegarasida nima sodir bo‘lishini tushuntiring.',
 '{"criteria":[{"id":"disc","rule":"Forms Δ=(p-1)^2-24.","marks":2},{"id":"condition","rule":"Uses Δ<0 to obtain 1-2sqrt(6)<p<1+2sqrt(6).","marks":3},{"id":"boundary","rule":"Explains each boundary gives Δ=0 and equal real roots.","marks":1}],"max_marks":6}',
 'Check the discriminant carefully, solve the squared inequality in both directions, and treat equality separately from the no-real-root interval.',
 'Проверьте дискриминант, решите квадратное неравенство в обе стороны и отдельно рассмотрите равенство на границах.',
 'Diskriminantni tekshiring, kvadratli tengsizlikni ikkala yo‘nalishda yeching va chegaralardagi tenglik holatini alohida ko‘ring.',
 'draft','pending','pending','pending','pending'),

(15603,4801,'P1QUA03-AW02','P1','P1-QUA-03','{}','v1',
 'Solve x²−6x−4=0 by completing the square. Keep the answers exact and verify both roots in the original equation.',
 'Решите x²−6x−4=0 методом выделения полного квадрата. Оставьте ответы в точном виде и проверьте оба корня в исходном уравнении.',
 'x²−6x−4=0 tenglamani to‘liq kvadratga keltirish usuli bilan yeching. Javoblarni aniq ko‘rinishda qoldiring va ikkala ildizni dastlabki tenglamada tekshiring.',
 '{"criteria":[{"id":"square","rule":"Obtains (x-3)^2=13 with valid working.","marks":2},{"id":"roots","rule":"States x=3±sqrt(13).","marks":2},{"id":"verification","rule":"Checks both exact roots in the original equation or by an equivalent valid verification.","marks":2}],"max_marks":6}',
 'Check the sign when moving the constant, remember both square-root branches, and substitute both exact roots back.',
 'Проверьте знак при переносе постоянного члена, учтите обе ветви квадратного корня и подставьте оба точных корня обратно.',
 'Doimiy hadni ko‘chirishdagi ishorani tekshiring, kvadrat ildizning ikkala tarmog‘ini oling va ikkala aniq ildizni qayta qo‘yib tekshiring.',
 'draft','pending','pending','pending','pending'),

(15604,4801,'P1FUN01-AW02','P1','P1-FUN-01','{}','v1',
 'Let f(x)=x−2 for real x and g(x)=x² for x≥0. State the domain and range of g, explain why g is one-one there, find g⁻¹(x), and determine both the formula and domain of (g∘f)(x).',
 'Пусть f(x)=x−2 для всех действительных x, а g(x)=x² при x≥0. Укажите область определения и диапазон g, объясните, почему g взаимно однозначна на этой области, найдите g⁻¹(x), а затем определите формулу и область определения (g∘f)(x).',
 'f(x)=x−2 barcha haqiqiy x lar uchun, g(x)=x² esa x≥0 da berilgan bo‘lsin. g ning aniqlanish va qiymatlar sohasini ko‘rsating, nima uchun u bu sohada bir-biriga mos ekanini tushuntiring, g⁻¹(x) ni toping, so‘ng (g∘f)(x) formulasini va uning aniqlanish sohasini aniqlang.',
 '{"criteria":[{"id":"domain_range","rule":"States domain [0,infinity) and range [0,infinity) for g.","marks":2},{"id":"one_one_inverse","rule":"Explains g is one-one on x>=0 and gives g^-1(x)=sqrt(x), x>=0.","marks":3},{"id":"composition","rule":"Gives (g∘f)(x)=(x-2)^2 with domain x>=2.","marks":3}],"max_marks":8}',
 'Keep the restriction on g visible. For the composition, f(x) must land inside the domain of g, so determine the allowed x before stating the final domain.',
 'Не теряйте ограничение области g. Для композиции значение f(x) должно попадать в область определения g, поэтому сначала найдите допустимые x.',
 'g ning cheklangan aniqlanish sohasini saqlang. Kompozitsiyada f(x) qiymati g ning aniqlanish sohasiga tushishi kerak, shuning uchun avval ruxsat etilgan x larni toping.',
 'draft','pending','pending','pending','pending'),

(15605,4801,'P1FUN02-AW02','P1','P1-FUN-02','{}','v1',
 'For f(x)=(x−2)²+1 with −1≤x≤6, determine the range. Your working must identify the turning point and compare both endpoint values.',
 'Для f(x)=(x−2)²+1 при −1≤x≤6 определите диапазон значений. В решении обязательно укажите точку поворота и сравните значения на обоих концах области определения.',
 'f(x)=(x−2)²+1 va −1≤x≤6 bo‘lsa, qiymatlar sohasini aniqlang. Yechimda burilish nuqtasini ko‘rsating va aniqlanish sohasining ikkala chekkasidagi qiymatlarni taqqoslang.',
 '{"criteria":[{"id":"turning","rule":"Identifies x=2 in the domain and f(2)=1 as the minimum.","marks":2},{"id":"endpoints","rule":"Finds f(-1)=10 and f(6)=17 and selects 17 as the maximum.","marks":2},{"id":"range","rule":"States 1<=f(x)<=17 with inclusive endpoints.","marks":2}],"max_marks":6}',
 'Check that the turning point lies inside the restricted domain, evaluate both endpoints, then choose the smaller/larger values before writing the inclusive range.',
 'Проверьте, что точка поворота входит в ограниченную область определения, вычислите оба конца и только затем запишите включённый диапазон.',
 'Burilish nuqtasi cheklangan aniqlanish sohasida ekanini tekshiring, ikkala chekka qiymatni hisoblang va so‘ng yopiq qiymatlar sohasini yozing.',
 'draft','pending','pending','pending','pending')
on conflict (id) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where id=4801 and content_version='p1_aw01_04_alt_learning_draft_v1'
),
src(meta_id,content_key,skill_code) as (values
 (58901,'P1QUA01-A01','P1-QUA-01'),(58902,'P1QUA01-A02','P1-QUA-01'),(58903,'P1QUA01-A03','P1-QUA-01'),
 (58904,'P1QUA02-A01','P1-QUA-02'),(58905,'P1QUA02-A02','P1-QUA-02'),(58906,'P1QUA02-A03','P1-QUA-02'),
 (58907,'P1QUA03-A01','P1-QUA-03'),(58908,'P1QUA03-A02','P1-QUA-03'),(58909,'P1QUA03-A03','P1-QUA-03'),
 (58910,'P1FUN01-A01','P1-FUN-01'),(58911,'P1FUN01-A02','P1-FUN-01'),(58912,'P1FUN01-A03','P1-FUN-01'),
 (58913,'P1FUN02-A01','P1-FUN-02'),(58914,'P1FUN02-A02','P1-FUN-02'),(58915,'P1FUN02-A03','P1-FUN-02')
)
insert into private.exam_prep_question_content_meta(
  id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
  exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
  copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select
  s.meta_id,cv.id,s.content_key,q.id,s.skill_code,'{}'::text[],'learning',
  'withheld','draft',
  'Original iClub-authored stem, numbers, distractors, answer and explanation; no Cambridge/coursebook question or mark-scheme wording copied.',
  'Alternate learning draft authored from the canonical skill intent. Independent values and contexts were chosen to avoid duplicating the current learning pack.',
  case when s.skill_code like 'P1-QUA-%' then 'Cambridge 9709 2026-2027 v4; P1 1.1 Quadratics'
       else 'Cambridge 9709 2026-2027 v4; P1 1.2 Functions' end,
  case when s.skill_code like 'P1-QUA-%' then 'Complete Pure Mathematics 1, Ch1 Quadratics, pp.2-20 (mapping only)'
       else 'Complete Pure Mathematics 1, Functions chapter (mapping only)' end,
  'pending','pending','pending','pending','pending','not_applicable',
  md5(concat_ws(chr(31),
    q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),
    coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
    coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),
    coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
    coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),
    coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')
  ))
from cv cross join src s
join public.questions q
  on q.book_ref='ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:'||s.content_key
on conflict (id) do nothing;

insert into private.exam_prep_assessments(
  id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35201,4801,'P1-QUA-01-learning-alt-02','v1','P1','learning','draft','Quadratics: completed square - alternate learning','Квадратные выражения: полный квадрат - дополнительное обучение','Kvadratlar: to‘liq kvadrat - qo‘shimcha o‘rganish'),
(35202,4801,'P1-QUA-02-learning-alt-02','v1','P1','learning','draft','Quadratics: discriminant - alternate learning','Квадратные уравнения: дискриминант - дополнительное обучение','Kvadrat tenglamalar: diskriminant - qo‘shimcha o‘rganish'),
(35203,4801,'P1-QUA-03-learning-alt-02','v1','P1','learning','draft','Quadratics: solving equations - alternate learning','Квадратные уравнения: решение - дополнительное обучение','Kvadrat tenglamalar: yechish - qo‘shimcha o‘rganish'),
(35204,4801,'P1-FUN-01-learning-alt-02','v1','P1','learning','draft','Functions: language, inverse and composition - alternate learning','Функции: язык, обратная функция и композиция - дополнительное обучение','Funksiyalar: til, teskari funksiya va kompozitsiya - qo‘shimcha o‘rganish'),
(35205,4801,'P1-FUN-02-learning-alt-02','v1','P1','learning','draft','Functions: range under domain restriction - alternate learning','Функции: диапазон при ограниченной области - дополнительное обучение','Funksiyalar: cheklangan sohada qiymatlar sohasi - qo‘shimcha o‘rganish')
on conflict (id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
 (35201,1,'P1QUA01-A01',null::bigint,'P1-QUA-01'),(35201,2,'P1QUA01-A02',null,'P1-QUA-01'),(35201,3,'P1QUA01-A03',null,'P1-QUA-01'),(35201,4,null,15601,'P1-QUA-01'),
 (35202,1,'P1QUA02-A01',null,'P1-QUA-02'),(35202,2,'P1QUA02-A02',null,'P1-QUA-02'),(35202,3,'P1QUA02-A03',null,'P1-QUA-02'),(35202,4,null,15602,'P1-QUA-02'),
 (35203,1,'P1QUA03-A01',null,'P1-QUA-03'),(35203,2,'P1QUA03-A02',null,'P1-QUA-03'),(35203,3,'P1QUA03-A03',null,'P1-QUA-03'),(35203,4,null,15603,'P1-QUA-03'),
 (35204,1,'P1FUN01-A01',null,'P1-FUN-01'),(35204,2,'P1FUN01-A02',null,'P1-FUN-01'),(35204,3,'P1FUN01-A03',null,'P1-FUN-01'),(35204,4,null,15604,'P1-FUN-01'),
 (35205,1,'P1FUN02-A01',null,'P1-FUN-02'),(35205,2,'P1FUN02-A02',null,'P1-FUN-02'),(35205,3,'P1FUN02-A03',null,'P1-FUN-02'),(35205,4,null,15605,'P1-FUN-02')
)
insert into private.exam_prep_assessment_items(
  assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select
  i.assessment_id,i.item_order,q.id,i.written_id,i.skill_code,
  case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions q
  on i.content_key is not null
 and q.book_ref='ExamPrep:P1:p1_aw01_04_alt_learning_draft_v1:'||i.content_key
on conflict (assessment_id,item_order) do nothing;

do $postcheck$
declare
  v_bad int;
begin
  if (select status from private.exam_prep_content_versions where id=4801)<>'draft'
     or (select count(*) from private.exam_prep_assessments where content_version_id=4801 and status='draft')<>5
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4801 and lifecycle_state='draft')<>5
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4801 and lifecycle_state='draft' and reserve_role='learning')<>15
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4801)<>20
  then
    raise exception 'aw01_04_alt_p1_draft cardinality/state postcheck failed';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id=4801
    and (
      m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or q.is_active<>false
      or q.quality_status<>'draft'
    );
  if v_bad<>0 then
    raise exception 'aw01_04_alt_p1_draft accidentally approved/exposed rows=%',v_bad;
  end if;

  if exists(
    select 1 from private.exam_prep_assessments a
    where a.content_version_id=4801 and a.status='published'
  ) then
    raise exception 'aw01_04_alt_p1_draft published assessment detected';
  end if;
end
$postcheck$;

commit;
