-- P2-11: 486 action calibration source candidates: publisher QA does
-- NOT establish duration; no question text/answer keys/learner IDs exposed.
\set ON_ERROR_STOP on
DO $$
declare
 total_rows int;
 p1_rows int;
 p5_rows int;
 missing_sources int;
 incorrect_routing int;
 real_minutes int;
 auto_approved int;
 possible_candidate_rows int;
 direct_route_unmapped int;
begin
 select count(*)::int,
   count(*) filter(where component_code='P1')::int,
   count(*) filter(where component_code='P5')::int,
   count(*) filter(where official_syllabus_section is null or
       nullif(trim(book_chapter),'') is null or
       nullif(trim(official_source_url),'') is null or
       content_coverage_status is distinct from 'core_content_source_mapped')::int,
   count(*) filter(where action_code='correction' and
     academic_candidate_status<>'correction_workflow_needs_direct_academic_observation')::int,
   count(*) filter(where min_observed_active_minutes_unreleased is not null or
       max_observed_active_minutes_unreleased is not null)::int,
   count(*) filter(where time_range_review_status <> 'unreviewed'
     or calibrated_personal_duration or candidate_route_equals_actual_observation
     or question_timers_equal_independent_study_minutes)::int,
   count(*) filter(where academic_candidate_status='published_candidate_available')::int,
   count(*) filter(where academic_candidate_status='no_direct_published_candidate_route')::int
 into total_rows,p1_rows,p5_rows,missing_sources,incorrect_routing,
      real_minutes,auto_approved,possible_candidate_rows,direct_route_unmapped
 from private.exam_prep_action_calibration_candidates_v1;

 if total_rows<>486 or p1_rows<>270 or p5_rows<>216 or
    missing_sources<>0 or incorrect_routing<>0 or
    real_minutes<>0 or auto_approved<>0 then
    raise exception 'P2-11 source mismatch, correction route overclaimed or fake minute calibration';
 end if;
 if (select count(*) from private.exam_prep_action_calibration_candidates_v1
      where action_code='correction' and
      academic_candidate_status='correction_workflow_needs_direct_academic_observation')<>81
 then raise exception 'P2-11 correction must require separately observed workflow on all 81 skills'; end if;
 if has_table_privilege('anon','private.exam_prep_action_calibration_candidates_v1','SELECT')
    or has_table_privilege('authenticated','private.exam_prep_action_calibration_candidates_v1','SELECT')
 then raise exception 'P2-11 internal academic calibration source exposed to learners'; end if;

 raise notice 'PASS P2-11: 486 authentic source-bound action candidates, 81 correction workflows held for direct observation, zero approved minutes';
 raise notice 'P2-11 audit: % routes have published source candidate, % lack direct item-to-action mapping (do not infer missing learning)',possible_candidate_rows,direct_route_unmapped;
end $$;
