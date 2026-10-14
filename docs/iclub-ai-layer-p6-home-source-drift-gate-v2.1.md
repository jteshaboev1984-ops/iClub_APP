# iClub AI v2.1 — §71 Home display-source drift gate (QA only)

**Date:** 2026-10-14  
**Status:** REVIEW-ONLY / GLOBAL AI NO-GO.  
**Source branch:** `qa/iclub-ai-layer-v21-20261012`.

## Purpose

The existing Home UI is useful for navigation and visual progress summaries. It does **not** establish server-signed cross-subject recommendations or an authoritative academic next action. §70 reconciled these facts against the actual unchanged `app.js`.

The §71 automated source-drift check deliberately tests what must **not** be treated as recommendation evidence. It is a tripwire for future changes, not a certification of the existing UI percentages.

## Source facts locked for fresh review on drift

1. `renderHome()` uses `loadProfile()` and `filterActiveUserSubjects(...)`; pinned Study tiles are limited to four.
2. `computeHomeCompetitiveStats()` includes `anti_cheat` with `submitted/time_expired` in its UI completion query, uses `new Date()` for the device-local Tour window, and has zero-progress and module-1 fallbacks. No `tour_session_runtime_v4` finalization is checked in this display query. These displayed counters **must not** be substituted for opened-archive proof, mastery or the AI planning source.
3. `computeHomeStudyPracticeStats()` reads the existing Practice stage display helper, caches its result and can return zero counters on error. Missing data is not evidence of poor progress.
4. Home cards open the subject hub; `renderSubjectHub()` evaluates `guardStudy` and `isSubjectActive`. Any future server-side recommendation must additionally verify eligibility itself, then recheck when the student acts.
5. The isolated `QAHomeNextActionProof` is not loaded by live `index.html` or `app.js`. The General Help editorial draft still has release approval disabled; the P6 preflight remains `NO_GO`.

## QA enforcement

`qa/ai-layer-v21-p6-home-source-drift.test.cjs` verifies these precise implementation facts and intentionally breaks status/date/fallback fixtures to prove that source changes fail the check. The test is part of `qa/run-ai-layer-v21-offline.cjs` and the corresponding QA-only GitHub Actions trigger.

A future legitimate Home change may break this test; that means **redo the source reconciliation and update the test**, not that the changed feature is necessarily unsafe.

This test does not create a planner, read live learner records, approve the three proposed Home action types, decide ordering/weights, supply approved content, publish a source bundle, deploy Edge functions or grant beta access.

## Remaining decisions and release boundary

- Architect to approve which Home action types are pedagogically allowed and their priority/tie/absence rules before any planner is built.
- Independent owner-scoped server plan with versioned per-action evidence and source/locale releases is still missing.
- The 18 draft RU/UZ/EN navigation replies require independent editorial, accessibility and rights review; they are not automatically approved by this test.
- Verified SSO/owner-cohort permission, production-safe integration and explicit release approval remain mandatory.

**No changes to** production/main, live Supabase/schema or data, student progress, localStorage, the deployed Mathematics Tutor, tariffs, billing, provider calls or Vercel Preview. Global AI remains **OFF / NO-GO**.
