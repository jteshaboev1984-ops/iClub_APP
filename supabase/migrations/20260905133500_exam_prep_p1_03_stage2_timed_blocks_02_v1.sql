-- P1-03 pre-live depth: second governed Stage-2 cross-topic timed blocks for P1 and P5.
-- Written-only, original iClub-authored content. No public.questions / legacy mutation.
-- Distinct primary skills from block 01; learner visibility remains operational-stage gated.
begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active'
), defs(component_code,content_version,release_label) as (values
  ('P1','p1_stage2_timed_block_02_v1','P1 Stage-2 timed block 02'),
  ('P5','p5_stage2_timed_block_02_v1','P5 Stage-2 timed block 02')
)
insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,d.content_version,d.component_code,d.release_label,'draft',
       'Original iClub-authored exam-prep timed content. Cambridge 9709 2026-2027 official syllabus defines scope/timing only; no protected question wording copied.'
from pv cross join defs d
on conflict(program_version_id,content_version) do nothing;

-- P1: inverse functions, geometric-series convergence, integration applications.
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_stage2_timed_block_02_v1' and component_code='P1' and status='draft'
), defs(task_key,primary_skill,secondary_skills,prompt_en,prompt_ru,prompt_uz,rubric,self_en,self_ru,self_uz) as (values
(
  'P1TB02-Q01','P1-FUN-04',array['P1-FUN-01']::text[],
  'The function f is defined by f(x)=x^2-4x+1 for x>=2. Write f in completed-square form, state its range, and find f^(-1)(x), including the domain of the inverse.',
  'Функция f задана формулой f(x)=x^2-4x+1 при x>=2. Представьте f в виде полного квадрата, укажите её область значений и найдите f^(-1)(x), включая область определения обратной функции.',
  'f funksiya x>=2 da f(x)=x^2-4x+1 bilan berilgan. f ni to‘liq kvadrat ko‘rinishida yozing, qiymatlar sohasini ko‘rsating va f^(-1)(x) ni uning aniqlanish sohasi bilan toping.',
  '{"max_marks":5,"criteria":[{"id":"completed_square","marks":1,"rule":"Gets f(x)=(x-2)^2-3."},{"id":"range","marks":1,"rule":"States range y>=-3."},{"id":"inverse_working","marks":1,"rule":"From y=(x-2)^2-3 uses x>=2 to select x=2+sqrt(y+3)."},{"id":"inverse","marks":1,"rule":"Gets f^(-1)(x)=2+sqrt(x+3)."},{"id":"inverse_domain","marks":1,"rule":"States domain x>=-3 for f^(-1)."}]}'::jsonb,
  'The restriction x>=2 decides the sign of the square root; do not write both branches for the inverse.',
  'Ограничение x>=2 определяет знак квадратного корня; для обратной функции нельзя оставлять обе ветви.',
  'x>=2 cheklovi kvadrat ildiz ishorasini belgilaydi; inverse uchun ikkala tarmoqni qoldirmang.'
),
(
  'P1TB02-Q02','P1-SER-05',array['P1-SER-04']::text[],
  'A geometric progression has first term 15 and second term 9. Find its common ratio, explain why its corresponding infinite series converges, find the sum to infinity, and find the sum of the first 5 terms.',
  'Геометрическая прогрессия имеет первый член 15 и второй член 9. Найдите знаменатель прогрессии, объясните, почему соответствующий бесконечный ряд сходится, найдите сумму до бесконечности и сумму первых 5 членов.',
  'Geometrik progressiyaning birinchi hadi 15, ikkinchi hadi 9. Umumiy nisbatni toping, mos cheksiz qator nega yaqinlashishini tushuntiring, cheksiz yig‘indini va dastlabki 5 had yig‘indisini toping.',
  '{"max_marks":5,"criteria":[{"id":"ratio","marks":1,"rule":"Gets r=9/15=3/5."},{"id":"convergence","marks":1,"rule":"States |r|<1, so the infinite series converges."},{"id":"infinite_formula","marks":1,"rule":"Uses S_infinity=a/(1-r)."},{"id":"infinite_sum","marks":1,"rule":"Gets S_infinity=75/2=37.5."},{"id":"finite_sum","marks":1,"rule":"Uses S_5=15(1-(3/5)^5)/(1-3/5) and gets 34.584 (or exact equivalent)."}]}'::jsonb,
  'Check convergence before using the infinite-sum formula; finite and infinite sums use related but different formulas.',
  'Проверьте сходимость до использования формулы бесконечной суммы; формулы конечной и бесконечной сумм различаются.',
  'Cheksiz yig‘indi formulasidan oldin yaqinlashishni tekshiring; chekli va cheksiz yig‘indi formulalari farq qiladi.'
),
(
  'P1TB02-Q03','P1-INT-05',array['P1-INT-04']::text[],
  'The region bounded by y=2x-x^2 and the x-axis for 0<=x<=2 is rotated about the x-axis. Find (i) the area of the region and (ii) the volume of the solid formed. Give exact answers.',
  'Область, ограниченная y=2x-x^2 и осью x при 0<=x<=2, вращается вокруг оси x. Найдите (i) площадь области и (ii) объём полученного тела. Дайте точные ответы.',
  '0<=x<=2 da y=2x-x^2 va x-o‘qi bilan chegaralangan soha x-o‘qi atrofida aylantiriladi. (i) soha yuzasini va (ii) hosil bo‘lgan jism hajmini toping. Aniq javoblarni bering.',
  '{"max_marks":5,"criteria":[{"id":"area_setup","marks":1,"rule":"Uses integral from 0 to 2 of (2x-x^2) dx."},{"id":"area","marks":1,"rule":"Gets area=4/3."},{"id":"volume_setup","marks":1,"rule":"Uses V=pi integral from 0 to 2 of (2x-x^2)^2 dx."},{"id":"volume_working","marks":1,"rule":"Expands/integrates 4x^2-4x^3+x^4 correctly."},{"id":"volume","marks":1,"rule":"Gets V=16pi/15."}]}'::jsonb,
  'For rotation about the x-axis, square the y-value inside the volume integral; the area integral itself is not the volume.',
  'При вращении вокруг оси x в интеграле объёма нужно возвести y в квадрат; интеграл площади сам по себе не даёт объём.',
  'x-o‘qi atrofida aylantirishda hajm integralida y ni kvadratga oshiring; yuza integrali hajm emas.'
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

-- P5: mixed counting, without-replacement probability, discrete RV spread.
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_stage2_timed_block_02_v1' and component_code='P5' and status='draft'
), defs(task_key,primary_skill,secondary_skills,prompt_en,prompt_ru,prompt_uz,rubric,self_en,self_ru,self_uz) as (values
(
  'P5TB02-Q01','P5-CNT-05',array['P5-CNT-04']::text[],
  'A group contains 5 boys and 4 girls. Three students are selected and then assigned three distinct speaking positions. How many ordered speaking teams contain at least one girl? Show the selection and arrangement stages separately.',
  'В группе 5 мальчиков и 4 девочки. Выбирают трёх учеников, после чего им назначают три различные позиции выступления. Сколько упорядоченных команд выступающих содержат хотя бы одну девочку? Покажите отдельно этап выбора и этап упорядочивания.',
  'Guruhda 5 o‘g‘il va 4 qiz bor. Uch o‘quvchi tanlanadi va ularga uchta turli chiqish tartibi beriladi. Kamida bitta qiz qatnashgan nechta tartiblangan chiqish jamoasi bor? Tanlash va tartiblash bosqichlarini alohida ko‘rsating.',
  '{"max_marks":5,"criteria":[{"id":"all_selections","marks":1,"rule":"Gets C(9,3)=84 total 3-person selections."},{"id":"all_boys","marks":1,"rule":"Gets C(5,3)=10 all-boy selections."},{"id":"valid_selections","marks":1,"rule":"Gets 84-10=74 selections containing at least one girl."},{"id":"arrangements","marks":1,"rule":"Uses 3!=6 speaking orders for each selected team."},{"id":"final","marks":1,"rule":"Gets 74*6=444 ordered speaking teams."}]}'::jsonb,
  'Do not count orders until after the valid group has been selected; selection and arrangement are different stages.',
  'Не учитывайте порядок до выбора допустимой тройки; выбор и упорядочивание — разные этапы.',
  'Avval mos uchlikni tanlang, keyin tartiblarni sanang; tanlash va joylashtirish turli bosqichlar.'
),
(
  'P5TB02-Q02','P5-PRO-06',array['P5-PRO-05']::text[],
  'A bag contains 4 red and 3 blue counters. Two counters are drawn at random without replacement. Draw or describe a complete probability tree and find (i) the probability of drawing one counter of each colour, (ii) P(second is red | first is blue), and (iii) the probability that the second counter is red.',
  'В мешке 4 красных и 3 синих жетона. Два жетона вытаскивают случайно без возвращения. Постройте или полностью опишите дерево вероятностей и найдите (i) вероятность получить по одному жетону каждого цвета, (ii) P(второй красный | первый синий), (iii) вероятность того, что второй жетон красный.',
  'Qopda 4 qizil va 3 ko‘k jeton bor. Ikki jeton tasodifiy, qaytarmasdan olinadi. To‘liq probability tree ni chizing yoki tasvirlang va (i) har rangdan bittadan olish ehtimolini, (ii) P(ikkinchisi qizil | birinchisi ko‘k), (iii) ikkinchi jeton qizil bo‘lish ehtimolini toping.',
  '{"max_marks":5,"criteria":[{"id":"tree_first","marks":1,"rule":"Uses first-draw probabilities 4/7 red and 3/7 blue."},{"id":"tree_second","marks":1,"rule":"Uses conditional second-draw branches 3/6,3/6 after red and 4/6,2/6 after blue."},{"id":"one_each","marks":1,"rule":"Gets (4/7)(3/6)+(3/7)(4/6)=4/7."},{"id":"conditional","marks":1,"rule":"Gets P(second red | first blue)=4/6=2/3."},{"id":"second_red","marks":1,"rule":"Gets P(second red)=(4/7)(3/6)+(3/7)(4/6)=4/7."}]}'::jsonb,
  'Without replacement, every second-stage denominator is 6 and the numerator depends on the first colour drawn.',
  'Без возвращения на втором шаге знаменатель всегда 6, а числитель зависит от цвета первого жетона.',
  'Qaytarmasdan olishda ikkinchi bosqich maxraji 6 bo‘ladi, surat esa birinchi olingan rangga bog‘liq.'
),
(
  'P5TB02-Q03','P5-DRV-03',array['P5-DRV-02']::text[],
  'A discrete random variable X takes values 0, 1, 2 and 3 with probabilities k, 2k, 3k and 4k respectively. Find k, E(X), Var(X) and the standard deviation of X.',
  'Дискретная случайная величина X принимает значения 0, 1, 2 и 3 с вероятностями k, 2k, 3k и 4k соответственно. Найдите k, E(X), Var(X) и стандартное отклонение X.',
  'Diskret tasodifiy X o‘zgaruvchi 0, 1, 2 va 3 qiymatlarni mos ravishda k, 2k, 3k va 4k ehtimollar bilan oladi. k, E(X), Var(X) va X ning standart og‘ishini toping.',
  '{"max_marks":5,"criteria":[{"id":"normalise","marks":1,"rule":"Uses 10k=1 and gets k=0.1."},{"id":"expectation","marks":1,"rule":"Gets E(X)=2."},{"id":"second_moment","marks":1,"rule":"Gets E(X^2)=5."},{"id":"variance","marks":1,"rule":"Gets Var(X)=5-2^2=1."},{"id":"sd","marks":1,"rule":"Gets standard deviation=1."}]}'::jsonb,
  'Calculate E(X^2) separately; variance is E(X^2)-[E(X)]^2, not E(X^2)-E(X).',
  'Сначала отдельно найдите E(X^2); дисперсия равна E(X^2)-[E(X)]^2, а не E(X^2)-E(X).',
  'E(X^2) ni alohida hisoblang; variance E(X^2)-[E(X)]^2, E(X^2)-E(X) emas.'
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

with cv as (
  select id,component_code from private.exam_prep_content_versions
  where content_version in ('p1_stage2_timed_block_02_v1','p5_stage2_timed_block_02_v1') and status='draft'
), defs(component_code,assessment_key,title_en,title_ru,title_uz) as (values
  ('P1','p1_stage2_timed_block_02','P1 Stage 2 timed block 02','P1 Stage 2: timed block 02','P1 Stage 2 timed blok 02'),
  ('P5','p5_stage2_timed_block_02','P5 Stage 2 timed block 02','P5 Stage 2: timed block 02','P5 Stage 2 timed blok 02')
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
  title_en,title_ru,title_uz,approved_at
)
select cv.id,d.assessment_key,'av1',d.component_code,'timed','approved',d.title_en,d.title_ru,d.title_uz,now()
from cv join defs d using(component_code)
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (
  select id,component_code from private.exam_prep_content_versions
  where content_version in ('p1_stage2_timed_block_02_v1','p5_stage2_timed_block_02_v1')
), a as (
  select a.id,a.component_code from private.exam_prep_assessments a join cv on cv.id=a.content_version_id
  where a.assessment_key in ('p1_stage2_timed_block_02','p5_stage2_timed_block_02') and a.assessment_version='av1'
), items(component_code,item_order,task_key,skill) as (values
  ('P1',1,'P1TB02-Q01','P1-FUN-04'),
  ('P1',2,'P1TB02-Q02','P1-SER-05'),
  ('P1',3,'P1TB02-Q03','P1-INT-05'),
  ('P5',1,'P5TB02-Q01','P5-CNT-05'),
  ('P5',2,'P5TB02-Q02','P5-PRO-06'),
  ('P5',3,'P5TB02-Q03','P5-DRV-03')
), wt as (
  select w.id,w.task_key,w.component_code from private.exam_prep_written_tasks w join cv on cv.id=w.content_version_id
)
insert into private.exam_prep_assessment_items(
  assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select a.id,i.item_order,null,wt.id,i.skill,'written',true
from items i join a using(component_code) join wt on wt.component_code=i.component_code and wt.task_key=i.task_key
on conflict(assessment_id,item_order) do nothing;

with a as (
  select id from private.exam_prep_assessments
  where assessment_key in ('p1_stage2_timed_block_02','p5_stage2_timed_block_02') and assessment_version='av1'
)
insert into private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks)
select a.id,v.item_order,5 from a cross join (values (1::smallint),(2::smallint),(3::smallint)) v(item_order)
on conflict(assessment_id,item_order) do nothing;

update private.exam_prep_content_versions
set status='published',approved_at=coalesce(approved_at,now()),published_at=coalesce(published_at,now())
where content_version in ('p1_stage2_timed_block_02_v1','p5_stage2_timed_block_02_v1') and status='draft';

update private.exam_prep_assessments
set status='published',approved_at=coalesce(approved_at,now())
where assessment_key in ('p1_stage2_timed_block_02','p5_stage2_timed_block_02') and assessment_version='av1' and status='approved';

with a as (
  select a.id,a.component_code from private.exam_prep_assessments a
  where a.assessment_key in ('p1_stage2_timed_block_02','p5_stage2_timed_block_02') and a.assessment_version='av1' and a.status='published'
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
       true,'section',case a.component_code when 'P1' then 'p1-stage2-timed-block-02-v1' else 'p5-stage2-timed-block-02-v1' end,
       'published',now()
from a join p using(component_code)
on conflict(assessment_id) do nothing;

-- Acceptance: exact content/mark/timing floor, no repeated primary skills from block 01, fail-closed runtime.
do $$
declare
  v_component text;
  v_ass bigint;
  v_tasks int;
  v_items int;
  v_marks int;
  v_rubric_marks int;
  v_overlap int;
  v_contract private.exam_prep_timed_assessment_contracts%rowtype;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  foreach v_component in array array['P1','P5'] loop
    select a.id into v_ass from private.exam_prep_assessments a
    where a.assessment_key=case v_component when 'P1' then 'p1_stage2_timed_block_02' else 'p5_stage2_timed_block_02' end
      and a.assessment_version='av1' and a.status='published';
    if v_ass is null then raise exception 'P1-03 Stage-2 block02 assessment missing component=%',v_component; end if;

    select count(*) into v_tasks
    from private.exam_prep_assessment_items ai join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
    where ai.assessment_id=v_ass and ai.question_id is null and ai.reserve_role='written'
      and wt.lifecycle_state='published' and wt.copyright_status='pass'
      and wt.qa_math_status='pass' and wt.qa_language_status='pass' and wt.qa_technical_status='pass';
    if v_tasks<>3 then raise exception 'P1-03 Stage-2 block02 written floor component=% tasks=%',v_component,v_tasks; end if;

    select count(*),coalesce(sum(ti.max_marks),0) into v_items,v_marks
    from private.exam_prep_timed_assessment_items ti where ti.assessment_id=v_ass;
    if v_items<>3 or v_marks<>15 then raise exception 'P1-03 Stage-2 block02 marks component=% items=% marks=%',v_component,v_items,v_marks; end if;

    select coalesce(sum((wt.rubric_json->>'max_marks')::int),0) into v_rubric_marks
    from private.exam_prep_assessment_items ai join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
    where ai.assessment_id=v_ass;
    if v_rubric_marks<>15 then raise exception 'P1-03 Stage-2 block02 rubric mismatch component=% marks=%',v_component,v_rubric_marks; end if;

    select count(*) into v_overlap
    from private.exam_prep_assessment_items newer
    join private.exam_prep_assessments olda on olda.assessment_key=case v_component when 'P1' then 'p1_stage2_timed_block_01' else 'p5_stage2_timed_block_01' end and olda.assessment_version='av1'
    join private.exam_prep_assessment_items older on older.assessment_id=olda.id and older.primary_skill_code=newer.primary_skill_code
    where newer.assessment_id=v_ass;
    if v_overlap<>0 then raise exception 'P1-03 Stage-2 block02 primary-skill overlap component=% count=%',v_component,v_overlap; end if;

    select * into v_contract from private.exam_prep_timed_assessment_contracts where assessment_id=v_ass and status='published';
    if v_contract.assessment_id is null or v_contract.attempt_kind<>'timed_section' or v_contract.comparison_scope<>'section'
       or v_contract.marks_available<>15 or not v_contract.strict_timing then
      raise exception 'P1-03 Stage-2 block02 contract invalid component=%',v_component;
    end if;
    if private.exam_prep_timed_min_stage_v1(v_contract.attempt_kind)<>2 then raise exception 'P1-03 Stage-2 block02 stage drift component=%',v_component; end if;
    if (v_component='P1' and v_contract.fixed_time_limit_sec<>1320)
       or (v_component='P5' and v_contract.fixed_time_limit_sec<>1350) then
      raise exception 'P1-03 Stage-2 block02 timing drift component=% seconds=%',v_component,v_contract.fixed_time_limit_sec;
    end if;
  end loop;

  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 Stage-2 block02 publication requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 Stage-2 block02 active entitlement residue=%',v_active; end if;
  if exists(select 1 from private.exam_prep_sessions) or exists(select 1 from private.exam_prep_evidence_events) then
    raise exception 'P1-03 Stage-2 block02 publication must not create learner runtime evidence';
  end if;
end $$;

commit;
