# B01 — Stitch export v2: four full-length screens, shell-only acceptance assessment
**Date:** 2026-11-11, 17:45 Asia/Tashkent. **Issue:** #531. **Status:** STITCH v2 RECEIVED → REVIEWED → **SHELL DESIGN PARTIALLY USABLE**, overall **NOT YET ARCHITECT-APPROVED**. No B01 code, backend, production, user data changes.

## Input and verified inventory
Uploaded archive: `stitch_iclub_registration_visual_redesign (3).zip`, despite legacy archive name content is **B01**. Inspected files without executing the supplied Tailwind/JS:
| Subfolder | Screenshot size | What it shows | Accuracy for B01 |
|---|---:|---|---|
| `b01_shell_home_unread_badge` | 543×1600 | Home header, mock unread badge 3, 4 tabs, placeholder dashboard | Reusable header/tabbar visual direction; invalid extra gear+avatar and unimplemented placeholder content |
| `b01_shell_home_zero_unread` | 533×1600 | Home zero badge, fabricated personalized dashboard | Zero badge absence correct; invented stats, events, courses, tasks, settings+avatar not source |
| `b01_shell_study_main_screen` | 493×1600 | Study tab and invented catalog, filters, lessons, progress | Study active tab correct; topbar incorrectly shows bell/gear/avatar; invented course functions; clipped horizontal filter |
| `b01_shell_study_nested_with_back` | 512×1600 | Nested Study with Back, fabricated English lesson+quiz | Back and Study active concept correct; topbar renamed `Course Detail/iClub Education` vs source `iClub/Smarter together`; non-source ellipsis/avatar, video/quiz, floating answer action and navigation safety questions |

Each state has a separate `code.html`; shared `academic_sapphire/DESIGN.md` also present. **Only 4 unique screenshots**, NOT 10+ state coverage. All screenshots are vertical 1600px, but at widths 493–543px; no true 320/375/390/1440 source-grounded layout example. HTML uses Tailwind CDN, Material Symbols, Google Fonts and local simulated page behavior, not production-compatible shell selectors.

## Source verified
Existing `main` SHA `85297150a347e98deb8f1e1c58cfbfa2236aea03`:
- Real `index.html`: `#topbar` grid with `#topbar-back`, real `logo.png`, title `iClub`, subtitle `Smarter together`, `#topbar-notifications` + count, `#topbar-action`; `#tabbar` four real `button.tab` with `.tab-ico`, `.tab-txt`.
- `app.js` `updateTopbarForView`: Home shows bell (Back hidden); Study root no bell/gear (Back according to stack); nested Study retains **iClub / Smarter together**; Profile root gear only (not shown in this export); Profile nested Back and no gear; splash no chrome; registration topbar Back is app-close with bottom tabs hidden; active Practice pause vs Tour/Exam Prep locking must remain unchanged.
- Real `i18n.js` tabs RU: Главная / Учёба / Рейтинг / Профиль; UZ: Bosh sahifa / O‘qish / Reyting / Profil; EN: Home / Study / Ratings / Profile.
- This is **B01 SHELL ONLY**. B02 Home and B03 Study catalog have separate actual source behavior; Stitch's decorative course content is NOT authorized.

## Strong elements worth retaining for CSS-only shell design
1. Pale Sapphire background, soft shadow and lightly translucent topbar, aligned existing brand title + subtitle;
2. Larger, more legible outlined nav icons with a clear active state and clean four-way spacing;
3. Restrained active blue (#2F6FD6) and consistent 44px+ targets;
4. Elegant raised/blurred footer surface and generous-but-not-excessive safe-area padding;
5. Distinct notification badge with the same semantic styling, but sourced only from real unread count.

## Rejected elements (do not copy from Stitch)
- **Invented Home/Study content and data**, including "14 из 22 модулей", 64%, 1,480 points, 98%, lesson schedules, professor/classes, enrollment, courses, audio quizzes, XP, community, 28 minutes. This export is only a visual reference for shared navigation, NOT authority to add or adjust actual dashboard/catalog/learning features.
- **Wrong topbar controls**: bell + settings + profile avatar appear simultaneously on Home and Study, but original Home has bell only; Study has no such trio. No new persistent avatar button.
- **Wrong nested header**: `Course Detail` / `iClub Education` and ellipsis/avatar where source still uses `iClub` / `Smarter together` with correct Back.
- **Wrong logo**: a cap/school icon replaces the actual iClub logo; never swap `logo.png`.
- **Questionable quiz shell**: source Tour/Exam Prep/Practice rules may suppress navigation/Back; do not force a tabbar or a new Pause/Check Answer control on top of a timed quiz.
- **Clipped text/overflow**: Study filter chips exceed viewport and course title rows use ellipses, violating architect's typography/semantic-wrap requirements.
- Unverified "Encrypted & Verified" claims, mock notification/activity/academic metrics, English `Home View Wireframe` label in user content.
- User-facing B01 screenshots for Ratings, Profile root/nested, Notifications, Registration, Splash and locale 320px are STILL MISSING. User did not yet approve a final B01 design.

## Efficient next move — avoid a third unnecessary Stitch cycle
Treat the four screenshots as **conditional design inspiration for topbar/tabbar only**. The needed changes are source-mapping/implementation work, not creative design ambiguity: retain actual `logo.png`, `#topbar` grid/`.is-no-left`, four tab buttons and exact source visibility, remove fake content/controls, apply additive CSS variables and selected states inspired by Stitch. Do not copy HTML, external scripts, JavaScript, or mock learning content.
**Await architect's explicit decision to accept the shell visual direction** before implementing in its own draft B01 code branch; if approved, self-correct the known differences instead of sending the user back to Stitch.

## Mandatory B01 acceptance
- Focus on shell only: topbar/back/bell/gear + four-tab dock; B02 Home and B03 Study content unchanged.
- At 320, 375, 390 and desktop 1440px, Chromium screenshots with **real** iClub shell markup, real RU/UZ/EN labels, correct app.js visibility states, badge=0 and badge>0, and no horizontal overflow.
- Inspect text glyph geometry: `Bosh sahifa`, `Smarter together`, `iClub`, tab label groups, no orphan/split parentheticals or clipped visible labels.
- Preserve back/notification/gear tap target ≥44px, original handler binding, no new actions.
- No changes to auth, Supabase/Postgres, users, practice/tours/Exam Prep, progress, other screen CSS, and no `main` or production deploy without separate owner release GO.
- B00 remains isolated [Draft PR #534](https://github.com/jteshaboev1984-ops/iClub_APP/pull/534), latest verified head `8a1aab29a5cb8924efdbe660f364d3846d864ff2`; do not mix B00 work.

**Next:** architect accepts or adjusts B01 shell visual direction based on these 4 screenshots. After approval, independent B01 CSS-first DRAFT and source-parity visual/functional QA; subsequent B02 and B03 content designs separate.
