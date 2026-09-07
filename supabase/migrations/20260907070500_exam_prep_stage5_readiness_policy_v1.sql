-- Exam Prep Stage-5 App Readiness policy/evaluator v1.
-- Engineering is complete without inventing Cambridge thresholds: the structural readiness law is approved,
-- while series/target/component thresholds are versioned data and must be explicitly approved before READY can be returned.
-- No threshold rows are fabricated by this migration. No Mentor Verified readiness is created.

begin;

create table if not exists private.exam_prep_stage5_readiness_rules (
  rule_version text primary key,
  status text not null check(status in ('draft','active','retired')),
  min_comparable_full_attempts smallint not null default 3 check(min_comparable_full_attempts>=3),
  require_stage4_exit boolean not null default true,
  require_all_skills_l3 boolean not null default true,
  require_all_corrections_closed boolean not null default true,
  require_last_three_above_threshold boolean not null default true,
  source_note text not null,
  created_at timestamptz not null default now()
);
create unique index if not exists exam_prep_stage5_readiness_rules_one_active_idx
  on private.exam_prep_stage5_readiness_rules((status)) where status='active';

create table if not exists private.exam_prep_stage5_thresholds (
  id bigint generated always as identity primary key,
  threshold_version text not null,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  exam_series_key text not null,
  target_grade text not null,
  min_in_time_score_pct numeric(5,2) not null check(min_in_time_score_pct between 0 and 100),
  max_unattempted_share numeric(7,6) not null check(max_unattempted_share between 0 and 1),
  max_after_time_share numeric(7,6) not null check(max_after_time_share between 0 and 1),
  status text not null default 'draft' check(status in ('draft','approved','retired')),
  source_ref text not null,
  policy_note text not null,
  approved_at timestamptz null,
  created_at timestamptz not null default now(),
  unique(threshold_version,program_version_id,component_code,exam_series_key,target_grade)
);
create unique index if not exists exam_prep_stage5_thresholds_one_approved_idx
  on private.exam_prep_stage5_thresholds(program_version_id,component_code,lower(exam_series_key),upper(target_grade))
  where status='approved';

alter table private.exam_prep_stage5_readiness_rules enable row level security;
alter table private.exam_prep_stage5_thresholds enable row level security;
revoke all on private.exam_prep_stage5_readiness_rules from public,anon,authenticated;
revoke all on private.exam_prep_stage5_thresholds from public,anon,authenticated;
grant all on private.exam_prep_stage5_readiness_rules to service_role;
grant all on private.exam_prep_stage5_thresholds to service_role;
grant usage,select on sequence private.exam_prep_stage5_thresholds_id_seq to service_role;

do $$ begin execute 'create trigger exam_prep_stage5_readiness_rules_audit_v1 after insert or update or delete on private.exam_prep_stage5_readiness_rules for each row execute function private.exam_prep_audit_row_change_v1()'; exception when duplicate_object then null; end $$;
do $$ begin execute 'create trigger exam_prep_stage5_thresholds_audit_v1 after insert or update or delete on private.exam_prep_stage5_thresholds for each row execute function private.exam_prep_audit_row_change_v1()'; exception when duplicate_object then null; end $$;

insert into private.exam_prep_stage5_readiness_rules(
  rule_version,status,min_comparable_full_attempts,require_stage4_exit,require_all_skills_l3,
  require_all_corrections_closed,require_last_three_above_threshold,source_note
) values (
  'stage5_readiness_v1_2026_09_07','active',3,true,true,true,true,
  'Master Plan P2-05 / Annual Roadmap: component-specific App Readiness requires at least three comparable strict full-paper attempts, last-three above an individual target/series-aware threshold, minimal unattempted marks, timing control, fundamentals closed and corrective cycles complete. iClub v1 implements the conservative scalable Core interpretation: all 81-map skills for the component must be objective L3, all correction cases closed, and each of the latest three in-time scores/timing shares must meet an explicitly approved threshold row. No fixed Cambridge grade threshold is invented; no arbitrary recency or paper-form diversity rule is added.'
);

