-- P2-77 Mentor Technical Simulation.
-- Validation-only. Requires a disposable database and rolls every synthetic
-- learner/mentor/queue/review/config mutation back.
\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p277.isolated_db',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-77 REFUSED: p277.isolated_db=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE p277_people(
  person_key text PRIMARY KEY,
  user_id uuid NOT NULL UNIQUE,
  identity_kind text NOT NULL CHECK(identity_kind IN ('learner','mentor'))
) ON COMMIT DROP;

-- Preserve deterministic academic-state counts. Mentor Care may add human
-- service records only; it must not manufacture Core evidence/state.
CREATE TEMP TABLE p277_academic_before AS
SELECT
  (SELECT count(*) FROM private.exam_prep_evidence_events) AS evidence_count,
  (SELECT count(*) FROM private.exam_prep_skill_states) AS skill_state_count,
  (SELECT count(*) FROM private.exam_prep_component_placements) AS placement_count,
  (SELECT count(*) FROM private.exam_prep_stage_states) AS stage_count,
  (SELECT count(*) FROM private.exam_prep_retest_events) AS retest_count;

SELECT private.register_exam_prep_synthetic_validation_run_v1(
  'SV-P277-MENTOR-TECH','p277-mentor-technical-v1',repeat('7',40),'p2-77',27701,'mentor_technical',
  'P2-77 rollback-only Mentor Technical Simulation'
);

INSERT INTO p277_people(person_key,user_id,identity_kind) VALUES
('waitlist',private.create_exam_prep_synthetic_identity_v1('SV-P277-MENTOR-TECH','learner','SVF-P277-WAITLIST','p277-waitlist','P2-77 waitlist learner','en'),'learner'),
('no_assignment',private.create_exam_prep_synthetic_identity_v1('SV-P277-MENTOR-TECH','learner','SVF-P277-NOASSIGN','p277-noassign','P2-77 entitled no-assignment learner','en'),'learner'),
('paused',private.create_exam_prep_synthetic_identity_v1('SV-P277-MENTOR-TECH','learner','SVF-P277-PAUSED','p277-paused','P2-77 paused Mentor Care learner','en'),'learner'),
('written',private.create_exam_prep_synthetic_identity_v1('SV-P277-MENTOR-TECH','learner','SVF-P277-WRITTEN','p277-written','P2-77 written judgement learner','en'),'learner'),
('dual',private.create_exam_prep_synthetic_identity_v1('SV-P277-MENTOR-TECH','learner','SVF-P277-DUAL','p277-dual','P2-77 dual-component learner','en'),'learner'),
('override',private.create_exam_prep_synthetic_identity_v1('SV-P277-MENTOR-TECH','learner','SVF-P277-OVERRIDE','p277-override','P2-77 audited override learner','en'),'learner'),
('handover',private.create_exam_prep_synthetic_identity_v1('SV-P277-MENTOR-TECH','learner','SVF-P277-HANDOVER','p277-handover','P2-77 mentor absence and handover learner','en'),'learner'),
('safeguard',private.create_exam_prep_synthetic_identity_v1('SV-P277-MENTOR-TECH','learner','SVF-P277-SAFEGUARD','p277-safeguard','P2-77 safeguarding learner','en'),'learner'),
('mentor_a',private.create_exam_prep_synthetic_identity_v1('SV-P277-MENTOR-TECH','mentor','SVF-P277-MENTORA','p277-mentora','P2-77 primary mentor A','en'),'mentor'),
('mentor_b',private.create_exam_prep_synthetic_identity_v1('SV-P277-MENTOR-TECH','mentor','SVF-P277-MENTORB','p277-mentorb','P2-77 primary mentor B','en'),'mentor'),
('moderator',private.create_exam_prep_synthetic_identity_v1('SV-P277-MENTOR-TECH','mentor','SVF-P277-MODERATOR','p277-moderator','P2-77 independent academic moderator','en'),'mentor'),
('ops',private.create_exam_prep_synthetic_identity_v1('SV-P277-MENTOR-TECH','mentor','SVF-P277-OPS','p277-ops','P2-77 mentor operations actor','en'),'mentor');

