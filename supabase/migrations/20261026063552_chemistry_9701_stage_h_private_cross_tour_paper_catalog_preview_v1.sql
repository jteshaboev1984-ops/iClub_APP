-- Exact private view definition restored from the live database after safe-branch rewind.
-- This migration is already registered/applied in production: archival source for new environments.
-- NO question bodies or answer keys are embedded here.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_core_chemistry_paper_catalog_preview_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'Refuse to overwrite pre-existing Chemistry preview'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND status='draft' AND launch_enabled=false)
 THEN RAISE EXCEPTION 'Chemistry draft/OFF requirement failed'; END IF;
END $pre$;
CREATE VIEW private.iclub_exam_core_chemistry_paper_catalog_preview_v1
WITH (security_invoker=true,security_barrier=true) AS
 SELECT p.program_key,
    p.version_key,
    ps.paper_code,
    s.skill_key,
    s.level_code,
    s.syllabus_point,
    s.syllabus_unit,
    s.tour_no,
    ps.link_role,
    'regular_theory'::text AS source_kind,
    s.status AS content_status,
    ps.status AS link_status,
    s.content_hash,
    t.locales AS theory_by_locale,
    tutor.tutor_by_locale,
    false AS can_issue_learner_task,
    false AS can_credit_mastery
   FROM private.iclub_exam_core_programs_v1 p
     JOIN private.iclub_exam_core_paper_skills_v1 ps ON ps.program_key = p.program_key AND ps.version_key = p.version_key
     JOIN private.iclub_exam_core_skills_v1 s ON s.program_key = ps.program_key AND s.version_key = ps.version_key AND s.skill_key = ps.skill_key
     JOIN private.iclub_subject_library_theory t ON t.subject_key = s.library_subject_key AND t.version_key = s.library_version_key AND t.skill_key = s.skill_key AND t.content_hash = s.content_hash
     LEFT JOIN LATERAL ( SELECT jsonb_object_agg(tc.locale, jsonb_build_object('title', tc.title, 'tutor_card_key', tc.tutor_card_key, 'content_version', tc.content_version, 'main_explanation', tc.main_explanation, 'simple_explanation', tc.simple_explanation, 'alternative_explanation', tc.alternative_explanation, 'focus_explanation', tc.focus_explanation)) AS tutor_by_locale
           FROM private.iclub_subject_library_tutor tc
          WHERE tc.subject_key = s.library_subject_key AND tc.version_key = s.library_version_key AND tc.skill_key = s.skill_key AND tc.source_card_hash = s.content_hash) tutor ON true
  WHERE p.program_key = 'chemistry_9701'::text AND p.version_key = 'chemistry_2025_2027_v1'::text AND p.status = 'draft'::text AND p.launch_enabled = false
UNION ALL
 SELECT p.program_key,
    p.version_key,
    ct.paper_code,
    ct.skill_key,
    ct.level_code,
    ct.syllabus_point,
    NULL::smallint AS syllabus_unit,
    NULL::smallint AS tour_no,
    'direct'::text AS link_role,
    'cross_tour_practical'::text AS source_kind,
    ct.state AS content_status,
    ct.state AS link_status,
    ct.content_hash,
    ct.locales AS theory_by_locale,
    ct.tutor_by_locale,
    false AS can_issue_learner_task,
    false AS can_credit_mastery
   FROM private.iclub_exam_core_programs_v1 p
     JOIN private.iclub_subject_library_cross_tour_v1 ct ON ct.subject_key = p.library_subject_key AND ct.version_key = p.library_version_key
     JOIN private.iclub_exam_core_papers_v1 paper ON paper.program_key = p.program_key AND paper.version_key = p.version_key AND paper.paper_code = ct.paper_code AND paper.level_code = ct.level_code
  WHERE p.program_key = 'chemistry_9701'::text AND p.version_key = 'chemistry_2025_2027_v1'::text AND p.status = 'draft'::text AND p.launch_enabled = false AND ct.source_tour = 'CROSS_TOUR'::text AND (ct.paper_code = ANY (ARRAY['P3'::text, 'P5'::text]));
REVOKE ALL ON private.iclub_exam_core_chemistry_paper_catalog_preview_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_core_chemistry_paper_catalog_preview_v1 TO service_role;
COMMENT ON VIEW private.iclub_exam_core_chemistry_paper_catalog_preview_v1 IS
'Chemistry academic preview only; never a learner task/grade/mastery authority.';
DO $post$ BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_core_chemistry_paper_catalog_preview_v1)<>348
 THEN RAISE EXCEPTION 'Unexpected Chemistry preview view counts'; END IF;
 IF has_table_privilege('anon','private.iclub_exam_core_chemistry_paper_catalog_preview_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_chemistry_paper_catalog_preview_v1','SELECT')
 THEN RAISE EXCEPTION 'Private preview has unsafe reader privileges'; END IF;
END $post$;
