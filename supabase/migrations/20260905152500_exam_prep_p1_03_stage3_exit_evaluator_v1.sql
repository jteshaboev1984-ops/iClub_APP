-- P1-03 pre-live hardening: machine-readable Stage-3 Syllabus Closure exit evaluator.
-- This migration DOES NOT unlock Stage 4. The explicit key-skill registry is deliberately pending/empty
-- until a separate governance decision identifies the canonical key skill codes.
-- Source law: 100% coverage, every canonical skill >= L2, key skills >= L3, first comparable full baseline,
-- no unknown syllabus section; evaluated independently per component.
begin;

create table if not exists private.exam_prep_stage3_exit_rules (
  rule_version text primary key,
  status text not null check (status in ('draft','active','retired')),
  min_all_skill_level smallint not null default 2 check (min_all_skill_level between 0 and 3),
  min_key_skill_level smallint not null default 3 check (min_key_skill_level between 0 and 3),
  require_comparable_full_baseline boolean not null default true,
  key_registry_status text not null default 'pending' check (key_registry_status in ('pending','approved','retired')),
  source_note text not null,
  created_at timestamptz not null default now(),
  check (min_key_skill_level >= min_all_skill_level)
);

create unique index if not exists exam_prep_stage3_exit_rules_one_active_idx
  on private.exam_prep_stage3_exit_rules ((status)) where status='active';

insert into private.exam_prep_stage3_exit_rules(
  rule_version,status,min_all_skill_level,min_key_skill_level,
  require_comparable_full_baseline,key_registry_status,source_note
) values (
  'stage3_exit_v1_2026_09_05','active',2,3,true,'pending',
  'Master Implementation Plan v1.1 / Annual Roadmap: Stage 3 Syllabus Closure exits separately per component only at 100% canonical coverage, every point >=L2, explicitly governed key skills >=L3, first comparable full-paper baseline, and no unknown syllabus section. The source documents do not enumerate key skill codes; registry therefore remains pending/fail-closed until separate governance approval.'
)
on conflict(rule_version) do update set
  status=excluded.status,
  min_all_skill_level=excluded.min_all_skill_level,
  min_key_skill_level=excluded.min_key_skill_level,
  require_comparable_full_baseline=excluded.require_comparable_full_baseline,
  key_registry_status=excluded.key_registry_status,
  source_note=excluded.source_note;

create table if not exists private.exam_prep_stage3_key_skills (
  rule_version text not null references private.exam_prep_stage3_exit_rules(rule_version) on delete restrict,
  program_version_id bigint not null,
  component_code text not null check (component_code in ('P1','P5')),
  skill_code text not null,
  governance_basis text not null,
  created_at timestamptz not null default now(),
  primary key(rule_version,program_version_id,component_code,skill_code),
  foreign key(program_version_id,skill_code)
    references private.exam_prep_syllabus_nodes(program_version_id,skill_code) on delete restrict
);

create or replace function private.exam_prep_validate_stage3_key_skill_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_component text;
begin
  select n.component_code into v_component
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=new.program_version_id
    and n.skill_code=new.skill_code;

  if v_component is null then
    raise exception 'exam_prep_stage3_key_skill_not_canonical';
  end if;
  if v_component<>new.component_code then
    raise exception 'exam_prep_stage3_key_skill_component_mismatch expected=% actual=%',v_component,new.component_code;
  end if;
  return new;
end;
$$;

revoke all on function private.exam_prep_validate_stage3_key_skill_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_validate_stage3_key_skill_v1() to service_role;

drop trigger if exists exam_prep_stage3_key_skill_validate_v1 on private.exam_prep_stage3_key_skills;
create trigger exam_prep_stage3_key_skill_validate_v1
before insert or update on private.exam_prep_stage3_key_skills
for each row execute function private.exam_prep_validate_stage3_key_skill_v1();

