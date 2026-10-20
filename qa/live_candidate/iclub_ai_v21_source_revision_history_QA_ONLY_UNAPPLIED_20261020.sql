-- iClub Global AI v2.1 | QA ONLY, UNAPPLIED. Strictly controlled trilingual
-- draft supersession with immutable source-history ledger. No production run.
-- Install only alongside the existing qbank provenance QA gate in SCRATCH PG.
-- This does not approve/publish/enable sources or touch original question rows.
CREATE TABLE private.iclub_ai_v21_source_revision_archive (
 source_card_key text PRIMARY KEY,
 surface_code text NOT NULL,
 subject_key text NOT NULL,
 context_key text NOT NULL,
 locale text NOT NULL CHECK(locale IN ('en','ru','uz')),
 source_version text NOT NULL,
 publication_revision integer NOT NULL,
 body_text text NOT NULL,
 content_hash text NOT NULL CHECK(content_hash ~ '^[a-f0-9]{64}$'),
 target_hash text NOT NULL CHECK(target_hash ~ '^[a-f0-9]{64}$'),
 superseded_by_version text NOT NULL,
 replaced_by_source_key text NOT NULL,
 revision_note text NOT NULL,
 archived_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK (source_version<>superseded_by_version),
 UNIQUE(surface_code,subject_key,context_key,locale,source_version)
);
ALTER TABLE private.iclub_ai_v21_source_revision_archive ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.iclub_ai_v21_source_revision_archive
 FROM PUBLIC,anon,authenticated,service_role;

CREATE FUNCTION private.iclub_ai_v21_archive_append_only_guard_v1()
 RETURNS trigger LANGUAGE plpgsql SET search_path=''
 AS $$
BEGIN
 RAISE EXCEPTION 'Immutable academic source revision history';
END;
$$;
CREATE TRIGGER iclub_ai_v21_source_archive_append_only
 BEFORE UPDATE OR DELETE ON private.iclub_ai_v21_source_revision_archive
 FOR EACH ROW EXECUTE FUNCTION private.iclub_ai_v21_archive_append_only_guard_v1();
REVOKE ALL ON FUNCTION private.iclub_ai_v21_archive_append_only_guard_v1()
 FROM PUBLIC,anon,authenticated,service_role;

-- Only the trusted migration owner may invoke this administrative stage function.
-- A failed, partial, stale, delivered or previously authorized source leaves
-- every locale unchanged; it must not "fix" a live released academic answer.
CREATE FUNCTION private.iclub_ai_v21_stage_three_locale_revision_v1(
 p_subject_key text,p_question_id bigint,
 p_expected_version text,p_new_version text,
 p_payload jsonb,p_note text
) RETURNS integer LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $stage$
DECLARE
 v_key text:='question_'||p_question_id::text;
 v_locale text;
 v_content text;
 v_new_key text;
 v_old private.iclub_ai_v21_academic_sources%rowtype;
 v_count integer:=0;
