-- PHASE 2 — deploy ONLY after verified new no-invite Math/Economics client,
-- protected Preview/production smoke and no in-flight old beta enrollment flow.
-- This disables obsolete self-enrollment / consent-grant RPCs without deleting
-- memberships, historical consent, attempts, answers or user progress.
BEGIN;
REVOKE ALL ON FUNCTION public.claim_my_exam_prep_beta_core_seat_v1(text,text)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.grant_my_exam_prep_beta_consent_v1(text,text)
 FROM PUBLIC,anon,authenticated;
-- The historical self-revocation API is deliberately retained.
COMMIT;
