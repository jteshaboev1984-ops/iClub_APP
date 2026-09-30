-- Draft assessment containers for AW9-12 annual reserve top-up.
-- DRAFT ONLY: all reserve items remain withheld and unselectable.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
 if (select count(*) from private.exam_prep_content_versions where id in (4811,4812) and status='draft')<>2
 then raise exception 'aw09_12_annual_reserve_assessments: draft versions missing'; end if;
 if exists(select 1 from private.exam_prep_assessments where id between 35387 and 35420 and content_version_id not in (4811,4812))
 then raise exception 'aw09_12_annual_reserve_assessments: reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35387,4811,'P1-AW09-12-diagnostic-variant-02','v1','P1','diagnostic','draft','P1 diagnostic — alternative form 2','P1: диагностика — альтернативный вариант 2','P1: diagnostika — muqobil variant 2'),
(35388,4811,'P1-AW09-12-diagnostic-variant-03','v1','P1','diagnostic','draft','P1 diagnostic — alternative form 3','P1: диагностика — альтернативный вариант 3','P1: diagnostika — muqobil variant 3'),
(35389,4811,'P1-QUA-04-retest-03','v1','P1','retest','draft','Quadratic inequalities — delayed check 3','Квадратные неравенства — повторная проверка 3','Kvadrat tengsizliklar — qayta tekshiruv 3'),
(35390,4811,'P1-QUA-04-retest-04','v1','P1','retest','draft','Quadratic inequalities — delayed check 4','Квадратные неравенства — повторная проверка 4','Kvadrat tengsizliklar — qayta tekshiruv 4'),
(35391,4811,'P1-QUA-05-retest-03','v1','P1','retest','draft','Linear–quadratic systems — delayed check 3','Линейно-квадратичные системы — повторная проверка 3','Chiziqli-kvadrat sistemalar — qayta tekshiruv 3'),
(35392,4811,'P1-QUA-05-retest-04','v1','P1','retest','draft','Linear–quadratic systems — delayed check 4','Линейно-квадратичные системы — повторная проверка 4','Chiziqli-kvadrat sistemalar — qayta tekshiruv 4'),
(35393,4811,'P1-QUA-06-retest-03','v1','P1','retest','draft','Transformed quadratic equations — delayed check 3','Уравнения с заменой переменной — повторная проверка 3','O‘zgaruvchi almashtirishli kvadrat tenglamalar — qayta tekshiruv 3'),
(35394,4811,'P1-QUA-06-retest-04','v1','P1','retest','draft','Transformed quadratic equations — delayed check 4','Уравнения с заменой переменной — повторная проверка 4','O‘zgaruvchi almashtirishli kvadrat tenglamalar — qayta tekshiruv 4'),
(35395,4811,'P1-FUN-03-retest-03','v1','P1','retest','draft','Composite functions and domains — delayed check 3','Композиции функций и области определения — повторная проверка 3','Funksiya kompozitsiyalari va aniqlanish sohalari — qayta tekshiruv 3'),
(35396,4811,'P1-FUN-03-retest-04','v1','P1','retest','draft','Composite functions and domains — delayed check 4','Композиции функций и области определения — повторная проверка 4','Funksiya kompozitsiyalari va aniqlanish sohalari — qayta tekshiruv 4'),
(35397,4811,'P1-FUN-04-retest-03','v1','P1','retest','draft','Inverse functions — delayed check 3','Обратные функции — повторная проверка 3','Teskari funksiyalar — qayta tekshiruv 3'),
(35398,4811,'P1-FUN-04-retest-04','v1','P1','retest','draft','Inverse functions — delayed check 4','Обратные функции — повторная проверка 4','Teskari funksiyalar — qayta tekshiruv 4'),
(35399,4811,'P1-FUN-05-retest-03','v1','P1','retest','draft','Inverse-function graphs — delayed check 3','Графики обратных функций — повторная проверка 3','Teskari funksiya grafiklari — qayta tekshiruv 3'),
(35400,4811,'P1-FUN-05-retest-04','v1','P1','retest','draft','Inverse-function graphs — delayed check 4','Графики обратных функций — повторная проверка 4','Teskari funksiya grafiklari — qayta tekshiruv 4'),
(35401,4811,'P1-COO-04-retest-03','v1','P1','retest','draft','Circles in coordinate geometry — delayed check 3','Окружности в координатной геометрии — повторная проверка 3','Koordinata geometriyasida aylanalar — qayta tekshiruv 3'),
(35402,4811,'P1-COO-04-retest-04','v1','P1','retest','draft','Circles in coordinate geometry — delayed check 4','Окружности в координатной геометрии — повторная проверка 4','Koordinata geometriyasida aylanalar — qayta tekshiruv 4'),
(35403,4811,'P1-CIR-02-retest-03','v1','P1','retest','draft','Arc length — delayed check 3','Длина дуги — повторная проверка 3','Yoy uzunligi — qayta tekshiruv 3'),
(35404,4811,'P1-CIR-02-retest-04','v1','P1','retest','draft','Arc length — delayed check 4','Длина дуги — повторная проверка 4','Yoy uzunligi — qayta tekshiruv 4'),
(35405,4811,'P1-AW09-12-mixed-transfer-02','v1','P1','mixed','draft','P1 mixed transfer — alternative set 2','P1: смешанный перенос — альтернативный набор 2','P1: aralash qo‘llash — muqobil to‘plam 2'),
(35406,4812,'P5-AW09-12-diagnostic-variant-02','v1','P5','diagnostic','draft','P5 diagnostic — alternative form 2','P5: диагностика — альтернативный вариант 2','P5: diagnostika — muqobil variant 2'),
(35407,4812,'P5-AW09-12-diagnostic-variant-03','v1','P5','diagnostic','draft','P5 diagnostic — alternative form 3','P5: диагностика — альтернативный вариант 3','P5: diagnostika — muqobil variant 3'),
(35408,4812,'P5-DAT-03-retest-03','v1','P5','retest','draft','Box plots and outliers — delayed check 3','Диаграммы размаха и выбросы — повторная проверка 3','Box plot va chet qiymatlar — qayta tekshiruv 3'),
(35409,4812,'P5-DAT-03-retest-04','v1','P5','retest','draft','Box plots and outliers — delayed check 4','Диаграммы размаха и выбросы — повторная проверка 4','Box plot va chet qiymatlar — qayta tekshiruv 4'),
(35410,4812,'P5-DAT-05-retest-03','v1','P5','retest','draft','Cumulative frequency — delayed check 3','Накопленная частота — повторная проверка 3','Kumulyativ chastota — qayta tekshiruv 3'),
(35411,4812,'P5-DAT-05-retest-04','v1','P5','retest','draft','Cumulative frequency — delayed check 4','Накопленная частота — повторная проверка 4','Kumulyativ chastota — qayta tekshiruv 4'),
(35412,4812,'P5-DAT-07-retest-03','v1','P5','retest','draft','Measures of spread — delayed check 3','Меры разброса — повторная проверка 3','Tarqoqlik o‘lchovlari — qayta tekshiruv 3'),
(35413,4812,'P5-DAT-07-retest-04','v1','P5','retest','draft','Measures of spread — delayed check 4','Меры разброса — повторная проверка 4','Tarqoqlik o‘lchovlari — qayta tekshiruv 4'),
(35414,4812,'P5-CNT-05-retest-03','v1','P5','retest','draft','Combinations and selections — delayed check 3','Сочетания и выбор — повторная проверка 3','Kombinatsiyalar va tanlash — qayta tekshiruv 3'),
(35415,4812,'P5-CNT-05-retest-04','v1','P5','retest','draft','Combinations and selections — delayed check 4','Сочетания и выбор — повторная проверка 4','Kombinatsiyalar va tanlash — qayta tekshiruv 4'),
(35416,4812,'P5-PRO-02-retest-03','v1','P5','retest','draft','Probability with combinations — delayed check 3','Вероятность с сочетаниями — повторная проверка 3','Kombinatsiyalar bilan ehtimollik — qayta tekshiruv 3'),
(35417,4812,'P5-PRO-02-retest-04','v1','P5','retest','draft','Probability with combinations — delayed check 4','Вероятность с сочетаниями — повторная проверка 4','Kombinatsiyalar bilan ehtimollik — qayta tekshiruv 4'),
(35418,4812,'P5-PRO-04-retest-03','v1','P5','retest','draft','Multiplication rule and independence — delayed check 3','Правило умножения и независимость — повторная проверка 3','Ko‘paytirish qoidasi va mustaqillik — qayta tekshiruv 3'),
(35419,4812,'P5-PRO-04-retest-04','v1','P5','retest','draft','Multiplication rule and independence — delayed check 4','Правило умножения и независимость — повторная проверка 4','Ko‘paytirish qoidasi va mustaqillik — qayta tekshiruv 4'),
(35420,4812,'P5-AW09-12-mixed-transfer-02','v1','P5','mixed','draft','P5 mixed transfer — alternative set 2','P5: смешанный перенос — альтернативный набор 2','P5: aralash qo‘llash — muqobil to‘plam 2')
on conflict(id) do nothing;

