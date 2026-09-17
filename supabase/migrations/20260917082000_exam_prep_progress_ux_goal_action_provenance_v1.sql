-- Proposed additive correction for the NOT-YET-DEPLOYED Progress UX read API.
-- Prevent a recovery refresh for a skill from being attributed to an earlier
-- first-coverage goal for the same skill (or vice versa).
-- No user data update, planner change, legacy table write or production execution.
begin;

do $provenance$
declare
  v_oid oid;
  v_definition text;
  v_history_old text := '(g.item_type<>''mixed_transfer'' and hi.skill_code is not distinct from g.skill_code)';
  v_history_new text := '(g.item_type<>''mixed_transfer'' and hi.skill_code is not distinct from g.skill_code and hi.action_code=g.action_code)';
  v_current_old text := '(g.item_type<>''mixed_transfer'' and i.skill_code is not distinct from g.skill_code)';
  v_current_new text := '(g.item_type<>''mixed_transfer'' and i.skill_code is not distinct from g.skill_code and i.action_code=g.action_code)';
begin
  select p.oid into strict v_oid
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='get_exam_prep_weekly_progress_safe_v1'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)='p_component_code text';
  v_definition:=pg_catalog.pg_get_functiondef(v_oid);
  if (length(v_definition)-length(replace(v_definition,v_history_old,'')))<>length(v_history_old)
     or (length(v_definition)-length(replace(v_definition,v_current_old,'')))<>length(v_current_old) then
    raise exception 'progress_ux_action_provenance_contract_changed';
  end if;
  v_definition:=replace(v_definition,v_history_old,v_history_new);
  v_definition:=replace(v_definition,v_current_old,v_current_new);
  execute v_definition;
end;
$provenance$;

commit;
