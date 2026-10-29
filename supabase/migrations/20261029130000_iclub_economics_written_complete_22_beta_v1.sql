-- Economics 9708: complete the governed written-practice QUESTION BANK for existing beta entitlement.
-- No public release, no automatic essay marking, no change to completed/started plan items.
-- Approval: architect explicitly requested full review and opening of the ten held exercises.
-- Version: economics_9708_written_editorial_candidate_v3_20261027 (immutable).
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='80s';

DO $pre$
DECLARE
 v_all text[]:=ARRAY[
  'P2.A.a','P2.A.b','P2.A.c','P2.A.d','P2.A.e','P2.A.f',
  'P2.B1.a','P2.B1.b','P2.B2.a','P2.B2.b',
  'P2.C1.a','P2.C1.b','P2.C2.a','P2.C2.b',
  'P4.A.a','P4.A.b','P4.A.c','P4.A.d',
  'P4.B1','P4.B2','P4.C1','P4.C2'
 ];
 v_held text[]:=ARRAY[
  'P2.B1.b','P2.B2.a','P2.B2.b',
  'P2.C1.b','P2.C2.a','P2.C2.b',
  'P4.A.b','P4.A.d','P4.B2','P4.C2'
 ];
 v_total integer;
 v_ready integer;
 v_unreleased integer;
 v_reserved integer;
 v_invalid integer;
BEGIN
 SELECT count(*),
        count(*) FILTER(WHERE NOT t.release_enabled),
        count(*) FILTER(WHERE t.task_key=ANY(v_held) AND NOT t.release_enabled),
        count(*) FILTER(
          WHERE t.status='approved'
            AND t.academic_review='approved'
            AND t.language_review='approved'
            AND t.source_review='approved'
            AND t.questions ?& ARRAY['en','ru','uz']
            AND t.answer_requirements ?& ARRAY['en','ru','uz']
            AND jsonb_typeof(t.questions)='object'
            AND jsonb_typeof(t.answer_requirements)='object'
            AND private.iclub_exam_written_source_ready_v1(
              t.program_key,t.version_key,t.task_key,t.task_version)
            AND m.max_marks BETWEEN 1 AND 20
            AND m.ao12_marks+m.ao3_marks=m.max_marks
            AND m.task_sha256=encode(pg_catalog.sha256(pg_catalog.convert_to(
              t.questions::text||'|'||t.answer_requirements::text,'UTF8')),'hex')
        )
 INTO v_total,v_unreleased,v_reserved,v_ready
 FROM private.iclub_exam_core_written_tasks_v1 t
 LEFT JOIN private.iclub_exam_written_mark_scheme_v1 m
 ON m.program_key=t.program_key AND m.version_key=t.version_key
  AND m.task_key=t.task_key AND m.task_version=t.task_version
 WHERE t.program_key='economics_9708'
   AND t.version_key='economics_2026_2028_v1'
   AND t.task_version='economics_9708_written_editorial_candidate_v3_20261027'
   AND t.task_key=ANY(v_all);
 IF v_total<>22 OR v_unreleased<>10 OR v_reserved<>10 OR v_ready<>22
 THEN RAISE EXCEPTION 'Written 22-bank QA gate failed: total %, held %, intended %, ready %',
  v_total,v_unreleased,v_reserved,v_ready; END IF;
 IF (SELECT count(DISTINCT task_key) FROM private.iclub_exam_core_written_tasks_v1
    WHERE program_key='economics_9708'
      AND task_version='economics_9708_written_editorial_candidate_v3_20261027')<>22
 THEN RAISE EXCEPTION 'Unexpected task keys outside the approved 22'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
    WHERE program_key='economics_9708' AND release_enabled)<>12
 THEN RAISE EXCEPTION 'Previous 12-task release baseline changed'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
    WHERE program_key='economics_9708'
    AND task_version<>'economics_9708_written_editorial_candidate_v3_20261027'
    AND release_enabled)<>0
 THEN RAISE EXCEPTION 'Legacy draft unexpectedly released'; END IF;
 IF (SELECT sum(m.max_marks) FROM private.iclub_exam_written_mark_scheme_v1 m
     WHERE m.program_key='economics_9708' AND m.task_key LIKE 'P2.A.%')<>20 OR
    (SELECT sum(m.max_marks) FROM private.iclub_exam_written_mark_scheme_v1 m
     WHERE m.program_key='economics_9708' AND m.task_key LIKE 'P4.A.%')<>20
 THEN RAISE EXCEPTION 'Cambridge source-data section maximum not 20'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_written_source_cards_v1
     WHERE program_key='economics_9708' AND status='approved'
      AND release_enabled AND academic_review='approved'
      AND language_review='approved' AND source_review='approved')<>2
 THEN RAISE EXCEPTION 'Versioned P2/P4 source cards not fully approved'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_econ_written_beta_control_v1
    WHERE singleton AND enabled AND max_members=3)
 THEN RAISE EXCEPTION 'Existing controlled beta guard changed'; END IF;
 IF has_table_privilege('authenticated','private.iclub_exam_written_mark_scheme_v1','SELECT')
 OR has_function_privilege('anon','public.iclub_exam_written_criteria_v1(uuid,text,text,uuid,text)','EXECUTE')
 THEN RAISE EXCEPTION 'Exam assessment criteria permissions weakened'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_plans_v1
     WHERE program_key='economics_9708' AND status='active')>3
 THEN RAISE EXCEPTION 'Unexpected number of active written beta plans'; END IF;
