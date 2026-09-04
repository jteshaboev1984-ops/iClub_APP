-- P1-02 E2 original content: P1-COO-01 straight-line equations.
-- 1 diagnostic + 3 learning + 2 retest + 1 mixed. DRAFT + INACTIVE only.

begin;
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_e2_coordinate_circular_trig_v1' and component_code='P1' and status='draft'
), src(k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P1COO01-D01','diagnostic','medium',
 'A straight line has gradient 3 and passes through (2, −1). Which equation represents the line?',
 'Прямая имеет градиент 3 и проходит через точку (2, −1). Какое уравнение задаёт эту прямую?',
 'To‘g‘ri chiziqning gradienti 3 va u (2, −1) nuqtadan o‘tadi. Qaysi tenglama shu chiziqni ifodalaydi?',
 '["y = 3x + 5","y = x − 3","y = 3x − 7","y = −3x + 5"]',
 '["y = 3x + 5","y = x − 3","y = 3x − 7","y = −3x + 5"]',
 '["y = 3x + 5","y = x − 3","y = 3x − 7","y = −3x + 5"]','C',
 'Use y − y₁ = m(x − x₁): y + 1 = 3(x − 2), so y = 3x − 7.',
 'Используем y − y₁ = m(x − x₁): y + 1 = 3(x − 2), поэтому y = 3x − 7.',
 'y − y₁ = m(x − x₁) dan foydalanamiz: y + 1 = 3(x − 2), demak y = 3x − 7.',70),
('P1COO01-L01','learning','easy',
 'Find the equation of the line with gradient 2 passing through (−1, 4).',
 'Найдите уравнение прямой с градиентом 2, проходящей через (−1, 4).',
 'Gradienti 2 bo‘lgan va (−1, 4) nuqtadan o‘tuvchi to‘g‘ri chiziq tenglamasini toping.',
 '["y = 2x + 2","y = 2x + 6","y = −2x + 2","y = x + 5"]',
 '["y = 2x + 2","y = 2x + 6","y = −2x + 2","y = x + 5"]',
 '["y = 2x + 2","y = 2x + 6","y = −2x + 2","y = x + 5"]','B',
 'Substitute (−1,4) into y = 2x + c: 4 = −2 + c, giving c = 6.',
 'Подставим (−1,4) в y = 2x + c: 4 = −2 + c, откуда c = 6.',
 '(−1,4) ni y = 2x + c ga qo‘yamiz: 4 = −2 + c, bundan c = 6.',55),
('P1COO01-L02','learning','medium',
 'Which equation is the line through (1, 2) and (5, 10)?',
 'Какое уравнение задаёт прямую через точки (1, 2) и (5, 10)?',
 '(1, 2) va (5, 10) nuqtalardan o‘tuvchi chiziq tenglamasi qaysi?',
 '["y = 2x","y = 2x + 1","y = x + 1","y = 4x − 2"]',
 '["y = 2x","y = 2x + 1","y = x + 1","y = 4x − 2"]',
 '["y = 2x","y = 2x + 1","y = x + 1","y = 4x − 2"]','A',
 'The gradient is (10−2)/(5−1)=2. Using (1,2), 2=2(1)+c gives c=0, so y=2x.',
 'Градиент равен (10−2)/(5−1)=2. По точке (1,2): 2=2(1)+c, значит c=0 и y=2x.',
 'Gradient (10−2)/(5−1)=2. (1,2) nuqta orqali: 2=2(1)+c, demak c=0 va y=2x.',70),
('P1COO01-L03','learning','medium',
 'A line has gradient −1 and passes through (3, 5). Which equation is correct?',
 'Прямая имеет градиент −1 и проходит через (3, 5). Какое уравнение верно?',
 'Chiziqning gradienti −1 va u (3, 5) nuqtadan o‘tadi. Qaysi tenglama to‘g‘ri?',
 '["y = x + 2","y = −x + 2","y = x + 8","y = −x + 8"]',
 '["y = x + 2","y = −x + 2","y = x + 8","y = −x + 8"]',
 '["y = x + 2","y = −x + 2","y = x + 8","y = −x + 8"]','D',
 'Write y = −x + c. Substituting (3,5) gives 5 = −3 + c, so c = 8.',
 'Запишем y = −x + c. Подстановка (3,5) даёт 5 = −3 + c, поэтому c = 8.',
 'y = −x + c deb yozamiz. (3,5) ni qo‘ysak 5 = −3 + c, shuning uchun c = 8.',60),
