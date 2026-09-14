begin;

-- P2-67: version the complete synthetic learner scenario set before broad runs.
-- This migration stores definitions only. It creates no auth/public users, no
-- learner evidence, no beta membership and no feature-state change.

create table if not exists private.exam_prep_synthetic_scenario_sets (
  scenario_set_version text primary key,
  status text not null check(status in ('active','retired')),
  canonical_profile_count integer not null check(canonical_profile_count>=0),
  adversarial_variant_count integer not null check(adversarial_variant_count>=0),
  total_scenario_count integer not null check(total_scenario_count=canonical_profile_count+adversarial_variant_count),
  required_locales text[] not null,
  manifest_hash text not null check(manifest_hash ~ '^[0-9a-f]{32}$'),
  source_ref text not null,
  created_at timestamptz not null default now(),
  activated_at timestamptz null,
  check(status<>'active' or activated_at is not null)
);
create unique index if not exists exam_prep_synthetic_scenario_sets_one_active_idx
  on private.exam_prep_synthetic_scenario_sets((status)) where status='active';

create table if not exists private.exam_prep_synthetic_scenarios (
  scenario_set_version text not null references private.exam_prep_synthetic_scenario_sets(scenario_set_version) on delete restrict,
  scenario_code text not null,
  deterministic_ordinal integer not null check(deterministic_ordinal>0),
  scenario_type text not null check(scenario_type in ('canonical_profile','adversarial_variant')),
  source_profile_id text null,
  capability_mode text not null check(capability_mode in ('core','ai_shadow','mentor_technical')),
  component_focus text not null check(component_focus in ('P1','P5','BOTH','NONE')),
  learner_facing boolean not null default true,
  required_locales text[] not null,
  tags text[] not null,
  initial_state jsonb not null default '{}'::jsonb,
  event_contract jsonb not null default '{}'::jsonb,
  expected_invariants jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key(scenario_set_version,scenario_code),
  unique(scenario_set_version,deterministic_ordinal),
  check(scenario_code ~ '^(CAN|ADV)-[0-9]{2}-[A-Z0-9-]+$'),
  check(
    (scenario_type='canonical_profile' and source_profile_id is not null)
    or (scenario_type='adversarial_variant' and source_profile_id is null)
  ),
  check(jsonb_typeof(initial_state)='object'),
  check(jsonb_typeof(event_contract)='object'),
  check(jsonb_typeof(expected_invariants)='object')
);
create unique index if not exists exam_prep_synthetic_scenarios_source_profile_idx
  on private.exam_prep_synthetic_scenarios(scenario_set_version,source_profile_id)
  where scenario_type='canonical_profile';
create index if not exists exam_prep_synthetic_scenarios_type_idx
  on private.exam_prep_synthetic_scenarios(scenario_set_version,scenario_type,deterministic_ordinal);

alter table private.exam_prep_synthetic_scenario_sets enable row level security;
alter table private.exam_prep_synthetic_scenarios enable row level security;
revoke all on private.exam_prep_synthetic_scenario_sets from public,anon,authenticated;
revoke all on private.exam_prep_synthetic_scenarios from public,anon,authenticated;
grant select on private.exam_prep_synthetic_scenario_sets to service_role;
grant select on private.exam_prep_synthetic_scenarios to service_role;

insert into private.exam_prep_synthetic_scenario_sets(
  scenario_set_version,status,canonical_profile_count,adversarial_variant_count,total_scenario_count,
  required_locales,manifest_hash,source_ref,activated_at
) values(
  'p2_67_canonical_v2_0','active',15,18,33,array['en','ru','uz'],repeat('0',32),
  'exam-prep/exam-prep-static-data.js + docs/exam-prep-synthetic-validation-roadmap-p2-62-p2-80.md',now()
);

