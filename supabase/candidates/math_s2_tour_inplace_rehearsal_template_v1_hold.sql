-- Mathematics Season 2 — confidential-payload-free exact-shape rehearsal.
-- HOLD / NOT A PRODUCTION MIGRATION. No actual book text, correct keys or
-- per-question permutations are committed. This template reads a payload
-- ONLY from a TEMP table in a dedicated disposable CI database, applies
-- 112 same-ID synthetic updates and ALWAYS rolls back the transaction.
-- Owner-private live-bank dry-run is distinct and has NOT been run here.
BEGIN;
SET LOCAL statement_timeout='25s';
SET LOCAL lock_timeout='3s';
SET LOCAL iclub.math_s2_disposable='true';
DO $math_s2_rehearsal$
DECLARE
 v_doc jsonb := (SELECT payload FROM pg_temp.math_s2_private_plan);
 v_row jsonb;
 v_rep jsonb;
 v_old public.questions%rowtype;
 v_tour_no int;
 v_mcq_md5 text;
 v_new_key text;
 v_pos jsonb;
 v_id bigint;
 v_perm_en jsonb;
 v_perm_ru jsonb;
 v_perm_uz jsonb;
 v_perm_default jsonb;
 v_count integer:=0;
 v_replacements integer:=0;
BEGIN
 IF current_database() <> 'iclub_math_s2_inplace_synthetic'
    OR current_setting('iclub.math_s2_disposable',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'MATH_S2_DISPOSABLE_DATABASE_ONLY'; END IF;
 IF v_doc->>'scope' IS DISTINCT FROM 'MATH_S2_TOURS_ONLY_INPLACE_REPAIR_NO_NEW_QUESTIONS'
    OR v_doc->>'status' IS DISTINCT FROM 'OFFLINE_HOLD_REHEARSAL_NO_LIVE_DB_WRITES'
    OR jsonb_array_length(v_doc->'mcq')<>112
    OR jsonb_array_length(v_doc->'localized_stem_replacements')<>4
 THEN RAISE EXCEPTION 'MATH_S2_INVALID_PRIVATE_PLAN_SHAPE'; END IF;
 IF (SELECT count(DISTINCT (j.value->>'old_question_id')::bigint)
      FROM jsonb_array_elements(v_doc->'mcq') j)<>112
    OR (SELECT count(DISTINCT (j.value->>'target_id')::bigint)
      FROM jsonb_array_elements(v_doc->'localized_stem_replacements') j)<>4
 THEN RAISE EXCEPTION 'MATH_S2_DUPLICATE_PLAN_IDS'; END IF;
 IF (SELECT count(*) FROM public.tours t JOIN public.seasons s ON s.id=t.season_id
    WHERE s.season_no=2 AND t.subject_id=5 AND NOT t.is_active
      AND t.start_date IS NULL AND t.end_date IS NULL)<>7
    OR (SELECT count(*) FROM public.tour_questions tq
        JOIN public.tours t ON t.id=tq.tour_id
        JOIN public.seasons s ON s.id=t.season_id
        WHERE s.season_no=2 AND t.subject_id=5 AND tq.is_active)<>140
 THEN RAISE EXCEPTION 'MATH_S2_NOT_SEVEN_DRAFT_TOURS_140'; END IF;
 IF EXISTS(SELECT 1 FROM public.tour_attempts a JOIN public.tours t ON t.id=a.tour_id
      JOIN public.seasons s ON s.id=t.season_id WHERE s.season_no=2 AND t.subject_id=5)
 THEN RAISE EXCEPTION 'MATH_S2_ATTEMPTS_ALREADY_ISSUED'; END IF;
 IF EXISTS(SELECT 1 FROM public.safe_questions_public v JOIN public.tour_questions tq ON tq.question_id=v.id
     JOIN public.tours t ON t.id=tq.tour_id JOIN public.seasons s ON s.id=t.season_id
     WHERE s.season_no=2 AND t.subject_id=5)
 THEN RAISE EXCEPTION 'MATH_S2_PUBLIC_CATALOGUE_NOT_SEALED'; END IF;
 FOR v_tour_no IN 1..7 LOOP
  SELECT md5(string_agg(q.id::text||':'||tq.order_no::text||':'||
    md5(concat_ws('|',q.question_text_en,q.question_text_ru,q.question_text_uz,
     q.options_text_en,q.options_text_ru,q.options_text_uz,
     q.correct_answer,q.explanation_en,q.explanation_ru,q.explanation_uz)),
    '|' ORDER BY tq.order_no))
  INTO v_mcq_md5
  FROM public.tour_questions tq JOIN public.tours t ON t.id=tq.tour_id
  JOIN public.seasons s ON s.id=t.season_id
  JOIN public.questions q ON q.id=tq.question_id
  WHERE s.season_no=2 AND t.subject_id=5 AND t.tour_no=v_tour_no
    AND tq.is_active AND q.qtype='mcq';
  IF v_mcq_md5 IS DISTINCT FROM v_doc->'per_tour_preflight_mcq_md5'->>v_tour_no::text
  THEN RAISE EXCEPTION 'MATH_S2_SOURCE_PIN_DRIFT'; END IF;
 END LOOP;
 FOR v_row IN SELECT value FROM jsonb_array_elements(v_doc->'mcq') LOOP
  v_id:=(v_row->>'old_question_id')::bigint;
  v_tour_no:=(v_row->>'tour_no')::integer;
  v_new_key:=v_row->>'new_key';
  v_pos:=v_row->'option_indices_new_to_old';
  SELECT * INTO v_old FROM public.questions WHERE id=v_id FOR UPDATE;
  IF v_old.id IS NULL OR v_old.subject_id<>5 OR v_old.qtype<>'mcq'
    OR NOT v_old.is_active OR v_old.quality_status<>'published'
    OR v_old.correct_answer IS DISTINCT FROM v_row->>'old_key'
    OR v_new_key NOT IN('A','B','C','D')
    OR jsonb_array_length(v_pos)<>4
    OR (SELECT count(DISTINCT p.value) FROM jsonb_array_elements_text(v_pos) p)<>4
    OR EXISTS(SELECT 1 FROM jsonb_array_elements_text(v_pos) p
        WHERE p.value NOT IN('0','1','2','3'))
    OR (v_pos->>(ascii(v_new_key)-65))::integer<>ascii(v_old.correct_answer)-65
    OR (SELECT count(*) FROM public.tour_questions tq JOIN public.tours t ON t.id=tq.tour_id
        JOIN public.seasons s ON s.id=t.season_id
        WHERE tq.question_id=v_id AND tq.is_active
          AND s.season_no=2 AND t.subject_id=5 AND t.tour_no=v_tour_no)<>1
    OR EXISTS(SELECT 1 FROM public.tour_questions tq JOIN public.tours t ON t.id=tq.tour_id
        JOIN public.seasons s ON s.id=t.season_id WHERE tq.question_id=v_id
        AND (s.season_no<>2 OR t.subject_id<>5 OR t.tour_no<>v_tour_no))
    OR EXISTS(SELECT 1 FROM public.practice_pool_questions p WHERE p.question_id=v_id)
    OR EXISTS(SELECT 1 FROM public.question_version_links l WHERE l.old_question_id=v_id OR l.new_question_id=v_id)
    OR EXISTS(SELECT 1 FROM public.tour_answers a WHERE a.question_id=v_id)
    OR EXISTS(SELECT 1 FROM public.tour_session_answers_v4 a WHERE a.question_id=v_id)
    OR EXISTS(SELECT 1 FROM public.practice_answers a WHERE a.question_id=v_id)
    OR EXISTS(SELECT 1 FROM public.practice_session_answers_v4 a WHERE a.question_id=v_id)
    OR EXISTS(SELECT 1 FROM public.practice_drill_answers_v4 a WHERE a.question_id=v_id)
    OR EXISTS(SELECT 1 FROM public.practice_sessions_v4 s WHERE v_id=ANY(s.question_ids))
    OR EXISTS(SELECT 1 FROM public.practice_drill_sessions_v4 s WHERE v_id=ANY(s.question_ids))
    OR EXISTS(SELECT 1 FROM public.tour_session_runtime_v4 s WHERE v_id=ANY(s.question_ids))
    OR EXISTS(SELECT 1 FROM private.exam_prep_assessment_items e WHERE e.question_id=v_id)
    OR EXISTS(SELECT 1 FROM private.exam_prep_session_items e WHERE e.question_id=v_id)
    OR EXISTS(SELECT 1 FROM public.question_answer_diagnostics d WHERE d.question_id=v_id)
   THEN RAISE EXCEPTION 'MATH_S2_QUESTION_NOT_UNUSED_OR_EXCLUSIVE'; END IF;
  IF jsonb_array_length(v_old.options_text_en::jsonb)<>4
    OR jsonb_array_length(v_old.options_text_ru::jsonb)<>4
    OR jsonb_array_length(v_old.options_text_uz::jsonb)<>4
    OR jsonb_array_length(v_old.options_text::jsonb)<>4
  THEN RAISE EXCEPTION 'MATH_S2_MCQS_NOT_TRILINGUAL'; END IF;
  SELECT jsonb_agg(v_old.options_text_en::jsonb -> (p.value::int) ORDER BY p.ordinality)
   INTO v_perm_en FROM jsonb_array_elements_text(v_pos) WITH ORDINALITY p(value,ordinality);
  SELECT jsonb_agg(v_old.options_text_ru::jsonb -> (p.value::int) ORDER BY p.ordinality)
   INTO v_perm_ru FROM jsonb_array_elements_text(v_pos) WITH ORDINALITY p(value,ordinality);
  SELECT jsonb_agg(v_old.options_text_uz::jsonb -> (p.value::int) ORDER BY p.ordinality)
   INTO v_perm_uz FROM jsonb_array_elements_text(v_pos) WITH ORDINALITY p(value,ordinality);
  SELECT jsonb_agg(v_old.options_text::jsonb -> (p.value::int) ORDER BY p.ordinality)
   INTO v_perm_default FROM jsonb_array_elements_text(v_pos) WITH ORDINALITY p(value,ordinality);
  SELECT value INTO v_rep FROM jsonb_array_elements(v_doc->'localized_stem_replacements') x(value)
     WHERE (x.value->>'target_id')::bigint=v_id;
  IF v_rep IS NOT NULL THEN
   IF (v_row->>'replace_stem_source')<>'private_fresh_item'
      OR (v_rep->>'target_tour')::integer<>v_tour_no
      OR v_rep->>'correct_answer'<>v_new_key
   THEN RAISE EXCEPTION 'MATH_S2_REPLACEMENT_NOT_LINKED'; END IF;
   UPDATE public.questions SET
      question_text_en=v_rep->>'question_text_en',
      question_text_ru=v_rep->>'question_text_ru',
      question_text_uz=v_rep->>'question_text_uz',
      question_text=v_rep->>'question_text_ru',
      options_text_en=(v_rep->'options_text_en')::text,
      options_text_ru=(v_rep->'options_text_ru')::text,
      options_text_uz=(v_rep->'options_text_uz')::text,
      options_text=(v_rep->'options_text_ru')::text,
      explanation_en=v_rep->>'explanation_en',
      explanation_ru=v_rep->>'explanation_ru',
      explanation_uz=v_rep->>'explanation_uz',
      explanation=v_rep->>'explanation_ru',
      correct_answer=v_new_key WHERE id=v_id;
   v_replacements:=v_replacements+1;
  ELSE
   IF (v_row->>'replace_stem_source')<>'old_published_unmodified'
   THEN RAISE EXCEPTION 'MATH_S2_STEM_MISSING'; END IF;
   UPDATE public.questions SET
      options_text_en=v_perm_en::text,
      options_text_ru=v_perm_ru::text,
      options_text_uz=v_perm_uz::text,
      options_text=v_perm_default::text,
      correct_answer=v_new_key WHERE id=v_id;
   IF (v_old.options_text_en::jsonb -> (ascii(v_old.correct_answer)-65))
        IS DISTINCT FROM (SELECT q.options_text_en::jsonb -> (ascii(v_new_key)-65)
                          FROM public.questions q WHERE q.id=v_id)
      OR (v_old.options_text_ru::jsonb -> (ascii(v_old.correct_answer)-65))
        IS DISTINCT FROM (SELECT q.options_text_ru::jsonb -> (ascii(v_new_key)-65)
                          FROM public.questions q WHERE q.id=v_id)
      OR (v_old.options_text_uz::jsonb -> (ascii(v_old.correct_answer)-65))
        IS DISTINCT FROM (SELECT q.options_text_uz::jsonb -> (ascii(v_new_key)-65)
                          FROM public.questions q WHERE q.id=v_id)
   THEN RAISE EXCEPTION 'MATH_S2_SEMANTIC_ANSWER_MOVED_INCORRECTLY'; END IF;
  END IF;
  v_count:=v_count+1;
 END LOOP;
 IF v_count<>112 OR v_replacements<>4
    OR (SELECT count(*) FROM public.questions)<>142
    OR (SELECT count(*) FROM public.tour_questions)<>142
 THEN RAISE EXCEPTION 'MATH_S2_INPLACE_ROW_COUNTS_CHANGED'; END IF;
 IF EXISTS(SELECT 1 FROM public.questions q JOIN private.s2_original_questions o ON o.id=q.id
   WHERE (q.id IN(997001,997002) OR q.qtype='input') AND to_jsonb(q)<>o.body)
 THEN RAISE EXCEPTION 'MATH_S2_OLDER_SEASON_OR_INPUT_CHANGED'; END IF;
 IF EXISTS(SELECT 1 FROM public.tour_questions q JOIN private.s2_original_links o ON o.id=q.id
   WHERE to_jsonb(q)<>o.body)
 THEN RAISE EXCEPTION 'MATH_S2_TOUR_MEMBERSHIP_CHANGED'; END IF;
 IF EXISTS(SELECT 1 FROM public.tours t JOIN public.tour_questions tq ON tq.tour_id=t.id
   JOIN public.questions q ON q.id=tq.question_id
   WHERE t.season_id=902 AND t.subject_id=5 AND q.qtype='mcq'
   GROUP BY t.tour_no HAVING count(*)<>16
      OR count(*) FILTER(WHERE q.correct_answer='A')<>4
      OR count(*) FILTER(WHERE q.correct_answer='B')<>4
      OR count(*) FILTER(WHERE q.correct_answer='C')<>4
      OR count(*) FILTER(WHERE q.correct_answer='D')<>4
 ) THEN RAISE EXCEPTION 'MATH_S2_ANSWER_POSITION_BALANCE_CHANGED'; END IF;
 RAISE NOTICE 'MATH_S2_DISPOSABLE_112_MCQ_4_TRILINGUAL_REPLACEMENTS_INPLACE_PASS';
END $math_s2_rehearsal$;
-- Even on passing test, NOTHING from the transaction may survive.
ROLLBACK;
