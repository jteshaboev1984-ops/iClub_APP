-- 21 Sep 2026 | P5 publication language/notation inventory | READ ONLY.
-- Does not return protected item bodies, choices, answer keys, or learner identifiers.
-- Run in an authorized read-only environment. Existing known baseline: 252 unique
-- published P5 question rows, 10 copied-prose MCQs, 7 malformed RU Bin notations,
-- 7 items retaining specific English technical phrases. These counts are findings,
-- NOT acceptance thresholds: after reviewed fixes, affected counts should be zero.
-- This heuristic does NOT prove all content is reviewed. #137 / #139 / #126.
BEGIN READ ONLY;
WITH p5 AS (
  SELECT DISTINCT q.id,q.qtype,q.question_text_ru AS ru_stem,
         q.question_text_uz AS uz_stem,
         q.options_text_en::jsonb AS en_opt,
         q.options_text_ru::jsonb AS ru_opt,
         q.options_text_uz::jsonb AS uz_opt
  FROM private.exam_prep_assessment_items ai
  JOIN private.exam_prep_assessments a ON a.id=ai.assessment_id
  JOIN public.questions q ON q.id=ai.question_id
  WHERE a.component_code='P5' AND a.status='published'
), prose_copy AS (
  SELECT p.id
  FROM p5 p
  CROSS JOIN LATERAL jsonb_array_elements_text(p.en_opt)
    WITH ORDINALITY AS e(opt,ord)
  WHERE p.qtype='mcq'
    AND regexp_replace(
      regexp_replace(lower(e.opt),
        '\m(bin|geom|geometric|normal|n)\s*\([^)]*\)', '', 'g'),
      '\m(a|b|c|d|e|f|h|i|j|k|m|n|p|q|r|s|t|u|v|w|x|y|z|mu|sigma|iqr|sd|sqrt|sin|cos|tan|ln|log|pi|hh|ht|th|tt|na)\M',
      '', 'g'
    ) ~ '[a-z]{3,}'
    AND (
      lower(trim(e.opt))=lower(trim(p.ru_opt->>(e.ord::integer-1)))
      OR lower(trim(e.opt))=lower(trim(p.uz_opt->>(e.ord::integer-1)))
    )
), bin_malformed AS (
  SELECT id FROM p5
  WHERE ru_stem ~ '\mBin\([[:digit:]]+,0,[[:digit:]]+'
     OR ru_opt::text ~ '\mBin\([[:digit:]]+,0,[[:digit:]]+'
), untranslated AS (
  SELECT id FROM p5
  WHERE ru_stem ILIKE '%normal approximation%'
     OR uz_stem ILIKE '%normal approximation%'
     OR ru_stem ILIKE '%continuity correction%'
     OR uz_stem ILIKE '%continuity correction%'
)
SELECT
  (SELECT count(*) FROM p5) AS published_membership_unique_questions,
  (SELECT count(DISTINCT id) FROM prose_copy) AS copied_prose_question_count,
  (SELECT array_agg(DISTINCT id ORDER BY id) FROM prose_copy) AS copied_prose_ids,
  (SELECT count(DISTINCT id) FROM bin_malformed) AS ambiguous_bin_notation_count,
  (SELECT array_agg(DISTINCT id ORDER BY id) FROM bin_malformed) AS bin_notation_ids,
  (SELECT count(DISTINCT id) FROM untranslated) AS untranslated_nor_terms_count,
  (SELECT array_agg(DISTINCT id ORDER BY id) FROM untranslated) AS untranslated_ids;
COMMIT;
