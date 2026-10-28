-- J23 Chemistry 9701 academic source inventory (read only, no question stems/keys or learner PII).
-- Intended use: secure metadata checks against live Supabase. Does NOT approve release.
WITH
theory AS (
 SELECT t.*, c.content_hash AS mapped_hash, c.skill_key AS mapped_skill,
        c.tour_no AS mapped_tour, c.syllabus_point AS mapped_syllabus,
        c.level_code
 FROM private.iclub_subject_library_theory t
 LEFT JOIN private.iclub_exam_core_skills_v1 c
   ON c.program_key='chemistry_9701' AND c.skill_key=t.skill_key
 WHERE t.subject_key='chemistry'
   AND t.version_key='chemistry9701_20261022_stageb_draft'
),
tutor AS (
 SELECT z.*,t.content_hash AS theory_hash,t.skill_key AS theory_skill
 FROM private.iclub_subject_library_tutor z
 LEFT JOIN theory t ON z.skill_key=t.skill_key
 WHERE z.subject_key='chemistry'
   AND z.version_key='chemistry9701_20261022_stageb_draft'
),
labs AS (
 SELECT * FROM private.iclub_subject_library_cross_tour_v1
 WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft'
),
entry AS (SELECT * FROM private.iclub_exam_chemistry_entry_preflight_v1),
recheck AS (SELECT * FROM private.iclub_exam_chemistry_recheck_preflight_v1),
p1 AS (SELECT * FROM private.iclub_exam_core_chemistry_p1_item_preflight_v1),
stats AS (
 SELECT
  (SELECT count(*) FROM theory) theory_total,
  (SELECT count(*) FROM theory WHERE level_code='AS') theory_as,
  (SELECT count(*) FROM theory WHERE level_code='A') theory_a,
  (SELECT count(*) FROM theory WHERE mapped_skill IS NULL) unmapped_core,
  (SELECT count(*) FROM theory WHERE content_hash IS DISTINCT FROM mapped_hash OR syllabus_point IS DISTINCT FROM mapped_syllabus OR tour_no IS DISTINCT FROM mapped_tour) theory_core_conflicts,
  (SELECT count(*) FROM theory WHERE (level_code='AS' AND tour_no>5) OR (level_code='A' AND tour_no<=5)) cross_level_tours,
  (SELECT count(*) FROM theory WHERE syllabus_point LIKE '%NO_EXPLICIT%') no_explicit_outcome,
  (SELECT count(*) FROM theory WHERE syllabus_point LIKE '%ENRICHMENT%' OR syllabus_point LIKE '%context only%') enrichment_context,
  (SELECT count(*) FROM theory WHERE length(coalesce(locales->'en'->>'explanation',''))<100 OR length(coalesce(locales->'ru'->>'explanation',''))<100 OR length(coalesce(locales->'uz'->>'explanation',''))<100) theory_short_locales,
  (SELECT count(*) FROM theory WHERE length(coalesce(locales->'en'->>'title',''))<4 OR length(coalesce(locales->'ru'->>'title',''))<4 OR length(coalesce(locales->'uz'->>'title',''))<4) theory_short_titles,
  (SELECT count(*) FROM tutor) tutor_total,
  (SELECT count(*) FROM tutor WHERE theory_skill IS NULL OR source_card_hash IS DISTINCT FROM theory_hash) tutor_orphan_or_stale,
  (SELECT count(DISTINCT(skill_key,locale)) FROM tutor) tutor_distinct_pairs,
  (SELECT count(*) FROM tutor WHERE locale NOT IN ('en','ru','uz') OR length(coalesce(main_explanation,''))<60 OR length(coalesce(simple_explanation,''))<30 OR length(coalesce(alternative_explanation,''))<30 OR length(coalesce(focus_explanation,''))<30) tutor_missing_text,
  (SELECT count(*) FROM labs) lab_total,
  (SELECT count(*) FROM labs WHERE paper_code='P3' AND level_code='AS') lab_p3_as,
  (SELECT count(*) FROM labs WHERE paper_code='P5' AND level_code='A') lab_p5_a,
  (SELECT count(*) FROM labs WHERE state<>'draft') lab_nondraft,
  (SELECT count(*) FROM labs WHERE length(coalesce(locales->'en'->>'explanation',''))<100 OR length(coalesce(locales->'ru'->>'explanation',''))<100 OR length(coalesce(locales->'uz'->>'explanation',''))<100) lab_short_locales,
  (SELECT count(*) FROM entry) entry_count,
  (SELECT count(*) FROM entry WHERE seven_ai_gates AND different_from_p1_selected_skill AND different_from_p1_english_stem AND strictly_unreleased) entry_internal_pass,
  (SELECT count(DISTINCT syllabus_unit) FROM entry) entry_units,
  (SELECT count(*) FROM recheck) recheck_count,
  (SELECT count(*) FROM recheck WHERE seven_internal_ai_reviews AND different_from_entry_stem AND different_from_p1_stem AND unreleased_no_mastery) recheck_internal_pass,
  (SELECT count(DISTINCT syllabus_unit) FROM recheck) recheck_units,
  (SELECT count(*) FROM p1) p1_count,
  (SELECT count(*) FROM p1 WHERE source_hash_valid AND source_id_and_draft_valid AND single_choice_key_format_valid AND paper_format_valid AND all_three_locale_keys AND locales_content_structurally_complete AND no_duplicate_options_in_locale AND no_duplicate_new_english_stem AND no_exact_legacy_english_stem AND direct_p1_skill_exists) p1_structural_pass,
  (SELECT count(*) FROM p1 WHERE documented_review_failures>0) p1_fail_count,
  (SELECT count(*) FROM p1 WHERE documented_review_passes=7) p1_reviewed_seven,
  (SELECT count(*) FROM p1 WHERE can_issue_learner_assessment) p1_issuable,
  (SELECT count(*) FROM private.iclub_exam_chemistry_entry_release_items_v1) entry_release_count,
  (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_release_items_v1) recheck_release_count,
  (SELECT count(*) FROM private.iclub_exam_chemistry_p1_owner_release_items_v1) p1_release_count
)
SELECT test_key, actual_value,expected_value,
 CASE WHEN actual_value=expected_value THEN 'PASS'
      WHEN test_key IN ('theory_explicit_outcome_exception_count',
                        'theory_context_enrichment_count',
                        'p1_failed_item_count',
                        'p1_secure_issuable_count',
                        'entry_release_manifest_count',
                        'recheck_release_manifest_count',
                        'p1_release_manifest_count') THEN 'HOLD'
      ELSE 'FAIL' END AS verdict
