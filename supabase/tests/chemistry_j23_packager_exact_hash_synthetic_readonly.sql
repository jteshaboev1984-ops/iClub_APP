-- Zero-write postcheck semantics regression. No user or private answer content.
-- Exercises exact row, tampered text, missing row, unexpected row and real empty-stage gate.
WITH synthetic AS (
 SELECT 'SYNTH-TEST-ONLY'::text skill_key,'ru'::text locale,
 ARRAY['TEST-CARD','synthetic_v1','Synthetic title','Synthetic main','Synthetic simple',
 'Synthetic alternative','Synthetic focus','sha256:synthetic']::text[] fields
), expected AS (
 SELECT skill_key,locale,
 encode(extensions.digest(convert_to(array_to_string(fields,chr(31)),'UTF8'),'sha256'),'hex') expected_hash
 FROM synthetic
), staged AS (
 SELECT skill_key,locale,
 encode(extensions.digest(convert_to(concat_ws(chr(31),fields[1],fields[2],fields[3],fields[4],
 fields[5],fields[6],fields[7],fields[8]),'UTF8'),'sha256'),'hex') actual_hash
 FROM synthetic
), poisoned AS (
 SELECT skill_key,locale,
 encode(extensions.digest(convert_to(concat_ws(chr(31),fields[1],fields[2],fields[3],fields[4]||' changed',
 fields[5],fields[6],fields[7],fields[8]),'UTF8'),'sha256'),'hex') actual_hash
 FROM synthetic
)
SELECT
 (SELECT count(*) FROM expected e JOIN staged s USING(skill_key,locale)
  WHERE s.actual_hash=e.expected_hash) exact_rows_accepted_expected_1,
 (SELECT count(*) FROM expected e JOIN poisoned s USING(skill_key,locale)
  WHERE s.actual_hash IS DISTINCT FROM e.expected_hash) poisoned_rows_rejected_expected_1,
 (SELECT count(*) FROM expected e LEFT JOIN (SELECT * FROM staged WHERE false) s USING(skill_key,locale)
  WHERE s.actual_hash IS DISTINCT FROM e.expected_hash) missing_rows_rejected_expected_1,
 (SELECT count(*) FROM staged s LEFT JOIN (SELECT * FROM expected WHERE false) e USING(skill_key,locale)
  WHERE e.skill_key IS NULL) unexpected_rows_rejected_expected_1;
