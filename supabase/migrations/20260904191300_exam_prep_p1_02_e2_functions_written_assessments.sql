-- P1-02 E2 functions bridge: written evidence + governed assessment memberships.
-- Core supports self-review; Mentor verification remains a separate higher-level authority.

begin;
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_e2_functions_bridge_v1' and component_code='P1' and status='draft'
), defs(task_key,skill,en,ru,uz,rubric,sen,sru,suz) as (values
('P1FUN06-W01','P1-FUN-06',
'The graph of y=f(x) contains the points (−2,1), (0,4) and (3,−1). For g(x)=f(x−2)+3: (a) state the translation vector from f to g; (b) write the three corresponding points on g; (c) explain why the horizontal sign in f(x−2) gives a movement to the right.',
'График y=f(x) содержит точки (−2,1), (0,4) и (3,−1). Для g(x)=f(x−2)+3: (a) укажите вектор сдвига от f к g; (b) запишите три соответствующие точки на g; (c) объясните, почему знак в f(x−2) даёт сдвиг вправо.',
'y=f(x) grafigida (−2,1), (0,4) va (3,−1) nuqtalar bor. g(x)=f(x−2)+3 uchun: (a) f dan g ga siljish vektorini yozing; (b) g dagi uchta mos nuqtani yozing; (c) nima uchun f(x−2) ichidagi ishora o‘ngga siljishni berishini tushuntiring.',
'{"max_marks":8,"criteria":[{"id":"vector","marks":2,"rule":"States translation vector (2,3) or equivalent right 2/up 3."},{"id":"points","marks":3,"rule":"Maps the three points to (0,4), (2,7), (5,2)."},{"id":"reasoning","marks":3,"rule":"Explains horizontal input compensation coherently and distinguishes it from the outside vertical shift."}]}',
'Check that every x-coordinate increased by 2 and every y-coordinate increased by 3. Your explanation should distinguish an inside input change from an outside output change.',
'Проверьте, что каждая x-координата увеличилась на 2, а каждая y-координата — на 3. В объяснении разделите изменение аргумента внутри функции и изменение значения снаружи.',
'Har bir x-koordinata 2 ga, har bir y-koordinata 3 ga oshganini tekshiring. Izohda funksiya ichidagi argument o‘zgarishini tashqi chiqish o‘zgarishidan ajrating.'),
('P1FUN07-W01','P1-FUN-07',
'The graph of y=f(x) contains A(−3,2), B(1,−4) and C(5,1). (a) Reflect the graph in the y-axis and give the images of A, B and C. (b) Reflect the original graph in the x-axis and give the images again. (c) State the corresponding equations using f.',
'График y=f(x) содержит A(−3,2), B(1,−4) и C(5,1). (a) Отразите график относительно оси y и укажите образы A, B и C. (b) Отразите исходный график относительно оси x и снова укажите образы. (c) Запишите соответствующие уравнения через f.',
'y=f(x) grafigida A(−3,2), B(1,−4) va C(5,1) nuqtalar bor. (a) Grafikni y o‘qiga nisbatan akslantirib, A, B, C tasvirlarini yozing. (b) Asl grafikni x o‘qiga nisbatan akslantirib, tasvirlarni yozing. (c) f orqali mos tenglamalarni yozing.',
'{"max_marks":10,"criteria":[{"id":"y_axis_points","marks":3,"rule":"Gives (3,2), (−1,−4), (−5,1)."},{"id":"x_axis_points","marks":3,"rule":"Gives (−3,−2), (1,4), (5,−1)."},{"id":"equations","marks":2,"rule":"States y=f(−x) for y-axis and y=−f(x) for x-axis reflection."},{"id":"communication","marks":2,"rule":"Uses consistent coordinate notation and explains which coordinate changes sign."}]}',
'For a y-axis reflection only x changes sign; for an x-axis reflection only y changes sign. Verify all six mapped points against those two rules.',
'При отражении относительно оси y меняется только знак x; относительно оси x — только знак y. Проверьте все шесть точек по этим двум правилам.',
'y o‘qiga nisbatan akslantirishda faqat x ishorasi, x o‘qiga nisbatan esa faqat y ishorasi o‘zgaradi. Oltita nuqtaning barchasini shu ikki qoida bilan tekshiring.'),
('P1FUN08-W01','P1-FUN-08',
'The graph of y=f(x) contains P(6,−2) and Q(−3,4). Consider h(x)=2f(3x). (a) Describe the horizontal and vertical scale effects. (b) Find the images of P and Q on h. (c) Explain why the horizontal factor is the reciprocal of 3 rather than 3.',
'График y=f(x) содержит P(6,−2) и Q(−3,4). Рассмотрим h(x)=2f(3x). (a) Опишите горизонтальное и вертикальное масштабирование. (b) Найдите образы P и Q на h. (c) Объясните, почему горизонтальный коэффициент масштаба равен 1/3, а не 3.',
'y=f(x) grafigida P(6,−2) va Q(−3,4) nuqtalar bor. h(x)=2f(3x) ni ko‘ring. (a) Gorizontal va vertikal masshtab ta’sirini tasvirlang. (b) P va Q ning h dagi tasvirlarini toping. (c) Nima uchun gorizontal masshtab 3 emas, 1/3 ekanini tushuntiring.',
'{"max_marks":9,"criteria":[{"id":"scales","marks":3,"rule":"States horizontal compression factor 1/3 and vertical stretch factor 2."},{"id":"points","marks":4,"rule":"Maps P to (2,−4) and Q to (−1,8) with valid working."},{"id":"reasoning","marks":2,"rule":"Explains 3x=old input, hence new x is old x divided by 3."}]}',
'Check the point-map rule (a,b) → (a/3,2b). Do not apply the visible inside factor directly to x-coordinates.',
'Проверьте правило отображения (a,b) → (a/3,2b). Не умножайте x-координаты напрямую на видимый внутренний множитель.',
'(a,b) → (a/3,2b) nuqta qoidasini tekshiring. Ichkaridagi ko‘rinadigan ko‘paytuvchini x-koordinataga to‘g‘ridan-to‘g‘ri qo‘llamang.')
)
insert into private.exam_prep_written_tasks(
  content_version_id,task_key,component_code,primary_skill_code,task_version,
  prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
  lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select cv.id,d.task_key,'P1',d.skill,'wtv1',d.en,d.ru,d.uz,d.rubric::jsonb,d.sen,d.sru,d.suz,
       'approved','pass','pass','pass','pass',now()
from defs d cross join cv
on conflict(content_version_id,task_key,task_version) do nothing;

-- Assessment shells.
with cv as (
  select id from private.exam_prep_content_versions where content_version='p1_e2_functions_bridge_v1' and status='draft'
), defs(k,t,en,ru,uz) as (values
('p1_e2_functions_diagnostic','diagnostic','P1 E2 transformations diagnostic','Диагностика преобразований P1 E2','P1 E2 transformatsiyalar diagnostikasi'),
('p1_fun06_learning','learning','Translations learning','Сдвиги графиков: обучение','Grafik siljishlari: o‘rganish'),
('p1_fun07_learning','learning','Reflections learning','Отражения графиков: обучение','Grafik akslantirishlari: o‘rganish'),
('p1_fun08_learning','learning','Stretches and combinations learning','Растяжения и комбинации: обучение','Cho‘zishlar va kombinatsiyalar: o‘rganish'),
('p1_fun06_retest','retest','Translations delayed retest','Отложенный ретест: сдвиги','Kechiktirilgan qayta test: siljishlar'),
('p1_fun07_retest','retest','Reflections delayed retest','Отложенный ретест: отражения','Kechiktirilgan qayta test: akslantirishlar'),
('p1_fun08_retest','retest','Stretches delayed retest','Отложенный ретест: растяжения','Kechiktirilgan qayta test: cho‘zishlar'),
('p1_e2_functions_mixed','mixed','P1 E2 transformations mixed transfer','Смешанный перенос преобразований P1 E2','P1 E2 transformatsiyalar aralash transferi')
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
select cv.id,d.k,'av1','P1',d.t,'approved',d.en,d.ru,d.uz
from defs d cross join cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

-- Memberships. R02 per skill intentionally remains outside every assessment as unseen reserve.
with cv as (
  select id,content_version from private.exam_prep_content_versions where content_version='p1_e2_functions_bridge_v1'
), a as (
  select x.id,x.assessment_key,cv.content_version from private.exam_prep_assessments x join cv on cv.id=x.content_version_id
), m as (
  select x.content_key,x.question_id,x.primary_skill_code,cv.content_version from private.exam_prep_question_content_meta x join cv on cv.id=x.content_version_id
), w as (
  select x.id,x.task_key,x.primary_skill_code,cv.content_version from private.exam_prep_written_tasks x join cv on cv.id=x.content_version_id
), items(akey,ord,ckey,wkey,skill,role,holdout) as (values
('p1_e2_functions_diagnostic',1,'P1FUN06-D01',null,'P1-FUN-06','diagnostic',true),
('p1_e2_functions_diagnostic',2,'P1FUN07-D01',null,'P1-FUN-07','diagnostic',true),
('p1_e2_functions_diagnostic',3,'P1FUN08-D01',null,'P1-FUN-08','diagnostic',true),
('p1_fun06_learning',1,'P1FUN06-L01',null,'P1-FUN-06','learning',false),('p1_fun06_learning',2,'P1FUN06-L02',null,'P1-FUN-06','learning',false),('p1_fun06_learning',3,'P1FUN06-L03',null,'P1-FUN-06','learning',false),('p1_fun06_learning',4,null,'P1FUN06-W01','P1-FUN-06','written',false),
('p1_fun07_learning',1,'P1FUN07-L01',null,'P1-FUN-07','learning',false),('p1_fun07_learning',2,'P1FUN07-L02',null,'P1-FUN-07','learning',false),('p1_fun07_learning',3,'P1FUN07-L03',null,'P1-FUN-07','learning',false),('p1_fun07_learning',4,null,'P1FUN07-W01','P1-FUN-07','written',false),
('p1_fun08_learning',1,'P1FUN08-L01',null,'P1-FUN-08','learning',false),('p1_fun08_learning',2,'P1FUN08-L02',null,'P1-FUN-08','learning',false),('p1_fun08_learning',3,'P1FUN08-L03',null,'P1-FUN-08','learning',false),('p1_fun08_learning',4,null,'P1FUN08-W01','P1-FUN-08','written',false),
('p1_fun06_retest',1,'P1FUN06-R01',null,'P1-FUN-06','retest',true),
('p1_fun07_retest',1,'P1FUN07-R01',null,'P1-FUN-07','retest',true),
('p1_fun08_retest',1,'P1FUN08-R01',null,'P1-FUN-08','retest',true),
('p1_e2_functions_mixed',1,'P1FUN06-M01',null,'P1-FUN-06','mixed',true),
('p1_e2_functions_mixed',2,'P1FUN07-M01',null,'P1-FUN-07','mixed',true),
('p1_e2_functions_mixed',3,'P1FUN08-M01',null,'P1-FUN-08','mixed',true)
)
insert into private.exam_prep_assessment_items(
  assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select a.id,i.ord,m.question_id,w.id,i.skill,i.role,i.holdout
from items i
join a on a.assessment_key=i.akey
left join m on m.content_key=i.ckey
left join w on w.task_key=i.wkey
on conflict(assessment_id,item_order) do nothing;

do $$ declare v_id bigint; v_bad int; begin
  select id into v_id from private.exam_prep_content_versions where content_version='p1_e2_functions_bridge_v1';
  if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_id)<>3 then raise exception 'P1-02 E2 functions expected 3 written tasks'; end if;
  if (select count(*) from private.exam_prep_assessments where content_version_id=v_id)<>8 then raise exception 'P1-02 E2 functions expected 8 assessments'; end if;
  select count(*) into v_bad from private.exam_prep_assessments a where a.content_version_id=v_id and a.assessment_type='learning' and (
    (select count(*) from private.exam_prep_assessment_items i where i.assessment_id=a.id and i.question_id is not null and i.reserve_role='learning')<>3
    or (select count(*) from private.exam_prep_assessment_items i where i.assessment_id=a.id and i.written_task_id is not null and i.reserve_role='written')<>1
  );
  if v_bad<>0 then raise exception 'P1-02 E2 functions learning assessment contract failed for % assessments',v_bad; end if;
  if (select count(*) from private.exam_prep_question_content_meta m where m.content_version_id=v_id and m.reserve_role='retest' and not exists(select 1 from private.exam_prep_assessment_items i where i.question_id=m.question_id))<>3 then
    raise exception 'P1-02 E2 functions expected 3 isolated R02 holdouts';
  end if;
end $$;
commit;
