-- P1-02 E2 coordinate/circular/trig: written evidence + governed assessment memberships.
-- Core supports self-review; higher-level Mentor verification remains separate.

begin;
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_e2_coordinate_circular_trig_v1' and component_code='P1' and status='draft'
), defs(task_key,skill,en,ru,uz,rubric,sen,sru,suz) as (values
('P1COO01-W01','P1-COO-01',
 'Find the equation of the line through A(−3,4) and B(5,−2). Give your answer first as y=mx+c and then as ax+by+c=0 with integer coefficients. Verify both points in your final equation.',
 'Найдите уравнение прямой через A(−3,4) и B(5,−2). Сначала запишите его как y=mx+c, затем как ax+by+c=0 с целыми коэффициентами. Проверьте обе точки.',
 'A(−3,4) va B(5,−2) nuqtalardan o‘tuvchi chiziq tenglamasini toping. Avval y=mx+c, keyin butun koeffitsiyentli ax+by+c=0 ko‘rinishida yozing. Ikkala nuqtani tekshiring.',
 '{"max_marks":8,"criteria":[{"id":"gradient","marks":2,"rule":"Obtains m=(-2-4)/(5-(-3))=-3/4."},{"id":"line","marks":2,"rule":"Obtains y=-3x/4+7/4 or equivalent."},{"id":"standard","marks":2,"rule":"Gives 3x+4y-7=0 or equivalent integer multiple."},{"id":"verification","marks":2,"rule":"Substitutes both A and B successfully."}]}',
 'Check the gradient from both points, then substitute one point to find the intercept. Expand your standard form back and verify both endpoints.',
 'Проверьте градиент по двум точкам, затем найдите свободный член. После преобразования проверьте обе точки.',
 'Ikki nuqtadan gradientni tekshiring, keyin ozod hadni toping. Standart ko‘rinishni ochib, ikkala nuqtani tekshiring.'),
('P1COO02-W01','P1-COO-02',
 'Points A(−2,1) and B(6,5) are given. (a) Find the midpoint M of AB. (b) Find the length AB in exact form. (c) The line through M with gradient −1 meets the y-axis at C. Find C.',
 'Даны точки A(−2,1) и B(6,5). (a) Найдите середину M. (b) Найдите длину AB в точной форме. (c) Прямая через M с градиентом −1 пересекает ось y в C. Найдите C.',
 'A(−2,1) va B(6,5) berilgan. (a) AB ning o‘rta nuqtasi M ni toping. (b) AB uzunligini aniq ko‘rinishda toping. (c) M orqali gradienti −1 bo‘lgan chiziq y o‘qini C da kesadi. C ni toping.',
 '{"max_marks":8,"criteria":[{"id":"midpoint","marks":2,"rule":"Gets M=(2,3)."},{"id":"distance","marks":3,"rule":"Gets sqrt(8^2+4^2)=4sqrt5 with coherent working."},{"id":"line","marks":2,"rule":"Uses y-3=-(x-2), hence y=-x+5."},{"id":"intercept","marks":1,"rule":"States C=(0,5)."}]}',
 'Keep midpoint and distance formulas separate. For part (c), use M in point-gradient form and set x=0 for the y-axis.',
 'Не смешивайте формулы середины и расстояния. В (c) используйте точку M и затем положите x=0.',
 'O‘rta nuqta va masofa formulalarini aralashtirmang. (c) da M nuqtadan foydalanib, y o‘qi uchun x=0 qiling.'),
('P1COO03-W01','P1-COO-03',
 'Line L passes through (−1,2) and (3,10). Point P is (4,−2). Find the equation of the line through P perpendicular to L. Explain explicitly how the gradient condition proves perpendicularity.',
 'Прямая L проходит через (−1,2) и (3,10). Точка P=(4,−2). Найдите уравнение прямой через P, перпендикулярной L. Явно объясните условие на градиенты.',
 'L chiziq (−1,2) va (3,10) orqali o‘tadi. P=(4,−2). P orqali L ga perpendikulyar chiziq tenglamasini toping va gradient sharti perpendikulyarlikni qanday isbotlashini tushuntiring.',
 '{"max_marks":7,"criteria":[{"id":"gradient_L","marks":2,"rule":"Finds gradient of L as 2."},{"id":"perp_gradient","marks":2,"rule":"Uses negative reciprocal -1/2 and states product -1."},{"id":"equation","marks":2,"rule":"Obtains y+2=-(1/2)(x-4), hence y=-x/2."},{"id":"reasoning","marks":1,"rule":"Connects m1*m2=-1 to perpendicularity."}]}',
 'Verify the two gradients multiply to −1. Then check that P satisfies your final equation.',
 'Проверьте, что произведение градиентов равно −1, и что P удовлетворяет итоговому уравнению.',
 'Ikki gradient ko‘paytmasi −1 ekanini va P yakuniy tenglamani qanoatlantirishini tekshiring.'),
('P1CIR01-W01','P1-CIR-01',
 'An angle is 210°. (a) Convert it to radians in exact form. (b) A second angle is 5π/9 radians; convert it to degrees. (c) Explain why multiplying degrees by π/180 and radians by 180/π are inverse operations.',
 'Угол равен 210°. (a) Переведите его в радианы. (b) Второй угол равен 5π/9 радиан; переведите его в градусы. (c) Объясните, почему множители π/180 и 180/π взаимно обратны.',
 'Burchak 210°. (a) Uni aniq radian ko‘rinishiga o‘tkazing. (b) Ikkinchi burchak 5π/9 radian; uni gradusga o‘tkazing. (c) Nima uchun π/180 va 180/π ko‘paytuvchilar teskari amallar ekanini tushuntiring.',
 '{"max_marks":7,"criteria":[{"id":"deg_to_rad","marks":2,"rule":"Gets 210*pi/180=7pi/6."},{"id":"rad_to_deg","marks":2,"rule":"Gets (5pi/9)(180/pi)=100 degrees."},{"id":"reasoning","marks":2,"rule":"Uses 180 degrees=pi radians and identifies reciprocal conversion factors."},{"id":"communication","marks":1,"rule":"Keeps degree/radian units explicit."}]}',
 'Use 180°=π radians as the common reference. Check that applying one conversion then the other returns the starting value.',
 'Используйте 180°=π радиан как опорное равенство. Проверьте обратимость преобразований.',
 '180°=π radian tengligini asos sifatida ishlating. Bir o‘girishdan keyin teskarisini qo‘llab boshlang‘ich qiymat qaytishini tekshiring.'),
('P1TRI01-W01','P1-TRI-01',
 'Sketch y=2sin x−1 for 0≤x≤2π. Mark the midline, maximum, minimum, zeros where exact values are simple, and the five standard x-positions 0, π/2, π, 3π/2, 2π. Then compare its amplitude and vertical shift with y=sin x.',
 'Постройте эскиз y=2sin x−1 на 0≤x≤2π. Отметьте среднюю линию, максимум, минимум, нули где их удобно задать точно, и стандартные x: 0, π/2, π, 3π/2, 2π. Сравните амплитуду и вертикальный сдвиг с y=sin x.',
 '0≤x≤2π da y=2sin x−1 grafigini chizing. O‘rta chiziq, maksimum, minimum, aniq topish mumkin bo‘lgan nollar va 0, π/2, π, 3π/2, 2π standart x nuqtalarni belgilang. Amplituda va vertikal siljishni y=sin x bilan taqqoslang.',
 '{"max_marks":10,"criteria":[{"id":"key_points","marks":4,"rule":"Plots/identifies (0,-1),(pi/2,1),(pi,-1),(3pi/2,-3),(2pi,-1)."},{"id":"features","marks":3,"rule":"Marks midline y=-1, max 1, min -3, amplitude 2."},{"id":"shape","marks":2,"rule":"Produces coherent sine shape over one 2pi period with labelled scale."},{"id":"comparison","marks":1,"rule":"States vertical stretch factor 2 and downward translation 1."}]}',
 'Check all five standard sine positions before joining the curve. The midline is the vertical shift, and the amplitude is half the max-min range.',
 'Сначала проверьте пять стандартных положений. Средняя линия задаётся вертикальным сдвигом, амплитуда — половина диапазона max-min.',
 'Avval beshta standart sine nuqtani tekshiring. O‘rta chiziq vertikal siljish, amplituda esa max-min oralig‘ining yarmi.' )
)
insert into private.exam_prep_written_tasks(content_version_id,task_key,component_code,primary_skill_code,task_version,prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at)
select cv.id,d.task_key,'P1',d.skill,'wtv1',d.en,d.ru,d.uz,d.rubric::jsonb,d.sen,d.sru,d.suz,'approved','pass','pass','pass','pass',now()
from defs d cross join cv
on conflict(content_version_id,task_key,task_version) do nothing;

