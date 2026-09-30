-- Draft assessment containers for AW17-20 annual reserve top-up.
-- DRAFT ONLY: all reserve items remain withheld and unselectable.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_content_versions where id in (4819,4820) and status='draft')<>2
  then raise exception 'aw17_20_annual_reserve_assessments: draft versions missing'; end if;

  if exists(select 1 from private.exam_prep_assessments where id between 35483 and 35510 and content_version_id not in (4819,4820))
  then raise exception 'aw17_20_annual_reserve_assessments: reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35483,4819,'P1-AW17-20-diagnostic-variant-02','v1','P1','diagnostic','draft','P1 diagnostic — alternative form 2','P1: диагностика — альтернативный вариант 2','P1: diagnostika — muqobil variant 2'),
(35484,4819,'P1-AW17-20-diagnostic-variant-03','v1','P1','diagnostic','draft','P1 diagnostic — alternative form 3','P1: диагностика — альтернативный вариант 3','P1: diagnostika — muqobil variant 3'),
(35485,4819,'P1-SER-03-retest-03','v1','P1','retest','draft','Arithmetic progression nth term and sum — delayed check 3','Арифметическая прогрессия: n-й член и сумма — повторная проверка 3','Arifmetik progressiya: n-had va yig‘indi — qayta tekshiruv 3'),
(35486,4819,'P1-SER-03-retest-04','v1','P1','retest','draft','Arithmetic progression nth term and sum — delayed check 4','Арифметическая прогрессия: n-й член и сумма — повторная проверка 4','Arifmetik progressiya: n-had va yig‘indi — qayta tekshiruv 4'),
(35487,4819,'P1-SER-04-retest-03','v1','P1','retest','draft','Geometric progression nth term and finite sum — delayed check 3','Геометрическая прогрессия: n-й член и конечная сумма — повторная проверка 3','Geometrik progressiya: n-had va chekli yig‘indi — qayta tekshiruv 3'),
(35488,4819,'P1-SER-04-retest-04','v1','P1','retest','draft','Geometric progression nth term and finite sum — delayed check 4','Геометрическая прогрессия: n-й член и конечная сумма — повторная проверка 4','Geometrik progressiya: n-had va chekli yig‘indi — qayta tekshiruv 4'),
(35489,4819,'P1-SER-05-retest-03','v1','P1','retest','draft','Geometric series convergence and sum to infinity — delayed check 3','Сходимость геометрического ряда и сумма до бесконечности — повторная проверка 3','Geometrik qator yaqinlashuvi va cheksiz yig‘indi — qayta tekshiruv 3'),
(35490,4819,'P1-SER-05-retest-04','v1','P1','retest','draft','Geometric series convergence and sum to infinity — delayed check 4','Сходимость геометрического ряда и сумма до бесконечности — повторная проверка 4','Geometrik qator yaqinlashuvi va cheksiz yig‘indi — qayta tekshiruv 4'),
(35491,4819,'P1-DIF-02-retest-03','v1','P1','retest','draft','Differentiating powers — delayed check 3','Дифференцирование степенных функций — повторная проверка 3','Darajali funksiyalarni differensiallash — qayta tekshiruv 3'),
(35492,4819,'P1-DIF-02-retest-04','v1','P1','retest','draft','Differentiating powers — delayed check 4','Дифференцирование степенных функций — повторная проверка 4','Darajali funksiyalarni differensiallash — qayta tekshiruv 4'),
(35493,4819,'P1-DIF-03-retest-03','v1','P1','retest','draft','Chain rule for linear inner functions — delayed check 3','Правило цепочки для линейной внутренней функции — повторная проверка 3','Chiziqli ichki funksiya uchun zanjir qoidasi — qayta tekshiruv 3'),
(35494,4819,'P1-DIF-03-retest-04','v1','P1','retest','draft','Chain rule for linear inner functions — delayed check 4','Правило цепочки для линейной внутренней функции — повторная проверка 4','Chiziqli ichki funksiya uchun zanjir qoidasi — qayta tekshiruv 4'),
(35495,4819,'P1-DIF-04-retest-03','v1','P1','retest','draft','Tangent and normal equations — delayed check 3','Уравнения касательной и нормали — повторная проверка 3','Urinma va normal tenglamalari — qayta tekshiruv 3'),
(35496,4819,'P1-DIF-04-retest-04','v1','P1','retest','draft','Tangent and normal equations — delayed check 4','Уравнения касательной и нормали — повторная проверка 4','Urinma va normal tenglamalari — qayta tekshiruv 4'),
(35497,4819,'P1-AW17-20-mixed-transfer-02','v1','P1','mixed','draft','P1 mixed transfer — alternative set 2','P1: смешанный перенос — альтернативный набор 2','P1: aralash qo‘llash — muqobil to‘plam 2'),
(35498,4820,'P5-AW17-20-diagnostic-variant-02','v1','P5','diagnostic','draft','P5 diagnostic — alternative form 2','P5: диагностика — альтернативный вариант 2','P5: diagnostika — muqobil variant 2'),
(35499,4820,'P5-AW17-20-diagnostic-variant-03','v1','P5','diagnostic','draft','P5 diagnostic — alternative form 3','P5: диагностика — альтернативный вариант 3','P5: diagnostika — muqobil variant 3'),
(35500,4820,'P5-BIN-02-retest-03','v1','P5','retest','draft','Binomial probabilities — delayed check 3','Биномиальные вероятности — повторная проверка 3','Binomial ehtimollar — qayta tekshiruv 3'),
(35501,4820,'P5-BIN-02-retest-04','v1','P5','retest','draft','Binomial probabilities — delayed check 4','Биномиальные вероятности — повторная проверка 4','Binomial ehtimollar — qayta tekshiruv 4'),
(35502,4820,'P5-BIN-03-retest-03','v1','P5','retest','draft','Binomial mean, variance and inverse parameters — delayed check 3','Биномиальные среднее, дисперсия и обратные параметры — повторная проверка 3','Binomial o‘rtacha, dispersiya va teskari parametrlar — qayta tekshiruv 3'),
(35503,4820,'P5-BIN-03-retest-04','v1','P5','retest','draft','Binomial mean, variance and inverse parameters — delayed check 4','Биномиальные среднее, дисперсия и обратные параметры — повторная проверка 4','Binomial o‘rtacha, dispersiya va teskari parametrlar — qayta tekshiruv 4'),
(35504,4820,'P5-GEO-02-retest-03','v1','P5','retest','draft','Geometric probabilities and complements — delayed check 3','Геометрические вероятности и дополнения — повторная проверка 3','Geometrik ehtimollar va to‘ldiruvchi hodisalar — qayta tekshiruv 3'),
(35505,4820,'P5-GEO-02-retest-04','v1','P5','retest','draft','Geometric probabilities and complements — delayed check 4','Геометрические вероятности и дополнения — повторная проверка 4','Geometrik ehtimollar va to‘ldiruvchi hodisalar — qayta tekshiruv 4'),
(35506,4820,'P5-GEO-03-retest-03','v1','P5','retest','draft','Geometric expectation and parameter — delayed check 3','Математическое ожидание и параметр геометрического распределения — повторная проверка 3','Geometrik kutilma va parametr — qayta tekshiruv 3'),
(35507,4820,'P5-GEO-03-retest-04','v1','P5','retest','draft','Geometric expectation and parameter — delayed check 4','Математическое ожидание и параметр геометрического распределения — повторная проверка 4','Geometrik kutilma va parametr — qayta tekshiruv 4'),
(35508,4820,'P5-NOR-01-retest-03','v1','P5','retest','draft','Recognising and describing a normal model — delayed check 3','Распознавание и описание нормальной модели — повторная проверка 3','Normal modelni aniqlash va tavsiflash — qayta tekshiruv 3'),
(35509,4820,'P5-NOR-01-retest-04','v1','P5','retest','draft','Recognising and describing a normal model — delayed check 4','Распознавание и описание нормальной модели — повторная проверка 4','Normal modelni aniqlash va tavsiflash — qayta tekshiruv 4'),
(35510,4820,'P5-AW17-20-mixed-transfer-02','v1','P5','mixed','draft','P5 mixed transfer — alternative set 2','P5: смешанный перенос — альтернативный набор 2','P5: aralash qo‘llash — muqobil to‘plam 2')
on conflict(id) do nothing;

