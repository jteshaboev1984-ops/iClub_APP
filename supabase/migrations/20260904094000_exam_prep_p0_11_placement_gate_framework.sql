-- P0-11: Stage 0 placement + Stages 0-6 access/gate framework.
-- Conservative by design: no undocumented advanced-placement threshold is invented.
-- Core never requires Mentor Care; ambiguous/insufficient evidence stays PENDING_EVIDENCE or Foundation.
-- Feature remains OFF; no legacy row is touched.

begin;

create table if not exists private.exam_prep_placement_rule_versions (
  rule_version text primary key,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  status text not null check(status in ('draft','active','retired')),
  policy_status text not null check(policy_status in ('framework_only','advanced_thresholds_approved')),
  p1_broad_required_items smallint not null check(p1_broad_required_items>0),
  p1_broad_required_areas smallint not null check(p1_broad_required_areas>0),
  p5_broad_required_items smallint not null check(p5_broad_required_items>0),
  p5_broad_required_areas smallint not null check(p5_broad_required_areas>0),
  targeted_min_items smallint not null check(targeted_min_items>0),
  targeted_max_items smallint not null check(targeted_max_items>=targeted_min_items),
  source_note text not null,
  policy_note text not null,
  created_at timestamptz not null default now(),
  activated_at timestamptz null
);
create unique index if not exists exam_prep_one_active_placement_rule_idx
  on private.exam_prep_placement_rule_versions(program_version_id)
  where status='active';

create table if not exists private.exam_prep_prerequisite_states (
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null,
  prerequisite_code text not null,
  status text not null default 'unknown'
    check(status in ('unknown','secure','blocker','retest_needed')),
  evidence_source text not null default 'none'
    check(evidence_source in ('none','objective','placement','mentor_verified')),
  reason jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key(user_id,program_version_id,prerequisite_code),
  foreign key(program_version_id,prerequisite_code)
    references private.exam_prep_prerequisite_nodes(program_version_id,prerequisite_code)
    on delete restrict
);

create table if not exists private.exam_prep_component_placements (
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  rule_version text not null references private.exam_prep_placement_rule_versions(rule_version) on delete restrict,
  placement_status text not null
    check(placement_status in ('not_started','content_blocked','screening_incomplete','targeted_required','conservative_foundation','confirmed')),
  route text not null
    check(route in ('pending_evidence','foundation','accelerated_coverage','consolidation','exam_mode')),
  profile_complete boolean not null default false,
  content_ready boolean not null default false,
  screening_required_items smallint not null,
  screening_required_areas smallint not null,
  screening_available_items integer not null default 0 check(screening_available_items>=0),
  screening_available_areas integer not null default 0 check(screening_available_areas>=0),
  screening_answered_items integer not null default 0 check(screening_answered_items>=0),
  screening_answered_areas integer not null default 0 check(screening_answered_areas>=0),
  screening_objective_items integer not null default 0 check(screening_objective_items>=0),
  screening_correct_items integer not null default 0 check(screening_correct_items>=0),
  screening_accuracy_pct numeric(5,2) null check(screening_accuracy_pct is null or screening_accuracy_pct between 0 and 100),
  prerequisite_unknown_count integer not null default 0 check(prerequisite_unknown_count>=0),
  prerequisite_blocker_count integer not null default 0 check(prerequisite_blocker_count>=0),
  ambiguity boolean not null default true,
  advanced_skip_requires_human boolean not null default true,
  stage0_complete boolean not null default false,
  route_reason text not null,
  evidence_summary jsonb not null default '{}'::jsonb,
  derived_at timestamptz not null default now(),
  primary key(user_id,program_version_id,component_code,rule_version)
);

create table if not exists private.exam_prep_stage_gate_catalog (
  rule_version text not null references private.exam_prep_placement_rule_versions(rule_version) on delete restrict,
  stage_no smallint not null check(stage_no between 0 and 6),
  stage_name text not null,
  dependency_state text not null check(dependency_state in ('implemented','p0_12','p2_content','p2_paper','p2_readiness')),
  gate_law text not null,
  primary key(rule_version,stage_no)
);

