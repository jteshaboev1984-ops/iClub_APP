# B01 Stitch export v1 — inspection, constraints and correction v2
Date: 2026-11-11 · Issue #531 · status: **STITCH RETURNED → REVIEWED → MATERIAL VISUAL REWORK REQUESTED**. No B01 code implementation or release authorized.
Source checked against real main `85297150a347e98deb8f1e1c58cfbfa2236aea03`; B00 isolated Draft PR #534 remains untouched.

## Actual uploaded file
`stitch_iclub_registration_visual_redesign (2).zip` inspected without trusting/executing its script or CSS. Contains exactly:
- `screen.png` **495×1600px**: one long **design-board**, an approximately tiny embedded demo phone, 12 miniature static variant cards, and a large code snippet. It is NOT 12 separate full-size mobile screenshots.
- `code.html` (45,341 bytes ZIP uncompressed) — one independent Tailwind/Google Fonts demo with inline JS simulated `setState`/`setTab` state switching; **not** iClub source code and must not be copied into production.
- `DESIGN.md` (8,454 bytes) — Academic Sapphire palette and component guidance (usable as inspiration only; not a verified responsive/runtime test).

## What the Stitch output gets right
- Correct 4-tab shell count and order in displayed primary RU mock: Главная / Учёба / Рейтинг / Профиль.
- Covers conceptual states for Home bell/badge, Study root/nested Back, Ratings, Profile gear/back, Notifications, registration boundary, splash and 320px Uzbek.
- Uses the intended Sapphire palette blue/white and sketches an active tab capsule.
- Explicitly flags sample unread count as fictitious and does not add a fifth tab.
- Notes that B01 is shell-only, not the actual B02 Home content.

## Problems to correct before design acceptance
| Priority | Observed Stitch output | Why not acceptable / source-safe correction |
|---|---|---|
| P0 DESIGN | One 495px-wide vertical collage with an approx. 150px-wide phone and 12 tiny cards | No individually usable 390×844/320px full-resolution mockups. Cannot judge impact, UI hit targets, meaningful line wraps or actual safe-area behavior; need separate full-size screen exports |
| P0 DESIGN | Topbar/tabbar minimally changed from existing | User's documented visual goal is emphatically visible, premium new appearance, not another microscopic cosmetic refresh. Raise the fidelity to corrected B00: elevated dock, clearer typography, more distinct selected pill and icon controls |
| P0 SOURCE | Invented blue 'ic' square in place of real `logo.png` | Preserve original real logo; placeholder only when asset unavailable, never replace the brand |
| P0 CODE | CSS guide uses `#topbar {display:flex}`, `#tabbar {display:flex}`, `.tab-indicator`/`.tab-label` | Existing topbar uses CSS **grid** and `.topbar.is-no-left`; tabbar uses four-column grid with `.tab-ico`/`.tab-txt`. Stitch CSS is non-drop-in and would risk real alignment/navigation. Never paste HTML/CSS runtime |
| P0 LOGIC | 'Tour In Progress — Back Paused' representation | app.js only pauses eligible **Practice**, while Tours/Exam Prep have different locks; do not invent Tour pause affordance or show locked Back as functional |
| P1 SOURCE | Nested shell mock may omit the 'Smarter together' subtitle | Actual updateTopbarForView sets brand/subtitle on relevant nested routes; preserve source |
| P1 QA | Uzbek 320px and English responsive handled as miniature text examples, not true browser evidence | Separate real mobile images showing Bosh sahifa / O‘qish / Reyting / Profil; no clipping, wrap splitting, badge overlaps |
| P1 QA | Only eight interactive state switches despite 12 static state cards | Need separate visible variants or explicit missing checklist; do not present simulated state harness as actual app |
| P1 PRODUCT | A large dark debug state-picker and CSS panel dominate the exported board | These are documentation, NOT user-facing app controls. User-facing mockups must contain only real iClub controls |
| P1 COVERAGE | Ratings' existing internal Back/Search/Info only mentioned in prose | Show them in an authentic Ratings state below the shell without deleting/merging them |
| P1 QA | Screenshot/document claims source-locked/compliant/verified | No authenticated runtime, full-sized responsive or source-CSS integration QA actually performed by Stitch. Treat as design hypotheses only |

