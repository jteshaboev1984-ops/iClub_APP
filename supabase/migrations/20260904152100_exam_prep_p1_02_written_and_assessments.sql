-- P1-02 written evidence + assessment memberships for the six newly authored opening skills.
-- Written tasks are Core self-review capable; Mentor Verified remains a separate human authority.

begin;

-- One original governed written task per new skill.
with cv as (
  select id,content_version,component_code from private.exam_prep_content_versions
  where content_version in ('p1_foundations_runway_v1','p5_dat02_runway_v1') and status='draft'
), defs(cvkey,task_key,component,skill,en,ru,uz,rubric,sen,sru,suz) as (values
('p1_foundations_runway_v1','P1QUA01-W01','P1','P1-QUA-01',
'Write x² − 8x + 13 in completed-square form. Hence state the vertex and minimum value of y = x² − 8x + 13. Expand your completed-square form to verify it.',
'Запишите x² − 8x + 13 в форме полного квадрата. Затем укажите вершину и минимальное значение y = x² − 8x + 13. Раскройте полученную форму для проверки.',
'x² − 8x + 13 ni to‘liq kvadrat ko‘rinishida yozing. So‘ng y = x² − 8x + 13 grafigining uchini va minimum qiymatini ayting. Tekshirish uchun hosil bo‘lgan ko‘rinishni oching.',
'{"max_marks":6,"criteria":[{"id":"form","marks":2,"rule":"Obtains (x-4)^2-3 with valid working."},{"id":"features","marks":2,"rule":"States vertex (4,-3) and minimum -3."},{"id":"verification","marks":2,"rule":"Expands back correctly and presents coherent algebra."}]}',
'Check the half-coefficient, the constant compensation, the vertex read from the form, and your final expansion.',
'Проверьте половину линейного коэффициента, компенсацию константы, вершину из полученной формы и обратное раскрытие.',
'Chiziqli koeffitsiyent yarmini, doimiy had kompensatsiyasini, hosil bo‘lgan ko‘rinishdan uchni va qayta ochishni tekshiring.'),
('p1_foundations_runway_v1','P1QUA02-W01','P1','P1-QUA-02',
'The equation x² + 6x + c = 0 has no real roots. Find the condition on c and explain what happens at the boundary value.',
'Уравнение x² + 6x + c = 0 не имеет действительных корней. Найдите условие на c и объясните, что происходит при граничном значении.',
'x² + 6x + c = 0 tenglama haqiqiy ildizga ega emas. c uchun shartni toping va chegara qiymatida nima bo‘lishini tushuntiring.',
'{"max_marks":6,"criteria":[{"id":"disc","marks":2,"rule":"Forms Δ=36-4c."},{"id":"condition","marks":2,"rule":"Uses Δ<0 to obtain c>9."},{"id":"boundary","marks":2,"rule":"Explains c=9 gives Δ=0 and equal real roots."}]}',
'Write a, b, c; form the full discriminant; use the correct inequality; then test the equality boundary.',
'Выпишите a, b, c; составьте полный дискриминант; используйте нужное неравенство; затем проверьте границу равенства.',
'a, b, c ni yozing; to‘liq diskriminant tuzing; kerakli tengsizlikdan foydalaning; so‘ng tenglik chegarasini tekshiring.'),
('p1_foundations_runway_v1','P1QUA03-W01','P1','P1-QUA-03',
'Solve 2x² + x − 6 = 0 by a suitable method. Show the factorisation or formula working and verify both roots in the original equation.',
'Решите 2x² + x − 6 = 0 подходящим методом. Покажите разложение или работу по формуле и проверьте оба корня в исходном уравнении.',
'2x² + x − 6 = 0 tenglamani mos usul bilan yeching. Ko‘paytuvchilarga ajratish yoki formula bosqichlarini ko‘rsating va ikkala ildizni dastlabki tenglamada tekshiring.',
'{"max_marks":6,"criteria":[{"id":"method","marks":2,"rule":"Uses a valid factorisation (2x-3)(x+2) or correct quadratic formula."},{"id":"roots","marks":2,"rule":"Obtains x=3/2 and x=-2."},{"id":"check","marks":2,"rule":"Verifies both roots or otherwise checks the solution coherently."}]}',
'Check that your factors expand to every term, that both roots are stated, and that both satisfy the original equation.',
'Проверьте раскрытие множителей, наличие обоих корней и их подстановку в исходное уравнение.',
'Ko‘paytuvchilar ochilganda barcha hadlar chiqishini, ikkala ildiz yozilganini va dastlabki tenglamani qanoatlantirishini tekshiring.'),
('p1_foundations_runway_v1','P1FUN01-W01','P1','P1-FUN-01',
'Let f(x)=2x+3 for real x and g(x)=x² for x≥0. State the domain and range of g, explain why g is one-one on this domain, find g⁻¹(x), and write (f∘g)(x).',
'Пусть f(x)=2x+3 для действительных x и g(x)=x² при x≥0. Укажите область определения и значений g, объясните её взаимную однозначность, найдите g⁻¹(x) и запишите (f∘g)(x).',
'f(x)=2x+3 haqiqiy x lar uchun va g(x)=x², x≥0 bo‘lsin. g ning aniqlanish va qiymatlar sohasini yozing, nima uchun u bir-biriga bir qiymatli ekanini tushuntiring, g⁻¹(x) ni toping va (f∘g)(x) ni yozing.',
'{"max_marks":8,"criteria":[{"id":"domain_range","marks":2,"rule":"Domain [0,∞), range [0,∞)."},{"id":"one_one","marks":2,"rule":"Explains distinct nonnegative inputs give distinct squares/monotonicity."},{"id":"inverse","marks":2,"rule":"g^-1(x)=sqrt(x), x≥0."},{"id":"composition","marks":2,"rule":"(f∘g)(x)=2x^2+3 for x≥0."}]}',
'Keep domain and range separate; use the domain restriction when choosing the inverse branch; apply g before f in the composition.',
'Не смешивайте область определения и значений; учтите ограничение при выборе ветви обратной функции; в композиции сначала применяйте g.',
'Aniqlanish va qiymatlar sohasini ajrating; teskari funksiya tarmog‘ini tanlashda cheklovni hisobga oling; kompozitsiyada avval g ni qo‘llang.'),
('p1_foundations_runway_v1','P1FUN02-W01','P1','P1-FUN-02',
'For f(x)=(x−1)²+2 with −2≤x≤4, determine the range. Your solution must identify the relevant turning point and compare the endpoint values.',
'Для f(x)=(x−1)²+2 при −2≤x≤4 найдите область значений. В решении укажите точку экстремума и сравните значения на концах.',
'f(x)=(x−1)²+2 va −2≤x≤4 bo‘lsa, qiymatlar sohasini toping. Yechimda tegishli burilish nuqtasini va chegara qiymatlarini taqqoslang.',
'{"max_marks":6,"criteria":[{"id":"turning","marks":2,"rule":"Identifies x=1 gives minimum 2 and lies in the domain."},{"id":"endpoints","marks":2,"rule":"Computes f(-2)=11 and f(4)=11."},{"id":"range","marks":2,"rule":"States 2≤f(x)≤11 with included endpoints and coherent reasoning."}]}',
'Check whether the turning point lies in the restricted domain, evaluate both endpoints, then state inclusion correctly.',
'Проверьте, лежит ли точка экстремума в области, вычислите оба конца и правильно укажите включение границ.',
'Burilish nuqtasi cheklangan sohada ekanini tekshiring, ikkala chegarani hisoblang va chegaralar kirishini to‘g‘ri yozing.'),
('p5_dat02_runway_v1','P5DAT02-W01','P5','P5-DAT-02',
'The observations are 11, 13, 16, 20, 22, 22, 27, 31. Construct an ordered stem-and-leaf diagram with a key. Then find the median and range.',
'Даны наблюдения 11, 13, 16, 20, 22, 22, 27, 31. Постройте упорядоченную диаграмму «стебель-листья» с ключом. Затем найдите медиану и размах.',
'Kuzatuvlar: 11, 13, 16, 20, 22, 22, 27, 31. Kalit bilan tartiblangan poya-barg diagrammasini tuzing. So‘ng mediana va oraliq kengligini toping.',
'{"max_marks":7,"criteria":[{"id":"diagram","marks":3,"rule":"Correct ordered stems/leaves: 1|1 3 6; 2|0 2 2 7; 3|1."},{"id":"key","marks":1,"rule":"Provides an unambiguous key such as 1|1=11."},{"id":"median","marks":2,"rule":"Median=(20+22)/2=21."},{"id":"range","marks":1,"rule":"Range=31-11=20."}]}',
'Keep repeated observations, order leaves, give a key, and use the ordered middle pair for the median.',
'Сохраните повторы, упорядочьте листья, дайте ключ и используйте среднюю пару для медианы.',
'Takroriy kuzatuvlarni saqlang, barglarni tartiblang, kalit yozing va mediana uchun o‘rtadagi juftlikdan foydalaning.')
)
insert into private.exam_prep_written_tasks(content_version_id,task_key,component_code,primary_skill_code,task_version,prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at)
select cv.id,d.task_key,d.component,d.skill,'wtv1',d.en,d.ru,d.uz,d.rubric::jsonb,d.sen,d.sru,d.suz,'approved','pass','pass','pass','pass',now()
from defs d join cv on cv.content_version=d.cvkey and cv.component_code=d.component
on conflict(content_version_id,task_key,task_version) do nothing;

