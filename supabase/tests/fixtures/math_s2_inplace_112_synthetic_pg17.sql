-- Mathematics Season 2: complete 112 MCQ same-ID rehearsal, INVENTED DATA ONLY.
-- Disposable PostgreSQL 17 test DB; no user question/answer text or key present.
-- NO hosted Supabase, no update to Season1, no new question rows.
DO $must_be_disposable$
BEGIN
 IF current_database()<>'iclub_math_s2_inplace_synthetic'
 THEN RAISE EXCEPTION 'disposable_db_name_required'; END IF;
END $must_be_disposable$;
CREATE SCHEMA private;
CREATE TABLE public.seasons(id bigint PRIMARY KEY,season_no integer NOT NULL);
CREATE TABLE public.tours(id bigint PRIMARY KEY,subject_id bigint NOT NULL,
 season_id bigint NOT NULL REFERENCES public.seasons(id),tour_no smallint NOT NULL,
 is_active boolean NOT NULL DEFAULT false,start_date date,end_date date);
CREATE TABLE public.questions(
 id bigint PRIMARY KEY,subject_id bigint NOT NULL,topic text,subtopic text,
 difficulty text NOT NULL,qtype text NOT NULL,question_text text NOT NULL,
 options_text text,correct_answer text NOT NULL,explanation text,image_url text,
 is_active boolean NOT NULL,created_at timestamptz DEFAULT now(),
 question_text_ru text,question_text_uz text,question_text_en text,
 options_text_ru text,options_text_uz text,options_text_en text,
 explanation_ru text,explanation_uz text,explanation_en text,
 book_ref text,time_limit_sec integer,quality_status text
);
CREATE TABLE public.tour_questions(
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,tour_id bigint NOT NULL
 REFERENCES public.tours(id),question_id bigint NOT NULL REFERENCES public.questions(id),
 order_no integer NOT NULL,is_active boolean NOT NULL DEFAULT true
);
CREATE TABLE public.tour_attempts(tour_id bigint NOT NULL);
CREATE TABLE public.tour_answers(question_id bigint NOT NULL);
CREATE TABLE public.tour_session_answers_v4(question_id bigint NOT NULL);
CREATE TABLE public.tour_session_runtime_v4(question_ids bigint[] NOT NULL);
CREATE TABLE public.practice_answers(question_id bigint NOT NULL);
CREATE TABLE public.practice_session_answers_v4(question_id bigint NOT NULL);
CREATE TABLE public.practice_drill_answers_v4(question_id bigint NOT NULL);
CREATE TABLE public.practice_sessions_v4(question_ids bigint[] NOT NULL);
CREATE TABLE public.practice_drill_sessions_v4(question_ids bigint[] NOT NULL);
CREATE TABLE public.practice_pool_questions(question_id bigint NOT NULL);
CREATE TABLE public.question_version_links(old_question_id bigint,new_question_id bigint);
CREATE TABLE public.question_answer_diagnostics(question_id bigint);
CREATE TABLE private.exam_prep_assessment_items(question_id bigint NOT NULL);
CREATE TABLE private.exam_prep_session_items(question_id bigint NOT NULL);
INSERT INTO public.seasons VALUES(901,1),(902,2);
INSERT INTO public.tours(id,subject_id,season_id,tour_no) VALUES
 (998001,5,901,1),(998002,4,902,1);
INSERT INTO public.tours(id,subject_id,season_id,tour_no)
 SELECT 999000+t,5,902,t FROM generate_series(1,7) t;
INSERT INTO public.questions(
 id,subject_id,topic,subtopic,difficulty,qtype,
 question_text,question_text_ru,question_text_en,question_text_uz,
 options_text,options_text_ru,options_text_en,options_text_uz,
 correct_answer,explanation,explanation_ru,explanation_en,explanation_uz,
 is_active,quality_status,time_limit_sec)
