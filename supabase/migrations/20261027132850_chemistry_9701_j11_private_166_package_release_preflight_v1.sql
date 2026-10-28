-- J11 private metadata-only release preflight: 154 Theory + 12 laboratory cross-tour nodes.
-- Does not publish content, approve any learner or alter historical data.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_chemistry_j11_release_readiness_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'J11 readiness already installed'; END IF;
 IF (SELECT visible_to_learners FROM private.iclub_subject_library WHERE subject_key='chemistry') IS DISTINCT FROM false
 OR (SELECT launch_enabled FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701') IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'J11 requires Chemistry hidden and OFF'; END IF;
END $pre$;
CREATE VIEW private.iclub_exam_chemistry_j11_release_readiness_v1
WITH (security_invoker=true) AS
WITH counted AS(
 SELECT rel.version_key,rel.expected_skills,rel.state AS release_state,rel.validated_at,
 (SELECT count(*)::int FROM private.iclub_subject_library_theory t
 WHERE t.subject_key='chemistry' AND t.version_key=rel.version_key) AS theory_skills,
 (SELECT count(*)::int FROM private.iclub_subject_library_cross_tour_v1 c
 WHERE c.subject_key='chemistry' AND c.version_key=rel.version_key) AS lab_skills,
 (SELECT count(*)::int FROM private.iclub_exam_core_skills_v1 s
 WHERE s.program_key='chemistry_9701' AND s.library_version_key=rel.version_key AND s.level_code='AS') AS AS_skills,
 (SELECT count(*)::int FROM private.iclub_subject_library_cross_tour_v1 c
 WHERE c.subject_key='chemistry' AND c.version_key=rel.version_key AND c.paper_code='P3') AS P3_labs,
 (SELECT count(*)::int FROM private.iclub_subject_library_cross_tour_v1 c
 WHERE c.subject_key='chemistry' AND c.version_key=rel.version_key AND c.paper_code='P5') AS P5_labs,
 NOT EXISTS(SELECT 1 FROM private.iclub_subject_library_theory t
 LEFT JOIN private.iclub_exam_core_skills_v1 s
 ON s.library_subject_key=t.subject_key AND s.library_version_key=t.version_key
 AND s.skill_key=t.skill_key AND s.program_key='chemistry_9701'
 WHERE t.subject_key='chemistry' AND t.version_key=rel.version_key
 AND (s.skill_key IS NULL OR t.syllabus_point IS DISTINCT FROM s.syllabus_point
 OR t.tour_no IS DISTINCT FROM s.tour_no
 OR NOT(t.locales ?& ARRAY['en','ru','uz'])
 OR (SELECT count(*) FROM private.iclub_subject_library_tutor tu
 WHERE tu.subject_key=t.subject_key AND tu.version_key=t.version_key
 AND tu.skill_key=t.skill_key AND tu.locale IN('en','ru','uz')
 AND tu.source_card_hash=t.content_hash
 AND length(coalesce(tu.main_explanation,''))>=50)<>3)) AS theory_trilingual_hash_ready,
 NOT EXISTS(SELECT 1 FROM private.iclub_subject_library_cross_tour_v1 c
 WHERE c.subject_key='chemistry' AND c.version_key=rel.version_key
 AND (NOT(c.locales ?& ARRAY['en','ru','uz'])
 OR NOT(c.tutor_by_locale ?& ARRAY['en','ru','uz'])
 OR c.state<>'draft'
 OR c.paper_code NOT IN('P3','P5')
 OR c.level_code NOT IN('AS','A')
 OR EXISTS(SELECT 1 FROM private.iclub_subject_library_theory t
 WHERE t.subject_key=c.subject_key AND t.version_key=c.version_key AND t.skill_key=c.skill_key)))
 AS lab_catalog_ready
 FROM private.iclub_subject_library_releases rel
 WHERE rel.subject_key='chemistry'
)
SELECT counted.version_key,counted.expected_skills,counted.theory_skills,
 counted.lab_skills,counted.AS_skills,counted.P3_labs,counted.P5_labs,
 counted.theory_trilingual_hash_ready,counted.lab_catalog_ready,
 (counted.theory_skills+counted.lab_skills=counted.expected_skills
 AND counted.theory_trilingual_hash_ready AND counted.lab_catalog_ready
 AND counted.P3_labs=6 AND counted.P5_labs=6) AS full_package_source_integrity,
 (counted.theory_skills=counted.expected_skills) AS generic_publisher_compatible,
 (counted.validated_at IS NOT NULL AND counted.release_state='validated') AS release_validated,
 (SELECT visible_to_learners=false AND active_version IS NULL
 FROM private.iclub_subject_library WHERE subject_key='chemistry') AS library_hidden,
 (SELECT status='draft' AND launch_enabled=false
 FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701') AS core_off,
 (SELECT enabled=false FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1) AS entry_off,
 (SELECT enabled=false FROM private.iclub_exam_chemistry_recheck_control_v1 WHERE id=1) AS recheck_off,
 (SELECT enabled=false FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) AS p1_off,
 false AS owner_approved_to_publish,false AS student_beta_enabled,
 'blocked_until_composite_166_publisher_and_owner_approval'::text AS decision
FROM counted;
REVOKE ALL ON private.iclub_exam_chemistry_j11_release_readiness_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_chemistry_j11_release_readiness_v1 TO service_role;
DO $post$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM private.iclub_exam_chemistry_j11_release_readiness_v1
 WHERE expected_skills=166 AND theory_skills=154 AND lab_skills=12
 AND AS_skills=91 AND P3_labs=6 AND P5_labs=6
 AND theory_trilingual_hash_ready AND lab_catalog_ready
 AND full_package_source_integrity AND NOT generic_publisher_compatible
 AND NOT release_validated AND library_hidden AND core_off
 AND entry_off AND recheck_off AND p1_off
 AND NOT owner_approved_to_publish AND NOT student_beta_enabled)
 OR has_table_privilege('authenticated',
 'private.iclub_exam_chemistry_j11_release_readiness_v1','SELECT')
 THEN RAISE EXCEPTION 'Expected private 154+12 blocked release preflight not met'; END IF;
END $post$;