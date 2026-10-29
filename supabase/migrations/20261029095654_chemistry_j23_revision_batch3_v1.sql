-- Chemistry J23 closed revision: restore omitted homogeneous/heterogeneous catalysis in Uzbek.
-- New record only; original theory and existing revision hashes stay immutable.
BEGIN;
SET LOCAL lock_timeout='4s';
DO $patch$
DECLARE v_base private.iclub_subject_library_theory%ROWTYPE;
 v_locales jsonb;
 v_old text := 'Bir xil haroratda to‘g‘ri va teskari reaksiyalarni tezlashtiradi, lekin reaksiya entalpiyasi yoki muvozanat doimiysini o‘zgartirmaydi.';
 v_new text := 'Bir xil haroratda to‘g‘ri va teskari reaksiyalarni tezlashtiradi, lekin reaksiya entalpiyasi yoki muvozanat doimiysini o‘zgartirmaydi. Gomogen katalizda katalizator va reagentlar bir xil fazada, geterogen katalizda esa turli fazalarda bo‘ladi.';
BEGIN
 SELECT * INTO v_base FROM private.iclub_subject_library_theory
 WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft'
 AND skill_key='CHEM9701-08-03';
 IF NOT FOUND THEN RAISE EXCEPTION 'J23 catalyst source missing'; END IF;
 IF (length(v_base.locales->'uz'->>'explanation')-
     length(replace(v_base.locales->'uz'->>'explanation',v_old,'')))/length(v_old)<>1
 THEN RAISE EXCEPTION 'J23 catalyst correction anchor mismatch'; END IF;
 v_locales:=jsonb_set(v_base.locales,'{uz,explanation}',to_jsonb(replace(v_base.locales->'uz'->>'explanation',v_old,v_new)),false);
 INSERT INTO private.iclub_exam_chemistry_j23_theory_revisions_v1
 (revision_key,skill_key,base_version,base_content_hash,revised_locales,revision_sha256)
 VALUES ('chemistry9701_j23_20261029_revision_v1',v_base.skill_key,v_base.version_key,v_base.content_hash,
 v_locales,'sha256:'||encode(digest(jsonb_build_object('skill_key',v_base.skill_key,'locales',v_locales)::text,'sha256'),'hex'))
 ON CONFLICT DO NOTHING;
 IF NOT FOUND THEN RAISE EXCEPTION 'J23 correction already exists, do not overwrite'; END IF;
END $patch$;
COMMIT;
