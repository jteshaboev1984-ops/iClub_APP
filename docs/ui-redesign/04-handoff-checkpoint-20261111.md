# LATEST CHECKPOINT — UI-REDESIGN #531

## LATEST CHECKPOINT — SECOND STITCH ZIP REVIEWED; B00 TWO-STEP DESIGN NEEDS TARGETED CORRECTION (11.11.2026)

The owner uploaded `stitch_iclub_registration_visual_redesign (1).zip`. Inspected FIVE PNG/HTML screen states (Step1 personal details, Step2 default school, Step2 two subjects, Step2 non-school, recovery modal) plus academic_sapphire/DESIGN.md. Two-step visual concept is ACCEPTED AS DIRECTION; **no design implementation approved**. Positive: 1/2 and 2/2 headers, school/non-school branches, secondary optional subject, one final submit, clean brand-like white/blue layout. P0 blockers: recovery backdrop invented phone/study-direction/Step1of3 and fake identity; exact existing source text replaced (including consent and the language note); selected school grade select only 9–11 vs actual 7–11. P1: mismatch of subject chip layouts, fictitious offline Retry/security marketing and missing error/saving/locale/splash/filled-step1 states; DESIGN.md still says 1 of 3. Exact review and ready-to-copy correction prompt in **`docs/ui-redesign/09-B00-Stitch-v2-archive-review-and-correction-v3-20261111.md`**. NEXT: user sends v3 correction into the SAME Stitch project, returns export, ChatGPT rechecks and asks for explicit design approval. Still no production, Supabase, main, personal data or exam changes. Source main verified `85297150a347e98deb8f1e1c58cfbfa2236aea03` at review.


## NEW LATEST CHECKPOINT — B00 TWO-STEP DESIGN DIRECTION ACCEPTED (2026-11-11)

User accepts a multi-step presentation for the registration screen. We resolved conflicting Stitch step counts as **exactly two VISUAL steps** of the **existing one registration form**, with no new business rules, required fields, checks, auth state, saves or routes. Step 1 = language/full name/region/district. Step 2 = school toggle, conditional school/class and competitive chips or non-school card, existing consent and single final registration submission. Existing topbar app-close back arrow remains; local Previous step is distinct. A progress indicator may say 1/2 and 2/2 but never a fake completion percentage. Minimal UI event code for navigating steps would need separate explicit integration approval and behavior-parity tests; it is not automatically permitted as CSS-only. No code implemented and no design accepted yet. **Revised source-backed Stitch correction prompt is in 08-B00-stitch-two-step-approved-direction-prompt-v2-20261111.md, superseding earlier no-steps directions in 06 and 07. NEXT: await revised Stitch export; review it; do not implement before owner design approval.**

**Snapshot:** 2026-11-11, Asia/Tashkent  
**Status:** **INVENTORY COMPLETE (source-backed), DESIGN NOT STARTED; NEXT = B00 Registration**  
**Repo:** jteshaboev1984-ops/iClub_APP  
**Tracker:** https://github.com/jteshaboev1984-ops/iClub_APP/issues/531  
**Docs-only branch:** `docs/ui-redesign-master-inventory-20261111`  
**Pinned audit main:** `12c4381d75b2ebe112b60cdd574626ba137a06d8` (verify newer main HEAD before code work)  
**Last committed docs SHA before this checkpoint:** `a6cafeeb86042ea697b7d06e28705ba561064a67`  
**Parallel non-UI tasks:** Mathematics Issue #450; general integration Issue #528 (do not touch).

## LATEST ARCHITECT DIRECTIVE: VISUAL-ONLY — 2026-11-11

**Binding, supersedes any broader phrasing in earlier docs:** redesign visual presentation only. Existing code is the sole authority for **every** route, user flow, screen, control, user-visible label, business rule, authorization, data contract, storage operation, assessment and action. Stitch can change colors/layout/typography/icons/spacing/responsive styling, but MUST NOT propose implementation of new functionality, reordering of user workflow, deletion of controls, altered semantics, changed copy or JS/DB changes. Code adoption is CSS-first and 100% behavior-preserving; changes to structural markup require separate explicit approval after selector/event compatibility proof. Do not conflate 'all visual states accounted for' with permission to redesign their behavior.

**Next B00 Stitch prompt MUST expressly demand exact registration field set and original paths as coded, not a reimagined onboarding wizard, extra login screen, new tariff selector, additional consent, or different validation.** A source-text inconsistency should be recorded, not quietly rewritten. This decision is also pinned atop Issue #531.

## Completed in this conversation
1. Verified real GitHub access and read the current main `index.html` (14 outer view sections), `app.js` (19 Courses screens + 4 Profile screens and dynamic UI) and the loaded visual, Practice, Exam Prep, Economics, Chemistry, AI, support, plan and learning modules. Read relevant source-backed UX/governance documents.
2. Compiled **157 numbered screen / user-state / conditional-route inventory units** across 14 A–N groups, including all known new/existing, student/nonstudent, Practice/Tours/ratings, certificate/archive/QR, Math/Econ/Chem Exam Prep, AI, commerce, modal/permission/error/empty states. These are *not* 157 distinct live pages: some are conditional or future/DRAFT. The inventory explicitly distinguishes them.
3. Decomposed the end-to-end visual redesign into **15 work blocks B00–B14**, from onboarding through final global QA. Finalized Stitch handoff process (ChatGPT prompt → owner pastes to Stitch → returns design → owner approves → isolated code PR → QA → separate owner production GO).
4. Established detailed UI state QA matrix with **20 E2E flows**, all tests **TODO**.
5. Created Issue #531 and separate **docs-only** branch; commits add project documents, not runtime files.