with cv as (select id from private.exam_prep_content_versions where content_version='p1_e2_coordinate_circular_trig_v1' and status='draft'),
defs(k,t,en,ru,uz) as (values
('p1_e2_coord_circ_trig_diagnostic','diagnostic','P1 E2 coordinate/circular/trig diagnostic','Диагностика P1 E2: координаты, радианы, тригонометрия','P1 E2 koordinata/radian/trigonometriya diagnostikasi'),
('p1_coo01_learning','learning','Straight-line equations learning','Уравнения прямой: обучение','To‘g‘ri chiziq tenglamalari: o‘rganish'),
('p1_coo02_learning','learning','Coordinate measures learning','Координатные величины: обучение','Koordinata o‘lchovlari: o‘rganish'),
('p1_coo03_learning','learning','Parallel/perpendicular learning','Параллельность и перпендикулярность: обучение','Parallel/perpendikulyar: o‘rganish'),
('p1_cir01_learning','learning','Radian conversion learning','Радианная мера: обучение','Radian o‘lchovi: o‘rganish'),
('p1_tri01_learning','learning','Trig graphs learning','Тригонометрические графики: обучение','Trigonometrik grafiklar: o‘rganish'),
('p1_coo01_retest','retest','Straight-line equations delayed retest','Отложенный ретест: уравнения прямой','Kechiktirilgan qayta test: chiziq tenglamalari'),
('p1_coo02_retest','retest','Coordinate measures delayed retest','Отложенный ретест: координаты','Kechiktirilgan qayta test: koordinatalar'),
('p1_coo03_retest','retest','Parallel/perpendicular delayed retest','Отложенный ретест: параллельность','Kechiktirilgan qayta test: parallel/perpendikulyar'),
('p1_cir01_retest','retest','Radian conversion delayed retest','Отложенный ретест: радианы','Kechiktirilgan qayta test: radianlar'),
('p1_tri01_retest','retest','Trig graphs delayed retest','Отложенный ретест: тригонометрия','Kechiktirilgan qayta test: trigonometriya'),
('p1_e2_coord_circ_trig_mixed','mixed','P1 E2 coordinate/circular/trig mixed transfer','Смешанный перенос P1 E2','P1 E2 aralash transfer')
)
insert into private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz)
select cv.id,d.k,'av1','P1',d.t,'approved',d.en,d.ru,d.uz from defs d cross join cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (select id,content_version from private.exam_prep_content_versions where content_version='p1_e2_coordinate_circular_trig_v1'),
a as (select x.id,x.assessment_key,cv.content_version from private.exam_prep_assessments x join cv on cv.id=x.content_version_id),
m as (select x.content_key,x.question_id,x.primary_skill_code,cv.content_version from private.exam_prep_question_content_meta x join cv on cv.id=x.content_version_id),
w as (select x.id,x.task_key,x.primary_skill_code,cv.content_version from private.exam_prep_written_tasks x join cv on cv.id=x.content_version_id),
items(akey,ord,ckey,wkey,skill,role,holdout) as (values
('p1_e2_coord_circ_trig_diagnostic',1,'P1COO01-D01',null,'P1-COO-01','diagnostic',true),('p1_e2_coord_circ_trig_diagnostic',2,'P1COO02-D01',null,'P1-COO-02','diagnostic',true),('p1_e2_coord_circ_trig_diagnostic',3,'P1COO03-D01',null,'P1-COO-03','diagnostic',true),('p1_e2_coord_circ_trig_diagnostic',4,'P1CIR01-D01',null,'P1-CIR-01','diagnostic',true),('p1_e2_coord_circ_trig_diagnostic',5,'P1TRI01-D01',null,'P1-TRI-01','diagnostic',true),
('p1_coo01_learning',1,'P1COO01-L01',null,'P1-COO-01','learning',false),('p1_coo01_learning',2,'P1COO01-L02',null,'P1-COO-01','learning',false),('p1_coo01_learning',3,'P1COO01-L03',null,'P1-COO-01','learning',false),('p1_coo01_learning',4,null,'P1COO01-W01','P1-COO-01','written',false),
('p1_coo02_learning',1,'P1COO02-L01',null,'P1-COO-02','learning',false),('p1_coo02_learning',2,'P1COO02-L02',null,'P1-COO-02','learning',false),('p1_coo02_learning',3,'P1COO02-L03',null,'P1-COO-02','learning',false),('p1_coo02_learning',4,null,'P1COO02-W01','P1-COO-02','written',false),
('p1_coo03_learning',1,'P1COO03-L01',null,'P1-COO-03','learning',false),('p1_coo03_learning',2,'P1COO03-L02',null,'P1-COO-03','learning',false),('p1_coo03_learning',3,'P1COO03-L03',null,'P1-COO-03','learning',false),('p1_coo03_learning',4,null,'P1COO03-W01','P1-COO-03','written',false),
('p1_cir01_learning',1,'P1CIR01-L01',null,'P1-CIR-01','learning',false),('p1_cir01_learning',2,'P1CIR01-L02',null,'P1-CIR-01','learning',false),('p1_cir01_learning',3,'P1CIR01-L03',null,'P1-CIR-01','learning',false),('p1_cir01_learning',4,null,'P1CIR01-W01','P1-CIR-01','written',false),
('p1_tri01_learning',1,'P1TRI01-L01',null,'P1-TRI-01','learning',false),('p1_tri01_learning',2,'P1TRI01-L02',null,'P1-TRI-01','learning',false),('p1_tri01_learning',3,'P1TRI01-L03',null,'P1-TRI-01','learning',false),('p1_tri01_learning',4,null,'P1TRI01-W01','P1-TRI-01','written',false),
('p1_coo01_retest',1,'P1COO01-R01',null,'P1-COO-01','retest',true),('p1_coo02_retest',1,'P1COO02-R01',null,'P1-COO-02','retest',true),('p1_coo03_retest',1,'P1COO03-R01',null,'P1-COO-03','retest',true),('p1_cir01_retest',1,'P1CIR01-R01',null,'P1-CIR-01','retest',true),('p1_tri01_retest',1,'P1TRI01-R01',null,'P1-TRI-01','retest',true),
('p1_e2_coord_circ_trig_mixed',1,'P1COO01-M01',null,'P1-COO-01','mixed',true),('p1_e2_coord_circ_trig_mixed',2,'P1COO02-M01',null,'P1-COO-02','mixed',true),('p1_e2_coord_circ_trig_mixed',3,'P1COO03-M01',null,'P1-COO-03','mixed',true),('p1_e2_coord_circ_trig_mixed',4,'P1CIR01-M01',null,'P1-CIR-01','mixed',true),('p1_e2_coord_circ_trig_mixed',5,'P1TRI01-M01',null,'P1-TRI-01','mixed',true)
)
insert into private.exam_prep_assessment_items(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout)
select a.id,i.ord,m.question_id,w.id,i.skill,i.role,i.holdout from items i join a on a.assessment_key=i.akey left join m on m.content_key=i.ckey left join w on w.task_key=i.wkey
on conflict(assessment_id,item_order) do nothing;

