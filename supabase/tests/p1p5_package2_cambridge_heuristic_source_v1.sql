-- P2-14: prove Cambridge topic-hour mapping and actual user skill-state
-- adjustment on disposable PostgreSQL, not real Supabase or fake study time.
\set ON_ERROR_STOP on
DO $$
declare
 v_uid uuid:='11111111-1111-4111-8111-111111111191';
 v_version bigint;
 v_p1 jsonb;v_p5 jsonb;v_item jsonb;
 v_paper text;v_payload jsonb;
 v_count int;v_expected numeric;v_base numeric;
 v_total_minutes numeric;v_est_hours numeric;v_pending int;
begin
 if current_setting('iclub.e2e_isolated',true) is distinct from 'true'
    or (select count(*) from public.users)<>2 then
    raise exception 'P2-14 REFUSED not isolated two-user fixture';
 end if;
 select program_version_id into v_version
 from private.exam_prep_exam_profiles where user_id=v_uid;
 if v_version is null then raise exception 'P2-14 profile unavailable'; end if;

 v_p1:=private.exam_prep_simple_guided_effort_internal_v1(v_uid,v_version,'P1');
 v_p5:=private.exam_prep_simple_guided_effort_internal_v1(v_uid,v_version,'P5');
 for v_paper,v_payload in select * from (values ('P1',v_p1),('P5',v_p5)) as x(paper,data) loop
    v_expected:=case when v_paper='P1' then 90 else 50 end;
    v_count:=case when v_paper='P1' then 45 else 36 end;
    if (v_payload->>'skill_count')::int<>v_count
       or (v_payload->>'source_coverage_count')::int<>v_count
       or (v_payload->>'historical_guided_content_hours')::numeric<>v_expected
       or (v_payload->>'source_hours_are_official_private_study_requirement')::boolean is not false
       or (v_payload->>'estimate_is_cambridge_endorsed_personal_hour_requirement')::boolean is not false
       or (v_payload->>'sensitivity_band_is_statistical_confidence_interval')::boolean is not false
       or jsonb_array_length(v_payload->'items')<>v_count
     then raise exception 'P2-14 invalid Cambridge 90/50h source or official-hour mislabel'; end if;

    v_base:=0;v_total_minutes:=0;
    for v_item in select value from jsonb_array_elements(v_payload->'items') loop
      if v_item->>'skill_code' not like v_paper||'-%'
         or (v_item->>'base_guided_minutes')::numeric<=0
         or v_item->>'source_topic_teaching_hours' is null
      then raise exception 'P2-14 skill source or baseline missing'; end if;
      v_base:=v_base+(v_item->>'base_guided_minutes')::numeric;
      v_total_minutes:=v_total_minutes+
        (v_item->>'estimated_remaining_minutes')::numeric;
      if (v_item->>'remaining_work_factor')::numeric not in (0,0.6,0.8,1) then
        raise exception 'P2-14 factor outside explicit iClub product policy'; end if;
    end loop;
    if abs(v_base/60-v_expected)>0.1 then
      raise exception 'P2-14 topic-guided source was rounded into wrong total: % vs %',v_base/60,v_expected;
    end if;
    v_est_hours:=(v_payload->>'estimated_remaining_hours')::numeric;
    if v_est_hours<0 or v_est_hours>v_expected or
       abs(v_total_minutes/60-v_est_hours)>0.2 then
      raise exception 'P2-14 weighted skill time inconsistent with displayed summary'; end if;
 end loop;
 if has_function_privilege('authenticated',
    'private.exam_prep_simple_guided_effort_internal_v1(uuid,bigint,text)','EXECUTE')
    or has_function_privilege('anon',
    'private.exam_prep_simple_guided_effort_internal_v1(uuid,bigint,text)','EXECUTE')
 then raise exception 'P2-14 private skill-time helper exposed'; end if;
 if exists (select 1 from private.exam_prep_historical_topic_teaching_refs_v1
    where approved_as_personal_study_norm) then
    raise exception 'P2-14 wrongly converted official teaching guide to approved individual norm'; end if;
 raise notice 'PASS P2-14: 90h P1 + 50h P5, 81 authentic source-weighted skills, consistent 0/0.6/0.8/1 heuristic and no false Cambridge private-hour claim';
end $$;
