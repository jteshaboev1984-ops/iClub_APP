# Mathematics P1/P5 — architect decision and practical delivery order
**2026-11-05 · Issue #450 · prelaunch planning amendment · DRAFT · no deployment**

## Architect's updated operating facts (supersedes overly cautious assumptions)

- Real usage of **Exam Prep and iClub as a whole is currently very limited**. Do not assume a busy production Exam Prep cohort or insist on months of observational beta testing.
- **All genuinely identified test data will be removed in a controlled, one-time prelaunch cleanup**, as previously decided. This is a product decision to prepare for the actual launch, **not** an instruction to delete rows now, wipe unknown real-user records, global `users`, localStorage or unrelated subject data.
- Therefore do **not** let hypothetical browser tabs, speculative old-JWT combinations, exhaustive trigger graphs or tests performed solely for their own sake distract from completing actual Mathematics teaching, practice and release features. **P0-16B is paused/deprioritized**, not falsely marked security-accepted. Existing draft implementation and signed evidence remain intact in PR #495. Its `writer_min_jwt_iat` remains NULL/OFF and must never be enabled as a hidden prelaunch prerequisite.
- Real user records, if any, remain protected until explicit one-time cleanup scope and GO. The separation between verified disposable/test rows and real user accounts/Tours/Practice v3/certificates/other subjects is still mandatory. The previous permission to **prepare** cleanup does not mean executing live DML right now.
- Minimal, meaningful deterministic acceptance and one genuine end-to-end pass are preferred over endlessly retesting identical code or artificially constructed usage.

## Accepted implementation state, not to be restarted

1. P4-01 through P4-06 written-Paper **operational** Stage3–6 architecture is already engineering accepted on isolated signed PG17. Six genuine P1/P5 full Papers were executed (three per component), writing was correctly **ungraded**, and grade/readiness remained `INSUFFICIENT_EVIDENCE`. Do not restart P4 audits.
2. The study timeline, learner-chosen P1/P5 dates, weekly/monthly-only reports and all **three opt-in study-time choices** already exist in draft code. Do not falsely mark these missing or generate replacement flows.
3. The Extra Hard noncredit, owner-only UI/database shell exists but its protected source bank is EMPTY and release OFF. The architect superseded the old lost 12 on **2026-11-06**. Exactly **12 new original Extra Hard tasks** (6 P1, 6 P5) with EN/RU/UZ solutions are authored and privately archived. All 12 computational mathematics checks passed. Do not recover old missing drafts, expose keys in GitHub or claim that new tasks are imported/published.
4. The independent evidence-based estimates for each of the 81 skills remain unapproved. Existing 2020 Cambridge topic-guided hours are a **historical reference**, not measured personal learning minutes. The already implemented voluntary approximate planning aid does not represent Cambridge's individual prescription.

## Actual remaining delivery order

**A — Academic content/product completion first.**
- Use the **newly authored** 12 original P1/P5 Extra Hard questions (6+6) and their checked EN/RU/UZ solutions in the owner's private bundle; stop searching for the superseded lost drafts. Finish controlled private versioned import, academic/noncredit and release-QA, then publish ONLY after separate GO. Never place answer text or keys in public GitHub.
- **D10-10 2026-11-06:** the five original EN/RU/UZ replacement questions are ready privately, and a **six-assessment draft versioning** mechanism (24 items) is now prepared for their protected import, not applied to production. Retain old 71 QUA diagnostic sessions and existing fallback. Publish only after separate content/release GO.
- Improve P1/P5 81-skill time estimate methodology based on actual content and observable work, and reflect uncertainty in the existing voluntary timeline. No fictitious independent-study norms, Cambridge grades or mandatory weekly quota.
- Finish the remaining product-level integration of the existing **three choices** only if an actual user-flow defect is found, rather than recreating already delivered UI/RPCs.

**B — Public Mathematics Core and subject separation.**
- Prepare the permanent owner-authenticated Math Core access route for registered Mathematics study or competitive members; remove practical UI/runtime dependency on `controlled_beta` in the candidate. Other subjects remain `В разработке`. Keep AI separate/consent-and-entitlement gated; no mandatory Mentor.
- Preserve Practice v3, Tours, ratings/certificates, Economics, Chemistry and current accounts. Only source-confirmed, user-facing regressions get fixes.

**C — Short practical acceptance + one-time prelaunch cutover.**
- One exact-source signed JWT→PostgREST→disposable PG17→real browser E2E for P1/P5 core journey, meaningful RU/UZ/EN and phone checks, access and answer-secrecy; no 4-week/72h real-user waiting rule.
- Make an **explicit snapshot and provenance manifest of every candidate test row** across Math Exam Prep and other beta/test areas; verify user ownership/relationships and cascade. Count and preview deletes; dry-run backup/restore against a disposable copy. Do not delete accounts or actual learner rows as a side effect.
- Only upon **separate architect GO**: one-time **identified test-data reset**, permanent Maths Core rollout, post-cutover proof, and rollback. Previous `NO_GO` history remains factual until this gate is met.

## P0-16B disposition

Status: **PAUSED / NOT A CURRENT DEVELOPMENT PRIORITY** (not `DONE`, not public release approval). Stop adding speculative cutover JWT writer permutations now. Return to it only on a demonstrated real conflict during the final code+data cutover or if a concrete live data-impacting defect appears. Preserve the already accepted 22 Core/Paper/settings writer guards + three read-projection fences in unmerged DRAFT PR #495; do not merge, activate or delete them as part of this reprioritization.

## Execution discipline

Work in one focused DRAFT branch based on the academically accepted P4 parent, avoiding the open independent P0 audit branch. For each real feature: source review → implement → targeted acceptance → brief Issue #450 checkpoint. Do not touch live Supabase, main, Vercel or any learner data in this planning PR. Keep the prelaunch cleanup decision visible in its designated package 8, not in a premature SQL script.