-- Canonical 15 profiles preserve the profile IDs and the minimum deterministic
-- academic shape already used by the Exam Prep preview. No person data is copied.
insert into private.exam_prep_synthetic_scenarios(
  scenario_set_version,scenario_code,deterministic_ordinal,scenario_type,source_profile_id,
  capability_mode,component_focus,learner_facing,required_locales,tags,initial_state,event_contract,expected_invariants
)
select 'p2_67_canonical_v2_0',scenario_code,ord,'canonical_profile',profile_id,
       capability_mode,component_focus,true,array['en','ru','uz'],tags,
       initial_state,
       jsonb_build_object('source_profile_id',profile_id,'causal_seed','canonical_profile_baseline'),
       jsonb_build_object('p1_p5_independent',true,'real_beta_evidence_credit',false,'legacy_mutation_allowed',false)
from (values
  (1,'CAN-01-BEGINNER','beginner','core','BOTH',array['both_weak','foundation_placement']::text[],jsonb_build_object('p1',jsonb_build_object('stage',0,'coverage',3),'p5',jsonb_build_object('stage',0,'coverage',2))),
  (2,'CAN-02-PREREQUISITE-GAPS','prerequisite-gaps','core','BOTH',array['prerequisite_gap','foundation_placement']::text[],jsonb_build_object('p1',jsonb_build_object('stage',1,'coverage',10),'p5',jsonb_build_object('stage',1,'coverage',8))),
  (3,'CAN-03-STRONG-P1','strong-p1','core','BOTH',array['component_asymmetry_p1']::text[],jsonb_build_object('p1',jsonb_build_object('stage',4,'coverage',94),'p5',jsonb_build_object('stage',1,'coverage',15))),
  (4,'CAN-04-STRONG-P5','strong-p5','core','BOTH',array['component_asymmetry_p5']::text[],jsonb_build_object('p1',jsonb_build_object('stage',1,'coverage',14),'p5',jsonb_build_object('stage',4,'coverage',96))),
  (5,'CAN-05-HALF-SYLLABUS','half-syllabus','core','BOTH',array['partial_coverage']::text[],jsonb_build_object('p1',jsonb_build_object('stage',2,'coverage',52),'p5',jsonb_build_object('stage',2,'coverage',48))),
  (6,'CAN-06-SLOW-ACCURATE','slow-accurate','core','BOTH',array['timing_risk']::text[],jsonb_build_object('p1',jsonb_build_object('stage',2,'coverage',42),'p5',jsonb_build_object('stage',2,'coverage',39))),
  (7,'CAN-07-FAST-INACCURATE','fast-inaccurate','core','BOTH',array['accuracy_risk']::text[],jsonb_build_object('p1',jsonb_build_object('stage',2,'coverage',55),'p5',jsonb_build_object('stage',2,'coverage',50))),
  (8,'CAN-08-MCQ-STRONG-INPUT-WEAK','mcq-strong-input-weak','core','BOTH',array['format_gap']::text[],jsonb_build_object('p1',jsonb_build_object('stage',2,'coverage',60),'p5',jsonb_build_object('stage',2,'coverage',55))),
  (9,'CAN-09-TOPIC-STRONG-MIXED-WEAK','topic-strong-mixed-weak','core','BOTH',array['mixed_transfer_gap']::text[],jsonb_build_object('p1',jsonb_build_object('stage',3,'coverage',78),'p5',jsonb_build_object('stage',3,'coverage',75))),
  (10,'CAN-10-EXAM-MODE-CANDIDATE','exam-mode-candidate','core','BOTH',array['exam_mode_candidate']::text[],jsonb_build_object('p1',jsonb_build_object('stage',5,'coverage',100),'p5',jsonb_build_object('stage',5,'coverage',100))),
  (11,'CAN-11-LATE-JOINER','late-joiner','core','BOTH',array['late_joiner']::text[],jsonb_build_object('p1',jsonb_build_object('stage',0,'coverage',12),'p5',jsonb_build_object('stage',0,'coverage',8))),
  (12,'CAN-12-ILLNESS-INTERRUPTION','illness-interruption','core','BOTH',array['interrupted_recovery']::text[],jsonb_build_object('p1',jsonb_build_object('stage',2,'coverage',44),'p5',jsonb_build_object('stage',2,'coverage',40))),
  (13,'CAN-13-AI-UNAVAILABLE','ai-unavailable','core','BOTH',array['ai_unavailable']::text[],jsonb_build_object('p1',jsonb_build_object('stage',2,'coverage',38),'p5',jsonb_build_object('stage',2,'coverage',35))),
  (14,'CAN-14-OFFLINE-RETRY','offline-retry','core','BOTH',array['offline_retry_idempotency']::text[],jsonb_build_object('p1',jsonb_build_object('stage',1,'coverage',20),'p5',jsonb_build_object('stage',1,'coverage',18))),
  (15,'CAN-15-MENTOR-OVERRIDE','mentor-override','mentor_technical','BOTH',array['mentor_override','advanced_placement']::text[],jsonb_build_object('p1',jsonb_build_object('stage',1,'coverage',28),'p5',jsonb_build_object('stage',1,'coverage',22)))
) as x(ord,scenario_code,profile_id,capability_mode,component_focus,tags,initial_state);

