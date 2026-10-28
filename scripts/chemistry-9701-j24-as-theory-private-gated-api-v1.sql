-- J24 STAGED ONLY (not applied): additive independent AS-only Theory route.
-- Chemistry content remains DRAFT, invisible globally, no learner release by creating this file.
-- Applying this script will only add a disabled private gate and two deny-by-default RPCs.
BEGIN;

CREATE TABLE IF NOT EXISTS private.iclub_exam_chemistry_j24_as_theory_control_v1 (
 id smallint PRIMARY KEY DEFAULT 1 CHECK (id=1),
 enabled boolean NOT NULL DEFAULT false,
 owner_go_at timestamptz,
 academic_science_review_at timestamptz,
 trilingual_review_at timestamptz,
 rights_owner_attestation_at timestamptz,
 owner_backup_deferral_at timestamptz,
 approved_version text,
 approved_source_md5 text,
 approved_as_manifest_md5 text,
 approved_skill_count integer CHECK (approved_skill_count=91),
 reviewed_evidence_ref text,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT j24_release_proof_required CHECK (
  enabled=false OR
  (owner_go_at IS NOT NULL AND academic_science_review_at IS NOT NULL
   AND trilingual_review_at IS NOT NULL AND rights_owner_attestation_at IS NOT NULL
   AND owner_backup_deferral_at IS NOT NULL
   AND approved_version='chemistry9701_20261022_stageb_draft'
   AND approved_source_md5 ~ '^[a-f0-9]{32}$'
   AND approved_as_manifest_md5 ~ '^[a-f0-9]{32}$'
   AND approved_skill_count=91
   AND length(btrim(reviewed_evidence_ref))>=16)
 )
);

ALTER TABLE private.iclub_exam_chemistry_j24_as_theory_control_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j24_as_theory_control_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j24_as_theory_control_v1 FROM PUBLIC, anon, authenticated;
INSERT INTO private.iclub_exam_chemistry_j24_as_theory_control_v1(id,enabled)
VALUES(1,false) ON CONFLICT(id) DO NOTHING;

CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_j24_theory_authorized_v1()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $$
 SELECT auth.role()='authenticated' AND auth.uid() IS NOT NULL
 AND coalesce(auth.jwt()->>'is_anonymous','false')<>'true'
 AND private.iclub_exam_chemistry_p1_math_beta_eligible_v1(auth.uid())
 AND NOT private.iclub_ai_has_active_protected_assessment_v1(auth.uid())
 AND EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_p1_beta_members_v1 m
  WHERE m.user_id=auth.uid() AND m.active=true AND m.consented_at IS NOT NULL
   AND m.owner_approved_at IS NOT NULL AND m.revoked_at IS NULL)
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
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_j24_theory_authorized_v1() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.iclub_exam_chemistry_j24_theory_catalog_v1(
 p_language text DEFAULT 'ru')
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_items jsonb;v_count integer;
BEGIN
 IF p_language IS NULL OR p_language NOT IN('ru','uz','en')
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_j24_theory_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;

 SELECT count(*),
 coalesce(jsonb_agg(jsonb_build_object(
  'skill_key',t.skill_key,'title',t.locales->p_language->>'title',
  'tour_number',t.tour_no,'syllabus_point',t.syllabus_point,
  'is_syllabus_outcome',t.syllabus_point NOT LIKE '%NO_EXPLICIT%'
 ) ORDER BY t.tour_no,t.skill_key),'[]'::jsonb)
 INTO v_count,v_items
 FROM private.iclub_exam_core_skills_v1 s
 JOIN private.iclub_subject_library_theory t
   ON t.subject_key=s.library_subject_key
  AND t.version_key=s.library_version_key AND t.skill_key=s.skill_key
 WHERE s.program_key='chemistry_9701' AND s.version_key='chemistry_2025_2027_v1'
   AND s.library_version_key='chemistry9701_20261022_stageb_draft'
   AND s.level_code='AS' AND t.tour_no BETWEEN 1 AND 5
   AND t.content_hash=s.content_hash
   AND length(btrim(coalesce(t.locales->p_language->>'title','')))>=4
   AND length(btrim(coalesce(t.locales->p_language->>'explanation','')))>=100;
 IF v_count<>91
 THEN RETURN jsonb_build_object('ok',false,'code','content_incomplete'); END IF;
 RETURN jsonb_build_object('ok',true,'subject','chemistry',
   'scope','AS_theory_only','locale',p_language,'count',v_count,
   'items',v_items,'ai_tutor_included',false,'can_credit_mastery',false);
END;
$$;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_j24_theory_catalog_v1(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_j24_theory_catalog_v1(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.iclub_exam_chemistry_j24_theory_lesson_v1(
 p_skill_key text,p_language text DEFAULT 'ru')
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_title text;v_body text;v_tour integer;v_point text;
BEGIN
 IF p_language IS NULL OR p_language NOT IN('ru','uz','en')
 OR p_skill_key IS NULL OR p_skill_key !~ '^CHEM9701-[0-9]{2}-[0-9]{2}$'
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_j24_theory_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;

 SELECT t.locales->p_language->>'title',t.locales->p_language->>'explanation',
        t.tour_no,t.syllabus_point
 INTO v_title,v_body,v_tour,v_point
 FROM private.iclub_exam_core_skills_v1 s
 JOIN private.iclub_subject_library_theory t
   ON t.subject_key=s.library_subject_key
  AND t.version_key=s.library_version_key AND t.skill_key=s.skill_key
 WHERE s.program_key='chemistry_9701' AND s.version_key='chemistry_2025_2027_v1'
 AND s.library_version_key='chemistry9701_20261022_stageb_draft'
 AND s.level_code='AS' AND s.skill_key=p_skill_key AND t.tour_no BETWEEN 1 AND 5
 AND t.content_hash=s.content_hash LIMIT 1;

 IF length(btrim(coalesce(v_title,'')))<4 OR length(btrim(coalesce(v_body,'')))<100
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 RETURN jsonb_build_object('ok',true,'skill_key',p_skill_key,
  'locale',p_language,'title',v_title,'explanation',v_body,
  'tour_number',v_tour,'syllabus_point',v_point,
  'is_syllabus_outcome',v_point NOT LIKE '%NO_EXPLICIT%',
  'can_credit_mastery',false,'ai_tutor_included',false,
  'paper3_lab_included',false,'paper5_lab_included',false);
END;
$$;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_j24_theory_lesson_v1(text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_j24_theory_lesson_v1(text,text) TO authenticated;

COMMIT;
