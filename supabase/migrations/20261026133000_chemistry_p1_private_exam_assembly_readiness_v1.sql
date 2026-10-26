-- iClub Chemistry 9701 Stage I-09 metadata-only P1 readiness.
-- Applied in Supabase migration 20261026; source retained after successful guarded deployment.
-- Public Git may contain this SECURITY-INVOKER VIEW DEFINITION only: no question bodies or keys.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_core_chemistry_p1_assembly_readiness_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'Chemistry readiness view already present; refuse replacement'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1'
 AND status='draft' AND launch_enabled=false)
 THEN RAISE EXCEPTION 'Chemistry must be draft OFF'; END IF;
END $pre$;

CREATE VIEW private.iclub_exam_core_chemistry_p1_assembly_readiness_v1
WITH (security_invoker=true,security_barrier=true) AS
 WITH draft_q AS (
         SELECT d.program_key,
            d.version_key,
            d.draft_key,
            d.authoring_version,
            d.syllabus_unit,
            p.source_hash_valid AND p.source_id_and_draft_valid AND p.single_choice_key_format_valid AND p.paper_format_valid AND p.all_three_locale_keys AND p.locales_content_structurally_complete AND p.no_duplicate_options_in_locale AND p.no_duplicate_new_english_stem AND p.no_exact_legacy_english_stem AND p.direct_p1_skill_exists AND p.seven_review_slots_exist AND p.all_review_snapshots_current AS machine_valid,
            p.documented_review_passes AS reviewed_passes,
            p.documented_review_failures AS reviewed_fails,
            d.release_enabled,
            d.exam_candidate_eligible,
            d.credit_mastery
           FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1 d
             JOIN private.iclub_exam_core_chemistry_p1_item_preflight_v1 p USING (program_key, version_key, draft_key, authoring_version)
          WHERE d.program_key = 'chemistry_9701'::text AND d.version_key = 'chemistry_2025_2027_v1'::text
        ), summary AS (
         SELECT count(*) AS private_drafts,
            count(*) FILTER (WHERE draft_q.machine_valid) AS structurally_valid,
            count(*) FILTER (WHERE draft_q.machine_valid AND draft_q.reviewed_fails = 0) AS unflagged_private,
            count(*) FILTER (WHERE draft_q.reviewed_fails > 0) AS flagged_private,
            count(*) FILTER (WHERE draft_q.machine_valid AND draft_q.reviewed_fails = 0 AND draft_q.reviewed_passes = 7) AS fully_reviewed_private,
            count(*) FILTER (WHERE draft_q.machine_valid AND draft_q.reviewed_fails = 0 AND draft_q.reviewed_passes = 7 AND draft_q.release_enabled AND draft_q.exam_candidate_eligible AND NOT draft_q.credit_mastery) AS secure_ready_items,
            count(DISTINCT draft_q.syllabus_unit) FILTER (WHERE draft_q.machine_valid AND draft_q.reviewed_fails = 0) AS topic_units_private
           FROM draft_q
        ), legacy AS (
         SELECT count(*) AS legacy_candidates,
            count(*) FILTER (WHERE iclub_exam_core_question_candidates_v1.qa_scope_status = 'fail'::text OR iclub_exam_core_question_candidates_v1.qa_academic_status = 'fail'::text OR iclub_exam_core_question_candidates_v1.qa_language_status = 'fail'::text OR iclub_exam_core_question_candidates_v1.qa_format_status = 'fail'::text) AS legacy_qa_holds,
            count(*) FILTER (WHERE iclub_exam_core_question_candidates_v1.status = 'approved'::text AND iclub_exam_core_question_candidates_v1.qa_scope_status = 'pass'::text AND iclub_exam_core_question_candidates_v1.qa_academic_status = 'pass'::text AND iclub_exam_core_question_candidates_v1.qa_language_status = 'pass'::text AND iclub_exam_core_question_candidates_v1.qa_format_status = 'pass'::text) AS approved_for_formative_only
           FROM private.iclub_exam_core_question_candidates_v1
          WHERE iclub_exam_core_question_candidates_v1.program_key = 'chemistry_9701'::text AND iclub_exam_core_question_candidates_v1.version_key = 'chemistry_2025_2027_v1'::text AND iclub_exam_core_question_candidates_v1.paper_code = 'P1'::text
        ), review AS (
         SELECT count(*) AS qa_slots,
            count(*) FILTER (WHERE iclub_exam_core_chemistry_p1_qa_slots_v1.gate_status = 'pending'::text) AS qa_pending,
            count(*) FILTER (WHERE iclub_exam_core_chemistry_p1_qa_slots_v1.gate_status = 'fail'::text) AS qa_fail,
            count(*) FILTER (WHERE iclub_exam_core_chemistry_p1_qa_slots_v1.gate_status = 'pass'::text) AS qa_pass
           FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1
          WHERE iclub_exam_core_chemistry_p1_qa_slots_v1.program_key = 'chemistry_9701'::text AND iclub_exam_core_chemistry_p1_qa_slots_v1.version_key = 'chemistry_2025_2027_v1'::text
        ), program AS (
         SELECT iclub_exam_core_programs_v1.program_key,
            iclub_exam_core_programs_v1.version_key,
            iclub_exam_core_programs_v1.status,
            iclub_exam_core_programs_v1.launch_enabled
           FROM private.iclub_exam_core_programs_v1
          WHERE iclub_exam_core_programs_v1.program_key = 'chemistry_9701'::text AND iclub_exam_core_programs_v1.version_key = 'chemistry_2025_2027_v1'::text
        )
 SELECT program.program_key,
    program.version_key,
    'P1'::text AS paper_code,
    40 AS paper_question_target,
    s.private_drafts,
    s.structurally_valid,
    s.unflagged_private,
    s.flagged_private,
    s.fully_reviewed_private,
    s.secure_ready_items,
    GREATEST(40 - s.secure_ready_items, 0::bigint)::integer AS reviewed_secure_shortfall,
    GREATEST(40 - s.unflagged_private, 0::bigint)::integer AS theoretical_private_shortfall_before_qa,
    s.topic_units_private,
    l.legacy_candidates,
    l.legacy_qa_holds,
    l.approved_for_formative_only,
    q.qa_slots,
    q.qa_pending,
    q.qa_fail,
    q.qa_pass,
    ( SELECT count(*) AS count
           FROM private.iclub_exam_core_chemistry_p1_quarantine_v1
          WHERE iclub_exam_core_chemistry_p1_quarantine_v1.program_key = program.program_key AND iclub_exam_core_chemistry_p1_quarantine_v1.version_key = program.version_key) AS prior_26_preserved,
    private.iclub_exam_core_native_plan_preflight_v1(program.program_key, program.version_key) ->> 'state'::text AS native_preflight_state,
    false AS can_issue_mock,
    false AS can_mark_mastery,
        CASE
            WHEN s.secure_ready_items < 40 THEN 'blocked_no_40_reviewed_secure_questions'::text
            ELSE 'blocked_not_wired_to_student_runtime'::text
        END AS readiness_status,
    '40 questions is Paper 1 length; minimum topic reserve is an internal iClub target, not an official Cambridge distribution'::text AS selection_policy_note
   FROM summary s
     CROSS JOIN legacy l
     CROSS JOIN review q
     CROSS JOIN program;

