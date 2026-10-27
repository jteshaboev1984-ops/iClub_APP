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
