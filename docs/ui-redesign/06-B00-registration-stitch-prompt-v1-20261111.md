# B00 — Google Stitch prompt v1.0 (ready to paste)

**Tracker:** Issue #531 · **Status:** PROMPT SENT TO ARCHITECT (Stitch response pending) · **main verified:** 85297150a347e98deb8f1e1c58cfbfa2236aea03 · **date:** 2026-11-11.

Source verified: index.html #view-splash/#view-registration (blob bb1b7268be2875faf11f19368e676d6ab9583ffe), app.js bindRegistration/updateSchoolFieldsVisibility/initRegSubjectChips/confirmAndRecoverTelegramProfile (blob 97b4a4868d32367397f8b21b5bf9869b71ccef9c), i18n.js, style.css. This is a design prompt, not a test pass or permission to implement.

---

# iClub APP — B00 Registration | STRICT VISUAL-ONLY REDESIGN

Design a premium, clean, modern visual refresh of the EXISTING registration interface in the iClub educational Telegram WebApp. This is an established product with active users, written in plain HTML/CSS/JavaScript. The result is a visual reference for adapting existing CSS; it must NOT be a new app or a new registration process.

HARD NON-NEGOTIABLE RULE:
Strict visual redesign only. Preserve the exact existing screens, controls, fields, actions, labels, navigation, hierarchy of user steps, permissions and app behavior defined by the following specification. Do not invent, remove, merge or rename features, inputs, buttons or screens. Only propose styling, spacing, typography, color, icons, layout within each existing screen and responsive appearance. Mockup code is not implementation authority.

VISUAL DIRECTION
- Professional, elegant, trustworthy educational product, appropriate for school students and older learners; refined rather than childish or flashy.
- Preserve the existing iClub identity. Primary blue #2F6FD6, darker blue #1E56B3, very light page background #F6F8FC, white card surfaces, main text #0F172A, secondary text #64748B. Do not invent a replacement logo, change the brand colors, or introduce a second unrelated design system.
- Use crisp system-like typography, clear headings, even spacing, quiet outlines, gentle shadows, consistent border radii and balanced whitespace. Fields, chips and CTAs should feel polished and perfectly aligned.
- Mobile-first portrait 390x844; also work at 320x720 and 375x812, and a sensible centered desktop column at 1440px. Respect Telegram safe-area inset, mobile keyboard, long Uzbek Latin labels and scrollability. No horizontal overflow.
- Avoid giant decorative illustrations, intrusive icons, glassmorphism, fake gamification and dense marketing copy.

EXACT EXISTING VIEW STRUCTURE — DO NOT ADD AN ONBOARDING WIZARD
A. Existing splash/loading view BEFORE the form: centered existing iClub logo, iClub title and short loading-status line. Keep it visually consistent with registration. This is a brief loading view, not a Get Started page.
B. Existing registration view: ONE vertically scrollable form on ONE screen. Keep the exact order and all existing fields below. Do not split into steps or tabs. Do not add back, skip, login, signup-with-Google, phone, email, password or new buttons. The normal four-tab navigation is NOT visible during registration.

REGISTRATION CONTENT IN THE ACTUAL ORDER
1. Heading with the existing "Create your account" meaning and one short existing curriculum-in-Uzbekistan subtitle. Preserve the product's current translated copy when implementing; the mockup may use Russian as its main display language.
2. Language selector: a native-style select with exactly three options: Русский, O‘zbek, English. This is the existing field, not three new language-selection screens. Under it retain BOTH explanatory text lines currently provided by the app (language used for Practice/Tours/certificates, and the separate note about later question-language changes). Do not simplify or rewrite their meaning.
3. Full Name / ФИО: one text input with its example placeholder. No separate first name/last name fields.
4. Region / Регион: one select with its original unselected placeholder.
5. District / Район: one dependent select. It is disabled until a region is chosen; give disabled/selected states visually distinct styling. Do not add geolocation or a map.
6. "Are you a school student?" / "Вы ученик школы?": ONE toggle switch, initially ON, with its short existing hint.
7. ONLY WHILE SCHOOL TOGGLE IS ON: School No. / Школа № text field, and Grade / Класс select with the original choices 7, 8, 9, 10, 11. They are currently presented as a two-column row where space allows. Preserve both fields. Avoid clipping at 320px.
8. ONLY WHILE SCHOOL TOGGLE IS ON: one existing competitive-subject selection card containing a heading, hint, existing selectable chips for Informatics, Economics, Biology, Chemistry and Mathematics (show only currently active subjects; do not invent new subjects), and the selection summary underneath. Exactly one main subject is required for a school student; a second is optional; maximum two, no duplicate, and deselection is possible. Visually distinguish unselected and selected chip states. Keep the summary's primary/secondary subject labels and the existing small note about changing selected subjects later. Do not add a visible third subject picker; legacy hidden selects are implementation details, not new UI.
9. ONLY WHILE SCHOOL TOGGLE IS OFF: HIDE the school/class row AND the competitive-subject card. Instead show the EXISTING informational card "Обучение без школьного режима", explaining that the learner may study/practice without active Tours and manage subjects later in Profile. Non-school users do NOT select subjects in registration. The same basic Language/Name/Region/District fields remain.
10. One mandatory consent checkbox with the app's current consent-to-data-processing wording. No extra separate legal agreement or invented link.
11. ONE primary action at the end: "Завершить регистрацию" / the exact localized Finish registration label. This button is the only form submission action; make it visually prominent without inventing sticky or floating duplicate CTAs.