create table if not exists private.exam_prep_component_access_gates (
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  rule_version text not null references private.exam_prep_placement_rule_versions(rule_version) on delete restrict,
  current_operational_stage smallint not null default 0 check(current_operational_stage between 0 and 6),
  max_unlocked_stage smallint not null default 0 check(max_unlocked_stage between 0 and 6),
  placement_access boolean not null default true,
  foundation_learning_access boolean not null default false,
  advanced_route_access boolean not null default false,
  mentor_required_for_core boolean not null default false,
  gate_status text not null check(gate_status in ('blocked_content','profile_required','screening_required','stage0_complete','future_gate_dependency')),
  gate_reason text not null,
  updated_at timestamptz not null default now(),
  primary key(user_id,program_version_id,component_code,rule_version),
  check(current_operational_stage<=max_unlocked_stage),
  check(mentor_required_for_core is false)
);

-- Private authoritative placement tables. No direct learner writes or reads.
do $$ declare t text; begin
  foreach t in array array[
    'exam_prep_placement_rule_versions','exam_prep_prerequisite_states',
    'exam_prep_component_placements','exam_prep_stage_gate_catalog','exam_prep_component_access_gates'
  ] loop
    execute format('alter table private.%I enable row level security',t);
    execute format('revoke all on private.%I from public,anon,authenticated',t);
    execute format('grant all on private.%I to service_role',t);
  end loop;
end $$;

insert into private.exam_prep_placement_rule_versions(
  rule_version,program_version_id,status,policy_status,
  p1_broad_required_items,p1_broad_required_areas,p5_broad_required_items,p5_broad_required_areas,
  targeted_min_items,targeted_max_items,source_note,policy_note,activated_at
)
select
  'placement_v1_conservative',pv.id,'active','framework_only',
  24,8,15,5,3,5,
  'Master Plan v1.1 / Mentor Care v1.1 Stage 0: P1 broad 24 across 8 areas; P5 broad 15 across 5 areas; targeted confirmation 3-5 tasks; placement and prerequisites component-safe/non-crediting.',
  'The normative sources do not approve numeric cutoffs for Accelerated Coverage, Consolidation or Exam Mode. Therefore v1 never auto-awards an advanced route. If broad screening is complete, Core can proceed on Foundation conservatively; advanced skips require a later versioned rule and, for high-impact human override, active Mentor Care scope.',
  now()
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(rule_version) do nothing;

insert into private.exam_prep_stage_gate_catalog(rule_version,stage_no,stage_name,dependency_state,gate_law) values
('placement_v1_conservative',0,'Exam Profile & Placement','implemented','Separate P1/P5 placement; realistic Mathematics budget; ambiguity routes conservatively; prerequisites are non-crediting.'),
('placement_v1_conservative',1,'Foundation / Fast-track','implemented','Unlocked only after Stage 0 placement. Foundation may include prerequisite repair; mentor is not a Core dependency.'),
('placement_v1_conservative',2,'Syllabus Building','p0_12','Requires Stage 1 evidence law: core prerequisites closed, approximately 10-15% confirmed coverage or evidence-backed fast-track, plus first correction/retest/mixed cycle.'),
('placement_v1_conservative',3,'Syllabus Closure','p2_content','Requires 100% component coverage, every skill at least L2, key skills at least L3, and first comparable full-paper baseline.'),
('placement_v1_conservative',4,'Timed Consolidation','p2_paper','Requires component-specific comparable full-paper/timed evidence and corrective linkage.'),
('placement_v1_conservative',5,'Exam Readiness','p2_readiness','Requires at least three comparable strict attempts, last-three trend, fundamentals/corrections closed and minimal unattempted; App Readiness is not Mentor Verified readiness.'),
('placement_v1_conservative',6,'Final Calibration','p2_readiness','Evidence-gated final calibration/taper; no new mastery from calendar or panic volume.')
on conflict(rule_version,stage_no) do nothing;

