-- iClub AI v2.1 original app navigation: 6 routes × 3 verified locales.
-- Architect authorized publication 2026-10-20; no beta/candidate gate activation.
-- Source: 6 literal routes from current main 453127c3; original iClub copy.
-- Replaces ONLY additive v2.1 deliver function whitelist, not academic routing.
DO $guard$
DECLARE v_count int;
BEGIN
 IF md5(pg_get_functiondef('public.deliver_iclub_ai_v21_beta_prepared_service(uuid,uuid,text,text)'::regprocedure))
    <> 'aa3570b3230a1d454f275cf4304b46f5'
 THEN RAISE EXCEPTION 'v2.1 release halted: runtime function differs from pre-reviewed version'; END IF;
 SELECT count(*) INTO v_count FROM private.iclub_ai_v21_beta_help_sources;
 IF v_count<>0 THEN RAISE EXCEPTION 'v2.1 publication halted: unexpected existing source rows'; END IF;
 IF NOT EXISTS (
 SELECT 1 FROM private.iclub_ai_v21_beta_control
 WHERE singleton=1 AND NOT beta_enabled AND NOT prepared_enabled
 AND NOT generation_enabled AND approved_release='none'
 ) THEN RAISE EXCEPTION 'Beta was enabled unexpectedly'; END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_beta_members WHERE enabled OR consent_at IS NOT NULL)>0
 THEN RAISE EXCEPTION 'Beta member activation already changed'; END IF;
END $guard$;

WITH verified_copy(help_key,locale,message) AS (
 VALUES
 ('nav_home','ru','В нижнем меню выберите «Главная».'),
 ('nav_home','uz','Pastki menyudan «Bosh sahifa»ni tanlang.'),
 ('nav_home','en','In the bottom menu, choose “Home”.'),
 ('nav_courses','ru','В нижнем меню выберите «Учёба».'),
 ('nav_courses','uz','Pastki menyudan «O‘qish»ni tanlang.'),
 ('nav_courses','en','In the bottom menu, choose “Study”.'),
 ('nav_ratings','ru','В нижнем меню выберите «Рейтинг».'),
 ('nav_ratings','uz','Pastki menyudan «Reyting»ni tanlang.'),
 ('nav_ratings','en','In the bottom menu, choose “Ratings”.'),
 ('nav_profile','ru','В нижнем меню выберите «Профиль».'),
 ('nav_profile','uz','Pastki menyudan «Profil»ni tanlang.'),
 ('nav_profile','en','In the bottom menu, choose “Profile”.'),
 ('nav_about','ru','Откройте вкладку «Главная» и выберите «О проекте».'),
 ('nav_about','uz','«Bosh sahifa» bo‘limiga o‘ting va «Loyiha haqida»ni tanlang.'),
 ('nav_about','en','On “Home”, choose “About project”.'),
 ('nav_support','ru','Откройте «Профиль» и выберите «Поддержка».'),
 ('nav_support','uz','«Profil» bo‘limini oching va «Yordam»ni tanlang.'),
 ('nav_support','en','Open “Profile” and choose “Support”.')
)
INSERT INTO private.iclub_ai_v21_beta_help_sources(
 help_key,locale,message,source_version,source_hash,
 publication_revision,content_reviewed,rights_reviewed,locale_reviewed,
 published,revoked,approved_at
)
SELECT help_key,locale,message,'app-nav-main-453127c3-v1',
 encode(extensions.digest(convert_to(message,'UTF8'),'sha256'),'hex'),
 1,true,true,true,true,false,clock_timestamp()
FROM verified_copy;

DO $asserted$
DECLARE v_rows int;
BEGIN
 SELECT count(*) INTO v_rows
 FROM private.iclub_ai_v21_beta_help_sources
 WHERE help_key IN ('nav_home','nav_courses','nav_ratings','nav_profile',
 'nav_about','nav_support') AND locale IN ('ru','uz','en')
 AND published AND NOT revoked AND content_reviewed AND rights_reviewed
 AND locale_reviewed AND approved_at IS NOT NULL
 AND source_version='app-nav-main-453127c3-v1' AND publication_revision=1
 AND source_hash=encode(extensions.digest(convert_to(message,'UTF8'),'sha256'),'hex');
 IF v_rows<>18 THEN
 RAISE EXCEPTION 'Source integrity failed; matched % of expected 18',v_rows;
 END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_beta_help_sources)<>18 THEN
 RAISE EXCEPTION 'Unexpected content rows after publication';
 END IF;
END $asserted$;

