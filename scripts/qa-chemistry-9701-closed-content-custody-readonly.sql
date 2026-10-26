-- iClub Chemistry 9701: read-only content custody and existing user-progress safeguards.
-- Do not include question bodies or keys in public GitHub.
-- Baseline is immediately after Stage I-05 secure re-authoring topics 5–13.
WITH a AS (
 SELECT (SELECT count(*) FROM private.iclub_exam_core_chemistry_p1_quarantine_v1) AS quarantine_n,
        (SELECT count(*) FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1) AS secure_n,
        (SELECT count(DISTINCT syllabus_unit) FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1) AS secure_units,
        (SELECT count(*) FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1 d
         WHERE d.release_enabled OR d.exam_candidate_eligible OR d.credit_mastery
         OR d.academic_review<>'pending' OR d.language_review<>'pending'
         OR d.format_review<>'pending' OR d.item_md5<>md5(d.item_json::text)) AS insecure_draft_n,
        (SELECT count(*) FROM private.iclub_exam_core_chemistry_p1_quarantine_v1 q
         WHERE q.release_enabled OR q.learner_assessment_eligible OR q.credit_mastery
         OR q.item_md5<>md5(q.item_json::text)) AS unsafe_quarantine_n,
        (SELECT count(*) FROM private.iclub_exam_core_question_candidates_v1 WHERE program_key='chemistry_9701') AS legacy_candidates,
        (SELECT count(*) FROM private.iclub_exam_core_question_candidates_v1
         WHERE program_key='chemistry_9701' AND status='approved') AS approved_legacy_candidates
)
SELECT
 quarantine_n=26 AS quarantined_26,
 secure_n=9 AND secure_units=9 AS secure_pilot_9_units,
 insecure_draft_n=0 AND unsafe_quarantine_n=0 AS zero_unauthorised_assessment_authority,
 NOT has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_quarantine_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_quarantine_v1','SELECT')
 AND NOT has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_secure_drafts_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_secure_drafts_v1','SELECT') AS no_direct_ordinary_user_reads,
 has_table_privilege('service_role','private.iclub_exam_core_chemistry_p1_secure_drafts_v1','SELECT')
 AND NOT has_table_privilege('service_role','private.iclub_exam_core_chemistry_p1_secure_drafts_v1','INSERT')
 AND NOT has_table_privilege('service_role','private.iclub_exam_core_chemistry_p1_quarantine_v1','UPDATE') AS private_read_only_service,
 (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_core_chemistry_p1_secure_drafts_v1'::regclass)
 AND (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_core_chemistry_p1_quarantine_v1'::regclass) AS forced_rls_on_both,
 legacy_candidates=30 AND approved_legacy_candidates=0 AS unchanged_legacy_exam_candidates,
 (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
 WHERE program_key='chemistry_9701' AND status='draft' AND release_enabled=false)=3 AS written_pilots_off,
 (SELECT count(*) FROM private.iclub_exam_core_chemistry_paper_catalog_preview_v1)=348 AS content_map_unchanged,
 (SELECT status='draft' AND launch_enabled=false FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701') AS program_launch_off,
 (SELECT visible_to_learners=false FROM private.iclub_subject_library WHERE subject_key='chemistry') AS subject_library_hidden,
 (private.iclub_exam_core_native_plan_preflight_v1('chemistry_9701','chemistry_2025_2027_v1')->>'state')='blocked' AS runtime_preflight_off,
 (SELECT count(*) FROM private.exam_prep_sessions)>=0
 AND (SELECT count(*) FROM private.exam_prep_responses)>=0
 AND (SELECT count(*) FROM public.practice_attempts)>=0
 AND (SELECT count(*) FROM public.practice_answers)>=0 AS historical_product_tables_readable
FROM a;
