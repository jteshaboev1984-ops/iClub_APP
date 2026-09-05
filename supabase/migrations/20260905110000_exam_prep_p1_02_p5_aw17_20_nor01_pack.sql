-- P1-02 P5 AW17-20 NOR-01: recognise the normal model, notation and shape parameters.
-- Scope deliberately stops before standardisation/tables/probability calculations (NOR-02+).
-- Original iClub-authored content only; legacy questions remain draft + inactive.
begin;

insert into private.exam_prep_content_versions(program_version_id,content_version,component_code,release_label,status,source_policy)
select pv.id,'p5_aw17_20_nor01_v1','P5','P5 AW17-20 NOR-01 normal model recognition','draft',
       'Original iClub content only; Cambridge 9709 official syllabus defines scope; Complete Probability & Statistics 1 is mapping/teaching reference only; no protected source wording copied. NOR-01 only: model recognition, N(mu,sigma^2) notation, symmetry/centre/spread; no standardisation or normal probability calculations.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,content_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_aw17_20_nor01_v1' and component_code='P5' and status='draft'
), src(k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P5NOR01-D01','diagnostic','medium',
 'A large set of adult heights is measured on a continuous scale and is approximately symmetric and bell-shaped around one central value. Which model is most appropriate?',
 'Большой набор ростов взрослых измерен по непрерывной шкале и имеет приблизительно симметричную колоколообразную форму вокруг одного центра. Какая модель наиболее подходит?',
 'Katta guruh kattalarning bo‘yi uzluksiz shkala bo‘yicha o‘lchangan va bitta markaz atrofida taxminan simmetrik, qo‘ng‘iroqsimon. Qaysi model eng mos?',
 '["Normal distribution","Binomial distribution","Geometric distribution","Discrete uniform distribution"]',
 '["Нормальное распределение","Биномиальное распределение","Геометрическое распределение","Дискретное равномерное распределение"]',
 '["Normal taqsimot","Binomial taqsimot","Geometrik taqsimot","Diskret tekis taqsimot"]','A',
 'A continuous, approximately symmetric bell-shaped measurement distribution is a standard setting for a normal model.',
 'Непрерывное приблизительно симметричное колоколообразное распределение измерений — стандартная ситуация для нормальной модели.',
 'Uzluksiz, taxminan simmetrik qo‘ng‘iroqsimon o‘lchovlar normal model uchun odatiy holat.',50),
('P5NOR01-L01','learning','easy',
 'If X ~ N(50, 9), what are the mean and standard deviation?',
 'Если X ~ N(50, 9), чему равны среднее и стандартное отклонение?',
 'Agar X ~ N(50, 9) bo‘lsa, o‘rtacha va standart og‘ish qancha?',
 '["mean 50, standard deviation 3","mean 50, standard deviation 9","mean 9, standard deviation 50","mean 3, standard deviation 50"]',
 '["среднее 50, стандартное отклонение 3","среднее 50, стандартное отклонение 9","среднее 9, стандартное отклонение 50","среднее 3, стандартное отклонение 50"]',
 '["o‘rtacha 50, standart og‘ish 3","o‘rtacha 50, standart og‘ish 9","o‘rtacha 9, standart og‘ish 50","o‘rtacha 3, standart og‘ish 50"]','A',
 'In N(mu, sigma^2), the second parameter is the variance. Here sigma=sqrt(9)=3.',
 'В N(mu, sigma^2) второй параметр — дисперсия. Здесь sigma=sqrt(9)=3.',
 'N(mu, sigma^2) da ikkinchi parametr dispersiya. Bu yerda sigma=sqrt(9)=3.',35),
('P5NOR01-L02','learning','easy',
 'Which statement is true for an ideal normal distribution?',
 'Какое утверждение верно для идеального нормального распределения?',
 'Ideal normal taqsimot uchun qaysi gap to‘g‘ri?',
 '["It is symmetric about its mean","It is always skewed right","Its mean must be 0","It is a discrete distribution"]',
 '["Оно симметрично относительно среднего","Оно всегда скошено вправо","Его среднее обязано быть 0","Это дискретное распределение"]',
 '["U o‘rtacha qiymatiga nisbatan simmetrik","U doim o‘ngga qiyshaygan","O‘rtachasi albatta 0","Bu diskret taqsimot"]','A',
 'A normal curve is symmetric about mu; mu need not be zero.',
 'Нормальная кривая симметрична относительно mu; mu не обязано быть нулём.',
 'Normal egri chiziq mu ga nisbatan simmetrik; mu nol bo‘lishi shart emas.',30),
