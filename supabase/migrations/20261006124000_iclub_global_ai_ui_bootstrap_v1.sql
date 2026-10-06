-- iClub Global AI learner-shell bootstrap v1.
-- Browser-safe read only: exposes only whether the shell may be shown and
-- whether a protected assessment currently forces the collapsed state.

begin;

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
begin
  if v_uid is null then
    return jsonb_build_object(
      'visible',false,
      'assessment_blocked',false,
      'reason','auth_required',
      'ui_version','global_ai_shell_v1'
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
      'reason','ui_disabled',
      'ui_version','global_ai_shell_v1'
    );
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(v_uid);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'visible',false,
      'assessment_blocked',false,
      'reason','access_unresolved',
      'ui_version','global_ai_shell_v1'
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

  return jsonb_build_object(
    'visible',true,
    'assessment_blocked',coalesce(v_blocked,true),
    'reason',case when coalesce(v_blocked,true) then 'active_assessment' else null end,
    'locale',coalesce(v_locale,'ru'),
    'ui_version','global_ai_shell_v1'
  );
end;
$$;

revoke all on function public.get_iclub_ai_ui_bootstrap_v1() from public,anon;
grant execute on function public.get_iclub_ai_ui_bootstrap_v1()
  to authenticated,service_role;

commit;
