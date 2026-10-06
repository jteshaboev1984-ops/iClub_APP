-- iClub Global AI conversation shell support v1.
-- Additive, browser-safe, and still dormant while Global AI runtime flags are OFF.
-- No raw chat storage is introduced.

begin;

insert into private.iclub_ai_subject_readiness(
  subject_key,scope_code,readiness,generation_allowed,approved_source_set,
  readiness_version,notes,adapter_code
) values (
  'general','global','basic',false,null,
  'global_ai_subject_readiness_v1',
  'General iClub help only. Academic generation is not enabled here.',
  'app_help_v1'
)
on conflict(subject_key,scope_code) do update
set readiness='basic',
    generation_allowed=false,
    approved_source_set=null,
    adapter_code='app_help_v1',
    notes='General iClub help only. Academic generation is not enabled here.',
    updated_at=now();

create or replace function public.get_iclub_ai_ui_bootstrap_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid:=auth.uid();
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_caps jsonb;
  v_blocked boolean:=true;
  v_locale text:='ru';
  v_exhausted boolean:=false;
  v_reset_at timestamptz:=null;
begin
  if v_uid is null then
    return jsonb_build_object(
      'visible',false,
      'assessment_blocked',false,
      'usage_exhausted',false,
      'reset_at',null,
      'reason','auth_required',
      'ui_version','global_ai_conversations_v1'
    );
  end if;

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if not found
     or v_runtime.kill_switch
     or not v_runtime.ui_enabled
     or not v_runtime.gateway_enabled then
    return jsonb_build_object(
      'visible',false,
      'assessment_blocked',false,
      'usage_exhausted',false,
      'reset_at',null,
      'reason','ui_disabled',
      'ui_version','global_ai_conversations_v1'
    );
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(v_uid);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'visible',false,
      'assessment_blocked',false,
      'usage_exhausted',false,
      'reset_at',null,
      'reason','access_unresolved',
      'ui_version','global_ai_conversations_v1'
    );
  end if;

  select case
    when u.language_code in ('ru','uz','en') then u.language_code
    else 'ru'
  end
  into v_locale
  from public.users u
  where u.id=v_uid;

  v_blocked:=private.iclub_ai_has_active_protected_assessment_v1(v_uid);

  select
    coalesce(p.exhausted,false),
    p.reset_at
  into v_exhausted,v_reset_at
  from private.iclub_ai_usage_periods p
  where p.user_id=v_uid
    and p.status='active'
    and p.reset_at>now()
  order by p.created_at desc
  limit 1;

  v_exhausted:=coalesce(v_exhausted,false);
  if not v_exhausted then
    v_reset_at:=null;
  end if;

  return jsonb_build_object(
    'visible',true,
    'assessment_blocked',coalesce(v_blocked,true),
    'usage_exhausted',v_exhausted,
    'reset_at',v_reset_at,
    'reason',case
      when coalesce(v_blocked,true) then 'active_assessment'
      when v_exhausted then 'usage_exhausted'
      else null
    end,
    'locale',coalesce(v_locale,'ru'),
    'ui_version','global_ai_conversations_v1'
  );
end;
$$;

revoke all on function public.get_iclub_ai_ui_bootstrap_v1() from public,anon;
grant execute on function public.get_iclub_ai_ui_bootstrap_v1()
  to authenticated,service_role;

commit;
