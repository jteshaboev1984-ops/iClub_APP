-- Mathematics P1/P5 D11: explicitly KEEP the learner's current weekly budget.
-- Acknowledgment of the recommendation shortfall is an owner-only durable
-- decision, not a profile update, learning cap, readiness boost or exam score.
-- DRAFT/NO_GO: never apply to live Supabase without separate architect approval.
BEGIN;

CREATE TABLE IF NOT EXISTS private.exam_prep_weekly_time_decisions_v1 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  program_version_id bigint NOT NULL REFERENCES private.exam_prep_program_versions(id),
  decision_kind text NOT NULL CHECK(decision_kind='keep'),
  chosen_math_hours numeric NOT NULL CHECK(chosen_math_hours>=0 AND chosen_math_hours<=168),
  suggested_math_hours numeric NOT NULL CHECK(suggested_math_hours>chosen_math_hours),
  profile_revision integer NOT NULL CHECK(profile_revision>=1),
  idempotency_key text NOT NULL CHECK(char_length(idempotency_key) BETWEEN 12 AND 150),
  acknowledged_shortfall boolean NOT NULL DEFAULT true CHECK(acknowledged_shortfall),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id,idempotency_key)
);
CREATE INDEX IF NOT EXISTS exam_prep_weekly_keep_owner_v1_idx
 ON private.exam_prep_weekly_time_decisions_v1(user_id,created_at DESC);
ALTER TABLE private.exam_prep_weekly_time_decisions_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_weekly_time_decisions_v1 FROM PUBLIC,anon,authenticated;
GRANT ALL ON private.exam_prep_weekly_time_decisions_v1 TO service_role;

CREATE OR REPLACE FUNCTION public.keep_my_exam_prep_timeline_weekly_time_safe_v1(
  p_expected_current_math_hours numeric,
  p_expected_profile_revision integer,
  p_expected_suggested_math_hours numeric,
  p_idempotency_key text
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO ''
AS $keep$
DECLARE
 v_uid uuid;
 v_profile private.exam_prep_exam_profiles%ROWTYPE;
 v_est jsonb;
 v_target numeric;
 v_first boolean;
 v_fifth boolean;
 v_saved private.exam_prep_weekly_time_decisions_v1%ROWTYPE;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF p_idempotency_key IS NULL OR char_length(p_idempotency_key) NOT BETWEEN 12 AND 150 THEN
   RAISE EXCEPTION 'exam_prep_weekly_keep_key_invalid' USING ERRCODE='22023';
 END IF;
 SELECT * INTO v_profile
 FROM private.exam_prep_exam_profiles
 WHERE user_id=v_uid FOR UPDATE;
 IF v_profile.user_id IS NULL OR v_profile.program_version_id IS NULL THEN
   RAISE EXCEPTION 'exam_prep_profile_required' USING ERRCODE='42501';
 END IF;
 IF p_expected_profile_revision IS DISTINCT FROM v_profile.profile_revision
   OR p_expected_current_math_hours IS DISTINCT FROM v_profile.mathematics_hours_budget
   OR p_expected_suggested_math_hours IS NULL THEN
   RAISE EXCEPTION 'exam_prep_weekly_plan_changed_refresh' USING ERRCODE='PT409';
 END IF;
 v_est:=public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2();
 v_first:=v_est->'P1'->>'exam_date_status'='valid_exam_date';
 v_fifth:=v_est->'P5'->>'exam_date_status'='valid_exam_date';
 v_target:=CASE
  WHEN v_first AND v_fifth THEN (v_est->>'estimated_joint_math_hours_per_week')::numeric
  WHEN v_first AND NOT v_fifth THEN (v_est->'P1'->>'estimated_component_weekly_hours')::numeric
  WHEN v_fifth AND NOT v_first THEN (v_est->'P5'->>'estimated_component_weekly_hours')::numeric
  ELSE NULL::numeric END;
 IF v_target IS NULL OR v_target<=v_profile.mathematics_hours_budget
    OR v_target IS DISTINCT FROM p_expected_suggested_math_hours THEN
   RAISE EXCEPTION 'exam_prep_weekly_recommendation_changed_refresh'
     USING ERRCODE='PT409';
 END IF;
 INSERT INTO private.exam_prep_weekly_time_decisions_v1(
   user_id,program_version_id,decision_kind,chosen_math_hours,
   suggested_math_hours,profile_revision,idempotency_key
 ) VALUES(
   v_uid,v_profile.program_version_id,'keep',v_profile.mathematics_hours_budget,
   v_target,v_profile.profile_revision,p_idempotency_key
 ) ON CONFLICT (user_id,idempotency_key) DO NOTHING;
 SELECT * INTO v_saved FROM private.exam_prep_weekly_time_decisions_v1
 WHERE user_id=v_uid AND idempotency_key=p_idempotency_key;
 IF v_saved.id IS NULL OR v_saved.program_version_id<>v_profile.program_version_id
   OR v_saved.profile_revision<>v_profile.profile_revision
   OR v_saved.chosen_math_hours IS DISTINCT FROM v_profile.mathematics_hours_budget
   OR v_saved.suggested_math_hours IS DISTINCT FROM v_target
   OR v_saved.decision_kind<>'keep' THEN
   RAISE EXCEPTION 'exam_prep_weekly_keep_key_conflict' USING ERRCODE='PT409';
 END IF;
 -- No updates to profile, answers, plans, sessions, mastery, Practice or Tours.
 RETURN v_est || jsonb_build_object(
   'decision_recorded',true,
   'decision_code','keep_current_hours',
   'hours_changed',false,
   'shortfall_acknowledged',true
 );
END;
$keep$;
REVOKE ALL ON FUNCTION public.keep_my_exam_prep_timeline_weekly_time_safe_v1(
 numeric,integer,numeric,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.keep_my_exam_prep_timeline_weekly_time_safe_v1(
 numeric,integer,numeric,text) TO authenticated,service_role;
COMMENT ON FUNCTION public.keep_my_exam_prep_timeline_weekly_time_safe_v1(
 numeric,integer,numeric,text) IS
'Owner-authenticated, revision-checked and idempotent Keep decision; acknowledges current syllabus-based shortfall without changing any weekly hours, progress or access.';
COMMIT;