REVOKE ALL ON private.iclub_exam_core_chemistry_p1_assembly_readiness_v1
 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_core_chemistry_p1_assembly_readiness_v1 TO service_role;
COMMENT ON VIEW private.iclub_exam_core_chemistry_p1_assembly_readiness_v1 IS
'Service-only Chemistry P1 assembly readiness. No student access, question text or answer key disclosure. Formative legacy source not treated as a secure unseen exam question.';
DO $post$ DECLARE r record;
BEGIN
 SELECT * INTO r FROM private.iclub_exam_core_chemistry_p1_assembly_readiness_v1;
 IF r.paper_question_target<>40 OR r.private_drafts<>38
 OR r.structurally_valid<>38 OR r.unflagged_private<>37 OR r.flagged_private<>1
 OR r.secure_ready_items<>0 OR r.theoretical_private_shortfall_before_qa<>3
 OR r.reviewed_secure_shortfall<>40 OR r.legacy_candidates<>30
 OR r.qa_slots<>266 OR r.qa_pending<>265 OR r.qa_fail<>1 OR r.qa_pass<>0
 OR r.prior_26_preserved<>26 OR r.native_preflight_state<>'blocked'
 OR r.can_issue_mock OR r.can_mark_mastery
 THEN RAISE EXCEPTION 'Private readiness invariant mismatch'; END IF;
 IF has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_assembly_readiness_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_assembly_readiness_v1','SELECT')
 OR NOT has_table_privilege('service_role','private.iclub_exam_core_chemistry_p1_assembly_readiness_v1','SELECT')
 THEN RAISE EXCEPTION 'Unsafe view reader grants'; END IF;
END $post$;
