-- Mathematics Practice editorial31 original published content-hash preflight.
-- SELECT ONLY. Pins from hosted PG17 snapshot 2026-11-20; no stems,
-- answers, tokens, PII or closed bank texts. Repeat immediately before a GO.
WITH expected(id, content_hash) AS (
 VALUES
 (7506::bigint,'f3d5b3a0c71cf4cd6cb5c04f3acac038f44985b1e10f4f4d5898b9e49971b79a'::text),
 (7553::bigint,'1d9cb30a2754fa7460d60adf2d4cc2fdd186e9768ec7ba20939698fa7eb82eea'::text),
 (7555::bigint,'400eb65a72828fce00a6a17fe9006fba2aec2d517fbdc89d87811ef477ef6ed6'::text),
 (7556::bigint,'7177974fd4bff1161fd092aa7a2b05f842c5c3e33816ff5946dd974c84c05bbf'::text),
 (7558::bigint,'671d922e8613eba51d8fbce8cb922d6bc99a96a0f1c7e7fcb1fbb3c9d8097272'::text),
 (7559::bigint,'cabff089ace69b7db9cabd33bdf72afe29f9cfba1a2d4e236cc3b5404f6e10e6'::text),
 (7562::bigint,'951ba9ba48ef6a040cc3af66223cba94f2eb05fca56683ccfa2c908a6be4d43d'::text),
 (7565::bigint,'7d4e20c49e890c7036df1b5cf3c7fd36c28829815689bb111ef86cd7020d0fe5'::text),
 (7569::bigint,'c60385b5525b63ac722d04a4b329ebe80c04cc6bc2deb741a22b5d6b47b8f911'::text),
 (7570::bigint,'3f280ef7d1229afe2723d15f9bbf4d8b520074b8cbd611432c5246a4500b62da'::text),
 (7581::bigint,'28210c571986a870b0ad49bdf860b510cd732d416d4a6e61db8d7388f414a945'::text),
 (7586::bigint,'f03201c39632f11904d6516f5cae49065ec99c7dd7509d73e5eb934f47722bba'::text),
 (7587::bigint,'359bfc5c8c805d5ac6e69c0fd6ba5e15b57f0127aaa3bba3c7a2d213780da9a1'::text),
 (7590::bigint,'050718c7b9e97653b304925ad02c793564e740c1e5731df3bc958680ef279c42'::text),
 (7591::bigint,'9129af66b20e3f9582e3a73e3c3586e33d0bec97af9dbb43a11d3a6557f950b2'::text),
 (7593::bigint,'654bf9ea568ad59b940d2af4fa515d52dfffebb434f708f45fb886b9060b6d26'::text),
 (7594::bigint,'b63c7f761275cd261a3575d45d815fc2e599f26524a57a1d9979f15353edd5ba'::text),
 (7597::bigint,'961f71f691903ad1d3d8af7e99e306c9384740990f0e3eb9ab607a09288a735c'::text),
 (7598::bigint,'e3bc33f520362ad809b0dfb1e9de702619425a73f48ebec2c839c056ecf69744'::text),
 (7599::bigint,'3dfb9c53c7d8ccaa800e18c1b571cde86edf7d381f3125fe5f4c5fa04fc34843'::text),
 (7710::bigint,'19928acd031087d741fe251b9fc4bb6f7b0f11e4840d89a61133a8ad3fe7feb6'::text),
 (7714::bigint,'cc6db4cfee0b8f03a3d2eac20e1072d25f690231ea96df6b063d6c7273f15759'::text),
 (7727::bigint,'12cb40ca98e1b9254c008870e3c5dfd4a61c3059bc6d8eebe960c5317ad3fcab'::text),
 (7754::bigint,'62624dc52cfc7d8cc4858da517213efb44a849644c3f9258d52efdf072f235a5'::text),
 (7761::bigint,'435daca251d04e28cae53db5a20047f76edc2586a92eb30860e97971a89b499e'::text),
 (7796::bigint,'4b6570d98de8656c449f56dff7b0a1452f176af554758f377f1c4b43086b25c6'::text),
 (7809::bigint,'5fcb36c761ecc3b03ea10dfe3c62650bc4ee5543c59d54b9f9d41dea970633b2'::text),
 (7818::bigint,'c963bf29e6652acab2bbbd227fdcaa17b927ca415b6113c1f87b335e75184f4a'::text),
 (7838::bigint,'cb9e5d82eb02aa4083fd6bb6a31d3639ab079163ddfc401f9e9288c3dc91baec'::text),
 (7900::bigint,'bb1a52aceeffe34c6478ac59e0561c249d4ac78ae852c839fe6ce5fdb8cfbeec'::text),
 (7965::bigint,'600d6bd3df9bc1409c72ece9fd249095b44101858c378d040b84b36ce9b5201e'::text)
),
actual AS (
 SELECT e.id, e.content_hash AS expected_hash,m.content_hash AS current_hash,
   q.is_active, q.quality_status,m.lifecycle_state,m.is_runtime_allowed
 FROM expected e
 LEFT JOIN public.questions q ON q.id=e.id AND q.subject_id=5
 LEFT JOIN private.practice_v2_question_meta m ON m.question_id=q.id
)
SELECT count(*) AS expected_rows,
 count(*) FILTER (WHERE expected_hash=current_hash
   AND is_active=true AND quality_status='published'
   AND lifecycle_state='published' AND is_runtime_allowed=true)
   AS unchanged_published_rows,
 count(*) FILTER (WHERE expected_hash IS DISTINCT FROM current_hash
   OR current_hash IS NULL) AS changed_or_missing_rows
FROM actual;
