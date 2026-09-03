-- P0-03: close direct client access to the canonical questions table.
-- Practice and Tour runtime/review paths are now exposed only through authenticated
-- SECURITY DEFINER safe-v4 RPCs. Client roles must not read answer keys or mutate
-- canonical assessment content directly.

drop policy if exists questions_public_read on public.questions;

revoke all privileges on table public.questions from anon, authenticated;

comment on table public.questions is
'Canonical assessment question bank. P0-03: no direct anon/authenticated table access; client assessment flows must use approved authenticated safe RPCs.';