create or replace function private.exam_prep_stage5_readiness_status_v1(
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
  v_rule private.exam_prep_stage5_readiness_rules%rowtype;
  v_threshold private.exam_prep_stage5_thresholds%rowtype;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_raw jsonb;
  v_attempt jsonb;
  v_sid uuid;
  v_marks_in_time int;
  v_marks_available int;
  v_score numeric;
  v_scores_ok boolean:=true;
  v_unattempted_ok boolean:=true;
  v_after_time_ok boolean:=true;
  v_eval jsonb:='[]'::jsonb;
  v_attempt_count int:=0;
  v_below_l3 int:=0;
  v_open_corrections int:=0;
  v_ready boolean:=false;
  v_reason text:='rule_missing';
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select * into v_rule from private.exam_prep_stage5_readiness_rules where status='active' order by created_at desc limit 1;
  if v_rule.rule_version is null then
    return jsonb_build_object('ready',false,'reason_code','rule_missing','component_code',p_component_code,'stage6_unlocked',false);
  end if;

  v_raw:=private.exam_prep_stage5_raw_readiness_v1(p_user_id,p_program_version_id,p_component_code);
  v_attempt_count:=coalesce((v_raw->>'last_three_count')::int,0);
  v_below_l3:=coalesce((v_raw->>'below_l3_count')::int,0);
  v_open_corrections:=coalesce((v_raw->>'unresolved_correction_case_count')::int,0);

  select * into v_profile from private.exam_prep_exam_profiles
  where user_id=p_user_id and program_version_id=p_program_version_id;

  if v_profile.user_id is not null and nullif(trim(v_profile.exam_series),'') is not null and nullif(trim(v_profile.target_grade),'') is not null then
    select * into v_threshold
    from private.exam_prep_stage5_thresholds
    where status='approved'
      and program_version_id=p_program_version_id
      and component_code=p_component_code
      and lower(trim(exam_series_key))=lower(trim(v_profile.exam_series))
      and upper(trim(target_grade))=upper(trim(v_profile.target_grade))
    order by approved_at desc nulls last,id desc
    limit 1;
  end if;

  if v_threshold.id is not null and v_attempt_count=3 then
    for v_attempt in select value from jsonb_array_elements(coalesce(v_raw->'last_three_attempts','[]'::jsonb)) loop
      v_sid:=(v_attempt->>'session_id')::uuid;
      select
        r.objective_marks_in_time + coalesce(sum(sm.marks_awarded) filter(where sm.was_in_time),0)::int,
        r.marks_available
      into v_marks_in_time,v_marks_available
      from private.exam_prep_timed_attempt_results r
      left join private.exam_prep_timed_written_self_marks sm on sm.session_id=r.session_id
      where r.session_id=v_sid and r.user_id=p_user_id and r.component_code=p_component_code
      group by r.objective_marks_in_time,r.marks_available;

      v_score:=case when coalesce(v_marks_available,0)>0 then (100.0*v_marks_in_time/v_marks_available) else null end;
      if v_score is null or v_score<v_threshold.min_in_time_score_pct then v_scores_ok:=false; end if;
      if (v_attempt->>'unattempted_share')::numeric>v_threshold.max_unattempted_share then v_unattempted_ok:=false; end if;
      if (v_attempt->>'after_time_share')::numeric>v_threshold.max_after_time_share then v_after_time_ok:=false; end if;

      v_eval:=v_eval || jsonb_build_array(v_attempt || jsonb_build_object(
        'marks_in_time',v_marks_in_time,
        'in_time_score_pct',round(v_score,2),
        'score_threshold_met',coalesce(v_score>=v_threshold.min_in_time_score_pct,false),
        'unattempted_threshold_met',coalesce((v_attempt->>'unattempted_share')::numeric<=v_threshold.max_unattempted_share,false),
        'after_time_threshold_met',coalesce((v_attempt->>'after_time_share')::numeric<=v_threshold.max_after_time_share,false)
      ));
    end loop;
  else
    v_scores_ok:=false;
    v_unattempted_ok:=false;
    v_after_time_ok:=false;
  end if;

  if v_rule.require_stage4_exit and not coalesce(((v_raw->'stage4_exit_status')->>'ready')::boolean,false) then
    v_reason:='stage4_exit_incomplete';
  elsif v_attempt_count<v_rule.min_comparable_full_attempts then
    v_reason:='three_comparable_attempts_incomplete';
  elsif v_threshold.id is null then
    v_reason:='threshold_configuration_pending';
  elsif v_rule.require_all_skills_l3 and v_below_l3<>0 then
    v_reason:='objective_skill_stability_incomplete';
  elsif v_rule.require_all_corrections_closed and v_open_corrections<>0 then
    v_reason:='corrective_cycles_open';
  elsif v_rule.require_last_three_above_threshold and not v_scores_ok then
    v_reason:='last_three_below_individual_threshold';
  elsif not v_unattempted_ok then
    v_reason:='unattempted_marks_not_minimal';
  elsif not v_after_time_ok then
    v_reason:='after_time_dependency_not_closed';
  else
    v_reason:='ready';
    v_ready:=true;
  end if;

  return jsonb_build_object(
    'ready',v_ready,
    'app_readiness_estimate',case when v_ready then 'STRONG_OBJECTIVE_EVIDENCE' else 'INSUFFICIENT_EVIDENCE' end,
    'reason_code',v_reason,
    'rule_version',v_rule.rule_version,
    'component_code',p_component_code,
    'program_version_id',p_program_version_id,
    'exam_series',v_profile.exam_series,
    'target_grade',v_profile.target_grade,
    'threshold_configured',(v_threshold.id is not null),
    'threshold_version',v_threshold.threshold_version,
    'min_in_time_score_pct',v_threshold.min_in_time_score_pct,
    'max_unattempted_share',v_threshold.max_unattempted_share,
    'max_after_time_share',v_threshold.max_after_time_share,
    'last_three_count',v_attempt_count,
    'last_three_evaluation',v_eval,
    'below_l3_count',v_below_l3,
    'unresolved_correction_case_count',v_open_corrections,
    'score_window_ready',v_scores_ok,
    'unattempted_gate_ready',v_unattempted_ok,
    'after_time_gate_ready',v_after_time_ok,
    'mentor_verified_readiness',false,
    'stage5_ready',v_ready,
    'stage6_unlocked',false
  );
end;
$$;

revoke all on function private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text) to service_role;

