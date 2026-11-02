#!/usr/bin/env bash
# Issue #450, Math P1/P5 Package 0: ISOLATED SYNTHETIC ONLY backup-restore test.
# No production data may be supplied.
set -euo pipefail
test "$P1P5_E2E_ISOLATED" = "true"
test "$PGHOST" = "127.0.0.1"
test "$PGPORT" = "5432"
test "$PGDATABASE" = "postgres"
test "$PGUSER" = "postgres"

psql -X -v ON_ERROR_STOP=1 -q -c "
DO \$\$
BEGIN
 IF (SELECT count(*) FROM public.users) <> 2 OR
    (SELECT count(*) FROM auth.users) <> 2 OR
    NOT EXISTS(SELECT 1 FROM public.users WHERE id='11111111-1111-4111-8111-111111111191'::uuid) OR
    NOT EXISTS(SELECT 1 FROM public.users WHERE id='22222222-2222-4222-8222-222222222292'::uuid)
 THEN RAISE EXCEPTION 'REFUSED: only 2 known synthetic CI accounts permitted'; END IF;
END
\$\$;
"

restore_db="iclub_p0_synthetic_restore"
archive="$(mktemp /tmp/p1p5-package0-fake-only-XXXXXX.dump)"
trap 'dropdb --if-exists --force "$restore_db" >/dev/null 2>&1 || true; rm -f "$archive"' EXIT
if psql -At -d postgres -c "SELECT 1 FROM pg_database WHERE datname='$restore_db';" | grep -q 1; then
  echo 'REFUSED: restore database unexpectedly already exists' >&2
  exit 1
fi
pg_dump --format=custom --no-owner --no-acl --dbname=postgres --file="$archive"
test -s "$archive"
createdb --template=template0 "$restore_db"
pg_restore --no-owner --no-acl --exit-on-error --dbname="$restore_db" "$archive"

fingerprint_query=$(cat <<'SQL'
SELECT jsonb_build_object(
 'auth_users',(SELECT md5(coalesce(string_agg(id::text,',' ORDER BY id),'')) FROM auth.users),
 'public_users',(SELECT md5(coalesce(string_agg(id::text,',' ORDER BY id),'')) FROM public.users),
 'exam_sessions',(SELECT md5(coalesce(string_agg(id::text||':'||status,',' ORDER BY id),'')) FROM private.exam_prep_sessions),
 'exam_auth',(SELECT md5(coalesce(string_agg(id::text||':'||status,',' ORDER BY id),'')) FROM private.exam_prep_session_authorizations),
 'exam_responses',(SELECT md5(coalesce(string_agg(id::text||':'||user_id::text,',' ORDER BY id),'')) FROM private.exam_prep_responses),
 'exam_evidence',(SELECT md5(coalesce(string_agg(id::text||':'||user_id::text,',' ORDER BY id),'')) FROM private.exam_prep_evidence_events),
 'exam_skills',(SELECT count(*) FROM private.exam_prep_skill_states),
 'exam_profiles',(SELECT count(*) FROM private.exam_prep_exam_profiles),
 'exam_assessments',(SELECT count(*) FROM private.exam_prep_assessments),
 'exam_published_content',(SELECT count(*) FROM private.exam_prep_content_versions WHERE status='published'),
 'beta_consents',(SELECT count(*) FROM private.exam_prep_beta_consents),
 'ai_grants',(SELECT count(*) FROM private.exam_prep_feature_entitlements WHERE ai_assist AND entitlement_status='active'),
 'practice_attempts',(SELECT count(*) FROM public.practice_attempts),
 'tour_attempts',(SELECT count(*) FROM public.tour_attempts),
 'certificates',(SELECT count(*) FROM public.certificates)
)::text;
SQL
)
before="$(psql -X -At -v ON_ERROR_STOP=1 -d postgres -c "$fingerprint_query")"
after="$(psql -X -At -v ON_ERROR_STOP=1 -d "$restore_db" -c "$fingerprint_query")"
if [[ "$before" != "$after" ]]; then
  echo 'FAIL: full synthetic backup/restore fingerprint differs' >&2
  exit 1
fi
echo "PASS: synthetic-only PG17 backup restored to independent DB; exact account, academic, content and protected fingerprints match"
