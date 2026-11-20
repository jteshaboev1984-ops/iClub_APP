# B01 — SOURCE-LOCKED Google Stitch prompt / UI shell and navigation
Date: 2026-11-11 · Issue #531 · baseline main `85297150a347e98deb8f1e1c58cfbfa2236aea03` · status **SOURCE VERIFIED → PROMPT READY, STITCH EXPORT NOT YET RECEIVED**. Source-verified against `index.html` #topbar/#tabbar/#main, `app.js` showView/setTab/updateTopbarForView/bindTabbar/bindTopbar, `i18n.js` RU/UZ/EN, `style.css`, `visual/iclub-visual-v3.css`, `visual/iclub-premium-v3.css`, roadmap and contract. This is a design input and NOT permission to modify main, production or Supabase.

## Architect directives in force
- B00's corrected "Academic Sapphire" / strong Stitch fidelity is visual reference for B01; owner wants students to notice a genuinely NEW app.
- The user explicitly re-emphasized line-break discipline: one-line where naturally possible; if wrapping required, break at semantic groups, no broken parentheses, lone orphan words, truncated RU/UZ/EN labels or overlapping badges. Manual design review plus Chromium text geometry is mandatory before accepting B01 code.
- Existing routes, visibility and permissions remain source-of-truth. B00 is not merged/released (DRAFT PR #534). No other app feature is to be changed.
- This file is a **ready-to-paste prompt**; no Stitch output or design acceptance yet. Do not implement B01 code until architect reviews the returned visuals or explicitly waives the Stitch design gate.

## Prompt to paste in SAME iClub Stitch workspace
```text
# iClub APP / B01 — Global top bar and four-tab navigation / Stitch visual redesign

Continue the SAME approved visual identity used in the corrected B00 registration ("Academic Sapphire" direction): bright airy near-white background, iClub existing royal blue #2F6FD6, premium white raised surfaces, confident typography, tactile rounded components and generous spacing. Make the redesigned app feel genuinely NEW to returning students, not minimally restyled. But this project is an EXISTING LIVE Telegram WebApp; preserve the exact HTML/JS functional contract below.

ABSOLUTE RULE — VISUAL ONLY: Strict visual redesign only. Preserve the exact existing screens, controls, fields, actions, labels, navigation, hierarchy of user steps, permissions and app behavior defined by the supplied source/screenshots. Do not invent, remove, merge or rename features, inputs, buttons or screens. Only propose styling, spacing, typography, color, icons, layout within each existing screen and responsive appearance. Mockup code is not implementation authority.

SOURCE-CONFIRMED SHELL
- One existing sticky TOP BAR: #topbar. It has exactly (1) #topbar-back arrow on the left as an EXISTING conditional action, (2) center/left brand cluster containing the REAL iClub logo.png (not a fabricated new logo), title "iClub", subtitle "Smarter together", (3) right optional controls #topbar-notifications with real notification count badge #topbar-notifications-badge, and #topbar-action used for contextual actions including profile settings. The actual JS sets visibility according to current view, and the brand shifts left when Back is not shown.
- One existing BOTTOM TAB BAR: #tabbar. Exactly FOUR real tabs, in this source order, using the existing outlined icons and labels:
  [home] Главная / Bosh sahifa / Home
  [courses] Учёба / O‘qish / Study (use the app's actual translation in each locale; never rename to a new tab)
  [ratings] Рейтинг / Reyting / Ratings
  [profile] Профиль / Profil / Profile
  These are the existing navigation actions to their existing view routes, not new pages. No fifth AI, Search, Add, Courses, or Premium tab. The "courses" tab is actually labeled "Учёба" by the existing tab_study translation; do not substitute a different label just because the section contains courses.
- Existing tab classes .tab / .is-active and existing outlined SVG icons are part of source; keep all four and their current order. A label's text and tap action must remain together. No new floating button, contextual popover, drawer, long-press action or gesture.
- Existing #main contains views #view-home, #view-courses, #view-ratings, #view-profile and several nested/global routes. Do not redesign the content of Home, catalog, ratings or profile in B01; the visible content in comps must be **neutral existing-layout wireframe placeholders** whose source-matched contents will be separately designed in B02–B09. Focus on the SHELL, not inventing a new dashboard.
- On Home the topbar has brand and existing notification bell + optional grounded badge, Back hidden. Ratings has brand, Back hidden, no new topbar action; the Ratings view additionally has its own existing internal Back/search/info controls, which must NOT be deleted or merged into the shell. On Profile main the topbar has brand, contextual settings (gear), Back hidden; within Profile subpages Back is visible and contextual settings is absent. On the root Study view Back may be hidden, but on an eligible nested Study view it becomes visible. In active Practice the Back action safely PAUSES; Tour/Exam Prep restrictions are enforced by JS, not to be overridden by visual styling. On the Notifications global screen, Back follows the real view stack; no invented alternate navigation.
- When Back is hidden, the brand occupies the left space; DO NOT leave an empty 44px gap. When Back is shown, it has a >=44x44 touch target and is visually distinct from the brand.
- The splash has no topbar/tabbar. During registration the existing topbar with its App-Close Back remains and bottom tabbar is hidden. Certificate verification may also hide navigation; other assessment/global visibility follows current app.js, never force it visible through CSS. No change to control visibility/gating, no forced overlay on quizzes.

VISUAL TARGET / MATERIAL CHANGE
A. Develop a recognizably NEW premium shared navigation treatment in the same Sapphire family as B00:
  - polished brand cluster with original 32-36px logo, slightly stronger iClub wordmark hierarchy, quiet "Smarter together" subtitle
  - clean airy top bar with intentional balanced space, subtle depth/backdrop, consistently aligned optional buttons, compact badge with accessible number (sample counts must be clearly labeled fictitious)
  - distinctive, elegant bottom four-tab dock with generous touch areas, a clear selected state (soft blue pill/surface for active icon and label, or another equally refined and eye-catching presentation), gentle shadow/rounded edges and a coherent relationship to the top bar; still the EXISTING four-tab navigation
  - robust contrast and pleasing symmetry at 320px and 390px; glassmorphism should be subtle, with full legibility
  - integrate safe-area top/bottom, no needless vertical footprint, no overlay that blocks the last visible course/rating/profile action
  - style shared buttons/labels/focus/disabled visual states as a SMALL coherent component kit for future screens, but don't globally recolor assessment widgets outside the authorized block
  - appearance should clearly match the corrected B00 screenshots, while the global shell is more distinctive than old thin grey/nav rectangles.

B. The shell must remain useful even with no badge and when only one right-hand icon exists. Preserve text/icon alignment in all combos; avoid awkward unused space. Keep original icons or visually refine them without changing their meanings.

EXACT SCREEN VARIANTS TO RENDER
1. Home active (Главная selected): iClub + Smarter together at top, notifications bell and a clearly MOCK unread badge; four-tab bar with Home highlighted.
2. Home with zero unread notification badge: keep bell, no empty red bubble.
3. Study root active (Учёба selected): brand; no Back unless current route requires it.
4. Study nested details (same Учёба active): real Back displayed; show preservation of left logo/title alignment. The arrow does the EXISTING navigation/pause/locked behavior, not a new route.
5. Ratings active (Рейтинг selected): shell and existing separate internal ratings header actions unaltered; never replace the ratings search or info with invented shell actions.
6. Profile root active (Профиль selected): gear visible as contextual #topbar-action, Back hidden.
7. Profile nested screen: Back visible, gear hidden.
8. Notifications global view opened from Home: existing Back, badge/notification behavior as source, not a fifth tab.
9. Registration shell boundary: real logo and App-Close Back visible, bottom tabbar HIDDEN; may reuse approved B00 visuals but do not redefine registration layout.
10. Splash shell boundary: no bars shown.
11. Tabbar safe-area and longer-label examples at 320px, 375px, 390px and 1440px desktop; both light and soft-shadow states should remain legible. Include a screen showing keyboard visible with the bottom navigation behaving only as current source permits (do not invent hide-on-keyboard behavior).
12. Disabled/hidden states due to current quiz/Tour safety rules: illustrate absence/presence exactly per existing JS and call out that the image never changes action availability.

SINGLE-LINE / LINE-WRAP QA — REQUIRED OWNER DECISION
- Never split explanatory parentheses between rows. At sufficient width render "Основной предмет (для рейтинга)" on one line; at narrow width render "Основной предмет" and "(для рейтинга)" as two complete groups. Do not create orphan "(для" / "рейтинга)".
- For the shell, keep the short brand "iClub" and "Smarter together" intact and aligned; badge digits cannot overlap the bell icon; bottom-tab icon+label belong to the same button.
- Bottom labels should remain one line when they fit naturally at 320px, using reasonable responsive text sizing and even four-column widths. If genuinely too long, use a balanced TWO-LINE wrap at a legitimate semantic boundary, never crop with ellipses or render a lonely one-word afterthought. No horizontal scroll at any breakpoint.
- RU/UZ Latin/EN: no clipped words, no ugly partial words, no premature text wrapping in card headings, no invisible full labels.
- Respect 44px tap sizes, focus-visible states, screen reader labels and reduced motion. Never rely on color alone to indicate active tab.

ACTUAL LANGUAGE LABELS — preserve source
Russian: Главная, Учёба, Рейтинг, Профиль.
Uzbek Latin: Bosh sahifa, O‘qish, Reyting, Profil.
English: Home, Study, Ratings, Profile.
Topbar title is always "iClub" with subtitle "Smarter together", subject to exact existing source for special certificate title. Do not invent "My Learning Hub", "Expert Dashboard", "Mentor Chat", "AI assistant" in the header. Sample badge like 3 is VISUAL EXAMPLE ONLY; real value must be provided by the existing notification system.

OUTPUT REQUIREMENTS
- Deliver one complete 390px portrait shell with visual Home-neutral placeholder, plus a coherent gallery of 10+ variants explicitly labeled with what changes and what stays the same.
- Provide style tokens and precise geometry (topbar height, padding, tabbar items, icon sizes, selected state, safe-area) suitable for implementation as an ADDITIVE CSS override, not a new framework.
- Show 320px and Uzbek long-label examples, plus 1440px reasonable desktop behavior; preserve the four-button grid, not a new sidebar.
- Include a concise side-by-side visual delta compared with the OLD iClub shell, showing unmistakably stronger design presence; not just 2px radius and color tweaks.
- No fake metrics, credentials, user profile data, avatars, scores, prices, awards, learning progress, experiment flags, or fabricated product features.
- If your Stitch tool cannot produce all states, enumerate what is missing instead of designing unsupported routes.
- This is a DESIGN HANDOFF only. Do not output a deploy plan, rewrite app.js, alter auth or persistent data, change route rules, or claim integration success.

Reminder: B01 is the SHARED CHROME ONLY. B02 HOME CONTENT is the next separate Stitch block and should NOT be silently rewritten in this mock.
```

## Post-Stitch intake checks (do before any code)
1. Verify original four tabs and their RU/UZ/EN names (source label for courses tab is `tab_study`, not `tab_courses`).
2. Verify each Back/notifications/gear visibility case in actual JS.
3. Verify splash, registration and certificate verify still hide navigation when source does.
4. Compare with corrected B00 visual system for recognizability, rhythm, shadows and accent colors; require material design transformation.
5. At 320/375/390/1440 inspect labels, topbar, badge, safe-area and horizontal overflow. For parenthesized/orphan groups validate rendered line rectangles rather than merely relying on CSS declarations.
6. Reject any Stitch-invented tabs/buttons/metrics/actions; defer changes until architect approves design B01.
7. After accepted design, isolated Draft PR and offline real-app Chromium fixture for Home/Study/Ratings/Profile/Notifications/back cases. No user data writes, no merge without separate release GO.
