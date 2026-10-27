# iClub Chemistry 9701 — J-11: Composite Library + Main Compatibility Checkpoint (2026-10-27)

**Verdict: NO GO for Chemistry learner launch; code/data preparation continues safely.**
Existing branch reused: `work/chemistry-9701-j02-auth-host-20261026`.
No new branch, merge/PR, Vercel deployment, student enrollment, release flag flip, mutation/deletion of Maths/Practice/Tours history or localStorage.

## 1. Actual source release contract (hard discovery)

Existing Chemistry library release record: version `chemistry9701_20261022_stageb_draft`; declared package **166 skills**; status `draft`, `validated_at=NULL`, `private.iclub_subject_library.active_version=NULL`, `visible_to_learners=false`.

The package consists of two **distinct** stores:
- **154** regular Theory source cards, all **154×3 = 462** locale-specific Tutor records (EN/RU/UZ), mapped to syllabus skills (91 AS, 63 A Level), 37 syllabus units. Full title/explanation presence, theory/tutor source-hash matches and tour/syllabus-point mappings all passed structural checks.
- **12** cross-tour LAB cards, **6 AS Paper 3 and 6 A Level Paper 5**; separate `private.iclub_subject_library_cross_tour_v1`. All 12 have three locale keys and Tutor payload keys; all remain draft. They are NOT duplicated in the regular Theory table nor in the regular Exam Core skill map. These are distinct lab components, not extra Paper 1 questions.

**Existing generic publisher limitation:** `public.iclub_subject_library_publish_service_v1` counts ONLY rows in `private.iclub_subject_library_theory` when checking `expected_skills`. It sees **154** but the owner package definition is **166**, thus its own validation would reject publication. **Do not change expected_skills from 166 to 154** or silently drop the 12 practical components; that would hide a product/content mismatch. Do not call the publishing function as a QA dry run because it also sets `visible_to_learners=true` on successful validation.

**New additive safety migration:** `private.iclub_exam_chemistry_j11_release_readiness_v1`, `security_invoker=true`, metadata-only, private service role SELECT only. It verifies 154+12 sources, 91 regular AS skills, 6 P3 LAB + 6 P5 LAB, theory locale/linked Tutor hash completeness and cross-component locale structure; reports `full_package_source_integrity=true` but **`generic_publisher_compatible=false`**, no release validation, owner approval false, beta false and a blocked decision. This view never publishes anything.

**Remaining backend implementation before an eventual GO:** a scoped composite Chemistry library release contract/adapter that validates BOTH independent stores, retains correct P3/P5 separation and rights approval, and is reversible without losing legacy data. Do not replace the generic publisher or prematurely activate the library/Exam Core. Obtain an explicit owner release decision after real-account QA.

## 2. Current `main` vs Chemistry branch safety

Found real divergence during J-11: main received newer live protections, including answer preservation / recovery in Mathematics, retest workflow work, Economics foundation diagnosis-first flow and updated Economics UI. Blindly merging or overwriting shared files from the Chemistry branch could regress active real users.

Verified common Git merge ancestor `564a927e2e8bc0c49944a017fa30e78a95c6dc36`. The Chemistry branch had NOT changed `exam-prep/exam-prep-api.js`, `exam-prep/exam-prep-live.js`, `exam-prep/exam-prep-economics-native.css` or `docs/exam-prep-multisubject-shell-contract-v1.json` relative to that ancestor; the branch Economics native file differed only in an English-localization source line while `main` had a much newer UI.

**Performed selective sync of five shared files INTO THE EXISTING CHEMISTRY BRANCH ONLY** using exact GitHub file SHA compare-and-set; never changed `main`:
- `exam-prep/exam-prep-api.js`
- `exam-prep/exam-prep-live.js`
- `exam-prep/exam-prep-economics-native.js`
- `exam-prep/exam-prep-economics-native.css`
- `docs/exam-prep-multisubject-shell-contract-v1.json`

Also updated ONLY three shared loader references in **branch** `index.html` to their latest `main` asset cache versions: Mathematics Exam Prep API (answer protection), Economics native JS, and Economics native CSS. Preserved isolated Chemistry P1/ENTRY/RECHECK script assets, the Chemistry modified shared Host and Host CSS. No other existing script, localization or localStorage changes made by J11.

