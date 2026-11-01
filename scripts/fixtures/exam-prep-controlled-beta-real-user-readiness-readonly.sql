-- Production READ ONLY. Zero live user mutation / no impersonation.
-- The existing real beta cohort remains feature-gated; weekly real-user
-- evidence cannot be fabricated from synthetic Playwright or developer tests.
WITH cohort AS (
 SELECT id,cohort_key,cohort_status,planned_size,current_wave,started_at
 FROM private.exam_prep_beta_cohorts
 WHERE cohort_key='math_as_p1_p5_beta_2026_09_01'
), gate AS (
 SELECT private.exam_prep_beta_expansion_gate_v1(cohort_key) result FROM cohort
)
SELECT c.cohort_key,c.cohort_status,c.planned_size,c.current_wave,
 (SELECT count(*) FROM private.exam_prep_beta_members m WHERE m.cohort_id=c.id AND m.member_status='active') active_learners,
 (SELECT count(*) FROM private.exam_prep_beta_consents con WHERE con.cohort_id=c.id AND con.consent_status='granted') real_consents,
 (SELECT count(*) FROM private.exam_prep_feature_entitlements e WHERE e.cohort_key=c.cohort_key AND e.entitlement_status='active' AND e.core_access) core_eligible,
 (SELECT count(*) FROM private.exam_prep_beta_weekly_reviews) recorded_weekly_reviews,
 gate.result->>'reason_code' expansion_blocker,
 (gate.result->>'ready')::boolean expansion_ready,
 gate.result->>'development_data_state' evidence_state
FROM cohort c CROSS JOIN gate;
