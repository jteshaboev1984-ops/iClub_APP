# iClub AI Preview — first verified real model response

**Date:** 19 October 2026  
**Status:** First genuine provider-backed public-app help answer verified. **NOT** production/global/student AI rollout.

## Root cause and fix

The screenshot showed `403` from `iclub-ai-qa-global` after an isolated anonymous QA Auth signup. That request was not an academic app failure or a Vercel build error.

- The Preview-only Auth test account existed in `auth.users`, but the separate `private.iclub_ai_qa_global_operator_v1` service allowlist did not initially admit it.
- Hosted PostgREST JWT claims were not reliably accepted by the QA service RPCs when checking only the legacy `request.jwt.claim.role` GUC. Five narrow QA canary RPCs were updated through live additive migration `iclub_ai_qa_service_role_claims_compat_v1` to honor trusted `auth.role()` first while keeping legacy-claim compatibility. Anonymous or signed-in learner JWTs still cannot directly call the privileged functions; only a verified server service-role request can.
- The screenshot Preview identity alone was admitted; **the three actual Mathematics beta users are still disabled for Global AI**.
- **No** production app bundle, Exam Prep algorithms, assessment records, Practice/Tour history, grade tables, user profiles, or localStorage keys were changed by this deployment.

## Actual full provider path

A separate one-shot isolated QA Auth identity was created by GitHub Actions and temporarily admitted to the exact operator allowlist. It invoked the deployed QA Edge, which:
1. Verified its signed Supabase Auth JWT and operator entitlement.
2. Enforced the independent funded canary switch and strict whitelist for verified public iClub help in an allowed locale and screen.
3. Atomically reserved `10000` micro-USD ($0.01) for one request.
4. Dispatched exactly one `gpt-5.6-luna` Responses API request.
5. Verified returned answer, provider model, token usage and accounting.
6. Completed the ledger with state `charged`, actual spend **114 micro-USD ($0.000114)**, and response `academic_state_changed=false`.

GitHub run **39227182937**, `one-real-reply`, conclusion **SUCCESS**:
https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39227182937

After that successful proof, the CI-specific test user was **disabled** in the allowlist. The one-shot workflow trigger was also removed from the QA branch to prevent unexpected repeat signups or paid requests. Its proof is preserved in the finished GitHub run.

## Final read-only production snapshot

- Enabled dedicated global QA operators: **1**, the existing anonymous Preview test account created through the user's button (no `public.users` profile and no Exam Prep entitlement).
- Enabled real Mathematics beta users in Global QA: **0**.
- Funded canary: **enabled** exclusively behind service authorization and isolated QA Edge.
- Money caps unchanged: **$1.00 lifetime, $0.50 UTC global/day, $0.05 operator/day, $0.01 maximum hold/call, at most 2 concurrent**.
- Paid ledger: **one charged event, 114 micro-USD**, and **zero unresolved** reservations/liabilities.
- Global production UI/gateway/generation OFF; global kill switch ON.
- Production Mathematics Exam Prep Tutor and existing learner access remain independent.

## Using the already-open Preview

**Same exact deployment origin is critical:** the voluntary QA session is held in per-origin sessionStorage. Do not switch to a new preview hash or create another account. Reopen the **same previously used Preview** `https://i-club-b5clj5fau-jasurbeks-projects-c5451f97.vercel.app/` with the previously issued temporary Vercel share link; tap `Проверить доступ`. A successful response will unlock the verified, narrow real-model route for approved public app help (e.g. `Что делать дальше?`).

This is **not** an academic-source-backed free-form Tutor. Questions about protected exams, unpublished subjects, personal marks or unapproved source content continue to be denied or answered by transparent prepared fallback as appropriate.

## Follow-up boundaries

Any expansion to more pilot accounts, academic help, real learner records, a new Preview origin, subscription entitlements or broader production rollout requires independent product/governance gates. Never advertise general AI as live for the other three beta users solely from this one small success.
