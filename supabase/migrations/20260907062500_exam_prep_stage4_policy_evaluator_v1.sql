-- Exam Prep Stage-4 Timed Consolidation policy/evaluator v1.
-- Approves the previously rollback-tested conservative policy unchanged.
-- This release is read-only with respect to learner evidence and DOES NOT yet raise the operational stage ceiling
-- or publish Paper02. It only makes Stage-4 exit eligibility machine-readable and approves the Stage-4 policy control.

begin;

create table if not exists private.exam_prep_stage4_exit_rules (
  rule_version text primary key,
  status text not null check(status in ('draft','active','retired')),
  min_compatible_full_attempts smallint not null check(min_compatible_full_attempts>=2),
  require_unattempted_nonworsening boolean not null default true,
  require_after_time_nonworsening boolean not null default true,
  require_one_improvement_or_zero boolean not null default true,
  allow_explicit_corrective_plan boolean not null default true,
  source_note text not null,
  created_at timestamptz not null default now()
);

create unique index if not exists exam_prep_stage4_exit_rules_one_active_idx
  on private.exam_prep_stage4_exit_rules ((status)) where status='active';

insert into private.exam_prep_stage4_exit_rules(
  rule_version,status,min_compatible_full_attempts,
  require_unattempted_nonworsening,require_after_time_nonworsening,
  require_one_improvement_or_zero,allow_explicit_corrective_plan,source_note
) values (
  'stage4_exit_v1_2026_09_07','active',2,true,true,true,true,
  'iClub Stage-4 governance v1. Based on Master Plan P2-04 plus the rollback-tested 2026-09-05 conservative proposal: Stage-3 exit complete; latest two attempts in the selected compatible strict full-paper family; unattempted and after-time shares do not worsen; at least one improves unless both remain zero; every below-L3 skill has an exact active correction case plus a concrete due plan action or scheduled retest. No score compensation and no arbitrary percentage-point trend threshold.'
)
on conflict(rule_version) do update set
  status=excluded.status,
  min_compatible_full_attempts=excluded.min_compatible_full_attempts,
  require_unattempted_nonworsening=excluded.require_unattempted_nonworsening,
  require_after_time_nonworsening=excluded.require_after_time_nonworsening,
  require_one_improvement_or_zero=excluded.require_one_improvement_or_zero,
  allow_explicit_corrective_plan=excluded.allow_explicit_corrective_plan,
  source_note=excluded.source_note;

alter table private.exam_prep_stage4_exit_rules enable row level security;
revoke all on private.exam_prep_stage4_exit_rules from public,anon,authenticated;
grant all on private.exam_prep_stage4_exit_rules to service_role;

do $$ begin
  execute 'create trigger exam_prep_stage4_exit_rules_audit_v1 after insert or update or delete on private.exam_prep_stage4_exit_rules for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null; end $$;

