# B00 Stitch v2 ZIP — source-parity review and precise final correction prompt
Date: 2026-11-11; Issue #531; owner-approved DESIGN DIRECTION: two visual steps of one existing registration. STATUS: **DESIGN RECEIVED, VISUAL DIRECTION GOOD, IMPLEMENTATION NOT APPROVED — TARGETED CORRECTIONS REQUIRED.**
Main verified: 85297150a347e98deb8f1e1c58cfbfa2236aea03. Source i18n.js / index.html / app.js read against actual registration, subject chips, modal, topbar. Prior correction v2: 08-B00-stitch-two-step-approved-direction-prompt-v2-20261111.md.

## Inspected archive
stitch_iclub_registration_visual_redesign (1).zip supplied by owner. Extracted only HTML/PNG/MD for inspection; did not execute untrusted JS/Tailwind; **no app code modified**.
1. step_1_of_2_personal_details: 677x1600 PNG and HTML.
2. step_2_of_2_school_subjects_default: 563x1600 PNG and HTML.
3. step_2_of_2_two_subjects_selected: 522x1600 PNG and HTML.
4. step_2_of_2_non_school_learner: 651x1600 PNG and HTML.
5. registration_telegram_recovery_modal_alert_states: 706x1600 PNG and HTML.
6. academic_sapphire/DESIGN.md.

## Passed conceptual visual checks
- Two-step count 1/2 and 2/2 on main 4 registration screenshots; no invented 85% completion on main views.
- School ON/OFF clearly differs; non-school subjects/school hidden; one-subject-required, second optional, max-two is expressed correctly; one visible final submit on Step 2.
- Region/district dependent controls and school/class controls appear in expected locations.
- App topbar Back remains visible, separate local Step 2 Previous; absence of bottom tabbar.
- Clean, consistent high-level blue/white aesthetic, reasonable structure and legibility.

