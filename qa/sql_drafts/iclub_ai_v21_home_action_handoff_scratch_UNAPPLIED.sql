-- §108: disposable LOCAL PostgreSQL only; one-use Home handoff records.
-- NEVER install this file on Supabase or production.
DO $scratch_guard$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$' THEN
  RAISE EXCEPTION 'STOP: one-use handoff only in disposable scratch';
 END IF;
END $scratch_guard$;

CREATE TABLE private.iclub_ai_v21_home_action_handoffs_scratch(
 token_sha256 text PRIMARY KEY CHECK(token_sha256 ~ '^[0-9a-f]{64}$'),
 owner_id uuid NOT NULL,
 context_handle uuid NOT NULL,
 locale text NOT NULL CHECK(locale IN ('ru','uz','en')),
 screen_revision bigint NOT NULL CHECK(screen_revision>0),
 expires_at timestamptz NOT NULL,
 signed_plan jsonb NOT NULL,
 allowed_choices jsonb NOT NULL,
 consumed_at timestamptz,
 selected_action text,
 selected_subject text,
 created_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT handoff_choice_type CHECK(jsonb_typeof(allowed_choices)='array'),
 CONSTRAINT handoff_plan_type CHECK(jsonb_typeof(signed_plan)='object'),
 CONSTRAINT handoff_consumption_integrity CHECK(
   (consumed_at IS NULL AND selected_action IS NULL AND selected_subject IS NULL)
   OR (consumed_at IS NOT NULL AND selected_action IS NOT NULL
       AND selected_subject IS NOT NULL))
);
REVOKE ALL ON private.iclub_ai_v21_home_action_handoffs_scratch
 FROM PUBLIC,anon,authenticated;
CREATE INDEX iclub_ai_v21_home_action_owner_context_scratch_idx
 ON private.iclub_ai_v21_home_action_handoffs_scratch
 (owner_id,context_handle,expires_at);
