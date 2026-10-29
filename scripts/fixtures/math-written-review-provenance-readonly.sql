-- Mathematics P1/P5 written criteria: review-evidence inventory.
-- SELECT ONLY. No English/rule translations, learner IDs, or reviewer IDs leave the DB.
-- A metadata PASS cannot establish that a human independently reviewed a rule.
-- Historical approved records are immutable; do not rewrite them for this audit.
WITH eligible_rules AS (
 SELECT wt.component_code,wt.id AS task_id,wt.task_version,
        criterion.value->>'id' AS criterion_id,
        md5(criterion.value->>'rule') AS source_md5
 FROM private.exam_prep_written_tasks wt
 CROSS JOIN LATERAL jsonb_array_elements(wt.rubric_json->'criteria') criterion(value)
 WHERE wt.component_code IN ('P1','P5')
   AND wt.lifecycle_state='published'
   AND wt.qa_math_status='pass'
   AND wt.qa_language_status='pass'
   AND wt.qa_technical_status='pass'
),
joined AS (
 SELECT e.component_code,e.task_id,lang.language,
        coalesce(loc.review_state='approved' AND loc.source_rule_md5=e.source_md5,false) AS checksum_approved,
        coalesce(loc.academic_review_ref=loc.language_review_ref,false) AS same_review_ref,
        coalesce(loc.academic_review_ref LIKE 'OWNER_DIRECTED_AI_ASSISTED%' OR
                 loc.language_review_ref LIKE 'OWNER_DIRECTED_AI_ASSISTED%',false) AS ai_assisted_ref,
        loc.academic_review_ref IS NOT NULL
          AND loc.language_review_ref IS NOT NULL
          AND loc.reviewed_at IS NOT NULL AS metadata_present
 FROM eligible_rules e
 CROSS JOIN (VALUES('ru'::text),('uz'::text)) lang(language)
 LEFT JOIN private.exam_prep_written_criteria_locale_v1 loc
 ON loc.written_task_id=e.task_id AND loc.task_version=e.task_version
 AND loc.criterion_id=e.criterion_id AND loc.language=lang.language
)
SELECT component_code,language,count(DISTINCT task_id) AS published_tasks,count(*) AS expected_criteria,
 count(*) FILTER(WHERE checksum_approved) AS checksum_approved,
 count(*) FILTER(WHERE NOT checksum_approved) AS missing_or_stale,
 count(*) FILTER(WHERE checksum_approved AND same_review_ref) AS same_review_ref,
 count(*) FILTER(WHERE checksum_approved AND ai_assisted_ref) AS owner_ai_assisted_ref,
 count(*) FILTER(WHERE checksum_approved AND NOT metadata_present) AS missing_review_metadata,
 CASE WHEN count(*) FILTER(WHERE NOT checksum_approved)>0 THEN 'TECHNICAL_COVERAGE_INCOMPLETE'
      WHEN count(*) FILTER(WHERE checksum_approved AND (same_review_ref OR ai_assisted_ref))>0 THEN 'REVIEW_PROVENANCE_UNVERIFIED'
      ELSE 'METADATA_ONLY_PASS_NOT_HUMAN_SIGNOFF' END AS evidence_gate
FROM joined
GROUP BY component_code,language
ORDER BY component_code,language;
