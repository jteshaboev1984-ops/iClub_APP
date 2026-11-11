# B00 — Stitch correction prompt v2: OWNER ACCEPTS TWO VISUAL REGISTRATION STEPS
Date: 2026-11-11 · Tracker: Issue #531 · STATUS: revised prompt prepared, awaiting updated Stitch export; **design not yet approved**.

## Owner's latest B00 decision and scope
The architect accepted a registration presentation with steps. This **supersedes only** the prior B00 instruction to remove steps in document 07. The original code remains one HTML `#reg-form` with one submit. Proposed division is exactly **two client-side presentational steps**, not changed registration rules, data persistence or validations. Two-step navigation (`Далее` and local `Назад`) would require a separately audited minimal UI interaction during eventual implementation; it is NOT already implemented and must not be treated as CSS-only. No code changes are authorized at the design stage. All other functional-preservation rules remain binding.
Step 1: Language + two existing notes, Full Name, Region, District. Step 2: school toggle, conditional school/class and competitive chips or non-school information, existing consent and single final submission. Existing global app-close back arrow continues to close app; local step back must be distinct.
Do not mistake visual progress for completion percent. Consistent 1/2 and 2/2 only.

## Ready-to-paste revised prompt — REPLACES the correction prompt in document 07
```text
Continue improving the SAME existing iClub B00 registration design in this Stitch project. This is a focused correction to your first four exported screens, not a new brand redesign.

UPDATED OWNER DECISION: A STEP-BY-STEP PRESENTATION OF REGISTRATION IS NOW APPROVED AS A DESIGN DIRECTION. The initial ban on registration steps is superseded for B00 only. Design exactly TWO clear visual steps with a consistent progress indicator; preserve the one underlying existing form, all actual fields, original data flow, original validation rules, single final submission, auth behavior, and user progress. "Next" and "Previous step" are visual in-form navigation only, not extra registration submissions, routes, accounts, verification checks or database saves. Do NOT generate implementation or claim that the current code already supports a wizard; technical compatibility will be reviewed separately before any code change.

KEEP the successful light-blue/white visual appearance of "registration_state_1_school_student_default": elegant cards, clear labels, restrained brand blue #2F6FD6, white surfaces, consistent radius/spacing, crisp typography, easy touch targets. Polish details without turning it into a different product.

STEP SYSTEM (SAME SINGLE REGISTRATION, TWO PRESENTATION SECTIONS):
- Step 1 of 2 — Personal details. Existing heading "Создайте аккаунт" and existing short description. Existing language SELECT with EXACTLY Русский / O‘zbek / English and BOTH existing explanatory lines. Full Name text INPUT. Region SELECT. District SELECT dependent on Region, disabled before Region is chosen. One visible "Далее" control to move VISUALLY to Step 2 without saving, submitting, verifying or invoking a new validation process.
- Step 2 of 2 — School and subjects. Existing "Вы ученик школы?" toggle, initially ON. If ON show School No. text INPUT and Grade SELECT with exactly 7/8/9/10/11, then one existing competitive-subject selection card with chips for Informatics/Economics/Biology/Chemistry/Mathematics, primary/secondary summary and existing explanatory note. The school user must choose ONE competitive subject, MAY choose an OPTIONAL second, maximum TWO; clicking selected chip can deselect. Only active subject chips appear. If toggle OFF, hide school/class/competitive card and show the existing "Обучение без школьного режима" information card with existing text; non-school users select no subjects during registration. Then present the single existing data-processing consent checkbox and ONE final "Завершить регистрацию" button. Include a visually secondary "Назад" step-navigation control to return to Step 1 while preserving everything entered. Do NOT let a step navigation click save a profile or clear input values.

- Progress must ALWAYS say "Шаг 1 из 2" or "Шаг 2 из 2", with a clean 2-part indicator (or 50%/100% NAVIGATION POSITION, not claimed completion). No 1/3, 2/3, 3/3, conflicting counts, fake "85% filled" status, new review/confirmation step or invented graduation metrics. Avoid confusing "Next" with "Finish registration"; on Step 1 there is only Next, on Step 2 there is one final Submit.

PRESERVE REAL APP SHELL AND BEHAVIOR:
- Current registration top bar displays actual iClub logo, "iClub" brand, subtitle "Smarter together", and an existing BACK arrow that CLOSES the app. Preserve that arrow and action in BOTH steps. The internal Step 2 "Назад" is an independent, clearly distinguished step-navigation control (not the app-close arrow). Do not show the app's tabbar during registration.
- Splash/loading view consists ONLY of existing logo.png, "iClub", and a loading status. It has no topbar/tabbar. Remove invented "Cambridge Assessment Partner", verified/accredited claims, fictional user counts or badges.
- Never replace the actual iClub logo with a fabricated "iC" mark; if source logo unavailable, use a clearly labeled existing-logo placeholder.

FIX THE ORIGINAL STITCH EXPORT ERRORS:
1. Keep language as the ONE real three-option SELECT, not static text, tiles or an "Изменить" link, wherever it is shown.
2. Keep all editable controls as inputs/selects even in "filled" variants, not read-only profile summaries. No new identity-verification icon, "Подтверждено", certificates, document-upload instructions, badges or advertising.
3. Subject selection: ONE subject required for school user and second optional. Remove the false statement "Выберите ровно 2". No third visible subject selector, no invented subject selection logic.
4. Non-school state must show the SAME Step 1 personal-information fields and Step 2 toggle/consent/finish as the student state, with only the existing conditional school and subject block replaced by its information card. No "Индивидуальный статус", extra photo tile, unsupported promises of full access, or made-up course plan.
5. Keep the app's ONE real consent checkbox with EXACT source wording about processing personal data. Remove new confirmations about academic rules, the accuracy of information, safety certification or privacy promises. Use existing app translations; if source copy is ambiguous, flag it instead of silently changing it.
6. Keep the final SAVE action at the end of Step 2 only; one current save workflow to Supabase, same original validation, existing Telegram-linked-profile recovery and direct Home transition after success. A Step 1 "Next" is NOT a substitute for final validation or registration; do not invent extra required fields or checks.

RENDER MISSING EXISTING VISUAL STATES WITHOUT NEW FUNCTIONALITY:
A. Step 1 default, Region blank with District disabled.
B. Step 1 with all editable fields filled and Region/District selected.
C. Step 2 school ON, zero subjects chosen.
D. Step 2 school ON, exactly TWO subjects chosen, with correct primary/secondary summary.
E. Step 2 school OFF, existing non-school explanation visible, no school/class/subject chips.
F. Existing missing-required-fields and max-two-subjects toast. Show the real feedback as an overlay rather than a new mandatory validation page.
G. Existing "Сохраняем регистрацию…" loading overlay with final submit temporarily disabled. Do not save or show loading on Next/Previous-step navigation.
H. Existing offline banner and registration-save-error alert.
I. Existing already-linked Telegram/inactive-device RECOVERY MODAL with exactly two actions "Восстановить профиль" and "Отмена" and the current explanation, including security limits 2 restores/24h, 4/7d, 6/30d. Confirmation makes this device active, old session inactive. No new login or password screen.
J. Existing splash/loading screen.

VISUAL QUALITY:
Design the same reusable component system for both steps, with consistent width, padding, progress indicator, buttons, chips, labels, input heights, switch, toast, modal and note cards. Keep the user aware that both steps form ONE registration. Avoid crowded mobile screens, giant empty areas, decorative infographics and clipped labels.
Keep the original ordering of fields even when separated across steps. Preserve data when navigating back and forward in the visual concept; no forced reset.
Use Russian as primary mockup. Preserve the actual app's RU / Uzbek Latin / EN copy, with a sample demonstrating long Uzbek Latin text wrapping without overflow. Source text has precedence over Stitch's invented copy. No real personal data.
Show responsive at 320px, 375px, 390px and desktop 1440px with Telegram safe-area handling and mobile keyboard accommodation.

DELIVERABLES:
1. Fully rendered Step 1 and Step 2 (school ON) connected by the same visual design.
2. Filled state of both steps with exactly two selected subject chips on Step 2.
3. Step 2 non-school state.
4. The remaining visual condition variants A–J, clearly labeled as states instead of additional routes.
5. Short style guide (brand, colors, typography, fields, buttons, progress, chips, alerts, modal) and responsive guidance.
6. List any states Stitch cannot show, rather than faking them.

DESIGN ONLY. Do not write or propose app business logic. Do not change authentication, server API, Supabase, validation, educational rules, access permissions, persistence, existing data, progress, user experience outside registration or deploy production. A two-step presentation is the ONLY specific change to the visual UX contract approved for B00; implementation still requires separate source compatibility and explicit owner approval.
```

## Next action
Owner pastes prompt v2 into SAME Stitch project and returns updated ZIP/screenshots. Review source parity, visual quality, i18n/responsiveness and states. Then request design approval; no code, Supabase or production changes absent separate consent.