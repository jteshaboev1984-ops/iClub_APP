-- P2-10 | iClub Mathematics 9709 P1/P5 | DRAFT / isolated PG17 only.
-- Source-bound pending skill actions are study units. Wrong answers do not
-- multiply a full learning course. No invented per-action time values.

create table private.exam_prep_skill_action_time_norms_v1 (
  program_version_id bigint not null,
  component_code text not null check (component_code in ('P1','P5')),
  skill_code text not null,
  action_code text not null check (action_code in (
    'targeted_check','correction','targeted_practice',
    'delayed_retest','mixed_transfer','written_work_unscored'
  )),
  min_active_minutes integer,
  max_active_minutes integer,
  review_status text not null default 'unreviewed'
    check (review_status in ('unreviewed','under_review','approved','retired')),
  method_version text,
  methodology_notes text,
  evidence_references text[] not null default array[]::text[],
  primary_reviewer_ref text,
  independent_approver_ref text,
  reviewed_at timestamptz,
  approved_at timestamptz,
  revision integer not null default 1 check(revision >= 1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (program_version_id,skill_code,action_code),
  foreign key (program_version_id,skill_code)
    references private.exam_prep_syllabus_nodes(program_version_id,skill_code)
    on update restrict on delete restrict,
  constraint exam_prep_skill_action_paper_code_check check (
    (component_code = 'P1' and skill_code like 'P1-%') or
    (component_code = 'P5' and skill_code like 'P5-%')
  ),
  constraint exam_prep_skill_action_valid_intervals check (
    (min_active_minutes is null or min_active_minutes between 1 and 1440) and
    (max_active_minutes is null or max_active_minutes between 1 and 2880) and
    (min_active_minutes is null or max_active_minutes is null or
       max_active_minutes >= min_active_minutes)
  ),
  constraint exam_prep_skill_action_approval_gate check (
    review_status <> 'approved' or (
      min_active_minutes is not null and max_active_minutes is not null and
      nullif(btrim(coalesce(method_version,'')),'') is not null and
      length(btrim(coalesce(methodology_notes,''))) >= 40 and
      array_length(evidence_references,1) >= 1 and
      nullif(btrim(coalesce(primary_reviewer_ref,'')),'') is not null and
      nullif(btrim(coalesce(independent_approver_ref,'')),'') is not null and
      primary_reviewer_ref <> independent_approver_ref and
      reviewed_at is not null and approved_at is not null and
      reviewed_at <= approved_at
    )
  )
);

alter table private.exam_prep_skill_action_time_norms_v1 enable row level security;
revoke all on private.exam_prep_skill_action_time_norms_v1
  from public,anon,authenticated;
comment on table private.exam_prep_skill_action_time_norms_v1 is
'PRIVATE unreviewed 81-skill x 6-action time source register. No Cambridge-issued personal minutes or learner time quotas. Independent-review gate before arithmetic.';

insert into private.exam_prep_skill_action_time_norms_v1 (
  program_version_id,component_code,skill_code,action_code
)
select s.program_version_id,s.component_code,s.skill_code,a.action_code
from private.exam_prep_syllabus_nodes s
join private.exam_prep_program_versions p on p.id=s.program_version_id
cross join (values
 ('targeted_check'::text),('correction'::text),('targeted_practice'::text),
 ('delayed_retest'::text),('mixed_transfer'::text),('written_work_unscored'::text)
) as a(action_code)
where p.program_key='math_as_p1_p5' and p.status='active'
  and s.component_code in ('P1','P5')
on conflict do nothing;

do $$
declare n int; p1 int; p5 int; numbered int; permitted int;
begin
 select count(*)::int,
        count(*) filter(where component_code='P1')::int,
        count(*) filter(where component_code='P5')::int,
        count(*) filter(where min_active_minutes is not null or
          max_active_minutes is not null)::int,
        count(*) filter(where review_status='approved')::int
 into n,p1,p5,numbered,permitted
 from private.exam_prep_skill_action_time_norms_v1;
 if n<>486 or p1<>270 or p5<>216 or numbered<>0 or permitted<>0 then
   raise exception 'P2-10 requires 81 canonical skills x 6 unapproved, zero-duration actions';
 end if;
end $$;

-- Sum ONLY private reviewed pending-action ranges; NEVER let a learner see
-- them as a complete Cambridge preparation estimate or schedule recommendation.
create or replace function private.exam_prep_action_time_calibration_internal_v1(
 p_uid uuid,p_program_version_id bigint,p_component text
)
returns jsonb
language sql
stable
security invoker
set search_path to ''
as $fn$
with skills as (
 select private.exam_prep_remaining_work_internal_v1(
   p_uid,p_program_version_id,p_component
 ) as payload
), actions as (
 select skill.item->>'skill_code' as skill_code,
        action.action_code
 from skills s
 cross join lateral jsonb_array_elements(s.payload->'items') as skill(item)
 cross join lateral jsonb_array_elements_text(skill.item->'pending_actions')
   as action(action_code)
), examined as (
 select a.skill_code,a.action_code,
        n.min_active_minutes,n.max_active_minutes,
        (n.review_status='approved' and
          n.min_active_minutes is not null and
          n.max_active_minutes is not null) as is_approved
 from actions a
 left join private.exam_prep_skill_action_time_norms_v1 n
   on n.program_version_id=p_program_version_id
   and n.component_code=p_component
   and n.skill_code=a.skill_code and n.action_code=a.action_code
)
select jsonb_build_object(
 'component_code',p_component,
 'unique_pending_action_count',count(*)::int,
 'academically_approved_action_count',count(*) filter(where is_approved)::int,
 'unapproved_action_count',count(*) filter(where not coalesce(is_approved,false))::int,
 'all_pending_action_ranges_reviewed',
    count(*) > 0 and count(*)=count(*) filter(where is_approved),
 'private_targeted_only_min_minutes',case when count(*) > 0 and
    count(*)=count(*) filter(where is_approved)
      then sum(min_active_minutes)::int else null::int end,
 'private_targeted_only_max_minutes',case when count(*) > 0 and
    count(*)=count(*) filter(where is_approved)
      then sum(max_active_minutes)::int else null::int end,
 'all_study_time_approved',false,
 'separate_paper_revision_and_shared_prerequisites_still_required',true
) from examined;
$fn$;

revoke all on function private.exam_prep_action_time_calibration_internal_v1(uuid,bigint,text)
 from public,anon,authenticated;

create or replace function public.get_exam_prep_action_time_calibration_status_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $fn$
declare
 v_uid uuid;
 v_program_version_id bigint;
 v_p1 jsonb;
 v_p5 jsonb;
begin
 v_uid:=private.exam_prep_require_core_access_v1();
 select p.program_version_id into v_program_version_id
 from private.exam_prep_exam_profiles p where p.user_id=v_uid;
 if v_program_version_id is null then raise exception 'exam_prep_profile_required'; end if;

 v_p1:=private.exam_prep_action_time_calibration_internal_v1(v_uid,v_program_version_id,'P1');
 v_p5:=private.exam_prep_action_time_calibration_internal_v1(v_uid,v_program_version_id,'P5');

 return jsonb_build_object(
   'contract_version','exam_prep_action_time_calibration_status_v1',
   'P1',jsonb_build_object(
     'unique_pending_action_count',v_p1->'unique_pending_action_count',
     'academically_approved_action_count',v_p1->'academically_approved_action_count',
     'unapproved_action_count',v_p1->'unapproved_action_count',
     'targeted_minutes_min',null,'targeted_minutes_max',null
   ),
   'P5',jsonb_build_object(
     'unique_pending_action_count',v_p5->'unique_pending_action_count',
     'academically_approved_action_count',v_p5->'academically_approved_action_count',
     'unapproved_action_count',v_p5->'unapproved_action_count',
     'targeted_minutes_min',null,'targeted_minutes_max',null
   ),
   'numeric_recommendation_available',false,
   'recommendation_accept_enabled',false,
   'recommended_weekly_hours',null,
   'paper_practice_and_revision_estimate_pending',true,
   'shared_p1_p5_calendar_capacity_nonadditive',true,
   'no_learning_time_cap',true,
   'no_grade_forecast',true
 );
end;
$fn$;

revoke all on function public.get_exam_prep_action_time_calibration_status_safe_v1()
 from public,anon;
grant execute on function public.get_exam_prep_action_time_calibration_status_safe_v1()
 to authenticated,service_role;

comment on function public.get_exam_prep_action_time_calibration_status_safe_v1() is
'Owner-only aggregated P1/P5 action coverage; ALWAYS withholds targeted hour totals and numeric recommendation pending independent full calendar/paper/academic approval.';
