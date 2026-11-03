-- P2-12: genuine deterministic current vs contingent-work contrast,
-- checked exclusively on disposable P1/P5 learner A after signed HTTP Stage0.
-- No history manipulation, user mutations or subjective student labels.
\set ON_ERROR_STOP on
DO $$
declare
 v_uid uuid := '11111111-1111-4111-8111-111111111191';
 v_version bigint;
 v_p1 jsonb; v_p5 jsonb; v_now1 jsonb; v_now5 jsonb;
 v_item jsonb; v_paper text; v_data jsonb; v_observed int := 0;
 v_future int := 0; v_skill_count int; v_now_count int;
begin
 if current_setting('iclub.e2e_isolated',true) is distinct from 'true' or
    (select count(*) from public.users)<>2 then
   raise exception 'P2-12 REFUSED: not in isolated two-user PG17';
 end if;
 select program_version_id into v_version
 from private.exam_prep_exam_profiles where user_id=v_uid;
 if v_version is null then
   raise exception 'P2-12 REFUSED: existing learner stage0 profile missing';
 end if;
 v_p1:=private.exam_prep_remaining_work_trajectory_internal_v1(v_uid,v_version,'P1');
 v_p5:=private.exam_prep_remaining_work_trajectory_internal_v1(v_uid,v_version,'P5');
 v_now1:=private.exam_prep_remaining_work_internal_v1(v_uid,v_version,'P1');
 v_now5:=private.exam_prep_remaining_work_internal_v1(v_uid,v_version,'P5');
 if (v_p1->>'canonical_skills')::int<>45
    or (v_p5->>'canonical_skills')::int<>36
    or (v_p1->>'current_unique_action_slots')::int<>
       (v_now1->>'unique_pending_action_slots')::int
    or (v_p5->>'current_unique_action_slots')::int<>
       (v_now5->>'unique_pending_action_slots')::int
    or (v_p1->>'missing_academic_contracts')::int<>0
    or (v_p5->>'missing_academic_contracts')::int<>0
 then raise exception 'P2-12 canonical current evidence did not match existing P2-09 model'; end if;

 for v_paper,v_data in select * from (values ('P1',v_p1),('P5',v_p5)) as p(component_code,packet) loop
   if (v_data->>'conditional_future_actions_are_not_current_assignments')::boolean is not true
      or (v_data->>'conditional_future_actions_are_not_calculated_study_hours')::boolean is not true
      or v_data->'total_time_to_demonstrated_mastery_minutes_min'<>'null'::jsonb
      or v_data->'total_time_to_demonstrated_mastery_minutes_max'<>'null'::jsonb
      or (v_data->>'student_schedule_modified')::boolean is not false
      or jsonb_array_length(v_data->'items')<>case when v_paper='P1' then 45 else 36 end
   then raise exception 'P2-12 invented learner hours or altered study state'; end if;
   for v_item in select value from jsonb_array_elements(v_data->'items') loop
      if v_item->>'component_code'<>v_paper or
         v_item->'whole_skill_time_to_mastery_min'<>'null'::jsonb or
         v_item->'whole_skill_time_to_mastery_max'<>'null'::jsonb or
         (v_item->>'future_actions_counted_in_current_study_minutes')::boolean is not false or
         (v_item->>'repeated_wrong_answers_billed_separately')::boolean is not false or
         (v_item->>'academic_contract_present')::boolean is not true or
         (v_item->>'written_work_is_a_verified_cambridge_mark')::boolean is not false
      then raise exception 'P2-12 item leakage, premature grade or duplicate billing'; end if;
      if v_item->>'current_evidence_status'='unobserved' then
         if v_item->'current_pending_actions'<>'["targeted_check"]'::jsonb
            or v_item->'possible_next_if_not_confirmed'<>
               '["correction","targeted_practice"]'::jsonb then
            raise exception 'P2-12 unknown skill wrongly assumed already weak'; end if;
         v_observed:=v_observed+1;
      elsif v_item->>'current_evidence_status'='objective_coverage_confirmed' then
         if v_item->'deferred_evidence_gates_after_objective_coverage'<>'[]'::jsonb then
            raise exception 'P2-12 double billed objective-confirmed follow-up'; end if;
      end if;
      if jsonb_array_length(v_item->'deferred_evidence_gates_after_objective_coverage')>0
         or jsonb_array_length(v_item->'possible_next_if_not_confirmed')>0
      then v_future:=v_future+1; end if;
   end loop;
 end loop;

 if v_observed=0 or v_future=0 then
   raise exception 'P2-12 real trajectory lacked expected unknown/conditional states'; end if;
 if has_function_privilege('authenticated',
   'private.exam_prep_remaining_work_trajectory_internal_v1(uuid,bigint,text)','EXECUTE')
   or has_function_privilege('anon',
   'private.exam_prep_remaining_work_trajectory_internal_v1(uuid,bigint,text)','EXECUTE')
 then raise exception 'P2-12 private pathways callable from direct browser'; end if;
 raise notice 'PASS P2-12: 81 real evidence-led trajectories; unknown stays check, current slots exact, future options unbilled, no minutes/grade/learner mutation';
end $$;
