-- P1-02 P5 AW13-16: DRV-01 discrete probability distributions.
-- Original iClub-authored content only; governed publication; legacy questions remain draft + inactive.

begin;

insert into private.exam_prep_content_versions(program_version_id,content_version,component_code,release_label,status,source_policy)
select pv.id,'p5_aw13_16_drv01_v1','P5','P5 AW13-16 DRV-01 discrete distributions','draft',
       'Original iClub content only; Cambridge 9709 official syllabus defines scope; Complete Probability & Statistics 1 is mapping/teaching reference only; no protected source wording copied.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,content_version) do nothing;

with cv as (select id from private.exam_prep_content_versions where content_version='p5_aw13_16_drv01_v1' and component_code='P5' and status='draft'),
src(k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P5DRV01-D01','diagnostic','medium','A discrete random variable X takes values 0, 1 and 2 with probabilities 0.20, k and 0.30. Find k.','Дискретная случайная величина X принимает значения 0, 1 и 2 с вероятностями 0,20, k и 0,30. Найдите k.','Diskret tasodifiy X 0, 1 va 2 qiymatlarni 0.20, k va 0.30 ehtimollar bilan oladi. k ni toping.','["0.50","0.10","0.60","1.50"]','["0,50","0,10","0,60","1,50"]','["0.50","0.10","0.60","1.50"]','A','Probabilities in a complete discrete distribution sum to 1, so k=1−0.20−0.30=0.50.','Вероятности полного дискретного распределения дают 1, поэтому k=1−0,20−0,30=0,50.','To‘liq diskret taqsimot ehtimollari yig‘indisi 1: k=1−0.20−0.30=0.50.',55),
('P5DRV01-L01','learning','easy','Which condition must every probability in a discrete probability distribution satisfy?','Какое условие должна выполнять каждая вероятность в дискретном распределении?','Diskret ehtimollik taqsimotidagi har bir ehtimol qaysi shartni bajarishi kerak?','["It lies between 0 and 1 inclusive","It is strictly greater than 1","It must equal the mean","It must be an integer"]','["Она находится от 0 до 1 включительно","Она строго больше 1","Она должна равняться среднему","Она должна быть целым числом"]','["U 0 va 1 oralig‘ida, chegaralar bilan","U 1 dan qat’iy katta","U o‘rtacha qiymatga teng","U butun son"]','A','Every probability must satisfy 0≤P≤1; all probabilities over the possible values must also sum to 1.','Каждая вероятность должна удовлетворять 0≤P≤1; сумма вероятностей всех возможных значений также равна 1.','Har bir ehtimol 0≤P≤1 bo‘lishi kerak; barcha mumkin qiymatlar ehtimollari yig‘indisi ham 1.',45),
('P5DRV01-L02','learning','medium','X takes values 1, 2 and 3 with probabilities k, 2k and 3k. Find k.','X принимает значения 1, 2 и 3 с вероятностями k, 2k и 3k. Найдите k.','X 1, 2 va 3 qiymatlarni k, 2k va 3k ehtimollar bilan oladi. k ni toping.','["1/6","1/3","1/5","1/2"]','["1/6","1/3","1/5","1/2"]','["1/6","1/3","1/5","1/2"]','A','k+2k+3k=1, so 6k=1 and k=1/6.','k+2k+3k=1, поэтому 6k=1 и k=1/6.','k+2k+3k=1, demak 6k=1 va k=1/6.',50),
('P5DRV01-L03','learning','medium','A fair coin is tossed twice and X is the number of heads. What is P(X=1)?','Честную монету подбрасывают дважды, X — число орлов. Чему равно P(X=1)?','Adolatli tanga ikki marta tashlanadi, X — gerblar soni. P(X=1) nechaga teng?','["1/2","1/4","3/4","1"]','["1/2","1/4","3/4","1"]','["1/2","1/4","3/4","1"]','A','Exactly one head occurs for HT or TH, two of four equally likely outcomes, so P(X=1)=1/2.','Ровно один орёл получается в HT или TH: 2 из 4 равновероятных исходов, то есть 1/2.','Aynan bitta gerb HT yoki TH da: 4 teng ehtimolli natijadan 2 tasi, ya’ni 1/2.',55),
('P5DRV01-R01','retest','easy','X has probabilities 0.15, 0.25 and k for its three possible values. Find k.','Для трёх возможных значений X вероятности равны 0,15, 0,25 и k. Найдите k.','X ning uchta mumkin qiymati uchun ehtimollar 0.15, 0.25 va k. k ni toping.','["0.60","0.40","0.10","1.40"]','["0,60","0,40","0,10","1,40"]','["0.60","0.40","0.10","1.40"]','A','k=1−0.15−0.25=0.60.','k=1−0,15−0,25=0,60.','k=1−0.15−0.25=0.60.',40),
('P5DRV01-R02','retest','medium','The probabilities of four outcomes are k, k+0.10, k and k. Find k.','Вероятности четырёх исходов равны k, k+0,10, k и k. Найдите k.','To‘rtta natija ehtimollari k, k+0.10, k va k. k ni toping.','["0.225","0.250","0.300","0.900"]','["0,225","0,250","0,300","0,900"]','["0.225","0.250","0.300","0.900"]','A','4k+0.10=1, so k=0.225.','4k+0,10=1, поэтому k=0,225.','4k+0.10=1, demak k=0.225.',55),
('P5DRV01-M01','mixed','medium','X takes values 0,1,2,3 with probabilities 0.20,0.30,0.40,0.10. Find P(X≥2).','X принимает значения 0,1,2,3 с вероятностями 0,20,0,30,0,40,0,10. Найдите P(X≥2).','X 0,1,2,3 qiymatlarni 0.20,0.30,0.40,0.10 ehtimollar bilan oladi. P(X≥2) ni toping.','["0.50","0.40","0.70","0.90"]','["0,50","0,40","0,70","0,90"]','["0.50","0.40","0.70","0.90"]','A','P(X≥2)=P(X=2)+P(X=3)=0.40+0.10=0.50.','P(X≥2)=0,40+0,10=0,50.','P(X≥2)=0.40+0.10=0.50.',50)
)
insert into public.questions(subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
select 5,'P5 Discrete Random Variables','P5-DRV-01',s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,'ExamPrep:P5:p5_aw13_16_drv01_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw13_16_drv01_v1:'||s.k);

