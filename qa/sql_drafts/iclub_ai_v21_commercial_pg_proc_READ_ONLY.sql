-- §103 READ-ONLY iClub commercial API catalog drift probe.
-- Safe against existing production schema: reads only pg_proc source metadata.
-- NEVER query student records, entitlements, grants, token/user tables.
SELECT n.nspname AS schema,
       p.proname AS name,
       pg_get_function_identity_arguments(p.oid) AS identity_args,
       md5(pg_get_functiondef(p.oid)) AS definition_md5
FROM pg_catalog.pg_proc AS p
JOIN pg_catalog.pg_namespace AS n ON n.oid=p.pronamespace
WHERE n.nspname='public'
  AND p.proname IN (
    'get_iclub_subject_access_guard_service_v1',
    'get_iclub_subscription_capabilities_service_v1'
  )
ORDER BY p.proname;
