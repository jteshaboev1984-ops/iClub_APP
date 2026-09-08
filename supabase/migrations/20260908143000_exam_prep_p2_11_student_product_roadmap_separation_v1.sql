-- P2-11 / Annual Roadmap C22: separate student roadmap from product/content roadmap.
-- Additive planning/governance metadata only. Calendar/product dates may block unavailable learning content;
-- they never force a learner stage, raise mastery, create evidence or label a learner Exam Ready.
begin;

create table if not exists private.exam_prep_student_roadmap_windows (
  id bigint generated always as identity primary key,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  roadmap_version text not null,
  cohort_scope text not null,
  stage_no smallint not null check(stage_no between 0 and 6),
  stage_key text not null,
  active_week_from smallint not null check(active_week_from between 1 and 36),
  active_week_through smallint not null check(active_week_through between active_week_from and 36),
  target_exit_date date not null,
  latest_safe_exit_date date null,
  latest_safe_basis text not null check(latest_safe_basis in ('fixed_date','official_component_date')),
  progression_basis text not null default 'evidence_only' check(progression_basis='evidence_only'),
  planning_only boolean not null default true check(planning_only),
  calendar_auto_promotion boolean not null default false check(not calendar_auto_promotion),
  status text not null default 'active' check(status in ('active','retired','superseded')),
  source_note text not null,
  created_at timestamptz not null default now(),
  unique(program_version_id,roadmap_version,stage_no),
  check(
    (latest_safe_basis='fixed_date' and latest_safe_exit_date is not null and latest_safe_exit_date>=target_exit_date)
    or
    (latest_safe_basis='official_component_date' and latest_safe_exit_date is null)
  )
);

create unique index if not exists exam_prep_student_roadmap_one_active_stage_idx
  on private.exam_prep_student_roadmap_windows(program_version_id,cohort_scope,stage_no)
  where status='active';

alter table private.exam_prep_student_roadmap_windows enable row level security;
revoke all on private.exam_prep_student_roadmap_windows from public,anon,authenticated;
grant all on private.exam_prep_student_roadmap_windows to service_role;
grant usage,select on sequence private.exam_prep_student_roadmap_windows_id_seq to service_role;

drop trigger if exists exam_prep_student_roadmap_windows_audit_v1 on private.exam_prep_student_roadmap_windows;
create trigger exam_prep_student_roadmap_windows_audit_v1
after insert or update or delete on private.exam_prep_student_roadmap_windows
for each row execute function private.exam_prep_audit_row_change_v1();

create table if not exists private.exam_prep_product_roadmap_milestones (
  id bigint generated always as identity primary key,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  roadmap_version text not null,
  milestone_key text not null,
  milestone_kind text not null check(milestone_kind in ('beta_availability','product_content_complete')),
  target_date date not null,
  product_label text not null,
  dependency_role text not null check(dependency_role in ('availability_gate','content_dependency_gate')),
  milestone_status text not null default 'scheduled' check(milestone_status in ('scheduled','met','held','retired')),
  can_block_learner_if_unavailable boolean not null default true,
  can_force_learner_stage boolean not null default false check(not can_force_learner_stage),
  can_raise_learner_mastery boolean not null default false check(not can_raise_learner_mastery),
  can_label_learner_exam_ready boolean not null default false check(not can_label_learner_exam_ready),
  source_note text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(program_version_id,roadmap_version,milestone_key)
);

create unique index if not exists exam_prep_product_roadmap_one_live_milestone_idx
  on private.exam_prep_product_roadmap_milestones(program_version_id,milestone_key)
  where milestone_status<>'retired';

alter table private.exam_prep_product_roadmap_milestones enable row level security;
revoke all on private.exam_prep_product_roadmap_milestones from public,anon,authenticated;
grant all on private.exam_prep_product_roadmap_milestones to service_role;
grant usage,select on sequence private.exam_prep_product_roadmap_milestones_id_seq to service_role;

