-- Full disposable publish -> rollback -> restage -> publish -> cleanup rehearsal.
-- Requires the rehearsal fixture plus metadata/audit/release migrations.

\set ON_ERROR_STOP on

insert into public.subjects(id,subject_key,is_active)
values
  (5,'mathematics',true),
  (6,'economics',true);

insert into public.practice_pools(id,subject_id,tour_no,is_active)
select 500+g,5,g,true from generate_series(1,7) g;

-- Non-Mathematics sentinel: this entire Practice state must survive a Mathematics-only reset.
insert into public.practice_pools(id,subject_id,tour_no,is_active)
values(601,6,1,true);

insert into public.questions(id,subject_id,is_active,quality_status)
values(9500,6,true,'published');

insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)
values(601,9500,1,true);

insert into public.practice_attempts(id,user_id,subject_id,is_lab)
values(900,'00000000-0000-0000-0000-000000000002',6,false);

insert into public.practice_answers(id,attempt_id,question_id,user_answer,is_correct,created_at)
values(900,900,9500,'C',true,'2026-10-06T08:00:00Z');

insert into public.practice_sessions_v4(id,user_id,subject_id,status)
values(900,'00000000-0000-0000-0000-000000000002',6,'active');

insert into public.practice_drill_sessions_v4(id,user_id,subject_id,status)
values(900,'00000000-0000-0000-0000-000000000002',6,'active');

insert into public.practice_review_events_v1(id,attempt_id)
values(900,900);

insert into public.user_answer_diagnosis(id,subject_id,practice_answer_id,question_id,attempt_type)
values(900,6,900,9500,'practice');

insert into public.recommendations(id,user_id,subject_id,source_type,topic,created_at)
values(900,'00000000-0000-0000-0000-000000000002',6,'practice','Economics sentinel','2026-10-06T08:01:00Z');

insert into public.learning_roadmaps(id,user_id,subject_id,source_type,payload,created_at)
values(900,'00000000-0000-0000-0000-000000000002',6,'practice_attempt','{"protected_other_subject":true}','2026-10-06T08:02:00Z');

insert into public.questions(id,subject_id,is_active,quality_status)
select g,5,true,'published'
from generate_series(1001,1490) g;

insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)
select 500+(((g-1001)%7)+1),g,((g-1001)/7)+1,true
from generate_series(1001,1490) g;

with counts(practice_no,n) as (
  values (1,68),(2,80),(3,68),(4,77),(5,66),(6,70),(7,66)
),
expanded as (
  select c.practice_no,x.order_no
  from counts c
  cross join lateral generate_series(1,c.n) x(order_no)
),
numbered as (
  select 2000+row_number() over(order by practice_no,order_no) as question_id,
         practice_no,order_no
  from expanded
)
insert into public.questions(id,subject_id,is_active,quality_status)
select question_id,5,false,'draft' from numbered;

with counts(practice_no,n) as (
  values (1,68),(2,80),(3,68),(4,77),(5,66),(6,70),(7,66)
),
expanded as (
  select c.practice_no,x.order_no
  from counts c
  cross join lateral generate_series(1,c.n) x(order_no)
),
numbered as (
  select 2000+row_number() over(order by practice_no,order_no) as question_id,
         practice_no,order_no
  from expanded
)
insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)
select 500+practice_no,question_id,order_no,false from numbered;

with counts(practice_no,n) as (
  values (1,68),(2,80),(3,68),(4,77),(5,66),(6,70),(7,66)
),
expanded as (
  select c.practice_no,x.order_no
  from counts c
  cross join lateral generate_series(1,c.n) x(order_no)
),
numbered as (
  select 2000+row_number() over(order by practice_no,order_no) as question_id,
         practice_no,order_no
  from expanded
)
insert into private.practice_v2_question_meta(
  question_id,content_key,release_version,practice_no,primary_skill_code,
  secondary_skill_codes,question_role,source_ref,answer_contract,content_hash,
  qa_math_status,qa_language_status,qa_technical_status,qa_tour_separation_status,
  lifecycle_state,is_runtime_allowed,approved_at
)
select
  question_id,
  'fixture_p'||practice_no||'_q'||order_no,
  'math_p1_practice_v2_2026_10_07',
  practice_no,
  'SKILL_'||practice_no,
  '{}'::text[],
  'direct_application',
  'fixture',
  '{"kind":"fixture"}'::jsonb,
  md5(question_id::text),
  'passed','passed','passed','passed',
  'approved',false,now()