-- Adversarial variants are contracts for later P2-68..P2-79 execution. They
-- define causal event sequences and expected invariants without fabricating any
-- learner evidence at P2-67.
insert into private.exam_prep_synthetic_scenarios(
  scenario_set_version,scenario_code,deterministic_ordinal,scenario_type,source_profile_id,
  capability_mode,component_focus,learner_facing,required_locales,tags,initial_state,event_contract,expected_invariants
)
select 'p2_67_canonical_v2_0',scenario_code,ord,'adversarial_variant',null,
       capability_mode,component_focus,true,array['en','ru','uz'],tags,initial_state,event_contract,expected_invariants
from (values
  (16,'ADV-01-FAILED-LEARNING-CORRECTION','core','P1',array['failed_learning_correction']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',1),'p5',jsonb_build_object('stage',1)),
    jsonb_build_object('events',jsonb_build_array('learning_attempt_failed','correction_opened','fresh_practice_required')),
    jsonb_build_object('mastery_must_not_increase_on_failure',true,'p5_unchanged',true)),
  (17,'ADV-02-RETEST-FAILED','core','P5',array['retest_failed']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',2),'p5',jsonb_build_object('stage',2)),
    jsonb_build_object('events',jsonb_build_array('correction_completed','delayed_retest_failed','correction_reopened')),
    jsonb_build_object('failed_retest_no_mastery_upgrade',true,'p1_unchanged',true)),
  (18,'ADV-03-RETEST-DELAYED-FRESH','core','P1',array['retest_delayed_fresh']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',2),'p5',jsonb_build_object('stage',2)),
    jsonb_build_object('events',jsonb_build_array('correction_completed','delay_window_elapsed','fresh_retest_passed')),
    jsonb_build_object('freshness_required',true,'calendar_alone_no_credit',true)),
  (19,'ADV-04-INTERRUPTED-RECOVERY-LONG','core','BOTH',array['interrupted_recovery']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',2),'p5',jsonb_build_object('stage',2)),
    jsonb_build_object('events',jsonb_build_array('interruption_over_30_days','recovery_opened','revalidation_before_progression')),
    jsonb_build_object('history_preserved',true,'no_automatic_stage_drop',true)),
  (20,'ADV-05-EXAM-PROFILE-REVISION','core','BOTH',array['exam_profile_revision']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',1),'p5',jsonb_build_object('stage',1)),
    jsonb_build_object('events',jsonb_build_array('exam_profile_created','exam_series_revised')),
    jsonb_build_object('academic_history_preserved',true,'revision_audited',true)),
  (21,'ADV-06-SESSION-REVISION','core','P1',array['session_revision']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',2),'p5',jsonb_build_object('stage',2)),
    jsonb_build_object('events',jsonb_build_array('session_authorized','session_interrupted','session_resumed_or_reauthorized')),
    jsonb_build_object('server_authority_preserved',true,'duplicate_credit_zero',true)),
  (22,'ADV-07-TARGET-REVISION','core','BOTH',array['target_revision']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',1),'p5',jsonb_build_object('stage',1)),
    jsonb_build_object('events',jsonb_build_array('target_grade_set','target_grade_revised')),
    jsonb_build_object('prior_evidence_preserved',true,'target_change_no_retroactive_mastery',true)),
  (23,'ADV-08-TIME-BUDGET-REVISION','core','BOTH',array['time_revision']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',1),'p5',jsonb_build_object('stage',1)),
    jsonb_build_object('events',jsonb_build_array('weekly_budget_set','weekly_budget_reduced','plan_rebuilt')),
    jsonb_build_object('evidence_preserved',true,'plan_respects_new_budget',true)),
  (24,'ADV-09-STALE-WEEKLY-PLAN','core','BOTH',array['stale_weekly_plan']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',2),'p5',jsonb_build_object('stage',2)),
    jsonb_build_object('events',jsonb_build_array('weekly_plan_created','state_changes','stale_plan_detected','fresh_plan_required')),
    jsonb_build_object('stale_plan_cannot_grant_credit',true,'history_preserved',true)),
  (25,'ADV-10-STALE-PLAN-ACTION','core','P1',array['stale_plan_action']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',2),'p5',jsonb_build_object('stage',2)),
    jsonb_build_object('events',jsonb_build_array('plan_action_authorized','plan_rebuilt','stale_action_replayed')),
    jsonb_build_object('stale_action_rejected',true,'duplicate_credit_zero',true)),
  (26,'ADV-11-OFFLINE-DUPLICATE-RETRY','core','BOTH',array['offline_retry_idempotency']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',1),'p5',jsonb_build_object('stage',1)),
    jsonb_build_object('events',jsonb_build_array('offline_draft_saved','same_idempotency_key_retried','server_accepts_once')),
    jsonb_build_object('offline_draft_no_mastery_credit',true,'server_credit_once',true)),
  (27,'ADV-12-INTEGRITY-FOCUS-VISIBILITY','core','BOTH',array['integrity_events']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',3),'p5',jsonb_build_object('stage',3)),
    jsonb_build_object('events',jsonb_build_array('protected_assessment_started','focus_exit','visibility_exit','integrity_state_updated')),
    jsonb_build_object('attempt_not_auto_finalized',true,'repeated_exit_can_reduce_comparability',true)),
  (28,'ADV-13-CORE-AI-SERVICE-TRANSITION','ai_shadow','BOTH',array['service_transition_core_ai']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',2),'p5',jsonb_build_object('stage',2)),
    jsonb_build_object('events',jsonb_build_array('core_baseline','ai_shadow_available','ai_unavailable','core_continues')),
    jsonb_build_object('academic_state_parity_required',true,'core_survives_ai_outage',true)),
  (29,'ADV-14-MENTOR-SERVICE-TRANSITION','mentor_technical','BOTH',array['service_transition_mentor']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',2),'p5',jsonb_build_object('stage',2)),
    jsonb_build_object('events',jsonb_build_array('mentor_unassigned','mentor_assigned','mentor_paused','mentor_removed')),
    jsonb_build_object('entitlement_not_assignment',true,'academic_history_preserved',true)),
  (30,'ADV-15-P1-P5-LEAK-ATTEMPT','core','BOTH',array['component_isolation_attack']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',3),'p5',jsonb_build_object('stage',1)),
    jsonb_build_object('events',jsonb_build_array('p1_evidence_added','attempt_p5_credit_from_p1')),
    jsonb_build_object('cross_component_credit_zero',true,'p5_unchanged',true)),
  (31,'ADV-16-CROSS-USER-ACCESS-ATTEMPT','core','BOTH',array['cross_user_access_attack']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',2),'p5',jsonb_build_object('stage',2)),
    jsonb_build_object('events',jsonb_build_array('learner_a_state_exists','learner_b_requests_a_private_state')),
    jsonb_build_object('cross_user_read_zero',true,'cross_user_write_zero',true)),
  (32,'ADV-17-PROTECTED-FEEDBACK-LEAK-ATTEMPT','core','BOTH',array['protected_feedback_attack']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',3),'p5',jsonb_build_object('stage',3)),
    jsonb_build_object('events',jsonb_build_array('protected_assessment_active','preanswer_feedback_requested','assessment_finalized')),
    jsonb_build_object('active_correctness_hidden',true,'active_explanation_hidden',true)),
  (33,'ADV-18-STALE-CONTENT-VERSION','core','BOTH',array['stale_content_version']::text[],
    jsonb_build_object('p1',jsonb_build_object('stage',2),'p5',jsonb_build_object('stage',2)),
    jsonb_build_object('events',jsonb_build_array('content_version_authorized','content_version_replaced','stale_client_replay')),
    jsonb_build_object('stale_authorization_rejected',true,'existing_evidence_preserved',true))
) as x(ord,scenario_code,capability_mode,component_focus,tags,initial_state,event_contract,expected_invariants);

