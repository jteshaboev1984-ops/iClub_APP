-- J12: private composite 166-source release custody; only metadata, no learner release.
-- Owner GO, rights, tutor isolation, LAB delivery, backups, real-browser QA are distinct.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_chemistry_j12_release_control_v1') IS NOT NULL
 OR to_regclass('private.iclub_exam_chemistry_j12_release_gate_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'J12 control already present'; END IF;
 IF (SELECT status='draft' AND launch_enabled=false FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701') IS DISTINCT FROM true
 OR (SELECT visible_to_learners=false AND active_version IS NULL FROM private.iclub_subject_library WHERE subject_key='chemistry') IS DISTINCT FROM true
 THEN RAISE EXCEPTION 'J12 must be installed with Chemistry completely hidden'; END IF;
END $pre$;

CREATE TABLE private.iclub_exam_chemistry_j12_release_control_v1(
 id smallint PRIMARY KEY CHECK(id=1),
 armed boolean NOT NULL DEFAULT false,
 owner_go_at timestamptz,
 approved_version text,
 approved_package_sha256 text CHECK(approved_package_sha256 IS NULL OR approved_package_sha256~'^[a-f0-9]{64}$'),
 approved_source_md5 text CHECK(approved_source_md5 IS NULL OR approved_source_md5~'^[a-f0-9]{32}$'),
 rights_review_at timestamptz,
 backup_restore_verified_at timestamptz,
 lab_delivery_verified_at timestamptz,
 tutor_access_isolated_at timestamptz,
 authenticated_device_qa_at timestamptz,
 consumed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK(NOT armed OR (
   owner_go_at IS NOT NULL AND approved_version IS NOT NULL
   AND approved_package_sha256 IS NOT NULL AND approved_source_md5 IS NOT NULL
   AND rights_review_at IS NOT NULL AND backup_restore_verified_at IS NOT NULL
   AND lab_delivery_verified_at IS NOT NULL AND tutor_access_isolated_at IS NOT NULL
   AND authenticated_device_qa_at IS NOT NULL AND consumed_at IS NULL))
);
INSERT INTO private.iclub_exam_chemistry_j12_release_control_v1(id,armed)
VALUES (1,false);
ALTER TABLE private.iclub_exam_chemistry_j12_release_control_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j12_release_control_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j12_release_control_v1
 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_chemistry_j12_release_control_v1 TO service_role;

CREATE VIEW private.iclub_exam_chemistry_j12_release_gate_v1
WITH (security_invoker=true)
AS WITH sources AS (
 SELECT 'T:'||t.skill_key AS stable_key,
 md5(t.content_hash||'|'||t.locales::text||'|'||
 coalesce((SELECT jsonb_agg(jsonb_build_object(
 'locale',u.locale,'title',u.title,'main',u.main_explanation,
 'simple',u.simple_explanation,'alternative',u.alternative_explanation,
 'focus',u.focus_explanation,'hash',u.source_card_hash)
 ORDER BY u.locale)::text FROM private.iclub_subject_library_tutor u
 WHERE u.subject_key=t.subject_key AND u.version_key=t.version_key
 AND u.skill_key=t.skill_key),'missing')) AS stable_md5
 FROM private.iclub_subject_library_theory t
 WHERE t.subject_key='chemistry'
 AND t.version_key='chemistry9701_20261022_stageb_draft'
 UNION ALL
 SELECT 'L:'||l.skill_key,
 md5(l.content_hash||'|'||l.locales::text||'|'||
 l.tutor_by_locale::text||'|'||l.paper_code||'|'||l.level_code)
 FROM private.iclub_subject_library_cross_tour_v1 l
 WHERE l.subject_key='chemistry'
 AND l.version_key='chemistry9701_20261022_stageb_draft'
), fingerprints AS (
 SELECT count(*)::integer AS sources_total,
 md5(string_agg(stable_key||'|'||stable_md5,';' ORDER BY stable_key)) AS source_snapshot_md5
 FROM sources
)
SELECT p.version_key,p.expected_skills,
 j.theory_skills,j.lab_skills,j.full_package_source_integrity,
 j.generic_publisher_compatible,
 f.sources_total,f.source_snapshot_md5,
 c.armed,c.owner_go_at IS NOT NULL AS owner_explicit_GO,
 c.rights_review_at IS NOT NULL AS rights_reviewed,
 c.backup_restore_verified_at IS NOT NULL AS backup_restore_tested,
 c.lab_delivery_verified_at IS NOT NULL AS lab_delivery_tested,
 c.tutor_access_isolated_at IS NOT NULL AS tutor_access_isolated,
 c.authenticated_device_qa_at IS NOT NULL AS actual_device_QA_done,
 c.approved_version=p.version_key AND c.approved_package_sha256=p.package_sha256
 AND c.approved_source_md5=f.source_snapshot_md5 AS content_exactly_approved,
 c.consumed_at IS NULL AS not_previously_consumed,
 (SELECT visible_to_learners=false AND active_version IS NULL
 FROM private.iclub_subject_library WHERE subject_key='chemistry') AS currently_hidden,
 (SELECT status='draft' AND launch_enabled=false
 FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701') AS core_disabled,
 (SELECT enabled=false FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1) AS entry_disabled,
 (SELECT enabled=false FROM private.iclub_exam_chemistry_recheck_control_v1 WHERE id=1) AS recheck_disabled,
 (SELECT enabled=false FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) AS p1_disabled,
 (p.state='draft' AND p.validated_at IS NULL) AS release_not_yet_validated,
 (
 j.full_package_source_integrity
 AND NOT j.generic_publisher_compatible AND f.sources_total=166
 AND c.armed AND c.owner_go_at IS NOT NULL AND c.rights_review_at IS NOT NULL
 AND c.backup_restore_verified_at IS NOT NULL
 AND c.lab_delivery_verified_at IS NOT NULL
 AND c.tutor_access_isolated_at IS NOT NULL
 AND c.authenticated_device_qa_at IS NOT NULL
 AND c.approved_version=p.version_key
 AND c.approved_package_sha256=p.package_sha256
 AND c.approved_source_md5=f.source_snapshot_md5
 AND c.consumed_at IS NULL
 AND (SELECT visible_to_learners=false AND active_version IS NULL
 FROM private.iclub_subject_library WHERE subject_key='chemistry')
 AND (SELECT status='draft' AND launch_enabled=false
 FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701')
 AND (SELECT enabled=false FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1)
 AND (SELECT enabled=false FROM private.iclub_exam_chemistry_recheck_control_v1 WHERE id=1)
 AND (SELECT enabled=false FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1)
 AND p.state='draft' AND p.validated_at IS NULL
 ) AS can_publish
FROM private.iclub_subject_library_releases p
JOIN private.iclub_exam_chemistry_j11_release_readiness_v1 j
 ON j.version_key=p.version_key
CROSS JOIN fingerprints f
CROSS JOIN private.iclub_exam_chemistry_j12_release_control_v1 c
WHERE p.subject_key='chemistry'
AND p.version_key='chemistry9701_20261022_stageb_draft'
AND c.id=1;
REVOKE ALL ON private.iclub_exam_chemistry_j12_release_gate_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_chemistry_j12_release_gate_v1 TO service_role;

DO $post$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j12_release_gate_v1 g
 WHERE g.expected_skills=166 AND g.theory_skills=154 AND g.lab_skills=12
 AND g.sources_total=166 AND g.source_snapshot_md5~'^[a-f0-9]{32}$'
 AND g.full_package_source_integrity AND NOT g.generic_publisher_compatible
 AND NOT g.armed AND NOT g.owner_explicit_GO AND NOT g.rights_reviewed
 AND NOT g.backup_restore_tested AND NOT g.lab_delivery_tested
 AND NOT g.tutor_access_isolated AND NOT g.actual_device_QA_done
 AND NOT g.can_publish AND g.currently_hidden AND g.core_disabled)
 OR has_table_privilege('authenticated',
 'private.iclub_exam_chemistry_j12_release_gate_v1','SELECT')
 THEN RAISE EXCEPTION 'J12 guarded snapshot not closed or source invalid'; END IF;
END $post$;