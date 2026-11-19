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

A scheduled cleanup can remove text **after** its deadline, but scheduling is not an exact 24-hour guarantee: a minute-based job may run late or fail. **Even a successful `UPDATE answer=NULL` is not proof of physical erasure.** PostgreSQL retains old row versions for transaction/vacuum mechanics, and WAL, replicas, backups and restore points can preserve old content after a logical update. Official references: [PostgreSQL 17 routine vacuuming](https://www.postgresql.org/docs/17/routine-vacuuming.html) and [Supabase backup and PITR](https://supabase.com/docs/guides/platform/backups).

**Owner's further decision, 2026-11-19: strict option A.** The 24-hour limit must not be weakened to allow late cleanup. Under this interpretation, the current PostgreSQL plaintext + periodic cleanup prototype is **NOT an acceptable production implementation**, regardless of successful synthetic redaction tests.

**Fail-closed next-stage design contract:** No *new* durable plaintext PC4 recovery storage or funded model dispatch can be enabled until source-verified infrastructure demonstrates that recoverable answer **text** is absent from all disallowed copies after the deadline (including backup/recovery implications). Prefer evaluating an answer encrypted at rest with a strictly expiring independently controlled decryption capability, with no plaintext in persistent logs/WAL/backups, **but cryptographic expiry must not be mislabeled as physical erasure of ciphertext**. If robust recovery for the full window cannot be provided without violating the rule, pause the paid candidate rather than silently shorten recovery or extend retention. Any new key store, paid service, backup policy or change in learner UX needs separate owner approval and independent security evidence.

## Isolated-only engineering rehearsal

The separate draft, `supabase/candidates/iclub_ai_practice_answer_retention24_isolated.sql`, is deliberately **guarded to reject a production database**. It:

- Adds `answer_redacted_at` and a replacement check constraint that still requires a live `ready/acknowledged` response, but permits **explicitly expired-and-redacted** receipts with null text/hash.
- Adds a disabled service-only retention control. A later authorized activation must set a **non-backdated cutoff**; entries created before activation are excluded. The draft does not activate anything.
- Provides a bounded, service-role-only, idempotent deletion of **answer text and answer hash**, not full receipt rows. No request UUID, answer text, learner data or financial amount is exposed in its response.
- Demonstrates an **isolated-only, service-role admission probe that refuses any paid model dispatch** while strict retention remains unproven, plus a last-resort DB trigger that refuses **new plaintext storage after synthetic cutover**. These negative controls are **not yet integrated into the real Edge dispatch path** and cannot alone serve as release approval. The existing redaction procedure remains a data-minimization tool only, **not** a 24h physical-erasure guarantee.
- Does **not** create a cron job, enable a paid model, change current service RPCs or move academic data.

`supabase/tests/iclub_ai_practice_answer_retention24_isolated.sql` verifies synthetic old vs new receipts, ready/acknowledged, expired/unexpired, unknown charge, OFF gate, unauthorized users, batch bounds, repeat calls, financial data integrity and irreversible redaction. It uses a transaction and **ROLLBACK**, even on disposable PostgreSQL 17. It is not a live production acceptance test.

## Release checklist — explicit owner permission still required

No migration, live data mutation, scheduling or merge now. Before any later production proposal:

- Review the exact deployed PC4 schema and current `main` against this candidate and test with actual isolated signed auth and E2E; preserve source/version gates.
- Review a **forward-only** production migration and activation time. Never backdate the cutoff or automatically process existing records.
- Strict 24-hour limit is **already approved**: do not ask to relax it. Independently prove a storage/recovery design that prevents post-deadline access **and** disallowed retained plaintext across PostgreSQL/WAL/backups, or leave new text persistence and paid dispatch OFF. A periodic cleanup alone fails this gate; a cryptographic-expiry alternative is only a candidate and needs separately reviewed key custody, backups and no-plaintext trace.
- Demonstrate money/quota reconciliation, shared-cost unknowns, `ready/acknowledged` replay/ACK consistency, permission boundary and no academic progress change.
- Request separate explicit consent to handle the **two existing expired text-bearing receipts**; **Question 2 = B means leave them unchanged until then**.

**Coordination:** Keep [Draft PR #580](https://github.com/jteshaboev1984-ops/iClub_APP/pull/580) (Tutor UI) untouched. This retention task is an isolated branch, not a competing UI or provider implementation.