-- P2-77 is the first stage that may grant staff authority to synthetic mentor
-- identities. Synthetic learners must still be structurally unable to become staff.
INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
SELECT user_id,'mentor','active' FROM p277_people WHERE person_key IN ('mentor_a','mentor_b');
INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
SELECT user_id,'lead_mentor','active' FROM p277_people WHERE person_key='mentor_a';
INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
SELECT user_id,'academic_moderator','active' FROM p277_people WHERE person_key='moderator';
INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
SELECT user_id,'mentor_ops','active' FROM p277_people WHERE person_key='ops';

DO $$
DECLARE v_blocked boolean:=false; v_uid uuid;
BEGIN
  SELECT user_id INTO v_uid FROM p277_people WHERE person_key='waitlist';
  BEGIN
    INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status) VALUES(v_uid,'mentor','active');
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_staff_role_requires_open_mentor_technical_run' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-77 synthetic learner gained staff authority'; END IF;
END
$$;

DO $$
DECLARE v_iso jsonb;
BEGIN
  v_iso:=private.exam_prep_synthetic_identity_isolation_report_v1();
  IF coalesce((v_iso->>'eligible')::boolean,false) IS NOT TRUE
     OR (v_iso->>'synthetic_staff_role_rows')::int<>4
     OR (v_iso->>'invalid_synthetic_staff_role_rows')::int<>0 THEN
    RAISE EXCEPTION 'P2-77 governed synthetic staff isolation failed: %',v_iso;
  END IF;
END
$$;

-- Enable Mentor Care only inside this transaction. AI stays OFF.
UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=true,kill_switch=false,updated_at=now()
WHERE id=1;

-- All eight learners retain Core. Mentor entitlement is deliberately separate
-- from operational assignment/service state.
INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
)
SELECT user_id,'active',true,false,true,null,now()
FROM p277_people WHERE identity_kind='learner';

INSERT INTO private.exam_prep_mentor_service_status(learner_user_id,service_status,status_reason)
SELECT user_id,
  CASE person_key
    WHEN 'waitlist' THEN 'entitled_waitlist'
    WHEN 'paused' THEN 'assigned_paused'
    ELSE 'assigned_active'
  END,
  'P2-77 isolated service-state fixture'
FROM p277_people WHERE identity_kind='learner';

-- Assignment fixtures. `no_assignment` intentionally receives none.
-- `paused` has a paused P1 assignment. `dual` proves P1/P5 scope can differ.
INSERT INTO private.exam_prep_mentor_assignments(learner_user_id,mentor_user_id,component_code,assignment_status,valid_from)
SELECT l.user_id,m.user_id,x.component_code,x.assignment_status,now()
FROM (VALUES
  ('paused','mentor_a','P1','paused'),
  ('written','mentor_a','P1','active'),
  ('dual','mentor_a','P1','active'),
  ('dual','mentor_b','P5','active'),
  ('override','mentor_a','P1','active'),
  ('handover','mentor_a','P1','active'),
  ('safeguard','mentor_a','P1','active')
) x(learner_key,mentor_key,component_code,assignment_status)
JOIN p277_people l ON l.person_key=x.learner_key
JOIN p277_people m ON m.person_key=x.mentor_key;

-- Entitlement != assignment/service authority matrix.
DO $$
DECLARE r record; c record;
BEGIN
  FOR r IN
    SELECT p.person_key,p.user_id,
      CASE WHEN p.person_key IN ('written','dual','override','handover','safeguard') THEN true ELSE false END expect_assignment
    FROM p277_people p
    WHERE p.person_key IN ('waitlist','no_assignment','paused','written','dual','override','handover','safeguard')
    ORDER BY p.person_key
  LOOP
    PERFORM set_config('request.jwt.claim.sub',r.user_id::text,true);
    PERFORM set_config('request.jwt.claim.role','authenticated',true);
    SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
    IF NOT c.core_access OR c.ai_assist OR NOT c.mentor_care_entitled
       OR c.mentor_assignment_active IS DISTINCT FROM r.expect_assignment
       OR c.mentor_authority IS DISTINCT FROM r.expect_assignment THEN
      RAISE EXCEPTION 'P2-77 capability separation failed learner=% got=% expected_assignment=%',r.person_key,row_to_json(c),r.expect_assignment;
    END IF;
  END LOOP;
