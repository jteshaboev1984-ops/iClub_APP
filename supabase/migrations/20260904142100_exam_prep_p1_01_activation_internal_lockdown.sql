-- P1-01 security hardening: the P0-16 activation delegate must not remain
-- directly callable by service_role after the AI-runtime wrapper is introduced.

begin;

alter function public.activate_exam_prep_controlled_beta_wave_p0_16_internal_v1(text,smallint)
set schema private;

revoke all on function private.activate_exam_prep_controlled_beta_wave_p0_16_internal_v1(text,smallint)
from public,anon,authenticated,service_role;

create or replace function public.activate_exam_prep_controlled_beta_wave_v1(p_cohort_key text,p_wave smallint)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_c private.exam_prep_beta_cohorts%rowtype;
begin
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if not private.exam_prep_beta_ai_wave_ready_v1(v_c.id,p_wave) then raise exception 'exam_prep_beta_ai_runtime_not_ready'; end if;
  return private.activate_exam_prep_controlled_beta_wave_p0_16_internal_v1(p_cohort_key,p_wave);
end;
$$;

revoke all on function public.activate_exam_prep_controlled_beta_wave_v1(text,smallint) from public,anon,authenticated;
grant execute on function public.activate_exam_prep_controlled_beta_wave_v1(text,smallint) to service_role;

do $$
declare v_oid oid;
begin
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='activate_exam_prep_controlled_beta_wave_p0_16_internal_v1'
    and pg_get_function_identity_arguments(p.oid)='p_cohort_key text, p_wave smallint';
  if v_oid is null then raise exception 'P1-01 activation delegate missing after lockdown'; end if;
  if has_function_privilege('service_role',v_oid,'EXECUTE')
     or has_function_privilege('authenticated',v_oid,'EXECUTE')
     or has_function_privilege('anon',v_oid,'EXECUTE') then
    raise exception 'P1-01 activation delegate privilege leak';
  end if;
end;
$$;

commit;
