-- Exam Prep identity recovery continuity v1
-- Purpose: preserve all Exam Prep rows when a Telegram/auth recovery moves a learner
-- from an old public.users UUID to the current auth UUID.
-- Academic facts are not recalculated. Only direct identity FK columns are re-keyed.

create or replace function private.exam_prep_identity_rekey_active_v1()
returns boolean
language sql
stable
set search_path = ''
as $$
  select current_user = 'postgres'
     and coalesce(current_setting('iclub.exam_prep_identity_rekey', true), '') = 'v1'
     and nullif(current_setting('iclub.exam_prep_identity_rekey_old_uid', true), '') is not null
     and nullif(current_setting('iclub.exam_prep_identity_rekey_new_uid', true), '') is not null;
$$;

revoke all on function private.exam_prep_identity_rekey_active_v1() from public;
revoke execute on function private.exam_prep_identity_rekey_active_v1() from anon, authenticated, service_role;

create or replace function private.exam_prep_user_has_identity_refs_v1(p_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
  v_found boolean;
begin
  if p_user_id is null then
    return false;
  end if;

  for r in
    select distinct n.nspname as schema_name,
           t.relname as table_name,
           a.attname as column_name
    from pg_catalog.pg_constraint c
    join pg_catalog.pg_class t on t.oid = c.conrelid
    join pg_catalog.pg_namespace n on n.oid = t.relnamespace
    join unnest(c.conkey) with ordinality ck(attnum, ord) on true
    join unnest(c.confkey) with ordinality fk(attnum, ord) on fk.ord = ck.ord
    join pg_catalog.pg_attribute a on a.attrelid = c.conrelid and a.attnum = ck.attnum
    where c.contype = 'f'
      and c.confrelid = 'public.users'::regclass
      and n.nspname = 'private'
      and t.relname like 'exam_prep\_%' escape '\'
    order by n.nspname, t.relname, a.attname
  loop
    execute format(
      'select exists(select 1 from %I.%I where %I = $1)',
      r.schema_name, r.table_name, r.column_name
    ) into v_found using p_user_id;

    if v_found then
      return true;
    end if;
  end loop;

  return false;
end;
$$;

revoke all on function private.exam_prep_user_has_identity_refs_v1(uuid) from public;
revoke execute on function private.exam_prep_user_has_identity_refs_v1(uuid) from anon, authenticated, service_role;

-- Immutable Exam Prep facts stay immutable. The only exception is a trusted identity
-- re-key, and even there the trigger verifies that every non-identity field is byte-for-byte
-- equivalent at the row JSON level and that changed identity columns move old UUID -> new UUID.
create or replace function private.exam_prep_block_immutable_mutation_v1()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_identity_cols text[];
  v_col text;
  v_old_payload jsonb;
  v_new_payload jsonb;
  v_old_uid text;
  v_new_uid text;
  v_changed boolean := false;
begin
  if tg_op = 'UPDATE' and private.exam_prep_identity_rekey_active_v1() then
    v_old_uid := nullif(current_setting('iclub.exam_prep_identity_rekey_old_uid', true), '');
    v_new_uid := nullif(current_setting('iclub.exam_prep_identity_rekey_new_uid', true), '');

    select array_agg(distinct a.attname order by a.attname)
      into v_identity_cols
    from pg_catalog.pg_constraint c
    join unnest(c.conkey) with ordinality ck(attnum, ord) on true
    join unnest(c.confkey) with ordinality fk(attnum, ord) on fk.ord = ck.ord
    join pg_catalog.pg_attribute a on a.attrelid = c.conrelid and a.attnum = ck.attnum
    where c.contype = 'f'
      and c.conrelid = tg_relid
      and c.confrelid = 'public.users'::regclass;

    if coalesce(array_length(v_identity_cols, 1), 0) > 0
       and v_old_uid is not null
       and v_new_uid is not null then
      v_old_payload := to_jsonb(old);
      v_new_payload := to_jsonb(new);

      foreach v_col in array v_identity_cols loop
        if (v_old_payload -> v_col) is distinct from (v_new_payload -> v_col) then
          if nullif(v_old_payload ->> v_col, '') is distinct from v_old_uid
             or nullif(v_new_payload ->> v_col, '') is distinct from v_new_uid then
            raise exception 'immutable_exam_prep_fact';
          end if;
          v_changed := true;
        end if;
        v_old_payload := v_old_payload - v_col;
        v_new_payload := v_new_payload - v_col;
      end loop;

      if v_changed and v_old_payload = v_new_payload then
        return new;
      end if;
    end if;
  end if;

  raise exception 'immutable_exam_prep_fact';
end;
$$;

-- These four stage projections used to fire on every UPDATE. During identity-only re-key
-- they must not recalculate stages/readiness or emit recommendations. Normal INSERT/UPDATE
-- behavior is unchanged outside the tightly scoped trusted re-key context.
drop trigger if exists exam_prep_readiness_projection_v1 on private.exam_prep_stage_states;
create trigger exam_prep_readiness_projection_v1
before insert or update on private.exam_prep_stage_states
for each row
when (not private.exam_prep_identity_rekey_active_v1())
execute function private.exam_prep_apply_readiness_projection_v1();

drop trigger if exists exam_prep_stage0_gate_projection_v1 on private.exam_prep_stage_states;
create trigger exam_prep_stage0_gate_projection_v1
before insert or update on private.exam_prep_stage_states
for each row
when (not private.exam_prep_identity_rekey_active_v1())
execute function private.exam_prep_apply_stage0_gate_v1();

drop trigger if exists exam_prep_maybe_recommend_readiness_v1 on private.exam_prep_stage_states;
create trigger exam_prep_maybe_recommend_readiness_v1
after insert or update on private.exam_prep_stage_states
for each row
when (not private.exam_prep_identity_rekey_active_v1())
execute function private.exam_prep_maybe_recommend_readiness_v1();

drop trigger if exists exam_prep_stage_access_sync_v1 on private.exam_prep_stage_states;
create trigger exam_prep_stage_access_sync_v1
after insert or update on private.exam_prep_stage_states
for each row
when (not private.exam_prep_identity_rekey_active_v1())
execute function private.exam_prep_sync_access_gate_stage_v1();

create or replace function private.exam_prep_rekey_user_identity_v1(
  p_old_user_id uuid,
  p_new_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
  v_count integer := 0;
  v_total integer := 0;
  v_moved jsonb := '{}'::jsonb;
begin
  if p_old_user_id is null or p_new_user_id is null or p_old_user_id = p_new_user_id then
    raise exception 'exam_prep_identity_rekey_bad_args';
  end if;

  if not exists (select 1 from public.users where id = p_old_user_id) then
    raise exception 'exam_prep_identity_rekey_old_user_missing';
  end if;

  if not exists (select 1 from public.users where id = p_new_user_id) then
    raise exception 'exam_prep_identity_rekey_new_user_missing';
  end if;

  if private.exam_prep_user_has_identity_refs_v1(p_new_user_id) then
    raise exception 'exam_prep_identity_rekey_target_not_clean';
  end if;

  perform set_config('iclub.exam_prep_identity_rekey', 'v1', true);
  perform set_config('iclub.exam_prep_identity_rekey_old_uid', p_old_user_id::text, true);
  perform set_config('iclub.exam_prep_identity_rekey_new_uid', p_new_user_id::text, true);

  begin
    for r in
      select distinct n.nspname as schema_name,
             t.relname as table_name,
             a.attname as column_name
      from pg_catalog.pg_constraint c
      join pg_catalog.pg_class t on t.oid = c.conrelid
      join pg_catalog.pg_namespace n on n.oid = t.relnamespace
      join unnest(c.conkey) with ordinality ck(attnum, ord) on true
      join unnest(c.confkey) with ordinality fk(attnum, ord) on fk.ord = ck.ord
      join pg_catalog.pg_attribute a on a.attrelid = c.conrelid and a.attnum = ck.attnum
      where c.contype = 'f'
        and c.confrelid = 'public.users'::regclass
        and n.nspname = 'private'
        and t.relname like 'exam_prep\_%' escape '\'
      order by
        case t.relname
          when 'exam_prep_beta_consents' then 0
          when 'exam_prep_beta_members' then 1
          else 10
        end,
        t.relname,
        a.attname
    loop
      execute format(
        'update %I.%I set %I = $1 where %I = $2',
        r.schema_name, r.table_name, r.column_name, r.column_name
      ) using p_new_user_id, p_old_user_id;
      get diagnostics v_count = row_count;
      v_total := v_total + v_count;
      if v_count > 0 then
        v_moved := v_moved || jsonb_build_object(r.table_name || '.' || r.column_name, v_count);
      end if;
    end loop;
  exception when others then
    perform set_config('iclub.exam_prep_identity_rekey', 'off', true);
    perform set_config('iclub.exam_prep_identity_rekey_old_uid', '', true);
    perform set_config('iclub.exam_prep_identity_rekey_new_uid', '', true);
    raise;
  end;

  perform set_config('iclub.exam_prep_identity_rekey', 'off', true);
  perform set_config('iclub.exam_prep_identity_rekey_old_uid', '', true);
  perform set_config('iclub.exam_prep_identity_rekey_new_uid', '', true);

  if private.exam_prep_user_has_identity_refs_v1(p_old_user_id) then
    raise exception 'exam_prep_identity_rekey_incomplete';
  end if;

  return jsonb_build_object(
    'ok', true,
    'total_identity_refs_moved', v_total,
    'moved', v_moved
  );
end;
$$;

revoke all on function private.exam_prep_rekey_user_identity_v1(uuid,uuid) from public;
revoke execute on function private.exam_prep_rekey_user_identity_v1(uuid,uuid) from anon, authenticated, service_role;

-- Preserve the existing Telegram recovery contract and legacy moves, with two additions:
-- 1) the destination auth UUID must also be clean across every current Exam Prep FK;
-- 2) all Exam Prep identity references are re-keyed before the old public.users row is deleted.
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
  v_exam_prep jsonb := '{}'::jsonb;
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

  -- The destination UUID must be empty in both legacy and Exam Prep state.
  -- We never merge two learner histories during automated recovery.
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
     or private.exam_prep_user_has_identity_refs_v1(p_current_uid)
  then
    return jsonb_build_object('ok', false, 'reason', 'current_uid_not_clean');
  end if;

  -- Free unique identity fields on the old public.users row.
  update public.users
  set
    telegram_user_id = null,
    login = null,
    auth_email = null
  where id = v_old.id;

  -- Create/update active public.users row under the current auth UUID.
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

  v_exam_prep := private.exam_prep_rekey_user_identity_v1(v_old.id, p_current_uid);
  v_moved := v_moved || jsonb_build_object(
    'exam_prep', jsonb_build_object(
      'total_identity_refs_moved', coalesce((v_exam_prep->>'total_identity_refs_moved')::integer, 0),
      'tables', coalesce(v_exam_prep->'moved', '{}'::jsonb)
    )
  );

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

  if private.exam_prep_user_has_identity_refs_v1(v_old.id) then
    raise exception 'exam_prep_identity_rekey_incomplete';
  end if;

  -- Old public.users row is no longer active. Old auth.users is intentionally retained.
  delete from public.users
  where id = v_old.id;

  return jsonb_build_object(
    'ok', true,
    'reason', 'recovered',
    'old_user_id', v_old.id,
    'user_id', p_current_uid,
    'telegram_user_id', v_tg,
    'moved', v_moved
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

comment on function private.exam_prep_rekey_user_identity_v1(uuid,uuid) is
  'Trusted identity-only re-key for Exam Prep during Telegram/auth recovery. Dynamically covers every private.exam_prep_* FK to public.users, preserves academic fields, and refuses merges.';
comment on function public.recover_telegram_user_identity(uuid,text) is
  'Telegram identity recovery with legacy + Exam Prep continuity. Destination histories are never merged; Exam Prep rows are re-keyed before deleting the old public.users row.';
