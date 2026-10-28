-- J23 AS Theory trilingual numeric/chemical-token parity heuristic (READ ONLY).
-- Uses 91 AS cards; returns keys and token differences, NEVER source explanations.
-- A difference is TRIAGE, not proof that the translation is wrong:
-- different locale annotations, optional examples and notation can legitimately differ.
WITH src AS (
 SELECT t.skill_key, lang.locale, lang.explanation
 FROM private.iclub_subject_library_theory t
 JOIN private.iclub_exam_core_skills_v1 c
   ON c.program_key='chemistry_9701' AND c.skill_key=t.skill_key AND c.level_code='AS'
 CROSS JOIN LATERAL (VALUES
  ('en', t.locales->'en'->>'explanation'),
  ('ru', t.locales->'ru'->>'explanation'),
  ('uz', t.locales->'uz'->>'explanation')
 ) lang(locale,explanation)
 WHERE t.subject_key='chemistry' AND t.version_key='chemistry9701_20261022_stageb_draft'
),
numeric_tokens AS (
 SELECT src.skill_key,src.locale,
        array_agg(DISTINCT replace(m.val[1],',','.') ORDER BY replace(m.val[1],',','.')) tokens
 FROM src
 LEFT JOIN LATERAL regexp_matches(
   translate(coalesce(src.explanation,''),
     '₀₁₂₃₄₅₆₇₈₉⁰¹²³⁴⁵⁶⁷⁸⁹',
     '01234567890123456789'),
   '[0-9]+([.,][0-9]+)?','g'
 ) AS m(val) ON true
 GROUP BY src.skill_key,src.locale
),
pairwise AS (
 SELECT en.skill_key,en.tokens AS en_tokens,ru.tokens AS ru_tokens,uz.tokens AS uz_tokens
 FROM numeric_tokens en
 JOIN numeric_tokens ru ON ru.skill_key=en.skill_key AND ru.locale='ru'
 JOIN numeric_tokens uz ON uz.skill_key=en.skill_key AND uz.locale='uz'
 WHERE en.locale='en'
),
diff AS (
 SELECT skill_key,
  ARRAY(SELECT DISTINCT x FROM unnest(en_tokens) x EXCEPT SELECT DISTINCT x FROM unnest(ru_tokens) x ORDER BY 1) missing_in_ru,
  ARRAY(SELECT DISTINCT x FROM unnest(en_tokens) x EXCEPT SELECT DISTINCT x FROM unnest(uz_tokens) x ORDER BY 1) missing_in_uz,
  ARRAY(SELECT DISTINCT x FROM unnest(ru_tokens) x EXCEPT SELECT DISTINCT x FROM unnest(en_tokens) x ORDER BY 1) additional_ru,
  ARRAY(SELECT DISTINCT x FROM unnest(uz_tokens) x EXCEPT SELECT DISTINCT x FROM unnest(en_tokens) x ORDER BY 1) additional_uz
 FROM pairwise
)
SELECT skill_key,CASE WHEN cardinality(missing_in_ru)+cardinality(missing_in_uz)
                       +cardinality(additional_ru)+cardinality(additional_uz)=0
                      THEN 'TOKEN_PARITY'
                      ELSE 'MANUAL_REVIEW' END AS verdict,
 missing_in_ru,missing_in_uz,additional_ru,additional_uz
FROM diff ORDER BY verdict DESC,skill_key;