-- Stage-state reconciliation hook: P0-10 rebuild remains source of skill/evidence facts;
-- this hook only lets a completed Stage 0 unlock Stage 1.
create or replace function private.exam_prep_apply_stage0_gate_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare v_gate private.exam_prep_component_access_gates%rowtype;
begin
  select * into v_gate
  from private.exam_prep_component_access_gates g
  where g.user_id=new.user_id and g.program_version_id=new.program_version_id
    and g.component_code=new.component_code
  order by g.updated_at desc limit 1;
  if v_gate.user_id is not null and v_gate.max_unlocked_stage>=1 then
    new.operational_stage:=greatest(new.operational_stage,1);
    new.stage_gate_status:='operational';
    new.stage_hold_reason:='Stage 0 complete; Stage 1 Foundation access is unlocked. Higher stages remain evidence/dependency gated.';
  end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_apply_stage0_gate_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_stage0_gate_projection_v1 on private.exam_prep_stage_states;
create trigger exam_prep_stage0_gate_projection_v1
before insert or update on private.exam_prep_stage_states
for each row execute function private.exam_prep_apply_stage0_gate_v1();

create or replace function private.rebuild_exam_prep_placement_v1(
  p_user_id uuid,
  p_component_code text default null
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_program bigint;
  v_rule private.exam_prep_placement_rule_versions%rowtype;
  v_component text;
  v_req_items int; v_req_areas int;
  v_available_items int; v_available_areas int;
  v_answered_items int; v_answered_areas int; v_objective int; v_correct int; v_accuracy numeric;
  v_unknown int; v_blockers int; v_profile_complete boolean;
  v_status text; v_route text; v_reason text; v_content_ready boolean; v_stage0 boolean; v_ambiguity boolean;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then raise exception 'exam_prep_placement_user_not_found'; end if;
  if p_component_code is not null and p_component_code not in ('P1','P5') then raise exception 'exam_prep_placement_invalid_component'; end if;

  select pv.id into v_program from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active';
  if v_program is null then raise exception 'exam_prep_placement_program_missing'; end if;
  select * into v_rule from private.exam_prep_placement_rule_versions r where r.program_version_id=v_program and r.status='active';
  if v_rule.rule_version is null then raise exception 'exam_prep_placement_rule_missing'; end if;

  -- Materialize all non-crediting prerequisite nodes as UNKNOWN until evidence says otherwise.
  insert into private.exam_prep_prerequisite_states(user_id,program_version_id,prerequisite_code,status,evidence_source,reason)
  select p_user_id,v_program,n.prerequisite_code,'unknown','none','{}'::jsonb
  from private.exam_prep_prerequisite_nodes n where n.program_version_id=v_program and n.is_mastery_crediting=false
  on conflict(user_id,program_version_id,prerequisite_code) do nothing;

  foreach v_component in array case when p_component_code is null then array['P1','P5'] else array[p_component_code] end loop
    v_req_items:=case when v_component='P1' then v_rule.p1_broad_required_items else v_rule.p5_broad_required_items end;
    v_req_areas:=case when v_component='P1' then v_rule.p1_broad_required_areas else v_rule.p5_broad_required_areas end;

    select count(distinct ai.question_id),count(distinct s.official_syllabus_section)
      into v_available_items,v_available_areas
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id and ai.question_id is not null
    join private.exam_prep_syllabus_nodes s on s.program_version_id=v_program and s.skill_code=ai.primary_skill_code and s.component_code=a.component_code
    where a.component_code=v_component and a.assessment_type='diagnostic' and a.status='published';

    with learner_diag as (
      select e.*,si.question_id
      from private.exam_prep_evidence_events e
      join private.exam_prep_sessions ses on ses.id=e.session_id and ses.status='finalized' and ses.user_id=p_user_id
      join private.exam_prep_responses r on r.id=e.response_id and r.session_id=ses.id and r.user_id=p_user_id
      join private.exam_prep_session_items si on si.session_id=ses.id and si.item_order=r.item_order
      where e.user_id=p_user_id and e.component_code=v_component and e.evidence_type='diagnostic'
    )
    select count(distinct ld.question_id),count(distinct s.official_syllabus_section),
           count(*) filter(where ld.verification_status='app_verified' and ld.is_correct is not null),
           count(*) filter(where ld.verification_status='app_verified' and ld.is_correct is true)
      into v_answered_items,v_answered_areas,v_objective,v_correct
    from learner_diag ld
    join private.exam_prep_syllabus_nodes s on s.program_version_id=v_program and s.skill_code=ld.skill_code and s.component_code=v_component;
    v_accuracy:=case when v_objective>0 then round((100.0*v_correct/v_objective)::numeric,2) else null end;

    select count(distinct ps.prerequisite_code) filter(where ps.status='unknown'),
           count(distinct ps.prerequisite_code) filter(where ps.status in ('blocker','retest_needed'))
      into v_unknown,v_blockers
    from private.exam_prep_prerequisite_states ps
    where ps.user_id=p_user_id and ps.program_version_id=v_program
      and exists(select 1 from private.exam_prep_prerequisite_edges pe where pe.program_version_id=v_program and pe.from_node_code=ps.prerequisite_code and pe.target_component_code=v_component and pe.is_mastery_crediting=false);

    select exists(
      select 1 from private.exam_prep_exam_profiles p
      where p.user_id=p_user_id and p.program_version_id=v_program
        and p.mathematics_hours_budget is not null and p.mathematics_hours_budget>0
        and p.total_student_hours_available is not null and p.total_student_hours_available>0
        and p.mathematics_hours_budget<=p.total_student_hours_available
        and p.active_week_no>=1
    ) into v_profile_complete;

    v_content_ready:=(coalesce(v_available_items,0)>=v_req_items and coalesce(v_available_areas,0)>=v_req_areas);
    v_stage0:=false; v_ambiguity:=true; v_route:='pending_evidence';
    if not v_profile_complete then
      v_status:='not_started'; v_reason:='exam_profile_or_realistic_mathematics_budget_required';
    elsif not v_content_ready then
      v_status:='content_blocked'; v_reason:=format('broad_screen_content_not_ready: available %s/%s items and %s/%s areas',coalesce(v_available_items,0),v_req_items,coalesce(v_available_areas,0),v_req_areas);
    elsif coalesce(v_answered_items,0)<v_req_items or coalesce(v_answered_areas,0)<v_req_areas then
      v_status:='screening_incomplete'; v_reason:=format('broad_screen_incomplete: answered %s/%s items and %s/%s areas',coalesce(v_answered_items,0),v_req_items,coalesce(v_answered_areas,0),v_req_areas);
    elsif coalesce(v_blockers,0)>0 then
      v_status:='confirmed'; v_route:='foundation'; v_reason:='foundation_due_to_explicit_prerequisite_blocker'; v_stage0:=true; v_ambiguity:=false;
    else
      -- No approved numeric advanced-route thresholds exist in the normative sources.
      -- Core therefore proceeds safely on Foundation rather than blocking on a mentor or inventing a skip.
      v_status:='conservative_foundation'; v_route:='foundation'; v_reason:='conservative_core_route_no_approved_advanced_threshold'; v_stage0:=true; v_ambiguity:=true;
    end if;

    insert into private.exam_prep_component_placements(
      user_id,program_version_id,component_code,rule_version,placement_status,route,profile_complete,content_ready,
      screening_required_items,screening_required_areas,screening_available_items,screening_available_areas,
      screening_answered_items,screening_answered_areas,screening_objective_items,screening_correct_items,screening_accuracy_pct,
      prerequisite_unknown_count,prerequisite_blocker_count,ambiguity,advanced_skip_requires_human,stage0_complete,
      route_reason,evidence_summary,derived_at
    ) values(
      p_user_id,v_program,v_component,v_rule.rule_version,v_status,v_route,v_profile_complete,v_content_ready,
      v_req_items,v_req_areas,coalesce(v_available_items,0),coalesce(v_available_areas,0),
      coalesce(v_answered_items,0),coalesce(v_answered_areas,0),coalesce(v_objective,0),coalesce(v_correct,0),v_accuracy,
      coalesce(v_unknown,0),coalesce(v_blockers,0),v_ambiguity,true,v_stage0,v_reason,
      jsonb_build_object('policy_status',v_rule.policy_status,'advanced_routes_auto_awarded',false),now()
    )
    on conflict(user_id,program_version_id,component_code,rule_version) do update set
      placement_status=excluded.placement_status,route=excluded.route,profile_complete=excluded.profile_complete,
      content_ready=excluded.content_ready,screening_required_items=excluded.screening_required_items,
      screening_required_areas=excluded.screening_required_areas,screening_available_items=excluded.screening_available_items,
      screening_available_areas=excluded.screening_available_areas,screening_answered_items=excluded.screening_answered_items,
      screening_answered_areas=excluded.screening_answered_areas,screening_objective_items=excluded.screening_objective_items,
      screening_correct_items=excluded.screening_correct_items,screening_accuracy_pct=excluded.screening_accuracy_pct,
      prerequisite_unknown_count=excluded.prerequisite_unknown_count,prerequisite_blocker_count=excluded.prerequisite_blocker_count,
      ambiguity=excluded.ambiguity,advanced_skip_requires_human=excluded.advanced_skip_requires_human,
      stage0_complete=excluded.stage0_complete,route_reason=excluded.route_reason,evidence_summary=excluded.evidence_summary,derived_at=excluded.derived_at;

    insert into private.exam_prep_component_access_gates(
      user_id,program_version_id,component_code,rule_version,current_operational_stage,max_unlocked_stage,
      placement_access,foundation_learning_access,advanced_route_access,mentor_required_for_core,gate_status,gate_reason,updated_at
    ) values(
      p_user_id,v_program,v_component,v_rule.rule_version,
      case when v_stage0 then 1 else 0 end,case when v_stage0 then 1 else 0 end,
      true,v_stage0,false,false,
      case when not v_profile_complete then 'profile_required' when not v_content_ready then 'blocked_content'
           when not v_stage0 then 'screening_required' else 'stage0_complete' end,
      v_reason,now()
    )
    on conflict(user_id,program_version_id,component_code,rule_version) do update set
      current_operational_stage=excluded.current_operational_stage,max_unlocked_stage=excluded.max_unlocked_stage,
      placement_access=excluded.placement_access,foundation_learning_access=excluded.foundation_learning_access,
      advanced_route_access=excluded.advanced_route_access,mentor_required_for_core=false,
      gate_status=excluded.gate_status,gate_reason=excluded.gate_reason,updated_at=excluded.updated_at;

    -- Re-fire the P0-10 stage projection trigger if a projection already exists.
    update private.exam_prep_stage_states ss set derived_at=now()
    where ss.user_id=p_user_id and ss.program_version_id=v_program and ss.component_code=v_component and ss.engine_version='objective_state_v1';
  end loop;

  return jsonb_build_object('user_id',p_user_id,'program_version_id',v_program,'rule_version',v_rule.rule_version,'component',coalesce(p_component_code,'ALL'));
end;
$$;
revoke all on function private.rebuild_exam_prep_placement_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.rebuild_exam_prep_placement_v1(uuid,text) to service_role;

create or replace function public.save_exam_prep_exam_profile_v1(
  p_exam_series text,
  p_target_grade text,
  p_total_student_hours_available numeric,
  p_mathematics_hours_budget numeric
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_program bigint; v_profile private.exam_prep_exam_profiles%rowtype;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_exam_series is not null and char_length(trim(p_exam_series))>80 then raise exception 'exam_prep_bad_exam_series'; end if;
  if p_target_grade is not null and char_length(trim(p_target_grade))>40 then raise exception 'exam_prep_bad_target_grade'; end if;
  if p_total_student_hours_available is null or p_total_student_hours_available<=0 or p_total_student_hours_available>168 then raise exception 'exam_prep_bad_total_hours'; end if;
  if p_mathematics_hours_budget is null or p_mathematics_hours_budget<=0 or p_mathematics_hours_budget>p_total_student_hours_available then raise exception 'exam_prep_bad_math_budget'; end if;
  select id into v_program from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_program is null then raise exception 'exam_prep_profile_program_missing'; end if;

  insert into private.exam_prep_exam_profiles(user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,active_week_no,created_by,updated_by)
  values(v_uid,v_program,nullif(trim(p_exam_series),''),nullif(trim(p_target_grade),''),p_total_student_hours_available,p_mathematics_hours_budget,1,v_uid,v_uid)
  on conflict(user_id) do update set
    program_version_id=excluded.program_version_id,exam_series=excluded.exam_series,target_grade=excluded.target_grade,
    total_student_hours_available=excluded.total_student_hours_available,mathematics_hours_budget=excluded.mathematics_hours_budget,
    active_week_no=greatest(private.exam_prep_exam_profiles.active_week_no,1),updated_at=now(),updated_by=v_uid
  returning * into v_profile;
  perform private.rebuild_exam_prep_placement_v1(v_uid,null);
  return jsonb_build_object('program_version_id',v_profile.program_version_id,'exam_series',v_profile.exam_series,
    'target_grade',v_profile.target_grade,'total_student_hours_available',v_profile.total_student_hours_available,
    'mathematics_hours_budget',v_profile.mathematics_hours_budget,'active_week_no',v_profile.active_week_no);
end;
$$;
revoke execute on function public.save_exam_prep_exam_profile_v1(text,text,numeric,numeric) from public,anon;
grant execute on function public.save_exam_prep_exam_profile_v1(text,text,numeric,numeric) to authenticated,service_role;

create or replace function public.get_exam_prep_placement_safe_v1(p_component_code text default null)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_program bigint; v_rule text; v_result jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code is not null and p_component_code not in ('P1','P5') then raise exception 'exam_prep_placement_invalid_component'; end if;
  perform private.rebuild_exam_prep_placement_v1(v_uid,p_component_code);
  select id into v_program from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select rule_version into v_rule from private.exam_prep_placement_rule_versions where program_version_id=v_program and status='active';
  select jsonb_build_object(
    'rule_version',v_rule,
    'components',coalesce(jsonb_agg(jsonb_build_object(
      'component_code',p.component_code,'placement_status',p.placement_status,'route',p.route,
      'profile_complete',p.profile_complete,'content_ready',p.content_ready,'stage0_complete',p.stage0_complete,
      'screening',jsonb_build_object('required_items',p.screening_required_items,'required_areas',p.screening_required_areas,
        'available_items',p.screening_available_items,'available_areas',p.screening_available_areas,
        'answered_items',p.screening_answered_items,'answered_areas',p.screening_answered_areas,
        'accuracy_pct',p.screening_accuracy_pct),
      'prerequisites',jsonb_build_object('unknown',p.prerequisite_unknown_count,'blockers',p.prerequisite_blocker_count),
      'ambiguity',p.ambiguity,'advanced_skip_requires_human',p.advanced_skip_requires_human,
      'route_reason',p.route_reason,'max_unlocked_stage',g.max_unlocked_stage,'foundation_learning_access',g.foundation_learning_access
    ) order by p.component_code),'[]'::jsonb)
  ) into v_result
  from private.exam_prep_component_placements p
  join private.exam_prep_component_access_gates g on g.user_id=p.user_id and g.program_version_id=p.program_version_id and g.component_code=p.component_code and g.rule_version=p.rule_version
  where p.user_id=v_uid and p.program_version_id=v_program and p.rule_version=v_rule
    and (p_component_code is null or p.component_code=p_component_code);
  return v_result;
end;
$$;
revoke execute on function public.get_exam_prep_placement_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_placement_safe_v1(text) to authenticated,service_role;

-- Acceptance: exact Stage-0 screening law and seven stage catalog rows.
do $$
declare v_program bigint; v_rule text; begin
  select id into v_program from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select rule_version into v_rule from private.exam_prep_placement_rule_versions where program_version_id=v_program and status='active';
  if v_rule is null then raise exception 'P0-11 gate: active placement rule missing'; end if;
  if not exists(select 1 from private.exam_prep_placement_rule_versions where rule_version=v_rule and p1_broad_required_items=24 and p1_broad_required_areas=8 and p5_broad_required_items=15 and p5_broad_required_areas=5 and targeted_min_items=3 and targeted_max_items=5 and policy_status='framework_only') then
    raise exception 'P0-11 gate: Stage 0 screening contract mismatch';
  end if;
  if (select count(*) from private.exam_prep_stage_gate_catalog where rule_version=v_rule)<>7 then raise exception 'P0-11 gate: expected seven Stage 0-6 catalog rows'; end if;
  if exists(select 1 from private.exam_prep_component_access_gates where mentor_required_for_core) then raise exception 'P0-11 gate: Core must never require mentor'; end if;
end $$;

commit;
