# iClub AI v2.1 — Source-governed Practice explanation QA checkpoint

**Date:** 15 October 2026
**Status:** QA implementation and synthetic E2E GREEN. **Production Global AI:** OFF / NO-GO.
**Branch:** `qa/iclub-ai-layer-v21-20261012`.

## Approved product decision

Architect accepted **iClub AI Tutor icon Option A**. The approved raster's optimized 96×96 transparent derivative is stored only under `qa/iclub-ai-tutor-a-96.webp`; it replaces provisional “AI” lettering in the real-app Preview button and header, not `logo.png`. Detailed brand acceptance and exact file hash: `docs/iclub-ai-tutor-approved-option-a-20261015.md`.

**Vercel Preview with approved mark:** https://i-club-ooxnejmos-jasurbeks-projects-c5451f97.vercel.app/
Deployment `dpl_EAP6N5RKLnVqw3F7yEDoZ7off2ub`, `READY`, immutable code revision `ff0e8c2d5e6551233e0608baa8778c10a6fdd462`. It is intentionally an **offline, synthetic real-app shell**, protected by project SSO and no-network CSP. No real learner actions or production Supabase calls. Approved logo artwork only, not a new AI release.

## Full verified-error QA technical path

`qa/ai-v21-practice-source-governed-error-e2e.test.cjs` connects existing implementations, without replacing production code:

1. Real Practice review screen selector in `qa/ai-v21-real-academic-screen-bridge.cjs` — `attemptReference` and `questionId` only; no scores, answers, readiness or topic data from DOM.
2. JWT-bound `QaV21ScreenClient.resolvePracticeV4` on the existing `/context` route; the protected service-role resolver maps actual Safe V5 `attempt_id` / `legacy_attempt_id` onto canonical owned `practice_sessions_v4.id`. Invalid sessions, wrong owners or active assessment refuse.
3. Distinct `/context` Practice mint for exact server-verified `sessionId` and `questionId`. This remains separate from the resolver and is not granted by the selector itself.
4. `/answer` status checks live scoped context, product release, rights approval, subject entitlement, requested locale, source SHA/revision and active-assessment blackout. No implicit translation between RU/UZ/EN.
5. `/answer` with `practice_error` returns **only a prepared answer approved for the exact locale and source**; no provider call, no academic mutation. After navigation, logout, source revocation, examination start or expired authorization the answer is refused.

### Test evidence

- **Logo + real browser test:** GitHub Actions run `38751755387` GREEN on pinned Preview commit `ff0e8c2`; Chromium loaded the local WebP image at native 96 px, checked the 40 px button and 32 px panel header, 320/390/1280 px layouts, Practice/Tour concealment; 0 remote responses and 0 JS exceptions.
- **Prepared error E2E:** GitHub Actions run `38752603713`, all three jobs GREEN on `4aa7f6be98a5578a670bf90dcf42fbdb3f188fc2`: 6/6 new E2E scenarios passed, prior 10+16+8+3 node contract groups and Deno /context tests still passed; loopback Chromium, temporary PostgreSQL and HTTP-to-PostgreSQL resolver GREEN.
- All explanations in these tests are explicitly labelled **SYNTHETIC QA ONLY**, not factual academic explanations or licensed textbook content.

### Explicit unresolved STOP conditions

- Local tests use synthetic identity tokens. Hosted real Supabase Auth/JWT, current-screen proof and all intended V2 RPCs are **not deployed**.
- Neither individual Cambridge curriculum source releases nor publisher/editorial rights, QA content corrections and RU/UZ/EN publication are approved. Do NOT derive them from an uploaded copyrighted textbook or pretend a generic model response is source-governed.
- The new server-side resolver and prepared-error candidate are isolated QA objects, **not imported by `index.html` or production Edge**; the protected Preview continues offering only guided navigation and correctly refusing fake scores.
- Practice result summary, full source-linked lesson explanation, Tour archive opening, Home/Profile personalized recommendations, and independent Exam Prep P1/P5 have their own different authority contracts. This milestone does not automatically enable them.
- Tariffs, AI spending/provider budget, rollout/cohort and the final real-user AI release remain separately blocked. Existing controlled beta, live Mathematics Tutor, production data and `main` unchanged.

## Next engineering objective

Prepare a **rights-reviewed editorial source manifest** for the first academically narrow Practice explanation, explicitly identifying `subject/topic/question`, source/version/hash, allowed RU/UZ/EN prepared variants and publisher rights. Keep it marked `NOT_APPROVED` and release OFF until checked and signed. Then test an authenticated hosted Preview architecture that cannot write to production student data, without creating a new paid Supabase branch.
