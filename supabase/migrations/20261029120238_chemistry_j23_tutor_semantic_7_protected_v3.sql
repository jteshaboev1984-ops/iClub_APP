-- J23 append-only v3: align 7 Tutor locale explanations with independently corrected Theory.
BEGIN;SET LOCAL lock_timeout='4s';
DO $g$ BEGIN
 IF EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v3')
 THEN RAISE EXCEPTION 'Already present';END IF;
END $g$;
INSERT INTO private.iclub_exam_chemistry_j23_as_canonical_candidate_v1
(candidate_version,skill_key,tour_no,syllabus_point,enrichment_only,base_version,base_content_hash,editorial_corrections_applied,locales,canonical_json_compact,content_hash,authoring_status)
SELECT 'chemistry9701_j23_20261029_as_91_sixfield_candidate_v3',skill_key,tour_no,syllabus_point,enrichment_only,base_version,base_content_hash,editorial_corrections_applied,locales,canonical_json_compact,content_hash,authoring_status
FROM private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v2';
WITH patched AS(
 SELECT u.*,
 CASE
 WHEN skill_key='CHEM9701-01-02' AND locale='ru' THEN main_explanation||E'\n\n'||'Масс-спектр показывает массы и относительную распространённость изотопов; Ar находят как средневзвешенное по этим данным.'
 WHEN skill_key='CHEM9701-01-02' AND locale='uz' THEN main_explanation||E'\n\n'||'Mass-spektr izotop massalari va ularning nisbiy ulushlarini ko‘rsatadi; Ar shu ulushlar bilan vaznli o‘rtacha qilib hisoblanadi.'
 WHEN skill_key='CHEM9701-08-03' AND locale='uz' THEN main_explanation||E'\n\n'||'Gomogen katalizda katalizator va reagentlar bir fazada, geterogen katalizda esa turli fazalarda bo‘ladi.'
 WHEN skill_key='CHEM9701-11-01' AND locale='ru' THEN main_explanation||E'\n\n'||'Образование HI из H₂ и I₂ обратимо: H₂(g) + I₂(g) ⇌ 2HI(g).'
 WHEN skill_key='CHEM9701-11-01' AND locale='uz' THEN main_explanation||E'\n\n'||'H₂ va I₂ dan HI hosil bo‘lishi qaytar: H₂(g) + I₂(g) ⇌ 2HI(g).'
 WHEN skill_key='CHEM9701-22-02' AND locale='uz' THEN replace(main_explanation,
 'molekulyar cho‘qqi kuchsiz bo‘lishi mumkin',
 'molekulyar ion cho‘qqisi kuchsiz bo‘lishi yoki ayrim spektrlarda umuman kuzatilmasligi mumkin')
 ELSE main_explanation END AS next_main,
 CASE WHEN skill_key='CHEM9701-17-01' AND locale='ru' THEN replace(focus_explanation,
 'Nega 2,4-ДНФГ осадок есть, а серебряного зеркала нет: какая карбонильная группа вероятнее?',
 'Если с 2,4-ДНФГ образуется осадок, но серебряного зеркала нет, какой класс карбонильных соединений наиболее вероятен?')
 ELSE focus_explanation END AS next_focus
 FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1 u WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v2'
)
INSERT INTO private.iclub_exam_chemistry_j23_as_tutor_candidate_v1
(candidate_version,skill_key,locale,tutor_card_key,base_tutor_content_version,title,main_explanation,simple_explanation,alternative_explanation,focus_explanation,base_tutor_source_hash,source_card_hash,tutor_candidate_digest,review_status)
SELECT 'chemistry9701_j23_20261029_as_91_sixfield_candidate_v3',skill_key,locale,tutor_card_key,base_tutor_content_version,title,
next_main,simple_explanation,alternative_explanation,next_focus,base_tutor_source_hash,source_card_hash,
'sha256:'||encode(extensions.digest(convert_to(jsonb_build_object(
'skill_key',skill_key,'locale',locale,'title',title,'main',next_main,
'simple',simple_explanation,'alternative',alternative_explanation,'focus',next_focus)::text,'UTF8'),'sha256'),'hex'),
review_status FROM patched;
DO $v$ BEGIN
IF (SELECT count(*) FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v3')<>273
THEN RAISE EXCEPTION 'Incomplete v3'; END IF;
END $v$;COMMIT;