('P5NOR01-L03','learning','medium',
 'Two normal distributions have the same mean. Distribution A has standard deviation 2 and distribution B has standard deviation 5. Which description is correct?',
 'Два нормальных распределения имеют одинаковое среднее. У A стандартное отклонение 2, у B — 5. Какое описание верно?',
 'Ikki normal taqsimotning o‘rtachasi bir xil. A da standart og‘ish 2, B da 5. Qaysi tavsif to‘g‘ri?',
 '["B is more spread out around the same centre","A is more spread out around the same centre","B must have a larger mean","A must be skewed"]',
 '["B сильнее разбросано вокруг того же центра","A сильнее разбросано вокруг того же центра","У B обязательно больше среднее","A обязательно скошено"]',
 '["B bir xil markaz atrofida kengroq tarqalgan","A bir xil markaz atrofida kengroq tarqalgan","B ning o‘rtachasi albatta kattaroq","A albatta qiyshaygan"]','A',
 'With the same mu, a larger sigma gives a wider, less concentrated normal curve.',
 'При одинаковом mu большее sigma даёт более широкую и менее концентрированную нормальную кривую.',
 'Bir xil mu da kattaroq sigma normal egri chiziqni kengroq va kamroq jamlangan qiladi.',40),
('P5NOR01-R01','retest','easy',
 'If Y ~ N(20, 16), what is the standard deviation of Y?',
 'Если Y ~ N(20, 16), чему равно стандартное отклонение Y?',
 'Agar Y ~ N(20, 16) bo‘lsa, Y ning standart og‘ishi qancha?',
 '["4","16","20","sqrt(20)"]','["4","16","20","sqrt(20)"]','["4","16","20","sqrt(20)"]','A',
 'The second parameter is sigma^2=16, so sigma=4.',
 'Второй параметр равен sigma^2=16, значит sigma=4.',
 'Ikkinchi parametr sigma^2=16, demak sigma=4.',30),
('P5NOR01-R02','retest','medium',
 'For X ~ N(mu, sigma^2), which statement about the centre is correct?',
 'Для X ~ N(mu, sigma^2) какое утверждение о центре верно?',
 'X ~ N(mu, sigma^2) uchun markaz haqidagi qaysi gap to‘g‘ri?',
 '["Half of the symmetric curve lies on each side of mu","The curve starts at mu","mu is the largest possible value of X","sigma is the centre of the curve"]',
 '["По каждую сторону от mu находится половина симметричной кривой","Кривая начинается в mu","mu — наибольшее возможное значение X","sigma — центр кривой"]',
 '["Simmetrik egri chiziqning yarmi mu ning har bir tomonida","Egri chiziq mu da boshlanadi","mu X ning eng katta qiymati","sigma egri chiziq markazi"]','A',
 'The normal distribution is symmetric about mu, so equal probability lies on either side of mu.',
 'Нормальное распределение симметрично относительно mu, поэтому по обе стороны находится одинаковая вероятность.',
 'Normal taqsimot mu ga nisbatan simmetrik, shuning uchun mu ning ikki tomonida ehtimol teng.',40),
