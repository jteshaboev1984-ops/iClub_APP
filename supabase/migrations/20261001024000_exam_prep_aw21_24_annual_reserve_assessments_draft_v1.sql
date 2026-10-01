-- Draft assessment containers for AW21-24 annual reserve top-up.
-- DRAFT ONLY: every reserve item remains withheld and all placements are holdout.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_content_versions where id in (4823,4824) and status='draft')<>2
  then raise exception 'aw21_24_annual_reserve_assessments: draft versions missing'; end if;
  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4823,4824) and lifecycle_state='draft' and exposure_state='withheld')<>90
  then raise exception 'aw21_24_annual_reserve_assessments: draft question surface missing'; end if;
  if exists(select 1 from private.exam_prep_assessments where id between 35529 and 35570 and content_version_id not in (4823,4824))
  then raise exception 'aw21_24_annual_reserve_assessments: reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35529,4823,'P1-AW21-24-diagnostic-variant-02','v1','P1','diagnostic','draft','P1 diagnostic — alternative form 2','P1: диагностика — альтернативный вариант 2','P1: diagnostika — muqobil variant 2'),
(35530,4823,'P1-AW21-24-diagnostic-variant-03','v1','P1','diagnostic','draft','P1 diagnostic — alternative form 3','P1: диагностика — альтернативный вариант 3','P1: diagnostika — muqobil variant 3'),
(35531,4823,'P1-COO-05-retest-03','v1','P1','retest','draft','Line-circle geometry — delayed check 3','Геометрия прямой и окружности — повторная проверка 3','Chiziq va aylana geometriyasi — qayta tekshiruv 3'),
(35532,4823,'P1-COO-05-retest-04','v1','P1','retest','draft','Line-circle geometry — delayed check 4','Геометрия прямой и окружности — повторная проверка 4','Chiziq va aylana geometriyasi — qayta tekshiruv 4'),
(35533,4823,'P1-COO-06-retest-03','v1','P1','retest','draft','Intersections and tangency — delayed check 3','Пересечения и касание — повторная проверка 3','Kesishish va urinma — qayta tekshiruv 3'),
(35534,4823,'P1-COO-06-retest-04','v1','P1','retest','draft','Intersections and tangency — delayed check 4','Пересечения и касание — повторная проверка 4','Kesishish va urinma — qayta tekshiruv 4'),
(35535,4823,'P1-DIF-05-retest-03','v1','P1','retest','draft','Increasing and decreasing — delayed check 3','Возрастание и убывание — повторная проверка 3','O‘sish va kamayish — qayta tekshiruv 3'),
(35536,4823,'P1-DIF-05-retest-04','v1','P1','retest','draft','Increasing and decreasing — delayed check 4','Возрастание и убывание — повторная проверка 4','O‘sish va kamayish — qayta tekshiruv 4'),
(35537,4823,'P1-DIF-06-retest-03','v1','P1','retest','draft','Connected rates — delayed check 3','Связанные скорости — повторная проверка 3','Bog‘langan tezliklar — qayta tekshiruv 3'),
(35538,4823,'P1-DIF-06-retest-04','v1','P1','retest','draft','Connected rates — delayed check 4','Связанные скорости — повторная проверка 4','Bog‘langan tezliklar — qayta tekshiruv 4'),
(35539,4823,'P1-DIF-07-retest-03','v1','P1','retest','draft','Stationary points and optimisation — delayed check 3','Стационарные точки и оптимизация — повторная проверка 3','Statsionar nuqtalar va optimallashtirish — qayta tekshiruv 3'),
(35540,4823,'P1-DIF-07-retest-04','v1','P1','retest','draft','Stationary points and optimisation — delayed check 4','Стационарные точки и оптимизация — повторная проверка 4','Statsionar nuqtalar va optimallashtirish — qayta tekshiruv 4'),
(35541,4823,'P1-INT-01-retest-03','v1','P1','retest','draft','Antiderivatives — delayed check 3','Первообразные — повторная проверка 3','Boshlang‘ich funksiyalar — qayta tekshiruv 3'),
(35542,4823,'P1-INT-01-retest-04','v1','P1','retest','draft','Antiderivatives — delayed check 4','Первообразные — повторная проверка 4','Boshlang‘ich funksiyalar — qayta tekshiruv 4'),
(35543,4823,'P1-INT-02-retest-03','v1','P1','retest','draft','Integration constants and boundary conditions — delayed check 3','Константа интегрирования и граничные условия — повторная проверка 3','Integrallash doimiysi va chegara shartlari — qayta tekshiruv 3'),
(35544,4823,'P1-INT-02-retest-04','v1','P1','retest','draft','Integration constants and boundary conditions — delayed check 4','Константа интегрирования и граничные условия — повторная проверка 4','Integrallash doimiysi va chegara shartlari — qayta tekshiruv 4'),
(35545,4823,'P1-INT-03-retest-03','v1','P1','retest','draft','Definite integrals — delayed check 3','Определённые интегралы — повторная проверка 3','Aniq integrallar — qayta tekshiruv 3'),
(35546,4823,'P1-INT-03-retest-04','v1','P1','retest','draft','Definite integrals — delayed check 4','Определённые интегралы — повторная проверка 4','Aniq integrallar — qayta tekshiruv 4'),
(35547,4823,'P1-INT-04-retest-03','v1','P1','retest','draft','Areas by integration — delayed check 3','Площади с помощью интегрирования — повторная проверка 3','Integrallash orqali yuzalar — qayta tekshiruv 3'),
(35548,4823,'P1-INT-04-retest-04','v1','P1','retest','draft','Areas by integration — delayed check 4','Площади с помощью интегрирования — повторная проверка 4','Integrallash orqali yuzalar — qayta tekshiruv 4'),
(35549,4823,'P1-INT-05-retest-03','v1','P1','retest','draft','Volumes of revolution — delayed check 3','Объёмы вращения — повторная проверка 3','Aylanish hajmlari — qayta tekshiruv 3'),
(35550,4823,'P1-INT-05-retest-04','v1','P1','retest','draft','Volumes of revolution — delayed check 4','Объёмы вращения — повторная проверка 4','Aylanish hajmlari — qayta tekshiruv 4'),
(35551,4823,'P1-AW21-24-mixed-transfer-02','v1','P1','mixed','draft','P1 mixed transfer — alternative set 2','P1: смешанное применение — альтернативный набор 2','P1: aralash qo‘llash — muqobil to‘plam 2'),
(35552,4824,'P5-AW21-24-diagnostic-variant-02','v1','P5','diagnostic','draft','P5 diagnostic — alternative form 2','P5: диагностика — альтернативный вариант 2','P5: diagnostika — muqobil variant 2'),
(35553,4824,'P5-AW21-24-diagnostic-variant-03','v1','P5','diagnostic','draft','P5 diagnostic — alternative form 3','P5: диагностика — альтернативный вариант 3','P5: diagnostika — muqobil variant 3'),
(35554,4824,'P5-DAT-08-retest-03','v1','P5','retest','draft','Comparing data sets — delayed check 3','Сравнение наборов данных — повторная проверка 3','Ma’lumot to‘plamlarini taqqoslash — qayta tekshiruv 3'),
(35555,4824,'P5-DAT-08-retest-04','v1','P5','retest','draft','Comparing data sets — delayed check 4','Сравнение наборов данных — повторная проверка 4','Ma’lumot to‘plamlarini taqqoslash — qayta tekshiruv 4'),
(35556,4824,'P5-DAT-09-retest-03','v1','P5','retest','draft','Mean and variance — delayed check 3','Среднее и дисперсия — повторная проверка 3','O‘rtacha va dispersiya — qayta tekshiruv 3'),
(35557,4824,'P5-DAT-09-retest-04','v1','P5','retest','draft','Mean and variance — delayed check 4','Среднее и дисперсия — повторная проверка 4','O‘rtacha va dispersiya — qayta tekshiruv 4'),
(35558,4824,'P5-DAT-10-retest-03','v1','P5','retest','draft','Coded and combined data — delayed check 3','Кодированные и объединённые данные — повторная проверка 3','Kodlangan va birlashtirilgan ma’lumotlar — qayta tekshiruv 3'),
(35559,4824,'P5-DAT-10-retest-04','v1','P5','retest','draft','Coded and combined data — delayed check 4','Кодированные и объединённые данные — повторная проверка 4','Kodlangan va birlashtirilgan ma’lumotlar — qayta tekshiruv 4'),
(35560,4824,'P5-NOR-02-retest-03','v1','P5','retest','draft','Standardising normal variables — delayed check 3','Стандартизация нормальной величины — повторная проверка 3','Normal kattalikni standartlash — qayta tekshiruv 3'),
(35561,4824,'P5-NOR-02-retest-04','v1','P5','retest','draft','Standardising normal variables — delayed check 4','Стандартизация нормальной величины — повторная проверка 4','Normal kattalikni standartlash — qayta tekshiruv 4'),
(35562,4824,'P5-NOR-03-retest-03','v1','P5','retest','draft','Normal probabilities — delayed check 3','Нормальные вероятности — повторная проверка 3','Normal ehtimollar — qayta tekshiruv 3'),
(35563,4824,'P5-NOR-03-retest-04','v1','P5','retest','draft','Normal probabilities — delayed check 4','Нормальные вероятности — повторная проверка 4','Normal ehtimollar — qayta tekshiruv 4'),
(35564,4824,'P5-NOR-04-retest-03','v1','P5','retest','draft','Normal quantiles — delayed check 3','Нормальные квантили — повторная проверка 3','Normal kvantillar — qayta tekshiruv 3'),
(35565,4824,'P5-NOR-04-retest-04','v1','P5','retest','draft','Normal quantiles — delayed check 4','Нормальные квантили — повторная проверка 4','Normal kvantillar — qayta tekshiruv 4'),
(35566,4824,'P5-NOR-05-retest-03','v1','P5','retest','draft','Unknown normal parameters — delayed check 3','Неизвестные параметры нормального распределения — повторная проверка 3','Noma’lum normal parametrlar — qayta tekshiruv 3'),
(35567,4824,'P5-NOR-05-retest-04','v1','P5','retest','draft','Unknown normal parameters — delayed check 4','Неизвестные параметры нормального распределения — повторная проверка 4','Noma’lum normal parametrlar — qayta tekshiruv 4'),
(35568,4824,'P5-NOR-06-retest-03','v1','P5','retest','draft','Normal approximation to binomial — delayed check 3','Нормальное приближение биномиального распределения — повторная проверка 3','Binomial taqsimotni normal yaqinlashtirish — qayta tekshiruv 3'),
(35569,4824,'P5-NOR-06-retest-04','v1','P5','retest','draft','Normal approximation to binomial — delayed check 4','Нормальное приближение биномиального распределения — повторная проверка 4','Binomial taqsimotni normal yaqinlashtirish — qayta tekshiruv 4'),
(35570,4824,'P5-AW21-24-mixed-transfer-02','v1','P5','mixed','draft','P5 mixed transfer — alternative set 2','P5: смешанное применение — альтернативный набор 2','P5: aralash qo‘llash — muqobil to‘plam 2')
on conflict(id) do nothing;