do $$ declare v_id bigint; v_bad int; begin
  select id into v_id from private.exam_prep_content_versions where content_version='p1_e2_coordinate_circular_trig_v1';
  if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_id)<>5 then raise exception 'P1-02 E2 coord/circ/trig expected 5 written tasks'; end if;
  if (select count(*) from private.exam_prep_assessments where content_version_id=v_id)<>12 then raise exception 'P1-02 E2 coord/circ/trig expected 12 assessments'; end if;
  select count(*) into v_bad from private.exam_prep_assessments a where a.content_version_id=v_id and a.assessment_type='learning' and ((select count(*) from private.exam_prep_assessment_items i where i.assessment_id=a.id and i.question_id is not null and i.reserve_role='learning')<>3 or (select count(*) from private.exam_prep_assessment_items i where i.assessment_id=a.id and i.written_task_id is not null and i.reserve_role='written')<>1);
  if v_bad<>0 then raise exception 'P1-02 E2 coord/circ/trig learning assessment contract failed for % assessments',v_bad; end if;
  if (select count(*) from private.exam_prep_question_content_meta m where m.content_version_id=v_id and m.reserve_role='retest' and not exists(select 1 from private.exam_prep_assessment_items i where i.question_id=m.question_id))<>5 then raise exception 'P1-02 E2 coord/circ/trig expected 5 isolated R02 holdouts'; end if;
end $$;
commit;
