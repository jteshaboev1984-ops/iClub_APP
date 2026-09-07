-- P1-01 monitoring semantics v2.
-- Read-only operational snapshot only. It does not authorize a release decision,
-- change learner evidence, alter placement, or mutate legacy Practice/Tour history.
--
-- Fixes an observability ambiguity in v1: placement rows are materialized before
-- a learner starts, with conservative ambiguity flags set TRUE by default. Those
-- rows must not be reported as real placement ambiguity / human-skip work.
-- v2 also attaches the governed content-runway hard floor when that P1-02 service
-- is present, without making this migration depend on P1-02 during isolated P1-01 CI.

begin;

create or replace function public.get_exam_prep_beta_weekly_snapshot_v2(
  p_cohort_key text,
  p_period_end timestamptz default now()
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_snapshot jsonb;
  v_mode text;
  v_started int;
  v_screening int;
  v_post_stage0_ambiguous int;
  v_advanced_human int;
  v_max_active_week smallint:=1;
  v_runway jsonb;
  v_runway_available boolean:=false;
  v_runway_red int:=0;
  v_stage_denominator_bad int:=0;
  v_legacy_credit_bad int:=0;
begin
  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  v_snapshot:=public.get_exam_prep_beta_weekly_snapshot_v1(p_cohort_key,p_period_end);

  -- Correct placement observability. A materialized NOT_STARTED row is not an
  -- academic ambiguity incident. Screening-incomplete is tracked separately.
  foreach v_mode in array array['core','ai_assist','mentor_care'] loop
    select
      count(*) filter(where p.placement_status<>'not_started'),
      count(*) filter(where p.placement_status='screening_incomplete'),
      count(*) filter(where p.stage0_complete and p.ambiguity),
      count(*) filter(where p.stage0_complete and p.ambiguity and p.advanced_skip_requires_human)
    into v_started,v_screening,v_post_stage0_ambiguous,v_advanced_human
    from private.exam_prep_component_placements p
    join private.exam_prep_beta_members bm
      on bm.user_id=p.user_id and bm.cohort_id=v_c.id
    where bm.service_mode=v_mode and bm.member_status='active';

    v_snapshot:=jsonb_set(v_snapshot,array['service_metrics',v_mode,'placements_started'],to_jsonb(coalesce(v_started,0)),true);
    v_snapshot:=jsonb_set(v_snapshot,array['service_metrics',v_mode,'screening_incomplete'],to_jsonb(coalesce(v_screening,0)),true);
    v_snapshot:=jsonb_set(v_snapshot,array['service_metrics',v_mode,'placement_ambiguity'],to_jsonb(coalesce(v_post_stage0_ambiguous,0)),true);
    v_snapshot:=jsonb_set(v_snapshot,array['service_metrics',v_mode,'advanced_skip_human_pending'],to_jsonb(coalesce(v_advanced_human,0)),true);
  end loop;

  -- Denominator drift is a hard academic-integrity signal: 45 for P1, 36 for P5.
  select count(*) into v_stage_denominator_bad
  from private.exam_prep_stage_states s
  join private.exam_prep_beta_members bm
    on bm.user_id=s.user_id and bm.cohort_id=v_c.id
  where bm.member_status='active'
    and ((s.component_code='P1' and s.denominator_count<>45)
      or (s.component_code='P5' and s.denominator_count<>36)
      or s.component_code not in ('P1','P5'));

  -- P1-05 references are advisory only. Any crediting row is a hard blocker.
  if to_regclass('private.exam_prep_legacy_evidence_references') is not null then
    execute $q$
      select count(*)
      from private.exam_prep_legacy_evidence_references r
      join private.exam_prep_beta_members bm
        on bm.user_id=r.user_id
      join private.exam_prep_beta_cohorts bc
        on bc.id=bm.cohort_id
      where bc.cohort_key=$1
        and bm.member_status='active'
        and (r.source_type<>'legacy_readonly' or r.academic_credit or r.verification_claim<>'none')
    $q$ into v_legacy_credit_bad using p_cohort_key;
  end if;

  -- Use the furthest active learner week as the conservative runway check.
  select coalesce(max(p.active_week_no),1)::smallint into v_max_active_week
  from private.exam_prep_exam_profiles p
  join private.exam_prep_beta_members bm
    on bm.user_id=p.user_id and bm.cohort_id=v_c.id
  where bm.member_status='active';

  if to_regprocedure('public.get_exam_prep_content_runway_v1(smallint)') is not null then
    execute 'select public.get_exam_prep_content_runway_v1($1::smallint)'
      into v_runway using v_max_active_week;
    v_runway_available:=true;
    v_runway_red:=case when coalesce((v_runway->>'hard_floor_green')::boolean,false) then 0 else 1 end;
  else
    v_runway:=jsonb_build_object(
      'available',false,
      'active_week_no',v_max_active_week,
      'hard_floor_green',false,
      'reason','content_runway_service_not_available'
    );
    v_runway_red:=1;
  end if;

  v_snapshot:=jsonb_set(v_snapshot,'{hard_blockers,stage_denominator_mismatches}',to_jsonb(v_stage_denominator_bad),true);
  v_snapshot:=jsonb_set(v_snapshot,'{hard_blockers,legacy_reference_credit_violations}',to_jsonb(v_legacy_credit_bad),true);
  v_snapshot:=jsonb_set(v_snapshot,'{hard_blockers,content_runway_hard_floor_red}',to_jsonb(v_runway_red),true);
  v_snapshot:=jsonb_set(v_snapshot,'{content_runway}',coalesce(v_runway,'{}'::jsonb),true);
  v_snapshot:=jsonb_set(v_snapshot,'{monitoring_semantics_version}',to_jsonb('weekly_snapshot_v2'::text),true);
  v_snapshot:=jsonb_set(v_snapshot,'{content_runway_service_available}',to_jsonb(v_runway_available),true);

  -- Metrics remain evidence for a human governance decision, never an automatic GO.
  v_snapshot:=jsonb_set(v_snapshot,'{decision}',to_jsonb('NOT_DERIVED_BY_SYSTEM'::text),true);

  return v_snapshot;
end;
$$;

revoke all on function public.get_exam_prep_beta_weekly_snapshot_v2(text,timestamptz) from public,anon,authenticated;
grant execute on function public.get_exam_prep_beta_weekly_snapshot_v2(text,timestamptz) to service_role;

-- Migration-level contract checks. No cohort or learner data is created/changed.
do $$
declare v_bad int;
begin
  if to_regprocedure('public.get_exam_prep_beta_weekly_snapshot_v1(text,timestamptz)') is null then
    raise exception 'P1-01 snapshot v2 requires v1 weekly snapshot';
  end if;
  if has_function_privilege('anon','public.get_exam_prep_beta_weekly_snapshot_v2(text,timestamptz)','EXECUTE') then
    raise exception 'P1-01 snapshot v2 anon execution must remain revoked';
  end if;
  if has_function_privilege('authenticated','public.get_exam_prep_beta_weekly_snapshot_v2(text,timestamptz)','EXECUTE') then
    raise exception 'P1-01 snapshot v2 authenticated execution must remain revoked';
  end if;

  select count(*) into v_bad
  from private.exam_prep_feature_config
  where id=1 and rollout_state='off' and not core_enabled and not ai_enabled and not mentor_enabled and kill_switch;
  -- Isolated P1-01 CI is fail-closed at migration time. Production may already be a
  -- controlled beta, so absence of this row is intentionally not an exception here.
end;
$$;

commit;
