-- Draft assessment containers for AW13-16 annual reserve top-up.
-- DRAFT ONLY: all reserve items remain withheld and unselectable.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_content_versions where id in (4815,4816) and status='draft')<>2
  then raise exception 'aw13_16_annual_reserve_assessments: draft versions missing'; end if;
  if exists(select 1 from private.exam_prep_assessments where id between 35436 and 35471 and content_version_id not in (4815,4816))
  then raise exception 'aw13_16_annual_reserve_assessments: reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35436,4815,'P1-AW13-16-diagnostic-variant-02','v1','P1','diagnostic','draft','P1 diagnostic — alternative form 2','P1: диагностика — альтернативный вариант 2','P1: diagnostika — muqobil variant 2'),
(35437,4815,'P1-AW13-16-diagnostic-variant-03','v1','P1','diagnostic','draft','P1 diagnostic — alternative form 3','P1: диагностика — альтернативный вариант 3','P1: diagnostika — muqobil variant 3'),
(35438,4815,'P1-CIR-03-retest-03','v1','P1','retest','draft','Sector and segment area — delayed check 3','Площади секторов и сегментов — повторная проверка 3','Sektor va segment yuzlari — qayta tekshiruv 3'),
(35439,4815,'P1-CIR-03-retest-04','v1','P1','retest','draft','Sector and segment area — delayed check 4','Площади секторов и сегментов — повторная проверка 4','Sektor va segment yuzlari — qayta tekshiruv 4'),
(35440,4815,'P1-TRI-02-retest-03','v1','P1','retest','draft','Exact trigonometric values — delayed check 3','Точные тригонометрические значения — повторная проверка 3','Aniq trigonometrik qiymatlar — qayta tekshiruv 3'),
(35441,4815,'P1-TRI-02-retest-04','v1','P1','retest','draft','Exact trigonometric values — delayed check 4','Точные тригонометрические значения — повторная проверка 4','Aniq trigonometrik qiymatlar — qayta tekshiruv 4'),
(35442,4815,'P1-TRI-03-retest-03','v1','P1','retest','draft','Inverse trigonometric principal values — delayed check 3','Главные значения обратных тригонометрических функций — повторная проверка 3','Teskari trigonometrik funksiyalarning bosh qiymatlari — qayta tekshiruv 3'),
(35443,4815,'P1-TRI-03-retest-04','v1','P1','retest','draft','Inverse trigonometric principal values — delayed check 4','Главные значения обратных тригонометрических функций — повторная проверка 4','Teskari trigonometrik funksiyalarning bosh qiymatlari — qayta tekshiruv 4'),
(35444,4815,'P1-TRI-04-retest-03','v1','P1','retest','draft','Trigonometric identities — delayed check 3','Тригонометрические тождества — повторная проверка 3','Trigonometrik ayniyatlar — qayta tekshiruv 3'),
(35445,4815,'P1-TRI-04-retest-04','v1','P1','retest','draft','Trigonometric identities — delayed check 4','Тригонометрические тождества — повторная проверка 4','Trigonometrik ayniyatlar — qayta tekshiruv 4'),
(35446,4815,'P1-TRI-05-retest-03','v1','P1','retest','draft','Trigonometric equations — delayed check 3','Тригонометрические уравнения — повторная проверка 3','Trigonometrik tenglamalar — qayta tekshiruv 3'),
(35447,4815,'P1-TRI-05-retest-04','v1','P1','retest','draft','Trigonometric equations — delayed check 4','Тригонометрические уравнения — повторная проверка 4','Trigonometrik tenglamalar — qayta tekshiruv 4'),
(35448,4815,'P1-SER-01-retest-03','v1','P1','retest','draft','Binomial expansion — delayed check 3','Биномиальное разложение — повторная проверка 3','Binomial yoyilma — qayta tekshiruv 3'),
(35449,4815,'P1-SER-01-retest-04','v1','P1','retest','draft','Binomial expansion — delayed check 4','Биномиальное разложение — повторная проверка 4','Binomial yoyilma — qayta tekshiruv 4'),
(35450,4815,'P1-SER-02-retest-03','v1','P1','retest','draft','Arithmetic and geometric progressions — delayed check 3','Арифметические и геометрические прогрессии — повторная проверка 3','Arifmetik va geometrik progressiyalar — qayta tekshiruv 3'),
(35451,4815,'P1-SER-02-retest-04','v1','P1','retest','draft','Arithmetic and geometric progressions — delayed check 4','Арифметические и геометрические прогрессии — повторная проверка 4','Arifmetik va geometrik progressiyalar — qayta tekshiruv 4'),
(35452,4815,'P1-DIF-01-retest-03','v1','P1','retest','draft','Derivative as gradient and rate — delayed check 3','Производная как градиент и скорость изменения — повторная проверка 3','Hosila gradient va o‘zgarish tezligi sifatida — qayta tekshiruv 3'),
(35453,4815,'P1-DIF-01-retest-04','v1','P1','retest','draft','Derivative as gradient and rate — delayed check 4','Производная как градиент и скорость изменения — повторная проверка 4','Hosila gradient va o‘zgarish tezligi sifatida — qayta tekshiruv 4'),
(35454,4815,'P1-AW13-16-mixed-transfer-02','v1','P1','mixed','draft','P1 mixed transfer — alternative set 2','P1: смешанный перенос — альтернативный набор 2','P1: aralash qo‘llash — muqobil to‘plam 2'),
(35455,4816,'P5-AW13-16-diagnostic-variant-02','v1','P5','diagnostic','draft','P5 diagnostic — alternative form 2','P5: диагностика — альтернативный вариант 2','P5: diagnostika — muqobil variant 2'),
(35456,4816,'P5-AW13-16-diagnostic-variant-03','v1','P5','diagnostic','draft','P5 diagnostic — alternative form 3','P5: диагностика — альтернативный вариант 3','P5: diagnostika — muqobil variant 3'),
(35457,4816,'P5-PRO-05-retest-03','v1','P5','retest','draft','Conditional probability — delayed check 3','Условная вероятность — повторная проверка 3','Shartli ehtimollik — qayta tekshiruv 3'),
(35458,4816,'P5-PRO-05-retest-04','v1','P5','retest','draft','Conditional probability — delayed check 4','Условная вероятность — повторная проверка 4','Shartli ehtimollik — qayta tekshiruv 4'),
(35459,4816,'P5-PRO-06-retest-03','v1','P5','retest','draft','Probability trees — delayed check 3','Деревья вероятностей — повторная проверка 3','Ehtimollar daraxti — qayta tekshiruv 3'),
(35460,4816,'P5-PRO-06-retest-04','v1','P5','retest','draft','Probability trees — delayed check 4','Деревья вероятностей — повторная проверка 4','Ehtimollar daraxti — qayta tekshiruv 4'),
(35461,4816,'P5-DRV-01-retest-03','v1','P5','retest','draft','Discrete probability distributions — delayed check 3','Дискретные распределения вероятностей — повторная проверка 3','Diskret ehtimollar taqsimoti — qayta tekshiruv 3'),
(35462,4816,'P5-DRV-01-retest-04','v1','P5','retest','draft','Discrete probability distributions — delayed check 4','Дискретные распределения вероятностей — повторная проверка 4','Diskret ehtimollar taqsimoti — qayta tekshiruv 4'),
(35463,4816,'P5-DRV-02-retest-03','v1','P5','retest','draft','Expected value — delayed check 3','Математическое ожидание — повторная проверка 3','Kutiladigan qiymat — qayta tekshiruv 3'),
(35464,4816,'P5-DRV-02-retest-04','v1','P5','retest','draft','Expected value — delayed check 4','Математическое ожидание — повторная проверка 4','Kutiladigan qiymat — qayta tekshiruv 4'),
(35465,4816,'P5-DRV-03-retest-03','v1','P5','retest','draft','Variance and standard deviation — delayed check 3','Дисперсия и стандартное отклонение — повторная проверка 3','Dispersiya va standart og‘ish — qayta tekshiruv 3'),
(35466,4816,'P5-DRV-03-retest-04','v1','P5','retest','draft','Variance and standard deviation — delayed check 4','Дисперсия и стандартное отклонение — повторная проверка 4','Dispersiya va standart og‘ish — qayta tekshiruv 4'),
(35467,4816,'P5-BIN-01-retest-03','v1','P5','retest','draft','Recognising a binomial model — delayed check 3','Распознавание биномиальной модели — повторная проверка 3','Binomial modelni aniqlash — qayta tekshiruv 3'),
(35468,4816,'P5-BIN-01-retest-04','v1','P5','retest','draft','Recognising a binomial model — delayed check 4','Распознавание биномиальной модели — повторная проверка 4','Binomial modelni aniqlash — qayta tekshiruv 4'),
(35469,4816,'P5-GEO-01-retest-03','v1','P5','retest','draft','Recognising a geometric model — delayed check 3','Распознавание геометрической модели — повторная проверка 3','Geometrik modelni aniqlash — qayta tekshiruv 3'),
(35470,4816,'P5-GEO-01-retest-04','v1','P5','retest','draft','Recognising a geometric model — delayed check 4','Распознавание геометрической модели — повторная проверка 4','Geometrik modelni aniqlash — qayta tekshiruv 4'),
(35471,4816,'P5-AW13-16-mixed-transfer-02','v1','P5','mixed','draft','P5 mixed transfer — alternative set 2','P5: смешанный перенос — альтернативный набор 2','P5: aralash qo‘llash — muqobil to‘plam 2')
on conflict(id) do nothing;