BEGIN
 IF p_subject_key IS NULL OR p_question_id IS NULL OR p_question_id<=0
 OR p_expected_version IS NULL OR p_new_version IS NULL
 OR p_expected_version=p_new_version
 OR p_new_version !~ '^[a-z][a-z0-9_]{2,119}$'
 OR p_note IS NULL OR length(btrim(p_note)) NOT BETWEEN 12 AND 500
 OR p_payload IS NULL OR jsonb_typeof(p_payload)<>'object'
 OR (SELECT count(*) FROM jsonb_object_keys(p_payload))<>3
 OR (SELECT count(*) FROM jsonb_object_keys(p_payload) k
    WHERE k IN ('en','ru','uz'))<>3
 THEN RAISE EXCEPTION 'Invalid three-language academic draft revision request'; END IF;

 -- Pure question/subject authority from live base tables.
 IF NOT EXISTS(SELECT 1 FROM public.questions q
 JOIN public.subjects subj ON subj.id=q.subject_id
 WHERE q.id=p_question_id AND q.is_active AND q.quality_status='published'
 AND subj.is_active AND subj.subject_key=p_subject_key) THEN
 RAISE EXCEPTION 'Question or subject no longer active'; END IF;

 -- Verify exactly three matching records and lock all in deterministic order.
 PERFORM 1 FROM private.iclub_ai_v21_academic_sources s
 WHERE s.surface_code='practice_error' AND s.subject_key=p_subject_key
 AND s.context_key=v_key AND s.locale IN ('en','ru','uz')
 ORDER BY s.locale FOR UPDATE;

 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources s
     WHERE s.surface_code='practice_error' AND s.subject_key=p_subject_key
       AND s.context_key=v_key
       AND s.source_version=p_expected_version
       AND s.locale IN ('en','ru','uz'))<>3
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources s
     WHERE s.surface_code='practice_error' AND s.subject_key=p_subject_key
       AND s.context_key=v_key)<>3
 THEN RAISE EXCEPTION 'Incomplete or mismatched existing locale versions'; END IF;

 FOREACH v_locale IN ARRAY ARRAY['en','ru','uz'] LOOP
  v_content:=btrim(p_payload->>v_locale);
  IF jsonb_typeof(p_payload->v_locale)<>'string'
  OR v_content IS NULL OR length(v_content) NOT BETWEEN 100 AND 6000
  THEN RAISE EXCEPTION 'Invalid academic revision text: %',v_locale; END IF;
  SELECT * INTO STRICT v_old
  FROM private.iclub_ai_v21_academic_sources s
  WHERE s.surface_code='practice_error' AND s.subject_key=p_subject_key
   AND s.context_key=v_key AND s.locale=v_locale;

  IF v_old.published OR NOT v_old.revoked OR v_old.content_reviewed
  OR v_old.rights_reviewed OR v_old.locale_reviewed OR v_old.academic_qa_passed
  OR v_old.approved_at IS NOT NULL
  OR private.iclub_ai_v21_source_admitted_v1(v_old)
  OR v_old.target_hash IS DISTINCT FROM
    private.iclub_ai_v21_target_fingerprint_v1('practice_error',p_question_id)
  OR v_old.content_hash<>encode(extensions.digest(
    convert_to(v_old.body_text,'UTF8'),'sha256'),'hex')
  OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_owner_beta_source_releases r
      WHERE r.source_card_key=v_old.source_card_key)
  OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_owner_beta_releases r
      WHERE r.source_card_key=v_old.source_card_key)
  OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_academic_deliveries d
      WHERE d.source_card_key=v_old.source_card_key
         OR (d.subject_key=p_subject_key AND d.context_key=v_key))
  THEN RAISE EXCEPTION 'Source has academic history, release, integrity drift or privileges; cannot stage'; END IF;

  -- Version-specific new key, cannot collide with the archived source key.
  v_new_key:='iclub_qrev_'||encode(extensions.digest(convert_to(
    p_subject_key||':'||p_question_id||':'||v_locale||':'||p_new_version,'UTF8'),
    'sha256'),'hex');

  INSERT INTO private.iclub_ai_v21_source_revision_archive(
   source_card_key,surface_code,subject_key,context_key,locale,
   source_version,publication_revision,body_text,content_hash,target_hash,
   superseded_by_version,replaced_by_source_key,revision_note)
  VALUES(v_old.source_card_key,v_old.surface_code,v_old.subject_key,
   v_old.context_key,v_old.locale,v_old.source_version,v_old.publication_revision,
   v_old.body_text,v_old.content_hash,v_old.target_hash,p_new_version,v_new_key,p_note);
  UPDATE private.iclub_ai_v21_academic_sources s SET
   source_card_key=v_new_key,
   source_version=p_new_version,
   publication_revision=v_old.publication_revision+1,
   body_text=v_content,
   content_hash=encode(extensions.digest(convert_to(v_content,'UTF8'),'sha256'),'hex'),
   content_reviewed=false,rights_reviewed=false,locale_reviewed=false,
   academic_qa_passed=false,published=false,revoked=true,approved_at=NULL
  WHERE s.surface_code='practice_error' AND s.subject_key=p_subject_key
   AND s.context_key=v_key AND s.locale=v_locale;
  v_count:=v_count+1;
 END LOOP;
 IF v_count<>3 THEN RAISE EXCEPTION 'Incomplete academic revision'; END IF;
 RETURN v_count;
END $stage$;
REVOKE ALL ON FUNCTION private.iclub_ai_v21_stage_three_locale_revision_v1(
 text,bigint,text,text,jsonb,text)
 FROM PUBLIC,anon,authenticated,service_role;
-- No GRANT to client, no publish or owner-beta release in this file.
