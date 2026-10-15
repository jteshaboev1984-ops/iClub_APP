-- §§110–113: QA-only destination-screen scope. NEVER run in Supabase.
DO $guard$ BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
 THEN RAISE EXCEPTION 'STOP: disposable QA PostgreSQL only'; END IF;
END $guard$;
CREATE TABLE private.iclub_ai_v21_study_routes_scratch(
 ticket_sha256 text PRIMARY KEY CHECK(ticket_sha256 ~ '^[0-9a-f]{64}$'),
 home_handoff_sha256 text NOT NULL UNIQUE REFERENCES
  private.iclub_ai_v21_home_action_handoffs_scratch(token_sha256),
 owner_id uuid NOT NULL,
 home_context uuid NOT NULL,
 route_context uuid NOT NULL UNIQUE,
 route_revision bigint NOT NULL CHECK(route_revision>0),
 locale text NOT NULL CHECK(locale IN ('ru','uz','en')),
 action_code text NOT NULL CHECK(action_code IN
 ('review_finalized_practice','review_open_tour_archive','continue_enrolled_subject')),
 subject_key text NOT NULL,
 target_screen text NOT NULL CHECK(target_screen IN
 ('practice-review','tour-review','subject-hub')),
 object_id bigint NOT NULL CHECK(object_id>0),
 evidence_revision bigint NOT NULL CHECK(evidence_revision>0),
 source_hash text NOT NULL CHECK(source_hash ~ '^[0-9a-f]{64}$'),
 source_version text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 expires_at timestamptz NOT NULL,
 revoked_at timestamptz,
 CONSTRAINT source_scope_non_empty CHECK(length(source_version) BETWEEN 1 AND 80)
);
REVOKE ALL ON private.iclub_ai_v21_study_routes_scratch
 FROM PUBLIC,anon,authenticated;
CREATE INDEX iclub_ai_v21_study_owner_scope_scratch_idx
 ON private.iclub_ai_v21_study_routes_scratch
 (owner_id,route_context,expires_at);
