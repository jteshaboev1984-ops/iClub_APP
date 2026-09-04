-- P1-02 E2 original content: P1-COO-02 distance, midpoint, gradient and intersection.
-- 1 diagnostic + 3 learning + 2 retest + 1 mixed. DRAFT + INACTIVE only.

begin;
with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_e2_coordinate_circular_trig_v1' and component_code='P1' and status='draft'
), src(k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P1COO02-D01','diagnostic','medium',
 'Points A(−2, 3) and B(4, 7) are given. What is the midpoint of AB?',
 'Даны точки A(−2, 3) и B(4, 7). Найдите середину отрезка AB.',
 'A(−2, 3) va B(4, 7) nuqtalar berilgan. AB kesmaning o‘rta nuqtasini toping.',
 '["(1, 5)","(2, 5)","(1, 10)","(−3, 2)"]','["(1, 5)","(2, 5)","(1, 10)","(−3, 2)"]','["(1, 5)","(2, 5)","(1, 10)","(−3, 2)"]','A',
 'Average the x-coordinates and y-coordinates separately: ((−2+4)/2,(3+7)/2)=(1,5).',
 'Усредняем координаты отдельно: ((−2+4)/2,(3+7)/2)=(1,5).',
 'x va y koordinatalarni alohida o‘rtachalaymiz: ((−2+4)/2,(3+7)/2)=(1,5).',55),
('P1COO02-L01','learning','easy',
 'Find the distance between P(1, 2) and Q(4, 6).',
 'Найдите расстояние между P(1, 2) и Q(4, 6).',
 'P(1, 2) va Q(4, 6) orasidagi masofani toping.',
 '["4","5","6","7"]','["4","5","6","7"]','["4","5","6","7"]','B',
 'Distance = √((4−1)²+(6−2)²)=√(9+16)=5.',
 'Расстояние = √((4−1)²+(6−2)²)=√25=5.',
 'Masofa = √((4−1)²+(6−2)²)=√25=5.',50),
('P1COO02-L02','learning','medium',
 'The lines y=2x+1 and y=−x+7 intersect at which point?',
 'В какой точке пересекаются прямые y=2x+1 и y=−x+7?',
 'y=2x+1 va y=−x+7 chiziqlari qaysi nuqtada kesishadi?',
 '["(1,3)","(2,5)","(3,4)","(4,3)"]','["(1,3)","(2,5)","(3,4)","(4,3)"]','["(1,3)","(2,5)","(3,4)","(4,3)"]','B',
 'At the intersection 2x+1=−x+7, so 3x=6 and x=2. Then y=5.',
 'В точке пересечения 2x+1=−x+7, поэтому 3x=6, x=2 и y=5.',
 'Kesishishda 2x+1=−x+7, demak 3x=6, x=2 va y=5.',65),
('P1COO02-L03','learning','medium',
 'What is the gradient of the line through (−1, 5) and (3, −3)?',
 'Найдите градиент прямой через точки (−1, 5) и (3, −3).',
 '(−1, 5) va (3, −3) nuqtalardan o‘tuvchi chiziq gradientini toping.',
 '["−2","−1/2","2","8"]','["−2","−1/2","2","8"]','["−2","−1/2","2","8"]','A',
 'Gradient=(−3−5)/(3−(−1))=−8/4=−2.',
 'Градиент=(−3−5)/(3−(−1))=−8/4=−2.',
 'Gradient=(−3−5)/(3−(−1))=−8/4=−2.',55),
('P1COO02-R01','retest','medium',
 'The midpoint of A(2, −4) and B(8, 6) is:',
 'Середина отрезка с концами A(2, −4) и B(8, 6) равна:',
 'A(2, −4) va B(8, 6) kesmaning o‘rta nuqtasi:',
 '["(5,1)","(10,2)","(3,5)","(5,−5)"]','["(5,1)","(10,2)","(3,5)","(5,−5)"]','["(5,1)","(10,2)","(3,5)","(5,−5)"]','A',
 'Midpoint=((2+8)/2,(−4+6)/2)=(5,1).',
 'Середина=((2+8)/2,(−4+6)/2)=(5,1).',
 'O‘rta nuqta=((2+8)/2,(−4+6)/2)=(5,1).',50),
('P1COO02-R02','retest','medium',
 'Find the distance between (−2, −1) and (4, 7).',
 'Найдите расстояние между (−2, −1) и (4, 7).',
 '(−2, −1) va (4, 7) orasidagi masofani toping.',
 '["8","10","12","14"]','["8","10","12","14"]','["8","10","12","14"]','B',
 'Distance=√(6²+8²)=√100=10.',
 'Расстояние=√(6²+8²)=10.',
 'Masofa=√(6²+8²)=10.',55),
('P1COO02-M01','mixed','hard',
 'The line through A(1, 6) and B(5, 2) meets the x-axis at C. What is the x-coordinate of C?',
 'Прямая через A(1, 6) и B(5, 2) пересекает ось x в точке C. Найдите x-координату C.',
 'A(1, 6) va B(5, 2) nuqtalardan o‘tuvchi chiziq x o‘qini C nuqtada kesadi. C ning x-koordinatasini toping.',
 '["5","6","7","8"]','["5","6","7","8"]','["5","6","7","8"]','C',
 'The gradient is (2−6)/(5−1)=−1, so y=−x+7. On the x-axis y=0, hence x=7.',
 'Градиент равен −1, поэтому y=−x+7. На оси x имеем y=0, значит x=7.',
 'Gradient −1, demak y=−x+7. x o‘qida y=0, shuning uchun x=7.',80)
)
insert into public.questions(subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
select 5,'P1 Coordinate geometry','P1-COO-02',s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,'ExamPrep:P1:p1_e2_coordinate_circular_trig_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P1:p1_e2_coordinate_circular_trig_v1:'||s.k);

with cv as (select id from private.exam_prep_content_versions where content_version='p1_e2_coordinate_circular_trig_v1' and status='draft'),
keys(k,role) as (values('P1COO02-D01','diagnostic'),('P1COO02-L01','learning'),('P1COO02-L02','learning'),('P1COO02-L03','learning'),('P1COO02-R01','retest'),('P1COO02-R02','retest'),('P1COO02-M01','mixed'))
insert into private.exam_prep_question_content_meta(content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5)
select cv.id,k.k,q.id,'P1-COO-02','{}'::text[],k.role,'withheld','draft','Original iClub-authored stem, numbers, distractors, answer and explanation; no Cambridge/coursebook wording copied.','Authored from the canonical coordinate-geometry measurement/intersection skill using independent coordinates.','Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1, Ch3 Coordinate geometry pp.48-67 (mapping only)','pending','pending','pending','pending','pending',case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k join public.questions q on q.book_ref='ExamPrep:P1:p1_e2_coordinate_circular_trig_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

do $$ declare v_id bigint; begin select id into v_id from private.exam_prep_content_versions where content_version='p1_e2_coordinate_circular_trig_v1'; if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code='P1-COO-02')<>7 then raise exception 'P1-02 COO-02 expected 7 question objects'; end if; end $$;
commit;
