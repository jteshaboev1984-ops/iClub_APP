-- Safe rollback for canary subject-access enforcement preview v1.
-- Refuses rollback if the beta enforcement flag is active.

begin;

do $$
declare
  v_cfg private.iclub_commercial_access_config%rowtype;
begin
  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if found and coalesce(v_cfg.canary_subject_access_enforced,false) then
    raise exception 'Canary subject-access rollback refused: enforcement preview is active';
  end if;
end
$$;

drop function if exists public.get_iclub_my_subject_access_v1(text,text);

alter table private.iclub_commercial_access_config
  drop column if exists canary_subject_access_enforced;

commit;
