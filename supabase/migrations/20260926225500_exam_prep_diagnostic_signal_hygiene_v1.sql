-- Future-only Stage-0 signal hygiene.
-- Broad diagnostic misses remain immutable evidence but no longer auto-open correction cases.
-- Learner focus may show up to five unconfirmed screening signals without changing mastery,
-- historical corrections, active plans, responses, evidence, or retest reserves.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if to_regprocedure('private.exam_prep_reconcile_finalized_session_v1()') is null
     or to_regprocedure('private.exam_prep_correction_queue_payload_v1(uuid,text)') is null
     or to_regprocedure('public.get_exam_prep_correction_queue_safe_v1(text)') is null
  then
    raise exception 'diagnostic_signal_hygiene_v1 prerequisite missing';
  end if;

  if md5(pg_get_functiondef('private.exam_prep_reconcile_finalized_session_v1()'::regprocedure))
       <> '78459802f1458219af1fea70c850d297'
     or md5(pg_get_functiondef('private.exam_prep_correction_queue_payload_v1(uuid,text)'::regprocedure))
       <> '49cce267427ef8c42b9b1b33b95cac7e'
  then
    raise exception 'diagnostic_signal_hygiene_v1 production function drift; refuse install';
  end if;
end
$preflight$;

-- Preserve every later hardening edit in the reconciliation trigger and make one narrow,
-- future-only change: diagnostic screening evidence does not create/reopen correction cases.
do $patch_reconcile$
declare
  v_def text;
  v_open text:='  for v_ev in';
  v_close text:='  end loop;';
begin
  v_def:=pg_get_functiondef('private.exam_prep_reconcile_finalized_session_v1()'::regprocedure);

  if (length(v_def)-length(replace(v_def,v_open,'')))<>length(v_open) then
    raise exception 'diagnostic_signal_hygiene_v1 reconcile loop anchor drift';
  end if;
  if (length(v_def)-length(replace(v_def,v_close,'')))<>length(v_close) then
    raise exception 'diagnostic_signal_hygiene_v1 reconcile loop close anchor drift';
  end if;

  v_def:=replace(
    v_def,
    v_open,
    '  if new.session_type<>''diagnostic'' then'||chr(10)||v_open
  );
  v_def:=replace(
    v_def,
    v_close,
    v_close||chr(10)||'  end if;'
  );
  execute v_def;
end
$patch_reconcile$;

