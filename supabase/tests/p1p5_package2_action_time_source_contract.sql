-- P2-10: source-bound 81x6 action registry. SELECT-only against PG17.
\set ON_ERROR_STOP on
DO $$
declare total_rows int; p1_rows int; p5_rows int;
        incomplete int; reviewed int; wrong_count int;
begin
 select count(*)::int,
        count(*) filter(where component_code='P1')::int,
        count(*) filter(where component_code='P5')::int,
        count(*) filter(where min_active_minutes is not null or
              max_active_minutes is not null or review_status='approved')::int
 into total_rows,p1_rows,p5_rows,reviewed
 from private.exam_prep_skill_action_time_norms_v1;
 select count(*)::int into incomplete
 from (
  select program_version_id,skill_code,count(*) n
  from private.exam_prep_skill_action_time_norms_v1
  group by 1,2 having count(*)<>6
 ) missing;
 select count(*)::int into wrong_count
 from private.exam_prep_skill_action_time_norms_v1 n
 left join private.exam_prep_syllabus_nodes s
   on s.program_version_id=n.program_version_id and s.skill_code=n.skill_code
 where s.skill_code is null or s.component_code<>n.component_code;
 if total_rows<>486 or p1_rows<>270 or p5_rows<>216
    or incomplete<>0 or wrong_count<>0 or reviewed<>0 then
   raise exception 'P2-10 81x6 action norms must be source-bound unreviewed and NULL';
 end if;
 if has_table_privilege('anon','private.exam_prep_skill_action_time_norms_v1','SELECT')
    or has_table_privilege('authenticated','private.exam_prep_skill_action_time_norms_v1','SELECT')
    or has_table_privilege('authenticated','private.exam_prep_skill_action_time_norms_v1','UPDATE')
    or has_function_privilege('authenticated',
       'private.exam_prep_action_time_calibration_internal_v1(uuid,bigint,text)','EXECUTE')
 then raise exception 'P2-10 academic source leaked to student or anon'; end if;
 raise notice 'PASS P2-10: 486 action norms, P1 270 P5 216, 0 minutes/approvals; direct student access denied';
end $$;
