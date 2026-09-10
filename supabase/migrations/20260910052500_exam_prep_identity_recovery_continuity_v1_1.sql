-- Exam Prep identity recovery continuity v1.1
-- Corrects the transfer mechanism for hosted Postgres where session_replication_role
-- cannot be changed. Uses a transaction-local recovery marker instead.

create or replace function private.exam_prep_block_immutable_mutation_v1()
returns trigger
language plpgsql
set search_path to ''
as $function$
begin
  if tg_op = 'UPDATE'
     and current_setting('iclub.exam_prep_identity_recovery', true) = 'on'
     and (to_jsonb(new) - array['user_id','learner_user_id','mentor_user_id','reviewer_user_id','raised_by_user_id','moderator_user_id']::text[])
       = (to_jsonb(old) - array['user_id','learner_user_id','mentor_user_id','reviewer_user_id','raised_by_user_id','moderator_user_id']::text[])
  then
    return new;
  end if;

  raise exception 'immutable_exam_prep_fact';
end;
$function$;

-- During an identity-only transfer, stage rows must retain exactly the same academic
-- projection. These four broad UPDATE triggers are therefore skipped only while the
-- private transfer helper holds the transaction-local marker.
drop trigger if exists exam_prep_maybe_recommend_readiness_v1 on private.exam_prep_stage_states;
create trigger exam_prep_maybe_recommend_readiness_v1
after insert or update on private.exam_prep_stage_states
for each row
when (current_setting('iclub.exam_prep_identity_recovery', true) is distinct from 'on')
execute function private.exam_prep_maybe_recommend_readiness_v1();

drop trigger if exists exam_prep_readiness_projection_v1 on private.exam_prep_stage_states;
create trigger exam_prep_readiness_projection_v1
before insert or update on private.exam_prep_stage_states
for each row
when (current_setting('iclub.exam_prep_identity_recovery', true) is distinct from 'on')
execute function private.exam_prep_apply_readiness_projection_v1();

drop trigger if exists exam_prep_stage0_gate_projection_v1 on private.exam_prep_stage_states;
create trigger exam_prep_stage0_gate_projection_v1
before insert or update on private.exam_prep_stage_states
for each row
when (current_setting('iclub.exam_prep_identity_recovery', true) is distinct from 'on')
execute function private.exam_prep_apply_stage0_gate_v1();

drop trigger if exists exam_prep_stage_access_sync_v1 on private.exam_prep_stage_states;
create trigger exam_prep_stage_access_sync_v1
after insert or update on private.exam_prep_stage_states
for each row
when (current_setting('iclub.exam_prep_identity_recovery', true) is distinct from 'on')
execute function private.exam_prep_sync_access_gate_stage_v1();