CREATE OR REPLACE FUNCTION public.deliver_iclub_ai_v21_beta_prepared_service(
 p_user_id uuid,p_request_id uuid,p_help_key text,p_locale text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $deliver$
DECLARE
 c private.iclub_ai_v21_beta_control%rowtype;
 m private.iclub_ai_v21_beta_members%rowtype;
 s private.iclub_ai_v21_beta_help_sources%rowtype;
 u private.iclub_ai_v21_beta_usage%rowtype;
 old private.iclub_ai_v21_beta_deliveries%rowtype;
 v_now timestamptz := clock_timestamp();
BEGIN
 IF p_user_id IS NULL OR p_request_id IS NULL
 OR p_locale NOT IN ('ru','uz','en')
 OR p_help_key NOT IN (
  'support_help','catalog_help','ratings_help','home_next',
  'practice_rules','tour_rules','books_help','about_help',
  'notifications_help','community_help','certificates_help',
  'profile_meaning','video_help','recs_help','archive_help',
  'nav_home','nav_courses','nav_ratings','nav_profile','nav_about','nav_support'
 ) THEN RETURN jsonb_build_object('ok',false,'reason','in_development'); END IF;

 -- The singleton row lock serializes read/grant/quota, including two workers.
 SELECT * INTO c FROM private.iclub_ai_v21_beta_control
  WHERE singleton=1 FOR UPDATE;
 IF NOT FOUND OR NOT c.beta_enabled OR NOT c.prepared_enabled
 OR c.generation_enabled OR c.approved_release='none' THEN
  RETURN jsonb_build_object('ok',false,'reason','beta_not_enabled'); END IF;

 SELECT * INTO m FROM private.iclub_ai_v21_beta_members
  WHERE user_id=p_user_id;
 IF NOT FOUND OR NOT m.enabled OR m.consent_version<>'global_ai_beta_v21'
 OR m.consent_at IS NULL THEN
  RETURN jsonb_build_object('ok',false,'reason','beta_not_enabled'); END IF;

 -- Protection is derived from server academic tables, never browser view hints.
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR EXISTS (
  SELECT 1 FROM public.practice_sessions_v4
  WHERE user_id=p_user_id AND status='in_progress'
 ) THEN
  RETURN jsonb_build_object('ok',false,'reason','active_assessment'); END IF;

 SELECT * INTO s FROM private.iclub_ai_v21_beta_help_sources
  WHERE help_key=p_help_key AND locale=p_locale FOR SHARE;
 IF NOT FOUND OR NOT s.published OR s.revoked
 OR NOT s.content_reviewed OR NOT s.rights_reviewed
 OR NOT s.locale_reviewed OR s.approved_at IS NULL
 OR encode(extensions.digest(convert_to(s.message,'UTF8'),'sha256'),'hex')
    <>s.source_hash THEN
  RETURN jsonb_build_object('ok',false,'reason','in_development'); END IF;

 -- A same-ID retry is idempotent only for the SAME owner/key/version/revision;
 -- after revocation, neither new nor historical messages are returned.
 SELECT * INTO old FROM private.iclub_ai_v21_beta_deliveries
  WHERE request_id=p_request_id;
 IF FOUND THEN
  IF old.user_id=p_user_id AND old.help_key=p_help_key
  AND old.locale=p_locale AND old.source_hash=s.source_hash
  AND old.source_version=s.source_version
  AND old.publication_revision=s.publication_revision THEN
   RETURN jsonb_build_object('ok',true,'message',s.message,
     'mode','prepared','academic_state_changed',false,
     'provider_called',false,'replayed',true);
  END IF;
  RETURN jsonb_build_object('ok',false,'reason','request_conflict');
 END IF;

 INSERT INTO private.iclub_ai_v21_beta_usage(user_id,started_at,committed_count)
 VALUES (p_user_id,v_now,0)
 ON CONFLICT(user_id) DO NOTHING;
 SELECT * INTO u FROM private.iclub_ai_v21_beta_usage
  WHERE user_id=p_user_id FOR UPDATE;
 IF u.started_at <= v_now-interval '5 hours' THEN
  UPDATE private.iclub_ai_v21_beta_usage
   SET started_at=v_now,committed_count=0,updated_at=v_now
   WHERE user_id=p_user_id;
  u.committed_count:=0;
 END IF;
 IF u.committed_count>=3 THEN
  RETURN jsonb_build_object('ok',false,'reason','usage_exhausted',
    'reset_at',u.started_at+interval '5 hours'); END IF;
 INSERT INTO private.iclub_ai_v21_beta_deliveries(
  request_id,user_id,help_key,locale,source_version,source_hash,publication_revision
 ) VALUES (
  p_request_id,p_user_id,p_help_key,p_locale,
  s.source_version,s.source_hash,s.publication_revision
 );
 UPDATE private.iclub_ai_v21_beta_usage
 SET committed_count=committed_count+1,updated_at=v_now
 WHERE user_id=p_user_id;

 RETURN jsonb_build_object('ok',true,'message',s.message,
  'mode','prepared','academic_state_changed',false,
  'provider_called',false,'replayed',false);
END $deliver$;
REVOKE ALL ON FUNCTION public.deliver_iclub_ai_v21_beta_prepared_service(uuid,uuid,text,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.deliver_iclub_ai_v21_beta_prepared_service(uuid,uuid,text,text)
 TO service_role;
