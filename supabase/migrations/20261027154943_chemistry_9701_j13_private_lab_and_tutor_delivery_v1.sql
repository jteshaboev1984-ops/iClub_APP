-- J13: Chemistry-only, additive controlled LAB and Tutor-source delivery.
-- Public RPCs are authenticated, have a real-user + beta consent + owner release
-- gate and do not expose anything while Chemistry is Draft/OFF.
-- P3 (AS) and P5 (A Level) are independent; P5 also needs learner-level A approval.
-- This does not mark practical competence, change mastery or grant any access.

DO $pre$
BEGIN
 IF to_regclass('private.iclub_exam_chemistry_j13_learning_control_v1') IS NOT NULL
 OR to_regprocedure('public.iclub_exam_chemistry_lab_catalog_v1(text,text)') IS NOT NULL
 OR (SELECT visible_to_learners FROM private.iclub_subject_library WHERE subject_key='chemistry') IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'J13 install requires an unused gate and hidden Chemistry'; END IF;
END $pre$;

CREATE TABLE private.iclub_exam_chemistry_j13_learning_control_v1(
 id smallint PRIMARY KEY CHECK(id=1),
 paper3_enabled boolean NOT NULL DEFAULT false,
 paper5_enabled boolean NOT NULL DEFAULT false,
 tutor_sources_enabled boolean NOT NULL DEFAULT false,
 paper3_owner_go_at timestamptz,
 paper5_owner_go_at timestamptz,
 tutor_owner_go_at timestamptz,
 approved_source_md5 text,
 CHECK(approved_source_md5 IS NULL OR approved_source_md5 ~ '^[a-f0-9]{32}$'),
 CHECK(NOT paper3_enabled OR (paper3_owner_go_at IS NOT NULL AND approved_source_md5 IS NOT NULL)),
 CHECK(NOT paper5_enabled OR (paper5_owner_go_at IS NOT NULL AND approved_source_md5 IS NOT NULL)),
 CHECK(NOT tutor_sources_enabled OR (tutor_owner_go_at IS NOT NULL AND approved_source_md5 IS NOT NULL))
);
INSERT INTO private.iclub_exam_chemistry_j13_learning_control_v1(id)
 VALUES(1);
ALTER TABLE private.iclub_exam_chemistry_j13_learning_control_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j13_learning_control_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j13_learning_control_v1
 FROM PUBLIC,anon,authenticated,service_role;

CREATE TABLE private.iclub_exam_chemistry_j13_a_level_permissions_v1(
 user_id uuid PRIMARY KEY REFERENCES auth.users(id),
 learner_consented_at timestamptz,
 owner_approved_at timestamptz,
 revoked_at timestamptz,
 CHECK(owner_approved_at IS NULL OR learner_consented_at IS NOT NULL)
);
ALTER TABLE private.iclub_exam_chemistry_j13_a_level_permissions_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j13_a_level_permissions_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j13_a_level_permissions_v1
 FROM PUBLIC,anon,authenticated,service_role;

CREATE FUNCTION private.iclub_exam_chemistry_j13_common_learner_authorized_v1(p_level text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $fn$
 SELECT auth.uid() IS NOT NULL
 AND coalesce(auth.jwt()->>'is_anonymous','false')<>'true'
 AND p_level IN ('AS','A')
 AND private.iclub_exam_chemistry_p1_math_beta_eligible_v1(auth.uid())
 AND EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_p1_beta_members_v1 m
  WHERE m.user_id=auth.uid() AND m.active=true AND m.consented_at IS NOT NULL
   AND m.owner_approved_at IS NOT NULL AND m.revoked_at IS NULL)
 AND EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1 p
  WHERE p.program_key='chemistry_9701' AND p.version_key='chemistry_2025_2027_v1'
  AND p.integration_mode='native' AND p.status='published' AND p.launch_enabled=true)
 AND EXISTS(SELECT 1 FROM private.iclub_subject_library l
  JOIN private.iclub_subject_library_releases r
   ON r.subject_key=l.subject_key AND r.version_key=l.active_version
  JOIN private.iclub_exam_chemistry_j12_release_control_v1 c ON c.id=1
  WHERE l.subject_key='chemistry' AND l.visible_to_learners=true
   AND l.active_version='chemistry9701_20261022_stageb_draft'
   AND r.state='validated' AND r.validated_at IS NOT NULL
   AND c.published_at IS NOT NULL AND c.rights_review_at IS NOT NULL)
 AND (p_level='AS' OR EXISTS(
  SELECT 1 FROM private.iclub_exam_chemistry_j13_a_level_permissions_v1 a
  WHERE a.user_id=auth.uid() AND a.learner_consented_at IS NOT NULL
    AND a.owner_approved_at IS NOT NULL AND a.revoked_at IS NULL));
$fn$;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_j13_common_learner_authorized_v1(text)
 FROM PUBLIC,anon,authenticated,service_role;

CREATE FUNCTION private.iclub_exam_chemistry_j13_can_read_lab_v1(p_paper text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $fn$
 SELECT p_paper IN ('P3','P5')
 AND private.iclub_exam_chemistry_j13_common_learner_authorized_v1(
   CASE WHEN p_paper='P3' THEN 'AS' ELSE 'A' END)
 AND EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j13_learning_control_v1 c
 JOIN private.iclub_exam_chemistry_j12_release_gate_v1 g ON true
 WHERE c.id=1 AND c.approved_source_md5=g.source_snapshot_md5
 AND ((p_paper='P3' AND c.paper3_enabled AND c.paper3_owner_go_at IS NOT NULL)
   OR (p_paper='P5' AND c.paper5_enabled AND c.paper5_owner_go_at IS NOT NULL)));