with src(assessment_id,item_order,content_key,skill_code,reserve_role,content_version_id) as (values
(35531,1,'P1COO05-R03','P1-COO-05','retest',4823),
(35532,1,'P1COO05-R04','P1-COO-05','retest',4823),
(35529,1,'P1COO05-D02','P1-COO-05','diagnostic',4823),
(35530,1,'P1COO05-D03','P1-COO-05','diagnostic',4823),
(35551,1,'P1COO05-M02','P1-COO-05','mixed',4823),
(35533,1,'P1COO06-R03','P1-COO-06','retest',4823),
(35534,1,'P1COO06-R04','P1-COO-06','retest',4823),
(35529,2,'P1COO06-D02','P1-COO-06','diagnostic',4823),
(35530,2,'P1COO06-D03','P1-COO-06','diagnostic',4823),
(35551,2,'P1COO06-M02','P1-COO-06','mixed',4823),
(35535,1,'P1DIF05-R03','P1-DIF-05','retest',4823),
(35536,1,'P1DIF05-R04','P1-DIF-05','retest',4823),
(35529,3,'P1DIF05-D02','P1-DIF-05','diagnostic',4823),
(35530,3,'P1DIF05-D03','P1-DIF-05','diagnostic',4823),
(35551,3,'P1DIF05-M02','P1-DIF-05','mixed',4823),
(35537,1,'P1DIF06-R03','P1-DIF-06','retest',4823),
(35538,1,'P1DIF06-R04','P1-DIF-06','retest',4823),
(35529,4,'P1DIF06-D02','P1-DIF-06','diagnostic',4823),
(35530,4,'P1DIF06-D03','P1-DIF-06','diagnostic',4823),
(35551,4,'P1DIF06-M02','P1-DIF-06','mixed',4823),
(35539,1,'P1DIF07-R03','P1-DIF-07','retest',4823),
(35540,1,'P1DIF07-R04','P1-DIF-07','retest',4823),
(35529,5,'P1DIF07-D02','P1-DIF-07','diagnostic',4823),
(35530,5,'P1DIF07-D03','P1-DIF-07','diagnostic',4823),
(35551,5,'P1DIF07-M02','P1-DIF-07','mixed',4823),
(35541,1,'P1INT01-R03','P1-INT-01','retest',4823),
(35542,1,'P1INT01-R04','P1-INT-01','retest',4823),
(35529,6,'P1INT01-D02','P1-INT-01','diagnostic',4823),
(35530,6,'P1INT01-D03','P1-INT-01','diagnostic',4823),
(35551,6,'P1INT01-M02','P1-INT-01','mixed',4823),
(35543,1,'P1INT02-R03','P1-INT-02','retest',4823),
(35544,1,'P1INT02-R04','P1-INT-02','retest',4823),
(35529,7,'P1INT02-D02','P1-INT-02','diagnostic',4823),
(35530,7,'P1INT02-D03','P1-INT-02','diagnostic',4823),
(35551,7,'P1INT02-M02','P1-INT-02','mixed',4823),
(35545,1,'P1INT03-R03','P1-INT-03','retest',4823),
(35546,1,'P1INT03-R04','P1-INT-03','retest',4823),
(35529,8,'P1INT03-D02','P1-INT-03','diagnostic',4823),
(35530,8,'P1INT03-D03','P1-INT-03','diagnostic',4823),
(35551,8,'P1INT03-M02','P1-INT-03','mixed',4823),
(35547,1,'P1INT04-R03','P1-INT-04','retest',4823),
(35548,1,'P1INT04-R04','P1-INT-04','retest',4823),
(35529,9,'P1INT04-D02','P1-INT-04','diagnostic',4823),
(35530,9,'P1INT04-D03','P1-INT-04','diagnostic',4823),
(35551,9,'P1INT04-M02','P1-INT-04','mixed',4823),
(35549,1,'P1INT05-R03','P1-INT-05','retest',4823),
(35550,1,'P1INT05-R04','P1-INT-05','retest',4823),
(35529,10,'P1INT05-D02','P1-INT-05','diagnostic',4823),
(35530,10,'P1INT05-D03','P1-INT-05','diagnostic',4823),
(35551,10,'P1INT05-M02','P1-INT-05','mixed',4823),
(35554,1,'P5DAT08-R03','P5-DAT-08','retest',4824),
(35555,1,'P5DAT08-R04','P5-DAT-08','retest',4824),
(35552,1,'P5DAT08-D02','P5-DAT-08','diagnostic',4824),
(35553,1,'P5DAT08-D03','P5-DAT-08','diagnostic',4824),
(35570,1,'P5DAT08-M02','P5-DAT-08','mixed',4824),
(35556,1,'P5DAT09-R03','P5-DAT-09','retest',4824),
(35557,1,'P5DAT09-R04','P5-DAT-09','retest',4824),
(35552,2,'P5DAT09-D02','P5-DAT-09','diagnostic',4824),
(35553,2,'P5DAT09-D03','P5-DAT-09','diagnostic',4824),
(35570,2,'P5DAT09-M02','P5-DAT-09','mixed',4824),
(35558,1,'P5DAT10-R03','P5-DAT-10','retest',4824),
(35559,1,'P5DAT10-R04','P5-DAT-10','retest',4824),
(35552,3,'P5DAT10-D02','P5-DAT-10','diagnostic',4824),
(35553,3,'P5DAT10-D03','P5-DAT-10','diagnostic',4824),
(35570,3,'P5DAT10-M02','P5-DAT-10','mixed',4824),
(35560,1,'P5NOR02-R03','P5-NOR-02','retest',4824),
(35561,1,'P5NOR02-R04','P5-NOR-02','retest',4824),
(35552,4,'P5NOR02-D02','P5-NOR-02','diagnostic',4824),
(35553,4,'P5NOR02-D03','P5-NOR-02','diagnostic',4824),
(35570,4,'P5NOR02-M02','P5-NOR-02','mixed',4824),
(35562,1,'P5NOR03-R03','P5-NOR-03','retest',4824),
(35563,1,'P5NOR03-R04','P5-NOR-03','retest',4824),
(35552,5,'P5NOR03-D02','P5-NOR-03','diagnostic',4824),
(35553,5,'P5NOR03-D03','P5-NOR-03','diagnostic',4824),
(35570,5,'P5NOR03-M02','P5-NOR-03','mixed',4824),
(35564,1,'P5NOR04-R03','P5-NOR-04','retest',4824),
(35565,1,'P5NOR04-R04','P5-NOR-04','retest',4824),
(35552,6,'P5NOR04-D02','P5-NOR-04','diagnostic',4824),
(35553,6,'P5NOR04-D03','P5-NOR-04','diagnostic',4824),
(35570,6,'P5NOR04-M02','P5-NOR-04','mixed',4824),
(35566,1,'P5NOR05-R03','P5-NOR-05','retest',4824),
(35567,1,'P5NOR05-R04','P5-NOR-05','retest',4824),
(35552,7,'P5NOR05-D02','P5-NOR-05','diagnostic',4824),
(35553,7,'P5NOR05-D03','P5-NOR-05','diagnostic',4824),
(35570,7,'P5NOR05-M02','P5-NOR-05','mixed',4824),
(35568,1,'P5NOR06-R03','P5-NOR-06','retest',4824),
(35569,1,'P5NOR06-R04','P5-NOR-06','retest',4824),
(35552,8,'P5NOR06-D02','P5-NOR-06','diagnostic',4824),
(35553,8,'P5NOR06-D03','P5-NOR-06','diagnostic',4824),
(35570,8,'P5NOR06-M02','P5-NOR-06','mixed',4824)
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
 if (select count(*) from private.exam_prep_assessments where content_version_id in (4823,4824) and status='draft')<>42
    or (select count(*) from private.exam_prep_assessments where content_version_id in (4823,4824) and assessment_type='diagnostic')<>4
    or (select count(*) from private.exam_prep_assessments where content_version_id in (4823,4824) and assessment_type='retest')<>36
    or (select count(*) from private.exam_prep_assessments where content_version_id in (4823,4824) and assessment_type='mixed')<>2
    or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id in (4823,4824))<>90
 then raise exception 'aw21_24_annual_reserve_assessments: cardinality mismatch'; end if;

 select count(*) into v_bad
 from private.exam_prep_assessment_items ai
 join private.exam_prep_assessments a on a.id=ai.assessment_id
 join private.exam_prep_question_content_meta m on m.question_id=ai.question_id and m.content_version_id=a.content_version_id
 where a.content_version_id in (4823,4824)
   and (ai.written_task_id is not null or ai.is_holdout is not true or ai.primary_skill_code<>m.primary_skill_code
        or ai.reserve_role<>m.reserve_role or ai.reserve_role<>a.assessment_type
        or ai.primary_skill_code not like a.component_code||'-%');
 if v_bad<>0 then raise exception 'aw21_24_annual_reserve_assessments: role/holdout/component mismatch rows=%',v_bad; end if;

 select count(*) into v_bad
 from private.exam_prep_assessments a
 where a.content_version_id in (4823,4824) and a.assessment_type='retest'
   and (select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id)<>1;
 if v_bad<>0 then raise exception 'aw21_24_annual_reserve_assessments: non-isolated retest rows=%',v_bad; end if;

 if (select count(*) from private.exam_prep_assessment_items where assessment_id in (35529,35530))<>20
    or (select count(*) from private.exam_prep_assessment_items where assessment_id=35551)<>10
    or (select count(*) from private.exam_prep_assessment_items where assessment_id in (35552,35553))<>16
    or (select count(*) from private.exam_prep_assessment_items where assessment_id=35570)<>8
    or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id in (4823,4824) and ai.is_holdout)<>90
 then raise exception 'aw21_24_annual_reserve_assessments: diagnostic/mixed/holdout coverage mismatch'; end if;

 if exists(select 1 from private.exam_prep_assessments where content_version_id in (4823,4824)
   and (lower(title_en) like '%reserve%' or lower(title_en) like '%draft%'
        or lower(title_ru) like '%резерв%' or lower(title_ru) like '%чернов%'
        or lower(title_uz) like '%zaxira%' or lower(title_uz) like '%qoralama%'))
 then raise exception 'aw21_24_annual_reserve_assessments: internal wording leaked into learner titles'; end if;
end
$postcheck$;

commit;
