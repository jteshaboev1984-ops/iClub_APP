-- P2-09 / Annual Roadmap C20: exam-series and study-capacity changes must rebuild the Exam Map
-- without deleting learner knowledge/progress. A genuine exam-series change starts a new paper
-- comparability epoch: older full papers stay in history but no longer count in the current Stage 4/5 trend.
-- Hours/target changes are versioned planning changes only; they do not erase evidence or reset stages.
begin;

alter table private.exam_prep_exam_profiles
  add column if not exists profile_revision integer not null default 1;
alter table private.exam_prep_exam_profiles
  add column if not exists paper_comparability_epoch integer not null default 1;
alter table private.exam_prep_exam_profiles
  add column if not exists last_exam_series_change_at timestamptz null;

do $$ begin
  alter table private.exam_prep_exam_profiles
    add constraint exam_prep_exam_profiles_profile_revision_check check(profile_revision>=1);
exception when duplicate_object then null; end $$;
do $$ begin
  alter table private.exam_prep_exam_profiles
    add constraint exam_prep_exam_profiles_comparability_epoch_check check(paper_comparability_epoch>=1);
exception when duplicate_object then null; end $$;

create table if not exists private.exam_prep_exam_map_revisions (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  profile_revision integer not null check(profile_revision>=1),
  paper_comparability_epoch integer not null check(paper_comparability_epoch>=1),
  exam_series text null,
  target_grade text null,
  total_student_hours_available numeric not null check(total_student_hours_available>0 and total_student_hours_available<=168),
  mathematics_hours_budget numeric not null check(mathematics_hours_budget>0 and mathematics_hours_budget<=total_student_hours_available),
  change_kind text not null check(change_kind in ('initial','series_change','target_change','hours_change','combined_change')),
  series_changed boolean not null default false,
  target_changed boolean not null default false,
  hours_changed boolean not null default false,
  progress_retained boolean not null default true check(progress_retained is true),
  prior_papers_remain_history boolean not null default true check(prior_papers_remain_history is true),
  created_at timestamptz not null default now(),
  unique(user_id,profile_revision)
);

alter table private.exam_prep_exam_map_revisions enable row level security;
revoke all on private.exam_prep_exam_map_revisions from public,anon,authenticated;
grant all on private.exam_prep_exam_map_revisions to service_role;
grant usage,select on sequence private.exam_prep_exam_map_revisions_id_seq to service_role;

drop trigger if exists exam_prep_exam_map_revisions_audit_v1 on private.exam_prep_exam_map_revisions;
create trigger exam_prep_exam_map_revisions_audit_v1
after insert or update or delete on private.exam_prep_exam_map_revisions
for each row execute function private.exam_prep_audit_row_change_v1();

insert into private.exam_prep_exam_map_revisions(
  user_id,program_version_id,profile_revision,paper_comparability_epoch,exam_series,target_grade,
  total_student_hours_available,mathematics_hours_budget,change_kind,series_changed,target_changed,hours_changed
)
select p.user_id,p.program_version_id,p.profile_revision,p.paper_comparability_epoch,p.exam_series,p.target_grade,
       p.total_student_hours_available,p.mathematics_hours_budget,'initial',false,false,false
from private.exam_prep_exam_profiles p
on conflict(user_id,profile_revision) do nothing;

-- Existing exam appointments are retained, but from now on they carry the exam-series/profile snapshot
-- that made the logistics confirmation meaningful.
alter table private.exam_prep_exam_appointments
  add column if not exists exam_series_snapshot text null;
alter table private.exam_prep_exam_appointments
  add column if not exists profile_revision_snapshot integer null;

update private.exam_prep_exam_appointments a
set exam_series_snapshot=p.exam_series,
    profile_revision_snapshot=p.profile_revision
from private.exam_prep_exam_profiles p
where p.user_id=a.user_id and p.program_version_id=a.program_version_id
  and a.exam_series_snapshot is null;

