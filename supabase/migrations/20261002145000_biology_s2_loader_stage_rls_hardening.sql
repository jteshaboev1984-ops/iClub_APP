-- Defense-in-depth hardening for the one-off Biology S2 loader staging table.
-- Preserves all 21 staging rows and service_role access. Browser roles remain blocked.
-- The table is production-only in some environments, so this migration is conditional.

begin;
set local lock_timeout='3s';
set local statement_timeout='30s';

do $$
begin
  if to_regclass('public.iclub_biology_s2_loader_stage_20260624') is not null then
    revoke all on table public.iclub_biology_s2_loader_stage_20260624 from anon, authenticated;
    alter table public.iclub_biology_s2_loader_stage_20260624 enable row level security;

    if not (
      select c.relrowsecurity
      from pg_class c
      where c.oid='public.iclub_biology_s2_loader_stage_20260624'::regclass
    ) then
      raise exception 'biology_s2_loader_stage_rls_not_enabled';
    end if;

    if has_table_privilege('anon','public.iclub_biology_s2_loader_stage_20260624','SELECT')
       or has_table_privilege('authenticated','public.iclub_biology_s2_loader_stage_20260624','SELECT')
    then
      raise exception 'biology_s2_loader_stage_browser_access_not_revoked';
    end if;
  end if;
end
$$;

commit;
