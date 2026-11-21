-- Disposable PG17 ONLY. Invented users, questions and binary metadata, never hosted.
DO $g$ BEGIN IF current_database()<>'iclub_math_s2_private_image_synthetic'
 THEN RAISE EXCEPTION 'DISPOSABLE_DATABASE_REQUIRED'; END IF; END $g$;
DO $g$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='anon') THEN CREATE ROLE anon NOLOGIN; END IF;
END $g$;
CREATE SCHEMA auth;
CREATE SCHEMA private;
CREATE SCHEMA storage;
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS
$fn$ SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid; $fn$;
CREATE FUNCTION storage.allow_only_operation(text) RETURNS boolean LANGUAGE sql STABLE AS
$fn$ SELECT $1=current_setting('storage.test_operation',true); $fn$;
CREATE TABLE storage.buckets(id text PRIMARY KEY,name text NOT NULL,public boolean NOT NULL);
CREATE TABLE storage.objects(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,bucket_id text NOT NULL,name text NOT NULL);
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON SCHEMA auth,storage TO authenticated,anon;
GRANT SELECT ON storage.objects TO authenticated,anon;
INSERT INTO storage.buckets VALUES('books','books',true);
CREATE TABLE public.seasons(id bigint PRIMARY KEY,season_no integer NOT NULL);
CREATE TABLE public.tours(id bigint PRIMARY KEY,subject_id bigint NOT NULL,season_id bigint NOT NULL REFERENCES public.seasons(id),
 is_active boolean NOT NULL,start_date date,end_date date);
CREATE TABLE public.users(id uuid PRIMARY KEY,is_school_student boolean NOT NULL);
CREATE TABLE public.user_subjects(user_id uuid,subject_id bigint,mode text);
CREATE TABLE public.questions(id bigint PRIMARY KEY,subject_id bigint,is_active boolean,image_url text);
CREATE TABLE public.tour_questions(tour_id bigint,question_id bigint,is_active boolean);
CREATE TABLE public.tour_attempts(id bigint PRIMARY KEY,user_id uuid,tour_id bigint,status text);
CREATE TABLE public.tour_session_runtime_v4(
 attempt_id bigint PRIMARY KEY,user_id uuid,tour_id bigint,
 question_ids bigint[],finalized_at timestamptz,created_at timestamptz DEFAULT now());
INSERT INTO public.seasons VALUES(901,1),(902,2);
INSERT INTO public.tours VALUES
(81,5,902,true,(now() AT TIME ZONE 'Asia/Tashkent')::date,(now() AT TIME ZONE 'Asia/Tashkent')::date),
(82,5,901,true,(now() AT TIME ZONE 'Asia/Tashkent')::date,(now() AT TIME ZONE 'Asia/Tashkent')::date),
(83,4,902,true,(now() AT TIME ZONE 'Asia/Tashkent')::date,(now() AT TIME ZONE 'Asia/Tashkent')::date);
INSERT INTO public.users VALUES
('00000000-0000-4000-8000-000000000101',true),
('00000000-0000-4000-8000-000000000102',true);
INSERT INTO public.user_subjects VALUES
('00000000-0000-4000-8000-000000000101',5,'competitive');
INSERT INTO public.questions(id,subject_id,is_active,image_url)
SELECT 2000+n,5,true, CASE WHEN n=1 THEN 'https://example.invalid/legacy-public.png' ELSE NULL END
FROM generate_series(1,20) n;
INSERT INTO public.tour_questions(tour_id,question_id,is_active)
 SELECT 81,id,true FROM public.questions;
\i supabase/candidates/math_s2_private_images_v1_uninstalled.sql
-- Explicitly stage metadata as reviewer/owner only; storage bytes simulated by row.
INSERT INTO private.math_s2_image_assets_v1(question_id,object_path,sha256)
 VALUES(2001,'s2/math/example.png',repeat('a',64));
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000101',false);
SET ROLE authenticated;
DO $g$ BEGIN
 BEGIN
  PERFORM public.get_math_s2_tour_preflight_v1(81);
  RAISE EXCEPTION 'UNREVIEWED_ASSET_WAS_ACCEPTED';
 EXCEPTION WHEN SQLSTATE '55000' THEN
  IF SQLERRM<>'math_s2_assets_not_ready' THEN RAISE; END IF;
 END;
END $g$;
RESET ROLE;
UPDATE private.math_s2_image_assets_v1 SET reviewed=true WHERE question_id=2001;
SET ROLE authenticated;
DO $g$ BEGIN
 BEGIN
  PERFORM public.get_math_s2_tour_preflight_v1(81);
  RAISE EXCEPTION 'UNUPLOADED_ASSET_WAS_ACCEPTED';
 EXCEPTION WHEN SQLSTATE '55000' THEN
  IF SQLERRM<>'math_s2_assets_not_ready' THEN RAISE; END IF;
 END;
