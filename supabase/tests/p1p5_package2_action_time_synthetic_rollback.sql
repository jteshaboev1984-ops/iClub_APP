-- P2-10 isolated regression ONLY, disposable CI PostgreSQL.
-- FAKE 7/11 minute fixtures test arithmetic; they are NOT academic norms.
-- All 486 modified rows are rolled back before the next E2E step.
\set ON_ERROR_STOP on
begin;
DO $$
declare
 v_user uuid := '11111111-1111-4111-8111-111111111191';
 v_version bigint := 1;
 v_p1_before jsonb;v_p1_after jsonb;v_p1_partial jsonb;
 v_p5_after jsonb;v_p5_remain jsonb;
 v_skill text;v_action text;
 v_n1 int;v_n5 int;
begin
 if (select count(*) from public.users)<>2 or
    not exists (select 1 from public.users where id=v_user) then
     raise exception 'P2-10 REFUSED not the disposable CI actor set';
 end if;
 v_p1_before:=private.exam_prep_action_time_calibration_internal_v1(v_user,v_version,'P1');
 if (v_p1_before->>'private_targeted_only_min_minutes') is not null or
    (v_p1_before->>'academically_approved_action_count')::int<>0 then
    raise exception 'P2-10 unexpected preapproved study minutes';
 end if;

 -- Absent independent review MUST prevent approval at DB constraint level.
 begin
   update private.exam_prep_skill_action_time_norms_v1 set review_status='approved'
   where program_version_id=v_version and component_code='P1'
     and skill_code='P1-QUA-01' and action_code='targeted_check';
   raise exception 'P2-10 invalid academic approval accepted';
 exception when check_violation then null;
 end;

 -- CI only: approved fake 7/11 data used to verify no repeated-error
 -- multiplication or P1/P5 capacity mixing. Not a learner estimate.
 update private.exam_prep_skill_action_time_norms_v1
 set review_status='approved',min_active_minutes=7,max_active_minutes=11,
     method_version='ci_synthetic_arithmetic_fixture',
     methodology_notes='Disposable PostgreSQL arithmetic verification ONLY; not observed learning or Cambridge guidance',
     evidence_references=array['CI_SYNTHETIC_NO_REAL_LEARNER_EVIDENCE'],
     primary_reviewer_ref='CI_SIMULATED_A',independent_approver_ref='CI_SIMULATED_B',
     reviewed_at=now()-interval '1 hour',approved_at=now()
 where program_version_id=v_version;
 -- An otherwise complete approved row with NO evidence references must
 -- fail even though PostgreSQL CHECK ordinarily accepts UNKNOWN/NULL.
 begin
   update private.exam_prep_skill_action_time_norms_v1
   set evidence_references=array[]::text[]
   where program_version_id=v_version and component_code='P1'
     and skill_code='P1-QUA-01' and action_code='targeted_check';
   raise exception 'P2-10 evidence-free approved duration passed';
 exception when check_violation then null;
 end;
 begin
   update private.exam_prep_skill_action_time_norms_v1
   set independent_approver_ref=primary_reviewer_ref
   where program_version_id=v_version and component_code='P1'
     and skill_code='P1-QUA-01' and action_code='targeted_check';
   raise exception 'P2-10 same-reviewer approved duration passed';
 exception when check_violation then null;
 end;
 v_p1_after:=private.exam_prep_action_time_calibration_internal_v1(v_user,v_version,'P1');
 v_p5_after:=private.exam_prep_action_time_calibration_internal_v1(v_user,v_version,'P5');
 v_n1:=(v_p1_after->>'unique_pending_action_count')::int;
 v_n5:=(v_p5_after->>'unique_pending_action_count')::int;
 if v_n1<1 or v_n5<1 or
    (v_p1_after->>'academically_approved_action_count')::int<>v_n1 or
    (v_p5_after->>'academically_approved_action_count')::int<>v_n5 or
    (v_p1_after->>'private_targeted_only_min_minutes')::int<>7*v_n1 or
    (v_p1_after->>'private_targeted_only_max_minutes')::int<>11*v_n1 or
    (v_p5_after->>'private_targeted_only_min_minutes')::int<>7*v_n5 or
    (v_p5_after->>'private_targeted_only_max_minutes')::int<>11*v_n5 then
    raise exception 'P2-10 fake bounds not counted exactly once per pending action';
 end if;

 -- Remove just one pending P1 action's approval -> full P1 targeted interval
 -- must go NULL, with separate P5 result unchanged.
 select skill.item->>'skill_code', action.action_code into v_skill,v_action
 from jsonb_array_elements(
   private.exam_prep_remaining_work_internal_v1(v_user,v_version,'P1')->'items'
 ) as skill(item)
 cross join lateral jsonb_array_elements_text(skill.item->'pending_actions')
   as action(action_code)
 limit 1;
 if v_skill is null or v_action is null then
   raise exception 'No authentic pending P1 action found in disposable actor';
 end if;
 update private.exam_prep_skill_action_time_norms_v1
 set review_status='under_review',min_active_minutes=null,max_active_minutes=null,
     primary_reviewer_ref=null,independent_approver_ref=null,approved_at=null
 where program_version_id=v_version and skill_code=v_skill and action_code=v_action;
 v_p1_partial:=private.exam_prep_action_time_calibration_internal_v1(v_user,v_version,'P1');
 v_p5_remain:=private.exam_prep_action_time_calibration_internal_v1(v_user,v_version,'P5');
 if (v_p1_partial->>'unapproved_action_count')::int<>1 or
    (v_p1_partial->>'private_targeted_only_min_minutes') is not null or
    (v_p1_partial->>'private_targeted_only_max_minutes') is not null or
    (v_p5_remain->>'private_targeted_only_min_minutes')::int<>7*v_n5 then
    raise exception 'P2-10 incomplete review did not fail closed or P1/P5 mixed';
 end if;
 raise notice 'PASS P2-10: independent-review negative case, fake-only sums, missing interval NULL, distinct P1/P5';
end $$;
rollback;
DO $$
begin
 if exists (select 1 from private.exam_prep_skill_action_time_norms_v1
       where review_status='approved' or min_active_minutes is not null
           or max_active_minutes is not null) then
   raise exception 'P2-10 ERROR: fake values survived rollback';
 end if;
 raise notice 'PASS P2-10: rollback restored zero artificial approvals and times';
end $$;
