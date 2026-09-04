-- P1-02 AW9-12 Quadratics: written evidence + governed assessment memberships.
-- Core supports self-review; Mentor verification remains separate and optional.

begin;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_aw09_12_quadratics_v1' and component_code='P1' and status='draft'
), defs(task_key,skill,en,ru,uz,rubric,sen,sru,suz) as (values
('P1QUA04-W01','P1-QUA-04',
'Solve (x − 1)(x − 4) ≤ 0. Show the critical values, determine the sign on each interval, state the final interval using correct endpoint notation, and explain why the endpoints are included.',
'Решите (x − 1)(x − 4) ≤ 0. Покажите критические значения, определите знак на каждом промежутке, запишите итоговый промежуток с правильными границами и объясните, почему границы включаются.',
'(x − 1)(x − 4) ≤ 0 tengsizlikni yeching. Kritik qiymatlarni ko‘rsating, har bir oraliqdagi ishorani aniqlang, yakuniy oraliqni chegaralar bilan to‘g‘ri yozing va nega chegaralar kirishini tushuntiring.',
'{"max_marks":8,"criteria":[{"id":"critical","marks":2,"rule":"Identifies critical values x=1 and x=4."},{"id":"sign","marks":3,"rule":"Determines positive/negative regions correctly and selects the non-positive interval."},{"id":"interval","marks":1,"rule":"States 1≤x≤4."},{"id":"endpoints","marks":2,"rule":"Explains that equality is allowed and both roots make the expression zero."}]}',
'Check that the factors change sign only at 1 and 4, then test one value in each interval. Because the symbol is ≤, both zero points must be included.',
'Проверьте, что множители меняют знак только при 1 и 4, затем возьмите по одной проверочной точке на каждом промежутке. Так как знак ≤, обе точки, где выражение равно нулю, должны входить в ответ.',
'Ko‘paytuvchilar faqat 1 va 4 da ishora almashtirishini tekshiring, so‘ng har bir oraliqda bittadan qiymat sinang. Belgi ≤ bo‘lgani uchun ifoda nol bo‘ladigan ikkala nuqta ham javobga kiradi.'),
('P1QUA05-W01','P1-QUA-05',
'The line y = 2x + 1 meets the curve y = x² − x + 1. Find both intersection points. Show how equating the two expressions produces the quadratic equation, solve it, calculate both y-values, and verify each ordered pair in both equations.',
'Прямая y = 2x + 1 пересекает кривую y = x² − x + 1. Найдите обе точки пересечения. Покажите, как приравнивание выражений приводит к квадратному уравнению, решите его, найдите оба значения y и проверьте каждую пару координат в обоих уравнениях.',
'y = 2x + 1 to‘g‘ri chiziq y = x² − x + 1 egri chiziq bilan kesishadi. Ikkala kesishish nuqtasini toping. Ifodalarni tenglashtirish qanday kvadrat tenglama berishini ko‘rsating, uni yeching, ikkala y qiymatini toping va har bir koordinata juftligini ikkala tenglamada tekshiring.',
'{"max_marks":9,"criteria":[{"id":"equate","marks":2,"rule":"Forms x²−3x=0 from equal y-values."},{"id":"xvalues","marks":2,"rule":"Obtains x=0 and x=3."},{"id":"yvalues","marks":2,"rule":"Obtains y=1 and y=7."},{"id":"points","marks":1,"rule":"States intersections (0,1) and (3,7)."},{"id":"verification","marks":2,"rule":"Checks both points satisfy both original relations."}]}',
'Your final answer must be coordinate pairs, not only x-values. Substitute x=0 and x=3 into the line and the curve separately to confirm the same y-value each time.',
'Итоговый ответ должен содержать пары координат, а не только значения x. Подставьте x=0 и x=3 отдельно в прямую и кривую и убедитесь, что каждый раз получается одно и то же y.',
'Yakuniy javob faqat x qiymatlari emas, koordinata juftliklari bo‘lishi kerak. x=0 va x=3 ni to‘g‘ri chiziq va egri chiziqqa alohida qo‘yib, har safar bir xil y chiqishini tekshiring.'),
('P1QUA06-W01','P1-QUA-06',
'Solve x⁴ − 10x² + 9 = 0 over the real numbers. Introduce a substitution, solve the resulting quadratic, reverse the substitution without losing branches, list all distinct real roots, and verify the number of solutions.',
'Решите x⁴ − 10x² + 9 = 0 в действительных числах. Введите замену, решите полученное квадратное уравнение, выполните обратную замену без потери ветвей, перечислите все различные действительные корни и проверьте количество решений.',
'x⁴ − 10x² + 9 = 0 tenglamani haqiqiy sonlarda yeching. Almashtirish kiriting, hosil bo‘lgan kvadrat tenglamani yeching, tarmoqlarni yo‘qotmasdan teskari almashtiring, barcha turli haqiqiy ildizlarni yozing va yechimlar sonini tekshiring.',
'{"max_marks":10,"criteria":[{"id":"substitution","marks":2,"rule":"Sets u=x² and obtains u²−10u+9=0."},{"id":"uvalues","marks":2,"rule":"Solves to u=1 and u=9."},{"id":"backsolve","marks":3,"rule":"Solves x²=1 and x²=9 with both square-root branches."},{"id":"roots","marks":1,"rule":"States x=−3,−1,1,3."},{"id":"verification","marks":2,"rule":"Checks four distinct real roots and no branch was lost."}]}',
'Keep the temporary variable u separate from x. Each positive u-value from u=x² normally produces two real x-values, so check both signs before collecting distinct roots.',
'Не смешивайте временную переменную u с x. Каждое положительное значение u при u=x² обычно даёт два действительных значения x, поэтому проверьте оба знака перед записью всех различных корней.',
'Vaqtinchalik u o‘zgaruvchini x bilan aralashtirmang. u=x² dagi har bir musbat u qiymati odatda ikkita haqiqiy x beradi, shuning uchun barcha turli ildizlarni yig‘ishdan oldin ikkala ishorani tekshiring.')
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
  select id from private.exam_prep_content_versions
  where content_version='p1_aw09_12_quadratics_v1' and status='draft'
), defs(k,t,en,ru,uz) as (values
('p1_aw09_12_quadratics_diagnostic','diagnostic','P1 AW9-12 quadratics diagnostic','Диагностика квадратных тем P1 AW9-12','P1 AW9-12 kvadrat mavzular diagnostikasi'),
('p1_qua04_learning','learning','Quadratic inequalities learning','Квадратные неравенства: обучение','Kvadrat tengsizliklar: o‘rganish'),
('p1_qua05_learning','learning','Linear-quadratic systems learning','Линейно-квадратные системы: обучение','Chiziqli-kvadrat sistemalar: o‘rganish'),
('p1_qua06_learning','learning','Transformed quadratic equations learning','Квадратные уравнения после замены: обучение','Almashtirishdan keyingi kvadrat tenglamalar: o‘rganish'),
('p1_qua04_retest','retest','Quadratic inequalities delayed retest','Отложенный ретест: квадратные неравенства','Kechiktirilgan qayta test: kvadrat tengsizliklar'),
('p1_qua05_retest','retest','Linear-quadratic systems delayed retest','Отложенный ретест: системы','Kechiktirilgan qayta test: sistemalar'),
('p1_qua06_retest','retest','Transformed equations delayed retest','Отложенный ретест: уравнения с заменой','Kechiktirilgan qayta test: almashtirishli tenglamalar'),
('p1_aw09_12_quadratics_mixed','mixed','P1 AW9-12 quadratics mixed transfer','Смешанный перенос квадратных тем P1 AW9-12','P1 AW9-12 kvadrat mavzular aralash transferi')
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
select cv.id,d.k,'av1','P1',d.t,'approved',d.en,d.ru,d.uz
from defs d cross join cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

-- Memberships. R02 per skill is deliberately kept outside every assessment as a fully isolated holdout.
with cv as (
  select id,content_version from private.exam_prep_content_versions where content_version='p1_aw09_12_quadratics_v1'
), a as (
  select x.id,x.assessment_key,cv.content_version
  from private.exam_prep_assessments x join cv on cv.id=x.content_version_id
), m as (
  select x.content_key,x.question_id,x.primary_skill_code,cv.content_version
  from private.exam_prep_question_content_meta x join cv on cv.id=x.content_version_id
), w as (
  select x.id,x.task_key,x.primary_skill_code,cv.content_version
  from private.exam_prep_written_tasks x join cv on cv.id=x.content_version_id
), items(akey,ord,ckey,wkey,skill,role,holdout) as (values
('p1_aw09_12_quadratics_diagnostic',1,'P1QUA04-D01',null,'P1-QUA-04','diagnostic',true),
('p1_aw09_12_quadratics_diagnostic',2,'P1QUA05-D01',null,'P1-QUA-05','diagnostic',true),
('p1_aw09_12_quadratics_diagnostic',3,'P1QUA06-D01',null,'P1-QUA-06','diagnostic',true),
('p1_qua04_learning',1,'P1QUA04-L01',null,'P1-QUA-04','learning',false),
('p1_qua04_learning',2,'P1QUA04-L02',null,'P1-QUA-04','learning',false),
('p1_qua04_learning',3,'P1QUA04-L03',null,'P1-QUA-04','learning',false),
('p1_qua04_learning',4,null,'P1QUA04-W01','P1-QUA-04','written',false),
('p1_qua05_learning',1,'P1QUA05-L01',null,'P1-QUA-05','learning',false),
('p1_qua05_learning',2,'P1QUA05-L02',null,'P1-QUA-05','learning',false),
('p1_qua05_learning',3,'P1QUA05-L03',null,'P1-QUA-05','learning',false),
('p1_qua05_learning',4,null,'P1QUA05-W01','P1-QUA-05','written',false),
('p1_qua06_learning',1,'P1QUA06-L01',null,'P1-QUA-06','learning',false),
('p1_qua06_learning',2,'P1QUA06-L02',null,'P1-QUA-06','learning',false),
('p1_qua06_learning',3,'P1QUA06-L03',null,'P1-QUA-06','learning',false),
('p1_qua06_learning',4,null,'P1QUA06-W01','P1-QUA-06','written',false),
('p1_qua04_retest',1,'P1QUA04-R01',null,'P1-QUA-04','retest',true),
('p1_qua05_retest',1,'P1QUA05-R01',null,'P1-QUA-05','retest',true),
('p1_qua06_retest',1,'P1QUA06-R01',null,'P1-QUA-06','retest',true),
('p1_aw09_12_quadratics_mixed',1,'P1QUA04-M01',null,'P1-QUA-04','mixed',true),
('p1_aw09_12_quadratics_mixed',2,'P1QUA05-M01',null,'P1-QUA-05','mixed',true),
('p1_aw09_12_quadratics_mixed',3,'P1QUA06-M01',null,'P1-QUA-06','mixed',true)
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
  select id into v_id from private.exam_prep_content_versions where content_version='p1_aw09_12_quadratics_v1';
  if v_id is null then raise exception 'P1-02 AW9-12 quadratics assessments: content version missing'; end if;
  if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_id)<>3 then
    raise exception 'P1-02 AW9-12 quadratics assessments: expected 3 written tasks';
  end if;
  if (select count(*) from private.exam_prep_assessments where content_version_id=v_id)<>8 then
    raise exception 'P1-02 AW9-12 quadratics assessments: expected 8 assessment shells';
  end if;
  select count(*) into v_bad
  from private.exam_prep_assessments a
  where a.content_version_id=v_id and a.assessment_type='learning' and (
    (select count(*) from private.exam_prep_assessment_items i where i.assessment_id=a.id and i.question_id is not null and i.reserve_role='learning')<>3
    or (select count(*) from private.exam_prep_assessment_items i where i.assessment_id=a.id and i.written_task_id is not null and i.reserve_role='written')<>1
  );
  if v_bad<>0 then raise exception 'P1-02 AW9-12 quadratics learning assessment contract failed for % assessments',v_bad; end if;
  if (select count(*) from private.exam_prep_question_content_meta m
      where m.content_version_id=v_id and m.reserve_role='retest'
        and not exists(select 1 from private.exam_prep_assessment_items i where i.question_id=m.question_id))<>3 then
    raise exception 'P1-02 AW9-12 quadratics assessments: expected 3 isolated R02 holdouts';
  end if;
end $$;

commit;