# iClub AI Layer v2.1 — §73 General Help: RU/UZ/EN copy and accessible-name review

**Date:** 2026-10-14  
**Status:** EDITORIAL CANDIDATE / NOT APPROVED / GLOBAL AI NO-GO.  
**Scope:** source-backed QA review only. No release, no schema/app migration.

## Sources reviewed

- `qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json` — six instructions in each of RU/UZ/EN (18 total).
- `qa/ai-layer-v21-p6-navigation-candidates.snapshot.json` — six current route candidates.
- Current unmodified `index.html`, `app.js`, `i18n.js` from QA branch; `docs/iclub-ai-layer-p6-editorial-review-sheet-v2.1.md`.
- This is a source audit, **not** an actual assistive-technology/screen-reader field test.

## Structural and semantic check

All six navigation destinations have corresponding selectors and handler expectations: Home, Study, Ratings and Profile in bottom navigation, plus About from Home and Support from Profile. The 18 draft instructions consistently quote the target captions exactly as present in the relevant UI locale. The navigation instruction for English About uses **“About project”** (entry button) rather than the destination heading **“About”**. The draft remains unchanged; no "approved" flag is inferred.

These checks establish *candidate copy consistency*, not complete translation quality, device accessibility, publication rights or academic suitability. Human editorial review remains required.

## Source-backed accessibility discrepancy

All four bottom-tab buttons in `index.html` specify a literal English `aria-label`. The visible captions are rendered from `data-i18n` translations. Since `aria-label` normally takes precedence over child text for the accessible name, the visible caption and the name an assistive reader may announce can differ:

| Button | Visible RU | Visible UZ | Visible EN | Static aria-label | Mismatches |
|---|---|---|---|---|---|
| Home | Главная | Bosh sahifa | Home | Home | RU, UZ |
| Study | Учёба | O‘qish | Study | Courses | RU, UZ, **EN** |
| Ratings | Рейтинг | Reyting | Ratings | Ratings | RU, UZ |
| Profile | Профиль | Profil | Profile | Profile | RU, UZ |

**Nine** mismatched view × locale combinations exist in the static source. Additionally, the bottom navigation container itself has the fixed English accessible label `Bottom navigation`. A browser/screen-reader audit is still required to confirm runtime behaviour and the most appropriate remediation.

### Product boundary

No attempt was made to change the production labels, `index.html`, `app.js`, the shared translation engine or visible route semantics. Accessibility repair of legacy tabs should be reviewed as a separately scoped, reversible patch. This source finding does **not** imply the new AI copy is published or ready.

## QA safeguard

New QA-only module `qa/ai-layer-v21-p6-navigation-semantic-review.cjs` and tests:

- Accept all 18 current *candidate* instructions only if their exact captions and parent tabs match `i18n.js` and the live route inventory.
- Reject cross-locale swaps, the wrong English About caption, missing quoted labels, nonexistent routes and attempted changes of draft approval/rights flags.
- Report the existing accessible-name differences separately, rather than silently declaring accessibility GREEN.
- Always return `status: NO_GO` and `independentLanguageAndAccessibilityReview: REQUIRED`; no publishing API exists in this module.

The negative scenarios have been added to the existing QA-only offline test runner and GitHub Actions path triggers. **Full CI GREEN must not be claimed until actual workflow results are confirmed.**

## Gates remaining open

1. Human review of language accuracy, reading simplicity, accessibility and rights for **all 18** lines.
2. Independently scoped remediation/review of the 9 static accessible-name discrepancies and tab navigation label.
3. Real screen-reader and keyboard verification on RU/UZ/EN mobile/desktop before any accessibility sign-off.
4. Independently verified source hash/version/locale publication, server authority, cohort approval and explicit owner GO before user-facing Global AI.
5. Home next-actions remains separately blocked until an architect-approved academic priority policy and owner-scoped server planner exist.

**Preservation:** No modifications to `main`, production app, existing Mathematics Tutor/Exam Prep, Supabase data/schema, localStorage, user progress, Vercel deployment, provider or billing. **Global AI remains OFF / NO-GO.**
