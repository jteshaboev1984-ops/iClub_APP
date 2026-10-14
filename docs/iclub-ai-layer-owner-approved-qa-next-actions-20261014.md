# iClub AI Layer v2.1 — owner-approved product decisions, QA implementation (2026-10-14)

**Scope:** `qa/iclub-ai-layer-v21-20261012` only. **Overall release:** NO-GO. This is implementation authorization, not a publishing, migration, payment or cohort permission.

## Three decisions received from the architect

1. The exact 18 General Help navigation directions (six actual app routes × RU/UZ/EN) are approved **as product copy**. The approved snapshot is pinned to Git blob `ab94d7ca03bbdf521acc95dedafd0dba43c45f7e`; changed text requires renewed product review.
2. Accessible names should match localized visible bottom-tab captions. The isolated QA Preview approach may also localize the bottom navigation landmark to **Нижнее меню / Pastki menyu / Bottom navigation**. Do not change deployed UI, handlers or layout automatically.
3. Home action priority is fixed: **finalized Practice mistake review → server-opened Tour archive → continue active enrolled subject**. Only authoritative, owner-scoped and current, fully enumerated and independently verified evidence is eligible. **Never** use visual Home percentages, local fallbacks, device calendar time, `anti_cheat` status, incomplete Practice, locked Tour, other students' data or missing/expired entitlements as recommendation evidence.

Within the same priority level, if more than one verified subject is eligible, the candidate returns a **subject selection required** state rather than inventing a ranking. With no complete signed server evidence, the entire recommendation is unavailable; the UI may retain its normal non-AI navigation.

## Implemented QA-only code

- `qa/ai-layer-v21-owner-product-decisions-20261014.json` stores all three approved product choices, and makes explicit that publication/release/spend permissions are **false**.
- `qa/ai-layer-v21-owner-product-gate.cjs` verifies the exact approved Git blob and separates owner product signoff from independent rights, editorial publication, runtime and deployment signoff.
- `qa/ai-layer-v21-p6-home-next-action-proof.cjs` now returns minimal verified candidate metadata **only if** the server-authority-verified plan includes the exact policy version and a complete authenticated scan of all three action types. This proof already checks immutable plan snapshot, current screen, owner, TTL, independent academic evidence and locale-specific source release before returning a handoff.
- `qa/ai-layer-v21-p6-home-approved-priority.cjs` applies the approved order without grading, ranking subjects or writing evidence. In case of same-priority ties it asks the UI to offer verified options instead of inventing a tie-breaker. This is **not** an operating production server-side Home planner.
- `qa/ai-layer-v21-p6-nav-approved-locale.cjs` builds a detached copy of the tabbar with localized accessible names, plus a QA helper to synchronize the landmark if the locale changes. Its rules reject unsupported locales, unexpected DOM and any production release permission.
- P6 release preflight displays product approval explicitly while **always returning `NO_GO`**: real source publication, legally checked source rights, live server RPC, original Tutor parity in release candidate, accessibility field testing, tariffs and owner-cohort rollout remain independently blocked.

## QA verification and next release boundaries

Added isolated Node tests for the owner decision digest, Home priority ordering, same-priority tie, wrong owner, incomplete authority scan, changed source/revocation, expired context and refusal to publish. Navigation tests cover RU/UZ/EN landmark, native visible captions, source drift and no global app imports. Existing Chromium QA was extended to assert the locale-specific landmark and four native accessible names on three viewports. All new tests are in the QA-only offline Node runner and GitHub Actions path triggers.

**Verification precision:** code parsing and synthetic Home decision checks have been executed independently. A complete current GitHub Actions Node/Deno/PostgreSQL/Chromium verdict is **not independently confirmed** at this checkpoint. Do not treat this document as CI GREEN or readiness for deployment.

Before a protected *real app* Preview integration: prove separate nonproduction server-owned evidence/planner, exact authenticated screen handles and source governance, 18 source rights/editorial releases and browser accessibility. Before any real-user beta, real Supabase writes, payments, provider spend or production deployment: **new explicit release consent from the architect.**

**Never altered:** `main`, `app.js`, `index.html`, `i18n.js`, `style.css`, deployed Tutor, `exam-prep/`, migrations, Supabase data, localStorage, actual learner progress, billing, Vercel production.