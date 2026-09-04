-- P1-02 E2 P5 Counting + Probability: written evidence + governed assessment memberships.
-- Core supports self-review; higher-level Mentor verification remains separate.

begin;
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_e2_counting_probability_v1' and component_code='P5' and status='draft'
), defs(task_key,skill,en,ru,uz,rubric,sen,sru,suz) as (values
('P5CNT01-W01','P5-CNT-01',
 'A school has 9 students available. (a) Choose a 3-person committee. (b) Choose a president, secretary and treasurer. For each part, state whether order matters, choose the correct counting model, calculate the number of outcomes, and explain why using the other model would overcount or undercount.',
 'В школе есть 9 доступных учеников. (a) Выберите комитет из 3 человек. (b) Выберите президента, секретаря и казначея. Для каждой части укажите, важен ли порядок, выберите правильную модель подсчёта, найдите число исходов и объясните, почему другая модель дала бы завышение или занижение.',
 'Maktabda 9 nafar o‘quvchi mavjud. (a) 3 kishilik qo‘mita tanlang. (b) Prezident, kotib va xazinachini tanlang. Har bir qismda tartib muhimmi, to‘g‘ri sanash modelini tanlang, natijalar sonini hisoblang va boshqa model nima uchun ortiqcha yoki kam sanashini tushuntiring.',
 '{"max_marks":10,"criteria":[{"id":"committee_model","marks":2,"rule":"Identifies committee as unordered and uses C(9,3)."},{"id":"committee_value","marks":2,"rule":"Obtains 84."},{"id":"officer_model","marks":2,"rule":"Identifies labelled offices as ordered and uses 9P3 or 9×8×7."},{"id":"officer_value","marks":2,"rule":"Obtains 504."},{"id":"comparison","marks":2,"rule":"Explains why permutations count role assignments while combinations do not."}]}',
 'Check whether swapping the same selected people changes the outcome. If it does, order matters. Compare 9P3 with C(9,3) and explain the factor of 3!.',
 'Проверьте, меняет ли перестановка тех же выбранных людей исход. Если да, порядок важен. Сравните 9P3 и C(9,3) и объясните множитель 3!.',
 'Ayni tanlangan odamlarni almashtirish natijani o‘zgartiradimi, tekshiring. O‘zgarsa, tartib muhim. 9P3 va C(9,3) ni solishtirib, 3! ko‘paytuvchini tushuntiring.'),
('P5CNT02-W01','P5-CNT-02',
 'Seven different books are available. (a) Arrange all 7 books in a row. (b) Arrange 4 of the 7 books in four labelled positions without repetition. Show the product-rule working for both parts and connect each product to factorial/permutation notation.',
 'Доступны 7 разных книг. (a) Расставьте все 7 книг в ряд. (b) Расставьте 4 из 7 книг на четырёх подписанных местах без повторений. Покажите правило произведения для обеих частей и свяжите каждое произведение с факториалом/обозначением перестановок.',
 '7 ta turli kitob mavjud. (a) Barcha 7 kitobni bir qatorga joylashtiring. (b) 7 kitobdan 4 tasini takrorlamasdan to‘rtta nomlangan o‘ringa joylashtiring. Har ikki qism uchun ko‘paytirish qoidasini ko‘rsating va uni faktorial/permutatsiya yozuvi bilan bog‘lang.',
 '{"max_marks":9,"criteria":[{"id":"all_product","marks":2,"rule":"Uses 7×6×5×4×3×2×1=7!."},{"id":"all_value","marks":1,"rule":"Obtains 5040."},{"id":"partial_product","marks":2,"rule":"Uses 7×6×5×4=7P4."},{"id":"partial_value","marks":1,"rule":"Obtains 840."},{"id":"reasoning","marks":3,"rule":"Explains decreasing choices and why no factor is reused."}]}',
 'For each labelled position, record how many unused books remain. Stop the product when all required positions are filled.',
 'Для каждого места записывайте, сколько неиспользованных книг осталось. Остановите произведение после заполнения требуемых мест.',
 'Har bir nomlangan o‘rin uchun nechta ishlatilmagan kitob qolganini yozing. Kerakli o‘rinlar to‘lganda ko‘paytmani to‘xtating.'),
('P5CNT03-W01','P5-CNT-03',
 'Find the number of distinct arrangements of the letters in STATISTICS. First list the multiplicity of each repeated letter, then write the factorial expression before simplifying. Explain exactly what overcounting each divisor removes.',
 'Найдите число различных перестановок букв слова STATISTICS. Сначала укажите кратность каждой повторяющейся буквы, затем запишите факториальное выражение до упрощения. Объясните, какое многократное считывание устраняет каждый делитель.',
 'STATISTICS so‘zidagi harflarning turli joylashuvlari sonini toping. Avval har bir takrorlangan harf sonini yozing, keyin soddalashtirishdan oldin faktorial ifodani tuzing. Har bir bo‘luvchi qaysi ortiqcha sanashni olib tashlashini tushuntiring.',
 '{"max_marks":10,"criteria":[{"id":"multiplicities","marks":3,"rule":"Correctly identifies 10 letters with S=3, T=3, I=2 and A,C each once."},{"id":"expression","marks":3,"rule":"Uses 10!/(3!3!2!)."},{"id":"value","marks":2,"rule":"Obtains 50400."},{"id":"reasoning","marks":2,"rule":"Explains that permutations among identical copies do not create new arrangements."}]}',
 'Count the total letters and every repeated group independently. Your denominator needs one factorial for each multiplicity greater than 1.',
 'Посчитайте общее число букв и каждую повторяющуюся группу отдельно. В знаменателе нужен отдельный факториал для каждой кратности больше 1.',
 'Umumiy harflar sonini va har bir takrorlangan guruhni alohida sanang. Maxrajda 1 dan katta har bir takror soni uchun alohida faktorial bo‘lishi kerak.'),
('P5CNT04-W01','P5-CNT-04',
 'Six distinct people A, B, C, D, E and F stand in a row. (a) Count arrangements where A and B are together. (b) Count arrangements where A and B are not together. (c) Explain why part (b) can be found by complementing the answer to part (a) from the unrestricted total.',
 'Шесть разных людей A, B, C, D, E и F становятся в ряд. (a) Найдите число перестановок, где A и B стоят рядом. (b) Найдите число перестановок, где A и B не стоят рядом. (c) Объясните, почему в (b) можно вычесть ответ (a) из общего числа перестановок.',
 'A, B, C, D, E va F ismli 6 ta turli odam qatorga turadi. (a) A va B yonma-yon bo‘lgan joylashuvlar sonini toping. (b) A va B yonma-yon bo‘lmagan joylashuvlar sonini toping. (c) Nima uchun (b) da (a) javobini barcha joylashuvlardan ayirish mumkinligini tushuntiring.',
 '{"max_marks":10,"criteria":[{"id":"block_model","marks":3,"rule":"Treats AB as one unit, uses 5!×2 and obtains 240."},{"id":"total","marks":2,"rule":"Uses unrestricted total 6!=720."},{"id":"apart","marks":2,"rule":"Obtains 720−240=480."},{"id":"reasoning","marks":3,"rule":"Explains together/apart are disjoint exhaustive cases for the same unrestricted sample of arrangements."}]}',
 'For “together”, make one block and remember its internal order. For “not together”, compare the valid together cases with all 6! arrangements.',
 'Для условия «вместе» создайте один блок и учтите внутренний порядок. Для «не рядом» сравните случаи «вместе» со всеми 6! перестановками.',
 '“Birga” sharti uchun bitta blok tuzing va blok ichidagi tartibni unutmang. “Yonma-yon emas” uchun birga holatlarini barcha 6! joylashuvlar bilan solishtiring.'),
('P5PRO01-W01','P5-PRO-01',
 'A fair coin is tossed and then a fair four-sided spinner labelled 1,2,3,4 is spun. (a) Write the complete ordered sample space. (b) State why its eight outcomes are equiprobable. (c) Define event E = “tail and an even number” and list the outcomes in E.',
 'Подбрасывают честную монету, затем вращают честный четырёхсекторный спиннер с числами 1,2,3,4. (a) Запишите полное упорядоченное пространство исходов. (b) Объясните, почему восемь исходов равновероятны. (c) Определите событие E = «решка и чётное число» и перечислите его исходы.',
 'Adolatli tanga tashlanadi, so‘ng 1,2,3,4 bilan belgilangan adolatli to‘rt qismli spinner aylantiriladi. (a) To‘liq tartiblangan natijalar fazosini yozing. (b) Nima uchun sakkiz natija teng ehtimolli ekanini ayting. (c) E = “gerb emas va juft son” hodisasini aniqlab, E dagi natijalarni sanang.',
 '{"max_marks":10,"criteria":[{"id":"sample_space","marks":4,"rule":"Lists H1,H2,H3,H4,T1,T2,T3,T4 exactly once."},{"id":"completeness","marks":2,"rule":"Connects 2 coin outcomes × 4 spinner outcomes = 8."},{"id":"equiprobable","marks":2,"rule":"Explains both devices are fair and independent product outcomes have equal probability 1/8."},{"id":"event","marks":2,"rule":"Lists E={T2,T4}."}]}',
 'Use a two-row table or Cartesian product so that every coin result is paired with every spinner result exactly once.',
 'Используйте таблицу из двух строк или декартово произведение, чтобы каждый результат монеты был соединён с каждым числом ровно один раз.',
 'Har bir tanga natijasini har bir spinner natijasi bilan aynan bir marta juftlash uchun ikki qatorli jadval yoki Dekart ko‘paytmasidan foydalaning.'),
('P5PRO03-W01','P5-PRO-03',
 'In a group, P(A)=0.55, P(B)=0.40 and P(A∩B)=0.20. (a) Find P(A∪B). (b) Find P(neither A nor B). (c) If a separate pair of events C and D are mutually exclusive with P(C)=0.25 and P(D)=0.35, find P(C∪D). For each part, state the probability rule used.',
 'В группе P(A)=0.55, P(B)=0.40 и P(A∩B)=0.20. (a) Найдите P(A∪B). (b) Найдите вероятность «ни A, ни B». (c) Для другой пары несовместных событий C и D: P(C)=0.25, P(D)=0.35. Найдите P(C∪D). Для каждой части укажите используемое правило.',
 'Guruhda P(A)=0.55, P(B)=0.40 va P(A∩B)=0.20. (a) P(A∪B) ni toping. (b) A ham emas, B ham emas ehtimolini toping. (c) Alohida C va D o‘zaro istisno hodisalari uchun P(C)=0.25, P(D)=0.35. P(C∪D) ni toping. Har bir qismda ishlatilgan ehtimollik qoidasini ayting.',
 '{"max_marks":10,"criteria":[{"id":"general_addition","marks":3,"rule":"Uses 0.55+0.40−0.20=0.75."},{"id":"complement","marks":2,"rule":"Uses 1−0.75=0.25 for neither."},{"id":"exclusive_addition","marks":2,"rule":"Uses 0.25+0.35=0.60 because intersection is zero."},{"id":"rule_language","marks":3,"rule":"Clearly distinguishes general addition, complement, and mutually exclusive special case."}]}',
 'Write the general union formula first. Then use complement for “neither”. Only remove the intersection term when mutual exclusivity is explicitly given.',
 'Сначала запишите общую формулу объединения. Затем используйте дополнение для «ни одно». Убирайте член пересечения только при явной несовместности.',
 'Avval umumiy birlashma formulasini yozing. Keyin “hech biri” uchun to‘ldiruvchidan foydalaning. Kesishma hadini faqat o‘zaro istisnolik aniq berilganda olib tashlang.')
)
insert into private.exam_prep_written_tasks(content_version_id,task_key,component_code,primary_skill_code,task_version,prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at)
select cv.id,d.task_key,'P5',d.skill,'wtv1',d.en,d.ru,d.uz,d.rubric::jsonb,d.sen,d.sru,d.suz,'approved','pass','pass','pass','pass',now()
from defs d cross join cv
on conflict(content_version_id,task_key,task_version) do nothing;

