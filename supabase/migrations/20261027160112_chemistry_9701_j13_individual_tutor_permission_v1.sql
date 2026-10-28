-- Require personal Tutor consent and an owner-approved entitlement as well as
-- the independent J13 global Tutor switch. No new learner is approved by migration.
DO $guard$ BEGIN
 IF to_regclass('private.iclub_exam_chemistry_j13_tutor_permissions_v1') IS NOT NULL
 OR (SELECT tutor_sources_enabled FROM private.iclub_exam_chemistry_j13_learning_control_v1 WHERE id=1)
 THEN RAISE EXCEPTION 'Tutor permission install requires closed unused gate'; END IF;
END $guard$;
CREATE TABLE private.iclub_exam_chemistry_j13_tutor_permissions_v1(
 user_id uuid PRIMARY KEY REFERENCES auth.users(id),
 learner_consented_at timestamptz,
 owner_approved_at timestamptz,
 revoked_at timestamptz,
 CHECK(owner_approved_at IS NULL OR learner_consented_at IS NOT NULL)
);
ALTER TABLE private.iclub_exam_chemistry_j13_tutor_permissions_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j13_tutor_permissions_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j13_tutor_permissions_v1
 FROM PUBLIC,anon,authenticated,service_role;
CREATE OR REPLACE FUNCTION public.iclub_exam_chemistry_tutor_source_v1(p_skill_key text, p_language text DEFAULT 'ru'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_card record;
BEGIN
 IF p_language NOT IN('en','ru','uz') OR p_language IS NULL
 OR p_skill_key !~ '^CHEM9701-[0-9]{2}-[0-9]{2}$' OR p_skill_key IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j13_learning_control_v1 c
 JOIN private.iclub_exam_chemistry_j12_release_gate_v1 g ON true
 WHERE c.id=1 AND c.tutor_sources_enabled AND c.tutor_owner_go_at IS NOT NULL
 AND c.approved_source_md5=g.source_snapshot_md5)
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j13_tutor_permissions_v1 a
 WHERE a.user_id=auth.uid() AND a.learner_consented_at IS NOT NULL
 AND a.owner_approved_at IS NOT NULL AND a.revoked_at IS NULL)
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 IF private.iclub_ai_has_active_protected_assessment_v1(auth.uid())
 THEN RETURN jsonb_build_object('ok',false,'code','assessment_in_progress'); END IF;
 SELECT s.level_code,t.content_hash,u.source_card_hash,
 u.title,u.main_explanation,u.simple_explanation,
 u.alternative_explanation,u.focus_explanation
 INTO v_card
 FROM private.iclub_exam_core_skills_v1 s
 JOIN private.iclub_subject_library_theory t
 ON t.subject_key=s.library_subject_key AND t.version_key=s.library_version_key
 AND t.skill_key=s.skill_key
 JOIN private.iclub_subject_library_tutor u
 ON u.subject_key=t.subject_key AND u.version_key=t.version_key
 AND u.skill_key=t.skill_key AND u.locale=p_language
 WHERE s.program_key='chemistry_9701' AND s.version_key='chemistry_2025_2027_v1'
 AND s.skill_key=p_skill_key AND s.level_code IN('AS','A')
 AND s.library_version_key='chemistry9701_20261022_stageb_draft';
 IF NOT FOUND OR v_card.content_hash IS DISTINCT FROM v_card.source_card_hash
 OR NOT private.iclub_exam_chemistry_j13_common_learner_authorized_v1(v_card.level_code)
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 RETURN jsonb_build_object('ok',true,'skill_key',p_skill_key,'locale',p_language,
  'title',v_card.title,'main_explanation',v_card.main_explanation,
  'simple_explanation',v_card.simple_explanation,
  'alternative_explanation',v_card.alternative_explanation,
  'focus_explanation',v_card.focus_explanation,
  'is_static_reviewed_source',true,'is_generated_ai_answer',false,
  'can_credit_mastery',false);
END $function$
;
DO $post$ BEGIN
 IF has_table_privilege('authenticated','private.iclub_exam_chemistry_j13_tutor_permissions_v1','SELECT')
 OR EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j13_tutor_permissions_v1)
 OR pg_get_functiondef('public.iclub_exam_chemistry_tutor_source_v1(text,text)'::regprocedure)
  NOT LIKE '%FROM private.iclub_exam_chemistry_j13_tutor_permissions_v1%'
 THEN RAISE EXCEPTION 'Tutor per-user entitlement failed'; END IF;
END $post$;
