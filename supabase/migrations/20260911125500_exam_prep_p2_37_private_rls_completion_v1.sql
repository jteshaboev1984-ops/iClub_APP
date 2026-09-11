begin;

-- P2-37: keep the Exam Prep private-table security invariant intact after the
-- P2-21/P2-34/P2-36 additions. These tables are server-owned; authenticated and
-- anonymous clients must never gain direct table access even if a future grant
-- is added accidentally.

alter table private.exam_prep_assessment_mixed_nodes enable row level security;
alter table private.exam_prep_stage4_timed_section_scope enable row level security;
alter table private.exam_prep_beta_expansion_controls enable row level security;
alter table private.exam_prep_beta_expansion_validation_evidence enable row level security;

revoke all on private.exam_prep_assessment_mixed_nodes from public,anon,authenticated;
revoke all on private.exam_prep_stage4_timed_section_scope from public,anon,authenticated;
revoke all on private.exam_prep_beta_expansion_controls from public,anon,authenticated;
revoke all on private.exam_prep_beta_expansion_validation_evidence from public,anon,authenticated;

do $$
declare
  v_missing_rls int;
  v_client_writes int;
begin
  select count(*)::int into v_missing_rls
  from pg_tables
  where schemaname='private'
    and tablename like 'exam_prep%'
    and not rowsecurity;

  if v_missing_rls<>0 then
    raise exception 'P2-37 private Exam Prep RLS invariant failed: % table(s) without RLS',v_missing_rls;
  end if;

  select count(*)::int into v_client_writes
  from information_schema.role_table_grants
  where table_schema='private'
    and table_name like 'exam_prep%'
    and grantee in ('anon','authenticated')
    and privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE');

  if v_client_writes<>0 then
    raise exception 'P2-37 private Exam Prep client-write invariant failed: % grant(s)',v_client_writes;
  end if;
end;
$$;

commit;