with cv as (select id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1' and status='draft'),
defs(k,t,en,ru,uz) as (values
('p5_e2_count_prob_diagnostic','diagnostic','P5 E2 counting/probability diagnostic','Диагностика P5 E2: комбинаторика и вероятность','P5 E2 sanash/ehtimollik diagnostikasi'),
('p5_cnt01_learning','learning','Counting model selection learning','Выбор модели подсчёта: обучение','Sanash modelini tanlash: o‘rganish'),
('p5_cnt02_learning','learning','Distinct permutations learning','Перестановки различных объектов: обучение','Turli obyektlar permutatsiyasi: o‘rganish'),
('p5_cnt03_learning','learning','Repeated-object arrangements learning','Перестановки с повторениями: обучение','Takrorli joylashuvlar: o‘rganish'),
('p5_cnt04_learning','learning','Restricted arrangements learning','Перестановки с ограничениями: обучение','Cheklangan joylashuvlar: o‘rganish'),
('p5_pro01_learning','learning','Sample-space construction learning','Построение пространства исходов: обучение','Natijalar fazosini tuzish: o‘rganish'),
('p5_pro03_learning','learning','Addition/complement rules learning','Правила сложения и дополнения: обучение','Qo‘shish/to‘ldiruvchi qoidalari: o‘rganish'),
('p5_cnt01_retest','retest','Counting model selection delayed retest','Отложенный ретест: выбор модели подсчёта','Kechiktirilgan qayta test: sanash modeli'),
('p5_cnt02_retest','retest','Distinct permutations delayed retest','Отложенный ретест: перестановки','Kechiktirilgan qayta test: permutatsiyalar'),
('p5_cnt03_retest','retest','Repeated arrangements delayed retest','Отложенный ретест: повторения','Kechiktirilgan qayta test: takrorlar'),
('p5_cnt04_retest','retest','Restricted arrangements delayed retest','Отложенный ретест: ограничения','Kechiktirilgan qayta test: cheklovlar'),
('p5_pro01_retest','retest','Sample-space delayed retest','Отложенный ретест: пространство исходов','Kechiktirilgan qayta test: natijalar fazosi'),
('p5_pro03_retest','retest','Probability rules delayed retest','Отложенный ретест: правила вероятности','Kechiktirilgan qayta test: ehtimollik qoidalari'),
('p5_e2_count_prob_mixed','mixed','P5 E2 counting/probability mixed transfer','Смешанный перенос P5 E2: комбинаторика и вероятность','P5 E2 sanash/ehtimollik aralash transfer')
)
insert into private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz)
select cv.id,d.k,'av1','P5',d.t,'approved',d.en,d.ru,d.uz from defs d cross join cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (select id,content_version from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1'),
a as (select x.id,x.assessment_key,cv.content_version from private.exam_prep_assessments x join cv on cv.id=x.content_version_id),
m as (select x.content_key,x.question_id,x.primary_skill_code,cv.content_version from private.exam_prep_question_content_meta x join cv on cv.id=x.content_version_id),
w as (select x.id,x.task_key,x.primary_skill_code,cv.content_version from private.exam_prep_written_tasks x join cv on cv.id=x.content_version_id),
items(akey,ord,ckey,wkey,skill,role,holdout) as (values
('p5_e2_count_prob_diagnostic',1,'P5CNT01-D01',null,'P5-CNT-01','diagnostic',true),('p5_e2_count_prob_diagnostic',2,'P5CNT02-D01',null,'P5-CNT-02','diagnostic',true),('p5_e2_count_prob_diagnostic',3,'P5CNT03-D01',null,'P5-CNT-03','diagnostic',true),('p5_e2_count_prob_diagnostic',4,'P5CNT04-D01',null,'P5-CNT-04','diagnostic',true),('p5_e2_count_prob_diagnostic',5,'P5PRO01-D01',null,'P5-PRO-01','diagnostic',true),('p5_e2_count_prob_diagnostic',6,'P5PRO03-D01',null,'P5-PRO-03','diagnostic',true),
('p5_cnt01_learning',1,'P5CNT01-L01',null,'P5-CNT-01','learning',false),('p5_cnt01_learning',2,'P5CNT01-L02',null,'P5-CNT-01','learning',false),('p5_cnt01_learning',3,'P5CNT01-L03',null,'P5-CNT-01','learning',false),('p5_cnt01_learning',4,null,'P5CNT01-W01','P5-CNT-01','written',false),
('p5_cnt02_learning',1,'P5CNT02-L01',null,'P5-CNT-02','learning',false),('p5_cnt02_learning',2,'P5CNT02-L02',null,'P5-CNT-02','learning',false),('p5_cnt02_learning',3,'P5CNT02-L03',null,'P5-CNT-02','learning',false),('p5_cnt02_learning',4,null,'P5CNT02-W01','P5-CNT-02','written',false),
('p5_cnt03_learning',1,'P5CNT03-L01',null,'P5-CNT-03','learning',false),('p5_cnt03_learning',2,'P5CNT03-L02',null,'P5-CNT-03','learning',false),('p5_cnt03_learning',3,'P5CNT03-L03',null,'P5-CNT-03','learning',false),('p5_cnt03_learning',4,null,'P5CNT03-W01','P5-CNT-03','written',false),
('p5_cnt04_learning',1,'P5CNT04-L01',null,'P5-CNT-04','learning',false),('p5_cnt04_learning',2,'P5CNT04-L02',null,'P5-CNT-04','learning',false),('p5_cnt04_learning',3,'P5CNT04-L03',null,'P5-CNT-04','learning',false),('p5_cnt04_learning',4,null,'P5CNT04-W01','P5-CNT-04','written',false),
('p5_pro01_learning',1,'P5PRO01-L01',null,'P5-PRO-01','learning',false),('p5_pro01_learning',2,'P5PRO01-L02',null,'P5-PRO-01','learning',false),('p5_pro01_learning',3,'P5PRO01-L03',null,'P5-PRO-01','learning',false),('p5_pro01_learning',4,null,'P5PRO01-W01','P5-PRO-01','written',false),
('p5_pro03_learning',1,'P5PRO03-L01',null,'P5-PRO-03','learning',false),('p5_pro03_learning',2,'P5PRO03-L02',null,'P5-PRO-03','learning',false),('p5_pro03_learning',3,'P5PRO03-L03',null,'P5-PRO-03','learning',false),('p5_pro03_learning',4,null,'P5PRO03-W01','P5-PRO-03','written',false),
('p5_cnt01_retest',1,'P5CNT01-R01',null,'P5-CNT-01','retest',true),('p5_cnt02_retest',1,'P5CNT02-R01',null,'P5-CNT-02','retest',true),('p5_cnt03_retest',1,'P5CNT03-R01',null,'P5-CNT-03','retest',true),('p5_cnt04_retest',1,'P5CNT04-R01',null,'P5-CNT-04','retest',true),('p5_pro01_retest',1,'P5PRO01-R01',null,'P5-PRO-01','retest',true),('p5_pro03_retest',1,'P5PRO03-R01',null,'P5-PRO-03','retest',true),
('p5_e2_count_prob_mixed',1,'P5CNT01-M01',null,'P5-CNT-01','mixed',true),('p5_e2_count_prob_mixed',2,'P5CNT02-M01',null,'P5-CNT-02','mixed',true),('p5_e2_count_prob_mixed',3,'P5CNT03-M01',null,'P5-CNT-03','mixed',true),('p5_e2_count_prob_mixed',4,'P5CNT04-M01',null,'P5-CNT-04','mixed',true),('p5_e2_count_prob_mixed',5,'P5PRO01-M01',null,'P5-PRO-01','mixed',true),('p5_e2_count_prob_mixed',6,'P5PRO03-M01',null,'P5-PRO-03','mixed',true)
)
insert into private.exam_prep_assessment_items(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout)
select a.id,i.ord,m.question_id,w.id,i.skill,i.role,i.holdout from items i join a on a.assessment_key=i.akey left join m on m.content_key=i.ckey left join w on w.task_key=i.wkey
on conflict(assessment_id,item_order) do nothing;

do $$ declare v_id bigint; v_bad int; begin
  select id into v_id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1';
  if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_id)<>6 then raise exception 'P1-02 P5 E2 expected 6 written tasks'; end if;
  if (select count(*) from private.exam_prep_assessments where content_version_id=v_id)<>14 then raise exception 'P1-02 P5 E2 expected 14 assessments'; end if;
  select count(*) into v_bad from private.exam_prep_assessments a where a.content_version_id=v_id and a.assessment_type='learning' and ((select count(*) from private.exam_prep_assessment_items i where i.assessment_id=a.id and i.question_id is not null and i.reserve_role='learning')<>3 or (select count(*) from private.exam_prep_assessment_items i where i.assessment_id=a.id and i.written_task_id is not null and i.reserve_role='written')<>1);
  if v_bad<>0 then raise exception 'P1-02 P5 E2 learning assessment contract failed for % assessments',v_bad; end if;
  if (select count(*) from private.exam_prep_question_content_meta m where m.content_version_id=v_id and m.reserve_role='retest' and not exists(select 1 from private.exam_prep_assessment_items i where i.question_id=m.question_id))<>6 then raise exception 'P1-02 P5 E2 expected 6 isolated R02 holdouts'; end if;
end $$;
commit;
