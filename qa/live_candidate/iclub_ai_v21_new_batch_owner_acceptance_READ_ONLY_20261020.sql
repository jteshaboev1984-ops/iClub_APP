-- iClub Global AI v2.1 owner-delegated acceptance: strictly READ ONLY.
-- Output is a snapshot only; never releases sources, signs evidence or grants access.
WITH state AS (
SELECT
 (SELECT count(*) FROM private.iclub_ai_v21_academic_sources) AS source_rows,
 (SELECT count(*) FROM private.iclub_ai_v21_academic_sources
  WHERE source_version='qbank_exact_explanation_draft_v1'
   AND NOT published AND revoked AND NOT content_reviewed
   AND NOT rights_reviewed AND NOT locale_reviewed
   AND NOT academic_qa_passed AND approved_at IS NULL) AS closed_new_rows,
 (SELECT count(*) FROM private.iclub_ai_v21_academic_sources src
  WHERE private.iclub_ai_v21_source_admitted_v1(src)) AS admitted_rows,
 (SELECT count(*) FROM private.iclub_ai_v21_owner_beta_source_releases
  WHERE enabled) AS old_owner_grants,
 (SELECT count(*) FROM private.iclub_ai_v21_academic_deliveries) AS deliveries,
 (SELECT provider_enabled FROM private.iclub_ai_v21_academic_policy
  WHERE singleton=1) AS provider_enabled,
 to_regclass('private.iclub_ai_v21_qbank_owner_beta_releases')
  IS NOT NULL AS new_provenance_gate_installed,
 to_regclass('private.iclub_ai_v21_source_revision_archive')
  IS NOT NULL AS revision_history_installed
)
SELECT *, CASE
 WHEN source_rows<>321 OR closed_new_rows<>210 OR admitted_rows<>111
 OR old_owner_grants<>111 OR provider_enabled IS DISTINCT FROM false
 THEN 'BLOCKED_BASELINE_DRIFT'
 WHEN NOT new_provenance_gate_installed OR NOT revision_history_installed
 THEN 'NO_GO__NEW_APPROVAL_AND_IMMUTABLE_HISTORY_NOT_DEPLOYED'
 ELSE 'REQUIRES_INDEPENDENT_RIGHTS_ACADEMIC_LOCALE_SIGNOFF_AND_E2E'
 END AS release_decision,
 'No database snapshot can prove legal ownership or an independent reviewer signature'::text
 AS manual_evidence_limit
FROM state;