create or replace function public.get_exam_prep_readiness_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_uid uuid; v_program bigint; v_result jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  select program_version_id into v_program from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_program is null then raise exception 'exam_prep_profile_required'; end if;
  v_result:=private.exam_prep_stage5_readiness_status_v1(v_uid,v_program,p_component_code);
  return v_result - 'threshold_version';
end;
$$;
revoke execute on function public.get_exam_prep_readiness_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_readiness_safe_v1(text) to authenticated,service_role;

update private.exam_prep_stage5_release_controls
set stage5_policy_status='approved',
    source_note=source_note || ' Policy amendment 2026-09-07: structural Stage-5 App Readiness evaluator deployed. Numeric series/target thresholds remain separately versioned and fail closed when absent; no Cambridge threshold is fabricated.',
    updated_at=now()
where status='active';

do $$
declare
  v_control private.exam_prep_stage5_release_controls%rowtype;
  v_stage4 private.exam_prep_stage4_release_controls%rowtype;
  v_max smallint;
  v_thresholds int;
  v_cfg private.exam_prep_feature_config%rowtype;
begin
  select * into v_control from private.exam_prep_stage5_release_controls where status='active';
  if v_control.stage5_policy_status<>'approved' or v_control.paper03_release_status<>'pending' then
    raise exception 'Stage5 policy v1: release control mismatch';
  end if;
  select * into v_stage4 from private.exam_prep_stage4_release_controls where status='active';
  if v_stage4.stage4_policy_status<>'approved' or v_stage4.paper02_release_status<>'approved' then
    raise exception 'Stage5 policy v1: Stage4 governance must be fully approved';
  end if;
  if to_regprocedure('private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text)') is null then raise exception 'Stage5 policy v1 evaluator missing'; end if;
  if to_regprocedure('public.get_exam_prep_readiness_safe_v1(text)') is null then raise exception 'Stage5 policy v1 safe RPC missing'; end if;
  select count(*) into v_thresholds from private.exam_prep_stage5_thresholds where status='approved';
  if v_thresholds<>0 then raise exception 'Stage5 policy v1: this migration must not invent production readiness thresholds'; end if;
  select max_automatic_stage into v_max from private.exam_prep_operational_stage_rules where status='active';
  if v_max<>4 then raise exception 'Stage5 policy v1: Stage5 access must remain locked in this release max=%',v_max; end if;
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'controlled_beta' or not v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or v_cfg.kill_switch then raise exception 'Stage5 policy v1: Core-only canary boundary drift'; end if;
end $$;

commit;
