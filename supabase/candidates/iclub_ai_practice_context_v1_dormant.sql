-- DORMANT CANDIDATE ONLY. Not in supabase/migrations. No production deployment.
-- Source of truth: owned finalized V4 Practice; no answer keys or question text exposed.
-- Isolated opt-in enrollment for named Cambridge Mathematics beta accounts.
-- DEFAULT OFF grants never bypass consent, cohort status or AI entitlement.
CREATE TABLE IF NOT EXISTS private.iclub_ai_practice_beta_grants_v1(
 user_id uuid PRIMARY KEY,
 enabled boolean NOT NULL DEFAULT false,
 granted_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE private.iclub_ai_practice_beta_grants_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_ai_practice_beta_grants_v1 FROM PUBLIC,anon,authenticated;
CREATE TABLE IF NOT EXISTS private.iclub_ai_practice_context_v1_control (
 singleton smallint PRIMARY KEY CHECK (singleton=1),
 enabled boolean NOT NULL DEFAULT false,
 owner_user_id uuid DEFAULT NULL,
 error_enabled boolean NOT NULL DEFAULT false,
 updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO private.iclub_ai_practice_context_v1_control(singleton,enabled)
VALUES (1,false) ON CONFLICT(singleton) DO NOTHING;
ALTER TABLE private.iclub_ai_practice_context_v1_control ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_ai_practice_context_v1_control FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION public.get_iclub_ai_practice_context_v1_service(
 p_user_id uuid,p_attempt_id bigint,p_intent text,
 p_question_id bigint DEFAULT NULL,p_locale text DEFAULT 'ru'
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $fn$
DECLARE
 v_verified record;
 v_subject text;
 v_total integer;
 v_answered integer;
 v_correct integer;
 v_incorrect integer;
 v_pct numeric;
 v_reviewable jsonb:='[]'::jsonb;
 v_comparison jsonb:=jsonb_build_object('available',false);
 v_previous integer;
 v_source_ready boolean:=false;
 v_now timestamptz:=statement_timestamp();
BEGIN
 IF (auth.jwt()->>'role') IS DISTINCT FROM 'service_role' THEN
   RETURN jsonb_build_object('ok',false,'reason','not_authorized');
 END IF;
 IF p_user_id IS NULL OR p_attempt_id IS NULL OR p_attempt_id<=0
  OR p_intent NOT IN ('practice_visibility','practice_result','practice_error','practice_next_step','practice_history_comparison')
  OR p_locale NOT IN ('ru','uz','en')
  OR (p_intent='practice_error' AND (p_question_id IS NULL OR p_question_id<=0))
  OR (p_intent<>'practice_error' AND p_question_id IS NOT NULL)
 THEN RETURN jsonb_build_object('ok',false,'reason','invalid_request'); END IF;

 IF NOT EXISTS (
  SELECT 1 FROM private.iclub_ai_practice_context_v1_control ctl
  JOIN private.iclub_ai_v21_beta_control beta ON beta.singleton=ctl.singleton
  JOIN private.iclub_ai_v21_academic_policy pol ON pol.singleton=ctl.singleton
  JOIN private.iclub_ai_v21_beta_members m ON m.user_id=p_user_id
  WHERE ctl.singleton=1 AND ctl.enabled
     AND (ctl.owner_user_id=p_user_id OR EXISTS (
       SELECT 1 FROM private.iclub_ai_practice_beta_grants_v1 grant_row
       JOIN private.exam_prep_beta_members bm
         ON bm.user_id=grant_row.user_id AND bm.member_status='active'
            AND bm.service_mode='ai_assist'
       JOIN private.exam_prep_beta_cohorts cohort
         ON cohort.id=bm.cohort_id
         AND cohort.program_key='math_as_p1_p5'
         AND cohort.cohort_status='canary'
       JOIN private.exam_prep_beta_consents consent
         ON consent.user_id=grant_row.user_id
         AND consent.cohort_id=cohort.id
         AND consent.consent_scope='exam_prep_controlled_beta_v1'
         AND consent.consent_status='granted' AND consent.revoked_at IS NULL
       JOIN private.exam_prep_feature_entitlements ent
         ON ent.user_id=grant_row.user_id
         AND ent.entitlement_status='active'
         AND ent.core_access AND ent.ai_assist
         AND (ent.valid_from IS NULL OR ent.valid_from<=v_now)
         AND (ent.valid_until IS NULL OR ent.valid_until>v_now)
       WHERE grant_row.user_id=p_user_id AND grant_row.enabled
     ))
     AND beta.beta_enabled
   AND beta.prepared_enabled AND NOT beta.generation_enabled
   AND pol.enabled AND NOT pol.provider_enabled
   AND m.enabled AND m.consent_version='global_ai_beta_v21'
   AND m.consent_at IS NOT NULL
 ) THEN RETURN jsonb_build_object('ok',false,'reason','not_enabled'); END IF;

 IF p_intent='practice_error' AND NOT EXISTS (
  SELECT 1 FROM private.iclub_ai_practice_context_v1_control
  WHERE singleton=1 AND error_enabled
 ) THEN RETURN jsonb_build_object('ok',false,'reason','source_not_ready'); END IF;

 -- A separate unfinished/resumable Practice session must NEVER
 -- block an independently verified finalized attempt. Active quiz UI
 -- hides the Tutor; this service still blocks protected Tour/Exam Prep
 -- and independently verifies owned finalized attempts below.
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 THEN RETURN jsonb_build_object('ok',false,'reason','active_assessment'); END IF;

 IF EXISTS (SELECT 1 FROM private.iclub_commercial_access_config WHERE id=1 AND lifecycle_enabled)
 AND NOT EXISTS (
  SELECT 1 FROM private.iclub_subscription_entitlements se
  JOIN private.iclub_plan_policies plan ON plan.plan_code=se.plan_code AND plan.is_active
  WHERE se.user_id=p_user_id AND se.entitlement_status='active'
   AND (se.valid_from IS NULL OR se.valid_from<=v_now)
   AND (se.valid_until IS NULL OR se.valid_until>v_now)
 ) THEN RETURN jsonb_build_object('ok',false,'reason','entitlement_required'); END IF;

 IF (SELECT count(*)
  FROM public.practice_attempts pa
  JOIN public.practice_sessions_v4 ps ON ps.legacy_attempt_id=pa.id
  JOIN public.subjects subj ON subj.id=ps.subject_id
  JOIN public.user_subjects us ON us.subject_id=subj.id AND us.user_id=p_user_id
  WHERE pa.id=p_attempt_id AND pa.user_id=p_user_id AND pa.is_lab IS NOT TRUE
   AND ps.user_id=p_user_id AND pa.subject_id=ps.subject_id
   AND (pa.bank_generation IS NULL OR ps.bank_generation IS NOT DISTINCT FROM pa.bank_generation)
   AND ps.status='finalized' AND ps.finalized_at IS NOT NULL AND subj.is_active
 ) <> 1 THEN RETURN jsonb_build_object('ok',false,'reason','context_not_authorized'); END IF;

 SELECT pa.id AS attempt_id, pa.subject_id AS attempt_subject_id,
        pa.score AS score, pa.percent AS percent,
        ps.id AS session_id, ps.question_ids AS question_ids,
        ps.pool_id AS pool_id, ps.bank_generation AS bank_generation,
        ps.subject_id AS session_subject_id, ps.finalized_at AS finalized_at,
        subj.subject_key AS subject_key
 INTO v_verified
 FROM public.practice_attempts pa
 JOIN public.practice_sessions_v4 ps ON ps.legacy_attempt_id=pa.id
 JOIN public.subjects subj ON subj.id=ps.subject_id
 WHERE pa.id=p_attempt_id AND pa.user_id=p_user_id AND pa.is_lab IS NOT TRUE
  AND ps.user_id=p_user_id AND ps.subject_id=pa.subject_id
  AND (pa.bank_generation IS NULL OR ps.bank_generation IS NOT DISTINCT FROM pa.bank_generation)
  AND ps.status='finalized' AND ps.finalized_at IS NOT NULL AND subj.is_active;
 v_subject:=v_verified.subject_key;
 v_total:=cardinality(v_verified.question_ids);
 IF v_total IS NULL OR v_total<1 OR v_total>100
 OR (SELECT count(DISTINCT qid) FROM unnest(v_verified.question_ids) qid)<>v_total
 THEN RETURN jsonb_build_object('ok',false,'reason','invalid_attempt'); END IF;
 IF EXISTS (SELECT 1 FROM public.practice_session_answers_v4 a
  WHERE a.session_id=v_verified.session_id AND NOT a.question_id=ANY(v_verified.question_ids))
 OR (SELECT count(*) FROM public.practice_session_answers_v4 a WHERE a.session_id=v_verified.session_id)
  <> (SELECT count(DISTINCT a.question_id) FROM public.practice_session_answers_v4 a
      WHERE a.session_id=v_verified.session_id)
 THEN RETURN jsonb_build_object('ok',false,'reason','inconsistent_attempt'); END IF;
 SELECT count(*) FILTER(WHERE answered_at IS NOT NULL),
        count(*) FILTER(WHERE answered_at IS NOT NULL AND is_correct IS TRUE),
        count(*) FILTER(WHERE answered_at IS NOT NULL AND is_correct IS FALSE)
 INTO v_answered,v_correct,v_incorrect
 FROM public.practice_session_answers_v4 WHERE session_id=v_verified.session_id;
 v_pct:=round(v_correct::numeric*100/v_total,1);
 IF v_answered>v_total OR v_correct+v_incorrect<>v_answered
 OR v_verified.score IS DISTINCT FROM v_correct
 OR v_verified.percent IS NULL OR abs(v_verified.percent-v_pct)>1
 THEN RETURN jsonb_build_object('ok',false,'reason','inconsistent_attempt'); END IF;

 SELECT coalesce(jsonb_agg(array_position(v_verified.question_ids,a.question_id)
    ORDER BY array_position(v_verified.question_ids,a.question_id)),'[]'::jsonb)
 INTO v_reviewable
 FROM public.practice_session_answers_v4 a
 JOIN public.questions q ON q.id=a.question_id AND q.subject_id=v_verified.attempt_subject_id
 WHERE a.session_id=v_verified.session_id AND a.answered_at IS NOT NULL
 AND a.is_correct IS FALSE AND q.is_active
 AND NOT public.iclub_practice_drill_question_protected_v4(q.id);

 IF p_intent='practice_error' THEN
   IF NOT EXISTS (
    SELECT 1 FROM public.practice_session_answers_v4 a
    JOIN public.questions q ON q.id=a.question_id
    WHERE a.session_id=v_verified.session_id AND a.question_id=p_question_id
     AND a.answered_at IS NOT NULL AND a.is_correct IS FALSE
     AND q.subject_id=v_verified.attempt_subject_id AND q.is_active AND q.quality_status='published'
     AND NOT public.iclub_practice_drill_question_protected_v4(q.id)
   ) THEN RETURN jsonb_build_object('ok',false,'reason','question_not_eligible'); END IF;
   SELECT EXISTS (
    SELECT 1 FROM private.iclub_ai_v21_academic_sources src
    WHERE src.surface_code='practice_error' AND src.subject_key=v_subject
     AND src.context_key='question_'||p_question_id::text AND src.locale=p_locale
     AND private.iclub_ai_v21_source_admitted_v1(src)
     AND src.source_version IS NOT NULL AND length(btrim(src.source_version))>0
     AND src.target_hash=private.iclub_ai_v21_target_fingerprint_v1('practice_error',p_question_id)
     AND src.content_hash=encode(extensions.digest(convert_to(src.body_text,'UTF8'),'sha256'),'hex')
     -- One language alone is insufficient. All three reviewed source versions
     -- must belong to the same current question fingerprint. No fallback to
     -- a stale translation or generic skill explanation.
     AND 3=(
       SELECT count(DISTINCT sibling.locale)
       FROM private.iclub_ai_v21_academic_sources sibling
       WHERE sibling.surface_code=src.surface_code
        AND sibling.subject_key=src.subject_key
        AND sibling.context_key=src.context_key
        AND sibling.source_version=src.source_version
        AND sibling.locale IN ('en','ru','uz')
        AND private.iclub_ai_v21_source_admitted_v1(sibling)
        AND sibling.target_hash=src.target_hash
        AND sibling.content_hash=encode(
          extensions.digest(convert_to(sibling.body_text,'UTF8'),'sha256'),'hex')
     )
   ) INTO v_source_ready;
 END IF;

 IF p_intent='practice_history_comparison' AND v_verified.pool_id IS NOT NULL
 AND v_verified.bank_generation IS NOT NULL THEN
  SELECT prior_pa.score INTO v_previous
  FROM public.practice_sessions_v4 prior
  JOIN public.practice_attempts prior_pa ON prior_pa.id=prior.legacy_attempt_id
  WHERE prior.user_id=p_user_id AND prior_pa.user_id=p_user_id
    AND prior_pa.is_lab IS NOT TRUE AND prior.id<>v_verified.session_id
    AND prior.subject_id=v_verified.session_subject_id AND prior_pa.subject_id=v_verified.session_subject_id
    AND prior.pool_id=v_verified.pool_id AND prior.bank_generation=v_verified.bank_generation
    AND cardinality(prior.question_ids)=v_total
    AND prior.status='finalized' AND prior.finalized_at IS NOT NULL
    AND prior.finalized_at<v_verified.finalized_at AND prior_pa.score BETWEEN 0 AND v_total
  ORDER BY prior.finalized_at DESC LIMIT 1;
  IF FOUND THEN v_comparison:=jsonb_build_object(
    'available',true,'previous_percentage',round(v_previous::numeric*100/v_total,1),
    'previous_correct',v_previous,'previous_total',v_total,
    'basis','same_subject_pool_bank_generation_question_count',
    'causation_claim_allowed',false);
  END IF;
 END IF;

 RETURN jsonb_build_object('ok',true,
  'source_status',CASE WHEN p_intent='practice_error' THEN
    CASE WHEN v_source_ready THEN 'ready' ELSE 'source_not_ready' END
    ELSE 'not_requested' END,
  'context',jsonb_build_object(
    'context_version','practice_context_v1','intent',p_intent,'locale',p_locale,
    'subject_key',v_subject,'attempt_ref',v_verified.attempt_id,'completed',true,
    'total',v_total,'correct',v_correct,'incorrect',v_incorrect,
    'unattempted',v_total-v_answered,'percentage',v_pct,
    'reviewable_error_ordinals',v_reviewable,
    'available_actions',CASE WHEN jsonb_array_length(v_reviewable)>0
     THEN jsonb_build_array('review_attempt','correct_mistakes')
     ELSE jsonb_build_array('review_attempt') END,
    'comparison',v_comparison
  ));
END;
$fn$;
REVOKE ALL ON FUNCTION public.get_iclub_ai_practice_context_v1_service(uuid,bigint,text,bigint,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_practice_context_v1_service(uuid,bigint,text,bigint,text)
 TO service_role;