# iClub Mathematics P1/P5 — Issue #450 P0-13/14 authenticated epoch cutover & concurrency

**2026-11-04 | DRAFT E2E proving ground | NOT a production RPC or authorized cleanup.**

## Why P0-09 needed stronger testing

The earlier P0-09 PostgreSQL fixture proved an isolated one-shot authorization contract, but it was not a real HTTP/JWT request and did not directly demonstrate what happens when an old but cryptographically valid mobile JWT, stale paper session, or a simultaneous in-flight write races with release cutover. This is essential before a future one-time beta-learning reset.

The current production `private.exam_prep_require_core_access_v1` validates signed identity, active Core entitlements and rollout flags, **not a distinct learning epoch**. The [read-only catalog inventory](p1p5-p0-12-public-rpc-epoch-fence-inventory-20261104.md) identified 134 publicly named Exam Prep RPCs, 98 authenticated-callable, 25 syntactic direct DML candidates; all public functions in the named group are SECURITY DEFINER. These are inventory counts, **not** a complete nested mutation call graph. They must be treated as a release blocker, not proof that a new test fixture protects current production writers.

## P0-13 signed JWT → local PostgREST → disposable PG17

- [Isolated SQL model](../supabase/tests/p1p5_v2_package0_signed_epoch_http_disposable.sql) adds only `private.p0_13_epoch_gate`, `private.p0_13_fake_write_events` and `private.p0_13_fake_authorizations`, all RLS-protected. The only public test RPC is `public.p0_13_submit_signed_epoch_test_v1` on the **disposable** PG17 stack; there is no corresponding migration, live deployment or real academic response modification.
- [Signed HTTP adversarial tests](../scripts/p1p5-v2-package0-signed-old-epoch-http.cjs) reuse exactly one HMAC-signed JWT issuance timestamp across the before/paused/after phases (via `P0_13_FIXED_IAT`). They test owner-only acceptance, anonymous/foreign/tampered JWT denial, an old paper authorization after epoch increment, and an explicit attempt to forge a new epoch on that old authorization. No purely client-supplied version may upgrade a frozen old issued session.
- The test-only writer locks its program's server-controlled epoch row `FOR SHARE` while committing a synthetic write, then checks `issued_epoch` from an authorization generated on the server. Identical request/payload is idempotent, conflicting payload is HTTP 409 `PT409` (never SQLSTATE 40001 retry loop), and old/paused epoch attempts return a nonretryable conflict. A new epoch can create new work only after the server has issued the new authorization.
- The workflow also checks two fake users, Economics isolation, synthetic response count and authorization issuance. Every test runs only at `127.0.0.1` with a disposable JWT secret and non-production PG17. A private source guard rejects accidental non-isolated test wiring.

## P0-14 actual simultaneous connections (not sequential-only)

[Two-backend PostgreSQL lock test](../scripts/p1p5-v2-package0-concurrent-epoch-lock.cjs) begins an **open transaction** holding a real `FOR SHARE` lock against the fake program epoch. A second PostgreSQL connection attempts maintenance `UPDATE` with a bounded timeout. It MUST fail specifically on a real PostgreSQL row-lock timeout and leave the epoch unchanged. Only after the first transaction finishes may the maintenance switch succeed; the test then restores the original fake gate and verifies Economics/response content unchanged. This prevents a dangerous claim of concurrency safety based only on sequential JavaScript mocks.

**Evidence status:** The [full PG17/JWT E2E workflow](../.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml) and [Package 0 fast source guard](../.github/workflows/p1p5-v2-package0-cleanup-rehearsal.yml) include both scenarios. Record exact HEAD SHA + final named test-step conclusions in [execution ledger](math-p1p5-v2-execution-ledger.md) and [Issue #450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450) only after CI really passes. No implied approval from the presence of tests or a prior SHA.

## Strict outstanding release blockers

This is an **isolated design proof**, not a replacement for a real versioned, authorized release service. All current real Exam Prep public/indirect writing paths, owner authorization/session issuance, correction/retest/plan updates, trusted epoch provenance, lost-ACK retries, offline stale mobile requests and administrative scoped reset must be revised/tested in exact final release source before GO. Draft PRs #469/#470/#471 must be combined with full table/FK owner audit, prelaunch receipt retention decisions and a verified production encrypted backup + independent restore. **Only an explicit architect-approved exact SHA, manifest, and one-time release GO** may authorize the actual cutover; until then current beta, non-Math lessons, Tours, Practice, certificates, users and historical audit records are immutable.

**NO_GO.** Nothing in P0-13/14 modifies main, production Supabase, Vercel or learner progress.
