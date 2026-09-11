begin;

-- P2-34 closes the remaining Stage-4 exit gap from the approved annual roadmap:
-- a learner needs a majority of the version-scoped governed timed-section set,
-- in addition to comparable full papers, timing trend and corrective linkage.
-- The scope is frozen per rule version so later content publication cannot silently
-- move an already-defined denominator.

create table if not exists private.exam_prep_stage4_timed_section_scope(
  rule_version text not null references private.exam_prep_stage4_exit_rules(rule_version) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  assessment_id bigint not null references private.exam_prep_assessments(id) on delete restrict,
  required boolean not null default true,
  created_at timestamptz not null default now(),
  primary key(rule_version,component_code,assessment_id)
);
revoke all on private.exam_prep_stage4_timed_section_scope from public,anon,authenticated;
grant select on private.exam_prep_stage4_timed_section_scope to service_role;

update private.exam_prep_stage4_exit_rules
set status='retired'
where status='active';

insert into private.exam_prep_stage4_exit_rules(
  rule_version,status,min_compatible_full_attempts,
  require_unattempted_nonworsening,require_after_time_nonworsening,
  require_one_improvement_or_zero,allow_explicit_corrective_plan,source_note
)
select
  'stage4_exit_v2_2026_09_11','active',r.min_compatible_full_attempts,
  r.require_unattempted_nonworsening,r.require_after_time_nonworsening,
  r.require_one_improvement_or_zero,r.allow_explicit_corrective_plan,
  r.source_note||' P2-34 adds the Annual Roadmap / Mentor Care Stage-4 exit requirement that a majority of the version-scoped governed timed-section set is completed under strict comparable timing.'
from private.exam_prep_stage4_exit_rules r
where r.rule_version='stage4_exit_v1_2026_09_07'
on conflict(rule_version) do update set status='active';

insert into private.exam_prep_stage4_timed_section_scope(rule_version,component_code,assessment_id,required)
select 'stage4_exit_v2_2026_09_11',a.component_code,a.id,true
from private.exam_prep_assessments a
join private.exam_prep_timed_assessment_contracts c on c.assessment_id=a.id
where a.status='published' and c.status='published' and c.attempt_kind='timed_section'
  and a.component_code in ('P1','P5')
on conflict do nothing;

do $$
declare v_p1 int; v_p5 int;
begin
  select count(*) into v_p1 from private.exam_prep_stage4_timed_section_scope where rule_version='stage4_exit_v2_2026_09_11' and component_code='P1' and required;
  select count(*) into v_p5 from private.exam_prep_stage4_timed_section_scope where rule_version='stage4_exit_v2_2026_09_11' and component_code='P5' and required;
  if v_p1<1 or v_p5<1 then raise exception 'P2-34 governed timed-section scope missing P1=% P5=%',v_p1,v_p5; end if;
end $$;

create or replace function private.exam_prep_stage4_timed_section_gate_v1(
  p_user_id uuid,p_program_version_id bigint,p_component_code text,p_rule_version text
)
returns jsonb
language plpgsql
stable security definer
set search_path=''
as $$
declare
  v_scope int:=0;
  v_required int:=0;
  v_completed int:=0;
  v_ready boolean:=false;
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  select count(*)::int into v_scope
  from private.exam_prep_stage4_timed_section_scope sc
  where sc.rule_version=p_rule_version and sc.component_code=p_component_code and sc.required;
  v_required:=case when v_scope>0 then floor(v_scope::numeric/2)::int+1 else 0 end;

  select count(distinct t.assessment_id)::int into v_completed
  from private.exam_prep_timed_attempt_results t
  join private.exam_prep_sessions s on s.id=t.session_id
  join private.exam_prep_stage4_timed_section_scope sc
    on sc.rule_version=p_rule_version and sc.component_code=p_component_code
   and sc.assessment_id=t.assessment_id and sc.required
  where t.user_id=p_user_id
    and t.component_code=p_component_code
    and t.attempt_kind='timed_section'
    and t.strict_timing
    and s.user_id=p_user_id
    and s.program_version_id=p_program_version_id
    and s.component_code=p_component_code
    and s.status='finalized'
    and private.exam_prep_timed_score_comparable_v1(t.session_id);

  v_ready:=(v_scope>0 and v_completed>=v_required);
  return jsonb_build_object(
    'ready',v_ready,
    'rule_version',p_rule_version,
    'component_code',p_component_code,
    'scoped_timed_section_count',v_scope,
    'required_majority_count',v_required,
    'completed_distinct_timed_section_count',v_completed,
    'strict_comparable_only',true
  );
