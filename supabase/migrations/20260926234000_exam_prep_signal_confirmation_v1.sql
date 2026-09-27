-- Stage-0 screening-signal confirmation through ordinary governed learning only.
-- No extra learner session type, no non-credit detour, no retest-reserve consumption.
-- The sole governed learning pack for a skill is therefore not spent on a separate check.
-- A diagnostic signal disappears only after a later finalized single-skill academic-credit
-- learning session proves the skill with all machine items correct and the written task completed.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare
  v_queue text;
begin
  if to_regprocedure('private.exam_prep_correction_queue_payload_v1(uuid,text)') is null
     or to_regprocedure('public.get_exam_prep_correction_queue_safe_v1(text)') is null
  then
    raise exception 'signal_confirmation_v1 prerequisite missing';
  end if;

  v_queue:=pg_get_functiondef('private.exam_prep_correction_queue_payload_v1(uuid,text)'::regprocedure);
  if position('diagnostic_screening' in v_queue)=0
     or position('focus_cases' in v_queue)=0
     or position('focus_rank<=5' in v_queue)=0
  then
    raise exception 'signal_confirmation_v1 attention queue contract missing';
  end if;
end
$preflight$;

create or replace function private.exam_prep_diagnostic_signal_confirmed_v1(
  p_user_id uuid,
  p_component_code text,
  p_skill_code text,
  p_signal_at timestamptz
) returns boolean
language sql
stable
security definer
set search_path=''
as $fn$
  select coalesce(
    exists(
      select 1
      from private.exam_prep_sessions s
      join private.exam_prep_session_authorizations sa
        on sa.id=s.authorization_id
       and sa.user_id=p_user_id
       and sa.academic_credit=true
       and coalesce(sa.credit_context,'')<>'learning_review'
       and sa.correction_case_id is null
      join private.exam_prep_session_items si
        on si.session_id=s.id
      left join private.exam_prep_responses r
        on r.session_id=s.id
       and r.item_order=si.item_order
       and r.user_id=p_user_id
      where s.user_id=p_user_id
        and s.component_code=p_component_code
        and s.session_type='learning'
        and s.status='finalized'
        and s.finalized_at is not null
        and exists(
          select 1
          from private.exam_prep_evidence_events after_signal
          where after_signal.session_id=s.id
            and after_signal.user_id=p_user_id
            and after_signal.component_code=p_component_code
            and after_signal.skill_code=p_skill_code
            and after_signal.verification_status='app_verified'
            and after_signal.created_at>=p_signal_at
        )
        and not exists(
          select 1
          from private.exam_prep_session_items other
          where other.session_id=s.id
            and other.primary_skill_code is distinct from p_skill_code
        )
      group by s.id
      having count(*) filter(where si.item_kind='question')>=3
         and count(*) filter(
           where si.item_kind='question'
             and r.response_kind='machine'
             and r.is_correct is true
         )=count(*) filter(where si.item_kind='question')
         and count(*) filter(where si.item_kind='written')>=1
         and count(*) filter(
           where si.item_kind='written'
             and r.response_kind='written'
         )=count(*) filter(where si.item_kind='written')
    )
    or exists(
      select 1
      from private.exam_prep_correction_cases c
      where c.user_id=p_user_id
        and c.component_code=p_component_code
        and c.skill_code=p_skill_code
        and c.status='resolved'
        and c.resolved_at is not null
        and c.resolved_at>=p_signal_at
    ),
    false
  );
$fn$;

revoke all on function private.exam_prep_diagnostic_signal_confirmed_v1(uuid,text,text,timestamptz)
  from public,anon,authenticated,service_role;

do $patch_queue$
declare
  v_def text;
  v_old text;
  v_new text;
begin
  v_def:=pg_get_functiondef('private.exam_prep_correction_queue_payload_v1(uuid,text)'::regprocedure);

  if position('exam_prep_diagnostic_signal_confirmed_v1' in v_def)>0 then
    return;
  end if;

  v_old:=
'      and not exists('||chr(10)||
'        select 1'||chr(10)||
'        from private.exam_prep_correction_cases c'||chr(10)||
'        where c.user_id=p_user_id'||chr(10)||
'          and c.component_code=p_component_code'||chr(10)||
'          and c.skill_code=ss.skill_code'||chr(10)||
'          and c.status in (''open'',''remediating'',''retest_due'',''reopened'')'||chr(10)||
'      )'||chr(10)||
'  ), signal_ranked as (';

  if (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) then
    raise exception 'signal_confirmation_v1 queue patch anchor drift';
  end if;

  v_new:=
'      and not exists('||chr(10)||
'        select 1'||chr(10)||
'        from private.exam_prep_correction_cases c'||chr(10)||
'        where c.user_id=p_user_id'||chr(10)||
'          and c.component_code=p_component_code'||chr(10)||
'          and c.skill_code=ss.skill_code'||chr(10)||
'          and c.status in (''open'',''remediating'',''retest_due'',''reopened'')'||chr(10)||
'      )'||chr(10)||
'      and not private.exam_prep_diagnostic_signal_confirmed_v1('||chr(10)||
'        p_user_id,p_component_code,ss.skill_code,d.created_at'||chr(10)||
'      )'||chr(10)||
'  ), signal_ranked as (';

  execute replace(v_def,v_old,v_new);
end
$patch_queue$;

do $postcheck$
declare
  v_queue text;
  v_confirmed text;
begin
  if to_regprocedure('private.exam_prep_diagnostic_signal_confirmed_v1(uuid,text,text,timestamptz)') is null then
    raise exception 'signal_confirmation_v1 confirmation helper missing';
  end if;

  v_queue:=pg_get_functiondef('private.exam_prep_correction_queue_payload_v1(uuid,text)'::regprocedure);
  v_confirmed:=pg_get_functiondef('private.exam_prep_diagnostic_signal_confirmed_v1(uuid,text,text,timestamptz)'::regprocedure);

  if position('exam_prep_diagnostic_signal_confirmed_v1' in v_queue)=0
     or position('sa.academic_credit=true' in v_confirmed)=0
     or position('sa.correction_case_id is null' in v_confirmed)=0
     or position('after_signal.created_at>=p_signal_at' in v_confirmed)=0
     or position('r.is_correct is true' in v_confirmed)=0
     or position('c.status=''resolved''' in v_confirmed)=0
     or position('c.resolved_at>=p_signal_at' in v_confirmed)=0
  then
    raise exception 'signal_confirmation_v1 postcheck failed';
  end if;
end
$postcheck$;

commit;
