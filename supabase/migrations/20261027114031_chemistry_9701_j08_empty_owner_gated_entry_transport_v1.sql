-- Chemistry 9701 J08. Isolated, owner-released learner ENTRY route.
-- Existing Mathematics beta cohort and separate Chemistry consent are reused by reference.
-- No enabled releases, learner sessions or user records are created.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_chemistry_entry_release_v1') IS NOT NULL
 OR to_regclass('private.iclub_exam_chemistry_entry_release_items_v1') IS NOT NULL
 OR to_regclass('private.iclub_exam_chemistry_entry_attempts_v1') IS NOT NULL
 OR to_regprocedure('public.get_my_exam_prep_chemistry_entry_shell_v1(text)') IS NOT NULL
 THEN RAISE EXCEPTION 'J08 already installed'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_entry_study_links_v1
 WHERE seven_review_gates AND trilingual_theory_link AND trilingual_tutor_link
 AND distinct_from_exam_blueprint AND unreleased)<>22
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_p1_beta_members_v1)<>0
 OR (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'J07 sources not intact or Chemistry beta unexpectedly open'; END IF;
END $pre$;

CREATE TABLE private.iclub_exam_chemistry_entry_release_v1(
 id smallint PRIMARY KEY CHECK(id=1),
 enabled boolean NOT NULL DEFAULT false,
 owner_go_at timestamptz,
 release_version text,
 approved_manifest_md5 text CHECK(approved_manifest_md5 IS NULL OR approved_manifest_md5~'^[0-9a-f]{32}$'),
 CHECK(enabled=false OR (owner_go_at IS NOT NULL AND length(release_version)>=12 AND approved_manifest_md5 IS NOT NULL))
);
INSERT INTO private.iclub_exam_chemistry_entry_release_v1(id,enabled) VALUES(1,false);

CREATE TABLE private.iclub_exam_chemistry_entry_release_items_v1(
 item_id text PRIMARY KEY REFERENCES private.iclub_exam_chemistry_entry_items_v1(id) ON DELETE RESTRICT,
 item_md5 text NOT NULL CHECK(item_md5~'^[0-9a-f]{32}$'),
 release_version text NOT NULL CHECK(length(release_version)>=12),
 approved_at timestamptz NOT NULL
);

CREATE TABLE private.iclub_exam_chemistry_entry_attempts_v1(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
 program_key text NOT NULL DEFAULT 'chemistry_9701' CHECK(program_key='chemistry_9701'),
 assessment_code text NOT NULL DEFAULT 'ENTRY' CHECK(assessment_code='ENTRY'),
 client_key text NOT NULL CHECK(length(client_key) BETWEEN 12 AND 128 AND client_key~'^[A-Za-z0-9_-]+$'),
 status text NOT NULL DEFAULT 'active' CHECK(status IN('active','finalized')),
 source_manifest_md5 text NOT NULL CHECK(source_manifest_md5~'^[0-9a-f]{32}$'),
 items jsonb NOT NULL CHECK(jsonb_typeof(items)='array' AND jsonb_array_length(items)=22),
 responses jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(responses)='object'),
 started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 deadline_at timestamptz NOT NULL,
 finalized_at timestamptz,
 score integer CHECK(score BETWEEN 0 AND 22),
 credited_to_mastery boolean NOT NULL DEFAULT false CHECK(credited_to_mastery=false),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(user_id,program_key,assessment_code,client_key),
 CHECK(deadline_at>started_at),
 CHECK((status='active' AND score IS NULL AND finalized_at IS NULL)
 OR (status='finalized' AND score IS NOT NULL AND finalized_at IS NOT NULL))
);
CREATE UNIQUE INDEX chemistry_entry_only_one_active_v1 ON
 private.iclub_exam_chemistry_entry_attempts_v1(user_id,program_key,assessment_code)
 WHERE status='active';
CREATE INDEX chemistry_entry_user_history_v1 ON
 private.iclub_exam_chemistry_entry_attempts_v1(user_id,started_at DESC);

ALTER TABLE private.iclub_exam_chemistry_entry_release_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_entry_release_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_entry_release_items_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_entry_release_items_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_entry_attempts_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_entry_attempts_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_entry_release_v1 FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON private.iclub_exam_chemistry_entry_release_items_v1 FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON private.iclub_exam_chemistry_entry_attempts_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_chemistry_entry_release_v1 TO service_role;
GRANT SELECT ON private.iclub_exam_chemistry_entry_release_items_v1 TO service_role;
GRANT SELECT ON private.iclub_exam_chemistry_entry_attempts_v1 TO service_role;

CREATE FUNCTION private.iclub_exam_chemistry_entry_student_authorized_v1()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $f$
 SELECT auth.uid() IS NOT NULL
 AND coalesce(auth.jwt()->>'is_anonymous','false')<>'true'
 AND private.iclub_exam_chemistry_p1_math_beta_eligible_v1(auth.uid())
 AND EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_p1_beta_members_v1 m
 WHERE m.user_id=auth.uid() AND m.active=true
 AND m.consented_at IS NOT NULL AND m.owner_approved_at IS NOT NULL AND m.revoked_at IS NULL)
 AND EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1 p
 WHERE p.program_key='chemistry_9701' AND p.version_key='chemistry_2025_2027_v1'
 AND p.integration_mode='native' AND p.status='published' AND p.launch_enabled=true)
 AND EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_entry_release_v1 c
 WHERE c.id=1 AND c.enabled=true AND c.owner_go_at IS NOT NULL
 AND length(c.release_version)>=12 AND c.approved_manifest_md5 IS NOT NULL);
$f$;

CREATE FUNCTION public.get_my_exam_prep_chemistry_entry_shell_v1(p_language text DEFAULT 'ru')
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
BEGIN
 IF p_language IS NULL OR p_language NOT IN('ru','uz','en')
 OR NOT private.iclub_exam_chemistry_entry_student_authorized_v1()
 THEN RETURN '{}'::jsonb; END IF;
 RETURN jsonb_build_object('enabled',true,'program_key','chemistry_9701',
 'assessment_code','ENTRY','duration_seconds',1800,'item_count',22,
 'language',p_language,'can_credit_mastery',false,
 'calibrated_diagnostic',false);
END $f$;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_entry_student_authorized_v1()
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.get_my_exam_prep_chemistry_entry_shell_v1(text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_chemistry_entry_shell_v1(text) TO authenticated;

DO $post$ BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_entry_attempts_v1)<>0
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_entry_release_items_v1)<>0
 OR (SELECT enabled FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1) IS DISTINCT FROM false
 OR public.get_my_exam_prep_chemistry_entry_shell_v1('en') <> '{}'::jsonb
 OR has_function_privilege('anon','public.get_my_exam_prep_chemistry_entry_shell_v1(text)','EXECUTE')
 OR has_table_privilege('authenticated','private.iclub_exam_chemistry_entry_attempts_v1','SELECT')
 THEN RAISE EXCEPTION 'Entry route must stay OFF, empty and private'; END IF;
END $post$;