with src(assessment_id,item_order,content_key,skill_code,reserve_role,content_version_id) as (values
(35485,1,'P1SER03-R03','P1-SER-03','retest',4819),
(35486,1,'P1SER03-R04','P1-SER-03','retest',4819),
(35483,1,'P1SER03-D02','P1-SER-03','diagnostic',4819),
(35484,1,'P1SER03-D03','P1-SER-03','diagnostic',4819),
(35497,1,'P1SER03-M02','P1-SER-03','mixed',4819),
(35487,1,'P1SER04-R03','P1-SER-04','retest',4819),
(35488,1,'P1SER04-R04','P1-SER-04','retest',4819),
(35483,2,'P1SER04-D02','P1-SER-04','diagnostic',4819),
(35484,2,'P1SER04-D03','P1-SER-04','diagnostic',4819),
(35497,2,'P1SER04-M02','P1-SER-04','mixed',4819),
(35489,1,'P1SER05-R03','P1-SER-05','retest',4819),
(35490,1,'P1SER05-R04','P1-SER-05','retest',4819),
(35483,3,'P1SER05-D02','P1-SER-05','diagnostic',4819),
(35484,3,'P1SER05-D03','P1-SER-05','diagnostic',4819),
(35497,3,'P1SER05-M02','P1-SER-05','mixed',4819),
(35491,1,'P1DIF02-R03','P1-DIF-02','retest',4819),
(35492,1,'P1DIF02-R04','P1-DIF-02','retest',4819),
(35483,4,'P1DIF02-D02','P1-DIF-02','diagnostic',4819),
(35484,4,'P1DIF02-D03','P1-DIF-02','diagnostic',4819),
(35497,4,'P1DIF02-M02','P1-DIF-02','mixed',4819),
(35493,1,'P1DIF03-R03','P1-DIF-03','retest',4819),
(35494,1,'P1DIF03-R04','P1-DIF-03','retest',4819),
(35483,5,'P1DIF03-D02','P1-DIF-03','diagnostic',4819),
(35484,5,'P1DIF03-D03','P1-DIF-03','diagnostic',4819),
(35497,5,'P1DIF03-M02','P1-DIF-03','mixed',4819),
(35495,1,'P1DIF04-R03','P1-DIF-04','retest',4819),
(35496,1,'P1DIF04-R04','P1-DIF-04','retest',4819),
(35483,6,'P1DIF04-D02','P1-DIF-04','diagnostic',4819),
(35484,6,'P1DIF04-D03','P1-DIF-04','diagnostic',4819),
(35497,6,'P1DIF04-M02','P1-DIF-04','mixed',4819),
(35500,1,'P5BIN02-R03','P5-BIN-02','retest',4820),
(35501,1,'P5BIN02-R04','P5-BIN-02','retest',4820),
(35498,1,'P5BIN02-D02','P5-BIN-02','diagnostic',4820),
(35499,1,'P5BIN02-D03','P5-BIN-02','diagnostic',4820),
(35510,1,'P5BIN02-M02','P5-BIN-02','mixed',4820),
(35502,1,'P5BIN03-R03','P5-BIN-03','retest',4820),
(35503,1,'P5BIN03-R04','P5-BIN-03','retest',4820),
(35498,2,'P5BIN03-D02','P5-BIN-03','diagnostic',4820),
(35499,2,'P5BIN03-D03','P5-BIN-03','diagnostic',4820),
(35510,2,'P5BIN03-M02','P5-BIN-03','mixed',4820),
(35504,1,'P5GEO02-R03','P5-GEO-02','retest',4820),
(35505,1,'P5GEO02-R04','P5-GEO-02','retest',4820),
(35498,3,'P5GEO02-D02','P5-GEO-02','diagnostic',4820),
(35499,3,'P5GEO02-D03','P5-GEO-02','diagnostic',4820),
(35510,3,'P5GEO02-M02','P5-GEO-02','mixed',4820),
(35506,1,'P5GEO03-R03','P5-GEO-03','retest',4820),
(35507,1,'P5GEO03-R04','P5-GEO-03','retest',4820),
(35498,4,'P5GEO03-D02','P5-GEO-03','diagnostic',4820),
(35499,4,'P5GEO03-D03','P5-GEO-03','diagnostic',4820),
(35510,4,'P5GEO03-M02','P5-GEO-03','mixed',4820),
(35508,1,'P5NOR01-R03','P5-NOR-01','retest',4820),
(35509,1,'P5NOR01-R04','P5-NOR-01','retest',4820),
(35498,5,'P5NOR01-D02','P5-NOR-01','diagnostic',4820),
(35499,5,'P5NOR01-D03','P5-NOR-01','diagnostic',4820),
(35510,5,'P5NOR01-M02','P5-NOR-01','mixed',4820)
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
  if (select count(*) from private.exam_prep_assessments where content_version_id in (4819,4820) and status='draft')<>28
     or (select count(*) from private.exam_prep_assessments where content_version_id in (4819,4820) and assessment_type='diagnostic')<>4
     or (select count(*) from private.exam_prep_assessments where content_version_id in (4819,4820) and assessment_type='retest')<>22
     or (select count(*) from private.exam_prep_assessments where content_version_id in (4819,4820) and assessment_type='mixed')<>2
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id in (4819,4820))<>55
  then raise exception 'aw17_20_annual_reserve_assessments: cardinality mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_assessment_items ai
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  join private.exam_prep_question_content_meta m on m.question_id=ai.question_id and m.content_version_id=a.content_version_id
  where a.content_version_id in (4819,4820)
    and (
      ai.written_task_id is not null
      or ai.is_holdout is not true
      or ai.primary_skill_code<>m.primary_skill_code
      or ai.reserve_role<>m.reserve_role
      or ai.reserve_role<>a.assessment_type
      or ai.primary_skill_code not like a.component_code||'-%'
    );
  if v_bad<>0 then raise exception 'aw17_20_annual_reserve_assessments: role/holdout/component mismatch rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_assessments a
  where a.content_version_id in (4819,4820) and a.assessment_type='retest'
    and (select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id)<>1;
  if v_bad<>0 then raise exception 'aw17_20_annual_reserve_assessments: non-isolated retest rows=%',v_bad; end if;

  if (select count(*) from private.exam_prep_assessment_items where assessment_id in (35483,35484))<>12
     or (select count(*) from private.exam_prep_assessment_items where assessment_id=35497)<>6
     or (select count(*) from private.exam_prep_assessment_items where assessment_id in (35498,35499))<>10
     or (select count(*) from private.exam_prep_assessment_items where assessment_id=35510)<>5
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id in (4819,4820) and ai.is_holdout)<>55
  then raise exception 'aw17_20_annual_reserve_assessments: diagnostic/mixed/holdout coverage mismatch'; end if;
end
$postcheck$;

commit;
