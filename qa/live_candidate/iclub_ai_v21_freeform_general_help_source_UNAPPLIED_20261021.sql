-- QA-CANDIDATE. Read-only signed 13-item General Help source per locale.
-- Authenticated learner NEVER receives raw source; only trusted service_role.
-- Any missing/revoked/not-reviewed help item closes the full bundle.
CREATE FUNCTION public.get_iclub_ai_v21_freeform_help_bundle_v1(p_locale text)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $bundle$
DECLARE n int;verified_count int;bundled text;digest_sha text;item_versions int;
BEGIN
 IF p_locale NOT IN('ru','uz','en')
 THEN RETURN jsonb_build_object('ok',false,'reason','invalid_locale'); END IF;
 SELECT count(*),
   count(*) FILTER (WHERE published AND NOT revoked
     AND content_reviewed AND rights_reviewed AND locale_reviewed
     AND approved_at IS NOT NULL
     AND source_hash=encode(extensions.digest(
       convert_to(message,'UTF8'),'sha256'),'hex')),
   count(DISTINCT source_version)
 INTO n,verified_count,item_versions
 FROM private.iclub_ai_v21_beta_help_sources WHERE locale=p_locale;
 IF n<>13 OR verified_count<>13 OR item_versions<>2
 THEN RETURN jsonb_build_object('ok',false,'reason','source_not_approved'); END IF;
 SELECT string_agg(help_key||': '||message,E'\n' ORDER BY help_key)
 INTO bundled
 FROM private.iclub_ai_v21_beta_help_sources WHERE locale=p_locale;
 IF bundled IS NULL OR length(bundled) NOT BETWEEN 800 AND 7000
 THEN RETURN jsonb_build_object('ok',false,'reason','source_not_approved'); END IF;
 digest_sha:=encode(extensions.digest(
   convert_to(bundled,'UTF8'),'sha256'),'hex');
 RETURN jsonb_build_object(
  'ok',true,'locale',p_locale,'subject','general',
  'source_version','approved_iclub_help_bundle_v1',
  'source_hash',digest_sha,'source_text',bundled,'cards',n);
END $bundle$;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_freeform_help_bundle_v1(text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_freeform_help_bundle_v1(text)
 TO service_role;
