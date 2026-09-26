-- Read-only structural contract for Stage-0 screening-signal confirmation.
begin;
do $$
declare
  v_authorizer text;
  v_confirmed text;
  v_queue text;
  v_reconcile text;
begin
  if to_regprocedure('private.exam_prep_diagnostic_signal_confirmed_v1(uuid,text,text,timestamptz)') is null
     or to_regprocedure('public.authorize_exam_prep_signal_confirmation_safe_v1(text,text)') is null
  then
    raise exception 'signal_confirmation_v1 functions missing';
  end if;

  if has_function_privilege('anon','public.authorize_exam_prep_signal_confirmation_safe_v1(text,text)','EXECUTE')
     or not has_function_privilege('authenticated','public.authorize_exam_prep_signal_confirmation_safe_v1(text,text)','EXECUTE')
  then
    raise exception 'signal_confirmation_v1 public ACL mismatch';
  end if;

  v_authorizer:=pg_get_functiondef('public.authorize_exam_prep_signal_confirmation_safe_v1(text,text)'::regprocedure);
  v_confirmed:=pg_get_functiondef('private.exam_prep_diagnostic_signal_confirmed_v1(uuid,text,text,timestamptz)'::regprocedure);
  v_queue:=pg_get_functiondef('private.exam_prep_correction_queue_payload_v1(uuid,text)'::regprocedure);
  v_reconcile:=pg_get_functiondef('private.exam_prep_reconcile_finalized_session_v1()'::regprocedure);

  if position('stage0_complete=true' in v_authorizer)=0
     or position('focus_kind''=''screening_signal' in v_authorizer)=0
     or position('first_learning_pack_already_seen' in v_authorizer)=0
     or position('false,''signal_confirmation''' in v_authorizer)=0
     or position('uses_retest_reserve' in v_authorizer)=0
     or position('signal_confirmation' in v_authorizer)=0
     or position('count(*) filter(where ai.question_id is not null)' in v_authorizer)=0
  then
    raise exception 'signal_confirmation_v1 authorizer guard missing';
  end if;

  if position('sa.academic_credit=false' in v_confirmed)=0
     or position('sa.credit_context=''signal_confirmation''' in v_confirmed)=0
     or position('count(*) filter(where si.item_kind=''question'')>=3' in v_confirmed)=0
     or position('r.is_correct is true' in v_confirmed)=0
     or position('count(*) filter(' in v_confirmed)=0
     or position('r.response_kind=''written''' in v_confirmed)=0
     or position('learning_review' in v_confirmed)=0
  then
    raise exception 'signal_confirmation_v1 confirmation evidence contract missing';
  end if;

  if position('exam_prep_diagnostic_signal_confirmed_v1' in v_queue)=0
     or position('focus_rank<=5' in v_queue)=0
  then
    raise exception 'signal_confirmation_v1 queue projection contract missing';
  end if;

  if position('v_auth.credit_context=''signal_confirmation''' in v_reconcile)=0
     or position('app_checked_noncredit' in v_reconcile)=0
  then
    raise exception 'signal_confirmation_v1 failed confirmation correction bridge missing';
  end if;
end $$;
rollback;
