-- CANDIDATE ONLY: NOT A MIGRATION, NOT installed in Supabase production.
-- Never touch the shared public "books" bucket, original URLs, or learner records.
-- Only a separately approved owner/servicer may upload the seven reviewed binaries.
-- Separate server v4 preflight S2 deny, live asset cutover and old-client rollout
-- are HARD release prerequisites. This file is deliberately inert in main.
BEGIN;

CREATE TABLE IF NOT EXISTS private.math_s2_image_assets_v1 (
  question_id bigint PRIMARY KEY REFERENCES public.questions(id),
  object_path text NOT NULL UNIQUE
    CHECK (object_path ~ '^s2/math/[a-z0-9_/-]+\.(png|jpg|jpeg|webp|svg)$'),
  sha256 text NOT NULL CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  reviewed boolean NOT NULL DEFAULT false,
  inserted_at timestamptz NOT NULL DEFAULT now()
);
REVOKE ALL ON private.math_s2_image_assets_v1 FROM PUBLIC, anon, authenticated;

-- New private bucket: do not change shared books or team-photos.
-- Storage bytes are uploaded separately through the approved operator flow.
INSERT INTO storage.buckets (id, name, public)
VALUES ('iclub-math-s2-private', 'iclub-math-s2-private', false)
ON CONFLICT (id) DO NOTHING;
DO $guard$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM storage.buckets
   WHERE id='iclub-math-s2-private' AND public IS FALSE) THEN
  RAISE EXCEPTION 'math_s2_bucket_must_be_private';
 END IF;
END $guard$;

