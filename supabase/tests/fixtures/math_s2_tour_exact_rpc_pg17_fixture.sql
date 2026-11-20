-- SYNTHETIC DISPOSABLE PostgreSQL 17 fixture ONLY. Extracted actual source
-- definitions of three public Tour RPCs read-only on 2026-11-20.
-- No live credentials, learner records, stems or answer keys included.
-- DO NOT RUN ON ANY PERSISTENT DATABASE.
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE service_role NOLOGIN;
CREATE ROLE authenticator LOGIN PASSWORD 'disposable-only-authenticator' NOINHERIT;
GRANT anon, authenticated, service_role TO authenticator;
CREATE SCHEMA auth;
CREATE SCHEMA private;
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $uid$
 SELECT COALESCE(
  NULLIF(current_setting('request.jwt.claim.sub', true),''),
  NULLIF(current_setting('request.jwt.claims', true),'')::json->>'sub'
 )::uuid;
$uid$;
CREATE TABLE public.questions(
 id bigint PRIMARY KEY, subject_id bigint NOT NULL, qtype text NOT NULL,
 correct_answer text NOT NULL, is_active boolean NOT NULL DEFAULT true
);
CREATE TABLE public.seasons(id bigint PRIMARY KEY, season_no integer NOT NULL);
CREATE TABLE public.tours(
 id bigint PRIMARY KEY, subject_id bigint NOT NULL,
 season_id bigint REFERENCES public.seasons(id), tour_no smallint NOT NULL,
 is_active boolean NOT NULL DEFAULT false,
 start_date date, end_date date
);
CREATE TABLE public.tour_questions(
 tour_id bigint NOT NULL, question_id bigint NOT NULL,
 is_active boolean DEFAULT true, PRIMARY KEY(tour_id,question_id)
);
CREATE TABLE public.tour_session_runtime_v4(
 attempt_id bigint PRIMARY KEY, user_id uuid NOT NULL,
 question_ids bigint[] NOT NULL, finalized_at timestamptz
);
CREATE TABLE public.tour_session_answers_v4(
 attempt_id bigint NOT NULL, question_id bigint NOT NULL,
 user_answer text, answered boolean, is_correct boolean,
 time_spent integer, finish_reason text, answered_at timestamptz,
 PRIMARY KEY(attempt_id,question_id)
);
CREATE TABLE private.chemistry_t1_stage_20261015(
 question_id bigint, candidate_id text,payload jsonb
);
CREATE TABLE private.chemistry_t2_stage_20261015(
 question_id bigint, candidate_id text,payload jsonb
);
CREATE TABLE private.chemistry_t3_stage_20261015(
 question_id bigint, candidate_id text,payload jsonb
);
CREATE TABLE private.chemistry_release_staging_20261015(
 question_id bigint,candidate_id text,payload jsonb
);

CREATE OR REPLACE FUNCTION public.iclub_tour_input_is_correct_v4(p_user_answer text, p_expected_answer text)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_user text := trim(translate(coalesce(p_user_answer,''), '−–—', '---'));
  v_expected text := trim(translate(coalesce(p_expected_answer,''), '−–—', '---'));
  v_user_num double precision;
  v_expected_num double precision;
  v_diff double precision;
  v_scale double precision;
  v_expected_signed boolean;
begin
  if v_user='' or v_expected='' then return false; end if;
  if v_expected ~ '^[+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$' then
    if v_user !~ '^[+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$' then return false; end if;
    v_expected_signed := v_expected ~ '^[+-]';
    if v_expected_signed then
      if left(v_expected,1) <> left(v_user,1) then return false; end if;
    elsif v_user ~ '^[+-]' then return false;
    end if;
    begin
      v_user_num := v_user::double precision;
      v_expected_num := v_expected::double precision;
    exception when others then return false;
    end;
    v_diff := abs(v_user_num-v_expected_num);
    v_scale := greatest(1::double precision,abs(v_user_num),abs(v_expected_num));
    return v_diff <= v_scale*1e-9;
  end if;
  if v_expected ~ '^[A-Z][A-Za-z0-9]*$' then
    if v_user !~ '^[A-Za-z][A-Za-z0-9]*$' then return false; end if;
    return lower(v_user)=lower(v_expected);
  end if;
  return lower(regexp_replace(v_user,'\\s+','','g')) = lower(regexp_replace(v_expected,'\\s+','','g'));
end;
$function$
;

