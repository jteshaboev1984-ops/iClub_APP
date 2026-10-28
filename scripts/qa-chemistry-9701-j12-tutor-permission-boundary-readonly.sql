-- J-12 supplementary READ-ONLY security boundary check (2026-10-27).
-- Generic library content API includes Tutor for service/admin contexts.
-- Do NOT grant this API to learners as a Chemistry Tutor route.
-- These tests never reveal source content, account IDs, answers or secrets.
SELECT
 NOT has_function_privilege('anon',
   'public.iclub_subject_library_content_service_v1(text,text,text)','EXECUTE')
   AS generic_content_anon_denied,
 NOT has_function_privilege('authenticated',
   'public.iclub_subject_library_content_service_v1(text,text,text)','EXECUTE')
   AS generic_content_authenticated_denied,
 NOT has_function_privilege('anon',
   'public.iclub_subject_library_catalog_service_v1(text,text)','EXECUTE')
   AS generic_catalog_anon_denied,
 NOT has_function_privilege('authenticated',
   'public.iclub_subject_library_catalog_service_v1(text,text)','EXECUTE')
   AS generic_catalog_authenticated_denied,
 NOT has_table_privilege('authenticated','private.iclub_subject_library_theory','SELECT')
   AS chemistry_theory_table_private,
 NOT has_table_privilege('authenticated','private.iclub_subject_library_tutor','SELECT')
   AS chemistry_tutor_table_private,
 NOT has_table_privilege('authenticated','private.iclub_subject_library_cross_tour_v1','SELECT')
   AS chemistry_labs_table_private,
 NOT has_function_privilege('anon',
   'public.iclub_exam_chemistry_entry_lesson_v1(uuid,text,text)','EXECUTE')
   AS entry_lesson_anon_denied,
 has_function_privilege('authenticated',
   'public.iclub_exam_chemistry_entry_lesson_v1(uuid,text,text)','EXECUTE')
   AS entry_lesson_authenticated_entry_only,
 (SELECT pg_get_functiondef('public.iclub_exam_chemistry_entry_lesson_v1(uuid,text,text)'::regprocedure)
   LIKE '%AND user_id=v_user%' AND pg_get_functiondef('public.iclub_exam_chemistry_entry_lesson_v1(uuid,text,text)'::regprocedure)
   LIKE '%v.status<>''finalized''%' AND pg_get_functiondef('public.iclub_exam_chemistry_entry_lesson_v1(uuid,text,text)'::regprocedure)
   LIKE '%lib.visible_to_learners=true%')
   AS entry_lesson_owned_finalized_visible_only,
 (SELECT pg_get_functiondef('public.iclub_exam_chemistry_entry_lesson_v1(uuid,text,text)'::regprocedure)
   LIKE '%''ai_tutor_content_included'',false%' AND pg_get_functiondef('public.iclub_exam_chemistry_entry_lesson_v1(uuid,text,text)'::regprocedure)
   NOT LIKE '%JOIN private.iclub_subject_library_tutor%')
   AS entry_lesson_excludes_tutor,
 (SELECT NOT armed AND NOT can_publish AND currently_hidden
   FROM private.iclub_exam_chemistry_j12_release_gate_v1)
   AS package_remains_unarmed_and_hidden;