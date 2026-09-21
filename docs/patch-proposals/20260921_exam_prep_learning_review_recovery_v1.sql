-- REVIEW PROPOSAL ONLY; run after same-pack start proposal in isolated CI.
-- Add review sessions to the existing read-only recovery RPC, without replacing
-- its public name, owner checks, first-unanswered answer discovery or Core scope.
BEGIN;
DO $patch$
DECLARE v_oid oid;
 v_def text;
 v_old text;
 v_new text;
BEGIN
 IF to_regclass('private.exam_prep_learning_review_starts_v1') IS NULL THEN
  RAISE EXCEPTION 'learning_review_recovery_missing_ledger';
 END IF;
 v_oid:=to_regprocedure('public.get_exam_prep_active_plan_session_safe_v1(text)');
 IF v_oid IS NULL THEN RAISE EXCEPTION 'learning_review_recovery_missing_rpc'; END IF;
 v_def:=pg_get_functiondef(v_oid);
 v_old:='and a.academic_credit is true';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>2*length(v_old) THEN
  RAISE EXCEPTION 'learning_review_recovery_credit_anchor_drift';
 END IF;
 v_new:='and (a.academic_credit is true OR (a.academic_credit is false AND a.credit_context=''learning_review''))';
 v_def:=replace(v_def,v_old,v_new);
 v_old:='and a.plan_id is not null';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>2*length(v_old) THEN
  RAISE EXCEPTION 'learning_review_recovery_plan_anchor_drift'; END IF;
 v_new:='and (a.plan_id is not null OR EXISTS(SELECT 1 FROM private.exam_prep_learning_review_starts_v1 rr '
  ||'WHERE rr.authorization_id=a.id AND rr.user_id=a.user_id AND rr.component_code=a.component_code))';
 v_def:=replace(v_def,v_old,v_new);
 v_old:='where p.id = v_auth.plan_id';
 IF position(v_old in v_def)=0 THEN RAISE EXCEPTION 'learning_review_recovery_plan_join_drift'; END IF;
 v_def:=replace(v_def,v_old,
  'where p.id = coalesce(v_auth.plan_id,(SELECT rr.plan_id FROM private.exam_prep_learning_review_starts_v1 rr '
  ||'WHERE rr.authorization_id=v_auth.id AND rr.user_id=v_uid))');
 v_old:='''source_plan_id'', v_auth.plan_id';
 IF position(v_old in v_def)=0 THEN RAISE EXCEPTION 'learning_review_recovery_plan_return_drift'; END IF;
 v_def:=replace(v_def,v_old,
  '''source_plan_id'', coalesce(v_auth.plan_id,(SELECT rr.plan_id FROM private.exam_prep_learning_review_starts_v1 rr '
  ||'WHERE rr.authorization_id=v_auth.id AND rr.user_id=v_uid))');
 v_old:='''source_plan_priority_order'', v_auth.plan_priority_order';
 IF position(v_old in v_def)=0 THEN RAISE EXCEPTION 'learning_review_recovery_priority_return_drift'; END IF;
 v_def:=replace(v_def,v_old,
  '''source_plan_priority_order'', coalesce(v_auth.plan_priority_order,(SELECT rr.priority_order FROM private.exam_prep_learning_review_starts_v1 rr '
  ||'WHERE rr.authorization_id=v_auth.id AND rr.user_id=v_uid))');
 EXECUTE v_def;
END;$patch$;
-- Original authenticated access and anon denial are preserved by CREATE OR REPLACE.
DO $verify$
BEGIN
 IF has_function_privilege('anon','public.get_exam_prep_active_plan_session_safe_v1(text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.get_exam_prep_active_plan_session_safe_v1(text)','EXECUTE') THEN
  RAISE EXCEPTION 'learning_review_recovery_acl_changed';
 END IF;
END;$verify$;
COMMIT;
