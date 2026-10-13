# iClub AI Layer v2.1 — P7 Distributed Request Safety and Atomic Settlement

**Date:** 2026-10-13. **State:** QA branch candidate, **NO deployment or database migration**. All SQL stored under `qa/sql_drafts`, not `supabase/migrations`. No learning content is authored here.

## Architectural risk removed in the candidate

A browser double-click, disconnected network, or two simultaneous Edge workers must not make the same provider request twice or charge the same learner twice. The previous process-local mock ledger/response receipt is **insufficient** when Edge workers restart or scale. This milestone adds a **durable, minimal, database-backed request tombstone** that survives worker restart and is verified against the same identity as the temporary 1:3 quota reservation.

### Technical package

- `qa/sql_drafts/iclub_ai_delivery_claim_v21_UNAPPLIED.sql`:
  - `private.iclub_ai_request_tombstones_v21` has a unique request UUID, owner UUID, SHA-256 server-session fingerprint, SHA-256 immutable content/request fingerprint, route class, status and claim expiry. **No question text, replies, prompts, marks, transcripts, academic state or provider logs** stored.
  - `claim_iclub_ai_delivery_service_v21` is service-role-only. It requires **an existing live v2 quota reservation** with identical UUID/user/route/fingerprint before the first and only successful claim. Repeated, expired, completed and released IDs are not reclaimed and cannot call the provider again. A second or foreign worker receives a safe denial.
  - `finish_iclub_ai_delivery_service_v21` is also service-role-only. It checks exact learner/session/fingerprint/route and claim lifetime. **It invokes `finalize_iclub_ai_usage_service_v2` and updates the tombstone in one PostgreSQL transaction**: a failure in either step rolls back both. `released` gives no learner charge; `completed` applies the temporary weight. Pre-existing v1 functions and deployed migrations remain unchanged.
  - The SQL has independent scratch-name and local-server/Docker-bridge guards. No receipt-text storage, cleanup/delete procedure or expiry-reuse loophole has been introduced. Permanent tombstones currently require a separate future retention design; deleting them without proven safe replay semantics is **NO-GO**.
- `qa/sql_drafts/iclub_ai_delivery_claim_local_pg.psql`: disposable PostgreSQL test for no-reservation, first claim, duplicate claim, foreign user, wrong fingerprint, quota mismatch, successful finalize, repeated finalize, release and expired claim.
- `qa/sql_drafts/iclub_ai_delivery_atomic_meter_local_pg.psql`: **real deployed v1 tariff foundation source + unapplied v2 1:3 draft + durable delivery** within a separate local PostgreSQL 16 database. Validates generated3, prepared1, no charge on release, and specifically injects a **trigger failure after quota-finalization code begins**. The PostgreSQL exception subtransaction rolls back BOTH usage and tombstone. After removing the synthetic trigger, the same claim can finish once without double-charge.
- `qa/run-ai-layer-v21-claim-race.sh`: two independent PostgreSQL connections compete for a single request UUID, first transaction deliberately held open for 0.6 sec. Observed exactly **1 claim / 1 denial / 1 durable tombstone**.
- `qa/ai-layer-v21-delivery-claim-sql.test.cjs`: 12 native Node static contract tests. The combined `qa/run-ai-layer-v21-offline.cjs` now includes **21** suites.

### Actually executed in GitHub Actions (NOT simulated)

[Green QA run 38348691615](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38348691615). Native Node.js 22: **352 / 352 PASS**; separate 8 / 8 synthetic smoke checks; legacy Mathematics P1/P5 and cross-subject isolation regression GREEN. Ephemeral real PostgreSQL 16: **6 / 6 scratch suites PASS** (`meter`, `math`, `practice`, `release`, `claim`, `atomic`); independent concurrent two-client SQL race PASS; forced mid-transaction failure + rollback PASS. Original Exam Prep source files, existing migrations and `app.js` / `index.html` protected-file comparison PASS. All test DBs were temporary and destroyed; no production Supabase calls/writes or Vercel deployments.

### Correct sequence for the FUTURE authenticated Edge adapter

1. Verify JWT on server, validate opaque session context ownership and the current protected assessment/subject/feature state.
2. Verify per-topic/per-locale editorial publication with current approved source **and independent live version/hash/rights proof**; if not ready, return RU/UZ/EN “В разработке” without reserving quota.
3. Derive route, usage policy, request fingerprint and session fingerprint **server-side**. Validate money/provider budget for generated route; prepared card route must never borrow an unverified source.
4. Call the existing QA v2 **atomic reserve RPC**, then the new atomic **claim RPC**. A retry/duplicate cannot call a provider or reset an earlier claim.
5. Repeat protected exam/subject/topic/source checks before provider and after generation. If refused/failure, call the new **atomic finish RPC with released**; if output passes, atomic finish with `completed`.
6. Deliver only a safe response. Do not let AI write Practice/Tours/Exam Prep learning state. Never import or reroute existing `exam-prep-ai`.

### Remaining critical gaps — no live rollout

- **Not yet connected** to `supabase/functions/global-ai/index.ts` or any deployed v2 Edge. A server-minted context endpoint and actual production-safe service adapters are still pending.
- **Reply recovery**: durable tombstone stops a duplicate paid/model call after a worker restart, but **does not replay reply text**. If completion succeeded and the HTTP response was lost, the same request gets safe `already_processed_no_receipt`; implement a separately reviewed, minimal, short-lived, session-bound encrypted delivery receipt if the owner approves the privacy/retention design. Do not silently re-execute the provider.
- **No distributed Edge acceptance** yet: two actual PostgreSQL sessions were tested, not two deployed Edge runtime instances. Provider cost/responses remain mocked; real budget and AI output safety are unverified.
- **Atomicity boundaries**: usage+request state is atomic inside PostgreSQL, but no database can guarantee delivery of an HTTP packet; do not claim zero lost responses on failed networks. Do not charge for a returned failure intentionally; route-specific rollback is verified.
- SQL/RLS/security privileges must be reviewed before an approved reversible future deployment. Real learner data, tariff activation, subscriptions, content publication and rollout are separately owner-authorized.

**Boundary maintained:** Mathematics Exam Prep production sources untouched; no content authoring, no real production DB writes, no migrations or deployments. 
