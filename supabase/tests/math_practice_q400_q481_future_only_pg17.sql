-- #574: Complete DRAFT-CANDIDATE regression for ONLY two pinned
-- Q400/Q481 Mathematics Practice corrections. DISPOSABLE PG17 only. Never hosted.
-- Uses actual confidential authored content *only* in ephemeral fixture SQL.
DO $checked2$
DECLARE
 v_release constant text := 'math_p1_practice_v2_q400_q481_20261120';
 v_pairs jsonb;
 v_result jsonb;
 v_err text;
 v_original_answers jsonb;
 v_original_drill_answers jsonb;
 v_new bigint;
BEGIN
 SELECT jsonb_agg(jsonb_build_object(
  'old_id',old.question_id,'new_id',fresh.question_id,
  'old_hash',old.content_hash,'new_hash',fresh.content_hash)
  ORDER BY old.question_id)
 INTO v_pairs
 FROM private.practice_v2_question_meta old
 JOIN private.practice_v2_question_meta fresh
  ON fresh.content_key=old.content_key||'-V20261120Q400Q481'
 WHERE fresh.release_version=v_release;
 IF v_pairs IS NULL OR jsonb_array_length(v_pairs)<>2
 THEN RAISE EXCEPTION 'two_version_pairs_missing'; END IF;
 IF (SELECT count(*) FROM public.questions q
   JOIN private.practice_v2_question_meta m ON q.id=m.question_id
   WHERE m.release_version=v_release
    AND q.is_active=false AND q.quality_status='draft'
    AND q.qtype='mcq'
    AND m.qa_math_status='pending' AND m.qa_language_status='pending'
    AND m.qa_technical_status='pending'
    AND m.qa_tour_separation_status='pending'
    AND m.lifecycle_state='approved' AND m.is_runtime_allowed=false)<>2
 OR (SELECT count(*) FROM public.question_version_links)<>0
 OR (SELECT count(*) FROM public.practice_pool_questions ppq
     JOIN private.practice_v2_question_meta m ON m.question_id=ppq.question_id
     WHERE m.release_version=v_release AND ppq.is_active)<>0
 THEN RAISE EXCEPTION 'staged_source_not_fail_closed'; END IF;

 SELECT jsonb_agg(to_jsonb(a) ORDER BY a.question_id)
 INTO v_original_answers
 FROM public.practice_session_answers_v4 a WHERE a.session_id=5001;
 SELECT jsonb_agg(to_jsonb(a) ORDER BY a.question_id)
 INTO v_original_drill_answers
 FROM public.practice_drill_answers_v4 a WHERE a.session_id=6001;

 -- QA must remain NOT approved on staging. The first activation must fail.
 BEGIN
  PERFORM private.math_practice_future_only_activate_v1(v_release,v_pairs);
  RAISE EXCEPTION 'unreviewed_staged_questions_published';
 EXCEPTION WHEN raise_exception THEN
  GET STACKED DIAGNOSTICS v_err=message_text;
  IF v_err<>'future_only_version_identity_or_hash_mismatch'
    THEN RAISE EXCEPTION 'incorrect_pending_qa_failure'; END IF;
 END;

 -- Synthetic academic approval is ONLY a CI test-fixture operation.
 UPDATE private.practice_v2_question_meta
 SET qa_math_status='passed',qa_language_status='passed',
     qa_technical_status='passed',qa_tour_separation_status='passed'
 WHERE release_version=v_release;
 -- One altered old hash should deny the whole batch atomically.
 BEGIN
  PERFORM private.math_practice_future_only_activate_v1(v_release,
    jsonb_set(v_pairs,ARRAY['9','old_hash'],to_jsonb(repeat('0',64))));
  RAISE EXCEPTION 'hash_drift_accepted';
 EXCEPTION WHEN raise_exception THEN
  GET STACKED DIAGNOSTICS v_err=message_text;
  IF v_err<>'future_only_version_identity_or_hash_mismatch'
    THEN RAISE EXCEPTION 'incorrect_hash_drift_failure'; END IF;
 END;
 IF (SELECT count(*) FROM public.question_version_links)<>0
 OR (SELECT count(*) FROM public.practice_pool_questions ppq
    JOIN private.practice_v2_question_meta m ON ppq.question_id=m.question_id
    WHERE m.release_version=v_release AND ppq.is_active)<>0
 THEN RAISE EXCEPTION 'hash_drift_left_partial_updates'; END IF;

 v_result:=private.math_practice_future_only_activate_v1(v_release,v_pairs);
 IF COALESCE((v_result->>'replaced')::int,0)<>2
 OR (SELECT count(*) FROM public.question_version_links
     WHERE reason=v_release AND link_type='replacement')<>2
 OR (SELECT count(*) FROM public.practice_pool_questions ppq
     JOIN private.practice_v2_question_meta m ON ppq.question_id=m.question_id
     WHERE m.release_version=v_release AND ppq.is_active)<>2
 OR (SELECT count(*) FROM public.questions q
     JOIN private.practice_v2_question_meta m ON q.id=m.question_id
     WHERE m.release_version='math_p1_practice_v2_2026_10_07'
       AND q.is_active=true AND q.quality_status='published')<>2
 THEN RAISE EXCEPTION 'full_two_cutover_invariant_failed'; END IF;

 -- Issue a synthetic learner response against the new version BEFORE rollback
 -- to prove old and new user evidence remains attributable to its original ID.
 v_new:=(v_pairs->0->>'new_id')::bigint;
 INSERT INTO public.practice_sessions_v4
 (id,user_id,subject_id,question_ids,status)
 VALUES (7010,'cccccccc-cccc-4ccc-8ccc-cccccccccccc',5,
 ARRAY[v_new]::bigint[],'in_progress');
 INSERT INTO public.practice_session_answers_v4
 (session_id,question_id,user_answer,is_correct)
 VALUES(7010,v_new,'TEST_NEW_VERSION',true);

 v_result:=private.math_practice_future_only_rollback_v1(v_release,v_pairs);
 IF COALESCE((v_result->>'restored_old_memberships')::int,0)<>2
 OR (SELECT count(*) FROM public.practice_pool_questions ppq
     JOIN private.practice_v2_question_meta m ON ppq.question_id=m.question_id
     WHERE m.release_version=v_release AND ppq.is_active)<>0
 OR (SELECT count(*) FROM public.practice_pool_questions ppq
     JOIN private.practice_v2_question_meta m ON ppq.question_id=m.question_id
     WHERE m.release_version='math_p1_practice_v2_2026_10_07'
       AND ppq.is_active)<>2
 OR (SELECT count(*) FROM public.question_version_links
     WHERE reason=v_release AND link_type='replacement')<>2
 OR (SELECT count(*) FROM public.practice_session_answers_v4
     WHERE session_id=7010 AND question_id=v_new)<>1
 OR (SELECT jsonb_agg(to_jsonb(a) ORDER BY a.question_id)
     FROM public.practice_session_answers_v4 a WHERE a.session_id=5001)
      IS DISTINCT FROM v_original_answers
 OR (SELECT jsonb_agg(to_jsonb(a) ORDER BY a.question_id)
     FROM public.practice_drill_answers_v4 a WHERE a.session_id=6001)
      IS DISTINCT FROM v_original_drill_answers
 THEN RAISE EXCEPTION 'two_question_rollback_destroyed_issued_answer_history'; END IF;
 RAISE NOTICE 'MATH_PRACTICE_Q400_Q481_TWO_ITEM_PG17_PASS';
END $checked2$;