## Exact source rules that survive
- `#topbar-back` clickable Back is conditional; in B00 registration it CLOSES app, in eligible Practice it safely pauses, in a locked Tour/Exam Prep it obeys existing JS rules.
- Notifications button only source-allowed state; unread badge must reflect real source data.
- Profile root uses `#topbar-action` gear; profile subviews use Back instead.
- Tabbar buttons are exactly `[data-tab=home,courses,ratings,profile]`, source labels RU `Главная/Учёба/Рейтинг/Профиль`, UZ Latin `Bosh sahifa/O‘qish/Reyting/Profil`, EN `Home/Study/Ratings/Profile`.
- Semantic line-wrap requirement: no split parenthetical groups or orphan words; verify using actual rendered glyph geometry at 320px and 390px after any implementation.
- No changes to authentication, Telegram, original data, account registration, Practice/Tours, Supabase, i18n texts, other views or production.

## Ready-to-copy targeted Stitch correction v2 for the SAME project
```text
Continue in the SAME iClub Google Stitch project. REVISE the B01 Global Shell mockup you just generated (one 495×1600 composite board with a tiny phone, 12 small state cards and a long CSS code panel). Keep the existing Academic Sapphire color family and correct four-tab navigation. Do NOT redesign from scratch.

ARCHITECT'S VISUAL GOAL: a student must immediately see that iClub has a NEW premium design. The current tiny demonstrations are useful as documentation but are NOT polished, full-size mobile screen designs. Make the TOP BAR and BOTTOM FOUR-TAB DOCK visibly more distinctive, balanced and refined than the old shell while retaining all existing actions and brand.

MANDATORY FIRST OUTPUT: produce SEPARATE FULL-RESOLUTION 390×844 mobile screens (one clear phone-width mockup per export) rather than a long collage or CSS guide. Provide:
A. Home / three MOCK unread notifications / Home active.
B. Home / zero unread / no red badge.
C. Study root / Study tab active / Back hidden.
D. Study nested / Back visible / Study active.
E. Ratings root / Ratings active / preserve the EXISTING internal ratings Back/Search/Info controls in their OWN header beneath the shell; no invented routes.
F. Profile root / Profile active / real contextual settings gear / no Back.
G. Profile nested / Back visible / gear hidden.
H. Global Notifications / real Back / four existing tabs if source allows.
I. Registration boundary / existing App-Close Back and brand, bottom tabs HIDDEN.
J. Splash boundary / no top bar, no bottom bar.
K. Small-phone 320×720 and 375×812 proof with real UZ Latin names; at least one 1440 desktop adaptation.
L. Practice/Tour safety notes, without inventing a visual action unsupported by the app. If an exact state cannot be drawn, label it MISSING, never replace with invented interface behavior.

VERY IMPORTANT FUNCTIONAL DISTINCTION: During an active Practice quiz, the existing Back action can safely pause an attempt when allowed; for Tours and Exam Prep existing lock/anti-cheat rules may block navigation. Your 'Tour In Progress — Back Paused' example is WRONG. Remove it. Do not render Back as permitted in a locked Tour or invent a Pause action for Tours. The original JS remains authoritative.

EXACT EXISTING SOURCE CONTRACT — DRAW THIS, DO NOT REPLACE IT:
- One original TOPBAR uses a grid with #topbar-back, .topbar-brand containing REAL logo.png, #topbar-title 'iClub', #topbar-subtitle 'Smarter together'; right #topbar-notifications and #topbar-notifications-badge; contextual #topbar-action for settings. When Back is hidden, existing .topbar.is-no-left shifts the brand left. If Back is visible, it remains a >=44px touch target. Do not remove subtitle from nested states unless source explicitly does so.
- One original BOTTOM BAR has exactly four EXISTING button.tab children with .tab-ico (real SVG icon) and .tab-txt (translated label). Existing JS uses data-tab='home', 'courses', 'ratings', 'profile' and .is-active. Do not create a fifth item, center plus button, AI shortcut, search, home badge or fake unread controls.
- REAL NAVIGATION LABELS:
  RU: Главная | Учёба | Рейтинг | Профиль.
  UZ Latin: Bosh sahifa | O‘qish | Reyting | Profil.
  EN: Home | Study | Ratings | Profile.
  In Uzbek the second tab is specifically O‘qish, NOT Fanlar. The source i18n key is tab_study (NOT tab_courses). Tab count/order/actions never change.
- #topbar-notifications is visible on Home, zero count hides the badge; #topbar-action (settings) is visible on Profile root. Other states rely on existing app.js.
- The original iClub logo MUST be used, not the fabricated blue 'ic' square from your first export. If you do not have logo.png, use a clearly labeled 'existing iClub logo' placeholder in the mockup; never draw a replacement brand.
- The topbar and tabbar have existing source DOM, CSS, event listeners and conditional show/hide. NEVER propose replacing them with Stitch's React/Tailwind buttons or independent scripted page state.

CRITICAL CSS-FIDELITY CORRECTIONS:
Your first exported CSS guide suggested '#topbar {display:flex}', '#tabbar {display:flex}' and selectors '.tab .tab-indicator' / '.tab .tab-label'. These do NOT match the existing iClub shell. The real #topbar is grid-based, #tabbar has a four-column grid and the existing labels are .tab-ico/.tab-txt. Preserve existing DOM classes, four-equal-column grid, .is-no-left behavior and JS-controlled 'display:none' on splash/registration. CSS-only, additive design proposals must STYLE the actual selectors, not replace their structure or claim that new elements already exist. Do not put a giant block of code into the screenshot; send any design tokens as a short separate reference note.

VISUAL QUALITY — MAKE A REAL DIFFERENCE:
Use the corrected B00 visual language: modern light Academic Sapphire (#FAF8FF page background where appropriate, existing primary blue #2F6FD6, rich #1E56B3 accents), softer substantial elevation, generous but efficient breathing room, confidently sized real iClub logo/title, high-quality notification/settings icon surfaces, visibly elevated rounded bottom navigation with a distinctive active soft blue capsule and matched icon/text. Align left/right controls and brand symmetrically. Avoid childish oversized badges, decorative widgets, misleading completion percentages or a dark engineering-dashboard selector within the app screen. Your state picker was a demo harness, not an iClub screen: REMOVE IT FROM ALL FINAL APP MOCKUPS.

WRAPPING IS A HARD ACCEPTANCE TEST:
- On 320px the four existing tabs are equal width, all icons aligned, labels legible and never clipped; 'Bosh sahifa' may stay in one line if it fits but must never be arbitrarily broken in the middle of a word. No ellipses/horizontal scroll.
- Brand 'iClub' and slogan 'Smarter together' must remain visually intact and never collide with Back, bell or gear. Badge count may not overlap the bell icon or screen boundary.
- Preserve meaningful phrase grouping throughout the future designs: e.g. 'Основной предмет (для рейтинга)' should be one line if it fits, otherwise 'Основной предмет' / '(для рейтинга)'. Never '(для' / 'рейтинга)'.
- Account for Telegram safe area (top and bottom), keyboard, focus and >=44px tap sizes. Show RU, UZ Latin and EN examples with REAL labels. Do not simply assert 'responsive' without showing a full-size narrow example.

DELIVERY FORMAT:
1. Separate polished 390×844 PNG screens for A-H, one or more full 320px Uzbek and 1440px examples, readable at actual screen scale.
2. A small complementary state matrix for I-L if a full screen is not helpful, but clearly label the conditional visibility rules.
3. Brief design tokens, CSS target mapping only to existing source selectors and a visible before/after comparison of the OLD iClub navigation vs your significantly refreshed version.
4. NO replacement framework, NO fake metrics or people, NO invented features, NO code deploy instructions, NO production modification.

This is strictly a visual design iteration. Leave all JavaScript behavior, Supabase/auth, user progress, existing registration B00, course routes, Practice/Tours assessment restrictions, badges and app functionality unchanged. A mockup is NOT implementation authority.
```

## Next stage
Architect sends correction v2 to SAME Stitch project and returns full-size, source-matched ZIP/screenshots. Assistant reviews visuals and exact existing actions; only after owner design decision, create an isolated B01 Draft PR with CSS-first targeted selectors and offline browser QA. **No B01 application code touched yet**, no release GO.