## Blocking differences and missing evidence
- **P0:** Recovery screenshot background is a completely fabricated three-step form with telephone and study-direction fields. Current app has no these registration fields. Recovery confirmation adds fictional user identity (Aлишер Каримов, ID #48194, Level B2 and verification), while real uiConfirm has just existing title/message/Restore/Cancel; backdrop should show actual registration.
- **P0:** Actual source copy was rewritten at many places: Step1 heading subtitle, language two notes (second drops source's results/answers phrase), Full Name adds ID-document requirement, school toggle hint, Step2 subjects heading, current subject labels, and one consent message. Source consent exact: 'Я даю согласие на обработку своих данных.' Stitch's '...в соответствии с регламентом iClub' is new legal wording. Non-school paragraph replaced by promotional benefits and different entitlement descriptions. Do not silently correct source contradictions.
- **P0:** In selected Step2 HTML Grade select has only 9th, 10th, 11th grades, vs actual 7–11 in source. Restore all options in ALL variants.
- **P1:** Subject chips flip from 2-column chip grid on default to single-column selection rows in filled state; prefer consistent actual 2-column chip group with same items and only active state changing.
- **P1:** DESiGN.md still says Step 1 of 3, despite 2-step screenshots. Palette first-party source #2F6FD6/#F6F8FC vs generated token background #FAF8FF.
- **P1:** Missing Step1 filled state; missing separate saving, missing-required, max-two toast, standalone offline/save error, simple splash, locale and actual 320/375/390 + desktop QA.
- **P1:** Fabricated 'Безопасная передача данных в iClub Uzbekistan', retry button in offline banner and title 'Шаг 1 из 3' under recovery overlay. Source offline banner has one sentence, no retry button.
- **P1:** 'ic' placeholder is not original logo; do not swap it into app.
- **P1:** Static exported HTML uses Tailwind CDN, Material Symbols and standalone JS and is not implementation code. Do not copy it over production UI.

## Exact UI source references
- index.html #view-registration includes one form #reg-form; #reg-language, #reg-fullname, #reg-region, #reg-district, #reg-is-school-toggle, #reg-school, #reg-class, #reg-subject-chips, #reg-subject-summary, #reg-consent, #reg-submit, and #reg-nonstudent-subjects.
- app.js updateTopbarForView('registration') shows actual iClub/Smarter together/topbar Back closes app and hides tabbar; bindRegistration final submit saves to Supabase exactly once; updateSchoolFieldsVisibility; initRegSubjectChips; confirmAndRecoverTelegramProfile.
- i18n.js reg_* RU phrases quoted in corrective prompt. Existing contradictory content-language explanation is COPY-QA, not a license to alter behavior.

## Owner instructions and next gate
Do NOT implement now. User agreed with two-step visual presentation as direction only. Send precise v3 prompt to the SAME Stitch project; receive revised export, verify missing states and exact copy; then ask for explicit DESIGN APPROVAL. A separate minimal UI navigation change may be needed if implemented but no business rules/DB/data changes permitted; engineering and release permissions remain separate.

## Copy-paste Stitch correction prompt v3
```text
Continue in the SAME Google Stitch project and revise your LATEST FIVE exported B00 mockups. Preserve the attractive two-step registration layout, proportions, progress bar, clean white cards and iClub blue styling. DO NOT start a new design.

Owner-approved concept: EXACTLY TWO VISUAL STEPS within the existing single registration form. Step 1 Language/Full Name/Region/District; Step 2 School Student switch/conditional School+Grade+Competitive Subjects or Non-school info/Consent/one Final Submit. Keep internal Next and Previous visual navigation, with entered values retained. The original registration topbar Back CLOSES APP, independent of the Step 2 Previous button. This presentation remains design-only; do not implement code, add validation, save on Next, add routes, change fields or touch Supabase, auth, progress, permissions or production.

CORRECTIONS TO THE CURRENT FIVE MOCKUPS — THESE TAKE PRIORITY:

1) SOURCE COPY MUST BE EXACT, not approximate. Use the actual existing Russian iClub labels and messages supplied here. Step 1:
   Heading: "Создайте аккаунт"
   Subtitle: "Введите данные, чтобы участвовать в обучении по Cambridge curriculum в Узбекистане."
   Language label: "Язык"
   Language note 1: "Этот язык будет использоваться для практики, туров и сертификатов."
   Language note 2: "Язык заданий можно изменить позже — результаты и ответы сохранятся."
   Name label: "ФИО"; placeholder "например, Alisher Navoiy"
   Region label: "Регион"; placeholder "Выберите регион…"
   District label: "Район"; disabled placeholder "Сначала выберите регион…"
   Keep the existing dropdown choices Русский/O‘zbek/English.
   Step 2:
   School switch: "Вы ученик школы?" and hint "Включите, чтобы указать школу и класс"
   "Школа №"; placeholder "например 154"; "Класс" with choices 7, 8, 9, 10, 11 in EVERY variant, not only 9,10,11.
   Subject heading "Основной предмет (для рейтинга)" and hint "Выберите основной предмет для рейтинга"; when none selected, summary "Выберите до 2 предметов"; when selected, summary tags "Основной" and "Дополнительный". Note: "Основной предмет можно изменить позже в профиле. Соревновательные предметы тоже можно менять в пределах лимита."
   Non-school card title: "Обучение без школьного режима"; exact paragraph: "Если вы не ученик школы, вы можете изучать и практиковаться по всем предметам без туров. Подключать и удалять предметы можно позже в профиле."
   Consent exact text: "Я даю согласие на обработку своих данных."
   Final button: "Завершить регистрацию".
   These are current-app copy strings. Do NOT add a passport/birth-certificate hint, rules/regulations statement, security promise, eligibility guarantee, school quotas, promotional bullets or additional descriptions. Do not invent or silently change translated wording. There is an existing question-language note ambiguity in code: do not editorially fix it in design.

2) EXACTLY CONSISTENT TWO STEPS across every mockup: "Шаг 1 из 2" / "Шаг 2 из 2". Your DESIGN.md still references "Step 1 of 3" — update the style guide to two steps only. Progress shows current position, not invented percentages. One actual registration submission on Step 2 only; Step 1 Next is visual page navigation only. Keep a clear secondary local "Назад" button on Step 2 that preserves data, separate from the actual topbar Back (closes the app).

3) ONE CONSISTENT SUBJECT CHIP DESIGN across default and two-selected versions. Currently the unselected version uses two-column small chips whereas the selected version changes all chips to large vertical radio-like rows. Do not completely change the layout when values are selected. Use the same balanced mobile 2-column chip grid in BOTH, with selected fill/outline/check states and the existing selection summary underneath. There may be one required, second optional; maximum two. Selected chip clicks can deselect. Preserve the real five potential subjects Informatics/Economics/Biology/Chemistry/Mathematics, showing only actually enabled ones. Do not invent new selectable controls or put dynamic subject rank labels inside chips; existing rank labels belong in the summary. For narrow 320px allow graceful wrapping/single-column as needed, consistent across states.

4) STEP 1 FILLED STATE IS MISSING. Show a separate version with editable Full Name INPUT, Region SELECT and District SELECT populated; do not turn them into read-only text. Preserve the District-disabled variant as well.

5) SCHOOL SELECT: Ensure ALL classes 7/8/9/10/11 appear in every variant. The filled HTML currently contains only grades 9–11. Do not change choices by school, user, or registration step.

6) RECOVERY MODAL MUST MATCH THE CURRENT PRODUCT, NOT THE INVENTED BACKGROUND SCREEN. The real app uses a straightforward confirmation modal: title "Профиль уже существует" for a linked Telegram profile, or "Профиль открыт на другом устройстве" for inactive session; existing explanation that restoring makes current device active and prior session inactive, and the exact limits 2/24h, 4/7d, 6/30d; EXACTLY two buttons "Восстановить профиль" and "Отмена". Do not show a fabricated user card, avatar, user ID, verified badge, "Уровень B2" or shield-send illustration. The backdrop must be the actual registration Step 1 or Step 2 with existing fields, NOT a fictional "Шаг 1 из 3" screen with phone number, study direction or new fields. Keep modal scrollable/readable on small phones.

7) OFFLINE ERROR STATE: The original offline-banner message is "Нет подключения к интернету. Данные могут не сохраниться." It contains NO "Повторить" button. Do not invent Retry controls. For save failure show the app's existing alert UI, not a new step or different action.

8) RENDER THE OTHER MISSING STATES, clearly labeled as overlays or conditions, not extra screens: required-fields toast, attempted third subject max-two toast ("Можно выбрать максимум 2 предмета."), saving-registration overlay with temporarily disabled final submit, offline banner, registration-save-failed one-button alert, simple splash with existing logo/iClub/loading only. For non-school mode show the ORIGINAL info paragraph and NO extra benefit bullets.

9) THE ORIGINAL EXISTING LOGO MUST BE REUSED. The little fabricated square "ic" is not the real app logo; if actual logo.png isn't available, mark it plainly as a placeholder instead of designing an alternate logo. Likewise no certification badges, inflated learner counts or security guarantees.

10) Keep real functionality intact: unchanged data fields and order; exact app copy and current error messages, same one-subject-required-for-school rule/second-optional/max-two; non-school selects no subjects; one data-processing consent; existing direct Home transition after one final save. The Stitch HTML/Tailwind/JS must NEVER be proposed as replacement production code.

STYLE/QA: iClub primary #2F6FD6, background #F6F8FC (avoid the lavender #FAF8FF theme substitution), white cards, dark text, consistent padding, symmetric controls and visual language. Russian main screenshots, show real Uzbek Latin/English text wrapping without inventing copy, and provide 320/375/390 mobile + 1440 desktop responsive evidence. Telegram safe-area and keyboard consideration. Fix DESIGN.md progress example from 1/3 to 1/2. List missing deliverables explicitly rather than claiming they exist.

OUTPUT: Correct only the existing B00 two-step design and missing real conditional states, keeping your successful visual appearance. No new onboarding, no new logic, no account actions or deployment.
```