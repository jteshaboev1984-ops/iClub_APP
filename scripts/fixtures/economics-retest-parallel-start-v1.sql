-- Two concurrent PostgreSQL connections run this against fictional user B.
-- Each has a different idempotency key for the same unseen skill-B error.
-- The other synthetic skill-A error is already exposed and must remain blocked.
\set ON_ERROR_STOP on
set role authenticated;
select set_config('test.concurrent_key',:'concurrent_key',false) \gset
select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',false) \gset
select set_config('request.jwt.claims',jsonb_build_object(
 'sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
 'session_id','bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb',
 'exp',extract(epoch from clock_timestamp()+interval '1 hour')::bigint,
 'is_anonymous',false)::text,false) \gset
do $$
declare v jsonb;
begin
  v:=public.iclub_econ_retest_start_v1(
    '22222222-2222-4222-8222-222222222222',2,
    current_setting('test.concurrent_key',true));
  if v->>'ok' is distinct from 'true'
     or v->>'session_id' is null then
    raise exception 'Parallel start must resolve to one active session: %',v;
  end if;
  insert into public.synthetic_parallel_results_v1(key,session_id)
    values(current_setting('test.concurrent_key'),(v->>'session_id')::uuid);
end $$;