from numbered;

insert into private.practice_v2_diagnostic_catalog(
  diagnostic_code,release_version,skill_code,mistake_type,inference_strength,
  feedback_ru,feedback_uz,feedback_en,next_action_ru,next_action_uz,next_action_en,
  approval_status,is_runtime_allowed,content_hash
)
select
  'D'||lpad(g::text,3,'0'),
  'math_p1_practice_v2_2026_10_07',
  'SKILL_'||((g-1)%7+1),
  'fixture',
  'specific',
  'ru','uz','en','ru next','uz next','en next',
  'approved',false,md5('d'||g)
from generate_series(1,201) g;

insert into public.question_answer_diagnostics(question_id,quality_status)
select 2001+((g-1)%495),'draft'
from generate_series(1,868) g;

-- Protected Tour state: four historical Tour links to old Practice questions,
-- plus a current Tour with attempts/answers/session-answer, recommendation,
-- roadmap and certificate.
insert into public.questions(id,subject_id,is_active,quality_status)
values(9001,5,true,'published');

insert into public.tours(id,subject_id,season_id,tour_no,start_date,end_date,is_active)
values
  (10,5,1,2,'2026-01-01','2026-01-02',false),
  (11,5,2,1,'2026-10-01','2026-10-31',true);

insert into public.tour_questions(tour_id,question_id,order_no,is_active)
values
  (10,1001,1,false),(10,1002,2,false),(10,1003,3,false),(10,1004,4,false),
  (11,9001,1,true);

insert into public.tour_attempts(id,user_id,tour_id,score,percent,total_time,status,created_at)
values(1,'00000000-0000-0000-0000-000000000001',11,1,100,30,'completed','2026-10-06T10:00:00Z');

insert into public.tour_answers(id,attempt_id,question_id,user_answer,answered,is_correct,time_spent,finish_reason,created_at)
values(1,1,9001,'A',true,true,30,'submitted','2026-10-06T10:00:30Z');

insert into public.tour_session_answers_v4(attempt_id,question_id,user_answer,answered,is_correct,time_spent,finish_reason,answered_at)
values(1,9001,'A',true,true,30,'submitted','2026-10-06T10:00:30Z');

insert into public.recommendations(user_id,subject_id,source_type,season_id,tour_no,topic,subtopic,book_id,book_reference,created_at)
values
 ('00000000-0000-0000-0000-000000000001',5,'tour',2,1,'Tour topic','Tour subtopic',1,'Tour ref','2026-10-06T10:01:00Z'),
 ('00000000-0000-0000-0000-000000000001',5,'practice',null,null,'Old Practice','Old Practice',1,'Practice ref','2026-10-06T09:00:00Z');

insert into public.learning_roadmaps(user_id,subject_id,source_type,payload,created_at)
values
 ('00000000-0000-0000-0000-000000000001',5,'tour_attempt','{"protected":true}','2026-10-06T10:02:00Z'),
 ('00000000-0000-0000-0000-000000000001',5,'practice_attempt','{"legacy":true}','2026-10-06T09:01:00Z'),
 ('00000000-0000-0000-0000-000000000001',5,'practice_ai_diagnosis','{"legacy":true}','2026-10-06T09:02:00Z');

insert into public.certificates(user_id,subject_id,certificate_key,created_at)
values('00000000-0000-0000-0000-000000000001',5,'tour-certificate','2026-10-06T10:03:00Z');

insert into public.ratings_cache(user_id,subject_id,score)
values('00000000-0000-0000-0000-000000000001',5,123);

-- Legacy Practice state that must be intentionally reset.
insert into public.practice_attempts(id,user_id,subject_id,is_lab)
values(1,'00000000-0000-0000-0000-000000000001',5,false);

insert into public.practice_answers(id,attempt_id,question_id,user_answer,is_correct,created_at)
values(1,1,1005,'B',false,'2026-10-06T09:00:30Z');

insert into public.practice_sessions_v4(id,user_id,subject_id,status)
values(1,'00000000-0000-0000-0000-000000000001',5,'active');