## Canonical documents to read in the next chat
- **01 Inventory (157 entries):** https://github.com/jteshaboev1984-ops/iClub_APP/blob/docs/ui-redesign-master-inventory-20261111/docs/ui-redesign/01-screen-inventory-20261111.md
- **02 Work blocks / roadmap B00–B14:** https://github.com/jteshaboev1984-ops/iClub_APP/blob/docs/ui-redesign-master-inventory-20261111/docs/ui-redesign/02-ux-blocks-roadmap-20261111.md
- **03 Stitch prompt contract:** https://github.com/jteshaboev1984-ops/iClub_APP/blob/docs/ui-redesign-master-inventory-20261111/docs/ui-redesign/03-stitch-prompts-and-visual-contract-20261111.md
- **04 This checkpoint:** https://github.com/jteshaboev1984-ops/iClub_APP/blob/docs/ui-redesign-master-inventory-20261111/docs/ui-redesign/04-handoff-checkpoint-20261111.md
- **05 Cross-screen state QA:** https://github.com/jteshaboev1984-ops/iClub_APP/blob/docs/ui-redesign-master-inventory-20261111/docs/ui-redesign/05-cross-screen-state-qa-matrix-20261111.md

## Precise status by block
- **B00 Registration, student/nonstudent, recovery:** BACKLOG / **NEXT** (no Stitch prompt delivered yet).
- **B01 Shared shell; B02 Home; B03 Catalog/Subject; B04 Practice; B05 Tours; B06 Ratings; B07 Profile; B08 Notifications/About/Support; B09 Certificates/Archive; B10 Mathematics Exam Prep; B11 Economics; B12 Chemistry; B13 AI/Commerce; B14 full cross-screen QA:** BACKLOG.
- One **source map/roadmap** is complete for every block. This does not constitute visual acceptance or successful functional E2E tests.
- **Owner design approvals: 0. Stitch exports received: 0. Code/DB changes: 0. Runtime/deployment modifications: 0.** No screenshots were collected from live user devices. No change to `main`, production or Supabase.

## NEXT: B00 — prepare real, complete Google Stitch prompt for Registration
In a fresh conversation:
1. Read top Issue #531 checkpoint and these five files, not audit old modules from scratch. Recheck current `main` SHA. Check current actual `index.html` `#view-splash` and `#view-registration` and `app.js` `bindRegistration`, `confirmAndRecoverTelegramProfile`, and live visual CSS. Use present source state if another team updated main.
2. Describe **all** B00 variants: splash; new Telegram account; returning/linked/recovery; RU/UZ/EN; school vs non-school; region→district; school, class; competitive subject chips (max 2 for students), inactive/duplicate/empty state; agreement; required-field validation, saving, error, network retry and successful arrival at Home. Include keyboard and Telegram safe areas and user-readable Back.
3. Cross-check factual copy conflict: registration `#reg_language_reset_note` says progress is preserved when changing content language, while `#profile-settings-content-language` says progress is deleted. **Do not arbitrarily correct text or change behavior**; mark COPY-VERIFY pending until the current effective contract is established.
4. Produce **ONE ready-to-copy, fully filled-out Google Stitch prompt**, not the generic template. Provide no JavaScript implementation before the architect supplies Stitch output and explicitly approves.
5. Architect pastes prompt into Stitch, brings response/screenshots/HTML/CSS export to ChatGPT. Assess per inventory and QA gates. Corrections through follow-up Stitch prompt.
6. Only after `APPROVE DESIGN B00`: isolated Draft PR from verified main SHA for visual changes; retain identities, localStorage, legacy attempts; separate Browser RU/UZ/EN 320/375/390/1440 QA. **No merge/deploy without further GO.**
7. After each subsequent block, prepend exact status/head SHA/new next task to Issue #531. Do not repeat finished work.

## Block ownership / no conflict
- Issue #531 = UI design only. Issue #450 = Math P1/P5 academic/runtime status (S4 or later must never be presumed live from DRAFT). Issue #528 = global integration. Do not alter any parallel branch/PR/DB migrations; don't merge pending math sources.
- Free/Plus/Pro registration/payments and UI may be future design-only: do not activate, enforce new limits or re-register existing users.
- Do not mutate current `index.html`, `app.js`, `style.css`, `i18n.js`, Supabase, Practice/Tours, certificates, old learners or localStorage under this documentation-only task.
- The docs-only Draft PR should remain unmerged until separate review/authorization.

## Exact new-chat message
> **Продолжай визуальный редизайн iClub APP по GitHub Issue #531 с последнего checkpoint. Прочитай пять документов в docs/ui-redesign и связанный Draft PR, проверь актуальный main SHA. Не повторяй полный аудит экранов: 157 экранных единиц уже инвентаризированы, план B00–B14 утверждён только как рабочий список. Следующая задача — B00: подготовь один полный готовый промпт для Google Stitch по регистрации, включая все ветки и состояния. Я передам тебе ответ Stitch. Код, main, production, Supabase и данные пользователей не меняй до моего отдельного согласия. Issue #450 и #528 не трогай.**
