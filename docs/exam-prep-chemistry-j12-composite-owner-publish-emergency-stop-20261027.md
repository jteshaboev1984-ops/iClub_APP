# iClub Chemistry Cambridge 9701 — J-12, guarded composite release and emergency recovery (2026-10-27)

**Release verdict: NO GO.** Administrative publication code was installed privately in Supabase but left **UNARMED**. No learner content published, no GO claimed, no real student enrolled, no production web deployment, no PR or merge. Work stays in the **existing** `work/chemistry-9701-j02-auth-host-20261026` branch.

## 1. 166-component release contract

The existing Chemistry package `chemistry9701_20261022_stageb_draft` is **154 Theory cards + 12 separate practical/cross-tour lab cards**, with **462 trilingual Tutor records** and 12 trilingual LAB companion Tutor payloads. Of the 12 labs, six map to AS Paper 3 and six to A Level Paper 5. Main Theory/Tutor cards cover 91 AS skills and 63 A Level skills. The old generic `public.iclub_subject_library_publish_service_v1` expects all 166 cards in the Theory table (which has only 154) and must **NOT** be used to release this package or be tricked by lowering `expected_skills` to 154.

Implemented **private and fail-closed** `private.iclub_exam_chemistry_j12_release_control_v1`, plus metadata-only `private.iclub_exam_chemistry_j12_release_gate_v1`. A composite source digest covers **the actual EN/RU/UZ source JSON of 154 lessons, all 462 Tutor texts, and all 12 lab source and Tutor payloads**, including all source content hashes. An editorial change changes the digest and invalidates the previously approved fingerprint. These values and checks are private, no unpublished question stem, explanation or answer key is committed to public GitHub.

The gate requires **all distinct independent attestations**: exact package+source digest/version; explicit owner GO; content rights approval; proven backup/restore; verified LAB lesson delivery; separately isolated AI Tutor access; authenticated real-device QA; Chemistry program, ENTRY, RECHECK and P1 all in the required pre-release state. **Every sign-off and owner GO is currently absent**, `armed=false`, `can_publish=false`.

## 2. Implemented private admin operations (no real release)

- `private.iclub_exam_chemistry_j12_admin_publish_v1(version,package_digest,source_digest,owner_phrase)`: exclusive to the `postgres` administrator, `SECURITY INVOKER` (no elevated definer), no anon/authenticated/service-role EXECUTE. Fails closed without separately pinned and approved exact source, all five release validations and a one-use owner phrase. Locks approved package/source for atomicity. Only on valid explicit future GO may it validate the **154+12** package, set its 12 lab records validated, mark the Chemistry library visible and append one release event. Does **not** automatically enroll Math Beta learners or activate Chemistry Exam Prep gates. It consumes the approval to prevent accidental replay.
- `private.iclub_exam_chemistry_j12_admin_hide_v1(reason)`: narrow library-only rollback to the previously active version (initially NULL) without deletion of source or attempts; existing release-event `hide` is recorded. Does not falsely undo already reviewed content.
- `private.iclub_exam_chemistry_j12_admin_emergency_stop_v1(reason)`: a stronger **all-Chemistry kill switch**. Independently forces Chemistry Core Draft/OFF, ENTRY/OFF, RECHECK/OFF, P1/OFF, clears owner GO timestamps (necessary for the P1 table CHECK), hides Theory and restores `active_version=NULL`, disarms further publication. Retains all learner IDs, consent history, attempts, source text, package manifests and prior results. Repeat call on already closed state does not create an extra hide event.

All operations are `private` and `SECURITY INVOKER`, grant denied to anon, authenticated and service_role. Only direct database administrator can use them. Their existence in live Supabase does **not** confer consent, does not arm publication and does not expose a new browser RPC.

## 3. Identified release-critical gap: existing shared library service leaks Tutor

`public.iclub_subject_library_content_service_v1` currently returns the Theory card **together with `tutor` explanation texts** whenever `private.iclub_subject_library.visible_to_learners=true`; this shared API does not independently gate Chemistry AI Tutor. At the moment the library is hidden and no Chemistry exposure occurs. **Do not publish** until a scoped fix ensures publishing Core Theory cannot unintentionally reveal disabled AI Tutor content. Prefer narrow subject-specific semantics and regression for existing other subjects rather than a broad risky replacement.

