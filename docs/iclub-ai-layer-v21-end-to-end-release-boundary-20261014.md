# iClub AI Layer v2.1 — §76 End-to-end implementation handoff and release boundary

**2026-10-14 • QA-only • NO-GO • no production changes**

This document consolidates the implementation state and **does not issue** owner, editorial, security, provider, tariff or deployment approval. It is the last honest handoff point before work requiring real sources and explicit permissions.

## What is established by QA implementation

The existing unified offline candidate covers server-first authority/readiness, one panel and domain adapters, P1/P5 Tutor parity, finalized Practice/opened Tour archive access contracts, explicit protected-assessment blackout, 90-second JWT-owned screen handles, stale reply/revocation guards, synthetic quota/paid spend accounting and server-only cross-subject evidence readers. The corresponding SQL files are named `_UNAPPLIED` and were exercised only in temporary isolated database tests in earlier checkpoints. This is technical preparation, not proof that the production Supabase RPCs or source releases exist.

P6 now has 18 exact RU/UZ/EN draft navigation directions for six existing iClub routes, a fail-closed editorial/rights source gate, independent current-route and accessible-name checks, and a synthetic in-memory four-button nav-name remediation candidate. The current app's bottom-tab labels have 9 accessibility discrepancies; the candidate removes those 9 caption/name conflicts but has not been shipped. The bottom-nav landmark is still English. Navigation content is **not** published. Home's personalized next actions are **not** implemented: existing display percentages and local fallbacks are not server-signed recommendations.

The latest direct QA checks covered source-bound copy integrity, negative source mutations, JavaScript parse checks, and original-versus-transformed HTML equality outside the four safe attributes. Standalone Chromium confirmed the native-button naming method at 320 RU / 390 UZ / 1366 EN. However the latest complete GitHub Actions workflow result was **not available** through the status endpoint at handoff; GREEN must not be inferred from source or partial checks.

## Mandatory future release gates, in order

| Gate | Authority and objective proof needed | Current verdict |
|---|---|---|
| R1. Original Mathematics Tutor | Fresh production snapshot, retained 243 Tutor cards, 45 P1 + 36 P5 independent evidence, no double billing | Protected; final parity at release time still required |
| R2. General Help | Human-reviewed 18 RU/UZ/EN lines, source rights, hashes/versions, independent publication signoff | **BLOCKED — owner-approved product copy; independent editorial, rights and source publication pending** |
| R3. Accessibility | Confirm tab names in authorized Preview with real assistive-technology QA; review RU/UZ/EN landmark language and role | **BLOCKED — owner-approved QA navigation labels; live integration/assistive-tech test pending** |
| R4. Home next-actions | Architect-approved academic action classes, priorities/tie rules, owner-scoped server proof, current entitlement and server time | **BLOCKED — architect-approved order; real signed server planner and evidence completeness missing** |
| R5. P6 server integration | Governed source bundles, real service-role-only current-screen/evidence RPCs in isolated approved environment, revoked-source/current-exam negative tests | **BLOCKED — QA-only SQL** |
| R6. UI/Edge | Authorized and protected Preview, 320/390/desktop path/keyboard/mobile/safe-area, no active exam help, no stale token/profile bleed | **BLOCKED — latest complete integrated verification needed** |
| R7. Financial policy | Confirm provider cost model, negotiated final allowances and weights, worst-case spend and provider reserve protection | **BLOCKED — 1:3 remains TEST ONLY** |
| R8. Final release | Full latest Node/Deno/Chrome/13 scratch PostgreSQL and two-worker regressions, original Math regression + verified production data freeze, explicit cohort/provider/beta authorization | **BLOCKED — owner release GO not granted** |

**Do not treat R1–R8 as automatically passed by the successful QA candidate.** A protection gate can hold release even when all engineering test files exist. Technical gates and commercial decisions remain separate.

## Production-preservation proof at this handoff

The GitHub compare against the recorded production baseline `9afc7b44aead03b2a30544e6e7d4c4eb8670efbf` reported zero changed protected `index.html`, `app.js`, `i18n.js`, `style.css`, `exam-prep/`, `supabase/migrations/`, or deployed Exam Prep Tutor function paths in this QA branch. This proves a repository comparison, not a live Supabase row-by-row audit.

No branch promotion, PR, deployment, real account creation, production database write, student-progress modification, payment or provider call was made by §§67–76.

## Next authorized work

A reviewer can independently evaluate the [18 copy directions](./iclub-ai-layer-p6-editorial-review-sheet-v2.1.md) and [accessible names report](./iclub-ai-layer-p6-navigation-locale-a11y-review-v2.1.md), then the architect can settle the Home priority policy. After those gates and a verified isolated source release, implement the same QA-tested contracts in a separately approved Preview with the least privileged credentials and rerun all current tests; a new explicit owner decision must precede any real-user beta or provider spend.

**Final current verdict: Global AI OFF / NO-GO. Existing production Mathematics Tutor and student histories are preserved.**


## 2026-10-14 owner approval addendum (supersedes only R2–R4 decision-state wording)

The architect explicitly approved the existing exact 18 RU/UZ/EN navigation draft texts as product copy, the QA/Preview method for matching accessible tab names and localizing the navigation landmark, and the Home category order **finalized Practice mistakes → server-opened Tour archive → enrolled subject**. The source text is pinned to blob `ab94d7ca03bbdf521acc95dedafd0dba43c45f7e` in `qa/ai-layer-v21-owner-product-decisions-20261014.json`. QA code/tests exist in `qa/ai-layer-v21-p6-home-approved-priority.cjs`, `qa/ai-layer-v21-p6-nav-approved-locale.cjs`, and the owner product gate. These decisions **do not** sign rights, publish source bundles, install the missing owner-scoped cross-subject server planner, confirm latest full CI, enable providers or permit an actual Preview deploy/beta. General AI remains NO-GO. Full new checkpoint: `docs/iclub-ai-layer-owner-approved-qa-next-actions-20261014.md`.
