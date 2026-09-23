-- DRAFT ONLY: future assessment-composition governance. NOT a production migration.
-- Do NOT run without independently approved academic reviewer workflow, schema
-- rehearsal, exact backup/rollback and owner permission. Existing published
-- P1/P5 rows and their historical NULL/inherited timestamps remain unchanged.
BEGIN;
DO $pre$
BEGIN
 IF to_regclass('private.exam_prep_assessment_composition_reviews_v1') IS NOT NULL
 OR to_regprocedure('private.exam_prep_assessment_publish_provenance_guard_v1()') IS NOT NULL THEN
  RAISE EXCEPTION 'assessment_provenance_guard_not_pristine';
 END IF;
 IF to_regclass('private.exam_prep_assessments') IS NULL
 OR to_regclass('private.exam_prep_assessment_items') IS NULL
 OR to_regprocedure('private.exam_prep_audit_row_change_v1()') IS NULL
 OR to_regprocedure('private.exam_prep_block_immutable_mutation_v1()') IS NULL THEN
  RAISE EXCEPTION 'assessment_provenance_guard_dependencies_missing';
 END IF;
END;$pre$;

-- One new, private, append-only composition-specific sign-off fact. This table
-- records an operator-supplied human evidence reference; the DB cannot certify
-- that a real external person signed it. The operator must verify it separately.
CREATE TABLE private.exam_prep_assessment_composition_reviews_v1 (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 assessment_id bigint NOT NULL REFERENCES private.exam_prep_assessments(id) ON DELETE RESTRICT,
 assessment_version text NOT NULL,
 composition_md5 text NOT NULL CHECK (composition_md5 ~ '^[a-f0-9]{32}$'),
 reviewer_ref text NOT NULL CHECK (char_length(trim(reviewer_ref)) BETWEEN 3 AND 200),
 evidence_ref text NOT NULL CHECK (char_length(trim(evidence_ref)) BETWEEN 12 AND 600),
 reviewed_at timestamptz NOT NULL,
 recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 verdict text NOT NULL CHECK (verdict IN ('approved','rejected')),
 CHECK (reviewed_at <= recorded_at),
 UNIQUE (assessment_id,assessment_version,composition_md5,reviewer_ref,reviewed_at)
);
ALTER TABLE private.exam_prep_assessment_composition_reviews_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_assessment_composition_reviews_v1 FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER exam_prep_assessment_composition_reviews_immutable_v1
 BEFORE UPDATE OR DELETE ON private.exam_prep_assessment_composition_reviews_v1
 FOR EACH ROW EXECUTE FUNCTION private.exam_prep_block_immutable_mutation_v1();
CREATE TRIGGER exam_prep_assessment_composition_reviews_audit_v1
 AFTER INSERT ON private.exam_prep_assessment_composition_reviews_v1
 FOR EACH ROW EXECUTE FUNCTION private.exam_prep_audit_row_change_v1();

CREATE FUNCTION private.exam_prep_assessment_publish_provenance_guard_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $guard$
DECLARE v_count integer; v_hash text;
BEGIN
 IF tg_op='INSERT' THEN
  IF NEW.status<>'draft' THEN
   RAISE EXCEPTION 'assessment_must_start_draft_before_composition_review';
  END IF;
  RETURN NEW;
 END IF;
 IF OLD.status='published' AND NEW.status='published' AND
    NEW.approved_at IS DISTINCT FROM OLD.approved_at THEN
  RAISE EXCEPTION 'published_assessment_approval_date_is_historical';
 END IF;
 IF NEW.status IN ('approved','published') AND NEW.status IS DISTINCT FROM OLD.status THEN
  IF NEW.approved_at IS NULL OR NEW.approved_at<NEW.created_at THEN
   RAISE EXCEPTION 'assessment_composition_approval_time_missing_or_inherited';
  END IF;
  SELECT count(*),md5(string_agg(md5(to_jsonb(i)::text),'' ORDER BY i.item_order))
   INTO v_count,v_hash FROM private.exam_prep_assessment_items i WHERE i.assessment_id=NEW.id;
  IF v_count<1 OR v_hash IS NULL THEN
   RAISE EXCEPTION 'assessment_composition_missing';
  END IF;
  IF NOT EXISTS (
   SELECT 1 FROM private.exam_prep_assessment_composition_reviews_v1 r
   WHERE r.assessment_id=NEW.id AND r.assessment_version=NEW.assessment_version
     AND r.composition_md5=v_hash AND r.verdict='approved'
     AND r.reviewed_at=NEW.approved_at AND r.reviewed_at>=NEW.created_at
     AND r.recorded_at<=clock_timestamp()
  ) THEN
   RAISE EXCEPTION 'assessment_composition_independent_review_missing';
  END IF;
 END IF;
 RETURN NEW;
END;$guard$;
REVOKE ALL ON FUNCTION private.exam_prep_assessment_publish_provenance_guard_v1()
 FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER exam_prep_assessment_publish_provenance_guard_v1
 BEFORE INSERT OR UPDATE OF status,approved_at ON private.exam_prep_assessments
 FOR EACH ROW EXECUTE FUNCTION private.exam_prep_assessment_publish_provenance_guard_v1();

-- Once approved/published, composition cannot be rewritten underneath a signed
-- fingerprint. Changes require a new draft assessment version and fresh review.
CREATE FUNCTION private.exam_prep_assessment_frozen_items_guard_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $guard$
DECLARE v_id bigint; v_state text;
BEGIN
 v_id:=CASE WHEN tg_op='INSERT' THEN NEW.assessment_id ELSE OLD.assessment_id END;
 SELECT a.status INTO v_state FROM private.exam_prep_assessments a WHERE a.id=v_id;
 IF v_state IN ('approved','published') THEN
  RAISE EXCEPTION 'assessment_approved_composition_is_frozen';
 END IF;
 RETURN CASE WHEN tg_op='DELETE' THEN OLD ELSE NEW END;
END;$guard$;
REVOKE ALL ON FUNCTION private.exam_prep_assessment_frozen_items_guard_v1()
 FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER exam_prep_assessment_frozen_items_guard_v1
 BEFORE INSERT OR UPDATE OR DELETE ON private.exam_prep_assessment_items
 FOR EACH ROW EXECUTE FUNCTION private.exam_prep_assessment_frozen_items_guard_v1();
COMMIT;
