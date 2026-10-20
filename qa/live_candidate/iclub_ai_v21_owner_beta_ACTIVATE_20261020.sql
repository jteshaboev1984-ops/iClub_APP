-- Owner-authorized academic beta ACTIVATE after full QA.
-- NO UI change, NO new student, NO retroactive editorial approvals.
DO $check$
BEGIN
 IF md5(pg_get_functiondef('public.deliver_iclub_ai_v21_academic_service(uuid,uuid,text,bigint,bigint,text)'::regprocedure))
  <> 'f62adb3499fc2664131f0c92b6342070'
 OR md5(pg_get_functiondef('public.get_iclub_ai_v21_academic_capabilities_service(uuid,text,bigint,text)'::regprocedure))
  <> '6e1722cd7f3e81cf87da090311dedec0'
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_policy
   WHERE singleton=1 AND NOT enabled AND NOT provider_enabled)<>1
 OR (SELECT count(*) FROM private.iclub_ai_v21_beta_members)<>3
 OR (SELECT count(*) FROM private.iclub_ai_v21_beta_control
   WHERE singleton=1 AND beta_enabled AND prepared_enabled
    AND NOT generation_enabled)<>1
 OR (SELECT count(*) FROM private.iclub_ai_v21_owner_beta_source_releases
   WHERE enabled AND release_basis='owner_authorized_closed_beta_20261020')<>111
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources src
   WHERE private.iclub_ai_v21_source_admitted_v1(src)
    AND src.target_hash=private.iclub_ai_v21_target_fingerprint_v1(
      'practice_error',substring(src.context_key FROM 10)::bigint)
    AND src.content_hash=encode(extensions.digest(
      convert_to(src.body_text,'UTF8'),'sha256'),'hex'))<>111
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources
   WHERE published OR content_reviewed OR rights_reviewed
    OR locale_reviewed OR academic_qa_passed)<>0
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_deliveries)<>0
 OR (SELECT count(*) FROM private.iclub_ai_v21_beta_help_sources
   WHERE published AND NOT revoked)<>39
 OR EXISTS (SELECT 1 FROM private.iclub_global_ai_runtime_config
   WHERE ui_enabled OR gateway_enabled OR generation_enabled OR NOT kill_switch)
 THEN RAISE EXCEPTION 'Beta activation stopped: facts, source admission or guards changed'; END IF;
END $check$;

UPDATE private.iclub_ai_v21_academic_policy SET enabled=true,
 updated_at=clock_timestamp()
WHERE singleton=1 AND NOT enabled AND NOT provider_enabled;

DO $verify$
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_policy
   WHERE singleton=1 AND enabled AND NOT provider_enabled)<>1
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources
   WHERE published OR content_reviewed OR rights_reviewed
    OR locale_reviewed OR academic_qa_passed)<>0
 THEN RAISE EXCEPTION 'Academic beta feature gate not opened or review forged'; END IF;
END $verify$;
