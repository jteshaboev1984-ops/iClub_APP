# Chemistry 9701 — current production master (16 October 2026)

**Release R5+R6 is installed and confirmed by Supabase.** This file supersedes the stale pre-release HOLD statuses in QA R4/R5/R6. It is not a claim that every item has external expert certification.

## Live app state

- Chemistry Subject ID 4: seven Practice pools, **490 available active links (7 × 70)**.
- Season 2: seven Tours with **140 active question links (7 × 20)**, still **`draft`**, not opened to students.
- Academic R5+R6: **36 unique new question IDs** installed, consisting of **30 Practice**, **6 Season 2 Tour**. A single atomic PostgreSQL migration succeeded at 2026-10-16, with scoped original membership/question snapshots and exact source checks.
- Old question IDs and old question rows are preserved; practice_answers and tour_answers unchanged. **62 historical Practice answers involving these 36 old IDs are still present**; no historical Tour answers for replaced Tour IDs.
- Formula-input replacements for original IDs **1946 and 1965** are registered through existing **Tour1 strict chemical-formula policy**, not a global scorer rewrite.
- Critical Practice4 ambiguity original **3373** is not active in the Practice pool; replacement **10062** is active.
- No GitHub main modifications, Vercel deploy, season open or learner score recalc were performed for this release.

## Academic state and limits

- R1–R3 examined the 630 original Chemistry question IDs in staged passes. **56 IDs** had documented QA observations: not necessarily 56 wrong keys.
- R5 corrected 8 of these; R6 applied 28 more; **20** had previously documented KEEP/dependency dispositions, which must remain in the QA ledger rather than be silently declared perfect.
- EN/RU/UZ editorial texts were self-verified using existing subject study materials and internal checks, not independently certified by an external chemist/native speaker.
- **User explicitly waived protected Preview/browser E2E and accepted production risk.** No authenticated end-user journey was witnessed. Production SQL includes fail-closed scorer assertions and transactional membership/count conditions; a successful DB result is not UI/E2E proof.
- New question IDs can appear as unanswered to learners who completed old IDs even though historical attempts are still in the database. Progress was **not transferred or recalculated**, and the visible effect is **not tested**. Do not claim zero UI-progress impact.
- Before Season2 public launch, separate product-level approval remains needed. Current Season2 remains `draft`.

## Reconciled traceability

- `630_Question_QA_Traceability_Ledger_v7_PRODUCTION.csv`: original 630 QA records, each with *original_qa_question_id* and *currently_active_question_id*; rows for 36 replacements now marked as installed, others preserved.
- `R56_36_VERSION_CROSSWALK.csv`: old→new exact IDs (36).
- `R56_36_ATOMIC_USER_AUTHORIZED_NOT_YET_EXECUTED.sql`: archived **executed content v2** of the authorized migration with a scoped Tour1 formula-policy adapter; the source filename was written before execution, but the DB migration `chemistry_r5_r6_consolidated_36_user_authorized_20261016_v2` returned success. Original unpatched version failed and rolled back, never published.
- Snapshots and mapping in DB: `private.chemistry_r56_backup_questions_20261016`, `private.chemistry_r56_backup_memberships_20261016`, `private.chemistry_r56_release_versions_20261016`.
- R6 editorial provenance: `Chemistry_9701_R6_Consolidated_Quality_Remediation_2026-10-16.zip`; R5 provenance: `Chemistry_9701_R5_AI_SELF_VERIFIED_Release_Review_2026-10-16.zip`.

## Next work (do not redo finished stages)

1. When user requests it, do ONE permissioned end-user Chemistry Practice/Tour smoke pass to determine whether newly assigned IDs alter visible completion and to check localization display; **do not assume it passed**.
2. Fix only concrete post-release defects, using new versions and preserved history; no new broad academic audit unless actual evidence requires it.
3. Separately decide Season2 launch timing; do not silently activate Season2.

**Current conclusion:** content corrections are live. Academic remediation R5+R6 is production-complete on the database layer; full user-facing QA remains explicitly unverified by user's choice.