# iClub Chemistry 9701 — J-13: Independent Tutor and LAB delivery (2026-10-27)

**Result: J-13 technical implementation completed behind closed gates; learner launch remains NO GO.**
All work remained in existing branch `work/chemistry-9701-j02-auth-host-20261026` and additive, controlled Supabase schema/function updates. No main merge, production Vercel deploy, Chemistry content publication, learner enrollment, assessment release, LocalStorage migration, or historical record mutation.

## 1. Chemistry-only Tutor firewall

The legacy `public.iclub_subject_library_content_service_v1` included Theory and Tutor in the same JSON response. J-13 now omits the `tutor` property for Chemistry even for its privileged callers, while retaining the original non-Chemistry contract. Client roles continue to lack direct EXECUTE permission on the generic API. A before/after MD5 of an actual live, published Economics library response was identical: `78d292047989d47ffba6d56c160f3d94`. This is **not** a release of AI Tutor or a change to Mathematics/Economics reading capabilities.

The new `public.iclub_exam_chemistry_tutor_source_v1(skill_key,language)` is a dedicated, authenticated **static reviewed Tutor-source** service, NOT a generative AI endpoint. It requires all of:
- separately enabled, owner-approved and current-source-pinned global Tutor gate;
- independently recorded personal learner consent and owner-approved Tutor permission;
- existing individually eligible/consenting/owner-approved Chemistry Beta membership;
- published Chemistry Exam Core and library with the exact expected 166-source version;
- no active protected assessment; correct EN/RU/UZ card hash and AS/A Level scope.
It never writes evidence or mastery. Its current result is `not_available`, with 0 Tutor entitlements and global Tutor OFF. An actual generative AI Tutor product still needs its own reviewed provider integration and policy verification.

## 2. Separate LAB-only routes

New authenticated RPCs:
- `public.iclub_exam_chemistry_lab_catalog_v1(p_paper,p_language)`: exact six-title catalogue, metadata-only, after server authorization.
- `public.iclub_exam_chemistry_lab_lesson_v1(p_paper,p_skill_key,p_language)`: one approved practical-skills **Theory** card, no Tutor payload.

They read the **independent** `private.iclub_subject_library_cross_tour_v1` store, not the 154 regular Theory rows. Both paper codes must be explicit and valid:
- **P3**: exactly six AS Level learning cards, requires its own owner-approved release switch and existing Chemistry Beta access.
- **P5**: exactly six A Level learning cards, separately owner-released **plus** individually consented and owner-approved A Level permission; Mathematics/AS Beta access alone never unlocks A Level.
Every card is one of the 12 known chemistry-specific LAB keys, source-version-scoped, locale-validated and must be in state `validated` after the owner's future composite library release. No method marks, mastery, assessment answers, stored attempts, or official practical-exam-substitute claims are produced.

Initial `private.iclub_exam_chemistry_j13_learning_control_v1` state: `paper3_enabled=false`, `paper5_enabled=false`, `tutor_sources_enabled=false`; all owner approvals and approved digest NULL. New A Level and Tutor learner permission tables contain zero rows. All three private control tables enforce FORCE RLS with no learner grants/policies.

## 3. UI integration

Created `exam-prep/exam-prep-chemistry-labs-native.js`: separate compact lesson list/detail screen, keyboard-accessible native buttons, EN/RU/UZ, explicit Paper 3 AS vs Paper 5 A Level labels, no unsafe HTML injection, no localStorage, no client marking. A practical-skills link is added to Chemistry Entry and its results **only after the corresponding authenticated catalog API returns an authorized complete set of six**. When the service is OFF, no learner link appears.

Minimal scoped changes to `exam-prep/exam-prep-chemistry-entry-native.js`, `exam-prep/exam-prep-host.js`, `exam-prep/exam-prep-host.css`, and the gated additional script reference in branch-only `index.html`. Mathematics and Economics shared JS source files were not edited in J-13.

The screen explicitly notes that reading a practical card does **not** replace a lab examination or prove practical competence. Return to Entry preserves actual server assessment records: the UI is recreated without deleting or overwriting progress.

## 4. Emergency stop and migration-ledger consistency

Extended **existing Chemistry-only** admin `private.iclub_exam_chemistry_j12_admin_hide_v1` and `...admin_emergency_stop_v1` so they disarm all J-13 P3/P5/Tutor switches, clear new GO timestamps/digest, and retain previously stored consent/history rows. Both functions remain postgres administrator only; no browser EXECUTE grants. J-12 earlier kill switches for Core, Entry, Recheck and P1 remain intact.

Four applied migration files were reconciled exactly to **actual Supabase migration history versions** before final commit:
1. `20261027154620_chemistry_9701_j13_generic_library_tutor_firewall_v1.sql`
2. `20261027154943_chemistry_9701_j13_private_lab_and_tutor_delivery_v1.sql`
3. `20261027155803_chemistry_9701_j13_rollbacks_disarm_all_learning_v1.sql`
4. `20261027160112_chemistry_9701_j13_individual_tutor_permission_v1.sql`

This avoids future accidental migration replay caused by filename/history timestamp mismatches. Earlier misnumbered J-13 *files* were removed from the working branch after identical correctly numbered files were created; **no applied DB migration, user data or content was removed**.

## 5. Verification

**Live read-only Supabase state/privilege QA (all repeated after implementation):**
- J04 32/32, J08 39/39, J09 36/36, J10 41/41, J11 42/42, J12 64/64, J12 Tutor ACL 12/12, J13 44/44 = **310/310 PASS**.
- New J13 assertions cover access gates OFF, P3/P5 source counts, Tutor personal permissions absent, typed invalid input rejection, anonymous role denial, unpublished content denial, emergency-stop disarming, and Mathematics/Practice history presence.
- All 8 inspected shared/Chemistry JS files compile. Repeatable existing synthetic UI J08 11/11 + J09 16/16 + J10 16/16 = 43/43; new J13 `scripts/qa-chemistry-9701-j13-labs-ui.cjs` = **20/20**, hence **63/63 synthetic UI**. These are **not** authenticated physical-device/browser acceptance.
- Supabase security advisor reported **three INFO** entries `rls_enabled_no_policy` for J13 private tables. Intentional closed-by-default FORCE RLS; no J13-specific WARN/ERROR found. Reference: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy .
- Chemistry remains 154 regular Theory + 462 Tutor locale rows + 6 P3 LAB + 6 P5 LAB, all unreleased. J13 APIs return `not_available` by default. Chemistry Entry/Recheck/P1 attempts remain zero at verification. Existing Mathematics and Practice records remain present.

## 6. Next hold points — no implicit GO

1. **Real desktop/mobile authenticated preview acceptance** with a separately consenting eligible beta learner; no Chemistry preview deployment has been verified in this session. Include offline recovery, keyboard, screen reader, all three locales, navigation and Math/Econ/Practice/Tours regression.
2. **Academic content + rights review** of all 12 practical cards and static Tutor sources, not just structural counts; verify no unsafe lab instructions and that cards do not claim to replace physical practical assessments.
3. **Recovery evidence:** verify production backup restore, release digest pin, full current main diff and production deployment SHA immediately before any final release decision.
4. Owner-controlled release decisions are distinct for composite library, P3, P5, static Tutor and separately Entry/Recheck/P1. None has been given here. A separate A Level beta cohort/consent policy must be explicitly authorized before any Paper 5 learners are enrolled.

**Final release decision: NO GO. J-13 code exists only as safely gated development.**
