begin;

-- P2-25 makes the retention planner and authorizer use the same governed
-- atomic mixed-task predicate as objective_state_v1. A generic historical
-- mixed row must not be enough when the skill contract explicitly requires
-- mixed evidence for provisional L3.

do $do$
declare
  v_def text;
  v_old text;
  v_new text;
begin
  select pg_get_functiondef('public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)'::regprocedure) into v_def;
  v_old := $old$
      if v_contract.requires_mixed_for_l3 then
        select exists(
          select 1
          from private.exam_prep_evidence_events e
          join private.exam_prep_sessions ses on ses.id=e.session_id
          where e.user_id=v_uid and e.component_code=v_plan.component_code
            and e.skill_code=v_item.skill_code and e.evidence_type='mixed'
            and e.verification_status='app_verified' and e.is_correct is true
            and ses.user_id=v_uid and ses.status='finalized'
        ) into v_has_mixed;
        if not v_has_mixed then raise exception 'exam_prep_retention_retest_mixed_required'; end if;
      end if;
$old$;
  v_new := $new$
      if v_contract.requires_mixed_for_l3
         and not private.exam_prep_atomic_mixed_satisfied_v1(
           v_uid,v_plan.component_code,v_item.skill_code
         ) then
        raise exception 'exam_prep_retention_retest_mixed_required';
      end if;
$new$;
  if strpos(v_def,v_old)=0 then
    raise exception 'P2-25 authorizer patch anchor not found';
  end if;
  if strpos(substr(v_def,strpos(v_def,v_old)+length(v_old)),v_old)>0 then
    raise exception 'P2-25 authorizer patch anchor not unique';
  end if;
  v_def:=replace(v_def,v_old,v_new);
  execute v_def;
end
$do$;

do $do$
declare
  v_def text;
  v_old text;
  v_new text;
begin
  select pg_get_functiondef('public.generate_exam_prep_weekly_plan_safe_v3(text)'::regprocedure) into v_def;
  v_old := $old$
      and (not c.requires_mixed_for_l3 or exists(
        select 1 from private.exam_prep_evidence_events me
        join private.exam_prep_sessions ms on ms.id=me.session_id
        where me.user_id=v_uid and me.component_code=p_component_code and me.skill_code=s.skill_code
          and me.evidence_type='mixed' and me.verification_status='app_verified' and me.is_correct is true
          and ms.user_id=v_uid and ms.status='finalized'
      ))
$old$;
  v_new := $new$
      and (not c.requires_mixed_for_l3 or private.exam_prep_atomic_mixed_satisfied_v1(
        v_uid,p_component_code,s.skill_code
      ))
$new$;
  if strpos(v_def,v_old)=0 then
    raise exception 'P2-25 planner patch anchor not found';
  end if;
  if strpos(substr(v_def,strpos(v_def,v_old)+length(v_old)),v_old)>0 then
    raise exception 'P2-25 planner patch anchor not unique';
  end if;
  v_def:=replace(v_def,v_old,v_new);
  execute v_def;
end
$do$;

revoke execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) from public,anon;
grant execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) to authenticated,service_role;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) to authenticated,service_role;

do $do$
declare v_a text; v_p text; begin
  select pg_get_functiondef('public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)'::regprocedure) into v_a;
  select pg_get_functiondef('public.generate_exam_prep_weekly_plan_safe_v3(text)'::regprocedure) into v_p;
  if strpos(v_a,'private.exam_prep_atomic_mixed_satisfied_v1')=0 then
    raise exception 'P2-25 authorizer did not adopt atomic mixed predicate';
  end if;
  if strpos(v_p,'private.exam_prep_atomic_mixed_satisfied_v1')=0 then
    raise exception 'P2-25 planner did not adopt atomic mixed predicate';
  end if;
end
$do$;

commit;