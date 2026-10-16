# iClub AI v2.1 — natural one-click Practice Review UX checkpoint

**Date:** 16 October 2026
**Architect acceptance direction:** one click must perform the entire in-context AI handoff; fake per-letter typing, repeated "Explain" tap and choppy re-render are disallowed.
**Branch:** `qa/iclub-ai-layer-v21-20261012` (isolated, source files frozen).
**QA CI:** [GitHub Actions 38853715340](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38853715340) — **3/3 jobs success**, pinned to commit `77ada62fd5472e6d27835e9f862cef88e02ca6f3`.
**Vercel protected Preview:** [Open iClub AI](https://i-club-202bcs130-jasurbeks-projects-c5451f97.vercel.app/), deployment `dpl_JhbnWdS1QXinSAcbfa2nAuMM1Li9`, `READY`, `target=null` (not production).

## Decision and implemented behavior

User's selected illustrative error at the original iClub Practice Review screen triggers exactly one action:

1. Open the SAME iClub AI Tutor bottom sheet with accepted **Option A** AI icon, not a new detached mock.
2. Immediately display the exact selected example question/answer in a read-only context strip. Never stage fake keyboard strokes or ask the student to select an AI quick prompt again.
3. Show one short user intent, a native pending state and the prewritten **synthetic QA** answer in a readable card: why it is wrong, 3 mathematical steps, and a follow-up understanding check.
4. Preserve existing message DOM nodes as requests update; avoid restarting entry animations or scrolling to the explanation's footer. Auto-scroll to the start of the final explanation. Respect reduced-motion preference.
5. Close and revoke demo context on navigation; rapid double-tap does not duplicate a request or explanation. All active Practice/Tours/Exam Prep assessment protections remain. The QA example cannot be mistaken for student history or a published source.

## Exact QA-only files changed

- `qa/ai-v21-real-preview-ui-snapshot.js`: scoped demo handoff, stable chat nodes, contextual strip, per-step structured explanation and first-step scroll; guard on `__ICLUB_AI_QA_PREVIEW__.noProductionWrites`.
- `qa/ai-v21-real-preview-demo.js`: original synthetic math example and **independent RU/UZ/EN fixed explanations**, suitable for interface testing; not a real Cambridge exam question or customer data.
- `qa/ai-v21-real-preview-ui-snapshot.css`: calmer 250ms sheet transition and responsive step-card styles; reduced-motion support.
- `qa/ai-v21-real-preview-fixture.js`: replaces staged 850ms delay with a brief 360ms QA-only response processing interval (no provider or network call).
- `qa/ai-v21-real-preview-browser.cjs`: automated two-rapid-tap real app check; requires single request, no manual second tap, no fake input, exact context strip, 3 structured steps, initial explanation visible.

## Regression evidence

- Native Chrome test on actual application source: Home -> illustrative Practice Review -> a single explicit Explain tap -> context shown -> short request sent -> 3-step answer -> back to Study.
- Browser acceptance passed in three viewports, active Practice and Tours hide AI, no external responses, zero observed JS exceptions.
- Existing Node/Deno contracts, rights/editorial/answer source non-release gates and disposable local PostgreSQL HTTP resolver jobs remained GREEN; protected `app.js`, `index.html`, `global-ai-ui.js`, `global-ai-ui.css`, `exam-prep/` and `supabase/migrations/` were unchanged.
- Vercel Preview is SSO-protected, no-production target, no paid provider, no learner read/write or Supabase networking.
- Previous design logo Option A stays unchanged; no recoloring/redesign was applied.

## Strict release status

This is a **visually ready, non-production QA demonstration**, not real academic tutoring. The sample answer is locally prepared original text; it is never derived from a learner or a published Cambridge source. Real signed JWT/authenticated permissions, server-verified academic records, and editor-reviewed RU/UZ/EN content remain separate mandatory release gates. Keep Global AI OFF for production, keep Mathematics Exam Prep P1/P5 Tutor independent, preserve every learner's scores/progress/storage.

**Next:** Architect visually evaluates naturalness and question context in the new protected Preview. Any later production rollout requires a separately approved safe data/backend release.
