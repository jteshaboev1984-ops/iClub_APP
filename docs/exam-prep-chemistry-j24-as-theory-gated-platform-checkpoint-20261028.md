# Chemistry 9701 J24 — AS-only Theory gated read path (technical checkpoint)
Date: 2026-10-28. **This is NOT Chemistry learner publication.**

## Production-safe changes actually completed
- An additive Supabase migration `20261028145137_chemistry_9701_j24_as_only_theory_fail_closed_v1` **was applied successfully** to project `mmmduffgpvwjdpruzikw`. Its exact source is versioned at `supabase/migrations/20261028145137_chemistry_9701_j24_as_only_theory_fail_closed_v1.sql`.
- Added a private, FORCE-RLS `private.iclub_exam_chemistry_j24_as_theory_control_v1` with independent **enabled=false** gate.
- Added two authenticated-only RPCs: `public.iclub_exam_chemistry_j24_theory_catalog_v1(text)` and `public.iclub_exam_chemistry_j24_theory_lesson_v1(text,text)`.
- These RPCs require a current active Mathematics Beta participant with Chemistry subject enrollment, **separate** Chemistry consent and owner approval; a signed-off exact 91-item AS manifest; scientific and trilingual review timestamps; owner rights and backup-deferral acknowledgments, version/source hash match; and **no active protected exam**. Neither RPC returns Tutor, answer keys, A Level content or mastery credit.
- A single `CHEM9701-10-04` enrichment record is exposed as `is_syllabus_outcome=false`, not independently assessable; 90 remaining AS topics are true candidates pending complete content review.
- Empty or missing proof data keeps access disabled. No J12 backup_restore flag was falsified, no automatic consent or beta membership created.

## Read-only post-deployment observations
- `as_theory_enabled=false`, Chemistry beta membership count = **0**, legacy `can_publish=false`.
- Unauthenticated catalog and lesson each returned `not_available`.
- `anon` EXECUTE privilege on both new RPCs = **false**, authenticated on catalog = **true** with independent server authorization.
- Mathematics `private.exam_prep_responses` remained at **1,987** at first post-migration read; Practice answers were **4,876** (counts may naturally increase). No user records were updated by this migration.
- Legacy read-only Chemistry J12 **64/64** and J13 **44/44** checks rerun after migration: **108/108 PASS**.

## Isolated technical tests
- GitHub Actions synthetic PostgreSQL 17 `j24-as-only-firewall` passed before production installation (3 successful checks across source PR validation). Rehearsal generated 91 AS cards plus a fake A Level card and tested: gate OFF by default, no-JWT denial, anon execution denial, one unscored enrichment, exact 91 topic count, A Level denial, invalid locale, active exam denial, revoked consent and stale manifest rejection. No real learner records were copied or used.
- A native Chemistry Theory module was staged (not released): `exam-prep/exam-prep-chemistry-theory-native.js`, 3 locales, 5 subject sections, safe `textContent`, accessible buttons, phone layout, no localStorage. Integrated in the PR's host and index **behind** the remote 91-card authorization response. There is no user-visible change while the gate remains OFF.
- A 20-assertion synthetic UI regression is staged; ten equivalent static/live JS checks were exercised directly with 10/10 PASS. Full PR CI remains subject to the current source SHA.

## Academic J23 progress
- 91/91 AS cards have source/locale numeric triage; 84 direct token parity and seven manually investigated notational differences.
- An additional **16 high-risk English explanations** were checked for equation balance, reaction conditions, oxidation-state, chemical-structure and numerical plausibility. Results in `docs/exam-prep-chemistry-j23-scientific-check-highrisk-16-20261028.csv`. This does **not** certify all 91 lessons or three-language meaning.
- The original failed P1 question remains held and unchanged. Its versioned source-skill correction script is **prepared but NOT APPLIED** because the earlier source-write path was blocked. No source item was marked academically approved without a fresh review.
- The supplied Chemistry Tour Map v1.1 DOCX was corrected to display the proper v1.1 heading (the prior file still showed v1.0); the original document was not modified in place.

## Release decision
**J24 backend infrastructure READY but feature OFF.** The PR remains DRAFT and must pass all relevant CI and protected Preview QA before client code reaches production. Releasing AS Theory requires 91/91 semantic science/language reviews, an exact 91-source manifest, one eligible/consenting canary learner and separate owner go. Papers 1/3/5, Tutor, Chemistry Entry/Recheck remain OFF. No production learner progress or browser data reset.


## J25 architecture update — replaces consent policy, 2026-10-28
Owner rejected all learner invites, Chemistry-specific consent screens and opt-in tables for beta and release. J24's **installed** authorization function remains fail-closed until a separately versioned J25 server rollout migration is tested/applied. The new J25 candidate makes `closed` the default; `beta` permits only authenticated active Chemistry subject members of the existing active Mathematics beta cohort (owner-controlled test accounts); `released` permits authenticated active Chemistry subject members. Both require J24 enabled, signed 91/91 reviewed content, source manifest match, and no active protected examination. No student account, attempt, grade, localStorage, Practice or Tours rows are changed. References earlier in this document to separate consent and canary consent are historical and not release requirements.
