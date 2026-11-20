-- Disposable PostgreSQL17-only, wholly invented S1 Math / S2 Math / S2 Chemistry.
-- Reproduce real original privileged preflight returning 20 questions BEFORE attempt.
DO $dbguard$ BEGIN
 IF current_database()<>'iclub_math_s2_preflight_synthetic' THEN
 RAISE EXCEPTION 'MATH_S2_PREFLIGHT_DISPOSABLE_ONLY'; END IF;
END $dbguard$;
DO $roles$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN CREATE ROLE anon NOLOGIN; END IF;
END $roles$;
CREATE SCHEMA auth;
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $u$
  SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid;
$u$;
CREATE TABLE public.seasons(id bigint PRIMARY KEY,season_no smallint NOT NULL);
CREATE TABLE public.tours(id bigint PRIMARY KEY,subject_id bigint NOT NULL,
 season_id bigint NOT NULL REFERENCES public.seasons(id),
 is_active boolean NOT NULL, start_date date,end_date date);
CREATE TABLE public.users(id uuid PRIMARY KEY,is_school_student boolean NOT NULL);
CREATE TABLE public.user_subjects(user_id uuid NOT NULL,subject_id bigint NOT NULL,mode text NOT NULL);
CREATE TABLE public.questions(
 id bigint PRIMARY KEY,subject_id bigint NOT NULL,is_active boolean NOT NULL,
 time_limit_sec int,question_text text,question_text_ru text,question_text_uz text,
 question_text_en text,options_text text,options_text_ru text,options_text_uz text,
 options_text_en text,image_url text,topic text,subtopic text,difficulty text,
 qtype text,book_ref text);
CREATE TABLE public.tour_questions(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 tour_id bigint NOT NULL, question_id bigint NOT NULL, order_no int NOT NULL,
 is_active boolean NOT NULL);
INSERT INTO public.seasons VALUES (901,1),(902,2);
INSERT INTO public.tours VALUES
(9101,5,901,true,(now() at time zone 'Asia/Tashkent')::date,(now() at time zone 'Asia/Tashkent')::date),
(9102,5,902,true,(now() at time zone 'Asia/Tashkent')::date,(now() at time zone 'Asia/Tashkent')::date),
(9103,4,902,true,(now() at time zone 'Asia/Tashkent')::date,(now() at time zone 'Asia/Tashkent')::date);
INSERT INTO public.users VALUES ('00000000-0000-4000-8000-000000009202',true);
INSERT INTO public.user_subjects VALUES
 ('00000000-0000-4000-8000-000000009202',5,'competitive'),
 ('00000000-0000-4000-8000-000000009202',4,'competitive');
INSERT INTO public.questions (id,subject_id,is_active,time_limit_sec,question_text,
 question_text_ru,question_text_uz,question_text_en,options_text,options_text_ru,
 options_text_uz,options_text_en,topic,subtopic,difficulty,qtype,book_ref)
 SELECT 990000+t.n*100+q.n,t.subject_id,true,60,'SYNTH_RU','SYNTH_RU',
 'SYNTH_UZ','SYNTH_EN','["A","B","C","D"]','["A","B","C","D"]',
 '["A","B","C","D"]','["A","B","C","D"]','synthetic','synthetic','easy','mcq','synthetic'
 FROM (VALUES(1,5),(2,5),(3,4)) t(n,subject_id)
 CROSS JOIN generate_series(1,20) q(n);
INSERT INTO public.tour_questions (tour_id,question_id,order_no,is_active)
 SELECT 9100+t.n,990000+t.n*100+q.n,q.n,true
 FROM generate_series(1,3) t(n) CROSS JOIN generate_series(1,20) q(n);