END;$pre$;

-- Make ten previously approved *practice parts* available only to already authorized owners.
-- 22 tasks are NOT a full syllabus, actual official Cambridge exam, or general public launch.
UPDATE private.iclub_exam_core_written_tasks_v1
SET release_enabled=true
WHERE program_key='economics_9708'
 AND version_key='economics_2026_2028_v1'
 AND task_version='economics_9708_written_editorial_candidate_v3_20261027'
 AND task_key IN (
  'P2.B1.b','P2.B2.a','P2.B2.b',
  'P2.C1.b','P2.C2.a','P2.C2.b',
  'P4.A.b','P4.A.d','P4.B2','P4.C2'
 )
 AND release_enabled=false;

-- Existing active plans: preserve ALL 12 original rows, order, status, tokens,
-- open/advanced timestamps and unique progress keys. Append only held items
-- as a follow-on module: P2 missing parts first, then P4 missing parts.
DO $extend$
DECLARE
 p record; n integer; v_last integer; v_keys text[];
 v_held text[]:=ARRAY[
  'P2.B1.b','P2.B2.a','P2.B2.b',
  'P2.C1.b','P2.C2.a','P2.C2.b',
  'P4.A.b','P4.A.d','P4.B2','P4.C2'
 ];
BEGIN
 FOR p IN
  SELECT id,learner_user_id,program_key,version_key FROM
   private.iclub_exam_core_written_plans_v1
  WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
   AND status='active'
  ORDER BY id FOR UPDATE
 LOOP
  SELECT count(*),COALESCE(max(priority_order),0) INTO n,v_last
  FROM private.iclub_exam_core_written_plan_items_v1
  WHERE plan_id=p.id;
  IF n=22 THEN
   IF (SELECT count(DISTINCT task_key) FROM private.iclub_exam_core_written_plan_items_v1
      WHERE plan_id=p.id)<>22 THEN RAISE EXCEPTION 'Unexpected duplicate upgraded plan'; END IF;
   CONTINUE;
  END IF;
  IF n<>12 OR v_last<>12
  THEN RAISE EXCEPTION 'Existing plan % not the audited 12-task baseline',p.id; END IF;
  IF (SELECT count(*) FROM private.iclub_exam_core_written_plan_items_v1 i
     WHERE i.plan_id=p.id AND i.task_key=ANY(v_held))<>0
  THEN RAISE EXCEPTION 'An incomplete follow-on already exists for plan %',p.id; END IF;
  IF (SELECT count(*) FROM private.iclub_exam_core_written_plan_items_v1 i
     WHERE i.plan_id=p.id AND i.task_version='economics_9708_written_editorial_candidate_v3_20261027'
      AND i.mode='practice')<>12
  THEN RAISE EXCEPTION 'Old version/mode mismatch for plan %',p.id; END IF;
  INSERT INTO private.iclub_exam_core_written_plan_items_v1 (
    plan_id,learner_user_id,program_key,version_key,task_key,task_version,priority_order,mode
  )
  SELECT p.id,p.learner_user_id,p.program_key,p.version_key,h.key,
   'economics_9708_written_editorial_candidate_v3_20261027',
   v_last+h.ordinal::integer,'practice'
  FROM unnest(v_held) WITH ORDINALITY AS h(key,ordinal);
  IF (SELECT count(*) FROM private.iclub_exam_core_written_plan_items_v1 WHERE plan_id=p.id)<>22
  THEN RAISE EXCEPTION 'Follow-on task append incomplete for plan %',p.id; END IF;
 END LOOP;
END;$extend$;

-- New plans: complete P2 first (all source parts, four structured essay pairs),
-- followed by complete P4 (four source parts + two B/C alternatives).
-- Same owner/beta/expiry checks as the existing start_v2 RPC. No consent row or new UI.
CREATE OR REPLACE FUNCTION public.iclub_econ_written_start_v2()
 RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $start$
DECLARE v_user uuid:=auth.uid(); v_ctl record; v_plan uuid;
 v_keys text[]:=ARRAY[
  'P2.A.a','P2.A.b','P2.A.c','P2.A.d','P2.A.e','P2.A.f',
  'P2.B1.a','P2.B1.b','P2.B2.a','P2.B2.b',
  'P2.C1.a','P2.C1.b','P2.C2.a','P2.C2.b',
  'P4.A.a','P4.A.b','P4.A.c','P4.A.d',
  'P4.B1','P4.B2','P4.C1','P4.C2'
 ];
 v_task_version text:='economics_9708_written_editorial_candidate_v3_20261027';
 v_program text:='economics_9708'; v_version text:='economics_2026_2028_v1';
