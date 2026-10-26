-- iClub Chemistry 9701 I-11: READ-ONLY regression after nine versioned legacy fixes,
-- seven new secure original P1 drafts, and closed 40+4 editorial mock preview.
-- IMPORTANT: No unissued stems, answer keys, scores, learner IDs or user data are output.
WITH originals AS (
 SELECT count(*) AS total,
 count(*) FILTER(WHERE release_enabled OR exam_candidate_eligible OR credit_mastery) AS exposed,
 count(*) FILTER(WHERE item_md5<>md5(item_json::text)) AS altered
 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1
), review AS (
 SELECT count(*) AS total,
 count(*) FILTER(WHERE gate_status='pass') AS ai_pass,
 count(*) FILTER(WHERE gate_status='fail') AS ai_fail,
 count(*) FILTER(WHERE gate_status='pending') AS pending,
 count(*) FILTER(WHERE q.source_snapshot_md5<>d.item_md5 OR q.can_release OR q.can_grant_mastery) AS broken
 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 q
 JOIN private.iclub_exam_core_chemistry_p1_secure_drafts_v1 d
 USING(program_key,version_key,draft_key,authoring_version)
), revise AS (
 SELECT count(*) AS versions,count(DISTINCT source_legacy_question_id) AS original_ids,
 count(*) FILTER(WHERE release_enabled OR exam_unseen_inventory OR can_score
 OR can_credit_mastery OR item_md5<>md5(item_json::text)) AS unsafe
 FROM private.iclub_exam_core_chemistry_p1_legacy_revisions_v1
), blueprint AS (
 SELECT count(*) AS total,
 count(*) FILTER(WHERE planning_role='proposed_form') AS core_count,
 count(*) FILTER(WHERE planning_role='proposed_reserve') AS reserve_count,
 count(DISTINCT syllabus_unit) FILTER(WHERE planning_role='proposed_form') AS covered_topics,
 count(DISTINCT proposed_question_no) FILTER(WHERE planning_role='proposed_form') AS numbered,
 count(*) FILTER(WHERE issued_to_learner OR scored_exam OR credit_mastery) AS exposed
 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
)
SELECT
 (SELECT total=45 AND exposed=0 AND altered=0 FROM originals) AS secure_new_drafts_45_locked,
 (SELECT total=315 AND ai_pass=308 AND ai_fail=1 AND pending=6 AND broken=0 FROM review) AS ai_reviews_308_good_one_held,
 (SELECT versions=10 AND original_ids=9 AND unsafe=0 FROM revise) AS legacy_nine_originals_corrected_versioned,
 (SELECT count(*)=9 FROM private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1
 WHERE review_status='ai_pass' AND independent_human_review=false
 AND can_issue_formative=false AND can_issue_exam=false AND can_credit_mastery=false) AS revisions_ai_checked_no_runtime,
 (SELECT total=44 AND core_count=40 AND reserve_count=4
 AND covered_topics=22 AND numbered=40 AND exposed=0 FROM blueprint) AS private_mock_40_plus_four_all_topics,
 (SELECT COUNT(*)=30 FROM private.iclub_exam_core_question_candidates_v1
 WHERE program_key='chemistry_9701' AND status='candidate') AS old_30_still_candidate,
 (SELECT COUNT(*)=0 FROM private.iclub_exam_core_question_candidates_v1
 WHERE program_key='chemistry_9701' AND status='approved') AS no_legacy_public_promotion,
 (SELECT COUNT(*)=26 FROM private.iclub_exam_core_chemistry_p1_quarantine_v1) AS original_26_safely_preserved,
 (SELECT count(*)=3 FROM private.iclub_exam_core_written_tasks_v1
 WHERE program_key='chemistry_9701' AND status='draft' AND release_enabled=false) AS written_three_still_hidden,
 (SELECT status='draft' AND launch_enabled=false FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701') AS chemistry_still_off,
 (SELECT visible_to_learners=false FROM private.iclub_subject_library
 WHERE subject_key='chemistry') AS library_still_invisible,
 (private.iclub_exam_core_native_plan_preflight_v1('chemistry_9701','chemistry_2025_2027_v1')->>'state')='blocked' AS native_runtime_still_blocked,
 NOT has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_legacy_revisions_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_legacy_revisions_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_secure_drafts_v1','SELECT') AS learners_cannot_read_private_stems,
 (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_core_chemistry_p1_legacy_revisions_v1'::regclass)
 AND (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1'::regclass)
 AS new_revision_tables_force_rls,
 (SELECT COUNT(*) FROM private.exam_prep_sessions)>=0
 AND (SELECT COUNT(*) FROM private.exam_prep_responses)>=0
 AND (SELECT COUNT(*) FROM public.practice_attempts)>=0
 AND (SELECT COUNT(*) FROM public.practice_answers)>=0
 AND (SELECT COUNT(*) FROM public.user_subjects)>=0 AS learner_product_history_tables_intact;
