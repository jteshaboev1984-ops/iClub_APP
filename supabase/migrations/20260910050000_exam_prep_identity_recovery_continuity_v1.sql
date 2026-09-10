-- Exam Prep identity recovery continuity v1
-- Purpose: preserve all Exam Prep learner/staff rows when Telegram identity recovery
-- moves a live account from an old auth/user UUID to the current auth UUID.
-- This migration does not rewrite existing learner data. It only changes future recovery behavior.

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
  v_prev_replication_role text := current_setting('session_replication_role');
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

  -- Fail closed if the destination UUID already owns any Exam Prep row.
  -- We never merge two academic histories automatically.
  for r in
    select distinct
      n.nspname as schema_name,
      c.relname as table_name,
      a.attname as column_name
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
    execute format(
      'select exists(select 1 from %I.%I where %I = $1)',
      r.schema_name, r.table_name, r.column_name
    ) into v_target_has_rows using p_new_user_id;

    if v_target_has_rows then
      raise exception 'exam_prep_identity_recovery_target_not_clean: %.%', r.table_name, r.column_name;
    end if;
  end loop;

  -- Identity reassignment must not create new academic evidence, recompute stages,
  -- enqueue mentor work or trip immutable-fact guards. Disable row triggers only for
  -- this transaction-local, postgres-owned SECURITY DEFINER operation.
  perform set_config('session_replication_role', 'replica', true);

  for r in
    select distinct
      n.nspname as schema_name,
      c.relname as table_name,
      a.attname as column_name
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
    execute format(
      'update %I.%I set %I = $1 where %I = $2',
      r.schema_name, r.table_name, r.column_name, r.column_name
    ) using p_new_user_id, p_old_user_id;

    get diagnostics v_count = row_count;
    if v_count > 0 then
      v_moved := v_moved || jsonb_build_object(r.table_name || '.' || r.column_name, v_count);
    end if;
  end loop;

  perform set_config('session_replication_role', v_prev_replication_role, true);

  -- Hard postcondition: no Exam Prep FK may still point at the old UUID before
  -- public.users(old) is allowed to be deleted by the caller.
  for r in
    select distinct
      n.nspname as schema_name,
      c.relname as table_name,
      a.attname as column_name
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
    execute format(
      'select count(*) from %I.%I where %I = $1',
      r.schema_name, r.table_name, r.column_name
    ) into v_count using p_old_user_id;
    v_remaining := v_remaining + coalesce(v_count, 0);
  end loop;

  if v_remaining <> 0 then
    raise exception 'exam_prep_identity_recovery_incomplete: % references remain', v_remaining;
  end if;

  return jsonb_build_object(
    'ok', true,
    'reason', 'reassigned',
    'moved', v_moved,
    'remaining_old_references', 0
  );
exception
  when others then
    begin
      perform set_config('session_replication_role', v_prev_replication_role, true);
    exception when others then
      null;
    end;
    raise;
end;
$function$;

revoke all on function private.exam_prep_reassign_user_identity_v1(uuid, uuid) from public;
revoke all on function private.exam_prep_reassign_user_identity_v1(uuid, uuid) from anon;
revoke all on function private.exam_prep_reassign_user_identity_v1(uuid, uuid) from authenticated;

create or replace function public.recover_telegram_user_identity(p_current_uid uuid, p_telegram_user_id text)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_tg text := nullif(trim(p_telegram_user_id), '');
  v_old public.users%rowtype;
  v_target public.users%rowtype;
  v_cnt integer := 0;
  v_moved jsonb := '{}'::jsonb;
  v_exam_prep_moved jsonb := '{}'::jsonb;