with cv as (select id from private.exam_prep_content_versions where content_version='p5_aw13_16_drv01_v1' and status='draft'),
keys(k,role) as (values('P5DRV01-D01','diagnostic'),('P5DRV01-L01','learning'),('P5DRV01-L02','learning'),('P5DRV01-L03','learning'),('P5DRV01-R01','retest'),('P5DRV01-R02','retest'),('P5DRV01-M01','mixed'))
insert into private.exam_prep_question_content_meta(content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5)
select cv.id,k.k,q.id,'P5-DRV-01','{}'::text[],k.role,'withheld','draft','Original iClub-authored content; no protected source wording copied.','Authored for p5_aw13_16_drv01_v1 from canonical DRV-01 intent.','Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1; Discrete random variables (mapping only)','pending','pending','pending','pending','pending',case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k join public.questions q on q.book_ref='ExamPrep:P5:p5_aw13_16_drv01_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

with meta as (select m.id from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id where cv.content_version='p5_aw13_16_drv01_v1' and m.content_key='P5DRV01-D01'),
r(match,dcode,mtype,fen,fru,fuz,nen,nru,nuz) as (values
('B','ignores_total_probability','concept','A complete distribution must sum to 1; subtract both known probabilities.','Полное распределение должно давать сумму 1; вычтите обе известные вероятности.','To‘liq taqsimot yig‘indisi 1; ikkala ma’lum ehtimolni ayiring.','Write ΣP(X=x)=1 before solving.','Сначала запишите ΣP(X=x)=1.','Avval ΣP(X=x)=1 ni yozing.'),
('C','uses_allocated_total','method','0.20+0.30 is the probability already allocated, not the missing probability.','0,20+0,30 — уже распределённая вероятность, а не пропущенная.','0.20+0.30 allaqachon taqsimlangan ehtimol, noma’lum emas.','Subtract the allocated total from 1.','Вычтите распределённую сумму из 1.','Ajratilgan yig‘indini 1 dan ayiring.'),
('D','invalid_probability','validity','A single probability cannot exceed 1, and the full set must sum exactly to 1.','Одна вероятность не может превышать 1, и весь набор должен давать ровно 1.','Bitta ehtimol 1 dan katta bo‘la olmaydi, to‘liq to‘plam esa 1 bo‘lishi kerak.','Check 0≤p≤1 and the total-probability condition.','Проверьте 0≤p≤1 и сумму вероятностей.','0≤p≤1 va yig‘indi shartini tekshiring.')
)
insert into private.exam_prep_diagnostic_rules(content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status,approved_at)
select meta.id,'drv1','mcq_option',r.match,r.dcode,r.mtype,'P5-DRV-01',r.fen,r.fru,r.fuz,r.nen,r.nru,r.nuz,'approved',now() from meta cross join r
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