STATES TO VISUALLY COVER — SAME SCREENS, NOT NEW PRODUCT FLOWS
- Default school-student registration: switch ON, school/class and subject chips present, no subject chosen.
- School-student registration: exactly two subjects selected, readable primary/secondary summary and selected-chip styling.
- Non-school registration: switch OFF, school and competitive fields hidden, informational non-school card visible.
- Region/District: region not chosen with District disabled, plus both selects in normal selected state.
- Validation problem: the existing toast-style notification for missing required fields, missing required competitive subject, exceeding two subjects or duplicate subject choice. Do not add a new mandatory validation screen or change validation policy.
- Registration saving: existing loading overlay/status and temporarily disabled Finish button. Preserve one submission, never simulate a second step.
- Registration save failure or offline: existing alert/toast and offline banner presentation; do not invent a different retry workflow.
- Already-linked Telegram profile / inactive device: show the EXISTING confirmation modal visually, with its original title, explanation, and exactly TWO actions: Restore profile and Cancel. The explanatory text includes real recovery limits, which must not be removed, shortened into different rules or invented. This modal is an existing conditional state, NOT a standalone login page.
- Successful save leads directly to the existing Home view; do not design a success wizard or new welcome/verification screen. A simple transition annotation is sufficient.

VISUAL DETAILS
Keep one consistent content width and vertical rhythm. The title/subtitle should not push the first field below the fold unnecessarily. Use tidy text labels above fields, clear focus rings, dropdown indicators, balanced switch alignment, legible two-column school/class fields when width permits, comfortable 44px+ tap areas, clean subject-chip spacing, visible selected borders and accessible contrast. The consent and final button must have comfortable bottom breathing room with Telegram safe-area protection. Use the same visual style for toast, offline banner, loading overlay and restoration confirmation.

LANGUAGE AND CONTENT ACCURACY
The actual app ships Russian, Uzbek Latin and English translations. Produce the full primary mockup in Russian and show how the same exact control layout handles Uzbek Latin and English, especially long labels and hints. Keep existing labels, translations, option sets and explanations; do not rewrite copy as part of this visual task. If any source text seems contradictory, flag it for the developer rather than silently correcting it. Use fictional placeholder personal details only.

DELIVERABLES
1. One polished, full-height/scrollable mobile registration design, not a cropped top-only view.
2. Visual variations showing the existing school ON / two subjects selected / school OFF / input-disabled / validation / loading / recovery-modal states.
3. One compact typography, spacing, color, input, chip, checkbox, CTA and overlay visual specification suitable for CSS-only implementation in the existing iClub app.
4. Responsive views or notes for 320px, 375px and desktop 1440px; demonstrate Uzbek Latin label wrapping.
5. Identify clearly which variations represent conditional states, not separate new pages. If your tool cannot render all variants, state which are missing rather than replacing them with invented screens.

This design will be reviewed by ChatGPT and the app architect before any CSS is changed. No implementation, deployment, backend, data, authentication, navigation or functional changes are authorized.

---

**Next:** Owner pastes this exact prompt in Stitch and sends visual results. ChatGPT reviews design against visual-only contract; code is forbidden before explicit design approval, and any release requires a separate GO.
