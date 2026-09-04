-- P1-02 E2 original content: P5-CNT-01 model selection, factorial/product rule, ordered vs unordered.
-- 1 diagnostic + 3 learning + 2 retest + 1 mixed. DRAFT + INACTIVE only.

begin;
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_e2_counting_probability_v1' and component_code='P5' and status='draft'
), src(k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P5CNT01-D01','diagnostic','medium',
 'Eight students are available. A president and a secretary are chosen. How many possible ordered pairs of office-holders are there?',
 'Есть 8 учеников. Выбирают президента и секретаря. Сколько существует упорядоченных пар должностных лиц?',
 '8 nafar o‘quvchi bor. Prezident va kotib tanlanadi. Lavozimlar bo‘yicha nechta tartiblangan juftlik mavjud?',
 '["28","56","64","8"]','["28","56","64","8"]','["28","56","64","8"]','B',
 'The roles are different, so order matters: 8 choices for president and then 7 for secretary, giving 8×7=56.',
 'Должности различны, поэтому порядок важен: 8 вариантов для президента и 7 для секретаря, итого 8×7=56.',
 'Lavozimlar turlicha, shuning uchun tartib muhim: prezident uchun 8, kotib uchun 7 tanlov, jami 8×7=56.',55),
('P5CNT01-L01','learning','easy',
 'Which situation is an unordered selection?',
 'Какая ситуация является неупорядоченным выбором?',
 'Qaysi vaziyat tartibsiz tanlov hisoblanadi?',
 '["Choosing gold, silver and bronze from 10 runners","Choosing a 3-person committee from 10 people","Choosing a captain and vice-captain from 10 people","Forming a 3-digit code from distinct digits"]',
 '["Выбор золота, серебра и бронзы из 10 бегунов","Выбор комитета из 3 человек из 10","Выбор капитана и вице-капитана из 10","Составление трёхзначного кода из разных цифр"]',
 '["10 yuguruvchidan oltin, kumush va bronza g‘oliblarini tanlash","10 kishidan 3 kishilik qo‘mita tanlash","10 kishidan kapitan va vitse-kapitan tanlash","Turli raqamlardan 3 xonali kod tuzish"]','B',
 'A committee has no labelled positions, so only the chosen set matters. The other situations assign different positions or order.',
 'В комитете нет подписанных ролей, поэтому важен только набор выбранных людей. В остальных случаях порядок или роль различаются.',
 'Qo‘mitada alohida lavozimlar yo‘q, shuning uchun faqat tanlangan to‘plam muhim. Boshqa vaziyatlarda tartib yoki rol farq qiladi.',50),
('P5CNT01-L02','learning','medium',
 'Five runners compete for gold, silver and bronze. In how many ways can the medals be awarded?',
 'Пять бегунов соревнуются за золото, серебро и бронзу. Сколькими способами можно распределить медали?',
 '5 yuguruvchi oltin, kumush va bronza uchun bellashadi. Medallarni nechta usulda taqsimlash mumkin?',
 '["10","20","60","125"]','["10","20","60","125"]','["10","20","60","125"]','C',
 'The medal positions are ordered: 5 choices, then 4, then 3, so 5×4×3=60.',
 'Места различаются: 5 вариантов, затем 4 и 3, поэтому 5×4×3=60.',
 'Medal o‘rinlari tartibli: 5, keyin 4, keyin 3 tanlov; 5×4×3=60.',55),
('P5CNT01-L03','learning','medium',
 'A code uses 4 distinct letters chosen from 6 available letters, and order matters. How many codes are possible?',
 'Код состоит из 4 разных букв, выбранных из 6, причём порядок важен. Сколько кодов возможно?',
 'Kod 6 ta mavjud harfdan tanlangan 4 ta turli harfdan iborat va tartib muhim. Nechta kod mumkin?',
 '["15","24","360","1296"]','["15","24","360","1296"]','["15","24","360","1296"]','C',
 'There are 6×5×4×3=360 ordered codes without repetition.',
 'Без повторений получаем 6×5×4×3=360 упорядоченных кодов.',
 'Takrorlanmasdan 6×5×4×3=360 ta tartiblangan kod bor.',60),
('P5CNT01-R01','retest','easy',
 'Six distinct books are placed in a row. How many orders are possible?',
 'Шесть разных книг ставят в ряд. Сколько порядков возможно?',
 '6 ta turli kitob bir qatorga joylashtiriladi. Nechta tartib mumkin?',
 '["36","120","360","720"]','["36","120","360","720"]','["36","120","360","720"]','D',
 'All 6 distinct positions are ordered, so the count is 6!=720.',
 'Все 6 различных объектов упорядочиваются, поэтому 6!=720.',
 '6 ta turli obyektning barchasi tartiblanadi, shuning uchun 6!=720.',45),
('P5CNT01-R02','retest','medium',
 'A captain and vice-captain are chosen from 9 people. How many outcomes are possible?',
 'Из 9 человек выбирают капитана и вице-капитана. Сколько исходов возможно?',
 '9 kishidan kapitan va vitse-kapitan tanlanadi. Nechta natija mumkin?',
 '["36","72","81","18"]','["36","72","81","18"]','["36","72","81","18"]','B',
 'The roles differ, so there are 9×8=72 ordered choices.',
 'Роли различны, поэтому 9×8=72 упорядоченных выбора.',
 'Rollar turlicha, shuning uchun 9×8=72 tartiblangan tanlov.',50),
('P5CNT01-M01','mixed','hard',
 'From 7 students, a 3-person team is selected and then one of the 3 is appointed captain. How many outcomes are possible?',
 'Из 7 учеников выбирают команду из 3 человек, затем одного из них назначают капитаном. Сколько исходов возможно?',
 '7 o‘quvchidan 3 kishilik jamoa tanlanadi, so‘ng jamoaning bittasi kapitan etib tayinlanadi. Nechta natija mumkin?',
 '["35","70","105","210"]','["35","70","105","210"]','["35","70","105","210"]','C',
 'First choose the unordered team: C(7,3)=35. Then choose its captain in 3 ways, giving 35×3=105.',
 'Сначала выбираем неупорядоченную команду: C(7,3)=35. Затем капитана — 3 способами. Итого 105.',
 'Avval tartibsiz jamoani tanlaymiz: C(7,3)=35. Keyin kapitanni 3 usulda tanlaymiz. Jami 105.',75)
)
insert into public.questions(subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
select 5,'P5 Permutations and combinations','P5-CNT-01',s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,'ExamPrep:P5:p5_e2_counting_probability_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_e2_counting_probability_v1:'||s.k);

with cv as (select id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1' and status='draft'),
keys(k,role) as (values('P5CNT01-D01','diagnostic'),('P5CNT01-L01','learning'),('P5CNT01-L02','learning'),('P5CNT01-L03','learning'),('P5CNT01-R01','retest'),('P5CNT01-R02','retest'),('P5CNT01-M01','mixed'))
insert into private.exam_prep_question_content_meta(content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5)
select cv.id,k.k,q.id,'P5-CNT-01','{}'::text[],k.role,'withheld','draft','Original iClub-authored stem, numbers, distractors, answer and explanation; no Cambridge/coursebook wording copied.','Authored from canonical ordered/unordered counting model selection using independent examples.','Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 pp.98-111 (mapping only)','pending','pending','pending','pending','pending',case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k join public.questions q on q.book_ref='ExamPrep:P5:p5_e2_counting_probability_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

do $$ declare v_id bigint; begin
  select id into v_id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1';
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code='P5-CNT-01')<>7 then raise exception 'P1-02 P5 CNT-01 expected 7 question objects'; end if;
end $$;
commit;
