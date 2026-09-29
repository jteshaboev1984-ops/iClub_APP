-- Draft assessment containers for AW1-4 annual reserve top-up.
-- DRAFT ONLY: no assessment is selectable by learners.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4803,4804)
        and status='draft')<>2 then
    raise exception 'aw01_04_annual_reserve_assessments: draft content versions missing';
  end if;

  if exists(
    select 1 from private.exam_prep_assessments
    where id between 35301 and 35324
      and content_version_id not in (4803,4804)
  ) then
    raise exception 'aw01_04_annual_reserve_assessments: reserved assessment id collision';
  end if;
end
$preflight$;

insert into private.exam_prep_assessments(
  id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
  title_en,title_ru,title_uz
)
overriding system value
values
(35301,4803,'P1-AW01-04-diagnostic-variant-02','v1','P1','diagnostic','draft','P1 foundation diagnostic — reserve variant 2','P1: входная проверка — резервный вариант 2','P1: boshlang‘ich tekshiruv — zaxira variant 2'),
(35302,4803,'P1-AW01-04-diagnostic-variant-03','v1','P1','diagnostic','draft','P1 foundation diagnostic — reserve variant 3','P1: входная проверка — резервный вариант 3','P1: boshlang‘ich tekshiruv — zaxira variant 3'),
(35303,4803,'P1-QUA-01-retest-03','v1','P1','retest','draft','P1 quadratic form — delayed check 3','P1: квадратная форма — повторная проверка 3','P1: kvadrat ko‘rinish — qayta tekshiruv 3'),
(35304,4803,'P1-QUA-01-retest-04','v1','P1','retest','draft','P1 quadratic form — delayed check 4','P1: квадратная форма — повторная проверка 4','P1: kvadrat ko‘rinish — qayta tekshiruv 4'),
(35305,4803,'P1-QUA-02-retest-03','v1','P1','retest','draft','P1 discriminant — delayed check 3','P1: дискриминант — повторная проверка 3','P1: diskriminant — qayta tekshiruv 3'),
(35306,4803,'P1-QUA-02-retest-04','v1','P1','retest','draft','P1 discriminant — delayed check 4','P1: дискриминант — повторная проверка 4','P1: diskriminant — qayta tekshiruv 4'),
(35307,4803,'P1-QUA-03-retest-03','v1','P1','retest','draft','P1 quadratic equations — delayed check 3','P1: квадратные уравнения — повторная проверка 3','P1: kvadrat tenglamalar — qayta tekshiruv 3'),
(35308,4803,'P1-QUA-03-retest-04','v1','P1','retest','draft','P1 quadratic equations — delayed check 4','P1: квадратные уравнения — повторная проверка 4','P1: kvadrat tenglamalar — qayta tekshiruv 4'),
(35309,4803,'P1-FUN-01-retest-03','v1','P1','retest','draft','P1 function language — delayed check 3','P1: язык функций — повторная проверка 3','P1: funksiyalar tili — qayta tekshiruv 3'),
(35310,4803,'P1-FUN-01-retest-04','v1','P1','retest','draft','P1 function language — delayed check 4','P1: язык функций — повторная проверка 4','P1: funksiyalar tili — qayta tekshiruv 4'),
(35311,4803,'P1-FUN-02-retest-03','v1','P1','retest','draft','P1 restricted range — delayed check 3','P1: область значений — повторная проверка 3','P1: qiymatlar sohasi — qayta tekshiruv 3'),
(35312,4803,'P1-FUN-02-retest-04','v1','P1','retest','draft','P1 restricted range — delayed check 4','P1: область значений — повторная проверка 4','P1: qiymatlar sohasi — qayta tekshiruv 4'),
(35313,4803,'P1-AW01-04-mixed-transfer-02','v1','P1','mixed','draft','P1 foundations — transfer set 2','P1: основы — перенос навыков 2','P1: asoslar — ko‘nikmani qo‘llash 2'),
(35314,4804,'P5-AW01-04-diagnostic-variant-02','v1','P5','diagnostic','draft','P5 data representation diagnostic — reserve variant 2','P5: представление данных — резервная проверка 2','P5: ma’lumotlarni tasvirlash — zaxira tekshiruv 2'),
(35315,4804,'P5-AW01-04-diagnostic-variant-03','v1','P5','diagnostic','draft','P5 data representation diagnostic — reserve variant 3','P5: представление данных — резервная проверка 3','P5: ma’lumotlarni tasvirlash — zaxira tekshiruv 3'),
(35316,4804,'P5-DAT-01-retest-03','v1','P5','retest','draft','P5 choosing displays — delayed check 3','P5: выбор представления — повторная проверка 3','P5: tasvirni tanlash — qayta tekshiruv 3'),
(35317,4804,'P5-DAT-01-retest-04','v1','P5','retest','draft','P5 choosing displays — delayed check 4','P5: выбор представления — повторная проверка 4','P5: tasvirni tanlash — qayta tekshiruv 4'),
(35318,4804,'P5-DAT-02-retest-03','v1','P5','retest','draft','P5 stem-and-leaf — delayed check 3','P5: стебле-листовая диаграмма — повторная проверка 3','P5: poya-barg diagrammasi — qayta tekshiruv 3'),
(35319,4804,'P5-DAT-02-retest-04','v1','P5','retest','draft','P5 stem-and-leaf — delayed check 4','P5: стебле-листовая диаграмма — повторная проверка 4','P5: poya-barg diagrammasi — qayta tekshiruv 4'),
(35320,4804,'P5-DAT-04-retest-03','v1','P5','retest','draft','P5 histograms — delayed check 3','P5: гистограммы — повторная проверка 3','P5: gistogrammalar — qayta tekshiruv 3'),
(35321,4804,'P5-DAT-04-retest-04','v1','P5','retest','draft','P5 histograms — delayed check 4','P5: гистограммы — повторная проверка 4','P5: gistogrammalar — qayta tekshiruv 4'),
(35322,4804,'P5-DAT-06-retest-03','v1','P5','retest','draft','P5 averages — delayed check 3','P5: средние показатели — повторная проверка 3','P5: markaziy ko‘rsatkichlar — qayta tekshiruv 3'),
(35323,4804,'P5-DAT-06-retest-04','v1','P5','retest','draft','P5 averages — delayed check 4','P5: средние показатели — повторная проверка 4','P5: markaziy ko‘rsatkichlar — qayta tekshiruv 4'),
(35324,4804,'P5-AW01-04-mixed-transfer-02','v1','P5','mixed','draft','P5 data representation — transfer set 2','P5: представление данных — перенос навыков 2','P5: ma’lumotlarni tasvirlash — ko‘nikmani qo‘llash 2')
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with x(assessment_id,item_order,content_key,skill_code,reserve_role,is_holdout) as (values
(35301,1,'P1QUA01-D02','P1-QUA-01','diagnostic',true),
(35301,2,'P1QUA02-D02','P1-QUA-02','diagnostic',true),
(35301,3,'P1QUA03-D02','P1-QUA-03','diagnostic',true),
(35301,4,'P1FUN01-D02','P1-FUN-01','diagnostic',true),
(35301,5,'P1FUN02-D02','P1-FUN-02','diagnostic',true),
(35302,1,'P1QUA01-D03','P1-QUA-01','diagnostic',true),
(35302,2,'P1QUA02-D03','P1-QUA-02','diagnostic',true),
(35302,3,'P1QUA03-D03','P1-QUA-03','diagnostic',true),
(35302,4,'P1FUN01-D03','P1-FUN-01','diagnostic',true),
(35302,5,'P1FUN02-D03','P1-FUN-02','diagnostic',true),
(35303,1,'P1QUA01-R03','P1-QUA-01','retest',true),
(35304,1,'P1QUA01-R04','P1-QUA-01','retest',true),
(35305,1,'P1QUA02-R03','P1-QUA-02','retest',true),
(35306,1,'P1QUA02-R04','P1-QUA-02','retest',true),
(35307,1,'P1QUA03-R03','P1-QUA-03','retest',true),
(35308,1,'P1QUA03-R04','P1-QUA-03','retest',true),
(35309,1,'P1FUN01-R03','P1-FUN-01','retest',true),
(35310,1,'P1FUN01-R04','P1-FUN-01','retest',true),
(35311,1,'P1FUN02-R03','P1-FUN-02','retest',true),
(35312,1,'P1FUN02-R04','P1-FUN-02','retest',true),
(35313,1,'P1QUA01-M02','P1-QUA-01','mixed',true),
(35313,2,'P1QUA02-M02','P1-QUA-02','mixed',true),
(35313,3,'P1QUA03-M02','P1-QUA-03','mixed',true),
(35313,4,'P1FUN01-M02','P1-FUN-01','mixed',true),
(35313,5,'P1FUN02-M02','P1-FUN-02','mixed',true),
(35314,1,'P5DAT01-D02','P5-DAT-01','diagnostic',true),
(35314,2,'P5DAT02-D02','P5-DAT-02','diagnostic',true),
(35314,3,'P5DAT04-D02','P5-DAT-04','diagnostic',true),
(35314,4,'P5DAT06-D02','P5-DAT-06','diagnostic',true),
(35315,1,'P5DAT01-D03','P5-DAT-01','diagnostic',true),
(35315,2,'P5DAT02-D03','P5-DAT-02','diagnostic',true),
(35315,3,'P5DAT04-D03','P5-DAT-04','diagnostic',true),
(35315,4,'P5DAT06-D03','P5-DAT-06','diagnostic',true),
(35316,1,'P5DAT01-R03','P5-DAT-01','retest',true),
(35317,1,'P5DAT01-R04','P5-DAT-01','retest',true),
(35318,1,'P5DAT02-R03','P5-DAT-02','retest',true),
(35319,1,'P5DAT02-R04','P5-DAT-02','retest',true),
(35320,1,'P5DAT04-R03','P5-DAT-04','retest',true),
(35321,1,'P5DAT04-R04','P5-DAT-04','retest',true),
(35322,1,'P5DAT06-R03','P5-DAT-06','retest',true),
(35323,1,'P5DAT06-R04','P5-DAT-06','retest',true),
(35324,1,'P5DAT01-M02','P5-DAT-01','mixed',true),
(35324,2,'P5DAT02-M02','P5-DAT-02','mixed',true),
(35324,3,'P5DAT04-M02','P5-DAT-04','mixed',true),
(35324,4,'P5DAT06-M02','P5-DAT-06','mixed',true)
)
insert into private.exam_prep_assessment_items(
  assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select
  x.assessment_id,x.item_order,m.question_id,null,x.skill_code,x.reserve_role,x.is_holdout
from x
join private.exam_prep_assessments a on a.id=x.assessment_id
join private.exam_prep_question_content_meta m
  on m.content_version_id=a.content_version_id
 and m.content_key=x.content_key
 and m.primary_skill_code=x.skill_code
 and m.reserve_role=x.reserve_role
on conflict(assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_assessments
      where id between 35301 and 35324 and status='draft')<>24
     or (select count(*) from private.exam_prep_assessments
         where id between 35301 and 35324 and assessment_type='diagnostic')<>4
     or (select count(*) from private.exam_prep_assessments
         where id between 35301 and 35324 and assessment_type='retest')<>18
     or (select count(*) from private.exam_prep_assessments
         where id between 35301 and 35324 and assessment_type='mixed')<>2
     or (select count(*) from private.exam_prep_assessment_items ai
         where ai.assessment_id between 35301 and 35324)<>45
  then
    raise exception 'aw01_04_annual_reserve_assessments: cardinality mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_assessment_items ai
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  join private.exam_prep_question_content_meta m on m.question_id=ai.question_id
  where ai.assessment_id between 35301 and 35324
    and (
      a.status<>'draft'
      or m.content_version_id<>a.content_version_id
      or ai.written_task_id is not null
      or not ai.is_holdout
      or ai.primary_skill_code<>m.primary_skill_code
      or ai.reserve_role<>m.reserve_role
      or ai.reserve_role<>a.assessment_type
    );
  if v_bad<>0 then
    raise exception 'aw01_04_annual_reserve_assessments: item linkage/role mismatch rows=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.id between 35301 and 35324
    group by a.id,a.assessment_type
    having (a.assessment_type='retest' and count(*)<>1)
        or (a.assessment_type='diagnostic' and count(*) not in (4,5))
        or (a.assessment_type='mixed' and count(*) not in (4,5))
  ) then
    raise exception 'aw01_04_annual_reserve_assessments: assessment shape mismatch';
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    where s.assessment_id between 35301 and 35324
  ) then
    raise exception 'aw01_04_annual_reserve_assessments: learner session exists on draft';
  end if;
end
$postcheck$;

commit;
