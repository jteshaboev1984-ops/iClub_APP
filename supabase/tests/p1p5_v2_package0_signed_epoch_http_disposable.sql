-- Issue #450 P0-13: REAL SIGNED JWT HTTP EPOCH FENCE, DISPOSABLE PG17 ONLY.
-- NOT A PRODUCTION MIGRATION. Never execute via Supabase project connector.
-- This isolated test model never reads/writes real Exam Prep academic tables.
\set ON_ERROR_STOP on
DO $guard$
BEGIN
 IF current_database()<>'postgres'
 OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR (SELECT count(*) FROM public.users)<>2
 OR (SELECT count(*) FROM auth.users)<>2
 OR NOT EXISTS(SELECT 1 FROM public.users
   WHERE id='11111111-1111-4111-8111-111111111191'::uuid)
 OR NOT EXISTS(SELECT 1 FROM public.users
   WHERE id='22222222-2222-4222-8222-222222222292'::uuid)
 THEN RAISE EXCEPTION 'P0-13 REFUSED: disposable two-user PG17 only'; END IF;
 IF to_regclass('private.p0_13_epoch_gate') IS NOT NULL
 OR to_regclass('private.p0_13_fake_write_events') IS NOT NULL
 THEN RAISE EXCEPTION 'P0-13 duplicate fake fixture'; END IF;
END $guard$;

CREATE TABLE private.p0_13_epoch_gate(
 program text PRIMARY KEY,
 epoch int NOT NULL CHECK(epoch>=1),
 paused boolean NOT NULL DEFAULT false
);
CREATE TABLE private.p0_13_fake_write_events(
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 user_id uuid NOT NULL,
 program text NOT NULL,
 epoch int NOT NULL,
 request_key text NOT NULL,
 payload_digest text NOT NULL,
 UNIQUE(user_id,program,epoch,request_key)
);
ALTER TABLE private.p0_13_epoch_gate ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.p0_13_fake_write_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.p0_13_epoch_gate FROM public,anon,authenticated;
REVOKE ALL ON private.p0_13_fake_write_events FROM public,anon,authenticated;
INSERT INTO private.p0_13_epoch_gate(program,epoch,paused)
VALUES ('math_as_p1_p5',1,false),('economics_as',1,false);

-- Test-only public RPC runs against *fabricated* tables. Its access guard
-- intentionally checks both signed auth.uid() AND the exact disposable
-- environment; no client controlled role/owner id or fake GUC can substitute.
CREATE OR REPLACE FUNCTION public.p0_13_submit_signed_epoch_test_v1(
 p_epoch int,p_request_key text,p_payload_digest text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $rpc$
DECLARE
 v_uid uuid;
 v_epoch int;
 v_paused boolean;
 v_added bigint;
 v_old text;
BEGIN
 IF current_database()<>'postgres'
    OR (SELECT count(*) FROM public.users)<>2
    OR (SELECT count(*) FROM auth.users)<>2
 THEN RAISE EXCEPTION 'disposable_only' USING ERRCODE='42501'; END IF;
 v_uid:=auth.uid();
 IF v_uid IS DISTINCT FROM '11111111-1111-4111-8111-111111111191'::uuid
 THEN RAISE EXCEPTION 'owner_only_test' USING ERRCODE='42501'; END IF;
 IF p_epoch IS NULL OR p_epoch<1
 OR length(coalesce(p_request_key,''))<5 OR length(p_request_key)>80
 OR coalesce(p_payload_digest,'') !~ '^[a-f0-9]{64}$'
 THEN RAISE EXCEPTION 'invalid_test_request' USING ERRCODE='22023'; END IF;

 -- FOR SHARE serializes learner writes with the future maintenance cutover
 -- UPDATE/epoch transition (which takes the opposing row lock).
 SELECT g.epoch,g.paused INTO v_epoch,v_paused
 FROM private.p0_13_epoch_gate g
 WHERE g.program='math_as_p1_p5'
 FOR SHARE;
 IF NOT FOUND OR v_paused OR v_epoch IS DISTINCT FROM p_epoch THEN
   RAISE EXCEPTION 'stale_or_paused_academic_epoch' USING ERRCODE='PT409';
 END IF;

 INSERT INTO private.p0_13_fake_write_events
   (user_id,program,epoch,request_key,payload_digest)
 VALUES(v_uid,'math_as_p1_p5',p_epoch,p_request_key,p_payload_digest)
 ON CONFLICT(user_id,program,epoch,request_key) DO NOTHING
 RETURNING id INTO v_added;

 IF v_added IS NULL THEN
   SELECT f.payload_digest INTO v_old
   FROM private.p0_13_fake_write_events f
   WHERE f.user_id=v_uid AND f.program='math_as_p1_p5'
      AND f.epoch=p_epoch AND f.request_key=p_request_key;
   IF v_old IS DISTINCT FROM p_payload_digest THEN
     RAISE EXCEPTION 'conflicting_duplicate_test_payload' USING ERRCODE='PT409';
   END IF;
 END IF;
 RETURN jsonb_build_object('contract_version','p0_13_disposable_only',
   'epoch',p_epoch,'duplicate',v_added IS NULL,
   'accepted',true);
END $rpc$;
REVOKE ALL ON FUNCTION public.p0_13_submit_signed_epoch_test_v1(int,text,text)
 FROM public,anon;
GRANT EXECUTE ON FUNCTION public.p0_13_submit_signed_epoch_test_v1(int,text,text)
 TO authenticated;

DO $rights$
BEGIN
 IF has_table_privilege('authenticated','private.p0_13_fake_write_events','INSERT')
 OR has_table_privilege('authenticated','private.p0_13_epoch_gate','UPDATE')
 OR has_function_privilege('anon','public.p0_13_submit_signed_epoch_test_v1(integer,text,text)','EXECUTE')
 THEN RAISE EXCEPTION 'P0-13 direct client mutation / anon gate open'; END IF;
 RAISE NOTICE 'PASS P0-13 disposable owner-only signed JWT epoch model installed';
END $rights$;