At checkpoint (live main changes frequently): comparison against `main` at **`63099eaff54ba11b79203704f6340db4ff026173`** reported work branch ahead 90 / behind 35; all five synced shared source files had the exact same current GitHub blob SHA as `main` at check time. Other new main migrations/workflows were **NOT** cherry-picked, squashed, reverted or overwritten. **This is selective preservation, NOT a completed branch reconciliation.** Before final integration, redo full merge diff and safeguard any newer main changes.

## 3. Source policies aligned

Consulted project-owned documents `04_Content_Governance_Model_P1_P5_v1.1` and `07_Beta_Release_Plan_P1_P5_v1.1`, plus `Tour Map v1.0 — Chemistry`. The first two apply normatively to Mathematics P1/P5 and inform the **analogous** safe Chemistry release policy; they are not incorrectly relabelled as Chemistry-specific syllabus authority. Core principles retained: independently authored learner questions, provenance/copyright firewall, explicit release gates, preservation of historical attempts, 3-language QA, controlled consent, isolated static/synthetic preflight, backup/recovery baseline and kill-switch rollback. Chemistry syllabus skill map stays the authority for Chemistry outcomes; the older 7-tour map is contextual, not a substitute for the 9701 syllabus.

**Rights and account approval are NOT inferred** from structural completeness, and 154/154 Tutor records per locale are not external subject-matter certification.

## 4. Current test evidence

- New repeatable SQL `scripts/qa-chemistry-9701-j11-composite-release-readonly.sql`: **42/42 PASS**, including the deliberate generic publisher compatibility **FAIL** as a correctly recognized blocker.
- Retested J04 (**32/32**), J08 (**39/39**), J09 (**36/36**), J10 (**41/41**) against live database after the shared-file sync: **190/190 PASS** overall.
- Retested synthetic JS UI after new Economics/Mathematics shared code sync: J08 **11/11**, J09 **16/16**, J10 **16/16**; all **43/43 PASS**. Seven JS files compiled, eight loader/shared-source assertions passed.
- Extra `BEGIN/ROLLBACK` role tests: `anon` and `authenticated` cannot execute the publisher/hide services or view the private preflight; user-facing Chemistry entry/recheck remain unavailable. These role checks are **not a substitute for a real browser session**.
- Production state unchanged: Chemistry `draft/OFF`, library hidden, no releases, Entry/Recheck/P1 attempts **0** and Chemistry beta enrollment **0**. Mathematics **544 sessions/1,979 responses**, Practice **502 attempts/4,816 answers**, Economics native attempts preserved, previous P1 originals and old Chemistry unpublished variants all retained.
- Supabase advisor returned no findings specifically on new J11 private readiness view; pre-existing private RLS INFO and authenticated SEC DEFINER WARN remain under their explicit authorization checks.

## 5. J-12 requirements / unresolved gates

1. Prepare a **composite 166-card Chemistry-only validation/publisher design** with rollback/hide strategy; do not change generic publisher, label 166 as 154, or auto-publish. Explicit sign-off before any publication.
2. Run **real desktop/mobile browser acceptance** on an isolated preview with an **explicitly consenting** Mathematics beta user eligible for Chemistry, ensuring no cross-account access, pause/resume, timing, low bandwidth, keyboard and screen-reader behavior, all three locales, Theory/LAB separation, and actual no-progress-loss through Mathematics/Economics/Practice. **No authenticated browser UI was available in this J11 session; do not claim it has been completed.**
3. Verify current Supabase backup/recovery point, production deployment SHA, and the migration ledger before any actual controlled rollout; those are release blocking prerequisites.
4. Audit all newer `main` scripts, workflows, migrations and index changes for compatibility, then implement a safeguarded reconciliation on the **same** work branch; never overwrite production using the stale branch tree.
5. Owner GO must be explicit for Theory package and separate Entry, Recheck and P1 releases. No implicit Math Beta cohort enrollments. AI Tutor remains gated by its independent feature flag; no mastery from a single question.

**No production release, browser-authenticated Chemistry session, data deletion, or PR/merge has occurred as part of J11.**
