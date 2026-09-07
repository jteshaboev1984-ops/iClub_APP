-- P1-04 AI runtime lifecycle marker.
-- Safe only after the JWT-protected exam-prep-ai Edge Function is deployed.
-- This does not enable learner AI: feature config, entitlements and AI policy remain independently gated.

update private.exam_prep_optional_capability_status
set runtime_status='shadow', updated_at=now()
where capability_code='ai_assist'
  and runtime_status='not_deployed';
