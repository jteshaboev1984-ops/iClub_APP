-- P1-02 AW9-12 Functions: written evidence + governed assessment memberships.

begin;
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_aw09_12_functions_v1' and component_code='P1' and status='draft'
), defs(task_key,skill,en,ru,uz,rubric,sen,sru,suz) as (values
('P1FUN03-W01','P1-FUN-03',
'Let f(x)=1/(x−1) and g(x)=2x+3. (a) Find and simplify (f∘g)(x), stating its domain restriction. (b) Find and simplify (g∘f)(x), stating its domain restriction. (c) Explain why the two composites are not the same function.',
'Пусть f(x)=1/(x−1), g(x)=2x+3. (a) Найдите и упростите (f∘g)(x), указав ограничение области определения. (b) Найдите и упростите (g∘f)(x), указав ограничение области определения. (c) Объясните, почему две композиции не являются одной и той же функцией.',
'f(x)=1/(x−1), g(x)=2x+3 bo‘lsin. (a) (f∘g)(x) ni topib soddalashtiring va aniqlanish sohasi cheklovini yozing. (b) (g∘f)(x) ni topib soddalashtiring va soha cheklovini yozing. (c) Nega ikki kompozitsiya bir xil funksiya emasligini tushuntiring.',
'{"max_marks":10,"criteria":[{"id":"fg","marks":3,"rule":"Obtains (f∘g)(x)=1/(2x+2) with x≠−1."},{"id":"gf","marks":3,"rule":"Obtains (g∘f)(x)=(3x−1)/(x−1) or equivalent with x≠1."},{"id":"domains","marks":2,"rule":"Explains restrictions from forbidden inputs/denominators in the relevant composition."},{"id":"order","marks":2,"rule":"Explains composition order and concludes f∘g≠g∘f."}]}',
'For each composite, substitute the entire inner function into the outer one before simplifying. Determine the forbidden input from the unsimplified or simplified denominator, and keep the order f∘g versus g∘f explicit.',
'Для каждой композиции подставьте всю внутреннюю функцию во внешнюю до упрощения. Найдите запрещённый аргумент по знаменателю и явно различайте порядок f∘g и g∘f.',
'Har bir kompozitsiyada soddalashtirishdan oldin ichki funksiyaning butun ifodasini tashqi funksiyaga qo‘ying. Maxrajdan taqiqlangan kirishni toping va f∘g hamda g∘f tartibini aniq ajrating.'),
('P1FUN04-W01','P1-FUN-04',
'Let f(x)=(2x+1)/(x−3), x≠3. Derive f⁻¹(x) algebraically. State the domain restriction of the inverse and verify your result by showing that f(f⁻¹(x)) simplifies to x on the valid domain.',
'Пусть f(x)=(2x+1)/(x−3), x≠3. Алгебраически выведите f⁻¹(x). Укажите ограничение области определения обратной функции и проверьте результат, показав, что f(f⁻¹(x)) упрощается до x на допустимой области.',
'f(x)=(2x+1)/(x−3), x≠3 bo‘lsin. f⁻¹(x) ni algebraik usulda keltirib chiqaring. Teskari funksiyaning aniqlanish sohasi cheklovini yozing va f(f⁻¹(x)) yaroqli sohada x ga soddalashishini ko‘rsatib tekshiring.',
'{"max_marks":11,"criteria":[{"id":"swap_solve","marks":4,"rule":"From y=(2x+1)/(x−3), obtains x=(3y+1)/(y−2) and hence f⁻¹(x)=(3x+1)/(x−2)."},{"id":"domain","marks":2,"rule":"States inverse domain x≠2 and relates it to the original range."},{"id":"verification","marks":4,"rule":"Correctly substitutes the inverse into f and simplifies to x without illegal cancellation."},{"id":"notation","marks":1,"rule":"Uses inverse-function notation consistently and does not confuse it with reciprocal 1/f."}]}',
'Swap input and output only after writing y=f(x), then solve fully for the new output. The inverse denominator shows x≠2. In the composition check, preserve restrictions while simplifying.',
'Сначала запишите y=f(x), затем поменяйте вход и выход и полностью решите относительно нового выхода. Знаменатель обратной функции показывает x≠2. При проверке композиции сохраняйте ограничения.',
'Avval y=f(x) ni yozing, keyin kirish va chiqishni almashtirib yangi chiqish bo‘yicha to‘liq yeching. Teskari funksiya maxraji x≠2 ni ko‘rsatadi. Kompozitsiyani tekshirishda cheklovlarni saqlang.'),
('P1FUN05-W01','P1-FUN-05',
'A one-one function y=f(x) passes through A(−2,1), B(0,4) and C(3,5). (a) State the three corresponding points on y=f⁻¹(x). (b) Describe the single geometric transformation that maps the graph of f to the graph of f⁻¹. (c) Explain why any fixed point under this transformation must lie on y=x.',
'График взаимно однозначной функции y=f(x) проходит через A(−2,1), B(0,4), C(3,5). (a) Укажите три соответствующие точки на y=f⁻¹(x). (b) Назовите одно геометрическое преобразование, переводящее график f в график f⁻¹. (c) Объясните, почему любая неподвижная точка этого преобразования должна лежать на y=x.',
'Bir qiymatli y=f(x) funksiya grafigi A(−2,1), B(0,4), C(3,5) nuqtalardan o‘tadi. (a) y=f⁻¹(x) dagi uchta mos nuqtani yozing. (b) f grafigini f⁻¹ grafigiga o‘tkazadigan bitta geometrik o‘zgarishni ayting. (c) Nega bu o‘zgarishda joyida qoladigan har qanday nuqta y=x da yotishini tushuntiring.',
'{"max_marks":9,"criteria":[{"id":"points","marks":3,"rule":"Maps points to (1,−2), (4,0), (5,3)."},{"id":"reflection","marks":3,"rule":"States reflection in y=x and connects it to swapping coordinates."},{"id":"fixed","marks":3,"rule":"Explains a fixed point must satisfy (x,y)=(y,x), hence x=y and the point lies on y=x."}]}',
'Apply the same point rule to all three coordinates: (a,b)→(b,a). Then connect coordinate swapping to reflection in y=x; a point unchanged by swapping must have equal coordinates.',
'Для всех трёх точек используйте одно правило: (a,b)→(b,a). Свяжите перестановку координат с отражением относительно y=x; неподвижная точка должна иметь равные координаты.',
'Uchala nuqtaga ham bir xil qoida qo‘llang: (a,b)→(b,a). Koordinatalarni almashtirishni y=x ga nisbatan akslantirish bilan bog‘lang; o‘zgarmaydigan nuqtada koordinatalar teng bo‘lishi kerak.')
)
insert into private.exam_prep_written_tasks(content_version_id,task_key,component_code,primary_skill_code,task_version,prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at)
select cv.id,d.task_key,'P1',d.skill,'wtv1',d.en,d.ru,d.uz,d.rubric::jsonb,d.sen,d.sru,d.suz,'approved','pass','pass','pass','pass',now()
from defs d cross join cv
on conflict(content_version_id,task_key,task_version) do nothing;

