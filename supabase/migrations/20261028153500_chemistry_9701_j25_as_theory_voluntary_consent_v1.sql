-- J25 / Chemistry AS Theory only. Additive consent and owner-controlled canary.
-- Deliberately NO student inserts, invitations, approvals, activation or content release.
-- Production Mathematics, Economics, Practice, Tours and history remain untouched.
BEGIN;

CREATE TABLE private.iclub_exam_chemistry_j25_as_theory_control_v1 (
 id smallint PRIMARY KEY DEFAULT 1 CHECK (id=1),
 release_phase text NOT NULL DEFAULT 'closed'
  CHECK (release_phase IN ('closed','canary','expanded')),
 owner_go_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK (release_phase='closed' OR owner_go_at IS NOT NULL)
);
ALTER TABLE private.iclub_exam_chemistry_j25_as_theory_control_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j25_as_theory_control_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j25_as_theory_control_v1 FROM PUBLIC,anon,authenticated;
INSERT INTO private.iclub_exam_chemistry_j25_as_theory_control_v1(id,release_phase)
VALUES (1,'closed');

CREATE TABLE private.iclub_exam_chemistry_j25_as_theory_optins_v1 (
 user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE RESTRICT,
 invited_at timestamptz NOT NULL,
 consented_at timestamptz,
 consent_language text CHECK (consent_language IN ('ru','uz','en')),
 consent_copy_version text CHECK
   (consent_copy_version IS NULL OR consent_copy_version='j25_as_theory_20261028_v1'),
 owner_approved_at timestamptz,
 revoked_at timestamptz,
 is_canary boolean NOT NULL DEFAULT false,
 active boolean NOT NULL DEFAULT false,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK (active=false OR (consented_at IS NOT NULL AND owner_approved_at IS NOT NULL
                         AND revoked_at IS NULL)),
 CHECK (consented_at IS NULL OR (consent_copy_version IS NOT NULL
                                 AND consent_language IS NOT NULL))
);
CREATE UNIQUE INDEX iclub_exam_chemistry_j25_one_active_canary_v1
 ON private.iclub_exam_chemistry_j25_as_theory_optins_v1 ((1))
 WHERE is_canary=true AND active=true;
ALTER TABLE private.iclub_exam_chemistry_j25_as_theory_optins_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j25_as_theory_optins_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j25_as_theory_optins_v1 FROM PUBLIC,anon,authenticated;

CREATE FUNCTION public.iclub_exam_chemistry_j25_theory_consent_status_v1()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_user uuid:=auth.uid();v_invited boolean:=false;v_consented boolean:=false;v_revoked boolean:=false;
BEGIN
 IF v_user IS NULL OR auth.role() IS DISTINCT FROM 'authenticated'
 OR coalesce(auth.jwt()->>'is_anonymous','false')='true'
 THEN RETURN jsonb_build_object('eligible',false,'invited',false,'consented',false,'can_start',false); END IF;
 SELECT true,consented_at IS NOT NULL AND revoked_at IS NULL,revoked_at IS NOT NULL
 INTO v_invited,v_consented,v_revoked
 FROM private.iclub_exam_chemistry_j25_as_theory_optins_v1 WHERE user_id=v_user;
 RETURN jsonb_build_object(
  'eligible',private.iclub_exam_chemistry_p1_math_beta_eligible_v1(v_user),
  'invited',coalesce(v_invited,false),'consented',coalesce(v_consented,false),
  'revoked',coalesce(v_revoked,false),
  'can_start',private.iclub_exam_chemistry_j24_theory_authorized_v1(),
  'component','AS_theory_only','copy_version','j25_as_theory_20261028_v1');
END;
$$;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_j25_theory_consent_status_v1() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_j25_theory_consent_status_v1() TO authenticated;

