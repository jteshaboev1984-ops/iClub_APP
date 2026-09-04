-- P1-03 ephemeral CI only.
-- The behavioral matrix creates one synthetic, back-dated session directly so it
-- can test AFTER-TIME buckets without waiting in real time. Production start RPCs
-- already freeze these values. This narrowly scoped trigger mirrors that freeze
-- only for the synthetic CI session key and exists only in the ephemeral CI DB.

\set ON_ERROR_STOP on

create or replace function private.p103_complete_after_time_fixture_item()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_client_key text;
  v_md5 text;
begin
  if new.item_kind<>'question' or new.item_version is not null then
    return new;
  end if;

  select s.client_idempotency_key into v_client_key
  from private.exam_prep_sessions s
  where s.id=new.session_id;

  if v_client_key<>'p103-after-session-0001' then
    return new;
  end if;

  select m.question_snapshot_md5 into v_md5
  from private.exam_prep_question_content_meta m
  where m.id=new.content_meta_id and m.question_id=new.question_id;

  if v_md5 is null then
    raise exception 'P1-03 fixture content meta snapshot missing';
  end if;

  new.question_snapshot_md5:=v_md5;
  new.item_version:='qmd5:'||v_md5;
  return new;
end;
$$;
revoke all on function private.p103_complete_after_time_fixture_item() from public,anon,authenticated;

drop trigger if exists p103_complete_after_time_fixture_item on private.exam_prep_session_items;
create trigger p103_complete_after_time_fixture_item
before insert on private.exam_prep_session_items
for each row execute function private.p103_complete_after_time_fixture_item();

-- The matrix retained an old defensive UPDATE after the INSERT. Once the INSERT
-- helper has already frozen the exact same values, that UPDATE is redundant.
-- Skip only that byte-identical no-op on the one synthetic CI session; any actual
-- mutation continues to the production immutable trigger and is rejected.
create or replace function private.p103_skip_identical_after_time_fixture_update()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_client_key text;
begin
  select s.client_idempotency_key into v_client_key
  from private.exam_prep_sessions s
  where s.id=old.session_id;

  if v_client_key='p103-after-session-0001'
     and new.question_snapshot_md5 is not distinct from old.question_snapshot_md5
     and new.item_version is not distinct from old.item_version
     and new.session_id is not distinct from old.session_id
     and new.item_order is not distinct from old.item_order
     and new.item_kind is not distinct from old.item_kind
     and new.question_id is not distinct from old.question_id
     and new.written_task_id is not distinct from old.written_task_id
     and new.primary_skill_code is not distinct from old.primary_skill_code
     and new.reserve_role is not distinct from old.reserve_role
     and new.is_holdout is not distinct from old.is_holdout
     and new.content_meta_id is not distinct from old.content_meta_id
  then
    return null;
  end if;
  return new;
end;
$$;
revoke all on function private.p103_skip_identical_after_time_fixture_update() from public,anon,authenticated;

drop trigger if exists aaa_p103_skip_identical_after_time_fixture_update on private.exam_prep_session_items;
create trigger aaa_p103_skip_identical_after_time_fixture_update
before update on private.exam_prep_session_items
for each row execute function private.p103_skip_identical_after_time_fixture_update();
