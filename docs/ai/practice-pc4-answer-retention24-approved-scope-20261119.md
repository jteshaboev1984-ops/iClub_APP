# Practice AI PC4 — 24-hour answer-text retention (owner-approved design scope)

**Issue:** [#412](https://github.com/jteshaboev1984-ops/iClub_APP/issues/412).  
**Decision:** architect confirmed on 2026-11-19: **Question 1 = A**, **Question 2 = B**.  
**Status:** approved **policy for preparation only**; **NOT** an approval to migrate Supabase, delete existing records, merge a PR, schedule a live job or deploy paid AI.

## What is approved

1. An AI Practice answer can be recovered for **24 hours** after receipt creation under the existing PC4 deadline. For **new receipts created after a separately approved activation**, store raw answer text for no longer than this intended period. Do not expand AI availability or lengthen the current recovery window.
2. Preserve the existing expired entries **unchanged now**. Prove the mechanism on synthetic disposable data and seek a separate owner GO for any treatment of previously stored text.
3. Retain receipt identities, owner linkage, request/context/source fingerprints required for accounting and ownership checks, receipt/ACK state and paid-provider/quota ledgers. Do **not** erase receipt rows or declare ambiguous provider charges free.
4. Remove the answer text **and** its content-derived answer hash together only when the new record has reached its deadline; record a time of redaction for audits without storing a copy of the response. Do not allow a redacted answer to be silently restored.

This policy applies to **Practice PC4 answer recovery text**, not Exam Prep Tutor Cards, Tour answers, examination results, certificates, learner history or other AI logs. New limits for those require separate review.

## Important difference: expiry vs physical deletion

Existing `expires_at` defaults to `received_at + 24 hours`, and current recovery RPCs reject expired requests. This is an **access deadline**, not an automatic erase. As verified on 2026-11-19, the existing `ready/acknowledged` database check requires answer text to remain non-null and blocks a naive `UPDATE answer=NULL`.

A scheduled cleanup can remove text **after** its deadline, but scheduling is not an exact 24-hour guarantee: a minute-based job may run slightly late or fail. Before any production release, the owner must approve an implementation/monitoring method that fulfills the 24-hour retention expectation, including what happens if cleanup is delayed. Never claim "automatically deleted at exactly 24h" until proven.

## Isolated-only engineering rehearsal

The separate draft, `supabase/candidates/iclub_ai_practice_answer_retention24_isolated.sql`, is deliberately **guarded to reject a production database**. It:

- Adds `answer_redacted_at` and a replacement check constraint that still requires a live `ready/acknowledged` response, but permits **explicitly expired-and-redacted** receipts with null text/hash.
- Adds a disabled service-only retention control. A later authorized activation must set a **non-backdated cutoff**; entries created before activation are excluded. The draft does not activate anything.
- Provides a bounded, service-role-only, idempotent deletion of **answer text and answer hash**, not full receipt rows. No request UUID, answer text, learner data or financial amount is exposed in its response.
- Does **not** create a cron job, enable a paid model, change current service RPCs or move academic data.

`supabase/tests/iclub_ai_practice_answer_retention24_isolated.sql` verifies synthetic old vs new receipts, ready/acknowledged, expired/unexpired, unknown charge, OFF gate, unauthorized users, batch bounds, repeat calls, financial data integrity and irreversible redaction. It uses a transaction and **ROLLBACK**, even on disposable PostgreSQL 17. It is not a live production acceptance test.

## Release checklist — explicit owner permission still required

No migration, live data mutation, scheduling or merge now. Before any later production proposal:

- Review the exact deployed PC4 schema and current `main` against this candidate and test with actual isolated signed auth and E2E; preserve source/version gates.
- Review a **forward-only** production migration and activation time. Never backdate the cutoff or automatically process existing records.
- Approve how strictly to meet the 24-hour physical erase target (schedule, monitoring, late-run recovery and evidence of successful cleanup) without exposing answer text in logs.
- Demonstrate money/quota reconciliation, shared-cost unknowns, `ready/acknowledged` replay/ACK consistency, permission boundary and no academic progress change.
- Request separate explicit consent to handle the **two existing expired text-bearing receipts**; **Question 2 = B means leave them unchanged until then**.

**Coordination:** Keep [Draft PR #580](https://github.com/jteshaboev1984-ops/iClub_APP/pull/580) (Tutor UI) untouched. This retention task is an isolated branch, not a competing UI or provider implementation.