-- Freeze a deterministic manifest over the scenario definitions.
update private.exam_prep_synthetic_scenario_sets ss
set manifest_hash=(
  select md5(string_agg(
    concat_ws('|',s.deterministic_ordinal::text,s.scenario_code,s.scenario_type,coalesce(s.source_profile_id,''),
      s.capability_mode,s.component_focus,s.learner_facing::text,s.required_locales::text,s.tags::text,
      s.initial_state::text,s.event_contract::text,s.expected_invariants::text),
    E'\n' order by s.deterministic_ordinal
  ))
  from private.exam_prep_synthetic_scenarios s
  where s.scenario_set_version=ss.scenario_set_version
)
where ss.scenario_set_version='p2_67_canonical_v2_0';

create or replace function private.prevent_exam_prep_synthetic_scenario_mutation_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  raise exception 'exam_prep_synthetic_scenario_definition_immutable';
end;
$$;
revoke all on function private.prevent_exam_prep_synthetic_scenario_mutation_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_synthetic_scenario_sets_immutable_v1 on private.exam_prep_synthetic_scenario_sets;
create trigger exam_prep_synthetic_scenario_sets_immutable_v1
before update or delete on private.exam_prep_synthetic_scenario_sets
for each row execute function private.prevent_exam_prep_synthetic_scenario_mutation_v1();