with cv as (select id from private.exam_prep_content_versions where content_version='p5_aw13_16_drv01_v1' and status='draft')
insert into private.exam_prep_written_tasks(content_version_id,task_key,component_code,primary_skill_code,task_version,prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at)
select cv.id,'P5DRV01-W01','P5','P5-DRV-01','wtv1',
'X has values 0,1,2,3 with probabilities k,2k,3k,4k. Find k, verify the distribution is valid, find P(X≥2), and explain both validity conditions for a discrete probability distribution.',
'X принимает значения 0,1,2,3 с вероятностями k,2k,3k,4k. Найдите k, проверьте корректность распределения, найдите P(X≥2) и объясните оба условия корректности дискретного распределения.',
'X 0,1,2,3 qiymatlarni k,2k,3k,4k ehtimollar bilan oladi. k ni toping, taqsimotni tekshiring, P(X≥2) ni toping va diskret taqsimotning ikki to‘g‘rilik shartini tushuntiring.',
'{"max_marks":10,"criteria":[{"id":"normalise","marks":3,"rule":"Uses 10k=1 and obtains k=0.1."},{"id":"validity","marks":2,"rule":"Checks every probability is in [0,1] and total is 1."},{"id":"event","marks":2,"rule":"Finds P(X≥2)=0.7."},{"id":"explanation","marks":3,"rule":"Explains both validity conditions."}]}',
'Normalise first, then check bounds and total before calculating the event.','Сначала нормируйте, затем проверьте границы и сумму перед вычислением события.','Avval normallashtiring, keyin hodisadan oldin chegaralar va yig‘indini tekshiring.',
'approved','pass','pass','pass','pass',now() from cv
on conflict(content_version_id,task_key,task_version) do nothing;

