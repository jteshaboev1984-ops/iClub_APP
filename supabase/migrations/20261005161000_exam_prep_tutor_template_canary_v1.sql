-- Tutor Template controlled-beta canary foundation v1.
-- Adds an independent kill switch and service-only scope check for provider-free Tutor Cards.
-- Default is OFF. No learner academic state, entitlement, cohort, Practice, Tours, ratings,
-- certificates, source-card content or localStorage changes.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

create table if not exists private.exam_prep_ai_tutor_template_policy (
  id smallint primary key default 1 check (id=1),
  template_canary_enabled boolean not null default false,
  preset_followups_enabled boolean not null default true,
  cohort_key text not null default 'math_as_p1_p5_beta_2026_09_01',
  policy_version text not null default 'tutor_template_canary_v1',
  updated_at timestamptz not null default now()
);

alter table private.exam_prep_ai_tutor_template_policy enable row level security;
alter table private.exam_prep_ai_tutor_template_policy force row level security;

insert into private.exam_prep_ai_tutor_template_policy(
  id,template_canary_enabled,preset_followups_enabled,cohort_key,policy_version
) values (
  1,false,true,'math_as_p1_p5_beta_2026_09_01','tutor_template_canary_v1'
)
on conflict (id) do nothing;

revoke all on private.exam_prep_ai_tutor_template_policy from public,anon,authenticated;
grant select,update on private.exam_prep_ai_tutor_template_policy to service_role;

create or replace function public.get_exam_prep_ai_tutor_template_canary_service_v1(
  p_user_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path=''
as $fn$
  with p as (
    select *
    from private.exam_prep_ai_tutor_template_policy
    where id=1
  ),
  eligible as (
    select exists(
      select 1
      from p
      join private.exam_prep_feature_config fc on fc.id=1
      join private.exam_prep_beta_cohorts bc on bc.cohort_key=p.cohort_key
      join private.exam_prep_beta_members bm
        on bm.cohort_id=bc.id
       and bm.user_id=p_user_id
       and bm.member_status='active'
       and bm.service_mode='ai_assist'
      join private.exam_prep_beta_consents c
        on c.cohort_id=bc.id
       and c.user_id=p_user_id
       and c.consent_status='granted'
       and c.revoked_at is null
      join private.exam_prep_feature_entitlements e
        on e.user_id=p_user_id
       and e.entitlement_status='active'
       and e.core_access
       and e.ai_assist
       and not e.mentor_care_entitled
       and e.cohort_key=p.cohort_key
       and (e.valid_from is null or e.valid_from<=now())
       and (e.valid_until is null or e.valid_until>now())
      where p.template_canary_enabled
        and fc.rollout_state='controlled_beta'
        and fc.core_enabled
        and fc.ai_enabled
        and not fc.mentor_enabled
        and not fc.kill_switch
        and bc.cohort_status in ('canary','active')
        and not exists(
          select 1
          from private.exam_prep_synthetic_identities s
          where s.user_id=p_user_id
        )
    ) enabled
  )
  select jsonb_build_object(
    'enabled',coalesce((select enabled from eligible),false),
    'preset_followups_enabled',coalesce((select preset_followups_enabled from p),false),
    'policy_version',coalesce((select policy_version from p),'tutor_template_canary_v1'),
    'cohort_key',coalesce((select cohort_key from p),'')
  );
$fn$;

revoke all on function public.get_exam_prep_ai_tutor_template_canary_service_v1(uuid)
  from public,anon,authenticated;
grant execute on function public.get_exam_prep_ai_tutor_template_canary_service_v1(uuid)
  to service_role;

do $postcheck$
declare
  v_policy private.exam_prep_ai_tutor_template_policy%rowtype;
begin
  select * into strict v_policy
  from private.exam_prep_ai_tutor_template_policy
  where id=1;

  if v_policy.template_canary_enabled then
    raise exception 'Tutor template canary foundation must default OFF';
  end if;

  if not v_policy.preset_followups_enabled then
    raise exception 'Tutor template preset follow-ups must be configured ON for later canary activation';
  end if;

  if has_table_privilege('authenticated','private.exam_prep_ai_tutor_template_policy','SELECT')
     or has_table_privilege('anon','private.exam_prep_ai_tutor_template_policy','SELECT')
  then
    raise exception 'Tutor template policy leaked to browser role';
  end if;

  if has_function_privilege(
       'authenticated',
       'public.get_exam_prep_ai_tutor_template_canary_service_v1(uuid)',
       'EXECUTE'
     )
     or has_function_privilege(
       'anon',
       'public.get_exam_prep_ai_tutor_template_canary_service_v1(uuid)',
       'EXECUTE'
     )
  then
    raise exception 'Tutor template canary service leaked to browser role';
  end if;

  if not has_function_privilege(
       'service_role',
       'public.get_exam_prep_ai_tutor_template_canary_service_v1(uuid)',
       'EXECUTE'
     )
  then
    raise exception 'Tutor template canary service missing service-role access';
  end if;
end
$postcheck$;

commit;
