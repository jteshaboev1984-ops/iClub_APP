# B00 Stitch ZIP review and corrective prompt v1 — Issue #531
Status 2026-11-11: STITCH RECEIVED → REVIEWED → REVISE STITCH; design NOT approved. No app, database or user data changes.
Verified main SHA: 85297150a347e98deb8f1e1c58cfbfa2236aea03. Sources: index.html registration/topbar, app.js bindRegistration / initRegSubjectChips / updateTopbarForView / Telegram recovery, i18n.js and style.css.

## ZIP inventory (inspected without running untrusted JS)
- 4 screenshots and 4 HTML static exports: splash (706x1600), default school form (355x1600), two-subject-filled (369x1600), non-school (439x1600); DESIGN.md.
- Missing: required-field and max-two toasts, saving overlay, offline/error alert, Telegram recovery modal, full RU/UZ/EN mockups, responsive proof for 320 and 1440.

## Positive visual aspects
- Clean blue-and-white card design, legible form controls, selected chips, strong primary submit button, coherent visual direction. Keep the school-default look as a visual reference.

## Verified blocking discrepancies
1. **P0** Invented multi-step registration, step counts 1/3 and 2/2, 85% progress; actual registration is one form with one submit.
2. **P0** False requirement to select exactly two competitive subjects; actual school user needs one, second optional, maximum two.
3. **P0** Filled/non-school variants replace editable fields/selects with static profile summaries or language pills; actual controls remain editable in all states.
4. **P0** Changed single consent wording and added academic regulations/identity verification. Actual existing consent is data-processing checkbox.
5. **P0** Fake splash claims including Cambridge Assessment Partner, verified and 4,200+ accredited students; actual splash is existing logo, iClub name and loading.
6. **P0** Changed registration topbar title to Student Profile Registration with new profile icon. Actual topbar is iClub / Smarter together, with real Back arrow that closes app and NO bottom tabbar.
7. **P1** Added Cambridge Track, personal-document instructions, security guarantees, non-school promotional benefits, separate photo tile; not authorized by current source.
8. **P1** Missing loading/errors/recovery states, locale and responsive evidence.
9. **P1** Exported HTML uses external Tailwind CDN, Material Symbols, Google fonts and standalone JS; cannot be pasted into current vanilla HTML/CSS/JS product. Design reference only.

## Decision
REVISE STITCH, not DESIGN APPROVED. No implementation of app code or main merge. User supplies corrected Stitch export for next review.

