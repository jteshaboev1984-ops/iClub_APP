-- P1-02 E2 original content: P5-PRO-01 sample spaces and equiprobable outcomes.
-- 1 diagnostic + 3 learning + 2 retest + 1 mixed. DRAFT + INACTIVE only.

begin;
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_e2_counting_probability_v1' and component_code='P5' and status='draft'
), src(k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P5PRO01-D01','diagnostic','medium',
 'Two fair coins are tossed and the order of the coins is recorded. Which sample space is complete?',
 'Подбрасывают две честные монеты и учитывают порядок монет. Какое пространство исходов полное?',
 'Ikki adolatli tanga tashlanadi va tangalar tartibi hisobga olinadi. Qaysi natijalar fazosi to‘liq?',
 '["{HH,HT,TH,TT}","{HH,HT,TT}","{H,T}","{HH,TT}"]','["{HH,HT,TH,TT}","{HH,HT,TT}","{H,T}","{HH,TT}"]','["{HH,HT,TH,TT}","{HH,HT,TT}","{H,T}","{HH,TT}"]','A',
 'The ordered outcomes are HH, HT, TH and TT. HT and TH are different ordered outcomes.',
 'Упорядоченные исходы: HH, HT, TH и TT. HT и TH — разные исходы.',
 'Tartiblangan natijalar HH, HT, TH va TT. HT va TH turli tartiblangan natijalardir.',50),
('P5PRO01-L01','learning','easy',
 'A fair six-sided die is rolled and a fair coin is tossed. How many equiprobable ordered outcomes are there?',
 'Бросают честный шестигранный кубик и честную монету. Сколько равновероятных упорядоченных исходов?',
 'Adolatli 6 qirrali kubik tashlanadi va adolatli tanga tashlanadi. Nechta teng ehtimolli tartiblangan natija bor?',
 '["6","8","12","36"]','["6","8","12","36"]','["6","8","12","36"]','C',
 'There are 6 die results and 2 coin results, so 6×2=12 ordered outcomes.',
 'У кубика 6 исходов, у монеты 2, поэтому 6×2=12 упорядоченных исходов.',
 'Kubikda 6, tangada 2 natija; shuning uchun 6×2=12 tartiblangan natija.',40),
('P5PRO01-L02','learning','medium',
 'Two distinguishable fair six-sided dice are rolled. How many equiprobable ordered outcomes are in the sample space?',
 'Бросают два различимых честных шестигранных кубика. Сколько равновероятных упорядоченных исходов?',
 'Ikki farqlanuvchi adolatli 6 qirrali kubik tashlanadi. Natijalar fazosida nechta teng ehtimolli tartiblangan natija bor?',
 '["12","21","36","72"]','["12","21","36","72"]','["12","21","36","72"]','C',
 'Each die has 6 outcomes and the dice are distinguishable, so the ordered sample space has 6×6=36 outcomes.',
 'У каждого кубика 6 исходов, кубики различимы, поэтому 6×6=36 исходов.',
 'Har bir kubikda 6 natija va kubiklar farqlanadi; 6×6=36 natija.',45),
('P5PRO01-L03','learning','medium',
 'A spinner has three equally likely sectors labelled 1, 2 and 3. It is spun once and a coin is tossed. Which number is the size of the complete sample space?',
 'Вертушка имеет три равновероятных сектора 1, 2 и 3. Её вращают один раз и подбрасывают монету. Каков размер полного пространства исходов?',
 'Aylantirgichda 1, 2 va 3 deb belgilangan uchta teng ehtimolli sektor bor. Bir marta aylantiriladi va tanga tashlanadi. To‘liq natijalar fazosi o‘lchami nechta?',
 '["3","5","6","9"]','["3","5","6","9"]','["3","5","6","9"]','C',
 'Pair each of the 3 spinner outcomes with each of the 2 coin outcomes: 3×2=6.',
 'Каждый из 3 исходов вертушки сочетается с 2 исходами монеты: 3×2=6.',
 '3 ta aylantirgich natijasining har biri 2 ta tanga natijasi bilan juftlanadi: 3×2=6.',45),
