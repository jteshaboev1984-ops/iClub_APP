-- Draft assessment containers for AW5-8 annual reserve top-up.
-- DRAFT ONLY: all reserve items remain withheld and unselectable.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
 if (select count(*) from private.exam_prep_content_versions where id in (4807,4808) and status='draft')<>2
 then raise exception 'aw05_08_annual_reserve_assessments: draft versions missing'; end if;
 if exists(select 1 from private.exam_prep_assessments where id between 35339 and 35372 and content_version_id not in (4807,4808))
 then raise exception 'aw05_08_annual_reserve_assessments: reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35339,4807,'P1-AW05-08-diagnostic-variant-02','v1','P1','diagnostic','draft','P1 E2 diagnostic — reserve variant 2','P1 E2: диагностическая проверка — резервный вариант 2','P1 E2: diagnostika — zaxira variant 2'),
(35340,4807,'P1-AW05-08-diagnostic-variant-03','v1','P1','diagnostic','draft','P1 E2 diagnostic — reserve variant 3','P1 E2: диагностическая проверка — резервный вариант 3','P1 E2: diagnostika — zaxira variant 3'),
(35341,4807,'P1-FUN-06-retest-03','v1','P1','retest','draft','P1 graph translations — delayed check 3','P1: сдвиги графиков — повторная проверка 3','P1: grafiklarni siljitish — qayta tekshiruv 3'),
(35342,4807,'P1-FUN-06-retest-04','v1','P1','retest','draft','P1 graph translations — delayed check 4','P1: сдвиги графиков — повторная проверка 4','P1: grafiklarni siljitish — qayta tekshiruv 4'),
(35343,4807,'P1-FUN-07-retest-03','v1','P1','retest','draft','P1 graph reflections — delayed check 3','P1: отражения графиков — повторная проверка 3','P1: grafiklarni akslantirish — qayta tekshiruv 3'),
(35344,4807,'P1-FUN-07-retest-04','v1','P1','retest','draft','P1 graph reflections — delayed check 4','P1: отражения графиков — повторная проверка 4','P1: grafiklarni akslantirish — qayta tekshiruv 4'),
(35345,4807,'P1-FUN-08-retest-03','v1','P1','retest','draft','P1 graph stretches — delayed check 3','P1: растяжения графиков — повторная проверка 3','P1: grafiklarni masshtablash — qayta tekshiruv 3'),
(35346,4807,'P1-FUN-08-retest-04','v1','P1','retest','draft','P1 graph stretches — delayed check 4','P1: растяжения графиков — повторная проверка 4','P1: grafiklarni masshtablash — qayta tekshiruv 4'),
(35347,4807,'P1-COO-01-retest-03','v1','P1','retest','draft','P1 line equations — delayed check 3','P1: уравнения прямых — повторная проверка 3','P1: to‘g‘ri chiziq tenglamalari — qayta tekshiruv 3'),
(35348,4807,'P1-COO-01-retest-04','v1','P1','retest','draft','P1 line equations — delayed check 4','P1: уравнения прямых — повторная проверка 4','P1: to‘g‘ri chiziq tenglamalari — qayta tekshiruv 4'),
(35349,4807,'P1-COO-02-retest-03','v1','P1','retest','draft','P1 distance, midpoint and intersection — delayed check 3','P1: расстояние, середина и пересечение — повторная проверка 3','P1: masofa, o‘rta nuqta va kesishish — qayta tekshiruv 3'),
(35350,4807,'P1-COO-02-retest-04','v1','P1','retest','draft','P1 distance, midpoint and intersection — delayed check 4','P1: расстояние, середина и пересечение — повторная проверка 4','P1: masofa, o‘rta nuqta va kesishish — qayta tekshiruv 4'),
(35351,4807,'P1-COO-03-retest-03','v1','P1','retest','draft','P1 parallel and perpendicular lines — delayed check 3','P1: параллельные и перпендикулярные прямые — повторная проверка 3','P1: parallel va perpendikulyar chiziqlar — qayta tekshiruv 3'),
(35352,4807,'P1-COO-03-retest-04','v1','P1','retest','draft','P1 parallel and perpendicular lines — delayed check 4','P1: параллельные и перпендикулярные прямые — повторная проверка 4','P1: parallel va perpendikulyar chiziqlar — qayta tekshiruv 4'),
(35353,4807,'P1-CIR-01-retest-03','v1','P1','retest','draft','P1 degrees and radians — delayed check 3','P1: градусы и радианы — повторная проверка 3','P1: gradus va radian — qayta tekshiruv 3'),
(35354,4807,'P1-CIR-01-retest-04','v1','P1','retest','draft','P1 degrees and radians — delayed check 4','P1: градусы и радианы — повторная проверка 4','P1: gradus va radian — qayta tekshiruv 4'),
(35355,4807,'P1-TRI-01-retest-03','v1','P1','retest','draft','P1 trigonometric graphs — delayed check 3','P1: тригонометрические графики — повторная проверка 3','P1: trigonometrik grafiklar — qayta tekshiruv 3'),
(35356,4807,'P1-TRI-01-retest-04','v1','P1','retest','draft','P1 trigonometric graphs — delayed check 4','P1: тригонометрические графики — повторная проверка 4','P1: trigonometrik grafiklar — qayta tekshiruv 4'),
(35357,4807,'P1-AW05-08-mixed-transfer-02','v1','P1','mixed','draft','P1 E2 — transfer set 2','P1 E2 — перенос навыков 2','P1 E2 — ko‘nikmani qo‘llash 2'),
(35358,4808,'P5-AW05-08-diagnostic-variant-02','v1','P5','diagnostic','draft','P5 E2 diagnostic — reserve variant 2','P5 E2: диагностическая проверка — резервный вариант 2','P5 E2: diagnostika — zaxira variant 2'),
(35359,4808,'P5-AW05-08-diagnostic-variant-03','v1','P5','diagnostic','draft','P5 E2 diagnostic — reserve variant 3','P5 E2: диагностическая проверка — резервный вариант 3','P5 E2: diagnostika — zaxira variant 3'),
(35360,4808,'P5-CNT-01-retest-03','v1','P5','retest','draft','P5 ordered and unordered counting — delayed check 3','P5: упорядоченный и неупорядоченный подсчёт — повторная проверка 3','P5: tartibli va tartibsiz sanash — qayta tekshiruv 3'),
(35361,4808,'P5-CNT-01-retest-04','v1','P5','retest','draft','P5 ordered and unordered counting — delayed check 4','P5: упорядоченный и неупорядоченный подсчёт — повторная проверка 4','P5: tartibli va tartibsiz sanash — qayta tekshiruv 4'),
(35362,4808,'P5-CNT-02-retest-03','v1','P5','retest','draft','P5 ordered arrangements — delayed check 3','P5: упорядоченные размещения — повторная проверка 3','P5: tartibli joylashtirish — qayta tekshiruv 3'),
(35363,4808,'P5-CNT-02-retest-04','v1','P5','retest','draft','P5 ordered arrangements — delayed check 4','P5: упорядоченные размещения — повторная проверка 4','P5: tartibli joylashtirish — qayta tekshiruv 4'),
(35364,4808,'P5-CNT-03-retest-03','v1','P5','retest','draft','P5 repeated objects — delayed check 3','P5: повторяющиеся объекты — повторная проверка 3','P5: takrorlanuvchi obyektlar — qayta tekshiruv 3'),
(35365,4808,'P5-CNT-03-retest-04','v1','P5','retest','draft','P5 repeated objects — delayed check 4','P5: повторяющиеся объекты — повторная проверка 4','P5: takrorlanuvchi obyektlar — qayta tekshiruv 4'),
(35366,4808,'P5-CNT-04-retest-03','v1','P5','retest','draft','P5 restricted arrangements — delayed check 3','P5: расстановки с ограничениями — повторная проверка 3','P5: cheklovli joylashtirish — qayta tekshiruv 3'),
(35367,4808,'P5-CNT-04-retest-04','v1','P5','retest','draft','P5 restricted arrangements — delayed check 4','P5: расстановки с ограничениями — повторная проверка 4','P5: cheklovli joylashtirish — qayta tekshiruv 4'),
(35368,4808,'P5-PRO-01-retest-03','v1','P5','retest','draft','P5 sample spaces — delayed check 3','P5: пространства исходов — повторная проверка 3','P5: namunalar fazosi — qayta tekshiruv 3'),
(35369,4808,'P5-PRO-01-retest-04','v1','P5','retest','draft','P5 sample spaces — delayed check 4','P5: пространства исходов — повторная проверка 4','P5: namunalar fazosi — qayta tekshiruv 4'),
(35370,4808,'P5-PRO-03-retest-03','v1','P5','retest','draft','P5 complement and addition rule — delayed check 3','P5: дополнение и правило сложения — повторная проверка 3','P5: to‘ldiruvchi va qo‘shish qoidasi — qayta tekshiruv 3'),
(35371,4808,'P5-PRO-03-retest-04','v1','P5','retest','draft','P5 complement and addition rule — delayed check 4','P5: дополнение и правило сложения — повторная проверка 4','P5: to‘ldiruvchi va qo‘shish qoidasi — qayta tekshiruv 4'),
(35372,4808,'P5-AW05-08-mixed-transfer-02','v1','P5','mixed','draft','P5 E2 — transfer set 2','P5 E2 — перенос навыков 2','P5 E2 — ko‘nikmani qo‘llash 2')
on conflict(id) do nothing;

