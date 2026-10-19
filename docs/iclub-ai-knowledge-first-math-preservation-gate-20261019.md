# iClub AI v2.1 — Knowledge First × Mathematics production-preservation gate
**19 October 2026 | QA only | No production rollout or database mutation**

## Connected implementation batch
- Existing Mathematics Exam Prep P1/P5 remains independent and running. Six protected files and the original host bridge are fingerprinted; the baseline is mandatory. This is not a second Math Tutor; its three AI-entitled learners do not become Global AI users.
- The original index.html and app.js on this QA branch are pinned to the earlier production baseline. Because main advanced with Economics Gen2, the offline comparison checks these and related original files against locally fetched origin/main. Drift remains a deliberate NO_GO for promotion until explicitly reconciled. main is never overwritten by this test.
- The QA-only draft Practice context formerly proved an owned finalized answered question, but did not require that the answer be wrong. Both mint_iclub_ai_v21_practice_context_service and get_iclub_ai_v21_scoped_context_service now require a.is_correct IS FALSE and a.answered_at IS NOT NULL for the exact error-explanation route, including after awaits. Unknown, correct and unanswered answers are denied.
- A disposable PostgreSQL fixture includes a correct finalized answer which MUST be denied as an error. The static SQL regression checks both independent gates. All original scratch suites and UI/Node/Deno checks remain mandatory.
- The read-only integration report explicitly lists missing authentication/current-screen, assessment guard, entitlement, independent publication, exact source and delivery approval. It never issues user-facing content or spends money.

## Production facts checked read-only
The existing exam-prep-ai Edge is ACTIVE with JWT verification; Exam Prep Core and AI Assist are enabled for controlled beta; Mentor Care remains OFF. Three authorized learners have AI Assist. Tutor v3 offers 45 P1 plus 36 P5 active approved cards per language (RU/UZ/EN); corresponding source cards are approved. Global AI ui_enabled/gateway_enabled/generation_enabled remain false, with kill switch true. Global AI v2.1 RPCs are not deployed.

## Scope / release
Changed: isolated QA scratch SQL, disposable PostgreSQL fixture, QA tests, runner, isolated Preview workflow and this document. Unchanged: exam-prep directory, exam-prep-ai Edge Function, app.js, index.html, production migrations, existing user records, Auth, subscriptions, limits and provider credentials. QA is not a production migration.

Next major stage: reconcile the real main host with QA overlays without overwriting Economics or Mathematics; then use independently published, rights-cleared and owner-authorized General Help and precise completed Practice explanations through Knowledge First. Until dedicated approvals and actual deployment tests, learner-visible Global AI stays NO_GO.