drop trigger if exists exam_prep_product_roadmap_milestones_audit_v1 on private.exam_prep_product_roadmap_milestones;
create trigger exam_prep_product_roadmap_milestones_audit_v1
after insert or update or delete on private.exam_prep_product_roadmap_milestones
for each row execute function private.exam_prep_audit_row_change_v1();

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active'
), rows(stage_no,stage_key,aw_from,aw_through,target_date,latest_date,latest_basis,source_note) as (values
  (0::smallint,'exam_profile_placement',1::smallint,2::smallint,date '2026-09-21',date '2026-09-28','fixed_date',
   'Controlled beta AW1-2. Dates are planning metadata; Stage 0 exit requires Exam Profile/placement evidence.'),
  (1::smallint,'foundation_fast_track',2::smallint,4::smallint,date '2026-10-12',date '2026-10-19','fixed_date',
   'Controlled beta AW2-4. Target/latest-safe guide recovery only; no calendar promotion.'),
  (2::smallint,'syllabus_building',5::smallint,20::smallint,date '2027-02-01',date '2027-02-08','fixed_date',
   'Controlled beta AW5-20. Exit remains component evidence-gated.'),
  (3::smallint,'syllabus_closure',21::smallint,24::smallint,date '2027-02-22',date '2027-03-01','fixed_date',
   'Controlled beta AW21-24. Product Content-Complete is a dependency only; learner closure requires 100% component evidence and first full baseline.'),
  (4::smallint,'timed_consolidation',25::smallint,28::smallint,date '2027-03-29',date '2027-04-05','fixed_date',
   'Controlled beta AW25-28. Comparable timed/full-paper evidence controls exit.'),
  (5::smallint,'exam_readiness',29::smallint,32::smallint,date '2027-04-26',date '2027-04-30','fixed_date',
   'Controlled beta AW29-32. Exam readiness is learner-only and component-specific; dates cannot manufacture readiness.'),
  (6::smallint,'final_calibration',33::smallint,36::smallint,date '2027-05-24',null::date,'official_component_date',
   'Controlled beta AW33-36. Latest-safe boundary is the official component date, not a fixed product deadline.')
)
insert into private.exam_prep_student_roadmap_windows(
  program_version_id,roadmap_version,cohort_scope,stage_no,stage_key,
  active_week_from,active_week_through,target_exit_date,latest_safe_exit_date,latest_safe_basis,source_note
)
select pv.id,'beta_2026_09_15_v1','controlled_beta_2026_09_15',r.stage_no,r.stage_key,
       r.aw_from,r.aw_through,r.target_date,r.latest_date,r.latest_basis,r.source_note
from pv cross join rows r
on conflict(program_version_id,roadmap_version,stage_no) do nothing;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active'
), rows(milestone_key,milestone_kind,target_date,product_label,dependency_role,source_note) as (values
  ('controlled_beta_availability','beta_availability',date '2026-09-15','Controlled beta availability','availability_gate',
   'Product calendar gate only. Availability never implies learner coverage, mastery, stage or readiness.'),
  ('product_content_complete','product_content_complete',date '2027-02-15','Product Content-Complete','content_dependency_gate',
   'Product/content gate: governed 81-skill support plus mixed/timed/full-cycle runway. It is not Syllabus Closure and never means Learner Exam Ready.')
)
insert into private.exam_prep_product_roadmap_milestones(
  program_version_id,roadmap_version,milestone_key,milestone_kind,target_date,product_label,dependency_role,source_note
)
select pv.id,'product_calendar_2026_2027_v1',r.milestone_key,r.milestone_kind,r.target_date,r.product_label,r.dependency_role,r.source_note
from pv cross join rows r
on conflict(program_version_id,roadmap_version,milestone_key) do nothing;