('P5NOR01-M01','mixed','medium',
 'Which variable is best modelled by a normal distribution rather than a binomial or geometric distribution?',
 'Какую величину лучше моделировать нормальным распределением, а не биномиальным или геометрическим?',
 'Qaysi o‘zgaruvchini binomial yoki geometrik emas, normal taqsimot bilan modellashtirish ma’qul?',
 '["Fill weight of packets from a stable process, measured continuously around a target","Number of defective packets among exactly 20 packets","Number of packets inspected until the first defective packet","Outcome of one fair six-sided die"]',
 '["Масса наполнения пакетов стабильного процесса, непрерывно измеряемая около целевого значения","Число дефектных пакетов среди ровно 20","Число проверенных пакетов до первого дефектного","Результат одного честного шестигранного кубика"]',
 '["Barqaror jarayondagi paketlarning maqsad atrofida uzluksiz o‘lchanadigan massasi","Aynan 20 paket ichidagi nuqsonlilar soni","Birinchi nuqsonli paketgacha tekshirilgan paketlar soni","Bitta adolatli olti tomonli kubik natijasi"]','A',
 'Continuous measurements fluctuating roughly symmetrically around a stable target are a natural normal-model setting. The other options are discrete counting/waiting outcomes.',
 'Непрерывные измерения, примерно симметрично колеблющиеся вокруг стабильной цели, естественно описываются нормальной моделью. Остальные варианты — дискретный счёт или ожидание.',
 'Barqaror maqsad atrofida taxminan simmetrik o‘zgaradigan uzluksiz o‘lchovlar normal modelga mos; qolganlari diskret sanash/kutish natijalari.',55)
)
insert into public.questions(subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
select 5,'P5 Normal Distribution','P5-NOR-01',s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,'ExamPrep:P5:p5_aw17_20_nor01_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw17_20_nor01_v1:'||s.k);

with cv as (select id from private.exam_prep_content_versions where content_version='p5_aw17_20_nor01_v1' and status='draft'),
keys(k,role) as (values('P5NOR01-D01','diagnostic'),('P5NOR01-L01','learning'),('P5NOR01-L02','learning'),('P5NOR01-L03','learning'),('P5NOR01-R01','retest'),('P5NOR01-R02','retest'),('P5NOR01-M01','mixed'))
insert into private.exam_prep_question_content_meta(content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5)
select cv.id,k.k,q.id,'P5-NOR-01','{}'::text[],k.role,'withheld','draft',
'Original iClub-authored content; no protected source wording copied.',
'Authored for p5_aw17_20_nor01_v1 from canonical NOR-01 intent; no NOR-02 probability procedure included.',
'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution',
'Complete Probability & Statistics 1; Normal distribution introduction (mapping only)',
'pending','pending','pending','pending','pending',case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k join public.questions q on q.book_ref='ExamPrep:P5:p5_aw17_20_nor01_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

with meta as (
 select m.id from private.exam_prep_question_content_meta m
 join private.exam_prep_content_versions cv on cv.id=m.content_version_id
 where cv.content_version='p5_aw17_20_nor01_v1' and m.content_key='P5NOR01-D01'
), r(match,dcode,mtype,fen,fru,fuz,nen,nru,nuz) as (values
('B','fixed_count_model_confusion','concept',
 'Binomial models a discrete number of successes in a fixed number of trials. Height is a continuous measurement, not a success count.',
 'Биномиальная модель описывает дискретное число успехов в фиксированном числе испытаний. Рост — непрерывное измерение, а не число успехов.',
 'Binomial model qat’iy sinovlar sonidagi diskret muvaffaqiyatlar sonini ifodalaydi. Bo‘y esa uzluksiz o‘lchov.',
 'First classify the variable as continuous measurement versus discrete count.',
 'Сначала определите: это непрерывное измерение или дискретный счёт.',
 'Avval o‘zgaruvchi uzluksiz o‘lchovmi yoki diskret sanoqmi aniqlang.'),
('C','waiting_time_model_confusion','concept',
 'Geometric models the trial number of the first success. There is no repeated success/failure waiting process here.',
 'Геометрическая модель описывает номер испытания первого успеха. Здесь нет процесса ожидания успеха.',
 'Geometrik model birinchi muvaffaqiyat sinovi raqamini ifodalaydi. Bu yerda bunday kutish jarayoni yo‘q.',
 'Ask whether the experiment continues until a first success; if not, geometric is not the defining model.',
 'Проверьте, продолжается ли эксперимент до первого успеха; если нет, геометрическая модель не определяющая.',
 'Tajriba birinchi muvaffaqiyatgacha davom etadimi tekshiring; bo‘lmasa geometrik model mos emas.'),
('D','uniform_shape_confusion','concept',
 'A discrete uniform model gives equal probability to separated discrete outcomes; it does not describe a bell-shaped continuous measurement distribution.',
 'Дискретная равномерная модель даёт равные вероятности отдельным дискретным исходам и не описывает колоколообразные непрерывные измерения.',
 'Diskret tekis model alohida diskret natijalarga teng ehtimol beradi; u qo‘ng‘iroqsimon uzluksiz o‘lchovlarni ifodalamaydi.',
 'Use both variable type and distribution shape when selecting a model.',
 'При выборе модели учитывайте и тип величины, и форму распределения.',
 'Model tanlashda o‘zgaruvchi turi va taqsimot shaklini birga hisobga oling.')
)
insert into private.exam_prep_diagnostic_rules(content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status,approved_at)
select meta.id,'drv1','mcq_option',r.match,r.dcode,r.mtype,'P5-NOR-01',r.fen,r.fru,r.fuz,r.nen,r.nru,r.nuz,'approved',now()
from r cross join meta
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