end;
$$;
revoke all on function private.exam_prep_stage4_timed_section_gate_v1(uuid,bigint,text,text) from public,anon,authenticated;
grant execute on function private.exam_prep_stage4_timed_section_gate_v1(uuid,bigint,text,text) to service_role;

do $$
declare
  v_oid oid;
  v_def text;
  v_old text;
  v_new text;
begin
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='exam_prep_stage4_exit_status_v1'
    and pg_get_function_identity_arguments(p.oid)='p_user_id uuid, p_program_version_id bigint, p_component_code text';
  if v_oid is null then raise exception 'P2-34 Stage-4 evaluator missing'; end if;
  v_def:=pg_get_functiondef(v_oid);

  v_old:='  v_below int:=0; v_unqualified int:=0; v_corrections_ready boolean:=false; v_ready boolean:=false; v_reason text:=''rule_missing'';';
  v_new:='  v_below int:=0; v_unqualified int:=0; v_corrections_ready boolean:=false; v_ready boolean:=false; v_reason text:=''rule_missing'';'||chr(10)||
         '  v_timed_section_gate jsonb; v_timed_section_ready boolean:=false;';
  if position(v_old in v_def)=0 then raise exception 'P2-34 declaration anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='  v_raw:=private.exam_prep_stage4_raw_evidence_v1(p_user_id,p_program_version_id,p_component_code); v_stage3:=v_raw->''stage3_exit_status'';';
  v_new:='  v_raw:=private.exam_prep_stage4_raw_evidence_v1(p_user_id,p_program_version_id,p_component_code); v_stage3:=v_raw->''stage3_exit_status'';'||chr(10)||
         '  v_timed_section_gate:=private.exam_prep_stage4_timed_section_gate_v1(p_user_id,p_program_version_id,p_component_code,v_rule.rule_version);'||chr(10)||
         '  v_timed_section_ready:=coalesce((v_timed_section_gate->>''ready'')::boolean,false);';
  if position(v_old in v_def)=0 then raise exception 'P2-34 raw evidence anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='  elsif not v_trend_ready then v_reason:=''timing_trend_incomplete'';'||chr(10)||
         '  elsif not v_corrections_ready then v_reason:=''l3_or_corrective_plan_incomplete'';';
  v_new:='  elsif not v_trend_ready then v_reason:=''timing_trend_incomplete'';'||chr(10)||
         '  elsif not v_timed_section_ready then v_reason:=''timed_section_majority_incomplete'';'||chr(10)||
         '  elsif not v_corrections_ready then v_reason:=''l3_or_corrective_plan_incomplete'';';
  if position(v_old in v_def)=0 then raise exception 'P2-34 reason anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='''corrective_plan_gate_ready'',v_corrections_ready,''stage4_exit_ready'',v_ready,''stage4_unlocked'',false,''stage5_unlocked'',false);';
  v_new:='''corrective_plan_gate_ready'',v_corrections_ready,''timed_section_gate'',v_timed_section_gate,''timed_section_gate_ready'',v_timed_section_ready,''stage4_exit_ready'',v_ready,''stage4_unlocked'',false,''stage5_unlocked'',false);';
  if position(v_old in v_def)=0 then raise exception 'P2-34 return anchor missing'; end if;
  execute replace(v_def,v_old,v_new);
end $$;

revoke all on function private.exam_prep_stage4_exit_status_v1(uuid,bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_stage4_exit_status_v1(uuid,bigint,text) to service_role;

commit;
