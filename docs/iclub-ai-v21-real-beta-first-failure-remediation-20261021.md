# iClub AI v2.1 — first real beta freeform failure / protected repair
**Date:** 2026-10-21
**Scope:** existing consent-only $5 general-help Free pilot; NO Math Tutor, grade, membership or academic source publication changes.

## Observed factual incident
The first consenting real beta user asked a freeform general-help question at ~12:55 UTC (17:55 Uzbekistan local time) through the Telegram mobile app. UI displayed localized “iClub AI сейчас недоступен. Попробуй позже.” This was **not** a success.
Production owner SQL read-only evidence showed exactly one money row `state='unknown'`, `held_microusd=50000` ($0.05 possible liability), `dispatched_at` ~12:55:23 UTC, `finished_at` ~12:55:26 UTC, and one student quota row `state='released'` (3 units returned). No academic delivery or confirmed positive model delivery.
Supabase request logs confirmed JWT/authentication, three locale/source/auth checks, monetary reserve/dispatch/settlement and quota release returned HTTP 200. The fault was **at the OpenAI Responses call or its returned model/usage validation**, not at Home UI, Supabase JWT, source permissions or student quota.
Provider HTTP status/payload was not previously logged. The exact upstream cause of this first attempt is therefore **not confirmed**; do not label the probable model snapshot mismatch as a proven root cause.

## Remediation
1. Disabled `private.iclub_ai_v21_freeform_budget_control.enabled` before making another charged request; other app features stayed untouched.
2. Identified a provider integration mismatch: runtime permitted only response.model exactly `gpt-5.4-mini`; OpenAI Responses may legitimately identify the published model snapshot `gpt-5.4-mini-2026-03-17`. API model documentation lists both.
3. Allowed only the alias **or its exact official dated snapshot** for payout and text validation. Skipped non-visible `reasoning` envelope output, while keeping all non-message tool/action output denied and preserving verified source and output safety checks.
4. Added restricted, non-PII diagnostics for HTTP status / fixed allowlisted provider error codes / completed status / recognized model / token usage. No prompt, response, keys, user ID, request ID or source is logged.
5. Extended disposable Deno HTTP tests for alias and snapshot, reasoning envelope, unrelated-model rejection and upstream HTTP 400. [Full protected QA PASS — 39604852768](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39604852768), QA commit `4c04a9003218d2f87237a75a50a2fce44eb49cf4`.
6. Deployed only Supabase Edge `iclub-ai-v21-freeform-beta` **v4**, `verify_jwt=true`. No GitHub main/Vercel frontend release was needed for this fix.
7. After version/QA verification re-enabled only new paid beta switch under original $5 cumulative limit, same one consented user, same existing approved Help sources. The unknown $0.05 liability remains counted. Exactly one student quota refund, zero confirmed generated replies, zero confirmed new paid charges at postflight. Existing 111 admitted source locales and Math Tutor untouched.

## Remaining validation
The repair is deployed, but it is **not yet a proven successful real user-generated reply**. Ask the same consented student to ask an in-scope Help question again (new request UUID, no quota from failed call). If it fails again, inspect structured Edge v4 diagnostics to distinguish actual upstream HTTP error from model-format rejection, disable the money pilot and fix specifically. Never retry the old request ID or erase uncertain provider liability.