-- Assessment definitions.
with cv as (select id,content_version,component_code from private.exam_prep_content_versions where content_version in ('p1_foundations_runway_v1','p5_dat02_runway_v1') and status='draft'),
defs(cvkey,k,t,en,ru,uz) as (values
('p1_foundations_runway_v1','p1_foundations_diagnostic','diagnostic','P1 Foundations diagnostic','Диагностика P1 Foundations','P1 Foundations diagnostikasi'),
('p1_foundations_runway_v1','p1_qua01_learning','learning','Completed square learning','Выделение полного квадрата: обучение','To‘liq kvadrat: o‘rganish'),
('p1_foundations_runway_v1','p1_qua02_learning','learning','Discriminant learning','Дискриминант: обучение','Diskriminant: o‘rganish'),
('p1_foundations_runway_v1','p1_qua03_learning','learning','Quadratic solving learning','Решение квадратных уравнений: обучение','Kvadrat tenglamalarni yechish: o‘rganish'),
('p1_foundations_runway_v1','p1_fun01_learning','learning','Function language learning','Язык функций: обучение','Funksiya tili: o‘rganish'),
('p1_foundations_runway_v1','p1_fun02_learning','learning','Restricted range learning','Область значений с ограничением: обучение','Cheklangan qiymatlar sohasi: o‘rganish'),
('p1_foundations_runway_v1','p1_qua01_retest','retest','Completed square delayed retest','Отложенный ретест: полный квадрат','Kechiktirilgan qayta test: to‘liq kvadrat'),
('p1_foundations_runway_v1','p1_qua02_retest','retest','Discriminant delayed retest','Отложенный ретест: дискриминант','Kechiktirilgan qayta test: diskriminant'),
('p1_foundations_runway_v1','p1_qua03_retest','retest','Quadratic solving delayed retest','Отложенный ретест: квадратные уравнения','Kechiktirilgan qayta test: kvadrat tenglamalar'),
('p1_foundations_runway_v1','p1_fun01_retest','retest','Function language delayed retest','Отложенный ретест: функции','Kechiktirilgan qayta test: funksiyalar'),
('p1_foundations_runway_v1','p1_fun02_retest','retest','Restricted range delayed retest','Отложенный ретест: область значений','Kechiktirilgan qayta test: qiymatlar sohasi'),
('p1_foundations_runway_v1','p1_foundations_mixed','mixed','P1 Foundations mixed transfer','Смешанный перенос P1 Foundations','P1 Foundations aralash transfer'),
('p5_dat02_runway_v1','p5_dat02_diagnostic','diagnostic','Stem-and-leaf diagnostic','Диагностика: стебель-листья','Poya-barg diagnostikasi'),
('p5_dat02_runway_v1','p5_dat02_learning','learning','Stem-and-leaf learning','Стебель-листья: обучение','Poya-barg: o‘rganish'),
('p5_dat02_runway_v1','p5_dat02_retest','retest','Stem-and-leaf delayed retest','Отложенный ретест: стебель-листья','Kechiktirilgan qayta test: poya-barg'),
('p5_dat02_runway_v1','p5_dat02_mixed','mixed','Stem-and-leaf transfer','Перенос: стебель-листья','Poya-barg transfer')
)
insert into private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz)
select cv.id,d.k,'av1',cv.component_code,d.t,'approved',d.en,d.ru,d.uz from defs d join cv on cv.content_version=d.cvkey
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