with src(assessment_id,item_order,content_key,skill_code,reserve_role,content_version_id) as (values
(35436,1,'P1CIR03-D02','P1-CIR-03','diagnostic',4815),
(35437,1,'P1CIR03-D03','P1-CIR-03','diagnostic',4815),
(35454,1,'P1CIR03-M02','P1-CIR-03','mixed',4815),
(35438,1,'P1CIR03-R03','P1-CIR-03','retest',4815),
(35439,1,'P1CIR03-R04','P1-CIR-03','retest',4815),
(35436,2,'P1TRI02-D02','P1-TRI-02','diagnostic',4815),
(35437,2,'P1TRI02-D03','P1-TRI-02','diagnostic',4815),
(35454,2,'P1TRI02-M02','P1-TRI-02','mixed',4815),
(35440,1,'P1TRI02-R03','P1-TRI-02','retest',4815),
(35441,1,'P1TRI02-R04','P1-TRI-02','retest',4815),
(35436,3,'P1TRI03-D02','P1-TRI-03','diagnostic',4815),
(35437,3,'P1TRI03-D03','P1-TRI-03','diagnostic',4815),
(35454,3,'P1TRI03-M02','P1-TRI-03','mixed',4815),
(35442,1,'P1TRI03-R03','P1-TRI-03','retest',4815),
(35443,1,'P1TRI03-R04','P1-TRI-03','retest',4815),
(35436,4,'P1TRI04-D02','P1-TRI-04','diagnostic',4815),
(35437,4,'P1TRI04-D03','P1-TRI-04','diagnostic',4815),
(35454,4,'P1TRI04-M02','P1-TRI-04','mixed',4815),
(35444,1,'P1TRI04-R03','P1-TRI-04','retest',4815),
(35445,1,'P1TRI04-R04','P1-TRI-04','retest',4815),
(35436,5,'P1TRI05-D02','P1-TRI-05','diagnostic',4815),
(35437,5,'P1TRI05-D03','P1-TRI-05','diagnostic',4815),
(35454,5,'P1TRI05-M02','P1-TRI-05','mixed',4815),
(35446,1,'P1TRI05-R03','P1-TRI-05','retest',4815),
(35447,1,'P1TRI05-R04','P1-TRI-05','retest',4815),
(35436,6,'P1SER01-D02','P1-SER-01','diagnostic',4815),
(35437,6,'P1SER01-D03','P1-SER-01','diagnostic',4815),
(35454,6,'P1SER01-M02','P1-SER-01','mixed',4815),
(35448,1,'P1SER01-R03','P1-SER-01','retest',4815),
(35449,1,'P1SER01-R04','P1-SER-01','retest',4815),
(35436,7,'P1SER02-D02','P1-SER-02','diagnostic',4815),
(35437,7,'P1SER02-D03','P1-SER-02','diagnostic',4815),
(35454,7,'P1SER02-M02','P1-SER-02','mixed',4815),
(35450,1,'P1SER02-R03','P1-SER-02','retest',4815),
(35451,1,'P1SER02-R04','P1-SER-02','retest',4815),
(35436,8,'P1DIF01-D02','P1-DIF-01','diagnostic',4815),
(35437,8,'P1DIF01-D03','P1-DIF-01','diagnostic',4815),
(35454,8,'P1DIF01-M02','P1-DIF-01','mixed',4815),
(35452,1,'P1DIF01-R03','P1-DIF-01','retest',4815),
(35453,1,'P1DIF01-R04','P1-DIF-01','retest',4815),
(35455,1,'P5PRO05-D02','P5-PRO-05','diagnostic',4816),
(35456,1,'P5PRO05-D03','P5-PRO-05','diagnostic',4816),
(35471,1,'P5PRO05-M02','P5-PRO-05','mixed',4816),
(35457,1,'P5PRO05-R03','P5-PRO-05','retest',4816),
(35458,1,'P5PRO05-R04','P5-PRO-05','retest',4816),
(35455,2,'P5PRO06-D02','P5-PRO-06','diagnostic',4816),
(35456,2,'P5PRO06-D03','P5-PRO-06','diagnostic',4816),
(35471,2,'P5PRO06-M02','P5-PRO-06','mixed',4816),
(35459,1,'P5PRO06-R03','P5-PRO-06','retest',4816),
(35460,1,'P5PRO06-R04','P5-PRO-06','retest',4816),
(35455,3,'P5DRV01-D02','P5-DRV-01','diagnostic',4816),
(35456,3,'P5DRV01-D03','P5-DRV-01','diagnostic',4816),
(35471,3,'P5DRV01-M02','P5-DRV-01','mixed',4816),
(35461,1,'P5DRV01-R03','P5-DRV-01','retest',4816),
(35462,1,'P5DRV01-R04','P5-DRV-01','retest',4816),
(35455,4,'P5DRV02-D02','P5-DRV-02','diagnostic',4816),
(35456,4,'P5DRV02-D03','P5-DRV-02','diagnostic',4816),
(35471,4,'P5DRV02-M02','P5-DRV-02','mixed',4816),
(35463,1,'P5DRV02-R03','P5-DRV-02','retest',4816),
(35464,1,'P5DRV02-R04','P5-DRV-02','retest',4816),
(35455,5,'P5DRV03-D02','P5-DRV-03','diagnostic',4816),
(35456,5,'P5DRV03-D03','P5-DRV-03','diagnostic',4816),
(35471,5,'P5DRV03-M02','P5-DRV-03','mixed',4816),
(35465,1,'P5DRV03-R03','P5-DRV-03','retest',4816),
(35466,1,'P5DRV03-R04','P5-DRV-03','retest',4816),
(35455,6,'P5BIN01-D02','P5-BIN-01','diagnostic',4816),
(35456,6,'P5BIN01-D03','P5-BIN-01','diagnostic',4816),
(35471,6,'P5BIN01-M02','P5-BIN-01','mixed',4816),
(35467,1,'P5BIN01-R03','P5-BIN-01','retest',4816),
(35468,1,'P5BIN01-R04','P5-BIN-01','retest',4816),
(35455,7,'P5GEO01-D02','P5-GEO-01','diagnostic',4816),
(35456,7,'P5GEO01-D03','P5-GEO-01','diagnostic',4816),
(35471,7,'P5GEO01-M02','P5-GEO-01','mixed',4816),
(35469,1,'P5GEO01-R03','P5-GEO-01','retest',4816),
(35470,1,'P5GEO01-R04','P5-GEO-01','retest',4816)
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
  if (select count(*) from private.exam_prep_assessments where content_version_id in (4815,4816) and status='draft')<>36
     or (select count(*) from private.exam_prep_assessments where content_version_id in (4815,4816) and assessment_type='diagnostic')<>4
     or (select count(*) from private.exam_prep_assessments where content_version_id in (4815,4816) and assessment_type='retest')<>30
     or (select count(*) from private.exam_prep_assessments where content_version_id in (4815,4816) and assessment_type='mixed')<>2
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id in (4815,4816))<>75
  then raise exception 'aw13_16_annual_reserve_assessments: cardinality mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_assessment_items ai
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  join private.exam_prep_question_content_meta m on m.question_id=ai.question_id and m.content_version_id=a.content_version_id
  where a.content_version_id in (4815,4816)
    and (
      ai.written_task_id is not null
      or ai.is_holdout is not true
      or ai.primary_skill_code<>m.primary_skill_code
      or ai.reserve_role<>m.reserve_role
      or ai.reserve_role<>a.assessment_type
      or ai.primary_skill_code not like a.component_code||'-%'
    );
  if v_bad<>0 then raise exception 'aw13_16_annual_reserve_assessments: role/holdout/component mismatch rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_assessments a
  where a.content_version_id in (4815,4816)
    and a.assessment_type='retest'
    and (select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id)<>1;
  if v_bad<>0 then raise exception 'aw13_16_annual_reserve_assessments: non-isolated retest rows=%',v_bad; end if;

  if (select count(*) from private.exam_prep_assessment_items where assessment_id in (35436,35437))<>16
     or (select count(*) from private.exam_prep_assessment_items where assessment_id in (35455,35456))<>14
     or (select count(*) from private.exam_prep_assessment_items where assessment_id=35454)<>8
     or (select count(*) from private.exam_prep_assessment_items where assessment_id=35471)<>7
  then raise exception 'aw13_16_annual_reserve_assessments: diagnostic/mixed coverage mismatch'; end if;
end
$postcheck$;

commit;
