-- Already applied to Supabase as 20261026174531. Git source mirrors live metadata-only view.
-- NO confidential question text, options or keys embedded.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'Blueprint already exists: never overwrite'; END IF;
 IF NOT EXISTS (SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1'
 AND status='draft' AND launch_enabled=false) THEN
 RAISE EXCEPTION 'Chemistry not draft/OFF'; END IF;
END $pre$;
CREATE VIEW private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
WITH (security_invoker=true,security_barrier=true) AS
 WITH flags AS (
         SELECT src.program_key,
            src.version_key,
            src.draft_key,
            src.authoring_version,
            src.syllabus_unit,
            src.skill_key,
            src.item_md5,
            count(*) FILTER (WHERE qa.gate_status = 'pass'::text) AS passed,
            count(*) FILTER (WHERE qa.gate_status = 'fail'::text) AS failed,
            count(*) FILTER (WHERE qa.gate_status = 'pending'::text) AS pending,
            count(*) FILTER (WHERE qa.source_snapshot_md5 <> src.item_md5) AS stale
           FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1 src
             JOIN private.iclub_exam_core_chemistry_p1_qa_slots_v1 qa USING (program_key, version_key, draft_key, authoring_version)
          WHERE src.program_key = 'chemistry_9701'::text AND src.version_key = 'chemistry_2025_2027_v1'::text AND src.release_enabled = false AND src.exam_candidate_eligible = false AND src.credit_mastery = false
          GROUP BY src.program_key, src.version_key, src.draft_key, src.authoring_version, src.syllabus_unit, src.skill_key, src.item_md5
        ), reviewed AS (
         SELECT flags.program_key,
            flags.version_key,
            flags.draft_key,
            flags.authoring_version,
            flags.syllabus_unit,
            flags.skill_key,
            flags.item_md5,
            flags.passed,
            flags.failed,
            flags.pending,
            flags.stale,
            row_number() OVER (PARTITION BY flags.syllabus_unit ORDER BY (md5(flags.draft_key || flags.item_md5)), flags.draft_key) AS unit_variant
           FROM flags
          WHERE flags.passed = 7 AND flags.failed = 0 AND flags.pending = 0 AND flags.stale = 0
        ), backup_sort AS (
         SELECT reviewed.program_key,
            reviewed.version_key,
            reviewed.draft_key,
            reviewed.authoring_version,
            reviewed.syllabus_unit,
            reviewed.skill_key,
            reviewed.item_md5,
            reviewed.passed,
            reviewed.failed,
            reviewed.pending,
            reviewed.stale,
            reviewed.unit_variant,
                CASE
                    WHEN reviewed.unit_variant = 2 THEN row_number() OVER (PARTITION BY reviewed.unit_variant ORDER BY (md5(reviewed.draft_key || 'mock-seed-i11'::text)), reviewed.draft_key)
                    ELSE NULL::bigint
                END AS extra_order
           FROM reviewed
        ), selected AS (
         SELECT backup_sort.program_key,
            backup_sort.version_key,
            backup_sort.draft_key,
            backup_sort.authoring_version,
            backup_sort.syllabus_unit,
            backup_sort.skill_key,
            backup_sort.item_md5,
            backup_sort.passed,
            backup_sort.failed,
            backup_sort.pending,
            backup_sort.stale,
            backup_sort.unit_variant,
            backup_sort.extra_order,
                CASE
                    WHEN backup_sort.unit_variant = 1 OR backup_sort.unit_variant = 2 AND backup_sort.extra_order <= 18 THEN 'proposed_form'::text
                    ELSE 'proposed_reserve'::text
                END AS planning_role
           FROM backup_sort
        )
 SELECT program_key,
    version_key,
    'P1'::text AS paper_code,
    draft_key,
    authoring_version,
    syllabus_unit,
    skill_key,
    item_md5 AS source_snapshot_md5,
    planning_role,
        CASE
            WHEN planning_role = 'proposed_form'::text THEN row_number() OVER (PARTITION BY planning_role ORDER BY syllabus_unit, unit_variant, draft_key)
            ELSE NULL::bigint
        END AS proposed_question_no,
    7 AS internal_ai_review_gates,
    false AS issued_to_learner,
    false AS scored_exam,
    false AS credit_mastery,
    'private editor-only trial arrangement, not official Cambridge topic weighting and not an exam release'::text AS preview_policy
   FROM selected;
REVOKE ALL ON private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1 TO service_role;
COMMENT ON VIEW private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1 IS
 'Private editor preview 40 original internally AI-reviewed choices plus 4 reserves, 22 AS topics. Never a learner assessment, grade or mastery authority.';
DO $post$ DECLARE n integer; core integer; backup integer; cover integer;
BEGIN
 SELECT count(*),count(*) FILTER(WHERE planning_role='proposed_form'),
 count(*) FILTER(WHERE planning_role='proposed_reserve'),
 count(DISTINCT syllabus_unit) FILTER(WHERE planning_role='proposed_form')
 INTO n,core,backup,cover
 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1;
 IF n<>44 OR core<>40 OR backup<>4 OR cover<>22 THEN
 RAISE EXCEPTION 'Unexpected editor preview distribution'; END IF;
 IF has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1','SELECT')
 THEN RAISE EXCEPTION 'Private editor preview is not private'; END IF;
END $post$;