with src(assessment_id,item_order,content_key,skill_code,reserve_role,content_version_id) as (values
(35339,1,'P1FUN06-D02','P1-FUN-06','diagnostic',4807),
(35339,2,'P1FUN07-D02','P1-FUN-07','diagnostic',4807),
(35339,3,'P1FUN08-D02','P1-FUN-08','diagnostic',4807),
(35339,4,'P1COO01-D02','P1-COO-01','diagnostic',4807),
(35339,5,'P1COO02-D02','P1-COO-02','diagnostic',4807),
(35339,6,'P1COO03-D02','P1-COO-03','diagnostic',4807),
(35339,7,'P1CIR01-D02','P1-CIR-01','diagnostic',4807),
(35339,8,'P1TRI01-D02','P1-TRI-01','diagnostic',4807),
(35340,1,'P1FUN06-D03','P1-FUN-06','diagnostic',4807),
(35340,2,'P1FUN07-D03','P1-FUN-07','diagnostic',4807),
(35340,3,'P1FUN08-D03','P1-FUN-08','diagnostic',4807),
(35340,4,'P1COO01-D03','P1-COO-01','diagnostic',4807),
(35340,5,'P1COO02-D03','P1-COO-02','diagnostic',4807),
(35340,6,'P1COO03-D03','P1-COO-03','diagnostic',4807),
(35340,7,'P1CIR01-D03','P1-CIR-01','diagnostic',4807),
(35340,8,'P1TRI01-D03','P1-TRI-01','diagnostic',4807),
(35341,1,'P1FUN06-R03','P1-FUN-06','retest',4807),
(35342,1,'P1FUN06-R04','P1-FUN-06','retest',4807),
(35343,1,'P1FUN07-R03','P1-FUN-07','retest',4807),
(35344,1,'P1FUN07-R04','P1-FUN-07','retest',4807),
(35345,1,'P1FUN08-R03','P1-FUN-08','retest',4807),
(35346,1,'P1FUN08-R04','P1-FUN-08','retest',4807),
(35347,1,'P1COO01-R03','P1-COO-01','retest',4807),
(35348,1,'P1COO01-R04','P1-COO-01','retest',4807),
(35349,1,'P1COO02-R03','P1-COO-02','retest',4807),
(35350,1,'P1COO02-R04','P1-COO-02','retest',4807),
(35351,1,'P1COO03-R03','P1-COO-03','retest',4807),
(35352,1,'P1COO03-R04','P1-COO-03','retest',4807),
(35353,1,'P1CIR01-R03','P1-CIR-01','retest',4807),
(35354,1,'P1CIR01-R04','P1-CIR-01','retest',4807),
(35355,1,'P1TRI01-R03','P1-TRI-01','retest',4807),
(35356,1,'P1TRI01-R04','P1-TRI-01','retest',4807),
(35357,1,'P1FUN06-M02','P1-FUN-06','mixed',4807),
(35357,2,'P1FUN07-M02','P1-FUN-07','mixed',4807),
(35357,3,'P1FUN08-M02','P1-FUN-08','mixed',4807),
(35357,4,'P1COO01-M02','P1-COO-01','mixed',4807),
(35357,5,'P1COO02-M02','P1-COO-02','mixed',4807),
(35357,6,'P1COO03-M02','P1-COO-03','mixed',4807),
(35357,7,'P1CIR01-M02','P1-CIR-01','mixed',4807),
(35357,8,'P1TRI01-M02','P1-TRI-01','mixed',4807),
(35358,1,'P5CNT01-D02','P5-CNT-01','diagnostic',4808),
(35358,2,'P5CNT02-D02','P5-CNT-02','diagnostic',4808),
(35358,3,'P5CNT03-D02','P5-CNT-03','diagnostic',4808),
(35358,4,'P5CNT04-D02','P5-CNT-04','diagnostic',4808),
(35358,5,'P5PRO01-D02','P5-PRO-01','diagnostic',4808),
(35358,6,'P5PRO03-D02','P5-PRO-03','diagnostic',4808),
(35359,1,'P5CNT01-D03','P5-CNT-01','diagnostic',4808),
(35359,2,'P5CNT02-D03','P5-CNT-02','diagnostic',4808),
(35359,3,'P5CNT03-D03','P5-CNT-03','diagnostic',4808),
(35359,4,'P5CNT04-D03','P5-CNT-04','diagnostic',4808),
(35359,5,'P5PRO01-D03','P5-PRO-01','diagnostic',4808),
(35359,6,'P5PRO03-D03','P5-PRO-03','diagnostic',4808),
(35360,1,'P5CNT01-R03','P5-CNT-01','retest',4808),
(35361,1,'P5CNT01-R04','P5-CNT-01','retest',4808),
(35362,1,'P5CNT02-R03','P5-CNT-02','retest',4808),
(35363,1,'P5CNT02-R04','P5-CNT-02','retest',4808),
(35364,1,'P5CNT03-R03','P5-CNT-03','retest',4808),
(35365,1,'P5CNT03-R04','P5-CNT-03','retest',4808),
(35366,1,'P5CNT04-R03','P5-CNT-04','retest',4808),
(35367,1,'P5CNT04-R04','P5-CNT-04','retest',4808),
(35368,1,'P5PRO01-R03','P5-PRO-01','retest',4808),
(35369,1,'P5PRO01-R04','P5-PRO-01','retest',4808),
(35370,1,'P5PRO03-R03','P5-PRO-03','retest',4808),
(35371,1,'P5PRO03-R04','P5-PRO-03','retest',4808),
(35372,1,'P5CNT01-M02','P5-CNT-01','mixed',4808),
(35372,2,'P5CNT02-M02','P5-CNT-02','mixed',4808),
(35372,3,'P5CNT03-M02','P5-CNT-03','mixed',4808),
(35372,4,'P5CNT04-M02','P5-CNT-04','mixed',4808),
(35372,5,'P5PRO01-M02','P5-PRO-01','mixed',4808),
(35372,6,'P5PRO03-M02','P5-PRO-03','mixed',4808)
)
insert into private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select s.assessment_id,s.item_order,m.question_id,null,s.skill_code,s.reserve_role,true
from src s
join private.exam_prep_question_content_meta m
  on m.content_version_id=s.content_version_id
 and m.content_key=s.content_key
 and m.primary_skill_code=s.skill_code
 and m.reserve_role=s.reserve_role
