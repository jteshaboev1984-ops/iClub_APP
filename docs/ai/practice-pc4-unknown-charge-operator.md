# PC4 — safe reconciliation policy for ambiguous model costs
**27 October 2026 · Candidate only · no production database/API change**

## Why a permanent "unknown" status is intentional
The OpenAI Responses request is sent with `store:false`. If the upstream request times out, HTTP 503 is received, or the Edge process dies after the request is dispatched, we cannot infer whether that individual request was billed. A project/day cost total is not proof of the bill for a single request. Do **not** automatically mark an unknown request as `no_charge`, and never send the same UUID to the model again.

The deployed canonical `reserve_iclub_ai_v21_freeform_budget_v1` calculates exposure using **reserved hold** for every non-`charged` state, including `unknown`. Accordingly:
- Unknown cost retains the conservative **$0.05 maximum per-request liability**, counted against the existing shared **$5 lifetime pilot ceiling** and per-learner budget.
- Learner-generated quota is safely **released** by the existing canonical finish RPC only where appropriate; it is separate from potential provider charges.
- An `unknown` receipt is **never replayed or retried** as a generated answer.
- Too many unresolved unknown costs eventually exhaust the pilot and **safely disable new paid requests**, rather than overspend.

## What can be audited automatically without guessing
New candidate `supabase/candidates/iclub_ai_practice_pc4_financial_audit_dormant.sql` provides `public.iclub_ai_practice_pc4_financial_audit_service(limit)`, readable **only by service_role** and callable even when feature controls are OFF. It is read-only, does not expose learner names, account IDs, question text, answers or prompt/source fingerprints, and never changes canonical financial states. Its output includes:
- Request UUID, receipt state, shared money and quota states, age and maximum possible amount.
- Action hint (manual review for unknown; no model retry for stale dispatch; recover original charged ready answer; inspect missing canonical ledgers).
- Count of unknown requests, count of **closed receipts with orphaned reserved learner quota**, and conservative maximum reserved+charged exposure for Practice receipt transactions.
- **Closed (`void`) receipt with an open money reservation**: still counts as financial exposure and is explicitly flagged. This can occur if a budget reservation commits but its HTTP response is lost. A closed receipt does not mean the budget is free.
- **Closed (`void`) receipt with reserved learner quota but no budget row**: flagged for manual examination rather than silently consuming learner requests. The Edge attempts a canonical quota release if quota reservation HTTP acknowledgment is lost; the audit catches unresolved holds if that compensation also fails.

## Operational workflow in controlled beta
1. Review the **read-only** audit at a bounded interval and immediately after an incident. Do not run it from the student browser or expose the service key.
2. For `ready+charged`: offer same-ID Tutor recovery and ACK; do not regenerate. For `void+reserved money` or `void+reserved quota`, investigate the canonical reservation/compensation outcomes without attempting to regenerate.
3. For `unknown+unknown`: keep its money hold counted. Inspect provider-side request evidence via account owner/admin. Record the actual request ID, time window and any support confirmation **outside the learner-facing app**. OpenAI organization usage/cost reports aggregate by time bucket/project/model and **cannot alone attribute an amount to this one request**.
4. If evidence is insufficient, leave `unknown` indefinitely under the $5 cap. Escalate only if too many unknowns consume the test allocation.
5. The currently deployed canonical budget settle function only permits transition to `charged` from `dispatched`, and `no_charge` from `reserved`; it **cannot** reconcile `unknown` directly. A future explicitly reviewed, audited and authorized administrative resolution mechanism would be needed to release or finalize that liability. **Do not bypass the canonical limits with ad hoc SQL writes.**
6. Do not delete receipt rows or ledger entries merely because `expires_at` has passed; expiry controls user answer replay, not financial audit retention.

## Release constraints
- This audit is **not an automatic per-request OpenAI billing lookup**, and it deliberately does not resolve any provider charge. It is a safe audit and containment mechanism.
- A limited beta may operate with unknowns reserved, if explicitly approved under the existing caps; unresolved unknowns lower remaining budget, they never increase it.
- For a production pilot, design an administrative evidence+approval workflow and a storage/retention policy without permitting learners to change accounting.
- Do not deploy `PC3/PC4`, alter database schemas, change `gpt-5.4-mini` or exceed the existing $5 pilot until separately authorized.

**Verification**: CI `supabase/tests/iclub_ai_practice_pc4_financial_audit_isolated.sql` audits synthetic `money=unknown, quota=released, receipt=unknown`, `receipt=void, money=reserved`, and `receipt=void, quota=reserved, money missing` cases after the actual candidate Deno Edge and canonical accounting-RPC integration. An additional fault injection makes quota reservation commit but drops its HTTP response: the Edge must compensate using the canonical quota release RPC, without calling OpenAI. It also tests unauthenticated-role denial, OFF-mode audit, no PII and absence of writes.

Reference: OpenAI [Usage API / Costs API](https://platform.openai.com/docs/api-reference/usage) docs; existing canonical budget/settlement PostgreSQL function definitions in the iClub production project were read-only inspected on 27 Oct 2026.
