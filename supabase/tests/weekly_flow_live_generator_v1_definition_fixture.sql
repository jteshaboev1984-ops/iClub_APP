-- Disposable PostgreSQL CI fixture ONLY. NEVER apply to live Supabase.
-- Definition obtained by SELECT pg_get_functiondef() from current production
-- on 2026-09-21, verified MD5 58247a59c0967848d21c5ab93cc9d647.
-- Migration replay yields MD5 0a2ab5a50e7f086b035960ccaccbc8eb.
-- The original dated migration MUST remain immutable. This fixture reconciles
-- only the verified legacy function in synthetic CI, before the original
-- immutable eight-function production baseline gate and backup execute.
BEGIN;
DO $guard$
BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true'
 OR current_database()<>'postgres'
 OR md5(pg_get_functiondef(to_regprocedure('public.generate_exam_prep_weekly_plan_safe_v1(text,text)')))
   IS DISTINCT FROM '0a2ab5a50e7f086b035960ccaccbc8eb' THEN
  RAISE EXCEPTION 'live_generator_fixture_requires_known_disposable_replay';
 END IF;
END;$guard$;
CREATE OR REPLACE FUNCTION public.generate_exam_prep_weekly_plan_safe_v1(p_component_code text, p_recovery_mode text DEFAULT 'normal'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid; v_program bigint; v_week smallint; v_plan uuid; v_version int; v_order smallint:=0; v_case record; v_skill text; v_note text;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  if p_recovery_mode not in ('normal','reserve_1w','recovery_2_3w','rebaseline_over_1mo') then raise exception 'exam_prep_bad_recovery_mode'; end if;
  select program_version_id,active_week_no into v_program,v_week from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_program is null or v_week<1 then raise exception 'exam_prep_profile_required'; end if;
  perform private.rebuild_exam_prep_state_v1(v_uid,p_component_code);
  perform private.rebuild_exam_prep_placement_v1(v_uid,p_component_code);

  update private.exam_prep_weekly_plans set status='superseded' where user_id=v_uid and component_code=p_component_code and status='active';
  select coalesce(max(plan_version),0)+1 into v_version from private.exam_prep_weekly_plans where user_id=v_uid and component_code=p_component_code and active_week_no=v_week;
  v_note:=case p_recovery_mode
    when 'normal' then 'Evidence-gated Core plan; at most three priorities; no calendar promotion.'
    when 'reserve_1w' then 'Absence <=1 week: use reserve/recovery; preserve key retest; do not lower evidence standards or auto-downgrade stage.'
    when 'recovery_2_3w' then 'Absence 2-3 weeks: 14-day recovery; retain retest/timed evidence; reprioritize at most three blockers; low-value work reduced. Source 50/25/15/10 split is recorded but not decomposed here because category semantics are not machine-defined in the approved source.'
    else 'Absence >1 month: rebaseline component feasibility, remaining weeks and must-do syllabus; no catch-up overload and no lowered evidence standard.' end;
  insert into private.exam_prep_weekly_plans(user_id,program_version_id,component_code,active_week_no,plan_version,status,recovery_mode,policy_note)
  values(v_uid,v_program,p_component_code,v_week,v_version,'active',p_recovery_mode,v_note) returning id into v_plan;

  if p_recovery_mode='rebaseline_over_1mo' then
    insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,action_code,action_payload)
    values(v_plan,1,'rebaseline','REBASELINE_COMPONENT',jsonb_build_object('component_code',p_component_code,'reason','prolonged_absence_over_one_month'));
    v_order:=1;
  else
    for v_case in
      select c.id,c.skill_code,r.due_not_before from private.exam_prep_correction_cases c
      join private.exam_prep_retest_events r on r.correction_case_id=c.id and r.status in ('scheduled','authorized')
      where c.user_id=v_uid and c.component_code=p_component_code and c.status='retest_due'
      order by r.due_not_before nulls first,c.opened_at
    loop
      exit when v_order>=3; v_order:=v_order+1;
      insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,action_code,action_payload)
      values(v_plan,v_order,'retest',v_case.skill_code,v_case.id,v_case.due_not_before,'COMPLETE_DELAYED_RETEST',jsonb_build_object('preserve_in_recovery',true));
    end loop;

    for v_case in
      select c.id,c.skill_code from private.exam_prep_correction_cases c
      where c.user_id=v_uid and c.component_code=p_component_code and c.status in ('open','remediating','reopened')
      order by c.opened_at
    loop
      exit when v_order>=3;
      if not exists(select 1 from private.exam_prep_weekly_plan_items i where i.plan_id=v_plan and i.correction_case_id=v_case.id) then
        v_order:=v_order+1;
        insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,correction_case_id,action_code,action_payload)
        values(v_plan,v_order,'correction',v_case.skill_code,v_case.id,'COMPLETE_CORRECTION_ANALOGUES',jsonb_build_object('analogue_floor',3,'analogue_ceiling',6,'written_or_unprompted_required',true));
      end if;
    end loop;

    if v_order<3 and p_recovery_mode='normal' then
      for v_skill in
        select st.skill_code from private.exam_prep_skill_states st
        where st.user_id=v_uid and st.component_code=p_component_code and st.engine_version='objective_state_v1' and st.objective_level<=1
          and exists(select 1 from private.exam_prep_assessments a join private.exam_prep_assessment_items ai on ai.assessment_id=a.id where a.component_code=p_component_code and a.assessment_type='learning' and a.status='published' and ai.primary_skill_code=st.skill_code)
        order by st.objective_level,st.skill_code
      loop
        exit when v_order>=3; v_order:=v_order+1;
        insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,action_code,action_payload)
        values(v_plan,v_order,'learning',v_skill,'BUILD_FIRST_COVERAGE',jsonb_build_object('component_code',p_component_code));
      end loop;
    end if;
  end if;

  return jsonb_build_object('plan_id',v_plan,'component_code',p_component_code,'active_week_no',v_week,'plan_version',v_version,'recovery_mode',p_recovery_mode,'priority_count',v_order);
end;
$function$;
DO $verify$
BEGIN
 IF md5(pg_get_functiondef('public.generate_exam_prep_weekly_plan_safe_v1(text,text)'::regprocedure))
   IS DISTINCT FROM '58247a59c0967848d21c5ab93cc9d647' THEN
  RAISE EXCEPTION 'live_generator_fixture_does_not_match_pinned_production';
 END IF;
END;$verify$;
COMMIT;