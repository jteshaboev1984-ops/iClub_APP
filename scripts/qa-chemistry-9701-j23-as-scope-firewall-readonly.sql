-- J23 scope/quality release firewall. Read only. No answer keys, student identities or learner changes.
WITH as_theory AS (
 SELECT t.skill_key,t.syllabus_point,t.content_hash,c.level_code,c.content_hash AS core_hash
 FROM private.iclub_subject_library_theory t
 JOIN private.iclub_exam_core_skills_v1 c
   ON c.program_key='chemistry_9701' AND c.skill_key=t.skill_key
 WHERE t.subject_key='chemistry' AND t.version_key='chemistry9701_20261022_stageb_draft'
), truth AS (
 SELECT
  (SELECT count(*) FROM as_theory WHERE level_code='AS') AS_count,
  (SELECT count(*) FROM as_theory WHERE level_code='AS'
     AND syllabus_point <> 'NO_EXPLICIT_9701_OUTCOME') AS_scored_candidates,
  (SELECT count(*) FROM as_theory WHERE level_code='AS'
     AND skill_key='CHEM9701-10-04' AND syllabus_point='NO_EXPLICIT_9701_OUTCOME') AS_enrichment_count,
  (SELECT count(*) FROM as_theory WHERE level_code='A') A_count,
  (SELECT count(*) FROM as_theory WHERE content_hash IS DISTINCT FROM core_hash) hash_drift,
  (SELECT count(*) FROM private.iclub_subject_library_cross_tour_v1
      WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft'
        AND paper_code='P3' AND level_code='AS') P3_as_cards,
  (SELECT count(*) FROM private.iclub_subject_library_cross_tour_v1
      WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft'
        AND paper_code='P5' AND level_code='A') P5_a_cards,
  (SELECT count(*) FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1
      WHERE draft_key='CHEM9701-P1-SECURE4-20261026-T12-02'
        AND authoring_version='iclub_original_private_20261026_v4'
        AND gate_key='syllabus_scope' AND gate_status='fail') original_fail_retained,
  (SELECT count(*) FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1
      WHERE draft_key='CHEM9701-P1-SECURE4-20261026-T12-02'
        AND authoring_version='iclub_original_private_j23_20261028_v5'
        AND skill_key='CHEM9701-12-04'
        AND release_enabled=false AND exam_candidate_eligible=false
        AND credit_mastery=false) corrected_private_versions,
  (SELECT count(*) FROM private.iclub_exam_core_chemistry_p1_item_preflight_v1
      WHERE can_issue_learner_assessment) issuable_p1,
  (SELECT can_publish FROM private.iclub_exam_chemistry_j12_release_gate_v1 LIMIT 1) publish_enabled
)
SELECT 'AS cards total' check_name,(AS_count=91) pass,AS_count observed FROM truth
UNION ALL SELECT 'AS required-mapped candidates',AS_scored_candidates=90,AS_scored_candidates FROM truth
UNION ALL SELECT 'AS enrichment correctly isolated',AS_enrichment_count=1,AS_enrichment_count FROM truth
UNION ALL SELECT 'A Level completely separate',A_count=63,A_count FROM truth
UNION ALL SELECT 'Theory core hash intact',hash_drift=0,hash_drift FROM truth
UNION ALL SELECT 'Paper 3 AS LAB only six',P3_as_cards=6,P3_as_cards FROM truth
UNION ALL SELECT 'Paper 5 A LAB only six',P5_a_cards=6,P5_a_cards FROM truth
UNION ALL SELECT 'Original P1 academic FAIL preserved',original_fail_retained=1,original_fail_retained FROM truth
UNION ALL SELECT 'New P1 corrected version at most one and still private',(corrected_private_versions BETWEEN 0 AND 1),corrected_private_versions FROM truth
UNION ALL SELECT 'P1 learner issuing impossible',issuable_p1=0,issuable_p1 FROM truth
UNION ALL SELECT 'Chemistry learner publishing OFF',NOT publish_enabled,publish_enabled::integer FROM truth;