with cv as (select id from private.exam_prep_content_versions where content_version='p5_aw13_16_drv01_v1' and status='draft'), defs(k,t,en,ru,uz) as (values
('p5_drv01_diagnostic','diagnostic','DRV-01 diagnostic','Диагностика DRV-01','DRV-01 diagnostikasi'),
('p5_drv01_learning','learning','DRV-01 learning','DRV-01 обучение','DRV-01 o‘rganish'),
('p5_drv01_retest','retest','DRV-01 delayed retest','DRV-01 отложенный ретест','DRV-01 kechiktirilgan retest'),
('p5_drv01_mixed','mixed','DRV-01 mixed transfer','DRV-01 смешанный перенос','DRV-01 mixed transfer'))
insert into private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz)
select cv.id,d.k,'av1','P5',d.t,'approved',d.en,d.ru,d.uz from defs d cross join cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (select id from private.exam_prep_content_versions where content_version='p5_aw13_16_drv01_v1'), a as (select x.id,x.assessment_key from private.exam_prep_assessments x join cv on cv.id=x.content_version_id), m as (select x.content_key,x.question_id from private.exam_prep_question_content_meta x join cv on cv.id=x.content_version_id), w as (select x.id,x.task_key from private.exam_prep_written_tasks x join cv on cv.id=x.content_version_id), items(akey,ord,ckey,wkey,role,holdout) as (values
('p5_drv01_diagnostic',1,'P5DRV01-D01',null,'diagnostic',true),
('p5_drv01_learning',1,'P5DRV01-L01',null,'learning',false),('p5_drv01_learning',2,'P5DRV01-L02',null,'learning',false),('p5_drv01_learning',3,'P5DRV01-L03',null,'learning',false),('p5_drv01_learning',4,null,'P5DRV01-W01','written',false),
('p5_drv01_retest',1,'P5DRV01-R01',null,'retest',true),('p5_drv01_mixed',1,'P5DRV01-M01',null,'mixed',true))
insert into private.exam_prep_assessment_items(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout)
select a.id,i.ord,m.question_id,w.id,'P5-DRV-01',i.role,i.holdout from items i join a on a.assessment_key=i.akey left join m on m.content_key=i.ckey left join w on w.task_key=i.wkey
on conflict(assessment_id,item_order) do nothing;

update private.exam_prep_question_content_meta m set copyright_status='pass',qa_scope_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',diagnostic_rule_status=case when reserve_role='diagnostic' then 'approved' else 'not_applicable' end,lifecycle_state='approved',approved_at=now(),updated_at=now() from private.exam_prep_content_versions cv where cv.id=m.content_version_id and cv.content_version='p5_aw13_16_drv01_v1' and cv.status='draft';
update private.exam_prep_content_versions set status='approved',approved_at=now() where content_version='p5_aw13_16_drv01_v1' and status='draft';
update private.exam_prep_question_content_meta m set lifecycle_state=case when reserve_role='learning' then 'published' else 'reserve' end,exposure_state=case when reserve_role='learning' then 'released' else 'withheld' end,published_at=case when reserve_role='learning' then now() else null end,updated_at=now() from private.exam_prep_content_versions cv where cv.id=m.content_version_id and cv.content_version='p5_aw13_16_drv01_v1' and cv.status='approved';
update private.exam_prep_written_tasks w set lifecycle_state='published' from private.exam_prep_content_versions cv where cv.id=w.content_version_id and cv.content_version='p5_aw13_16_drv01_v1' and cv.status='approved';
update private.exam_prep_assessments a set status='published',approved_at=coalesce(a.approved_at,now()) from private.exam_prep_content_versions cv where cv.id=a.content_version_id and cv.content_version='p5_aw13_16_drv01_v1' and cv.status='approved';
update private.exam_prep_content_versions set status='published',published_at=now() where content_version='p5_aw13_16_drv01_v1' and status='approved';

do $$ declare v_program bigint; begin
select id into v_program from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';
if not private.exam_prep_skill_content_ready_v1(v_program,'P5','P5-DRV-01') then raise exception 'DRV-01 not ready after publish'; end if;
if exists(select 1 from public.questions where book_ref like 'ExamPrep:P5:p5_aw13_16_drv01_v1:%' and is_active) then raise exception 'legacy activation residue'; end if;
if exists(select 1 from private.exam_prep_feature_config where program_key='math_as_p1_p5' and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch)) then raise exception 'feature escaped fail-closed'; end if;
if exists(select 1 from private.exam_prep_feature_entitlements where entitlement_status='active') then raise exception 'active entitlement residue'; end if;
end $$;

commit;
