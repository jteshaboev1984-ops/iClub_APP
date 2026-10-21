# iClub AI — Telegram WebView second real freeform failure and CORS remediation
**2026-10-21** · owner-approved Free beta · $5 lifetime cap unchanged

## Report
The user submitted a new General Help question in the Telegram mobile webview and received "iClub AI сейчас недоступен. Попробуй позже." The existing prepared General Help button answered correctly. This is a failed user acceptance check, NOT a successful model response.

## Verified production trace
Around **13:53 UTC** (18:53 Tashkent), Supabase logs:
- Prepared route `iclub-ai-v21-prepared`: repeated POST 200.
- New `iclub-ai-v21-freeform-beta`: **OPTIONS 204** but NO corresponding POST.
- Production `private.iclub_ai_v21_freeform_budget_ledger` and `freeform_quota_holds` remained at their previous single first-attempt row. There was NO new provider attempt/charged delivery. Thus the second incident occurred BEFORE Edge business logic and BEFORE OpenAI.
- Old initial attempt at 12:55 UTC did have a POST and unknown $0.05 liability. Its upstream provider root cause remains unconfirmed. Do not conflate the two distinct incidents.

## CORS defect (reproduced on live server)
Supabase `@supabase/supabase-js@2` is loaded via the iClub `index.html` CDN (floating v2 major). The new Edge handler v4 had a custom CORS allow-headers limited to `authorization, apikey, content-type, x-client-info`, omitting supported SDK headers `x-retry-count, traceparent, tracestate, baggage`.

An independent **public OPTIONS-only GitHub Actions** probe reproduced a **real live missing-header failure**:
- [Baseline live preflight FAILED: `x-retry-count` missing](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39617213129).
- Kept exact production Origin `https://i-club-app.vercel.app`, method POST, Telegram Android user agent and the complete canonical v2 SDK header list. No token, user data, POST or money was included in baseline probe.

Note: Supabase logs do NOT preserve the exact Access-Control-Request-Headers from the actual Telegram user's preflight. Therefore this confirms a real browser-compatibility bug in the Edge CORS implementation, **but does not prove which individual SDK header the user's device requested**.

## Safely applied fix
- `qa/edge_v21/freeform_beta_pilot.ts`: extend strictly the exact-origin allowed CORS headers to `authorization, x-client-info, apikey, content-type, x-retry-count, traceparent, tracestate, baggage`. No wildcard origin, no extra user permissions.
- Add Deno tests against the entire browser header set, wrong origin, and zero network/financial calls for OPTIONS.
- [Full synthetic PostgreSQL + Deno + Chromium/Math regressions PASSED](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39617494542), QA commit `e842235c2371d595a2b52f7b49e610814b303f11`.
- Re-deployed ONLY Supabase Edge `iclub-ai-v21-freeform-beta` to **v5**, `verify_jwt=true`. The existing prepared Edge, Math Exam Prep Luna, production GitHub main, Vercel frontend, academic DB and user localStorage were untouched.
- [Live corrected public OPTIONS preflight PASSED](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39618205077) with the full SDK header list.
- [Real Chromium CORS → POST path PASSED](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39618752734). Chromium navigated to the real production site then sent exactly one **synthetic, intentionally unauthorized** cross-origin POST using the SDK-style headers. Supabase live logs showed **OPTIONS 204 → POST 401** at 14:39:39 UTC. Authorization failure is correct for the fake JWT; no model usage or DB writes.
- Production readback afterward: new pilot enabled, lifetime cap still $5, exactly 1 prior `unknown` $0.05 possible liability, exactly 1 prior refunded learner quota, 0 successful generated replies, 111 old academic source admissions, 0 academic deliveries. Nothing reset.

## Remaining acceptance requirement
**Still not a positive live learner generation.** A consenting authenticated real student must send a NEW General Help question; then validate `POST` to Edge v5, source/consent/assessment checks, provider outcome and safe learner delivery:
1. Edge `OPTIONS 204` followed by authenticated `POST` (not a cached old failed bubble).
2. Money ledger gets one new bounded entry, and successful generation must be `charged` with verified tokens. Unknown provider status remains full monetary liability, no refund shortcut.
3. Student receives a useful source-grounded new reply; 3 shared 5-hour quota units become `completed`.
4. Core/Math Tutor questions/grades/progress unchanged.

If the new authenticated POST occurs but is rejected, inspect the **existing privacy-safe v4/v5 provider diagnostic code** (`iclub_freeform_provider_validation_failed`) rather than guessing model issues. The initial provider response on first incident remains unproven.

Do NOT expand beta roster or unreviewed Chemistry/Economics sources as part of this CORS repair.
