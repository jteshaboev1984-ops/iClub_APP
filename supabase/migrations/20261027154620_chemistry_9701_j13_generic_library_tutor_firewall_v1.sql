-- Chemistry-only J13 safety correction: existing admin generic reader must not leak
-- unpublished Chemistry Tutor texts when Theory becomes learner-visible.
-- Economics and every non-Chemistry subject preserve their legacy response shape.
-- Does NOT publish any content or grant access to anon/authenticated.
DO $guard$
BEGIN
 IF to_regprocedure('public.iclub_subject_library_content_service_v1(text,text,text)') IS NULL
 OR (SELECT visible_to_learners FROM private.iclub_subject_library WHERE subject_key='chemistry') IS DISTINCT FROM false
 OR has_function_privilege('authenticated','public.iclub_subject_library_content_service_v1(text,text,text)','EXECUTE')
 THEN RAISE EXCEPTION 'J13 shared reader safety precondition failed'; END IF;
 IF pg_get_functiondef('public.iclub_subject_library_content_service_v1(text,text,text)'::regprocedure)
 NOT LIKE '%join private.iclub_subject_library_tutor u%'
 THEN RAISE EXCEPTION 'Unknown generic content-service version; manual reconciliation required'; END IF;
END $guard$;
CREATE OR REPLACE FUNCTION public.iclub_subject_library_content_service_v1(
 p_subject_key text,p_skill_key text,p_locale text)
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $func$
 SELECT coalesce((
   SELECT jsonb_build_object(
     'subject_key',s.subject_key,'version_key',s.active_version,
     'skill_key',t.skill_key,'tour_no',t.tour_no,
     'syllabus_point',t.syllabus_point,
     'theory',t.locales->lower(p_locale)
   ) ||
   CASE WHEN s.subject_key='chemistry' THEN '{}'::jsonb
   ELSE jsonb_build_object('tutor',jsonb_build_object(
      'title',u.title,'main_explanation',u.main_explanation,
      'simple_explanation',u.simple_explanation,
      'alternative_explanation',u.alternative_explanation,
      'focus_explanation',u.focus_explanation
   )) END
   FROM private.iclub_subject_library s
   JOIN private.iclub_subject_library_theory t
     ON t.subject_key=s.subject_key AND t.version_key=s.active_version
   JOIN private.iclub_subject_library_tutor u
     ON u.subject_key=t.subject_key AND u.version_key=t.version_key
     AND u.skill_key=t.skill_key AND u.locale=lower(p_locale)
   WHERE s.subject_key=p_subject_key AND s.visible_to_learners
     AND t.skill_key=p_skill_key
   LIMIT 1
 ),'{}'::jsonb);
$func$;
-- Preserve existing privileged callers and explicit absence of browser privileges.
REVOKE ALL ON FUNCTION public.iclub_subject_library_content_service_v1(text,text,text)
 FROM PUBLIC,anon,authenticated;
DO $post$
BEGIN
 IF has_function_privilege('anon',
  'public.iclub_subject_library_content_service_v1(text,text,text)','EXECUTE')
 OR has_function_privilege('authenticated',
  'public.iclub_subject_library_content_service_v1(text,text,text)','EXECUTE')
 OR (SELECT visible_to_learners FROM private.iclub_subject_library WHERE subject_key='chemistry')
 THEN RAISE EXCEPTION 'J13 generic content reader unexpectedly open'; END IF;
END $post$;
