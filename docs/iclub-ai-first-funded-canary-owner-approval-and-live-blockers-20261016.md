# First funded Global iClub AI canary — owner limit confirmed; payout gate still OFF

**16 October 2026** — Architecture status after owner confirmed **US$1** total pilot lifetime cap.

## Owner-approved financial envelope
- Hard absolute lifetime: **$1.00**.
- UTC daily global: **$0.50**.
- UTC per learner: **$0.05**.
- Atomic reservation per call: **$0.01**.
- Maximum 2 concurrent paid provider calls.
- Approved amount does **not** authorize broader public/student rollout, tariff changes or exposure to unscreened contexts.
- Machine-readable record: `qa/ai-v21-funded-canary-approved-money-policy.json`, defaults provider disabled and no real students.

## Proven on isolated QA

- Local PostgreSQL money ledger validates default OFF, atomic one-request reserve, double-spend refusal, lifetime, UTC day, learner day, **third concurrent call refusal**, and retained full unknown provider liability.
- Detached funded provider HTTP candidate `qa/ai-v21-funded-provider-transport.cjs` limits UTF-8 input, output (220 tokens total including reasoning), accepts only verified server-sourced public app help and exactly matched SHA256 source, uses model `gpt-5.6-luna`, `store:false`, `reasoning.effort:none`, no tools, no provider retry after uncertain dispatch, verifies provider model and usage, reconciles token prices, never releases uncertain provider charges as free. This is NOT a deployed function and receives no secrets.
- Negative tests cover forged source, revoked entitlement, missing key, id replay, denied money reserve, ambiguous dispatch, provider outage, unknown token bill, rejected answer, and lost accounting acknowledgment.
- The old live Exam Prep and Practice AI providers remain untouched.

## Live evidence / blockers

Read-only Supabase catalog on 16 October returned **0 v2.1 public RPCs**, **0 v2.1 private relations**, **0 of the four required provider-spend / Practice resolver RPCs**. Live Edge inventory includes old `exam-prep-ai` and `practice-ai`; **no Global AI Edge function is deployed**. This does not prove provider secret presence/availability, and a service-role credential is not available here for authorized, cost-metered synthetic smoke invocations.

The current money schema is marked UNAPPLIED, scratch-only and explicitly rejects deployment to live DB until separately adapted, audited, and reviewed. The hosted v2.1 infrastructure is a real requirement; green QA is NOT a substitute.

Because the production app has real learners, DO NOT deploy incomplete foundation RPCs or an open endpoint merely to force a first paid request. Do not retrofit the existing Mathematics Tutor or reuse its active paid-account entitlements. Maintain Production Global AI OFF.

## Remaining ordered sequence for *actual* first billed API call

1. Design and validate the minimal versioned production migration for an **isolated, name-spaced** funded-canary money ledger and independently approved public-app support source; prove the migration on a backup/disposable clone, RLS/grants and reversible downtime-free deployment. No touching grades/lesson tables. Existing 24+1 RPC candidates must not be silently treated as deployed.
2. Wire the server-authenticated, exact source/locale/role + server kill-switch gates to the real money ledger and the pinned provider transport, set caps from the owner-approved policy. Verify the actual installed secret inside the runtime **without printing it**. Fully deny public/student clients until a pre-authorized operator canary path exists.
3. Allow at most ONE explicitly budgeted real call through that complete endpoint; reconcile provider invoice and assert remaining budget, audit the result, then keep the feature off until the operator approves beta graduation. Production student cohort remains empty.

## Financial modelling

Official API list for `gpt-5.6-luna`: input $0.20 per 1M tokens, cached input $0.02, output $1.20. With input <=8,000 UTF-8 bytes plus protocol buffer and max 220 output tokens (including reasoning), transport reserve is conservatively bounded by $0.01 per call; it rejects excessive input instead of relying on average token counts. Real billing is based on provider-reported tokens; unknown invoices retain the full hold.

Source: https://developers.openai.com/api/docs/models/gpt-5.6-luna; https://developers.openai.com/api/reference/resources/responses/methods/create.

**Actual paid calls during this phase: none. Actual newly incurred model cost: US$0.**
**Do not claim the $1 pilot has launched yet.** The architect's financial cap is approved, but a secure production money gate and authenticated canary invocation are not yet available.

**Regression evidence:** [GitHub Actions full QA](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38909826319) (check final status before reporting).