with cv as (select id from private.exam_prep_content_versions where content_version='p1_aw09_12_functions_v1' and status='draft'), defs(k,t,en,ru,uz) as (values
('p1_aw09_12_functions_diagnostic','diagnostic','P1 AW9-12 functions diagnostic','Диагностика функций P1 AW9-12','P1 AW9-12 funksiyalar diagnostikasi'),
('p1_fun03_learning','learning','Composition and domains learning','Композиции и области: обучение','Kompozitsiya va sohalar: o‘rganish'),
('p1_fun04_learning','learning','Inverse functions learning','Обратные функции: обучение','Teskari funksiyalar: o‘rganish'),
('p1_fun05_learning','learning','Inverse graphs learning','Графики обратных функций: обучение','Teskari funksiya grafiklari: o‘rganish'),
('p1_fun03_retest','retest','Composition delayed retest','Отложенный ретест: композиции','Kechiktirilgan qayta test: kompozitsiyalar'),
('p1_fun04_retest','retest','Inverse-function delayed retest','Отложенный ретест: обратные функции','Kechiktirilgan qayta test: teskari funksiyalar'),
('p1_fun05_retest','retest','Inverse-graph delayed retest','Отложенный ретест: графики обратных функций','Kechiktirilgan qayta test: teskari grafiklar'),
('p1_aw09_12_functions_mixed','mixed','P1 AW9-12 functions mixed transfer','Смешанный перенос функций P1 AW9-12','P1 AW9-12 funksiyalar aralash transferi'))
insert into private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz)
select cv.id,d.k,'av1','P1',d.t,'approved',d.en,d.ru,d.uz from defs d cross join cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (select id,content_version from private.exam_prep_content_versions where content_version='p1_aw09_12_functions_v1'),
a as (select x.id,x.assessment_key from private.exam_prep_assessments x join cv on cv.id=x.content_version_id),
m as (select x.content_key,x.question_id from private.exam_prep_question_content_meta x join cv on cv.id=x.content_version_id),
w as (select x.id,x.task_key from private.exam_prep_written_tasks x join cv on cv.id=x.content_version_id),
items(akey,ord,ckey,wkey,skill,role,holdout) as (values
('p1_aw09_12_functions_diagnostic',1,'P1FUN03-D01',null,'P1-FUN-03','diagnostic',true),('p1_aw09_12_functions_diagnostic',2,'P1FUN04-D01',null,'P1-FUN-04','diagnostic',true),('p1_aw09_12_functions_diagnostic',3,'P1FUN05-D01',null,'P1-FUN-05','diagnostic',true),
('p1_fun03_learning',1,'P1FUN03-L01',null,'P1-FUN-03','learning',false),('p1_fun03_learning',2,'P1FUN03-L02',null,'P1-FUN-03','learning',false),('p1_fun03_learning',3,'P1FUN03-L03',null,'P1-FUN-03','learning',false),('p1_fun03_learning',4,null,'P1FUN03-W01','P1-FUN-03','written',false),
('p1_fun04_learning',1,'P1FUN04-L01',null,'P1-FUN-04','learning',false),('p1_fun04_learning',2,'P1FUN04-L02',null,'P1-FUN-04','learning',false),('p1_fun04_learning',3,'P1FUN04-L03',null,'P1-FUN-04','learning',false),('p1_fun04_learning',4,null,'P1FUN04-W01','P1-FUN-04','written',false),
('p1_fun05_learning',1,'P1FUN05-L01',null,'P1-FUN-05','learning',false),('p1_fun05_learning',2,'P1FUN05-L02',null,'P1-FUN-05','learning',false),('p1_fun05_learning',3,'P1FUN05-L03',null,'P1-FUN-05','learning',false),('p1_fun05_learning',4,null,'P1FUN05-W01','P1-FUN-05','written',false),
('p1_fun03_retest',1,'P1FUN03-R01',null,'P1-FUN-03','retest',true),('p1_fun04_retest',1,'P1FUN04-R01',null,'P1-FUN-04','retest',true),('p1_fun05_retest',1,'P1FUN05-R01',null,'P1-FUN-05','retest',true),
('p1_aw09_12_functions_mixed',1,'P1FUN03-M01',null,'P1-FUN-03','mixed',true),('p1_aw09_12_functions_mixed',2,'P1FUN04-M01',null,'P1-FUN-04','mixed',true),('p1_aw09_12_functions_mixed',3,'P1FUN05-M01',null,'P1-FUN-05','mixed',true))
insert into private.exam_prep_assessment_items(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout)
select a.id,i.ord,m.question_id,w.id,i.skill,i.role,i.holdout from items i join a on a.assessment_key=i.akey left join m on m.content_key=i.ckey left join w on w.task_key=i.wkey
on conflict(assessment_id,item_order) do nothing;

