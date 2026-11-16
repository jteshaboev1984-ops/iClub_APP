# iClub UX #531 — Academy OS v5.5, architecture lock & implementation safety gate

**Date:** 2026-11-15. **Status:** DESIGN APPROVED BY ARCHITECT (v5.4 with unified header v5.5); **NOT** runtime integration approved and **NOT** release approved.

## 1. Decision & source boundaries
- Old screen arrangements are **not** canonical. **Existing capabilities, business rules, data ownership and server permissions ARE canonical.**
- Design preview: independent Vercel project `iclub-academy-os-v5-phone-preview`, no Supabase/production connection; v5.5 is design reference, never a candidate to paste over source index.html.
- Core navigation: four destinations Home / Subjects (UI label replacing “Study” on catalogue) / Ratings / Profile; underlying `data-tab="courses"` and existing route stack **remain unchanged**.
- “Subjects” is for discovering/activating/pinning. Learning happens inside subject; labels must be confirmed RU/UZ/EN through existing i18n keys, not hardcoded in JS.
- Shared header family: Home = sapphire, Subjects = lighter sapphire, subject hub = deeper sapphire; future Ratings = steel-blue, Profile = blue-gray. Same logo position/scale, back affordance, notifications, safe area, typography, white surfaces, blue borders/shadows. No decorative formulas, circles, icons for subjects, or unrelated greens/golds/violets.
- Two **independent** horizontal carousels on Home: Competitive (0–2 items), Study pinned (0–N items); native swipe, snap, partial next-card peek, accessible navigation, no carousel when 0/1; no duplicated Subject activation action. No new backend data source.
- “Continue” above subject rails: only user-owned paused Practice drafts and server-confirmed Exam Prep active sessions. Do **not** infer resume from partial progress or open Tour sessions. Any sessions with ambiguous ownership/status fail closed; show a safe route to subject, not a fake Resume.
- Design mockups have illustrative cards/statuses; never ship demo numbers, demo toggles, preview-only actions or invented achievements.

## 2. Feature parity: source → intended UI → required proof
| Original capability | Existing source | Intended v5.5 place | Gate / invariant | QA |
|---|---|---|---|---|
| Home competitive subjects + tour status | `#home-competitive-list`, app.js `renderHome` | Home competitive rail | real server/user state, max two, no invented active flags | 0/1/2, dates, navigation |
| Home pinned subjects | `#home-study-list` | independent pinned rail | preserve user subjects, no new writes, empty state | 0/1/3/overflow |
| Home Extras / About / News / Community | `#home-extra-block`, `data-action` | compact extras, About visible | all original destinations accessible | exact actions/back |
| Resources / all subjects quick access | `#view-home .home-legacy`, source routes | move to relevant resource/catalogue entry | no disappearance even if moved from home | navigation inventory |
| Select catalogue filter | `#courses-filter-row` `state.courses.mainFilter` | Subjects segmented selector | no third mode; competitive 2/2 source behaviour unchanged | both filters, 2/2 |
| Open subject | `.catalog-head`, `guardStudy` | tap subject title/card | preserve commercial access guard | each subject |
| Select/unselect | `.catalog-toggle-row`, `guardLegacyToggle` | separate state control | competitive max 2, confirmations and reset warning unchanged; Study off currently removes subject record | cancel/save/failure |
| Subject hub mode | `#courses-subject-hub`, topbar | hub shared header + 3 inner panels | retain context/back/mentor and access | each mode + return |
| Practice | `data-action=open-practice` | Preparation + qualifying Continue | draft owner-bound; existing safe resume/start rules | paused same/other user, active |
| Tours | `data-action=open-tours` | Preparation | one attempt/anti-cheat/timers, no fake Resume | past/future/live |
| Math Exam Prep | `data-action=open-exam-prep`, host/native module | Preparation / P1, P5 labels | server gate; independent P1=45, P5=36; verified marks distinct | allowed/denied/pending |
| Lessons/books/recs | `open-lessons/open-books/open-my-recommendations` | Materials tab | existing Telegram/books/recs routes exactly | linked/open/back |
| Mentor | `open-subject-mentor` | Materials or compact profile row | no invented mentor chat or avatar | loading/assigned |
| Certificates/archive | `open-certificates/open-archive` | Achievements tab | access/issuance/download/QR unchanged | empty/issued/locked |
| Ratings/Profile/notifications/support | existing global views | future themed screens | original functions/filters/permissions unchanged | B06–B09 later |

## 3. Build strategy (non-destructive)
1. Work **on a fresh SHA-pinned draft branch**, never cherry-pick old draft CSS blindly. PRs #534 (registration), #535 (shell), #536 (Home) are still draft and diverge from v5.5. Inspect/diff and selectively reuse only verified source-safe pieces.
2. Deliver common shell visual system independently; CSS scoped to proper active root states, no leaking onto registration, tour full-screen, modals, exam attempts, public QR verification.
3. Deliver Home composition and rails. **Do not ship Continue** until reliable ownership-safe aggregated selector and authenticated routing exist, verified in staging. No direct localStorage guesses; respect DB server authority and draft binding. Preserve old actions.
4. Deliver Subjects catalogue and subject hub using original application handlers/identifiers, with genuine real data and access gates. No demo HTML in production.
5. Implement only in isolated Draft PRs; compare before/after at 320/375/390/430/1440 and RU/UZ/EN, plus keyboard/touch/voiceover. Preserve live local drafts, retries, pending operations, auth, history.
6. Run lint/CI, offline DOM fixtures and signed JWT/PostgREST + Chromium staging tests where relevant; screenshots & precise SHA in #531. Never use production user account for destructive test, never deploy `main`, never merge without explicit approval.

## 4. Gate status
- [x] Architect approves overall Academy OS direction + v5.4 swipe strategy; requests same Sapphire top-zone across screens and onward.
- [x] Concept v5.5 mobile viewport structural check 320/375/390/430: header, no horizontal overflow, core mock transitions. This verifies preview **only**, not live behavior.
- [ ] Production-source implementation (real UI) — NOT STARTED.
- [ ] Production/staging feature-parity E2E — NOT RUN.
- [ ] Security / ownership / cross-account draft isolation E2E — NOT RUN.
- [ ] Owner approves merge and production release — NO.

## Next
Begin **B01 shared shell + top-area compatibility audit** against current main and open PR #535. First source-safe implementation lives in a *separate isolated draft*, with screenshot/selector parity proof before merging. Then B02 Home and B03 Subjects/Hub; Resume aggregator is a separately gated task, not a CSS-only shortcut.