('P5PRO01-R01','retest','easy',
 'Three fair coins are tossed. How many ordered outcomes are possible?',
 'Подбрасывают три честные монеты. Сколько упорядоченных исходов возможно?',
 '3 ta adolatli tanga tashlanadi. Nechta tartiblangan natija mumkin?',
 '["6","8","9","12"]','["6","8","9","12"]','["6","8","9","12"]','B',
 'Each coin has 2 outcomes, so 2³=8 ordered outcomes.',
 'У каждой монеты 2 исхода, поэтому 2³=8.',
 'Har bir tangada 2 natija, shuning uchun 2³=8.',40),
('P5PRO01-R02','retest','medium',
 'A fair die is rolled twice and the order of the rolls matters. How many equiprobable outcomes are possible?',
 'Честный кубик бросают дважды, порядок бросков важен. Сколько равновероятных исходов возможно?',
 'Adolatli kubik ikki marta tashlanadi va tashlashlar tartibi muhim. Nechta teng ehtimolli natija mumkin?',
 '["12","21","36","216"]','["12","21","36","216"]','["12","21","36","216"]','C',
 'The ordered pair (first roll, second roll) has 6×6=36 possibilities.',
 'Упорядоченная пара (первый бросок, второй бросок) имеет 6×6=36 вариантов.',
 'Tartiblangan (birinchi, ikkinchi tashlash) juftligi 6×6=36 imkoniyatga ega.',45),
('P5PRO01-M01','mixed','hard',
 'Two fair coins are tossed and then a fair six-sided die is rolled. How many equiprobable ordered outcomes are possible?',
 'Подбрасывают две честные монеты, затем бросают честный шестигранный кубик. Сколько равновероятных упорядоченных исходов?',
 'Ikki adolatli tanga tashlanadi, so‘ng adolatli 6 qirrali kubik tashlanadi. Nechta teng ehtimolli tartiblangan natija mumkin?',
 '["12","18","24","36"]','["12","18","24","36"]','["12","18","24","36"]','C',
 'The two coins have 4 ordered outcomes and the die has 6, so 4×6=24.',
 'Две монеты дают 4 упорядоченных исхода, кубик — 6, поэтому 4×6=24.',
 'Ikki tanga 4 tartiblangan natija, kubik 6 natija beradi; 4×6=24.',55)
)
insert into public.questions(subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
select 5,'P5 Probability','P5-PRO-01',s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,'ExamPrep:P5:p5_e2_counting_probability_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_e2_counting_probability_v1:'||s.k);

with cv as (select id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1' and status='draft'),
keys(k,role) as (values('P5PRO01-D01','diagnostic'),('P5PRO01-L01','learning'),('P5PRO01-L02','learning'),('P5PRO01-L03','learning'),('P5PRO01-R01','retest'),('P5PRO01-R02','retest'),('P5PRO01-M01','mixed'))
insert into private.exam_prep_question_content_meta(content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5)
select cv.id,k.k,q.id,'P5-PRO-01','{}'::text[],k.role,'withheld','draft','Original iClub-authored stem, outcomes, distractors, answer and explanation; no Cambridge/coursebook wording copied.','Authored from canonical sample-space construction skill using independent experiments.','Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 pp.63-82 (mapping only)','pending','pending','pending','pending','pending',case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k join public.questions q on q.book_ref='ExamPrep:P5:p5_e2_counting_probability_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

do $$ declare v_id bigint; begin
  select id into v_id from private.exam_prep_content_versions where content_version='p5_e2_counting_probability_v1';
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code='P5-PRO-01')<>7 then raise exception 'P1-02 P5 PRO-01 expected 7 question objects'; end if;
end $$;
commit;
