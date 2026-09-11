begin;

-- P2-39: private Exam Prep implementation helpers must not be directly
-- executable by browser-facing roles. This helper leaked no learner data, but
-- its default PostgreSQL ACL granted EXECUTE to PUBLIC.
revoke all on function private.exam_prep_timed_min_stage_v1(text)
from public, anon, authenticated;

grant execute on function private.exam_prep_timed_min_stage_v1(text)
to service_role;

-- Defense in depth for future private helpers created by the migration owner.
-- New functions in private should not inherit PostgreSQL's default PUBLIC
-- EXECUTE privilege; explicit grants remain deliberate and reviewable.
alter default privileges in schema private
revoke execute on functions from public;

-- Deployment invariant: no existing private exam_prep_* helper may be
-- client-callable after this migration.
do $$
declare
  v_exposed int;
begin
  select count(*) into v_exposed
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private'
    and p.proname like 'exam_prep_%'
    and (
      has_function_privilege('anon',p.oid,'EXECUTE')
      or has_function_privilege('authenticated',p.oid,'EXECUTE')
      or has_function_privilege('public',p.oid,'EXECUTE')
    );

  if v_exposed<>0 then
    raise exception 'P2-39 private Exam Prep helper execute exposure count=%',v_exposed;
  end if;
end
$$;

commit;