-- Product->student coupling is one-way and blocking only. The hard runway floor may withhold NEW learning
-- while future syllabus content is genuinely unavailable. Once the governed syllabus runway is complete through AW24,
-- a short remaining week horizon must not block closure/catch-up work that is already published and governed.
create or replace function private.exam_prep_product_dependency_for_week_v1(
  p_program_version_id bigint,
  p_component_code text,
  p_active_week_no smallint
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_runway jsonb;
  v_component jsonb;
  v_ready_through int;
  v_raw_hard_floor boolean;
  v_terminal_content_complete boolean;
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  if p_active_week_no is null or p_active_week_no not between 1 and 36 then raise exception 'exam_prep_bad_active_week'; end if;
  if not exists(
    select 1 from private.exam_prep_program_versions pv
    where pv.id=p_program_version_id and pv.status='active'
  ) then raise exception 'exam_prep_program_version_missing'; end if;

  v_runway:=public.get_exam_prep_content_runway_v1(p_active_week_no);
  v_component:=v_runway->'components'->p_component_code;
  v_ready_through:=coalesce((v_component->>'ready_through_aw')::int,p_active_week_no-1);
  v_raw_hard_floor:=coalesce((v_component->>'hard_floor_2w_green')::boolean,false);
  v_terminal_content_complete:=v_ready_through>=24;

  return jsonb_build_object(
    'component_code',p_component_code,
    'active_week_no',p_active_week_no,
    'dependency_mode','block_new_learning_only',
    'hard_floor_weeks',2,
    'target_weeks',4,
    'ready_through_aw',v_ready_through,
    'ahead_weeks',coalesce((v_component->>'ahead_weeks')::int,0),
    'hard_floor_2w_green',v_raw_hard_floor,
    'terminal_content_runway_complete',v_terminal_content_complete,
    'learning_dependency_green',(v_raw_hard_floor or v_terminal_content_complete),
    'target_4w_green',coalesce((v_component->>'target_4w_green')::boolean,false),
    'can_block_new_learning',true,
    'can_force_learner_stage',false,
    'can_raise_learner_mastery',false,
    'can_create_learner_evidence',false,
    'can_label_learner_exam_ready',false
  );
end;
$$;
revoke all on function private.exam_prep_product_dependency_for_week_v1(bigint,text,smallint) from public,anon,authenticated;
grant execute on function private.exam_prep_product_dependency_for_week_v1(bigint,text,smallint) to service_role;

-- Harden the existing skill/runway guard with the roadmap dependency gate. Weekly-plan generation and
-- learning authorization already use this guard, so unavailable future content can withhold new learning
-- without touching learner state. Terminal AW24 completion keeps already-governed closure learning available.
create or replace function private.exam_prep_skill_runway_ready_for_week_v1(
  p_program_version_id bigint,
  p_component_code text,
  p_skill_code text,
  p_active_week_no smallint
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select coalesce((private.exam_prep_product_dependency_for_week_v1(
      p_program_version_id,p_component_code,p_active_week_no
    )->>'learning_dependency_green')::boolean,false)
    and private.exam_prep_skill_content_ready_v1(p_program_version_id,p_component_code,p_skill_code)
    and exists(
      select 1
      from private.exam_prep_content_runway_releases r
      join private.exam_prep_content_runway_release_skills rs
        on rs.release_id=r.id and rs.required_for_release
      where r.program_version_id=p_program_version_id
        and r.component_code=p_component_code
        and r.schedule_status='active'
        and p_active_week_no between r.active_week_from and r.active_week_through
        and rs.skill_code=p_skill_code
    );
$$;
revoke all on function private.exam_prep_skill_runway_ready_for_week_v1(bigint,text,text,smallint) from public,anon,authenticated;
grant execute on function private.exam_prep_skill_runway_ready_for_week_v1(bigint,text,text,smallint) to service_role;

create or replace function private.exam_prep_product_roadmap_status_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_program bigint;
  v_milestones jsonb;
  v_p1_total int:=0; v_p1_ready int:=0;
  v_p5_total int:=0; v_p5_ready int:=0;
  v_p1_full int:=0; v_p5_full int:=0;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_program is null then raise exception 'exam_prep_program_version_missing'; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'milestone_key',m.milestone_key,
    'milestone_kind',m.milestone_kind,
    'target_date',m.target_date,
    'product_label',m.product_label,
    'dependency_role',m.dependency_role,
    'milestone_status',m.milestone_status,
    'can_block_learner_if_unavailable',m.can_block_learner_if_unavailable,
    'can_force_learner_stage',false,
    'can_raise_learner_mastery',false,
    'can_label_learner_exam_ready',false
  ) order by m.target_date,m.id),'[]'::jsonb)
  into v_milestones
  from private.exam_prep_product_roadmap_milestones m
  where m.program_version_id=v_program and m.milestone_status<>'retired';

  select count(*)::int,count(*) filter(where private.exam_prep_skill_content_ready_v1(n.program_version_id,'P1',n.skill_code))::int
    into v_p1_total,v_p1_ready
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program and n.component_code='P1';
  select count(*)::int,count(*) filter(where private.exam_prep_skill_content_ready_v1(n.program_version_id,'P5',n.skill_code))::int
    into v_p5_total,v_p5_ready
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program and n.component_code='P5';

  select count(*)::int into v_p1_full
  from private.exam_prep_assessments a
  where a.component_code='P1' and a.status='published' and a.assessment_key ilike '%full_paper%';
  select count(*)::int into v_p5_full
  from private.exam_prep_assessments a
  where a.component_code='P5' and a.status='published' and a.assessment_key ilike '%full_paper%';

  return jsonb_build_object(
    'contract_version','p2_11_c22_v1',
    'roadmap_type','product_content',
    'clock_type','calendar_delivery_deadlines_and_runway',
    'milestones',v_milestones,
    'content_support',jsonb_build_object(
      'P1',jsonb_build_object('canonical_skills',v_p1_total,'governed_content_ready_skills',v_p1_ready,'published_full_paper_support',v_p1_full),
      'P5',jsonb_build_object('canonical_skills',v_p5_total,'governed_content_ready_skills',v_p5_ready,'published_full_paper_support',v_p5_full)
    ),
    'product_status_does_not_equal_learner_readiness',true,
    'learner_state_mutated',false,
    'can_force_learner_stage',false,
    'can_raise_learner_mastery',false,
    'can_label_learner_exam_ready',false
  );
