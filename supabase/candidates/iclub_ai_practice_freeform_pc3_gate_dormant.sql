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
  WHERE pc3.singleton=1 AND pc3.enabled AND pc4.enabled AND pc1.enabled
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
