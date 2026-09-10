-- The identity-rekey guard is intentionally safe to execute from any database role.
-- It returns TRUE only while a postgres-owned SECURITY DEFINER re-key is active.
-- Stage trigger WHEN clauses must be able to evaluate it during normal authenticated writes.
grant execute on function private.exam_prep_identity_rekey_active_v1() to public;