create or replace function private.exam_prep_reassign_user_identity_v1(
  p_old_user_id uuid,
  p_new_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  r record;
  v_target_has_rows boolean := false;
  v_remaining bigint := 0;
  v_count bigint := 0;
  v_moved jsonb := '{}'::jsonb;
  v_prev_marker text := current_setting('iclub.exam_prep_identity_recovery', true);
begin
  if p_old_user_id is null or p_new_user_id is null then
    raise exception 'exam_prep_identity_recovery_bad_args';
  end if;

  if p_old_user_id = p_new_user_id then
    return jsonb_build_object('ok', true, 'reason', 'same_user', 'moved', v_moved);
  end if;

  if not exists (select 1 from public.users where id = p_old_user_id) then
    raise exception 'exam_prep_identity_recovery_old_user_missing';
  end if;

  if not exists (select 1 from public.users where id = p_new_user_id) then
    raise exception 'exam_prep_identity_recovery_new_user_missing';
  end if;

  -- Never merge two independent Exam Prep histories automatically.
  for r in
    select distinct n.nspname as schema_name,c.relname as table_name,a.attname as column_name
    from pg_constraint con
    join pg_class c on c.oid = con.conrelid
    join pg_namespace n on n.oid = c.relnamespace
    join pg_class fc on fc.oid = con.confrelid
    join pg_namespace fn on fn.oid = fc.relnamespace
    join unnest(con.conkey) with ordinality ck(attnum, ord) on true
    join unnest(con.confkey) with ordinality fk(attnum, ord) on fk.ord = ck.ord
    join pg_attribute a on a.attrelid = c.oid and a.attnum = ck.attnum
    where con.contype = 'f'
      and n.nspname = 'private'
      and c.relname like 'exam_prep_%'
      and fn.nspname = 'public'
      and fc.relname = 'users'
    order by c.relname, a.attname
  loop
    execute format('select exists(select 1 from %I.%I where %I = $1)',r.schema_name,r.table_name,r.column_name)
      into v_target_has_rows using p_new_user_id;
    if v_target_has_rows then
      raise exception 'exam_prep_identity_recovery_target_not_clean: %.%', r.table_name, r.column_name;
    end if;
  end loop;

  perform set_config('iclub.exam_prep_identity_recovery', 'on', true);

  -- Move identity FKs only. Immutable facts keep every other column unchanged.
  for r in
    select distinct n.nspname as schema_name,c.relname as table_name,a.attname as column_name
    from pg_constraint con
    join pg_class c on c.oid = con.conrelid
    join pg_namespace n on n.oid = c.relnamespace
    join pg_class fc on fc.oid = con.confrelid
    join pg_namespace fn on fn.oid = fc.relnamespace
    join unnest(con.conkey) with ordinality ck(attnum, ord) on true
    join unnest(con.confkey) with ordinality fk(attnum, ord) on fk.ord = ck.ord
    join pg_attribute a on a.attrelid = c.oid and a.attnum = ck.attnum
    where con.contype = 'f'
      and n.nspname = 'private'
      and c.relname like 'exam_prep_%'
      and fn.nspname = 'public'
      and fc.relname = 'users'
    order by c.relname, a.attname
  loop
    execute format('update %I.%I set %I = $1 where %I = $2',r.schema_name,r.table_name,r.column_name,r.column_name)
      using p_new_user_id, p_old_user_id;
    get diagnostics v_count = row_count;
    if v_count > 0 then
      v_moved := v_moved || jsonb_build_object(r.table_name || '.' || r.column_name, v_count);
    end if;
  end loop;

  if v_prev_marker is null then
    perform set_config('iclub.exam_prep_identity_recovery', '', true);
  else
    perform set_config('iclub.exam_prep_identity_recovery', v_prev_marker, true);
  end if;

  -- Hard postcondition before caller can delete the old public.users row.
  for r in
    select distinct n.nspname as schema_name,c.relname as table_name,a.attname as column_name
    from pg_constraint con
    join pg_class c on c.oid = con.conrelid
    join pg_namespace n on n.oid = c.relnamespace
    join pg_class fc on fc.oid = con.confrelid
    join pg_namespace fn on fn.oid = fc.relnamespace
    join unnest(con.conkey) with ordinality ck(attnum, ord) on true
    join unnest(con.confkey) with ordinality fk(attnum, ord) on fk.ord = ck.ord
    join pg_attribute a on a.attrelid = c.oid and a.attnum = ck.attnum
    where con.contype = 'f'
      and n.nspname = 'private'
      and c.relname like 'exam_prep_%'
      and fn.nspname = 'public'
      and fc.relname = 'users'
    order by c.relname, a.attname
  loop
    execute format('select count(*) from %I.%I where %I = $1',r.schema_name,r.table_name,r.column_name)
      into v_count using p_old_user_id;
    v_remaining := v_remaining + coalesce(v_count, 0);
  end loop;

  if v_remaining <> 0 then
    raise exception 'exam_prep_identity_recovery_incomplete: % references remain', v_remaining;
  end if;

  return jsonb_build_object('ok',true,'reason','reassigned','moved',v_moved,'remaining_old_references',0);
exception
  when others then
    begin
      if v_prev_marker is null then
        perform set_config('iclub.exam_prep_identity_recovery', '', true);
      else
        perform set_config('iclub.exam_prep_identity_recovery', v_prev_marker, true);
      end if;
    exception when others then null; end;
    raise;
end;
$function$;

revoke all on function private.exam_prep_reassign_user_identity_v1(uuid, uuid) from public;
revoke all on function private.exam_prep_reassign_user_identity_v1(uuid, uuid) from anon;
revoke all on function private.exam_prep_reassign_user_identity_v1(uuid, uuid) from authenticated;
