# Mathematics P1/P5 — Stage B authenticated HTTP E2E, first implemented integration segment

**Date:** 2026-11-01  
**Repository:** `jteshaboev1984-ops/iClub_APP`  
**PR:** [#452](https://github.com/jteshaboev1984-ops/iClub_APP/pull/452)  
**Evidence run:** [GitHub Actions 41322969750](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41322969750) — **GREEN** at observed candidate before the final ephemeral JWT-log masking hardening. Recheck workflow after masking before merging.

## What actually runs (NO mocks for RPC results)

- Real checked-in Mathematics `exam-prep-api.js`, `exam-prep-host.js`, `exam-prep-live.js` execute in Playwright Chromium on a mobile viewport, English locale.
- `window.sb.rpc` is a browser **fetch transport** speaking actual HTTP to local `postgrest/postgrest:v12.2.3`. All returned data, errors, authenticated authorization and item correctness originate in *real PostgREST + actual versioned public RPCs + isolated PostgreSQL 17*. It is **not** the official hosted Supabase GoTrue/Auth service or production API.
- A CI-only HMAC JWT with role `authenticated` / subject of a fake learner uses the real PostgREST signature validator and PostgreSQL role context. A local `auth.uid()` compatibility fixture reads JWT `request.jwt.claims`; **never apply this fixture to production**.
- A second fake learner and anonymous/invalid JWT attempts check authorization isolation.
- Actual P1/P5 diagnostic questions, stage-0 routing, weekly plan generation/readback, learning question flow and finalization persist in the **disposable** PostgreSQL service.
- Real historical student accounts, responses, active sessions and production Supabase have **no involvement**.
- CI reuses the already verified full P2-73-style migration bootstrap/order, rather than maintaining a divergent schema.

## Verified integrated acceptance — exact green run 41322969750

| Covered operation | Actual browser/HTTP/server/DB evidence |
| --- | --- |
| Student sign-in *at HTTP JWT layer* | Signed local JWT accepted, anonymous and malformed JWT denied |
| First exam profile | Actual Math UI wrote and reloaded server-owned profile |
| P1 diagnostic | 4 server-selected P1 diagnostic sessions fully answered and finalized |
| P5 diagnostic | 3 server-selected P5 diagnostic sessions fully answered and finalized |
| Stage-0 floor | Server controls the coverage target; first diagnostic alone does not unlock plan. Test loops legally until `stage0_complete=true`, without forcing stages |
| P1 weekly plan | Actual `generate_exam_prep_weekly_plan_safe_v3` + readback returned published pending learning item |
| P5 weekly plan | Separate real server-issued plan; P1/P5 IDs differ |
| P1 learning | Real Math UI opened a governed learning pack, submitted 4 responses and finalized |
| P5 learning | Real Math UI opened a governed learning pack, submitted 4 responses and finalized |
| Reopen finalized results | Authenticated real RPC can reopen both P1 and P5 own sessions |
| Cross-user session isolation | Test account B cannot obtain account A’s P1 session items |
| Authoritative persistent DB evidence | `P1:finalized:5`, `P5:finalized:4`; 9 total complete sessions, zero real student changes |

The smoke test intentionally submits synthetic answers without asserting fabricated correctness. Written Core and objective grading retain server authority. Failures before GREEN were in the **test harness assumptions** (component card auto-start; multiple screening cycles; server-owned assessment item count; asynchronous written-state reload before finalization), fixed in PR. No product runtime changes required.

## Genuine remaining Stage B gaps

**Stage B remains IN PROGRESS**. This green segment does **not** establish all of the following on the exact same HTTP/browser chain:

- Correction case creation and one real owned correction session, under actual published content.
- Delayed fresh retest and server-controlled due time; proper virtual test clock without faking academic progress.
- Mixed transfer session and per-paper reserve isolation.
- Timed practice/full-paper deadline, write, review and qualified scoring in real HTTP roundtrip.
- Math-specific external written criteria / non-credit Next / honest resume, including signed-out browser reload after a partially completed task.
- Real `@supabase/supabase-js` (currently HTTP-compatible fetch wrapper), full GoTrue managed session refresh, Telegram WebApp chrome/device. No synthetic test is evidence of real user consent or 4 real weekly beta reviews.

## Safety and hard gates

- Local test is hard-bound to `http://127.0.0.1:3000`, requires `P1P5_E2E_ISOLATED=true` and an ephemeral JWT secret, and DB seed refuses non-disposable contexts and any pre-existing users.
- All student data are fake; no production credentials, project keys or live learner data. No production mutations or runtime/feature changes.
- The dedicated workflow runs independently on changed Exam Prep runtime/migrations or manual invocation; fails if either P1 or P5 actual HTTP route diverges.
- Engineering test evidence is **not** a mass release gate pass. Retain `NO_GO` for mass rollout until genuine human weekly reviews and owner-approved existing access reconciliation.

## Reproduce/continue

- Workflow: `.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml`
- Disposable local fixture: `supabase/tests/p1p5_isolated_http_auth_e2e_seed.sql`
- Browser driver: `scripts/p1p5-isolated-http-auth-e2e.cjs`
- First green source trace: `docs/math-p1p5-e2e-stage-a-source-server-trace-20261101.md`
- Canonical roadmap ledger: `docs/math-p1p5-integrated-e2e-release-roadmap-v1.md`
- Continue the above remaining gaps in substantial new automated integration batches; do not re-audit the already academically checked 1,448 items without new defects.