CREATE OR REPLACE FUNCTION public.iclub_eval_tour_question_safe_v4(p_question_id bigint, p_user_answer text, p_picked_index integer DEFAULT NULL::integer, p_answered boolean DEFAULT true)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
declare
  v_q public.questions%rowtype;
  v_selected text;
  v_correct boolean := false;
begin
  select q.* into v_q from public.questions q where q.id=p_question_id and q.is_active is true;
  if v_q.id is null then raise exception 'question_not_found_or_inactive' using errcode='P0002'; end if;
  if coalesce(p_answered,true) is false then return jsonb_build_object('selected_answer',null,'is_correct',false); end if;
  if lower(coalesce(v_q.qtype,''))='mcq' then
    if p_picked_index is not null and p_picked_index between 0 and 25 then
      v_selected := chr(65+p_picked_index);
    elsif upper(trim(coalesce(p_user_answer,''))) ~ '^[A-Z]$' then
      v_selected := upper(trim(p_user_answer));
    elsif trim(coalesce(p_user_answer,'')) ~ '^[0-9]+$' and trim(p_user_answer)::integer between 0 and 25 then
      v_selected := chr(65+trim(p_user_answer)::integer);
    else
      v_selected := upper(trim(coalesce(p_user_answer,'')));
    end if;
    v_correct := upper(trim(coalesce(v_selected,'')))=upper(trim(coalesce(v_q.correct_answer,'')));
  else
    v_selected := trim(coalesce(p_user_answer,''));
    if v_q.subject_id=4 and (v_q.id IN (1946,1965) or exists (
      select 1 from private.chemistry_t1_stage_20261015 s where s.question_id=v_q.id and s.payload->>'candidate_id'=s.candidate_id and v_q.qtype='input'
    )) then
      v_correct:=private.iclub_chemistry_t1_typed_correct_20261015(v_q.id,p_user_answer);
    elsif v_q.subject_id=4 and exists (
      select 1 from private.chemistry_t3_stage_20261015 s
       where s.question_id=v_q.id and s.payload->>'qtype'='input'
    ) then
      v_correct:=private.iclub_chem_t3_numeric_correct_20261015(v_q.id,v_selected);
    elsif v_q.subject_id=4 and exists (
      select 1 from private.chemistry_release_staging_20261015 s
      where s.question_id=v_q.id and s.payload->>'qtype'='input'
    ) then
      v_correct:=private.iclub_chemistry_release_numeric_correct_20261015(v_q.id,v_selected);
    elsif v_q.subject_id=4 and exists (
      select 1 from private.chemistry_t2_stage_20261015 s
       where s.question_id=v_q.id and s.payload->>'qtype'='input'
    ) then
      v_correct:=private.iclub_chem_t2_numeric_correct_20261015(v_q.id,v_selected);
    else
      v_correct := public.iclub_tour_input_is_correct_v4(v_selected,v_q.correct_answer);
    end if;
  end if;
  return jsonb_build_object('selected_answer',nullif(v_selected,''),'is_correct',v_correct);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_tour_answer_safe_v4(p_attempt_id bigint, p_question_id bigint, p_user_answer text, p_picked_index integer, p_time_spent integer, p_answered boolean DEFAULT true, p_finish_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_rt public.tour_session_runtime_v4%rowtype;
  v_eval jsonb;
  v_saved public.tour_session_answers_v4%rowtype;
  v_count integer;
  v_was_existing boolean := false;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode='28000'; end if;
  select * into v_rt from public.tour_session_runtime_v4 r where r.attempt_id=p_attempt_id and r.user_id=v_uid;
  if v_rt.attempt_id is null then raise exception 'tour_session_not_found' using errcode='P0002'; end if;
  if v_rt.finalized_at is not null then raise exception 'tour_session_finalized' using errcode='55000'; end if;
  if not (p_question_id=any(v_rt.question_ids)) then raise exception 'question_not_in_tour_session' using errcode='22023'; end if;
  select * into v_saved from public.tour_session_answers_v4 a where a.attempt_id=p_attempt_id and a.question_id=p_question_id;
  v_was_existing := v_saved.attempt_id is not null;
  if not v_was_existing then
    v_eval := public.iclub_eval_tour_question_safe_v4(p_question_id,p_user_answer,p_picked_index,coalesce(p_answered,true));
    insert into public.tour_session_answers_v4(attempt_id,question_id,user_answer,answered,is_correct,time_spent,finish_reason,answered_at)
    values(p_attempt_id,p_question_id,v_eval->>'selected_answer',coalesce(p_answered,true),coalesce((v_eval->>'is_correct')::boolean,false),greatest(coalesce(p_time_spent,0),0),nullif(trim(coalesce(p_finish_reason,'')),''),now())
    on conflict(attempt_id,question_id) do nothing;
    select * into v_saved from public.tour_session_answers_v4 a where a.attempt_id=p_attempt_id and a.question_id=p_question_id;
  end if;
  if v_saved.attempt_id is null then raise exception 'tour_answer_save_failed' using errcode='55000'; end if;
  select count(*)::integer into v_count from public.tour_session_answers_v4 a where a.attempt_id=p_attempt_id;
  return jsonb_build_object('ok',true,'attempt_id',p_attempt_id,'question_id',p_question_id,'recorded',true,'recorded_count',v_count,'question_count',20,'idempotent',v_was_existing);
end;
$function$
;

-- Exact live source pin, and existing strict RPC ACLs before any candidate changes.
REVOKE ALL ON FUNCTION public.iclub_eval_tour_question_safe_v4(bigint,text,integer,boolean) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_tour_input_is_correct_v4(text,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.submit_tour_answer_safe_v4(bigint,bigint,text,integer,integer,boolean,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_eval_tour_question_safe_v4(bigint,text,integer,boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.iclub_tour_input_is_correct_v4(text,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.submit_tour_answer_safe_v4(bigint,bigint,text,integer,integer,boolean,text) TO authenticated,service_role;
GRANT USAGE ON SCHEMA public TO anon,authenticated,service_role;
INSERT INTO public.seasons(id,season_no) VALUES (91,1),(92,2);
INSERT INTO public.tours(id,subject_id,season_id,tour_no) VALUES
 (999201,5,92,1),(999202,5,92,2),(999203,5,92,3),
 (999204,5,92,4),(999205,5,92,5),(999206,5,92,6),(999207,5,92,7),
 (999101,5,91,1),(999301,4,92,1);
INSERT INTO public.questions(id,subject_id,qtype,correct_answer,is_active) VALUES
 (995001,5,'input','1/2',true),
 (995002,5,'input','4.5',true),
 (995003,5,'input','-8',true),
 (995004,5,'input','14/3',true),
 (995005,5,'mcq','C',true),
 (995006,5,'input','9/2',true),
 (995011,5,'input','1/2',true),
 (995021,4,'input','1/2',true);
-- Total 28 invented S2 Math input samples, mirroring the real input count.
-- Four fractional canonical strings and one decimal .5 canonical key;
-- none of these are hidden production Tour keys.
INSERT INTO public.questions(id,subject_id,qtype,correct_answer,is_active)
 VALUES (995030,5,'input','3/4',true);
INSERT INTO public.questions(id,subject_id,qtype,correct_answer,is_active)
 SELECT n,5,'input',(n-995030)::text,true
 FROM generate_series(995031,995052) AS n;

INSERT INTO public.tour_questions(tour_id,question_id,is_active) VALUES
 (999201,995001,true),(999201,995002,true),(999201,995003,true),
 (999201,995004,true),(999201,995005,true),(999201,995006,true),
 (999101,995011,true),(999301,995021,true);
INSERT INTO public.tour_questions(tour_id,question_id,is_active)
 SELECT 999202 + ((id-995030) % 6), id,true
 FROM public.questions WHERE id BETWEEN 995030 AND 995052;
INSERT INTO public.tour_session_runtime_v4(attempt_id,user_id,question_ids,finalized_at)
 VALUES
 (996101,'11111111-1111-4111-8111-111111111111',
  ARRAY[995001,995002,995003,995004,995005,995006]::bigint[],NULL),
 (996102,'11111111-1111-4111-8111-111111111111',
  ARRAY[995011]::bigint[],NULL),
 (996103,'11111111-1111-4111-8111-111111111111',
  ARRAY[995021]::bigint[],NULL),
 (996104,'22222222-2222-4222-8222-222222222222',
  ARRAY[995001]::bigint[],NULL),
 (996105,'11111111-1111-4111-8111-111111111111',
  ARRAY[995001]::bigint[],NULL);
DO $guard$
BEGIN
 IF (SELECT md5(p.prosrc) FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public'
      AND p.proname='iclub_eval_tour_question_safe_v4')
   <> '7f564255956fbe61ab8d1a14cade9389' THEN
   RAISE EXCEPTION 'fixture baseline differs from authentic 2026-11-20 installed evaluator';
 END IF;
END $guard$;
