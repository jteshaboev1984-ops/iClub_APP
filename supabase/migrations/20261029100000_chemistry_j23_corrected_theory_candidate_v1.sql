-- Chemistry 9701 J23 editor fixes (closed candidate, NOT a release/learner feed).
-- Immutable source 20261022 unchanged; no edits to original mastery/attempt/content hashes.
-- This records full corrected EN/RU/UZ locale content plus a new revision payload digest.
-- NOTE revision_sha256 is a candidate payload audit digest, NOT the original
-- 6-field subject-release-packager content_hash. A full canonical source
-- package with its 6 content fields must be generated before academic approval.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='30s';
CREATE TABLE IF NOT EXISTS private.iclub_exam_chemistry_j23_theory_revisions_v1 (
 revision_key text NOT NULL,
 skill_key text NOT NULL,
 base_version text NOT NULL,
 base_content_hash text NOT NULL CHECK (base_content_hash ~ '^sha256:[0-9a-f]{64}$'),
 revised_locales jsonb NOT NULL CHECK (jsonb_typeof(revised_locales)='object' AND revised_locales ?& ARRAY['en','ru','uz']),
 revision_sha256 text NOT NULL CHECK (revision_sha256 ~ '^sha256:[0-9a-f]{64}$'),
 review_status text NOT NULL DEFAULT 'needs_academic_signoff'
   CHECK (review_status IN ('needs_academic_signoff','approved_for_packaging','rejected')),
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY (revision_key,skill_key)
 -- This candidate table deliberately has no learner access or FK to user data.
);
ALTER TABLE private.iclub_exam_chemistry_j23_theory_revisions_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j23_theory_revisions_v1 FROM PUBLIC,anon,authenticated;
DO $j23$
DECLARE v_base private.iclub_subject_library_theory%ROWTYPE; v_locales jsonb;
BEGIN
  SELECT * INTO v_base FROM private.iclub_subject_library_theory
   WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft'
   AND skill_key='CHEM9701-01-02' AND content_hash='sha256:2827061a23601af06b7ef23397b246be3812513a59acdeda5ce859e238553d67';
  IF NOT FOUND THEN RAISE EXCEPTION 'J23 base mismatch: CHEM9701-01-02'; END IF;
  v_locales := v_base.locales;
  IF (v_locales #>> '{ru,explanation}') IS NULL OR (length((v_locales #>> '{ru,explanation}'))-length(replace((v_locales #>> '{ru,explanation}'),'Изотопы имеют одинаковое число протонов, но разное число нейтронов.','')))/length('Изотопы имеют одинаковое число протонов, но разное число нейтронов.') <> 1
   THEN RAISE EXCEPTION 'J23 patch anchor mismatch: CHEM9701-01-02/ru/explanation'; END IF;
  v_locales := jsonb_set(v_locales,'{ru,explanation}',to_jsonb(replace((v_locales #>> '{ru,explanation}'),'Изотопы имеют одинаковое число протонов, но разное число нейтронов.','Изотопы имеют одинаковое число протонов, но разное число нейтронов. Масс-спектр показывает массы изотопов и их относительную распространённость; по этим данным рассчитывают относительную атомную массу.')),false);
  IF (v_locales #>> '{uz,explanation}') IS NULL OR (length((v_locales #>> '{uz,explanation}'))-length(replace((v_locales #>> '{uz,explanation}'),'Izotoplarda protonlar soni bir xil, neytronlar soni esa turlicha bo‘ladi.','')))/length('Izotoplarda protonlar soni bir xil, neytronlar soni esa turlicha bo‘ladi.') <> 1
   THEN RAISE EXCEPTION 'J23 patch anchor mismatch: CHEM9701-01-02/uz/explanation'; END IF;
  v_locales := jsonb_set(v_locales,'{uz,explanation}',to_jsonb(replace((v_locales #>> '{uz,explanation}'),'Izotoplarda protonlar soni bir xil, neytronlar soni esa turlicha bo‘ladi.','Izotoplarda protonlar soni bir xil, neytronlar soni esa turlicha bo‘ladi. Mass-spektr izotoplarning massalari va nisbiy ulushlarini ko‘rsatadi; shu ma’lumotlardan nisbiy atom massa hisoblanadi.')),false);
  INSERT INTO private.iclub_exam_chemistry_j23_theory_revisions_v1
     (revision_key,skill_key,base_version,base_content_hash,revised_locales,revision_sha256)
   VALUES ('chemistry9701_j23_20261029_revision_v1',v_base.skill_key,v_base.version_key,v_base.content_hash,
           v_locales,'sha256:'||encode(digest(jsonb_build_object('skill_key',v_base.skill_key,'locales',v_locales)::text,'sha256'),'hex'))
   ON CONFLICT (revision_key,skill_key) DO NOTHING;
   IF NOT FOUND THEN RAISE EXCEPTION 'J23 revision already exists; inspect instead of overwriting: CHEM9701-01-02'; END IF;

  SELECT * INTO v_base FROM private.iclub_subject_library_theory
   WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft'
   AND skill_key='CHEM9701-01-03' AND content_hash='sha256:dde744fca6ad75dc097671c13d83cdac77be2e5abf6b0899271af6936d9cd78c';
  IF NOT FOUND THEN RAISE EXCEPTION 'J23 base mismatch: CHEM9701-01-03'; END IF;
  v_locales := v_base.locales;
  IF (v_locales #>> '{uz,explanation}') IS NULL OR (length((v_locales #>> '{uz,explanation}'))-length(replace((v_locales #>> '{uz,explanation}'),'p-orbital yadrodan ikki tomonga yo‘nalgan ikki bo‘lakdan iborat;','')))/length('p-orbital yadrodan ikki tomonga yo‘nalgan ikki bo‘lakdan iborat;') <> 1
   THEN RAISE EXCEPTION 'J23 patch anchor mismatch: CHEM9701-01-03/uz/explanation'; END IF;
  v_locales := jsonb_set(v_locales,'{uz,explanation}',to_jsonb(replace((v_locales #>> '{uz,explanation}'),'p-orbital yadrodan ikki tomonga yo‘nalgan ikki bo‘lakdan iborat;','p-orbital yadro orqali o‘tuvchi tugun tekisligi bilan ajralgan, ikki qarama-qarshi bo‘lakdan iborat;')),false);
  INSERT INTO private.iclub_exam_chemistry_j23_theory_revisions_v1
     (revision_key,skill_key,base_version,base_content_hash,revised_locales,revision_sha256)
   VALUES ('chemistry9701_j23_20261029_revision_v1',v_base.skill_key,v_base.version_key,v_base.content_hash,
           v_locales,'sha256:'||encode(digest(jsonb_build_object('skill_key',v_base.skill_key,'locales',v_locales)::text,'sha256'),'hex'))
   ON CONFLICT (revision_key,skill_key) DO NOTHING;
   IF NOT FOUND THEN RAISE EXCEPTION 'J23 revision already exists; inspect instead of overwriting: CHEM9701-01-03'; END IF;

  SELECT * INTO v_base FROM private.iclub_subject_library_theory
   WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft'
   AND skill_key='CHEM9701-06-03' AND content_hash='sha256:98fcaa424c002f0c22ea0fd8bcd8687190959ffa64d1d20dc644c910cb6464ea';
  IF NOT FOUND THEN RAISE EXCEPTION 'J23 base mismatch: CHEM9701-06-03'; END IF;
  v_locales := v_base.locales;
  IF (v_locales #>> '{ru,explanation}') IS NULL OR (length((v_locales #>> '{ru,explanation}'))-length(replace((v_locales #>> '{ru,explanation}'),'Не используйте продукт Mn²⁺ для кислой среды без проверки условий.','')))/length('Не используйте продукт Mn²⁺ для кислой среды без проверки условий.') <> 1
   THEN RAISE EXCEPTION 'J23 patch anchor mismatch: CHEM9701-06-03/ru/explanation'; END IF;
  v_locales := jsonb_set(v_locales,'{ru,explanation}',to_jsonb(replace((v_locales #>> '{ru,explanation}'),'Не используйте продукт Mn²⁺ для кислой среды без проверки условий.','Не переносите продукт Mn²⁺, характерный для кислой среды, в уравнение для щелочной среды без учёта условий реакции.')),false);
  INSERT INTO private.iclub_exam_chemistry_j23_theory_revisions_v1
     (revision_key,skill_key,base_version,base_content_hash,revised_locales,revision_sha256)
   VALUES ('chemistry9701_j23_20261029_revision_v1',v_base.skill_key,v_base.version_key,v_base.content_hash,
           v_locales,'sha256:'||encode(digest(jsonb_build_object('skill_key',v_base.skill_key,'locales',v_locales)::text,'sha256'),'hex'))
   ON CONFLICT (revision_key,skill_key) DO NOTHING;
   IF NOT FOUND THEN RAISE EXCEPTION 'J23 revision already exists; inspect instead of overwriting: CHEM9701-06-03'; END IF;

  SELECT * INTO v_base FROM private.iclub_subject_library_theory
   WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft'
   AND skill_key='CHEM9701-10-02' AND content_hash='sha256:11a05fa3b6a9e5f02e6b0b4c85858e77d396d134c26671259aeabe6ae975d07b';
  IF NOT FOUND THEN RAISE EXCEPTION 'J23 base mismatch: CHEM9701-10-02'; END IF;
  v_locales := v_base.locales;
  IF (v_locales #>> '{ru,title}') IS NULL OR (length((v_locales #>> '{ru,title}'))-length(replace((v_locales #>> '{ru,title}'),'Растворимость солей второй группы','')))/length('Растворимость солей второй группы') <> 1
   THEN RAISE EXCEPTION 'J23 patch anchor mismatch: CHEM9701-10-02/ru/title'; END IF;
  v_locales := jsonb_set(v_locales,'{ru,title}',to_jsonb(replace((v_locales #>> '{ru,title}'),'Растворимость солей второй группы','Растворимость гидроксидов и сульфатов элементов группы 2')),false);
  IF (v_locales #>> '{uz,title}') IS NULL OR (length((v_locales #>> '{uz,title}'))-length(replace((v_locales #>> '{uz,title}'),'Ikkinchi guruh tuzlarining eruvchanligi','')))/length('Ikkinchi guruh tuzlarining eruvchanligi') <> 1
   THEN RAISE EXCEPTION 'J23 patch anchor mismatch: CHEM9701-10-02/uz/title'; END IF;
  v_locales := jsonb_set(v_locales,'{uz,title}',to_jsonb(replace((v_locales #>> '{uz,title}'),'Ikkinchi guruh tuzlarining eruvchanligi','2-guruh gidroksidlari va sulfatlarining eruvchanligi')),false);
  IF (v_locales #>> '{ru,explanation}') IS NULL OR (length((v_locales #>> '{ru,explanation}'))-length(replace((v_locales #>> '{ru,explanation}'),'Тема: Растворимость солей второй группы.','')))/length('Тема: Растворимость солей второй группы.') <> 1
   THEN RAISE EXCEPTION 'J23 patch anchor mismatch: CHEM9701-10-02/ru/explanation'; END IF;
  v_locales := jsonb_set(v_locales,'{ru,explanation}',to_jsonb(replace((v_locales #>> '{ru,explanation}'),'Тема: Растворимость солей второй группы.','Тема: Растворимость гидроксидов и сульфатов элементов группы 2.')),false);
  IF (v_locales #>> '{uz,explanation}') IS NULL OR (length((v_locales #>> '{uz,explanation}'))-length(replace((v_locales #>> '{uz,explanation}'),'Mavzu: Ikkinchi guruh tuzlarining eruvchanligi.','')))/length('Mavzu: Ikkinchi guruh tuzlarining eruvchanligi.') <> 1
   THEN RAISE EXCEPTION 'J23 patch anchor mismatch: CHEM9701-10-02/uz/explanation'; END IF;
  v_locales := jsonb_set(v_locales,'{uz,explanation}',to_jsonb(replace((v_locales #>> '{uz,explanation}'),'Mavzu: Ikkinchi guruh tuzlarining eruvchanligi.','Mavzu: 2-guruh gidroksidlari va sulfatlarining eruvchanligi.')),false);
  INSERT INTO private.iclub_exam_chemistry_j23_theory_revisions_v1
     (revision_key,skill_key,base_version,base_content_hash,revised_locales,revision_sha256)
   VALUES ('chemistry9701_j23_20261029_revision_v1',v_base.skill_key,v_base.version_key,v_base.content_hash,
           v_locales,'sha256:'||encode(digest(jsonb_build_object('skill_key',v_base.skill_key,'locales',v_locales)::text,'sha256'),'hex'))
   ON CONFLICT (revision_key,skill_key) DO NOTHING;
   IF NOT FOUND THEN RAISE EXCEPTION 'J23 revision already exists; inspect instead of overwriting: CHEM9701-10-02'; END IF;

END $j23$;
COMMIT;