## Ready-to-paste correction prompt for the SAME Stitch project
```text
Continue revising the EXISTING iClub B00 registration mockups in this same Stitch project. This is a targeted CORRECTION, not a new design direction. Preserve the successful appearance of registration_state_1_school_student_default: white cards, blue accents, restrained borders, form proportions, well-spaced selectable subject chips and a single main CTA. Do not start a new project or change the underlying functionality.

ABSOLUTE RULE: VISUAL DESIGN ONLY. Existing iClub code determines the precise fields, control types, order, screens, conditions, language labels, actions and permissions. Do not invent, remove, merge, rename or reword functionality. Your HTML is reference only; no new app logic is requested.

1. REMOVE all invented registration steps and progress: "Шаг 1 из 3", "Шаг 2 из 2", "85% заполнено", progress bar, "Финальная настройка". There is ONE continuous vertically scrollable registration form and ONE submit action. Default/filled/non-school are THREE STATES OF THE SAME FORM, not a step sequence.

2. Keep the REAL registration topbar: existing iClub logo, title "iClub", subtitle "Smarter together", and the existing Back arrow which CLOSES the app on this view. Remove "Student Profile Registration" wording, fabricated profile button and any extra action. No bottom tab navigation. Splash has no topbar/tabbar.

3. The real splash ONLY contains existing iClub logo (if its asset is unavailable, use a labeled placeholder "existing logo.png"), the "iClub" word and one loading-status line. REMOVE fabricated "Cambridge Assessment Partner", "verified", "4200+ accredited students", fictitious certification or security promises. Do not replace the logo with a new iC mark.

4. Keep exactly ONE editable language SELECT in EVERY form variation at the top: Русский, O‘zbek, English. Keep BOTH existing help/note lines below. Do NOT use two-option pills, "Изменить" links or static language displays. Do not editorially claim anything about loss/preservation of progress; reproduce existing text only.

5. EXACT ORDER and types of registration fields, unchanged across all variants: heading and subtitle; language SELECT and two notes; Full Name TEXT INPUT; Region SELECT; District SELECT (disabled until Region); School Student TOGGLE (default ON); if ON, School No. TEXT INPUT and Grade SELECT with 7,8,9,10,11; if ON, competitive subject card with chips plus existing summary/note; if OFF, show existing non-school explanation card and HIDE school/class/subject chips; one mandatory existing-consent checkbox; one "Завершить регистрацию" submit button. There is no password, email, OTP, extra form step, duplicate button or separately requested confirmation.
   In your filled/non-school designs, you replaced some editable selects and inputs with static profile summaries. Restore the exact input/select control appearance, only show them FILLED rather than blank. Remove invented "Подтверждено" account/identity verification.

6. Subject selection for SCHOOL users: ONE subject REQUIRED, second OPTIONAL, maximum two selected, one may be deselected. Potential chips: Informatics, Economics, Biology, Chemistry, Mathematics, but hide any currently inactive ones. Keep existing primary/secondary summary below. Correct your false "Выберите ровно 2" claim. Do not make third/fourth/fifth options look unavailable simply because two are already selected; follow existing clickable-chip and toast semantics.

7. NON-SCHOOL mode: same continuous form, school toggle OFF; school/class and competitive cards hidden, existing "Обучение без школьного режима" informational card visible with the original wording. Non-school users select no subjects during registration. REMOVE new "Индивидуальный статус", promotional benefits, fake "full access" promises, decorative extra learner/photo tile. Do not create a separate non-school onboarding experience.

8. CONSENT text must be identical to the existing application's single data-processing consent wording on all variants. Remove your invented confirmations about academic regulations, data correctness and security claims.

9. ADD the missing visual STATE VARIANTS, without adding separate routes:
  a) Region empty and District disabled; Region and District both selected;
  b) Existing missing-required-field toast;
  c) Existing max-two-subjects toast on attempted third selection;
  d) Existing registration saving overlay with one disabled submit button;
  e) Existing offline banner and existing one-button save-error alert;
  f) Existing Telegram-linked-profile / inactive-device recovery MODAL with precisely two actions "Восстановить профиль" and "Отмена". The source explanation limits recovery to 2 times in 24h, 4 in 7 days, 6 in 30 days; confirmation makes the current device active and previous session inactive. No new login screen, no invented recovery conditions.
  g) Actual simple splash loading state.
Show the actual existing UI visual anatomy for these states; do not invent behavior.

10. RESPONSIVE AND LOCALES: Show full registration all the way to bottom consent + submit, at 390px mobile and stress-test 320px/375px, plus desktop 1440px. Russian primary mockup; same input layout with long Uzbek Latin and English labels (do not invent missing translations). Respect Telegram safe area/keyboard. No clipped text or horizontal overflow. Provide a compact component style guide (colors, typography, padding, cards, fields, select, switch, chips, modal, toast, button).

Your deliverable must retain ONE design system and ONE form structure across all states. List any states you cannot generate instead of fabricating new workflows. Re-use the existing brand blue #2F6FD6 and white cards. This is a design-only handoff, not authorization for JS, SQL, auth, data, payment, routes or deployment.
```

## Next exact action
Owner sends this correction to the same Stitch project, returns revised ZIP or screenshots. ChatGPT compares actual design to source code, asks for design approval only when all relevant controls/states match. CSS-first draft implementation only after explicit approval; separate release GO.