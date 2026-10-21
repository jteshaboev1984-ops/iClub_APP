# iClub Universal Subject Library — versioned release protocol v1
Status: production infrastructure installed, Economics staged for gated publication.
Owner-approved content rights: Economics 9708, 2026-10-21.

## Design boundaries
- Store all subjects in private.iclub_subject_library*, separate from Mathematics P1/P5 Exam Prep.
- Do not edit user progress, results, attempts, question IDs, certificates, existing P1/P5 tables or localStorage.
- A subject uses the existing public.subjects.subject_key (biology, chemistry, economics, informatics, mathematics).
- One immutable release per subject/version. Three required locales en/ru/uz for each Theory skill, exactly three Tutor records, canonical Theory hashes and matching Tutor source-card hashes.
- Release is initially invisible. The only normal activation is public.iclub_subject_library_publish_service_v1(subject,version,package_sha256) after exact cardinality/link checks.
- Roll back immediately with public.iclub_subject_library_hide_service_v1(subject); this never deletes content or learner data.
- Direct release flag edits by service_role are revoked. No browser access to private storage or service-only RPCs.

## Learner access
- Authenticated users with a matching public.user_subjects selection for the active public.subjects row can call public.get_my_subject_learning_catalog_v1 and public.get_my_subject_learning_content_v1.
- Anon or nonselected users are denied; an unpublished release returns {}.
- The optional subject-learning-ui.js appears in the existing subject hub only when a catalog is available. Reading content does not affect assessments or learning progress.
- Mathematics Exam Prep remains separate and unchanged.

## Reusable future-subject workflow
1. Create original Theory and Tutor JSON with the same exact fields as the validated Economics package, for all three languages and for the existing subject_key. Retain source/history, rights and syllabus documentation.
2. Run scripts/subject-release-packager.py with --theory, --tutor, --subject, --version, --title-en/ru/uz, --out. Any duplicate key, missing locale, empty field, source hash mismatch or modified source bytes must fail.
3. Review manifest.json (SHA256 source files, package digest, exact counts); upload the generated 00 registry SQL, numbered Theory SQL chunks, then numbered Tutor SQL chunks, all into the hidden release. No DELETE or UPDATE of existing release cards.
4. Run the 99 read-only postcheck and independently verify zero missing locale groups and source hash mismatches. Run role/RLS/security tests and responsive UI QA for the new subject.
5. Only then call publish_service_v1 with the exact package digest. Confirm the subject catalog and signed-in UI for en/ru/uz in production. Keep the previous version and the instant hide function for rollback.
6. Never claim expert sign-offs or a published release before those events actually occur.

## Economics v1 source
- subject_key: economics
- version_key: economics9708_20261021_p62
- expected Theory skills: 498
- expected Tutor locale records: 1494
- source package digest: 1374252abbc06dcd5268fe1869335e0087037c4208af9dd12f639c1ecb6bc9f7
- initial candidate: iClub_Economics_9708_Phase62_Numeric_Rights_Triage_OFFLINE_NO_GO.zip
- Rollback does not alter older releases, Mathematics or student data.