END
$$;

-- Recommendations exist for waitlisted/no-assignment/paused learners but must
-- create zero queue/SLA work. Assigned learner/component recommendations queue.
INSERT INTO private.exam_prep_human_review_recommendations(
  learner_user_id,component_code,skill_code,recommendation_type,source_object_type,source_object_id,recommendation_reason
)
SELECT p.user_id,x.component_code,x.skill_code,x.recommendation_type,'p277',x.source_object_id,x.reason
FROM (VALUES
  ('waitlist','P1','P1-QUA-01','written_mastery','waitlist','Waitlisted recommendation is metadata only and must not create human work.'),
  ('no_assignment','P1','P1-QUA-01','written_mastery','no-assignment','Entitlement without assignment must not create human work.'),
  ('paused','P1','P1-QUA-01','written_mastery','paused','Paused assignment must not create new routine human work.'),
  ('written','P1','P1-QUA-01','written_mastery','written','Assigned learner written method requires governed human judgement.'),
  ('dual','P1','P1-QUA-02','written_mastery','dual-p1','P1 human review must remain P1-scoped.'),
  ('dual','P5','P5-NOR-02','written_mastery','dual-p5','P5 human review must remain P5-scoped.'),
  ('override','P1','P1-QUA-02','override_review','override','High-impact override review requires independent second check.'),
  ('handover','P1','P1-QUA-03','written_mastery','handover','Open queue work must survive mentor absence and handover without resetting age.'),
  ('safeguard','P1','P1-QUA-04','written_mastery','safeguard','Safeguarding fixture remains assignment-scoped.')
) x(learner_key,component_code,skill_code,recommendation_type,source_object_id,reason)
JOIN p277_people p ON p.person_key=x.learner_key;

DO $$
DECLARE v_bad int; v_good int;
BEGIN
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p277' AND r.source_object_id IN ('waitlist','no-assignment','paused');
  SELECT count(*) INTO v_good
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p277' AND r.source_object_id IN ('written','dual-p1','dual-p5','override','handover','safeguard');
  IF v_bad<>0 OR v_good<>6 THEN
    RAISE EXCEPTION 'P2-77 queue isolation failed forbidden=% expected_assigned_queues=%',v_bad,v_good;
  END IF;
END
$$;

-- P1/P5 queue ownership is component-scoped even for one learner.
DO $$
DECLARE v_p1 uuid; v_p5 uuid; v_m1 uuid; v_m2 uuid;
BEGIN
  SELECT q.mentor_user_id INTO v_p1
  FROM private.exam_prep_mentor_queue_items q JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p277' AND r.source_object_id='dual-p1';
  SELECT q.mentor_user_id INTO v_p5
  FROM private.exam_prep_mentor_queue_items q JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p277' AND r.source_object_id='dual-p5';
  SELECT user_id INTO v_m1 FROM p277_people WHERE person_key='mentor_a';
  SELECT user_id INTO v_m2 FROM p277_people WHERE person_key='mentor_b';
  IF v_p1 IS DISTINCT FROM v_m1 OR v_p5 IS DISTINCT FROM v_m2 OR v_p1=v_p5 THEN
    RAISE EXCEPTION 'P2-77 P1/P5 mentor scope leaked p1=% p5=%',v_p1,v_p5;
  END IF;
END
$$;