with cv as (select id from private.exam_prep_content_versions where content_version='p5_aw17_20_nor01_v1' and status='draft')
insert into private.exam_prep_written_tasks(content_version_id,task_key,component_code,primary_skill_code,task_version,prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at)
select cv.id,'P5NOR01-W01','P5','P5-NOR-01','wtv1',
'Two continuous measurement variables are modelled as A ~ N(60,16) and B ~ N(60,36). State the mean and standard deviation of each. Draw or describe labelled bell-shaped sketches on a common horizontal scale and explain how the two distributions differ. Then give two features of a real measurement context that would make a normal model plausible. Do not calculate normal probabilities.',
'Две непрерывные измеряемые величины моделируются как A ~ N(60,16) и B ~ N(60,36). Укажите среднее и стандартное отклонение каждой. Нарисуйте или опишите подписанные колоколообразные кривые на общей горизонтальной шкале и объясните их различие. Затем назовите два признака реального контекста измерений, при которых нормальная модель правдоподобна. Не вычисляйте нормальные вероятности.',
'Ikki uzluksiz o‘lchov A ~ N(60,16) va B ~ N(60,36) bilan modellashtirilgan. Har birining o‘rtacha va standart og‘ishini ayting. Bitta gorizontal shkala ustida belgilangan qo‘ng‘iroqsimon grafiklarni chizing yoki tasvirlang va farqini tushuntiring. So‘ng normal model mos bo‘lishi mumkin bo‘lgan real o‘lchov kontekstining ikki belgisini ayting. Normal ehtimollarni hisoblamang.',
'{"max_marks":10,"criteria":[{"id":"parameters","marks":3,"rule":"States both means 60 and standard deviations 4 and 6."},{"id":"centre","marks":2,"rule":"Shows/describes both curves centred and symmetric at 60."},{"id":"spread","marks":2,"rule":"Explains B is wider/more dispersed because sigma=6 > 4."},{"id":"model_context","marks":2,"rule":"Gives two relevant plausibility features such as continuous measurement and approximate symmetric bell shape around a stable centre."},{"id":"scope","marks":1,"rule":"Keeps reasoning at NOR-01 model/shape/parameter level without unsupported probability calculation."}]}',
'Check that you read the second parameter as variance, not standard deviation. Then compare centre and spread separately.',
'Проверьте, что второй параметр прочитан как дисперсия, а не стандартное отклонение. Затем отдельно сравните центр и разброс.',
'Ikkinchi parametr standart og‘ish emas, dispersiya ekanini tekshiring. Keyin markaz va tarqalishni alohida taqqoslang.',
'approved','pass','pass','pass','pass',now()
from cv
on conflict(content_version_id,task_key,task_version) do nothing;