do $$ declare v_id bigint; v_bad int; begin
 select id into v_id from private.exam_prep_content_versions where content_version='p1_aw09_12_functions_v1';
 if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_id)<>3 then raise exception 'P1-02 AW9-12 functions assessments: expected 3 written tasks'; end if;
 if (select count(*) from private.exam_prep_assessments where content_version_id=v_id)<>8 then raise exception 'P1-02 AW9-12 functions assessments: expected 8 assessments'; end if;
 select count(*) into v_bad from private.exam_prep_assessments a where a.content_version_id=v_id and a.assessment_type='learning' and ((select count(*) from private.exam_prep_assessment_items i where i.assessment_id=a.id and i.question_id is not null and i.reserve_role='learning')<>3 or (select count(*) from private.exam_prep_assessment_items i where i.assessment_id=a.id and i.written_task_id is not null and i.reserve_role='written')<>1);
 if v_bad<>0 then raise exception 'P1-02 AW9-12 functions learning assessment contract failed for % assessments',v_bad; end if;
 if (select count(*) from private.exam_prep_question_content_meta m where m.content_version_id=v_id and m.reserve_role='retest' and not exists(select 1 from private.exam_prep_assessment_items i where i.question_id=m.question_id))<>3 then raise exception 'P1-02 AW9-12 functions assessments: expected 3 isolated R02 holdouts'; end if;
end $$;
commit;