-- Cross-mentor submission is denied before the real primary mentor reviews the
-- written item.
DO $$
DECLARE v_queue uuid; v_wrong uuid; v_blocked boolean:=false;
BEGIN
  SELECT q.id INTO v_queue
  FROM private.exam_prep_mentor_queue_items q JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p277' AND r.source_object_id='written';
  SELECT user_id INTO v_wrong FROM p277_people WHERE person_key='mentor_b';
  PERFORM set_config('request.jwt.claim.sub',v_wrong::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  BEGIN
    PERFORM public.submit_exam_prep_mentor_review_safe_v1(v_queue,'verified','wrong_scope','Wrong mentor must not be able to review this learner item.',4,'{}'::jsonb);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_mentor_queue_not_found' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-77 cross-mentor review was accepted'; END IF;
END
$$;

-- Genuine written judgement through the authenticated mentor RPC.
DO $$
DECLARE v_queue uuid; v_mentor uuid; v_result jsonb; v_review uuid; v_q record;
BEGIN
  SELECT q.id INTO v_queue
  FROM private.exam_prep_mentor_queue_items q JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p277' AND r.source_object_id='written';
  SELECT user_id INTO v_mentor FROM p277_people WHERE person_key='mentor_a';
  PERFORM set_config('request.jwt.claim.sub',v_mentor::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_result:=public.submit_exam_prep_mentor_review_safe_v1(
    v_queue,'verified','rubric_verified','Written method is complete and satisfies the governed P2-77 rubric fixture.',4,
    jsonb_build_object('rubric_version','p277-rubric-v1','judgement_type','written_method')
  );
  v_review:=(v_result->>'review_id')::uuid;
  IF v_result->>'status'<>'final' OR coalesce((v_result->>'requires_second_check')::boolean,true) THEN
    RAISE EXCEPTION 'P2-77 routine written review did not finalize correctly: %',v_result;
  END IF;
  SELECT * INTO v_q FROM private.exam_prep_mentor_queue_items WHERE id=v_queue;
  IF v_q.status<>'resolved' OR v_q.opened_at IS NULL OR v_q.updated_at<v_q.opened_at OR v_q.resolved_at<v_q.opened_at THEN
    RAISE EXCEPTION 'P2-77 routine queue SLA timestamps invalid: %',row_to_json(v_q);
  END IF;
  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_mentor_reviews r
    WHERE r.id=v_review AND r.verified_level=4 AND r.review_status='final'
      AND r.reason_text LIKE 'Written method%'
      AND r.review_scope->>'rubric_version'='p277-rubric-v1'
  ) THEN RAISE EXCEPTION 'P2-77 written judgement record incomplete'; END IF;
END
$$;

-- High-impact override review is append-only, does not mutate Core academic
-- state, and cannot exit without an independent second check.
DO $$
DECLARE v_queue uuid; v_mentor uuid; v_mod uuid; v_result jsonb; v_review uuid; v_blocked boolean:=false; v_sc jsonb;
BEGIN
  SELECT q.id INTO v_queue
  FROM private.exam_prep_mentor_queue_items q JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p277' AND r.source_object_id='override';
  SELECT user_id INTO v_mentor FROM p277_people WHERE person_key='mentor_a';
  SELECT user_id INTO v_mod FROM p277_people WHERE person_key='moderator';

  PERFORM set_config('request.jwt.claim.sub',v_mentor::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_result:=public.submit_exam_prep_mentor_review_safe_v1(
    v_queue,'confirm','high_impact_override','The proposed high-impact override is supported by linked governed evidence.',null,
    jsonb_build_object('override_scope','P1-only','requested_change','human_verification_only')
  );
  v_review:=(v_result->>'review_id')::uuid;
  IF v_result->>'status'<>'pending_second_check' OR coalesce((v_result->>'requires_second_check')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-77 override did not require second check: %',v_result;
  END IF;

  BEGIN
    PERFORM public.submit_exam_prep_second_check_safe_v1(v_review,'confirmed','A reviewer cannot independently second-check their own decision.');
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_second_check_must_be_independent' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-77 original mentor self-second-checked override'; END IF;

  PERFORM set_config('request.jwt.claim.sub',v_mod::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_sc:=public.submit_exam_prep_second_check_safe_v1(
    v_review,'confirmed','Independent moderator confirms the high-impact P1 override review evidence.'
  );
  IF v_sc->>'outcome'<>'confirmed' OR v_sc->>'queue_status'<>'resolved' THEN
    RAISE EXCEPTION 'P2-77 independent second check failed: %',v_sc;
  END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_audit_events a
    WHERE a.event_type='mentor_review_created' AND a.object_id=v_review::text
      AND a.component_code='P1' AND a.before_state IS NOT NULL
      AND a.after_state->>'decision_code'='confirm'
  ) OR NOT EXISTS(
    SELECT 1 FROM private.exam_prep_audit_events a
    WHERE a.event_type='mentor_second_check_created' AND a.target_user_id=(SELECT user_id FROM p277_people WHERE person_key='override')
      AND a.component_code='P1' AND a.after_state->>'outcome'='confirmed'
  ) THEN RAISE EXCEPTION 'P2-77 override/second-check audit chain incomplete'; END IF;
END
$$;

-- Mentor absence pauses only the human assignment. Core stays alive and the
-- open queue item is hidden rather than reassigned silently.
CREATE TEMP TABLE p277_handover_before AS
SELECT q.id queue_item_id,q.opened_at,q.updated_at,q.assignment_id,q.mentor_user_id
FROM private.exam_prep_mentor_queue_items q
JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
WHERE r.source_object_type='p277' AND r.source_object_id='handover';

DO $$
DECLARE v_assignment bigint; v_ops uuid; v_learner uuid; v_result jsonb; c record; v_visible jsonb;
BEGIN
  SELECT assignment_id INTO v_assignment FROM p277_handover_before;
  SELECT user_id INTO v_ops FROM p277_people WHERE person_key='ops';
  SELECT user_id INTO v_learner FROM p277_people WHERE person_key='handover';
  PERFORM set_config('request.jwt.claim.sub',v_ops::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_result:=public.pause_exam_prep_mentor_assignment_safe_v1(v_assignment,'Primary mentor is temporarily unavailable; preserve Core and pending human work.');
  IF v_result->>'assignment_status'<>'paused' THEN RAISE EXCEPTION 'P2-77 pause failed: %',v_result; END IF;

  PERFORM set_config('request.jwt.claim.sub',v_learner::text,true);
  SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
  IF NOT c.core_access OR NOT c.mentor_care_entitled OR c.mentor_assignment_active OR c.mentor_authority THEN
    RAISE EXCEPTION 'P2-77 mentor absence blocked Core or leaked authority: %',row_to_json(c);
  END IF;

  PERFORM set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p277_people WHERE person_key='mentor_a'),true);
  v_visible:=public.get_exam_prep_mentor_queue_safe_v1();
  IF EXISTS(
    SELECT 1 FROM jsonb_array_elements(v_visible) x WHERE x->>'queue_item_id'=(SELECT queue_item_id::text FROM p277_handover_before)
  ) THEN RAISE EXCEPTION 'P2-77 paused assignment still exposed routine queue work'; END IF;
END
$$;

-- Governed handover moves the same open queue item to the replacement mentor,
-- preserves opened_at (SLA age), and leaves the prior assignment/history intact.
DO $$
DECLARE v_old bigint; v_ops uuid; v_new_mentor uuid; v_result jsonb; v_q record; v_before record; v_oldmentor_queue jsonb; v_newmentor_queue jsonb;
BEGIN
  SELECT * INTO v_before FROM p277_handover_before;
  v_old:=v_before.assignment_id;
  SELECT user_id INTO v_ops FROM p277_people WHERE person_key='ops';
  SELECT user_id INTO v_new_mentor FROM p277_people WHERE person_key='mentor_b';
  PERFORM set_config('request.jwt.claim.sub',v_ops::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_result:=public.handover_exam_prep_mentor_assignment_safe_v1(
    v_old,v_new_mentor,'Primary mentor absence requires governed handover without resetting queue age.'
  );
  IF (v_result->>'moved_open_queue_items')::int<>1 OR v_result->>'assignment_status'<>'active' THEN
    RAISE EXCEPTION 'P2-77 handover did not move exactly one open item: %',v_result;
  END IF;

  SELECT * INTO v_q FROM private.exam_prep_mentor_queue_items WHERE id=v_before.queue_item_id;
  IF v_q.mentor_user_id IS DISTINCT FROM v_new_mentor
     OR v_q.assignment_id IS DISTINCT FROM (v_result->>'new_assignment_id')::bigint
     OR v_q.status<>'open'
     OR v_q.opened_at IS DISTINCT FROM v_before.opened_at
     OR v_q.updated_at<v_before.updated_at THEN
    RAISE EXCEPTION 'P2-77 handover queue/SLA preservation failed before=% after=%',row_to_json(v_before),row_to_json(v_q);
  END IF;
  IF NOT EXISTS(SELECT 1 FROM private.exam_prep_mentor_assignments WHERE id=v_old AND assignment_status='ended') THEN
    RAISE EXCEPTION 'P2-77 old assignment was not retained as ended history';
  END IF;
  IF NOT EXISTS(SELECT 1 FROM private.exam_prep_audit_events WHERE event_type='mentor_assignment_paused' AND object_id=v_old::text)
     OR NOT EXISTS(SELECT 1 FROM private.exam_prep_audit_events WHERE event_type='mentor_assignment_handover' AND object_id=(v_result->>'new_assignment_id')) THEN
    RAISE EXCEPTION 'P2-77 pause/handover audit chain missing';
  END IF;

  PERFORM set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p277_people WHERE person_key='mentor_a'),true);
  v_oldmentor_queue:=public.get_exam_prep_mentor_queue_safe_v1();
  IF EXISTS(SELECT 1 FROM jsonb_array_elements(v_oldmentor_queue) x WHERE x->>'queue_item_id'=v_before.queue_item_id::text) THEN
    RAISE EXCEPTION 'P2-77 old mentor retained queue access after handover';
  END IF;
  PERFORM set_config('request.jwt.claim.sub',v_new_mentor::text,true);
  v_newmentor_queue:=public.get_exam_prep_mentor_queue_safe_v1();
  IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(v_newmentor_queue) x WHERE x->>'queue_item_id'=v_before.queue_item_id::text) THEN
    RAISE EXCEPTION 'P2-77 new mentor did not receive handed-over queue item';
  END IF;