with cv as (select id from private.exam_prep_content_versions where content_version='p5_aw17_20_nor01_v1' and status='draft'), defs(k,t,en,ru,uz) as (values
('p5_aw17_nor01_diagnostic','diagnostic','P5 AW17-20 NOR-01 diagnostic','Диагностика P5 AW17–20 NOR-01','P5 AW17–20 NOR-01 diagnostikasi'),
('p5_nor01_learning','learning','Normal model recognition learning','Распознавание нормальной модели: обучение','Normal modelni aniqlash: o‘rganish'),
('p5_nor01_retest','retest','NOR-01 delayed retest','NOR-01 отложенный ретест','NOR-01 kechiktirilgan retest'),
('p5_aw17_nor01_mixed','mixed','P5 AW17-20 NOR-01 mixed model selection','P5 AW17–20 NOR-01: смешанный выбор модели','P5 AW17–20 NOR-01 mixed model tanlash'))
insert into private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz)
select cv.id,d.k,'av1','P5',d.t,'approved',d.en,d.ru,d.uz from defs d cross join cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (select id from private.exam_prep_content_versions where content_version='p5_aw17_20_nor01_v1'),
a as (select x.id,x.assessment_key from private.exam_prep_assessments x join cv on cv.id=x.content_version_id),
m as (select x.content_key,x.question_id from private.exam_prep_question_content_meta x join cv on cv.id=x.content_version_id),
w as (select x.id,x.task_key from private.exam_prep_written_tasks x join cv on cv.id=x.content_version_id),
items(akey,ord,ckey,wkey,role,holdout) as (values
('p5_aw17_nor01_diagnostic',1,'P5NOR01-D01',null,'diagnostic',true),
('p5_nor01_learning',1,'P5NOR01-L01',null,'learning',false),
('p5_nor01_learning',2,'P5NOR01-L02',null,'learning',false),
('p5_nor01_learning',3,'P5NOR01-L03',null,'learning',false),
('p5_nor01_learning',4,null,'P5NOR01-W01','written',false),
('p5_nor01_retest',1,'P5NOR01-R01',null,'retest',true),
('p5_aw17_nor01_mixed',1,'P5NOR01-M01',null,'mixed',true))
insert into private.exam_prep_assessment_items(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout)
select a.id,i.ord,m.question_id,w.id,'P5-NOR-01',i.role,i.holdout
from items i join a on a.assessment_key=i.akey left join m on m.content_key=i.ckey left join w on w.task_key=i.wkey
on conflict(assessment_id,item_order) do nothing;

-- QA and publication transition.
update private.exam_prep_question_content_meta m
set copyright_status='pass',qa_scope_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
    diagnostic_rule_status=case when reserve_role='diagnostic' then 'approved' else 'not_applicable' end,
    lifecycle_state='approved',approved_at=now(),updated_at=now()
from private.exam_prep_content_versions cv
where cv.id=m.content_version_id and cv.content_version='p5_aw17_20_nor01_v1' and cv.status='draft';

update private.exam_prep_content_versions set status='approved',approved_at=now()
where content_version='p5_aw17_20_nor01_v1' and status='draft';

update private.exam_prep_question_content_meta m
set lifecycle_state=case when reserve_role='learning' then 'published' else 'reserve' end,
    exposure_state=case when reserve_role='learning' then 'released' else 'withheld' end,
    published_at=case when reserve_role='learning' then now() else null end,
    updated_at=now()
from private.exam_prep_content_versions cv
where cv.id=m.content_version_id and cv.content_version='p5_aw17_20_nor01_v1' and cv.status='approved';

update private.exam_prep_written_tasks w set lifecycle_state='published'
from private.exam_prep_content_versions cv
where cv.id=w.content_version_id and cv.content_version='p5_aw17_20_nor01_v1' and cv.status='approved';

update private.exam_prep_assessments a set status='published',approved_at=coalesce(a.approved_at,now())
from private.exam_prep_content_versions cv
where cv.id=a.content_version_id and cv.content_version='p5_aw17_20_nor01_v1' and cv.status='approved';

update private.exam_prep_content_versions set status='published',published_at=now()
where content_version='p5_aw17_20_nor01_v1' and status='approved';

do $$
declare v_program bigint;
begin
 select id into v_program from private.exam_prep_program_versions
 where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';
 if not private.exam_prep_skill_content_ready_v1(v_program,'P5','P5-NOR-01') then
   raise exception 'NOR-01 content floor failed';
 end if;
 if exists(select 1 from public.questions where book_ref like 'ExamPrep:P5:p5_aw17_20_nor01_v1:%' and is_active) then
   raise exception 'NOR-01 legacy activation residue';
 end if;
 if exists(select 1 from private.exam_prep_feature_config where program_key='math_as_p1_p5' and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch)) then
   raise exception 'NOR-01 publication escaped fail-closed';
 end if;
 if exists(select 1 from private.exam_prep_feature_entitlements where entitlement_status='active') then
   raise exception 'NOR-01 active entitlement residue';
 end if;
end $$;
commit;
