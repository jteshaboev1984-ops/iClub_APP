-- iClub Chemistry 9701 Stage I-10 read-only acceptance, internal AI QA ONLY.
-- No question text, keyed answers or user records exposed in result; all fields must be true.
WITH new_qa AS(
 SELECT COUNT(*) AS all_gates,
 COUNT(*) FILTER(WHERE gate_status='pass') AS passes,
 COUNT(*) FILTER(WHERE gate_status='fail') AS fails,
 COUNT(*) FILTER(WHERE gate_status='pending') AS pending,
 COUNT(*) FILTER(WHERE gate_status='pass' AND reviewer_identity=
 'OpenAI GPT-6 internal AI QA — NOT independent or human review'
 AND reviewer_evidence IS NOT NULL AND length(btrim(reviewer_evidence))>=30
 AND reviewed_at IS NOT NULL) AS correctly_attributed_ai_passes,
 COUNT(*) FILTER(WHERE qa.source_snapshot_md5<>d.item_md5 OR qa.can_release OR qa.can_grant_mastery) AS unsafe
 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 qa
 JOIN private.iclub_exam_core_chemistry_p1_secure_drafts_v1 d
 USING(program_key,version_key,draft_key,authoring_version)
), old_qa AS(
 SELECT COUNT(*) AS linked,
 COUNT(*) FILTER(WHERE c.qa_scope_status='pass' AND c.qa_academic_status='pass'
 AND c.qa_language_status='pass' AND c.qa_format_status='pass'
 AND c.status='candidate' AND evidence.review_class='ai_first_pass_no_issue_found'
 AND evidence.academy_review_is_independent=false) AS clean,
 COUNT(*) FILTER(WHERE c.qa_scope_status='fail' OR c.qa_academic_status='fail'
 OR c.qa_language_status='fail' OR c.qa_format_status='fail') AS held,
 COUNT(*) FILTER(WHERE c.status='approved') AS approved,
 COUNT(*) FILTER(WHERE c.source_snapshot_md5<>evidence.source_snapshot_md5
 OR c.source_snapshot_md5<>r.source_snapshot_md5 OR evidence.can_issue_question
 OR evidence.can_credit_mastery) AS unsafe
 FROM private.iclub_exam_core_question_candidates_v1 c
 JOIN private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1 evidence
 USING(program_key,version_key,paper_code,skill_key,legacy_question_id)
 JOIN private.iclub_exam_core_question_review_v1 r
 USING(program_key,version_key,legacy_question_id)
 WHERE c.program_key='chemistry_9701'
), preview AS(
 SELECT COUNT(*) AS n, COUNT(*) FILTER(WHERE
 source_hash_valid AND source_id_and_draft_valid
 AND single_choice_key_format_valid AND paper_format_valid
 AND all_three_locale_keys AND locales_content_structurally_complete
 AND no_duplicate_options_in_locale AND no_duplicate_new_english_stem
 AND no_exact_legacy_english_stem AND direct_p1_skill_exists
 AND seven_review_slots_exist AND all_review_snapshots_current
 AND remains_draft_and_unapproved
 AND NOT can_issue_learner_assessment AND NOT can_credit_mastery
 ) AS good
 FROM private.iclub_exam_core_chemistry_p1_item_preflight_v1
)
SELECT
 (SELECT all_gates=266 AND passes=259 AND fails=1 AND pending=6 FROM new_qa)
 AS new_ai_gate_distribution_pass,
 (SELECT correctly_attributed_ai_passes=259 FROM new_qa)
 AS all_ai_passes_not_misrepresented_as_human,
 (SELECT unsafe=0 FROM new_qa) AS all_new_review_hashes_match,
 (SELECT n=38 AND good=38 FROM preview) AS all_new_drafts_structurally_valid,
 (SELECT linked=30 AND clean=21 AND held=9 AND approved=0 FROM old_qa)
 AS legacy_qa_21_clear_9_hold_0_approved,
 (SELECT unsafe=0 FROM old_qa) AS legacy_snapshots_and_authority_safe,
 (SELECT COUNT(*)=30 FROM private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1)
 AS old_review_ledger_complete,
 (SELECT COUNT(*)=26 FROM private.iclub_exam_core_chemistry_p1_quarantine_v1)
 AS preserved_all_26_prior_originals,
 (SELECT fully_reviewed_private=37 AND flagged_private=1 AND secure_ready_items=0
 AND can_issue_mock=false AND can_mark_mastery=false
 FROM private.iclub_exam_core_chemistry_p1_assembly_readiness_v1)
 AS private_mock_still_off_even_with_internal_ai_review,
 (SELECT COUNT(*)=3 FROM private.iclub_exam_core_written_tasks_v1
 WHERE program_key='chemistry_9701' AND status='draft' AND release_enabled=false)
 AS written_pilots_still_closed,
 (SELECT status='draft' AND launch_enabled=false
 FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701')
 AS chemistry_program_remains_off,
 (SELECT visible_to_learners=false FROM private.iclub_subject_library WHERE subject_key='chemistry')
 AS chemistry_library_hidden,
 (private.iclub_exam_core_native_plan_preflight_v1('chemistry_9701','chemistry_2025_2027_v1')->>'state')='blocked'
 AS native_learner_runtime_blocked,
 NOT has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_secure_drafts_v1','SELECT')
 AS student_cannot_read_private_qa_or_draft,
 (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1'::regclass)
 AS private_legacy_ai_review_forced_rls,
 (SELECT COUNT(*) FROM private.exam_prep_sessions)>=0
 AND (SELECT COUNT(*) FROM private.exam_prep_responses)>=0
 AND (SELECT COUNT(*) FROM public.practice_attempts)>=0
 AND (SELECT COUNT(*) FROM public.practice_answers)>=0
 AND (SELECT COUNT(*) FROM public.user_subjects)>=0
 AS maths_practice_learner_tables_accessible;
