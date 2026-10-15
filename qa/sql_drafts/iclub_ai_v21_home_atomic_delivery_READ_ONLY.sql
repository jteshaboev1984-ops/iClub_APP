-- §107: ONE READ-ONLY PostgreSQL statement, ONE MVCC statement snapshot.
-- Disposable scratch only. This does not deploy to live Supabase and
-- is NOT a production release authorization or a locking transaction.
WITH
 parameters AS (
  SELECT
   '{{USER}}'::uuid AS owner,
   '{{HANDLE}}'::uuid AS handle,
   '{{LOCALE}}'::text AS locale,
   {{REVISION}}::bigint AS revision,
   to_timestamp({{EXPIRES_MS}}::double precision / 1000.0) AS expires_at,
   '{{ACTIONS_JSON}}'::jsonb AS actions
 ),
 actions AS (
  SELECT v.*
  FROM parameters p,
       jsonb_to_recordset(p.actions) AS v(
        "actionId" text,"actionCode" text,"subjectKey" text,
        "evidenceRevision" bigint,"evidenceHash" text,
        "sourceHash" text,"sourceVersion" text)
 ),
 current_scan AS (
  SELECT public.get_iclub_ai_v21_home_scan_scratch_service(
   p.owner,p.handle) AS data
  FROM parameters p
 ),
 normalized AS (
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
   'actionCode',a."actionCode",'subjectKey',a."subjectKey",
   'evidenceId',substring(a."actionId" FROM '_([0-9]+)$')::bigint,
   'evidenceRevision',a."evidenceRevision"
  ) ORDER BY a."subjectKey",substring(a."actionId" FROM '_([0-9]+)$')::bigint),
  '[]'::jsonb) AS rows
  FROM actions a
 )
SELECT EXISTS(
 SELECT 1
 FROM parameters p
 JOIN private.iclub_ai_v21_current_screen n
   ON n.user_id=p.owner AND n.current_handle=p.handle
    AND n.revision=p.revision
 JOIN private.iclub_ai_v21_scoped_contexts c
   ON c.context_handle=n.current_handle AND c.user_id=n.user_id
   AND c.context_revision=n.revision
 JOIN private.iclub_global_ai_runtime_config runtime ON runtime.id=1
 JOIN private.iclub_commercial_access_config cfg ON cfg.id=1
 JOIN private.iclub_ai_qa_capabilities_fixture caps ON caps.user_id=p.owner
 JOIN private.iclub_ai_qa_home_feature_gate gate ON gate.user_id=p.owner
 CROSS JOIN current_scan scan
 CROSS JOIN normalized norm
 WHERE current_database() ~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
   AND c.surface_code='home' AND c.app_view_code='home'
   AND c.revoked_at IS NULL AND c.expires_at>now()
   AND c.expires_at>=p.expires_at AND p.expires_at>now()
   AND runtime.kill_switch=false AND runtime.gateway_enabled=true
   AND NOT private.iclub_ai_has_active_protected_assessment_v1(p.owner)
   AND cfg.subject_limits_mode='enforced'
   AND cfg.grandfather_snapshot_completed_at IS NOT NULL
   AND caps.resolved=true AND caps.ai_generation_entitled=true
   AND gate.approved=true
   AND (scan.data->>'allowed')='true'
   AND (scan.data->>'complete_scan')='true'
   AND (scan.data->>'owner_id')=p.owner::text
   AND (scan.data->>'context_handle')=p.handle::text
   AND (scan.data->>'screen_revision')=p.revision::text
   AND scan.data->'candidates'=norm.rows
   AND jsonb_array_length(p.actions) BETWEEN 1 AND 3
   AND NOT EXISTS(
    SELECT 1 FROM actions a WHERE NOT EXISTS(
     SELECT 1 FROM public.subjects sj
     JOIN public.user_subjects us
       ON us.subject_id=sj.id AND us.user_id=p.owner
     JOIN private.iclub_subject_slot_selections slot
       ON slot.user_id=p.owner AND slot.subject_key=sj.subject_key
     JOIN private.iclub_ai_v21_home_synthetic_access local_grant
       ON local_grant.user_id=p.owner
       AND local_grant.subject_key=sj.subject_key
       AND local_grant.intent=us.mode AND local_grant.allowed=true
     JOIN private.iclub_ai_v21_home_source_test_releases src
       ON src.locale=p.locale AND src.subject_key=sj.subject_key
       AND src.action_code=a."actionCode"
     WHERE sj.subject_key=a."subjectKey" AND sj.is_active=true
       AND us.mode=CASE WHEN a."actionCode"='review_open_tour_archive'
                    THEN 'competitive' ELSE 'study' END
       AND slot.study_selected=true
       AND (us.mode='study' OR
        (sj.type='main' AND slot.competitive_selected=true))
       AND src.rights_approved=true AND src.content_approved=true
       AND src.revoked_at IS NULL AND src.source_hash=a."sourceHash"
       AND src.source_version=a."sourceVersion"
       AND (public.get_iclub_subject_access_guard_service_v1(
            p.owner,sj.subject_key,'open')->>'mode')='commercial'
       AND (public.get_iclub_subject_access_guard_service_v1(
            p.owner,sj.subject_key,'open')->>'allowed')='true'
       AND (
         (a."actionCode"='review_finalized_practice' AND EXISTS(
           SELECT 1 FROM public.practice_sessions_v4 ps
           JOIN public.practice_session_answers_v4 answer
             ON answer.session_id=ps.id
           WHERE ps.id=substring(a."actionId" FROM '_([0-9]+)$')::bigint
             AND ps.subject_id=sj.id AND ps.user_id=p.owner
             AND ps.status='finalized' AND ps.finalized_at IS NOT NULL
             AND extract(epoch from ps.finalized_at)::bigint=a."evidenceRevision"
             AND answer.is_correct=false AND answer.answered_at IS NOT NULL
             AND answer.question_id=ANY(ps.question_ids)))
         OR (a."actionCode"='review_open_tour_archive' AND EXISTS(
           SELECT 1 FROM public.tour_attempts ta
           JOIN public.tours t ON t.id=ta.tour_id
           JOIN public.tour_session_runtime_v4 rt ON rt.attempt_id=ta.id
           WHERE ta.id=substring(a."actionId" FROM '_([0-9]+)$')::bigint
             AND ta.user_id=p.owner AND t.subject_id=sj.id
             AND ta.status IN ('submitted','time_expired')
             AND t.end_date < (now() AT TIME ZONE 'Asia/Tashkent')::date
             AND rt.user_id=ta.user_id AND rt.tour_id=ta.tour_id
             AND rt.finalized_at IS NOT NULL
             AND extract(epoch from rt.finalized_at)::bigint=a."evidenceRevision"))
         OR (a."actionCode"='continue_enrolled_subject'
           AND sj.id=substring(a."actionId" FROM '_([0-9]+)$')::bigint
           AND a."evidenceRevision"=p.revision)
       )
    )
   )
)::text AS still_authorized;
