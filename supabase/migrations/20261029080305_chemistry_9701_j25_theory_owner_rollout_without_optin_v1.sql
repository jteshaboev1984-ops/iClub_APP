-- J25: OWNER-SELECTED ROLLOUT WITHOUT CHEMISTRY INVITATIONS OR OPT-IN.
-- Unapplied J25 consent draft was abandoned by owner; NO user-facing consent.
-- Controls access only; no changes to account membership, progress or assessments.
-- Requires J24 academic review, exact signed source manifest and exam blackout.
BEGIN;

CREATE TABLE private.iclub_exam_chemistry_j25_theory_rollout_control_v1 (
 id smallint PRIMARY KEY DEFAULT 1 CHECK(id=1),
 audience_mode text NOT NULL DEFAULT 'closed'
   CHECK(audience_mode IN ('closed','beta','released')),
 owner_opened_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CONSTRAINT j25_open_requires_owner_gate CHECK(
   audience_mode='closed' OR owner_opened_at IS NOT NULL)
);
ALTER TABLE private.iclub_exam_chemistry_j25_theory_rollout_control_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j25_theory_rollout_control_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j25_theory_rollout_control_v1
 FROM PUBLIC,anon,authenticated;
INSERT INTO private.iclub_exam_chemistry_j25_theory_rollout_control_v1(id,audience_mode)
VALUES(1,'closed');

-- Preserves the existing J24 academic and security proof exactly. In beta,
-- only already-activated Mathematics Beta account + active Chemistry subject.
-- Released: active Chemistry subject account; not tied to beta membership.
-- No learner invite, acknowledgement, consent RPC or additional seat record.
CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_j24_theory_authorized_v1()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $$
 SELECT auth.role()='authenticated' AND auth.uid() IS NOT NULL
 AND coalesce(auth.jwt()->>'is_anonymous','false')<>'true'
 AND NOT private.iclub_ai_has_active_protected_assessment_v1(auth.uid())
 AND EXISTS(SELECT 1 FROM public.user_subjects us JOIN public.subjects s ON s.id=us.subject_id
  WHERE us.user_id=auth.uid() AND s.subject_key='chemistry' AND s.is_active=true)
 AND EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j25_theory_rollout_control_v1 rollout
  WHERE rollout.id=1 AND rollout.owner_opened_at IS NOT NULL
   AND (rollout.audience_mode='released'
      OR (rollout.audience_mode='beta' AND EXISTS(
       SELECT 1 FROM private.exam_prep_beta_cohorts c
       JOIN private.exam_prep_beta_members m ON m.cohort_id=c.id
       WHERE c.cohort_key='math_as_p1_p5_beta_2026_09_01'
         AND c.program_key='math_as_p1_p5'
         AND c.cohort_status IN ('canary','active')
         AND m.user_id=auth.uid() AND m.member_status='active'
         AND m.activated_at IS NOT NULL
      ))))
 AND EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j24_as_theory_control_v1 c
  CROSS JOIN private.iclub_exam_chemistry_j12_release_gate_v1 g
  WHERE c.id=1 AND c.enabled=true AND c.owner_go_at IS NOT NULL
   AND c.academic_science_review_at IS NOT NULL AND c.trilingual_review_at IS NOT NULL
   AND c.rights_owner_attestation_at IS NOT NULL AND c.owner_backup_deferral_at IS NOT NULL
   AND c.approved_version='chemistry9701_20261022_stageb_draft'
   AND c.approved_source_md5=g.source_snapshot_md5
   AND c.approved_skill_count=91 AND length(btrim(c.reviewed_evidence_ref))>=16
   AND EXISTS (SELECT 1 FROM private.iclub_exam_core_skills_v1 s
    JOIN private.iclub_subject_library_theory t
     ON t.subject_key=s.library_subject_key AND t.version_key=s.library_version_key
      AND t.skill_key=s.skill_key
    WHERE s.program_key='chemistry_9701' AND s.version_key='chemistry_2025_2027_v1'
      AND s.library_version_key=c.approved_version AND s.level_code='AS'
      AND t.tour_no BETWEEN 1 AND 5 AND t.content_hash=s.content_hash
    HAVING count(*)=91 AND md5(string_agg(s.skill_key||':'||t.content_hash,'|' ORDER BY s.skill_key))=c.approved_as_manifest_md5)
 );
$$;

REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_j24_theory_authorized_v1()
 FROM PUBLIC,anon,authenticated;

COMMIT;
-- Default: closed. J24.enabled=false remains independent and mandatory.