drop trigger if exists exam_prep_synthetic_scenarios_immutable_v1 on private.exam_prep_synthetic_scenarios;
create trigger exam_prep_synthetic_scenarios_immutable_v1
before update or delete on private.exam_prep_synthetic_scenarios
for each row execute function private.prevent_exam_prep_synthetic_scenario_mutation_v1();

create or replace function private.exam_prep_synthetic_scenario_set_report_v1(p_scenario_set_version text)
returns jsonb
language plpgsql
stable security definer
set search_path=''
as $$
declare
  v_set private.exam_prep_synthetic_scenario_sets%rowtype;
  v_total int;
  v_canonical int;
  v_adversarial int;
  v_sources int;
  v_locale_violations int;
  v_structure_violations int;
  v_recomputed_hash text;
  v_missing_tags text[];
begin
  select * into v_set
  from private.exam_prep_synthetic_scenario_sets
  where scenario_set_version=p_scenario_set_version;
  if v_set.scenario_set_version is null then raise exception 'exam_prep_synthetic_scenario_set_not_found'; end if;

  select count(*)::int,
         count(*) filter(where scenario_type='canonical_profile')::int,
         count(*) filter(where scenario_type='adversarial_variant')::int,
         count(distinct source_profile_id) filter(where scenario_type='canonical_profile')::int,
         count(*) filter(where learner_facing and not(required_locales @> array['en','ru','uz'] and required_locales <@ array['en','ru','uz']))::int,
         count(*) filter(where initial_state is null or event_contract is null or expected_invariants is null)::int
  into v_total,v_canonical,v_adversarial,v_sources,v_locale_violations,v_structure_violations
  from private.exam_prep_synthetic_scenarios
  where scenario_set_version=p_scenario_set_version;

  select md5(string_agg(
    concat_ws('|',s.deterministic_ordinal::text,s.scenario_code,s.scenario_type,coalesce(s.source_profile_id,''),
      s.capability_mode,s.component_focus,s.learner_facing::text,s.required_locales::text,s.tags::text,
      s.initial_state::text,s.event_contract::text,s.expected_invariants::text),
    E'\n' order by s.deterministic_ordinal
  )) into v_recomputed_hash
  from private.exam_prep_synthetic_scenarios s
  where s.scenario_set_version=p_scenario_set_version;

  with required(tag) as (values
    ('component_asymmetry_p1'),('component_asymmetry_p5'),('both_weak'),('advanced_placement'),('partial_coverage'),
    ('failed_learning_correction'),('retest_failed'),('retest_delayed_fresh'),('interrupted_recovery'),
    ('exam_profile_revision'),('session_revision'),('target_revision'),('time_revision'),
    ('stale_weekly_plan'),('stale_plan_action'),('offline_retry_idempotency'),('integrity_events'),
    ('service_transition_core_ai'),('service_transition_mentor')
  )
  select coalesce(array_agg(r.tag order by r.tag) filter(where not exists(
    select 1 from private.exam_prep_synthetic_scenarios s
    where s.scenario_set_version=p_scenario_set_version and r.tag=any(s.tags)
  )),array[]::text[])
  into v_missing_tags
  from required r;

  return jsonb_build_object(
    'scenario_set_version',v_set.scenario_set_version,
    'status',v_set.status,
    'manifest_hash',v_set.manifest_hash,
    'recomputed_manifest_hash',v_recomputed_hash,
    'total_scenarios',v_total,
    'canonical_profiles',v_canonical,
    'adversarial_variants',v_adversarial,
    'canonical_source_profiles',v_sources,
    'locale_violations',v_locale_violations,
    'structure_violations',v_structure_violations,
    'missing_required_tags',to_jsonb(v_missing_tags),
    'eligible',
      v_set.status='active'
      and v_total=v_set.total_scenario_count
      and v_canonical=v_set.canonical_profile_count
      and v_adversarial=v_set.adversarial_variant_count
      and v_sources=15
      and v_locale_violations=0
      and v_structure_violations=0
      and coalesce(array_length(v_missing_tags,1),0)=0
      and v_set.manifest_hash=v_recomputed_hash
  );