create or replace function private.exam_prep_stage4_exit_status_v1(
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
  v_rule private.exam_prep_stage4_exit_rules%rowtype;
  v_raw jsonb;
  v_stage3 jsonb;
  v_family jsonb;
  v_attempts int:=0;
  v_latest_u numeric;
  v_previous_u numeric;
  v_latest_a numeric;
  v_previous_a numeric;
  v_trend_ready boolean:=false;
  v_below int:=0;
  v_unqualified int:=0;
  v_corrections_ready boolean:=false;
  v_ready boolean:=false;
  v_reason text:='rule_missing';
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select * into v_rule
  from private.exam_prep_stage4_exit_rules
  where status='active'
  order by created_at desc
  limit 1;

  if v_rule.rule_version is null then
    return jsonb_build_object('ready',false,'reason_code','rule_missing','component_code',p_component_code,'stage4_unlocked',false,'stage5_unlocked',false);
  end if;

  v_raw:=private.exam_prep_stage4_raw_evidence_v1(p_user_id,p_program_version_id,p_component_code);
  v_stage3:=v_raw->'stage3_exit_status';

  select e into v_family
  from jsonb_array_elements(coalesce(v_raw->'comparison_families','[]'::jsonb)) e
  order by coalesce((e->>'attempt_count')::int,0) desc,
           coalesce((e->>'latest_at')::timestamptz,'epoch'::timestamptz) desc,
           coalesce(e->>'family_key','')
  limit 1;

  if v_family is not null then
    v_attempts:=coalesce((v_family->>'attempt_count')::int,0);
    v_latest_u:=(v_family->>'latest_unattempted_share')::numeric;
    v_previous_u:=(v_family->>'previous_unattempted_share')::numeric;
    v_latest_a:=(v_family->>'latest_after_time_share')::numeric;
    v_previous_a:=(v_family->>'previous_after_time_share')::numeric;

    if v_attempts>=v_rule.min_compatible_full_attempts
       and v_latest_u is not null and v_previous_u is not null
       and v_latest_a is not null and v_previous_a is not null
       and v_latest_u between 0 and 1 and v_previous_u between 0 and 1
       and v_latest_a between 0 and 1 and v_previous_a between 0 and 1
       and (not v_rule.require_unattempted_nonworsening or v_latest_u<=v_previous_u)
       and (not v_rule.require_after_time_nonworsening or v_latest_a<=v_previous_a)
       and (
         not v_rule.require_one_improvement_or_zero
         or v_latest_u<v_previous_u
         or v_latest_a<v_previous_a
         or (v_latest_u=0 and v_latest_a=0)
       ) then
      v_trend_ready:=true;
    end if;
  end if;

  v_below:=coalesce((v_raw->>'below_l3_count')::int,0);
  if v_below=0 then
    v_corrections_ready:=true;
  elsif v_rule.allow_explicit_corrective_plan then
    select count(*) into v_unqualified
    from jsonb_array_elements(coalesce(v_raw->'below_l3_details','[]'::jsonb)) d
    where coalesce((d->>'active_correction_cases')::int,0)<1
       or (
         coalesce((d->>'pending_plan_actions_with_due')::int,0)<1
         and coalesce((d->>'scheduled_retests_with_due')::int,0)<1
       );
    v_corrections_ready:=(v_unqualified=0);
  end if;

  if not coalesce((v_stage3->>'ready')::boolean,false) then
    v_reason:='stage3_exit_incomplete';
  elsif v_family is null or v_attempts<v_rule.min_compatible_full_attempts then
    v_reason:='two_comparable_full_attempts_incomplete';
  elsif not v_trend_ready then
    v_reason:='timing_trend_incomplete';
  elsif not v_corrections_ready then
    v_reason:='l3_or_corrective_plan_incomplete';
  else
    v_reason:='ready';
    v_ready:=true;
  end if;

  return jsonb_build_object(
    'ready',v_ready,
    'reason_code',v_reason,
    'rule_version',v_rule.rule_version,
    'component_code',p_component_code,
    'program_version_id',p_program_version_id,
    'stage3_exit_ready',coalesce((v_stage3->>'ready')::boolean,false),
    'selected_family_key',v_family->>'family_key',
    'selected_family_attempt_count',v_attempts,
    'min_compatible_full_attempts',v_rule.min_compatible_full_attempts,
    'latest_unattempted_share',v_latest_u,
    'previous_unattempted_share',v_previous_u,
    'latest_after_time_share',v_latest_a,
    'previous_after_time_share',v_previous_a,
    'trend_gate_ready',v_trend_ready,
    'below_l3_count',v_below,
    'unqualified_below_l3_count',v_unqualified,
    'corrective_plan_gate_ready',v_corrections_ready,
    'stage4_exit_ready',v_ready,
    'stage4_unlocked',false,
    'stage5_unlocked',false
  );
end;
$$;

revoke all on function private.exam_prep_stage4_exit_status_v1(uuid,bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_stage4_exit_status_v1(uuid,bigint,text) to service_role;

-- Approve the policy control only. Paper02 remains separately pending/unreleased until the stage-access release.
update private.exam_prep_stage4_release_controls
set stage4_policy_status='approved',
    source_note=source_note || ' Policy amendment 2026-09-07: the previously rollback-tested conservative Stage-4 trend/corrective policy was approved unchanged and evaluator v1 deployed. Paper02 release remains a separate gate.',
    updated_at=now()
where status='active';

do $$
declare
  v_control private.exam_prep_stage4_release_controls%rowtype;
  v_key_status text;
  v_keys int;
  v_max smallint;
  v_cfg private.exam_prep_feature_config%rowtype;
begin
  select * into v_control from private.exam_prep_stage4_release_controls where status='active';
  if v_control.stage4_policy_status<>'approved' or v_control.paper02_release_status<>'pending' then
    raise exception 'Stage4 evaluator v1: release control state mismatch policy=% paper=%',v_control.stage4_policy_status,v_control.paper02_release_status;
  end if;
  select key_registry_status into v_key_status from private.exam_prep_stage3_exit_rules where status='active';
  select count(*) into v_keys from private.exam_prep_stage3_key_skills;
  if v_key_status<>'approved' or v_keys<>15 then
    raise exception 'Stage4 evaluator v1: governed Stage3 key registry required status=% rows=%',v_key_status,v_keys;
  end if;
  select max_automatic_stage into v_max from private.exam_prep_operational_stage_rules where status='active';
  if v_max<>3 then raise exception 'Stage4 evaluator v1: this release must not unlock Stage4 max=%',v_max; end if;
  if to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is null then raise exception 'Stage4 evaluator v1 missing'; end if;
  if exists(
    select 1 from private.exam_prep_timed_assessment_contracts c
    join private.exam_prep_assessments a on a.id=c.assessment_id
    where a.assessment_key in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02')
  ) then raise exception 'Stage4 evaluator v1: Paper02 must remain unreleased'; end if;
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'controlled_beta' or not v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or v_cfg.kill_switch then
    raise exception 'Stage4 evaluator v1: expected live Core-only controlled beta boundary';
  end if;
end $$;

commit;
