-- Emergency CLOSED beta pause: no user data or academic source is removed.
-- Only the separately controlled new academic feature is stopped.
UPDATE private.iclub_ai_v21_academic_policy SET enabled=false,
 updated_at=clock_timestamp()
WHERE singleton=1 AND enabled AND NOT provider_enabled;

UPDATE private.iclub_ai_v21_owner_beta_source_releases SET enabled=false
WHERE enabled AND release_basis='owner_authorized_closed_beta_20261020';
