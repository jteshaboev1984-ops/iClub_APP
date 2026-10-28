-- J12: Chemistry-only administrative composite publisher and immediate hide.
-- Never callable by anon/authenticated/service_role. Require explicit, pinned owner GO.
-- Functions are SECURITY INVOKER, and are initially inert (control.armed=false).
ALTER TABLE private.iclub_exam_chemistry_j12_release_control_v1
 ADD COLUMN IF NOT EXISTS previous_active_version text,
 ADD COLUMN IF NOT EXISTS previous_visible boolean,
 ADD COLUMN IF NOT EXISTS published_version text,
 ADD COLUMN IF NOT EXISTS published_at timestamptz,
 ADD COLUMN IF NOT EXISTS hidden_at timestamptz;

CREATE FUNCTION private.iclub_exam_chemistry_j12_admin_publish_v1(
 p_version text,p_package_sha256 text,p_source_md5 text,p_owner_phrase text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY INVOKER SET search_path=''
AS $func$
DECLARE c private.iclub_exam_chemistry_j12_release_control_v1%ROWTYPE;
 lib private.iclub_subject_library%ROWTYPE;
 pkg private.iclub_subject_library_releases%ROWTYPE;
 g private.iclub_exam_chemistry_j12_release_gate_v1%ROWTYPE;
 n integer;
BEGIN
 IF current_user<>'postgres'
 THEN RAISE EXCEPTION 'J12 publisher is exclusively an administrator operation' USING ERRCODE='42501'; END IF;
 IF p_owner_phrase IS DISTINCT FROM 'ICLUB_CHEMISTRY_9701_166_OWNER_GO'
 OR p_version IS DISTINCT FROM 'chemistry9701_20261022_stageb_draft'
 OR p_source_md5 IS NULL OR p_package_sha256 IS NULL
 THEN RETURN jsonb_build_object('published',false,'code','explicit_go_not_provided'); END IF;
 -- A real release waits for five separate nontechnical sign-offs in the control table.
 SELECT * INTO c FROM private.iclub_exam_chemistry_j12_release_control_v1
 WHERE id=1 FOR UPDATE;
 IF NOT FOUND OR NOT c.armed THEN
 RETURN jsonb_build_object('published',false,'code','owner_release_not_armed'); END IF;
 SELECT * INTO lib FROM private.iclub_subject_library
 WHERE subject_key='chemistry' FOR UPDATE;
 SELECT * INTO pkg FROM private.iclub_subject_library_releases
 WHERE subject_key='chemistry' AND version_key=p_version FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Source package not found'; END IF;
 -- Seal the content snapshot while verifying and publishing; no concurrent author edits.
 LOCK TABLE private.iclub_subject_library_theory,
 private.iclub_subject_library_tutor,
 private.iclub_subject_library_cross_tour_v1 IN SHARE MODE;
 SELECT * INTO g FROM private.iclub_exam_chemistry_j12_release_gate_v1
 WHERE version_key=p_version;
 IF NOT FOUND OR g.can_publish IS DISTINCT FROM true
 OR g.sources_total<>166
 OR g.source_snapshot_md5 IS DISTINCT FROM p_source_md5
 OR c.approved_source_md5 IS DISTINCT FROM p_source_md5
 OR c.approved_version IS DISTINCT FROM p_version
 OR c.approved_package_sha256 IS DISTINCT FROM p_package_sha256
 OR pkg.package_sha256 IS DISTINCT FROM p_package_sha256
 OR pkg.expected_skills<>166
 OR lib.active_version IS NOT NULL OR lib.visible_to_learners
 OR pkg.state<>'draft' OR pkg.validated_at IS NOT NULL
 THEN RAISE EXCEPTION 'J12 composite release conditions no longer match approved source'; END IF;
 UPDATE private.iclub_subject_library_releases
 SET state='validated',validated_at=clock_timestamp()
 WHERE subject_key='chemistry' AND version_key=p_version AND state='draft';
 GET DIAGNOSTICS n=ROW_COUNT;
 IF n<>1 THEN RAISE EXCEPTION 'Package state race detected'; END IF;
 UPDATE private.iclub_subject_library_cross_tour_v1
 SET state='validated'
 WHERE subject_key='chemistry' AND version_key=p_version AND state='draft';
 GET DIAGNOSTICS n=ROW_COUNT;
 IF n<>12 THEN RAISE EXCEPTION 'Not all 12 LAB records transitioned to validated'; END IF;
 UPDATE private.iclub_subject_library
 SET active_version=p_version,visible_to_learners=true,updated_at=clock_timestamp()
 WHERE subject_key='chemistry' AND active_version IS NULL
 AND visible_to_learners=false;
 GET DIAGNOSTICS n=ROW_COUNT;
 IF n<>1 THEN RAISE EXCEPTION 'Subject state race detected'; END IF;
 INSERT INTO private.iclub_subject_library_release_events
 (subject_key,from_version,to_version,action)
 VALUES('chemistry',lib.active_version,p_version,'publish');
 UPDATE private.iclub_exam_chemistry_j12_release_control_v1
 SET armed=false,consumed_at=clock_timestamp(),
 previous_active_version=lib.active_version,
 previous_visible=lib.visible_to_learners,
 published_version=p_version,published_at=clock_timestamp()
 WHERE id=1;
 RETURN jsonb_build_object('published',true,'subject','chemistry',
 'version',p_version,'theory_skills',154,'lab_skills',12,
 'recheck_and_exam_access_unchanged',true);
END $func$;

CREATE FUNCTION private.iclub_exam_chemistry_j12_admin_hide_v1(
 p_reason text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY INVOKER SET search_path=''
AS $func$
DECLARE c private.iclub_exam_chemistry_j12_release_control_v1%ROWTYPE;
 lib private.iclub_subject_library%ROWTYPE;
 n integer;
BEGIN
 IF current_user<>'postgres' THEN
 RAISE EXCEPTION 'J12 hide is exclusively an administrator operation' USING ERRCODE='42501'; END IF;
 IF p_reason IS NULL OR length(trim(p_reason))<10
 THEN RETURN jsonb_build_object('hidden',false,'code','reason_required'); END IF;
 SELECT * INTO c FROM private.iclub_exam_chemistry_j12_release_control_v1
 WHERE id=1 FOR UPDATE;
 SELECT * INTO lib FROM private.iclub_subject_library
 WHERE subject_key='chemistry' FOR UPDATE;
 IF c.published_at IS NULL OR c.published_version IS NULL
 THEN RETURN jsonb_build_object('hidden',false,'code','no_composite_release_to_hide'); END IF;
 IF lib.visible_to_learners IS DISTINCT FROM true OR
 lib.active_version IS DISTINCT FROM c.published_version THEN
 RETURN jsonb_build_object('hidden',false,'code','already_hidden_or_version_changed'); END IF;
 UPDATE private.iclub_subject_library
 SET visible_to_learners=false,
 active_version=c.previous_active_version,updated_at=clock_timestamp()
 WHERE subject_key='chemistry';
 GET DIAGNOSTICS n=ROW_COUNT;
 IF n<>1 THEN RAISE EXCEPTION 'Subject disappeared while hiding'; END IF;
 INSERT INTO private.iclub_subject_library_release_events
 (subject_key,from_version,to_version,action)
 VALUES('chemistry',c.published_version,c.previous_active_version,'hide');
 UPDATE private.iclub_exam_chemistry_j12_release_control_v1
 SET armed=false,hidden_at=clock_timestamp() WHERE id=1;
 RETURN jsonb_build_object('hidden',true,'subject','chemistry',
 'visible',false,'attempts_preserved',true,'reason_recorded',false,
 'validated_content_preserved',true);
END $func$;

REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_j12_admin_publish_v1(text,text,text,text)
 FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_j12_admin_hide_v1(text)
 FROM PUBLIC,anon,authenticated,service_role;

DO $post$ DECLARE r jsonb;BEGIN
 IF has_function_privilege('anon','private.iclub_exam_chemistry_j12_admin_publish_v1(text,text,text,text)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_j12_admin_publish_v1(text,text,text,text)','EXECUTE')
 OR has_function_privilege('service_role','private.iclub_exam_chemistry_j12_admin_publish_v1(text,text,text,text)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_j12_admin_hide_v1(text)','EXECUTE')
 THEN RAISE EXCEPTION 'J12 admin release unexpectedly callable by learners'; END IF;
 SELECT private.iclub_exam_chemistry_j12_admin_publish_v1(
 'chemistry9701_20261022_stageb_draft', repeat('0',64),repeat('0',32),
 'ICLUB_CHEMISTRY_9701_166_OWNER_GO') INTO r;
 IF r->>'code'<>'owner_release_not_armed'
 OR (SELECT visible_to_learners FROM private.iclub_subject_library WHERE subject_key='chemistry')
 OR (SELECT armed FROM private.iclub_exam_chemistry_j12_release_control_v1 WHERE id=1)
 THEN RAISE EXCEPTION 'J12 release failed-closed test'; END IF;
END $post$;