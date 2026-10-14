# iClub AI v2.1 — §58–59 App Screen / General Help Isolation (QA only)

**2026-10-14. Working branch:** `qa/iclub-ai-layer-v21-20261012`  
**Release:** NO-GO. All changes are detached QA modules, offline tests and docs; not loaded in `app.js`, `index.html`, production Edge, Vercel or Supabase.

## §58 — Detect active nested lessons and unsupported overlays

Inspection of the actual `index.html` revealed that Courses includes many nested `.stack-screen` views, not merely the two protected quiz screens. A generic “Courses” Global Help handle should not supersede the source-specific Tutor context when the learner is on a video, Practice start/result/review/recommendations, Tour rules/result/review or a recommendation detail screen.

The QA-only `QaV21AppScreenBinder.read()` now disallows `courses-video`, `courses-practice-start`, `courses-practice-result`, `courses-practice-review`, `courses-practice-recs`, `courses-tour-rules`, `courses-tour-result`, `courses-tour-review`, `courses-my-rec-detail`, as well as the existing active Practice/Tour Quiz and protected Exam Prep. It preserves a clear separation from the already independently scoped Lesson, Practice, Tour Archive and active testing flows; other subviews still require their own future source review before allowing AI.

Previously `querySelector(".view.is-active")` could only inspect the **first** active global view. A stale allowed Home behind an unknown newly active Certificates/registration overlay could be mistakenly accepted. It now requires exactly one `querySelectorAll(".view.is-active")` node that matches the single allowlisted view. Hidden browser tabs and dual active views stay blocked.

In `askPrepared`, a valid Home/Profile screen must not launch a General Help answer: those surfaces require independent Home-next-action and Profile-governance semantics. Prepared navigation remains eligible for the four registered global navigation contexts `courses`, `ratings`, `about`, `support` only, subject to the **independently unreleased** server content gates of §51. No actual provider or UI is enabled.

## §59 — Detect differences between candidate and real production UI

An independent Node regression `qa/ai-layer-v21-p6-real-ui-contract.test.cjs` checks against **the actual unchanged** `app.js` and `index.html`, rather than synthetic fixture IDs alone. It verifies the router and DOM IDs, the protected nested stack list, that no unsupported views can be minted, and that detached scripts are absent from live HTML/JS. It fails on future app-route, DOM or context-surface drift, instead of pretending such screens remain compatible.

The exact binding, routing, JWT and async answer-race tests remain in `qa/ai-layer-v21-p6-app-screen-binding.test.cjs` and `qa/ai-layer-v21-ui-transport.test.cjs`. All remain synthetic, with no new account, student records, locale backfill, actual content signoff or Preview.

## Confirmed limits

A server-minted 90-second context is evidence of accepted **intent**, not the real physical pixels on the user's device. Hidden/onBlur and client logout attempt revocation; if the JWT has already disappeared, server-owned expiry, authenticated request checks and protected assessment guards remain essential. No change claims uninterrupted secure revoke across a real network disconnect. Real live integration needs navigation lifecycle review and protected independent Preview **only after explicit approval**.

The editorial drafts still need RU/UZ/EN human approval and correctly hashed source publication. Home still has no approved planner; Profile aggregates are not a mastery ranking. Global AI is **NO-GO**.
