# iClub AI — next useful typed help milestone (QA only)

**Date:** 16 October 2026  
**Status:** QA Preview READY; production Global AI OFF; no model connected.  
**Verified commit:** `56c234c41b69bb58f4a429f71a46783c010713ee`
**GitHub Actions:** https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38902467696 — all three groups passed.  
**Preview:** https://i-club-b3qhy0g19-jasurbeks-projects-c5451f97.vercel.app/ (`dpl_4Rv4qVGq8nL1yv52VmDpEY8xXgyV`, target null).

## Actual user-facing improvement

Previously typing a clear, ordinary app question such as «Как обратиться в поддержку?» returned the same generic "test AI" fallback as unrelated typed questions. Now the **existing** iClub AI conversation offers a corresponding prepared navigation response for an **exactly matched** public app-help phrase, irrespective of which allowed app section is open, in RU/UZ/EN.

The new `qa/ai-v21-preview-typed-app-help.js` is an intentionally conservative, **offline-only** exact matching helper. Its allowed topics: Support, Leaderboard, Practice rules, Tour rules, subject catalogue, About, Certificates, Books, Notifications, Community, Recommendations, Archive, Video and public next-step guidance. It is NOT a model, not semantic AI classification, and never authorizes source publication, content correctness, student profile access or billing. Missing, ambiguous, academic or personal questions remain honestly declined in this protected Preview.

The current UX remains architect-approved: one global icon opens an empty contextual chat, suggested prompts require explicit selection, free-text queries are submitted only by user action. Explicit "Explain mistake" keeps its independently guarded one-click context. Active Practice/Tours and existing Exam Prep remain protected.

## Implementation evidence

- `qa/ai-v21-preview-typed-app-help.js`: 3-language public navigation exact string mapping; strict input-length, Unicode normalization and scope/screen guards; no substring, fuzzy match or guess.
- `qa/ai-v21-real-preview-fixture.js`: uses this helper only when the user **typed** a query with no prompt key; then reuses public app-help text already available in the QA fixture. Any other free text receives the existing honest unconnected-model fallback.
- `qa/ai-v21-real-preview-build.cjs` and QA regression tests: loader instantiated **after** synthetic no-write fixture; byte-for-byte bundled checks; no production script changes; CSP network blocked.
- `qa/ai-v21-preview-typed-app-help.test.cjs`: trilingual mappings, secret/personal/academic/assessment/privacy and injection refusals.
- `qa/ai-v21-real-preview-browser.cjs`: actual UI submits typed Support question and receives its relevant prepared response; a typed personal chemistry-score question is refused; the existing app-wide and protected assessment routes still pass.
- Existing full GitHub QA suite: **3/3 GREEN** for Preview/Deno/browser, disposable PostgreSQL and signed local Auth HTTP→PG.

## Non-negotiable next step

This is a more useful **preview experience**, not an artificially claimed live AI release. Truly open-ended typed generation will require the user-architect's separate provider and monetary-budget approval, authenticated server-bound scoped context, readiness/source/content rights per topic/locale, and a staged no-data-loss rollout. Do NOT silently activate a paid provider, real student cohort, tariff or production RPC from a green QA result.

**Production, Supabase, paid services, existing Mathematics Tutor, original app files and real student records unchanged.**