CREATE FUNCTION public.iclub_exam_chemistry_j25_grant_theory_consent_v1(
 p_language text,p_acknowledgement text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_user uuid:=auth.uid();v_updated integer;
BEGIN
 IF v_user IS NULL OR auth.role() IS DISTINCT FROM 'authenticated'
 OR coalesce(auth.jwt()->>'is_anonymous','false')='true'
 THEN RETURN jsonb_build_object('ok',false,'code','sign_in_required'); END IF;
 IF p_language IS NULL OR p_language NOT IN ('ru','uz','en')
 OR p_acknowledgement IS DISTINCT FROM 'I_VOLUNTARILY_AGREE_TO_CHEMISTRY_AS_THEORY_BETA_V1'
 THEN RETURN jsonb_build_object('ok',false,'code','explicit_consent_required'); END IF;
 IF NOT private.iclub_exam_chemistry_p1_math_beta_eligible_v1(v_user)
 THEN RETURN jsonb_build_object('ok',false,'code','not_eligible'); END IF;
 -- Only specifically invited learners may opt in. Repeated consent is idempotent.
 UPDATE private.iclub_exam_chemistry_j25_as_theory_optins_v1
 SET consented_at=clock_timestamp(),consent_language=p_language,
     consent_copy_version='j25_as_theory_20261028_v1',
     owner_approved_at=NULL,revoked_at=NULL,active=false
 WHERE user_id=v_user AND invited_at IS NOT NULL
   AND (consented_at IS NULL OR revoked_at IS NOT NULL);
 GET DIAGNOSTICS v_updated=ROW_COUNT;
 IF v_updated=0 THEN
  IF EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j25_as_theory_optins_v1
            WHERE user_id=v_user AND consented_at IS NOT NULL AND revoked_at IS NULL)
  THEN RETURN jsonb_build_object('ok',true,'code','already_recorded',
                                 'access','pending_or_existing_owner_decision'); END IF;
  RETURN jsonb_build_object('ok',false,'code','not_invited');
 END IF;
 RETURN jsonb_build_object('ok',true,'code','consent_recorded','access','pending_owner_approval');
END;
$$;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_j25_grant_theory_consent_v1(text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_j25_grant_theory_consent_v1(text,text) TO authenticated;

CREATE FUNCTION public.iclub_exam_chemistry_j25_revoke_theory_consent_v1()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_user uuid:=auth.uid();
BEGIN
 IF v_user IS NULL OR auth.role() IS DISTINCT FROM 'authenticated'
 OR coalesce(auth.jwt()->>'is_anonymous','false')='true'
 THEN RETURN jsonb_build_object('ok',false,'code','sign_in_required'); END IF;
 -- Revocation is available even after Mathematics Beta eligibility changes.
 UPDATE private.iclub_exam_chemistry_j25_as_theory_optins_v1
 SET revoked_at=clock_timestamp(),owner_approved_at=NULL,active=false
 WHERE user_id=v_user AND consented_at IS NOT NULL AND revoked_at IS NULL;
 RETURN jsonb_build_object('ok',true,'code','revoked','access','off');
END;
$$;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_j25_revoke_theory_consent_v1() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_j25_revoke_theory_consent_v1() TO authenticated;

-- J24 now insists on the separate J25 AS Theory opt-in rather than treating
-- the older Chemistry Paper 1 consent as implicit permission for Theory.
-- Every existing J24 academic, manifest, exam and release gate is preserved.
CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_j24_theory_authorized_v1()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $$
 SELECT auth.role()='authenticated' AND auth.uid() IS NOT NULL
 AND coalesce(auth.jwt()->>'is_anonymous','false')<>'true'
 AND private.iclub_exam_chemistry_p1_math_beta_eligible_v1(auth.uid())
 AND NOT private.iclub_ai_has_active_protected_assessment_v1(auth.uid())
 AND EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j25_as_theory_optins_v1 m
  CROSS JOIN private.iclub_exam_chemistry_j25_as_theory_control_v1 jc
  WHERE m.user_id=auth.uid() AND m.active=true AND m.invited_at IS NOT NULL
   AND m.consented_at IS NOT NULL AND m.owner_approved_at IS NOT NULL
   AND m.revoked_at IS NULL AND jc.id=1 AND jc.owner_go_at IS NOT NULL
   AND ((jc.release_phase='canary' AND m.is_canary=true)
        OR jc.release_phase='expanded'))
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

REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_j24_theory_authorized_v1() FROM PUBLIC,anon,authenticated;

COMMIT;
-- Neither consent nor invitation confers access without owner-controlled canary
-- phase, owner activation, J24 source and academic approvals, and Math Beta status.