-- Authenticated Storage downloads only. No listing, upload, update, delete,
-- unauthenticated fetch, or signing capability is added to learner roles.
CREATE OR REPLACE FUNCTION public.iclub_math_s2_can_read_private_image_v1(p_path text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path=''
AS $safe$
 SELECT (auth.uid() IS NOT NULL) AND EXISTS (
  SELECT 1
  FROM private.math_s2_image_assets_v1 a
  JOIN public.tour_session_runtime_v4 r
   ON a.question_id=ANY(r.question_ids)
  JOIN public.tour_attempts ta
   ON ta.id=r.attempt_id AND ta.user_id=r.user_id AND ta.tour_id=r.tour_id
  JOIN public.tours t ON t.id=r.tour_id AND t.subject_id=5
  JOIN public.seasons s ON s.id=t.season_id AND s.season_no=2
  WHERE a.object_path=p_path AND a.reviewed IS TRUE
   AND r.user_id=auth.uid()
   AND r.finalized_at IS NULL
 );
$safe$;
REVOKE ALL ON FUNCTION public.iclub_math_s2_can_read_private_image_v1(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.iclub_math_s2_can_read_private_image_v1(text) TO authenticated;
DROP POLICY IF EXISTS iclub_math_s2_private_image_download_v1 ON storage.objects;
CREATE POLICY iclub_math_s2_private_image_download_v1 ON storage.objects
FOR SELECT TO authenticated
USING (
 bucket_id='iclub-math-s2-private'
 AND storage.allow_only_operation('object.get_authenticated')
 AND public.iclub_math_s2_can_read_private_image_v1(name)
);

-- Pre-start metadata ONLY, no question IDs, ordering, diagram paths or binary URLs.
-- Fails closed if any of the currently linked images is not independently reviewed
-- or not physically present in the private bucket.
CREATE OR REPLACE FUNCTION public.get_math_s2_tour_preflight_v1(p_tour_id bigint)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path='public','auth','pg_temp'
AS $rpc$
DECLARE v_tour public.tours%rowtype; v_uid uuid:=auth.uid();
  v_today date:=(now() AT TIME ZONE 'Asia/Tashkent')::date;
  v_count integer; v_image_count integer; v_ready_count integer;
BEGIN
 IF v_uid IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING errcode='28000'; END IF;
 SELECT t.* INTO v_tour FROM public.tours t JOIN public.seasons s ON s.id=t.season_id
 WHERE t.id=p_tour_id AND t.subject_id=5 AND t.is_active
 AND s.season_no=2;
 IF v_tour.id IS NULL THEN RAISE EXCEPTION 'math_s2_not_active' USING errcode='P0002'; END IF;
 IF v_tour.start_date IS NULL OR v_tour.end_date IS NULL
   OR v_today<v_tour.start_date OR v_today>v_tour.end_date THEN
   RAISE EXCEPTION 'tour_not_open' USING errcode='55000'; END IF;
 IF NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=v_uid AND u.is_school_student IS TRUE)
 THEN RAISE EXCEPTION 'tour_requires_school_student' USING errcode='42501'; END IF;
 IF NOT EXISTS (SELECT 1 FROM public.user_subjects us
   WHERE us.user_id=v_uid AND us.subject_id=5 AND us.mode='competitive')
 THEN RAISE EXCEPTION 'tour_subject_not_competitive_for_user' USING errcode='42501'; END IF;
 SELECT count(*)::integer,
   count(*) FILTER(WHERE nullif(btrim(q.image_url),'') IS NOT NULL)::integer,
   count(*) FILTER(WHERE nullif(btrim(q.image_url),'') IS NOT NULL
     AND a.reviewed IS TRUE AND so.id IS NOT NULL)::integer
 INTO v_count,v_image_count,v_ready_count
 FROM public.tour_questions tq
 JOIN public.questions q ON q.id=tq.question_id AND q.is_active
 LEFT JOIN private.math_s2_image_assets_v1 a ON a.question_id=q.id
 LEFT JOIN storage.objects so ON so.bucket_id='iclub-math-s2-private'
   AND so.name=a.object_path
 WHERE tq.tour_id=v_tour.id AND tq.is_active AND q.subject_id=5;
 IF v_count<>20 OR v_image_count<1 OR v_ready_count<>v_image_count THEN
   RAISE EXCEPTION 'math_s2_assets_not_ready' USING errcode='55000';
 END IF;
 RETURN jsonb_build_object('ready',true,'question_count',v_count,
   'image_count',v_image_count);
END $rpc$;
REVOKE ALL ON FUNCTION public.get_math_s2_tour_preflight_v1(bigint) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_math_s2_tour_preflight_v1(bigint) TO authenticated;

-- Owner scoped recovery. Return only the existing unfinalized attempt ID;
-- never reissue, delete, reset or convert a submitted/anti-cheat attempt.
CREATE OR REPLACE FUNCTION public.get_math_s2_resume_attempt_v1(p_tour_id bigint)
RETURNS bigint LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $rpc$
 SELECT r.attempt_id FROM public.tour_session_runtime_v4 r
 JOIN public.tour_attempts ta ON ta.id=r.attempt_id
   AND ta.user_id=r.user_id AND ta.tour_id=r.tour_id
 JOIN public.tours t ON t.id=r.tour_id AND t.subject_id=5
 JOIN public.seasons s ON s.id=t.season_id AND s.season_no=2
 WHERE r.user_id=auth.uid() AND r.tour_id=p_tour_id
   AND r.finalized_at IS NULL
 ORDER BY r.created_at DESC LIMIT 1;
$rpc$;
REVOKE ALL ON FUNCTION public.get_math_s2_resume_attempt_v1(bigint) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_math_s2_resume_attempt_v1(bigint) TO authenticated;

-- Only after a verified issued attempt. Raw public URLs are never returned.
CREATE OR REPLACE FUNCTION public.get_math_s2_image_manifest_v1(p_attempt_id bigint)
RETURNS TABLE(question_id bigint, object_path text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $rpc$
 SELECT a.question_id,a.object_path FROM public.tour_session_runtime_v4 r
 JOIN public.tour_attempts ta ON ta.id=r.attempt_id
   AND ta.user_id=r.user_id AND ta.tour_id=r.tour_id
 JOIN public.tours t ON t.id=r.tour_id AND t.subject_id=5
 JOIN public.seasons s ON s.id=t.season_id AND s.season_no=2
 JOIN private.math_s2_image_assets_v1 a
   ON a.question_id=ANY(r.question_ids) AND a.reviewed IS TRUE
 WHERE r.attempt_id=p_attempt_id AND r.user_id=auth.uid()
 AND r.finalized_at IS NULL ORDER BY a.question_id;
$rpc$;
REVOKE ALL ON FUNCTION public.get_math_s2_image_manifest_v1(bigint) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_math_s2_image_manifest_v1(bigint) TO authenticated;
COMMIT;
