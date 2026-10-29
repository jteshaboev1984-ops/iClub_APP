-- Closed J23 correction batch 2; ONLY candidate data, no Theory source change.
-- Fixes 09-01 RU agreement and 09-04 RU overgeneralised hydrolysis title.
BEGIN;
SET LOCAL lock_timeout='4s';
DO $patch$
DECLARE v_base private.iclub_subject_library_theory%ROWTYPE; v_locales jsonb;
BEGIN
 SELECT * INTO v_base FROM private.iclub_subject_library_theory
 WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft' AND skill_key='CHEM9701-09-01';
 IF NOT FOUND THEN RAISE EXCEPTION 'J23 source not found CHEM9701-09-01'; END IF;
 v_locales:=v_base.locales;
 IF (v_locales #>> '{ru,explanation}') IS NULL OR (length((v_locales #>> '{ru,explanation}')) - length(replace((v_locales #>> '{ru,explanation}'),'из более высокоэнергетической подуровни 3p','')))/length('из более высокоэнергетической подуровни 3p')<>1
 THEN RAISE EXCEPTION 'J23 anchor mismatch for CHEM9701-09-01 {ru,explanation}'; END IF;
 v_locales:=jsonb_set(v_locales,'{ru,explanation}',to_jsonb(replace((v_locales #>> '{ru,explanation}'),'из более высокоэнергетической подуровни 3p','с более высокоэнергетического подуровня 3p')),false);
 INSERT INTO private.iclub_exam_chemistry_j23_theory_revisions_v1
 (revision_key,skill_key,base_version,base_content_hash,revised_locales,revision_sha256)
 VALUES ('chemistry9701_j23_20261029_revision_v1',v_base.skill_key,v_base.version_key,v_base.content_hash,
 v_locales,'sha256:'||encode(digest(jsonb_build_object('skill_key',v_base.skill_key,'locales',v_locales)::text,'sha256'),'hex'))
 ON CONFLICT DO NOTHING;
 IF NOT FOUND THEN RAISE EXCEPTION 'Existing J23 revision must not be overwritten: CHEM9701-09-01'; END IF;

 SELECT * INTO v_base FROM private.iclub_subject_library_theory
 WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft' AND skill_key='CHEM9701-09-04';
 IF NOT FOUND THEN RAISE EXCEPTION 'J23 source not found CHEM9701-09-04'; END IF;
 v_locales:=v_base.locales;
 IF (v_locales #>> '{ru,title}') IS NULL OR (length((v_locales #>> '{ru,title}')) - length(replace((v_locales #>> '{ru,title}'),'Гидролиз хлоридов третьего периода','')))/length('Гидролиз хлоридов третьего периода')<>1
 THEN RAISE EXCEPTION 'J23 anchor mismatch for CHEM9701-09-04 {ru,title}'; END IF;
 v_locales:=jsonb_set(v_locales,'{ru,title}',to_jsonb(replace((v_locales #>> '{ru,title}'),'Гидролиз хлоридов третьего периода','Взаимодействие хлоридов элементов третьего периода с водой')),false);
 IF (v_locales #>> '{ru,explanation}') IS NULL OR (length((v_locales #>> '{ru,explanation}')) - length(replace((v_locales #>> '{ru,explanation}'),'Тема: Гидролиз хлоридов третьего периода.','')))/length('Тема: Гидролиз хлоридов третьего периода.')<>1
 THEN RAISE EXCEPTION 'J23 anchor mismatch for CHEM9701-09-04 {ru,explanation}'; END IF;
 v_locales:=jsonb_set(v_locales,'{ru,explanation}',to_jsonb(replace((v_locales #>> '{ru,explanation}'),'Тема: Гидролиз хлоридов третьего периода.','Тема: Взаимодействие хлоридов элементов третьего периода с водой.')),false);
 INSERT INTO private.iclub_exam_chemistry_j23_theory_revisions_v1
 (revision_key,skill_key,base_version,base_content_hash,revised_locales,revision_sha256)
 VALUES ('chemistry9701_j23_20261029_revision_v1',v_base.skill_key,v_base.version_key,v_base.content_hash,
 v_locales,'sha256:'||encode(digest(jsonb_build_object('skill_key',v_base.skill_key,'locales',v_locales)::text,'sha256'),'hex'))
 ON CONFLICT DO NOTHING;
 IF NOT FOUND THEN RAISE EXCEPTION 'Existing J23 revision must not be overwritten: CHEM9701-09-04'; END IF;

END $patch$;
COMMIT;
