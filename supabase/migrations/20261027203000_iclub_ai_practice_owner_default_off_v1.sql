-- iClub Practice AI, exact owner-only server candidates.
-- APPEND-ONLY schema; independent feature flags default OFF.
-- Never enable AI or alter user grades/progress in this migration.
-- Must be applied only with explicit reviewed production approval.
BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '90s';

-- BEGIN reviewed source: iclub_ai_practice_context_v1_dormant.sql
-- DORMANT CANDIDATE ONLY. Not in supabase/migrations. No production deployment.
-- Source of truth: owned finalized V4 Practice; no answer keys or question text exposed.
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
  WHERE ctl.singleton=1 AND ctl.enabled AND ctl.owner_user_id=p_user_id
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

 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR EXISTS (SELECT 1 FROM public.practice_sessions_v4
            WHERE user_id=p_user_id AND status='in_progress')
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
-- END reviewed source: iclub_ai_practice_context_v1_dormant.sql

-- BEGIN reviewed source: iclub_ai_practice_receipts_pc4_dormant.sql
-- DORMANT PC4 receipt schema candidate. NOT a production migration.
-- No model call, no quota/budget reset, no user-facing access.
CREATE TABLE IF NOT EXISTS private.iclub_ai_practice_receipt_v1_control (
 singleton smallint PRIMARY KEY CHECK(singleton=1),
 enabled boolean NOT NULL DEFAULT false,
 updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO private.iclub_ai_practice_receipt_v1_control(singleton,enabled)
VALUES (1,false) ON CONFLICT(singleton) DO NOTHING;
ALTER TABLE private.iclub_ai_practice_receipt_v1_control ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_ai_practice_receipt_v1_control FROM PUBLIC,anon,authenticated;
CREATE TABLE IF NOT EXISTS private.iclub_ai_practice_receipts_v1 (
 request_id uuid PRIMARY KEY,
 user_id uuid NOT NULL,
 attempt_ref bigint NOT NULL CHECK(attempt_ref>0),
 locale text NOT NULL CHECK(locale IN('ru','uz','en')),
 request_fingerprint text NOT NULL CHECK(request_fingerprint ~ '^[a-f0-9]{64}$'),
 context_fingerprint text NOT NULL CHECK(context_fingerprint ~ '^[a-f0-9]{64}$'),
 source_fingerprint text NOT NULL CHECK(source_fingerprint ~ '^[a-f0-9]{64}$'),
 status text NOT NULL DEFAULT 'registered'
   CHECK(status IN('registered','dispatched','ready','acknowledged','void','unknown')),
 answer text CHECK(answer IS NULL OR char_length(answer) BETWEEN 20 AND 2400),
 answer_hash text,
 estimated_hold_microusd bigint NOT NULL DEFAULT 50000
   CHECK(estimated_hold_microusd=50000),
 provider_reported_microusd bigint
   CHECK(provider_reported_microusd BETWEEN 0 AND 50000),
 received_at timestamptz NOT NULL DEFAULT now(),
 dispatched_at timestamptz,
 stored_at timestamptz,
 acknowledged_at timestamptz,
 quota_confirmed_at timestamptz,
 expires_at timestamptz NOT NULL DEFAULT (now()+interval '24 hours'),
 CHECK((answer IS NULL AND answer_hash IS NULL) OR
       (answer IS NOT NULL AND answer_hash ~ '^[a-f0-9]{64}$')),
 CHECK(status NOT IN('ready','acknowledged') OR answer IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS iclub_ai_practice_receipts_user_state_v1
 ON private.iclub_ai_practice_receipts_v1(user_id,status,received_at);
ALTER TABLE private.iclub_ai_practice_receipts_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_ai_practice_receipts_v1 FROM PUBLIC,anon,authenticated;

-- END reviewed source: iclub_ai_practice_receipts_pc4_dormant.sql

-- BEGIN reviewed source: iclub_ai_practice_freeform_pc3_gate_dormant.sql
-- DORMANT PC3 release gate. NOT a production migration.
-- Service-only inspection of existing, unchanged paid General Help controls.
CREATE TABLE IF NOT EXISTS private.iclub_ai_practice_freeform_pc3_control(
 singleton smallint PRIMARY KEY CHECK(singleton=1),
 enabled boolean NOT NULL DEFAULT false,
 updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO private.iclub_ai_practice_freeform_pc3_control(singleton,enabled)
VALUES(1,false) ON CONFLICT(singleton) DO NOTHING;
ALTER TABLE private.iclub_ai_practice_freeform_pc3_control ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_ai_practice_freeform_pc3_control FROM PUBLIC,anon,authenticated;
CREATE OR REPLACE FUNCTION public.iclub_ai_practice_freeform_pc3_gate_service()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $pc3$
BEGIN
 IF (auth.jwt()->>'role') IS DISTINCT FROM 'service_role' THEN
  RETURN jsonb_build_object('ok',false,'reason','not_authorized');
 END IF;
 IF NOT EXISTS (
  SELECT 1 FROM private.iclub_ai_practice_freeform_pc3_control pc3
  JOIN private.iclub_ai_practice_receipt_v1_control pc4 ON pc4.singleton=pc3.singleton
  JOIN private.iclub_ai_practice_context_v1_control pc1 ON pc1.singleton=pc3.singleton
  JOIN private.iclub_ai_v21_beta_control beta ON beta.singleton=pc3.singleton
  JOIN private.iclub_ai_v21_freeform_budget_control money ON money.singleton=pc3.singleton
  WHERE pc3.singleton=1 AND pc3.enabled AND pc4.enabled AND pc1.enabled AND pc1.owner_user_id IS NOT NULL
    AND beta.beta_enabled AND beta.prepared_enabled
    AND NOT beta.generation_enabled AND beta.approved_release<>'none'
    AND money.enabled AND money.owner_permitted AND money.include_free_beta
    AND money.model='gpt-5.4-mini'
    AND money.maximum_lifetime_microusd=5000000
    AND money.maximum_per_request_microusd=50000
    AND money.maximum_per_learner_microusd=750000
    AND money.maximum_parallel=2
    AND money.output_token_cap=384
    AND money.input_microusd_per_token=0.75
    AND money.output_microusd_per_token=4.5
 ) THEN RETURN jsonb_build_object('ok',false,'reason','not_released'); END IF;
 RETURN jsonb_build_object('ok',true,'released',true,
    'model','gpt-5.4-mini','output_token_cap',384,
    'maximum_per_request_microusd',50000,'generated_weight',3);
END;
$pc3$;
REVOKE ALL ON FUNCTION public.iclub_ai_practice_freeform_pc3_gate_service()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_ai_practice_freeform_pc3_gate_service()
 TO service_role;

-- END reviewed source: iclub_ai_practice_freeform_pc3_gate_dormant.sql

-- BEGIN reviewed source: iclub_ai_practice_receipt_rpc_pc4_dormant.sql
-- DORMANT PC4 RPC. Compile only after the receipt-table candidate.
-- Edge remains responsible for JWT validation, source/version admission,
-- existing shared quota + budget reservation, provider result validation.
CREATE OR REPLACE FUNCTION public.iclub_ai_practice_receipt_pc4_service(
 p_action text,p_request_id uuid,p_user_id uuid,p_attempt_ref bigint,
 p_request_fingerprint text,p_context_fingerprint text,
 p_source_fingerprint text,p_locale text,
 p_answer text DEFAULT NULL,p_actual_microusd bigint DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path TO '' AS $fn$
DECLARE r private.iclub_ai_practice_receipts_v1%ROWTYPE;
 ctx jsonb;
 money_state text;
 quota_state text;
BEGIN
 IF (auth.jwt()->>'role') IS DISTINCT FROM 'service_role' THEN
  RETURN jsonb_build_object('ok',false,'reason','not_authorized');
 END IF;
 IF p_action NOT IN('begin','inspect','dispatch','store','replay','ack','accounted','void','unknown')
 OR p_request_id IS NULL OR p_user_id IS NULL
 OR p_attempt_ref IS NULL OR p_attempt_ref<=0
 OR p_locale NOT IN('ru','uz','en')
 OR p_request_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_context_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_source_fingerprint !~ '^[a-f0-9]{64}$' THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_request');
 END IF;
 -- Financial cleanup remains necessary AFTER consent/entitlement is
 -- revoked or an emergency kill switch is engaged. These actions NEVER
 -- release student content, create a receipt, or dispatch a model request.
 -- All still require service_role and exact UUID/owner/fingerprint matching.
 IF p_action NOT IN('void','unknown','inspect','accounted') THEN
  IF NOT EXISTS (
   SELECT 1 FROM private.iclub_ai_practice_receipt_v1_control a
   JOIN private.iclub_ai_practice_context_v1_control b
    ON a.singleton=b.singleton
   WHERE a.singleton=1 AND a.enabled AND b.enabled
  ) THEN RETURN jsonb_build_object('ok',false,'reason','not_enabled'); END IF;
  ctx:=public.get_iclub_ai_practice_context_v1_service(
   p_user_id,p_attempt_ref,'practice_visibility',NULL,p_locale);
  IF ctx->>'ok' IS DISTINCT FROM 'true' THEN
   RETURN jsonb_build_object('ok',false,'reason','context_unavailable');
  END IF;
 END IF;
 -- Serialize one learner's receipt creation before checking pending count.
 PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text),4516);
 PERFORM pg_advisory_xact_lock(hashtext(p_request_id::text),4517);
 SELECT * INTO r FROM private.iclub_ai_practice_receipts_v1
 WHERE request_id=p_request_id FOR UPDATE;
 IF NOT FOUND THEN
  IF p_action<>'begin' THEN
   RETURN jsonb_build_object('ok',false,'reason','receipt_missing');
  END IF;
  IF (SELECT count(*) FROM private.iclub_ai_practice_receipts_v1
      WHERE user_id=p_user_id AND status IN('registered','dispatched','ready')
        AND expires_at>now())>=2 THEN
   RETURN jsonb_build_object('ok',false,'reason','pending_limit');
  END IF;
  INSERT INTO private.iclub_ai_practice_receipts_v1(
   request_id,user_id,attempt_ref,locale,request_fingerprint,
   context_fingerprint,source_fingerprint)
  VALUES(p_request_id,p_user_id,p_attempt_ref,p_locale,p_request_fingerprint,
    p_context_fingerprint,p_source_fingerprint);
  RETURN jsonb_build_object('ok',true,'action','registered');
 END IF;
 IF r.user_id IS DISTINCT FROM p_user_id OR
    r.attempt_ref IS DISTINCT FROM p_attempt_ref OR
    r.locale IS DISTINCT FROM p_locale OR
    r.request_fingerprint IS DISTINCT FROM p_request_fingerprint OR
    r.context_fingerprint IS DISTINCT FROM p_context_fingerprint OR
    r.source_fingerprint IS DISTINCT FROM p_source_fingerprint THEN
  RETURN jsonb_build_object('ok',false,'reason','request_conflict');
 END IF;
 IF p_action='begin' THEN
  RETURN jsonb_build_object('ok',true,'action','existing',
    'state',r.status,'provider_called',false);
 END IF;
 IF p_action='inspect' THEN
  -- Internal accounting metadata only; no learner answer or keys returned.
  RETURN jsonb_build_object('ok',true,'action','inspection',
    'state',r.status,'actual_microusd',r.provider_reported_microusd,
    'quota_accounted',r.quota_confirmed_at IS NOT NULL);
 END IF;
 IF p_action='replay' THEN
  IF r.status NOT IN('ready','acknowledged') OR now()>=r.expires_at THEN
   RETURN jsonb_build_object('ok',false,'reason','replay_unavailable');
  END IF;
  -- Do not deliver a stored response before the shared budget records cost.
  IF NOT EXISTS (SELECT 1 FROM private.iclub_ai_v21_freeform_budget_ledger
      WHERE request_id=p_request_id AND user_id=p_user_id
        AND request_fingerprint=p_request_fingerprint AND state='charged') THEN
    RETURN jsonb_build_object('ok',false,'reason','budget_settlement_pending');
  END IF;
  RETURN jsonb_build_object('ok',true,'action','replay',
   'message',r.answer,'message_hash',r.answer_hash,
   'state',r.status,'provider_called',false);
 END IF;
 IF p_action='dispatch' THEN
  IF r.status<>'registered' OR now()>=r.expires_at THEN
   RETURN jsonb_build_object('ok',false,'reason','dispatch_already_decided');
  END IF;
  -- Verify holds in the EXISTING $5 shared accounting structures.
  -- Provider may be called only after this transaction commits.
  SELECT state INTO money_state FROM private.iclub_ai_v21_freeform_budget_ledger
   WHERE request_id=p_request_id AND user_id=p_user_id
    AND request_fingerprint=p_request_fingerprint
    AND held_microusd=50000;
  SELECT state INTO quota_state FROM private.iclub_ai_v21_freeform_quota_holds
   WHERE request_id=p_request_id AND user_id=p_user_id
    AND request_fingerprint=p_request_fingerprint AND weight=3;
  IF coalesce(money_state,'')<>'dispatched'
     OR coalesce(quota_state,'')<>'reserved' THEN
   RETURN jsonb_build_object('ok',false,'reason','shared_hold_missing');
  END IF;
  UPDATE private.iclub_ai_practice_receipts_v1
   SET status='dispatched',dispatched_at=now() WHERE request_id=p_request_id;
  RETURN jsonb_build_object('ok',true,'action','dispatch_once');
 END IF;
 IF p_action='store' THEN
  IF r.status<>'dispatched' OR p_answer IS NULL
     OR char_length(p_answer) NOT BETWEEN 20 AND 2400
     OR p_actual_microusd IS NULL OR p_actual_microusd NOT BETWEEN 0 AND 50000
     OR p_answer ~* '<[/!]?[a-z][^>]*>' THEN
   RETURN jsonb_build_object('ok',false,'reason','invalid_store');
  END IF;
  UPDATE private.iclub_ai_practice_receipts_v1
   SET status='ready',answer=p_answer,stored_at=now(),
    answer_hash=encode(extensions.digest(convert_to(p_answer,'UTF8'),'sha256'),'hex'),
    provider_reported_microusd=p_actual_microusd
   WHERE request_id=p_request_id;
  RETURN jsonb_build_object('ok',true,'action','stored');
 END IF;
 IF p_action='ack' THEN
  IF r.status='acknowledged' THEN
   RETURN jsonb_build_object('ok',true,'action','acknowledged',
     'quota_settlement_pending',r.quota_confirmed_at IS NULL);
  END IF;
  IF r.status<>'ready' OR now()>=r.expires_at THEN
   RETURN jsonb_build_object('ok',false,'reason','ack_unavailable');
  END IF;
  UPDATE private.iclub_ai_practice_receipts_v1
   SET status='acknowledged',acknowledged_at=now() WHERE request_id=p_request_id;
  RETURN jsonb_build_object('ok',true,'action','acknowledged',
    'quota_settlement_pending',true);
 END IF;
 IF p_action='accounted' THEN
  IF r.status<>'acknowledged' THEN
   RETURN jsonb_build_object('ok',false,'reason','ack_required');
  END IF;
  SELECT state INTO quota_state FROM private.iclub_ai_v21_freeform_quota_holds
    WHERE request_id=p_request_id AND user_id=p_user_id
      AND request_fingerprint=p_request_fingerprint;
  SELECT state INTO money_state FROM private.iclub_ai_v21_freeform_budget_ledger
    WHERE request_id=p_request_id AND user_id=p_user_id
      AND request_fingerprint=p_request_fingerprint;
  IF coalesce(quota_state,'')<>'completed' OR
     coalesce(money_state,'')<>'charged' THEN
   RETURN jsonb_build_object('ok',false,'reason','shared_settlement_unconfirmed');
  END IF;
  UPDATE private.iclub_ai_practice_receipts_v1
   SET quota_confirmed_at=coalesce(quota_confirmed_at,now())
   WHERE request_id=p_request_id;
  RETURN jsonb_build_object('ok',true,'action','accounted');
 END IF;
 IF p_action='void' AND r.status='registered' THEN
  UPDATE private.iclub_ai_practice_receipts_v1
   SET status='void' WHERE request_id=p_request_id;
  RETURN jsonb_build_object('ok',true,'action','void_before_dispatch');
 END IF;
 IF p_action='unknown' AND r.status='dispatched' THEN
  UPDATE private.iclub_ai_practice_receipts_v1
   SET status='unknown' WHERE request_id=p_request_id;
  RETURN jsonb_build_object('ok',true,'action','provider_exposure_unknown');
 END IF;
 RETURN jsonb_build_object('ok',false,'reason','invalid_transition');
END;
$fn$;
REVOKE ALL ON FUNCTION public.iclub_ai_practice_receipt_pc4_service(
 text,uuid,uuid,bigint,text,text,text,text,text,bigint)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_ai_practice_receipt_pc4_service(
 text,uuid,uuid,bigint,text,text,text,text,text,bigint)
 TO service_role;

-- END reviewed source: iclub_ai_practice_receipt_rpc_pc4_dormant.sql

-- BEGIN reviewed source: iclub_ai_practice_recover_pc4_dormant.sql
-- DORMANT PC4 RECOVERY. Service-only lookup; never expose raw table to browser.
-- Current live learner and current owned finalized main Practice checked on EVERY call.
-- Only a charged and still-available reply can be discovered after full reload.
CREATE OR REPLACE FUNCTION public.iclub_ai_practice_recover_pc4_service(
 p_user_id uuid,p_attempt_ref bigint,p_locale text,
 p_request_id uuid DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO '' AS $fn$
DECLARE r private.iclub_ai_practice_receipts_v1%ROWTYPE;
 granted jsonb;
BEGIN
 IF (auth.jwt()->>'role') IS DISTINCT FROM 'service_role' THEN
  RETURN jsonb_build_object('ok',false,'reason','not_authorized');
 END IF;
 IF p_user_id IS NULL OR p_attempt_ref IS NULL OR p_attempt_ref<1
    OR p_locale NOT IN('ru','uz','en') THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_request');
 END IF;
 IF NOT EXISTS (
  SELECT 1 FROM private.iclub_ai_practice_receipt_v1_control pc4
  JOIN private.iclub_ai_practice_context_v1_control pc1 USING(singleton)
  JOIN private.iclub_ai_practice_freeform_pc3_control pc3 USING(singleton)
  WHERE pc4.singleton=1 AND pc4.enabled AND pc1.enabled AND pc3.enabled
 ) THEN RETURN jsonb_build_object('ok',false,'reason','not_enabled'); END IF;
 granted:=public.get_iclub_ai_practice_context_v1_service(
   p_user_id,p_attempt_ref,'practice_visibility',NULL,p_locale);
 IF granted->>'ok' IS DISTINCT FROM 'true' THEN
  RETURN jsonb_build_object('ok',false,'reason','context_unavailable');
 END IF;
 SELECT x.* INTO r FROM private.iclub_ai_practice_receipts_v1 x
 JOIN private.iclub_ai_v21_freeform_budget_ledger money
   ON money.request_id=x.request_id AND money.user_id=x.user_id
  AND money.request_fingerprint=x.request_fingerprint
 WHERE x.user_id=p_user_id AND x.attempt_ref=p_attempt_ref
   AND x.locale=p_locale
   AND (x.status='ready' OR
        (p_request_id IS NOT NULL AND x.status='acknowledged'))
   AND x.expires_at>clock_timestamp() AND money.state='charged'
   AND (p_request_id IS NULL OR x.request_id=p_request_id)
 ORDER BY x.received_at DESC,x.request_id DESC LIMIT 1;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'reason','no_pending_answer'); END IF;
 -- All hashes are sent ONLY to the internally authenticated service Edge;
 -- its fresh PC1 snapshot must match both hashes before any response/ACK.
 RETURN jsonb_build_object('ok',true,'action','recoverable',
  'request_id',r.request_id,
  'request_fingerprint',r.request_fingerprint,
  'context_fingerprint',r.context_fingerprint,
  'source_fingerprint',r.source_fingerprint);
END $fn$;
REVOKE ALL ON FUNCTION public.iclub_ai_practice_recover_pc4_service(
 uuid,bigint,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_ai_practice_recover_pc4_service(
 uuid,bigint,text,uuid) TO service_role;

-- END reviewed source: iclub_ai_practice_recover_pc4_dormant.sql

-- BEGIN reviewed source: iclub_ai_practice_pc4_financial_audit_dormant.sql
-- PC4 FINANCIAL AUDIT QUEUE — DORMANT, READ-ONLY, SERVICE-ROLE ONLY.
-- This query NEVER changes money/quota/receipts and NEVER erases an unknown.
-- Manual provider billing evidence is REQUIRED for any final classification.
CREATE OR REPLACE FUNCTION public.iclub_ai_practice_pc4_financial_audit_service(
 p_limit integer DEFAULT 25
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO '' AS $audit$
DECLARE
 v_pending jsonb;
 v_total bigint;
 v_unknown bigint;
 v_max_exposure bigint;
 v_orphan_quota bigint;
BEGIN
 IF (auth.jwt()->>'role') IS DISTINCT FROM 'service_role' THEN
  RETURN jsonb_build_object('ok',false,'reason','not_authorized');
 END IF;
 IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 100 THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_limit');
 END IF;
 -- Deliberately works even when PC3/PC4 release switches are OFF:
 -- operators must be able to audit liabilities after an emergency shutdown.
 SELECT count(*),
   count(*) FILTER(WHERE r.status='unknown' OR b.state='unknown'),
   coalesce(sum(CASE WHEN b.state='charged' THEN
      coalesce(b.actual_microusd,0)
      WHEN b.state IN('reserved','dispatched','unknown')
        THEN coalesce(b.held_microusd,0) ELSE 0 END),0),
   count(*) FILTER(WHERE r.status='void' AND q.state='reserved')
 INTO v_total,v_unknown,v_max_exposure,v_orphan_quota
 FROM private.iclub_ai_practice_receipts_v1 r
 LEFT JOIN private.iclub_ai_v21_freeform_budget_ledger b
   ON b.request_id=r.request_id AND b.user_id=r.user_id
   AND b.request_fingerprint=r.request_fingerprint
 LEFT JOIN private.iclub_ai_v21_freeform_quota_holds q
   ON q.request_id=r.request_id AND q.user_id=r.user_id
   AND q.request_fingerprint=r.request_fingerprint
 -- Even a closed/void receipt may retain an unresolved money hold after
 -- a network failure. Include it in reserved exposure until proven settled.
 WHERE r.status IN('registered','dispatched','ready','acknowledged','unknown')
    OR b.state IN('reserved','dispatched','unknown')
    OR q.state='reserved';
 SELECT coalesce(jsonb_agg(entry ORDER BY created_at,request_id), '[]'::jsonb)
 INTO v_pending FROM (
  SELECT x.received_at AS created_at,x.request_id,
   jsonb_build_object(
    'request_id',x.request_id,
    'receipt_state',x.status,
    'money_state',coalesce(b.state,'missing'),
    'quota_state',coalesce(q.state,'missing'),
    'age_seconds',greatest(0,floor(extract(epoch from
      (clock_timestamp()-x.received_at)))::bigint),
    'maximum_possible_microusd',CASE
       WHEN b.state='charged' THEN coalesce(b.actual_microusd,0)
       WHEN b.state IN('reserved','dispatched','unknown')
         THEN coalesce(b.held_microusd,0)
       ELSE 0 END,
    'action',CASE
      WHEN x.status='unknown' OR b.state='unknown'
        THEN 'confirm_external_provider_charge_manually'
      WHEN x.status='void' AND b.state IN('reserved','dispatched')
        THEN 'investigate_closed_receipt_with_open_money_hold'
      WHEN x.status='void' AND q.state='reserved'
        THEN 'investigate_closed_receipt_with_reserved_learner_quota'
      WHEN x.status='void' AND b.state='charged'
        THEN 'investigate_charged_receipt_marked_void'
      WHEN b.request_id IS NULL OR q.request_id IS NULL
        THEN 'investigate_missing_canonical_ledger'
      WHEN x.status='dispatched'
        THEN 'do_not_retry_provider_manual_check'
      WHEN x.status='registered'
        THEN 'investigate_unfinished_reservation'
      WHEN x.status='ready'
        THEN 'replay_original_receipt_do_not_regenerate'
      WHEN x.status='acknowledged'
        THEN 'verify_quota_settlement'
      ELSE 'review_needed' END
   ) entry
  FROM private.iclub_ai_practice_receipts_v1 x
  LEFT JOIN private.iclub_ai_v21_freeform_budget_ledger b
    ON b.request_id=x.request_id AND b.user_id=x.user_id
    AND b.request_fingerprint=x.request_fingerprint
  LEFT JOIN private.iclub_ai_v21_freeform_quota_holds q
    ON q.request_id=x.request_id AND q.user_id=x.user_id
    AND q.request_fingerprint=x.request_fingerprint
  WHERE (x.status='unknown' OR b.state='unknown')
     OR (x.status='void' AND b.state IN('reserved','dispatched','charged'))
     OR (x.status='void' AND q.state='reserved')
     OR (x.status='dispatched' AND x.dispatched_at <
          clock_timestamp()-interval '5 minutes')
     OR (x.status='registered' AND x.received_at <
          clock_timestamp()-interval '10 minutes')
     OR (x.status='ready' AND x.stored_at <
          clock_timestamp()-interval '1 hour')
     OR (x.status='acknowledged' AND x.quota_confirmed_at IS NULL
          AND x.acknowledged_at < clock_timestamp()-interval '10 minutes')
     OR b.request_id IS NULL OR q.request_id IS NULL
  ORDER BY x.received_at ASC,x.request_id ASC LIMIT p_limit
 ) k;
 RETURN jsonb_build_object(
   'ok',true,'mode','read_only_financial_audit',
   'pending_count',jsonb_array_length(v_pending),
   'total_receipts_monitored',v_total,
   'unknown_count',v_unknown,
   'orphaned_quota_count',v_orphan_quota,
   'maximum_possible_microusd',v_max_exposure,
   'items',v_pending,
   'billing_attribution','no_automatic_per_request_cost_lookup',
   'automatic_write_performed',false);
END;
$audit$;
REVOKE ALL ON FUNCTION public.iclub_ai_practice_pc4_financial_audit_service(integer)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_ai_practice_pc4_financial_audit_service(integer)
 TO service_role;

-- END reviewed source: iclub_ai_practice_pc4_financial_audit_dormant.sql
COMMIT;
