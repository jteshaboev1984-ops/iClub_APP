-- Mathematics Practice #574 · four exact-range trilingual source clarifications.
-- Disposable PostgreSQL17 only. No hosted queries or mutation performed by CI.
-- The originally published MCQ options, key and skill are unchanged; this
-- checks future-only membership/QA/history transaction and rollback.
DO $range4$
DECLARE
 v_release constant text := 'math_p1_practice_v2_range4_20261121';
 v_pairs jsonb;
 v_wrong jsonb;
 v_result jsonb;
 v_failed boolean;
 v_original_answers jsonb;
 v_original_drill_answers jsonb;
BEGIN
 SELECT jsonb_agg(jsonb_build_object(
   'old_id',old.question_id,'new_id',fresh.question_id,
   'old_hash',old.content_hash,'new_hash',fresh.content_hash)
   ORDER BY old.question_id)
 INTO v_pairs
 FROM private.practice_v2_question_meta old
 JOIN private.practice_v2_question_meta fresh
   ON fresh.content_key=old.content_key||'-V20261121RANGE4'
 WHERE fresh.release_version=v_release;
 IF v_pairs IS NULL OR jsonb_array_length(v_pairs)<>4
   OR (SELECT array_agg((x.value->>'old_id')::bigint ORDER BY (x.value->>'old_id')::bigint)
       FROM jsonb_array_elements(v_pairs) x)
     IS DISTINCT FROM array[7562::bigint,7565::bigint,7569::bigint,7570::bigint]
 THEN RAISE EXCEPTION 'range4_scope_or_version_mismatch'; END IF;

 IF (SELECT count(*) FROM private.practice_v2_question_meta m
    JOIN public.questions q ON q.id=m.question_id
    JOIN public.practice_pool_questions pp ON pp.question_id=q.id
    WHERE m.release_version=v_release AND m.lifecycle_state='approved'
      AND m.is_runtime_allowed=false AND m.qa_math_status='pending'
      AND m.qa_language_status='pending' AND m.qa_technical_status='pending'
      AND m.qa_tour_separation_status='pending'
      AND q.is_active=false AND q.quality_status='draft'
      AND q.qtype='mcq' AND q.difficulty='medium' AND q.time_limit_sec=60
      AND q.question_text_en IS NOT NULL AND q.question_text_ru IS NOT NULL
      AND q.question_text_uz IS NOT NULL
      AND q.options_text_en IS NOT NULL AND q.options_text_ru IS NOT NULL
      AND q.options_text_uz IS NOT NULL AND pp.is_active=false)<>4
 THEN RAISE EXCEPTION 'range4_staging_is_not_fail_closed'; END IF;

 IF EXISTS(SELECT 1 FROM public.question_version_links)
 THEN RAISE EXCEPTION 'unexpected_prior_version_links'; END IF;
 IF (SELECT count(*) FROM public.questions fresh
   JOIN private.practice_v2_question_meta fm ON fm.question_id=fresh.id
   JOIN public.questions old ON old.id=(
     SELECT (x.value->>'old_id')::bigint
     FROM jsonb_array_elements(v_pairs) x
     WHERE (x.value->>'new_id')::bigint=fresh.id)
   WHERE fm.release_version=v_release
     AND fresh.correct_answer=old.correct_answer AND fresh.qtype=old.qtype
     AND fresh.difficulty=old.difficulty)<>4
 THEN RAISE EXCEPTION 'range4_mcq_contract_changed'; END IF;

 SELECT jsonb_agg(to_jsonb(a) ORDER BY a.id) INTO v_original_answers
 FROM public.practice_session_answers_v4 a;
 SELECT jsonb_agg(to_jsonb(a) ORDER BY a.id) INTO v_original_drill_answers
 FROM public.practice_drill_answers_v4 a;

 v_failed:=false;
 BEGIN
  PERFORM private.math_practice_future_only_activate_v1(v_release,v_pairs);
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM='future_only_version_identity_or_hash_mismatch'
    THEN v_failed:=true;
  ELSE RAISE; END IF;
 END;
 IF NOT v_failed THEN RAISE EXCEPTION 'range4_unapproved_qa_accepted'; END IF;
 UPDATE private.practice_v2_question_meta
 SET qa_math_status='passed',qa_language_status='passed',
   qa_technical_status='passed',qa_tour_separation_status='passed'
 WHERE release_version=v_release;

 v_wrong=jsonb_set(v_pairs,'{0,old_hash}',to_jsonb(repeat('0',64)));
 v_failed:=false;
 BEGIN
  PERFORM private.math_practice_future_only_activate_v1(v_release,v_wrong);
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM='future_only_version_identity_or_hash_mismatch' THEN v_failed:=true;
  ELSE RAISE; END IF;
 END;
 IF NOT v_failed THEN RAISE EXCEPTION 'range4_unpinned_hash_accepted'; END IF;

 SELECT private.math_practice_future_only_activate_v1(v_release,v_pairs)
 INTO v_result;
 IF (v_result->>'replaced')::int<>4
   OR (v_result->>'history_deleted')::boolean<>false
 THEN RAISE EXCEPTION 'range4_atomic_activation_failed'; END IF;
 IF (SELECT count(*) FROM public.practice_pool_questions pp
   JOIN private.practice_v2_question_meta m ON m.question_id=pp.question_id
   WHERE m.release_version=v_release AND pp.is_active=true)<>4
   OR EXISTS(SELECT 1 FROM public.practice_pool_questions
     WHERE question_id IN(7562,7565,7569,7570) AND is_active=true)
   OR (SELECT count(*) FROM public.question_version_links)<>4
 THEN RAISE EXCEPTION 'range4_membership_or_version_links_bad'; END IF;
 IF (SELECT jsonb_agg(to_jsonb(a) ORDER BY a.id)
     FROM public.practice_session_answers_v4 a) IS DISTINCT FROM v_original_answers
   OR (SELECT jsonb_agg(to_jsonb(a) ORDER BY a.id)
     FROM public.practice_drill_answers_v4 a) IS DISTINCT FROM v_original_drill_answers
 THEN RAISE EXCEPTION 'range4_changed_saved_user_answers'; END IF;

 SELECT private.math_practice_future_only_rollback_v1(v_release,v_pairs)
 INTO v_result;
 IF (v_result->>'restored_old_memberships')::int<>4
   OR (v_result->>'history_deleted')::boolean<>false
   OR (SELECT count(*) FROM public.practice_pool_questions
       WHERE question_id IN(7562,7565,7569,7570) AND is_active=true)<>4
   OR (SELECT count(*) FROM public.practice_pool_questions pp
       JOIN private.practice_v2_question_meta m ON m.question_id=pp.question_id
       WHERE m.release_version=v_release AND pp.is_active=true)<>0
   OR (SELECT jsonb_agg(to_jsonb(a) ORDER BY a.id)
       FROM public.practice_session_answers_v4 a) IS DISTINCT FROM v_original_answers
   OR (SELECT jsonb_agg(to_jsonb(a) ORDER BY a.id)
       FROM public.practice_drill_answers_v4 a) IS DISTINCT FROM v_original_drill_answers
 THEN RAISE EXCEPTION 'range4_rollback_changed_history'; END IF;
 RAISE NOTICE 'MATH_PRACTICE_RANGE4_FUTURE_ONLY_PG17_PASS';
END $range4$;
