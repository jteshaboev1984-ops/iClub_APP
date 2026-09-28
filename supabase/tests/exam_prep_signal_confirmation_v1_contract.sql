-- Read-only structural contract for Stage-0 screening-signal confirmation.
-- Confirmation must come only from later governed academic-credit learning evidence.
begin;
do $$
declare
  v_confirmed text;
  v_queue text;
begin
  if to_regprocedure('private.exam_prep_diagnostic_signal_confirmed_v1(uuid,text,text,timestamptz)') is null then
    raise exception 'signal_confirmation_v1 helper missing';
  end if;

  v_confirmed:=pg_get_functiondef(
    'private.exam_prep_diagnostic_signal_confirmed_v1(uuid,text,text,timestamptz)'::regprocedure
  );
  v_queue:=pg_get_functiondef(
    'private.exam_prep_correction_queue_payload_v1(uuid,text)'::regprocedure
  );

  if position('sa.academic_credit=true' in v_confirmed)=0
     or position('learning_review' in v_confirmed)=0
     or position('sa.correction_case_id is null' in v_confirmed)=0
     or position('s.session_type=''learning''' in v_confirmed)=0
     or position('s.status=''finalized''' in v_confirmed)=0
     or position('after_signal.verification_status=''app_verified''' in v_confirmed)=0
     or position('after_signal.created_at>=p_signal_at' in v_confirmed)=0
     or position('count(*) filter(where si.item_kind=''question'')>=3' in v_confirmed)=0
     or position('r.is_correct is true' in v_confirmed)=0
     or position('count(*) filter(where si.item_kind=''written'')>=1' in v_confirmed)=0
     or position('r.response_kind=''written''' in v_confirmed)=0
     or position('c.status=''resolved''' in v_confirmed)=0
     or position('c.resolved_at>=p_signal_at' in v_confirmed)=0
  then
    raise exception 'signal_confirmation_v1 governed-learning evidence contract missing';
  end if;

  if position('exam_prep_diagnostic_signal_confirmed_v1' in v_queue)=0
     or position('focus_rank<=5' in v_queue)=0
     or position('diagnostic_screening' in v_queue)=0
  then
    raise exception 'signal_confirmation_v1 queue projection contract missing';
  end if;

  if to_regprocedure('public.authorize_exam_prep_signal_confirmation_safe_v1(text,text)') is not null
     or to_regprocedure('public.start_exam_prep_signal_confirmation_session_safe_v1(uuid,text)') is not null
  then
    raise exception 'signal_confirmation_v1 must not create a parallel public learning route';
  end if;
end $$;
rollback;
