-- LIVE read-only language and option structure parity for current P1 calculus sources.
WITH src AS (
 SELECT m.content_key k,q.qtype,q.question_text_en en,q.question_text_ru ru,q.question_text_uz uz,
   q.options_text_en::jsonb oe,q.options_text_ru::jsonb oru,q.options_text_uz::jsonb ouz,
   q.explanation_en ee,q.explanation_ru er,q.explanation_uz eu
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions c ON c.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE c.component_code='P1' AND m.lifecycle_state IN ('published','reserve')
 AND (m.primary_skill_code LIKE 'P1-DIF-%' OR m.primary_skill_code LIKE 'P1-INT-%')
), scan AS (
 SELECT k,qtype,
   (en IS NULL OR ru IS NULL OR uz IS NULL OR ee IS NULL OR er IS NULL OR eu IS NULL
     OR btrim(en)='' OR btrim(ru)='' OR btrim(uz)='') bad_locale,
   (jsonb_array_length(oe)<>jsonb_array_length(oru) OR jsonb_array_length(oe)<>jsonb_array_length(ouz)) options_length_mismatch,
   (SELECT count(DISTINCT value)<>4 FROM jsonb_array_elements_text(oe) v(value)) duplicate_en,
   (SELECT count(DISTINCT value)<>4 FROM jsonb_array_elements_text(oru) v(value)) duplicate_ru,
   (SELECT count(DISTINCT value)<>4 FROM jsonb_array_elements_text(ouz) v(value)) duplicate_uz,
   ARRAY(SELECT a[1] FROM regexp_matches(en,'[0-9]+','g') a) <> ARRAY(SELECT a[1] FROM regexp_matches(ru,'[0-9]+','g') a) digit_flag_en_ru,
   ARRAY(SELECT a[1] FROM regexp_matches(en,'[0-9]+','g') a) <> ARRAY(SELECT a[1] FROM regexp_matches(uz,'[0-9]+','g') a) digit_flag_en_uz
 FROM src
)
SELECT count(*) reviewed,
 count(*) FILTER(WHERE bad_locale) bad_locales,
 count(*) FILTER(WHERE options_length_mismatch) option_length_errors,
 count(*) FILTER(WHERE qtype='mcq' AND (duplicate_en OR duplicate_ru OR duplicate_uz)) literal_option_duplicates,
 count(*) FILTER(WHERE digit_flag_en_ru OR digit_flag_en_uz) lexical_numeric_flags,
 jsonb_agg(k) FILTER(WHERE digit_flag_en_ru OR digit_flag_en_uz) lexical_flag_keys
FROM scan;