SELECT 999000+t*100+n,5,'synthetic','synthetic',
 CASE WHEN n<=6 THEN 'easy' WHEN n<=15 THEN 'medium' ELSE 'hard' END,
 CASE WHEN n<=16 THEN 'mcq' ELSE 'input' END,
 'SYN_RU_'||t||'_'||n,'SYN_RU_'||t||'_'||n,
 'SYN_EN_'||t||'_'||n,'SYN_UZ_'||t||'_'||n,
 CASE WHEN n<=16 THEN '["A_RU","B_RU","C_RU","D_RU"]' ELSE '[]' END,
 CASE WHEN n<=16 THEN '["A_RU","B_RU","C_RU","D_RU"]' ELSE '[]' END,
 CASE WHEN n<=16 THEN '["A_EN","B_EN","C_EN","D_EN"]' ELSE '[]' END,
 CASE WHEN n<=16 THEN '["A_UZ","B_UZ","C_UZ","D_UZ"]' ELSE '[]' END,
 CASE WHEN n<=16 THEN chr(65+((n-1)%4)) ELSE (n-16)::text END,
 'SYNT_RU_EXPL','SYNT_RU_EXPL','SYNT_EN_EXPL','SYNT_UZ_EXPL',
 true,'published',45
FROM generate_series(1,7) t CROSS JOIN generate_series(1,20) n;
INSERT INTO public.tour_questions(tour_id,question_id,order_no)
SELECT 999000+t,999000+t*100+n,n
FROM generate_series(1,7) t CROSS JOIN generate_series(1,20) n;
INSERT INTO public.questions(
 id,subject_id,difficulty,qtype,question_text,question_text_ru,question_text_en,
 question_text_uz,options_text,options_text_ru,options_text_en,options_text_uz,
 correct_answer,explanation,explanation_ru,explanation_en,explanation_uz,
 is_active,quality_status)
SELECT id,subject,'easy','mcq','SYN_RU_OLDER','SYN_RU_OLDER','SYN_EN_OLDER','SYN_UZ_OLDER',
 '["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]','["A","B","C","D"]',
 'A','SYNTH','SYNTH','SYNTH','SYNTH',true,'published'
FROM (VALUES(997001::bigint,5::bigint),(997002::bigint,4::bigint)) q(id,subject);
INSERT INTO public.tour_questions(tour_id,question_id,order_no)
VALUES(998001,997001,1),(998002,997002,1);

-- This candidate view changes only closed Mathematics Season 2 visibility.
\i supabase/candidates/math_s2_safe_questions_public_shield_v1_hold.sql
CREATE TABLE private.s2_original_questions AS
 SELECT id,to_jsonb(q) body FROM public.questions q;
CREATE TABLE private.s2_original_links AS
 SELECT id,to_jsonb(q) body FROM public.tour_questions q;
CREATE TEMP TABLE s2_original_source_pins AS
SELECT t.tour_no,
md5(string_agg(q.id::text||':'||tq.order_no::text||':'||
md5(concat_ws('|',q.question_text_en,q.question_text_ru,q.question_text_uz,
 q.options_text_en,q.options_text_ru,q.options_text_uz,
 q.correct_answer,q.explanation_en,q.explanation_ru,q.explanation_uz)),
 '|' ORDER BY tq.order_no)) source_md5
FROM public.tours t JOIN public.tour_questions tq ON tq.tour_id=t.id
JOIN public.questions q ON q.id=tq.question_id
WHERE t.season_id=902 AND t.subject_id=5 AND q.qtype='mcq'
GROUP BY t.tour_no;
CREATE TEMP TABLE s2_planned_rows AS
WITH ranked AS (
 SELECT t.tour_no,tq.order_no,q.id,q.correct_answer,
 row_number() OVER(PARTITION BY t.tour_no ORDER BY md5(q.id::text||'synthetic-only')) rank_key
 FROM public.tours t JOIN public.tour_questions tq ON tq.tour_id=t.id
 JOIN public.questions q ON q.id=tq.question_id
 WHERE t.season_id=902 AND t.subject_id=5 AND q.qtype='mcq'
), target AS (
 SELECT tour_no,order_no,id,correct_answer old_key,
 chr(65+((rank_key-1)/4)::integer) new_key
 FROM ranked
)
SELECT t.*,
 (SELECT jsonb_agg(
   CASE WHEN pos.i=ascii(t.new_key)-65 THEN ascii(t.old_key)-65
        WHEN pos.i=ascii(t.old_key)-65 THEN ascii(t.new_key)-65
        ELSE pos.i END ORDER BY pos.i)
   FROM generate_series(0,3) pos(i)) option_indices_new_to_old,
 (t.id IN (999111,999203,999402,999514)) fresh