END
$$;

-- Safeguarding is assignment-scoped for ordinary mentors and audited. An
-- unrelated mentor must not raise an event against another mentor's assignment.
DO $$
DECLARE v_assignment bigint; v_m1 uuid; v_m2 uuid; v_result jsonb; v_blocked boolean:=false; v_event uuid;
BEGIN
  SELECT a.id INTO v_assignment
  FROM private.exam_prep_mentor_assignments a JOIN p277_people p ON p.user_id=a.learner_user_id
  WHERE p.person_key='safeguard' AND a.component_code='P1' AND a.assignment_status='active';
  SELECT user_id INTO v_m1 FROM p277_people WHERE person_key='mentor_a';
  SELECT user_id INTO v_m2 FROM p277_people WHERE person_key='mentor_b';

  PERFORM set_config('request.jwt.claim.sub',v_m2::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  BEGIN
    PERFORM public.raise_exam_prep_safeguarding_safe_v1(v_assignment,'concern','wrong_scope','Unrelated mentor must not be able to raise this safeguarding event.');
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_safeguarding_assignment_scope_required' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-77 safeguarding cross-assignment scope leaked'; END IF;

  PERFORM set_config('request.jwt.claim.sub',v_m1::text,true);
  v_result:=public.raise_exam_prep_safeguarding_safe_v1(
    v_assignment,'urgent','approved_channel_concern','Urgent safeguarding concern routed through the approved governed escalation path.'
  );
  v_event:=(v_result->>'safeguarding_event_id')::uuid;
  IF v_result->>'status'<>'open' OR v_result->>'severity'<>'urgent' THEN
    RAISE EXCEPTION 'P2-77 safeguarding route failed: %',v_result;
  END IF;
  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_safeguarding_events s
    WHERE s.id=v_event AND s.assignment_id=v_assignment AND s.status='open'
      AND s.created_at IS NOT NULL AND s.updated_at>=s.created_at
  ) OR NOT EXISTS(
    SELECT 1 FROM private.exam_prep_audit_events a
    WHERE a.event_type='safeguarding_escalated' AND a.object_id=v_event::text AND a.metadata->>'severity'='urgent'
  ) THEN RAISE EXCEPTION 'P2-77 safeguarding evidence/audit incomplete'; END IF;