('P1COO01-R01','retest','easy',
 'A line has gradient 4 and y-intercept −3. Which equation represents it?',
 'Прямая имеет градиент 4 и пересекает ось y в −3. Какое уравнение её задаёт?',
 'Chiziqning gradienti 4 va y o‘qini −3 da kesadi. Qaysi tenglama uni ifodalaydi?',
 '["y = −3x + 4","y = 4x + 3","y = 4x − 3","y = 3x − 4"]',
 '["y = −3x + 4","y = 4x + 3","y = 4x − 3","y = 3x − 4"]',
 '["y = −3x + 4","y = 4x + 3","y = 4x − 3","y = 3x − 4"]','C',
 'In y = mx + c, m=4 and c=−3, so y=4x−3.',
 'В y = mx + c имеем m=4 и c=−3, поэтому y=4x−3.',
 'y = mx + c da m=4 va c=−3, demak y=4x−3.',45),
('P1COO01-R02','retest','medium',
 'Which equation passes through (−2, 1) and (2, 9)?',
 'Какое уравнение задаёт прямую через (−2, 1) и (2, 9)?',
 'Qaysi tenglama (−2, 1) va (2, 9) nuqtalardan o‘tadi?',
 '["y = 2x + 3","y = 2x + 5","y = 4x + 5","y = x + 5"]',
 '["y = 2x + 3","y = 2x + 5","y = 4x + 5","y = x + 5"]',
 '["y = 2x + 3","y = 2x + 5","y = 4x + 5","y = x + 5"]','B',
 'The gradient is (9−1)/(2−(−2))=2. Substituting (2,9) gives 9=4+c, so c=5.',
 'Градиент равен (9−1)/(2−(−2))=2. Подстановка (2,9): 9=4+c, значит c=5.',
 'Gradient (9−1)/(2−(−2))=2. (2,9) ni qo‘ysak 9=4+c, demak c=5.',65),
('P1COO01-M01','mixed','hard',
 'The line through A(−1, 2) and B(3, 6) is written as ax + by + c = 0 with a = 1. Which equation is equivalent to this line?',
 'Прямая через A(−1, 2) и B(3, 6) записана как ax + by + c = 0, где a = 1. Какое уравнение ей эквивалентно?',
 'A(−1, 2) va B(3, 6) nuqtalardan o‘tuvchi chiziq ax + by + c = 0 ko‘rinishda yozilgan, bunda a = 1. Qaysi tenglama unga ekvivalent?',
 '["x − y + 3 = 0","x + y − 1 = 0","x − y − 3 = 0","x + y − 7 = 0"]',
 '["x − y + 3 = 0","x + y − 1 = 0","x − y − 3 = 0","x + y − 7 = 0"]',
 '["x − y + 3 = 0","x + y − 1 = 0","x − y − 3 = 0","x + y − 7 = 0"]','A',
 'The gradient is 1, so y=x+c. Using (−1,2) gives c=3, hence y=x+3 or x−y+3=0.',
 'Градиент равен 1, поэтому y=x+c. По точке (−1,2) получаем c=3, значит y=x+3 или x−y+3=0.',
 'Gradient 1, shuning uchun y=x+c. (−1,2) dan c=3, demak y=x+3 yoki x−y+3=0.',85)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,'P1 Coordinate geometry','P1-COO-01',s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,
 s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,
 'ExamPrep:P1:p1_e2_coordinate_circular_trig_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P1:p1_e2_coordinate_circular_trig_v1:'||s.k);

with cv as (select id from private.exam_prep_content_versions where content_version='p1_e2_coordinate_circular_trig_v1' and status='draft'),
keys(k,role) as (values
 ('P1COO01-D01','diagnostic'),('P1COO01-L01','learning'),('P1COO01-L02','learning'),('P1COO01-L03','learning'),
 ('P1COO01-R01','retest'),('P1COO01-R02','retest'),('P1COO01-M01','mixed')
)
insert into private.exam_prep_question_content_meta(
 content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,exposure_state,lifecycle_state,
 originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
select cv.id,k.k,q.id,'P1-COO-01','{}'::text[],k.role,'withheld','draft',
 'Original iClub-authored stem, distractors, answer and explanation; no Cambridge/coursebook wording copied.',
 'Authored from the canonical straight-line equation skill using independent coordinates and algebra.',
 'Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry',
 'Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)',
 'pending','pending','pending','pending','pending',case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
 md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k join public.questions q on q.book_ref='ExamPrep:P1:p1_e2_coordinate_circular_trig_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

do $$ declare v_id bigint; begin
 select id into v_id from private.exam_prep_content_versions where content_version='p1_e2_coordinate_circular_trig_v1';
 if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code='P1-COO-01')<>7 then
   raise exception 'P1-02 COO-01 expected 7 question objects';
 end if;
end $$;
commit;