-- Final score comparability after written self-review. This intentionally mirrors
-- public.get_exam_prep_timed_result_safe_v1 rather than relying on the finalize-time
-- base_score_comparable snapshot, which can still be false while written marks are pending.
create or replace function private.exam_prep_timed_score_comparable_v1(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select coalesce((
    select t.timing_comparable
       and t.attempt_kind<>'diagnostic_full'
       and greatest(
             0,
             t.pending_review_in_time_marks - coalesce((
               select sum(sm.max_marks)
               from private.exam_prep_timed_written_self_marks sm
               where sm.session_id=t.session_id and sm.was_in_time
             ),0)
           )=0
       and greatest(
             0,
             t.pending_review_after_time_marks - coalesce((
               select sum(sm.max_marks)
               from private.exam_prep_timed_written_self_marks sm
               where sm.session_id=t.session_id and not sm.was_in_time
             ),0)
           )=0
    from private.exam_prep_timed_attempt_results t
    where t.session_id=p_session_id
  ),false);
$$;

revoke all on function private.exam_prep_timed_score_comparable_v1(uuid) from public,anon,authenticated;
grant execute on function private.exam_prep_timed_score_comparable_v1(uuid) to service_role;

create or replace function private.exam_prep_stage3_exit_status_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_rule private.exam_prep_stage3_exit_rules%rowtype;
  v_engine text;
  v_denominator int:=0;
  v_coverage int:=0;
  v_l2_or_higher int:=0;
  v_expected_sections int:=0;
  v_covered_sections int:=0;
  v_key_total int:=0;
  v_key_l3 int:=0;
  v_full_baselines int:=0;
  v_ready boolean:=false;
  v_reason text:='rule_missing';
begin
  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_bad_component';
  end if;

  select * into v_rule
  from private.exam_prep_stage3_exit_rules r
  where r.status='active'
  order by r.created_at desc
  limit 1;

  if v_rule.rule_version is null then
    return jsonb_build_object(
      'ready',false,'reason_code','rule_missing','component_code',p_component_code,
      'program_version_id',p_program_version_id
    );
  end if;

  select ev.engine_version into v_engine
  from private.exam_prep_state_engine_versions ev
  where ev.status='active'
  order by ev.created_at desc
  limit 1;

  select count(*),count(distinct n.official_syllabus_section)
    into v_denominator,v_expected_sections
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=p_program_version_id
    and n.component_code=p_component_code;

  if v_engine is not null then
    select
      count(*) filter(where coalesce(ss.coverage_confirmed,false)),
      count(*) filter(where coalesce(ss.objective_level,0)>=v_rule.min_all_skill_level),
      count(distinct n.official_syllabus_section) filter(where coalesce(ss.coverage_confirmed,false))
      into v_coverage,v_l2_or_higher,v_covered_sections
    from private.exam_prep_syllabus_nodes n
    left join private.exam_prep_skill_states ss
      on ss.user_id=p_user_id
     and ss.program_version_id=n.program_version_id
     and ss.component_code=n.component_code
     and ss.skill_code=n.skill_code
     and ss.engine_version=v_engine
    where n.program_version_id=p_program_version_id
      and n.component_code=p_component_code;
  end if;

  select
    count(*),
    count(*) filter(where coalesce(ss.objective_level,0)>=v_rule.min_key_skill_level)
    into v_key_total,v_key_l3
  from private.exam_prep_stage3_key_skills k
  left join private.exam_prep_skill_states ss
    on ss.user_id=p_user_id
   and ss.program_version_id=k.program_version_id
   and ss.component_code=k.component_code
   and ss.skill_code=k.skill_code
   and ss.engine_version=v_engine
  where k.rule_version=v_rule.rule_version
    and k.program_version_id=p_program_version_id
    and k.component_code=p_component_code;

  select count(*) into v_full_baselines
  from private.exam_prep_timed_attempt_results t
  join private.exam_prep_sessions s on s.id=t.session_id
  where t.user_id=p_user_id
    and t.component_code=p_component_code
    and s.program_version_id=p_program_version_id
    and s.status='finalized'
    and s.session_type='paper'
    and t.attempt_kind='full_paper'
    and t.timing_rule='official_full'
    and t.comparison_scope='full'
    and t.strict_timing
    and private.exam_prep_timed_score_comparable_v1(t.session_id);

  if v_engine is null then
    v_reason:='state_engine_missing';
  elsif v_denominator=0 or v_expected_sections=0 then
    v_reason:='syllabus_scope_missing';
  elsif v_rule.key_registry_status<>'approved' then
    v_reason:='key_registry_pending';
  elsif v_key_total=0 then
    v_reason:='key_registry_empty';
  elsif v_coverage<>v_denominator then
    v_reason:='coverage_incomplete';
  elsif v_l2_or_higher<>v_denominator then
    v_reason:='l2_incomplete';
  elsif v_key_l3<>v_key_total then
    v_reason:='key_l3_incomplete';
  elsif v_covered_sections<>v_expected_sections then
    v_reason:='unknown_section';
  elsif v_rule.require_comparable_full_baseline and v_full_baselines<1 then
    v_reason:='full_baseline_missing';
  else
    v_reason:='ready';
    v_ready:=true;
  end if;

  return jsonb_build_object(
    'ready',v_ready,
    'reason_code',v_reason,
    'rule_version',v_rule.rule_version,
    'key_registry_status',v_rule.key_registry_status,
    'component_code',p_component_code,
    'program_version_id',p_program_version_id,
    'engine_version',v_engine,
    'denominator_count',v_denominator,
    'coverage_count',v_coverage,
    'min_all_skill_level',v_rule.min_all_skill_level,
    'l2_or_higher_count',v_l2_or_higher,
    'key_skill_count',v_key_total,
    'min_key_skill_level',v_rule.min_key_skill_level,
    'key_l3_count',v_key_l3,
    'expected_section_count',v_expected_sections,
    'covered_section_count',v_covered_sections,
    'comparable_full_baseline_count',v_full_baselines,
    'stage4_unlocked',false
  );
end;
$$;

revoke all on function private.exam_prep_stage3_exit_status_v1(uuid,bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_stage3_exit_status_v1(uuid,bigint,text) to service_role;

-- Deployment invariants: evaluator ships fail-closed, no key codes are invented,
-- and the existing operational projection still caps automatic progression at Stage 3.
do $$
declare
  v_rule private.exam_prep_stage3_exit_rules%rowtype;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_keys int;
  v_active int;
  v_papers int;
begin
  select * into v_rule from private.exam_prep_stage3_exit_rules where status='active';
  if v_rule.rule_version<>'stage3_exit_v1_2026_09_05'
     or v_rule.min_all_skill_level<>2
     or v_rule.min_key_skill_level<>3
     or not v_rule.require_comparable_full_baseline
     or v_rule.key_registry_status<>'pending' then
    raise exception 'P1-03 Stage-3 exit rule drift';
  end if;

  select count(*) into v_keys
  from private.exam_prep_stage3_key_skills
  where rule_version=v_rule.rule_version;
  if v_keys<>0 then raise exception 'P1-03 Stage-3 key registry must deploy empty/pending rows=%',v_keys; end if;

  if not exists(
    select 1 from private.exam_prep_operational_stage_rules
    where status='active' and max_automatic_stage=3
  ) then raise exception 'P1-03 Stage-3 exit evaluator requires Stage-4 projection to remain disabled'; end if;

  select count(*) into v_papers
  from private.exam_prep_timed_assessment_contracts c
  join private.exam_prep_assessments a on a.id=c.assessment_id
  where c.status='published' and c.attempt_kind='full_paper'
    and c.timing_rule='official_full' and c.comparison_scope='full'
    and a.assessment_key in ('p1_stage3_full_paper_01','p5_stage3_full_paper_01');
  if v_papers<>2 then raise exception 'P1-03 Stage-3 exit evaluator requires both governed full-paper baselines, found=%',v_papers; end if;

  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 Stage-3 exit evaluator deployment requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 Stage-3 exit evaluator active entitlement residue=%',v_active; end if;
end $$;

commit;