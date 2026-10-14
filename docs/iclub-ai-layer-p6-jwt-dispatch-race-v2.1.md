# iClub AI Layer v2.1 — §72 P6 delayed-JWT dispatch safety

**Date:** 2026-10-14. **Scope:** QA branch only; no deployed browser/Edge change. **Release:** NO-GO.

## Observed issue

The detached `QaV21ScreenClient.authenticatedPost()` awaited `readJwt()` and then called `post()` without an additional client-generation check. Its existing checks after a response were already capable of hiding a late answer, but this did not, by itself, prevent a stale request from reaching the Edge after navigation or sign-out. The distinction matters for provider cost, scope and audit clarity.

This observation concerns an **offline QA-only candidate**, not proof of the deployed iClub implementation being exploitable. The server must continue to enforce ownership, current screen, source, quota and assessment guards independently.

## Fix in isolated QA transport

- The transport now accepts a local `shouldSend` callback, evaluated only after successful awaited JWT acquisition, immediately before `post()`.
- `mintAppView` and other context mint requests cancel when a logout/navigation increments `epoch`, when the local clock is unsafe or when the elapsed auth wait exceeds the 90-second maximum context lease. The callback does not send any extra fields to the Edge.
- The same guard rechecks epoch, exact handle and remaining lease for prepared/generated `/answer` and answer-free status requests.
- Remote revoke retains its independent best-effort authenticated cleanup; local authority is invalidated before awaiting it.
- All existing after-reply checks remain in place. This is an extra **pre-dispatch** defense; it cannot replace server checks or justify publishing a source.

## Negative regression cases added

The existing `qa/ai-layer-v21-ui-transport.test.cjs` now includes:

1. Abandoned context mint: token resolves after `leave()`, zero `/context` calls.
2. Prepared answer or status: token resolves after logout, zero `/answer` calls.
3. Prepared answer or status: token resolves after screen switch, zero `/answer` calls.
4. Prepared answer or status: context expires during JWT lookup, zero `/answer` calls.
5. Context mint: JWT lookup exceeds 90 seconds, zero `/context` calls.

The test file is already part of the offline Node runner and watched by `.github/workflows/iclub-ai-v21-offline-qa.yml`. **No CI GREEN claim is made until an actual complete run result is observed.**

## Hard boundary

This update does not change `app.js`, `index.html`, `exam-prep/`, existing Tutor endpoints, Supabase SQL, Vercel, user progress/localStorage, a commercial entitlement, provider secrets, or the paid Global AI route. The unified AI remains behind NO-GO; editorial RU/UZ/EN and Home next-actions are still not approved.