with src(assessment_id,item_order,content_key,skill_code,reserve_role,content_version_id) as (values
(35389,1,'P1QUA04-R03','P1-QUA-04','retest',4811),
(35390,1,'P1QUA04-R04','P1-QUA-04','retest',4811),
(35391,1,'P1QUA05-R03','P1-QUA-05','retest',4811),
(35392,1,'P1QUA05-R04','P1-QUA-05','retest',4811),
(35393,1,'P1QUA06-R03','P1-QUA-06','retest',4811),
(35394,1,'P1QUA06-R04','P1-QUA-06','retest',4811),
(35395,1,'P1FUN03-R03','P1-FUN-03','retest',4811),
(35396,1,'P1FUN03-R04','P1-FUN-03','retest',4811),
(35397,1,'P1FUN04-R03','P1-FUN-04','retest',4811),
(35398,1,'P1FUN04-R04','P1-FUN-04','retest',4811),
(35399,1,'P1FUN05-R03','P1-FUN-05','retest',4811),
(35400,1,'P1FUN05-R04','P1-FUN-05','retest',4811),
(35401,1,'P1COO04-R03','P1-COO-04','retest',4811),
(35402,1,'P1COO04-R04','P1-COO-04','retest',4811),
(35403,1,'P1CIR02-R03','P1-CIR-02','retest',4811),
(35404,1,'P1CIR02-R04','P1-CIR-02','retest',4811),
(35408,1,'P5DAT03-R03','P5-DAT-03','retest',4812),
(35409,1,'P5DAT03-R04','P5-DAT-03','retest',4812),
(35410,1,'P5DAT05-R03','P5-DAT-05','retest',4812),
(35411,1,'P5DAT05-R04','P5-DAT-05','retest',4812),
(35412,1,'P5DAT07-R03','P5-DAT-07','retest',4812),
(35413,1,'P5DAT07-R04','P5-DAT-07','retest',4812),
(35414,1,'P5CNT05-R03','P5-CNT-05','retest',4812),
(35415,1,'P5CNT05-R04','P5-CNT-05','retest',4812),
(35416,1,'P5PRO02-R03','P5-PRO-02','retest',4812),
(35417,1,'P5PRO02-R04','P5-PRO-02','retest',4812),
(35418,1,'P5PRO04-R03','P5-PRO-04','retest',4812),
(35419,1,'P5PRO04-R04','P5-PRO-04','retest',4812),
(35387,1,'P1QUA04-D02','P1-QUA-04','diagnostic',4811),
(35388,1,'P1QUA04-D03','P1-QUA-04','diagnostic',4811),
(35405,1,'P1QUA04-M02','P1-QUA-04','mixed',4811),
(35387,2,'P1QUA05-D02','P1-QUA-05','diagnostic',4811),
(35388,2,'P1QUA05-D03','P1-QUA-05','diagnostic',4811),
(35405,2,'P1QUA05-M02','P1-QUA-05','mixed',4811),
(35387,3,'P1QUA06-D02','P1-QUA-06','diagnostic',4811),
(35388,3,'P1QUA06-D03','P1-QUA-06','diagnostic',4811),
(35405,3,'P1QUA06-M02','P1-QUA-06','mixed',4811),
(35387,4,'P1FUN03-D02','P1-FUN-03','diagnostic',4811),
(35388,4,'P1FUN03-D03','P1-FUN-03','diagnostic',4811),
(35405,4,'P1FUN03-M02','P1-FUN-03','mixed',4811),
(35387,5,'P1FUN04-D02','P1-FUN-04','diagnostic',4811),
(35388,5,'P1FUN04-D03','P1-FUN-04','diagnostic',4811),
(35405,5,'P1FUN04-M02','P1-FUN-04','mixed',4811),
(35387,6,'P1FUN05-D02','P1-FUN-05','diagnostic',4811),
(35388,6,'P1FUN05-D03','P1-FUN-05','diagnostic',4811),
(35405,6,'P1FUN05-M02','P1-FUN-05','mixed',4811),
(35387,7,'P1COO04-D02','P1-COO-04','diagnostic',4811),
(35388,7,'P1COO04-D03','P1-COO-04','diagnostic',4811),
(35405,7,'P1COO04-M02','P1-COO-04','mixed',4811),
(35387,8,'P1CIR02-D02','P1-CIR-02','diagnostic',4811),
(35388,8,'P1CIR02-D03','P1-CIR-02','diagnostic',4811),
(35405,8,'P1CIR02-M02','P1-CIR-02','mixed',4811),
(35406,1,'P5DAT03-D02','P5-DAT-03','diagnostic',4812),
(35407,1,'P5DAT03-D03','P5-DAT-03','diagnostic',4812),
(35420,1,'P5DAT03-M02','P5-DAT-03','mixed',4812),
(35406,2,'P5DAT05-D02','P5-DAT-05','diagnostic',4812),
(35407,2,'P5DAT05-D03','P5-DAT-05','diagnostic',4812),
(35420,2,'P5DAT05-M02','P5-DAT-05','mixed',4812),
(35406,3,'P5DAT07-D02','P5-DAT-07','diagnostic',4812),
(35407,3,'P5DAT07-D03','P5-DAT-07','diagnostic',4812),
(35420,3,'P5DAT07-M02','P5-DAT-07','mixed',4812),
(35406,4,'P5CNT05-D02','P5-CNT-05','diagnostic',4812),
(35407,4,'P5CNT05-D03','P5-CNT-05','diagnostic',4812),
(35420,4,'P5CNT05-M02','P5-CNT-05','mixed',4812),
(35406,5,'P5PRO02-D02','P5-PRO-02','diagnostic',4812),
(35407,5,'P5PRO02-D03','P5-PRO-02','diagnostic',4812),
(35420,5,'P5PRO02-M02','P5-PRO-02','mixed',4812),
(35406,6,'P5PRO04-D02','P5-PRO-04','diagnostic',4812),
(35407,6,'P5PRO04-D03','P5-PRO-04','diagnostic',4812),
(35420,6,'P5PRO04-M02','P5-PRO-04','mixed',4812)
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
 if (select count(*) from private.exam_prep_assessments where content_version_id in (4811,4812) and status='draft')<>34
    or (select count(*) from private.exam_prep_assessments where content_version_id in (4811,4812) and assessment_type='diagnostic')<>4
    or (select count(*) from private.exam_prep_assessments where content_version_id in (4811,4812) and assessment_type='retest')<>28
    or (select count(*) from private.exam_prep_assessments where content_version_id in (4811,4812) and assessment_type='mixed')<>2
    or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id in (4811,4812))<>70
 then raise exception 'aw09_12_annual_reserve_assessments: cardinality mismatch'; end if;

 select count(*) into v_bad
 from private.exam_prep_assessment_items ai
 join private.exam_prep_assessments a on a.id=ai.assessment_id
 join private.exam_prep_question_content_meta m on m.question_id=ai.question_id and m.content_version_id=a.content_version_id
 where a.content_version_id in (4811,4812)
   and (
     ai.written_task_id is not null
     or ai.is_holdout is not true
     or ai.primary_skill_code<>m.primary_skill_code
     or ai.reserve_role<>m.reserve_role
     or ai.reserve_role<>a.assessment_type
     or ai.primary_skill_code not like a.component_code||'-%'
   );
 if v_bad<>0 then raise exception 'aw09_12_annual_reserve_assessments: role/holdout/component mismatch rows=%',v_bad; end if;

 select count(*) into v_bad
 from private.exam_prep_assessments a
 where a.content_version_id in (4811,4812)
   and a.assessment_type='retest'
   and (select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id)<>1;
 if v_bad<>0 then raise exception 'aw09_12_annual_reserve_assessments: non-isolated retest rows=%',v_bad; end if;

 if exists(
   select 1 from private.exam_prep_assessments a
   where a.id in (35387,35388,35406,35407)
     and (
       (a.component_code='P1' and (select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id)<>8)
       or (a.component_code='P5' and (select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id)<>6)
     )
 ) then raise exception 'aw09_12_annual_reserve_assessments: diagnostic variant coverage mismatch'; end if;

 if (select count(*) from private.exam_prep_assessment_items where assessment_id=35405)<>8
    or (select count(*) from private.exam_prep_assessment_items where assessment_id=35420)<>6
 then raise exception 'aw09_12_annual_reserve_assessments: mixed transfer coverage mismatch'; end if;
end
$postcheck$;

commit;