$fn$;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_j13_can_read_lab_v1(text)
 FROM PUBLIC,anon,authenticated,service_role;

CREATE FUNCTION public.iclub_exam_chemistry_lab_catalog_v1(
 p_paper text,p_language text DEFAULT 'ru')
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $fn$
DECLARE v_items jsonb; v_count integer;
BEGIN
 IF p_paper NOT IN('P3','P5') OR p_paper IS NULL
 OR p_language NOT IN('en','ru','uz') OR p_language IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_j13_can_read_lab_v1(p_paper)
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT count(*),coalesce(jsonb_agg(jsonb_build_object(
  'skill_key',x.skill_key,'title',x.locales->p_language->>'title',
  'paper_code',x.paper_code,'level_code',x.level_code,
  'syllabus_point',x.syllabus_point
 ) ORDER BY x.skill_key),'[]'::jsonb)
 INTO v_count,v_items
 FROM private.iclub_subject_library_cross_tour_v1 x
 WHERE x.subject_key='chemistry'
 AND x.version_key='chemistry9701_20261022_stageb_draft'
 AND x.paper_code=p_paper AND x.level_code=CASE WHEN p_paper='P3' THEN 'AS' ELSE 'A' END
 AND x.state='validated'
 AND length(coalesce(x.locales->p_language->>'title',''))>5
 AND length(coalesce(x.locales->p_language->>'explanation',''))>=100;
 IF v_count<>6 THEN RETURN jsonb_build_object('ok',false,'code','content_incomplete'); END IF;
 RETURN jsonb_build_object('ok',true,'subject','chemistry',
  'paper_code',p_paper,'level_code',CASE WHEN p_paper='P3' THEN 'AS' ELSE 'A' END,
  'locale',p_language,'items',v_items,'count',v_count,'can_credit_mastery',false);
END $fn$;

CREATE FUNCTION public.iclub_exam_chemistry_lab_lesson_v1(
 p_paper text,p_skill_key text,p_language text DEFAULT 'ru')
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $fn$
DECLARE v_card record;
BEGIN
 IF p_paper NOT IN('P3','P5') OR p_paper IS NULL
 OR p_language NOT IN('en','ru','uz') OR p_language IS NULL
 OR p_skill_key !~ '^CHEM9701-LAB-(0[1-9]|1[0-2])$' OR p_skill_key IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_j13_can_read_lab_v1(p_paper)
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT x.skill_key,x.paper_code,x.level_code,x.syllabus_point,
  x.locales->p_language->>'title' AS title,
  x.locales->p_language->>'explanation' AS explanation
 INTO v_card
 FROM private.iclub_subject_library_cross_tour_v1 x
 WHERE x.subject_key='chemistry'
 AND x.version_key='chemistry9701_20261022_stageb_draft'
 AND x.skill_key=p_skill_key AND x.paper_code=p_paper
 AND x.level_code=CASE WHEN p_paper='P3' THEN 'AS' ELSE 'A' END
 AND x.state='validated';
 IF NOT FOUND OR length(coalesce(v_card.title,''))<=5
 OR length(coalesce(v_card.explanation,''))<100
 THEN RETURN jsonb_build_object('ok',false,'code','lesson_not_available'); END IF;
 RETURN jsonb_build_object('ok',true,'skill_key',v_card.skill_key,
  'paper_code',v_card.paper_code,'level_code',v_card.level_code,
  'syllabus_point',v_card.syllabus_point,'locale',p_language,
  'title',v_card.title,'explanation',v_card.explanation,
  'tutor_included',false,'can_credit_mastery',false,
  'practical_exam_replacement',false);
END $fn$;

CREATE FUNCTION public.iclub_exam_chemistry_tutor_source_v1(
 p_skill_key text,p_language text DEFAULT 'ru')
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $fn$
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
END $fn$;

REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_lab_catalog_v1(text,text)
 FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_lab_lesson_v1(text,text,text)
 FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_tutor_source_v1(text,text)
 FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_lab_catalog_v1(text,text)
 TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_lab_lesson_v1(text,text,text)
 TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_tutor_source_v1(text,text)
 TO authenticated;

DO $post$
BEGIN
 IF (SELECT paper3_enabled OR paper5_enabled OR tutor_sources_enabled
 FROM private.iclub_exam_chemistry_j13_learning_control_v1 WHERE id=1)
 OR EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j13_a_level_permissions_v1)
 OR (SELECT visible_to_learners FROM private.iclub_subject_library WHERE subject_key='chemistry')
 OR has_function_privilege('anon','public.iclub_exam_chemistry_lab_catalog_v1(text,text)','EXECUTE')
 OR has_function_privilege('anon','public.iclub_exam_chemistry_lab_lesson_v1(text,text,text)','EXECUTE')
 OR has_function_privilege('anon','public.iclub_exam_chemistry_tutor_source_v1(text,text)','EXECUTE')
 THEN RAISE EXCEPTION 'J13 accidentally enabled access'; END IF;
END $post$;