begin
  if p_current_uid is null or v_tg is null then
    return jsonb_build_object('ok', false, 'reason', 'bad_args');
  end if;

  if not exists (select 1 from auth.users where id = p_current_uid) then
    return jsonb_build_object('ok', false, 'reason', 'auth_user_not_found');
  end if;

  select *
    into v_old
  from public.users
  where telegram_user_id = v_tg
  for update;

  if not found then
    return jsonb_build_object('ok', false, 'reason', 'old_user_not_found');
  end if;

  if v_old.id = p_current_uid then
    return jsonb_build_object(
      'ok', true,
      'reason', 'already_linked',
      'user_id', p_current_uid,
      'telegram_user_id', v_tg
    );
  end if;

  select *
    into v_target
  from public.users
  where id = p_current_uid
  for update;

  if found and v_target.telegram_user_id is not null and v_target.telegram_user_id <> v_tg then
    return jsonb_build_object('ok', false, 'reason', 'current_uid_has_other_telegram');
  end if;

  -- Existing safety rule: destination UUID must not already own legacy learning data.
  if exists (select 1 from public.practice_attempts where user_id = p_current_uid)
     or exists (select 1 from public.tour_attempts where user_id = p_current_uid)
     or exists (select 1 from public.user_subjects where user_id = p_current_uid)
     or exists (select 1 from public.certificates where user_id = p_current_uid)
     or exists (select 1 from public.ratings_cache where user_id = p_current_uid)
     or exists (select 1 from public.recommendations where user_id = p_current_uid)
     or exists (select 1 from public.user_credentials where user_id = p_current_uid)
     or exists (select 1 from public.user_notifications where user_id = p_current_uid)
     or exists (select 1 from public.video_events where user_id = p_current_uid)
     or exists (select 1 from public.app_events where user_id = p_current_uid)
  then
    return jsonb_build_object('ok', false, 'reason', 'current_uid_not_clean');
  end if;

  -- Release unique fields on the old public.users row.
  update public.users
  set
    telegram_user_id = null,
    login = null,
    auth_email = null
  where id = v_old.id;

  -- Create/update the active public.users row under the current auth UUID.
  if exists (select 1 from public.users where id = p_current_uid) then
    update public.users
    set
      telegram_user_id = v_tg,
      first_name = v_old.first_name,
      last_name = v_old.last_name,
      avatar_url = v_old.avatar_url,
      language_code = coalesce(v_old.language_code, 'ru'),
      is_school_student = v_old.is_school_student,
      region = v_old.region,
      district = v_old.district,
      school = v_old.school,
      class = v_old.class,
      region_id = v_old.region_id,
      district_id = v_old.district_id,
      country_code = v_old.country_code,
      country = v_old.country,
      login = v_old.login,
      auth_email = v_old.auth_email,
      must_change_password = coalesce(v_old.must_change_password, false),
      auth_migrated_at = now()
    where id = p_current_uid;
  else
    insert into public.users (
      id,
      telegram_user_id,
      first_name,
      last_name,
      avatar_url,
      language_code,
      is_school_student,
      region,
      district,
      school,
      class,
      created_at,
      region_id,
      district_id,
      country_code,
      country,
      login,
      auth_email,
      must_change_password,
      auth_migrated_at
    )
    values (
      p_current_uid,
      v_tg,
      v_old.first_name,
      v_old.last_name,
      v_old.avatar_url,
      coalesce(v_old.language_code, 'ru'),
      v_old.is_school_student,
      v_old.region,
      v_old.district,
      v_old.school,
      v_old.class,
      v_old.created_at,
      v_old.region_id,
      v_old.district_id,
      v_old.country_code,
      v_old.country,
      v_old.login,
      v_old.auth_email,
      coalesce(v_old.must_change_password, false),
      now()
    );
  end if;

  -- New continuity step: move every Exam Prep FK identity before deleting old user.
  -- Destination conflicts fail closed; no academic-state triggers are fired.
  v_exam_prep_moved := private.exam_prep_reassign_user_identity_v1(v_old.id, p_current_uid);

  update public.app_events set user_id = p_current_uid where user_id = v_old.id;
  get diagnostics v_cnt = row_count;
  v_moved := v_moved || jsonb_build_object('app_events', v_cnt);

  update public.certificates set user_id = p_current_uid where user_id = v_old.id;
  get diagnostics v_cnt = row_count;
  v_moved := v_moved || jsonb_build_object('certificates', v_cnt);

  update public.practice_attempts set user_id = p_current_uid where user_id = v_old.id;
  get diagnostics v_cnt = row_count;
  v_moved := v_moved || jsonb_build_object('practice_attempts', v_cnt);

  update public.ratings_cache set user_id = p_current_uid where user_id = v_old.id;
  get diagnostics v_cnt = row_count;
  v_moved := v_moved || jsonb_build_object('ratings_cache', v_cnt);

  update public.recommendations set user_id = p_current_uid where user_id = v_old.id;
  get diagnostics v_cnt = row_count;
  v_moved := v_moved || jsonb_build_object('recommendations', v_cnt);

  update public.tour_attempts set user_id = p_current_uid where user_id = v_old.id;
  get diagnostics v_cnt = row_count;
  v_moved := v_moved || jsonb_build_object('tour_attempts', v_cnt);

  update public.user_credentials set user_id = p_current_uid where user_id = v_old.id;
  get diagnostics v_cnt = row_count;
  v_moved := v_moved || jsonb_build_object('user_credentials', v_cnt);

  update public.user_notifications set user_id = p_current_uid where user_id = v_old.id;
  get diagnostics v_cnt = row_count;
  v_moved := v_moved || jsonb_build_object('user_notifications', v_cnt);

  update public.user_subjects set user_id = p_current_uid where user_id = v_old.id;
  get diagnostics v_cnt = row_count;
  v_moved := v_moved || jsonb_build_object('user_subjects', v_cnt);

  update public.video_events set user_id = p_current_uid where user_id = v_old.id;
  get diagnostics v_cnt = row_count;
  v_moved := v_moved || jsonb_build_object('video_events', v_cnt);

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_subjects_history'
      and column_name = 'user_id'
  ) then
    execute 'update public.user_subjects_history set user_id = $1 where user_id = $2'
    using p_current_uid, v_old.id;

    get diagnostics v_cnt = row_count;
    v_moved := v_moved || jsonb_build_object('user_subjects_history', v_cnt);
  end if;

  -- The old public.users row can now be removed safely: the helper above guarantees
  -- that no Exam Prep FK still points to it. The old auth.users row remains untouched.
  delete from public.users
  where id = v_old.id;

  return jsonb_build_object(
    'ok', true,
    'reason', 'recovered',
    'old_user_id', v_old.id,
    'user_id', p_current_uid,
    'telegram_user_id', v_tg,
    'moved', v_moved,
    'exam_prep', v_exam_prep_moved
  );

exception
  when unique_violation then
    return jsonb_build_object(
      'ok', false,
      'reason', 'unique_violation',
      'message', sqlerrm
    );
  when foreign_key_violation then
    return jsonb_build_object(
      'ok', false,
      'reason', 'foreign_key_violation',
      'message', sqlerrm
    );
  when others then
    return jsonb_build_object(
      'ok', false,
      'reason', 'exception',
      'message', sqlerrm
    );
end;
$function$;