FROM stats s
CROSS JOIN LATERAL (VALUES
 ('theory_cards',s.theory_total,154::bigint),
 ('theory_as_cards',s.theory_as,91::bigint),
 ('theory_a_cards',s.theory_a,63::bigint),
 ('theory_missing_canonical_skill',s.unmapped_core,0::bigint),
 ('theory_canonical_hash_syllabus_tour_conflicts',s.theory_core_conflicts,0::bigint),
 ('theory_cross_level_tour_mismatch',s.cross_level_tours,0::bigint),
 ('theory_explicit_outcome_exception_count',s.no_explicit_outcome,0::bigint),
 ('theory_context_enrichment_count',s.enrichment_context,0::bigint),
 ('theory_short_locale_explanations',s.theory_short_locales,0::bigint),
 ('theory_missing_locale_titles',s.theory_short_titles,0::bigint),
 ('tutor_locale_records',s.tutor_total,462::bigint),
 ('tutor_distinct_skill_language_pairs',s.tutor_distinct_pairs,462::bigint),
 ('tutor_orphan_or_source_hash_mismatch',s.tutor_orphan_or_stale,0::bigint),
 ('tutor_incomplete_explanation_fields',s.tutor_missing_text,0::bigint),
 ('lab_cards',s.lab_total,12::bigint),
 ('lab_p3_as_cards',s.lab_p3_as,6::bigint),
 ('lab_p5_a_cards',s.lab_p5_a,6::bigint),
 ('lab_non_draft_cards',s.lab_nondraft,0::bigint),
 ('lab_short_locale_explanations',s.lab_short_locales,0::bigint),
 ('entry_distinct_units',s.entry_units,22::bigint),
 ('entry_item_count',s.entry_count,22::bigint),
 ('entry_internal_qa_and_independence',s.entry_internal_pass,22::bigint),
 ('recheck_distinct_units',s.recheck_units,22::bigint),
 ('recheck_item_count',s.recheck_count,22::bigint),
 ('recheck_internal_qa_and_independence',s.recheck_internal_pass,22::bigint),
 ('p1_private_drafts',s.p1_count,45::bigint),
 ('p1_structure_only_pass',s.p1_structural_pass,45::bigint),
 ('p1_reviewed_seven_checks',s.p1_reviewed_seven,45::bigint),
 ('p1_failed_item_count',s.p1_fail_count,0::bigint),
 ('p1_secure_issuable_count',s.p1_issuable,40::bigint),
 ('entry_release_manifest_count',s.entry_release_count,22::bigint),
 ('recheck_release_manifest_count',s.recheck_release_count,22::bigint),
 ('p1_release_manifest_count',s.p1_release_count,40::bigint)
) AS tests(test_key,actual_value,expected_value)
ORDER BY test_key;