-- Isolated PostgreSQL 17 only; 3 synthetic historical mistake answers.
-- Must execute AFTER math_practice_future_only_signed_http_seed_pg17.sql.
\set ON_ERROR_STOP on
insert into public.practice_attempts(id,user_id,subject_id,score,percent,time_seconds)
values
 (880001,'11111111-1111-4111-8111-111111111191',5,0,0,18),
 (880002,'11111111-1111-4111-8111-111111111191',5,0,0,21),
 (880003,'22222222-2222-4222-8222-222222222292',5,0,0,25);
insert into public.practice_answers(attempt_id,question_id,user_answer,is_correct,time_spent)
values (880001,2001,'B',false,18),
       (880002,3001,'B',false,21),
       (880003,2001,'B',false,25);
do $verify$
begin
  if (select count(*) from public.practice_answers
      where attempt_id in (880001,880002,880003))<>3
     or (select count(*) from public.question_version_links
      where old_question_id=2001 and new_question_id=3001)<>1
  then raise exception 'synthetic versioned mistake fixture invalid'; end if;
  raise notice 'MISTAKES_VERSION_HISTORY_FIXTURE_PG17_PASS';
end $verify$;