END $g$;
RESET ROLE;
INSERT INTO storage.objects(bucket_id,name) VALUES ('iclub-math-s2-private','s2/math/example.png');
SET ROLE authenticated;
DO $g$
DECLARE payload jsonb;
BEGIN
 payload:=public.get_math_s2_tour_preflight_v1(81);
 IF payload->>'ready'<>'true' OR payload->>'question_count'<>'20'
  OR payload->>'image_count'<>'1' OR payload ? 'object_path'
  OR payload ? 'question_id' OR payload ? 'image_url' THEN
  RAISE EXCEPTION 'PREFLIGHT_DISCLOSES_CONTENT_OR_WRONG_COUNT'; END IF;
 IF public.get_math_s2_resume_attempt_v1(81) IS NOT NULL THEN
  RAISE EXCEPTION 'PRESTART_PRETENDS_ISSUED_ATTEMPT'; END IF;
 IF EXISTS(SELECT 1 FROM public.get_math_s2_image_manifest_v1(7001))
 THEN RAISE EXCEPTION 'MANIFEST_BEFORE_ATTEMPT'; END IF;
END $g$;
RESET ROLE;
-- Synthetic signed start/issue boundary: owner only, server immutable question snapshot.
INSERT INTO public.tour_attempts VALUES(7001,'00000000-0000-4000-8000-000000000101',81,'active');
INSERT INTO public.tour_session_runtime_v4(attempt_id,user_id,tour_id,question_ids)
VALUES(7001,'00000000-0000-4000-8000-000000000101',81,
 ARRAY(SELECT id FROM public.questions ORDER BY id));
SET ROLE authenticated;
DO $g$ BEGIN
 IF public.get_math_s2_resume_attempt_v1(81)<>7001 THEN RAISE EXCEPTION 'RESUME_LOST'; END IF;
 IF (SELECT count(*) FROM public.get_math_s2_image_manifest_v1(7001))<>1 THEN
 RAISE EXCEPTION 'ISSUED_ASSET_MANIFEST_NOT_AVAILABLE'; END IF;
 IF NOT public.iclub_math_s2_can_read_private_image_v1('s2/math/example.png') THEN
 RAISE EXCEPTION 'AUTHORIZED_OWNER_DENIED'; END IF;
END $g$;
SELECT set_config('storage.test_operation','object.get_authenticated',false);
DO $g$ BEGIN
 IF (SELECT count(*) FROM storage.objects WHERE bucket_id='iclub-math-s2-private')<>1 THEN
 RAISE EXCEPTION 'JWT_STORAGE_DOWNLOAD_DENIED'; END IF;
END $g$;
SELECT set_config('storage.test_operation','object.list',false);
DO $g$ BEGIN
 IF (SELECT count(*) FROM storage.objects WHERE bucket_id='iclub-math-s2-private')<>0 THEN
 RAISE EXCEPTION 'BUCKET_LIST_LEAK'; END IF;
END $g$;
RESET ROLE;
-- Foreign JWT cannot see the object or another learner's attempt.
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000102',false);
SELECT set_config('storage.test_operation','object.get_authenticated',false);
SET ROLE authenticated;
DO $g$ BEGIN
 IF (SELECT count(*) FROM storage.objects WHERE bucket_id='iclub-math-s2-private')<>0
 OR public.get_math_s2_resume_attempt_v1(81) IS NOT NULL
 OR EXISTS(SELECT 1 FROM public.get_math_s2_image_manifest_v1(7001)) THEN
 RAISE EXCEPTION 'CROSS_ACCOUNT_LEAK'; END IF;
 BEGIN
  PERFORM public.get_math_s2_tour_preflight_v1(81);
  RAISE EXCEPTION 'NONCOMPETITOR_ACCEPTED';
 EXCEPTION WHEN SQLSTATE '42501' THEN
  IF SQLERRM<>'tour_subject_not_competitive_for_user' THEN RAISE; END IF;
 END;
END $g$;
RESET ROLE;
-- Finalizing an attempt revokes future authenticated reads but preserves rows.
UPDATE public.tour_session_runtime_v4 SET finalized_at=now() WHERE attempt_id=7001;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000101',false);
SET ROLE authenticated;
DO $g$ BEGIN
 IF public.get_math_s2_resume_attempt_v1(81) IS NOT NULL
 OR EXISTS(SELECT 1 FROM public.get_math_s2_image_manifest_v1(7001))
 OR (SELECT count(*) FROM storage.objects WHERE bucket_id='iclub-math-s2-private')<>0 THEN
 RAISE EXCEPTION 'FINALIZED_ASSET_NOT_REVOKED'; END IF;
END $g$;
RESET ROLE;
DO $g$ BEGIN
 IF (SELECT count(*) FROM public.tour_attempts)<>1 OR
    (SELECT count(*) FROM public.tour_session_runtime_v4)<>1 OR
    (SELECT count(*) FROM public.questions)<>20 OR
    (SELECT count(*) FROM storage.buckets WHERE id='books' AND public IS TRUE)<>1 OR
    (SELECT count(*) FROM storage.buckets WHERE id='iclub-math-s2-private' AND public IS FALSE)<>1 THEN
  RAISE EXCEPTION 'HISTORY_OR_OTHER_BUCKET_CHANGED';
 END IF;
 IF has_function_privilege('anon','public.get_math_s2_image_manifest_v1(bigint)','EXECUTE')
 OR has_function_privilege('anon','public.get_math_s2_resume_attempt_v1(bigint)','EXECUTE') THEN
  RAISE EXCEPTION 'ANON_RPC_GRANTED'; END IF;
 RAISE NOTICE 'PRIVATE_IMAGE_AUTH_PG17_PASS';
END $g$;
