-- J13 Chemistry access/rollback READ-ONLY pre-release invariant suite.
-- All fields are booleans. This intentionally fails after any future owner launch.
-- No secret lesson text, learner IDs or answer keys selected.
SELECT
 (SELECT NOT visible_to_learners AND active_version IS NULL
  FROM private.iclub_subject_library WHERE subject_key='chemistry') AS chemistry_hidden,
 (SELECT NOT launch_enabled AND status='draft'
  FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701') AS core_off,
 (SELECT NOT enabled FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1) AS entry_off,
 (SELECT NOT enabled FROM private.iclub_exam_chemistry_recheck_control_v1 WHERE id=1) AS recheck_off,
 (SELECT NOT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) AS p1_off,
 (SELECT NOT armed AND NOT can_publish FROM private.iclub_exam_chemistry_j12_release_gate_v1) AS no_publish_go,
 (SELECT NOT paper3_enabled AND NOT paper5_enabled AND NOT tutor_sources_enabled
  AND paper3_owner_go_at IS NULL AND paper5_owner_go_at IS NULL
  AND tutor_owner_go_at IS NULL AND approved_source_md5 IS NULL
  FROM private.iclub_exam_chemistry_j13_learning_control_v1 WHERE id=1) AS j13_all_off,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_j13_a_level_permissions_v1) AS a_approvals_empty,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_j13_tutor_permissions_v1) AS tutor_approvals_empty,
 NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_j13_tutor_permissions_v1','SELECT') AS tutor_personal_acl_private,
 (SELECT pg_get_functiondef('public.iclub_exam_chemistry_tutor_source_v1(text,text)'::regprocedure)
   LIKE '%FROM private.iclub_exam_chemistry_j13_tutor_permissions_v1%') AS tutor_requires_individual_approval,
 (SELECT count(*)=6 FROM private.iclub_subject_library_cross_tour_v1
  WHERE subject_key='chemistry' AND paper_code='P3' AND level_code='AS') AS p3_as_six,
 (SELECT count(*)=6 FROM private.iclub_subject_library_cross_tour_v1
  WHERE subject_key='chemistry' AND paper_code='P5' AND level_code='A') AS p5_a_six,
 (SELECT count(*)=154 FROM private.iclub_subject_library_theory
  WHERE subject_key='chemistry') AS theory_source_unchanged,
 (SELECT count(*)=462 FROM private.iclub_subject_library_tutor
  WHERE subject_key='chemistry') AS tutor_source_unchanged,
 (SELECT count(*)=0 FROM private.iclub_subject_library_release_events
  WHERE subject_key='chemistry') AS no_library_publish,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_entry_attempts_v1) AS no_entry_attempts,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_recheck_attempts_v1) AS no_recheck_attempts,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_live_attempts_v1) AS no_p1_attempts,
 (SELECT count(*)>=544 FROM private.exam_prep_sessions) AS math_sessions_preserved,
 (SELECT count(*)>=1979 FROM private.exam_prep_responses) AS math_answers_preserved,
 (SELECT count(*)>=502 FROM public.practice_attempts) AS practice_sessions_preserved,
 (SELECT count(*)>=4816 FROM public.practice_answers) AS practice_answers_preserved,
 NOT has_table_privilege('anon','private.iclub_exam_chemistry_j13_learning_control_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_j13_learning_control_v1','SELECT') AS j13_control_private,
 NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_j13_a_level_permissions_v1','SELECT') AS a_permissions_private,
 NOT has_function_privilege('anon','public.iclub_exam_chemistry_lab_catalog_v1(text,text)','EXECUTE') AS catalog_anon_denied,
 NOT has_function_privilege('anon','public.iclub_exam_chemistry_lab_lesson_v1(text,text,text)','EXECUTE') AS lesson_anon_denied,
 NOT has_function_privilege('anon','public.iclub_exam_chemistry_tutor_source_v1(text,text)','EXECUTE') AS tutor_anon_denied,
 has_function_privilege('authenticated','public.iclub_exam_chemistry_lab_catalog_v1(text,text)','EXECUTE') AS catalog_auth_limited,
 has_function_privilege('authenticated','public.iclub_exam_chemistry_lab_lesson_v1(text,text,text)','EXECUTE') AS lesson_auth_limited,
 has_function_privilege('authenticated','public.iclub_exam_chemistry_tutor_source_v1(text,text)','EXECUTE') AS tutor_auth_limited,
 (public.iclub_exam_chemistry_lab_catalog_v1('P3','ru')->>'code')='not_available' AS p3_denied_with_no_auth,
 (public.iclub_exam_chemistry_lab_catalog_v1('P5','en')->>'code')='not_available' AS p5_denied_with_no_auth,
 (public.iclub_exam_chemistry_lab_lesson_v1('P3','CHEM9701-LAB-01','uz')->>'code')='not_available' AS detail_denied_with_no_auth,
 (public.iclub_exam_chemistry_tutor_source_v1('CHEM9701-01-01','en')->>'code')='not_available' AS tutor_denied_with_no_auth,
 (public.iclub_exam_chemistry_lab_catalog_v1('P1','ru')->>'code')='invalid_request' AS wrong_paper_rejected,
 (public.iclub_exam_chemistry_lab_lesson_v1('P3','CHEM9701-LAB-99','ru')->>'code')='invalid_request' AS wrong_skill_rejected,
 (public.iclub_exam_chemistry_lab_catalog_v1('P3','es')->>'code')='invalid_request' AS unsupported_language_rejected,
 (SELECT pg_get_functiondef('public.iclub_subject_library_content_service_v1(text,text,text)'::regprocedure)
  LIKE '%CASE WHEN s.subject_key=''chemistry'' THEN ''{}''::jsonb%') AS generic_reader_tutor_firewall,
 NOT has_function_privilege('authenticated',
   'public.iclub_subject_library_content_service_v1(text,text,text)','EXECUTE') AS generic_reader_client_denied,
 (SELECT pg_get_functiondef('private.iclub_exam_chemistry_j12_admin_emergency_stop_v1(text)'::regprocedure)
  LIKE '%paper3_enabled=false,paper5_enabled=false,tutor_sources_enabled=false%') AS emergency_revokes_j13,
 (SELECT pg_get_functiondef('private.iclub_exam_chemistry_j12_admin_hide_v1(text)'::regprocedure)
  LIKE '%paper3_enabled=false,paper5_enabled=false,tutor_sources_enabled=false%') AS hide_revokes_j13,
 NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_j12_admin_emergency_stop_v1(text)','EXECUTE') AS emergency_private,
 NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_j13_can_read_lab_v1(text)','EXECUTE') AS lab_helper_private;
