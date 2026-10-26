-- Chemistry 9701 / I-06 proof (READ-ONLY).
-- Never publish exam questions, correct answers, or answer-key content in Git.
WITH d AS (
 SELECT count(*) AS draft_count,count(DISTINCT syllabus_unit) AS topic_count,
 COUNT(*) FILTER(WHERE release_enabled OR exam_candidate_eligible OR credit_mastery
 OR academic_review<>'pending' OR language_review<>'pending' OR format_review<>'pending') AS draft_unsafe
 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1
), g AS(
 SELECT count(*) AS gate_count,
 count(DISTINCT draft_key) AS gate_item_count,
 count(*) FILTER(WHERE gate_status<>'pending' OR can_release OR can_grant_mastery
 OR reviewer_identity IS NOT NULL OR reviewer_evidence IS NOT NULL
 OR reviewed_at IS NOT NULL) AS invalid_or_premature_gates,
 count(*) FILTER(WHERE qa.source_snapshot_md5<>src.item_md5) AS changed_snapshot_links
 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 qa
 JOIN private.iclub_exam_core_chemistry_p1_secure_drafts_v1 src
 USING(program_key,version_key,draft_key,authoring_version)
), p AS(
 SELECT COUNT(*) AS old_count FROM private.iclub_exam_core_chemistry_p1_quarantine_v1
)
SELECT
 (SELECT draft_count FROM d)=18 AS eighteen_private_drafts,
 (SELECT topic_count FROM d)=18 AS eighteen_units_five_to_twenty_two,
 (SELECT min(syllabus_unit)=5 AND max(syllabus_unit)=22
 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1) AS topic_range_verified,
 (SELECT draft_unsafe FROM d)=0 AS no_automatic_content_release,
 (SELECT gate_count FROM g)=126 AS seven_review_gates_each,
 (SELECT gate_item_count FROM g)=18 AS all_drafts_in_review_queue,
 (SELECT invalid_or_premature_gates FROM g)=0 AS no_unearned_review_passes,
 (SELECT changed_snapshot_links FROM g)=0 AS all_review_hashes_current,
 (SELECT old_count FROM p)=26 AS old_twenty_six_retained,
 (SELECT count(*) FROM private.iclub_exam_core_question_candidates_v1 WHERE program_key='chemistry_9701')=30 AS legacy_candidates_unchanged,
 (SELECT count(*) FROM private.iclub_exam_core_question_candidates_v1
 WHERE program_key='chemistry_9701' AND status='approved')=0 AS no_legacy_approvals,
 (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1 WHERE program_key='chemistry_9701')=3 AS written_pilots_unchanged,
 NOT has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_qa_slots_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_qa_slots_v1','SELECT') AS no_student_review_access,
 NOT has_table_privilege('service_role','private.iclub_exam_core_chemistry_p1_qa_slots_v1','UPDATE')
 AND has_table_privilege('service_role','private.iclub_exam_core_chemistry_p1_qa_slots_v1','SELECT') AS service_role_read_only,
 (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_core_chemistry_p1_qa_slots_v1'::regclass) AS forced_review_rls,
 (SELECT status='draft' AND launch_enabled=false
 FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701') AS chemistry_draft_off,
 (SELECT visible_to_learners=false FROM private.iclub_subject_library WHERE subject_key='chemistry') AS chemistry_library_hidden,
 (private.iclub_exam_core_native_plan_preflight_v1('chemistry_9701','chemistry_2025_2027_v1')->>'state')='blocked' AS native_exam_core_still_blocked,
 (SELECT count(*) FROM private.exam_prep_sessions)>=0 AND
 (SELECT count(*) FROM public.practice_attempts)>=0 AS legacy_product_tables_readable;
