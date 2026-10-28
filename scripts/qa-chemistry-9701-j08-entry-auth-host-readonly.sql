-- J08 final read-only Chemistry ENTRY safety, privacy & regression.
-- No student data, stems, private keys or synthetic attempts are emitted.
SELECT
(SELECT count(*)=22 FROM private.iclub_exam_chemistry_entry_items_v1) AS original_entry_22,
(SELECT count(DISTINCT syllabus_unit)=22 FROM private.iclub_exam_chemistry_entry_items_v1) AS syllabus_coverage_22,
(SELECT count(*)=154 FROM private.iclub_exam_chemistry_entry_review_v1 WHERE verdict='internal_ai_pass') AS internal_ai_slots_154,
(SELECT count(*)=22 FROM private.iclub_exam_chemistry_entry_preflight_v1
 WHERE seven_AI_gates AND different_from_P1_selected_skill AND different_from_P1_english_stem AND strictly_unreleased) AS entry_source_preflight_all_22,
(SELECT count(*)=22 FROM private.iclub_exam_chemistry_entry_study_links_v1
 WHERE AI_review_complete AND seven_review_gates AND syllabus_skill_link
 AND trilingual_theory_link AND trilingual_tutor_link AND distinct_from_exam_blueprint AND unreleased)
 AS study_skill_links_22_stable,
(SELECT count(*)=22 FROM private.iclub_exam_chemistry_entry_items_v1
 WHERE can_issue_learner=false AND can_grade_mastery=false AND can_be_p1_paper=false) AS entry_drafts_cannot_auto_release_or_credit,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_entry_attempts_v1) AS no_real_entry_attempts,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_entry_shadow_v1) AS no_synthetic_entry_attempts,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_entry_release_items_v1) AS no_owner_entry_release_items,
(SELECT enabled=false AND owner_go_at IS NULL FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1) AS owner_entry_gate_off,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_beta_members_v1) AS chemistry_beta_consents_zero,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_live_attempts_v1) AS chemistry_p1_attempts_zero,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_owner_release_items_v1) AS P1_content_approval_zero,
(SELECT enabled=false FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) AS P1_beta_control_off,
(SELECT status='draft' AND launch_enabled=false FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701') AS Chemistry_program_draft_off,
(SELECT visible_to_learners=false FROM private.iclub_subject_library WHERE subject_key='chemistry') AS Chemistry_library_hidden,
(private.iclub_exam_core_native_plan_preflight_v1('chemistry_9701','chemistry_2025_2027_v1')->>'state')='blocked' AS existing_Core_gate_blocked,
public.get_my_exam_prep_chemistry_entry_shell_v1('ru')='{}'::jsonb AS Entry_shell_fails_closed_ru,
public.get_my_exam_prep_chemistry_entry_shell_v1('uz')='{}'::jsonb AS Entry_shell_fails_closed_uz,
public.get_my_exam_prep_chemistry_entry_shell_v1('en')='{}'::jsonb AS Entry_shell_fails_closed_en,
public.get_my_exam_prep_chemistry_shell_v1('ru')='{}'::jsonb AS P1_shell_unchanged_closed,
(SELECT count(*)=40 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_form') AS old_P1_40_untouched,
(SELECT count(*)=4 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_reserve') AS P1_reserve_4_untouched,
(SELECT count(*)=45 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1) AS P1_original_drafts_45_untouched,
(SELECT count(*)=26 FROM private.iclub_exam_core_chemistry_p1_quarantine_v1) AS original_earlier_26_preserved,
(SELECT count(*)>=544 FROM private.exam_prep_sessions) AS Mathematics_sessions_preserved,
(SELECT count(*)>=1979 FROM private.exam_prep_responses) AS Mathematics_answers_preserved,
(SELECT count(*)>=502 FROM public.practice_attempts) AS Practice_attempts_preserved,
(SELECT count(*)>=4816 FROM public.practice_answers) AS Practice_answers_preserved,
(SELECT count(*)>=1 FROM private.iclub_exam_native_mcq_attempts_v1) AS Economics_attempts_preserved,
(SELECT count(*)>=2098 FROM public.user_subjects) AS subject_choices_preserved,
(SELECT relrowsecurity AND relforcerowsecurity FROM pg_class WHERE oid='private.iclub_exam_chemistry_entry_attempts_v1'::regclass)
 AND (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class WHERE oid='private.iclub_exam_chemistry_entry_release_v1'::regclass)
 AND (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class WHERE oid='private.iclub_exam_chemistry_entry_release_items_v1'::regclass) AS new_tables_FORCE_RLS,
NOT has_table_privilege('anon','private.iclub_exam_chemistry_entry_attempts_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_entry_attempts_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_entry_release_items_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_entry_items_v1','SELECT') AS no_private_exam_keys_in_browser,
NOT has_function_privilege('anon','public.get_my_exam_prep_chemistry_entry_shell_v1(text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_entry_start_v1(text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_entry_get_v1(uuid,text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_entry_answer_v1(uuid,integer,integer)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_entry_finish_v1(uuid)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_entry_history_v1()','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_entry_review_v1(uuid,text)','EXECUTE') AS anonymous_blocked_on_every_ENTRY_RPC,
has_function_privilege('authenticated','public.get_my_exam_prep_chemistry_entry_shell_v1(text)','EXECUTE')
 AND has_function_privilege('authenticated','public.iclub_exam_chemistry_entry_start_v1(text)','EXECUTE')
 AND has_function_privilege('authenticated','public.iclub_exam_chemistry_entry_get_v1(uuid,text)','EXECUTE')
 AND has_function_privilege('authenticated','public.iclub_exam_chemistry_entry_answer_v1(uuid,integer,integer)','EXECUTE')
 AND has_function_privilege('authenticated','public.iclub_exam_chemistry_entry_finish_v1(uuid)','EXECUTE')
 AND has_function_privilege('authenticated','public.iclub_exam_chemistry_entry_history_v1()','EXECUTE')
 AND has_function_privilege('authenticated','public.iclub_exam_chemistry_entry_review_v1(uuid,text)','EXECUTE') AS authenticated_contract_present_but_owner_gated,
NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_entry_student_authorized_v1()','EXECUTE') AS private_authorisation_helper_not_exposed,
(SELECT count(*)=1 FROM pg_indexes WHERE schemaname='private'
 AND indexname='chemistry_entry_no_same_form_retake_uq') AS anti_memorisation_unique_index_present,
(SELECT count(*)=1 FROM pg_indexes WHERE schemaname='private'
 AND indexname='chemistry_entry_only_one_active_v1') AS no_parallel_active_entry_attempts,
(SELECT count(*)=0 FROM private.iclub_exam_chemistry_entry_review_v1 q
 JOIN private.iclub_exam_chemistry_entry_items_v1 i ON i.id=q.item_id
 WHERE q.snapshot_md5<>i.item_md5) AS every_AI_review_pinned_to_exact_source_hash;
