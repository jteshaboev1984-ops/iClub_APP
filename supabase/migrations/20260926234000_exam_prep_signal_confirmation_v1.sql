-- Stage-0 screening-signal confirmation.
-- Uses only a learner's first unseen governed learning pack for that skill.
-- Retest reserve is never used; a successful confirmation is 3+ machine items all correct
-- plus the required written artifact completed (written is not marked correct/incorrect).
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare
  v_queue text;
begin
  if to_regprocedure('private.exam_prep_correction_queue_payload_v1(uuid,text)') is null
     or to_regprocedure('private.exam_prep_skill_runway_ready_for_week_v1(bigint,text,text,smallint)') is null
     or to_regprocedure('public.start_exam_prep_session_safe_v1(uuid,text)') is null
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
  select coalesce(exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_session_authorizations sa
      on sa.id=s.authorization_id
     and sa.user_id=p_user_id
     and sa.academic_credit=true
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
      and s.finalized_at>p_signal_at
      and coalesce(sa.credit_context,'')<>'learning_review'
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
       and count(*) filter(
         where si.item_kind='written'
           and r.response_kind='written'
       )>=1
  ),false);
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

create or replace function public.authorize_exam_prep_signal_confirmation_safe_v1(
  p_component_code text,
  p_skill_code text
) returns jsonb
language plpgsql
security definer
set search_path=''
as $fn$
declare
  v_uid uuid;
  v_program bigint;
  v_week smallint;
  v_signal_at timestamptz;
  v_queue jsonb;
  v_focus jsonb;
  v_ass bigint;
  v_questions integer;
  v_written integer;
  v_active_session uuid;
  v_active_component text;
  v_active_assessment bigint;
  v_existing private.exam_prep_session_authorizations%rowtype;
  v_plan_id uuid;
  v_plan_priority smallint;
  v_auth uuid;
  v_now timestamptz;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  if coalesce(trim(p_skill_code),'')='' then raise exception 'exam_prep_signal_skill_required'; end if;

  select ep.program_version_id into v_program
  from private.exam_prep_exam_profiles ep
  where ep.user_id=v_uid;
  v_week:=private.exam_prep_effective_active_week_v1(v_uid);
  v_now:=private.exam_prep_effective_academic_now_v1(v_uid);
  if v_program is null or v_week is null then raise exception 'exam_prep_profile_required'; end if;

  if not exists(
    select 1
    from private.exam_prep_component_placements cp
    where cp.user_id=v_uid
      and cp.program_version_id=v_program
      and cp.component_code=p_component_code
      and cp.stage0_complete=true
  ) then
    return jsonb_build_object('status','not_ready','reason','entry_check_incomplete');
  end if;

  select e.created_at into v_signal_at
  from private.exam_prep_evidence_events e
  join private.exam_prep_sessions s
    on s.id=e.session_id
   and s.user_id=v_uid
   and s.component_code=p_component_code
   and s.session_type='diagnostic'
   and s.status='finalized'
  where e.user_id=v_uid
    and e.component_code=p_component_code
    and e.skill_code=p_skill_code
    and e.evidence_type='diagnostic'
    and e.verification_status='app_verified'
    and e.is_correct is false
  order by e.created_at desc,e.id desc
  limit 1;

  if v_signal_at is null then
    return jsonb_build_object('status','no_signal');
  end if;

  if private.exam_prep_diagnostic_signal_confirmed_v1(
    v_uid,p_component_code,p_skill_code,v_signal_at
  ) then
    return jsonb_build_object('status','already_confirmed','skill_code',p_skill_code);
  end if;

  if exists(
    select 1
    from private.exam_prep_correction_cases c
    where c.user_id=v_uid
      and c.component_code=p_component_code
      and c.skill_code=p_skill_code
      and c.status in ('open','remediating','retest_due','reopened')
  ) then
    return jsonb_build_object('status','correction_open','skill_code',p_skill_code);
  end if;

  if not private.exam_prep_skill_runway_ready_for_week_v1(
    v_program,p_component_code,p_skill_code,v_week
  ) then
    return jsonb_build_object('status','not_ready','reason','topic_not_open_yet','skill_code',p_skill_code);
  end if;

  v_queue:=private.exam_prep_correction_queue_payload_v1(v_uid,p_component_code);
  select x.value into v_focus
  from jsonb_array_elements(coalesce(v_queue->'focus_cases','[]'::jsonb)) x
  where x.value->>'focus_kind'='screening_signal'
    and x.value->>'skill_code'=p_skill_code
  limit 1;
  if v_focus is null then
    return jsonb_build_object('status','not_in_focus','skill_code',p_skill_code);
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended('ep-signal-confirm:'||v_uid::text||':'||p_component_code||':'||p_skill_code,0)
  );

  select s.id,s.component_code,s.assessment_id
    into v_active_session,v_active_component,v_active_assessment
  from private.exam_prep_sessions s
  where s.user_id=v_uid and s.status='active'
  order by s.started_at desc,s.id desc
  limit 1;
  if v_active_session is not null then
    return jsonb_build_object(
      'status','resume_existing_session_first',
      'session_id',v_active_session,
      'active_component_code',v_active_component,
      'active_assessment_id',v_active_assessment
    );
  end if;

  -- If this same skill is already a pending learning priority in the current
  -- stable plan, do not create a parallel route. Send the learner to that plan.
  select p.id,i.priority_order
    into v_plan_id,v_plan_priority
  from private.exam_prep_weekly_plans p
  join private.exam_prep_weekly_plan_items i
    on i.plan_id=p.id
   and i.status='pending'
   and i.item_type='learning'
   and i.skill_code=p_skill_code
  where p.user_id=v_uid
    and p.program_version_id=v_program
    and p.component_code=p_component_code
    and p.active_week_no=v_week
    and p.status='active'
  order by p.created_at desc,i.priority_order
  limit 1;

  if v_plan_id is not null then
    return jsonb_build_object(
      'status','use_weekly_plan',
      'plan_id',v_plan_id,
      'priority_order',v_plan_priority,
      'component_code',p_component_code,
      'skill_code',p_skill_code
    );
  end if;

  select a.id into v_ass
  from private.exam_prep_assessments a
  where a.component_code=p_component_code
    and a.assessment_type='learning'
    and a.status='published'
    and exists(
      select 1 from private.exam_prep_assessment_items ai
      where ai.assessment_id=a.id and ai.primary_skill_code=p_skill_code
    )
    and not exists(
      select 1 from private.exam_prep_assessment_items ai
      where ai.assessment_id=a.id and ai.primary_skill_code<>p_skill_code
    )
  order by a.id
  limit 1;
  if v_ass is null then
    return jsonb_build_object('status','content_unavailable','reason','governed_learning_pack_missing');
  end if;

  select
    count(*) filter(where ai.question_id is not null),
    count(*) filter(where ai.written_task_id is not null)
  into v_questions,v_written
  from private.exam_prep_assessment_items ai
  where ai.assessment_id=v_ass;
  if v_questions<3 or v_written<1 then
    return jsonb_build_object('status','content_unavailable','reason','learning_pack_floor_not_met');
  end if;

  update private.exam_prep_session_authorizations
  set status='expired'
  where user_id=v_uid
    and assessment_id=v_ass
    and purpose='learning'
    and plan_id is null
    and credit_context='signal_confirmation'
    and status='issued'
    and valid_until is not null
    and valid_until<=v_now;

  select * into v_existing
  from private.exam_prep_session_authorizations sa
  where sa.user_id=v_uid
    and sa.assessment_id=v_ass
    and sa.purpose='learning'
    and sa.status='issued'
    and (sa.valid_until is null or sa.valid_until>v_now)
  order by sa.issued_at desc
  limit 1;

  if v_existing.id is not null then
    if v_existing.plan_id is not null then
      return jsonb_build_object(
        'status','use_weekly_plan',
        'plan_id',v_existing.plan_id,
        'priority_order',v_existing.plan_priority_order,
        'component_code',p_component_code,
        'skill_code',p_skill_code
      );
    end if;
    return jsonb_build_object(
      'status','authorized',
      'authorization_id',v_existing.id,
      'assessment_id',v_ass,
      'component_code',p_component_code,
      'skill_code',p_skill_code,
      'fresh_questions',true,
      'uses_retest_reserve',false,
      'replayed',true
    );
  end if;

  -- Once a session has started, its questions are considered seen even if the
  -- learner later abandons it. Never silently reuse them as fresh evidence.
  if exists(
    select 1
    from private.exam_prep_sessions s
    where s.user_id=v_uid
      and s.assessment_id=v_ass
  ) then
    return jsonb_build_object(
      'status','content_exhausted',
      'reason','first_learning_pack_already_seen',
      'component_code',p_component_code,
      'skill_code',p_skill_code,
      'uses_retest_reserve',false
    );
  end if;

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,
    academic_credit,credit_context
  ) values(
    v_uid,v_ass,p_component_code,'learning','issued',v_now+interval '1 hour',
    'Fresh governed learning pack for confirmation of an unresolved entry-check screening signal',
    true,'signal_confirmation'
  )
  returning id into v_auth;

  return jsonb_build_object(
    'status','authorized',
    'authorization_id',v_auth,
    'assessment_id',v_ass,
    'component_code',p_component_code,
    'skill_code',p_skill_code,
    'fresh_questions',true,
    'uses_retest_reserve',false,
    'replayed',false
  );
end
$fn$;

revoke all on function public.authorize_exam_prep_signal_confirmation_safe_v1(text,text)
  from public,anon;
grant execute on function public.authorize_exam_prep_signal_confirmation_safe_v1(text,text)
  to authenticated,service_role;

do $postcheck$
declare
  v_queue text;
begin
  v_queue:=pg_get_functiondef('private.exam_prep_correction_queue_payload_v1(uuid,text)'::regprocedure);
  if to_regprocedure('private.exam_prep_diagnostic_signal_confirmed_v1(uuid,text,text,timestamptz)') is null
     or to_regprocedure('public.authorize_exam_prep_signal_confirmation_safe_v1(text,text)') is null
     or position('exam_prep_diagnostic_signal_confirmed_v1' in v_queue)=0
     or has_function_privilege('anon','public.authorize_exam_prep_signal_confirmation_safe_v1(text,text)','EXECUTE')
     or not has_function_privilege('authenticated','public.authorize_exam_prep_signal_confirmation_safe_v1(text,text)','EXECUTE')
  then
    raise exception 'signal_confirmation_v1 postcheck failed';
  end if;
end
$postcheck$;

commit;
