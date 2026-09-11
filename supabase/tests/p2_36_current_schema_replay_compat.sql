-- P2-36 isolated CI-only historical replay compatibility.
-- Production received the Stage-4 evaluator through live migrations whose stored
-- function body was compacted before P2-34. The repository's earlier source file
-- preserves the same semantics with multiline formatting. P2-34 is intentionally
-- immutable and uses exact patch anchors, so normalize formatting only in this
-- ephemeral test database. No production data/schema is touched.

\set ON_ERROR_STOP on

do $do$
declare
  v_oid oid;
  v_def text;
  v_before text;
begin
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='exam_prep_stage4_exit_status_v1'
    and pg_get_function_identity_arguments(p.oid)='p_user_id uuid, p_program_version_id bigint, p_component_code text';
  if v_oid is null then raise exception 'P2-36 replay compat: Stage-4 evaluator missing'; end if;

  v_def:=pg_get_functiondef(v_oid);
  v_before:=v_def;

  v_def:=regexp_replace(
    v_def,
    $re$  v_below int:=0;[[:space:]]+v_unqualified int:=0;[[:space:]]+v_corrections_ready boolean:=false;[[:space:]]+v_ready boolean:=false;[[:space:]]+v_reason text:='rule_missing';$re$,
    $rep$  v_below int:=0; v_unqualified int:=0; v_corrections_ready boolean:=false; v_ready boolean:=false; v_reason text:='rule_missing';$rep$
  );

  v_def:=regexp_replace(
    v_def,
    $re$  v_raw:=private\.exam_prep_stage4_raw_evidence_v1\(p_user_id,p_program_version_id,p_component_code\);[[:space:]]+v_stage3:=v_raw->'stage3_exit_status';$re$,
    $rep$  v_raw:=private.exam_prep_stage4_raw_evidence_v1(p_user_id,p_program_version_id,p_component_code); v_stage3:=v_raw->'stage3_exit_status';$rep$
  );

  v_def:=regexp_replace(
    v_def,
    $re$  elsif not v_trend_ready then[[:space:]]+v_reason:='timing_trend_incomplete';[[:space:]]+elsif not v_corrections_ready then[[:space:]]+v_reason:='l3_or_corrective_plan_incomplete';$re$,
    E'  elsif not v_trend_ready then v_reason:=''timing_trend_incomplete'';\n  elsif not v_corrections_ready then v_reason:=''l3_or_corrective_plan_incomplete'';'
  );

  v_def:=regexp_replace(
    v_def,
    $re$'corrective_plan_gate_ready',v_corrections_ready,[[:space:]]+'stage4_exit_ready',v_ready,[[:space:]]+'stage4_unlocked',false,[[:space:]]+'stage5_unlocked',false[[:space:]]*\);$re$,
    $rep$'corrective_plan_gate_ready',v_corrections_ready,'stage4_exit_ready',v_ready,'stage4_unlocked',false,'stage5_unlocked',false);$rep$
  );

  if v_def=v_before then raise exception 'P2-36 replay compat: no formatting drift found'; end if;
  if position('  v_below int:=0; v_unqualified int:=0; v_corrections_ready boolean:=false; v_ready boolean:=false; v_reason text:=''rule_missing'';' in v_def)=0 then
    raise exception 'P2-36 replay compat: declaration normalization failed';
  end if;
  if position('  v_raw:=private.exam_prep_stage4_raw_evidence_v1(p_user_id,p_program_version_id,p_component_code); v_stage3:=v_raw->''stage3_exit_status'';' in v_def)=0 then
    raise exception 'P2-36 replay compat: raw normalization failed';
  end if;
  if position('  elsif not v_trend_ready then v_reason:=''timing_trend_incomplete'';' in v_def)=0 then
    raise exception 'P2-36 replay compat: reason normalization failed';
  end if;
  if position('''corrective_plan_gate_ready'',v_corrections_ready,''stage4_exit_ready'',v_ready,''stage4_unlocked'',false,''stage5_unlocked'',false);' in v_def)=0 then
    raise exception 'P2-36 replay compat: return normalization failed';
  end if;

  execute v_def;
end
$do$;