end;
$$;
revoke all on function private.exam_prep_product_roadmap_status_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_product_roadmap_status_v1() to service_role;

create or replace function public.get_exam_prep_student_roadmap_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_week smallint;
  v_stage smallint:=0;
  v_stage_available boolean:=false;
  v_window private.exam_prep_student_roadmap_windows%rowtype;
  v_dependency jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select program_version_id,active_week_no into v_program,v_week
  from private.exam_prep_exam_profiles
  where user_id=v_uid;
  if v_program is null or v_week not between 1 and 36 then raise exception 'exam_prep_profile_required'; end if;

  select ss.operational_stage,true into v_stage,v_stage_available
  from private.exam_prep_stage_states ss
  where ss.user_id=v_uid and ss.program_version_id=v_program and ss.component_code=p_component_code
    and ss.engine_version='objective_state_v1'
  order by ss.derived_at desc limit 1;
  v_stage:=coalesce(v_stage,0);

  select * into v_window
  from private.exam_prep_student_roadmap_windows w
  where w.program_version_id=v_program
    and w.roadmap_version='beta_2026_09_15_v1'
    and w.stage_no=v_stage
    and w.status='active'
  limit 1;
  if v_window.id is null then raise exception 'exam_prep_student_roadmap_window_missing'; end if;

  v_dependency:=private.exam_prep_product_dependency_for_week_v1(v_program,p_component_code,v_week);

  return jsonb_build_object(
    'contract_version','p2_11_c22_v1',
    'roadmap_type','student',
    'component_code',p_component_code,
    'clock_type','active_week_plus_target_latest_safe',
    'active_week_no',v_week,
    'operational_stage',v_stage,
    'stage_state_available',v_stage_available,
    'target_exit_date',v_window.target_exit_date,
    'latest_safe_exit_date',v_window.latest_safe_exit_date,
    'latest_safe_basis',v_window.latest_safe_basis,
    'planning_only',true,
    'progression_basis','evidence_only',
    'calendar_auto_promotion',false,
    'product_dependency',v_dependency,
    'product_deadline_can_force_stage',false,
    'product_content_complete_is_syllabus_closure',false,
    'product_content_complete_is_learner_exam_ready',false,
    'p1_p5_mastery_separate',true
  );
end;
$$;
revoke execute on function public.get_exam_prep_student_roadmap_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_student_roadmap_safe_v1(text) to authenticated,service_role;

-- Release assertions: two clocks are structurally distinct and product coupling is blocking-only.
do $$
declare
  v_program bigint;
  v_student int;
  v_product int;
  v_def text;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';

  select count(*) into v_student
  from private.exam_prep_student_roadmap_windows
  where program_version_id=v_program and roadmap_version='beta_2026_09_15_v1' and status='active';
  if v_student<>7 then raise exception 'P2-11 student roadmap: expected 7 stage windows, got %',v_student; end if;

  select count(*) into v_product
  from private.exam_prep_product_roadmap_milestones
  where program_version_id=v_program and roadmap_version='product_calendar_2026_2027_v1' and milestone_status<>'retired';
  if v_product<>2 then raise exception 'P2-11 product roadmap: expected 2 canonical milestones, got %',v_product; end if;

  if not exists(
    select 1 from private.exam_prep_product_roadmap_milestones
    where program_version_id=v_program and milestone_key='product_content_complete'
      and target_date=date '2027-02-15' and product_label='Product Content-Complete'
  ) then raise exception 'P2-11 Product Content-Complete milestone missing/mislabeled'; end if;

  if exists(
    select 1 from private.exam_prep_product_roadmap_milestones
    where program_version_id=v_program and milestone_status<>'retired'
      and (can_force_learner_stage or can_raise_learner_mastery or can_label_learner_exam_ready)
  ) then raise exception 'P2-11 forbidden product-to-learner authority detected'; end if;

  if exists(
    select 1 from private.exam_prep_student_roadmap_windows
    where program_version_id=v_program and status='active'
      and (progression_basis<>'evidence_only' or not planning_only or calendar_auto_promotion)
  ) then raise exception 'P2-11 student roadmap gained calendar promotion authority'; end if;

  select pg_get_functiondef('private.exam_prep_skill_runway_ready_for_week_v1(bigint,text,text,smallint)'::regprocedure) into v_def;
  if position('learning_dependency_green' in v_def)=0 then
    raise exception 'P2-11 product dependency gate is not enforced on learning';
  end if;

  if has_table_privilege('authenticated','private.exam_prep_student_roadmap_windows','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_product_roadmap_milestones','SELECT') then
    raise exception 'P2-11 private roadmap tables exposed directly';
  end if;
end $$;

commit;
