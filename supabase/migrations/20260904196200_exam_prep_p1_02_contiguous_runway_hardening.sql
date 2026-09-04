-- P1-02 contiguous runway hardening.
--
-- The original report only extended ready_through_aw across releases whose
-- active_week_from <= the queried week. Once a future adjacent release was
-- already fully governed, querying AW2 still stopped at AW4 and reported only
-- three weeks ahead. Runway is a forward-looking capacity measure: it must
-- continue across adjacent READY release windows, but it must never jump over
-- a missing/not-ready week.

begin;

create or replace function public.get_exam_prep_content_runway_v1(p_active_week_no smallint default 1)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_program bigint;
  v_releases jsonb;
  v_components jsonb;
  v_global_hard boolean;
  v_global_target boolean;
begin
  if p_active_week_no is null or p_active_week_no<1 then
    raise exception 'exam_prep_bad_active_week';
  end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';
  if v_program is null then raise exception 'exam_prep_program_version_missing'; end if;

  with rs as (
    select r.id,r.release_key,r.component_code,r.active_week_from,r.active_week_through,
      count(s.skill_code) filter(where s.required_for_release) as required_skills,
      count(s.skill_code) filter(
        where s.required_for_release
          and private.exam_prep_skill_content_ready_v1(v_program,r.component_code,s.skill_code)
      ) as ready_skills
    from private.exam_prep_content_runway_releases r
    join private.exam_prep_content_runway_release_skills s on s.release_id=r.id
    where r.program_version_id=v_program and r.schedule_status='active'
    group by r.id
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'release_key',release_key,
    'component_code',component_code,
    'active_week_from',active_week_from,
    'active_week_through',active_week_through,
    'required_skills',required_skills,
    'ready_skills',ready_skills,
    'release_ready',(required_skills>0 and ready_skills=required_skills)
  ) order by active_week_from,component_code),'[]'::jsonb)
  into v_releases
  from rs;

  -- Evaluate every calendar week from the queried week forward. A week is ready
  -- when at least one active, fully-governed release covers that component/week.
  -- ready_through_aw stops immediately before the FIRST uncovered/not-ready week.
  with comps(component_code) as (values('P1'::text),('P5'::text)),
  rr as (
    select r.id,r.component_code,r.active_week_from,r.active_week_through,
      count(s.skill_code) filter(where s.required_for_release) as required_skills,
      count(s.skill_code) filter(
        where s.required_for_release
          and private.exam_prep_skill_content_ready_v1(v_program,r.component_code,s.skill_code)
      ) as ready_skills
    from private.exam_prep_content_runway_releases r
    join private.exam_prep_content_runway_release_skills s on s.release_id=r.id
    where r.program_version_id=v_program and r.schedule_status='active'
    group by r.id
  ), bounds as (
    select c.component_code,
      coalesce(max(rr.active_week_through),p_active_week_no-1)::int as max_week
    from comps c
    left join rr on rr.component_code=c.component_code
    group by c.component_code
  ), weeks as (
    select b.component_code,g.w,
      exists(
        select 1 from rr
        where rr.component_code=b.component_code
          and g.w between rr.active_week_from and rr.active_week_through
          and rr.required_skills>0
          and rr.ready_skills=rr.required_skills
      ) as week_ready
    from bounds b
    cross join lateral generate_series(
      p_active_week_no::int,
      greatest(p_active_week_no::int,b.max_week)
    ) as g(w)
  ), gaps as (
    select b.component_code,b.max_week,
      min(w.w) filter(where not w.week_ready) as first_gap
    from bounds b
    left join weeks w on w.component_code=b.component_code
    group by b.component_code,b.max_week
  ), x as (
    select component_code,
      case
        when max_week<p_active_week_no then p_active_week_no-1
        when first_gap is null then max_week
        else first_gap-1
      end::int as ready_through_aw
    from gaps
  )
  select jsonb_object_agg(component_code,jsonb_build_object(
    'ready_through_aw',ready_through_aw,
    'ahead_weeks',greatest(0,ready_through_aw-p_active_week_no+1),
    'hard_floor_2w_green',greatest(0,ready_through_aw-p_active_week_no+1)>=2,
    'target_4w_green',greatest(0,ready_through_aw-p_active_week_no+1)>=4
  ))
  into v_components
  from x;

  v_global_hard:=
    coalesce((v_components#>>'{P1,hard_floor_2w_green}')::boolean,false)
    and coalesce((v_components#>>'{P5,hard_floor_2w_green}')::boolean,false);
  v_global_target:=
    coalesce((v_components#>>'{P1,target_4w_green}')::boolean,false)
    and coalesce((v_components#>>'{P5,target_4w_green}')::boolean,false);

  return jsonb_build_object(
    'runway_version','annual_runway_v1',
    'active_week_no',p_active_week_no,
    'hard_floor_weeks',2,
    'target_weeks',4,
    'components',v_components,
    'hard_floor_green',v_global_hard,
    'target_4w_green',v_global_target,
    'releases',v_releases
  );
end;
$$;

revoke all on function public.get_exam_prep_content_runway_v1(smallint) from public,anon,authenticated;
grant execute on function public.get_exam_prep_content_runway_v1(smallint) to service_role;

-- Fail-closed deployment invariant; this reporting correction must not activate beta.
do $$
declare v_cfg private.exam_prep_feature_config%rowtype;
begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off'
     or v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not v_cfg.kill_switch then
    raise exception 'P1-02 contiguous runway hardening requires fail-closed feature state';
  end if;
end
$$;

commit;
