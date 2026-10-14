# iClub AI v2.1 — §74 Accessible bottom-navigation preview candidate (QA only)

**Date:** 2026-10-14. **Status:** candidate only; no production application edits. **Global AI: NO-GO.**

## What was fixed in the isolated candidate

The four existing bottom tabs each contain a visible child `span.tab-txt[data-i18n]` and an icon marked `aria-hidden="true"`. The active i18n mechanism updates the visible span's text on language change; the static `aria-label` instead overrides that text with English. For `Study` it even uses a different English name (`Courses`).

A new pure QA-only transform `qa/ai-layer-v21-p6-nav-a11y-preview.cjs` removes **only** the four per-button static `aria-label` attributes from a copy of the original `index.html` held in memory. The native accessible name can then come from the visible translated caption. This needs no new on-screen UI text, state, storage, route, handler, subject permission, CSS or academic logic. Source drift and other changed buttons are rejected. The original `index.html` is never overwritten or shipped by the transform.

**Byte-level check:** on the current source, only four attribute substrings totaling 81 characters are removed; outside the tabbar, the HTML is unchanged. Current-source mismatches: 9 across RU/UZ/EN. Preview candidate's direct caption-comparison mismatches: 0. The `aria-label="Bottom navigation"` container landmark remains English and is an **open accessibility/translation decision**, not hidden in a GREEN claim.

## Isolated quality gates

- `qa/ai-layer-v21-p6-nav-a11y-preview.test.cjs` checks exactly four intentional changes, unmodified document prefix/suffix, no app imports, stable repeatability and rejection when route selectors or translated captions drift.
- Existing `qa/ai-layer-v21-p6-navigation-semantic-review.cjs` now supports either unchanged literal ARIA labels or the reviewed candidate's native name derived from visible text with hidden icon; both remain `NO_GO` pending editorial/accessibility sign-off.
- `qa/ai-layer-v21-p6-nav-a11y-browser.cjs` is wired into the existing QA-only GitHub Actions Chromium step; it uses the real nav markup, unchanged i18n source, simulated locale application and Chrome Accessibility Tree on **320×568 RU, 390×844 UZ, 1366×768 EN**. It checks focusability, clipping, equal visible/accessible names and zero external requests. This is a test harness, not a deployed Preview or a real screen-reader verification.

At this checkpoint the transform and semantic comparison have been directly evaluated against the current QA source; full native browser and GitHub Actions results are **pending independent CI observation**. Their inclusion in a workflow is not an assertion that a job passed.

## What remains

A separately reviewed production-safe patch may later remove these attributes from a release candidate after owner authorization. Do not automatically edit `main/index.html` or switch on Global AI. Independently review the landmark name in RU/UZ/EN and confirm with a real assistive technology test after an approved Preview implementation. All 18 prepared Help instructions remain editorial drafts, and Home next-actions has no approved server planner or academic priority policy.

No changes to existing Mathematics Tutor, `app.js`, `index.html`, `i18n.js`, shared styles, `exam-prep/`, Supabase, real progress, localStorage, tariffs, provider, live cohort or Vercel deployments. This candidate cannot approve or publish anything.