-- Memberships. Second retest item per skill intentionally remains outside the retest assessment as unseen reserve.
with cv as (select id,content_version from private.exam_prep_content_versions where content_version in ('p1_foundations_runway_v1','p5_dat02_runway_v1')),
a as (select x.id,x.assessment_key,cv.content_version from private.exam_prep_assessments x join cv on cv.id=x.content_version_id),
m as (select x.content_key,x.question_id,x.primary_skill_code,cv.content_version from private.exam_prep_question_content_meta x join cv on cv.id=x.content_version_id),
w as (select x.id,x.task_key,x.primary_skill_code,cv.content_version from private.exam_prep_written_tasks x join cv on cv.id=x.content_version_id),
items(cvkey,akey,ord,ckey,wkey,skill,role,holdout) as (values
('p1_foundations_runway_v1','p1_foundations_diagnostic',1,'P1QUA01-D01',null,'P1-QUA-01','diagnostic',true),
('p1_foundations_runway_v1','p1_foundations_diagnostic',2,'P1QUA02-D01',null,'P1-QUA-02','diagnostic',true),
('p1_foundations_runway_v1','p1_foundations_diagnostic',3,'P1QUA03-D01',null,'P1-QUA-03','diagnostic',true),
('p1_foundations_runway_v1','p1_foundations_diagnostic',4,'P1FUN01-D01',null,'P1-FUN-01','diagnostic',true),
('p1_foundations_runway_v1','p1_foundations_diagnostic',5,'P1FUN02-D01',null,'P1-FUN-02','diagnostic',true),
('p1_foundations_runway_v1','p1_qua01_learning',1,'P1QUA01-L01',null,'P1-QUA-01','learning',false),('p1_foundations_runway_v1','p1_qua01_learning',2,'P1QUA01-L02',null,'P1-QUA-01','learning',false),('p1_foundations_runway_v1','p1_qua01_learning',3,'P1QUA01-L03',null,'P1-QUA-01','learning',false),('p1_foundations_runway_v1','p1_qua01_learning',4,null,'P1QUA01-W01','P1-QUA-01','written',false),
('p1_foundations_runway_v1','p1_qua02_learning',1,'P1QUA02-L01',null,'P1-QUA-02','learning',false),('p1_foundations_runway_v1','p1_qua02_learning',2,'P1QUA02-L02',null,'P1-QUA-02','learning',false),('p1_foundations_runway_v1','p1_qua02_learning',3,'P1QUA02-L03',null,'P1-QUA-02','learning',false),('p1_foundations_runway_v1','p1_qua02_learning',4,null,'P1QUA02-W01','P1-QUA-02','written',false),
('p1_foundations_runway_v1','p1_qua03_learning',1,'P1QUA03-L01',null,'P1-QUA-03','learning',false),('p1_foundations_runway_v1','p1_qua03_learning',2,'P1QUA03-L02',null,'P1-QUA-03','learning',false),('p1_foundations_runway_v1','p1_qua03_learning',3,'P1QUA03-L03',null,'P1-QUA-03','learning',false),('p1_foundations_runway_v1','p1_qua03_learning',4,null,'P1QUA03-W01','P1-QUA-03','written',false),
('p1_foundations_runway_v1','p1_fun01_learning',1,'P1FUN01-L01',null,'P1-FUN-01','learning',false),('p1_foundations_runway_v1','p1_fun01_learning',2,'P1FUN01-L02',null,'P1-FUN-01','learning',false),('p1_foundations_runway_v1','p1_fun01_learning',3,'P1FUN01-L03',null,'P1-FUN-01','learning',false),('p1_foundations_runway_v1','p1_fun01_learning',4,null,'P1FUN01-W01','P1-FUN-01','written',false),
('p1_foundations_runway_v1','p1_fun02_learning',1,'P1FUN02-L01',null,'P1-FUN-02','learning',false),('p1_foundations_runway_v1','p1_fun02_learning',2,'P1FUN02-L02',null,'P1-FUN-02','learning',false),('p1_foundations_runway_v1','p1_fun02_learning',3,'P1FUN02-L03',null,'P1-FUN-02','learning',false),('p1_foundations_runway_v1','p1_fun02_learning',4,null,'P1FUN02-W01','P1-FUN-02','written',false),
('p1_foundations_runway_v1','p1_qua01_retest',1,'P1QUA01-R01',null,'P1-QUA-01','retest',true),('p1_foundations_runway_v1','p1_qua02_retest',1,'P1QUA02-R01',null,'P1-QUA-02','retest',true),('p1_foundations_runway_v1','p1_qua03_retest',1,'P1QUA03-R01',null,'P1-QUA-03','retest',true),('p1_foundations_runway_v1','p1_fun01_retest',1,'P1FUN01-R01',null,'P1-FUN-01','retest',true),('p1_foundations_runway_v1','p1_fun02_retest',1,'P1FUN02-R01',null,'P1-FUN-02','retest',true),
('p1_foundations_runway_v1','p1_foundations_mixed',1,'P1QUA01-M01',null,'P1-QUA-01','mixed',true),('p1_foundations_runway_v1','p1_foundations_mixed',2,'P1QUA02-M01',null,'P1-QUA-02','mixed',true),('p1_foundations_runway_v1','p1_foundations_mixed',3,'P1QUA03-M01',null,'P1-QUA-03','mixed',true),('p1_foundations_runway_v1','p1_foundations_mixed',4,'P1FUN01-M01',null,'P1-FUN-01','mixed',true),('p1_foundations_runway_v1','p1_foundations_mixed',5,'P1FUN02-M01',null,'P1-FUN-02','mixed',true),
('p5_dat02_runway_v1','p5_dat02_diagnostic',1,'P5DAT02-D01',null,'P5-DAT-02','diagnostic',true),
('p5_dat02_runway_v1','p5_dat02_learning',1,'P5DAT02-L01',null,'P5-DAT-02','learning',false),('p5_dat02_runway_v1','p5_dat02_learning',2,'P5DAT02-L02',null,'P5-DAT-02','learning',false),('p5_dat02_runway_v1','p5_dat02_learning',3,'P5DAT02-L03',null,'P5-DAT-02','learning',false),('p5_dat02_runway_v1','p5_dat02_learning',4,null,'P5DAT02-W01','P5-DAT-02','written',false),
('p5_dat02_runway_v1','p5_dat02_retest',1,'P5DAT02-R01',null,'P5-DAT-02','retest',true),
('p5_dat02_runway_v1','p5_dat02_mixed',1,'P5DAT02-M01',null,'P5-DAT-02','mixed',true)
)
insert into private.exam_prep_assessment_items(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout)
select a.id,i.ord,m.question_id,w.id,i.skill,i.role,i.holdout from items i
join a on a.content_version=i.cvkey and a.assessment_key=i.akey
left join m on m.content_version=i.cvkey and m.content_key=i.ckey
left join w on w.content_version=i.cvkey and w.task_key=i.wkey
on conflict(assessment_id,item_order) do nothing;

-- Static structure checks before QA publication.
do $$ declare v_p1 bigint; v_p5 bigint; begin
  select id into v_p1 from private.exam_prep_content_versions where content_version='p1_foundations_runway_v1';
  select id into v_p5 from private.exam_prep_content_versions where content_version='p5_dat02_runway_v1';
  if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_p1)<>5 then raise exception 'P1-02 expected 5 P1 written tasks'; end if;
  if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_p5)<>1 then raise exception 'P1-02 expected 1 DAT02 written task'; end if;
  if (select count(*) from private.exam_prep_assessments where content_version_id=v_p1)<>12 then raise exception 'P1-02 expected 12 P1 assessments'; end if;
  if (select count(*) from private.exam_prep_assessments where content_version_id=v_p5)<>4 then raise exception 'P1-02 expected 4 DAT02 assessments'; end if;
end $$;

commit;
