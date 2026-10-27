-- Chemistry J-04 final READ-ONLY regression, safe to repeat on production.
-- Positive end-to-end authenticated API simulated inside single transaction and ROLLBACK;
-- see docs/exam-prep-chemistry-j04-private-e2e-20261027.md for precise test scope.
-- NEVER run tests by committing synthetic grants / publishing Chemistry.
WITH baseline AS (
 SELECT count(*) math_active,
 count(*) FILTER(WHERE private.iclub_exam_chemistry_p1_math_beta_eligible_v1(m.user_id)) chemistry_eligible
 FROM private.exam_prep_beta_members m
 JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
 JOIN private.exam_prep_beta_consents k ON k.cohort_id=c.id AND k.user_id=m.user_id
 WHERE c.cohort_key='math_as_p1_p5_beta_2026_09_01'
 AND c.program_key='math_as_p1_p5' AND m.member_status='active'
 AND m.activated_at IS NOT NULL AND k.consent_status='granted' AND k.revoked_at IS NULL
)
SELECT
 (SELECT math_active=3 FROM baseline) AS mathematics_beta_three_active,
 (SELECT chemistry_eligible=2 FROM baseline) AS chemistry_subject_two_math_beta_users,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_beta_members_v1)
 AS zero_real_chemistry_optins,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_live_attempts_v1)
 AS zero_real_chemistry_attempts,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_shadow_sessions_v1)
 AS zero_synthetic_sessions_left,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_owner_release_items_v1)
 AS zero_owner_release_items,
 (SELECT enabled=false AND owner_go_at IS NULL FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1)
 AS chemistry_beta_kill_gate_off,
 (SELECT status='draft' AND launch_enabled=false FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1')
 AS chemistry_program_draft_off,
 (SELECT status='draft' AND mcq_count=40 AND duration_seconds=4500
 FROM private.iclub_exam_core_papers_v1
 WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1' AND paper_code='P1')
 AS chemistry_P1_paper_draft_75min,
 (SELECT visible_to_learners=false FROM private.iclub_subject_library WHERE subject_key='chemistry')
 AS chemistry_learning_library_hidden,
 (private.iclub_exam_core_native_plan_preflight_v1('chemistry_9701','chemistry_2025_2027_v1')->>'state')='blocked'
 AS chemistry_native_preflight_blocked,
 public.get_my_exam_prep_chemistry_shell_v1('ru')='{}'::jsonb AS shell_empty_ru,
 public.get_my_exam_prep_chemistry_shell_v1('uz')='{}'::jsonb AS shell_empty_uz,
 public.get_my_exam_prep_chemistry_shell_v1('en')='{}'::jsonb AS shell_empty_en,
 (SELECT count(*)=45 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1) AS forty_five_originals_preserved,
 (SELECT count(*)=26 FROM private.iclub_exam_core_chemistry_p1_quarantine_v1) AS twenty_six_early_versions_preserved,
 (SELECT count(*)=40 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_form') AS private_mock_form_40,
 (SELECT count(*)=4 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_reserve') AS private_reserve_4,
 (SELECT count(DISTINCT syllabus_unit)=22 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_form') AS all_22_AS_topics,
 (SELECT count(*)=308 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 WHERE gate_status='pass')
 AS AI_review_checks_unchanged,
 (SELECT count(*)=1 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 WHERE gate_status='fail')
 AS old_editorial_hold_still_blocked,
 (SELECT count(*)=0 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1
 WHERE release_enabled OR exam_candidate_eligible OR credit_mastery) AS no_item_release_flags,
 (SELECT count(*)=0 FROM private.iclub_exam_core_question_candidates_v1
 WHERE program_key='chemistry_9701' AND status='approved') AS historical_Chemistry_Practice_not_promoted,
 (SELECT count(*)=3 FROM private.iclub_exam_core_written_tasks_v1
 WHERE program_key='chemistry_9701' AND status='draft' AND release_enabled=false)
 AS other_writing_papers_draft,
 (SELECT count(*)>=544 FROM private.exam_prep_sessions) AS mathematics_history_intact,
 (SELECT count(*)>=1979 FROM private.exam_prep_responses) AS mathematics_answers_intact,
 (SELECT count(*)>=502 FROM public.practice_attempts) AS practice_history_intact,
 (SELECT count(*)>=4816 FROM public.practice_answers) AS practice_answers_intact,
 (SELECT count(*)>=1 FROM private.iclub_exam_native_mcq_attempts_v1) AS economics_history_intact,
 NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_p1_live_attempts_v1','SELECT')
 AND NOT has_table_privilege('anon','private.iclub_exam_chemistry_p1_live_attempts_v1','SELECT')
 AS private_exam_answers_not_visible_to_browsers,
 NOT has_function_privilege('anon','public.iclub_exam_chemistry_p1_start_v1(text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_p1_get_v1(uuid,text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_p1_answer_v1(uuid,integer,integer)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_p1_finish_v1(uuid)','EXECUTE')
 AS anon_cannot_use_chemistry_assessment,
 NOT has_function_privilege('anon','public.grant_my_exam_prep_chemistry_consent_v1(text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.get_my_exam_prep_chemistry_beta_status_v1()','EXECUTE')
 AS anon_cannot_use_beta_controls;