create or replace function public.save_exam_prep_exam_profile_v2(
  p_exam_series text,
  p_target_grade text,
  p_total_student_hours_available numeric,
  p_mathematics_hours_budget numeric
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_old private.exam_prep_exam_profiles%rowtype;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_series text:=nullif(trim(p_exam_series),'');
  v_target text:=nullif(upper(trim(p_target_grade)),'');
  v_changed boolean:=false;
  v_series_changed boolean:=false;
  v_target_changed boolean:=false;
  v_hours_changed boolean:=false;
  v_revision int:=1;
  v_epoch int:=1;
  v_kind text:='initial';
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_exam_series is not null and char_length(trim(p_exam_series))>80 then raise exception 'exam_prep_bad_exam_series'; end if;
  if p_target_grade is not null and char_length(trim(p_target_grade))>40 then raise exception 'exam_prep_bad_target_grade'; end if;
  if p_total_student_hours_available is null or p_total_student_hours_available<=0 or p_total_student_hours_available>168 then raise exception 'exam_prep_bad_total_hours'; end if;
  if p_mathematics_hours_budget is null or p_mathematics_hours_budget<=0 or p_mathematics_hours_budget>p_total_student_hours_available then raise exception 'exam_prep_bad_math_budget'; end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_program is null then raise exception 'exam_prep_profile_program_missing'; end if;

  select * into v_old from private.exam_prep_exam_profiles where user_id=v_uid for update;

  if v_old.user_id is null then
    insert into private.exam_prep_exam_profiles(
      user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,
      active_week_no,profile_revision,paper_comparability_epoch,created_by,updated_by
    ) values(
      v_uid,v_program,v_series,v_target,p_total_student_hours_available,p_mathematics_hours_budget,
      1,1,1,v_uid,v_uid
    ) returning * into v_profile;

    insert into private.exam_prep_exam_map_revisions(
      user_id,program_version_id,profile_revision,paper_comparability_epoch,exam_series,target_grade,
      total_student_hours_available,mathematics_hours_budget,change_kind,series_changed,target_changed,hours_changed
    ) values(
      v_uid,v_program,1,1,v_series,v_target,p_total_student_hours_available,p_mathematics_hours_budget,
      'initial',false,false,false
    );
  else
    v_series_changed:=nullif(trim(v_old.exam_series),'') is not null
      and lower(trim(v_old.exam_series)) is distinct from lower(coalesce(v_series,''));
    v_target_changed:=upper(coalesce(trim(v_old.target_grade),'')) is distinct from upper(coalesce(v_target,''));
    v_hours_changed:=v_old.total_student_hours_available is distinct from p_total_student_hours_available
      or v_old.mathematics_hours_budget is distinct from p_mathematics_hours_budget;
    v_changed:=lower(coalesce(trim(v_old.exam_series),'')) is distinct from lower(coalesce(v_series,''))
      or v_target_changed or v_hours_changed;

    v_revision:=v_old.profile_revision + case when v_changed then 1 else 0 end;
    v_epoch:=v_old.paper_comparability_epoch + case when v_series_changed then 1 else 0 end;
    v_kind:=case
      when v_series_changed and (v_target_changed or v_hours_changed) then 'combined_change'
      when v_series_changed then 'series_change'
      when v_target_changed and v_hours_changed then 'combined_change'
      when v_target_changed then 'target_change'
      when v_hours_changed then 'hours_change'
      else 'initial'
    end;

    update private.exam_prep_exam_profiles
    set program_version_id=v_program,
        exam_series=v_series,
        target_grade=v_target,
        total_student_hours_available=p_total_student_hours_available,
        mathematics_hours_budget=p_mathematics_hours_budget,
        profile_revision=v_revision,
        paper_comparability_epoch=v_epoch,
        last_exam_series_change_at=case when v_series_changed then now() else last_exam_series_change_at end,
        active_week_no=greatest(active_week_no,1),
        updated_at=now(),updated_by=v_uid
    where user_id=v_uid
    returning * into v_profile;

    if v_changed then
      insert into private.exam_prep_exam_map_revisions(
        user_id,program_version_id,profile_revision,paper_comparability_epoch,exam_series,target_grade,
        total_student_hours_available,mathematics_hours_budget,change_kind,series_changed,target_changed,hours_changed
      ) values(
        v_uid,v_program,v_revision,v_epoch,v_series,v_target,p_total_student_hours_available,p_mathematics_hours_budget,
        v_kind,v_series_changed,v_target_changed,v_hours_changed
      );
    end if;
  end if;

  perform private.rebuild_exam_prep_placement_v1(v_uid,null);

  return jsonb_build_object(
    'program_version_id',v_profile.program_version_id,
    'exam_series',v_profile.exam_series,
    'target_grade',v_profile.target_grade,
    'total_student_hours_available',v_profile.total_student_hours_available,
    'mathematics_hours_budget',v_profile.mathematics_hours_budget,
    'active_week_no',v_profile.active_week_no,
    'profile_revision',v_profile.profile_revision,
    'paper_comparability_epoch',v_profile.paper_comparability_epoch,
    'series_changed',v_series_changed,
    'target_changed',v_target_changed,
    'hours_changed',v_hours_changed,
    'progress_retained',true,
    'prior_papers_remain_history',true,
    'prior_papers_count_toward_current_trend',case when v_series_changed then false else true end,
    'plan_rebuild_required',(v_series_changed or v_target_changed or v_hours_changed),
    'timetable_reconfirmation_required',v_series_changed,
    'note','Exam-plan changes never delete academic evidence. A genuine exam-series change starts a new full-paper comparability epoch; older papers remain visible history but do not count in the current readiness trend.'
  );
end;
$$;
revoke execute on function public.save_exam_prep_exam_profile_v2(text,text,numeric,numeric) from public,anon;
grant execute on function public.save_exam_prep_exam_profile_v2(text,text,numeric,numeric) to authenticated,service_role;

-- Every new timed/paper session snapshots the current Exam Map revision/series.
create or replace function private.exam_prep_attach_timing_contract_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_timed_assessment_contracts%rowtype;
  v_p private.exam_prep_component_paper_profiles%rowtype;
  v_ep private.exam_prep_exam_profiles%rowtype;
  v_limit integer;
  v_deadline timestamptz;
begin
  if new.session_type not in ('timed','paper') then return new; end if;
  select * into v_c from private.exam_prep_timed_assessment_contracts where assessment_id=new.assessment_id and status='published';
  if v_c.assessment_id is null then raise exception 'exam_prep_timed_contract_not_published'; end if;
  select * into v_p from private.exam_prep_component_paper_profiles where id=v_c.paper_profile_id and status='published';
  if v_p.id is null or v_p.component_code<>new.component_code then raise exception 'exam_prep_timed_session_profile_scope_mismatch'; end if;
  select * into v_ep from private.exam_prep_exam_profiles where user_id=new.user_id and program_version_id=new.program_version_id;
  if v_ep.user_id is null then raise exception 'exam_prep_profile_required'; end if;
  v_limit:=private.exam_prep_timed_time_limit_v1(v_c.paper_profile_id,v_c.timing_rule,v_c.marks_available,v_c.fixed_time_limit_sec);
  v_deadline:=coalesce(new.started_at,now()) + make_interval(secs=>v_limit);
  new.timing_contract:=jsonb_build_object(
    'contract_version',v_c.contract_version,'attempt_kind',v_c.attempt_kind,'timing_rule',v_c.timing_rule,
    'comparison_scope',v_c.comparison_scope,'comparability_key',v_c.comparability_key,'strict_timing',v_c.strict_timing,
    'marks_available',v_c.marks_available,'time_limit_sec',v_limit,'deadline_at',v_deadline,
    'official_total_marks',v_p.official_total_marks,'official_duration_sec',v_p.official_duration_sec,
    'paper_profile_version',v_p.profile_version,'component_code',new.component_code,
    'exam_profile_revision',v_ep.profile_revision,
    'paper_comparability_epoch',v_ep.paper_comparability_epoch,
    'exam_series_snapshot',v_ep.exam_series,
    'target_grade_snapshot',v_ep.target_grade
  );
  return new;
end;
$$;
revoke all on function private.exam_prep_attach_timing_contract_v1() from public,anon,authenticated;

-- This helper already gates Stage 4/5 raw readers. Extending it makes previous-series papers
-- dynamically historical/non-comparable without mutating or deleting their attempt rows.
create or replace function private.exam_prep_timed_score_comparable_v1(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select coalesce((
    select t.timing_comparable
       and t.attempt_kind<>'diagnostic_full'
       and coalesce(nullif(s.timing_contract->>'paper_comparability_epoch','')::int,1)=coalesce(p.paper_comparability_epoch,1)
       and (
         nullif(trim(p.exam_series),'') is null
         or lower(trim(coalesce(nullif(s.timing_contract->>'exam_series_snapshot',''),p.exam_series)))=lower(trim(p.exam_series))
       )
       and greatest(
             0,
             t.pending_review_in_time_marks - coalesce((
               select sum(sm.max_marks)
               from private.exam_prep_timed_written_self_marks sm
               where sm.session_id=t.session_id and sm.was_in_time
             ),0)
           )=0
       and greatest(
             0,
             t.pending_review_after_time_marks - coalesce((
               select sum(sm.max_marks)
               from private.exam_prep_timed_written_self_marks sm
               where sm.session_id=t.session_id and not sm.was_in_time
             ),0)
           )=0
    from private.exam_prep_timed_attempt_results t
    join private.exam_prep_sessions s on s.id=t.session_id
    join private.exam_prep_exam_profiles p on p.user_id=t.user_id and p.program_version_id=s.program_version_id
    where t.session_id=p_session_id
  ),false);
$$;
revoke all on function private.exam_prep_timed_score_comparable_v1(uuid) from public,anon,authenticated;
grant execute on function private.exam_prep_timed_score_comparable_v1(uuid) to service_role;

-- Appointment confirmations are series-scoped from now on.
create or replace function public.save_my_exam_prep_exam_appointment_v1(
  p_component_code text,
  p_scheduled_start_at timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_profile private.exam_prep_exam_profiles%rowtype;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  if p_scheduled_start_at is null then raise exception 'exam_prep_exam_start_required'; end if;
  select * into v_profile from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_profile.user_id is null or nullif(trim(v_profile.exam_series),'') is null then raise exception 'exam_prep_exam_series_required'; end if;

  insert into private.exam_prep_exam_appointments(
    user_id,program_version_id,component_code,scheduled_start_at,confirmation_source,confirmed_at,updated_at,
    exam_series_snapshot,profile_revision_snapshot
  ) values(
    v_uid,v_profile.program_version_id,p_component_code,p_scheduled_start_at,'learner_school_confirmation',now(),now(),
    v_profile.exam_series,v_profile.profile_revision
  )
  on conflict(user_id,program_version_id,component_code) do update set
    scheduled_start_at=excluded.scheduled_start_at,confirmation_source=excluded.confirmation_source,
    confirmed_at=now(),updated_at=now(),exam_series_snapshot=excluded.exam_series_snapshot,
    profile_revision_snapshot=excluded.profile_revision_snapshot;

  return private.exam_prep_exam_ops_status_v1(v_uid,v_profile.program_version_id,p_component_code);
end;
$$;
revoke execute on function public.save_my_exam_prep_exam_appointment_v1(text,timestamptz) from public,anon;
grant execute on function public.save_my_exam_prep_exam_appointment_v1(text,timestamptz) to authenticated,service_role;

create or replace function private.exam_prep_exam_ops_status_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_calendar private.exam_prep_exam_calendar%rowtype;
  v_appointment private.exam_prep_exam_appointments%rowtype;
  v_ready jsonb;
  v_stage smallint:=0;
  v_items jsonb:='[]'::jsonb;
  v_total int:=0;
  v_done int:=0;
  v_stop_at timestamptz;
  v_mode text;
  v_notices jsonb:='[]'::jsonb;
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  select * into v_profile from private.exam_prep_exam_profiles
  where user_id=p_user_id and program_version_id=p_program_version_id;
  if v_profile.user_id is null then raise exception 'exam_prep_profile_required'; end if;

  v_ready:=private.exam_prep_stage5_readiness_status_v1(p_user_id,p_program_version_id,p_component_code);
  select coalesce(operational_stage,0) into v_stage
  from private.exam_prep_stage_states
  where user_id=p_user_id and program_version_id=p_program_version_id and component_code=p_component_code
  order by derived_at desc limit 1;

  if nullif(trim(v_profile.exam_series),'') is not null then
    select * into v_calendar from private.exam_prep_exam_calendar c
    where c.program_version_id=p_program_version_id and c.component_code=p_component_code
      and c.status='final_verified' and lower(trim(c.exam_series_key))=lower(trim(v_profile.exam_series))
    order by c.verified_at desc nulls last,c.id desc limit 1;
  end if;

  select * into v_appointment from private.exam_prep_exam_appointments a
  where a.user_id=p_user_id and a.program_version_id=p_program_version_id and a.component_code=p_component_code
    and (
      a.exam_series_snapshot is null
      or lower(trim(a.exam_series_snapshot))=lower(trim(coalesce(v_profile.exam_series,'')))
    );
  if v_appointment.user_id is not null then v_stop_at:=v_appointment.scheduled_start_at-interval '24 hours'; end if;

  select count(*)::int,count(*) filter(where coalesce(c.confirmed,false))::int,
         coalesce(jsonb_agg(jsonb_build_object(
           'item_code',i.item_code,'item_order',i.item_order,'title_ru',i.title_ru,'title_uz',i.title_uz,'title_en',i.title_en,
           'item_kind',i.item_kind,'confirmed',coalesce(c.confirmed,false),'confirmed_at',c.confirmed_at
         ) order by i.item_order),'[]'::jsonb)
  into v_total,v_done,v_items
  from private.exam_prep_exam_ops_checklist_items i
  left join private.exam_prep_exam_ops_confirmations c
    on c.user_id=p_user_id and c.program_version_id=p_program_version_id and c.component_code=p_component_code and c.item_code=i.item_code
  where i.active;

  if v_appointment.user_id is null then v_mode:='start_time_confirmation_needed';
  elsif now()>=v_appointment.scheduled_start_at then v_mode:='component_time_reached';
  elsif now()>=v_stop_at then v_mode:='stop_major_work';
  else v_mode:='targeted_taper'; end if;

  if v_calendar.id is null then v_notices:=v_notices||jsonb_build_array(jsonb_build_object('code','final_timetable_not_verified','priority',1)); end if;
  if v_appointment.user_id is null then v_notices:=v_notices||jsonb_build_array(jsonb_build_object('code','school_start_time_not_confirmed','priority',1)); end if;
  if v_mode='stop_major_work' then v_notices:=v_notices||jsonb_build_array(jsonb_build_object('code','major_work_stop_active','priority',1)); end if;
  if v_mode='component_time_reached' then v_notices:=v_notices||jsonb_build_array(jsonb_build_object('code','component_time_reached','priority',1)); end if;

  return jsonb_build_object(
    'available',coalesce((v_ready->>'ready')::boolean,false),
    'component_code',p_component_code,
    'operational_stage',v_stage,
    'exam_series',v_profile.exam_series,
    'target_grade',v_profile.target_grade,
    'profile_revision',v_profile.profile_revision,
    'paper_comparability_epoch',v_profile.paper_comparability_epoch,
    'final_timetable_verified',v_calendar.id is not null,
    'paper_code',v_calendar.paper_code,'exam_date',v_calendar.exam_date,'session_code',v_calendar.session_code,
    'timetable_version',v_calendar.timetable_version,'timetable_source_url',v_calendar.source_url,
    'school_start_time_confirmed',v_appointment.user_id is not null,
    'scheduled_start_at',v_appointment.scheduled_start_at,
    'major_work_stop_at',v_stop_at,'major_work_stop_rule_hours',24,'calibration_mode',v_mode,
    'checklist_total',v_total,'checklist_confirmed',v_done,'checklist_complete',(v_total>0 and v_total=v_done),
    'checklist_items',v_items,'notifications',v_notices,
    'new_mastery_allowed',false,'readiness_can_be_created_by_checklist',false,
    'note','Exam operations are planning/logistics only. A series change invalidates old start-time logistics and old full-paper comparability for the current trend, but never deletes learner history or academic evidence.'
  );
end;
$$;
revoke all on function private.exam_prep_exam_ops_status_v1(uuid,bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_exam_ops_status_v1(uuid,bigint,text) to service_role;

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
  v_total int:=0;
  v_current int:=0;
  v_stale int:=0;
  v_timetable_rows int:=0;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_profile from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_profile.user_id is null then raise exception 'exam_prep_profile_required'; end if;

  select count(*)::int,count(*) filter(where private.exam_prep_timed_score_comparable_v1(t.session_id))::int
  into v_total,v_current
  from private.exam_prep_timed_attempt_results t
  join private.exam_prep_sessions s on s.id=t.session_id
  where t.user_id=v_uid and s.user_id=v_uid and s.program_version_id=v_profile.program_version_id
    and s.session_type='paper' and s.status='finalized' and t.attempt_kind='full_paper';
  v_stale:=greatest(v_total-v_current,0);

  if nullif(trim(v_profile.exam_series),'') is not null then
    select count(*)::int into v_timetable_rows
    from private.exam_prep_exam_calendar c
    where c.program_version_id=v_profile.program_version_id and c.status='final_verified'
      and lower(trim(c.exam_series_key))=lower(trim(v_profile.exam_series));
  end if;

  return jsonb_build_object(
    'profile_revision',v_profile.profile_revision,
    'paper_comparability_epoch',v_profile.paper_comparability_epoch,
    'exam_series',v_profile.exam_series,
    'target_grade',v_profile.target_grade,
    'total_student_hours_available',v_profile.total_student_hours_available,
    'mathematics_hours_budget',v_profile.mathematics_hours_budget,
    'full_papers_in_history',v_total,
    'full_papers_counting_in_current_trend',v_current,
    'historical_full_papers_excluded_from_current_trend',v_stale,
    'final_timetable_verified_for_current_series',(v_timetable_rows>=2),
    'progress_retained',true,
    'calendar_can_reduce_progress',false,
    'series_change_requires_new_comparable_window',(v_stale>0),
    'hours_change_action','rebuild_weekly_plan_preserve_corrections_retests',
    'note','Profile changes are planning changes. Academic evidence remains immutable. Only a genuine exam-series change starts a new full-paper comparability window.'
  );
end;
$$;
revoke execute on function public.get_exam_prep_exam_map_status_safe_v1() from public,anon;
grant execute on function public.get_exam_prep_exam_map_status_safe_v1() to authenticated,service_role;

commit;
