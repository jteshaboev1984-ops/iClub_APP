-- Compensating cleanup: the speculative draft-vault table was never used.
-- Original question drafts are held in the user's private ChatGPT Library.
-- Do not disturb user tables, legacy question banks, or prior migration history.
DO $$
BEGIN
  IF to_regclass('private.iclub_exam_core_authoring_blobs_v1') IS NULL THEN
    RAISE NOTICE 'Authoring vault already absent; no action';
    RETURN;
  END IF;
  IF EXISTS (SELECT 1 FROM private.iclub_exam_core_authoring_blobs_v1) THEN
    RAISE EXCEPTION 'Refuse to remove a non-empty authoring vault';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE confrelid='private.iclub_exam_core_authoring_blobs_v1'::regclass) THEN
    RAISE EXCEPTION 'Refuse to remove referenced authoring vault';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_depend d JOIN pg_rewrite rw ON rw.oid=d.objid
    WHERE d.refobjid='private.iclub_exam_core_authoring_blobs_v1'::regclass
  ) THEN RAISE EXCEPTION 'Refuse: dependent view'; END IF;
END $$;
DROP TABLE IF EXISTS private.iclub_exam_core_authoring_blobs_v1 RESTRICT;