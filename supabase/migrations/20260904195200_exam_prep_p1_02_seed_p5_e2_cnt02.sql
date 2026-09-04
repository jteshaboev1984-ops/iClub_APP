-- P1-02 E2 original content: P5-CNT-02 permutations of distinct objects.
-- 1 diagnostic + 3 learning + 2 retest + 1 mixed. DRAFT + INACTIVE only.

begin;
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_e2_counting_probability_v1' and component_code='P5' and status='draft'
), src(k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P5CNT02-D01','diagnostic','medium',
 'Seven distinct books are arranged in a row. How many different arrangements are possible?',
 'Семь разных книг расставляют в ряд. Сколько различных перестановок возможно?',
 '7 ta turli kitob bir qatorga joylashtiriladi. Nechta turli joylashuv mumkin?',
 '["49","720","5040","823543"]','["49","720","5040","823543"]','["49","720","5040","823543"]','C',
 'All 7 distinct books occupy ordered positions, so there are 7!=5040 arrangements.',
 'Все 7 различных книг занимают упорядоченные позиции, поэтому число перестановок равно 7!=5040.',
 '7 ta turli kitob tartibli o‘rinlarni egallaydi, shuning uchun 7!=5040 ta joylashuv bor.',50),
('P5CNT02-L01','learning','easy',
 'Six different people stand in a line. How many orders are possible?',
 'Шесть разных людей становятся в ряд. Сколько порядков возможно?',
 '6 ta turli odam bir qatorga turadi. Nechta tartib mumkin?',
 '["36","120","360","720"]','["36","120","360","720"]','["36","120","360","720"]','D',
 'Six distinct people can be permuted in 6!=720 ways.',
 'Шесть разных людей можно переставить 6!=720 способами.',
 '6 ta turli odam 6!=720 usulda joylashishi mumkin.',40),
('P5CNT02-L02','learning','medium',
 'Four positions are filled from 7 distinct objects without repetition. How many ordered arrangements are possible?',
 'Четыре позиции заполняют из 7 различных объектов без повторений. Сколько упорядоченных размещений возможно?',
 '4 ta o‘rin 7 ta turli obyektdan takrorlanmasdan to‘ldiriladi. Nechta tartiblangan joylashuv mumkin?',
 '["35","210","840","2401"]','["35","210","840","2401"]','["35","210","840","2401"]','C',
 'There are 7 choices, then 6, 5 and 4: 7×6×5×4=840.',
 'Последовательно 7, 6, 5 и 4 вариантов: 7×6×5×4=840.',
 'Ketma-ket 7, 6, 5 va 4 tanlov: 7×6×5×4=840.',55),
('P5CNT02-L03','learning','medium',
 'How many 5-letter arrangements can be made using all letters A, B, C, D and E exactly once?',
 'Сколько пятибуквенных перестановок можно составить, используя A, B, C, D и E ровно по одному разу?',
 'A, B, C, D va E harflarining har birini aynan bir marta ishlatib nechta 5 harfli joylashuv tuzish mumkin?',
 '["25","60","120","625"]','["25","60","120","625"]','["25","60","120","625"]','C',
 'All five distinct letters are used, giving 5!=120 arrangements.',
 'Используются все пять разных букв, значит 5!=120 перестановок.',
 'Barcha 5 ta turli harf ishlatiladi, demak 5!=120 ta joylashuv.',45),
('P5CNT02-R01','retest','easy',
 'Eight distinct flags are displayed in a row. How many orders are possible?',
 'Восемь разных флагов располагают в ряд. Сколько порядков возможно?',
 '8 ta turli bayroq bir qatorga joylashtiriladi. Nechta tartib mumkin?',
 '["64","720","5040","40320"]','["64","720","5040","40320"]','["64","720","5040","40320"]','D',
 'The number of permutations is 8!=40320.',
 'Число перестановок равно 8!=40320.',
 'Joylashuvlar soni 8!=40320.',40),
('P5CNT02-R02','retest','medium',
 'Three ordered positions are filled from 9 distinct candidates without repetition. How many outcomes are possible?',
 'Три упорядоченных места заполняют из 9 различных кандидатов без повторений. Сколько исходов возможно?',
 '3 ta tartibli o‘rin 9 ta turli nomzoddan takrorlanmasdan to‘ldiriladi. Nechta natija mumkin?',
 '["84","504","729","362880"]','["84","504","729","362880"]','["84","504","729","362880"]','B',
 'Use 9P3=9×8×7=504.',
 'Используем 9P3=9×8×7=504.',
 '9P3=9×8×7=504 ni ishlatamiz.',50),
('P5CNT02-M01','mixed','hard',
 'A display uses 5 of 8 distinct paintings, arranged from left to right. How many displays are possible?',
 'Для экспозиции выбирают 5 из 8 разных картин и располагают слева направо. Сколько экспозиций возможно?',
 '8 ta turli rasmdan 5 tasi tanlanib, chapdan o‘ngga tartiblanadi. Nechta ekspozitsiya mumkin?',
 '["56","336","6720","40320"]','["56","336","6720","40320"]','["56","336","6720","40320"]','C',
 'Selection and order are both involved: 8P5=8×7×6×5×4=6720.',
 'И выбор, и порядок важны: 8P5=8×7×6×5×4=6720.',
 'Tanlash ham, tartib ham muhim: 8P5=8×7×6×5×4=6720.',65)
)
insert into public.questions(subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
select 5,'P5 Permutations and combinations','P5-CNT-02',s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,'ExamPrep:P5:p5_e2_counting_probability_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_e2_counting_probability_v1:'||s.k);

with cv as (select id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1' and status='draft'),
keys(k,role) as (values('P5CNT02-D01','diagnostic'),('P5CNT02-L01','learning'),('P5CNT02-L02','learning'),('P5CNT02-L03','learning'),('P5CNT02-R01','retest'),('P5CNT02-R02','retest'),('P5CNT02-M01','mixed'))
insert into private.exam_prep_question_content_meta(content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5)
select cv.id,k.k,q.id,'P5-CNT-02','{}'::text[],k.role,'withheld','draft','Original iClub-authored stem, numbers, distractors, answer and explanation; no Cambridge/coursebook wording copied.','Authored from canonical permutations-of-distinct-objects skill using independent objects and values.','Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 pp.98-111 (mapping only)','pending','pending','pending','pending','pending',case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k join public.questions q on q.book_ref='ExamPrep:P5:p5_e2_counting_probability_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

do $$ declare v_id bigint; begin
  select id into v_id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1';
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code='P5-CNT-02')<>7 then raise exception 'P1-02 P5 CNT-02 expected 7 question objects'; end if;
end $$;
commit;
