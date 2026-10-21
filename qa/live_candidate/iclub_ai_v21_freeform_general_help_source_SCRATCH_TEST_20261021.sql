DO $s$
DECLARE r jsonb;loc text;hash text;body text;
BEGIN
 IF has_function_privilege('authenticated',
  'public.get_iclub_ai_v21_freeform_help_bundle_v1(text)','EXECUTE')
 THEN RAISE EXCEPTION 'Learner may read raw prompt data'; END IF;
 FOREACH loc IN ARRAY ARRAY['en','ru','uz'] LOOP
  r:=public.get_iclub_ai_v21_freeform_help_bundle_v1(loc);
  IF r->>'ok'<>'true' OR r->>'cards'<>'13'
  THEN RAISE EXCEPTION 'Approved locale bundle missing for %',loc;END IF;
  hash:=r->>'source_hash';body:=r->>'source_text';
  IF hash IS DISTINCT FROM encode(extensions.digest(
   convert_to(body,'UTF8'),'sha256'),'hex')
  OR length(body)<800
  THEN RAISE EXCEPTION 'Noncanonical bundle hash for %',loc;END IF;
 END LOOP;
 UPDATE private.iclub_ai_v21_beta_help_sources
  SET revoked=true WHERE locale='ru' AND help_key='synthetic_help_4';
 r:=public.get_iclub_ai_v21_freeform_help_bundle_v1('ru');
 IF r->>'ok'<>'false' THEN RAISE EXCEPTION 'Revoked locale still used by model';END IF;
 UPDATE private.iclub_ai_v21_beta_help_sources
  SET revoked=false WHERE locale='ru' AND help_key='synthetic_help_4';
 UPDATE private.iclub_ai_v21_beta_help_sources
 SET message='tampered' WHERE locale='uz' AND help_key='synthetic_help_5';
 r:=public.get_iclub_ai_v21_freeform_help_bundle_v1('uz');
 IF r->>'ok'<>'false' THEN RAISE EXCEPTION 'Modified unverified text used by model';END IF;
 r:=public.get_iclub_ai_v21_freeform_help_bundle_v1('xx');
 IF r->>'ok'<>'false' THEN RAISE EXCEPTION 'Unsupported locale allowed';END IF;
END $s$;
SELECT 'PASS_VERIFIED_GENERAL_HELP_SOURCE_TRILINGUAL_SCRATCH' result;
