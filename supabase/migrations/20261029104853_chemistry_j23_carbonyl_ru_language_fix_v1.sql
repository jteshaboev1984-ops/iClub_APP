-- Correct untranslated Uzbek question opener in Russian carbonyl lesson 17-01.
-- Candidate only, source historical version remains unchanged; no learner access.
BEGIN;
SET LOCAL lock_timeout='4s';
DO $fix$
DECLARE v_base private.iclub_subject_library_theory%ROWTYPE;v_old text;
v_locales jsonb;
BEGIN
 SELECT * INTO v_base FROM private.iclub_subject_library_theory
 WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft'
 AND skill_key='CHEM9701-17-01';
 IF NOT FOUND THEN RAISE EXCEPTION 'J23 original carbonyl source absent'; END IF;
 v_old:=v_base.locales->'ru'->>'explanation';
 IF (length(v_old)-length(replace(v_old,'Nega 2,4-ДНФГ осадок есть, а серебряного зеркала нет: какая карбонильная группа вероятнее?','')))/length('Nega 2,4-ДНФГ осадок есть, а серебряного зеркала нет: какая карбонильная группа вероятнее?')<>1 THEN
   RAISE EXCEPTION 'J23 RU defect text changed; no write';
 END IF;
 v_locales:=jsonb_set(v_base.locales,'{ru,explanation}',to_jsonb(replace(v_old,
  'Nega 2,4-ДНФГ осадок есть, а серебряного зеркала нет: какая карбонильная группа вероятнее?',
  'Если с 2,4-ДНФГ образуется осадок, но серебряного зеркала нет, какой класс карбонильных соединений наиболее вероятен?')),false);
 INSERT INTO private.iclub_exam_chemistry_j23_theory_revisions_v1
 (revision_key,skill_key,base_version,base_content_hash,revised_locales,revision_sha256)
 VALUES ('chemistry9701_j23_20261029_revision_v1',v_base.skill_key,v_base.version_key,v_base.content_hash,
 v_locales,'sha256:'||encode(digest(jsonb_build_object('skill_key',v_base.skill_key,'locales',v_locales)::text,'sha256'),'hex'))
 ON CONFLICT DO NOTHING;
 IF NOT FOUND THEN RAISE EXCEPTION 'J23 revision already exists, no overwrite'; END IF;
END $fix$;
COMMIT;
