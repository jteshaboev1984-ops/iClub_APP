-- iClub Chemistry 9701 / I-08 preliminary P1 coverage release gate (READ ONLY).
-- No question bodies, keys, answer options, explanations, grades or user data written.
-- All checks must return TRUE. This is NOT independent academic approval.
WITH units AS (
 SELECT generate_series(1,22) AS unit
), legacy AS(
 SELECT s.syllabus_unit AS unit,COUNT(*) AS n,
 COUNT(*) FILTER (WHERE c.qa_format_status='fail' OR c.qa_language_status='fail'
 OR c.qa_scope_status='fail' OR c.qa_academic_status='fail') AS known_bad
 FROM private.iclub_exam_core_question_candidates_v1 c
 JOIN private.iclub_exam_core_skills_v1 s ON s.program_key=c.program_key
 AND s.version_key=c.version_key AND s.skill_key=c.skill_key
 WHERE c.program_key='chemistry_9701'
 GROUP BY 1
), secured AS(
 SELECT d.syllabus_unit AS unit,COUNT(*) AS n,
 COUNT(*) FILTER(WHERE EXISTS(
  SELECT 1 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 q
  WHERE q.program_key=d.program_key AND q.version_key=d.version_key
  AND q.draft_key=d.draft_key AND q.authoring_version=d.authoring_version
  AND q.gate_status='fail')) AS known_bad
 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1 d GROUP BY 1
), coverage AS(
 SELECT u.unit,coalesce(l.n,0) AS legacy_count,coalesce(l.known_bad,0) AS legacy_bad,
 coalesce(s.n,0) AS private_count,coalesce(s.known_bad,0) AS private_bad
 FROM units u LEFT JOIN legacy l USING(unit) LEFT JOIN secured s USING(unit)
), pre AS(
 SELECT COUNT(*) total,COUNT(*) FILTER(WHERE source_hash_valid AND source_id_and_draft_valid
 AND single_choice_key_format_valid AND paper_format_valid AND all_three_locale_keys
 AND locales_content_structurally_complete AND no_duplicate_options_in_locale
 AND no_duplicate_new_english_stem AND no_exact_legacy_english_stem AND direct_p1_skill_exists
 AND seven_review_slots_exist AND all_review_snapshots_current AND remains_draft_and_unapproved
 AND NOT can_issue_learner_assessment AND NOT can_credit_mastery) technical_good
 FROM private.iclub_exam_core_chemistry_p1_item_preflight_v1
)
SELECT
 (SELECT total=38 AND technical_good=38 FROM pre) AS closed_technical_preflight_pass,
 (SELECT COUNT(*)=22 FROM coverage WHERE legacy_count+private_count-legacy_bad-private_bad>=2)
  AS all_22_as_topics_two_preliminary_unflagged_pass,
 (SELECT COUNT(*)=13 FROM coverage WHERE unit BETWEEN 10 AND 22
  AND private_count-private_bad>=2) AS all_13_target_topics_two_private_unflagged_pass,
 (SELECT COUNT(*)=266 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1) AS review_slots_266_pass,
 (SELECT COUNT(*)=265 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1
 WHERE gate_status='pending') AS pending_265_pass,
 (SELECT COUNT(*)=1 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1
 WHERE gate_status='fail' AND gate_key='syllabus_scope'
 AND reviewer_identity LIKE 'AI-assisted%') AS explicit_mapping_issue_recorded_pass,
 (SELECT COUNT(*)=0 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1
 WHERE gate_status='pass') AS no_unearned_academic_approval_pass,
 (SELECT COUNT(*)=0 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 qa
 JOIN private.iclub_exam_core_chemistry_p1_secure_drafts_v1 d USING
 (program_key,version_key,draft_key,authoring_version)
 WHERE qa.source_snapshot_md5<>d.item_md5 OR qa.can_release OR qa.can_grant_mastery)
 AS review_source_hash_and_authority_pass,
 (SELECT COUNT(*)=30 FROM private.iclub_exam_core_question_candidates_v1
 WHERE program_key='chemistry_9701') AS legacy_candidate_links_intact_pass,
 (SELECT COUNT(*)=0 FROM private.iclub_exam_core_question_candidates_v1
 WHERE program_key='chemistry_9701' AND status='approved') AS no_legacy_approvals_pass,
 (SELECT COUNT(*)=26 FROM private.iclub_exam_core_chemistry_p1_quarantine_v1) AS original_26_preserved_pass,
 NOT has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_secure_drafts_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_secure_drafts_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_qa_slots_v1','SELECT')
 AS learner_confidentiality_pass,
 (SELECT status='draft' AND launch_enabled=false FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701') AS chemistry_program_off_pass,
 (SELECT visible_to_learners=false FROM private.iclub_subject_library
 WHERE subject_key='chemistry') AS chemistry_library_hidden_pass,
 (private.iclub_exam_core_native_plan_preflight_v1('chemistry_9701',
 'chemistry_2025_2027_v1')->>'state')='blocked' AS native_runtime_blocked_pass;
