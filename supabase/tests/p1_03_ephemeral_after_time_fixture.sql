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
