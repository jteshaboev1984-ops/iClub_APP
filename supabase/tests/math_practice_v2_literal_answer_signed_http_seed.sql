-- iClub #574 · CI-only synthetic learner fixtures for signed local PostgREST.
-- PostgreSQL17 disposable fixture only. Never apply on production.
\set ON_ERROR_STOP on

-- PostgREST v12 sets request.jwt.claims as JSON; preserve legacy GUC support.
create or replace function auth.uid()
returns uuid language sql stable
as $fn$
  select coalesce(
    nullif(current_setting('request.jwt.claim.sub',true),''),
    nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'sub'
  )::uuid;
$fn$;

insert into public.questions(
 id,subject_id,topic,subtopic,qtype,difficulty,correct_answer,is_active,
 question_text_en,question_text_ru,question_text_uz,
 explanation_en,explanation_ru,explanation_uz,time_limit_sec,quality_status
) values
 (995001,5,'Synthetic','CI','input','easy','-4',true,
  'CI only','CI only','CI only','CI only','CI only','CI only',45,'published'),
 (995002,7,'Synthetic','CI','input','easy','-7',true,
  'CI only','CI only','CI only','CI only','CI only','CI only',45,'published');

insert into public.practice_sessions_v4(
 id,user_id,subject_id,client_session_id,question_ids,status
) values
 (995101,'11111111-1111-4111-8111-111111111191',5,'signed-negative',array[995001]::bigint[],'in_progress'),
 (995102,'11111111-1111-4111-8111-111111111191',5,'signed-correct',array[995001]::bigint[],'in_progress'),
 (995103,'11111111-1111-4111-8111-111111111191',7,'signed-other-subject',array[995002]::bigint[],'in_progress');

-- No public read access to protected answer columns, including authenticated.
revoke all on public.questions from anon,authenticated;
revoke all on public.practice_sessions_v4 from anon,authenticated;
grant usage on schema public,auth to anon,authenticated;
-- v5 submit/finalize retain their migration-defined grants.
