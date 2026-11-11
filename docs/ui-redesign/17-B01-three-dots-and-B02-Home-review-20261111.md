# B01 icon restoration + B02 Home content — verified draft checkpoint
**Date:** 2026-11-11. **Master:** Issue #531. **Scope:** visual CSS only; project architect confirmed further work on screen content after B01. **Main SHA unchanged:** `85297150a347e98deb8f1e1c58cfbfa2236aea03`.

## 1. B01 Profile topbar icon regression — FIXED
- User supplied screenshot visibly reading `âš™` instead of the expected **three-dot menu symbol**.
- Root cause verified in `visual/iclub-shell-b01.css`: previous visual revision hid `#topbar-action[data-action="profile-settings"] > svg.v3-shell-icon` (the three circles of original `index.html`) and substituted CSS `::before { content: "⚙"; }`, which suffered a Unicode/mojibake display failure. Also changed existing icon semantics unnecessarily.
- **Repair:** removed both glyph-substitution rules and restored existing SVG with 3 circles. Kept the original `#topbar-action` button/handler, ID, dataset and source visibility (Profile root only) unchanged.
- Added Chromium assertion: original SVG has exactly three circles; computed SVG display is not none; no pseudo-content icon.
- **Source-isolated Draft PR [#535](https://github.com/jteshaboev1984-ops/iClub_APP/pull/535)**: HEAD `fbd6a1395578f93b3f34814f7505fb9325e6b832`; **[Actions #43065999659 SUCCESS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/43065999659)**. Screenshot `b01-after-profile-ru-390.png` in artifact `b01-shell-before-after-chromium` visually reviewed: original three dots appear, not mojibake. Do NOT replace with an emoji or gear in another CSS file.

## 2. B02 Home screen content — new separate draft visual-only
- **Draft PR [#536](https://github.com/jteshaboev1984-ops/iClub_APP/pull/536)** on `draft/b02-sapphire-home-content-20261111`, HEAD `d472600781a00bab11235864e29f8bdfbe909415`; base unchanged `main` `85297150a347e98deb8f1e1c58cfbfa2236aea03`. NOT merged/released.
- Exactly 4 source paths: new `visual/iclub-home-b02.css`; two-line stylesheet include in `index.html`; new isolated `qa/b02-home-content-browser.cjs`; new `.github/workflows/b02-home-content-visual-qa.yml`.
- **Existing Home source retained:** `#view-home` containing Competitive block `#home-competitive-list` (0–2 real user competitive subjects), pinned Study `#home-study-list` (0–4 source-bound entries), `#home-extra-card` expandable Extras, `#home-extra-body` and **About always visible**, News/Community under collapse. Hidden `.home-legacy` untouched. Original app.js dynamic card class/ID hierarchy, data fields, progress/badges/CTA listeners and action IDs untouched. No JS changes, no new route or feature, no auth/Supabase/localStorage writes, no hidden content removed.
- **Design:** Academic Sapphire card hierarchy, tall subject-image heroes from original asset files, clear verified status badges (using only source text), padded primary CTA, fuller progress bars, raised pinned tiles with original SVG book icon, white Extras accordion with original actions, pronounced heading accents. Responsive/polished labels; 320–439px pinned subjects single-column to preserve whole RU/UZ words. Source i18n text unchanged.
- **[CI #43068363801 SUCCESS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/43068363801)** at exact code SHA. Isolated Chromium, no app.js/auth/backend loaded, real Home HTML and copy of exact original dynamic card markup using **explicitly demo** values. Before/after screenshot source markup identical; only CSS differs. Passed RU 390 (2 Competitive/2 pinned closed; 2/4 open), RU 320 (1/2), UZ 320 (2/2 open), EN 375 (0/0), EN 1440 (2/4). All displayed navigation/extras text in fixture corrected to exact RU/UZ/EN i18n rather than accidental mixed languages. **No horizontal overflow and no broken words** on tested title and pinned labels. Source Controls About/News/Community each remain exactly once within the active Extras card; legacy duplicates remain hidden. Screenshot artifact `b02-home-before-after-chromium` contains six PNGs.
- Paired comparison files created in conversation: `b02_home_first_view_before_after.png` (same 390px viewport BEFORE/AFTER) and `b02_home_before_after.png` (full tall content). Original Home screenshot is NOT claimed to be a real authenticated user's Home: central card fields are representative source-shape demo content. Production data never involved.

## Explicit remaining gates
- Architect has not formally approved revised B02 visuals in PR #536; may request refinement on sizes, card density, and wrapping. **Do not merge/deploy** B01 or B02 automatically.
- CSS-only fixture passing is **NOT** live app.js/Telegram/Supabase production E2E. Before any release, stage both CSS PRs in an isolated test integration (without real user writes) and verify at least Home/Study/Profile/Notifications back/badge/gear state, actual view hierarchy, 4 navigation controls and bottom safe area. Keep B00 separate until tested and approved.
- Existing Maths Paper #450 and integration #528 remain separate and must not be touched. Main untouched. No beta data cleanup.
- **Next:** Architect evaluates B02 before/after screenshots, approves or requests specific corrections. Then proceed to B03 Study/Courses real content, not by copying invented lessons/stats/menus from Stitch. Source document `02-ux-blocks-roadmap-20261111.md` governs B03.

## Accurate status and SHAs
| Workstream | PR | Verified HEAD | QA | Merge |
|---|---|---|---|---|
| B00 registration | #534 | `8a1aab29a5cb8924efdbe660f364d3846d864ff2` (last known) | PASS isolated, release gate pending | DRAFT |
| B01 nav+three-dot correction | #535 | `fbd6a1395578f93b3f34814f7505fb9325e6b832` | #43065999659 SUCCESS | DRAFT |
| B02 Home content | #536 | `d472600781a00bab11235864e29f8bdfbe909415` | #43068363801 SUCCESS | DRAFT |