on conflict(assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int;
begin
 if (select count(*) from private.exam_prep_assessments where content_version_id in (4807,4808) and status='draft')<>34
    or (select count(*) from private.exam_prep_assessments where content_version_id in (4807,4808) and assessment_type='diagnostic')<>4
    or (select count(*) from private.exam_prep_assessments where content_version_id in (4807,4808) and assessment_type='retest')<>28
    or (select count(*) from private.exam_prep_assessments where content_version_id in (4807,4808) and assessment_type='mixed')<>2
    or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id in (4807,4808))<>70
 then raise exception 'aw05_08_annual_reserve_assessments: cardinality mismatch'; end if;

 select count(*) into v_bad
 from private.exam_prep_assessment_items ai
 join private.exam_prep_assessments a on a.id=ai.assessment_id
 join private.exam_prep_question_content_meta m on m.question_id=ai.question_id and m.content_version_id=a.content_version_id
 where a.content_version_id in (4807,4808)
   and (
     ai.written_task_id is not null
     or ai.is_holdout is not true
     or ai.primary_skill_code<>m.primary_skill_code
     or ai.reserve_role<>m.reserve_role
     or ai.reserve_role<>a.assessment_type
     or ai.primary_skill_code not like a.component_code||'-%'
   );
 if v_bad<>0 then raise exception 'aw05_08_annual_reserve_assessments: role/holdout/component mismatch rows=%',v_bad; end if;

 -- Retests are isolated one-item assessments.
 select count(*) into v_bad
 from private.exam_prep_assessments a
 where a.content_version_id in (4807,4808)
   and a.assessment_type='retest'
   and (select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id)<>1;
 if v_bad<>0 then raise exception 'aw05_08_annual_reserve_assessments: non-isolated retest rows=%',v_bad; end if;

 -- Diagnostic variants cover every target skill exactly once.
 if exists(
   select 1 from private.exam_prep_assessments a
   where a.id in (35339,35340,35358,35359)
     and (
       (a.component_code='P1' and (select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id)<>8)
       or (a.component_code='P5' and (select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id)<>6)
     )
 ) then raise exception 'aw05_08_annual_reserve_assessments: diagnostic variant coverage mismatch'; end if;
end
$postcheck$;

commit;
