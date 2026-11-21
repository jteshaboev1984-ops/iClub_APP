# Mathematics Season 2 — compatible redacted preflight (HOLD)

Source checkpoint: GitHub main `65a40204d719f8e5dd67ef87d62fb73902131367`, 2026-11-21. Canonical [Issue #574](https://github.com/jteshaboev1984-ops/iClub_APP/issues/574). This candidate is independent of historical [Draft #610](https://github.com/jteshaboev1984-ops/iClub_APP/pull/610), whose unconditional S2 denial cannot ship with current or cached app.js. No academic content, answer keys or image assets are committed.

## Verified live SELECT-only baseline

- Seven inactive/undated Mathematics Season 2 Tours: 140 distinct items, exactly 20 each; each has six Easy, nine Medium, five Hard, sixteen MCQ, four input, one Hard diagram. Structural and required trilingual-field checks 7/7 PASS; no cross-tour/S1/Practice overlap or recorded attempts/session references. No academic/rights/language human signoff inferred.
- Existing privileged preflight function source MD5 `91fc6b12dcb059426668bdff040223b1` (unchanged at live readback). Existing public catalogue / ID lookup currently returns zero S2 Math rows; these are point-in-time aggregate checks, not universal future authorization proofs.
- Seven diagrams still have public URLs: four GitHub-backed and three Supabase `/storage/v1/object/public/`. No tokenized URLs. Keeping them as-is leaks image content even if question text/options are redacted.

## Scoped source candidate

The `supabase/candidates/` SQL is **not** a versioned migration or approved hosted change. It retains the existing signature and all existing user/subject/date/count/competitor guards. Only for S2 Mathematics it returns 20 positive IDs in order and image preload URLs, with all question text/options/timing/topics/difficulty/book refs redacted. The actual 20 questions still come from the already-existing server-authoritative `start_tour_attempt_safe_v4` → `get_tour_session_questions_safe_v4` path. S1, Chemistry and other subjects are not intended to change. The function's preimage MD5 pin fails closed on unexpected live drift.

The old client depends on `preflight → preload images → start attempt → issued questions`. Returning no rows or a blanket error breaks its startup. This proposed redaction deliberately keeps the preflight shape; image preload failure still occurs before a consumed attempt, but the public image URL exposure is an unresolved launch blocker. Suppressing image URLs without a new protected-image readiness protocol would permit start with missing assets and must not be treated as safe.

## Tests and remaining GO gates

- Source guard and synthetic PG17 fixture test preflight redaction plus S1/Chemistry unchanged, 20-row old-client compatibility, synthetic image readiness, preserved bank rows and anon denial. This is **not** signed GoTrue/PostgREST/Chromium or Telegram WebView end-to-end acceptance.
- Before any host install, independently audit all RPC and direct table routes plus protected diagrams/assets; finish image access under authenticated, time-scoped delivery without breaking existing users, inspect old cached builds, and run signed JWT→PostgREST→PG17→actual app.js Chromium start/20/submit/resume/anti-cheat/timeout/history including image failure and rollback. Verify no attempt loss or leak and S1/other-subject parity. Final academic key/diagram/originality + RU/UZ/EN human review, dates decided by owner, and separate source-merge/hosted SQL/asset/Tour-launch GO are required.

**Release verdict: HOLD.** No Tour active/date change, main merge, Supabase mutation, Vercel deployment, image relocation or learner history change authorized.
