-- P2-09 follow-up: learner/readiness reporting must keep P1 and P5 separate.
-- This is read-only projection hardening. It does not mutate attempts, evidence, mastery, stages or legacy history.
begin;

create or replace function public.get_exam_prep_exam_map_status_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_component text;
  v_history int:=0;
  v_current int:=0;
  v_stale int:=0;
  v_timetable int:=0;
  v_total_history int:=0;
  v_total_current int:=0;
  v_total_stale int:=0;
  v_components jsonb:='[]'::jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_profile from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_profile.user_id is null then raise exception 'exam_prep_profile_required'; end if;

  foreach v_component in array array['P1','P5'] loop
    select count(*)::int,
           count(*) filter(where private.exam_prep_timed_score_comparable_v1(t.session_id))::int
      into v_history,v_current
    from private.exam_prep_timed_attempt_results t
    join private.exam_prep_sessions s on s.id=t.session_id
    where t.user_id=v_uid
      and t.component_code=v_component
      and s.user_id=v_uid
      and s.program_version_id=v_profile.program_version_id
      and s.component_code=v_component
      and s.session_type='paper'
      and s.status='finalized'
      and t.attempt_kind='full_paper';

    v_history:=coalesce(v_history,0);
    v_current:=coalesce(v_current,0);
    v_stale:=greatest(v_history-v_current,0);
    v_timetable:=0;

    if nullif(trim(v_profile.exam_series),'') is not null then
      select count(*)::int into v_timetable
      from private.exam_prep_exam_calendar c
      where c.program_version_id=v_profile.program_version_id
        and c.component_code=v_component
        and c.status='final_verified'
        and lower(trim(c.exam_series_key))=lower(trim(v_profile.exam_series));
    end if;

    v_components:=v_components||jsonb_build_array(jsonb_build_object(
      'component_code',v_component,
      'full_papers_in_history',v_history,
      'full_papers_counting_in_current_trend',v_current,
      'historical_full_papers_excluded_from_current_trend',v_stale,
      'final_timetable_verified_for_current_series',(v_timetable>0),
      'series_change_requires_new_comparable_window',(v_stale>0),
      'progress_retained',true
    ));

    v_total_history:=v_total_history+v_history;
    v_total_current:=v_total_current+v_current;
    v_total_stale:=v_total_stale+v_stale;
  end loop;

  return jsonb_build_object(
    'profile_revision',v_profile.profile_revision,
    'paper_comparability_epoch',v_profile.paper_comparability_epoch,
    'exam_series',v_profile.exam_series,
    'target_grade',v_profile.target_grade,
    'total_student_hours_available',v_profile.total_student_hours_available,
    'mathematics_hours_budget',v_profile.mathematics_hours_budget,
    'components',v_components,
    'full_papers_in_history',v_total_history,
    'full_papers_counting_in_current_trend',v_total_current,
    'historical_full_papers_excluded_from_current_trend',v_total_stale,
    'progress_retained',true,
    'calendar_can_reduce_progress',false,
    'hours_change_action','rebuild_weekly_plan_preserve_corrections_retests',
    'p1_p5_separate',true,
    'note','P1 and P5 paper history and current readiness windows are reported separately. Profile changes never delete academic evidence.'
  );
end;
$$;

revoke execute on function public.get_exam_prep_exam_map_status_safe_v1() from public,anon;
grant execute on function public.get_exam_prep_exam_map_status_safe_v1() to authenticated,service_role;

-- Release assertions: component separation is structural and private data stays private.
do $$
declare v_def text;
begin
  select pg_get_functiondef('public.get_exam_prep_exam_map_status_safe_v1()'::regprocedure) into v_def;
  if position("'components'" in v_def)=0 or position("'P1','P5'" in v_def)=0 or position("'p1_p5_separate',true" in v_def)=0 then
    raise exception 'P2-09 component status: P1/P5 separation contract missing';
  end if;
  if has_table_privilege('authenticated','private.exam_prep_exam_map_revisions','SELECT') then
    raise exception 'P2-09 component status: private revision history exposed';
  end if;
end $$;

commit;
