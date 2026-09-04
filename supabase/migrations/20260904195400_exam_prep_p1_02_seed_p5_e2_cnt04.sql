-- P1-02 E2 original content: P5-CNT-04 restricted arrangements.
-- 1 diagnostic + 3 learning + 2 retest + 1 mixed. DRAFT + INACTIVE only.

begin;
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_e2_counting_probability_v1' and component_code='P5' and status='draft'
), src(k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P5CNT04-D01','diagnostic','medium',
 'Five distinct people stand in a row. A and B must stand together. How many arrangements are possible?',
 'Пять разных людей становятся в ряд. A и B должны стоять рядом. Сколько перестановок возможно?',
 '5 ta turli odam bir qatorga turadi. A va B yonma-yon turishi shart. Nechta joylashuv mumkin?',
 '["24","48","60","120"]','["24","48","60","120"]','["24","48","60","120"]','B',
 'Treat A and B as one block: there are 4 units, arranged in 4! ways, and A/B can swap in 2 ways. Total 2×4!=48.',
 'Рассматриваем A и B как один блок: 4 объекта дают 4! перестановок, а внутри блока 2 порядка. Итого 2×4!=48.',
 'A va B ni bitta blok deb olamiz: 4 ta birlik 4! usulda, blok ichida esa 2 usul. Jami 2×4!=48.',65),
('P5CNT04-L01','learning','easy',
 'Six distinct people stand in a row, with A fixed in the first position. How many arrangements are possible?',
 'Шесть разных людей становятся в ряд, причём A закреплён на первом месте. Сколько перестановок возможно?',
 '6 ta turli odam bir qatorga turadi, A birinchi o‘rinda mahkamlangan. Nechta joylashuv mumkin?',
 '["24","120","360","720"]','["24","120","360","720"]','["24","120","360","720"]','B',
 'A is fixed, so only the remaining 5 people are arranged: 5!=120.',
 'A закреплён, поэтому переставляются только остальные 5 человек: 5!=120.',
 'A mahkamlangan, qolgan 5 odam joylashadi: 5!=120.',45),
('P5CNT04-L02','learning','medium',
 'Five distinct books are arranged in a row. Two particular books must not be adjacent. How many arrangements are possible?',
 'Пять разных книг ставят в ряд. Две определённые книги не должны стоять рядом. Сколько перестановок возможно?',
 '5 ta turli kitob bir qatorga joylashtiriladi. Ikki ma’lum kitob yonma-yon turmasligi kerak. Nechta joylashuv mumkin?',
 '["48","72","96","120"]','["48","72","96","120"]','["48","72","96","120"]','B',
 'Total arrangements are 5!=120. Adjacent arrangements are 2×4!=48. So not adjacent gives 120−48=72.',
 'Всего 5!=120. Соседние случаи: 2×4!=48. Значит несоседних 120−48=72.',
 'Jami 5!=120. Yonma-yon holatlar 2×4!=48. Demak yonma-yon bo‘lmaganlari 120−48=72.',65),
('P5CNT04-L03','learning','medium',
 'Six distinct people stand in a row. A and B must not stand together. How many arrangements are possible?',
 'Шесть разных людей становятся в ряд. A и B не должны стоять рядом. Сколько перестановок возможно?',
 '6 ta turli odam qatorga turadi. A va B yonma-yon turmasligi kerak. Nechta joylashuv mumkin?',
 '["240","360","480","600"]','["240","360","480","600"]','["240","360","480","600"]','C',
 'Total 6!=720. Together: treat AB as a block, giving 2×5!=240. Therefore 720−240=480.',
 'Всего 6!=720. Вместе: 2×5!=240. Следовательно 720−240=480.',
 'Jami 6!=720. Yonma-yon: 2×5!=240. Shuning uchun 720−240=480.',65),
('P5CNT04-R01','retest','easy',
 'Four distinct people stand in a row. A and B must be together. How many arrangements are possible?',
 'Четыре разных человека становятся в ряд. A и B должны стоять рядом. Сколько перестановок возможно?',
 '4 ta turli odam qatorga turadi. A va B yonma-yon bo‘lishi kerak. Nechta joylashuv mumkin?',
 '["6","8","12","24"]','["6","8","12","24"]','["6","8","12","24"]','C',
 'Treat AB as one unit: 3! arrangements of units and 2 internal orders, giving 2×3!=12.',
 'AB — один блок: 3! перестановок блоков и 2 порядка внутри, итого 12.',
 'AB ni blok deb olamiz: 3! birlik tartibi va blok ichida 2 tartib, jami 12.',50),
('P5CNT04-R02','retest','medium',
 'Seven distinct people stand in a row with C fixed at the last position. How many arrangements are possible?',
 'Семь разных людей становятся в ряд, причём C закреплён на последнем месте. Сколько перестановок возможно?',
 '7 ta turli odam qatorga turadi, C oxirgi o‘rinda mahkamlangan. Nechta joylashuv mumkin?',
 '["120","360","720","5040"]','["120","360","720","5040"]','["120","360","720","5040"]','C',
 'With C fixed, the other 6 people can be arranged in 6!=720 ways.',
 'При закреплённом C остальные 6 человек переставляются 6!=720 способами.',
 'C mahkamlangan, qolgan 6 odam 6!=720 usulda joylashadi.',45),
('P5CNT04-M01','mixed','hard',
 'Seven distinct people stand in a row. C must be at one end, and A and B must stand together. How many arrangements are possible?',
 'Семь разных людей становятся в ряд. C должен стоять на одном из концов, а A и B — рядом. Сколько перестановок возможно?',
 '7 ta turli odam qatorga turadi. C chetlardan birida, A va B esa yonma-yon turishi kerak. Nechta joylashuv mumkin?',
 '["240","480","720","960"]','["240","480","720","960"]','["240","480","720","960"]','B',
 'Choose the end for C in 2 ways. In the remaining 6 positions, treat AB as a block: 5! unit arrangements and 2 internal orders. Total 2×5!×2=480.',
 'Для C есть 2 конца. На оставшихся 6 местах считаем AB блоком: 5! перестановок блоков и 2 порядка внутри. Итого 2×5!×2=480.',
 'C uchun 2 ta chet. Qolgan 6 o‘rinda AB blok: 5! birlik tartibi va blok ichida 2 tartib. Jami 2×5!×2=480.',80)
)
insert into public.questions(subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
select 5,'P5 Permutations and combinations','P5-CNT-04',s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,'ExamPrep:P5:p5_e2_counting_probability_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_e2_counting_probability_v1:'||s.k);

with cv as (select id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1' and status='draft'),
keys(k,role) as (values('P5CNT04-D01','diagnostic'),('P5CNT04-L01','learning'),('P5CNT04-L02','learning'),('P5CNT04-L03','learning'),('P5CNT04-R01','retest'),('P5CNT04-R02','retest'),('P5CNT04-M01','mixed'))
insert into private.exam_prep_question_content_meta(content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5)
select cv.id,k.k,q.id,'P5-CNT-04','{}'::text[],k.role,'withheld','draft','Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook wording copied.','Authored from canonical restricted-arrangement skill using independent people/book contexts.','Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 pp.98-111 (mapping only)','pending','pending','pending','pending','pending',case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k join public.questions q on q.book_ref='ExamPrep:P5:p5_e2_counting_probability_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

do $$ declare v_id bigint; begin
  select id into v_id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1';
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code='P5-CNT-04')<>7 then raise exception 'P1-02 P5 CNT-04 expected 7 question objects'; end if;
end $$;
commit;