FROM target t;
CREATE TEMP TABLE math_s2_private_plan AS
SELECT jsonb_build_object(
 'scope','MATH_S2_TOURS_ONLY_INPLACE_REPAIR_NO_NEW_QUESTIONS',
 'status','OFFLINE_HOLD_REHEARSAL_NO_LIVE_DB_WRITES',
 'per_tour_preflight_mcq_md5',
   (SELECT jsonb_object_agg(tour_no::text,source_md5) FROM s2_original_source_pins),
 'mcq',(SELECT jsonb_agg(jsonb_build_object(
   'tour_no',tour_no,'old_question_id',id,'old_key',old_key,'new_key',new_key,
   'option_indices_new_to_old',option_indices_new_to_old,
   'replace_stem_source',CASE WHEN fresh THEN 'private_fresh_item'
                              ELSE 'old_published_unmodified' END
   ) ORDER BY tour_no,order_no) FROM s2_planned_rows),
 'localized_stem_replacements',
 (SELECT jsonb_agg(jsonb_build_object(
  'target_id',p.id,'target_tour',p.tour_no,'correct_answer',p.new_key,
  'question_text_en','SYN_NEW_EN_'||p.id,
  'question_text_ru','SYN_NEW_RU_'||p.id,
  'question_text_uz','SYN_NEW_UZ_'||p.id,
  'explanation_en','SYN_EXPLANATION_EN',
  'explanation_ru','SYN_EXPLANATION_RU',
  'explanation_uz','SYN_EXPLANATION_UZ',
  'options_text_en',(SELECT jsonb_agg(
    CASE WHEN k=ascii(p.new_key)-65 THEN 'SYN_CORRECT_EN'
         ELSE 'SYN_DISTRACTOR_EN_'||k END ORDER BY k) FROM generate_series(0,3) k),
  'options_text_ru',(SELECT jsonb_agg(
    CASE WHEN k=ascii(p.new_key)-65 THEN 'SYN_CORRECT_RU'
         ELSE 'SYN_DISTRACTOR_RU_'||k END ORDER BY k) FROM generate_series(0,3) k),
  'options_text_uz',(SELECT jsonb_agg(
    CASE WHEN k=ascii(p.new_key)-65 THEN 'SYN_CORRECT_UZ'
         ELSE 'SYN_DISTRACTOR_UZ_'||k END ORDER BY k) FROM generate_series(0,3) k)
 ) ORDER BY p.tour_no,p.order_no) FROM s2_planned_rows p WHERE p.fresh)
) AS payload;
DO $fixture_guard$
DECLARE v_doc jsonb := (SELECT payload FROM pg_temp.math_s2_private_plan);
BEGIN
 IF jsonb_array_length(v_doc->'mcq')<>112
 OR jsonb_array_length(v_doc->'localized_stem_replacements')<>4
 OR (SELECT count(*) FROM public.tour_questions tq
     JOIN public.tours t ON t.id=tq.tour_id WHERE t.season_id=902 AND t.subject_id=5)<>140
 THEN RAISE EXCEPTION 'invented_bank_fixture_mismatch'; END IF;
END $fixture_guard$;

-- This public code is run with the same shape of 112/4 payload as the private
-- owner-only file, but with wholly invented data and different example IDs.
-- The template itself has mandatory ROLLBACK and cannot publish any contents.
\i supabase/candidates/math_s2_tour_inplace_rehearsal_template_v1_hold.sql

-- After mandatory rollback, ALL question row contents and Tour links remain
-- byte-for-byte equal to the original, including original season and Chemistry.
DO $no_changes$
BEGIN
 IF EXISTS(SELECT 1 FROM public.questions q FULL JOIN private.s2_original_questions o USING(id)
    WHERE o.body IS DISTINCT FROM to_jsonb(q))
 OR EXISTS(SELECT 1 FROM public.tour_questions tq FULL JOIN private.s2_original_links l USING(id)
    WHERE l.body IS DISTINCT FROM to_jsonb(tq))
 OR (SELECT count(*) FROM public.questions)<>142
 OR (SELECT count(*) FROM public.tour_questions)<>142
 OR (SELECT count(*) FROM public.safe_questions_public
     WHERE id BETWEEN 999101 AND 999720)<>0
 OR (SELECT count(*) FROM public.safe_questions_public WHERE id IN(997001,997002))<>2
 THEN RAISE EXCEPTION 'inplace_rehearsal_rollback_or_scope_failure'; END IF;
 RAISE NOTICE 'MATH_S2_INPLACE_112_4_PG17_ROLLBACK_AND_S1_SCOPE_PASS';
END $no_changes$;
