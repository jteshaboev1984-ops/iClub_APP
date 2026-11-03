-- P2-17 disposable PG17 regression of the EXISTING audited profile path
-- after the signed owner acceptance, rejection, and final fixture restore.
\set ON_ERROR_STOP on
do $$
declare
 uid uuid:='11111111-1111-4111-8111-111111111191';
 p private.exam_prep_exam_profiles%rowtype;
 latest private.exam_prep_exam_map_revisions%rowtype;
 previous private.exam_prep_exam_map_revisions%rowtype;
begin
 if current_setting('iclub.e2e_isolated',true) is distinct from 'true'
   or (select count(*) from public.users)<>2 then
   raise exception 'P2-17 REFUSED: not isolated two-user PG17 fixture';
 end if;
 select * into p from private.exam_prep_exam_profiles where user_id=uid;
 if p.user_id is null then raise exception 'P2-17 profile missing'; end if;
 if p.mathematics_hours_budget<>6 or p.total_student_hours_available<>12 then
   raise exception 'P2-17 fixture was not restored, profile now %/%',
     p.mathematics_hours_budget,p.total_student_hours_available;
 end if;
 select * into latest from private.exam_prep_exam_map_revisions
  where user_id=uid order by profile_revision desc limit 1;
 select * into previous from private.exam_prep_exam_map_revisions
  where user_id=uid and profile_revision<latest.profile_revision
  order by profile_revision desc limit 1;
 if latest.user_id is null or previous.user_id is null
   or latest.profile_revision<>previous.profile_revision+1
   or latest.profile_revision<>p.profile_revision
   or latest.paper_comparability_epoch<>previous.paper_comparability_epoch
   or latest.change_kind<>'hours_change'
   or previous.change_kind<>'hours_change'
   or latest.hours_changed is not true or previous.hours_changed is not true
   or latest.series_changed is not false
   or previous.series_changed is not false
   or latest.target_changed is not false
   or previous.target_changed is not false
   or latest.mathematics_hours_budget<>6
   or previous.mathematics_hours_budget<=6
   or latest.progress_retained is not true
   or previous.progress_retained is not true
   or latest.prior_papers_remain_history is not true
   or previous.prior_papers_remain_history is not true
 then
   raise exception 'P2-17 real v2 profile audit or historical grade comparability broken';
 end if;
 if has_function_privilege('anon',
   'public.accept_my_exam_prep_timeline_weekly_target_safe_v1(numeric,integer,numeric)','EXECUTE')
   or not has_function_privilege('authenticated',
   'public.accept_my_exam_prep_timeline_weekly_target_safe_v1(numeric,integer,numeric)','EXECUTE')
 then raise exception 'P2-17 invalid opt-in RPC access'; end if;
 raise notice 'PASS P2-17: explicit budget opt-in has audited hours-change revision, old grade epoch intact, history/progress retained, no auto budget increase';
end $$;
