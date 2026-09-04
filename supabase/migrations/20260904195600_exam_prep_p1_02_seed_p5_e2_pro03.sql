-- P1-02 E2 original content: P5-PRO-03 addition rule, complements and mutually exclusive events.
-- 1 diagnostic + 3 learning + 2 retest + 1 mixed. DRAFT + INACTIVE only.

begin;
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_e2_counting_probability_v1' and component_code='P5' and status='draft'
), src(k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P5PRO03-D01','diagnostic','medium',
 'Events A and B are mutually exclusive, with P(A)=0.4 and P(B)=0.3. Find P(A∪B).',
 'События A и B несовместны, P(A)=0.4 и P(B)=0.3. Найдите P(A∪B).',
 'A va B o‘zaro istisno hodisalar, P(A)=0.4 va P(B)=0.3. P(A∪B) ni toping.',
 '["0.12","0.3","0.7","1.0"]','["0.12","0.3","0.7","1.0"]','["0.12","0.3","0.7","1.0"]','C',
 'For mutually exclusive events the intersection is 0, so P(A∪B)=P(A)+P(B)=0.7.',
 'Для несовместных событий пересечение равно 0, поэтому P(A∪B)=P(A)+P(B)=0.7.',
 'O‘zaro istisno hodisalar uchun kesishma 0, shuning uchun P(A∪B)=P(A)+P(B)=0.7.',50),
('P5PRO03-L01','learning','easy',
 'If P(A)=0.28, what is P(Aᶜ)?',
 'Если P(A)=0.28, чему равно P(Aᶜ)?',
 'Agar P(A)=0.28 bo‘lsa, P(Aᶜ) nechaga teng?',
 '["0.28","0.72","1.28","0.0784"]','["0.28","0.72","1.28","0.0784"]','["0.28","0.72","1.28","0.0784"]','B',
 'A and its complement cover the whole sample space, so P(Aᶜ)=1−0.28=0.72.',
 'A и его дополнение покрывают всё пространство исходов, поэтому P(Aᶜ)=1−0.28=0.72.',
 'A va uning to‘ldiruvchisi barcha natijalar fazosini qoplaydi, shuning uchun P(Aᶜ)=1−0.28=0.72.',40),
('P5PRO03-L02','learning','medium',
 'P(A)=0.5, P(B)=0.4 and P(A∩B)=0.2. Find P(A∪B).',
 'P(A)=0.5, P(B)=0.4 и P(A∩B)=0.2. Найдите P(A∪B).',
 'P(A)=0.5, P(B)=0.4 va P(A∩B)=0.2. P(A∪B) ni toping.',
 '["0.3","0.7","0.9","1.1"]','["0.3","0.7","0.9","1.1"]','["0.3","0.7","0.9","1.1"]','B',
 'Use the addition rule: 0.5+0.4−0.2=0.7.',
 'По правилу сложения: 0.5+0.4−0.2=0.7.',
 'Qo‘shish qoidasi: 0.5+0.4−0.2=0.7.',50),
('P5PRO03-L03','learning','medium',
 'Events C and D are mutually exclusive. P(C)=0.35 and P(C∪D)=0.8. Find P(D).',
 'События C и D несовместны. P(C)=0.35 и P(C∪D)=0.8. Найдите P(D).',
 'C va D o‘zaro istisno. P(C)=0.35 va P(C∪D)=0.8. P(D) ni toping.',
 '["0.28","0.35","0.45","1.15"]','["0.28","0.35","0.45","1.15"]','["0.28","0.35","0.45","1.15"]','C',
 'For mutually exclusive events, P(C∪D)=P(C)+P(D). Hence P(D)=0.8−0.35=0.45.',
 'Для несовместных событий P(C∪D)=P(C)+P(D). Поэтому P(D)=0.8−0.35=0.45.',
 'O‘zaro istisno hodisalarda P(C∪D)=P(C)+P(D). Demak P(D)=0.8−0.35=0.45.',50),
('P5PRO03-R01','retest','easy',
 'The probability that a machine fails a test is 0.13. What is the probability that it does not fail?',
 'Вероятность отказа машины на тесте равна 0.13. Какова вероятность, что отказа не будет?',
 'Mashinaning testdan yiqilish ehtimoli 0.13. Yiqilmaslik ehtimoli qancha?',
 '["0.13","0.77","0.87","1.13"]','["0.13","0.77","0.87","1.13"]','["0.13","0.77","0.87","1.13"]','C',
 'Use the complement: 1−0.13=0.87.',
 'Используем дополнение: 1−0.13=0.87.',
 'To‘ldiruvchidan foydalanamiz: 1−0.13=0.87.',40),
('P5PRO03-R02','retest','medium',
 'P(E)=0.6, P(F)=0.5 and P(E∩F)=0.25. Find P(E∪F).',
 'P(E)=0.6, P(F)=0.5 и P(E∩F)=0.25. Найдите P(E∪F).',
 'P(E)=0.6, P(F)=0.5 va P(E∩F)=0.25. P(E∪F) ni toping.',
 '["0.30","0.75","0.85","1.10"]','["0.30","0.75","0.85","1.10"]','["0.30","0.75","0.85","1.10"]','C',
 'P(E∪F)=0.6+0.5−0.25=0.85.',
 'P(E∪F)=0.6+0.5−0.25=0.85.',
 'P(E∪F)=0.6+0.5−0.25=0.85.',45),
('P5PRO03-M01','mixed','hard',
 'In a group, P(A)=0.55, P(B)=0.38 and P(A∩B)=0.18. What is the probability that neither A nor B occurs?',
 'В группе P(A)=0.55, P(B)=0.38 и P(A∩B)=0.18. Какова вероятность, что не произойдёт ни A, ни B?',
 'Guruhda P(A)=0.55, P(B)=0.38 va P(A∩B)=0.18. A ham, B ham sodir bo‘lmaslik ehtimoli qancha?',
 '["0.07","0.25","0.45","0.75"]','["0.07","0.25","0.45","0.75"]','["0.07","0.25","0.45","0.75"]','B',
 'First P(A∪B)=0.55+0.38−0.18=0.75. Neither event occurs with probability 1−0.75=0.25.',
 'Сначала P(A∪B)=0.55+0.38−0.18=0.75. Вероятность ни A, ни B равна 1−0.75=0.25.',
 'Avval P(A∪B)=0.55+0.38−0.18=0.75. A ham, B ham bo‘lmaslik ehtimoli 1−0.75=0.25.',65)
)
insert into public.questions(subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
select 5,'P5 Probability','P5-PRO-03',s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,'ExamPrep:P5:p5_e2_counting_probability_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_e2_counting_probability_v1:'||s.k);

with cv as (select id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1' and status='draft'),
keys(k,role) as (values('P5PRO03-D01','diagnostic'),('P5PRO03-L01','learning'),('P5PRO03-L02','learning'),('P5PRO03-L03','learning'),('P5PRO03-R01','retest'),('P5PRO03-R02','retest'),('P5PRO03-M01','mixed'))
insert into private.exam_prep_question_content_meta(content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5)
select cv.id,k.k,q.id,'P5-PRO-03','{}'::text[],k.role,'withheld','draft','Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook wording copied.','Authored from canonical addition/complement probability skill using independent event values.','Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 pp.63-82 (mapping only)','pending','pending','pending','pending','pending',case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k join public.questions q on q.book_ref='ExamPrep:P5:p5_e2_counting_probability_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

do $$ declare v_id bigint; begin
  select id into v_id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1';
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code='P5-PRO-03')<>7 then raise exception 'P1-02 P5 PRO-03 expected 7 question objects'; end if;
end $$;
commit;