BEGIN
 IF v_user IS NULL THEN RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 SELECT enabled,max_members INTO v_ctl FROM
 private.iclub_econ_written_beta_control_v1 WHERE singleton FOR UPDATE;
 IF NOT FOUND OR NOT v_ctl.enabled THEN RETURN jsonb_build_object('ok',false,'code','beta_closed'); END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plans_v1 p
   JOIN private.iclub_exam_core_written_access_v1 a
   ON a.learner_user_id=p.learner_user_id AND a.program_key=p.program_key
   AND a.version_key=p.version_key
   WHERE p.learner_user_id=v_user AND p.program_key=v_program
   AND p.version_key=v_version AND p.status='active'
   AND a.status='active' AND a.core_access
   AND (a.valid_until IS NULL OR a.valid_until>now()))
 THEN RETURN jsonb_build_object('ok',true,'joined',true,'replayed',true); END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_econ_written_beta_optins_v1
   WHERE user_id=v_user AND status='withdrawn')
 THEN RETURN jsonb_build_object('ok',false,'code','existing_withdrawn_plan'); END IF;
 IF NOT private.iclub_econ_written_beta_eligible_v1(v_user)
 THEN RETURN jsonb_build_object('ok',false,'code','not_eligible'); END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_access_v1
      WHERE program_key=v_program AND version_key=v_version)>=v_ctl.max_members
 THEN RETURN jsonb_build_object('ok',false,'code','beta_full'); END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_core_written_access_v1
   WHERE learner_user_id=v_user AND program_key=v_program AND version_key=v_version)
 OR EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plans_v1
   WHERE learner_user_id=v_user AND program_key=v_program AND version_key=v_version)
 THEN RETURN jsonb_build_object('ok',false,'code','existing_written_plan'); END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1 t
  WHERE t.program_key=v_program AND t.version_key=v_version
  AND t.task_version=v_task_version AND t.task_key=ANY(v_keys)
  AND t.status='approved' AND t.release_enabled
  AND t.academic_review='approved' AND t.language_review='approved'
  AND t.source_review='approved' AND t.questions ?& ARRAY['en','ru','uz']
  AND t.answer_requirements ?& ARRAY['en','ru','uz']
  AND private.iclub_exam_written_source_ready_v1(
    t.program_key,t.version_key,t.task_key,t.task_version)
 )<>22 THEN RETURN jsonb_build_object('ok',false,'code','beta_content_unavailable'); END IF;
 INSERT INTO private.iclub_exam_core_written_access_v1
  (learner_user_id,program_key,version_key,core_access,status,valid_from,valid_until)
 VALUES(v_user,v_program,v_version,true,'active',now(),now()+INTERVAL '28 days');
 INSERT INTO private.iclub_exam_core_written_plans_v1
  (learner_user_id,program_key,version_key,status)
 VALUES(v_user,v_program,v_version,'active') RETURNING id INTO v_plan;
 INSERT INTO private.iclub_exam_core_written_plan_items_v1
  (plan_id,learner_user_id,program_key,version_key,task_key,task_version,priority_order,mode)
 SELECT v_plan,v_user,v_program,v_version,k,v_task_version,i::integer,'practice'
 FROM unnest(v_keys) WITH ORDINALITY AS v(k,i);
 RETURN jsonb_build_object('ok',true,'joined',true,'replayed',false);
END;
$start$;
REVOKE ALL ON FUNCTION public.iclub_econ_written_start_v2() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_econ_written_start_v2() TO authenticated;

DO $post$
BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
    WHERE program_key='economics_9708' AND task_version='economics_9708_written_editorial_candidate_v3_20261027'
    AND release_enabled)<>22
 THEN RAISE EXCEPTION 'Expected exactly 22 controlled written tasks'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
    WHERE program_key='economics_9708' AND task_version<>'economics_9708_written_editorial_candidate_v3_20261027'
     AND release_enabled)<>0
 THEN RAISE EXCEPTION 'Historical draft released inadvertently'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plans_v1 p
   JOIN private.iclub_exam_core_written_plan_items_v1 i ON i.plan_id=p.id
   WHERE p.program_key='economics_9708' AND p.status='active'
   GROUP BY p.id HAVING count(*)<>22 OR count(DISTINCT i.task_key)<>22)
 THEN RAISE EXCEPTION 'Active written plan incomplete or duplicated'; END IF;
 IF has_function_privilege('anon','public.iclub_econ_written_start_v2()','EXECUTE')
 THEN RAISE EXCEPTION 'Unexpected public written enrollment'; END IF;
END;$post$;
COMMIT;
