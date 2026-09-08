-- P2-08 hotfix: make non-crediting progress checks safely resumable and ensure
-- every failed representative check can feed targeted refresh without displacing corrections/retests.
begin;

create or replace function public.authorize_exam_prep_revalidation_item_safe_v1(
  p_case_id uuid,
  p_item_order integer
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_case private.exam_prep_progress_revalidation_cases%rowtype;
  v_item private.exam_prep_progress_revalidation_items%rowtype;
  v_ass bigint;
  v_auth private.exam_prep_session_authorizations%rowtype;
  v_existing_session uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_case_id is null then raise exception 'exam_prep_revalidation_case_required'; end if;
  if p_item_order is null or p_item_order not between 1 and 3 then raise exception 'exam_prep_bad_revalidation_item'; end if;

  select * into v_case
  from private.exam_prep_progress_revalidation_cases
  where id=p_case_id and user_id=v_uid and status in ('recommended','in_progress','refresh_recommended');
  if v_case.id is null then raise exception 'exam_prep_revalidation_case_not_available' using errcode='P0002'; end if;

  select * into v_item
  from private.exam_prep_progress_revalidation_items
  where case_id=v_case.id and item_order=p_item_order::smallint;
  if v_item.case_id is null then raise exception 'exam_prep_revalidation_item_not_found' using errcode='P0002'; end if;
  if v_item.status='completed' then raise exception 'exam_prep_revalidation_item_already_completed'; end if;

  if v_item.authorization_id is not null then
    select * into v_auth
    from private.exam_prep_session_authorizations
    where id=v_item.authorization_id and user_id=v_uid;

    if v_auth.id is not null and v_auth.academic_credit=false and v_auth.credit_context='progress_revalidation' then
      if v_auth.status='issued' and (v_auth.valid_until is null or v_auth.valid_until>now()) then
        return jsonb_build_object(
          'authorization_id',v_auth.id,'session_id',null,'case_id',v_case.id,'item_order',v_item.item_order,
          'component_code',v_case.component_code,'academic_credit',false,'resumed',true
        );
      elsif v_auth.status='consumed' and v_auth.consumed_session_id is not null then
        v_existing_session:=v_auth.consumed_session_id;
        return jsonb_build_object(
          'authorization_id',v_auth.id,'session_id',v_existing_session,'case_id',v_case.id,'item_order',v_item.item_order,
          'component_code',v_case.component_code,'academic_credit',false,'resumed',true
        );
      end if;
    end if;
  end if;

  select a.id into v_ass
  from private.exam_prep_assessments a
  where a.component_code=v_case.component_code and a.assessment_type='retest' and a.status='published'
    and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=v_item.skill_code)
    and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>v_item.skill_code)
  order by a.id limit 1;
  if v_ass is null then raise exception 'exam_prep_revalidation_content_not_ready'; end if;

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit,credit_context
  ) values(
    v_uid,v_ass,v_case.component_code,'retest','issued',now()+interval '1 hour',
    'Non-crediting progress revalidation after study interruption',false,'progress_revalidation'
  ) returning * into v_auth;

  update private.exam_prep_progress_revalidation_items
    set status='authorized',authorization_id=v_auth.id,session_id=null,passed=null,completed_at=null
  where case_id=v_case.id and item_order=v_item.item_order;
  update private.exam_prep_progress_revalidation_cases
    set status='in_progress',updated_at=now(),completed_at=null
  where id=v_case.id;

  return jsonb_build_object(
    'authorization_id',v_auth.id,'session_id',null,'case_id',v_case.id,'item_order',v_item.item_order,
    'component_code',v_case.component_code,'academic_credit',false,'resumed',false
  );
end;
$$;
revoke execute on function public.authorize_exam_prep_revalidation_item_safe_v1(uuid,integer) from public,anon;
grant execute on function public.authorize_exam_prep_revalidation_item_safe_v1(uuid,integer) to authenticated,service_role;

-- Replace v3 planner with the same non-destructive behavior plus complete failed-check handling.
create or replace function public.generate_exam_prep_weekly_plan_safe_v3(p_component_code text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_base jsonb;
  v_plan uuid;
  v_case private.exam_prep_progress_revalidation_cases%rowtype;
  v_failed record;
  v_replace smallint;
  v_count int;
  v_applied int:=0;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  v_base:=public.generate_exam_prep_weekly_plan_safe_v2(p_component_code);
  v_plan:=(v_base->>'plan_id')::uuid;

  select rv.* into v_case
  from private.exam_prep_progress_revalidation_cases rv
  join private.exam_prep_recovery_cases rc on rc.id=rv.recovery_case_id
  where rv.user_id=v_uid and rv.component_code=p_component_code
    and rv.status='refresh_recommended' and rc.status='active'
  order by rv.updated_at desc limit 1;

  if v_case.id is not null then
    for v_failed in
      select i.skill_code
      from private.exam_prep_progress_revalidation_items i
      where i.case_id=v_case.id and i.status='completed' and i.passed is false
      order by i.item_order
    loop
      -- Existing corrective/retest work for the same skill is already stronger and must remain untouched.
      continue when exists(
        select 1 from private.exam_prep_weekly_plan_items x
        where x.plan_id=v_plan and x.skill_code=v_failed.skill_code
          and x.item_type in ('retest','correction')
      );
      continue when exists(
        select 1 from private.exam_prep_weekly_plan_items x
        where x.plan_id=v_plan and x.skill_code=v_failed.skill_code
          and x.action_code='RECOVERY_REFRESH_RETAINED_SKILL'
      );

      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;
      select max(priority_order)::smallint into v_replace
      from private.exam_prep_weekly_plan_items
      where plan_id=v_plan and item_type='learning' and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';

      if v_replace is not null then
        delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
      elsif v_count<3 then
        v_replace:=(v_count+1)::smallint;
      else
        continue;
      end if;

      insert into private.exam_prep_weekly_plan_items(
        plan_id,priority_order,item_type,skill_code,action_code,action_payload
      ) values(
        v_plan,v_replace,'learning',v_failed.skill_code,'RECOVERY_REFRESH_RETAINED_SKILL',
        jsonb_build_object('progress_retained',true,'revalidation_failed',true,'academic_stage_unchanged',true)
      );
      v_applied:=v_applied+1;
    end loop;
  end if;

  return v_base || jsonb_build_object(
    'progress_retained',true,
    'revalidation_refresh_applied',(v_applied>0),
    'revalidation_refresh_count',v_applied,
    'academic_stage_changed_by_recovery',false
  );
end;
$$;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) to authenticated,service_role;

commit;