insert into public.practice_drill_sessions_v4(id,user_id,subject_id,status)
values(1,'00000000-0000-0000-0000-000000000001',5,'active');

insert into public.practice_review_events_v1(attempt_id) values(1);

insert into public.user_answer_diagnosis(subject_id,practice_answer_id,question_id,attempt_type)
values(5,1,1005,'practice');

insert into private.exam_prep_legacy_evidence_references(question_id,legacy_source,legacy_attempt_id)
values(1005,'practice_answers',1);

insert into private.exam_prep_question_skill_map(question_id) values(1005);

do $baseline$
declare
  v_count integer;
  v_snapshot jsonb;
begin
  select count(*) into v_count
  from public.practice_pool_questions ppq
  join public.practice_pools p on p.id=ppq.pool_id
  where p.subject_id=5 and p.tour_no between 1 and 7 and p.is_active and ppq.is_active;
  if v_count<>490 then raise exception 'fixture_old_memberships_expected_490_found_%',v_count; end if;

  select count(*) into v_count
  from private.practice_v2_question_meta
  where release_version='math_p1_practice_v2_2026_10_07';
  if v_count<>495 then raise exception 'fixture_v2_meta_expected_495_found_%',v_count; end if;

  v_snapshot:=private.practice_v2_tour_invariant_snapshot_v1(5);
  if coalesce((v_snapshot->>'tour_questions_count')::integer,0)<>5 then
    raise exception 'fixture_tour_question_snapshot_bad_%',v_snapshot;
  end if;
  if coalesce((v_snapshot->>'tour_recommendations_count')::integer,0)<>1
     or coalesce((v_snapshot->>'tour_roadmaps_count')::integer,0)<>1
     or coalesce((v_snapshot->>'certificates_count')::integer,0)<>1 then
    raise exception 'fixture_protected_snapshot_incomplete_%',v_snapshot;
  end if;
end;
$baseline$;

-- Definition gate first.
\ir math_practice_v2_atomic_release_switch_v1.sql

-- First publish and the exact repo audit.
select private.publish_math_practice_v2_release_v1('math_p1_practice_v2_2026_10_07');
\ir ../preflight/math_practice_v2_post_publish_audit.sql

-- Simulate learner activity on the new v2 bank, then prove rollback removes it.
insert into public.practice_attempts(id,user_id,subject_id,is_lab)
values(2,'00000000-0000-0000-0000-000000000001',5,false);
insert into public.practice_answers(id,attempt_id,question_id,user_answer,is_correct)
values(2,2,2001,'A',true);
insert into public.practice_sessions_v4(id,user_id,subject_id,status)
values(2,'00000000-0000-0000-0000-000000000001',5,'active');
insert into public.practice_drill_sessions_v4(id,user_id,subject_id,status)
values(2,'00000000-0000-0000-0000-000000000001',5,'active');
insert into public.practice_review_events_v1(attempt_id) values(2);
insert into public.user_answer_diagnosis(subject_id,practice_answer_id,question_id,attempt_type)
values(5,2,2001,'practice');
insert into public.recommendations(user_id,subject_id,source_type,topic)
values('00000000-0000-0000-0000-000000000001',5,'practice','New v2 Practice');
insert into public.learning_roadmaps(user_id,subject_id,source_type,payload)
values('00000000-0000-0000-0000-000000000001',5,'practice_attempt','{"v2":true}');

select private.rollback_math_practice_v2_release_v1('math_p1_practice_v2_2026_10_07');
\ir ../preflight/math_practice_v2_post_rollback_audit.sql

-- Recreate the pre-publish staged state solely to exercise the cleanup path
-- in this disposable database.
update public.questions q
set is_active=false,quality_status='draft'
where q.id in (
  select m.question_id from private.practice_v2_question_meta m
  where m.release_version='math_p1_practice_v2_2026_10_07'
);

update public.question_answer_diagnostics d
set quality_status='draft'
where d.question_id in (
  select m.question_id from private.practice_v2_question_meta m
  where m.release_version='math_p1_practice_v2_2026_10_07'
);

update private.practice_v2_question_meta
set lifecycle_state='approved',is_runtime_allowed=false,published_at=null
where release_version='math_p1_practice_v2_2026_10_07';

