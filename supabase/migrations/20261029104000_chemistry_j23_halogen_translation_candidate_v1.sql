-- Chemistry J23 versioned CLOSED candidate fix of Group 17 H2+I2 reversibility.
BEGIN;
SET LOCAL lock_timeout='4s';
DO $patch$
DECLARE v_base private.iclub_subject_library_theory%ROWTYPE; v_locales jsonb;
BEGIN
 SELECT * INTO v_base FROM private.iclub_subject_library_theory
 WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft'
 AND skill_key='CHEM9701-11-01';
 IF NOT FOUND THEN RAISE EXCEPTION 'J23 original halogen lesson absent'; END IF;
 v_locales:=v_base.locales;
  IF (length((v_locales #>> '{ru,explanation}'))-length(replace((v_locales #>> '{ru,explanation}'),'Фтор с водородом реагирует очень бурно, а для йода нужны более жёсткие условия.','')))/length('Фтор с водородом реагирует очень бурно, а для йода нужны более жёсткие условия.')<>1 THEN
 RAISE EXCEPTION 'J23 11-01 ru translation anchor not found exactly once'; END IF;
 v_locales:=jsonb_set(v_locales,'{ru,explanation}',to_jsonb(replace((v_locales #>> '{ru,explanation}'),'Фтор с водородом реагирует очень бурно, а для йода нужны более жёсткие условия.','Фтор с водородом реагирует очень бурно, а для йода нужны более жёсткие условия; реакция образования HI обратима.')),false);
 IF (length((v_locales #>> '{uz,explanation}'))-length(replace((v_locales #>> '{uz,explanation}'),'Ftor vodorod bilan juda shiddatli reaksiyaga kirishadi; yod uchun kuchliroq sharoit kerak.','')))/length('Ftor vodorod bilan juda shiddatli reaksiyaga kirishadi; yod uchun kuchliroq sharoit kerak.')<>1 THEN
 RAISE EXCEPTION 'J23 11-01 uz translation anchor not found exactly once'; END IF;
 v_locales:=jsonb_set(v_locales,'{uz,explanation}',to_jsonb(replace((v_locales #>> '{uz,explanation}'),'Ftor vodorod bilan juda shiddatli reaksiyaga kirishadi; yod uchun kuchliroq sharoit kerak.','Ftor vodorod bilan juda shiddatli reaksiyaga kirishadi; yod uchun kuchliroq sharoit kerak, HI hosil bo‘lish reaksiyasi esa qaytardir.')),false);
 IF (length((v_locales #>> '{uz,explanation}'))-length(replace((v_locales #>> '{uz,explanation}'),'Galogenlar ikki atomli molekulalardir. Guruh bo‘ylab pastga molekula hajmi, qutblanuvchanlik, London kuchlari va qaynash harorati ortadi.','')))/length('Galogenlar ikki atomli molekulalardir. Guruh bo‘ylab pastga molekula hajmi, qutblanuvchanlik, London kuchlari va qaynash harorati ortadi.')<>1 THEN
 RAISE EXCEPTION 'J23 11-01 uz translation anchor not found exactly once'; END IF;
 v_locales:=jsonb_set(v_locales,'{uz,explanation}',to_jsonb(replace((v_locales #>> '{uz,explanation}'),'Galogenlar ikki atomli molekulalardir. Guruh bo‘ylab pastga molekula hajmi, qutblanuvchanlik, London kuchlari va qaynash harorati ortadi.','Galogenlar ikki atomli molekulalardir. Guruh bo‘ylab pastga molekula hajmi, qutblanuvchanlik, London kuchlari va qaynash harorati ortadi; galogenlarning rangi ham odatda to‘qroq bo‘lib boradi.')),false);

 INSERT INTO private.iclub_exam_chemistry_j23_theory_revisions_v1
  (revision_key,skill_key,base_version,base_content_hash,revised_locales,revision_sha256)
 VALUES ('chemistry9701_j23_20261029_revision_v1',v_base.skill_key,v_base.version_key,v_base.content_hash,
 v_locales,'sha256:'||encode(digest(jsonb_build_object('skill_key',v_base.skill_key,'locales',v_locales)::text,'sha256'),'hex'))
 ON CONFLICT DO NOTHING;
 IF NOT FOUND THEN RAISE EXCEPTION 'J23 original revision already exists'; END IF;
END $patch$;
COMMIT;
