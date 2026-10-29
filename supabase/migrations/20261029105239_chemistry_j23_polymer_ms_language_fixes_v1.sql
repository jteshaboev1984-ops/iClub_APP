-- J23 closed content candidate: correct polymer disposal titles and missing UZ absent M+ ion detail.
-- Changes no learners, existing content or AS access flags.
BEGIN;
SET LOCAL lock_timeout='4s';
DO $fix$
DECLARE v_base private.iclub_subject_library_theory%ROWTYPE; v_locale jsonb;
BEGIN
SELECT * INTO v_base FROM private.iclub_subject_library_theory WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft' AND skill_key='CHEM9701-20-03';
IF NOT FOUND THEN RAISE EXCEPTION 'J23 missing original CHEM9701-20-03'; END IF;
v_locale:=v_base.locales;
IF (length((v_locale #>> '{ru,title}'))-length(replace((v_locale #>> '{ru,title}'),'Свойства и переработка полимеров','')))/length('Свойства и переработка полимеров')<>1 THEN RAISE EXCEPTION 'J23 correction anchor CHEM9701-20-03/ru/title mismatch'; END IF;
v_locale:=jsonb_set(v_locale,'{ru,title}',to_jsonb(replace((v_locale #>> '{ru,title}'),'Свойства и переработка полимеров','Свойства и утилизация полимеров')),false);
IF (length((v_locale #>> '{ru,explanation}'))-length(replace((v_locale #>> '{ru,explanation}'),'Тема: Свойства и переработка полимеров','')))/length('Тема: Свойства и переработка полимеров')<>1 THEN RAISE EXCEPTION 'J23 correction anchor CHEM9701-20-03/ru/explanation mismatch'; END IF;
v_locale:=jsonb_set(v_locale,'{ru,explanation}',to_jsonb(replace((v_locale #>> '{ru,explanation}'),'Тема: Свойства и переработка полимеров','Тема: Свойства и утилизация полимеров')),false);
IF (length((v_locale #>> '{uz,title}'))-length(replace((v_locale #>> '{uz,title}'),'Polimer xossalari va qayta ishlash','')))/length('Polimer xossalari va qayta ishlash')<>1 THEN RAISE EXCEPTION 'J23 correction anchor CHEM9701-20-03/uz/title mismatch'; END IF;
v_locale:=jsonb_set(v_locale,'{uz,title}',to_jsonb(replace((v_locale #>> '{uz,title}'),'Polimer xossalari va qayta ishlash','Polimer xossalari va chiqindilarini boshqarish')),false);
IF (length((v_locale #>> '{uz,explanation}'))-length(replace((v_locale #>> '{uz,explanation}'),'Mavzu: Polimer xossalari va qayta ishlash','')))/length('Mavzu: Polimer xossalari va qayta ishlash')<>1 THEN RAISE EXCEPTION 'J23 correction anchor CHEM9701-20-03/uz/explanation mismatch'; END IF;
v_locale:=jsonb_set(v_locale,'{uz,explanation}',to_jsonb(replace((v_locale #>> '{uz,explanation}'),'Mavzu: Polimer xossalari va qayta ishlash','Mavzu: Polimer xossalari va chiqindilarini boshqarish')),false);
INSERT INTO private.iclub_exam_chemistry_j23_theory_revisions_v1
(revision_key,skill_key,base_version,base_content_hash,revised_locales,revision_sha256)
VALUES ('chemistry9701_j23_20261029_revision_v1',v_base.skill_key,v_base.version_key,v_base.content_hash,v_locale,
'sha256:'||encode(digest(jsonb_build_object('skill_key',v_base.skill_key,'locales',v_locale)::text,'sha256'),'hex'))
ON CONFLICT DO NOTHING;
IF NOT FOUND THEN RAISE EXCEPTION 'J23 revision CHEM9701-20-03 already exists, do not overwrite'; END IF;

SELECT * INTO v_base FROM private.iclub_subject_library_theory WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft' AND skill_key='CHEM9701-22-02';
IF NOT FOUND THEN RAISE EXCEPTION 'J23 missing original CHEM9701-22-02'; END IF;
v_locale:=v_base.locales;
IF (length((v_locale #>> '{uz,explanation}'))-length(replace((v_locale #>> '{uz,explanation}'),'fragment cho‘qqilari alohida va molekulyar cho‘qqi kuchsiz bo‘lishi mumkin.','')))/length('fragment cho‘qqilari alohida va molekulyar cho‘qqi kuchsiz bo‘lishi mumkin.')<>1 THEN RAISE EXCEPTION 'J23 correction anchor CHEM9701-22-02/uz/explanation mismatch'; END IF;
v_locale:=jsonb_set(v_locale,'{uz,explanation}',to_jsonb(replace((v_locale #>> '{uz,explanation}'),'fragment cho‘qqilari alohida va molekulyar cho‘qqi kuchsiz bo‘lishi mumkin.','fragment cho‘qqilari alohida bo‘ladi; molekulyar ion cho‘qqisi ba’zi spektrlarda kuchsiz bo‘lishi yoki umuman kuzatilmasligi mumkin.')),false);
INSERT INTO private.iclub_exam_chemistry_j23_theory_revisions_v1
(revision_key,skill_key,base_version,base_content_hash,revised_locales,revision_sha256)
VALUES ('chemistry9701_j23_20261029_revision_v1',v_base.skill_key,v_base.version_key,v_base.content_hash,v_locale,
'sha256:'||encode(digest(jsonb_build_object('skill_key',v_base.skill_key,'locales',v_locale)::text,'sha256'),'hex'))
ON CONFLICT DO NOTHING;
IF NOT FOUND THEN RAISE EXCEPTION 'J23 revision CHEM9701-22-02 already exists, do not overwrite'; END IF;

END $fix$;
COMMIT;