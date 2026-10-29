-- Closed, append-only correction of multi-step AS ester transformations RU/UZ titles.
BEGIN; SET LOCAL lock_timeout='4s';
DO $fix$
DECLARE v_base private.iclub_subject_library_theory%ROWTYPE;v_locale jsonb;
BEGIN
SELECT * INTO v_base FROM private.iclub_subject_library_theory
WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft' AND skill_key='CHEM9701-18-03';
IF NOT FOUND THEN RAISE EXCEPTION 'Source 18-03 missing'; END IF;
v_locale:=v_base.locales;
IF (length((v_locale #>> '{ru,title}'))-length(replace((v_locale #>> '{ru,title}'),'Этерификация и гидролиз эфиров','')))/length('Этерификация и гидролиз эфиров')<>1 THEN RAISE EXCEPTION 'J23 18-03 ru/title anchor mismatch'; END IF;
v_locale:=jsonb_set(v_locale,'{ru,title}',to_jsonb(replace((v_locale #>> '{ru,title}'),'Этерификация и гидролиз эфиров','Многостадийный синтез и превращения сложных эфиров')),false);
IF (length((v_locale #>> '{uz,title}'))-length(replace((v_locale #>> '{uz,title}'),'Esterlanish va ester gidrolizi','')))/length('Esterlanish va ester gidrolizi')<>1 THEN RAISE EXCEPTION 'J23 18-03 uz/title anchor mismatch'; END IF;
v_locale:=jsonb_set(v_locale,'{uz,title}',to_jsonb(replace((v_locale #>> '{uz,title}'),'Esterlanish va ester gidrolizi','Murakkab efirlarning ko‘p bosqichli sintezi va o‘zgarishlari')),false);
IF (length((v_locale #>> '{ru,explanation}'))-length(replace((v_locale #>> '{ru,explanation}'),'Тема: Этерификация и гидролиз эфиров','')))/length('Тема: Этерификация и гидролиз эфиров')<>1 THEN RAISE EXCEPTION 'J23 18-03 ru/explanation anchor mismatch'; END IF;
v_locale:=jsonb_set(v_locale,'{ru,explanation}',to_jsonb(replace((v_locale #>> '{ru,explanation}'),'Тема: Этерификация и гидролиз эфиров','Тема: Многостадийный синтез и превращения сложных эфиров')),false);
IF (length((v_locale #>> '{uz,explanation}'))-length(replace((v_locale #>> '{uz,explanation}'),'Mavzu: Esterlanish va ester gidrolizi','')))/length('Mavzu: Esterlanish va ester gidrolizi')<>1 THEN RAISE EXCEPTION 'J23 18-03 uz/explanation anchor mismatch'; END IF;
v_locale:=jsonb_set(v_locale,'{uz,explanation}',to_jsonb(replace((v_locale #>> '{uz,explanation}'),'Mavzu: Esterlanish va ester gidrolizi','Mavzu: Murakkab efirlarning ko‘p bosqichli sintezi va o‘zgarishlari')),false);

INSERT INTO private.iclub_exam_chemistry_j23_theory_revisions_v1
(revision_key,skill_key,base_version,base_content_hash,revised_locales,revision_sha256)
VALUES ('chemistry9701_j23_20261029_revision_v1',v_base.skill_key,v_base.version_key,v_base.content_hash,v_locale,
 'sha256:'||encode(digest(jsonb_build_object('skill_key',v_base.skill_key,'locales',v_locale)::text,'sha256'),'hex'))
ON CONFLICT DO NOTHING;
IF NOT FOUND THEN RAISE EXCEPTION 'Existing correction 18-03: no overwrite'; END IF;
END $fix$;
COMMIT;