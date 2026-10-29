-- Closed J23 source-integrity probe; READ ONLY, not a release action.
SELECT candidate_version,skill_count,tutor_locale_count,
 theory_sha256=encode(extensions.digest(convert_to(theory_source_text,'UTF8'),'sha256'),'hex') AS theory_ok,
 tutor_sha256=encode(extensions.digest(convert_to(tutor_source_text,'UTF8'),'sha256'),'hex') AS tutor_ok,
 package_sha256=encode(extensions.digest(convert_to(theory_source_text,'UTF8')||decode('00','hex')||convert_to(tutor_source_text,'UTF8'),'sha256'),'hex') AS package_ok
FROM private.iclub_exam_chemistry_j23_as_source_bundle_v1
WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v5';
