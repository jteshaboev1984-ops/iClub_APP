#!/usr/bin/env bash
# Two real PostgreSQL connections, disposable CI database only.
set -euo pipefail
owner='00000000-0000-4000-8000-000000000001'
s_advance='00000000-0000-4000-8000-000000000106'
s_legacy='00000000-0000-4000-8000-000000000107'
psql -v ON_ERROR_STOP=1 <<'SQL'
update private.exam_prep_written_learning_config_v1 set enabled=true where component_code='P1';
insert into private.exam_prep_sessions(id,user_id,component_code,session_type,status,total_items) values
 ('00000000-0000-4000-8000-000000000106','00000000-0000-4000-8000-000000000001','P1','learning','active',1),
 ('00000000-0000-4000-8000-000000000107','00000000-0000-4000-8000-000000000001','P1','learning','active',1);
insert into private.exam_prep_session_items(session_id,item_order,item_kind,written_task_id,item_version) values
 ('00000000-0000-4000-8000-000000000106',1,'written',91,'written:t1'),
 ('00000000-0000-4000-8000-000000000107',1,'written',91,'written:t1');
SQL

# New paper progression wins and holds the same row lock.
psql -v ON_ERROR_STOP=1 > /tmp/math-paper-wins.log 2>&1 <<'SQL' &
begin;
select set_config('iclub.test_uid','00000000-0000-4000-8000-000000000001',true);
select public.advance_exam_prep_written_step_safe_v1(
  '00000000-0000-4000-8000-000000000106',1,'concurrent-next-001');
select pg_sleep(2);
commit;
SQL
new_pid=$!
sleep .4
if psql -v ON_ERROR_STOP=1 > /tmp/math-paper-loser.log 2>&1 <<'SQL'
begin;
insert into private.exam_prep_responses(session_id,item_order,user_id,response_kind,is_correct)
values('00000000-0000-4000-8000-000000000106',1,
 '00000000-0000-4000-8000-000000000001','written',null);
commit;
SQL
then
  echo "FAIL: legacy answer committed after written progression"; exit 1
fi
wait "$new_pid"
grep -q 'exam_prep_written_already_advanced' /tmp/math-paper-loser.log

# Reverse order: legacy response acquires session lock first, new Next must
# reconcile the existing answer rather than writing a second progression event.
psql -v ON_ERROR_STOP=1 > /tmp/math-old-wins.log 2>&1 <<'SQL' &
begin;
insert into private.exam_prep_responses(session_id,item_order,user_id,response_kind,is_correct)
values('00000000-0000-4000-8000-000000000107',1,
 '00000000-0000-4000-8000-000000000001','written',null);
select pg_sleep(2);
commit;
SQL
old_pid=$!
sleep .4
psql -v ON_ERROR_STOP=1 > /tmp/math-reconcile.log 2>&1 <<'SQL'
select set_config('iclub.test_uid','00000000-0000-4000-8000-000000000001',false);
select public.advance_exam_prep_written_step_safe_v1(
  '00000000-0000-4000-8000-000000000107',1,'concurrent-next-002');
SQL
wait "$old_pid"
grep -q 'answered_legacy' /tmp/math-reconcile.log

result=$(psql -Atc "
select concat(
 (select count(*) from private.exam_prep_written_step_advances_v1 where session_id='$s_advance'),
 ':',
 (select count(*) from private.exam_prep_responses where session_id='$s_advance'),
 ':',
 (select count(*) from private.exam_prep_written_step_advances_v1 where session_id='$s_legacy'),
 ':',
 (select count(*) from private.exam_prep_responses where session_id='$s_legacy'));
")
test "$result" = '1:0:0:1' || { echo "FAIL inconsistent ledger: $result"; exit 1; }
echo 'GREEN: PG17 two-connection written legacy/New Next race safety; one outcome per item.'

# Timed/Paper writing must NOT inherit the learning-only session-row lock.
psql -v ON_ERROR_STOP=1 <<'SQL'
insert into private.exam_prep_sessions(id,user_id,component_code,session_type,status,total_items)
values('00000000-0000-4000-8000-000000000108',
       '00000000-0000-4000-8000-000000000001','P1','paper','active',1);
insert into private.exam_prep_session_items(session_id,item_order,item_kind,written_task_id,item_version)
values('00000000-0000-4000-8000-000000000108',1,'written',91,'written:t1');
SQL
psql -v ON_ERROR_STOP=1 > /tmp/math-timed-lock.log 2>&1 <<'SQL' &
begin;
select 1 from private.exam_prep_sessions
where id='00000000-0000-4000-8000-000000000108' for update;
select pg_sleep(2);
commit;
SQL
timed_lock_pid=$!
sleep .4
psql -v ON_ERROR_STOP=1 > /tmp/math-timed-insert.log 2>&1 <<'SQL'
set statement_timeout='1000ms';
insert into private.exam_prep_responses(session_id,item_order,user_id,response_kind,is_correct)
values('00000000-0000-4000-8000-000000000108',1,
 '00000000-0000-4000-8000-000000000001','written',null);
SQL
wait "$timed_lock_pid"
timed_count=$(psql -Atc "select count(*) from private.exam_prep_responses
  where session_id='00000000-0000-4000-8000-000000000108'")
test "$timed_count" = '1' || { echo 'FAIL: timed written save interfered';exit 1; }
echo 'GREEN: timed written inserts do not acquire learning-specific session locks.'

