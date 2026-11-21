-- Mathematics Practice #574 · nine Hard-transfer future-only release rehearsal.
-- Synthetic disposable PostgreSQL17 fixture only; never hosted production.
-- Tests source-pinned stage -> QA gate -> exact 9-ID atomic swap -> rollback,
-- preserving historical Q351 #7835 -> active #10119 lineage and issued answers.
DO $hard9$
DECLARE
 v_release CONSTANT text := 'math_p1_practice_v2_hard9_20261121';
 v_pairs jsonb;
 v_bad_pairs jsonb;
 v_result jsonb;
 v_failed boolean;
 v_before_main jsonb;
 v_before_drill jsonb;
 v_new_q351 bigint;
BEGIN
 SELECT jsonb_agg(jsonb_build_object(
  'old_id',old.question_id,'new_id',fresh.question_id,
  'old_hash',old.content_hash,'new_hash',fresh.content_hash)
  ORDER BY old.question_id)
 INTO v_pairs
 FROM private.practice_v2_question_meta old
 JOIN private.practice_v2_question_meta fresh
  ON fresh.content_key=old.content_key||'-V20261121HARD9'
 WHERE fresh.release_version=v_release;

 IF v_pairs IS NULL OR jsonb_array_length(v_pairs)<>9
  OR (SELECT array_agg((x.value->>'old_id')::bigint ORDER BY (x.value->>'old_id')::bigint)
     FROM jsonb_array_elements(v_pairs) x)
     IS DISTINCT FROM ARRAY[7511::bigint,7585::bigint,7692::bigint,7723::bigint,
       7769::bigint,7823::bigint,7908::bigint,7974::bigint,10119::bigint]
 THEN RAISE EXCEPTION 'hard9_stage_exact_live_id_mismatch'; END IF;

 SELECT (x.value->>'new_id')::bigint INTO v_new_q351
 FROM jsonb_array_elements(v_pairs) x WHERE (x.value->>'old_id')::bigint=10119;

 IF (SELECT count(*) FROM private.practice_v2_question_meta m
     JOIN public.questions q ON q.id=m.question_id
     JOIN public.practice_pool_questions pp ON pp.question_id=q.id
     WHERE m.release_version=v_release
       AND m.lifecycle_state='approved'
       AND m.qa_math_status='pending' AND m.qa_language_status='pending'
       AND m.qa_technical_status='pending'
       AND m.qa_tour_separation_status='pending'
       AND m.is_runtime_allowed=false AND q.is_active=false
       AND q.quality_status='draft' AND pp.is_active=false
       AND q.difficulty='hard' AND q.time_limit_sec=90
       AND q.qtype='input' AND q.question_text_en IS NOT NULL
       AND q.question_text_ru IS NOT NULL AND q.question_text_uz IS NOT NULL)<>9
 THEN RAISE EXCEPTION 'hard9_staged_must_be_private_and_fail_closed'; END IF;

 IF NOT EXISTS(SELECT 1 FROM public.question_version_links l
    WHERE l.old_question_id=7835 AND l.new_question_id=10119
      AND l.link_type='replacement'
      AND l.reason='math_p1_practice_v2_pending10_20261120')
   OR EXISTS(SELECT 1 FROM public.practice_pool_questions pp
    WHERE pp.question_id=7835 AND pp.is_active=true)
   OR NOT EXISTS(SELECT 1 FROM public.practice_pool_questions pp
    WHERE pp.question_id=10119 AND pp.is_active=true)
 THEN RAISE EXCEPTION 'hard9_prior_q351_version_chain_missing'; END IF;

 SELECT jsonb_agg(to_jsonb(a) ORDER BY a.id)
 INTO v_before_main FROM public.practice_session_answers_v4 a;
 SELECT jsonb_agg(to_jsonb(a) ORDER BY a.id)
 INTO v_before_drill FROM public.practice_drill_answers_v4 a;
 IF NOT EXISTS(SELECT 1 FROM public.practice_drill_answers_v4 WHERE question_id=10119)
 THEN RAISE EXCEPTION 'hard9_missing_in_progress_successor_answer_fixture'; END IF;

 v_failed:=false;
 BEGIN
  PERFORM private.math_practice_future_only_activate_v1(v_release,v_pairs);
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM='future_only_version_identity_or_hash_mismatch'
     THEN v_failed:=true;
  ELSE RAISE; END IF;
 END;
 IF NOT v_failed THEN RAISE EXCEPTION 'hard9_unapproved_QA_accepted'; END IF;

 UPDATE private.practice_v2_question_meta
 SET qa_math_status='passed',qa_language_status='passed',
     qa_technical_status='passed',qa_tour_separation_status='passed'
 WHERE release_version=v_release;

 v_bad_pairs=jsonb_set(v_pairs,'{0,old_hash}',to_jsonb(repeat('0',64)));
 v_failed:=false;
 BEGIN
  PERFORM private.math_practice_future_only_activate_v1(v_release,v_bad_pairs);
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM='future_only_version_identity_or_hash_mismatch'
     THEN v_failed:=true;
  ELSE RAISE; END IF;
 END;
 IF NOT v_failed THEN RAISE EXCEPTION 'hard9_wrong_preimage_hash_accepted'; END IF;

 v_bad_pairs=jsonb_set(v_pairs,'{8,old_id}','7835'::jsonb);
 v_failed:=false;
 BEGIN
  PERFORM private.math_practice_future_only_activate_v1(v_release,v_bad_pairs);
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM='hard9_exact_live_successor_scope'
     THEN v_failed:=true;
  ELSE RAISE; END IF;
 END;
 IF NOT v_failed THEN RAISE EXCEPTION 'hard9_retired_original_Q351_was_accepted'; END IF;

 SELECT private.math_practice_future_only_activate_v1(v_release,v_pairs) INTO v_result;
 IF (v_result->>'replaced')::int<>9 OR (v_result->>'history_deleted')::boolean<>false
 THEN RAISE EXCEPTION 'hard9_incomplete_atomic_swap'; END IF;

 IF (SELECT count(*) FROM public.practice_pool_questions pp
      JOIN private.practice_v2_question_meta m ON m.question_id=pp.question_id
      WHERE m.release_version=v_release AND pp.is_active=true)<>9
   OR (SELECT count(*) FROM public.practice_pool_questions pp
      JOIN private.practice_v2_question_meta m ON m.question_id=pp.question_id
      WHERE m.question_id IN(7511,7585,7692,7723,7769,7823,7908,7974,10119)
       AND pp.is_active=true)<>0
   OR (SELECT count(*) FROM public.question_version_links)<>10
   OR NOT EXISTS(SELECT 1 FROM public.question_version_links l
       WHERE l.old_question_id=7835 AND l.new_question_id=10119)
   OR NOT EXISTS(SELECT 1 FROM public.question_version_links l
       WHERE l.old_question_id=10119 AND l.new_question_id=v_new_q351)
 THEN RAISE EXCEPTION 'hard9_membership_or_q351_lineage_not_atomic'; END IF;

 IF (SELECT jsonb_agg(to_jsonb(a) ORDER BY a.id)
     FROM public.practice_session_answers_v4 a) IS DISTINCT FROM v_before_main
  OR (SELECT jsonb_agg(to_jsonb(a) ORDER BY a.id)
     FROM public.practice_drill_answers_v4 a) IS DISTINCT FROM v_before_drill
 THEN RAISE EXCEPTION 'hard9_changed_historical_student_answers'; END IF;

 SELECT private.math_practice_future_only_rollback_v1(v_release,v_pairs)
 INTO v_result;
 IF (v_result->>'restored_old_memberships')::int<>9
  OR (v_result->>'history_deleted')::boolean<>false
 THEN RAISE EXCEPTION 'hard9_rollback_failed'; END IF;

 IF (SELECT count(*) FROM public.practice_pool_questions pp
     JOIN private.practice_v2_question_meta m ON m.question_id=pp.question_id
     WHERE m.question_id IN(7511,7585,7692,7723,7769,7823,7908,7974,10119)
      AND pp.is_active=true)<>9
  OR EXISTS(SELECT 1 FROM public.practice_pool_questions pp
     WHERE pp.question_id=7835 AND pp.is_active=true)
  OR (SELECT count(*) FROM public.practice_pool_questions pp
      JOIN private.practice_v2_question_meta m ON m.question_id=pp.question_id
      WHERE m.release_version=v_release AND pp.is_active=true)<>0
  OR (SELECT count(*) FROM public.question_version_links)<>10
  OR (SELECT jsonb_agg(to_jsonb(a) ORDER BY a.id)
      FROM public.practice_session_answers_v4 a) IS DISTINCT FROM v_before_main
  OR (SELECT jsonb_agg(to_jsonb(a) ORDER BY a.id)
      FROM public.practice_drill_answers_v4 a) IS DISTINCT FROM v_before_drill
 THEN RAISE EXCEPTION 'hard9_rollback_damaged_old_history_or_chain'; END IF;

 RAISE NOTICE 'MATH_PRACTICE_HARD9_SUCCESSOR_PG17_PASS';
END $hard9$;