-- Exact original production preflight SQL, with no protected bank content.
CREATE OR REPLACE FUNCTION public.get_tour_preflight_questions_safe_v4(p_tour_id bigint)
 RETURNS TABLE(order_no integer, id bigint, subject_id bigint, time_limit_sec integer, question_text text, question_text_ru text, question_text_uz text, question_text_en text, options_text text, options_text_ru text, options_text_uz text, options_text_en text, image_url text, topic text, subtopic text, difficulty text, qtype text, book_ref text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_tour public.tours%rowtype;
  v_today date := (now() at time zone 'Asia/Tashkent')::date;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;

  if p_tour_id is null or p_tour_id <= 0 then
    raise exception 'invalid_tour_id' using errcode='22023';
  end if;

  select * into v_tour
  from public.tours t
  where t.id=p_tour_id
    and t.is_active is true;

  if v_tour.id is null then
    raise exception 'tour_not_found_or_inactive' using errcode='P0002';
  end if;

  if v_tour.start_date is null
     or v_tour.end_date is null
     or v_today < v_tour.start_date
     or v_today > v_tour.end_date then
    raise exception 'tour_not_open' using errcode='55000';
  end if;

  if not exists(
    select 1 from public.users u
    where u.id=v_uid and coalesce(u.is_school_student,false) is true
  ) then
    raise exception 'tour_requires_school_student' using errcode='42501';
  end if;

  if not exists(
    select 1 from public.user_subjects us
    where us.user_id=v_uid
      and us.subject_id=v_tour.subject_id
      and us.mode='competitive'
  ) then
    raise exception 'tour_subject_not_competitive_for_user' using errcode='42501';
  end if;

  if (
    select count(*)
    from public.tour_questions tq
    join public.questions q on q.id=tq.question_id and q.is_active is true
    where tq.tour_id=p_tour_id
      and tq.is_active is true
      and q.subject_id=v_tour.subject_id
  ) <> 20 then
    raise exception 'tour_question_count_not_20' using errcode='55000';
  end if;

  return query
  select
    tq.order_no::integer,
    q.id,
    q.subject_id,
    q.time_limit_sec,
    q.question_text,
    q.question_text_ru,
    q.question_text_uz,
    q.question_text_en,
    q.options_text,
    q.options_text_ru,
    q.options_text_uz,
    q.options_text_en,
    q.image_url,
    q.topic,
    q.subtopic,
    q.difficulty,
    q.qtype,
    q.book_ref
  from public.tour_questions tq
  join public.questions q on q.id=tq.question_id and q.is_active is true
  where tq.tour_id=p_tour_id
    and tq.is_active is true
    and q.subject_id=v_tour.subject_id
  order by tq.order_no,tq.id;
end;
$function$;
REVOKE ALL ON FUNCTION public.get_tour_preflight_questions_safe_v4(bigint) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_tour_preflight_questions_safe_v4(bigint) TO authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000009202',false);
SET ROLE authenticated;
DO $baseline$
BEGIN
 IF (SELECT count(*) FROM public.get_tour_preflight_questions_safe_v4(9102))<>20
 THEN RAISE EXCEPTION 'BASELINE_VULNERABILITY_NOT_REPRODUCED'; END IF;
 IF (SELECT count(*) FROM public.get_tour_preflight_questions_safe_v4(9101))<>20
  OR (SELECT count(*) FROM public.get_tour_preflight_questions_safe_v4(9103))<>20
 THEN RAISE EXCEPTION 'UNRELATED_ORIGINAL_20_QUESTIONS_NOT_AVAILABLE'; END IF;
 RAISE NOTICE 'UNISSUED_S2_MATH_20_QUESTIONS_PREFLIGHT_LEAK_REPRODUCED';
END $baseline$;
RESET ROLE;

-- Candidate holds a strict MD5 pin to the original production function.
\i supabase/candidates/math_s2_preflight_unissued_20q_deny_v1_hold.sql

SET ROLE authenticated;
DO $check$
BEGIN
 BEGIN
  PERFORM id FROM public.get_tour_preflight_questions_safe_v4(9102);
  RAISE EXCEPTION 'S2_MATH_UNISSUED_20_QUESTIONS_STILL_RETURNED';
 EXCEPTION WHEN SQLSTATE '55000' THEN
  IF SQLERRM <> 'math_s2_questions_require_started_attempt' THEN
   RAISE EXCEPTION 'WRONG_S2_PREFLIGHT_FAILURE'; END IF;
 END;
 IF (SELECT count(*) FROM public.get_tour_preflight_questions_safe_v4(9101))<>20
  OR (SELECT count(*) FROM public.get_tour_preflight_questions_safe_v4(9103))<>20
 THEN RAISE EXCEPTION 'S1_OR_CHEMISTRY_REGRESSION'; END IF;
 IF (SELECT count(*) FROM public.questions)<>60
  OR (SELECT count(*) FROM public.tour_questions)<>60
 THEN RAISE EXCEPTION 'QUESTION_BANK_ROWS_CHANGED'; END IF;
 RAISE NOTICE 'S2_UNISSUED_20Q_DENIED_S1_AND_CHEMISTRY_UNCHANGED';
END $check$;
RESET ROLE;
DO $secure$
BEGIN
 IF has_function_privilege('anon','public.get_tour_preflight_questions_safe_v4(bigint)','EXECUTE')
 THEN RAISE EXCEPTION 'ANON_PREFLIGHT_EXECUTE_UNEXPECTED'; END IF;
END $secure$;