end;
$$;
revoke all on function private.exam_prep_synthetic_scenario_set_report_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_synthetic_scenario_set_report_v1(text) to service_role;

-- P2-68+ must use this governed registration path for canonical broad runs.
-- Older isolated unit matrices may continue using the lower-level P2-64 helper.
create or replace function private.register_exam_prep_canonical_synthetic_run_v2(
  p_run_id text,
  p_scenario_set_version text,
  p_git_sha text,
  p_schema_generation text,
  p_deterministic_seed bigint,
  p_capability_mode text,
  p_evidence_ref text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_report jsonb;
begin
  v_report:=private.exam_prep_synthetic_scenario_set_report_v1(p_scenario_set_version);
  if coalesce((v_report->>'eligible')::boolean,false) is not true then
    raise exception 'exam_prep_synthetic_scenario_set_not_eligible';
  end if;
  return private.register_exam_prep_synthetic_validation_run_v1(
    p_run_id,p_scenario_set_version,p_git_sha,p_schema_generation,p_deterministic_seed,p_capability_mode,p_evidence_ref
  );
end;
$$;
revoke all on function private.register_exam_prep_canonical_synthetic_run_v2(text,text,text,text,bigint,text,text) from public,anon,authenticated;
grant execute on function private.register_exam_prep_canonical_synthetic_run_v2(text,text,text,text,bigint,text,text) to service_role;

-- Migration acceptance: fixed counts, manifest and required coverage must already be clean.
do $$
declare v_report jsonb;
begin
  v_report:=private.exam_prep_synthetic_scenario_set_report_v1('p2_67_canonical_v2_0');
  if coalesce((v_report->>'eligible')::boolean,false) is not true then
    raise exception 'exam_prep_p2_67_scenario_matrix_not_eligible: %',v_report;
  end if;
end;
$$;

commit;
