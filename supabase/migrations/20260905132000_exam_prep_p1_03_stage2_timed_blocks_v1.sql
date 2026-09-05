-- P1-03 pre-live depth: first governed Stage-2 cross-topic timed blocks for P1 and P5.
-- Written-only, original iClub-authored content. No public.questions / legacy mutation.
-- Publication does not grant learner access: timed catalog/authorization remains operational-stage gated.
begin;

-- Dedicated paper-depth content versions, separate from the 81-skill first-coverage runway.
with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active'
), defs(component_code,content_version,release_label) as (values
  ('P1','p1_stage2_timed_block_01_v1','P1 Stage-2 timed block 01'),
  ('P5','p5_stage2_timed_block_01_v1','P5 Stage-2 timed block 01')
)
insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,d.content_version,d.component_code,d.release_label,'draft',
       'Original iClub-authored exam-prep timed content. Cambridge 9709 2026-2027 official syllabus defines scope/timing only; no protected question wording copied.'
from pv cross join defs d
on conflict(program_version_id,content_version) do nothing;

-- P1: 3 x 5-mark written tasks = 15 marks.
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_stage2_timed_block_01_v1' and component_code='P1' and status='draft'
), defs(task_key,primary_skill,secondary_skills,prompt_en,prompt_ru,prompt_uz,rubric,self_en,self_ru,self_uz) as (values
(
  'P1TB01-Q01','P1-COO-06',array['P1-QUA-02']::text[],
  'The circle C has equation x^2+y^2=20. The line y=2x+k is tangent to C. Find all possible values of k and the corresponding points of contact. Show a discriminant or equivalent repeated-root method.',
  'Окружность C задана уравнением x^2+y^2=20. Прямая y=2x+k касается C. Найдите все возможные значения k и соответствующие точки касания. Покажите решение через дискриминант или эквивалентное условие кратного корня.',
  'C aylana x^2+y^2=20 tenglama bilan berilgan. y=2x+k chiziq C ga urinma. k ning barcha mumkin qiymatlarini va mos urinish nuqtalarini toping. Diskriminant yoki takroriy ildiz usulini ko‘rsating.',
  '{"max_marks":5,"criteria":[{"id":"substitution","marks":1,"rule":"Obtains 5x^2+4kx+k^2-20=0."},{"id":"tangency","marks":1,"rule":"Uses discriminant zero or an equivalent repeated-root condition."},{"id":"k_values","marks":1,"rule":"Gets k=10 and k=-10."},{"id":"repeated_roots","marks":1,"rule":"Gets x=-4 for k=10 and x=4 for k=-10 (or equivalent)."},{"id":"contacts","marks":1,"rule":"Gets contact points (-4,2) and (4,-2)."}]}'::jsonb,
  'Check that each final point satisfies both the circle and its corresponding tangent line.',
  'Проверьте, что каждая найденная точка удовлетворяет и окружности, и соответствующей касательной.',
  'Har bir yakuniy nuqta aylana tenglamasini ham, mos urinma chiziqni ham qanoatlantirishini tekshiring.'
),
(
  'P1TB01-Q02','P1-TRI-05',array['P1-TRI-04','P1-TRI-02']::text[],
  'Solve 2cos^2(x)-3sin(x)=0 for 0<=x<=2pi. Give exact values and show the identity/algebra used; do not give decimal angle approximations.',
  'Решите 2cos^2(x)-3sin(x)=0 при 0<=x<=2pi. Дайте точные значения и покажите использованное тождество и алгебру; десятичные приближения углов не нужны.',
  '0<=x<=2pi da 2cos^2(x)-3sin(x)=0 tenglamani yeching. Aniq qiymatlarni bering va ishlatilgan ayniyat/algebrani ko‘rsating; burchaklarni o‘nli yaqinlashtirmang.',
  '{"max_marks":5,"criteria":[{"id":"identity","marks":1,"rule":"Uses cos^2(x)=1-sin^2(x) correctly."},{"id":"quadratic","marks":1,"rule":"Obtains 2sin^2(x)+3sin(x)-2=0."},{"id":"roots","marks":1,"rule":"Gets sin(x)=1/2 or sin(x)=-2 and rejects the impossible root."},{"id":"solution_one","marks":1,"rule":"Gets x=pi/6."},{"id":"solution_two","marks":1,"rule":"Gets x=5pi/6 and no extra solutions on the interval."}]}'::jsonb,
  'After solving for sin(x), check each algebraic root against the range -1<=sin(x)<=1 before finding angles.',
  'После решения относительно sin(x) проверьте каждый алгебраический корень по условию -1<=sin(x)<=1, затем находите углы.',
  'sin(x) uchun ildizlarni topgach, burchaklarni topishdan oldin har bir ildizni -1<=sin(x)<=1 oralig‘ida tekshiring.'
),
(
  'P1TB01-Q03','P1-DIF-07',array['P1-DIF-05']::text[],
  'For f(x)=x^3-6x^2+9x, find the coordinates of all stationary points and determine the nature of each point. Show enough derivative work to justify the classification.',
  'Для f(x)=x^3-6x^2+9x найдите координаты всех стационарных точек и определите тип каждой. Покажите достаточное вычисление производных для обоснования классификации.',
  'f(x)=x^3-6x^2+9x uchun barcha statsionar nuqtalar koordinatalarini toping va har birining turini aniqlang. Tasnifni asoslash uchun yetarli hosila hisobini ko‘rsating.',
  '{"max_marks":5,"criteria":[{"id":"first_derivative","marks":1,"rule":"Gets f''(x)=3x^2-12x+9=3(x-1)(x-3)."},{"id":"stationary_x","marks":1,"rule":"Gets x=1 and x=3."},{"id":"coordinates","marks":1,"rule":"Gets (1,4) and (3,0)."},{"id":"classification_method","marks":1,"rule":"Uses f''''(x)=6x-12 or a valid first-derivative sign change."},{"id":"classification","marks":1,"rule":"Classifies (1,4) as a local maximum and (3,0) as a local minimum."}]}'::jsonb,
  'A stationary x-value is not a complete answer: substitute back for y and justify maximum/minimum separately.',
  'Одного значения x недостаточно: найдите y и отдельно обоснуйте максимум или минимум.',
  'Faqat statsionar x qiymati yetarli emas: y ni ham toping va maksimum/minimum turini alohida asoslang.'
)
)
insert into private.exam_prep_written_tasks(
  content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
  prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
  lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select cv.id,d.task_key,'P1',d.primary_skill,d.secondary_skills,'wtv1',
       d.prompt_en,d.prompt_ru,d.prompt_uz,d.rubric,d.self_en,d.self_ru,d.self_uz,
       'published','pass','pass','pass','pass',now()
from cv cross join defs d
on conflict(content_version_id,task_key,task_version) do nothing;

-- P5: 3 x 5-mark written tasks = 15 marks.
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_stage2_timed_block_01_v1' and component_code='P5' and status='draft'
), defs(task_key,primary_skill,secondary_skills,prompt_en,prompt_ru,prompt_uz,rubric,self_en,self_ru,self_uz) as (values
(
  'P5TB01-Q01','P5-DAT-09',array[]::text[],
  'The values 1, 2, 3 and 4 occur with frequencies 2, 3, 4 and 1 respectively. Calculate the mean and the standard deviation of the 10 observations. Show the totals used in your calculation and give the standard deviation to 3 significant figures.',
  'Значения 1, 2, 3 и 4 встречаются с частотами 2, 3, 4 и 1 соответственно. Вычислите среднее и стандартное отклонение 10 наблюдений. Покажите используемые суммы и дайте стандартное отклонение до 3 значащих цифр.',
  '1, 2, 3 va 4 qiymatlar mos ravishda 2, 3, 4 va 1 chastota bilan uchraydi. 10 ta kuzatuvning o‘rtacha qiymati va standart og‘ishini hisoblang. Ishlatilgan yig‘indilarni ko‘rsating va standart og‘ishni 3 muhim raqamgacha bering.',
  '{"max_marks":5,"criteria":[{"id":"totals","marks":1,"rule":"Gets sum f=10, sum fx=24 and sum fx^2=66 (or equivalent working)."},{"id":"mean","marks":1,"rule":"Gets mean=2.4."},{"id":"variance_setup","marks":1,"rule":"Uses variance=66/10-(2.4)^2."},{"id":"variance","marks":1,"rule":"Gets variance=0.84."},{"id":"sd","marks":1,"rule":"Gets standard deviation sqrt(0.84)=0.9165..., hence 0.917 to 3 s.f."}]}'::jsonb,
  'Keep variance and standard deviation separate: take the square root only after subtracting the square of the mean.',
  'Не смешивайте дисперсию и стандартное отклонение: извлекайте квадратный корень только после вычитания квадрата среднего.',
  'Dispersiya va standart og‘ishni ajrating: o‘rtacha qiymat kvadratini ayirgandan keyingina kvadrat ildiz oling.'
),
(
  'P5TB01-Q02','P5-BIN-02',array['P5-BIN-03']::text[],
  'Let X~Bin(8,0.5). Find (i) P(X=3), (ii) P(X>=6), (iii) E(X), and (iv) Var(X). Give exact fractions for the probabilities where convenient and decimal values if you use them.',
  'Пусть X~Bin(8,0.5). Найдите (i) P(X=3), (ii) P(X>=6), (iii) E(X) и (iv) Var(X). Для вероятностей можно дать точные дроби и, при необходимости, десятичные значения.',
  'X~Bin(8,0.5) bo‘lsin. (i) P(X=3), (ii) P(X>=6), (iii) E(X) va (iv) Var(X) ni toping. Ehtimollar uchun qulay bo‘lsa aniq kasr va o‘nli qiymatlarni bering.',
  '{"max_marks":5,"criteria":[{"id":"binomial_setup","marks":1,"rule":"Uses the correct binomial term/combinations for n=8,p=0.5."},{"id":"point_probability","marks":1,"rule":"Gets P(X=3)=56/256=0.21875."},{"id":"tail_probability","marks":1,"rule":"Gets P(X>=6)=(28+8+1)/256=37/256=0.14453125."},{"id":"mean","marks":1,"rule":"Gets E(X)=np=4."},{"id":"variance","marks":1,"rule":"Gets Var(X)=np(1-p)=2."}]}'::jsonb,
  'For a cumulative tail, list the included integer outcomes before adding binomial terms; then keep mean np and variance np(1-p) distinct.',
  'Для хвоста сначала перечислите включённые целые значения X, затем складывайте биномиальные вероятности; отдельно используйте np для среднего и np(1-p) для дисперсии.',
  'Yig‘ma tail uchun avval kiritilgan butun X qiymatlarini yozing, keyin binomial hadlarni qo‘shing; mean uchun np, variance uchun np(1-p) ni alohida ishlating.'
),
(
  'P5TB01-Q03','P5-NOR-03',array['P5-NOR-02','P5-NOR-04']::text[],
  'Let X~N(50,16), where 16 is the variance. (i) Find P(46<X<58). (ii) Find the 90th percentile of X. Give probabilities to 4 d.p. and the percentile to 3 significant figures.',
  'Пусть X~N(50,16), где 16 — дисперсия. (i) Найдите P(46<X<58). (ii) Найдите 90-й процентиль X. Дайте вероятность до 4 знаков после запятой, а процентиль — до 3 значащих цифр.',
  'X~N(50,16) bo‘lsin, bu yerda 16 — dispersiya. (i) P(46<X<58) ni toping. (ii) X ning 90-percentilini toping. Ehtimolni 4 o‘nli xonagacha, percentilni 3 muhim raqamgacha bering.',
  '{"max_marks":5,"criteria":[{"id":"standardise","marks":1,"rule":"Uses sigma=4 and z-bounds -1 and 2."},{"id":"interval_probability","marks":2,"rule":"Gets Phi(2)-Phi(-1) about 0.8186 (0.8185 accepted with 4 d.p. tables)."},{"id":"quantile_z","marks":1,"rule":"Uses z_0.90 about 1.2816."},{"id":"percentile","marks":1,"rule":"Gets x=50+4(1.2816)=55.1264..., hence 55.1 to 3 s.f."}]}'::jsonb,
  'Read N(mu,sigma^2) correctly: the standard deviation is 4, not 16. For the percentile, convert the z-quantile back to X-units.',
  'Правильно читайте N(mu,sigma^2): стандартное отклонение равно 4, а не 16. Для процентиля переведите z-квантиль обратно в единицы X.',
  'N(mu,sigma^2) ni to‘g‘ri o‘qing: standart og‘ish 4, 16 emas. Percentil uchun z-kvantildan X birliklariga qayting.'
)
)
insert into private.exam_prep_written_tasks(
  content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
  prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
  lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select cv.id,d.task_key,'P5',d.primary_skill,d.secondary_skills,'wtv1',
       d.prompt_en,d.prompt_ru,d.prompt_uz,d.rubric,d.self_en,d.self_ru,d.self_uz,
       'published','pass','pass','pass','pass',now()
from cv cross join defs d
on conflict(content_version_id,task_key,task_version) do nothing;

-- Assessments remain ordinary governed records; learner visibility is controlled by P1-03 stage-gated RPCs.
with cv as (
  select id,component_code from private.exam_prep_content_versions
  where content_version in ('p1_stage2_timed_block_01_v1','p5_stage2_timed_block_01_v1') and status='draft'
), defs(component_code,assessment_key,title_en,title_ru,title_uz) as (values
  ('P1','p1_stage2_timed_block_01','P1 Stage 2 timed block 01','P1 Stage 2: timed block 01','P1 Stage 2 timed blok 01'),
  ('P5','p5_stage2_timed_block_01','P5 Stage 2 timed block 01','P5 Stage 2: timed block 01','P5 Stage 2 timed blok 01')
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
  title_en,title_ru,title_uz,approved_at
)
select cv.id,d.assessment_key,'av1',d.component_code,'timed','approved',d.title_en,d.title_ru,d.title_uz,now()
from cv join defs d using(component_code)
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

-- Add the three written items to each timed block in deterministic order.
with cv as (
  select id,component_code from private.exam_prep_content_versions
  where content_version in ('p1_stage2_timed_block_01_v1','p5_stage2_timed_block_01_v1')
), a as (
  select a.id,a.component_code from private.exam_prep_assessments a join cv on cv.id=a.content_version_id
  where a.assessment_key in ('p1_stage2_timed_block_01','p5_stage2_timed_block_01') and a.assessment_version='av1'
), items(component_code,item_order,task_key,skill) as (values
  ('P1',1,'P1TB01-Q01','P1-COO-06'),
  ('P1',2,'P1TB01-Q02','P1-TRI-05'),
  ('P1',3,'P1TB01-Q03','P1-DIF-07'),
  ('P5',1,'P5TB01-Q01','P5-DAT-09'),
  ('P5',2,'P5TB01-Q02','P5-BIN-02'),
  ('P5',3,'P5TB01-Q03','P5-NOR-03')
), wt as (
  select w.id,w.task_key,w.component_code
  from private.exam_prep_written_tasks w join cv on cv.id=w.content_version_id
)
insert into private.exam_prep_assessment_items(
  assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select a.id,i.item_order,null,wt.id,i.skill,'written',true
from items i join a using(component_code) join wt on wt.component_code=i.component_code and wt.task_key=i.task_key
on conflict(assessment_id,item_order) do nothing;

-- Each question is worth 5 marks, total 15.
with a as (
  select id from private.exam_prep_assessments
  where assessment_key in ('p1_stage2_timed_block_01','p5_stage2_timed_block_01') and assessment_version='av1'
)
insert into private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks)
select a.id,v.item_order,5
from a cross join (values (1::smallint),(2::smallint),(3::smallint)) v(item_order)
on conflict(assessment_id,item_order) do nothing;

-- Publish underlying content/assessments before publishing timed contracts; the contract trigger validates this floor.
update private.exam_prep_content_versions
set status='published',approved_at=coalesce(approved_at,now()),published_at=coalesce(published_at,now())
where content_version in ('p1_stage2_timed_block_01_v1','p5_stage2_timed_block_01_v1') and status='draft';

update private.exam_prep_assessments
set status='published',approved_at=coalesce(approved_at,now())
where assessment_key in ('p1_stage2_timed_block_01','p5_stage2_timed_block_01') and assessment_version='av1' and status='approved';

-- Fixed section timing follows the official seconds-per-mark pace: P1 88 sec/mark, P5 90 sec/mark.
with a as (
  select a.id,a.component_code
  from private.exam_prep_assessments a
  where a.assessment_key in ('p1_stage2_timed_block_01','p5_stage2_timed_block_01') and a.assessment_version='av1' and a.status='published'
), p as (
  select id,component_code from private.exam_prep_component_paper_profiles
  where profile_version='9709_2026_2027_v1' and status='published'
)
insert into private.exam_prep_timed_assessment_contracts(
  assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
  strict_timing,comparison_scope,comparability_key,status,published_at
)
select a.id,p.id,'tcv1','timed_section','fixed_section',15,
       case a.component_code when 'P1' then 1320 else 1350 end,
       true,'section',case a.component_code when 'P1' then 'p1-stage2-timed-block-01-v1' else 'p5-stage2-timed-block-01-v1' end,
       'published',now()
from a join p using(component_code)
on conflict(assessment_id) do nothing;

-- Acceptance: governed written floor, marks/timing, stage gate and pre-live safety.
do $$
declare
  v_component text;
  v_ass bigint;
  v_tasks int;
  v_items int;
  v_marks int;
  v_rubric_marks int;
  v_contract private.exam_prep_timed_assessment_contracts%rowtype;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  foreach v_component in array array['P1','P5'] loop
    select a.id into v_ass
    from private.exam_prep_assessments a
    where a.assessment_key=case v_component when 'P1' then 'p1_stage2_timed_block_01' else 'p5_stage2_timed_block_01' end
      and a.assessment_version='av1' and a.status='published';
    if v_ass is null then raise exception 'P1-03 Stage-2 block assessment missing component=%',v_component; end if;

    select count(*) into v_tasks
    from private.exam_prep_assessment_items ai
    join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
    where ai.assessment_id=v_ass and ai.question_id is null and ai.reserve_role='written'
      and wt.lifecycle_state='published' and wt.copyright_status='pass'
      and wt.qa_math_status='pass' and wt.qa_language_status='pass' and wt.qa_technical_status='pass';
    if v_tasks<>3 then raise exception 'P1-03 Stage-2 block written floor component=% tasks=%',v_component,v_tasks; end if;

    select count(*),coalesce(sum(ti.max_marks),0) into v_items,v_marks
    from private.exam_prep_timed_assessment_items ti where ti.assessment_id=v_ass;
    if v_items<>3 or v_marks<>15 then raise exception 'P1-03 Stage-2 block mark floor component=% items=% marks=%',v_component,v_items,v_marks; end if;

    select coalesce(sum((wt.rubric_json->>'max_marks')::int),0) into v_rubric_marks
    from private.exam_prep_assessment_items ai join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
    where ai.assessment_id=v_ass;
    if v_rubric_marks<>15 then raise exception 'P1-03 Stage-2 rubric marks mismatch component=% marks=%',v_component,v_rubric_marks; end if;

    select * into v_contract from private.exam_prep_timed_assessment_contracts where assessment_id=v_ass and status='published';
    if v_contract.assessment_id is null or v_contract.attempt_kind<>'timed_section' or v_contract.comparison_scope<>'section'
       or v_contract.marks_available<>15 or not v_contract.strict_timing then
      raise exception 'P1-03 Stage-2 contract invalid component=%',v_component;
    end if;
    if private.exam_prep_timed_min_stage_v1(v_contract.attempt_kind)<>2 then
      raise exception 'P1-03 Stage-2 timed gate drift component=%',v_component;
    end if;
    if (v_component='P1' and v_contract.fixed_time_limit_sec<>1320)
       or (v_component='P5' and v_contract.fixed_time_limit_sec<>1350) then
      raise exception 'P1-03 Stage-2 timing drift component=% seconds=%',v_component,v_contract.fixed_time_limit_sec;
    end if;
  end loop;

  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 Stage-2 content publication requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 Stage-2 content publication found active entitlements=%',v_active; end if;
  if exists(select 1 from private.exam_prep_sessions) or exists(select 1 from private.exam_prep_evidence_events) then
    raise exception 'P1-03 Stage-2 content publication must not create learner runtime evidence';
  end if;
end $$;

commit;