The 12 LAB records also live in a **separate table**, not the normal learner Theory catalogue. A true delivery route and UI, maintaining Paper 3/Paper 5 distinctions and independent student access permissions, must be implemented and device-tested. A structural 12/12 pass is not proof LAB content is rendered or readable by users.

Current system does **not** grant mastery from an ENTRY/RECHECK pair of single MCQs per topic.

## 4. Actual tests performed

- **Synthetic release in one BEGIN/ROLLBACK:** publisher denied without GO; temporary *test-only* rights/owner/backup/LAB/Tutor/device signoffs allowed an atomic composite 154+12 publication and 12 validated LAB rows; repeat publication denied; emergency hide returned library to hidden without removing content. The database transaction was **rolled back completely**, not committed.
- **Tamper test in BEGIN/ROLLBACK:** temporarily changing one Tutor explanation changed the composite digest; the synthetic earlier approval stopped authorizing publication. All mutations rolled back; no source edited in the live bank.
- **Emergency stop in BEGIN/ROLLBACK:** temporarily marked the Chemistry program and three Exam Prep gates ON, invoked one admin-only stop, checked all gates OFF with their owner GO revoked, one hide event, 154+462+12 intact; second emergency stop remained idempotent. Rolled back entirely.
- **Repeatable QA script** `scripts/qa-chemistry-9701-j12-transactional-composite-release-rollback.sql` runs test-only owner approval, publication, replay denial, library hide and emergency stop under a closed-only precondition; always ends in `ROLLBACK`. It returns no sensitive question or account content.
- **Production READ-ONLY**: J04 **32/32**, J08 **39/39**, J09 **36/36**, J10 **41/41**, J11 **42/42**, J12 **64/64** = **254/254** invariant checks passed. Repeatable `scripts/qa-chemistry-9701-j12-private-composite-owner-readonly.sql` has 64 checks.
- **Synthetic client regression**: J08 **11/11**, J09 **16/16**, J10 **16/16** = **43/43**; seven JavaScript files compiled, eight Math/Econ/loader assertions passed. These are *not* a real browser or accessible device acceptance run.
- **Supabase security advisor:** one INFO for private J12 control table with FORCE RLS/no policies; intentional to block all browser role table access. No new critical J12 issues. See https://supabase.com/docs/guides/database/postgres/row-level-security .
- **Last snapshot:** Chemistry `draft/OFF`, `active_version=NULL`, library hidden, owner GO absent, release-control unarmed, `published_at=NULL`, zero Chemistry ENTRY/RECHECK/P1 attempts, zero Chemistry library publication events. Mathematics **544 sessions / 1,979 responses**, Practice **502 attempts / 4,816 responses**, all preserved.

## 5. Branch/current production boundary

Work completed **only in the existing Chemistry work branch and additive private Supabase objects**. Source `main` and Vercel production deployment were **not modified**. After the earlier J11 targeted sync, the shared current `exam-prep-api.js`, `exam-prep-live.js`, `exam-prep-economics-native.js/.css` and multisubject shell contract were matched to main, while isolated Chemistry Entry/Recheck/P1 modules remained gated. The branch still diverges from main; do not blind-merge or force-reset it. At the most recent J12 comparison, branch was ahead **97** and behind **35** commits; these counts will continue changing as main progresses.

## 6. J-13 exact next safe tasks (without GO)

1. Resolve **Chemistry-specific Tutor API access boundary**: make the shared content API return Theory-only when Chemistry AI Tutor is disabled, while preserving existing Economics/Mathematics or other subjects. Validate actual role-based authorization and localized content with rollback tests.
2. Create **12 LAB-only learner routes and UI** with exact Paper 3/Paper 5 section roles and rights gates; do not claim they are official hands-on practical exam substitutes. Integrate with existing subject learning navigation only after destination ownership/permission confirmed.
3. Real preview/browser test using an actual, explicitly consenting current Math Beta account: keyboard, smartphone, screen-reader, internet interruption, account separation, all EN/RU/UZ, result/history and Maths/Practice/Tours nonregression. Keep public production Chemistry hidden.
4. Verify recoverable backups, final rights sign-off, package digest, current `main` conflicts and deployment SHA. Those are owner-release blocking prerequisites.
5. Only after these pass, ask for **explicit owner GO** to approve the source digest + release scope. Never infer GO from routine “continue”, never publish or enroll learners automatically.

**J12 did not and must not be described as a live Chemistry beta launch or verified student acceptance test.**