create or replace function private.exam_prep_correction_queue_payload_v1(
  p_user_id uuid,
  p_component_code text
) returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $fn$
declare
  v_program bigint;
  v_payload jsonb;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_correction_queue_user_not_found' using errcode='P0002';
  end if;
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select pv.id into v_program
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and pv.status='active';
  if v_program is null then raise exception 'exam_prep_correction_queue_program_missing'; end if;

  with active_cases as (
    select
      c.id,c.skill_code,c.status,c.opened_at,c.updated_at,
      n.sequence_no,n.official_syllabus_section,n.canonical_description,
      case when c.reason->>'source'='finalized_incorrect_evidence'
        then 'incorrect_evidence'
        else coalesce(c.reason->>'source','other')
      end as origin,
      rt.id as retest_event_id,rt.status as retest_status,rt.due_not_before as retest_due_at,
      ca.action_type as latest_action_type,ca.created_at as latest_action_at,
      (select count(*)::integer
       from private.exam_prep_prerequisite_edges pe
       where pe.program_version_id=v_program
         and pe.from_node_code=c.skill_code
         and pe.target_component_code=p_component_code) as downstream_dependency_count,
      exists(
        select 1 from private.exam_prep_assessments a
        where a.component_code=p_component_code
          and a.assessment_type='learning'
          and a.status='published'
          and exists(
            select 1 from private.exam_prep_assessment_items ai
            where ai.assessment_id=a.id and ai.primary_skill_code=c.skill_code
          )
          and not exists(
            select 1 from private.exam_prep_assessment_items ai
            where ai.assessment_id=a.id and ai.primary_skill_code<>c.skill_code
          )
      ) as correction_content_ready,
      private.exam_prep_fresh_retest_content_ready_v1(
        p_user_id,p_component_code,c.skill_code
      ) as retest_content_ready
    from private.exam_prep_correction_cases c
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=v_program
     and n.component_code=c.component_code
     and n.skill_code=c.skill_code
    left join lateral (
      select r.id,r.status,r.due_not_before
      from private.exam_prep_retest_events r
      where r.correction_case_id=c.id and r.user_id=p_user_id
      order by r.created_at desc
      limit 1
    ) rt on true
    left join lateral (
      select a.action_type,a.created_at
      from private.exam_prep_correction_actions a
      where a.correction_case_id=c.id and a.user_id=p_user_id
      order by a.created_at desc,
               private.exam_prep_correction_action_rank_v1(a.action_type) desc,
               a.id desc
      limit 1
    ) ca on true
    where c.user_id=p_user_id
      and c.component_code=p_component_code
      and c.status in ('open','remediating','retest_due','reopened')
  ), normalized as (
    select
      a.*,
      'correction'::text as focus_kind,
      case
        when status in ('open','reopened') then 'review_error'
        when status='remediating' then 'practice_analogues'
        when status='retest_due' and retest_due_at is not null and retest_due_at>now()
          then 'wait_delayed_retest'
        when status='retest_due' and not retest_content_ready
          then 'retest_content_wait'
        when status='retest_due' then 'delayed_retest'
        else 'review_error'
      end as process_step,
      case
        when status='retest_due' and retest_due_at is not null and retest_due_at<=now()
          then 'retest_due'
        when status in ('reopened','remediating') then 'repeated_gap'
        when downstream_dependency_count>0 then 'foundation_dependency'
        else 'needs_attention'
      end as focus_reason,
      (status in ('open','remediating','reopened') and correction_content_ready) as can_start_correction,
      (status='retest_due'
       and retest_status='scheduled'
       and retest_due_at is not null
       and retest_due_at<=now()
       and retest_content_ready) as can_start_retest
    from active_cases a
  ), correction_ranked as (
    select n.*,
      row_number() over(order by
        case
          when status='retest_due' and retest_due_at is not null and retest_due_at<=now() then 0
          when status='reopened' then 1
          when status='remediating' then 2
          when status='open' then 3
          when status='retest_due' then 4
          else 9
        end,
        case when status in ('reopened','remediating') then updated_at end desc nulls last,
        downstream_dependency_count desc,
        sequence_no,opened_at,skill_code
      ) as correction_rank
    from normalized n
  ), diagnostic_signals as (
    select
      null::uuid as id,
      ss.skill_code,
      'screening_signal'::text as status,
      d.created_at as opened_at,
      d.created_at as updated_at,
      n.sequence_no,
      n.official_syllabus_section,
      n.canonical_description,
      'diagnostic_screening'::text as origin,
      null::uuid as retest_event_id,
      null::text as retest_status,
      null::timestamptz as retest_due_at,
      null::text as latest_action_type,
      null::timestamptz as latest_action_at,
      (select count(*)::integer
       from private.exam_prep_prerequisite_edges pe
       where pe.program_version_id=v_program
         and pe.from_node_code=ss.skill_code
         and pe.target_component_code=p_component_code) as downstream_dependency_count,
      false as correction_content_ready,
      false as retest_content_ready,
      'screening_signal'::text as focus_kind,
      'confirm_signal'::text as process_step,
      case
        when exists(
          select 1
          from private.exam_prep_prerequisite_edges pe
          where pe.program_version_id=v_program
            and pe.from_node_code=ss.skill_code
            and pe.target_component_code=p_component_code
        ) then 'diagnostic_signal_foundation'
        else 'diagnostic_signal'
      end as focus_reason,
      false as can_start_correction,
      false as can_start_retest
    from private.exam_prep_skill_states ss
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=v_program
     and n.component_code=p_component_code
     and n.skill_code=ss.skill_code
    join lateral (
      select e.created_at
      from private.exam_prep_evidence_events e
      join private.exam_prep_sessions s
        on s.id=e.session_id
       and s.user_id=p_user_id
       and s.component_code=p_component_code
       and s.session_type='diagnostic'
       and s.status='finalized'
      where e.user_id=p_user_id
        and e.component_code=p_component_code
        and e.skill_code=ss.skill_code
        and e.evidence_type='diagnostic'
        and e.verification_status='app_verified'
        and e.is_correct is false
      order by e.created_at desc,e.id desc
      limit 1
    ) d on true
    where ss.user_id=p_user_id
      and ss.program_version_id=v_program
      and ss.component_code=p_component_code
      and ss.engine_version='objective_state_v1'
      and ss.objective_level<=1
      and not exists(
        select 1
        from private.exam_prep_correction_cases c
        where c.user_id=p_user_id
          and c.component_code=p_component_code
          and c.skill_code=ss.skill_code
          and c.status in ('open','remediating','retest_due','reopened')
      )
  ), signal_ranked as (
    select d.*,
      row_number() over(order by
        d.downstream_dependency_count desc,
        d.sequence_no,
        d.updated_at desc,
        d.skill_code
      ) as signal_rank
    from diagnostic_signals d
  ), combined_focus as (
    select
      c.id,c.skill_code,c.status,c.opened_at,c.updated_at,
      c.sequence_no,c.official_syllabus_section,c.canonical_description,
      c.origin,c.retest_event_id,c.retest_status,c.retest_due_at,
      c.latest_action_type,c.latest_action_at,
      c.downstream_dependency_count,c.correction_content_ready,c.retest_content_ready,
      c.focus_kind,c.process_step,c.focus_reason,c.can_start_correction,c.can_start_retest,
      row_number() over(order by 0,c.correction_rank) as focus_rank
    from correction_ranked c
    union all
    select
      s.id,s.skill_code,s.status,s.opened_at,s.updated_at,
      s.sequence_no,s.official_syllabus_section,s.canonical_description,
      s.origin,s.retest_event_id,s.retest_status,s.retest_due_at,
      s.latest_action_type,s.latest_action_at,
      s.downstream_dependency_count,s.correction_content_ready,s.retest_content_ready,
      s.focus_kind,s.process_step,s.focus_reason,s.can_start_correction,s.can_start_retest,
      (select count(*) from correction_ranked)+s.signal_rank as focus_rank
    from signal_ranked s
  ), resolved_recent as (
    select
      c.id,c.skill_code,c.opened_at,c.resolved_at,
      n.official_syllabus_section,n.canonical_description
    from private.exam_prep_correction_cases c
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=v_program
     and n.component_code=c.component_code
     and n.skill_code=c.skill_code
    where c.user_id=p_user_id
      and c.component_code=p_component_code
      and c.status='resolved'
    order by c.resolved_at desc nulls last,c.updated_at desc
    limit 10
  )
  select jsonb_build_object(
    'component_code',p_component_code,
    'active_count',(select count(*) from correction_ranked),
    'signal_count',(select count(*) from signal_ranked),
    'attention_count',(select count(*) from combined_focus),
    'focus_limit',5,
    'focus_count',least((select count(*) from combined_focus),5),
    'deferred_count',greatest((select count(*) from combined_focus)-5,0),
    'retest_due_count',(select count(*) from correction_ranked where status='retest_due'),
    'focus_cases',coalesce((
      select jsonb_agg(jsonb_build_object(
        'correction_case_id',id,
        'focus_kind',focus_kind,
        'skill_code',skill_code,
        'official_syllabus_section',official_syllabus_section,
        'description',canonical_description,
        'status',status,
        'origin',origin,
        'process_step',process_step,
        'focus_reason',focus_reason,
        'downstream_dependency_count',downstream_dependency_count,
        'opened_at',opened_at,
        'updated_at',updated_at,
        'retest_event_id',retest_event_id,
        'retest_status',retest_status,
        'retest_due_at',retest_due_at,
        'latest_action_type',latest_action_type,
        'latest_action_at',latest_action_at,
        'correction_content_ready',correction_content_ready,
        'retest_content_ready',retest_content_ready,
        'can_start_correction',can_start_correction,
        'can_start_retest',can_start_retest
      ) order by focus_rank)
      from combined_focus
      where focus_rank<=5
    ),'[]'::jsonb),
    'cases',coalesce((
      select jsonb_agg(jsonb_build_object(
        'correction_case_id',id,
        'focus_kind',focus_kind,
        'skill_code',skill_code,
        'official_syllabus_section',official_syllabus_section,
        'description',canonical_description,
        'status',status,
        'origin',origin,
        'process_step',process_step,
        'focus_reason',focus_reason,
        'downstream_dependency_count',downstream_dependency_count,
        'opened_at',opened_at,
        'updated_at',updated_at,
        'retest_event_id',retest_event_id,
        'retest_status',retest_status,
        'retest_due_at',retest_due_at,
        'latest_action_type',latest_action_type,
        'latest_action_at',latest_action_at,
        'correction_content_ready',correction_content_ready,
        'retest_content_ready',retest_content_ready,
        'can_start_correction',can_start_correction,
        'can_start_retest',can_start_retest
      ) order by correction_rank)
      from correction_ranked
    ),'[]'::jsonb),
    'recent_resolved',coalesce((
      select jsonb_agg(jsonb_build_object(
        'correction_case_id',id,
        'skill_code',skill_code,
        'official_syllabus_section',official_syllabus_section,
        'description',canonical_description,
        'opened_at',opened_at,
        'resolved_at',resolved_at
      ) order by resolved_at desc)
      from resolved_recent
    ),'[]'::jsonb)
  ) into v_payload;

  return v_payload;
end
$fn$;

revoke all on function private.exam_prep_correction_queue_payload_v1(uuid,text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_correction_queue_payload_v1(uuid,text)
  to service_role;

do $postcheck$
declare
  v_reconcile text;
  v_queue text;
begin
  v_reconcile:=pg_get_functiondef('private.exam_prep_reconcile_finalized_session_v1()'::regprocedure);
  v_queue:=pg_get_functiondef('private.exam_prep_correction_queue_payload_v1(uuid,text)'::regprocedure);

  if position('if new.session_type<>''diagnostic'' then' in v_reconcile)=0
     or position('new.session_type=''learning''' in v_reconcile)=0
     or position('new.session_type=''retest''' in v_reconcile)=0
     or position('diagnostic_screening' in v_queue)=0
     or position('focus_kind' in v_queue)=0
     or position('focus_rank<=5' in v_queue)=0
  then
    raise exception 'diagnostic_signal_hygiene_v1 postcheck failed';
  end if;
end
$postcheck$;

commit;
