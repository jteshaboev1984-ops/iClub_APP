-- #574 Disposable PG17 only. Runs after actual v5 migrations and the staged
-- future-serving selector candidate. Synthetic questions, no protected keys.
\set ON_ERROR_STOP on

insert into public.subjects(id,subject_key,title,type,is_active) values
 (5,'mathematics','Mathematics','main',true),
 (7,'economics','Economics','main',true);
insert into public.seasons(id,season_no,status,title) values
 (1,1,'closed','Season 1'),(2,2,'current','Season 2');
insert into public.tours(id,subject_id,season_id,tour_no,start_date,end_date,is_active) values
 (11,5,1,1,'2026-04-21','2026-04-26',false),
 (12,7,1,1,'2026-04-21','2026-04-26',false),
 (21,5,2,1,null,null,false),
 (22,7,2,1,null,null,false);
insert into public.practice_pools(id,subject_id,tour_no,title,is_active) values
 (501,5,1,'Synthetic Math Practice',true),
 (701,7,1,'Synthetic Econ Practice',true);

insert into public.questions(
 id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
 explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,
 options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,
 explanation_en,book_ref,time_limit_sec,quality_status
)
select 2000+g,5,'Synthetic','Basics',
 case when g<=3 then 'easy' when g<=8 then 'medium' else 'hard' end,
 'mcq','Synthetic','A|B|C|D','A','Synthetic',null,true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D',
 'RU explanation','UZ explanation','EN explanation','Synthetic only',60,'published'
from generate_series(1,10) g;
insert into public.questions(
 id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
 explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,
 options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,
 explanation_en,book_ref,time_limit_sec,quality_status
)
select 7000+g,7,'Synthetic','Basics',
 case when g<=3 then 'easy' when g<=8 then 'medium' else 'hard' end,
 'mcq','Synthetic','A|B|C|D','A','Synthetic',null,true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D',
 'RU explanation','UZ explanation','EN explanation','Synthetic only',60,'published'
from generate_series(1,10) g;
insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)
 select 501,2000+g,g,true from generate_series(1,10) g;
insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)
 select 701,7000+g,g,true from generate_series(1,10) g;

insert into private.practice_v2_question_meta(
  question_id,content_key,release_version,practice_no,primary_skill_code,
  secondary_skill_codes,question_role,source_ref,answer_contract,content_hash,
  qa_math_status,qa_language_status,qa_technical_status,qa_tour_separation_status,
  lifecycle_state,is_runtime_allowed,approved_at,published_at
)
select 2000+g,'s2_synthetic_'||g,'math_p1_practice_v2_2026_10_07',1,
       'ALG_'||((g%4)+1),'{}'::text[],'direct_application','Synthetic',
       '{"kind":"mcq"}'::jsonb,md5(g::text),
       'passed','passed','passed','passed',
       'published',true,now(),now()
from generate_series(1,10) g;

insert into public.practice_attempts(
 id,user_id,subject_id,created_at,is_lab,score,percent,time_seconds
) values(900,'11111111-1111-4111-8111-111111111111',5,
 '2026-10-30T12:00:00Z',false,1,10,50);
insert into public.practice_answers(
 attempt_id,question_id,user_answer,is_correct,time_spent
) values(900,2001,'A',true,12);
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);

do $check$
declare
  a jsonb; b jsonb; econ jsonb; topic jsonb;
  sid bigint; ids bigint[];
begin
  -- Math Tour1 undated in Season2 -> stay on archived S1 rules.
  a:=public.start_practice_session_auto_safe_v5(501,'s2-pre-t1-math-001');
  select question_ids into ids from public.practice_sessions_v4
    where id=(a->>'session_id')::bigint;
  if 2001=any(ids) then
    raise exception 'undated Season2 incorrectly reopened Season1 correct answer';
  end if;
  -- Only Math Tour1 launches. Econ Tour1 S2 stays undated.
  update public.tours
  set start_date='2026-11-01',end_date='2099-12-31',is_active=true
  where id=21;
  b:=public.start_practice_session_auto_safe_v5(501,'s2-new-t1-math-001');
  sid:=(b->>'session_id')::bigint;
  select question_ids into ids from public.practice_sessions_v4 where id=sid;
  if cardinality(ids)<>10 or not(2001=any(ids)) then
    raise exception 'Math S2 failed to re-serve old correct question';
  end if;
  econ:=public.start_practice_session_auto_safe_v5(701,'s2-econ-s1-001');
  if (econ->>'question_count')::integer<>10 then
    raise exception 'Economics previous-season Practice locked by Mathematics S2';
  end if;
  topic:=public.start_practice_topic_drill_safe_v5(
    'economics','Synthetic',null,'s2-econ-topic-s1-001');
  if (topic->>'question_count')::integer<1 then
    raise exception 'Economics Topic Practice locked by Mathematics S2';
  end if;
  -- No past attempt or grade rewriting; even current sessions are new records.
  if (select count(*) from public.practice_attempts)<>1
     or (select count(*) from public.practice_answers)<>1 then
    raise exception 'Practice Season2 selector mutated historical results';
  end if;
  raise notice 'PRACTICE_SUBJECT_TOUR1_SELECTOR_PG17_PASS';
end
$check$;