END
$$;

-- Mentor operations must not have altered deterministic academic truth.
DO $$
DECLARE b record; a record;
BEGIN
  SELECT * INTO b FROM p277_academic_before;
  SELECT
    (SELECT count(*) FROM private.exam_prep_evidence_events) AS evidence_count,
    (SELECT count(*) FROM private.exam_prep_skill_states) AS skill_state_count,
    (SELECT count(*) FROM private.exam_prep_component_placements) AS placement_count,
    (SELECT count(*) FROM private.exam_prep_stage_states) AS stage_count,
    (SELECT count(*) FROM private.exam_prep_retest_events) AS retest_count
  INTO a;
  IF row_to_json(a)::text<>row_to_json(b)::text THEN
    RAISE EXCEPTION 'P2-77 Mentor Care mutated deterministic academic state before=% after=%',row_to_json(b),row_to_json(a);
  END IF;
END
$$;

-- Direct learner/browser writes to private mentor tables remain absent.
DO $$
BEGIN
  IF has_table_privilege('authenticated','private.exam_prep_mentor_assignments','INSERT')
     OR has_table_privilege('authenticated','private.exam_prep_mentor_queue_items','UPDATE')
     OR has_table_privilege('authenticated','private.exam_prep_mentor_reviews','INSERT')
     OR has_table_privilege('authenticated','private.exam_prep_mentor_second_checks','INSERT')
     OR has_table_privilege('authenticated','private.exam_prep_safeguarding_events','INSERT') THEN
    RAISE EXCEPTION 'P2-77 authenticated role gained direct private mentor-table write access';
  END IF;
  IF has_function_privilege('anon','public.pause_exam_prep_mentor_assignment_safe_v1(bigint,text)','EXECUTE')
     OR has_function_privilege('anon','public.handover_exam_prep_mentor_assignment_safe_v1(bigint,uuid,text)','EXECUTE')
     OR has_function_privilege('anon','public.submit_exam_prep_mentor_review_safe_v1(uuid,text,text,text,smallint,jsonb)','EXECUTE')
     OR has_function_privilege('anon','public.submit_exam_prep_second_check_safe_v1(uuid,text,text)','EXECUTE')
     OR has_function_privilege('anon','public.raise_exam_prep_safeguarding_safe_v1(bigint,text,text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-77 anon role gained Mentor Care RPC access';
  END IF;
END
$$;

RESET ROLE;
SELECT set_config('request.jwt.claim.sub','',true);
SELECT set_config('request.jwt.claim.role','',true);

ROLLBACK;

-- Rollback/zero-residue proof. Baseline is production-shaped Core ON, AI OFF,
-- Mentor OFF; no P2-77 synthetic identity or human-service row may survive.
DO $$
DECLARE v_count int; v_cfg record;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'exam-prep-sv-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-77 rollback left synthetic auth users=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_synthetic_validation_runs WHERE run_id='SV-P277-MENTOR-TECH';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-77 rollback left synthetic run=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_synthetic_identities WHERE fixture_profile_key LIKE 'SVF-P277-%';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-77 rollback left synthetic identities=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_human_review_recommendations WHERE source_object_type='p277';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-77 rollback left recommendations=%',v_count; END IF;
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta' OR NOT v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P2-77 rollback failed to restore production-shaped Core-only baseline: %',row_to_json(v_cfg);
  END IF;
END
$$;

\echo 'P2-77 Mentor Technical Simulation: GREEN'
