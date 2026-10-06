-- Safe reversion for iClub subject-access shadow routing v1.

begin;

do $guard$
declare
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_count integer;
begin
  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if found and coalesce(v_cfg.subject_access_shadow_routing_enabled,false) then
    raise exception 'Subject-access shadow routing reversion refused: routing is still enabled';
  end if;

  select count(*) into v_count
  from private.iclub_subject_access_shadow_events;

  if v_count<>0 then
    raise exception 'Subject-access shadow routing reversion refused: audit rows exist=%',v_count;
  end if;
end;
$guard$;

drop function if exists public.record_iclub_my_subject_access_shadow_v1(text,text);
drop table if exists private.iclub_subject_access_shadow_events;

alter table private.iclub_commercial_access_config
  drop column if exists subject_access_shadow_routing_enabled;

commit;
