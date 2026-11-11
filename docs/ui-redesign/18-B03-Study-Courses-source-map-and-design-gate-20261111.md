# B03 — Study/Courses content source map and visual-only implementation gate
**Date:** 2026-11-11. **Master:** Issue #531. **Source verified against main:** `85297150a347e98deb8f1e1c58cfbfa2236aea03`. **State:** SOURCE MAPPED — NO B03 CODE CHANGE OR DESIGN APPROVAL YET.

## Real structures and original actions
| Scope | Existing source | What visual styling may change | What must remain exactly as app.js |
|---|---|---|---|
| Study/Courses root | `#courses-all-subjects` inside `#view-courses/#courses-stack`; `#courses-filter-row`, `#subjects-grid` | Header hierarchy, two existing filter chips, card spacing/images/shadows, responsive grids | `state.courses.mainFilter` defaults Study, two filter choices `competitive` / `study`; app.js `renderAllSubjects` & `saveState`; no new third filter/search |
| Catalogue card | Dynamically generated `.catalog-card` + `button.catalog-head` + real subject image `.catalog-ico-img`; `.catalog-toggle-row` + native `label.switch/input` | Card layout, icons/image display, active/inactive visual feedback, text wrapping | Clicking head follows `guardStudy` then opens actual `subject-hub`; switch follows `guardLegacyToggle`, confirmations and exact modes. **Competitive maximum 2**. Deactivating Competitive has explicit user-confirmed state/progress reset; NEVER silently trigger, hide or reinterpret this action |
| Subject hub | `#courses-subject-hub`, `#subject-hub-title`, `#subject-hub-meta`, `#subject-hub-mentor-btn`, `#subject-hub-mentor-avatar` | Sapphire title header, mentor card/text hierarchy | Real mentor data may be pending, leave original loading text/assignment and action |
| Preparation modes | Existing `#subject-hub-exam-prep-placeholder` / `#subject-hub-exam-prep-entry` conditional gate, Practice button `[data-action=open-practice]`, Tours button `[data-action=open-tours]` | Surface elevation, status chip typography, existing SVG alignment, 320px nonbreaking line wraps | No new Prep entitlement, no forced visibility of hidden Exam Prep, no changing Tour/Practice access, timer, scoring, draft/resume behavior |
| Materials and system | Existing subject hub `.subject-hub-actions` with `open-lessons`, `open-books`, `open-my-recommendations`, plus `open-certificates`, `open-archive`, `open-all-subjects` | Original settings-nav rows, icons, spacing, separators, hit targets | No new route or action, source visible state unchanged |
| Video | Existing `#courses-video` with subject title, note on Uzbek video-language and external Telegram opening | Card and CTA presentation only | No invented video player functionality, no new external lesson destination |
| Practice/Tours child routes | `#courses-practice-*`, `#courses-tour-*` | OUT OF SCOPE for B03; reserved B04/B05 | Do not touch assessment screens, Exam Prep runtime or navigation safety |
| Books/recommendations | `#courses-books`, `#courses-my-recs*` | Later B03 sub-stage if source checked | Preserve book/recommendation source and state |

## B03 visual output direction
Use B00/B01 Sapphire and B02 Home components: a noticeably new but consistent Student hub. Style only existing source elements; real `logo.png`, actual subject image assets, icons, dividers and shell remain authoritative. Avoid Stitch's invented class/courses/tuition/quiz/points statistics and fake actions. Prefer CSS-first isolated draft from main so B00/B01/B02 remain independently testable.

**Text handling requirement, explicit architect instruction:** maintain exact existing RU/UZ/EN labels, keep short phrases and explanatory parentheses together; no split words; 320px single-column cards when needed; test actual rendered `Range` text geometry, `scrollWidth`, no disappearing control labels, enough 44px target.

## Stage and safety gates
1. B02 Home draft [#536](https://github.com/jteshaboev1984-ops/iClub_APP/pull/536) first receives architect feedback (no implied release).
2. B03 catalogue + subject-hub visuals can proceed in separate isolated draft with **only additive CSS and original source DOM**.
3. State matrix: Study vs Competitive filter, 0/1/2 selected competitive, real cap error/confirm, pin/unpin behavior, pending access, subject images, long label cases, loading/empty and school/non-school.
4. No actual backend writes in QA; fixture only for visual, full source app.js/auth RLS stage required before release.
5. Do not merge, deploy or perform beta cleanup without explicit architect GO. Keep open Math Issue #450 and global #528 isolated.
