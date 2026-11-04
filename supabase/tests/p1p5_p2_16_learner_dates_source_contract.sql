-- P2-16 isolated PG17 after signed HTTP owner-date saves.
-- Verify NO school approval, NO access to cross-user rows, NO changes
-- to the existing exam operations table, syllabus or student budget.
\set ON_ERROR_STOP on
do $body$
declare
 v_uid uuid:='11111111-1111-4111-8111-111111111191';
 v_ver bigint;
 v_rows int;
 v_public text;
 v_rls boolean;
begin
 if current_setting('iclub.e2e_isolated',true) is distinct from 'true'
   or (select count(*) from public.users)<>2 then
  raise exception 'P2-16 REFUSED: not a two-user disposable fixture';
 end if;
 if to_regclass('private.exam_prep_learner_exam_dates_v1') is null then
  raise exception 'P2-16 missing private learner date store';
 end if;
 select relrowsecurity into v_rls
 from pg_class where oid='private.exam_prep_learner_exam_dates_v1'::regclass;
 if v_rls is not true then raise exception 'P2-16 RLS disabled'; end if;
 if has_table_privilege('authenticated',
     'private.exam_prep_learner_exam_dates_v1','SELECT')
  or has_table_privilege('authenticated',
     'private.exam_prep_learner_exam_dates_v1','UPDATE')
  or has_table_privilege('anon',
     'private.exam_prep_learner_exam_dates_v1','SELECT') then
  raise exception 'P2-16 private date store exposed to browser SQL';
 end if;
 if has_function_privilege('anon',
    'public.save_my_exam_prep_timeline_dates_safe_v1(date,date)','EXECUTE')
    or not has_function_privilege('authenticated',
    'public.save_my_exam_prep_timeline_dates_safe_v1(date,date)','EXECUTE')
 then raise exception 'P2-16 save RPC grants incorrect'; end if;
 select program_version_id into v_ver from private.exam_prep_exam_profiles
 where user_id=v_uid;
 select count(*) into v_rows from private.exam_prep_learner_exam_dates_v1
 where user_id=v_uid and program_version_id=v_ver;
 if v_rows<>2 then
  raise exception 'P2-16 expected exactly two saved (nullable) personal paper days, got %',v_rows;
 end if;
 if exists(select 1 from private.exam_prep_learner_exam_dates_v1
    where user_id<>v_uid) then
  raise exception 'P2-16 changed other learners date data';
 end if;
 if (select exam_date from private.exam_prep_learner_exam_dates_v1
     where user_id=v_uid and component_code='P1') is not null
   or (select exam_date from private.exam_prep_learner_exam_dates_v1
     where user_id=v_uid and component_code='P5') <>date '2028-03-10'
 then
  raise exception 'P2-16 learner date clear or saved day incorrect';
 end if;
 select pg_get_functiondef('public.save_my_exam_prep_timeline_dates_safe_v1(date,date)'::regprocedure)
   into v_public;
 if position('learner_school_confirmation' in v_public)>0
   or position('insert into private.exam_prep_exam_appointments' in lower(v_public))>0
   or position('private.exam_prep_require_core_access_v1' in v_public)=0
 then raise exception 'P2-16 school approval or legacy appointment mutation found'; end if;
 if (select count(*) from private.exam_prep_syllabus_nodes
   where program_version_id=v_ver and component_code='P1')<>45
   or (select count(*) from private.exam_prep_syllabus_nodes
   where program_version_id=v_ver and component_code='P5')<>36
 then raise exception 'P2-16 changed canonical P1/P5 curriculum'; end if;
 raise notice 'PASS P2-16: learner-selected dates source-scoped, no school approval, two paper days, private RLS and old academic state intact';
end
$body$;
