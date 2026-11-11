# B01 — UI shell source matrix and semantic wrapping QA (pre-implementation)
Date 2026-11-11 · Issue #531 · based on exact `main` `85297150a347e98deb8f1e1c58cfbfa2236aea03`. **Design-phase only**; do not construe as successful runtime QA.
Source: `index.html` `#topbar` and `#tabbar` original controls, `app.js` `showView`/`setTab`/`updateTopbarForView`/`bindTabbar`/`bindTopbar`, `i18n.js` real values, existing `style.css` and `visual/iclub-visual-v3.css`.

## Functional integrity cases (MANDATORY after Stitch and before merge)
| ID | Real current state | Allowed visible chrome | Exact preservation check |
|---|---|---|---|
| S01 | Splash | No topbar; no tabbar | Loading logo/text only; no flash of navigation |
| S02 | Registration | Topbar + app-close Back; no tabbar | Back closes Telegram app, not Step1; B00 remains visually coherent |
| S03 | Home root | Brand; notifications bell; tabbar Home active; Back absent | Notification count is actual data, not static mock |
| S04 | Home badge=0 | Bell without number badge | No empty red bubble or false unread count |
| S05 | Home badge>0 | Real count badge | Badge does not collide with bell/touch zone; no invented counts |
| S06 | Study root | Brand; Study active | Original `data-tab="courses"` action untouched; no fabricated Back |
| S07 | Study nested with Back enabled | Back; brand; Study active | Existing Back returns to correct Study state |
| S08 | Practice quiz with active draft | Actual available Back preserves safe pause | No CSS re-enabling disabled Tour or forced exit |
| S09 | Tour/Exam Prep locked paths | Exact JS-controlled back/tab restrictions | Styling never overrides functional lock conditions |
| S10 | Ratings root | Brand; Ratings active | Separate `.lb-header` real search/info/back remain visible/functional |
| S11 | Profile root | Brand + actual contextual gear; Profile active | Settings event selector and `#topbar-action` unchanged |
| S12 | Profile nested | Actual Back; gear absent | Preserve profile screen stack and action gating |
| S13 | Notifications global view | Back per view stack | No fifth navigation tab; no made-up bell on other views |
| S14 | About/Support/Certificates/Archive | Existing global Back visibility | Back, title, action and tabbar follow source |
| S15 | Certificate verify | Source suppresses nav | Prevent shell from showing an unsafe tab/back |
| S16 | Telegram safe-area | Header/footer respect safe inset | No content under status bar or home indicator |
| S17 | Keyboard/open field | Existing app behavior; no new keyboard automations | No clipped controls on responsive resize |
| S18 | RU/UZ/EN during tab switch | Exact source translation and no extra controls | Locale change does not reset course or exam progress |
| S19 | Online/offline/loading overlay | Existing banners and overlays | Z-index remains safe; modal and toast above shell |
| S20 | Narrow/mobile/desktop | 320/375/390/1440 | Four tabs present, tappable, aligned, no horizontal overflow |

## Exact source tab labels — important
`#tabbar .tab[data-tab="courses"]` visibly uses `data-i18n="tab_study"`, **not** `tab_courses`. Verified i18n source:
| Locale | Home | Study | Ratings | Profile |
|---|---|---|---|---|
| RU | Главная | Учёба | Рейтинг | Профиль |
| UZ Latin | Bosh sahifa | O‘qish | Reyting | Profil |
| EN | Home | Study | Ratings | Profile |

**No relabeling to `Предметы`/`Fanlar`/`Courses`** in the navigation; those are separate translation keys and are NOT the current tab label.

## Visual acceptance / line-break geometry
- Topbar brand `iClub` and subtitle `Smarter together` never intersect Back, notification bell, count bubble or gear.
- Four bottom labels should fit without splitting at 320px when practical; if wrapping is unavoidable, wrap only at a semantic space, never split a word or let one glyph hang on its own line. Never use hiding ellipses to conceal text.
- Preserve exact parenthetical groups in future screen titles: e.g., for `Основной предмет (для рейтинга)`, at narrow width `Основной предмет` / `(для рейтинга)`; never `(для` / `рейтинга)`.
- Test RU/UZ/EN labels with Chromium `Range.getClientRects()` or equivalent glyph rectangles on **rendered source text**, not just CSS property values. Check first/last glyph per indivisible semantic group share line `top`.
- At 320px, record `document.documentElement.scrollWidth <= window.innerWidth + 1`. No clipping within `#tabbar`, `#topbar`, `.tab-txt`, `.topbar-brand`.
- Icon and text should be aligned centrally; tab labels can expand within their actual four equal columns without shrinking to illegible sizes; active state never depends on color alone.
- Preserve tap target >=44x44 and focus-visible for keyboard users; the shell remains safe with Telegram safe insets.
- Do not globally set `white-space: nowrap` on all dynamic titles (can cause overflow); use selective nonbreaking grouping or balanced line breaking with real responsive measurement. No token change in i18n to hide a wrap.

## Gates
1. B01 Stitch export returned with all shell state illustrations, exact source controls and faithful Sapphire design, no invented tabs.
2. Architect approves visual design.
3. Separate additive CSS-only B01 implementation in isolated Draft PR (do not merge B00 automatically); when necessary do not alter original JS handlers/route/back logic.
4. Chromium before/after for the 20 functional scenarios + label geometry across RU/UZ/EN, min widths, and screenshots.
5. Explicit owner release GO only after isolated staging checks; no production/Supabase/data writes during design.

**Current state:** B01 source mapped and Stitch prompt ready in `docs/ui-redesign/12-B01-shell-stitch-prompt-and-wrap-contract-20261111.md`. No Stitch B01 images received, no B01 application code modified, no functional scenario in this matrix claimed as tested.
