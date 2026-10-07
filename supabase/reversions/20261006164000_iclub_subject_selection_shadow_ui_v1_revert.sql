-- Safe reversion for beta subject-selection UI v1.
-- Keeps any private shadow selections because their storage belongs to the parent lifecycle phase.

begin;

do $guard$
declare
  v_cfg private.iclub_commercial_access_config%rowtype;
begin
  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if found and coalesce(v_cfg.subject_selection_ui_enabled,false) then
    raise exception 'Subject-selection UI reversion refused: UI is still enabled';
  end if;
end;
$guard$;

drop function if exists public.set_iclub_my_subject_slot_v1(text,boolean,boolean);
drop function if exists public.get_iclub_subject_selection_bootstrap_v1();

alter table private.iclub_commercial_access_config
  drop column if exists subject_selection_ui_enabled;

commit;
