-- Chemistry J09 repeatable, production READ-ONLY. No item bodies or answer keys returned.
SELECT
(SELECT count(*)=22 FROM private.iclub_exam_chemistry_recheck_items_v1) AS twenty_two_private_rechecks,
(SELECT count(DISTINCT syllabus_unit)=22 FROM private.iclub_exam_chemistry_recheck_items_v1) AS all_AS_units_covered,
(SELECT count(*)=154 FROM private.iclub_exam_chemistry_recheck_review_v1 WHERE verdict='internal_ai_pass'
 AND reviewer_type='internal_ai') AS internal_AI_review_slots_154,
(SELECT count(*)=22 FROM private.iclub_exam_chemistry_recheck_preflight_v1
 WHERE seven_internal_AI_reviews AND different_from_entry_stem AND different_from_P1_stem
 AND unreleased_no_mastery) AS all_22_preflight_pass,
(SELECT count(*)=10 FROM private.iclub_exam_chemistry_recheck_revisions_v1) AS old_editorial_variants_privately_preserved,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_recheck_items_v1 r
 LEFT JOIN private.iclub_exam_core_skills_v1 s ON s.program_key=r.program_key
 AND s.version_key=r.version_key AND s.skill_key=r.skill_key
 WHERE s.skill_key IS NULL OR s.level_code<>'AS' OR s.syllabus_unit<>r.syllabus_unit
 OR s.syllabus_point IS DISTINCT FROM r.syllabus_point
 OR s.syllabus_point='NO_EXPLICIT_9701_OUTCOME') AS all_recheck_skills_strictly_AS_syllabus_mapped,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_recheck_review_v1 q
 JOIN private.iclub_exam_chemistry_recheck_items_v1 i ON i.id=q.item_id
 WHERE q.snapshot_md5 IS DISTINCT FROM i.item_md5) AS all_recheck_QA_exact_source_hashes,
(SELECT count(*)=22 FROM private.iclub_exam_chemistry_recheck_items_v1
 WHERE can_issue_learner=false AND can_credit_mastery=false
 AND can_be_entry_question=false AND can_be_P1_paper=false) AS rechecks_can_never_auto_release_or_credit_mastery,
(SELECT count(*)=22 FROM private.iclub_exam_chemistry_entry_items_v1) AS original_entry_22_unchanged,
(SELECT count(*)=154 FROM private.iclub_exam_chemistry_entry_review_v1
 WHERE verdict='internal_ai_pass') AS original_entry_QA_unchanged,
(SELECT count(*)=45 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1) AS original_P1_drafts_45_preserved,
(SELECT count(*)=26 FROM private.iclub_exam_core_chemistry_p1_quarantine_v1) AS earlier_26_originals_retained,
(SELECT count(*)=40 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_form') AS P1_form_40_preserved,
(SELECT count(*)=4 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_reserve') AS P1_reserves_4_preserved,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_entry_attempts_v1) AS no_real_Chemistry_entry_attempts,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_entry_shadow_v1) AS no_technical_entry_attempts_left,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_live_attempts_v1) AS no_real_Chemistry_P1_attempts,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_beta_members_v1) AS no_Chemistry_consent_rows,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_entry_release_items_v1) AS no_owner_entry_release_items,
(SELECT enabled=false AND owner_go_at IS NULL FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1) AS entry_beta_gate_off,
(SELECT enabled=false FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) AS P1_beta_gate_off,
(SELECT status='draft' AND launch_enabled=false FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701') AS Chemistry_program_draft_off,
(SELECT visible_to_learners=false AND active_version IS NULL FROM private.iclub_subject_library
 WHERE subject_key='chemistry') AS Chemistry_lessons_not_published,
public.get_my_exam_prep_chemistry_entry_shell_v1('ru')='{}'::jsonb AS no_Entry_shell_without_GO,
public.get_my_exam_prep_chemistry_shell_v1('ru')='{}'::jsonb AS no_P1_shell_without_GO,
(public.iclub_exam_chemistry_entry_lesson_v1(
 '00000000-0000-4000-8000-000000000001'::uuid,
 'CHEM9701-01-02','ru')->>'code')='invalid_request'
 AS no_theory_without_logged_in_identity,
NOT has_function_privilege('anon','public.iclub_exam_chemistry_entry_lesson_v1(uuid,text,text)','EXECUTE')
 AS lesson_anon_EXECUTE_denied,
has_function_privilege('authenticated','public.iclub_exam_chemistry_entry_lesson_v1(uuid,text,text)','EXECUTE')
 AS lesson_auth_RPC_available_but_owner_gated,
NOT has_table_privilege('authenticated','private.iclub_subject_library_theory','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_recheck_items_v1','SELECT')
 AND NOT has_table_privilege('anon','private.iclub_exam_chemistry_recheck_revisions_v1','SELECT')
 AS hidden_theory_and_recheck_questions_not_queryable_by_client,
(SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_chemistry_recheck_items_v1'::regclass)
 AND (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_chemistry_recheck_review_v1'::regclass)
 AND (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_chemistry_recheck_revisions_v1'::regclass)
 AS all_recheck_storage_FORCE_RLS,
(SELECT count(*)>=544 FROM private.exam_prep_sessions) AS Mathematics_sessions_intact,
(SELECT count(*)>=1979 FROM private.exam_prep_responses) AS Mathematics_responses_intact,
(SELECT count(*)>=1 FROM private.iclub_exam_native_mcq_attempts_v1) AS Economics_attempts_intact,
(SELECT count(*)>=502 FROM public.practice_attempts) AS Practice_attempts_intact,
(SELECT count(*)>=4816 FROM public.practice_answers) AS Practice_answers_intact,
(SELECT count(*)>=2098 FROM public.user_subjects) AS subject_choices_intact;
