-- P1-02 E2 original content: P5-CNT-03 arrangements with repeated/identical objects.
-- 1 diagnostic + 3 learning + 2 retest + 1 mixed. DRAFT + INACTIVE only.

begin;
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_e2_counting_probability_v1' and component_code='P5' and status='draft'
), src(k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P5CNT03-D01','diagnostic','medium',
 'How many distinct arrangements of the letters in LEVEL are possible?',
 'Сколько различных перестановок букв слова LEVEL возможно?',
 'LEVEL so‘zidagi harflarning nechta turli joylashuvi mumkin?',
 '["20","30","60","120"]','["20","30","60","120"]','["20","30","60","120"]','B',
 'LEVEL has 5 letters with L repeated twice and E repeated twice, so the count is 5!/(2!2!)=30.',
 'В LEVEL 5 букв, при этом L повторяется дважды и E дважды, поэтому 5!/(2!2!)=30.',
 'LEVEL da 5 ta harf bor; L ikki marta, E ikki marta takrorlanadi. Shuning uchun 5!/(2!2!)=30.',60),
('P5CNT03-L01','learning','easy',
 'How many distinct arrangements of the letters in BANANA are possible?',
 'Сколько различных перестановок букв слова BANANA возможно?',
 'BANANA so‘zidagi harflarning nechta turli joylashuvi mumkin?',
 '["30","60","120","720"]','["30","60","120","720"]','["30","60","120","720"]','B',
 'BANANA has 6 letters with A repeated 3 times and N repeated 2 times: 6!/(3!2!)=60.',
 'В BANANA 6 букв: A повторяется 3 раза, N — 2 раза. Получаем 6!/(3!2!)=60.',
 'BANANA da 6 ta harf: A 3 marta, N 2 marta. 6!/(3!2!)=60.',55),
('P5CNT03-L02','learning','medium',
 'How many distinct arrangements of the letters in LETTER are possible?',
 'Сколько различных перестановок букв слова LETTER возможно?',
 'LETTER so‘zidagi harflarning nechta turli joylashuvi mumkin?',
 '["90","120","180","360"]','["90","120","180","360"]','["90","120","180","360"]','C',
 'LETTER has 6 letters, with T repeated twice and E repeated twice, so 6!/(2!2!)=180.',
 'В LETTER 6 букв; T и E повторяются по два раза. Поэтому 6!/(2!2!)=180.',
 'LETTER da 6 ta harf; T va E ikkitadan takrorlanadi. Demak 6!/(2!2!)=180.',55),
('P5CNT03-L03','learning','medium',
 'A row contains 3 identical red counters and 2 identical blue counters. How many distinct colour arrangements are possible?',
 'В ряд ставят 3 одинаковых красных и 2 одинаковых синих жетона. Сколько различных цветовых последовательностей возможно?',
 'Bir qatorga 3 ta bir xil qizil va 2 ta bir xil ko‘k jeton joylashtiriladi. Nechta turli rang tartibi mumkin?',
 '["5","10","20","120"]','["5","10","20","120"]','["5","10","20","120"]','B',
 'There are 5 positions with 3 identical red and 2 identical blue objects: 5!/(3!2!)=10.',
 'Имеем 5 позиций, 3 одинаковых красных и 2 одинаковых синих: 5!/(3!2!)=10.',
 '5 ta o‘rin, 3 ta bir xil qizil va 2 ta bir xil ko‘k: 5!/(3!2!)=10.',50),
('P5CNT03-R01','retest','easy',
 'How many distinct arrangements of the letters in MOMENT are possible?',
 'Сколько различных перестановок букв слова MOMENT возможно?',
 'MOMENT so‘zidagi harflarning nechta turli joylashuvi mumkin?',
 '["180","360","720","30"]','["180","360","720","30"]','["180","360","720","30"]','B',
 'MOMENT has 6 letters with M repeated twice, so 6!/2!=360.',
 'В MOMENT 6 букв, M повторяется дважды, поэтому 6!/2!=360.',
 'MOMENT da 6 ta harf, M ikki marta takrorlanadi; 6!/2!=360.',45),
('P5CNT03-R02','retest','medium',
 'How many distinct arrangements can be made from the multiset {C,C,O,O,A}?',
 'Сколько различных перестановок можно составить из набора {C,C,O,O,A}?',
 '{C,C,O,O,A} to‘plamidan nechta turli joylashuv tuzish mumkin?',
 '["20","30","60","120"]','["20","30","60","120"]','["20","30","60","120"]','B',
 'There are 5 objects with two C and two O: 5!/(2!2!)=30.',
 'Пять объектов, две C и две O: 5!/(2!2!)=30.',
 '5 ta obyekt, C ikkita va O ikkita: 5!/(2!2!)=30.',50),
('P5CNT03-M01','mixed','hard',
 'How many distinct 5-symbol strings can be formed using exactly the symbols 1,1,2,2,3?',
 'Сколько различных пятисимвольных строк можно составить ровно из символов 1,1,2,2,3?',
 'Aynan 1,1,2,2,3 belgilaridan nechta turli 5 belgili satr tuzish mumkin?',
 '["15","20","30","60"]','["15","20","30","60"]','["15","20","30","60"]','C',
 'The two 1s and two 2s are identical, so 5!/(2!2!)=30.',
 'Две единицы и две двойки неразличимы, поэтому 5!/(2!2!)=30.',
 'Ikki 1 va ikki 2 bir xil, shuning uchun 5!/(2!2!)=30.',60)
)
insert into public.questions(subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
select 5,'P5 Permutations and combinations','P5-CNT-03',s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,'ExamPrep:P5:p5_e2_counting_probability_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_e2_counting_probability_v1:'||s.k);

with cv as (select id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1' and status='draft'),
keys(k,role) as (values('P5CNT03-D01','diagnostic'),('P5CNT03-L01','learning'),('P5CNT03-L02','learning'),('P5CNT03-L03','learning'),('P5CNT03-R01','retest'),('P5CNT03-R02','retest'),('P5CNT03-M01','mixed'))
insert into private.exam_prep_question_content_meta(content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5)
select cv.id,k.k,q.id,'P5-CNT-03','{}'::text[],k.role,'withheld','draft','Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook wording copied.','Authored from canonical repeated-object arrangement skill using independent words and multisets.','Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 pp.98-111 (mapping only)','pending','pending','pending','pending','pending',case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k join public.questions q on q.book_ref='ExamPrep:P5:p5_e2_counting_probability_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

do $$ declare v_id bigint; begin
  select id into v_id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1';
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code='P5-CNT-03')<>7 then raise exception 'P1-02 P5 CNT-03 expected 7 question objects'; end if;
end $$;
commit;