update private.practice_v2_diagnostic_catalog
set approval_status='approved',is_runtime_allowed=false
where release_version='math_p1_practice_v2_2026_10_07';

select private.publish_math_practice_v2_release_v1('math_p1_practice_v2_2026_10_07');
\ir ../preflight/math_practice_v2_post_publish_audit.sql

select private.cleanup_math_practice_v1_questions_v1('math_p1_practice_v2_2026_10_07');
\ir ../preflight/math_practice_v2_post_cleanup_audit.sql

do $final$
declare
  v_count integer;
  v_deleted integer;
  v_retained integer;
begin
  select coalesce((notes->>'legacy_questions_deleted')::integer,0),
         coalesce((notes->>'legacy_questions_retained')::integer,0)
  into v_deleted,v_retained
  from private.practice_v2_release_switch_audit
  where release_version='math_p1_practice_v2_2026_10_07';

  if v_deleted<>486 or v_retained<>4 then
    raise exception 'cleanup_expected_486_deleted_4_retained_found_%_%',v_deleted,v_retained;
  end if;

  select count(*) into v_count from public.questions where id between 1001 and 1490;
  if v_count<>4 then raise exception 'cleanup_old_questions_expected_4_found_%',v_count; end if;

  select count(*) into v_count
  from public.questions
  where id in (1001,1002,1003,1004);
  if v_count<>4 then raise exception 'cleanup_tour_linked_questions_missing'; end if;

  select count(*) into v_count from public.ratings_cache where subject_id=5;
  if v_count<>1 then raise exception 'protected_ratings_cache_changed'; end if;

  select count(*) into v_count from public.certificates where subject_id=5;
  if v_count<>1 then raise exception 'protected_certificate_changed'; end if;

  select count(*) into v_count from public.recommendations where subject_id=5 and source_type='tour';
  if v_count<>1 then raise exception 'protected_tour_recommendation_changed'; end if;

  select count(*) into v_count from public.learning_roadmaps where subject_id=5 and source_type='tour_attempt';
  if v_count<>1 then raise exception 'protected_tour_roadmap_changed'; end if;

  -- Mathematics reset/rollback/cleanup must never spill into another subject.
  select count(*) into v_count from public.practice_pool_questions ppq
  join public.practice_pools p on p.id=ppq.pool_id
  where p.subject_id=6 and ppq.question_id=9500 and ppq.is_active is true;
  if v_count<>1 then raise exception 'other_subject_practice_membership_changed'; end if;

  select count(*) into v_count from public.practice_attempts
  where id=900 and subject_id=6;
  if v_count<>1 then raise exception 'other_subject_practice_attempt_changed'; end if;

  select count(*) into v_count from public.practice_answers
  where id=900 and attempt_id=900 and question_id=9500 and is_correct is true;
  if v_count<>1 then raise exception 'other_subject_practice_answer_changed'; end if;

  select count(*) into v_count from public.practice_sessions_v4
  where id=900 and subject_id=6 and status='active';
  if v_count<>1 then raise exception 'other_subject_practice_session_changed'; end if;

  select count(*) into v_count from public.practice_drill_sessions_v4
  where id=900 and subject_id=6 and status='active';
  if v_count<>1 then raise exception 'other_subject_practice_drill_changed'; end if;

  select count(*) into v_count from public.practice_review_events_v1
  where id=900 and attempt_id=900;
  if v_count<>1 then raise exception 'other_subject_practice_review_changed'; end if;

  select count(*) into v_count from public.user_answer_diagnosis
  where id=900 and subject_id=6 and question_id=9500;
  if v_count<>1 then raise exception 'other_subject_practice_diagnosis_changed'; end if;

  select count(*) into v_count from public.recommendations
  where id=900 and subject_id=6 and source_type='practice' and topic='Economics sentinel';
  if v_count<>1 then raise exception 'other_subject_practice_recommendation_changed'; end if;

  select count(*) into v_count from public.learning_roadmaps
  where id=900 and subject_id=6 and source_type='practice_attempt'
    and payload='{"protected_other_subject":true}'::jsonb;
  if v_count<>1 then raise exception 'other_subject_practice_roadmap_changed'; end if;
end;
$final$;

select 'MATHEMATICS_PRACTICE_V2_RELEASE_REHEARSAL_GREEN' as result;
